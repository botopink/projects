# Release workflows — botopink-lang + vscode-extension publish artifacts on tag

**Slug**: release-workflows
**Depends on**: nothing
**Files**: `repository/botopink-lang/.github/workflows/{release.yml,test.yml}`, `repository/botopink-lang/scripts/release-pack.sh`, `repository/vscode-extension/.github/workflows/{release.yml,test.yml}`, both repos' `.gitignore` (allow `dist/`)
**Touches docs**: `repository/botopink-lang/AGENTS.md` (CI section), `repository/botopink-lang/README.md` (installation), `repository/vscode-extension/AGENTS.md`, this set's `README.md` link table
**Status**: pending

## Problem

Today neither `botopink-lang` nor `vscode-extension` publishes anything: a user
who wants the toolchain clones the repo and runs `zig build`; a user who wants
the VS Code extension reaches into `repository/vscode-extension/` and packages
it locally. v0.beta.18 hangs three downstream pieces — [`bpmp`](bpmp.md),
[`install-script`](install-script.md), and the marketplace presence — on
"there is a GitHub Release with predictable asset URLs". This spec sets that
up.

Two repos, two workflow files each:

| Repo | `test.yml` (push/PR) | `release.yml` (tag `v*`) |
|---|---|---|
| `botopink-lang` | `zig build test` on linux/macos/windows | matrix cross-build 5 targets × 4 binaries + sha256 + GH Release |
| `vscode-extension` | `npm test` on linux | `vsce package` + GH Release; marketplace publish iff `VSCE_PAT` is set |

The tag is the single source of truth — pushing `v0.0.1` produces the
`v0.0.1` release; pushing `v0.0.2` produces `v0.0.2`. No "latest" channel
besides GitHub's built-in `releases/latest/download/<file>` alias.

## Target — botopink-lang

### Asset naming (see [plan §D4](../plan.md))

For every tag `v<X.Y.Z>` the release carries these 24 files
(5 targets × 4 binaries × {archive, sha256 sidecar}):

```
botopink-v0.0.1-linux-x86_64.tar.gz       botopink-v0.0.1-linux-x86_64.tar.gz.sha256
botopink-v0.0.1-linux-aarch64.tar.gz      …
botopink-v0.0.1-macos-x86_64.tar.gz       …
botopink-v0.0.1-macos-aarch64.tar.gz      …
botopink-v0.0.1-windows-x86_64.zip        botopink-v0.0.1-windows-x86_64.zip.sha256

botopink-lsp-v0.0.1-<target>.<ext>        …  (5)
botopink-lib-test-v0.0.1-<target>.<ext>   …  (5)
bpmp-v0.0.1-<target>.<ext>                …  (5)
```

Each archive contains **one file** — the binary, executable bit preserved on
POSIX. Windows archives are `.zip` carrying `<binary>.exe`. No top-level
directory inside the archive (matches the convention rustup / setup-zig
expect — easier for the install script to extract directly into
`$BPMP_HOME/botopink/versions/<v>/`).

### Cross-compile matrix

| matrix.target | runner | Zig target string | archive | needs |
|---|---|---|---|---|
| linux-x86_64 | `ubuntu-22.04` | `x86_64-linux-gnu` | tar.gz | — |
| linux-aarch64 | `ubuntu-22.04` | `aarch64-linux-gnu` | tar.gz | Zig handles cross |
| macos-x86_64 | `macos-13` | `x86_64-macos` | tar.gz | — |
| macos-aarch64 | `macos-14` | `aarch64-macos` | tar.gz | — |
| windows-x86_64 | `windows-2022` | `x86_64-windows-gnu` | zip | — |

Two macOS runners are used so each native binary is built on its own arch —
avoids the codesigning pitfalls of `zig build -Dtarget=aarch64-macos` from
an x86 runner. Cross-compiling to Linux aarch64 is fine because Zig's
`-Dtarget` is solid for Linux GNU.

### Workflow shape (informal, the spec is the *intent*, not the YAML)

`release.yml`:

