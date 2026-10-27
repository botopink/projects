#!/usr/bin/env bash
# Test of the scheduler's admission rule (front 163 s13, decision 1042), in a private pool: a small gate passes older full-pool
# waiters while the pool is busy, and the full-pool gates still start one at a time on an empty pool, in order.
#
# Usage: scripts/gate-test.sh
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"
trap 'jobs -p | xargs -r kill 2>/dev/null || true; rm -rf "$tmp"' EXIT
export XDG_RUNTIME_DIR="$tmp"          # the pool becomes $tmp/botopink-gate-pool, never the machine's
export BOTOPINK_POOL_CAPACITY=3 BOTOPINK_POOL_STAGGER=0
log="$tmp/events"; : >"$log"
run() { # <name> <jobs> <seconds>
    "$here/gate.sh" exec --jobs "$2" "$1" -- bash -c "echo \"start $1 \$(date +%s.%N)\" >>'$log'; sleep $3; echo \"end $1 \$(date +%s.%N)\" >>'$log'" &
    sleep 0.5
}
run R 1 7      # runs, holds 1 of 3
run A 3 2      # full-pool, waits
run B 3 2      # full-pool, waits
run C 1 2      # small, newest: may pass A and B
wait
t() { awk -v k="$1 $2" '$1" "$2 == k { print $3 }' "$log"; }
lt() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'; }
fail() { echo "FAIL: $1" >&2; cat "$log" >&2; exit 1; }
lt "$(t start C)" "$(t end R)" || fail "C was not admitted while R ran"
lt "$(t start C)" "$(t start A)" || fail "C did not pass A"
lt "$(t end R)" "$(t start A)" || fail "A started before the pool drained"
lt "$(t end C)" "$(t start A)" || fail "A started before C ended"
lt "$(t end A)" "$(t start B)" || fail "B started before A ended"

# A lease released while another gate scans the pool (163, the release race): R ends during W's scan, which pauses
# between finding R's lease and reading it; the release waits for the lock, so the scan never reads a vanished lease.
err="$tmp/race-err"; : >"$err"
BOTOPINK_POOL_SCAN_DELAY=2 "$here/gate.sh" exec --jobs 1 R2 -- sleep 1 2>>"$err" &
sleep 0.3
BOTOPINK_POOL_SCAN_DELAY=2 "$here/gate.sh" exec --jobs 3 W2 -- true 2>>"$err" &
wait
[ ! -s "$err" ] || { cat "$err" >&2; fail "a scan read a lease released mid-scan"; }

# The stagger holds heavy admissions only (decision 1042): with capacity 4 and a 4 s stagger, a 1-job run is admitted
# at once while another holds a job; a run asking for half the capacity, and a `zig build` of one job, each wait the
# stagger after the last admission.
: >"$log"
srun() { # <name> <jobs> <seconds> [command text]
    BOTOPINK_POOL_CAPACITY=4 BOTOPINK_POOL_STAGGER=4 "$here/gate.sh" exec --jobs "$2" "$1" -- bash -c "echo \"start $1 \$(date +%s.%N)\" >>'$log'; sleep $3; echo \"end $1 \$(date +%s.%N)\" >>'$log' ${4:+; : $4}" &
}
srun L1 1 8; sleep 0.5
srun L2 1 1; sleep 1.5
srun H 2 1; sleep 0.5
wait
srun L3 1 8; sleep 0.5
srun Z 1 1 "zig build"
wait
since() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.3f", b - a }'; }
lt "$(t start L2)" "$(t end L1)" || fail "a light run waited while jobs were free"
lt "$(since "$(t start L1)" "$(t start L2)")" 2 || fail "a light run was staggered"
lt 3.5 "$(since "$(t start L2)" "$(t start H)")" || fail "a half-capacity run was not staggered"
lt 3.5 "$(since "$(t start L3)" "$(t start Z)")" || fail "a zig build was not staggered"
# Nothing an `exec` starts outlives it (decision 1061 (1)): the command spawns a sleeping grandchild; `exec` is killed
# with TERM, then with KILL, and no process of the command's session is left. The session is read from the pid the
# command writes, never from a pattern.
orphans() { # <pidfile> — live (not zombie) processes in the session of the pid in the file
    local sid; sid="$(cat "$1")"
    ps -eo sid=,stat= | awk -v s="$sid" '$1 == s && $2 !~ /^Z/ { n++ } END { print n + 0 }'
}
for sig in TERM KILL; do
    pf="$tmp/grand.$sig"; rm -f "$pf"
    BOTOPINK_GROUP_GRACE=2 "$here/gate.sh" exec --jobs 1 G"$sig" -- bash -c "sleep 300 & echo \$\$ >'$pf'; wait" &
    gpid=$!
    for _ in $(seq 50); do [ -s "$pf" ] && break; sleep 0.1; done
    [ -s "$pf" ] || fail "the $sig exec's command did not start"
    [ "$(orphans "$pf")" -ge 2 ] || fail "the $sig exec's session has no grandchild"
    kill -"$sig" "$gpid"; wait "$gpid" 2>/dev/null || true
    for _ in $(seq 60); do [ "$(orphans "$pf")" -eq 0 ] && break; sleep 0.1; done
    [ "$(orphans "$pf")" -eq 0 ] || fail "$sig on exec left processes of its session"
done
# A command that ends normally leaves nothing either: its backgrounded child is swept.
pf="$tmp/grand.end"; rm -f "$pf"
BOTOPINK_GROUP_GRACE=1 "$here/gate.sh" exec --jobs 1 Gend -- bash -c "sleep 300 & echo \$\$ >'$pf'"
[ "$(orphans "$pf")" -eq 0 ] || fail "a finished command left a process in its session"
# machine-1's refusals (decisions 768, 769, 1002 (c)): a whole-suite conformance run is refused before taking a job, one
# module by its own path and a suite by --only pass. `echo` stands for the command: a passing line only has to run.
cfg="$tmp/cfg"; mkdir -p "$cfg/botopink"; echo machine-1 >"$cfg/botopink/machine"
refused() { local o; o="$(XDG_CONFIG_HOME="$cfg" "$here/gate.sh" exec t -- bash -c ": # $1" 2>&1)" && fail "not refused: $1"; case "$o" in *"machine 2's"*|*"--no-conformance"*) ;; *) fail "refused for another reason: $1";; esac; }
allowed() { XDG_CONFIG_HOME="$cfg" "$here/gate.sh" exec t -- bash -c ": # $1" >/dev/null 2>&1 || fail "refused: $1"; }
refused "conformance/run.sh"
refused "conformance/run.sh --target erlang"
refused "./run.sh --jobs 4"
refused "conformance/run.sh --only modules"
refused "conformance/run.sh --only conformance/modules/"
refused "conformance/run.sh --only test/case_arms.bp --only modules"
refused "scripts/gate.sh --stage test-conformance"
refused "zig build test-conformance"
refused "zig build -Doptimize=ReleaseSafe test-conformance"
refused "botopink cell check conformance/"
refused "scripts/gate.sh"
allowed "conformance/run.sh --list"
allowed "conformance/run.sh --self-test"
allowed "conformance/run.sh --only test/case_arms.bp"
allowed "conformance/run.sh --only modules/foo"
allowed "cd conformance/modules/foo && botopink run --target erlang"
allowed "scripts/gate.sh --no-conformance"
allowed "scripts/gate.sh --staged --no-conformance"
allowed "zig build test"
echo "ok: gate-test"
