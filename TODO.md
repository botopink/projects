# TODO — backend-parity

> Live checklist for branch `task/backend-parity` (worktree `.tasks/backend-parity/`).
> Spec (intent, immutable): [`tasks/v0.beta.3/specs/backend-parity.md`](tasks/v0.beta.3/specs/backend-parity.md)

> **Goal**: close the open backend/stdlib gaps (stdlib-gleam known gaps 1, 3, 4,
> 7, 8 + WASM runner + duplicate-name warning) and the 5 live `botopink test`
> failures found 2026-06-07. Phases are independent — order by impact.

**Suggested order**: F7 → F8 (cheap, unblock 3 whole suites) → F0 → F9 → F1 → F2 → F3 → F4 → F5 → F6.

## F7 — `#[@external(node, …)]` against JS globals  ✔ done
- [x] JS codegen: reference globals (`Math`, `console`, `JSON`, …) directly
      instead of `require('Math')` (allowlist `js_global_namespaces` in
      `commonJS.zig`; `require` stays for relative/package paths)
- [x] Snapshot `codegen/node/external_global_math`
- [x] `float` suite green under `cd libs/std && botopink test` (4/4)

## F8 — JS reserved-word sanitization  ✔ done
- [x] Rename reserved-word identifiers on emission (`with` → `with_`,
      `delete` → `delete_`) — params, locals, fn names, destructure binds,
      match-arm binds; consistent across call sites; `exports.<name>` keeps the
      original botopink name (`jsIdent` helper in `commonJS.zig`)
- [x] ES2015+ reserved-word table (true/false/null/of omitted — valid JS)
- [x] Snapshot `codegen/node/reserved_word_identifiers` (test js_features.zig)
- [x] `sets` suite green (9/9); `string` + `sets` modules load — remaining
      string failures are F2 (snake_case dispatch), not reserved words

## F0 — Iterator JS codegen (known gap #8, widened)  ✔ done
- [x] Fix `*fn` lowering: `return <iter>` → `yield*` delegation; `loop { yield }`
      → `for…of` with native `yield` (was `.map()`, yielded nothing). Nested
      lambdas guarded so their `return` stays `return` (`in_generator` flag).
- [x] Cover `range`/`toList`/`fold`/`map`/`filter`/`take` + `fromList`/`repeat`
- [x] Snapshot `codegen/node/iterator_fromlist_yields_array_items`
- [x] `iterator` suite green (12/12); known-gap note removed from
      `libs/std/AGENTS.md` + `iterator.bp`/`iterator_test.bp`

## F9 — `?T` runtime repr in tuple returns  ◀ queue 3/7 FAIL
- [ ] Trace why `.unwrapOr` is missing on tuple-extracted `?T` (commonJS)
- [ ] Fix lowering (dispatch on inferred `?T` type, not runtime wrapper)
- [ ] Snapshot `codegen/node/option_method_on_tuple_element`
- [ ] `queue` suite green

## F1 — Literal method receivers (known gap #4)
- [ ] Parser: literals as method-call receivers (`"a,b".split(",")`)
- [ ] Formatter round-trips; snapshot `parser/literal_method_receiver`
- [ ] Update string tests to direct form; remove known gap #4 from AGENTS.md

## F2 — snake_case → camelCase method dispatch (known gap #1)
- [ ] JS name-mapping for builtin string/array methods (`to_upper` → `toUpperCase`, …)
      — table shrinks if stdlib-interface normalizes names at definition
- [ ] Snapshot `codegen/node/string_snake_to_camel_dispatch`

## F3 — Erlang/BEAM std package loading (known gap #3) — heaviest
- [ ] Multi-module compile (separate `.erl`/`.beam`) or inline into entry module
- [ ] Wire std package into `comptime/runtime/erlang.zig`
- [ ] Snapshot `codegen/erlang/std_package_list_map_via_erlang`

## F4 — `?.` codegen for Erlang/BEAM/WASM (known gap #7)
- [ ] Identify record-field-access blocker per backend
- [ ] Erlang: case/match on `{ok, Val}`; WASM: conditional on optional tag
- [ ] Snapshots `codegen/erlang/optional_chain`, `codegen/wasm/optional_chain`

## F5 — WASM test runner (deferred from test-blocks)
- [ ] WASM runner shim + wire into `botopink test` CLI
- [ ] Snapshot `codegen/wasm/test_runner_basic`

## F6 — Duplicate test name warning (deferred from test-blocks)
- [ ] `Diagnostic.warning` on duplicate test names per file
- [ ] Snapshot `comptime/duplicate_test_name_warning`

## Notes
- Known gap #5 (structural `==` on arrays in JS) stays deferred — workaround
  `.join(…)` documented; no fix phase here.
- Verify suites with `cd libs/std && botopink test` after each phase.
