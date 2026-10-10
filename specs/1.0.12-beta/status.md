# Status — 1.0.12-beta

**Date:** 2026-10-10 · **Base** (each repository's `feat`): botopink-lang `856bbc69` (batch 21: typed meta keyed by type — 298, 370 (1); section values and records on the comptime runtime — 34 s5) · rakun `d609f8c` · jhonstart `50514f1` · emilia `9c3e24a`
· onze `783af40` · erika `8f88482` · vscode-extension `f041865`

**Fronts:** 72 — **0 done** · **23 partial** · **49 not started**.

| Track | Done | Partial | Not started |
|---|---|---|---|
| `00-gate` | — | 114 | — |
| `01-compiler` | — | 01 · 02 · 03 · 04 · 05 · 07 · 12 · 14 · 17 · 18 · 26 · 129 · 130 · 134 | 16 · 23 · 24 · 139 |
| `02-std-and-packaging` | — | 97 | 98 |
| `03-bundled-libs` | — | 102 · 103 · 104 · 106 · 125 | 105 · 107 |
| `04-rakun` | — | 13 · 92 | the other 18 |
| `06-emilia` | — | 33 | 34 |
| `05-jhonstart` · `07-onze` · `08-bpp` · `09-cardume` · `10-specs` · `20-snap` | — | — | all (3 · 5 · 11 · 1 · 1 · 1) |

**Gate:** `scripts/gate.sh --cold` green on botopink-lang `576c8d17` (batch 3: every stage; test-libs
123 passed, 0 failed; language tests 2431 passed, 0 failed) — 7m54s wall against the 7m30s budget
under load 16–20, so 114 step 7 (≤ 450 s on an idle machine) stays open. botopink-lang's
GitHub CI still owes a green run on `feat` (114 step 3).

Each line: `front/step — what is left · blocker`. Lanes: **L1** finish what is on `feat` · **L2**
the libraries' critical path · **L3** ready to open now · **L4** later, in the waves of
[`fronts.md`](./fronts.md) § Execution order of tracks 03–08 · **L5** blocked on a decision.

## L1 — finish what is already on `feat`

- [ ] 114 s3 — botopink-lang `test.yml` green on GitHub on `feat` · the `libs` job was red on `94a9c3ef` on Node 20 (`fs.globSync`, five `std·commonJS` `fs.glob` tests, needs Node 22) — fixed in botopink-lang `6d95d8fc` (both Node installs at 22); the box stays open until a green run is read
- [x] 114 s6 box 1 — vscode-extension workflow installs the compiler's OTP 28 (vscode-extension `f041865`)
- [x] 114 s6 box 2 — vscode-extension's workflow green on `feat` (`f041865`)
- [x] 114 — the runtime cache never stores a run not ended by its own exit: `RunStatus.interrupted` (a signal, a stop, an `erl` that printed its break handler's banner and halted 0) is never recorded nor cached, wasm included; `HARNESS_VERSION` `6-own-exit` drops older entries (`tests/runtime_scratch.zig` "never cached"; bugs-sweep patch 01, bs-c)
- [ ] 114 — `codegen/runtime.zig`'s own `test` blocks never run: `codegen/tests.zig` does not import the file (`runtimeTrapLog`, `compileFailureLog`, the duplicate-atom refusals — `-Dtest-filter` finds none) · none
- [x] 114 — `result_store.sh` no longer reads a sibling checkout: `check-docs.sh`'s default library roots are this checkout's `libs/` and every sibling under `repository/` holding a `botopink.json` (vscode-extension's included), each hashed whole into every key; `--lib-root` replaces them and the test names its own (bugs-sweep patch 02; the gate's cost of it: bs-d)
- [x] 114 — onze-cli `start_test.bp` asks the OS for each server's port (`freePort`, a listener on port 0) instead of 43101/43102; both cells green run side by side (onze-wave patch 05, lands with the coordinator)
- [ ] 114 s7 — a cold gate recorded on the current tip, ≤ 450 s, exit-check counts re-derived · a machine with `zig` and `erl`
- [x] 114 s8 boxes 1–2 — 133's emitted modules byte-identical, measured; rakun's `test.yml` glibc comment says 2.35
- [x] 114 s8 box 3 — emilia `test.yml`'s jhonstart checkout removed (its own emilia patch, after 06-emilia/33 s2)
- [x] 114 — the four other libraries' `test.yml` stale glibc 2.38 comment says 2.35 (emilia `b3d877e`, erika `44aef93`, jhonstart `0ba3c55`, onze `d6664c8`)
- [x] 01-compiler — the node floor is 22 (std's `fs.glob` calls `fs.globSync`): `codegen/AGENTS.md`'s `toReversed` note, and the `node ≥` rows of `AGENTS.md`, `README.md` and `docs.md` (bugs-sweep patch 09)
- [ ] 01-checker s6 box 3 — `throw` in a `case` arm under `@Result` · 04 s6
- [x] **01-checker s21 (priority, 331)** — every `comptime` runs on the comptime runtime (BEAM or WAT), never on the target; the same value on the four targets; a declared function's reference lifted; rakun `beans()` green unchanged; a decorator body's helper building another module's record (`block_eval.typesReached`)
- [x] 134 s4 (267) — the variadic parameter `..name: T[]`; 134 s6 (269) — `@getContext(T)` answers `Component<T, T>`, refused outside `use`; 134 s2 — `Type.pick` / `Type.omit` declared (no cell calls them yet: 01-checker s28) · botopink-lang `56d4bc29`
- [ ] 134 — `registerStdlib` now runs the associated-type rewrite on std modules (`comptime.zig`, landed with batch 8 for `Type.Field<T>`): owner 01-checker · none
- [x] 01-compiler — a string template in a method body (a type's, an enum's, a behavior's `default fn`) reached every backend's `stringTemplate => unreachable`: the method-body walk desugars it, and runs whatever the maps hold (`run/template_in_type_method`, four targets; bugs-sweep patch 04)
- [x] 01-compiler — a type's associated fn is arity-checked: a short call filled from the declared defaults, a labelled one reordered, any other count refused at the call (`reject/associated_fn_too_many_arguments`, `reject/associated_fn_missing_argument`, `run/associated_fn_of_type_default`; bugs-sweep patch 05, bs-a)
- [ ] 140 (334) — steps 1–3 and 6's loader landed (botopink-lang `56d4bc29`: `wasm.host`, `@External.Wasm(host:)`, the wasi build a preview 2 component, the browser `.wasm` + `.mjs`, every wasm cell on both hosts); open: steps 4–5 and 6's `@Task` (392: a Promise's behaviour — the state machine and its scheduler; 393; 394), the binary component encoding, std's `External.Wasm` declaration without `host` · a wasm build binds to wasmtime / WASI preview 2 (`wasi:http`, clocks, pollables; `@Task` blocking on pollables), `browser` together (one `.out` on both) · then 97 s17 (`io/http`, `async` on wasm)
- [x] 97 s16 (333 (A), first) — `unicode.normalize` in botopink on the four targets over `unicode_tables.bp`, generated by `zig build gen-unicode` from Unicode 17.0.0; every line of `NormalizationTest.txt` green on commonJS, erlang and beam; `run/std_unicode_on_every_target` one `.out` (its `.wasm.expect` gone) · `97-s16-a` (where the tables live)
- [ ] 05-wasm s9 · 04-js s11 (333 (B), later) — a prebuilt wasm library merged into the module; no user yet
- [ ] 139 (332) — `bigint` on the four targets · then 97 s15 (`Decimal`, `Json`'s `Int` / `BigInt` / `Dec`) · 125's bind rule
- [ ] 01-checker s13 — JS-4's two checker gaps · 05 lowering a nested constructor in a `val`
- [ ] 01-checker s18 — numeric literal suffixes (247): built on feat (`49455602`); left: the two `language-gaps.md` literal halves, a cold gate · the `l` literal rule on every target (319)
- [x] 01-checker s21 part — every body `comptime` `eval.zig` folds is folded by the checker (`foldBodyComptime`), so no backend meets it (`run/comptime_block_in_body`, four targets); the runtime box is the priority row above (331)
- [ ] 01-checker s23 — `Decl.hooks`: every reachable node, annotations with their `Decorator` (277), each `provide` / `context` with its context (134 s6 box 3, 354 (4)) — built as a patch (`front/checker-s23`), eight cells; `Decorator.same` (371) and the `.hooks` readers' phase (372) built as a patch (`front/decl-hooks-371-372`, five cells; s23-g – s23-i) · then 26 s8, 49 s5, 22 s4
- [ ] 01-checker s24 — typed comptime decorator arguments, `@Decl<T>`, `Field<T>` (`Type.Field<T>`, 308) and `.name` (280; cases in `01-checker/examples/decorator-arguments-280.md`) · then 125 s7, the `nat-*` rewrites
- [ ] decision 281 (references, not strings) — rakun 04 s6, 08 s4, 12 s4 · 130 s7 · 125 s11 · 120 s6 · 127 s5 · 126 s4 · 26 s9 · 53 s7 · each after 01-checker s24
- [ ] decision 282 (a role in the decorator) — 117 s6 · 53 s8 · 51 s8 · 121 s8 · after 01-checker s24
- [ ] decision 285 (the toolchain knows `bpp`, `html`, the prelude) — 116 s2 · 117 s1 · rakun 22 s7 · 26 s10
- [x] 01-checker s25 — the anonymous default `pub default fn (…)` and `pub default Name;` (289); the formatter arm handed to 16
- [x] 01-checker s26 — a `comptime` parameter taking a value or a type (`Atom<T> | type T`, 297); 280 (0)'s `comptime-arg-not-known`
- [ ] decision 290 (no segment config; `revalidate`, `dynamicParams` in `#[page]`) — rakun 22 s8 · 26 s10 · 53 s9
- [ ] decision 291 (`use request()` / `use response()`; no `isPrerendered`) — 122 s1, s3 · 26 s8, s10 · 120 s4
- [ ] decision 292 (`#[reload]`, `#[history]`, navigation hooks, `ScriptStrategy`) — 126 s1–2 · 50 s10
- [ ] decision 293 (`use params<P>()`, `use pageData<D>()`; no page parameter) — 26 s11 · 01-checker s23 (type args) · 117 s7 · 53 s10 · 120 s7 · 121 s9 · 122 s4 · 123 s5
- [ ] decision 294 (`Cookie<T>` declared once; `use cookieValue(decl)`, `cookieSetter`) — 104 s6 · 26 s12 · 123 · 127 · 53
- [ ] decision 295 (atoms: cardume's `Atom<T>` (296), `use local` / `use atomSetter`; middleware `@Component<Response>`, the request the root context `RequestContext` (354)) — 104 s6 · 123 s7 · 127 · 26 s12 · 53
- [ ] decision 298 (typed meta keyed by type: `setMeta(v)`, `meta(T)`) — 130 s8 built (botopink-lang `856bbc69`: `setMeta(v)` / `addMeta(v)`, `meta(T)` / `metaAll(T)`, `@Expr<T>` fields); left: the libraries' migration, the string form's removal · 26 s8 · rakun 08
- [ ] decision 299 (`#[config("…")]` typed records; 03r-b reversed) — rakun 04 s7 · 08 · 13 · 15 · 88
- [ ] decision 300 (typed theme entries, one `#[theme]`; the mechanism `styled`'s, the values emilia's — 338) — 119 s1 · 34 s3
- [ ] decision 301 (`#[styled(..)]`, `jhonstart-styled`'s since 338; emilia's tokens through `#[emilia(..)]` since 369) — 119 s4 · 53 s12 · after 34 s1 for the build-time sheet
- [ ] decision 338 (CSS in three layers — the repositories `css` and `styled`, emilia over `styled`; `jhonstart-styled`, `use` of a scoped style; `"bpp": {"default", "style"}`; the header with no opening `---` and one `--- style ---` section; `jhonstart-emilia` deleted) — 119 s1–5 · 116 s1, s2, s5, s6 · 34 s3, s5 · 118 (`<style>` refusal) · 124 (scaffold manifest)
- [ ] decision 354 (`@Component<R>`; contexts — `Context<T>`, `use provide` / `use context`, only in a render tree, checked at build through `Decl.hooks`, stage markers, the island seam, the render scope of 388; answers 134-f) — 134 s6 · 01-checker · 02–05 · 18 · codemod · 26 · rakun 128 · 119 s1 box 4 · 120 · 34 s5
- [ ] decision 357 (rules of hooks: `use` only at a `@Component` body's top level — never in `if`, a loop, a lambda, `try`, after an early return; every `use` runs on every call, its arguments always given) — 134 s6 · 01-checker · 24 (guide § use) · every library body with a `use`
- [ ] decision 359 (spread: `Pessoa(...old, nome: n)` and `<Card {...p} featured />`, the source the record's type or a 307 derived type, left to right, complete at build) — 01-checker s34 · 02–05 · 16 · 118 s1
- [ ] decision 360 (slots as Astro's: `<Slot />`, `<Slot name="x">fallback</Slot>`, a child `#[slot("x")]`, transfer, `use hasSlot("x")`, `Slot` / `slot` jhonstart functions with `comptime` parameters (302); never props; 193's `children` field goes) — 118 s4 · 130 s9 · 26 (`Slot`, `hasSlot`, prelude) · 01-checker · 120
- [ ] decision 361 (std's module `bpp`: `#[bpp.html]`, `#[bpp.htmlPrelude]`, `#[bpp.style]`, `#[bpp.stylePrelude]`; `jhonstart-styled` merged into the core; `"bpp": "jhonstart"`) — 116 s1 (the std module, the manifest, the roles) · 119 s2–5 (in the core) · 26 · onze · 124
- [ ] decision 362 (26 rewrites the native builders into props form in place, with the 78 hand-written callers; no second builder per tag) — 26 s13 · after 26 s0, 01-checker s28 and the props-filling lowering
- [ ] decision 363 (a browser-only cell is `#[clientOnly]`, no erlang twin; a server `Link` styled by `data-jh-pending`) — 27 s1–3 · 26 (island cells) · 120 · 126
- [ ] decision 364 (every `comptime` parameter is `comptime x: @Expr<T>` — decorators, annotations, templates, functions, builtins: passed on to outputs, `.value` read at build for data, a function or a type never run at build) — 01-checker s35 (built but box 3, the hand-over to the program: 370 — the typed member now, the typed meta with 130 s8) · 130 · 125 s7 · 281's ten fronts · the codemod over std, builtins, jhonstart, rakun, validation (done; cardume when it exists)
- [ ] decision 365 (a deferred `after()` failure through the core's logger is 17's step 4, not 128's) — rakun 17 s4 · after 128
- [ ] decision 388 (a `@Component` at run time is a lambda over an opaque `RenderScope`; the render library runs it, when and with which scope — replaces 354 (8), 374, 387; answers 134-g) — 134 s6: measurement, then box 4b replacing the built map lowering (`front/ctx-async-374-375`'s capture goes with it) · 02–05, 18 · jhonstart's renderer · 119 s2–3
- [ ] decision 375 (`HookNode.async`; commonJS emits a synchronous component as a plain `function`) — 01-checker s23 and 04-js s12 (top-level functions): built as a patch (`front/ctx-async-374-375`); open `s23-j`, `04s12-a`
- [ ] decision 302 (a tag's annotation = a decorator: `@Decl`, no return, meta) — 130 s9 · 118 s5 · 119 · 120 · 126
- [ ] decision 303 (an action answers `@Result<T, ActionError>`; no `ActionOutcome`) — 127 s1–s3
- [ ] decision 304 (a store answers `@Result<T, StoreError>`; no `try*` twin, no raise) — rakun 08 s6 · 09 s6 · 65 s4 · 02-erlang s14
- [ ] decisions 311–313 (`declare fn` in a `type` is host-only; the template annotation `#[f "…"]`; erika queries a database — `from User`, holes bound, `limit 1` against `?T`; a repository is `#[repository] behavior` with `#[erika "…"]` or `#[nativeQuery("…")]`, `#[query]` goes) — 01-checker s29 · 16 s9 · 137 · rakun 08 s7 · 130 s5
- [ ] decision 308 (`Field<T>` is `Type.Field<T>` in std; `Type.keys(T)`; a field key at run time) — 01-checker s24, s28 · 134 s2
- [ ] decision 307 (a derived type is a comptime function answering a new type: `pub val RecipeTitle = Type.pick(Recipe, .title);`, `Type` in std) — 01-checker s28 · 134 s2 · 125 s5
- [ ] decision 306 (`#[schema]` becomes `#[validated]`, the type is the only public schema; `Schema<T>` private; value-only forms become field markers) — 125 s12 · 121 s10 · 117 s8 · 127 s5
- [ ] decision 305 (compiler annotations: `label: value`; `@External(fn: f)`, `op: "…"`, `wasi: .X`) — 01-checker s27 · 16 s10 · 05-wasm s5 · 17
- [ ] 01-checker s22 — the `.bpp` prelude scope (270) · 116 hands the prelude list
- [x] 01-checker s19–s20 — type application and `comptime <expr>` (255): on feat (`49455602`)
- [x] 01-checker rows — the `@block` tail refusal, the `$stringify` parser refusal (239), `primitive-type-name-taken`, T17, row 33 re-measured (refused at the alias); a type reached twice through `@TypeInfo.all` and an import accepted
- [ ] 01-checker rows — the comptime body's file, a package's module namespace, two aliased same-named types (310), `@External.Wasm` read on every target · none
- [x] 01-checker row — the template memo key is O(text) (`template_eval.memoKey`, 237)
- [x] 01-checker rows — a partially returning `@block` is `block-tail-value` (`reject/block_partial_return`); a decorator body's `decl.nope` is the checker's unknown field, located in the body (`reject/decorator_{body,helper}_unknown_field`); the two diagnostics teaching retired spellings corrected
- [x] 01-checker rows (319) — an unsuffixed literal is range-checked in the type its position asks for (`i32` with nothing asking, 247); the operand of a unary `-` is read as the negative value, so each signed minimum is written as itself (wasm emits it as the constant, `negatedMinimum`) and a negated literal takes its width from the other operand; the refusal cites 319 (`reject/integer_literal_*`, `run/integer_literal_type_minimum`, `infer_errors` "cites decision 319"; `run/i64_full_width`'s `@print(4294967296)` written `4294967296l`; bugs-sweep patch 07, bs-b)
- [x] 04-js s1 — the `@block` tail form refused before commonJS (01's `block-tail-value`); the IIFE serves the two shapes left
- [x] 04-js s2 — `$stringify` in a template (164, 239); `render`'s arm and `emitStringify*` deleted
- [ ] 04-js s6 — `throw` in a `case` arm · 01 s6
- [x] 04-js s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`)
- [x] 04-js s9 (319) — `i64` / `u64` / `isize` / `usize` a number below 2^53 and a `BigInt` past it: every operation through the prelude helpers, literals, host templates and `.d.ts` as `number | bigint`, the cost within 10 %, `run/i64_full_range` on the four targets
- [ ] 04-js s9 rest — `Json`'s exact `i64` (332: 139, then 97 s15) · the explicit conversions (97 s13's std surface)
- [x] 04-js s10 (320) — a string index counts codepoints on commonJS: the five reads through prelude helpers, host templates in codepoints, `run/string_index_of_codepoints` one `.out` for the four targets
- [ ] 04-js s10 row — string reads cost +24 % against the 10 % target (`js/AGENTS.md`) · none
- [x] 04-js row — an immediately invoked plain arrow or `function` is not a closure for the self-tail-call scan (`NameScan.immediateBody`): the `??` IIFE keeps the loop, std `path.resolveAll` / `applyPieces` loop again (two `std_package` snapshots re-recorded; bugs-sweep patch 03)
- [x] 05-wasm s1 box 1 · s3 box 2 — `Array.unique` keeps the first occurrence (`run/array_unique`); C-07's cells on wasm as `run/is_truth_table` (`run/unknown_stores_nothing` struck — §11 is a cost, no program prints a difference)
- [ ] 05-wasm s5 — the rest of std on wasm: heap growth, `pow`, astral `contentHash`, `encoding` / `querystring` family cells, the `wat/AGENTS.md` limits row done; left: `json` on wasm and its cell · 97 s15 (336)
- [x] 05-wasm s8 — overflow for `u32`/`u64` and the narrow integer types on wasm (264)
- [x] 05-wasm — an `@block`'s `return` is the block's value (decision 2), `run/block_return_is_block_value`
- [x] 05-wasm rows — `_` in a variant payload, a nested variant pattern (`run/variant_payload_wildcard_and_nested`); unsigned compare and divide (`run/unsigned_compare_and_divide`); `u64`'s unsigned overflow checks and printing, an unannotated `u64` literal or sum keeps its type, radix literals to `u64`'s top
- [x] 05-wasm row — a nested record field read through a generic record and concatenated is the field's text: `recordTypeOfExpr` reads a field declared as a type parameter (`data: D` of `Route<P, D>`) as the record the receiver's type argument names (`recvTypeArg`); `route.data.title` printed `<h1>332</h1>` on wasm (`run/generic_record_nested_field_concat`; backend-bugs patch 01)
- [x] 04-js row — a record field named by a JS reserved word (`type Tag(class: string)`): a record's and a payload variant's constructor parameters and a variant factory's arguments are bindings (`class_`), the property keeps the name, so construction, a read, a destructuring, a pattern, an update and the `.d.ts` agree; wasm types a destructured record binder by its field (`class + "#"` printed an address) — `run/record_field_reserved_word` (backend-bugs-2 patch 01)
- [x] 04-js · 05-wasm row — a labelled record pattern (`Dog(name: n, breed: b)`, swapped, `..`, positional, nested, a literal field, a guard): commonJS tests the record's class (`variantTest`; it tested `tag` and the `case` printed `null`); on wasm a binder read off a record pattern carries the field's declared type, so `"${a ?? 0}"` over `?i32` unboxes (it printed the box's address) — `run/case_record_labelled_fields` (backend-bugs-2 patch 02). erlang and beam were right on every shape tried, a record imported from a sibling module included
- [x] 02-erlang · 03-beam · 04-js · 05-wasm row — `null` (and `true` / `false`) written as a record field's pattern is a literal: the parser keeps it out of the `fields` shape (`isPlainBinder`), and erlang tests `undefined`, beam `is_eq_exact` on it, commonJS `== null`, wasm `eqz` (bound as a name `null` it matched anything; commonJS was a `SyntaxError`) — `run/case_record_field_null` (backend-bugs-2 patch 03)
- [x] 05-wasm row — a `case` over a union of records whose arm binds the record it names (`DogB { d -> … }`): the binder is that record (`arm_record`), not the union subject's type (`d.name` printed an address) — `run/case_record_union_binder` (backend-bugs-2 patch 04)
- [x] 03-beam · 04-js · 05-wasm row — an enum field prints `Target.Top`, as erlang did: a leading-dot field default (`target: Target = .Top`) is injected qualified by the field's enum (`transform.injectedDefault`; commonJS read `Top`, a `ReferenceError`, beam the atom `'Top'`); wasm prints a field of an enum with a payload variant and an optional field by the value's header / the payload's shape (`fieldShape`), and `@print` of a name or field declared as such an enum by its header (`payloadEnumOfName`; both printed an address) — `modules/imported_enum_field`, two wasm descriptor snapshots re-recorded (backend-bugs-2 patch 05)
- [ ] 01-checker row — a `case` over `Dog | Cat` whose arms are constructor patterns (`Dog(name: n, breed: b) { … } Cat(lives: l, name: n) { … }`) is refused `` `case` on 'Dog | Cat' is not exhaustive: missing member(s) Dog, Cat ``; with a `_` arm it compiles and runs right · none
- [ ] 01-checker row — `.Filled(null) { … }` before `.Filled(item: i) { … }` is refused `unreachable case arm (Slot): variant 'Filled' is already covered`: the coverage reads `null` in a payload as a binder (the backends test it since backend-bugs-2 patch 03) · none
- [ ] 05-wasm row — a `_ { n -> n.toString() }` binder over a field-read subject (`case d.age { 3 { … } _ { n -> … } }`) prints an address (`max 320`); a record's `?f64` field holding `null` prints `0.0`; a local `?Place` (an optional of an enum with a payload) prints an address; `R(q: .Here)` into a `?Place` field prints nothing; `val t = Token.Color.White; @print(t)` prints an address · none
- [ ] 01-compiler row — an enum value interpolated (`"${t}"`) differs on every target: `[object Object]` on commonJS, the variant atom (`language_tests@main@@Target__v__top`) on erlang and beam, the ordinal on wasm · none
- [ ] 02-erlang · 04-js row — a leading-dot variant (written, or a field default) of an enum the consumer does not import (`Anchor(href: "/y", target: .Bottom)` with only `Anchor` imported): commonJS `ReferenceError: Target is not defined`, erlang `variable 'Target' is unbound`; beam and wasm right — the import closure · batch 17 (module identity, every backend's import closure)
- [ ] 01-compiler row — an `l`-suffixed literal inside a `case` arm keeps its suffix in the generated code: `Ok(s) -> @print(s.mtime > 1577836800000l)` is a JS `SyntaxError`, an `erlc` syntax error and `illegal integer` on beam (the same literal in a plain function is fine) · none
- [ ] 03-beam row — std's `unicode_test` does not assemble on beam: `Internal consistency check failed … {unassigned,{y,6}}` (baseline 106c84b3; std's declared targets are commonJS and erlang) · none
- [ ] 01-checker row — T7 ("fills the element labeled `x`") fires between two elements of one array literal with no type written (onze-cli `build.bp` static-tree list, `create.bp:187`) · none
- [x] 05-wasm rows — `?u64`'s `toString` and a `u64` record field print unsigned; a `u64` tuple slot holds its 8-byte cell — already on `feat` (batch 6, `c6483b21`): `run/optional_u64_to_string`, `run/u64_record_field_print`, `run/u64_tuple_slot` green on the four targets at `106c84b3`
- [x] 02-erlang s4 — `run/array_unique` (C-35), four targets
- [x] 02-erlang s5 box 2 — a decorator body carrying `\u{…}` (cell: 14 s7)
- [x] 02-erlang s7 — C-07's erlang tails as `run/is_truth_table`; `run/unknown_stores_nothing` struck (§11 is a cost, no program prints a difference)
- [x] 02-erlang s10 — the block-as-value lowering (R7): the valueless tail refused by the checker, a `return` the block's fun cannot answer last throws to the block's own guard
- [x] 02-erlang row — an `@block` with a `return` (or in value position) that reassigns an enclosing `var`: every `return` answers `{V, Group}` and the call site rebinds the group (`valueBlockExpr`; `run/block_value_reassigns_enclosing_var`, a `for`'s `return` in `tests/erlang.zig`; bugs-sweep patch 06)
- [x] 03-beam row — a `return` from a `for` inside an `@block` is the block's value: a loop's fun throws `{'__bp_return', V}` (apart from a `try`'s `'__bp_try'`), and `guardLoopCall` answers it into the `@block` of its frame (`answerLoopThrow`, `inBlockExit`); beam answered `7` for `700`. wasm's `blockReturnValue` reads a `return` written in the body before one inside a loop (a string block over a `for` printed an address) — `run/block_for_return_is_block_value` (backend-bugs patch 02)
- [x] 02-erlang s12 · 03-beam s7 — one `math` on every OS (263): on feat (`a443f52d`)
- [x] 02-erlang s13 · 03-beam s8 — an integer that leaves its type aborts (264): on feat (`48a096ea`)
- [x] 02-erlang s15 · 97 s14 box 1 (320) — erlang and beam count codepoints: the emitters and std's Erlang templates read the codepoint list (`run/string_index_of_codepoints`, combining-mark and astral rows)
- [x] 03-beam s9 — a lambda a `case` arm answers is the arm's value (`language-gaps.md` row 28 deleted); an `@block`'s `return` is the block's value; an in-frame loop's head keeps a forward entry under `beam_jump`
- [x] 03-beam row — a variant name declared by two enums with different fields binds the payload on a positional pattern: `beam_asm` registers an imported enum's name (`modules/variant_positional_payload_same_name`)
- [x] 03-beam row — a `case` no arm matches raises `case_clause` (`run/case_no_arm_matches_raises`)
- [ ] 03-beam s1 box 3 — the checker's two binding shapes on beam · 01 s13
- [x] 03-beam s2 box 1 — C-07's `run/` cells on beam (`run/is_truth_table`)
- [ ] 12 s1 box 2 — `--cold` with the pre-existing tool set · 114 s7
- [ ] 12 s2 box 1 — `run/throw_in_case_arm_result` (`run/array_unique` landed with 02 s4 and 05 s1) · 01 s6 + 04 s6
- [x] 14 s2 slope — ≤ 1 ms/eval on both runtimes (wat 0.5, BEAM 0.6–0.7): kept wasm3 instance, argument-only trace listing, O(text) memo key, the bench's stage split
- [ ] 14 s2 rest — N=200 ≤ 600 ms on the BEAM runtime (712 / 782 ms): the N=0 build and the node's spawn · 02/03/CLI, 18
- [x] 14 s8 boxes 1–3, 5 — a hole's build value (`Part.known` / `Part.value`), the lifted record imported, `comptime` over an expansion; `styled "${tab4} color: red;"` emitted `styledConstant` (`run/styled_holes_known_at_build`, styled's `repository-stages.sh`)
- [ ] 14 s8 rest — a hole naming an imported `val` (the export carries its expansion), `contentHash` at comptime · s6 (T19) — computed at render meanwhile, the same CSS
- [ ] 14 s6 — a decorator's host cells, `@embedFile` / `@embedBytes`, independent invocations · decisions 341–343
- [x] 14 s7 — a `comptime/tests` fixture for a `\u{…}` decorator body
- [ ] 17 s1 box 4 — the per-row increment of a keyed `Dict` · `Dict.bump`, decision 340
- [ ] 17 s2 — the `@BeamMemory` text and the migration handed over · 07 s6 · the rakun track
- [x] 26 s2 box 3 — measured: rakun's `orm_host.bp` workaround deletable (move to `src/orm/host.bp`; rakun-data 128 passed) — the deletion is a rakun-track row (L2)
- [x] 26 s3 — only a direct dependency is importable (T4, 242): located refusal, `modules/transitive_package_import`
- [x] 26 s4 — `build` and `test` print checker warnings
- [x] 26 s6 — the `subdir` resolver half · decision 344
- [x] 26 s7 — `build.zig`'s `test-docs` comment
- [x] 26 s8 — 206's residuals: the LSP reports `module-import-with-from` and `unresolved import source`; a package importing itself by name refused (309), std's three sources migrated
- [ ] 26 s9 — a dependency's sidecars and imports answer as its own build does · none
- [x] 26 row — the LSP makes the 309 refusal: the package name from the nearest manifest, through `engine.importDiagnostics` to the resolver
- [ ] 130 s5 — the remaining decorator sites (38 of 119 done, plus `#[schema]`'s 5) · rakun's DI on 01 s20 · rakun sites under the 130↔128 rule (decision 339) · rakun-client's on the behavior-member gap (ctr-q closed: the table built at comptime, 281, 256)
- [ ] 130 s10 rest — `value` read at build (353); a decorator on a `val` runs and the `val` is catalogued, its build value lifted (356) · row 133 → 119 s1 box 5 · 34 s3 · 119 s4
- [x] 130 s10 part — `@TypeInfo.all` in a template body answers for the calling program (353): the oracle session, the importer's `typeinfo-all-imported` at the handle, `typeinfo-all-template-value`
- [ ] 130 s6 — module-level `@emit` removed · 130 s5 · `#[schema]`'s free functions → members of the type (306; `T.parse(…)`, 327)
- [x] 134 s2 part — `@is` refused (322); the drift test walks the mirrored types and `@Result`'s methods (declared); std `Type` (`keys`, `partial`, `required`, `merge`)
- [ ] 134 s2 — `Decl.fields` as `Type.Field<unknown>`, `examples/types.bp` · 01-checker s28 (`Type` a namespace type, `Type.Field<T>` declared, `Type.pick` / `omit` declared with the variadic; `result` deleted and `?T` methodless — done)
- [x] 01-checker s31 row — on commonJS, `x?.m()` over an enum method (`doc.field("src")?.str()` on std `Json`) is the static call guarded around a receiver evaluated once (`optEnumCall`); the owner is read at the checker's link loc (`ast.optional_synthetic_col`) — `run/optional_enum_method_call` (backend-bugs patch 03)
- [ ] 03-beam row — `x?.m()` over an IMPORTED enum's method calls the variant's atom as a module: `doc.field("src")?.str()` on std `Json` is `undef` `'std@json@@Json__v__str':str/1` (a local enum and erlang are right; the written `?.` call's loc records no instance lowering, the payload link's does — `ast.optional_synthetic_col`) · none
- [ ] 01-checker s31 — `?T` by `??`, `?.`, `?.[]`, `?.()`, `x!` (330); the migration script before the refusals
- [x] 134 s5 — the `Decorator` type for `with:` (268)
- [x] 134 s4 — the variadic parameter `..name: T[]` and the print builtins declared with it (267)
- [ ] 134 s6 — contexts (354), rules of hooks (357): built on `front/134-s6-contexts` (patches) — `@Component<R>` / `@Renderable`, std `context`, `use` refused outside a render tree, `use-not-top-level`, the codemod and the libraries migrated; the hidden map runs on erlang, beam, commonJS, to be rewritten as 388's lambda over a `RenderScope` after the measurement; `Decl.hooks` waits on `01-checker` s23 (277) · 02–05, 18 for the rest of the lowerings
- [ ] 07-residuals s8 — the lib-agnostic gate names every library: the test-file comments reworded; the other owners' comments, then the `-w` pattern · 02 and the other owners landed (s3, s5–s7, s12, s13 done)
- [ ] 07-residuals s1, s2, s4 — the codegen and comptime report waves, three renames · 02–05 landed · 01 landed
- [ ] 07-residuals s9 · s10 · s11 — `->` arms · erika's C-13 migration · the pointers' sweep (last) · C-14 · 16 s1–2 · every library merged
- [x] 97 s1 residue — `bindInt`'s `i32` through std: `parseInt`, then `toI32()` inside the range; past it a `typeMismatch` (it aborted); `parseI32` deleted (validation)
- [ ] 97 s2 residue — the library repositories' `Json` accessor copies (botopink-lang's `libs/` is std alone, clean): validation `derived.bp` `membersOf`, `formats.bp` `isObject` · 125 s2 residue · rakun `jwt.bp`, `autoconfig_registry.bp` · 04-rakun
- [ ] 97 s3 · s5 residue — rakun's `parseDuration`, `skewOf` and four retry loops as "consume std" rows · no 04-rakun front carries them yet
- [ ] 97 s4 residue — the full `test-libs` count against its last record (138: 125 passed) · the cold gate; the engine half is done: no `-test` member has its own, and `test-libs --lib std` plus the seven `-test` members read 12 passed, 0 failed, 1 without tests, 3 restrictions audited
- [ ] 97 s11 — std on wasm, group 3 (230) · `io/http`, `async` through 140 + s17 (334) · `testing/mocks` in module memory when tests run on wasm (335), 110-a
- [ ] 97 s13 rest — `io/clock`'s `formatIso8601` / `toCivil` / `offsetMinutes` past ECMAScript's time range · `97-s13-b` · `Json`'s `i64` as its digits (332, s15) · `97-s13-a` (`abs` of the minimum)
- [x] 97 s13 box 1 but three — `fs.stat` (`bigint: true`), `async`'s `millisAsFloat` / `wholeMillis`, `clock`'s `wide` (`toI64()`) and `largestExactMillis` (a literal) in 319's canonical form: `run/std_io_i64_canonical`
- [x] 97 s13 boxes 3–5 — `parseInt` exact over `i64`; `min` / `max` / `abs` / `clamp` / `isEven` / `isOdd` past 2^53 on commonJS; `toI32()` … `toF64()` on `Integer`, aborting when the value does not fit (wasm halves: 05-wasm rows)
- [x] 97 s12 — `unicode.fromCodepoint` a `fn:` over `String.fromCodepoint` on all four targets (with `powBody`, `fn:` transcendentals, code-point `contentHash`)
- [x] 97 row — an embedded std module that does not lex or parse is printed located at its `libs/std/src/<module>.bp` file and the build stops with `EmbeddedStdRefused` (was `compilation failed` / `UnexpectedToken`; `parseEmbeddedStd`, `comptime/tests/located_errors.zig`; bugs-sweep patch 08)
- [ ] 104 s5 — the consumer sweep · 04, 65, 79, 12, 19, 22, `08-bpp/123`, 49, 51 landed (188)
- [ ] 106 s2 — consumers: 17's and 26 s4's boxes; rakun-web's `problem_digest` commit · 65 landed
- [ ] 106 s3 — built on erlang, beam and commonJS (log `2c5f568`: per-name levels, consoleSink, fanOut, rotating fileSink, captureRuntimeReports); left: the wasm column — the sink slot and the file cells have no wasm binding (two `language-gaps.md` rows, 140), std's `json` / `io/clock` on wasm (97 s15), the four file cells' wasm `fn:` bindings (405: `fileSink` an `Error` on wasm)
- [x] 125 s0 residue — the `f32` and `url.parse` platform facts as tests
- [x] 125 s2 residue — the examples as suite cases, the 2 000-deep test, the refusal test, `schemas.bp`'s accessors
- [x] 125 s3 — checks and formats (39 `surface.md` rows)
- [x] 125 s4–s12 — enums, unions, tuples, dicts, sets; object policy; coercion and `T.bind`; messages and locales; `T.encode`, codecs, `#[each]` / `#[check(rule)]` / `#[preprocess]`; error views and `T.jsonSchema()`; `#[schema]` folded into `#[validated]` (327's members, `derived` private, `#[validated(transparent)]`) — validation 246 / 0 on erlang and commonJS; consumer patches rakun (375 / 0) and onze-content (714 / 0) — validation, rakun and onze land as patches (hooked)
- [ ] 125 s4–s12 residue — `#[tag]`'s refusal and `#[wireName]` (`Decl.variants` gap) · the type-level `#[check]`, `#[map]` / `#[tryMap]` / `#[codec]`, signature refusals (01-checker s24) · `Type`'s derived types (01-checker s28, 134 s4) · reflection by `@typeInfo(T).fields` and 298

## L2 — the libraries' critical path

- [ ] rakun-messaging — one erlang test failed once in the pre-commit gate under load 26 (90 passed, 1 failed; the hook log did not name it) — not reproduced: 39 runs at c0e991c, 91 passed, 0 failed each, under load 21–74 (up to four copies of the suite side by side, rakun-websocket's beside them, CPU hogs) and once pinned to a third of one core; every runtime test ends in under 0.5 s against its 2–3 s bounds even starved, so no bound is near. Candidates left: the three fixed windows followed by a positive assertion (`ack: auto settles a Done once`, `ack: batch settles …`, 200 ms; `jms: a queue send reaches one of two …`, 300 ms) and the seven `build_test.bp` cells (a compiler run each, comptime `EVAL_TIMEOUT_MS` 10 s wall clock). The hook prints only the tail of a red member's log, so the next red names nothing either · the failing test's name (a red log kept whole)
- [x] 138 — the five new repositories carry Node 22 and the glibc 2.35 note (actions 5b78ce8, http fe75240, log 220cfe2, routing 7e6a24f, validation bf0610f); their first CI run reads after this push
- [x] 138 (decision 326) — actions, http, log, routing, validation are repository/<pkg> submodules (history kept); the compiler embeds std alone (botopink-lang 541336e3); rakun, jhonstart, onze declare them
- [x] 138 rest — doc comments say "shared library" where they said "bundled library" (jhonstart, onze, routing, validation; rakun's starter-web `root.bp:3` rewritten: `validation` is declared by rakun core, the starter lists it nowhere); emilia, erika, jhonstart and onze `test.yml` on Node 22 with the `fs.globSync` note; onze-cli `build.bp:165`'s two T7 warnings gone at their cause — the `extraDeps` list is built in place, no variable lends its name as a label (chores patches, land with the coordinator; jhonstart 204+15, onze-bundler 42, onze-cli 31, routing 82, validation 246 passed, 0 failed, on commonJS and erlang)
- [x] 138 rest, rakun — "shared library" doc comments in rakun's sources, the four formerly non-canonical files included (after 128)
- [ ] 138 rest — the `cardume` submodule · `botopink/cardume` holds its scaffold
- [ ] 01-checker — decision 8 §6 T7 warns between two elements of one array literal, where no type is written: `[#("a", linkDir), #("b", formsDir)]` says "the variable `formsDir` fills the element labeled `linkDir`" (the first element's T1 labels taken as the written type; `comptime/infer.zig` `warnTupleLabelMismatch` via `unifyAt`); still hit by onze-cli `build.bp` (the static-tree list), `create.bp:187` · none
- [x] 102 s1–2 — `conventions.bp` and the segment helpers in `libs/routing` (re-implemented)
- [x] 103 s1 — `id.bp` (`deriveActionId`, `isActionId`) in `libs/actions` (re-implemented)
- [x] 102 s3 (W2) — consumers, one commit per member: rakun-app and rakun-hateoas (rakun de85b3d), jhonstart `routes.bp` (`#[page]` → `segment.paramNamesOf`, jhonstart 6b368ec), onze-cli, onze-bundler and onze (onze 3c25410; `classifyAppFile` and `patternOfSegment` gone) · decision 323
- [x] 103 s2 (W2) — consumers: rakun-app `actions.bp` (`actionId` deleted, 324), jhonstart-forms `form.bp` (`isActionId`)
- [ ] 103 — the action secret from rakun-app's `#[config("rakun.actions")]` record, not `rkProp` · rakun 04 s7 (299; no `#[config]` record in rakun yet)
- [x] 128 (W3) — the nine merges, alone in rakun: 25 members → 16, 1 819 tests before and after, every starter and example building (rakun `00d4fcc`…`343a55c`, eleven commits)
- [ ] 130 ↔ 128 — 128 does not wait on 130; no 130 rakun commit while 128 is open; after it, each is a decision-188 consumer commit · decision 339
- [ ] rakun group A (W4–W5) — 04 (s1 the tag epoch on `feat`, rakun `d609f8c`; s2 on) · 74 · 08 (s1 after 04 s4) · 15 · 79 · 81 · 93 · 73 · 19 s1 · 128 landed
- [ ] rakun group B (W5–W7) — 13 · 12 (19 s1) · 22 (04 s5) · 17 (13 s2) · 11 (22) · 65 · 09 (19 s1, 13) · 91 (15) · 92 (74, 15) · the A step each names
- [ ] rakun group C (W8) — 88 (81, 93, 92, 04 s4, 73) · 19 s2–5 (15 s1, 04 s4) · group B
- [x] rakun-websocket `test/limits_test.bp:48` — the 1013 test read `rkWsSessionIds()` before the connection had registered its session (101 is written before `run/4` inserts the row: 19 of 200 handshakes under load 31 found none, so every frame went to no one and the close code was 0), then slept 3 s for the close; it now waits on the session's row and on its close-log entry (test-side Erlang helpers; chores patch, rakun test file only, rebase after 128) — 7 runs green under load 20–37 beside rakun-messaging's suite
- [ ] rakun-websocket — `rakun_websocket.erl`'s `handshake/10` writes 101 before `run/4` registers the session, so a caller that reads the sessions right after the handshake can find none; register first, then answer 101 (a sidecar change, not a test bound) · 128 landed
- [ ] rakun track — remove the workarounds the compiler made deletable: rakun-data `rows.bp`'s `longOf` (C2 fixed), `runtime.bp`'s row-89 named fn (row 28 fixed), `orm_host.bp` → `src/orm/host.bp` (26 s2) · `04-rakun` RX-14
- [ ] rakun track — latent `i32` clocks: `migration_host.cellNowMs`, the test-only monotonic `nowMs` in `rakun-mail`, `rakun-rsocket` and `tls_listener_test`, `Duration.millis` · `04-rakun` RX-15
- [ ] rakun track — stale `__rkMake_` text in rakun's `AGENTS.md` · `04-rakun` RX-16
- [x] rakun track — the server test measures `Content-Length` in bytes (320's follow-up) · `04-rakun` RX-17
- [x] 01-checker — a module is its package plus its path (170, 337): two packages' `theme` modules no longer collide (`modules/two_packages_one_module_name`, four targets); jhonstart's core on `styled` compiles `jhonstart-emilia` on both rows — unblocks 119 s1 box 4 and 34 s5 (front `pkg-module-collision`)
- [ ] emilia on `styled` first (decision 350) — 34 s5: the two text boxes and the class box done (367: `e_` + `contentHash` of the class's rules, fixture `e_f51c2501`, every reader re-recorded — patches of `front/emilia-34-s5b`); boxes 1–3, 6 wait on 34-d (a family answering `StyledProperty` does not compile), box 4 on 34-e, 34-f and 119 s4, box 5 on `contentHash` as a host `declare fn` (01-compiler/14 s6) — the two toolchain rows (a nested-section enum value at comptime, emilia's dispatcher at comptime) landed in botopink-lang `856bbc69`, box 8 on box 1 — 119 s1's two open boxes (a component with no run-time hook computed at build; the theme mechanism, 300) → 34 s5 (emilia over `styled`, output byte-identical) → 34 s2 (the five families in `styled`'s literal) · through 352 / 354 (registration by `use context(StyledSheet)`, 379), 134 s6 (box 4), box 5 on `01-compiler/130` s10 (353, row 134) — measured on `d7c71405`, see L5 (`css` done, `styled` landed)

## L3 — ready to open now

- [ ] 143 (398) — `dbcontext`, botopink's JPA over erika: s0 done (`botopink/dbcontext` scaffolded, a submodule); s1 entities and `DbContext` over a `Driver`, s2 `#[repository]` / `#[query "…"]` / `#[nativeQuery]`, s3 rakun-data over it · 137 s2 · 01-checker s29 · s3 after 128
- [ ] 142 (396) — `json`, `yaml`, `markdown`, one repository each: s0 done (the three repositories scaffolded, submodules), s1 std's `json.bp` out with the six consumers' imports, s2 `yaml` (rakun's reader its seed; 121 s3), s3 `markdown` (onze-content's reader, a tree of its own) · s1–2's rakun commits after 128
- [ ] 135 s0 (391) — the `snap` library: `botopink/snap` scaffolded and a submodule (`repository/snap`, meta `79e4af6`); left: `snap`'s `botopink.json`, `std/testing/snapshots.bp` moved whole into it with std's four `.snap`, std's generic text methods (newline normalisation, trailing trim, first differing line), the consumers' imports one commit per library (jhonstart, onze), `contracts.md` § 7 · none — every `.snap` byte-identical before and after; 135 s1–5 write through it
- [ ] 141 (`10-specs`) — steps 0–5 done (`decisions-taken.md`'s 26 amended rows stated as in force, the central files, tracks 04, 06–09, the examples; F10 for 384, 385); left: step 6, the rule that keeps the specs from drifting · `141-a`
- [ ] 129 s1–4 (337) — `mod m;` binds the namespace `m`; the shorthand `import {x};` refused (`shorthand-import`, fix written); about 75 items migrated in botopink-lang, rakun, jhonstart · before 138 s3 deletes `libs/<pkg>` or after, either — a consumer commit per library (188)
- [ ] 118 — the template language, tag annotations (278), `prelude.bp`, the node type · none (s1: 351's html-side rules; native props handed to 26 s13 (362); s4's slots are 360; s1's component spread is 359, on 01-checker s34; ctr-r closed: 118 goes first, org-3 holds)
- [x] 121 s1–2 — Markdown to `Element` in `onze-content` (onze `584f64a`, on `feat`): 714 / 714 on both rows at onze `05b7005`
- [x] 33 s2 — `emilia-card` emilia-only, the fifteen example READMEs (s1, s3, s4 are 135's)
- [x] 49 s1 · s6 — `config.bp` / `types.bp` on std's `Json` methods (`isString` stays — `49-g`); the six `onze-test` group stubs (onze-wave patch 02)
- [x] 50 s1 — `onze-cli` / `onze-bundler` read std's `Json` methods; no local `membersOf` / `itemsOf` / `textOf` (onze-wave patch 03)
- [x] 51 s1 — `onze-og` reads integers with std's `parseInt`; no `intOf` (malformed text still `0` — `51-a`) (onze-wave patch 04)
- [x] 27 s1 box 1 · s2 boxes 1, 3 · s3 — the reconcile driver (`applyTransition` over `DomOps`, question 27-b ★), `use linkStatus()` in a `#[client]` component (363), `data-jh-pending`, the example (jhonstart `b25e959`)
- [ ] 27 s2 box 2 — `use linkStatus()` outside `#[client]` refused · 26 s8 (`#[clientOnly]`, `src/stage.bp`) on 01-checker s23 (`Decl.hooks`)

## L4 — later, in waves

Wave numbers are [`fronts.md`](./fronts.md) § Waves.

- [ ] decision 321 (qualified beans: `#[qualifier("label")]`, `ctx.resolveNamed(Type, "label")`, `resolveNamed(Type)` the primary, labels checked at build) — 130 s5 · rakun 04 s6
- [ ] decision 320 (string index: codepoints on every target; erlang leaves `string:length/1`; commonJS native when no surrogate pair) — 97 s14 boxes 2–3 (04-js s10, 02-erlang s15 done)
- [ ] decision 319 (`i64` is 64-bit on every target; commonJS a number below 2^53, a `BigInt` above; literal refused past the type's range everywhere; 176, 264 amended) — 04-js s9's rest · 01-checker s18 and its literal rows · 97 s13
- [ ] decision 318 (one decorator per role, rakun's names: `#[component]`, `#[repository]` on a behavior, `#[provides]`, `#[httpClient]`, `#[listen(dest)]`, `#[controller]`, wrappers; closes 130-c, erk-c) — 130 s5 · rakun 04 s8 · 08 s7 · 12 s6 · 13 s6 · 15 s8 · 19 s7 · 79 s4 · 91 s2 · 93 s4
- [ ] decisions 315, 316 (no module annotation; a decorator wraps its function, `decl.wrapWith`, typed) — 01-checker s30 · rakun 12 s5 · 15's example
- [ ] 137 (`04-rakun`) — erika's database target: holes, `QueryContext` / `QueryTable` (397), `self.db.query "…"`, the grammar, `#[erika "…"]` · s5 and s2's template method: 01-checker s29
- [ ] 136 (`09-cardume`) — cardume: the core, `rakun-cardume`, `jhonstart-cardume` · `botopink/cardume` to be created and pushed · 26 · 120 · 125 · atm-c · s8: atm-d
- [ ] 26 (W3) — the core: s0 merges `jhonstart-html`, s1–6 · 118 landed · 102 s3 `routes.bp` · s5: 29-a (reduced: `registerRouteStarters` + `globals.starters`) · s8: 01's hooks capability, ctr-l (only the record) (s7 is 135's)
- [ ] 27 s1 box 2 (W7) — the route-kind flag read · 22
- [ ] 67 (W4) — the DOM-side forms boxes, the wire names handed in · 26 · 103 s2 · 67-a (only the record) (s4 needs only 103 s2)
- [ ] 49 s2–5 (W3 → W7) — query, headers, dispatcher; the digest's sink; the public root; the dynamic mark · 102 s3 · s3: 26 s4 + 17 · s4: 65 s1 · s5: 22 s4 · 49-e
- [ ] 50 s2–7, s9 (W3 → W8) — `dev`, `prerender/`, the signal, `bin/onze`, the bundler tail, the defaults table; the `@/` alias gone (218) · 102 s3 · s2: 50-b · s4, s7: std-d · s5: 71 s2 · s6: 27 s1
- [ ] 51 s2–6 (W7) — single flight and the route, the prop table, the metrics generator, the OG defaults · 22 · s4: 52-a
- [ ] 71 s1–2 (W3) · s3–4 (W7) · s5 (W10) — ERTS copy and `bin/onze`; shutdown over real cells and static export; the four gate boxes over the blog · 49 s6 · s3: 11, 04, 81 · s4: 22 · s5: 50, 53
- [ ] 53 (W8) — the blog's `alias` gone, the acceptance script's second half, the browser · 49 · 50 · 51 · 71 s1–4 · 26 · 27 · 67 · 22 · 12 · 65 · 135 s5 (the runner) · s6: 50-b
- [ ] 119 s2–5 (W3) — `jhonstart-styled`: the style section, `use`, run-time holes, `#[styled(..)]`, the one sheet; `jhonstart-emilia` deleted (338) · s1 · s2: 118, 26 · s5: 34 s5
- [ ] 34 s3 — Tailwind's theme values over `styled`'s mechanism (338); the theme always declared (358) · 119 s1 · 34 s5
- [ ] 117 (W7) — `.bpp` / `.md` app files, `staticPaths`, `paginate`, partials · 102 · 22 · 49 · 50 · 121 s1–2 · s1: 293
- [ ] 123 (W7) — `locals`, `sequence`, `actionContext` · 04 · 65 (s1 box 3: 08-j closed → 295/296, `use local(atom)`, the store `rakun-cardume`'s)
- [ ] 120 (W8) — hydration strategies as `#[client…]` / `#[serverDefer]` annotations (278), server islands · 118 · s1: 26 s8 (`clientOnly`) · 119 · 117 · 26 · 22 · 49 · 50
- [ ] 121 s3–6 (W9) · s7 (W10) — frontmatter, collections, references and RSS, `.md` pages; the blog reads Markdown · s3: 142 s2 (396's `yaml`) · s6: 118, 117 · s7: 53
- [ ] 122 (W9) — page-side status and headers, `rewrite`, `site` · 26 · 49 · 102 · 118 · 120
- [ ] 126 (W9) — view transitions, `#[transition…]` annotations (278) · 27 · 118 · 120
- [ ] 127 (W10) — actions typed by a schema · 125 s6 · 103 · 22 · 67 · 49 · 117 · 120 · 126 · s4: 123
- [ ] 116 (W5 at the earliest) — the `.bpp` file kind · 118 · 26 s0 · 01-compiler/26 · with 01-checker s22 · s6: 293
- [ ] 105 (W9) — bundled `i18n` · 104 s5 · 22 · 26 · 03r-q confirmed
- [ ] 107 (W9) — bundled `release` · 07-g · 71 · 81
- [ ] 124 s1–4 (W10) · s5 (W11) — the commands, the config keys, the `.bpp` scaffold (08-h closed → 285, 224) · every other 08 front · s5: 116, 53
- [ ] 98 (W11) — packaging checked everywhere · every library track's `-test` and README steps · s3: 95-f · s4 done: `subdir` (344)
- [ ] 16 s1–7 — the `;` re-count, migration and refusal, C-12's reformat, 165, 166/243/345, C-11 · s2: each library track runs the script · s6 (345 in the printer) before s4 · s3 last, after every tree is migrated
- [ ] 18 s1, s3 — the CI matrix, the bench's close row (s2, s4, s5, s3's evaluation budget done) · s1: the maintainer's push
- [ ] 23 — the import cells and LSP snapshots, the confirmations · 23-a/b/c, std-c
- [ ] 24 — the guide as one program, the confirmations, the per-item cost · 24-a/b/c/g · rakun's `serverAction`
- [ ] 135 s5 (W7) — onze: the E2E runner (five harness functions), the release tree as a path table, 107's README names the two snapshots · 390, 391 (s0 first) · before 53 s2–6
- [ ] 135 s1–4 (W11, last) — std's `mocks.verify` message; rakun-test's `assertResponse`; jhonstart's `AGENTS.md` paragraph; emilia-test's `assertClassName` / `assertCss` (they replace 97 s7, 19 s6, 26 s7, 33 s1/3/4, 50 s8, 51 s7) · 390, 391 (s0 first: the `snap` library) · s4: 34 landed

## L5 — blocked on a decision

Full text in [`decisions-pending.md`](./decisions-pending.md); confirmations (1.0.10 choices) in its
last section. Open after the answers through 389: 90 questions, 6 contradictions, 94 implementation choices (the
counts live at the top of `decisions-pending.md`).

**First — what blocks now** (`decisoes-pendentes.md` Parte 1, "O que trava agora", set by the maintainer 2026-10-09), in order:
- [ ] 05w-i → 333 (A): 97 s16 · 05w-j → 336: 97 s15

**Then — the botopink shape** (raised 2026-10-04):
- [ ] nat-d6…d9 — case by case (283; nat-d1 → 303, nat-d2 → 304, nat-d3 and nat-d4 → 306, nat-d5 → 307): `nav:` strings (26, 53), lifecycle (rakun 04), `use use…` (53), erika's LINQ names (98)
- [ ] nat-f2…f4 — case by case (284): `onze.json` keys (124), `files`/`workspaces` (98), `ONZE_PUBLIC_` (50, 53)

Then:
- [ ] std-d — 97 s6 · 50 s4, s7
- [ ] 97-s13-b — 97 s13's three `io/clock` templates · 97-s13-c, 97-s13-d block nothing
- [ ] 95-f — 98 s3
- [ ] 07-g — 107 whole
- [ ] 03r-ab — 09 s5 (and the scope of s1–4) · only the record
- [ ] 03r-ae — 79 s3
- [ ] 03r-af — 73 s3
- [ ] 03r-ak — 81 s3
- [ ] 03r-al — 15 s5
- [ ] 03r-am — 19 s3–4
- [ ] 03r-an — 92 s2 (boxes 1, 3)
- [ ] 67-a — 67 s1–3 · 53's write path · only the record
- [ ] 50-b — 50 s2 · 53 s6
- [ ] erk-b — `#[documentQuery]` under 313 (09 s4) 
- [ ] lg2-b … lg2-u — none opens a front; each opens a step when answered: 01-checker (q — reduced); the rakun boxes that name them — 13 · 65 · 92 (b), 22 (q) · answered: a (346 → 01 s32), e (347), j (343), o (342), w (341) → 14 s6, v (344) → 26 s6 / 98 s4 / 73, f, i (280), k (216, 253), r (311–313), t (314), m (315), c (316); g has no subject under 281
- [ ] C-14 — 07-residuals s9 (a 1.0.10 id)
- [ ] confirmations a step waits on — 49-e (49 s2) · 52-a (51 s4) · 29-a (26 s5; reduced: `registerRouteStarters` + `globals.starters`) · 03r-q (105) · 23-a/b, std-c (23; 23-c → 317) · 24-a/b/c/g (24; 24-g also 97 s5's surface)
- [ ] ctr-l — 26 s8's refusal list (only the record) · ctr-v — 34 / 33 opening before 118 (only the record) · ctr-w — 09 s3
- [ ] ctr-o — lem-c · ctr-p — 04's readers · 104 s5
- [ ] lg2-s — module-graph reflection

Closed on 9 Oct (no longer pending): 08-h → 285, 224 · 08-j → 295 · lg2-g → 281 · ctr-q → 281, 256 · ctr-m (= lg2-s) · ctr-n · ctr-r · 111-c → 228 · 03r-b (reversed), 03r-d → 299 · 95-e · 03r-o → 290 · 05emilia-h → 206 · 68-c → 280, 281. `#[schema]`'s free functions → 306 (ctr-u); `not-found.bpp` (213 against 221) → 289. own-a blocks nothing (`fronts.md` § Ownership's provisional rule).
