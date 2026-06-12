# module-auto-tag — auto-tag compiler-core, compiler-cli, vscode-extension on push

**Slug**: module-auto-tag
**Depends on**: nothing (sibling of [`lib-test-workflows`](lib-test-workflows.md) §"auto-tag")
**Files**: `repository/botopink-lang/.github/workflows/tag.yml` (path-scoped over `modules/compiler-core/` + `modules/compiler-cli/`), `repository/vscode-extension/.github/workflows/tag.yml`, three new `botopink.json` files: `repository/botopink-lang/modules/compiler-core/botopink.json`, `repository/botopink-lang/modules/compiler-cli/botopink.json`, `repository/vscode-extension/botopink.json`
**Touches docs**: `repository/botopink-lang/modules/compiler-core/AGENTS.md` (Tagging section), `repository/botopink-lang/modules/compiler-cli/AGENTS.md` (Tagging section), `repository/vscode-extension/AGENTS.md` (Tagging section), this set's `README.md`
**Status**: pending

## Problem

[`lib-test-workflows`](lib-test-workflows.md) §"auto-tag" gives the four
framework libs an auto-tag-on-push contract. Three more units in the v0.beta.18
workspace want the same lifecycle:

| Unit | Lives in | Why it wants its own tags |
|---|---|---|
| `compiler-core` | `repository/botopink-lang/modules/compiler-core/` (a subtree) | The compiler's internal API changes independently of the CLI surface; pinning a feat/stable label to compiler-core lets the language server and bpmp know which API they were built against |
| `compiler-cli` | `repository/botopink-lang/modules/compiler-cli/` (a subtree) | The CLI flags + driver evolve independently of the core; bpmp's "compiler version" constraint is best satisfied by tagging the CLI explicitly |
| `vscode-extension` | `repository/vscode-extension/` (own repo, but already has `package.json`) | The extension cuts its own marketplace releases; tagging on push gives the `.vsix` publish workflow ([`release-workflows`](release-workflows.md)) a reliable trigger |

Eric's instruction (verbatim):

> crie tags automaticas ao subir
>   repository/botopink-lang/modules/compiler-core
>   repository/botopink-lang/modules/compiler-cli
>   repository/vscode-extension
> 0.0.1-feat — se já existir atualiza a tag
> para master e main 0.0.1
> exigir que se avance uma versão
> observe o version dentro de botopink.json

Two new wrinkles vs. lib-test-workflows §"auto-tag":

1. **Two of the three units live inside botopink-lang.** A single `tag.yml`
   in that repo must iterate over both subtrees, and tags must be **prefixed
   by the unit name** to avoid collision with the human-driven `v*` tags
   ([`release-workflows`](release-workflows.md)).
2. **One unit (vscode-extension) already has `package.json`** carrying its
   own `version`. Per Eric's explicit instruction, the auto-tag workflow
   reads from `botopink.json` — uniform across all seven taggable units in
   v0.beta.18. So vscode-extension gains a minimal `botopink.json`
   alongside its `package.json`. Keeping the two in sync is the
   maintainer's discipline (and a separate spec can add a pre-commit
   check); the auto-tag workflow only reads `botopink.json`.

## Target — tag conventions

| Unit | Branch pushed to | Tag created | Mutability |
|---|---|---|---|
| `compiler-core` | `feat` | `compiler-core/<version>-feat` | moving |
| `compiler-core` | `master`/`main` | `compiler-core/<version>` | immutable; require version bump |
| `compiler-cli` | `feat` | `compiler-cli/<version>-feat` | moving |
| `compiler-cli` | `master`/`main` | `compiler-cli/<version>` | immutable; require version bump |
| `vscode-extension` | `feat` | `<version>-feat` | moving |
| `vscode-extension` | `master`/`main` | `<version>` | immutable; require version bump |

**Why the prefix on the botopink-lang subtrees and not on vscode-extension?**
vscode-extension is its own repo — its tag namespace is private. The
botopink-lang repo already carries human-driven `v0.0.1`-style tags for the
whole-workspace releases; the subtree tags must not collide. Prefixing them
`compiler-core/…` / `compiler-cli/…` keeps the three tag families
unambiguous in `git tag --list`.

## Target — `botopink.json` per unit

Each tagged unit grows a minimal `botopink.json` whose **only required
field is `version`**:

