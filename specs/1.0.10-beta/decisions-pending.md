# Decisions the maintainer owes — 1.0.10-beta

**Twenty-six questions are open** (lg-a, lg-b, lg2-a…w, ck2-c). Implementation choices wait for the maintainer to confirm or reverse them:
front 24's (24-a…c, 24-g), `01-std`'s (01std-a, 01std-c…e, std-a…c), `00 · 23-std-purity`'s (23-a…c), front 95's
(95-a…e), `00 · 16-formatter`'s (16-a…b), track C's (26-a…b, 27-a, 30-b…e, 31-a), `00 · 04-js` /
`05-wasm`'s (0405-b), `00 · 01-checker`'s (01c-a…b), `checker-rows-2`'s (ck2-a, ck2-b, ck2-d, ck2-e),
track D's (05emilia-a…l), track E's (49-a…d, 52-a, 53-a, 68-a…c, 69-a), track B's (03r-a…e) and the host methods' (lem-a…f). The
open questions are the language-gaps sweeps' lg-a, lg-b and lg2-a…w, and `checker-rows-2`'s ck2-c (§ Open). Every other question raised so far is answered in
[`decisions-taken.md`](./decisions-taken.md) — 24-f is decision 143 (library resolution stops at the
enclosing checkout; dependencies are transitive); the next free number is **144**.

This file stays because the fronts will fill it again. A front that meets a question it cannot answer
from the code writes it here rather than guessing, in the shape the others used:

> **Raised by:** `<NN>-<front>` step <k>, <date>
> **Measured.** What was observed, with the command or program that produced it and the file or commit
> that can be re-read.
> **Options.** Each one stated so that choosing between them is possible without reading the code.
> **Recommendation.** One, argued — the default is the most restrictive behaviour, and no configuration
> that bypasses it (decision 67).
> **Blocks.** The step, front or landed work that waits on the answer.

## Front 24 (effects by return) — choices made in implementation, to confirm

Each one was decided by the implementation so the front could land; the maintainer confirms or
reverses it. Numbered `24-a` … so they do not collide with the decision numbering.

### 24-a · The effect codes the diagnostics table does not name (README open point 2)

> **Raised by:** `00 · 24-effects-by-return` step E3
> **Measured.** `effect-missing-annotation`, `effect-missing-wrapper`,
> `effect-duplicate-annotation`, `effect-on-declare-forbidden` and `effect-on-behavior-method-forbidden`
> have no annotation left to be about; `for-over-fallible-generator` enforced a rule decision 122 deletes;
> the guide spells a `throw` refusal with `effect-try-without-fallible-channel`.
> **Options.** (a) delete the annotation codes, merge `effect-throw-without-fallible-channel` into
> `effect-try-without-fallible-channel`, keep `effect-wrapper-mismatch` for the one mismatch left, keep
> `yield-without-generator` / `generator-loop-closed-scope`; (b) keep a separate `throw` code.
> **Recommendation.** (a), implemented: `comptime/diagnostics.zig` lists the survivors;
> `effect-wrapper-mismatch` now means only "a component's `T` implements `@Context<B>` with a `B` other than
> the `C` it is written with"; `for-over-future-generator` / `for-await-expects-future-generator` are renamed
> `for-over-stream` / `for-await-expects-stream`. The guide's code-less refusals (a component `use`d, `use`
> in a closure, `break :outer` out of a prefixed loop) keep their existing codes (`use-of-non-context-fn`,
> `use-without-context-effect`, `generator-loop-closed-scope`).
> **Blocks.** Nothing — reversible by renaming constants.

### 24-b · `@Task`'s method set (README open point 4)

> **Raised by:** step E1
> **Measured.** The prelude's async wrapper had `map` / `flatMap` / `await`; decision 120 says "`.map`,
> `.then` and the like, without an error parameter".
> **Options.** (a) `map` and `then` (the monadic bind under the name the guide uses); (b) add `flatMap` as
> an alias of `then`.
> **Recommendation.** (a), implemented — one spelling per operation (decision 67). `mapError` has nothing to
> map. Neither method is lowered by a backend yet: they are declared (documentation, like the rest of
> `builtins.d.bp`) and a call to them is not type-checked against the declaration until the behavior-method
> registry reads wrappers.
> **Blocks.** std/async (24-c) if it wants a combinator form.

### 24-c · `iter for` / `iter while` as a desugared `loop`, and the label's place (README open point 9)

> **Raised by:** step E2
> **Measured.** The README asks for a `GenLoop { kind, loop }` node; the four backends each lower one
> annotated-loop shape (the `loop` of 22-loops).
> **Options.** (a) a new node and a fourth-times-four set of lowerings; (b) parse `iter for (xs) { … }` as
> the prefixed `loop { for (xs) { … }; break; }` it means — decision 125's own equivalence — keeping the
> written keyword in `LoopExpr.prefixedKeyword` for the formatter.
> **Recommendation.** (b), implemented. The label stays where 105 writes it, after the loop keyword:
> `iter loop :l { … }` labels the generator scope (`yield :l`, `break :l v`); `iter for :l (xs) { … }` labels
> the written `for` (so `break :l` / `continue :l` keep their meaning) — `yield :l` there is then
> `yield-label-not-generator`. If the maintainer wants the label of a prefixed `for` to name the generator
> scope too, the parser moves it to the outer node; nothing else changes.
> **Blocks.** Nothing.

### 24-g · `std/async`'s shape under a Task that never fails (README open point 3)

> **Raised by:** step E7
> **Measured.** Before front 24, `std/async` had a thunk surface (`allOf`, `settleOf`, `raceOf`,
> `timeout` over thunks of the old fallible wrapper) and a started surface (`all`, `allSettled`, `race`),
> both built on a rejected task being the failure. The guide writes
> `try await async.allOf([fetchUser(1), fetchUser(2)])` — started Tasks whose value is a `@Result` — and
> the `front/24-cells` suite follows it; the `beam_memory_*` cells need unstarted thunks, because an eager
> erlang Task has already run by the time a combinator receives it.
> **Options.** (a) `allOf` over started `@Task<@Result<T, E>>` (stops at the first `Error` in input order)
> plus a thunk surface under other names; (b) `allOf` over thunks, as `01-std/02` wrote it; (c) one
> overloaded `allOf` for both element shapes (the language has no overloading by type).
> **Recommendation.** (a), implemented: **started** — `allOf(Array<@Task<@Result<T, E>>>) ->
> @Task<@Result<Array<T>, E>>`, `all(Array<@Task<T>>) -> @Task<Array<T>>` (both written in botopink over
> `try await` / `await`), `race`; **unstarted** — `runAll(Array<fn() -> @Task<T>>) -> @Task<Array<T>>`
> (spawned per task on erlang, `Promise.all` on node; over `@Result` thunks it is the settled view),
> `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` answering `Error("timeout")` (a `string`,
> as every std error is — no `TimeoutError` type, and a fallible task's own `Error` stays inside the `Ok`).
> `failed(message)` answers `Error(message)` instead of rejecting. `allSettled`, `settleOf`, `unwrapAll`
> and `attempt` are removed: a Task has no rejection to settle. A crash inside a spawned task is
> re-raised (a crash is a bug, decision 120's fatal host failure).
> **Blocks.** `01-std/02-std-async-primitives`, whose README still specifies the thunk-shaped `allOf`.

## Front 01-std (the bundled libraries, `json.decode`) — choices made in implementation, to confirm

Decided by the implementation of `01-std-lib-enablement` Step 13, `04-routing-lib`, `05-actions-lib`
and `06-validation-lib` so the fronts could land; the
maintainer confirms or reverses each.

### 01std-a · Where a bundled library is loaded — the CLI and the LSP, not `expandStdImports`

> **Raised by:** `01-std/04-routing-lib` Step 2
> **Measured.** The front's *Mechanism* table generalises `expandStdImports` and replaces each `"std"`
> check in compiler-core, `commonJS.zig`, `erlang.zig`, `beam_asm.zig` and `engine.zig` with a lookup.
> `std`'s path through the core is std-specific end to end (`markStdImports`, `env.stdModules`,
> qualified-call gating, the BIF table, synthesised imports), and `beam_asm.zig` is held by fronts 14
> and 18. A declared dependency, on the other hand, already reaches the codegens as ordinary modules
> `<dep>/<stem>` and comes out as `<dep>@<stem>` / `./<dep>/<stem>.js` (decision 109). Implemented:
> `build.zig`'s `bundled_packages` generates `comptime.bundled_packages` (names + embedded `.bp`
> modules); the CLI (`libs.loadDependencies` → `appendBundled`) and the LSP
> (`ProjectGraph.appendBundled`) prepend the embedded modules of every bundled package a module
> imports; `checkImportSources` exempts bundled names; a bundled name in `dependencies` is refused.
> compiler-core names no package but `std`; no codegen file changed; `snapshots/codegen/**` unchanged.
> **Options.** (a) keep it — a non-std bundled package is ordinary code to the core, as decision 115's
> "`routing` is ordinary code to the checker" reads; (b) generalise `expandStdImports` and the std
> checks as the table says, which changes the four codegens and the checker for no observable
> difference today.
> **Recommendation.** (a). The observable contract of Step 2 holds (no `dependencies`, atoms,
> requires, refusal, embedded copy only); the one box it does not tick is the compiler-suite test
> beside `std_package.zig`, replaced by CLI and LSP unit tests.
> **Blocks.** Nothing; `00 · 23-std-purity` step 3 rewrites `stdPkgFilesFromRoot` beside the new
> `bundledPkgFiles` and should keep `std` out of the latter.

### 01std-c · `routing.pattern`'s empty pattern matches only `/`

> **Raised by:** `01-std/04-routing-lib` Step 8
> **Measured.** rakun-web's `matcherMatches("", path)` was true for every path (the Next default for a
> middleware with no `#[matcher]`); `routeMatches` had no such rule. A grammar shared with jhonstart
> should not carry one consumer's default.
> **Options.** (a) `parsePattern("")` is no segments and matches `/` only; rakun-web keeps "empty runs
> everywhere" at its call site (`matcherAdmits`) — implemented; (b) the library's empty pattern
> matches everything.
> **Recommendation.** (a). Leaves the Step 8 box "every `middleware_test.bp` assertion has a line here
> with the same literals" one literal short, by design.
> **Blocks.** Nothing.

### 01std-d · The decorator registry is keyed by bare name — rakun's placement-only `#[validated]` left

> **Raised by:** `01-std/06-validation-lib` Step 7
> **Measured.** In `modules/rakun`, a test importing `{decorators.validated} from "validation"` got
> `unbound variable 'validateProbe'`: `config.bp`'s placement-only `pub fn validated(comptime decl:
> @Decl)` shadowed the imported one package-wide, even under `as`. The same probe in a package with no
> local `validated` passes. `comptime.zig` `resolveImports` looks decorators up in one
> `StringHashMap(FnDecl)` keyed by name.
> **Options.** (a) delete rakun's placement-only marker (implemented — decision 116 rule 5 already says
> never both); (b) key the decorator registry by module and resolve through the import, a checker
> change for `00 · 01-checker`.
> **Recommendation.** (a) for rakun now, and (b) as a checker item: two libraries may not declare a
> same-named decorator today without one silently winning.
> **(b) landed** — `00 · 01-checker`: both comptime registries are keyed by the
> exporting module; `modules/template_name_collision` pins it.
> **Blocks.** Nothing here; (b) blocks any two bundled/declared libraries sharing a decorator name.

### 01std-e · `actions.readEnvelope` refuses a `redirect` that disagrees with `n`

> **Raised by:** `01-std/05-actions-lib` Step 3
> **Measured.** The spec derives `redirect` from `n` in the writer; the reader was silent. The only
> writer can never produce a disagreeing pair, so one that arrives was not written by it.
> **Options.** (a) refuse it (implemented, decision 67); (b) read `n` and ignore `redirect`.
> **Recommendation.** (a).
> **Blocks.** Nothing.

## Front 01-std (std's open rows) — choices made in implementation, to confirm

Decided by the std rows (`querystring`, `fs.exists`, `throwsWith`, decision 110's use side) so the
rows could close; the maintainer confirms or reverses each.

### std-a · `querystring` refuses by `Error`, in both directions, with two parsers

> **Raised by:** `01-std` — the `querystring` row
> **Measured.** rakun's 03r-e keeps a component that is malformed or decodes to a control character
> *as written* (`decodeComponent("%0A") == "%0A"`). `querystring.parse` / `parseForm` answer
> `@Result<Array<#(string, string)>, string>` and refuse instead: "a `%` not followed by two hex
> digits", "an escape sequence that is not UTF-8", "a control character" (U+0000–U+001F, U+007F, raw)
> and "an escape that decodes to a control character". `stringify` answers `@Result<string, string>`
> and refuses a control character, so every text it writes is one `parse` reads back. `parse` is the
> RFC 3986 query (`+` stays `+`, a leading `?` stripped); `parseForm` is the form flavour (`+` is a
> space, nothing stripped). Identical on commonJS, erlang and beam (`libs/std/src/querystring.bp`'s
> fourteen tests; the beam run by hand); wasm refuses the host cells at the call.
> **Options.** (a) as implemented; (b) 03r-e's keep-as-written in `parse`, `stringify` infallible;
> (c) one `parse` taking the flavour as a parameter.
> **Recommendation.** (a) — the restrictive reading (decision 67): a component that cannot be read is
> not read, and an input the codec's own reader refuses is not written.
> **Blocks.** rakun's `splitQuery` / `encodeQuery` moving onto `querystring` (the rakun front's).

