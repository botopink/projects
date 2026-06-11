# Front C — runtime, CLI & editor tooling (test-tooling · execution · LSP · VS Code)

**Slug**: front-c-runtime
**Front territory** (edit ONLY here — disjoint from Fronts A/B):
`modules/compiler-cli/tests/*.sh` · `modules/lib-test-runner/**` · the wasm/beam run
harness · `modules/language-server/**` · `modules/vscode-extension/**`.
**Scope**: the test machinery (`test {}`, `botopink test`, the lib-test matrix), the
backend **execution** parity that Front A's snapshots can't prove (beam/wasm actually
running), and the whole editor surface — the LSP server and the VS Code client. One
worktree (`task/v13-tooling`) covers the entire front.
**Status**: pending (test-audit)

> Tags + dead-syntax table: [`../README.md`](../README.md). `[have]` = a test exists;
> `[gap]` = add it. Lines under `— net-new —` are gaps no prior spec covered.
> This file is the **single Front-C spec** — it absorbs the former `language-server.md`
> and `vscode-extension.md` (sections C3 and C4 below).

---

## C1 · test-tooling — `test {}`, `botopink test`, lib-test-runner
Source: `comptime/tests` (parser/format of `test`), `modules/lib-test-runner/src/{main,args}.zig`, cli.
```
[have] parser  ---- `test {}` / `test "name" {}` parse; `test` in a fn body errors
[have] comptime ---- `assert cond` requires bool; a test body type-checks like void; `@emit` in a test works
[have] format  ---- a test block round-trips
[have] cli     ---- `botopink test` reports pass/fail; `--filter` narrows; `--target erlang` runs
[have] codegen/node ---- a duplicate test name → stderr warning, both still run (commonJS.zig F6)
[have] run     ---- `zig build test-libs` runs every lib on node+erlang; a failing lib test → ✗, exit ≠ 0
[have] run     ---- `--target=node` aliases commonJS; `--lib rakun` filters; a no-test lib shows `–`
[have] run     ---- `--target beam` → `~ skipped-unsupported`, exit 0; `--strict` → exit 1
[have] run     ---- the matrix covers inline-test libs (std 88, erika 25, jhonstart 6) via `botopink test`
[have] unit    ---- arg parsing + lib discovery have Zig tests
[gap]  run     ---- a wasm-target lib test actually executes (today skipped-unsupported)
# — net-new —
[gap]  run     ---- a test body that throws UNCAUGHT is reported as FAIL (not a runner crash)
[gap]  comptime ---- `assert cond, "msg"` surfaces the custom message on failure
[gap]  run     ---- an empty test block `test "x" {}` passes
[gap]  run     ---- `--filter` matching MULTIPLE tests runs all; matching none → clear report
[gap]  run     ---- the runner aggregates a mixed matrix (pass/skip/fail) with the right exit code
```

## C2 · backend execution parity (the `run/*` Front A can't prove)
Source: `modules/compiler-cli/tests/{mutual_recursion,std_erlang}.sh` + a wasm/beam harness.
```
[have] run/erlang ---- mutual_recursion.sh green (recursion guard)
[gap]  run/erlang ---- std_erlang.sh green for order/dict/queue/sets (blocked on `case…of` codegen reds)
[gap]  run/beam ---- a records/enums/case/lambda program runs on BEAM via script
[gap]  run/wasm ---- a numeric program runs under wasmtime (`--invoke main`) and asserts the result
[gap]  run/* ---- string interpolation "${a}-${b}" produces the SAME string on every backend
[gap]  run/* ---- a Result/Option chain + a 3-variant case run with parity across backends
[gap]  run/erlang ---- a closure capturing a local var runs (make_fun); [gap] run/beam deep tail recursion (call_only)
[gap]  run/{node,erlang} ---- a multi-folder `mod`/`pub mod` package builds + runs end-to-end
[gap]  infra   ---- beam + wasm execution reachable from a single `zig build` step (today: scripts only)
```
(The `case…of` erlang reds surface in erika/jhonstart/onze/rakun under the lib matrix —
the fix is product work; here we add the run scenario that pins it.)

---

## C3 · language-server — every `botopink-lsp` request + engine behaviour
Source: `modules/language-server/src/tests/*.zig` (19 files, ~130 `test {}` + 88 snapshots
under `snapshots/lsp/`); `helpers.zig` (`compile`/`compileEval`/`compileMulti`). The
`@ExprCustom` overlay here is the editor counterpart of Front B's lib-side expansion (B2);
multi-module gaps feed [`lsp-project-awareness`](../../v0.beta.14/specs/lsp-project-awareness.md).

