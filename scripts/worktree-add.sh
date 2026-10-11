#!/usr/bin/env bash
# worktree-add.sh — open a task worktree of the meta repository, the one way
# (AGENTS.md § Worktrees).
#
# Usage:
#   scripts/worktree-add.sh <name> [<base>]
#   scripts/worktree-add.sh --repo <repo> <name> [<base>]
#   scripts/worktree-add.sh --lang <name> [<base>]      (= --repo botopink-lang)
#
# Full (no --repo): a task that edits the meta specs or several repositories.
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
# --repo <repo>: a task that changes `repository/<repo>` alone. No meta branch
# and no clone: `.tasks/<name>/repository/<repo>` is a git worktree of the main
# checkout's submodule on `front/<name>` from its remote `feat` (default base
# `origin/feat`), and every other submodule path is a symlink to the main
# checkout's. `.tasks/<name>` holds `repository/`, so the compiler's library
# walk-up (`manifest.isCheckoutRoot`) and a library hook's `locateBotopink`
# stop there: a library task uses the MAIN checkout's compiler
# (`repository/botopink-lang/zig-out/bin/botopink`, kept at remote `feat` and
# built by the coordinator at each compiler landing; `source_stamp` refuses it
# when its sources changed since), and `test-libs` sees the same libraries as
# a full worktree. The hook is the repository's own (a worktree shares its
# repository's config, where `core.hooksPath scripts/git-hooks` is set). The
# coordinator writes the specs and the pointer bump at landing. Remove with
#   git -C repository/<repo> worktree remove .tasks/<name>/repository/<repo> && rm -r .tasks/<name>
#
# Exit 0 when the worktree is ready; 1 when <name> is missing, the worktree or
# the branch exists, or a step fails (the step's own message is above).
set -euo pipefail

repo=""
case "${1:-}" in
    --lang) repo="botopink-lang"; shift ;;
    --repo) repo="${2:-}"; shift 2 || true
            [ -n "$repo" ] || { echo "worktree-add: --repo needs a repository name" >&2; exit 1; } ;;
esac
name="${1:-}"
if [ -z "$name" ] || [ "$name" = "-h" ] || [ "$name" = "--help" ]; then
    sed -n '2,38p' "$0"
    [ -n "$name" ] && exit 0
    exit 1
fi

common="$(git rev-parse --path-format=absolute --git-common-dir)"
main="$(dirname "$common")"
wt="$main/.tasks/$name"
[ ! -e "$wt" ] || { echo "worktree-add: $wt exists" >&2; exit 1; }

if [ -n "$repo" ]; then
    base="${2:-origin/feat}"
    sub="$main/repository/$repo"
    [ -d "$sub" ] || { echo "worktree-add: no repository/$repo in the main checkout" >&2; exit 1; }
    git -C "$sub" fetch -q origin
    if git -C "$sub" ls-files --error-unmatch scripts/git-hooks/pre-commit >/dev/null 2>&1; then
        git -C "$sub" config core.hooksPath scripts/git-hooks
    fi
    mkdir -p "$wt/repository"
    git -C "$sub" worktree add -q "$wt/repository/$repo" -b "front/$name" "$base"
    linked=""
    while read -r _ path; do
        [ "$path" = "repository/$repo" ] && continue
        [ -e "$main/$path" ] || continue
        ln -s "$main/$path" "$wt/$path"
        linked="$linked ${path#repository/}"
    done < <(git -C "$main" config -f .gitmodules --get-regexp '^submodule\..*\.path$')
    echo "worktree-add: $wt/repository/$repo on front/$name from $base (worktree of the submodule)"
    echo "worktree-add: hooks: $(git -C "$wt/repository/$repo" config --get core.hooksPath || echo NONE)"
    echo "worktree-add: linked from the main checkout:${linked:- (none)}"
    if [ "$repo" != "botopink-lang" ] && [ ! -x "$main/repository/botopink-lang/zig-out/bin/botopink" ]; then
        echo "worktree-add: note — the main checkout's compiler is not built (repository/botopink-lang/zig-out/bin/botopink): the coordinator builds it before the task's gate" >&2
    fi
    exit 0
fi

base="${2:-feat}"

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
