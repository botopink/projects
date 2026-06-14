#!/usr/bin/env bash
# botopink-bin.sh — locate the `botopink` binary for `.bp` lib gates.
#
# Resolution order:
#   1. $BOTOPINK_BIN (env, explicit override).
#   2. Closest ancestor `repository/botopink-lang/zig-out/bin/botopink` walking
#      up from the current dir — covers nested worktrees + the meta workspace
#      where the compiler is bundled.
#   3. $PATH lookup.
#   4. Empty string + a yellow warning. Caller decides whether to skip or fail.

locateBotopink() {
    if [ -n "${BOTOPINK_BIN:-}" ] && [ -x "$BOTOPINK_BIN" ]; then
        echo "$BOTOPINK_BIN"
        return 0
    fi

    local cur
    cur=$(pwd)
    while [ "$cur" != "/" ]; do
        local cand="$cur/repository/botopink-lang/zig-out/bin/botopink"
        if [ -x "$cand" ]; then
            echo "$cand"
            return 0
        fi
        # Also catch the in-place flat tree (running inside botopink-lang itself).
        cand="$cur/zig-out/bin/botopink"
        if [ -x "$cand" ] && [ -f "$cur/build.zig" ]; then
            echo "$cand"
            return 0
        fi
        cur=$(dirname "$cur")
    done

    if command -v botopink >/dev/null 2>&1; then
        command -v botopink
        return 0
    fi

    return 1
}