> **C3 status (v0.beta.13 — done).** Closed: cross-module **references**, **rename**, and
> **import-missing codeAction** (`tests/cross_module.zig`, project-index over a real on-disk
> fixture); the didOpen→didChange→didClose **lifecycle** (`tests/lifecycle.zig` — which
> surfaced & fixed a double-dup leak in `files.FileCache.change`); **codeAction remove unused
> import**; **typeDefinition** on a generic (`Array<i32>`) binding; and a **comptime
> annotation `fail`** diagnostic (`@external` arity, node-free). Recorded/deferred: **add
> missing case patterns** (exhaustiveness is enforced at type-check time, so a non-exhaustive
> `case` has no `.ok` bindings for the types-only helper — needs a best-effort-bindings path);
> the precise **range** of the annotation-`fail` diagnostic (currently null `loc` — a Front-A
> span-propagation nicety); **typeDefinition** optional/function-typed; hover async-unwrap for
> `@Future`/`@AsyncIterator` (the `@Iterator` case already pins the mechanism); and
> request-after-shutdown. The `→ v14` items below (local-scope completion/def, decorator-emit
> bindings, cross-module sub-language tokens) ship with their fix in `lsp-project-awareness`.

> **The structural gap.** Every existing test compiles a **single self-contained document**.
> `compileMulti()` exists in `helpers.zig` but is **called by no test**; the one cross-module
> case (`definition: imported symbol`) hand-builds a `ModuleSource[]`. No test exercises a
> decorator that `@emit`s. These are exactly the shapes that broke in the field reports.

```
# ── lifecycle / transport ──
[have] lsp   ---- message framing: single frame, consecutive frames, extra headers, EOF (messages.zig)
[have] lsp   ---- initialize advertises every provider capability; shutdown then exit ends the loop
[gap]  lsp   ---- didOpen→didChange→didClose updates the cache and (re)publishes diagnostics each step
[gap]  lsp   ---- a request arriving after shutdown is rejected (no handler runs)

# ── diagnostics ──
[have] lsp   ---- empty / single / multiple decls produce the expected diagnostic set
[have] lsp   ---- parse errors (unexpected token, unclosed) surface with a range
[have] lsp   ---- a type mismatch surfaces as a diagnostic
[gap]  lsp   ---- a comptime/decorator `fail`/`failAt` surfaces as a diagnostic at the annotated decl

# ── completion ──
[have] lsp   ---- empty prefix lists all bindings; a prefix filters; no-match returns empty
[have] lsp   ---- fn binding carries Function kind; item detail shows the inferred type
[have] lsp   ---- cursor in a string / comment / on a numeric literal returns empty
[have] lsp   ---- dot-completion: enum variants, record fields, iterator receiver
[have] lsp   ---- std-module member completion (`list.`); builtin-receiver (`42.`/`true.`/`xs.`/`"s".`)
[have] lsp   ---- labeled-argument completion inside `fn(|)`
[have] lsp   ---- module-name completion inside `from "…"` (moduleCompletion)
[gap]  lsp   ---- completion includes function-LOCAL bindings: params, `val`/`var`, `comptime` param, closure binder   (→ v14 F1)
[gap]  lsp   ---- completion still returns bindings in a file whose decorator `@emit`s                                   (→ v14 F2)
[gap]  lsp   ---- completion resolves names imported across `mod` siblings / `from "<lib>"` (multi-module)               (→ v14 F3)

# ── definition / typeDefinition ──
[have] lsp   ---- go-to-def on val / fn / record / enum usage in the same file; URI preserved
[have] lsp   ---- go-to-def on an imported symbol jumps to the defining module (hand-built ModuleSource)
[have] lsp   ---- go-to-def on a std member (`list.map`) / bare std module name; non-std qualifier misses cleanly
[have] lsp   ---- typeDefinition on a named type; literal returns null
[gap]  lsp   ---- go-to-def on a function param / `var` local / closure binder lands on its binding site            (→ v14 F1)
[gap]  lsp   ---- go-to-def on `from "<lib>"` member access (`Response.created`) via the lib botopink.json           (→ v14 F3)
[gap]  lsp   ---- typeDefinition on a generic / optional / function-typed binding (beyond the literal case)

# ── hover ──
[have] lsp   ---- hover on val (int/string), fn, annotated fn; keyword `null`; second-line position
[have] lsp   ---- hover on a std-module fn renders its signature + doc comments
[have] lsp   ---- hover on a builtin interface method (int / array)
[have] lsp   ---- hover on an effectful (`#[@…]`) fn shows the effect
[gap]  lsp   ---- hover async-unwrap: `@Future<T>` / `@Iterator<T>` / `@AsyncIterator<T,_>` element type surfaced

