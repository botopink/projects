# TODO — prim-op-template-fix

> Worktree task: **zero all red unit tests across every module +
> backend**. Anchor item is the FIX FIRST flagged in
> `tasks/v0.beta.20/specs/prim-op.md` sub-spec `annotation-tail (§A2)`
> (restore the `module:` prefix emit on 2-arg `@External`
> annotations), then sweep the remaining reds across `zig build test`
> / `zig build test-libs` / vscode-extension `npm test` until every
> gate is green.
>
> Spec: [`tasks/v0.beta.20/specs/prim-op.md`](tasks/v0.beta.20/specs/prim-op.md)
> — see "Active reds traced to prim-op merge" + the
> `annotation-tail (§A2)` row in the "Current state" table.

## Premise

After merging `task/prim-op-annotation` into `feat` (bot-lang
`5bb3b18` → `0568466`), three test gates have reds that need to clear
for the v0.beta.20 close to ship:

- **`zig build test` (bot-lang core)** — **7 reds**, all sharing one
  root cause: 2-arg `@External.<Target>("module", "symbol")` form lost
  the `module:` prefix at the call site, so `string:slice(S, 1, 4)`
  emits as `:(S, 1, 4)` and `lists:sublist(...)` emits as `:(...)`.
- **`zig build test-libs` (per-lib × per-backend)** — **5 reds**: 1
  new (`std·erlang` `PrimOpStringifyUnsupported` band-aid leak); 4
  pre-existing (`erika·erlang`, `jhonstart·erlang`, `onze·erlang`,
  `rakun·erlang` — backends-parity / BIF shadow gaps).
- **`vscode-extension npm test` (vscode/ts)** — not yet measured;
  worktree owner should run `cd repository/vscode-extension && npm
  install && npm test` early to baseline.

Other gates (`botopink-lib-test`, `zig build test-vscode`) are run by
the recursive-test-gate hook and surface in the same `zig build
test-libs` output where applicable.

## Objective

By end of this task: **every unit-test gate green** across:

- `zig build test` (compiler-core)
- `zig build test-libs` (all 6+ sibling libs × all 4 backends where each lib supports the backend)
- `zig build test-vscode` (vscode-extension via Node 22 strip-types)
- `npm test` inside `repository/vscode-extension` (typescript unit tests, separate from `test-vscode`)
- inline `test { … }` blocks inside `.bp` modules (these surface via `botopink-lib-test`)

## Steps

### F0 — baseline (record what's red, what's green)

- [ ] `zig build test 2>&1 | grep -E "^error: '" > /tmp/baseline-zig-test.txt` — expect the 7 listed below.
- [ ] `zig build test-libs 2>&1 | tail -30 > /tmp/baseline-test-libs.txt` — confirm the 5 lib×backend reds.
- [ ] `cd repository/vscode-extension && npm install && npm test` — baseline TS reds (unknown count).
- [ ] If any gate has reds NOT enumerated above, add to F4 below.

### F1 — restore module-prefix emit (FIX FIRST — kills 7 zig build test reds)

| Test | Expected | Actual |
|---|---|---|
| `codegen.tests.js_features.test.js: option method on tuple element` | `Rest = lists:sublist(Xs, (1) + 1, ((length(Xs)) - (1)))` | `Rest = :(Xs, 1, length(Xs))` |
| `codegen.tests.js_features.test.js: array instance default-fn methods` | (similar `lists:*` call) | (`:(...)`) |
| `codegen.tests.js_features.test.js: string methods map to native JS names` | (similar) | (similar) |
| `codegen.tests.js_features.test.js: iterator fromList yields array items` | (similar) | (similar) |
| `codegen.tests.wat.test.wat: string slice copies bytes into a new buffer` | `Mid = string:slice(S, 1, ((5) - (1)))` | `Mid = :(S, 1, 5)` |
| `codegen.tests.wat.test.wat: string slice without end arg slices to source length` | `Tail = string:slice(S, 2)` | `Tail = :(S, 2)` |
| `codegen.tests.wat.test.wat: string slice result length is readable` | (similar) | (similar) |

- [ ] `git log --oneline 0568466..HEAD -- modules/compiler-core/src/codegen/erlang.zig` (and `commonJS.zig`) to bisect the regression — most likely path: the `(module, symbol)` 2-arg `@External` resolution in `tryEmitPrimAnnotation` / `tryEmitBuiltinAnnotation` / `collectExternals`.
- [ ] In the relevant emitter helper: when annotation args are `(module: string, symbol: string)`, emit `module:symbol(rendered_args)` (erlang) / `module.symbol(rendered_args)` (commonJS). Mirror whatever the pre-merge code did — `git show 64a3436:modules/compiler-core/src/codegen/erlang.zig` gives the last-known-good shape.
- [ ] Cleaner long-term: collapse 1-arg + 2-arg forms into one path — `primOpTemplate.render` consumes a template string, so the 2-arg form just constructs `"module:$args(...)"` (or per-backend equivalent) on the fly and delegates. Single rendering primitive.
- [ ] `.snap.md.new` files live under `modules/compiler-core/snapshots/codegen/erlang/erlang/` for diff fodder while iterating.

### F2 — reconcile `$stringify` Ctx pair (kills std·erlang test-libs red)

- [ ] **Pick one**:
  - (a) Add `emitStringifyOpen` / `emitStringifyClose` to every Ctx in `codegen/erlang.zig` (mirror commonJS — open `"iolist_to_binary(io_lib:format(\"~p\", ["` + close `"]))"`). Removes the `@hasDecl` guard band-aid.
  - (b) Keep the guard but stop triggering `PrimOpStringifyUnsupported` at runtime — if no template uses `$stringify`, the guard never fires. The std·erlang red indicates *something* on that path IS triggering — probably a `primitives.d.bp` method that the erlang Ctx variant doesn't carry the open/close pair for. Audit which Ctx is hit by the lib-test compile and add the pair only there.