```yaml
name: release
on:
  push:
    tags: ['v*']
jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - target: linux-x86_64;   runner: ubuntu-22.04;  zigtarget: x86_64-linux-gnu;  ext: tar.gz
          - target: linux-aarch64;  runner: ubuntu-22.04;  zigtarget: aarch64-linux-gnu; ext: tar.gz
          - target: macos-x86_64;   runner: macos-13;      zigtarget: x86_64-macos;       ext: tar.gz
          - target: macos-aarch64;  runner: macos-14;      zigtarget: aarch64-macos;      ext: tar.gz
          - target: windows-x86_64; runner: windows-2022;  zigtarget: x86_64-windows-gnu; ext: zip
    runs-on: ${{ matrix.runner }}
    steps:
      - checkout
      - setup-zig (pinned version — read from `flake.nix`/`.zig-version`/`build.zig.zon`'s minimum_zig_version)
      - zig build -Doptimize=ReleaseSafe -Dtarget=${{ matrix.zigtarget }}
        (produces zig-out/bin/{botopink,botopink-lsp,botopink-lib-test,bpmp} — see Steps F2 for bpmp wiring)
      - scripts/release-pack.sh ${{ matrix.target }} ${{ github.ref_name }} ${{ matrix.ext }}
        (packages each binary into its archive + writes sha256)
      - upload all 8 artifacts to a matrix-scoped staging area (actions/upload-artifact)
  publish:
    needs: build
    runs-on: ubuntu-22.04
    steps:
      - download all artifacts
      - softprops/action-gh-release@v2:
          tag_name: ${{ github.ref_name }}
          files: dist/*
          fail_on_unmatched_files: true
          draft: false
          prerelease: ${{ contains(github.ref_name, '-') }}   # tags like v0.0.1-rc.1 are prereleases
```

The packaging script `scripts/release-pack.sh` is the per-target glue —
takes the binaries out of `zig-out/bin/`, names them per [D4](../plan.md),
computes sha256 (`sha256sum` on linux, `shasum -a 256` on macOS, PowerShell
`Get-FileHash` on windows — abstracted by the script). The script writes
into `dist/`; the workflow uploads `dist/*`.

`test.yml`:

```yaml
name: test
on: [push, pull_request]
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        runner: [ubuntu-22.04, macos-14, windows-2022]
    runs-on: ${{ matrix.runner }}
    steps:
      - checkout
      - setup-zig
      - zig build test               # compiler-core + cli + LSP tests + lib-agnostic gate
      - zig build test-libs -- --target commonJS   # opt-in; need node — see Notes
```

`test-libs` runs only on the targets where `node` and `escript` are present —
GitHub's `ubuntu-22.04`/`macos-14` images include both; the windows image
lacks `escript`, so the workflow caps test-libs to `commonJS` on Windows.

## Target — vscode-extension

### Asset

```
botopink-<X.Y.Z>.vsix         # the only release asset
```

Pulled out of `vsce package` directly. SHA256 sidecar is **not** produced for
`.vsix` — the marketplace verifies signatures already, and the install path
for `.vsix` is `code --install-extension`, not bpmp.

### `release.yml`

```yaml
name: release
on:
  push:
    tags: ['v*']
jobs:
  package:
    runs-on: ubuntu-22.04
    steps:
      - checkout
      - setup-node@v4 (node 20)
      - npm ci
      - npm run package    # → dist/botopink-<version>.vsix (via vsce package -o dist/)
      - upload-artifact: dist/*.vsix
  publish-gh:
    needs: package
    runs-on: ubuntu-22.04
    steps:
      - download-artifact
      - softprops/action-gh-release@v2:
          files: dist/*.vsix
          tag_name: ${{ github.ref_name }}
  publish-marketplace:
    needs: package
    if: ${{ secrets.VSCE_PAT != '' }}
    runs-on: ubuntu-22.04
    steps:
      - download-artifact
      - vsce publish --packagePath dist/*.vsix --pat ${{ secrets.VSCE_PAT }}
```

