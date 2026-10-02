#!/usr/bin/env bash
# language-gap-markers.sh — every `// LANGUAGE GAP` marker names a row of the
# milestone's `language-gaps.md`, and the marker index there is exact.
#
# Usage:
#   scripts/language-gap-markers.sh        (from anywhere in the meta checkout)
#
# A MARKER is the literal `// LANGUAGE GAP` in a tracked `.bp` file: the line a
# library front (or a front's `examples/`) writes where the language has no
# spelling and the nearest valid form stands in. Prose that talks about markers
# (`*.md`) is not one. The script reads
#   · every repository under `repository/` (the paths of `.gitmodules`), and
#   · the meta repository itself, except the spec trees of closed milestones
#     (`specs/<older>/**` — frozen; today that is what leaves `specs/1.0.10-beta`
#     out).
# The milestone is the newest `specs/<version>/` that holds a `language-gaps.md`.
#
# The file's `## Marker index` table is what a marker is checked against, one
# row per file that holds a marker:
#
#   | `<path from the meta root>` | <markers in the file> | **<gap row>** · … |
#
# Exit 1, naming each offender, when
#   · a file holds a marker and has no index row      (write the gap row, then
#                                                      the index row)
#   · an index row's count is not the file's count    (a marker was added or
#                                                      removed: re-read the file)
#   · an index row names a gap row the tables no
#     longer hold                                     (the gap closed: delete the
#                                                      marker, then the index row)
#   · an index row's file holds no marker             (stale: delete the row)
#   · a repository under `repository/` is not
#     checked out                                     (nothing was read: `git
#                                                      submodule update --init`)
# Exit 0 otherwise, after printing every marker. No flag, variable or list
# exempts a marker or a file (decision 67).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MARK='// LANGUAGE GAP'

# ── the milestone ────────────────────────────────────────────────────────────
milestone=""
while IFS= read -r dir; do
    [ -f "$dir/language-gaps.md" ] && milestone="$dir"
done < <(find specs -mindepth 1 -maxdepth 1 -type d | sort -V)
if [ -z "$milestone" ]; then
    echo "language-gap-markers: no specs/<version>/language-gaps.md in this checkout" >&2
    exit 1
fi
gaps="$milestone/language-gaps.md"

# ── the markers ──────────────────────────────────────────────────────────────
# One `<path from the meta root>:<line>:<text>` line per marker.
status=0
markers="$(mktemp)"
index="$(mktemp)"
rows="$(mktemp)"
trap 'rm -f "$markers" "$index" "$rows"' EXIT
# markers_of <file> — the marker lines of exactly that file.
markers_of() { awk -F: -v f="$1" '$1 == f' "$markers"; }

# The meta repository: every tracked `.bp`, the closed milestones' trees left out.
excludes=()
while IFS= read -r dir; do
    [ "$dir" = "$milestone" ] || excludes+=(":!$dir")
done < <(find specs -mindepth 1 -maxdepth 1 -type d | sort -V)
git grep -n -I -F -e "$MARK" -- '*.bp' "${excludes[@]}" >>"$markers" || true

# Every repository under repository/.
repos="$(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{ print $2 }' | sort)"
if [ -z "$repos" ]; then
    echo "language-gap-markers: .gitmodules names no repository" >&2
    exit 1
fi
for repo in $repos; do
    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
        [ "$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" != "$PWD/$repo" ]; then
        echo "language-gap-markers: $repo is not checked out — nothing was read there (git submodule update --init)" >&2
        status=1
        continue
    fi
    { git -C "$repo" grep -n -I -F -e "$MARK" -- '*.bp' || true; } | sed "s|^|$repo/|" >>"$markers"
done

# ── the index ────────────────────────────────────────────────────────────────
# One `<path>\t<count>\t<named rows, each **…**>` line per index row.
awk '
    /^## / { in_index = ($0 ~ /^## Marker index/) }
    in_index && /^\| `[^`]+\.bp` \|/ {
        n = split($0, cell, " \\| ")
        path = cell[1]; sub(/^\| `/, "", path); sub(/`$/, "", path)
        count = cell[2]; gsub(/[^0-9]/, "", count)
        rows = cell[3]; sub(/ \|$/, "", rows)
        printf "%s\t%s\t%s\n", path, count, rows
    }
' "$gaps" >"$index"

# The gap rows themselves: every table line outside the index that starts
# `| **<gap>**`. An index row is checked against these and never against itself.
awk '
    /^## / { in_index = ($0 ~ /^## Marker index/) }
    !in_index && /^\| \*\*/
' "$gaps" >"$rows"
# has_row <gap> — a gap row whose title is exactly `**<gap>**`.
has_row() { awk -v want="| **$1**" 'index($0, want) == 1 { found = 1; exit } END { exit found ? 0 : 1 }' "$rows"; }

if ! grep -q '^## Marker index' "$gaps"; then
    echo "language-gap-markers: $gaps has no \`## Marker index\` section" >&2
    status=1
fi

# ── report every marker ──────────────────────────────────────────────────────
total="$(grep -c . "$markers" || true)"
files="$(cut -d: -f1 "$markers" | sort -u | grep -c . || true)"
sed 's/^/  /' "$markers"

# ── check ────────────────────────────────────────────────────────────────────
while IFS= read -r file; do
    [ -n "$file" ] || continue
    count="$(markers_of "$file" | grep -c . || true)"
    row="$(awk -F '\t' -v f="$file" '$1 == f { print; exit }' "$index")"
    if [ -z "$row" ]; then
        status=1
        echo "language-gap-markers: no row for the $count marker(s) in $file:" >&2
        markers_of "$file" | sed 's/^/    /' >&2
        echo "    → write the gap's row in $gaps, then the file's row in its \`## Marker index\`" >&2
        continue
    fi
    listed="$(printf '%s' "$row" | cut -f2)"
    if [ "$listed" != "$count" ]; then
        status=1
        echo "language-gap-markers: $file holds $count marker(s), its index row says ${listed:-nothing}:" >&2
        markers_of "$file" | sed 's/^/    /' >&2
        echo "    → a marker was added or removed; make the index row of $gaps say what the file holds" >&2
    fi
done < <(cut -d: -f1 "$markers" | sort -u)

while IFS=$'\t' read -r file listed named; do
    [ -n "$file" ] || continue
    if [ -z "$(markers_of "$file")" ]; then
        status=1
        echo "language-gap-markers: stale index row — $file holds no marker" >&2
        echo "    → delete its row in the \`## Marker index\` of $gaps" >&2
        continue
    fi
    # Every **gap** the row names must still be a row of the tables: a line
    # that starts `| **<gap>**`.
    rest="$named"
    any=0
    while [[ "$rest" == *'**'*'**'* ]]; do
        rest="${rest#*\*\*}"
        gap="${rest%%\*\**}"
        rest="${rest#*\*\*}"
        any=1
        if ! has_row "$gap"; then
            status=1
            echo "language-gap-markers: $file names the row **$gap**, which $gaps does not hold:" >&2
            markers_of "$file" | sed 's/^/    /' >&2
            echo "    → the gap closed: delete the marker; or the row was renamed: name it as the table spells it" >&2
        fi
    done
    if [ "$any" -eq 0 ]; then
        status=1
        echo "language-gap-markers: the index row of $file names no gap row (want **<gap>** in its third cell)" >&2
    fi
done <"$index"

if [ "$status" -ne 0 ]; then
    echo "language-gap-markers: FAILED — $total marker(s) in $files file(s) read against $gaps" >&2
    exit 1
fi
echo "language-gap-markers: $total marker(s) in $files file(s), every one names a row of $gaps"
