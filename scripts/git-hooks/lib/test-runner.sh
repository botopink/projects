#!/usr/bin/env bash
# Minimal project-gate runner. Replaces the inline pre-commit gate from
# pre-recursive-test-gate days; preserves the same behaviour (conflict
# markers, zig fmt --check, zig build, zig build test) until the full
# `recursive-test-gate` spec lands its richer runner.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
pass() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Public entry point used by the pre-commit hook.
runProjectGate() {
    local root="${1:-$(git rev-parse --show-toplevel)}"

    # 1. Conflict markers — only scan tracked-and-staged paths, excluding
    #    submodule directories (which the hook should not recurse into) and
    #    build-cache binaries that may legitimately contain `=======` runs.
    local staged
    staged=$(git -C "$root" diff --cached --name-only --diff-filter=ACM)
    if [ -n "$staged" ]; then
        local bad=""
        while IFS= read -r path; do
            [ -z "$path" ] && continue
            # Skip submodule pointers and cache trees.
            if [ -d "$root/$path" ] && [ -f "$root/$path/.git" ]; then
                continue
            fi
            case "$path" in
                *.zig-cache/*|.zig-cache/*|node_modules/*) continue ;;
            esac
            local marker_lt marker_eq marker_gt
            marker_lt='<''<''<''<''<''<''< '
            marker_eq='^''=''=''=''=''=''=''=$'
            marker_gt='^''>''>''>''>''>''>''> '
            if [ -f "$root/$path" ] && grep -Iq -E "$marker_lt|$marker_eq|$marker_gt" "$root/$path" 2>/dev/null; then
                bad="$bad  $path\n"
            fi
        done <<< "$staged"
        if [ -n "$bad" ]; then
            echo -e "${RED}✗ Conflict markers found in staged files:${NC}"
            echo -e "$bad"
            exit 1
        fi
        pass "No conflict markers"
    fi

    # 2. Find the project's zig core (flat tree or workspace under
    #    repository/botopink-lang/).
    local core=""
    if [ -f "$root/build.zig" ]; then
        core="$root"
    elif [ -f "$root/repository/botopink-lang/build.zig" ]; then
        core="$root/repository/botopink-lang"
    fi

    if [ -z "$core" ]; then
        pass "No zig project to gate at $root"
        return 0
    fi

    # 3. zig fmt on staged .zig files only
    local zig_files
    zig_files=$(echo "$staged" | grep '\.zig$' || true)
    if [ -n "$zig_files" ]; then
        local bad_fmt=""
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            [ -f "$root/$f" ] || continue
            if ! zig fmt --check "$root/$f" >/dev/null 2>&1; then
                bad_fmt="$bad_fmt  $f\n"
            fi
        done <<< "$zig_files"
        if [ -n "$bad_fmt" ]; then
            echo -e "${RED}✗ Formatting issues:${NC}"
            echo -e "$bad_fmt"
            echo "  Run: zig fmt <file> to fix"
            exit 1
        fi
        pass "zig fmt OK ($(echo "$zig_files" | wc -w) files)"
    fi

    # 4. Build + test
    (cd "$core" && zig build >/dev/null 2>&1) || fail "zig build failed at $core"
    pass "zig build OK"
    (cd "$core" && zig build test >/dev/null 2>&1) || fail "zig build test failed at $core"
    pass "zig build test OK"
}