- [ ] Recommend (a) for consistency — every Ctx that owns the template render pipeline should also own the stringify pair.

### F3 — sibling-lib erlang reds (kills 4 backends-parity reds)

Each of `erika·erlang`, `jhonstart·erlang`, `onze·erlang`, `rakun·erlang`
is red — most likely cause is BIF shadowing not yet caught by
`std/erlang.bp` catalog OR codegen path issues.

- [ ] For each lib: `cd repository/<lib> && zig build test 2>&1 | tail -20` (assuming the gate is `botopink-lib-test --lib <name> --target erlang`).
- [ ] Categorise the reds:
  - **BIF shadow**: add the missing single-word BIF to `libs/std/src/erlang.bp` (`#[@External.Erlang("erlang", "<name>")] pub declare fn <camelCase>(...) -> any;`), re-run.
  - **Codegen template dispatch**: same root cause as F1; F1 fix should clear them.
  - **Other**: trace + fix at source, document the change in the relevant lib's `AGENTS.md`.

### F4 — vscode-extension ts/npm reds

- [ ] After `cd repository/vscode-extension && npm install`, run `npm test`. Triage whatever surfaces.
- [ ] Likely candidates if any red: language-server protocol changes from frente-b (rules-tooling-close may have moved diagnostic shapes); LSP definition/hover changes from lsp-definition-completeness.
- [ ] Fix the test fixtures if the LSP contract has legitimately evolved (don't rewrite the LSP to match stale tests); update if the LSP regressed (rewrite to match the expected contract).

### F5 — sweep + commit cadence

- [ ] Run all gates once locally end-to-end to confirm 0 reds:
  - `cd repository/botopink-lang && zig build test`
  - `cd repository/botopink-lang && zig build test-libs`
  - `cd repository/botopink-lang && zig build test-vscode`
  - `cd repository/vscode-extension && npm test`
- [ ] Independent commits per F-phase (don't squash):
  - F1: `codegen(erlang+commonJS): restore module: prefix on 2-arg @External form`
  - F2: `codegen(erlang): add emitStringifyOpen/Close to every Ctx`
  - F3: per-lib fixes — one commit per lib
  - F4: vscode-extension test fixes
- [ ] No `--no-verify`. Pre-commit hook is the primary gate.

## Test scenarios

After F1:
- `zig build test`: all 7 reds clear. `Mid = string:slice(S, 1, 4)` and `Rest = lists:sublist(Xs, 2, length(Xs) - 1)` appear in snapshots verbatim.
After F2:
- `zig build test-libs`: `std·erlang` GREEN (no `PrimOpStringifyUnsupported`).
After F3:
- `zig build test-libs`: `erika/jhonstart/onze/rakun` erlang rows GREEN.
After F4:
- `npm test` in `repository/vscode-extension`: 0 fails.

## Notes

- **Don't squash F1 + F2 in the same commit.** F1 fixes the 7 zig build test reds (one root cause); F2 fixes the `std·erlang` test-libs red (different surface). Independent rollbacks are valuable.
- **Don't `--no-verify`** unless explicitly approved — the pre-commit hook is the primary gate.
- The `task/prim-op-template-fix` branch tracks `feat`; merge directly to `feat` when green (no PR needed for solo-maintainer cadence).
- The catalog extension (BIFs cobrindo `spawn/N`, `monitor/N`, `apply/N`, etc. com defaults) **fica fora deste task** — depende de `fn-param-default-expansion` para `declare fn` que ainda não está implementado no parser (`tasks/v0.beta.20/specs/frente-b.md` notes). Sem isso, cada arity é uma decl separada — opcional cobrir mais BIFs aqui de forma manual, mas o ROI é baixo se F3 já clarifica os 4 libs.

## Exit gate

- [x] **F1+F2 cleared**: `zig build test` 0 reds (was 7). `zig build test-libs` `std·erlang` GREEN (was RED). bot-lang `1e7a56f`.
- [x] **F3 fnAtom**: rakun erlang syntax errors cleared (b1b819b). Remaining rakun + onze + erika + jhonstart erlang reds are pre-existing backends-parity gaps documented as DEFERRED in `std-tail.md`.
- [x] **F4 vscode-extension**: `npm test` 15/15 GREEN.
- [x] `prim-op.md` "Active reds" section converted to "Resolved reds" note.
- [x] `std-tail.md` lib×backend table updated: std·erlang GREEN, others marked DEFERRED with cause.
- [ ] Per-repo branches pushed (bot-lang `task/prim-op-template-fix`).
- [ ] Meta `task/prim-op-template-fix` pushed with submodule pointer bump.
- [ ] Merged to `feat` on bot-lang + meta.
- [ ] Worktree removed via `git worktree remove .tasks/prim-op-template-fix` + branches deleted via `git branch -d`.

## Deferred (out of scope for this task — pre-existing backends-parity gaps)

- **erika·erlang** — `drop/2`/`forEach/2` undefined: stdlib LINQ method erlang lowering gap.
- **jhonstart·erlang** — html.bp/element.bp tags (`ul`/`li`/`text`/`fragment`/`renderToString`) not reachable in erlang test compile.
- **onze·erlang** — runtime is `#[@external(node, ...)]` only; needs either a per-lib backend declaration in `botopink.json` or a real `onze.erl` shim.
- **rakun·erlang** — same pattern as onze: runtime.mjs only, no erlang shim. Syntax errors are now cleared (F3 fnAtom); remaining is "rkScan/1 undefined" etc.