### std-b · `fs.exists` follows a symbolic link

> **Raised by:** `01-std` — the `fs.exists` row
> **Measured.** `fs.exists` is a `stat` on both targets now (`existsSync` / `file:read_file_info`):
> `/`, `/dev/null`, a file and a directory are `true` on commonJS and erlang (`io/fs.bp`'s "fs.exists
> is true for a path of any kind"). A link whose target is missing is `false` on both — the answer a
> read through it gives.
> **Options.** (a) follow the link (implemented); (b) `lstat` — a dangling link exists as a link.
> **Recommendation.** (a): the question a caller asks before reading is whether the read can find
> something.
> **Blocks.** Nothing.

### std-c · Decision 110's folder namespace is a rewrite of the parsed program

> **Raised by:** `00 · 23-std-purity` step 6
> **Measured.** `comptime/std_namespace.zig` rewrites `io.fs.f()` after `import {io} from "std"`
> into the namespace of `io/fs` bound as `__bp_ns_io_fs` (the item `io.fs as __bp_ns_io_fs` added),
> and `collections.Dict` after `import {collections}` into `Dict` (the item `collections.Dict`
> added) — the leaf forms the checker and four backends already lower. Only the modules the program
> reaches are imported, so STD-001 checks those and not all of `io/`. A member that names nothing
> (`io.nope.f()`) is refused as `unbound variable 'io'` at the use, and a module declaring its own
> top-level `Dict` keeps `collections.Dict` unrewritten (refused the same way). A local named like
> the folder (`fn f(io: …)`) is not told apart from it.
> **Options.** (a) the rewrite (implemented); (b) a namespace type in the checker and a lowering of
> `a.b.f()` in each of the four backends.
> **Recommendation.** (a) — one file, no backend change; (b) only if a diagnostic naming the folder
> ("std folder `io` has no module `nope`") is wanted.
> **Blocks.** Nothing; 23-a's option (b) is this.

## Front 01-checker — choices made in implementation, to confirm

Decided by `00 · 01-checker` so its steps could land; the
maintainer confirms or reverses each. Numbered `01c-a` … so they do not collide with the decisions.

### 01c-a · A comptime module's atom keeps the compiler's `bp` namespace and adds the owner's path

> **Raised by:** `00 · 01-checker` / C-01 (13 half 1 step 5's last box)
> **Measured.** 13's README wrote the target atom as `jhonstart@html__tpl__html__<hash>` — the owning
> package's namespace — before decision 109 made every atom start with its package and before the
> comptime node became shared by every package of a build. The owner's path now reaches the
> evaluator (`Env.comptimeOwners`); the owner's *package* does not reach
> `comptime/**` at all — `crossModule.Packages` is set by the driver on the codegen config.
> **Options.** (a) `bp@comptime@<owner path>__tpl__<decl>__<hash>` — the compiler's reserved package,
> the owner as path (implemented; decodes to package `bp`, path `comptime/<owner>`); (b)
> `<owner package>@<owner path>__tpl__<decl>__<hash>` — needs `Packages` threaded into inference, and
> puts content-addressed scratch in the same namespace as the modules the package ships.
> **Recommendation.** (a): no user atom can ever meet it (`manifest` refuses `bp`), the file is named,
> and the hash keeps its content-addressing.
> **Blocks.** Nothing.

### 01c-b · A section leaf has a leading-dot shorthand, where the position is that section

> **Raised by:** `00 · 01-checker` step 12 — the step's own "what the step has to decide
> first".
> **Measured.** `.Zeta` against `Token.Layout.Break` was `unbound variable 'Zeta'` with no
> collision anywhere; step 4 (d)'s acceptance already wrote `val t: Token.Text = .Bold;` as checking.
> A top-level variant's shorthand is decided by the position's expected type (`.Circle(…)`, front 15).
> **Options.** (a) yes, by the same rule — the position's type is the section (implemented); with no expectation the leaf is refused naming its section; (b) no shorthand for a
> section leaf, the full path always, with a named refusal.
> **Recommendation.** (a): one rule for every leading dot, and a refusal wherever the rule has no
> answer — nothing is picked.
> **Blocks.** Nothing; emilia writes the full path today and keeps compiling.


## `checker-rows-2` — choices made in implementation, to confirm

Decided by the checker rows of `front/checker-rows-2` so they could land; the maintainer confirms or
reverses each. Numbered `ck2-a` … so they do not collide with the decisions.

### ck2-a · `@module()` is refused until a target lowers it

> **Raised by:** `checker-rows-2`, the `runtime_builtin_names` row
> **Measured.** `builtins.d.bp` declares `pub declare fn module() -> module;`; no backend lowers the
> call — commonJS emitted `@module()` verbatim (`SyntaxError` at load), erlang called an undefined
> `module/0` — and no type named `module` exists. The checker typed it `void`.
> **Options.** (a) refuse it at the `@` (`builtin-not-lowered`) until a rule says what a module
> value is (implemented, `reject/builtin_module_not_lowered`); (b) delete the declaration from
> `builtins.d.bp`, making it `unknown-builtin`; (c) specify the module value and lower it.
> **Recommendation.** (a) now, (b) unless a front needs the value: a declared name with no meaning is
> a promise the compiler does not keep.
> **Blocks.** Nothing.

### ck2-b · A section member may share a name with a top-level variant of the same enum

> **Raised by:** `checker-rows-2`, the status row "an enum section head silently captures a top-level
> variant of the same name"
> **Measured.** `Layout.Break { After }` beside `After(inner: Token[])`: the checker resolves each
> position by its path or its expected type — `Token.After(…)` and `.After(…)` under `Token` build the
> payload variant, `.After` under `Token.Layout.Break` the leaf, a `case` over each matches its own —
> and commonJS, erlang and beam run it (`modules/enum_section_leaf_beside_variant`); wasm's `case`
> reads the leaf's tag through a flat table. Refusing the name at the declaration was implemented and
> measured: emilia's `Token` has eleven such pairs (`Sm`/`Md`/`Lg`/`Xl`/`X2xl` beside
> `Text.Size.*`, `Alpha` beside `Mask.Mode.Alpha`, `Empty`, `First`, `Last`, `Dark`, `Transform`),
> each an upstream Tailwind name.
> **Options.** (a) legal: the path and the position's type tell the two apart (`docs.md` § Sections of
> an enum says so — implemented); (b) refuse a section member named like a top-level variant
> (`enum-section-member-shadows-variant`, at the member), and emilia renames eleven members.
> **Recommendation.** (a): nothing is ambiguous in the language — every position that names the
> member names its level — and the defect was the checker's flat table (fixed) and is wasm's
> (listed). A variant declared twice at ONE level is refused (`enum-variant-duplicate`).
> **Blocks.** emilia, if (b).

### ck2-d · A label in a call of a function value is refused

> **Raised by:** `checker-rows-2`, the labelled-call row
> **Measured.** `fn apply(f: fn(i32, string) -> string) { return f(n: 1, s: "x"); }` checked and
> zipped by position: a function type carries no parameter names, so the labels were ignored and
> `f(s: "x", n: 1)` meant `f("x", 1)`.
> **Options.** (a) `label-on-function-value` at the labelled argument (implemented;
> `reject/label_on_function_value`); (b) labels ignored (today's reading, silent); (c) function types
> carry names (`fn(n: i32, s: string)`) and a label must match one.
> **Recommendation.** (a); (c) is a larger surface change for a form nobody writes.
> **Blocks.** Nothing.

### ck2-e · A std decorator is reached through its module, and emits through the annotation's handle

> **Raised by:** `checker-rows-2`, the `#[mocks.mock]` row
> **Measured.** `@emit`ted code is spliced into the consumer's module, where `mocks.bp`'s runtime is
> reachable only through the handle the consumer imported (`mocks`, or an alias); inside `mocks.bp`
> it is bare. A leaf import (`import {testing.mocks.mock}`) would leave the emitted code no handle.
> **Options.** (a) a namespace import registers the module's decorators as `#[<handle>.<fn>]`; the
> decorator reads its handle from the annotation that fired it (`decl.annotations`' name prefix); a
> leaf import of a std decorator is `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` is
> `unknown-annotation` (implemented); (b) the leaf import allowed, and the decorator's emitted names
> resolved in the decorator's module (decision 112's hygiene extended to `@emit`).
> **Recommendation.** (a) now; (b) is the general answer for every library's decorator and needs
> decision 112 to say it covers `@emit`.
> **Blocks.** Nothing.

## Front 23 (`00 · 23-std-purity`) — choices made in implementation, to confirm

Decided by the implementation of steps 3 and 5 so the
tree could land; the maintainer confirms or reverses each.

### 23-a · A `collections` constructor is reached through its type leaf, not the module namespace

> **Raised by:** `00 · 23-std-purity` step 3
> **Measured.** Decision 111's `Dict.empty()` compiles and runs on commonJS, erlang, beam and wasm
> when `Dict` is imported as a leaf (`import {collections.Dict}` / `collections: {Dict, Set}`).
> After `import {collections} from "std"`, `collections.Dict.empty()` is `unbound variable
> 'collections'` on every target — the checker has no `module.Type.fn()` path; `collections.toInt(…)`
> (a module function) resolves. Every importer written by the sweep (routing, rakun, the compiler's
> tests and cells, `examples/stdlib-tour`) uses the leaf form.
> **Options.** (a) the leaf form is the spelling (implemented; decision 111's own example imports
> `collections: {Dict, Set, Queue}`); (b) teach the checker and the four codegens
> `module.Type.fn()` — the same use-side path decision 110's folder namespace needs.
> **Recommendation.** (a) now, (b) with decision 110 (23 step 6): one change covers both.
> **(b) landed** — 23 step 6: `collections.Dict.empty()` after `import {collections}` runs on the four
> targets (`modules/import_std_type_through_module`; the mechanism is std-c).
> **Blocks.** Nothing.

### 23-b · `base64`'s four functions are retired, not aliased

> **Raised by:** `00 · 23-std-purity` step 3
> **Measured.** `base64.decode` answered a `string`; its replacement `encoding.base64Decode` answers
> `@Result<string, string>` (front 01 validates before `Buffer.from` truncates), and
> `decodeUrlSafe` → `base64UrlDecode` likewise. No library imported `base64`. `base64.bp` is deleted
> and its four tests are re-spelled over `encoding`'s names at the foot of `encoding.bp` (so std
> stays at 417 tests).
> **Options.** (a) retire the four (implemented — decision 106 and `01-std/modules.md` name the
> replacements); (b) keep `encode`/`decode`/`encodeUrlSafe`/`decodeUrlSafe` in `encoding` as
> string-returning aliases.
> **Recommendation.** (a): two spellings of one codec, one of which hides the refusal, is what front
> 01 removed.
> **Blocks.** Nothing.

### 23-c · Two `botopink test` fixes for a project whose own modules sit in a folder

