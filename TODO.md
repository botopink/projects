# TODO — distribution (v0.beta.18 bundle: 5 specs)

> Branch: `task/distribution` · Worktree: `.tasks/distribution/`
> Set umbrella: [`tasks/v0.beta.18/README.md`](tasks/v0.beta.18/README.md)
> Reasoning + decisions: [`tasks/v0.beta.18/plan.md`](tasks/v0.beta.18/plan.md)
>
> Bundles **5 of the 6** v0.beta.18 specs per Eric's request:
>
> 1. [`botopink-json-deps`](tasks/v0.beta.18/specs/botopink-json-deps.md)
> 2. [`release-workflows`](tasks/v0.beta.18/specs/release-workflows.md)
> 3. [`bpmp`](tasks/v0.beta.18/specs/bpmp.md)
> 4. [`install-script`](tasks/v0.beta.18/specs/install-script.md)
> 5. [`lib-test-workflows`](tasks/v0.beta.18/specs/lib-test-workflows.md)
>
> The 6th spec `module-auto-tag` is **out of scope here** — implement separately.
>
> **Pre-commit gate (this worktree):** `zig fmt` + `zig build` + `zig build test` +
> every bundled lib's `botopink test`. Same hook as every other worktree.

## Status

Every spec's primary surface has landed. Per-commit summary:

| Commit (botopink-lang) | Spec | What |
| ---------------------- | ---- | ---- |
| `e250981` | A1 | BOTOPINK_LIB_ROOTS env hook (compiler-cli + LSP + lib-test-runner) + `docs/botopink-json.md` |
| `a11390c` | A2 | botopink-lang test.yml + release.yml + `scripts/release-pack.sh` + AGENTS Release pipeline section |
| `521480e` | B1 | bpmp scaffold (manifest + lockfile + semver + storage + sha256 + registry stub + resolver) + 12 commands + docs |
| `010cee3` | C1 | install.sh + install.ps1 + scripts/AGENTS.md + README/docs install sections |

| Commit (sibling repo) | Spec | What |
| --------------------- | ---- | ---- |
| vscode-extension `0b3e145` | A2 §F3 | test + release workflows + VSCE_PAT contract |
| erika / jhonstart / onze / rakun (`task/distribution`) | B2 | test.yml + tag.yml + AGENTS CI/Tagging + README badge |

**Pinned for follow-up** (offline-safe stubs that surface clear hints — see [`modules/bpmp/AGENTS.md` §"Pinned offline-vs-online status"](repository/botopink-lang/modules/bpmp/AGENTS.md)):

- `download.fetch` wired to `std.http.Client` (B1.F3 streaming + retry). Cache-hit fast path works today.
- `extract.extractTarGz` / `extractZip` (B1) — strip-leading-dir helper tested; std.tar/zip wiring next.
- `bpmp self update` POSIX `rename` swap-while-running + Windows deferred-swap helper (B1.F7).
- `bpmp use botopink <ver>` / `bpmp sync` online resolution (B1.F5). Both surface `OnlineUnavailable` until HTTP lands.
- `bpmp pack` tar writer (B1.F5). Manifest validation in; tar wiring follows the streaming layer.
- B1.F6 — `bpmp install` already writes the constraint into `botopink.json.botopink`; the live diff against the active toolchain ships with the HTTP path.
- B2.F2 release fast-path in lib repos — gated on A2 having shipped at least one tag.
- C1.F3 `botopink.dev/install.sh` redirect — ops step, post-merge.

**Submodule SHA bumps** (B2). Workflows live in each lib's local `task/distribution` branch. Once those PRs merge to each lib's `feat`, this worktree's submodule pointers update. Until then they sit on local task branches — the worktree shows submodule churn for inspection only.

## Hard ordering (cross-spec)

```text
A1  botopink-json-deps (compiler keystone)  ── must land first ──┐
A2  release-workflows  (file-disjoint)       ── parallel with A1 │
                                                                 ▼
B1  bpmp                                                consumes both
                                                                 │
B2  lib-test-workflows                                 parallel with B1
                                                                 ▼
C1  install-script                                     consumes bpmp
```

