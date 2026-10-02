#!/usr/bin/env bash
# worktree-add.sh — open a task worktree of the meta repository, the one way
# (AGENTS.md § Worktrees).
#
# Usage:
#   scripts/worktree-add.sh <name> [<base>]
#
# 1. `git worktree add .tasks/<name> -b front/<name> <base>` (default base
#    `feat`), under the MAIN checkout whichever worktree this runs from;
# 2. `git submodule update --init --recursive` inside it;
# 3. `core.hooksPath scripts/git-hooks` in every submodule that tracks
#    `scripts/git-hooks/pre-commit`. A submodule of a worktree is a repository
#    of its own (its git directory lives under the worktree's), so nothing the
#    main checkout's submodules have configured reaches it: without this step
#    a commit there runs no hook at all — the gate that is not run;
# 4. `repository/botopink-lang` on a branch `front/<name>` at the pointer.
#
# Exit 0 when the worktree is ready; 1 when <name> is missing, the worktree or
# the branch exists, or a step fails (the step's own message is above).
set -euo pipefail

name="${1:-}"
base="${2:-feat}"
if [ -z "$name" ] || [ "$name" = "-h" ] || [ "$name" = "--help" ]; then
    sed -n '2,19p' "$0"
    [ -n "$name" ] && exit 0
    exit 1
fi

common="$(git rev-parse --path-format=absolute --git-common-dir)"
main="$(dirname "$common")"
wt="$main/.tasks/$name"
[ ! -e "$wt" ] || { echo "worktree-add: $wt exists" >&2; exit 1; }

git -C "$main" worktree add "$wt" -b "front/$name" "$base"
git -C "$wt" submodule update --init --recursive

hooked=""
while read -r _ sub; do
    [ -d "$wt/$sub" ] || continue
    if git -C "$wt/$sub" ls-files --error-unmatch scripts/git-hooks/pre-commit >/dev/null 2>&1; then
        git -C "$wt/$sub" config core.hooksPath scripts/git-hooks
        hooked="$hooked $sub"
    fi
done < <(git -C "$wt" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

git -C "$wt/repository/botopink-lang" checkout -q -b "front/$name"

echo "worktree-add: $wt on front/$name (repository/botopink-lang on front/$name)"
echo "worktree-add: core.hooksPath scripts/git-hooks in:${hooked:- (none)}"