> **Raised by:** `00 · 23-std-purity` step 3
> **Measured.** `botopink test` in `libs/std` after the move: on commonJS every module refused with
> `module 'io/random' requires "./sidecars/random.mjs", but its library 'io' resolves to no package
> directory` (`shipMjsSidecars` reads any `a/b` module name as dependency `a`'s); on erlang twelve
> tests died `{error,undef}` — `test_cmd` wrote a module's type units (`std@io@net@@Socket`) at the
> root of the run, and the runner of `io/net` loads only its own directory and below. A two-module
> scratch (`src/top.bp`, `src/io/rec.bp`, one record each) reproduces the second on any project.
> **Options.** (a) fix both in the CLI (implemented, compiler-cli carve-out: a module whose source
> is in the project's own `src` is the project's; units are written beside the module that declares
> them); (b) keep std flat on disk and nest only the registry keys.
> **Recommendation.** (a). The rules are general — any library with a folder module had both
> defects — and neither touches compiler-core or a snapshot.
> **Blocks.** Nothing.

## Front 02-packaging · 95 (the package cut) — choices made in implementation, to confirm

Decided by `02-packaging/95-ecosystem-package-restructure` so the relocations could land; the maintainer confirms or reverses each.

### 95-a · Front 95 performs the relocation-only cuts `jhonstart-link` and `rakun-app`

> **Raised by:** `95-ecosystem-package-restructure` steps 5 and 7
> **Measured.** `04-jhonstart/modules.md` § 1 puts front 27's `link.bp` / `reconcile.bp` in
> `jhonstart-link`, and `03-rakun/modules.md` § The cut puts fronts 22 and 23 in `rakun-app`; both
> fronts had landed in the core. Front 95's own README listed `jhonstart-link` as "front 27's" and
> said rakun had "nothing left" for it, while its **Owns** line claims "the relocations the cut in
> each library's `modules.md` needs". Nothing in either core imports the moved modules
> (`grep`), so each move is the files plus the import lines it changes: jhonstart 120 → 85 + 35,
> rakun 369 → 310 + 59 on commonJS (367/2 → 308/2 + 59/0 on erlang); `examples/rakun-ssr` prints
> a byte-identical document.
> **Options.** (1) relocate now, as a move with no behaviour; (2) leave both in the core until the
> owning fronts (27's step 4, 22/24) touch them again.
> **Recommendation.** (1) — implemented. The two owning fronts would otherwise make the move in the
> middle of a behaviour change, which is the harder diff to review; `modules.md` § 0 (a) and the
> `fronts.md` rows now name the members.

### 95-b · `rakun-app` inherits the workspace's `targets`

> **Raised by:** `95-ecosystem-package-restructure` step 5
> **Measured.** The core it came from declares `["commonJS"]` (a restriction front 04 lifts);
> `03-rakun/modules.md` § Targets says every member is `["erlang"]`, corrected "by the lowest-numbered
> front of each module". The 59 moved tests pass on **both** rows.
> **Options.** (1) no `targets` — inherit `["commonJS", "erlang"]` now and `["erlang"]` when front 04
> changes the workspace root; (2) `["commonJS"]` like the core (an erlang ledger line); (3)
> `["erlang"]` now (a commonJS ledger line, and the node half of `ssr.mjs` untested).
> **Recommendation.** (1) — implemented: both rows are hard cells, no ledger line, and the member
> follows the workspace without an edit.

### 95-c · `erika-test` exists

> **Raised by:** `95-ecosystem-package-restructure`
> **Measured.** `02-packaging/README.md` § 2 makes `modules/<lib>-test/` mandatory for every library;
> erika is a workspace since `02-packaging` step 2 and its `AGENTS.md` said the member "waits on
> `01-std` steps 2–3", which have landed. Front 95's table did not list erika.
> **Options.** (1) create it empty now; (2) wait for an erika front.
> **Recommendation.** (1) — implemented: one inline test, 1/1 on both rows.

### 95-d · The onze takeover, prepared: the tag's commit and the orchestrator's first commit

> **Raised by:** `95-ecosystem-package-restructure` step 2
> **Measured.** The orchestrator's workspace is an orphan branch `front/95-onze-orchestrator` (no
> history of the mocking library) — seven members, each 1/1 on commonJS and erlang on a copy of
> the tree; the retirement banner is a commit on onze `front/95-packaging` over `feat` `b1e690d`.
> The restricted cells `onze-cli · erlang` and `onze-og · commonJS` need ledger lines that are
> stale (refused) until `repository/onze` is the orchestrator.
> **Options.** Tag `mocking-lib-final` on (1) `b1e690d`, the last code commit, or (2) the banner
> commit. Ledger lines (a) in the compiler commit the takeover's meta bump pins, or (b) now, which
> reds `test-libs` until the takeover.
> **Recommendation.** (1) and (a); the exact commands are in front 95's step 2.

### 95-e · A member importing the core's request context names the module

> **Raised by:** `95-ecosystem-package-restructure` step 5
> **Measured.** In `modules/rakun-app/src/ssr.bp`, `import {…, percentDecode, …} from "rakun";`
> is refused: `` `percentDecode` is declared `pub` by `std/encoding` and by `rakun/request_context`,
> and this import does not say which ``. Inside the core the same import (`from "request_context"`)
> named the module. The move writes `from "rakun/request_context"`, which the compiler accepts.
> **Options.** (1) keep the qualified import; (2) rename one of the two `percentDecode`s (decision
> 116 moves rakun's codec to std `encoding`, which would retire the duplicate).
> **Recommendation.** (1) now; (2) is the decision-116 work of rakun front 62, after which the line
> can go back to `from "rakun"` or drop the name.

## Track B (03-rakun) — choices made in implementation, to confirm

Decided by the rakun track (worktree `.tasks/03-rakun`, branch `front/03-rakun`, 2026-09-26) so the
fronts could land; the maintainer confirms or reverses each.

### 03r-a · Every rakun manifest `["erlang"]` now, with the examples not runnable until the compiler ships sidecars

> **Raised by:** `04-rakun-erlang-runtime` step 10, 2026-09-26
> **Measured.** With `request/6` fixed the core is 310/0 on erlang; decision 117 rule 9 puts every
> manifest on `["erlang"]` and decision 113 deletes `runtime.mjs`. But a BUILT erlang program neither
> ships nor loads its `.erl` sidecars (`shipErlSidecars` runs only from `test_cmd.zig`;
> `__bp_load_siblings/0` is emitted only under the test flag): `botopink run` in `examples/rakun`
> dies with `undef rakun_runtime:serve/2`, in `examples/rakun-ssr` with `undef
> rakun_file_router:register_layout/2`. The three examples build; none runs. The compiler
> repository's `scripts/restricted-targets.txt` pins the old matrix, so `test-libs` reds on stale
> lines until that ledger is edited.
> **The compiler half now.** `botopink build --target erlang` ships a package's `.erl` sidecars into
> `out/erl/` (five for `examples/rakun`), where `botopink run` compiles every `.erl` onto the code
> path; an `@External.Erlang` module neither shipped nor in the Erlang code path is a located build
> error.
> **Options.** (1) move now (rakun `99b8049`) and owe the run to `00 · 10-cli-residuals` and the
> ledger to the compiler repository; (2) keep the examples on commonJS with a node twin kept alive
> for them only; (3) wait for the compiler.
> **Recommendation.** (1) — implemented. (2) is the second runtime decision 113 retires; (3) leaves
> the two reds and the node twin for a milestone. The ledger edit: delete the `rakun`,
> `rakun-example`, `rakun-container-example`, `rakun-ssr-example` erlang lines; add a commonJS
> `build` line for `rakun`, `rakun-app`, `rakun-test` and the three examples; `rakun-web commonJS 0`
> becomes `build` (`test-libs` names each).

### 03r-b · `rkPropInt("12abc")` is `12`, not `0`

> **Raised by:** the track audit of `04-rakun-erlang-runtime` step 3, 2026-09-26
> **Measured.** The box says `0`; `rakun_runtime.erl` and `test/erlang_runtime_test.bp` "propInt is
> parseInt, and unparsable is zero" say `12` — `parseInt(v, 10)`'s leading-integer rule, which
> front 05's `toI32` states for every typed reader so `#[value]` and a bound record never disagree.
> **Options.** (1) keep `12`, amend the box; (2) make both refuse trailing text.
> **Recommendation.** (1) — the box text is amended. (2) is the stricter reading and would be a
> behaviour change across fronts 04 and 05 at once; say so and it is one function in each.

### 03r-c · Front 05's readers stay botopink; there is no `rakun_config.erl`

> **Raised by:** the track audit of `05-rakun-config-profiles`'s Definition of done, 2026-09-26
> **Measured.** The DoD asks for `src/sidecars/rakun_config.erl`; front 05 wrote the readers over
> std's `fs` / `env`, and `.json` now reads through std's `json.decode` (rakun `b742a4c`).
> **Options.** (1) no sidecar — amend the box; (2) port the readers to Erlang.
> **Recommendation.** (1). A reader in botopink has no host half to keep in step.

### 03r-d · The configuration check runs in `bootSequenceFor`, lazy initialization included

> **Raised by:** `05-rakun-config-profiles` step 9 / `14-rakun-validation` step 6, 2026-09-26
> **Measured.** `Rakun.run` (`bootstrap.bp`) is frozen; the boot that constructs components is front
> 06's `bootSequenceFor`. rakun `c8f185c` registers one check per `#[configurationProperties]` +
> `#[validated]` record at module load and runs them all after event 3 and before the eager pass.
> **Options.** (1) there, with lazy initialization too; (2) at the record's first injection only.
> **Recommendation.** (1) — implemented: an invalid configuration must not wait for the request that
> first injects it, and `lazy-initialization` is about construction, not about validation.

### 03r-e · A cookie or query component never decodes into a control character

> **Raised by:** `62-rakun-request-context` step 7, 2026-09-26
> **Measured.** std's `encoding.percentDecode("%0A")` answers a newline; front 62's own decoder
> kept `%0A` as written ("a decoder that can produce a newline is how a newline reaches a header").
> rakun `98a5090` reads through `decodeComponent`: std's decode, but an input std refuses (`%zz`,
> `100%`) or one that would decode to a control character stays exactly as written.
> **Options.** (1) `decodeComponent` as above; (2) std's decode verbatim.
> **Recommendation.** (1) — the restrictive default. With rakun's `percentDecode` gone, 95-e's
> qualified import can return to `from "rakun"`; it is left as it is.

## Open

Questions the language-gaps sweeps (`front/compiler-gaps-rakun`, the rakun rows of
[`language-gaps.md`](./language-gaps.md); `front/gaps-sweep-2`, every other row) could not answer from
`docs.md` or the decisions taken. Each `lg2-*` row of `language-gaps.md` is a feature the language does
not have; the recommendation is always the most restrictive reading — the feature stays out and the
row's nearest form is the design — and the cost of that reading is named where it is high.

### ck2-c · A leading default on a free `fn`

> **Raised by:** `checker-rows-2`, C-04's remaining reach
> **Measured.** `fn lead(a: i32 = 1, b: i32)` is `fn-param-default-trailing-only`, while
> `type Port(number: i32 = 80, host: string)` is legal and `Port(host: "a")` fills `number`
> (`docs.md` § defaults). Since a label names its parameter on every call path, `lead(b: 2)` would
> fill `a` by the same rule the record uses.
> **Options.** (a) keep the asymmetry: a free `fn` declares trailing defaults only; (b) a free `fn` may
> declare a leading default, reached by labelling what follows it, as a record's field; (c) refuse the
> leading default on a record too.
> **Recommendation.** (a) — the most restrictive that breaks nothing written: (c) would refuse
> `docs.md`'s own `Port` and the libraries' records with a leading default.
> **Blocks.** Nothing.

### lg-a · Where a `try` inside a lambda may appear

> **Raised by:** the language-gaps sweep, row "`try` inside a lambda does not propagate", 2026-09-26
> **Measured.** `fn each() -> @Result<i32, string> { [1, 2].forEach({ x -> try bad(); }); return 2; }`
> answers `Ok(2)` on commonJS and erlang: the checker gives every lambda body `throwContext =
> .unchecked` (`inferFunctionExprExpected`), so the `try` type-checks, the lambda's `Error` is its
> own value and `forEach` drops it. `docs.md` § Tests says "a `try` inside a lambda is the lambda's",
> and decision 121 says `try` is legal only where a `@Result` is in some layer of the return — but no
> rule says what a lambda's return is when nothing annotates it, nor whether a `@Result` a callee
> discards is an error. An assertion written through a lambda passes vacuously.
> **Options.** (1) The lambda's return is its expected type's (`fn(x: T)` → `void`): `try` there is
> `effect-try-without-fallible-channel`, and an unannotated lambda with no expected type takes the
> same refusal; (2) as (1), but a lambda with no expected type becomes `-> @Result<…>` on its own;
> (3) keep today's reading and refuse only a `@Result` a statement discards.
> **Recommendation.** (1) — the most restrictive, and 121's rule applied to lambdas as written: a
> lambda that must fail declares it (`{ x -> … }` under an expected `fn(x: T) -> @Result<U, E>`).
> Every library lambda with a `try` today is then located by the checker.
> **Blocks.** The language-gaps row; front 08's assertion helpers.

### lg-b · What a lambda's write to a captured `var` means on the BEAM

> **Raised by:** the language-gaps sweep, row "A `var` mutated inside a lambda body (outside a
> `for`) does not lower on erlang", 2026-09-26
> **Measured.** `fn run(f: fn() -> i32, x: i32) -> i32 { return f() + x; }` ·
> `var n = 0; val r = run({ -> n = n + 1; 1; }, 0); @print(n);` prints `1` on commonJS; erlang does
> not compile (`variable 'N@1' is unbound`); **beam prints `0` at exit 0**. `test/closure_capture.bp`
> pins that a write threads out of the lambda `forEach` runs (lowered as a fold), and a local
> closure called at statement position threads through its arguments — but a lambda handed to an
> arbitrary function has no value to thread through, and the BEAM has no mutable local. Every
> lowering is a semantic choice: a process-dictionary cell per activation (never erased — an
> escaping closure still needs it — and invisible to a process `async.runAll` spawns), an ETS cell
> (shared across processes, needs an owner), or a refusal.
> **Options.** (1) Refuse at check time a write to a captured `var` from a lambda that is neither a
> `forEach` body nor a local closure called at statement position (every target, located at the
> write); (2) a process-dictionary cell on erlang and beam, documented as per-process; (3) an ETS
> cell like decision 39's `Ets` module var.
> **Recommendation.** (1) — the most restrictive: the one form each backend threads stays, and the
> program that meant a shared counter says so with a module-level `var` and its `#[@BeamMemory]`
> mode (decisions 38–43), which already answers the per-process question.
> **Blocks.** The language-gaps row; beam's silent `0` stays until the answer lands.