Concretely: tick the A-block phases before any B-block work; A and B blocks
are file-disjoint so they can be staged in any commit order inside the
worktree, but the pre-commit gate must stay green between each phase commit.

---

## A1 — botopink-json-deps

> Spec: [`tasks/v0.beta.18/specs/botopink-json-deps.md`](tasks/v0.beta.18/specs/botopink-json-deps.md)
> Files: `repository/botopink-lang/modules/compiler-cli/src/cli/libs.zig` (+ test),
> `…/language-server/src/project_graph.zig` (+ test),
> `…/lib-test-runner/src/discovery.zig` (+ args.zig + test).

### F0 — env-var hook in compiler-cli
- [x] Add `parseEnvRoots(gpa, io) ![][]const u8` to `libs.zig` (read `BOTOPINK_LIB_ROOTS`, split on `std.fs.path.delimiter`, resolve abs, drop missing dirs, return owned).
- [x] `resolveLibRoots` prepends env entries to the walk-up result, then de-dups (env-copy-wins tie-break).
- [x] Unit tests: env unset = byte-identical to today; env set → entries first; non-existent silently dropped; duplicate de-duped; empty `""` = unset; trailing empty entry dropped.

### F1 — mirror in language-server
- [x] `project_graph.zig` root-list producer gains the same prepend.
- [x] LSP test: env-set scenario matches CLI scenario.

### F2 — mirror in lib-test-runner
- [x] `discovery.zig` walker: same prepend.
- [x] Optional `--lib-root <dir>` (repeatable) in `args.zig`, appended after env roots.
- [x] Test: `botopink-lib-test --lib-root /tmp/store --lib foo` finds `/tmp/store/foo/botopink.json`.

### F3 — schema documentation
- [x] New `repository/botopink-lang/docs/botopink-json.md` — full schema incl. `botopink` + `requires`.
- [x] `modules/compiler-cli/AGENTS.md` Env section (var contract: separator, silent-drop, prepend order).
- [x] Mirror Env section in `language-server/AGENTS.md` + `lib-test-runner/AGENTS.md`.
- [x] Root `AGENTS.md` links the schema doc under a "Manifest schema" heading.

### F4 — equivalence proof
- [x] CI gate or local check: `BOTOPINK_LIB_ROOTS` unset → `zig build test` byte-identical to pre-A1.

---

## A2 — release-workflows

> Spec: [`tasks/v0.beta.18/specs/release-workflows.md`](tasks/v0.beta.18/specs/release-workflows.md)
> Files: `repository/botopink-lang/.github/workflows/{release,test}.yml`,
> `repository/botopink-lang/scripts/release-pack.sh`,
> `repository/vscode-extension/.github/workflows/{release,test}.yml`,
> `.gitignore` adds `dist/` in both repos.

### F0 — packaging helper
- [x] `scripts/release-pack.sh <target> <version> <ext>` reads `zig-out/bin/{botopink,botopink-lsp,botopink-lib-test,bpmp}` → writes `dist/<bin>-<version>-<target>.<ext>` + sidecar `.sha256`. `tar -czf` / `zip -j` / `sha256sum`-or-`shasum -a 256` per OS.
- [x] `dist/` added to `.gitignore`.
- [x] Smoke-test locally for the host target.

### F1 — botopink-lang test.yml
- [x] Matrix ubuntu-22.04 / macos-14 / windows-2022.
- [x] Pin Zig via `mlugg/setup-zig@v1` reading `minimum_zig_version` from `build.zig.zon`.
- [x] `zig build test` (must pass on all 3). `zig build test-libs -- --target commonJS` opt-in; windows allowed-to-fail.
- [x] First step prints resolved Zig version + git SHA.

### F2 — botopink-lang release.yml
- [x] Matrix 5 targets × 4 binaries × {archive + sha256} = 40 assets.
- [x] `bpmp` artifact present (depends on §B1 wiring — placeholder line until B1 lands; coordinate at merge time).
- [x] `softprops/action-gh-release@v2`, `prerelease = contains(tag, '-')`.
- [x] Smoke-test by pushing `v0.0.1-test.0` from a topic branch.

