# botopink-install-from-deps — F0–F6 closeout

> Spec: [`tasks/v0.beta.20/specs/botopink-install-from-deps.md`](../../tasks/v0.beta.20/specs/botopink-install-from-deps.md)

## Baseline (pre-this-session)

- meta `feat`: `ebd0fcc` (post wasm3-unified-runtime perf).
- bot-lang `feat`: `8f2fdbe` (post wasm3 perf).

## Phases

- [x] **F3 — consumer fixture migration** (8/8 botopink.json on object form)
  - emilia-card `af1c66d`, erika-linq `abfcfe4`, jhonstart-{counter,html,todo} `7a9b0ae`,
    onze `ab7788b`, rakun `ee798f8`, generic-loader-binding `3aecd65`.
- [x] **F0 — `config.zig` parser extension**
  - `ProjectConfig.dependencies` now `[]const DepEntry` (was `[]const []const u8`).
  - New `DepEntry`/`DepSpec`/`DepRef` shapes; new `DepDiagnostic` collection.
  - DEP-001 / DEP-002 / DEP-003 surfaced as `dep_diagnostics`; **8 parser tests** pin every path.
  - `dependencyNames` helper preserves the legacy bare-name surface for callers that don't care about source coordinates.
- [x] **F2 — resolver `$BPMP_HOME` fallback in `libs.zig`**
  - `loadDependencies` now takes `[]const DepEntry` directly.
  - New `resolveFallbackRoots` + `resolveBpmpStoreRoot` (BPMP_HOME / XDG_CACHE_HOME / HOME chain).
  - `loadOne` consults `.botopinkbuild/deps/<name>/` after the normal `libs/<name>/` + `BOTOPINK_LIB_ROOTS` walk.
  - `LibsRootNotFound` callsites (build/check/test_cmd) gain a `bpmp install` hint.
  - **5 new tests**: fallback-root lookup, BPMP_HOME/XDG/HOME resolution.
- [x] **F1 — `bpmp install` (object-form path)**
  - NEW `modules/bpmp/src/dep/spec.zig` — `DepSpec`/`DepEntry`/`anySpec` + `parseFromManifest` (5 tests).
  - NEW `modules/bpmp/src/dep/clone.zig` — `materialise` wraps `git clone --depth 1 [--branch <b>]` + `git rev-parse HEAD`; atomic tmp-dir → CAS rename; `path:` variant; 4 tests.
  - NEW `modules/bpmp/src/dep/resolver.zig` — `plan` produces one `Action` (`clone` / `reuse_cas` / `path_symlink` / `skip_legacy`) per entry; 6 tests (legacy / path / git+branch / git+rev / frozen-missing / lock_in CAS hit).
  - NEW `modules/bpmp/src/lock.zig` — `botopink.lock` read/write (distinct from v18's `botopink.lock.json`); sorted-by-name JSON; 5 tests.
  - `commands/install.zig` — `maybeRunDepInstall` short-circuits the legacy compiler-distribution flow whenever the local `botopink.json` carries object-form deps; new `--frozen` / `--update` / `--dry-run` flags wired.
  - Symlinks `<project>/.botopinkbuild/deps/<name>` → `$BPMP_HOME/store/<name>/<rev>/`.
- [x] **F5 — `--frozen` flag + DEP-004**
  - Implemented as part of F1 dispatch — `dep_resolver.plan` returns `FrozenMissingEntry`; `commands/install.zig` surfaces DEP-004 + a hint to run a non-frozen install first.
- [x] **F6 — AGENTS.md / docs sweep**
  - `modules/bpmp/AGENTS.md` — new "botopink.lock" row, new dep/ + lock.zig in the tree, store/ layout entry, install behaviour table extended with --frozen/--update/--dry-run rows.
  - `modules/bpmp/docs.md` — full "Installing project deps from git (v0.beta.20)" section + `DepSpec` table + diagnostics table + troubleshooting line.
  - `modules/compiler-cli/src/cli/AGENTS.md` — `config.zig` row notes both shapes + DEP-001/002/003; `libs.zig` row notes `.botopinkbuild/deps/` fallback + `resolveBpmpStoreRoot`.
  - Root `AGENTS.md` — Manifest schema § extended with the object-form / `bpmp install` / `botopink.lock` paragraph.
- [ ] **F4 — install snapshot (offline-fixture smoke)** — **deferred**
  - Spec calls for an end-to-end snapshot under `modules/compiler-cli/snapshots/cli/install_e2e.snap.md` that materialises a scratch project + a local bare repo + invokes `bpmp install --offline-fixture <bare>` + `botopink build`. The `--offline-fixture` flag itself is not in the spec's clone surface, and constructing a hermetic local bare repo is large enough to be its own consumer spec. Recorded here so the v0.beta.20 closeout can carry it forward.

## Exit gate

- [x] `config.zig` accepts both legacy + object form, with 8 parser tests pinning every diagnostic.
- [x] `libs.zig` consults `.botopinkbuild/deps/` fallback; `resolveBpmpStoreRoot` plumbs the `$BPMP_HOME`/XDG/HOME chain (5 tests).
- [x] `bpmp install <path>` materialises object-form deps into `$BPMP_HOME/store/` + writes `botopink.lock`.
- [x] `bpmp install --frozen` exits with **DEP-004** when `botopink.lock` is missing entries.
- [x] Per-module AGENTS.md updated in the same commit as the code.
- [x] `zig build` green; `zig build test-bpmp` green.
- [ ] Full `zig build test` re-run on the host post-merge (compiler-core cache had to be re-warmed under the new `[]DepEntry` libs.loadDependencies signature; touched callsites: `build.zig`/`check.zig`/`test_cmd.zig`).
