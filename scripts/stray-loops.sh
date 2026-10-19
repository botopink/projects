#!/usr/bin/env bash
# stray-loops.sh — the wait loops left behind by threads (AGENTS.md § Keeping the threads honest, rule 3).
#
#   scripts/stray-loops.sh          list every shell polling in a `sleep` loop, flagging the stray ones
#   scripts/stray-loops.sh --kill   the same, then kill each flagged loop by PID
#
# A loop is a shell process with a `sleep` child. It is flagged stray when one of these holds:
#   dead-pid   it waits on `kill -0 <pid>` and every such pid is gone;
#   stale-file it is older than STRAY_MINUTES (default 30) and every file its command line names
#              under /tmp or .tasks is missing or was last written more than STRAY_MINUTES ago;
#   too-old    it is older than STRAY_MAX_MINUTES (default 180) and runs no `timeout`.
# A loop under `timeout` that is not dead-pid or stale-file is left alone: its deadline ends it.
# Only loops of the current user are read; nothing else is ever killed.
set -u

kill_flagged=0
[ "${1:-}" = "--kill" ] && kill_flagged=1
stray_min=${STRAY_MINUTES:-30}
max_min=${STRAY_MAX_MINUTES:-180}
now=$(date +%s)
found=0

for parent in $(ps -u "$(id -u)" -o ppid=,comm= | awk '$2 == "sleep" { print $1 }' | sort -u); do
    [ -r "/proc/$parent/cmdline" ] || continue
    cmd=$(tr '\0' ' ' < "/proc/$parent/cmdline")
    # a `gate.sh exec` waiting for a job is the pool's: its lease is reaped by the pool itself
    grep -q 'gate.sh exec' <<<"$cmd" && ! grep -qE '(until|while) ' <<<"$cmd" && continue
    start=$(stat -c %Y "/proc/$parent" 2>/dev/null || echo "$now")
    age_min=$(( (now - start) / 60 ))
    cwd=$(readlink "/proc/$parent/cwd" 2>/dev/null || echo "?")
    reason=""

    pids=$(grep -oE 'kill -0 [0-9]+' <<<"$cmd" | awk '{ print $3 }' | sort -u)
    if [ -n "$pids" ]; then
        alive=0
        for p in $pids; do kill -0 "$p" 2>/dev/null && alive=1; done
        [ "$alive" = 0 ] && reason="dead-pid"
    fi

    if [ -z "$reason" ] && [ "$age_min" -ge "$stray_min" ]; then
        files=$(grep -oE '(/tmp/|\.tasks/)[^ '"'"'";|&)]+' <<<"$cmd" | grep -vE '/scratchpad$|/$' | sort -u)
        # $S/<name> forms: resolve against an S= assignment in the same command line
        sdir=$(grep -oE "S=[^ ;']+" <<<"$cmd" | head -1 | cut -d= -f2)
        if [ -n "$sdir" ]; then
            files="$files"$'\n'$(grep -oE '\$S/[A-Za-z0-9._-]+' <<<"$cmd" | sed "s#\$S#$sdir#" | sort -u)
        fi
        fresh=0
        named=0
        while IFS= read -r f; do
            [ -n "$f" ] || continue
            named=1
            if [ -e "$f" ]; then
                m=$(stat -c %Y "$f")
                [ $(( (now - m) / 60 )) -lt "$stray_min" ] && fresh=1
            fi
        done <<<"$files"
        [ "$named" = 1 ] && [ "$fresh" = 0 ] && reason="stale-file"
    fi

    if [ -z "$reason" ] && [ "$age_min" -ge "$max_min" ] && ! grep -q 'timeout ' <<<"$cmd"; then
        reason="too-old"
    fi

    loop=$(grep -oE "(until|while) .{0,140}" <<<"$cmd" | head -1)
    [ -n "$loop" ] || loop=$(cut -c1-140 <<<"$cmd")
    printf '%-8s %5sm  %-10s %s\n         %s\n' "$parent" "$age_min" "${reason:-ok}" "$cwd" "$loop"
    if [ -n "$reason" ]; then
        found=$((found + 1))
        if [ "$kill_flagged" = 1 ]; then
            pkill -P "$parent" sleep 2>/dev/null
            kill "$parent" 2>/dev/null && echo "         killed $parent"
        fi
    fi
done

[ "$found" = 0 ] && exit 0
[ "$kill_flagged" = 1 ] && exit 0
exit 1