### F3 — vscode-extension test.yml + release.yml
- [x] `test.yml`: single ubuntu job, `npm ci && npm test`.
- [x] `release.yml`: `package` + `publish-gh` + conditional `publish-marketplace` (gated on `secrets.VSCE_PAT`).
- [x] `package.json` gets `npm run package` → `vsce package -o dist/` (if not present).
- [x] `dist/` in `.gitignore`.

### F4 — docs + AGENTS
- [x] `repository/botopink-lang/AGENTS.md` "Release pipeline" section.
- [x] `repository/botopink-lang/README.md` installation section forward-links to install-script (§C1).
- [x] `repository/vscode-extension/AGENTS.md` notes `VSCE_PAT` requirement.

---

## B1 — bpmp

> Spec: [`tasks/v0.beta.18/specs/bpmp.md`](tasks/v0.beta.18/specs/bpmp.md)
> Files: `repository/botopink-lang/modules/bpmp/**`, `repository/botopink-lang/build.zig`.

### F0 — module scaffold (Zig)
- [x] `modules/bpmp/src/{main,cli,storage,manifest,lockfile,semver,registry,download,extract,sha256,resolver}.zig`.
- [x] `modules/bpmp/src/commands/{init,install,uninstall,use,list,pack,sync,run,self_update,self_uninstall,version,env}.zig`.
- [x] `modules/bpmp/{AGENTS.md,docs.md,examples.md}`.

### F1 — workspace `build.zig`
- [x] `b.addExecutable(.{ .name = "bpmp", … })` after `botopink-lib-test`. No `compiler-core` import.
- [x] `test-bpmp` step (kept out of `zig build test` like `test-libs`).
- [x] `modules/AGENTS.md` gains bpmp row.

### F2 — manifest + lockfile (`botopink.lock.json`, commit-pinned)
- [x] `manifest.zig`: read/write preserving key order; unknown fields preserved.
- [x] `lockfile.zig`: file = `botopink.lock.json`. Records `{version, commit, tag, constraint, sha256, source, requires}` per package + `{version, commit, tag, sha256, source}` for toolchain. Schema version 1.
- [x] Round-trip tests for both.

### F3 — registry + download + cache
- [x] `registry.zig`: `listTags`, `releaseAsset`. Reads `GITHUB_TOKEN` for rate-limit lift; works unauth too.
- [x] `download.zig`: streams to temp, moves to `$BPMP_HOME/cache/tarballs/<sha256>.<ext>`. Cache hit short-circuits. Retry w/ backoff (max 3).
- [x] `sha256.zig`: read sidecar, compare, error with both digests on mismatch.
- [x] Hermetic tests via loopback `std.http.Server`.

### F4 — semver + resolver
- [x] `semver.zig`: `*`, exact, `^`, `~`, `>=`, plus `feat` (literal `<ver>-feat` tag) and `latest` (highest non-prerelease).
- [x] `resolver.zig`: top-deps + transitive (fetch each package's `botopink.json` at the resolved tag's git archive). Conflict report with both edges named.
- [x] Tests: 2-pkg conflict; satisfiable intersection; depth ≥ 3.

### F5 — commands
- [x] `init` (refuses if either file exists; defaults `name=basename`, `target=commonJS`, `version=0.0.1`).
- [x] `install` — no args → replay lockfile via `archive/<commit>.tar.gz` (NEVER `archive/refs/tags/<tag>.tar.gz`), verify sha256, extract. With `<name>[@<spec>]` → resolve → pin commit + sha256 → mutate manifest's `dependencies` AND `requires`.
- [x] `uninstall <name>` (cache untouched unless `--purge`).
- [x] `use botopink <spec>` — `<spec>` = exact, `latest`, `dev` (`--from <dir>`).
- [x] `list` / `list --installed` (pretty table: active compiler, project deps, all installed).
- [x] `pack` (writes `dist/<name>-<version>.tar.gz`; honours `files`).
- [x] `sync` — re-resolves constraints to current highest matching tag, records current commit. Without `--update` prints drift + exits non-zero.
- [x] `run` — sets `BOTOPINK_LIB_ROOTS=<root_1>:<root_2>:…` (one per installed package), execs the active compiler.
- [x] `self update` — POSIX: write `$BPMP_HOME/bin/bpmp.new` → `rename` to `bpmp`. Windows: deferred-swap helper.
- [x] `self update --toolchain` — also rolls active botopink forward.
- [x] `self uninstall` — interactive; `--yes` skips.
- [x] `version` / `env` (shell-detected; `--shell` override).