### lg2-a · A byte type

> **Raised by:** the second language-gaps sweep, row "No byte or binary type"
> **Measured.** `val b: Bytes = "a";` is `type mismatch: expected Bytes, got string` on every target: no
> primitive, std type or literal holds bytes, and every host cell marshals through `string`.
> **Options.** (1) No byte type: text only, a binary payload refused at the boundary (front 25's 415);
> (2) a `Bytes` primitive with an explicit encoding boundary (`Bytes.fromUtf8`, `toUtf8` answering
> `@Result`), no implicit conversion to or from `string`; (3) `string` also carries raw bytes.
> **Recommendation.** (1) — the most restrictive: a binary payload is refused where it enters, never
> read lossily. Its cost is every upload, download and image endpoint; if the maintainer takes (2)
> instead, no conversion may happen without a call that can fail, and (3) stays refused — it is how
> `Socket.recv` answers mangled UTF-8 today.
> **Blocks.** The row; fronts 01, 13, 15, 24, 25, 70, 71 (uploads, downloads, images).

### lg2-b · What `@Task<T>` means on the BEAM

> **Raised by:** the second language-gaps sweep, row "`@Task<T>` lowers eagerly on erlang"
> **Measured.** Two `async.delay(300, …)` tasks created before either is awaited take ≥ 600 ms on
> erlang and beam and under 600 ms on commonJS (`@print(elapsed >= 600)` prints `true` / `false`):
> a Task body runs to completion where it is created on the BEAM.
> **Options.** (1) A Task is a value that has not arrived yet, with no promise about when its body
> runs; concurrency is `std/async`'s explicit process per unstarted thunk — documented, and the
> backends keep their evaluation order; (2) a scheduler behind `@Task` on the BEAM (a process per
> Task, `await` a receive); (3) `spawn` / `join` in the language.
> **Recommendation.** (1) — the restrictive reading of decision 120: the type promises the value,
> nothing about overlap, and the one concurrent form stays the explicit one.
> **Blocks.** The row; fronts 02, 23, 25, 28, 30, 60.

### lg2-c · A decorator that rewrites or wraps the body it annotates

> **Raised by:** the second language-gaps sweep, row "A decorator cannot rewrite or wrap the body it
> annotates"
> **Measured.** A decorator reaches its declaration only as `@Decl` data and answers only `@emit`ted
> module-level declarations (`libs/std/src/builtins.d.bp` § Decl reflection model); no form returns a
> replacement body.
> **Options.** (1) None: a decorator adds declarations beside its target (proxies, combinators) and
> never changes what the target does; (2) a decorator form that receives the body and returns the
> one that replaces it; (3) a fixed set of wrapping hooks (before / after / around) the compiler
> composes.
> **Recommendation.** (1) — the most restrictive: reading a declaration never changes its meaning,
> and the proxy types track B ships are the design.
> **Blocks.** The row; track B (06 · 07 · 08 · 10 · 12 · 16 · 83).

### lg2-d · A decorator that reads the body it annotates

> **Raised by:** the second language-gaps sweep, row "A decorator cannot read the body of the
> declaration it annotates"
> **Measured.** `decl.body` in a decorator body is `{error,{badkey,body}}` at the annotation: the
> handle carries kind, name, fields, variants, methods, return type and annotations only.
> **Options.** (1) No statement access: a decorator reads signatures, not bodies; (2) a read-only
> statement tree on `@Decl`; (3) a body-walking comptime API.
> **Recommendation.** (1) — the most restrictive; front 83's saga stays a value pairing each step with
> its compensation.
> **Blocks.** The row; front 83.

### lg2-e · A method-level `@Decl`'s owner and parameters

> **Raised by:** the second language-gaps sweep, row "A method-level `@Decl` carries no owner and no
> parameter list"
> **Measured.** `decl.owner` and `decl.params` on a decorator placed on a method are
> `{error,{badkey,owner}}` / `{badkey,params}` at the annotation; only a type-level handle lists its
> methods' parameters.
> **Options.** (1) Method-level markers stay placement-only and the type-level decorator reads its
> methods (today's pattern); (2) `owner` and `params` on a method-level `@Decl`.
> **Recommendation.** (1) — nothing new reaches a method-level decorator; the type-level decorator
> already sees every parameter.
> **Blocks.** The row; fronts 06 · 07 · 08 · 09 · 10 · 29.

### lg2-f · A decorator argument that names a type

> **Raised by:** the second language-gaps sweep, row "A decorator argument cannot name a type"
> **Measured.** `#[onMissing(MailSender)]` against `fn onMissing(comptime decl: @Decl, t: string)` is
> `` `#[onMissing]` argument 1 must be string ``: an argument is a value, and there is no type value.
> **Options.** (1) A type is named by its string (Spring's `excludeName`); (2) a `type`-typed
> decorator parameter that takes a type name, checked to resolve at the annotation.
> **Recommendation.** (1) — no type-of-type enters the language for one annotation family.
> **Blocks.** The row; fronts 72, 78.

### lg2-g · `@typeName<T>()`

> **Raised by:** the second language-gaps sweep, row "No `@typeName<T>()`"
> **Measured.** `@typeName<User>()` does not parse (`unexpected <`); explicit type arguments now
> parse at every call, method calls included (decision 8 §1.3), so the intrinsic is the only half
> missing.
> **Options.** (1) No intrinsic: a registry key travels as a string beside `T`; (2) a comptime
> `@typeName<T>()` answering the declared name (decision 109's atom is the run-time half).
> **Recommendation.** (1) — the restrictive reading; `rakun`'s `resolve<T>(typeName)` keeps the
> string, now with `T` written explicitly where the binding does not annotate it.
> **Blocks.** The row; front 06.

### lg2-h · Raising and catching by type

> **Raised by:** the second language-gaps sweep, row "No typed raise and no catch by type"
> **Measured.** `try load(p) catch { e: NotFound -> … }` does not parse; the error of a
> `@Result<T, E>` is already typed by `E` and read with `case` inside the `catch` body, and a host
> exception is not an `E`.
> **Options.** (1) An error is the `E` of a `@Result` (decision 121): a typed error is an enum `E`,
> matched with `case`; (2) a `catch` arm per type; (3) typed host exceptions.
> **Recommendation.** (1) — the most restrictive; it makes the row a documentation of decision 121.
> **Blocks.** The row; fronts 07, 31, 63.

### lg2-i · A decorator argument is a raw lexeme

> **Raised by:** the second language-gaps sweep, row "A decorator argument is a raw lexeme"
> **Measured.** An array literal written as a decorator argument, or declared as a parameter's
> default, reaches the body as its source text: `sizes: Array<i32> = [1, 2]` gives `sizes.length ==
> 6`. Only `string`, numeric and `bool` arguments are checked against the parameter type.
> **Options.** (1) Refuse a decorator parameter whose type is not `string`, a number or `bool`, at the
> declaration; (2) typed decorator arguments: each argument checked against its parameter's type and
> handed over as that value.
> **Recommendation.** (1) — the most restrictive: the lexeme path stays exact for the three types it
> handles, and nothing else claims to be typed.
> **Blocks.** The row; front 07.

### lg2-j · Comptime state across decorator invocations

> **Raised by:** the second language-gaps sweep, row "A decorator body cannot accumulate comptime
> state across invocations"
> **Measured.** A module-level `var seen` written by a decorator body is `the wat runtime does not take
> variable Seen used before it is bound` at the annotation; each invocation is its own module call.
> **Options.** (1) Each invocation is independent (today); (2) comptime mutable state scoped to one
> compilation.
> **Recommendation.** (1) — the most restrictive: a decorator's answer depends on its declaration
> alone, so the order the compiler visits declarations can never change a build.
> **Blocks.** The row; front 05.

### lg2-k · Comptime reflection over the project

> **Raised by:** the second language-gaps sweep, row "No comptime reflection over the project"
> **Measured.** `@project()` is `unknown-builtin: unknown builtin @project`.
> **Options.** (1) None: the application list and the SBOM come from a build-time walk; (2) a
> read-only `@project()` answering the manifest and the module list.
> **Recommendation.** (1) — the restrictive reading: a comptime body sees its own declaration.
> **Blocks.** The row; front 81.

### lg2-l · Whether `noreturn` is a bottom type

> **Raised by:** the second language-gaps sweep, row "The navigation signals do not return
> `noreturn`"
> **Measured.** `pub fn notFound() -> noreturn { raise("…"); }` over a `declare fn raise(…) ->
> noreturn` compiles and ends the path on commonJS and erlang; but `throw notFound();` in a `@Result`
> body is `type mismatch: expected string, got noreturn`, and so is `val s: string = notFound();`.
> jhonstart's `notFound()` / `redirect()` declare `-> string` so that `throw notFound();` and
> rakun's `{ -> notFound() }` thunks check.
> **Options.** (1) `noreturn` unifies with nothing: a call to it is a statement that ends its path,
> and the signals become `-> noreturn` called as statements; (2) `noreturn` is the bottom type and
> fits any position.
> **Recommendation.** (1) — the most restrictive; a signal is never a value.
> **Blocks.** The row; jhonstart's signals (front 63) and rakun's navigation tests.

### lg2-m · A module-level annotation

> **Raised by:** the second language-gaps sweep, row "No module-level annotation"
> **Measured.** `#![useCache]` at the top of a module is `this token cannot appear here` at `#`.
> **Options.** (1) None: a module-level policy is a module-level `val`; (2) an inner attribute
> `#![name(…)]` a decorator receives with the module's `@Decl`.
> **Recommendation.** (1) — the most restrictive.
> **Blocks.** The row; front 12.

### lg2-n · A thunk coerced into `Children`

> **Raised by:** the second language-gaps sweep, row "`Children` coerces from array, `Element` and
> `string` but not from a thunk"
> **Measured.** `show({ -> "x" })` against `fn show(children: Children)` is `type mismatch: expected
> Children, got function`.
> **Options.** (1) No thunk coercion: a deferred child is a named field of the boundary; (2) a
> `fn() -> Element` coerces into `Children`.
> **Recommendation.** (1) — the restrictive reading; the compiler-known coercions stay the three.
> **Blocks.** The row; front 30.

### lg2-o · Filesystem access from a comptime body

> **Raised by:** the second language-gaps sweep, row "A comptime body has no filesystem access"
> **Measured.** `fs.readText("schema.txt")` in a decorator body is refused at the annotation (`calls
> .readText(…) … which no primitive type … and no decorator host function provides`).
> **Options.** (1) None: generated `.bp` is checked in (`rakun ws generate`); (2) a sandboxed read of
> declared build inputs, keyed into the build's cache.
> **Recommendation.** (1) — the most restrictive: a build reads only its sources.
> **Blocks.** The row; fronts 88, 93.

### lg2-p · Cancellation

> **Raised by:** the second language-gaps sweep, row "No cancellation"
> **Measured.** `std/async` has no cancel handle; a losing racer and an expired timeout run to
> completion (`libs/std/src/async.bp`).
> **Options.** (1) None: the losing work completes and its result is discarded, documented;
> (2) cancellation tokens passed explicitly; (3) linked processes with a kill path on the BEAM.
> **Recommendation.** (1) — the restrictive reading, in step with lg2-b (1).
> **Blocks.** The row; front 02.

### lg2-q · `@Decl`'s source location

> **Raised by:** the second language-gaps sweep, row "`@Decl` carries no source location"
> **Measured.** `decl.loc.file` in a decorator body is `{error,{badkey,loc}}` at the annotation.
> **Options.** (1) None: the app-relative segment is an explicit decorator argument; (2) a `loc` field
> on `@Decl`, `@src()`'s `SourceLocation`.
> **Recommendation.** (1) — the most restrictive: a decorator's output never depends on where its
> file sits.
> **Blocks.** The row; front 22.

### lg2-r · A body a decorator supplies for a declared method

> **Raised by:** the second language-gaps sweep, row "A bodyless method in a `type` body is only a
> host-backed method"
> **Measured.** A bodyless `declare fn` method with no `#[@External.<Target>]` compiled and failed at
> run time (`… .find is not a function`, `undef`); it is now refused at the call on every target
> (`run/bodyless_method_without_binding`). No decorator can supply the body.
> **Options.** (1) A bodyless method is a host binding only; a `#[query]`-style decorator emits a
> helper the method's body calls; (2) a decorator-supplied body for a declared method.
> **Recommendation.** (1) — the most restrictive, and what the refusal now enforces.
> **Blocks.** The row; fronts 08, 09, 78.

### lg2-s · Module-graph reflection

> **Raised by:** the second language-gaps sweep, row "No module-graph reflection"
> **Measured.** `decl.imports` in a decorator body is `{error,{badkey,imports}}` at the annotation.
> **Options.** (1) None: `importsOf` stays a textual scan that fails loudly; (2) an `imports` field on
> a module-level `@Decl`.
> **Recommendation.** (1) — the restrictive reading, in step with lg2-k and lg2-m.
> **Blocks.** The row; front 68.

### lg2-t · A negative numeric enum leaf

> **Raised by:** the second language-gaps sweep, row "No spelling for a negative numeric enum leaf"
> **Measured.** `type Tok { Rotate { 12, -12 } }` is `this token cannot appear here` at the `-`.
> **Options.** (1) None: a `Neg { … }` sub-section is the convention (fronts 35, 40, 45); (2) a signed
> numeric leaf (`-12`, written `.__N12` in expression position); (3) a unary `-` on an enum path.
> **Recommendation.** (1) — the most restrictive: a leaf name stays a name.
> **Blocks.** The row; fronts 35, 36, 45.

### lg2-u · An expression-position decorator

> **Raised by:** the second language-gaps sweep, row "No expression-position decorator"
> **Measured.** `val x = #[deco] 1;` is refused at the annotation (`loop-annotation-not-generator`,
> the only place an annotation may precede an expression).
> **Options.** (1) None: a decorator annotates a declaration, and expression-level work is a call;
> (2) expression-position decorators run in the eval script.
> **Recommendation.** (1) — the most restrictive.
> **Blocks.** The row; front 48.

### lg2-v · A subdirectory in a git dependency

> **Raised by:** the second language-gaps sweep, row "`DepSpec` has no subdirectory field"
> **Measured.** `DepSpec` is `{git, path, ref, workspace}` (`modules/manifest/src/root.zig`); a
> package that is a directory inside a repository is reachable by `path` only.
> **Options.** (1) None: a git dependency is a repository root, and a monorepo member is installed by
> `path`; (2) a `subdir` field on a git `DepSpec`, resolved by `bpmp`.
> **Recommendation.** (1) — the most restrictive. Its cost is that no `rakun-*` starter installs from
> git outside the meta checkout; if the maintainer takes (2) instead, `subdir` is refused unless
> paired with `git`, and one escaping the checkout (`..`) is refused.
> **Blocks.** The row; front 73, `02-packaging`.

### lg2-w · A host function called from a decorator body

> **Raised by:** the second language-gaps sweep, row "A decorator body cannot call a std function it
> imports"
> **Measured.** A decorator calling `json.quote(…)` (namespace form) is refused as a method nothing
> provides; through `import {json.quote}` it is `call to undefined function quote/1` on the wat
> (commonJS) and BEAM (erlang) runtimes. A project's own host `declare fn`
> (`#[@External.Node(…), @External.Erlang(…)]`) called from a decorator fails the same way on both
> runtimes — only bodied functions travel into the decorator module.
> **Options.** (1) A comptime body calls bodied functions only; a host call in one is refused at the
> call, located, naming the function, on every target; (2) the Erlang cell travels into the decorator
> module on the BEAM runtime and the call is refused on wat; (3) decorators that reach a host cell
> run on the BEAM runtime whatever the target.
> **Recommendation.** (1) — the most restrictive: a decorator's answer never depends on which
> runtime the target selected (decision 84).
> **Blocks.** The row; front 16 (`#[scheduled]`) and every decorator that would reuse std.

## Front 16 (formatter) — choices made in implementation, to confirm

Decided by the implementation of `00-compiler-carry-over/16-formatter` so C-12 and C-13 could land; the maintainer confirms or
reverses each. Every number below is measured over scratch copies of the compiler's trees (`libs/std`,
the three bundled libraries, `examples/`) and the five sibling libraries at their pinned commits — 248
`.bp` files — formatted by the parent commit's binary and by the new one.

### 16-a · C-12's argument list is enabled **with** the constructs that enclose it

> **Measured.** Enabled alone (the parked `argument-list.patch`), the list opened ~1 480 of ~2 770
> lists for what followed them (`) != -1;`, `) + "…"`), because the binary expression around them was
> pinned — decision 65's wrong middle. The same happens inside a pinned array literal
> (`[ThemeEntry(` / `…` / `)]`) and after a brace-less `if` condition (`if (absDiff` /
> `    > tolerance) throw "…"`, the condition breaking for the branch that follows it).
> **Options.** (a) Enable the enclosing constructs first, the list after them, one commit each;
> (b) enable the list together with them; (c) keep the list pinned.
> **Chosen: (b)** — (a)'s intermediate commits are each a wrong middle of their own (a binary run
> enabled alone breaks *inside* the still-pinned argument list: `doc.indexOf("."` / `+ a` …), so the
> six trees would be reformatted twice for nothing. One `groupMeasured` each, all-or-nothing, the outer
> deciding first: a **binary run** (one precedence level) breaks before every operator `+4`; a
> **brace-less `if`** puts its branch on the next line `+4` (a bare `else` under an `else` line; an
> `else if` chain breaks at every `else` or at none; a braced `else { … }` stays outside the group);
> the **argument list** takes decision 61 rule 4's shape; the **array, tuple and behavior literals**
> the same. `commaList` (generic, parameter, pattern, import, type lists) and the one-step pipeline
> stay pinned — none of them holds a call.
> **Cost.** 142 files, +20 835 −7 292 (C-13 included); lines past 80 columns 5 973 → 1 840 (the rest are
> strings and comments); lines opening with `)` and going on with an operator 192 → 8. A second pass
> moves nothing, no token or comment is lost, every sibling package `check`s as before and the cells
> run identically (emilia 569, erika 31, jhonstart 120, onze 4, rakun-web 104 — before and after).
> Per sibling: emilia 18 files +12 940 −4 663 (mostly its test assertions: `assert doc.indexOf(…)` /
> `    != -1;`), rakun 47 +4 760 −1 471, jhonstart 19 +784 −231, erika 2 +167 −63, onze 2 +44 −8 —
> **09's reformat, not committed here**; the compiler's own canonical trees are reformatted.
> **Blocks.** 09's reformat of the five libraries; nothing else.

### 16-b · An array literal's open form is one element per line

> **Measured.** Elements written on one source line were kept on one output line. Once the list
> measures width that is not idempotent (the joined line runs past 80, a call inside it breaks, and the
> next pass reads a different layout: 3 files of the corpus moved on a second pass), and it makes the
> output a function of the input's layout, which decision 65 part 2 rules out.
> **Options.** (a) One element per line in the open form; (b) Wadler's `fill` (as many per line as fit).
> **Chosen: (a)** — all-or-nothing, as decision 65 part 1 states for every group; (b) is the middle.
> **Cost.** Part of 16-a's numbers: a long list of short numbers takes one line each.

## Track C (jhonstart) — choices made in implementation, to confirm

Decided by the implementation of the `04-jhonstart` fronts so they could land; the maintainer confirms or reverses
each.

### 26-a · Every router cell is dual-target, not `#[@External.Erlang]` only

> **Raised by:** `04-jhonstart/26-jhonstart-router` Step 2 / Step 4
> **Measured.** A called erlang-only cell reds the commonJS compile of the core member at its call
> site (`` `__jhRoutePath` has no `#[@External.<Target>(…)]` for the node backend ``); the core is
> compiled on both rows. The five reads, `fill`, `navigate` and `lastNavigation` therefore carry a
> `#[@External.Node("./router_runtime.mjs", …)]` twin.
> **Options.** (a) dual-target cells, one assertion set on both rows (landed); (b) move the router
> to an erlang-only member, which the core's render (front 30) then imports across a target split.
> **Recommendation.** (a). The README's Step 2 / Step 4 boxes state the dual-target shape and cite
> this entry.
> **Blocks.** Nothing.

### 31-a · `notFound()` / `redirect(url)` raise; a boundary captures the raise through one host cell

> **Raised by:** `04-jhonstart/31-jhonstart-error-boundaries` Step 3
> **Measured.** A page, layout or template is a `-> @Component<ElementBase, Element>` body and
> cannot `throw` (decision 121), so the README's `notFound();` statement form needs the call itself
> to raise; `throw notFound();` inside a `@Result` thunk must keep working. botopink's `try … catch`
> unwraps a `@Result` only, so no `.bp` code can observe a raise.
> **Options.** (a) the two functions raise the `routing` reason through a jhonstart host cell
> (`__jhRaise`, `signal_runtime.mjs` / `jhonstart_signal.erl`), typed `-> string`, and the boundary
> runs its child through `__jhCapture`, which answers a raise as `Error(reason)` — implemented;
> (b) the functions return the reason and a component returns a "signalling tree" the render
> inspects; (c) a `never` type (the language gap front 63 records).
> **Recommendation.** (a): the same statement works in a page, a layout, a template and a thunk, a
> crashing component is caught like one that answered `Error`, and the render (front 30) needs the
> same capture for its page thunks. `notFoundReason()` / `redirectReason(url)` answer the reason
> without raising, for a caller that wants it as a value.
> **Blocks.** Nothing.

### 27-a · A browser cell in a two-target member is dual-target, its erlang twin answering the server's truth

> **Raised by:** `04-jhonstart/27-jhonstart-link` Step 4 and `29-jhonstart-client-directive` Step 4 (`modules.md` § 0 (b) / § 4's unsettled `jhonstart-link` row)
> **Measured.** A CALLED `#[@External.Node]`-only cell reds the erlang compile at its caller; both
> `jhonstart-link` and the core declare both targets, and `linkStatus()` / `propsFor()` call theirs.
> **Options.** (a) dual-target cells — `link_runtime.mjs` + `sidecars/jhonstart_link.erl`,
> `island_runtime.mjs` + `sidecars/jhonstart_island.erl` — whose erlang twins answer what is true on
> a server (no link in flight, nothing prefetched, nothing hydrated, no props) — implemented;
> (b) a wrapper nothing on erlang calls (impossible for a hook a server render calls); (c) a
> commonJS-only member for the cells (splits `link.bp` in two).
> **Recommendation.** (a). The Step 4 boxes of fronts 27 and 29 state the dual-target shape and cite
> this entry.
> **Blocks.** Nothing.

### 30-b · `RenderPlugin` is a record of async functions; `chunk` runs where the boundary resolved

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 6 / Step 9
> **Measured.** An `Array<RenderPlugin>` of two different types implementing a `behavior` does not
> type (`type mismatch: expected Rec, got Quiet`). On erlang each streamed boundary resolves in its own
> process, and emilia's stylesheet is per process, so a `chunk(id)` called by the render's process
> never sees what the boundary registered.
> **Options.** (a) `RenderPlugin(name, head, chunk, close, payload)` as a record of functions,
> `payload` answering `Array<#(key, json)>` (`[]` for "nothing", one pair otherwise) instead of
> `?#(…)`, and `chunk(id)` called in the boundary's own process right after it rendered —
> implemented; (b) the `behavior` shape once heterogeneous behavior arrays type.
> **Recommendation.** (a). The four moments and their order are the README's; only where `chunk`
> executes moves, and the fill still carries its CSS first.
> **Blocks.** Nothing.

### 30-c · `render` / `renderStream` / `App` live in `streaming.bp`; `compose` takes the page as a thunk

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Steps 4 and 8
> **Measured.** `resolve` needs `render.bp`'s walker and the entries need `resolve` — the same file
> pair importing each other. A layout must run before the page for "a layout's redirect means the
> page is never called", so `compose` cannot take a rendered `page: Element`.
> **Options.** (a) the walker, `compose`, the payload and the document in `render.bp`; `Chunk` /
> `resolve` / `fillHtml`, `Response`, `PageInput`, `App`, `render` / `renderStream` in
> `streaming.bp`; `compose(chain, route, page: fn() -> @Component<…>)` running layouts first over a
> placeholder child — implemented; (b) one larger module.
> **Recommendation.** (a). The flat `from "jhonstart"` surface is unchanged. `PageInput` also gains
> `metadata: Array<Metadata>` / `viewports: Array<Viewport>` (the segments' resolved exports,
> root-first) so the render merges front 32's head itself.
> **Blocks.** Nothing.

### 30-d · `Suspense` registers its boundary with the render

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 1
> **Measured.** An `Element` has no field that can carry the thunk, so the render cannot find a
> hand-written boundary in the tree it composed.
> **Options.** (a) `Suspense(b)` pushes `b` into the per-render state (`render.mjs` /
> `jhonstart_render`) as it writes the hole — implemented; (b) a page returns its boundaries beside
> its tree.
> **Recommendation.** (a). The Step 1 box states the one host cell and cites this entry.
> **Blocks.** Nothing.

### 30-e · The segment record is `UiSegment`

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 4
> **Measured.** The bundled `routing` also exports `Segment` (its `segment` module); a consumer's
> `import {Segment} from "jhonstart"` is then refused as ambiguous.
> **Options.** (a) `UiSegment`, with `segment(pattern)` / `with*` / `segmentFor` — implemented;
> (b) keep `Segment` and require consumers to name the module.
> **Recommendation.** (a).
> **Blocks.** Nothing.

### 29-a · The island starter table is a registry global filled through two functions, split by route

> **Raised by:** onze front 68's "What the other libraries owe" (68-c: "jhonstart owes a registry
> entry (or a `registerStarter`)"; the entry imports every client component, so the bundle does not
> split by route)
> **Measured.** `hydrate()` read `globalThis.__jhIslandStarters`, a name onze's generated entry wrote
> by hand through a host cell of its own; the payload's `r` carries the matched pattern and the
> manifest's `R` record maps a pattern to its chunk, and nothing in jhonstart could start a route's
> islands from that route's chunk.
> **Options.** (a) the table is the registry's fourth global (`globals.starters`, `__bp3`), filled
> by `registerStarter(name, start)` and `registerRouteStarters(pattern, load)`; `hydrate()` calls the
> loader of the payload's `r` once and runs again when it resolves; a second starter for one
> component, or a second loader for one pattern, fails naming it — implemented; (b) the registry
> entry only, the entry keeping its own host cell over `globals.starters`; (c) per-component lazy
> starters instead of per-route loaders.
> **Recommendation.** (a): the entry names no global and declares no cell, the split follows the
> manifest's own unit (the route), and the refusals keep one starter per name. A client navigation
> that reaches a route whose loader has not run starts its islands on the next `hydrate()` call.
> **Blocks.** Nothing; onze front 68 adopts it (its "no hand-written `__` name" box).

### 30-f · `app(…, lang:)`: one language per app, `"en"` by default, a checked tag

> **Raised by:** onze front 50's `--lang` ("the `lang` attribute, written once on the document
> element"), which a root layout cannot reach: the render writes `<html>` itself
> **Measured.** `documentStart` wrote the literal `<html lang="pt-BR">`; rakun front 64's
> `htmlLang()` (per request, from the resolved locale) is not landed.
> **Options.** (a) `app(plugins, allowedRedirects = [], lang = "en")` — `App.lang`, written into
> every document, refused by `app` unless letters, digits and `-` starting with a letter —
> implemented; (b) a `PageInput.lang`, per request, for front 64's `htmlLang()`; (c) no default.
> **Recommendation.** (a) now — onze's CLI default is `en` and the attribute is written once per app;
> (b) is additive when front 64 lands (a per-request value beside the app's default).
> **Blocks.** Nothing.

### 30-g · The browser half is asserted in a commonJS-only member over a minimal document

> **Raised by:** `04-jhonstart/30-jhonstart-streaming` Step 7 / Step 12 (the fill function, the
> payload reader and the signal function "on the DOM")
> **Measured.** `render.mjs`'s `registerFill` / `registerSignal` / `payloadText` read `document`,
> `history` and `location`; `botopink test` runs on node and on the BEAM, neither has a DOM, and the
> core member runs every suite on both rows (a node-only fake would red or vacuously pass the erlang
> row); no browser is in reach before onze front 53.
> **Options.** (a) a member `modules/jhonstart-dom-test` with `targets ["commonJS"]`: `fake_dom.mjs`
> parses the render's markup into a minimal document (the selectors, `template` content,
> `replaceChildren` and serializer those functions use; `history` / `location` / `dispatchEvent`
> recorded) and `dom_test.bp` calls the registered functions by their registry names —
> implemented; (b) leave the boxes to front 53's browser-in-the-loop; (c) a real DOM library as a
> dependency.
> **Recommendation.** (a): the three boxes are asserted today against the markup the render's own
> writers produce, with no dependency; front 53 still proves them in a browser.
> **Blocks.** Nothing.

### 31-b · The error digest: one scheme, and the render's way to the logger

> **Raised by:** `04-jhonstart/31-jhonstart-error-boundaries` Definition of done ("correlates with
> front 17's log line")
> **Measured.** jhonstart's `digestOf(message)` is `hash.contentHash(message)` — 8 hex, the message
> only. rakun front 17's `errorDigest(module, errorClass, message, topFrames)` is the first 16 hex of
> `hash.strongHash` over `module|errorClass|message|topFrames` (`contentHash` cannot give 16 hex),
> and `logErrorWithDigest` returns it "for the renderer to put in the payload". jhonstart's render
> never calls a logger (jhonstart and rakun never import each other, decision 113), so today no log
> line carries the digest a fallback shows. Both READMEs claim the scheme.
> **Options.** (a) jhonstart takes the digest from outside: `app(…)` (or `RenderHooks`) gains an
> `onError: fn(message: string) -> string` that onze sets to `logErrorWithDigest(log, …)`, the
> default staying `contentHash`; (b) jhonstart adopts front 17's scheme (a `strongHash` of what it
> has — the message alone — which still differs from the logger's four-part input); (c) front 17
> adopts `contentHash(message)`, dropping the module, class and frames from the fault identity.
> **Recommendation.** (a): one scheme (front 17's), one call site that both logs and answers the
> digest, and the render still names no rakun type; onze wires it like `allowedRedirects`.
> **Blocks.** front 31's "correlates with front 17's log line" box.

### 26-b · The query is reachable only through a marking hook; the payload's `d` is the mark

> **Raised by:** `status.md`'s `03-rakun` front 22 / `04-jhonstart` dynamic-marking row
> **Measured.** `PageContext.query` was a public field, so a page could read the query without
> marking the render dynamic; botopink has no private field. jhonstart's payload wrote `d` as a
> constant `true`. On erlang each boundary renders in its own process, whose process dictionary a
> flag set there does not reach.
> **Options.** (a) Drop `query` from `PageContext`; `searchParams()` and `request()` set a flag in the
> router's host store; `renderWith` clears it; `Resolved.dynamic` carries a boundary's flag back;
> `d` is the flag. (b) Keep the field and document a direct read as undefined for caching. (c) Keep
> `d` constant `true`.
> **Recommendation.** (a) — implemented (`streaming_test.bp` "dynamic: …"). `request()` marks on any
> read, headers and cookies included, as Next's dynamic APIs do.

## Front 00 · 04-js / 05-wasm — choices made in implementation, to confirm

Decided by the implementation of 04-js and 05-wasm; the maintainer confirms or reverses each.

### 0405-b · The empty value `?.` answers on commonJS still prints `undefined`

> **Raised by:** `04-js` / `05-wasm`, decision 47
> **Measured.** wasm prints every empty `?T` as `null` now (`$__print_null`), and commonJS's
> `Array.at` answers `null`. Two commonJS shapes still produce JS's other none: `choose(false)?.kind`
> (native `?.`) and an `if` with no `else` used as a value (`val r = if (n > 0) { "positive"; };`),
> and both print `undefined` — `snapshots/codegen/*/commonJS/{optional_fn_return_null_path,if_simple_conditional_in_fn_body}`,
> where wasm now prints `null`.
> **Options.** (a) `__bp_show` prints `undefined` as `null` — one branch in the §7 printer, which is
> written into every module that prints, so the prelude text of every such commonJS snapshot moves
> (163 per tree); (b) lower `?.` and the else-less `if` to produce `null`, which moves every `?.` site.
> **Recommendation.** (a), as its own commit: the printer is where the spelling is decided, and it
> leaves `== null` (already loose on this backend) untouched. Implemented:
> 196 commonJS snapshots per tree gained the one prelude line, and the two RUN LOGs above read `null`.
> **Blocks.** Nothing now — commonJS and wasm both print absence as `null`; erlang and beam are C-18's.

## Fronts 00 · 02-erlang / 03-beam — choices made in implementation, to confirm

Decided by the implementation of 02-erlang and 03-beam; the maintainer confirms or reverses each.

## Track D (`05-emilia`) — choices made in implementation, to confirm

Each was implemented with the recommended option; a different answer is a
local change in the named front.

### 05emilia-a. The filter reader is an inline chain, not `var(--tw-filter)` (front 42)

> **Raised by:** `42-emilia-filters` step 4
> **Measured.** The spec's reader `filter:var(--tw-filter)` needs `--tw-filter` defined somewhere.
> `extendTheme` panics on a name in none of `Ns`'s nineteen prefixes, and `--tw-` is in none
> (front 45 met the same wall). Even as a `:root` rule it would not compose: a custom property's
> `var()`s are substituted on the element that declares it, so `:root`'s `--tw-filter` would read
> `:root`'s (unset) families and every element would inherit that empty result. Upstream v4
> (`utilities.ts`, `cssFilterValue`) writes the chain into every utility:
> `filter: var(--tw-blur, ) var(--tw-brightness, ) … var(--tw-drop-shadow, )`.
> **Options.** (a) Inline upstream's chain, spelled once by `filterChain()` / `backdropFilterChain()`.
> (b) Add a `Tw` namespace to `Ns` so `--tw-filter` is a theme entry — it still would not compose.
> **Recommendation.** (a) — implemented; the step-4 box is marked superseded.

### 05emilia-b. The backdrop section is `BackdropFilter`, not `Backdrop` (front 42)

> **Raised by:** `42-emilia-filters` step 3
> **Measured.** `Backdrop(inner: Token[])` is front 34's `::backdrop` modifier, a top-level payload
> variant; a section head of the same name is the collision emilia's `AGENTS.md` records as silently
> breaking the variant's payload projection.
> **Options.** (a) `BackdropFilter` (upstream's property name). (b) Rename front 34's modifier.
> **Recommendation.** (a) — implemented; `BackdropRaw` keeps the spec's name.

### 05emilia-c. `drop-shadow-none` follows upstream (front 42)

> **Raised by:** `42-emilia-filters` step 2
> **Measured.** `TAILWIND_CSS_DOCS.md § 13.1` prints `filter: drop-shadow(none)`, which is not valid
> CSS (`drop-shadow()` takes a shadow). Upstream's `staticUtility('drop-shadow-none')` writes
> `--tw-drop-shadow: ` and the reader.
> **Options.** (a) Upstream's form. (b) The reference's string.
> **Recommendation.** (a) — implemented, the reference form asserted absent. `blur-none` keeps the
> reference's `filter:none`, which is valid CSS.

### 05emilia-d. The snap strictness default is a fallback, not a theme entry (front 46)

> **Raised by:** `46-emilia-interactivity` step 6
> **Measured.** The step asks front 54's theme to carry `--tw-scroll-snap-strictness`; `extendTheme`
> refuses any `--tw-` name (05emilia-a). Upstream registers the variable with `@property` and the
> initial value `proximity`.
> **Options.** (a) `scroll-snap-type:x var(--tw-scroll-snap-strictness, proximity)` — front 39's
> `cssVarOr`. (b) A `Tw` namespace in `Ns`.
> **Recommendation.** (a) — implemented: a lone `Snap.Type.X` snaps by proximity,
> a `Snap.Strictness` token in the same class overrides it.

### 05emilia-e. `fullTheme()` rides on `fullOptions()`, not `defaultOptions()` (front 56, decision 80)

> **Raised by:** `56-emilia-cascade-and-output`, decision 80
> **Measured.** Decision 80 says `defaultOptions()` carries `fullTheme()`. `defaultOptions()` is in
> `output.bp`; `fullTheme()` composes entries functions that live in `emilia.bp`, and `emilia.bp`
> imports `output.bp` — the reverse import is a module cycle.
> **Options.** (a) `fullOptions()` in `emilia.bp` = `withTheme(defaultOptions(), fullTheme())`, and
> `flush()` renders with it; `defaultOptions()` stays the palette-free baseline. (b) Move every
> front's entries function into `theme.bp` — five fronts' data in front 54's file.
> **Recommendation.** (a) — implemented; a test fails on any undefined `var(--…)`
> in a flushed document, with `defaultTheme()` as the control that must leave some undefined.

### 05emilia-f. `--inset-shadow-*` entries drop upstream's leading `inset` (front 41)

> **Raised by:** `56-emilia-cascade-and-output` (`fullTheme`)
> **Measured.** Front 41 emits the reference's `box-shadow:inset var(--inset-shadow-xs)`; upstream's
> `theme.css` values already start with `inset`, so the pair would render `inset inset …` — not CSS.
> **Options.** (a) Entries without the keyword (`effectEntries()`). (b) Upstream's values, and front
> 41 emits `box-shadow:var(--inset-shadow-*)` — moves a landed front's pinned output.
> **Recommendation.** (a) — implemented; the rendered shadow equals upstream's.

### 05emilia-g. `space-*` / `divide-*` against upstream (fronts 35, 40)

> **Raised by:** the track-D audit, front 35 step 4
> **Measured.** Upstream `utilities.ts` writes `space-x-*` as `:where(& > :not(:last-child))` with
> `--tw-space-x-reverse:0` and both logical margins read through it; emilia writes
> `& > :not(:last-child)` (higher specificity) and the end margin only, so `Space.XReverse` sets a
> variable nothing reads. `divide-*` calls the same `siblingSelector()`.
> **Options.** (a) Align both fronts to upstream in one change (selector, reverse-aware margins).
> (b) Keep emilia's form and document it.
> **Recommendation.** (a) — implemented: both fronts'
> pinned output and the two examples that assert a spaced or divided list moved together.

### 05emilia-h. Sibling modules never import `from "emilia"`; `named()` lives in `emilia.bp` (fronts 55, 57, 58, 59)

> **Raised by:** `59-emilia-custom-utilities-and-variants` step 5
> **Measured.** A sibling module importing `from "emilia"` (the default module `emilia.bp`) passes
> `botopink test` in `modules/emilia/` and fails in every consumer: `unbound variable 'flushWith'`
> in `emilia/preflight.bp` when `examples/emilia-cascade` compiles emilia as a dependency. Front 59's
> step 5 wants `emilia.bp` untouched, but `named()` needs the host cell, and a host cell cannot be
> imported across modules either.
> **Options.** (a) Siblings import `tokens`/`theme`/`output`/each other only; `named()` and the
> read-only `lookupRule` cell live in `emilia.bp`, and each front's rendering tests sit under its
> banner there. (b) Fix the resolver first (a compiler change — not this track's).
> **Recommendation.** (a) — implemented; the resolver defect is a compiler finding.

### 05emilia-i. The `--tw-*` transform variables are `@property` blocks, with upstream's `properties` layer (front 45, fronts 54/56)

> **Raised by:** `status.md`'s front 45 / fronts 54–56 rows (translate and skew did not compose;
> "making it compose needs `@property` emission, a new output kind and front 56's")
> **Measured.** Tailwind 4.3.2, compiled: `translate-x-4` is `--tw-translate-x: …; translate:
> var(--tw-translate-x) var(--tw-translate-y)` with `@property --tw-translate-{x,y,z}` (initial `0`)
> and a `@layer properties` `@supports` fallback; `skew-x-3` is `--tw-skew-x: skewX(3deg); transform:
> var(--tw-rotate-x,) … var(--tw-skew-y,)` with five `@property` (no initial value). emilia's `Block`
> is already `header` + brace-balanced `body`, deduplicated by header at flush — the shape a
> `@property` rule has.
> **Options.** (a) each translate / skew sheet carries its `@property` registrations as `Block`s,
> and `renderDocument` writes `@layer properties;` first and the `@supports` fallback last when a
> `@property` block is present — implemented; (b) a new output kind in front 56's model; (c) keep the
> inline `var(--tw-translate-y, 0)` fallback and non-composing skews.
> **Recommendation.** (a): upstream's output byte for byte in shape, no new model kind, and nothing
> changes for a document without a transform (no `properties` layer is declared).
> **Blocks.** Nothing. `scale-*` still writes `scale:` directly where upstream writes `--tw-scale-*`
> and percentages — `status.md` records it.

### 05emilia-j. A selector-list modifier is a list of one-`&` variants (front 34, front 56)

> **Raised by:** `reference-coverage.md`'s `marker:` / `selection:` rows
> **Measured.** Tailwind 4.3.2 compiles `marker:flex` to four rules — `& *::marker`, `&::marker`,
> `& *::-webkit-details-marker`, `&::-webkit-details-marker` — and `selection:` to two. "The element
> and its descendants" cannot be one selector with one `&` (a pseudo-element cannot sit inside
> `:is()`), and front 56's `checkVariantSelector` refuses two `&` with no opt-out.
> **Options.** (a) A LIST of one-`&` variants (`markerVariants()`, `selectionVariants()`), the inner
> sheet wrapped once per variant by `nestVariants` — several rules, upstream's order. (b) Keep the
> reference's `& ::marker` (descendants only). (c) Let `Variant` carry a selector list.
> **Recommendation.** (a) — implemented: front 56's one-`&` rule is untouched and the output is
> upstream's; front 34's "one `Variant` fn per name" becomes "one fn per name, a list for these two".

### 05emilia-k. The negative half step is `spacingNegHalf(n)`; `spacingHalf` refuses a negative `n` (front 54)

> **Raised by:** `status.md`'s front 54 row (`spacingHalf` cannot spell `-0.5`)
> **Measured.** `spacingHalf(n: i32)` takes the whole part; `-0` is `0`, so `-mt-0.5` had no token.
> Upstream 4.3.2: `-mt-0.5` is `margin-top: calc(var(--spacing) * -0.5)`.
> **Options.** (a) `spacingNegHalf(n)` — the sign in the name, `n` the magnitude's whole part —
> and `spacingHalf` aborting on a negative `n`, so every rung has one spelling. (b) `spacingHalf(n,
> negative: bool)`. (c) A string-typed step (`"0.5"`, `"-0.5"`).
> **Recommendation.** (a) — implemented; every `*.Neg.Half` gains `0`.

### 05emilia-l. Confirming a column moves its whole family to upstream's form (fronts 35–45)

> **Raised by:** `status.md`'s spec-writing-rule row and fronts 36/47's two flagged spellings
> **Measured.** Tailwind 4.3.2, compiled: a fraction is `calc(1 / 2 * 100%)` on `w-*`, `inset-*`,
> `basis-*` and `translate-*`; `opacity-60` is `opacity: 60%`; `-rotate-12` is
> `rotate: calc(12deg * -1)`; `shadow-[…]` writes `--tw-shadow` and the five-channel reader;
> `transition-[…]` writes the property with the timing and duration defaults.
> **Options.** (a) Move each family whole to upstream's form, one helper per shape (`fraction(n, d)`),
> so the library keeps one convention. (b) Change only the unconfirmed rows. (c) Keep the reference's
> spellings and document the divergence.
> **Recommendation.** (a) — implemented. `rawTransitionProperty` takes the presets' defaults
> (`var(--ease-out)`, `150ms`) rather than upstream's `var(--tw-ease, …)`, because the presets beside it
> have not moved; the presets' own shape, `backdrop-opacity`'s `opacity(0.5)` (upstream
> `opacity(50%)`), `border-spacing` (upstream's `--tw-border-spacing-*`) and `-webkit-backdrop-filter`
> are the same kind of divergence in families no open row names — `status.md` records them.

## `libs-external-methods` (host functions as methods of their owner) — choices made in implementation, to confirm

Decided by the implementation of host methods inside a `type` body (every backend, and std's
owner-bound host functions moved into their types); the maintainer confirms or reverses each.

### lem-a · A host method is a real method whose body is the binding, never inlined at the call site

> **Measured.** A `declare fn` with `#[@External.*]` inside a `type` body parsed and
> checked, and no backend emitted it (erlang `undef`, commonJS `… is not a function`, beam panicked
> in `lowerIdentAccess`, wasm wrote an invalid module).
> **Options.** (a) every backend emits the method as a function of the type (class member, exported
> function of the type's module) whose body is the binding over its own parameters — the wrapper a
> `pub` module-level `declare fn` already gets — so `sock.recv(n)` stays an ordinary method call and
> a method on an imported type is answered by its owner (decision 21) with no new call-site path —
> **implemented** (`codegen/hostMethods.zig`); (b) additionally render the binding inline at a call
> site in the owning module, as a module-level template is.
> **Recommendation.** (a): one lowering, one frame more per call. (b) is an optimisation with a
> second path to keep in agreement on four backends.

### lem-b · `inline = true` on a method's `External.Erlang` / `External.Beam` changes nothing

> **Measured.** `inline` opts a PRIMITIVE behavior's method out of the dispatch table so a
> hand-coded shape keeps emitting; a user type has neither the table nor a hand-coded shape.
> **Options.** (a) accept it (the checker's `refuseUnreadInline` rules still apply) and lower the
> method the same way — **implemented**, pinned by `run/external_method_local`'s `times`; (b) refuse
> it on a type-body method as a switch nothing reads (decision 67's reading of front 20 F9).
> **Recommendation.** (b) is the restrictive reading and is `01-checker`'s to add; (a) until then.

### lem-c · A method with no binding is refused where it is CALLED; wasm refuses every host method

> **Measured.** A module-level host function is refused at its call site (06 C13); a type is
> declared once and may be compiled for a backend its method has no binding for.
> **Options.** (a) the method is not emitted and a call through a receiver inference typed
> (`InstanceLowering.type_`) is refused with `MissingExternal` naming `Type.method` —
> **implemented** (`hostMethods.missingAt`, `CrossModule.host_methods`); (b) refuse the
> declaration itself on that backend. On wasm (a) refuses even an `External.Wasm` binding, where a
> module-level one lowers to `unreachable`; the index is keyed by the TYPE NAME, so two modules
> declaring one `Type.method` keep the first walked.
> **Recommendation.** (a); the wasm asymmetry resolves the day wasm has a host (both then refuse
> or both lower). An untyped receiver (no `.type_` lowering) is not refused and fails at run time as
> any unknown method does.

### lem-d · The names the collapse chose

> **Measured.** `io.net` had one free function per type and operation; `regex` had
> `runCompiled(r, input)` because `matches(pattern, input)` held the name.
> **Options.** (a) one name per operation on every type — `Listener.port/accept/close`,
> `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`,
> `Regex.matches` — **implemented**; (b) keep the old names as methods (`l.listenerPort()`,
> `r.runCompiled(s)`).
> **Recommendation.** (a): the prefixes named the owner, which the receiver now does. Constructors
> (`listen`, `connect`, `tlsListen`, `tlsConnect`, `regex.compile`) stay module functions.

### lem-e · What stayed free although it takes a type

> **Measured.** `io.net`'s private `tlsEchoOnce(listener, length)` (a test instrument); `validation`'s
> private `rkvPush(v: Violation)`, `putMessageSource(source)` and `messageSourceOr(fallback)` (a
> process-global store, not an operation on the value); every other std host function takes
> primitives, `any` host terms or builtin types (`@Task`), and `routing` / `actions` declare none.
> **Options.** (a) keep them free — **implemented**: a method is exported from its type's module on
> erlang and beam, so a private helper would join the type's public surface; (b) move them too.
> **Recommendation.** (a).

### lem-f · commonJS adopts a host-built record into its class

> **Measured.** A host answer declared as a record stayed a plain object on commonJS — fields read,
> methods absent (`regex.compile(p).map({ r -> r.matches(s) })`: `r.matches is not a function`),
> printed as `%O`. erlang has adopted maps since decision 21 (`adoptHostResult`).
> **Options.** (a) `__bp_adopt(v, C, path)` gives the answer the class's prototype — directly,
> through `?T`, an array, an `@Result`'s ok side — at the owner's call site, in the exported
> template wrapper and in a host method's body — **implemented** (pinned by
> `run/external_method_on_host_record`); `@Task` is not looked through, and a `(module, symbol)`
> alias another module imports bypasses it; (b) require templates to build the class
> (`new Regex(…)`).
> **Recommendation.** (a): (b) makes a template name an emitted class, and `docs.md` already
> promised the adoption on every backend. beam still adopts no host map (`external_host_record`'s
> `.targets`) — a `03-beam` row.

## Track E (onze) — choices made in implementation, to confirm

Decided by the implementation of the `06-onze` fronts so they could land; the maintainer confirms or
reverses each.

### 49-a · The core's suites render through the core's own `describe*`; `onze-test` wraps them

> **Raised by:** `06-onze/49-onze-stand-up` test plan, 2026-09-26
> **Measured.** `test-snap.md` writes the core's suites as `import {assertConfig, …} from
> "onze-test"`, and front 49's test plan says the core's `test/` imports only std. `onze-test`
> depends on `onze`, and a manifest has no dev-dependencies, so the core cannot import it.
> **Options.** (a) the core owns `describeConfig` / `describeAliases` / `describeAppFiles` /
> `describePublicEnv` (the text `onze info` prints too); the core's suites call std's
> `snapshots.assertAs` over them, and `onze-test`'s `assert<Subject>` helpers are thin wrappers
> with their own suite — implemented; (b) move the core's snapshot suites into `onze-test/test/`.
> **Recommendation.** (a): one rendering, the snapshot paths `test-snap.md` names, and the
> std-only rule holds for `config_test` / `types_test`. The snapshot slugs are std's
> (`snapshots.slugOf`: `_` separators), not the `-` `test-snap.md` spells.
> **Blocks.** Nothing.

### 49-b · The boot's rakun half is data and adapters until rakun 23 / 04 / 82 land

> **Raised by:** `06-onze/49-onze-stand-up` step 4, 2026-09-26
> **Measured.** At rakun `2a01ea5` there is no `ChunkWriter`, `PageRenderer`, `page(pattern,
> render)` or `registerStaticRoot`; `modules/rakun` is `["commonJS"]` and `rakun-web` `["erlang"]`,
> so a both-target member cannot import them together.
> **Options.** (a) `integration.bp` imports jhonstart, `jhonstart-forms` and the bridge now and
> hands rakun `rakunEntries(config, i18nExclude)` (the five `rakun.*` keys as pairs) and
> `responseOver(setStatus, setHeader, write, close)`; `Onze.run` lands with rakun's pieces —
> implemented; (b) write `Onze.run` against rakun's commonJS core now and make the core
> commonJS-only.
> **Recommendation.** (a): the jhonstart half is exercised on both rows today (a render through
> the bridge, a 307 through the writer), and (b) would pin the core to the row rakun is leaving.
> The core's `integration_test.bp` imports jhonstart and emilia — the one suite of the core that
> is not std-only, because the boot is the seam it tests.
> **Blocks.** Step 4's `Onze.run` boxes; rakun owes front 23 step 1, 04 and 82.

### 49-c · `onze.json` refuses an unknown key; the config table has every field

> **Raised by:** `06-onze/49-onze-stand-up` step 2, 2026-09-26
> **Measured.** The README lists the fields but not what a key outside them does.
> **Options.** (a) an unknown key, a duplicate, a value of the wrong kind, a fractional or
> out-of-range port (`1..65535`) and a non-string `allowedRedirects` entry are each an `Error`
> naming the key — implemented; (b) ignore unknown keys.
> **Recommendation.** (a) (decision 67: a misspelt `"prot"` must not silently leave port 3000).
> `describeConfig` prints `actionsBodyLimit` and `allowedRedirects` rows beside the eight
> `test-snap.md` shows (decision 117 added the two fields after the map was written).
> **Blocks.** Nothing.

### 49-d · `chainFor` takes the ancestor patterns; onze imports nothing from `routing`

> **Raised by:** `06-onze/49-onze-stand-up` step 4, 2026-09-26
> **Measured.** jhonstart builds its client chain with `routing`'s `ancestorPatterns`; step 4 says
> the boot imports nothing from `routing`.
> **Options.** (a) `chainFor(patterns)` maps `segmentFor` over the patterns rakun's layout chain
> names for the matched route — implemented; (b) import `ancestorPatterns`.
> **Recommendation.** (a): rakun matched the route and knows its chain; onze does not derive it
> twice.
> **Blocks.** Nothing.

### 52-a · The font-metrics table is transcribed, and its generator is owed

> **Raised by:** `06-onze/52-onze-font` step 2, 2026-09-26
> **Measured.** Generating the table needs each family's font files (a network fetch) and a binary
> reader (`fontTools`); neither is available to this thread.
> **Options.** (a) commit five transcribed rows (Arial, Times New Roman, Inter, Roboto,
> Merriweather) with their provenance in the file header and the generator owed — implemented;
> (b) commit no table, so every Google family with `adjustFontFallback: true` is refused.
> **Recommendation.** (a), with the rows re-derived by the generator before a release; the
> formula tests pin the arithmetic independently of the rows.
> **Blocks.** Step 2's "the script that generated it" box.

### 53-a · The blog's sources sit under `src/`

> **Raised by:** `06-onze/53-onze-example-app` step 1, 2026-09-26
> **Measured.** A package whose `"src"` is `"."` cannot reach a nested module (finding F5 of front
> 53: `lib/mod.bp` + `lib/db.bp` under `"src": "."` answer `unbound variable`; the same tree under
> `"src": "src/"` imports as `from "lib.db"`).
> **Options.** (a) `src/app/`, `src/components/`, `src/lib/` with `onze.json`'s `appDir:
> "src/app"` — Next's own `src/` layout — implemented; (b) keep the root layout and wait for the
> compiler.
> **Recommendation.** (a): the acceptance script's rows read `src/<path>`; nothing else changes.
> **Blocks.** Nothing.

### 68-a · A manifest field escapes four characters, not the whole value

> **Raised by:** `06-onze/68-onze-client-bundle` step 5, 2026-09-26
> **Measured.** std's `encoding.percentEncode` escapes `/`, `:` and `[`, so every URL and route
> pattern in the manifest became unreadable (`%2F_onze%2Fstatic…`), while the README's own
> example keeps URLs raw.
> **Options.** (a) escape `%`, `|`, LF and CR only (`%25`, `%7C`, `%0A`, `%0D`) and read back with
> `percentDecode` — implemented; (b) `percentEncode` every field.
> **Recommendation.** (a): the rule the format needs is "no `|` and no newline inside a field",
> and (a) is exactly that, round-trip asserted on both targets.
> **Blocks.** Nothing.

### 68-b · The emilia rules without `styleRule`: token text in the `styleMap`, an ASCII-only refusal

> **Raised by:** `06-onze/68-onze-client-bundle` step 3, 2026-09-26
> **Measured.** emilia front 56's `styleRule(tokens, th)` is not in `repository/emilia` at
> `4cac151`; a token list read from source text cannot be evaluated without it.
> **Options.** (a) the `styleMap` records the literal token text per call site, and the
> hash-parity rule is the static one — a non-ASCII token list is `emilia-hash-split` (std's two
> `contentHash` cells differ only above U+FFFF, and contract 4 clause 3 makes rule text ASCII) —
> implemented; (b) wait for front 56.
> **Recommendation.** (a) now; when `styleRule` lands the build generates a program over the
> recorded token texts and records the class and body, and the runtime `s` check follows.
> **Blocks.** Step 3's `styleRule` half, step 6's `s` box — onze's to adopt: `styleRule` is in
> emilia's `emilia.bp`.

### 68-c · Island starters decode `#[clientProps]` from source into `__jhIslandStarters`

> **Raised by:** `06-onze/68-onze-client-bundle` step 6, 2026-09-26
> **Measured.** jhonstart's `hydrate()` starts `globalThis.__jhIslandStarters[component](el,
> props)`; `@Decl` has no parameters, so no decorator can build a props decoder.
> **Options.** (a) the generator reads `#[client] pub fn Name(props: T)` and `T`'s fields from the
> source, generates `startName(raw, commit)` decoding the four whitelisted types, and registers it
> through a generated host cell writing `__jhIslandStarters` — implemented; (b) jhonstart grows a
> starter API.
> **Recommendation.** (a), with jhonstart asked for a registry-owned name for the table so the
> entry writes no `__` name by hand. The document/payload check is generated into the entry as
> the twin of the bundler's `islandMismatches` (asserted equal), because the entry imports nothing
> of onze.
> **Blocks.** The "no hand-written `__` name" box — onze's to adopt: jhonstart's `registerStarter` /
> `registerRouteStarters` over `globals.starters` (29-a) replace the generated cell.

### 69-a · The static roots are onze's `AssetRoot` until rakun-web front 82 lands `StaticRoot`

> **Raised by:** `06-onze/69-onze-styling-pipeline` step 3, 2026-09-26
> **Measured.** `grep -rn "StaticRoot\|registerStaticRoot" repository/rakun` is empty at `2a01ea5`.
> **Options.** (a) `AssetRoot(pattern, directory, immutable, cacheSeconds)` in `onze-assets`, the
> README's four fields, replaced by an import of front 82's record when it exists — implemented;
> (b) wait.
> **Recommendation.** (a); the swap is one import and one type name. A CSS module's generated
> accessors are `pub fn` rather than `pub val` for the same reason as 49's constants (finding F1).
> **Blocks.** Step 3's registration box; rakun owes front 82.

### ck-host · A function around a host call with no binding for the target

> **Raised by:** the merge of `checker-rows` and `beam-std-rows`, 2026-09-26
> **Measured.** `checker-rows` wrote the strict rule into `docs.md` § host bindings and pinned it
> with `run/external_wrapper_keeps_refusal`: `fn linkStatus() { return otpRelease(); }`, where
> `otpRelease` names only `@External.Erlang`, is refused on commonJS and wasm even though nothing
> calls `linkStatus`. `beam-std-rows` made wasm drop such a function (`collectHostBound`) and refuse
> only a call to it — which is what lets `testing.asserts` build on wasm (`deepEquals` reaches
> `canonical`, which has no wasm binding). Together, wasm accepts the cell; commonJS still refuses it.
> **Options.** (a) the strict rule everywhere: `asserts` does not build on wasm until `canonical` has
> a wasm lowering (restructure `deepEquals` without it); (b) the lazy rule everywhere: a function is
> refused only when called, and `docs.md` says so; (c) strict for the root package, lazy for a
> dependency's functions (a library ships functions no consumer calls).
> **Recommendation.** (a) — the most restrictive (decision 67), and the one `docs.md` states; the
> cost is one std restructuring.
> **Blocks.** The wasm line of `run/external_wrapper_keeps_refusal`.
