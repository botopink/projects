# lib-test-workflows — per-platform CI + auto-tagging for the four framework lib repos

**Slug**: lib-test-workflows
**Depends on**: nothing (release-workflows is helpful but not required — see Notes)
**Files**: `.github/workflows/test.yml` + `.github/workflows/tag.yml` inside each of `repository/erika/`, `repository/jhonstart/`, `repository/onze/`, `repository/rakun/` (8 files total); per-repo `AGENTS.md` updates
**Touches docs**: each lib repo's `AGENTS.md` (CI section), each lib repo's `README.md` (badge), this set's `README.md`
**Status**: pending

## Problem

Two unrelated needs, sharing the same four repos and the same workflow
infrastructure (`.github/workflows/`). Folding both into one spec keeps the
"things that touch the four lib repos in v0.beta.18" footprint clean.

### Need 1 — per-platform CI

Today none of `erika`, `jhonstart`, `onze`, `rakun` runs CI in its own
repo. Tests are exercised only as part of botopink-lang's `zig build
test-libs`, which means a regression in a lib repo's `feat` branch is
silent until somebody runs the workspace-wide gate. Each lib repo needs
a per-platform test workflow that runs on every push and PR, against a
known version of botopink-lang (the bootstrap path) so its CI matrix is
self-contained.

### Need 2 — auto-tagging on push

Per Eric (multiple iterations):

> crie tags automaticas ao subir repository/erika repository/jhonstart
> repository/onze repository/rakun
> 0.0.1-feat para master e main 0.0.1
> observe o version dentro de botopink.json

So every push triggers a tag creation step whose target is read from
the lib's `botopink.json` `version` field. The convention:

| Branch pushed to | Tag created | Mutability | Use |
|---|---|---|---|
| `feat` | `<version>-feat` | **moving** — force-updated | bpmp `@feat` spec resolves here |
| `master` *or* `main` | `<version>` | **immutable** — re-run is a no-op | bpmp `@<version>` and stable-tag resolution |

`<version>` is the literal value of `version` in the lib's
`botopink.json` at the **commit being tagged**. This means:

- A push that does not bump `version` to a master branch where a tag
  for that version already exists is a no-op (warns, exits 0). To
  publish, bump `version` in `botopink.json` in the same PR that lands
  the changes.
- A push to `feat` re-points the moving `<version>-feat` tag at the
  new HEAD. SemVer pre-release ordering ensures bpmp picks the stable
  `<version>` tag over the `<version>-feat` tag by default; users
  opt in to feat via `requires.<lib> = "feat"`.

The auto-tag workflow lives in each lib repo as a sibling of `test.yml`.

## Target — test.yml

### Matrix

```text
runner = ubuntu-22.04 | macos-14 | windows-2022
target = commonJS | erlang | wasm | beam   (per Need-1 default)
```

Not every (runner, target) cell is exercised — some runtimes are
unavailable on some runners. The viable set:

| target | ubuntu | macos | windows | Reason |
|---|---|---|---|---|
| commonJS | ✓ | ✓ | ✓ | `node` is installed everywhere |
| erlang   | ✓ | ✓ | ✗ | `escript`/`erlc` ship cleanly only on linux + macos |
| beam     | ✓ | ✓ | ✗ | same |
| wasm     | ✓ | ✓ | ✗ | `wasmtime` setup on Windows runner is flaky in v0.18 — re-enable later |

`commonJS` is the **universal** target. The other three are added per
lib (rakun ships erlang/beam server code; others may not). Each lib's
workflow file lists its own viable targets — the spec describes the
default; per-lib trimming is a one-line edit at adoption.

### Bootstrap path

The lib repo's CI does not assume the lib lives where the resolver
expects. It performs three setup steps before running tests:

```yaml
- name: Checkout this lib
  uses: actions/checkout@v4
  with: { path: self }
