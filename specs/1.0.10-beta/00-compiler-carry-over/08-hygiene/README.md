# Front 08 — hygiene

**Priority:** low — no program is wrong; comments, documents and one test.
**Depends on:** each open item lands after the front that owns its file (C-23), or is handed to it.
**Owns:** `docs.md`, `README.md`, `examples/**`, every `AGENTS.md`, `libs/std/botopink.json` and
`libs/std/AGENTS.md`, the relative links of the meta `specs/` tree, and comments — the comments
only after their files' owners
**Does not touch:** any behaviour. Every edit is a comment, a manifest, a document or a link

Paths are relative to `repository/botopink-lang/`. Item numbers are 1.0.1-beta's
[`05-repo-hygiene.md`](../../../1.0.1-beta/05-repo-hygiene.md) groups, kept so old references
resolve.

---

## What holds

| Group | State |
|---|---|
| A — the removed WAT runtime (5.6, 5.7) | The **old** runtime is gone. `wasm3` is in the tree again **by design**: it is the WAT comptime runtime of decision 84 (`comptime/runtime/persistent_wat.zig`, `modules/wasm3/`, C-26), so a grep for `wasm3` no longer measures this group. `build_options` has no occurrence in any `build.zig`; `libcResolvedTarget` is kept and its comment names a live reason (Zig 0.16 + glibc ≥ 2.41 `.sframe` `crt1.o` relocations; glibc pinned to 2.38 on linux-gnu) |
| B — 5.4 and the lib-test-runner build files | `modules/lib-test-runner/` holds `AGENTS.md` and `src/` only, and its `AGENTS.md` says the workspace `build.zig` builds it; `zig build test-vscode` runs `scripts/test-vscode.sh` |
| C — `libs/std` (5.1–5.3, 5.14) | Every `files` entry of every `botopink.json` resolves; `libs/std/AGENTS.md`'s tree matches `src/`; the "not reached by any `mod` path" warning is gone from `test-libs` (a module the manifest's `files` declares is exempt, decision 16) |
| D — vocabulary and instructions (5.8, 5.13, `docs.md`) | `examples/hello.bp` runs as its header says. Every `botopink` fence of `docs.md` and `README.md` is checked: `zig build test-docs` → **88 fences — 72 checked, 8 skipped, 0 failed**. `docs.md` § *Decided, not yet implemented* is re-derived by running every row (below). A lower-case `#[@external(node, …)]` is a located error naming `External.<Target>` (`docs.md` § Host bindings; the `reject/` cell passes). The `MIGRATION.md` link resolves. The fixture that wrote the retired `@external(<target>, …)` form (`comptime/tests/infer_decls.zig:540`) names it as the error it is |
| E — the comptime transport error (5.10) | The frame-protocol guard holds (logger off `standard_io`, own group leader, 16 MiB frame cap). `comptime/runtime/runtime.zig`'s BEAM branch reads `persistent_beam.lastTransportError()` and answers `the <host> evaluator's erl runtime failed (<error>): <message>`; with no message it stays `error.EvalFailed`, because that case is `erl` missing and the caller's hint names `PATH`. `runtime/AGENTS.md` names the reader |
| Links | Every relative link and anchor in `docs.md`, the compiler's `AGENTS.md` files, erika's, jhonstart's and emilia's docs and `specs/1.0.10-beta/` resolves, except the three links into `repository/vscode-extension/` (resolve once that submodule is checked out) |

### `docs.md` § *Decided, not yet implemented*, re-derived

Each row run in a scratch project on commonJS (erlang, beam and wasm where the row is about them):

| Row | Measured | Result |
|---|---|---|
| `Self<T>` in a generic declaration | `fn get(self: Self<T>)` → `type mismatch: expected Self, got Holder`; bare `Self` runs | stays — C-15 |
| no `;` after a braced statement | both forms compile and run; `format` prints none | stays — C-13 in decision 132's order |
| the pattern range | `1..9` in an arm is `error[pattern-range-exclusive]` naming `...`; `case 9 { 1...9 { 1 } _ { 0 } }` prints `1` on commonJS, erlang, beam and wasm | **left the table** — the row stated decision 53 inverted; § Case teaches `...` with a fence |
| an imported default | an imported `fn`'s default is not filled (`'greet' expects 2 argument(s), got 1`); an imported record's field default **is** (`Cfg(n: 1).m` prints `5`) | the limit narrowed to functions |
| a behavior-typed parameter or return | one module: runs on commonJS, erlang and beam, **traps on wasm** (`unreachable`); across a sibling `mod` or a package: `expected behavior Greeter { … }, got Bob` | taught in § behavior; both limits stated |
| the deliberately-absent forms | `is` binding a payload, a nameless payload, `val assert … catch`, plus the eight the parser names — `ternary-absent`, `bitwise-operator-absent`, `char-literal-absent`, `nested-fn-decl`, `list-spread-not-last`, `list-spread-dot-dot-dot`, `implement-clause-for`, `tuple-literal-label` — each message as printed | the table carries all eleven |

## Open

Each item below is a comment in a file another front owns, or a test in one; this front lands it
after that owner, or hands it over (C-23). The owners are 1.0.10-beta's.

**1. `primitives.d.bp` in comments** (group C, 5.1). The file is `primitives.bp`. **14 stale** —
`codegen/erlang.zig` ×10 (`:2414`, `:2445`, `:2595`, `:2842`, `:3186`, `:3206`, `:3208`, `:3219`,
`:4572`, `:8443`; `02-erlang`'s), `comptime/env.zig:838` and `comptime/infer.zig:9788,10005`
(`01-checker`'s), `language-server/src/tests/hover.zig:277` (`11-tooling`'s). Two mentions are
legitimate and stay: the extension-assertion tests `cli/resolver.zig:894` and
`lib-test-runner/src/discovery.zig:414`.

**2. `@external(<target>, …)` / `@[external(…)]` taught as current** (group D, D1). Only
`External.<Target>` is read. The comments that describe the retired forms as the live surface, by
owner: `codegen/erlang.zig` ×19 (`02-erlang`); `comptime/infer.zig` ×10, `comptime/env.zig:687`,
`comptime/diagnostics.zig:234` (`01-checker`); `ast.zig:1464,2775,2820`, `parser.zig:585`,
`parser/decls.zig:356,500` (the parser's — `01-checker` in this milestone);
`comptime/tests/std_target_gating.zig:6`, `comptime/tests/infer_errors.zig:455`,
`language-server/src/tests/hover.zig:276,278` (`C-22`, no owner). What stays: the sites that name a
retired form **as retired** — `docs.md` § Host bindings, `codegen/AGENTS.md`, `comptime/AGENTS.md`'s
R3 note, `scripts/AGENTS.md`'s `legacy` audit mode, `infer.zig:3188,3414` (the R3 refusal),
`tests/language/reject/external_lowercase_target.bp`, the parser error fixtures in
`parser/tests/errors.zig`, and the two test **names** in `codegen/tests/externals.zig:55,67`
(renaming a test re-keys its snapshot).

**3. Test-file comments that describe a lowering or an owner that moved** (step 6). All in
`src/codegen/tests/**` (C-22, no owner): `control_flow.zig:73` ("pinned, 06-wasm" — `05-wasm`),
`control_flow.zig:76` ("07-checker's to land" — `01-checker`), `narrowing.zig:90` ("registered
with 07-checker" — `01-checker`), `builtins.zig:365` (commonJS "still lowers to `console.assert`" —
decision 4 is implemented on all four backends).

**4. The transport error's diagnostic has no test** (group E). `persistent_beam.zig`'s tests assert
the transport message (the frame cap, a stray `=INFO REPORT`); nothing asserts that the message
reaches the user through `runtime.zig`'s `evalBeam`. The test belongs beside `evalBeam` —
`comptime/runtime/runtime.zig`, `18-comptime-runtimes`' file (C-26).

**5. `zig fmt --check` is red on ten files of an untouched base** — `bpmp/src/commands/{self_uninstall,self_update}.zig`,
`bpmp/src/{registry,storage}.zig`, `compiler-cli/src/cli/libs.zig`,
`compiler-core/src/comptime/{diagnostics,transform}.zig`,
`compiler-core/src/comptime/runtime/beam/{lower,program}.zig`, `language-server/src/engine.zig`.
The gate runs `zig fmt` on **staged** files only, so a front that touches one of them meets it;
`zig fmt <file>` in the owner's next commit closes each. (`comptime/tests/effect_generator.zig`,
the file `status.md` named first, passes now.)

**Acceptance:**
- [ ] `grep -rIn 'primitives\.d\.bp'` returns exactly the two extension-assertion tests
- [ ] no comment presents `@external(<target>, …)` or `@[external(…)]` as current; the sites
      listed under item 2 as naming it retired are unchanged
- [ ] `grep -rn '06-wasm\|07-checker\|F7 checker' src/` returns nothing, and no comment in
      `src/codegen/tests/**` describes a lowering the backends have changed
- [ ] a test drives a comptime body past the 16 MiB frame cap and asserts the diagnostic quotes
      `lastTransportError()`'s message, not `EvalFailed`
- [ ] `zig fmt --check` passes on every `.zig` under `modules/`
- [x] `zig build test-docs` green — 88 fences, 72 checked, 8 skipped, 0 failed — and every
      relative link of the documents this front owns resolves

## Gate

- [ ] `scripts/gate.sh --cold` green, and `zig build` / `zig build test` on the CI runners — the
      maintainer's, after the push; this front's commits are documents only, verified by
      `zig build test-docs` and `scripts/check-docs.sh`
- [x] Matching `AGENTS.md` files updated in the same commits
- [x] Commits on `front/sweep-docs`; no push, no merge

## Ownership

A comment-only edit in another front's file is safe to make and expensive to merge: each sweep is
one commit per owning file, after that file's front lands.

| Item | Files | Owner |
|---|---|---|
| 1, 2 | `codegen/erlang.zig` | `02-erlang` |
| 1, 2 | `comptime/{infer,env,diagnostics}.zig`, `ast.zig`, `parser.zig`, `parser/decls.zig` | `01-checker` |
| 1, 2 | `language-server/src/tests/hover.zig` | `11-tooling` |
| 2, 3 | `comptime/tests/**`, `codegen/tests/**` | C-22 (no owner) |
| 4 | `comptime/runtime/runtime.zig` | `18-comptime-runtimes` (C-26) |
| 5 | the ten files | the front that next stages each |