```jsonc
// repository/botopink-lang/modules/compiler-core/botopink.json
{ "name": "compiler-core", "version": "0.0.1" }

// repository/botopink-lang/modules/compiler-cli/botopink.json
{ "name": "compiler-cli",  "version": "0.0.1" }

// repository/vscode-extension/botopink.json
{ "name": "vscode-extension", "version": "0.3.0" }       // mirror package.json's current value at the time the spec lands
```

`name` is informational (used in the tag job's log lines, never in the tag
itself — the tag uses the directory's short name). The compiler does not
load these as packages (`compiler-core` and `compiler-cli` carry no `files`
array — they're not lib packages, they're internal modules); the file
exists **only** for the auto-tag workflow and any future tooling that wants
to read "what version is this thing today" without spelunking `build.zig.zon`
or `package.json`.

vscode-extension's `botopink.json.version` must stay equal to its
`package.json.version`. F4 below adds a pre-commit-hook-style CI check
inside vscode-extension's `test.yml` that fails if they drift.

## Target — `tag.yml` in botopink-lang (path-scoped, iterates two units)

### Trigger

```yaml
on:
  push:
    branches: [feat, master, main]
    paths:
      - 'modules/compiler-core/**'
      - 'modules/compiler-cli/**'
```

The `paths` filter ensures the workflow only fires when one of the two
subtrees changes. A push that touches *only* `libs/std/` (for example) does
not run this workflow at all.

### Logic — per unit

The job iterates over a static matrix of `(unit, path)` pairs. For each, it:

1. Checks whether the *push* (range `${{ github.event.before }}..${{ github.sha }}`)
   touched the unit's path. If not, skip this unit silently.
2. Reads `<unit-path>/botopink.json` → `version`.
3. Computes the tag: `<unit>/${version}` for master/main, `<unit>/${version}-feat`
   for feat.
4. Applies the create-or-move rule (identical to
   [`lib-test-workflows`](lib-test-workflows.md) §"tag.yml": force-move on
   feat, immutable on master/main, version-bump required to publish).

```yaml
jobs:
  tag:
    runs-on: ubuntu-22.04
    permissions:
      contents: write
    strategy:
      fail-fast: false
      matrix:
        include:
          - unit: compiler-core; path: modules/compiler-core
          - unit: compiler-cli;  path: modules/compiler-cli
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Did this unit change in the pushed range?
        id: scope
        run: |
          before=${{ github.event.before }}
          after=${{ github.sha }}
          # On a fresh branch, before is all-zeros — treat as "yes, fire"
          if [ "$before" = "0000000000000000000000000000000000000000" ]; then
            echo "changed=1" >> "$GITHUB_OUTPUT"
          elif ! git diff --quiet "$before" "$after" -- ${{ matrix.path }}; then
            echo "changed=1" >> "$GITHUB_OUTPUT"
          else
            echo "changed=0" >> "$GITHUB_OUTPUT"
          fi

      - name: Read version
        if: steps.scope.outputs.changed == '1'
        id: ver
        run: |
          ver=$(jq -r .version ${{ matrix.path }}/botopink.json)
          if [ -z "$ver" ] || [ "$ver" = "null" ]; then
            echo "::error::${{ matrix.path }}/botopink.json missing 'version'"
            exit 1
          fi
          echo "version=$ver" >> "$GITHUB_OUTPUT"

      - name: Compute tag
        if: steps.scope.outputs.changed == '1'
        id: tag
        run: |
          branch=${GITHUB_REF_NAME}
          ver=${{ steps.ver.outputs.version }}
          case "$branch" in
            feat)         tag="${{ matrix.unit }}/${ver}-feat" ; mutable=1 ;;
            master|main)  tag="${{ matrix.unit }}/${ver}"      ; mutable=0 ;;
            *) exit 1 ;;
          esac
          echo "tag=$tag"        >> "$GITHUB_OUTPUT"
          echo "mutable=$mutable" >> "$GITHUB_OUTPUT"

      - name: Create or move tag
        if: steps.scope.outputs.changed == '1'
        env:
          GIT_AUTHOR_NAME: botopink-auto-tag
          GIT_AUTHOR_EMAIL: noreply@botopink.dev
          GIT_COMMITTER_NAME: botopink-auto-tag
          GIT_COMMITTER_EMAIL: noreply@botopink.dev
        run: |
          tag=${{ steps.tag.outputs.tag }}
          mutable=${{ steps.tag.outputs.mutable }}
          if git rev-parse "refs/tags/$tag" >/dev/null 2>&1; then
            if [ "$mutable" = "1" ]; then
              git tag -f "$tag" "$GITHUB_SHA"
              git push --force origin "refs/tags/$tag"
            else
              existing=$(git rev-list -n 1 "refs/tags/$tag")
              if [ "$existing" = "$GITHUB_SHA" ]; then
                echo "tag $tag already at $GITHUB_SHA — no-op"
                exit 0
              fi
              echo "::error::tag $tag already exists at $existing — bump '${{ matrix.path }}/botopink.json' version to publish"
              exit 1
            fi
          else
            git tag "$tag" "$GITHUB_SHA"
            git push origin "refs/tags/$tag"
          fi
```

## Target — `tag.yml` in vscode-extension (single unit, full repo)

Structurally identical to
[`lib-test-workflows`](lib-test-workflows.md) §"tag.yml": single matrix
entry, no path filter (every push to the extension repo is in-scope), tag
uses no prefix (own repo, own namespace). The only difference vs. the lib
spec: `tag.yml` runs alongside `release.yml`
([`release-workflows`](release-workflows.md)), and a successful
`master`/`main` tag will subsequently trigger that release workflow
(which is gated on `v*` tags — see Notes for the naming choice).

```yaml
# repository/vscode-extension/.github/workflows/tag.yml
on:
  push:
    branches: [feat, master, main]
jobs:
  tag:
    runs-on: ubuntu-22.04
    permissions: { contents: write }
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Read version
        id: ver
        run: |
          ver=$(jq -r .version botopink.json)
          [ -z "$ver" ] || [ "$ver" = "null" ] && { echo "::error::missing version"; exit 1; }
          # consistency check vs package.json
          pkg=$(jq -r .version package.json)
          if [ "$ver" != "$pkg" ]; then
            echo "::error::botopink.json version ($ver) != package.json version ($pkg)"
            exit 1
          fi
          echo "version=$ver" >> "$GITHUB_OUTPUT"
      - name: Compute + apply tag
        # … same compute + create-or-move steps as the botopink-lang job above,
        # but tag = "${ver}-feat" / "${ver}" (no prefix).
```

The drift check between `botopink.json` and `package.json` is run **here**
on every push (not as a separate test job) — it's cheap and the failure
mode is exactly the same as the version-bump-required check
(maintainer must fix the manifest).

## Examples

### push to feat, only compiler-core changes
```bash
$ git push origin feat   # head touches modules/compiler-core/src/parser.zig
# tag.yml fires (paths filter matched modules/compiler-core/**).
# matrix entry compiler-core: scope check → changed=1 → version 0.0.1 → tag = compiler-core/0.0.1-feat
#   tag exists from previous push, force-moves to new HEAD
# matrix entry compiler-cli: scope check → changed=0 → SKIPPED silently
```

### push to feat, both compiler-core and compiler-cli change
```bash
$ git push origin feat   # head touches both subtrees
# tag.yml fires.
# both matrix entries: changed=1 → each force-moves its own moving tag.
# end state: compiler-core/0.0.1-feat AND compiler-cli/0.0.1-feat both at new HEAD.
```

### push to master without version bump
```bash
$ git push origin master   # touched modules/compiler-cli/, version still 0.0.1, tag exists
# compiler-cli matrix entry → changed=1 → tag compiler-cli/0.0.1 exists at the previous SHA → ERROR
# the workflow exits red. Maintainer must bump modules/compiler-cli/botopink.json version → push again.
```

### push to vscode-extension with mismatched package.json/botopink.json
```bash
$ git push origin master
# vscode-extension tag.yml runs.
# botopink.json says 0.3.1, package.json says 0.3.0 (forgot to bump one).
# Workflow exits red with the diff. Maintainer fixes both → push again.
```

### git tag --list after a few pushes
```
$ git tag --list | sort
# in botopink-lang:
compiler-cli/0.0.1
compiler-cli/0.0.1-feat
compiler-core/0.0.1
compiler-core/0.0.1-feat
v0.0.1                          # the whole-workspace release tag (release-workflows.md, human-driven)

# in vscode-extension:
0.3.0
0.3.0-feat
```

## Steps

### F0 — add `botopink.json` to the three units
- [ ] `repository/botopink-lang/modules/compiler-core/botopink.json` →
      `{ "name": "compiler-core", "version": "0.0.1" }`.
- [ ] `repository/botopink-lang/modules/compiler-cli/botopink.json` →
      `{ "name": "compiler-cli", "version": "0.0.1" }`.
- [ ] `repository/vscode-extension/botopink.json` →
      `{ "name": "vscode-extension", "version": "<current package.json version>" }`.
- [ ] Each unit's `AGENTS.md` gains a "Tagging" subsection explaining the
      single-source-of-truth rule and how to bump (edit `botopink.json`
      `version` in the same PR that lands the changes you want
      tagged). vscode-extension's section also instructs the maintainer
      to bump `package.json` in the same edit.

### F1 — tag.yml in botopink-lang
- [ ] Author `repository/botopink-lang/.github/workflows/tag.yml` per
      the shape above. Paths filter on the two subtrees;
      matrix-driven per-unit job.
- [ ] Smoke-test by pushing a no-op `modules/compiler-core/` change to
      a fresh feat branch in a fork. Verify only compiler-core gets
      tagged; compiler-cli is skipped.

### F2 — tag.yml in vscode-extension
- [ ] Author `repository/vscode-extension/.github/workflows/tag.yml`
      with the embedded package.json drift check.
- [ ] Smoke-test similarly.

### F3 — docs
- [ ] This set's `README.md` Scope table gains a row for
      `module-auto-tag`.
- [ ] Each tagged unit's `AGENTS.md` documents the tag prefix
      (compiler-core: `compiler-core/<ver>[-feat]`, etc.) and the
      "bump to publish" discipline.

## Test scenarios

```
fil   ---- push touching only libs/std/: tag.yml does NOT fire (paths filter)
fil   ---- push touching modules/compiler-core/ only: compiler-core tagged, compiler-cli skipped
fil   ---- push touching both: both units tagged
fil   ---- push touching modules/lib-test-runner/: tag.yml does NOT fire (not in paths)
tag   ---- compiler-core feat tag is moving — force-updated on each push
tag   ---- compiler-core master tag is immutable — re-push without bump errors
tag   ---- compiler-core master tag idempotent — re-push of same SHA is a no-op
tag   ---- compiler-cli has its own tag namespace — does not collide with compiler-core
tag   ---- workspace `v*` tags coexist with compiler-{core,cli}/<ver> tags without conflict
vsx   ---- vscode-extension master tag pushed: tag <ver> created
vsx   ---- vscode-extension push with botopink.json/package.json drift → red
git   ---- git tag --list after a few pushes contains all three families cleanly
```

## Notes

- **Why path-scoped instead of one workflow per subtree?** A single
  workflow file is shorter to maintain than two, and the matrix
  pattern scales when a fourth subtree (`language-server`,
  `lib-test-runner`?) wants its own tags later — one matrix entry, no
  new file.
- **Why prefix `compiler-core/` not `compiler-core@`?** Git allows
  `/` in tag names (and they sort hierarchically in
  `git tag --list compiler-core/*`); `@` is reserved in some shells'
  globs. Slash matches Lerna's monorepo convention.
- **Why not auto-tag `language-server` and `lib-test-runner`?** Eric
  did not include them. Both ship as part of the workspace release
  (`v*` human-driven tags + the release-workflows pipeline). When/if
  they want their own lifecycle, this spec's matrix gains a row.
  No new spec, no new workflow file.
- **vscode-extension's release pipeline.**
  [`release-workflows`](release-workflows.md) §"Target —
  vscode-extension" triggers on `v*` tags. The `<version>` tag this
  spec creates is **not** prefixed with `v` — so it does not trigger
  the release workflow by itself. Two options:
  (a) Manually push `v<version>` after the auto-tag, when the
  maintainer wants a marketplace publish.
  (b) Adjust `release-workflows.md` §"vscode-extension release.yml"
  to trigger on **either** `v*` or `<numeric>*` tags. (b) is a
  one-line trigger change; left for the maintainer to choose at
  implementation time. Documented here so the choice is explicit.
- **Why no `tag.yml` on botopink-lang for the whole workspace?**
  Workspace releases are deliberate (a human types `git tag v0.0.1`
  per [`release-workflows`](release-workflows.md)). Auto-tagging the
  whole workspace would conflict with that intent.
- **Cross-spec coordination.**
  - [`lib-test-workflows`](lib-test-workflows.md) §"auto-tag" — uses
    the same create-or-move logic; the spec here mirrors it for the
    three internal units.
  - [`release-workflows`](release-workflows.md) — see the
    vscode-extension trigger note above.
  - [`bpmp`](bpmp.md) — does **not** consume `compiler-core/*` or
    `compiler-cli/*` tags directly. bpmp's compiler-version
    constraint is satisfied by the workspace's `v*` releases, not by
    the per-module tags. The per-module tags are observability
    metadata + future-tooling hooks, not bpmp's resolution input.
