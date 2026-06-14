#!/usr/bin/env bash
# meta.sh — gate for the workspace meta repo.
#
# Steps:
#   1. compile-side: zig build + zig build test against repository/botopink-lang/
#   2. botopink test against every repository/botopink-lang/libs/<name>/
#   3. submodule-pointer scan: for each staged submodule bump, check out the
#      staged SHA in a throwaway worktree under .tasks/_hook-<sub>-<sha7>/
#      and recursively run that submodule's own gate.
#
# Worktree handling (per spec):
#   - on success → remove the throwaway worktree
#   - on failure → leave it for inspection + fail the meta commit
#   - reuse an existing worktree at the path (race-safety: previous fail).
#   - 10-minute budget per submodule; over budget fails with a hint.

# Resolve the staged SHA for a submodule path from `git diff --cached`.
__metaStagedSha() {
    local path="$1"
    git diff --cached "$path" 2>/dev/null | awk '/^\+Subproject commit/ { print $3 }'
}

# Resolve the HEAD-side SHA for a submodule path; empty if the path is
# a fresh add (or staged for removal).
__metaHeadSha() {
    local path="$1"
    git diff --cached "$path" 2>/dev/null | awk '/^-Subproject commit/ { print $3 }'
}

# True if a submodule path is staged for *removal* (gitlink dropped from
# the index). A path whose working tree is just empty (submodule not
# initialized) is **not** considered removed.
__metaStagedForRemoval() {
    local path="$1"
    local entry
    entry=$(git ls-files --stage -- "$path" 2>/dev/null | head -1)
    if [ -z "$entry" ]; then
        return 0
    fi
    case "$entry" in
        160000\ *) return 1 ;;   # gitlink still present
        *) return 0 ;;            # turned into regular file — effectively removed as submodule
    esac
}

# Run a child gate with a wall-clock budget. Args: <budget-seconds> <path>.
# Inherits the parent shell's $__GIT_HOOKS_LIB_DIR so the sourced
# runProjectGate resolves siblings.
__metaRunGateWithBudget() {
    local budget_s="$1"
    local target="$2"
    # `timeout` (GNU coreutils) is the standard pre-installed binary on the
    # CI runners + every dev workstation in the team. Spawn a subshell so
    # `runProjectGate` cd-ing around doesn't leak into the meta gate.
    timeout --signal=TERM --kill-after=10 "${budget_s}s" \
        bash -c "
            __GIT_HOOKS_LIB_DIR='$__GIT_HOOKS_LIB_DIR'
            . '$__GIT_HOOKS_LIB_DIR/test-runner.sh'
            runProjectGate '$target'
        "
}