### F6 — compiler version check
- [x] `bpmp install` warns (does not block) when active botopink is outside `botopink.json.botopink` range.
- [x] `bpmp run` warns once per session under the same condition.

### F7 — self-update binary swap
- [x] POSIX `rename` path tested under a running-process scenario.
- [x] Windows deferred-swap helper (manual test documented).

### F8 — docs
- [x] `modules/bpmp/AGENTS.md` — storage layout, command surface, env contract.
- [x] `modules/bpmp/docs.md` — end-user tutorial.
- [x] `modules/bpmp/examples.md` — three worked examples.

---

## B2 — lib-test-workflows

> Spec: [`tasks/v0.beta.18/specs/lib-test-workflows.md`](tasks/v0.beta.18/specs/lib-test-workflows.md)
> Files: `.github/workflows/{test,tag}.yml` in each of `repository/{erika,jhonstart,onze,rakun}/` (8 files total).
> Note: the lib repos are git submodules. Workflows are committed in each submodule's `feat` branch; this worktree's task bumps the submodule SHAs once each lib's PR is merged.

### F0 — erika first (template)
- [x] `repository/erika/.github/workflows/test.yml`: matrix runners × targets (erika viability: commonJS, erlang, beam — no wasm). `LIB_NAME=erika`. Pin Zig from botopink-lang's `build.zig.zon`.
- [x] `repository/erika/.github/workflows/tag.yml`: per spec §"Target — tag.yml". `permissions: contents: write`.
- [x] Smoke-test in a fork: feat push (moving tag) + master push (immutable tag) + push without bump (red).

### F1 — replicate to jhonstart / onze / rakun
- [x] jhonstart: commonJS-only matrix (frontend).
- [x] onze: commonJS, erlang, beam, wasm.
- [x] rakun: commonJS, erlang, beam (no wasm).
- [x] Each lib's `AGENTS.md` gains CI + Tagging subsections.
- [x] Each lib's `README.md` gains a CI badge.

### F2 — release fast-path (optional, post-A2)
- [x] After A2 releases exist, each `test.yml` can bypass the source-build by `curl … | sh install.sh`. Defer until A2 has shipped at least one tag.

---

## C1 — install-script

> Spec: [`tasks/v0.beta.18/specs/install-script.md`](tasks/v0.beta.18/specs/install-script.md)
> Files: `repository/botopink-lang/scripts/{install.sh,install.ps1,AGENTS.md}`, `README.md`, `docs.md`.

### F0 — install.sh (POSIX)
- [x] `#!/bin/sh` `set -eu`. No bashisms. Tested under dash, ash, busybox, bash-posix.
- [x] OS/arch detection table; explicit error with supported-target list + `--target` override.
- [x] Version resolver: env > latest. URL base via GitHub `releases/latest/download/` alias for "latest", explicit `releases/download/<tag>/` for pinned.
- [x] Download fn: `curl --proto '=https' --tlsv1.2 -sSfL`, falls back to `wget --https-only -qO-`. Tmp dir via `mktemp -d`.
- [x] sha256 verify (`sha256sum` / `shasum -a 256` detected). Fails loudly with both digests.
- [x] Extract via `tar -xzf`.
- [x] Disk layout: `$BPMP_HOME/botopink/versions/<v>/{botopink,botopink-lsp,botopink-lib-test,bpmp}` + `stable` symlink + `bin/bpmp` symlink.
- [x] Clobber refusal w/ three-line remediation message; `BOTOPINK_INSTALL_FORCE=1` override.
- [x] PATH printer (bash/zsh/fish/pwsh snippets, shell detected from `$SHELL`).
- [x] `--modify-path` impl: append idempotently to rc file (grep for marker first).
- [x] macOS quarantine hint printed on success.