# ── references / rename / prepareRename ──
[have] lsp   ---- references with/without the declaration; ranges correct; fn usages; unused binding
[have] lsp   ---- rename a val/fn with N usages → correct edit ranges; literal is not renameable
[have] lsp   ---- prepareRename rejects keyword / literal / Self; accepts an identifier / fn name
[gap]  lsp   ---- cross-module references find usages in OTHER files via the project index (compileMulti)
[gap]  lsp   ---- cross-module rename edits the current file AND every external file with the symbol (WorkspaceEdit)

# ── semantic tokens (incl. the sub-language overlay — Front B is the producer) ──
[have] lsp   ---- empty doc; val binding; free / interface / effectful fn; builtin `@Type`; enum/record; comments+keywords; member access
[have] lsp   ---- comptime param tokenized `parameter readonly`
[have] lsp   ---- sub-language overlay merges lexed + Custom AST tokens into one sorted stream (sublanguage.zig)
[have] lsp   ---- erika/html semantic tokens, in-string diagnostics, hover (CustomNode ref), go-to-def; plain strings unchanged
[have] lsp   ---- /range request filters tokens to the requested line span
[gap]  lsp   ---- semantic tokens for a cross-module `erika "…"` (Custom AST only exists once the template resolves)   (→ v14 F4)

# ── signatureHelp / inlayHint / codeAction / folding / formatting / documentSymbol ──
[have] lsp   ---- signatureHelp highlights the active param; outside a call / zero-param / non-fn behave; builtin method drops self
[have] lsp   ---- inlayHints: inferred val type (suppressed when annotated); param-name hints (suppressed on bare-name); lambda param types; range-filtered
[have] lsp   ---- codeAction: add type annotation to an untyped val (and the already-annotated / empty-source no-ops)
[have] lsp   ---- foldingRange: fn/struct/record/enum/interface blocks; consecutive `use` imports; test block; empty source
[have] lsp   ---- formatting: already-formatted no-op; invalid/empty source; full-document edit + end position
[have] lsp   ---- documentSymbol: val/fn/record/enum + children (fields/variants/methods); test block as a Method symbol; selection range
[gap]  lsp   ---- codeAction: remove unused import
[gap]  lsp   ---- codeAction: add missing case patterns to a non-exhaustive match
[gap]  lsp   ---- codeAction: import a missing symbol (suggests `import { X } from "module"` via the project index)
[gap]  lsp   ---- signatureHelp on a generic / multi-param-label signature beyond the basic cases
```

LSP notes:
- **`compileMulti()` is the unlock.** Five `[gap]`s (cross-module completion / def / refs /
  rename, import-missing code action) all need a real multi-module fixture. The helper
  exists — no test uses it. A `tests/cross_module.zig` file is the natural home.
- **Three `[gap]`s are bug-fixes, not just missing tests** (`→ v14`): local-scope
  completion/def, decorator-`@emit` bindings, cross-module sub-language tokens — their tests
  ship with the fix in `lsp-project-awareness`; listed here so the audit is complete.
- **codeAction is the thinnest provider**: 3 of 4 actions implemented but untested — pure test-add.

---

## C4 · vscode-extension — the VS Code client
Source: **none today.** `package.json` has no `test` script, no test runner
(`@vscode/test-electron`/mocha/jest absent), no `*.test.ts`, no CI. Every scenario below is a
`[gap]` — the first work item is standing up a harness.

> **The whole module is untested.** Several behaviours are **pure functions** with zero VS
> Code dependency (`parseTestOutput`, `argsFor`, `quoteArg`, the `symbols.ts` predicates, the
> target-fallback) — unit-testable with a plain node runner, no Electron host. The rest
> (providers, lifecycle, file I/O) need `@vscode/test-electron`. Land the cheap pure-function
> tests first, gate them in CI, then decide whether the host tier is worth its weight.

### F0 — stand up a unit-test harness
- [ ] Add a `test` script + a lightweight runner (`node:test` or vitest) that compiles `src/`
      and runs `*.test.ts` against the **pure** exports. No VS Code host.
- [ ] Export the pure helpers where needed (`parseTestOutput`, `argsFor`, `label`, `groupFor`,
      `quoteArg`, `flattenSymbols`, `isTestSymbol`, `isMainSymbol`, `isDocumentSymbolArray`,
      target-fallback). Keep `vscode` imports out of those test-reachable paths (or shim it).
- [ ] Wire it into the repo gate so the extension is no longer build-only.

```
# ── pure / unit (no VS Code host) ──
[gap] unit  ---- parseTestOutput: an "ok <name>" line → { passed: true }
[gap] unit  ---- parseTestOutput: a "FAIL <name> (<msg>) at <loc>" line → { passed: false, message }
[gap] unit  ---- parseTestOutput: unrelated / malformed lines ignored; empty output → empty map
[gap] unit  ---- parseTestOutput: duplicate test names + special chars in name/message handled
[gap] unit  ---- tasks.argsFor: check → ["check"]; format → ["format"] (no extra args)
[gap] unit  ---- tasks.argsFor: build → ["build","--target",<target>]; target falls back to the active target when unset
[gap] unit  ---- tasks.argsFor: test → ["test","--target",<t>] and appends ["--filter",<f>] only when a filter is given
[gap] unit  ---- tasks.label / groupFor: build/test labels show command+target; group = Build/Test, none for check/format
[gap] unit  ---- extension.quoteArg: plain identifiers pass through; spaces/specials get quoted; inner quotes escape
[gap] unit  ---- symbols.flattenSymbols: depth-first traversal of a nested DocumentSymbol tree in order
[gap] unit  ---- symbols.isTestSymbol / isMainSymbol: Method ⇒ test; Function named "main" ⇒ main; others ⇒ false
[gap] unit  ---- symbols.isDocumentSymbolArray: distinguishes DocumentSymbol[] from SymbolInformation[]
[gap] unit  ---- target fallback: a botopink.json with a valid target loads it; invalid/missing → DEFAULT_TARGET ("commonJS")
[gap] unit  ---- target write: setTarget round-trips botopink.json preserving sibling fields (JSON parse→write)
[gap] unit  ---- cli/lsp path resolution: absolute used as-is; relative resolved vs workspace folder; empty → bare "botopink"