- name: Checkout botopink-lang
  uses: actions/checkout@v4
  with:
    repository: botopink/botopink-lang
    ref: ${{ env.BOTOPINK_LANG_REF || 'main' }}
    path: botopink-lang
- name: Place lib under repository/<name>/
  run: rsync -a --delete self/ botopink-lang/repository/${{ env.LIB_NAME }}/
```

`BOTOPINK_LANG_REF` is settable via repo variable; default `main` once
release-workflows has shipped, can be temporarily set to a specific SHA
during compiler-version dance. `LIB_NAME` is set per workflow file
(`erika`, `jhonstart`, etc.).

The "place lib under repository/<name>/" trick is needed because the
multi-root resolver ([`botopink-json-deps`](botopink-json-deps.md))
walks up from cwd looking for `repository/<lib>/botopink.json`. By
co-locating the lib checkout inside the freshly cloned botopink-lang's
`repository/` directory, the resolver finds it without extra config.

### Test invocation

```yaml
- name: Install Zig
  uses: mlugg/setup-zig@v1
- name: Install botopink + run lib-test
  working-directory: botopink-lang
  run: |
    zig build install
    zig build test-libs -- --lib ${{ env.LIB_NAME }} --target ${{ matrix.target }}
```

`zig build test-libs` already accepts `--lib <name>` and `--target
<t>` (see [investigation in v0.beta.18 plan §"What's already true"](../plan.md)
and `modules/lib-test-runner/src/args.zig`). One matrix entry per
viable (runner, target) cell.

### Speed-up — release fast path

Once [`release-workflows`](release-workflows.md) ships, the lib CI can
optionally bypass the source build by downloading the published binary:

```yaml
- name: Install botopink (release fast path)
  if: ${{ env.BOTOPINK_LANG_REF == 'main' || env.BOTOPINK_LANG_REF == '' }}
  run: curl --proto '=https' --tlsv1.2 -sSfL https://botopink.dev/install.sh | sh
```

…but the source path remains the default until the release pipeline
has shipped at least one tagged version. This is an opt-in F2
follow-up; F0/F1 land on the source-build path so the spec does not
depend on `release-workflows`.

## Target — tag.yml

### Trigger

```yaml
on:
  push:
    branches: [feat, master, main]
```

Only branch pushes. Tags don't recursively re-tag.

### Workflow logic

```yaml
jobs:
  tag:
    runs-on: ubuntu-22.04
    permissions:
      contents: write          # required to push tags via github.token
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }      # need full history to detect existing tags

      - name: Read version from botopink.json
        id: ver
        run: |
          ver=$(jq -r .version botopink.json)
          if [ -z "$ver" ] || [ "$ver" = "null" ]; then
            echo "::error::botopink.json missing 'version'"
            exit 1
          fi
          echo "version=$ver" >> "$GITHUB_OUTPUT"

      - name: Compute tag
        id: tag
        run: |
          branch=${GITHUB_REF_NAME}
          ver=${{ steps.ver.outputs.version }}
          case "$branch" in
            feat)            tag="${ver}-feat" ; mutable=1 ;;
            master|main)     tag="${ver}"      ; mutable=0 ;;
            *) echo "::error::unsupported branch $branch"; exit 1 ;;
          esac
          echo "tag=$tag" >> "$GITHUB_OUTPUT"
          echo "mutable=$mutable" >> "$GITHUB_OUTPUT"

      - name: Create or move tag
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
              echo "moving tag $tag to $GITHUB_SHA"
              git tag -f "$tag" "$GITHUB_SHA"
              git push --force origin "refs/tags/$tag"
            else
              existing=$(git rev-list -n 1 "refs/tags/$tag")
              if [ "$existing" = "$GITHUB_SHA" ]; then
                echo "tag $tag already at $GITHUB_SHA — no-op"
                exit 0
              fi
              echo "::error::tag $tag already exists at $existing — bump version in botopink.json to publish a new release"
              exit 1
            fi
          else
            echo "creating tag $tag at $GITHUB_SHA"
            git tag "$tag" "$GITHUB_SHA"
            git push origin "refs/tags/$tag"
          fi
