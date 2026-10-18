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
echo "ok: gate-test"