# ── host integration (require @vscode/test-electron + a built LSP) ──
[gap] ext   ---- activation: opening a .bp file starts the LSP client; restartServer reconnects it
[gap] ext   ---- CodeLens: a file with test blocks + `fn main` shows Run-test / Run lenses wired to the right commands
[gap] ext   ---- TaskProvider: the four tasks (check/build/test/format) are offered; check carries the problem matcher
[gap] ext   ---- TestController: tests in a .bp file are discovered from LSP symbols; a run spawns the CLI and maps pass/fail to the UI
[gap] ext   ---- target switcher: picking a target updates botopink.json AND the status-bar item; an external edit reloads via the watcher
[gap] ext   ---- comment-continuation OnEnterRules continue `//` / `///` / `////` on newline

# ── static contributions (assertable without a full host) ──
[gap] ext   ---- the tmGrammar tokenizes keywords/decls/strings/attributes/comments for a sample .bp (scope-name snapshot)
[gap] ext   ---- the markdown-codeblock injection highlights ```botopink / ```bp fences
[gap] ext   ---- language-configuration: bracket auto-close + indent rules behave on a sample
[gap] ext   ---- snippets.json is valid JSON and each body parses (no broken placeholders)
[gap] ext   ---- package.json contributes match the code: every registered command id has a contributes.commands entry and vice-versa
```

vscode notes:
- **Tier the effort.** The 15 `unit` scenarios are cheap, deterministic, and catch the bugs
  that bite (a regex drift in `parseTestOutput` silently shows every test green-on-failure;
  an `argsFor` slip ships the wrong `--target`). Do these first under F0. The `ext` tier needs
  a downloaded VS Code + a built `botopink-lsp` and is slow — worth it for TestController +
  target switcher, optional for the rest.
- **`parseTestOutput` is the highest-value target** (`OK_LINE`/`FAIL_LINE` regex in
  `testExplorer.ts`): pin it with fixtures of real `botopink test` output across backends.
- **Keep `vscode` out of the unit path** — move pure helpers to `vscode`-free files or shim it.

---

## Notes
- This front never edits `modules/compiler-core/src` (Front A) or `libs/`/`examples/`
  production code (Front B) — only CLI test scripts, the lib-test-runner, the LSP, and the
  VS Code client. One worktree (`task/v13-tooling`) covers C1–C4.
- Highest value: close `std_erlang.sh` (or pin the `case…of` red as a recorded limitation),
  stand up the wasm execution smoke test (C2), the LSP `compileMulti` cross-module fixtures
  (C3), and the vscode pure-function unit harness (C4 F0).
