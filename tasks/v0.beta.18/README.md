# v0.beta.18 — distribution: the language ships itself

> v0.beta.17 turned the monorepo into a **workspace of projects**. v0.beta.18
> turns that workspace into a **distributable**. Today a botopink user installs
> the toolchain by cloning the repo and running `zig build`; there is no
> release pipeline, no installer, no package manager, and a framework lives
> wherever its source happens to be on disk. After this set lands: a tag push
> produces signed-by-checksum binaries on GitHub Releases; one curl line
> installs the toolchain; a `bpmp` CLI resolves third-party packages declared in
> `botopink.json`; each framework repo runs its own per-platform CI; and bpmp
> can update itself.

## What this set delivers

| Capability | Where it lives | Used by |
|---|---|---|
| Cross-platform release binaries (5 targets) per tag | `repository/botopink-lang/.github/workflows/release.yml` | install script, bpmp, end users |
| Per-platform CI on push/PR for the compiler | `repository/botopink-lang/.github/workflows/test.yml` | repo gate |
| `botopink.json` carries dependency *versions* + a minimum compiler constraint; compiler honours `BOTOPINK_LIB_ROOTS` | `modules/compiler-cli/src/cli/libs.zig` + mirrors in `language-server/project_graph.zig` + `lib-test-runner/discovery.zig` | bpmp |
| Boto Pink Package Manager (`bpmp`) CLI | `repository/botopink-lang/modules/bpmp/` | end users, install script |
| One-line installer (`curl … \| sh` + PowerShell) | `repository/botopink-lang/scripts/install.sh` + `install.ps1` | end users |
| Per-platform CI **+ auto-tagging** for each framework lib | `.github/workflows/{test,tag}.yml` inside each of `repository/{erika,jhonstart,onze,rakun}` | framework repo gates, bpmp resolution |
| VS Code extension release pipeline (`.vsix`) | `repository/vscode-extension/.github/workflows/release.yml` | end users via marketplace |

## Scope

