#!/usr/bin/env bash
# Test of the scheduler's admission rule (front 163 s13), in a private pool: a small gate passes older full-pool
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
