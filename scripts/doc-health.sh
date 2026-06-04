#!/usr/bin/env bash
# doc-health.sh — documentation invariants checker (docs-refactor F4).
#
# Checks, repo-wide (tracked files only, worktrees in .tasks/ excluded):
#   1. orphan dirs       — every directory containing source files (.zig/.bp)
#                          has an AGENTS.md
#   2. broken links      — every relative markdown link in *.md resolves
#   3. volatile counters — AGENTS.md must not hardcode drifting counts
#                          (e.g. "164 .snap.md", "70 fixtures"); counts live nowhere
#
# Exit code: 0 = healthy, 1 = at least one violation (prints each one).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

fail=0
violation() {
    printf 'doc-health: %s\n' "$1" >&2
    fail=1
}

# ── 1. orphan dirs: source dirs without AGENTS.md ───────────────────────────
while IFS= read -r dir; do
    [ -f "$dir/AGENTS.md" ] || violation "orphan dir (no AGENTS.md): $dir"
done < <(git ls-files -- '*.zig' '*.bp' \
    | grep -v -e '^\.tasks/' -e '^zig-out/' \
    | xargs -r -n1 dirname | sort -u)

# ── 2. broken relative links in markdown ────────────────────────────────────
while IFS= read -r md; do
    dir=$(dirname "$md")
    # extract (target) of [text](target); skip absolute URLs and pure anchors
    while IFS= read -r target; do
        [ -n "$target" ] || continue
        case "$target" in
            http://* | https://* | mailto:* | /*) continue ;;
        esac
        [ -e "$dir/$target" ] || violation "broken link in $md → $target"
    done < <(grep -oE '\]\([^)#]+' "$md" 2>/dev/null | sed 's/^](//' || true)
done < <(git ls-files -- '*.md' | grep -v -e '^\.tasks/' -e '^zig-out/')

# ── 3. volatile counters in AGENTS.md ────────────────────────────────────────
# Patterns like "(164 .snap.md)", "← 140 AST snapshots", "**66 files**"
while IFS= read -r agents; do
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        violation "volatile counter in $agents: $line"
    done < <(grep -nE '(\(|← *|\*\* *)[0-9]{2,} +(\.[a-z.]+ +)?(files?|snapshots?|fixtures?|outputs?|tests?|lines)\b' \
        "$agents" 2>/dev/null || true)
done < <(git ls-files | grep -v '^\.tasks/' | grep -E '(^|/)AGENTS\.md$')

if [ "$fail" -eq 0 ]; then
    echo "doc-health: OK"
fi
exit "$fail"