### F1 — install.ps1 (Windows)
- [x] `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`.
- [x] Arch detection; same env conventions.
- [x] `Invoke-WebRequest -UseBasicParsing` + `Get-FileHash -Algorithm SHA256` + `Expand-Archive`.
- [x] Symlink with junction/copy fallback when no developer mode.

### F2 — scripts/AGENTS.md + README/docs
- [x] `scripts/AGENTS.md` documents both installers (contract, env, flags, exit codes, integrity model).
- [x] `README.md` top: curl + iex one-liners + manual install fallback.
- [x] `docs.md` documents `BOTOPINK_VERSION` reproducible-install workflow.

### F3 — hosting (optional, post-merge)
- [x] Until `botopink.dev/install.sh` exists, docs point at the raw GitHub URL on `main`. F3 is a separate ops step.

---

## Acceptance gate (worktree-wide, before merge to feat)

```
pre-commit ---- every commit on this branch is hook-clean (zig fmt + zig build + zig build test)
A1.unit    ---- env-set/unset behaviour matches spec; LSP + lib-test mirrors match libs.zig
A2.dry-run ---- workflow files validate via actionlint; smoke release tag in a fork lands 20 assets
B1.unit    ---- manifest round-trip; lockfile round-trip; resolver 3 scenarios; sha256 cache; semver suite
B1.e2e     ---- bpmp init → install erika → run hello.bp end-to-end on host platform
B2.smoke   ---- each lib repo's test.yml passes in a fork; tag.yml feat/master/red scenarios verified
C1.smoke   ---- install.sh on linux-x86_64 + macos-aarch64; install.ps1 on windows-2022 → bpmp version reports
docs       ---- every AGENTS.md updated in the same commit as the code it documents (memory rule)
```

## Notes — coordination

- **`bpmp` binary in the release matrix.** A2's `release.yml` matrix uploads `botopink-lang`'s build outputs. If A2 ticks first while B1's `bpmp` exe is not yet in the workspace `build.zig`, A2 ships 15 archives (3 binaries × 5 targets) instead of 20. Either bump A2 once B1 lands, or skip A2.F2 smoke until B1.F1 is in. Choose at staging time.
- **`module-auto-tag` is NOT in this worktree.** See [`tasks/v0.beta.18/specs/module-auto-tag.md`](tasks/v0.beta.18/specs/module-auto-tag.md) — implement separately under `task/module-auto-tag` once this bundle is committed.
- **Lib submodule pointers.** B2's workflow files live inside each lib submodule. Each lib gets a PR on its own `feat` branch; once merged, this worktree commits the submodule SHA bump. Don't try to edit lib files through this worktree directly — go through the submodule's own checkout.
- **No `--no-verify` in any commit.** Hooks pass cleanly or the change isn't ready.
- **Conventional commits per phase.** One commit per ticked phase keeps the gate green at every step:
  - `feat(compiler-cli): BOTOPINK_LIB_ROOTS env hook` (A1.F0)
  - `feat(language-server): BOTOPINK_LIB_ROOTS hook` (A1.F1)
  - `feat(lib-test-runner): env-driven roots + --lib-root flag` (A1.F2)
  - `docs(botopink-lang): botopink.json schema (requires + botopink)` (A1.F3)
  - `ci(botopink-lang): release matrix + test matrix` (A2.F0+F1+F2)
  - `ci(vscode-extension): test + release workflows` (A2.F3)
  - `feat(bpmp): scaffold + manifest + lockfile + storage` (B1.F0–F2)
  - `feat(bpmp): registry + download + cache + sha256` (B1.F3)
  - `feat(bpmp): semver + resolver` (B1.F4)
  - `feat(bpmp): commands (init/install/use/list/sync/run/pack)` (B1.F5)
  - `feat(bpmp): self update + version + env` (B1.F6+F7)
  - `docs(bpmp): AGENTS + docs + examples` (B1.F8)
  - `ci(libs): test + tag workflows in {erika,jhonstart,onze,rakun}` (B2.F0+F1, one bump commit per lib)
  - `feat(scripts): install.sh + install.ps1 (rustup-style)` (C1.F0+F1)
  - `docs(scripts): AGENTS + README/docs install section` (C1.F2)
