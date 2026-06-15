#!/usr/bin/env bash
# install-hooks.sh — wire the tracked pre-commit hook into every project
# (meta + 6 submodules). Idempotent. Backs up pre-existing non-symlink hooks
# to pre-commit.bak.<ts>.
#
# Usage:
#   scripts/install-hooks.sh             # install all 7
#   scripts/install-hooks.sh --check     # print state, exit non-zero on drift
#   scripts/install-hooks.sh --meta-only # install only the meta hook (partial clone)
#
# Resolution model:
#   - meta: <common>/.git/hooks/pre-commit → MAIN_ROOT/scripts/git-hooks/pre-commit
#       (always anchored at the main repo — the common git dir is shared
#       across worktrees, so the symlink must not point at a worktree's
#       in-flight source.)
#   - submodule: <sub-git-dir>/hooks/pre-commit →
#       CURRENT_ROOT/<path>/scripts/git-hooks/pre-commit
#       (worktree-local — each worktree has its own submodule git dirs.)
#
# `--check` exit codes:
#   0 — every hook is the tracked symlink
#   1 — at least one is missing or drifted (custom local hook, plain file, etc.)

set -euo pipefail

MODE=install
META_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --check) MODE=check ;;
        --meta-only) META_ONLY=1 ;;
        --help|-h)
            sed -n '2,17p' "$0"; exit 0 ;;
        *)
            echo "install-hooks: unknown arg: $arg" >&2
            echo "see --help" >&2
            exit 2 ;;
    esac
done

META_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$META_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

declare -a STATUS_LABELS=()
declare -a STATUS_CODES=()

record() {
    STATUS_LABELS+=("$1")
    STATUS_CODES+=("$2")  # ok | drift | missing | warn-bak | warn-no-tracked
}

# Compute the relative path from $1 to $2 (POSIX-ish).
relPath() {
    local from="$1" to="$2"
    python3 - "$from" "$to" <<'PY'
import os, sys
print(os.path.relpath(sys.argv[2], sys.argv[1]))
PY
}

linkHook() {
    local label="$1"      # display name (meta / repository/erika / ...)
    local hook_dir="$2"   # absolute path to .git/hooks (or modules/.../hooks)
    local tracked="$3"    # absolute path to scripts/git-hooks/pre-commit
    local target_link
    target_link="$hook_dir/pre-commit"

    if [ ! -f "$tracked" ]; then
        printf '%b⚠%b %s: tracked source missing at %s\n' "$YELLOW" "$NC" "$label" "$tracked"
        record "$label" warn-no-tracked
        return 0
    fi

    mkdir -p "$hook_dir"
    local rel
    rel=$(relPath "$hook_dir" "$tracked")

    if [ -L "$target_link" ]; then
        local cur
        cur=$(readlink "$target_link")
        if [ "$cur" = "$rel" ]; then
            printf '%b✓%b %s: already linked\n' "$GREEN" "$NC" "$label"
            record "$label" ok
            return 0
        fi
        if [ "$MODE" = check ]; then
            printf '%b⚠%b %s: symlink drifted (points at %s, want %s)\n' "$YELLOW" "$NC" "$label" "$cur" "$rel"
            record "$label" drift
            return 0
        fi
        # Live install: replace with the correct symlink.
        rm -f "$target_link"
    elif [ -e "$target_link" ]; then
        if [ "$MODE" = check ]; then
            printf '%b⚠%b %s: custom local hook at %s (not a symlink)\n' "$YELLOW" "$NC" "$label" "$target_link"
            record "$label" drift
            return 0
        fi
        local ts
        ts=$(date +%Y%m%d-%H%M%S)
        mv "$target_link" "$target_link.bak.$ts"
        printf '%b⚠%b %s: local hook backed up to %s\n' "$YELLOW" "$NC" "$label" "pre-commit.bak.$ts"
        # No record yet — the final outcome is set below after the symlink lands.
    fi

    if [ "$MODE" = check ]; then
        printf '%b✗%b %s: hook missing\n' "$RED" "$NC" "$label"
        record "$label" missing
        return 0
    fi

    ln -s "$rel" "$target_link"
    chmod +x "$tracked"
    printf '%b✓%b %s: %s → %s\n' "$GREEN" "$NC" "$label" "$target_link" "$rel"
    record "$label" ok
}

# --- meta ---------------------------------------------------------------
# The meta hook lives in the COMMON git dir, which is shared by every
# worktree. It must point at the MAIN repo's tracked source — not the
# current worktree's, which may diverge during in-flight task work.
COMMON_GIT_DIR=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null \
    || git rev-parse --git-common-dir)
case "$COMMON_GIT_DIR" in
    /*) ;;
    *) COMMON_GIT_DIR="$META_ROOT/$COMMON_GIT_DIR" ;;
esac
MAIN_ROOT=$(git worktree list --porcelain | awk '/^worktree / { print $2; exit }')
META_TRACKED="$MAIN_ROOT/scripts/git-hooks/pre-commit"
META_HOOKS="$COMMON_GIT_DIR/hooks"
linkHook "meta" "$META_HOOKS" "$META_TRACKED"

# --- submodules ---------------------------------------------------------
if [ "$META_ONLY" = 0 ] && [ -f "$META_ROOT/.gitmodules" ]; then
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        sub_root="$META_ROOT/$path"
        if [ ! -d "$sub_root" ]; then
            printf '%b⚠%b %s: submodule not checked out — run `git submodule update --init` first\n' "$YELLOW" "$NC" "$path"
            record "$path" missing
            continue
        fi
        # The submodule's git dir: works for both `.git`-file linkfiles and
        # the meta's .git/modules/<path>/ layout.
        sub_gitdir=$(git -C "$sub_root" rev-parse --git-dir)
        case "$sub_gitdir" in
            /*) ;;
            *) sub_gitdir="$sub_root/$sub_gitdir" ;;
        esac
        sub_tracked="$sub_root/scripts/git-hooks/pre-commit"
        linkHook "$path" "$sub_gitdir/hooks" "$sub_tracked"
    done < <(git config --file "$META_ROOT/.gitmodules" --get-regexp 'submodule\..*\.path' | awk '{print $2}')
fi

# --- summary ------------------------------------------------------------
echo
total=${#STATUS_LABELS[@]}
ok=0; drifted=0; missing=0
for code in "${STATUS_CODES[@]}"; do
    case "$code" in
        ok) ok=$((ok + 1)) ;;
        drift) drifted=$((drifted + 1)) ;;
        missing|warn-no-tracked) missing=$((missing + 1)) ;;
    esac
done
echo "── $total project(s): $ok ok · $drifted drifted · $missing missing ──"

if [ "$MODE" = check ]; then
    if [ "$drifted" -gt 0 ] || [ "$missing" -gt 0 ]; then
        exit 1
    fi
fi
exit 0