| Spec | Area | Files (target tree — v17 already landed) |
|---|---|---|
| [botopink-json-deps](specs/botopink-json-deps.md) | extend `botopink.json` schema (`requires`, `botopink`) + add `BOTOPINK_LIB_ROOTS` env hook to the three lib resolvers. **Compiler keystone for bpmp.** | `modules/compiler-cli/src/cli/libs.zig`, `modules/language-server/src/project_graph.zig`, `modules/lib-test-runner/src/discovery.zig`, schema doc |
| [release-workflows](specs/release-workflows.md) | GH Actions on `v*` tag — botopink-lang cross-builds 5 targets + sha256 sidecars; vscode-extension packages `.vsix`; both upload to GitHub Releases. Plus push/PR test workflows for both repos. | `repository/botopink-lang/.github/workflows/{release,test}.yml`, `repository/vscode-extension/.github/workflows/{release,test}.yml`, packaging helper scripts |
| [bpmp](specs/bpmp.md) | Boto Pink Package Manager — Zig CLI at `modules/bpmp/`. Reads `botopink.json` deps, writes commit-pinned `botopink.lock.json`; storage at `$BPMP_HOME`; commands `init`/`install`/`use`/`list`/`pack`/`sync`/`run`/`self update`/`self uninstall`; exports `BOTOPINK_LIB_ROOTS` to spawned compiler; downloads from GitHub Releases (toolchain) and `archive/<commit>.tar.gz` (libs). | `repository/botopink-lang/modules/bpmp/**`, `build.zig` |
| [install-script](specs/install-script.md) | rustup-style `curl … \| sh` installer at `repository/botopink-lang/scripts/install.sh` (POSIX) + `install.ps1` (Windows). Detects OS/arch, fetches latest release, verifies sha256, installs into `$BPMP_HOME`. Refuses to clobber → suggests `bpmp self update`. | `repository/botopink-lang/scripts/{install.sh,install.ps1,AGENTS.md}`, `docs.md` |
| [lib-test-workflows](specs/lib-test-workflows.md) | Two workflows per lib repo: (1) `test.yml` — push/PR, matrix ubuntu/macos/windows, checkout self + botopink-lang, place lib under `repository/<name>/`, `zig build install && zig build test-libs -- --lib <name>`; (2) `tag.yml` — auto-tag on push, branch `feat` ⇒ moving tag `<version>-feat`, `master`/`main` ⇒ immutable tag `<version>` (version read from the lib's `botopink.json`). **No release tarballs for libs** — bpmp resolves them via `git archive` on the tag. | `.github/workflows/{test,tag}.yml` in each of 4 lib repos |
| [module-auto-tag](specs/module-auto-tag.md) | Extends the same auto-tag contract to three more units: `modules/compiler-core` + `modules/compiler-cli` (path-scoped inside the botopink-lang repo, tags prefixed `compiler-core/<ver>[-feat]` and `compiler-cli/<ver>[-feat]`) and `vscode-extension` (own repo, tags `<ver>[-feat]`). Each unit gains a minimal `botopink.json` carrying `version` as the single source of truth. Same rules: feat = moving tag, master/main = immutable with required version bump. | `repository/botopink-lang/.github/workflows/tag.yml`, `repository/vscode-extension/.github/workflows/tag.yml`, 3 new `botopink.json` files |

## Order

```text
botopink-json-deps  ──┐
release-workflows   ──┼──▶  bpmp  ──▶  install-script
                      │
                      └──▶  lib-test-workflows  (independent — can land any time after release-workflows; libs CI will reach for a published compiler once releases exist)
```

Two specs are **independent and parallel** at the start (`botopink-json-deps` is
a pure superset on the compiler; `release-workflows` is wholly inside
`.github/`). `bpmp` consumes both (the env hook and the artifact URLs).
`install-script` consumes the bpmp binary + release artifacts.
`lib-test-workflows` is independent but lands ergonomically after
`release-workflows` so it can pull a published compiler instead of building from
source on every job.

## Non-goals (explicit)

- **No registry server.** `bpmp` resolves packages by `github.com/botopink/<name>`
  (GitHub Releases as a static CDN). A real index/search service is post-v18.
- **No version solver beyond "pick the highest matching tag".** SemVer
  constraints accepted are `<exact>`, `^X.Y.Z`, `~X.Y.Z`, `>=X.Y.Z`, `*`. No
  backtracking — first-fit wins.
- **No marketplace auto-publish without explicit secret.** The vscode-extension
  release workflow uploads `.vsix` to GitHub Releases unconditionally; it only
  pushes to the VS Code Marketplace when `VSCE_PAT` is configured.
- **No source rewrite for existing `dependencies: [name, …]` arrays.** The
  compiler keeps reading the array; `requires` is *additional* metadata for the
  package manager. No breaking change to existing libs.
- **No multi-package workspaces (Cargo-style virtual manifest).** One
  `botopink.json` per project. Workspaces are post-v18.
- **Lib repos do not produce release tarballs.** Per Eric, the four framework
  repos run CI only — `bpmp install <framework>` reaches into the framework's
  git tag, not a curated release tarball.

## Goal

After v0.beta.18 lands: pushing `git tag v0.0.1 && git push --tags` on
`repository/botopink-lang` produces a GitHub Release with 5×4 = 20 tarballs
(`botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp` per target) + sha256
sidecars. Running `curl --proto '=https' --tlsv1.2 -sSf
https://botopink.dev/install.sh | sh` (or the raw GitHub URL) installs the
toolchain into `~/.bpmp/` and prints PATH instructions. `bpmp init && bpmp
install erika` creates a workspace, downloads erika from its GitHub Release,
and `bpmp run examples/hello.bp` compiles using a compiler that finds erika at
`$BPMP_HOME/packages/erika/versions/<v>/src/` via `BOTOPINK_LIB_ROOTS`. `bpmp
self update` swaps the live bpmp binary for the latest release.