`publish-marketplace` is gated on the secret being present. With no secret
configured (the default for a fresh fork or a PR), the job is skipped — a
maintainer's tag push still produces a `.vsix` on the GitHub Release.

### `test.yml`

```yaml
name: test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
      - checkout
      - setup-node
      - npm ci
      - npm test       # the existing pure-fn suite (modules/vscode-extension AGENTS.md)
```

Linux-only — the `vscode`-free unit suite has no platform dependency, and
adding macOS/windows runs would not exercise anything new. (The full
extension-host suite needs `xvfb`/`code` and is a separate effort, out of
scope here.)

## Examples

### producing v0.0.1
```bash
$ cd repository/botopink-lang
$ git tag v0.0.1
$ git push origin v0.0.1
# release.yml fires; 5 matrix jobs each upload 8 artifacts (4 binaries × {archive, sha256}).
# publish job collects them into a single GitHub Release titled "v0.0.1".
# the Release page now has 40 assets:
#   botopink-v0.0.1-linux-x86_64.tar.gz       botopink-v0.0.1-linux-x86_64.tar.gz.sha256
#   …
#   bpmp-v0.0.1-windows-x86_64.zip            bpmp-v0.0.1-windows-x86_64.zip.sha256
```

### CI on every push
```bash
$ git push origin feat
# test.yml fires on 3 runners (linux/macos/windows).
# Each runs `zig build test`.
# Required to merge into main.
```

### vsce publish without a secret
```bash
# Fork without VSCE_PAT — tag v0.3.1
# publish-gh succeeds, .vsix lands on the Release.
# publish-marketplace is SKIPPED — no token, no surprise charges to a stranger's marketplace.
```

## Steps

### F0 — packaging helper script
- [ ] Write `repository/botopink-lang/scripts/release-pack.sh` taking
      `<target> <version> <ext>`. Reads from `zig-out/bin/`, writes to
      `dist/<binary>-<version>-<target>.<ext>` and a sidecar `.sha256`. Uses
      `tar -czf` for `tar.gz`, `zip -j` for `zip`, `sha256sum`/`shasum -a 256`
      based on uname. Windows path: same script under `bash` (git-bash on
      windows-2022 GH runner has both `tar` and `sha256sum`).
- [ ] Add `dist/` to `repository/botopink-lang/.gitignore`.
- [ ] Smoke-test locally: `zig build` + run the script for the host target;
      verify the archive extracts and runs.

### F1 — botopink-lang test.yml
- [ ] Author `repository/botopink-lang/.github/workflows/test.yml`. Matrix
      ubuntu-22.04/macos-14/windows-2022. Pin Zig version from
      `build.zig.zon`'s `minimum_zig_version` (use `mlugg/setup-zig@v1` with
      that string).
- [ ] First job step prints the resolved Zig version + git SHA for
      debuggability.
- [ ] Allow `windows` to fail at `test-libs` (continue-on-error or matrix
      include with `experimental: true`) until a separate spec resolves
      windows newline / escript-skip issues. `zig build test` (no -libs)
      MUST pass on all three.

### F2 — botopink-lang release.yml
- [ ] Add `bpmp` as a build artifact in the workspace `build.zig`. This is
      **dependency-edge-on**: the `bpmp` Zig executable is defined in
      [`bpmp`](bpmp.md) §F0 (`b.addExecutable(.{.name="bpmp", …})`). If
      `release-workflows` lands before `bpmp`, the release matrix is wired
      to upload only 3 binaries × 5 targets = 15 archives; once `bpmp` lands
      the matrix grows to 4 × 5 = 20. Either order works; the spec is
      shaped to make the bump trivial.
- [ ] Author `release.yml` with the matrix shape above. Pin `setup-zig`,
      `softprops/action-gh-release@v2`, `actions/upload-artifact@v4`.
- [ ] `prerelease` flag derives from tag name (anything with a `-` in the
      part after `v` is a prerelease — `v0.0.1-rc.1` ≠ `v0.0.1`).
- [ ] Smoke-test by pushing a `v0.0.1-test.0` tag from a topic branch and
      validating the resulting Release locally before deletion.