metaGate() {
    local root="$1"
    cd "$root"

    # 1. Conflict markers in staged files.
    #    The previous hook used `grep -rn` which recurses into submodule paths
    #    and false-positives on `.zig-cache` artifacts. Filter to regular
    #    files so a staged submodule (a gitlink, not a tree) is skipped.
    #    The 7-character marker literals are built dynamically so this file
    #    itself never contains the run that would self-trigger the gate.
    local lt7 eq7 gt7
    lt7=$(printf '<%.0s' {1..7})
    eq7=$(printf '=%.0s' {1..7})
    gt7=$(printf '>%.0s' {1..7})
    local marker_re="${lt7} |${eq7}\$|${gt7} "
    local staged
    staged=$(git diff --cached --name-only --diff-filter=ACM)
    if [ -n "$staged" ]; then
        local marker_hits=""
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            [ -f "$f" ] || continue
            if grep -nE "$marker_re" "$f" 2>/dev/null | head -1 | grep -q .; then
                marker_hits="$marker_hits $f"
            fi
        done <<< "$staged"
        if [ -n "$marker_hits" ]; then
            echo "  Conflict markers in:$marker_hits"
            fail "Conflict markers found in staged files"
        fi
        pass "No conflict markers"
    fi

    # 2. zig fmt on staged .zig files only.
    local zig_files
    zig_files=$(echo "$staged" | grep '\.zig$' || true)
    if [ -n "$zig_files" ]; then
        local bad_fmt=""
        for f in $zig_files; do
            if ! zig fmt --check "$f" >/dev/null 2>&1; then
                bad_fmt="$bad_fmt  $f\n"
            fi
        done
        if [ -n "$bad_fmt" ]; then
            echo -e "${RED}✗ Formatting issues:${NC}"
            echo -e "$bad_fmt"
            echo "  Run: zig fmt <file> to fix"
            exit 1
        fi
        pass "zig fmt OK ($(echo "$zig_files" | wc -w) files)"
    else
        warn "No .zig files staged, skipping fmt"
    fi

    # 3. Compile + test repository/botopink-lang (workspace layout) or the
    #    flat tree (root build.zig) so the same hook works during the
    #    workspace migration.
    local core
    if [ -f "$root/repository/botopink-lang/build.zig" ]; then
        core="$root/repository/botopink-lang"
    elif [ -f "$root/build.zig" ]; then
        core="$root"
    else
        fail "no build.zig at the repo root or repository/botopink-lang/"
    fi

    # shellcheck source=botopink-lang.sh
    . "$__GIT_HOOKS_LIB_DIR/runners/botopink-lang.sh"
    botopinkLangGate "$core"

    # Restore CWD: botopinkLangGate cd-ed into the core; the submodule scan
    # below depends on running at the meta root.
    cd "$root"

    # 4. Scan staged submodule bumps and recurse.
    local gitmodules="$root/.gitmodules"
    if [ ! -f "$gitmodules" ]; then
        info "(no .gitmodules — skipping recursive submodule scan)"
        return 0
    fi

    # Collect every submodule path from .gitmodules.
    local sub_paths
    sub_paths=$(git config --file "$gitmodules" --get-regexp 'submodule\..*\.path' | awk '{print $2}')

    # Filter to those whose pointer is staged for change.
    local bumped=()
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        if __metaStagedForRemoval "$path"; then
            info "(submodule $path staged for removal — skipping)"
            continue
        fi
        local new_sha old_sha
        new_sha=$(__metaStagedSha "$path")
        old_sha=$(__metaHeadSha "$path")
        if [ -z "$new_sha" ]; then
            continue
        fi
        if [ "$new_sha" = "$old_sha" ]; then
            continue
        fi
        bumped+=("$path:$new_sha")
    done <<< "$sub_paths"

    if [ "${#bumped[@]}" -eq 0 ]; then
        info "(submodule pointer scan: no submodule bumps staged — skipping recursive gate)"
        return 0
    fi

    info "(submodule pointer scan: ${#bumped[@]} bump(s) staged)"

    # Drop the meta's GIT_* env so submodule git invocations don't reach into
    # the meta's index/object DB. `git -C <path>` only changes CWD; without
    # this unset, GIT_DIR (inherited from the parent commit) overrides it and
    # `cat-file -e <submodule-sha>` runs against the meta's object DB, where
    # the submodule's tip does not exist.
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX

    local budget_s=600   # 10 minutes per submodule, per spec
    local preserved=()
    for entry in "${bumped[@]}"; do
        local path="${entry%%:*}"
        local sha="${entry##*:}"
        local sha7="${sha:0:7}"
        local slug
        slug=$(basename "$path")
        local worktree_path="$root/.tasks/_hook-$slug-$sha7"

        # Make sure the staged SHA exists in the submodule's object DB
        # (else this is a "push not done yet" scenario).
        if ! git -C "$path" cat-file -e "${sha}^{commit}" 2>/dev/null; then
            echo
            echo "  Staged SHA $sha7 does not exist in $path."
            echo "  Have you pushed / fetched the submodule's branch first?"
            fail "submodule $path: staged SHA $sha7 missing in its object DB"
        fi

        # Reuse an existing worktree at the same path (race-safety) so a
        # previous failed commit doesn't break the rerun.
        if [ ! -d "$worktree_path" ]; then
            mkdir -p "$root/.tasks"
            if ! git -C "$path" worktree add -d "$worktree_path" "$sha" >/dev/null 2>&1; then
                # Last-resort retry: prune stale worktree records then add again.
                git -C "$path" worktree prune >/dev/null 2>&1 || true
                if ! git -C "$path" worktree add -d "$worktree_path" "$sha"; then
                    fail "submodule $path: cannot create worktree at $worktree_path for $sha7"
                fi
            fi
        else
            info "(reusing existing throwaway worktree at $worktree_path)"
        fi

        echo "  Testing $slug @ $sha7 in throwaway worktree..."
        if __metaRunGateWithBudget "$budget_s" "$worktree_path"; then
            git -C "$path" worktree remove --force "$worktree_path" >/dev/null 2>&1 || rm -rf "$worktree_path"
            pass "$slug @ $sha7: gate green"
        else
            local rc=$?
            if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
                echo
                echo "  $slug gate exceeded the 10-minute budget."
                echo "  Split your commit — don't bump multiple submodules at once."
            fi
            preserved+=("$worktree_path")
        fi
    done

    if [ "${#preserved[@]}" -gt 0 ]; then
        echo
        echo "── recursive gate FAILED ──"
        echo "  Inspect the throwaway worktree(s):"
        for w in "${preserved[@]}"; do
            echo "    $w"
        done
        fail "${#preserved[@]} submodule gate(s) failed"
    fi
}