```

### Why this shape

- **Read-then-decide.** The version is in `botopink.json`, branch
  determines mutability, tag name is derived. No magic, no env
  variables to forget.
- **Idempotent on master/main.** Pushing the same commit twice (rebase,
  re-tag) is a no-op. Pushing a *different* commit for the same version
  is a hard error — the lib author must bump `version` to publish.
  This forces the "release is a manifest change" discipline.
- **Force-move on feat.** Always. There's no concept of "two feat
  versions coexisting"; feat is always the latest.
- **Uses `github.token`** — no PAT secret required. The
  `contents: write` permission is repo-level and matches the
  built-in default for push permissions.

## Examples

### push to feat — tag moves
```bash
$ git checkout feat
$ git push origin feat
# tag.yml fires.
# botopink.json says version = "0.0.1".
# tag 0.0.1-feat exists, pointing at the previous commit.
# workflow force-moves 0.0.1-feat to the new HEAD SHA.
# bpmp users with `requires.erika = "feat"` get the new commit on next bpmp sync.
```

### push to master — tag created
```bash
$ git checkout master
$ git push origin master
# tag.yml fires.
# botopink.json says version = "0.0.1".
# tag 0.0.1 does not exist.
# workflow creates 0.0.1 at the HEAD SHA, pushes it.
# bpmp install erika now resolves to 0.0.1.
```

### push to master without bumping version — workflow errors loudly
```bash
$ # Previous push already created tag 0.0.1 at SHA aaaa1111.
$ git push origin master   # new SHA bbbb2222, botopink.json still "0.0.1"
# tag.yml fires.
# tag 0.0.1 exists at aaaa1111; HEAD is bbbb2222; immutable rule.
# workflow exits 1 with "bump version in botopink.json to publish a new release".
# the PR/push is red — the maintainer either reverts or bumps version.
```

### test.yml — fresh PR run
```bash
$ git push origin feature/x
# test.yml fires for the PR.
# matrix: (ubuntu, commonJS) (ubuntu, erlang) (ubuntu, beam) (ubuntu, wasm)
#         (macos,  commonJS) (macos,  erlang) (macos,  beam) (macos,  wasm)
#         (windows, commonJS)
# each cell:
#   1. checkout self → self/
#   2. checkout botopink-lang main → botopink-lang/
#   3. rsync self/ → botopink-lang/repository/erika/
#   4. zig build install
#   5. zig build test-libs -- --lib erika --target <matrix.target>
# all green → PR mergeable.
```

## Steps

### F0 — author the workflows for one lib (erika)
- [ ] Create `repository/erika/.github/workflows/test.yml`. Matrix as
      above. `LIB_NAME=erika`. Use `mlugg/setup-zig@v1`. Pin Zig
      version from botopink-lang's `build.zig.zon`.
- [ ] Create `repository/erika/.github/workflows/tag.yml`. Exactly the
      shape above; `permissions: contents: write`.
- [ ] Test by pushing a no-op commit to a feat branch in a forked
      repo; verify the moving-tag path. Then push to master in the
      fork; verify the immutable-tag path.

### F1 — replicate to jhonstart, onze, rakun
- [ ] Copy both files; change `LIB_NAME`.
- [ ] Adjust `target` matrix per lib viability:
      - erika: commonJS, erlang, beam (no wasm — Query lowering not wasm-ready, [stdlib-backends-parity §"limites"](../../../tasks/v0.beta.13/…) keeps it on the recorded-gap list)
      - jhonstart: commonJS (frontend-only) — single-target matrix
      - onze: commonJS, erlang, beam, wasm
      - rakun: commonJS, erlang, beam (no wasm — same reason as erika)
- [ ] Each lib's `AGENTS.md` gains a "CI" section pointing to its own
      workflow files and a "Tagging" subsection explaining the
      version-in-botopink.json contract.

### F2 — release fast path (optional, post-release-workflows)
- [ ] In each lib's `test.yml`, gate the source-build steps on
      `BOTOPINK_LANG_REF` being set; otherwise fetch via the install
      script. Saves ~2 minutes per matrix cell once releases exist.
- [ ] Document the switch in each lib's `AGENTS.md`.

### F3 — docs
- [ ] Each lib's `README.md` gets a CI badge linking to its own
      Actions page.
- [ ] Each lib's `AGENTS.md` documents the auto-tag contract — when
      tags are created/moved, and the "bump version to publish"
      discipline.
- [ ] This set's `README.md` already names the workflows; nothing to
      change there.

## Test scenarios

```
ci   ---- push to a feature branch on erika: 9 matrix cells green
ci   ---- push to a feature branch on jhonstart: 3 cells green (commonJS-only)
ci   ---- erlang cell on macOS finds escript via setup-erlang
ci   ---- windows cell runs only commonJS targets
ci   ---- a regression in libs/erika/src/erika.bp turns the erlang cell red
tag  ---- first push to master on a fresh repo: tag <version> created
tag  ---- second push to master without version bump → workflow errors loudly
tag  ---- second push to master with bumped version → new tag created
tag  ---- first push to feat: moving tag <version>-feat created
tag  ---- second push to feat: moving tag force-updated
tag  ---- push to a non-{feat,master,main} branch: tag.yml does NOT fire
tag  ---- botopink.json missing 'version' field: tag.yml errors with explicit message
bp   ---- after master tag is published: bpmp install erika resolves it; sha256 + commit recorded
bp   ---- after feat tag is moved: bpmp sync drifts the recorded commit
```

## Notes

- **Why not run the workflows from botopink-lang's CI as well?** They
  already are — `zig build test-libs` in botopink-lang exercises every
  framework. But that gate is workspace-wide and slow; per-lib CI
  catches regressions per push, in the *lib's* PR, where the author
  has context. Both are useful; they don't substitute for each other.
- **Why `rsync -a --delete` instead of symlinking?** Symlinks under
  `repository/<name>/` would not be followed by the resolver's
  `openDir` call on all platforms; `rsync` produces a real tree.
  Slower (~1 second per lib) but unambiguous.
- **Why force-move feat tags instead of versioning them as
  `<ver>-feat.<n>`?** Per Eric's spec literal: `0.0.1-feat`. A
  single moving tag is simpler for bpmp's resolver (it doesn't
  have to enumerate pre-release variants), simpler for humans
  reading the tags page (no clutter), and reflects the semantic
  intent ("the current feat HEAD").
- **What if a lib author does want pre-release versioning?** Bump
  `version` in `botopink.json` to `0.0.2-rc.1` and push to master.
  The workflow creates `0.0.2-rc.1` as an immutable tag (SemVer's
  pre-release ordering puts it below `0.0.2`). bpmp's resolver
  treats it correctly.
- **No `tag.yml` on botopink-lang itself.** botopink-lang is
  human-tagged (Eric pushes `git tag v0.0.1` deliberately to trigger
  releases — see [`release-workflows`](release-workflows.md)). Auto
  tagging is for the framework libs where each push is potentially a
  pre-release.
- **Why `master` AND `main`?** None of the four lib repos has
  standardised — some still use `master`, the newer ones use
  `main`. Supporting both costs one extra `case` arm.
- **Cross-spec coordination.**
  - [`botopink-json-deps`](botopink-json-deps.md) — does not require
    this spec; the env hook works regardless of how lib tags get
    created.
  - [`release-workflows`](release-workflows.md) — enables F2's
    fast-path. F0/F1 are independent.
  - [`bpmp`](bpmp.md) consumes the tags this workflow creates.
    bpmp's `archive/<commit>.tar.gz` URL works against any tag
    (the commit SHA is what matters); the tag is just bpmp's lookup
    key during constraint resolution.