### F3 — vscode-extension test.yml + release.yml
- [ ] Author `repository/vscode-extension/.github/workflows/test.yml` —
      single ubuntu job, `npm ci && npm test`.
- [ ] Author `repository/vscode-extension/.github/workflows/release.yml` —
      `package` + `publish-gh` + conditional `publish-marketplace`.
- [ ] Add `dist/` to `repository/vscode-extension/.gitignore`.
- [ ] Add `npm run package` script to `package.json` (`vsce package -o dist/`)
      if not already present.

### F4 — docs + AGENTS
- [ ] `repository/botopink-lang/AGENTS.md` gains a "Release pipeline"
      section: tag → 5 matrix jobs → 20 binaries on GitHub Release; lists
      the assets the install script + bpmp depend on.
- [ ] `repository/botopink-lang/README.md` installation section points at
      `curl … | sh` (forward-link to install-script spec) and at the
      Releases page as the fallback.
- [ ] `repository/vscode-extension/AGENTS.md` documents the
      `VSCE_PAT` secret requirement.

## Test scenarios

```
ci    ---- test.yml on push to a feature branch: 3 runners green
ci    ---- test.yml on a PR: same 3 runners green (or red on intent)
rel   ---- push v0.0.1: 5 matrix builds succeed, 20 assets uploaded
rel   ---- push v0.0.1-rc.1: same 20 assets, Release marked "prerelease"
rel   ---- sha256 sidecar of each archive verifies (shasum -a 256 -c)
rel   ---- archive extracts and the binary runs `--version` on its native target
vsx   ---- push tag in vscode-extension: .vsix uploaded to Release
vsx   ---- without VSCE_PAT, marketplace publish job is skipped (not failed)
vsx   ---- with VSCE_PAT, marketplace receives the new version
```

## Notes

- **Why ubuntu-22.04, not 24.04?** glibc compatibility — the 22.04 image
  builds against glibc 2.35, runs on essentially every distro from 2022
  onwards. 24.04 raises glibc and would break older systems for no win.
- **Why ReleaseSafe, not ReleaseFast?** ReleaseSafe keeps runtime safety
  checks (overflow, OOB) — for a v0.x compiler shipping to users, the size
  cost is worth the diagnostic clarity.
- **Why not use the GitHub-provided `windows-latest` and `macos-latest`?**
  Pinning runner versions prevents silent breakage when GitHub bumps the
  default — Zig versions get re-cached, environments shift. The trade is
  manual bumps every ~12 months.
- **Why `softprops/action-gh-release@v2` over `gh release create`?** Single
  action handles upload of all matrix artifacts in one step with
  idempotency — re-running a build for the same tag overwrites assets
  cleanly. `gh release create` would need extra logic for the "release
  already exists" branch.
- **macOS Gatekeeper / quarantine.** v0.beta.18 does **not** notarise. The
  install script ([install-script](install-script.md)) prints a hint about
  `xattr -d com.apple.quarantine ~/.bpmp/bin/bpmp`. Notarisation is a
  one-spec follow-up; it lives entirely inside `release.yml`.
- **Windows code-signing.** Same as macOS — out of scope for v0.18.
  SmartScreen will warn on first launch; documented in the install script.
- **Why is `bpmp` in the same release as `botopink`?** They version
  together — the bpmp CLI knows about the manifest schema and the env hook,
  both of which can evolve. Bundling means a `bpmp self update` always
  picks a bpmp that matches its embedded compiler.
- **Cross-spec coordination.**
  - [`bpmp`](bpmp.md) consumes the asset URL convention and exposes the
    `bpmp` binary that this release pipeline ships. If `bpmp` lands after
    `release-workflows`, the matrix is bumped from 3 binaries × 5 = 15 to
    4 × 5 = 20; F2 above is written to make this a one-line change.
  - [`install-script`](install-script.md) consumes the asset URLs and the
    sha256 sidecar convention.
  - [`lib-test-workflows`](lib-test-workflows.md) consumes the published
    compiler binaries (faster CI path); also works without them by building
    botopink-lang from source.
