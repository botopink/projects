# Decisions the maintainer owes

The open questions of the current milestone, 1.0.12-beta; one file above every milestone since 2026-10-18.

**36 questions and 8 contradictions are open, and 100 implementation choices await confirmation** (counted from the
entries below: a lettered question, `nat-d` and `nat-f` being headings of their cases; `ctr-*` and `119-a` the
contradictions; a row of a choices table, or a `#####` entry beside it).

- An answer goes into [`decisions-taken-steps.md`](decisions-taken-steps.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

- **Blocking now** — maximum priority: the questions that hold machine 2's work back today, most blocking first; an index of entries kept in their sections.
- **Blocking now — machine 1 and front 165** — the same for machine 1's steps and front 165.
- **Machine 1** — maximum priority: the questions front 144's machine 1 waits on, by step.
- **Machine 2** — maximum priority: the questions front 144's machine 2 waits on, most urgent first. New development is centred on front 164 wasm-gc (s1 → s4, wasmtime-a, wasmgc-a).
- **Front 165** — rakun-workspace: one `rakun` repository, 17 plug-and-play packages (mono-a).
- **Part 1** — what blocks front 144 (`repository/botopink-lang`, decision 433: the open steps of the old tracks
  `00-gate`, `01-compiler`, `02-std-and-packaging`, `03-bundled-libs`), by old track, then those
  tracks' implementation choices awaiting confirmation.
- **Part 2** — the rest (tracks 04–10, 20, ownership, contradictions that block no 00–03 step).
- **Part 3** — the implementation choices of tracks 04–09.

The Portuguese page (`decisoes-pendentes.md`) is this page's direct translation: this English text holds the meaning
(meta `AGENTS.md` § Conventions). Answered ids leave this file; `decisions-taken-steps.md` holds the answers and the next free
number, which is **755**.

## Blocking now — maximum priority (machine 2, 2026-10-15)

The questions that hold machine 2's work back today, most blocking first. Each is explained here in a few lines — the
problem, an example, the options, the recommendation and why — and its full entry (Measured, every option) stays in
§ Machine 2. Tick one option per question (`[x]`); the coordinator turns a ticked answer into a decision, and the question leaves this list.

No question holds machine 2's work today; the open ones hold one row each, or nothing built (§ Machine 2).

## Blocking now — machine 1 and front 165 (2026-10-15)

The questions that hold machine 1's steps and front 165 back today, most blocking first. Each entry stays in its section; this table indexes them and leaves when they are answered. With § Blocking now — machine 2 above, these are the questions to answer first.

| # | Question | What it decides | Blocks | Recommendation |
|---|---|---|---|---|
| 1 | **50-b** — what the dev server (`onze dev`, now rakun-ssr) does on a change (§ Part 2, 07-onze) | whether the dev server restarts from a fresh build on every change or hot-loads the changed modules | 50 step 2; 53 step 6 | (a) `build` then `start` on every change |

Open and blocking nothing (front 165): **165-b** (three package names), **548-a** (every library links its code),
**548-b** (the code names that keep a former library's name).

---

## Machine 1 — maximum priority (front 144, `machine-1/144-checker/`)

The questions machine 1's steps wait on (lane A, B-19, B-22, B-23, B-24, B-25, B-27, B-55, B-60, the module-model
group), answered before every other part of this page; in the order of the steps they block.

#### B-02-c · `"std:…"` written as a `.JavaScript` / `.Erlang` `template`: host code, or refused like the other prefixes? (decisions 305, 481; 144 B-02)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): refused on every target, naming the labelled form** — `conformance/docs.md` § Host bindings already says the four prefixed strings are refused at the argument on every target; a string that reads as a cell and runs as host code is the ambiguity 305 removed. Since 575 (6), 610 and 621 the cell is a value of `Implementation` and `std` is a labelled field of `.Wasm` alone (`.Wasm(std: "hash.contentHash")`); `.JavaScript` and `.Erlang` have only `template` and `body`, so the question narrows to a `template` text that starts with `std:`. Changes: the `template` check refuses `"std:"` on `.JavaScript` and `.Erlang` too; a cell.
- **Measured.** The table checks (516, kept over the value by 575 (6)) refuse `"std:…"` only in a `.Wasm` template (before 606: `@External.Wasm`); in a `.JavaScript` / `.Erlang` template it is host code ("`std:` was only ever a wasm cell").
- **Options.**
  (a) Refused everywhere.
  ```bp
  #[compiler.external(.JavaScript("std:hash.contentHash"))]   // refused: a `std:` cell is `.Wasm(std: …)`'s
  ```
  (b) Host code off wasm, the text corrected.
  ```bp
  #[compiler.external(.JavaScript("std:hash.contentHash"))]   // JavaScript source `std:hash.contentHash`
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-02's `std:` row.

#### B-10-b · `compiler.variants(d)`: what does an entry carry, a section included? (decisions 268, 298; 144 B-10 G1)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): `Variant(name: string, fields: compiler.Field<unknown>[], annotations: DeclAnnotation[], section: ?string)`**, a record of `compiler.bp` beside the handle records (608) — a payload variant lists its fields as `compiler.fields(T)` does (576 (8), 630); a section is not an entry, its variants carry the section's name. One entry per constructible variant.
- **Measured.** `compiler.variants(d)` (before 576: `Decl.variants`) carries names only, sections listed among them.
- **Options.**
  (a) Typed entries, sections as a field.
  ```bp
  compiler.variants(decl)[0].fields[0].name   // "amount"
  ```
  (b) As today: names.
  ```bp
  compiler.variants(decl)[0]   // "Paid" — a name, sections among them
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10's row.

#### B-10-c · `clock.formatIso8601`: which text is the one answer? (decision 497; 144 B-10 G1)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): always milliseconds, `.sssZ`** — `2026-10-12T20:31:02.000Z` on every target; a fixed width sorts as text and parses back with one rule.
- **Measured.** commonJS answers `.sssZ` always (node's `toISOString`); erlang never writes milliseconds.
- **Options.**
  (a) Always `.sssZ`.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02.000Z
  ```
  (b) Milliseconds only when nonzero.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02Z, .123Z only when nonzero
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10's row.

#### B-10-e · How does a type alias of `Component<Styled>` implement a behavior? (144 B-10 G2)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(b): it does not — an alias is its target**: `Styleable` is implemented by `Styled`, and `Component<Styled>` (bare since 606 (1)) reaches it through `R`; an alias declares nothing (a second name, not a type). styled's marker is rewritten over `Styled`'s implementation. Re-read under 629: a `val` names a type wherever a type is named (629 (2)), but only a nominal type — declared, or built by `compiler.buildType(name, fields, implements)` — carries an `implement` clause; `buildTypeInline(fields)` takes none (629 (1)). 629 does not say whether a `val` naming the nominal `Component<Styled>` could carry one, so (a) stays a question and not a spelling.
- **Measured.** `pub val StyledView = Component<Styled>` cannot carry `implement`; no spelling exists.
- **Options.**
  (a) An alias with `implement`.
  ```bp
  pub val StyledView = Component<Styled> implement Styleable;
  ```
  (b) Only the target type implements.
  ```bp
  pub type Styled(…) implement Styleable { … }   // StyledView reaches it
  ```
- **Recommendation.** (b).
- **Blocks.** 144 B-10's row.

#### B-10-f · How does a decorator read whether a `Component<R>` return's `R` implements `Renderable`? (decisions 268, 280; 144 B-10 G3)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): through `compiler.typeInfo` of the declared return** — `compiler.typeInfo(compiler.returnType(decl)).typeArg(0).implements(Renderable)`; the handle stays a declaration's handle read through `compiler.*` (576 (3)) and type questions go through `compiler.typeInfo`, the one reflection of a type (606 (3)). Viable: `compiler.returnType(d)` as a type value (today a name) and `compiler.Info<T>.implements(B)`. Changes: two members; jhonstart's marker in `client.bp` goes.
- **Measured.** No reflection answers it: `compiler.returnType(d)` (before 576: `decl.returnType`) is the type's name as text, and no member asks whether a type implements a behavior. Since 626 (2) a decorator's handle may be typed by what the decorator requires (`syntax decl: fn() -> string`), checked at the annotation — a third route, (c).
- **Options.**
  (a) `compiler.typeInfo` of the return type.
  ```bp
  if (!compiler.typeInfo(compiler.returnType(decl)).typeArg(0).implements(Renderable)) compiler.fail("…", at: decl);
  ```
  (b) A `Compiler` read on the handle.
  ```bp
  if (!compiler.returnImplements(decl, Renderable)) compiler.fail("…", at: decl);
  ```
  (c) The handle's type says it (626 (2)); whether `Component<Element>` fits `Component<Renderable>` through `Element implement Renderable` is a generic rule 626 does not state.
  ```bp
  pub fn page(syntax decl: fn() -> Component<Renderable>) -> void { … }   // a return whose R is no Renderable refused at the annotation
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10 G3's `Renderable` row.

#### B-10-g · A template declared `-> View` whose built code is an `Element`: is the expansion a `View`? (decisions 275, 276; 144 B-10 G3)
- **Proposed (opus, 2026-10-12; awaiting the maintainer):** **(a): yes — the expansion is what the template declares** — `html` declared `-> View` (576 (4), 578 (2): a template returns an ordinary type, its reference tree attached by `compiler.custom(ast)`) answers a `View` (`Component<Element>`), and a built `Element` is checked against it as a component's body; jhonstart's `renderNode(html …)` and its `-> Element` components move to `View`. Viable: the built code's check against `View` accepts an `Element` as a component's answer. Changes: jhonstart's components (a consumer commit), a cell.
- **Measured.** With `-> View` (before 576: `-> @ExprCustom<View>`) every `html` expansion fails `expected Component, got Element`. 578 (2) makes the declared `T` the call's type, so the former option — the call keeping `Element` while the declaration says `View` — cannot be written and is gone; what is left is whether the built `Element` code is accepted against `View` as a component's answer, or refused, the template having to build the component itself.
- **Options.**
  (a) A `View`: the built `Element` accepted as a component's answer.
  ```bp
  fn Card() -> View { html @`<div/>` }   // the expansion is a View
  ```
  (b) Refused as today; `html` builds the component around its `Element` itself.
  ```bp
  fn Card() -> View { html @`<div/>` }   // expected Component, got Element — unless html answers the component
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-10 G3's `View` row.

#### B-17-h · math's `op:`-only host functions at build: given `std:` cells? (decisions 452, 481; 144 B-17)
- **Proposed (opus, 2026-10-13; awaiting the maintainer):** **(a): yes — one `std:` binding cell per function in std-wasm** (`floor`, `abs`, `trunc`, `sqrt`, `minF`, `maxF`), so the comptime runtime answers them and they fold (380); an opcode has no host form at build otherwise. Since 610 a third way exists beside `std:` and run-time-only: a botopink body, `.Wasm(body: f)`, which 594 (1) and 633 name a build form as `std:` is; a `Wasm` cell holds one of `op` / `std` / `body`, so (a) and (b) alike take the opcode off the wasm target.
- **Measured.** They are refused at build (452) and no longer treated as foldable; 633 confirms the rule — a wasm form (`std:` or `body:`) is callable at build, an `op:` alone is not.
- **Options.**
  (a) A `std:` cell each.
  ```bp
  #[compiler.external(.Erlang("…"), .JavaScript("…"), .Wasm(std: "math.sqrt"))] pub declare fn sqrt(x: f64) -> f64;
  val r = "${math.sqrt(16.0)}";   // computed at build by std-wasm's export
  ```
  (b) A botopink body each (610).
  ```bp
  fn sqrtBody(x: f64) -> f64 { … }
  #[compiler.external(.Erlang("…"), .JavaScript("…"), .Wasm(body: sqrtBody))] pub declare fn sqrt(x: f64) -> f64;
  val r = "${math.sqrt(16.0)}";   // computed at build by the body
  ```
  (c) Run time only.
  ```bp
  val r = "${math.sqrt(16.0)}";   // computed at run time
  ```
- **Recommendation.** (a).
- **Blocks.** 144 B-17's row.

#### B-27-e · On erlang, `not-found.bpp` and `not_found.bp` become the same module name (decisions 561, 109; 144 B-27)
- **Proposed (opus, 2026-10-15; awaiting the maintainer):** (a): the erlang module atom is quoted from the file's name as written, so the two never meet.
- **Context.** Decision 561 lets a file whose name is no identifier (`not-found.bpp`) be imported, and asks each backend to map a name without collision. On erlang a module's name goes through decision 109's cleanup, which replaces the characters an unquoted atom cannot hold.
- **Measured.** Decision 109's cleanup turns `not-found.bpp` into `…@not_found`, the same module as a sibling `not_found.bp`; the two would overwrite each other's `.beam`. No cell holds the pair today.
- **Options.**
  (a) ★ The module atom is quoted and keeps the file's name (`'pages@not-found'`).
  ```erlang
  'app@pages@not-found':render(...)   % not_found.bp stays app@pages@not_found
  ```
  (b) Decision 109's cleanup stays, and the pair is refused at the second file ("`not-found.bpp` and `not_found.bp` are one module on erlang").
  ```text
  error: src/pages/not_found.bp and src/pages/not-found.bpp are one module on erlang (app@pages@not_found) — rename one
  ```
  (c) Decision 109's cleanup stays and nothing is checked.
- **Recommendation.** (a): 561 asks for no collision, and a quoted atom is erlang's own form for such a name; (b) if a quoted module atom breaks a tool.
- **Blocks.** Nothing today; a package holding both files.

#### B-27-f · `Name<T>.f()` with a backtick type name (decision 561; 144 B-27)
- **Proposed (opus, 2026-10-15; awaiting the maintainer):** (a): the parser tells a type from what the name is, not from an uppercase first letter.
- **Context.** Explicit type arguments before a `.` (`Name<T>.f()`) are read as a type only when the name starts with an uppercase letter. A backtick type name (`` `my point` ``) has no such letter, so it cannot be written there; a call `Name<T>(…)` already works.
- **Measured.** `` `my box`<i32>.make() `` does not parse as a type with type arguments; `` `my box`<i32>(…) `` does.
- **Options.**
  (a) ★ Extended: a backtick name followed by `<…>.` is read as a type, like an uppercase one.
  ```bp
  val b = `my box`<i32>.make();
  ```
  (b) Left as is: a backtick type takes its type arguments only at a call or in a type position.
  ```bp
  val b: `my box`<i32> = `my box`.make();
  ```
- **Recommendation.** (a): 561 says every position that takes a name.
- **Blocks.** Nothing.

#### B-27-g2 · `io.terminal.keys()` on erlang and beam (decisions 506 (c), 553; 144 B-27 step 6)
- **Proposed (sonnet, 2026-10-15; awaiting the maintainer):** (b): add `readKey() -> Task<?Key>` (bare since 606 (1)) on every target.
- **Context.** `keys()` answers a stream of key presses for interactive prompts. On erlang and beam a `Stream` is lowered eagerly.
- **Measured.** On erlang / beam `keys()` gathers all input before yielding its first key, so it never answers on a live terminal (a hang under a pty); commonJS yields lazily. `stdin.readChunk()` + `terminal.parseKey` works on the three targets.
- **Options.**
  (a) `keys()` as is; an interactive loop on erlang reads `readChunk()` and `parseKey`.
  ```bp
  val chunk = await stdin.readChunk(); val key = terminal.parseKey(chunk);
  ```
  (b) ★ `readKey() -> Task<?Key>` on every target, `keys()` kept.
  ```bp
  val key = await terminal.readKey();   // one key, null at end of input
  ```
  (c) Wait for a lazy `{ async iter -> … }` lowering on erlang (553; 584's marker spelling), `keys()` the one API.
  ```bp
  for (await terminal.keys()) { k -> … }   // lazy once 553 lands on erlang
  ```
- **Recommendation.** (b), or (c) once 553 lowers lazily on erlang.
- **Blocks.** Key-driven prompts (`cli.prompt`) on erlang.

#### B-27-g4 · Raw mode and terminal size on erlang outside Linux (decision 506 (c); 144 B-27 step 6)
- **Proposed (sonnet, 2026-10-15; awaiting the maintainer):** (a): Linux only, the call answering `Unsupported` elsewhere.
- **Context.** `terminal.setRaw(on)` and `terminal.size()` need the terminal's device. Node has them built in; the Erlang VM does not.
- **Measured.** On erlang / beam the build reads Linux's `/proc/<pid>/fd/{0,1}` and runs `stty` (to clear `isig` and read the size). macOS and Windows have no `/proc`.
- **Options.**
  (a) ★ Linux only: elsewhere `setRaw` answers `Error(Unsupported)` and `size()` `null`.
  ```bp
  case terminal.setRaw(true) { Ok(_) -> …; Error(e) -> … }   // macOS on erlang: Error(Unsupported)
  ```
  (b) A path per OS (`/dev/tty` and `stty -f` on macOS; Windows refused).
  ```bp
  terminal.setRaw(true);   // Linux and macOS on erlang
  ```
- **Recommendation.** (a): no untested path ships.
- **Blocks.** Nothing on Linux.

#### 564-d · May a module declare a name the compiler gives rules to? (decision 564; 144 machine-1 row)
- **Proposed (opus, 2026-10-16; built as (a), awaiting the maintainer):** (b) for the names the compiler has rules for, (a) for the rest.
- **Context.** A module's own or imported `behavior` now owns its name in every type position, as a `type` of the same name already did (`conformance/docs.md` § behavior). Some prelude names carry language rules: `Result` (`try`, `throw`), `Task`, `Component`, `Iterator`.
- **Measured.** As built, `pub behavior Result { fn score(self: Self) -> i32; }` compiles and dispatches; the module's `Result` is what the name reads there, and `try` / `throw` keep std's.
- **Options.**
  (a) Yes, for every name: the module's declaration is what the name reads (built).
  ```bp
  pub behavior Result { fn score(self: Self) -> i32; }   // accepted
  ```
  (b) ★ Refused at the declaration for a name the compiler has rules for, located, naming std's declaration, as `primitive-type-name-taken` does for primitives; (a) for the rest.
  ```bp
  pub behavior Result { … }      // refused: `Result` is std's (builtins.d.bp), the language's rules use it
  pub behavior Component { … }   // accepted
  ```
- **Recommendation.** (b) for the names the compiler has rules for, (a) for the rest: never a quiet shadow of a language type.
- **Blocks.** Nothing.

#### 667-a · How `v is t` reaches the concrete type: a specialised copy, or the test passed at run time (decision 667; 144 B-146)
- **Proposed (sonnet, 2026-10-18; built as (b), held back from landing):** (a) as 667 states it.
- **Context.** 667: the `comptime t: type<T>` parameter is the function's specialisation (417), so `e is t` is `e is Users` in the copy `get(Users)` compiles to.
- **Measured.** The thread built no copy. The call passes the test function `{ v -> v is Users }` at run time and the body calls it. `is_type_parameter_refused` and `is_comptime_type_parameter` answer the same on the four targets. One visible difference: passing `t` on to another call (`r.count(t)`) is refused `expr-value-of-type`, where a specialised copy would know `t` at build and accept it (417).
- **Options.**
  (a) ★ A copy per type argument, as 667 states: `t` is known at build inside the copy, and handing it on is a `comptime` argument known at build.
  ```bp
  pub fn count<T>(self: Registry, comptime t: type<T>) -> i32 { … }
  pub fn get<T>(self: Registry, comptime t: type<T>) -> ?T { if (self.count(t) == 0) { return null; } … }   // accepted
  ```
  (b) The test passed at run time (built): no copies, the same answers, and `t` cannot be handed on.
  ```bp
  pub fn get<T>(self: Registry, comptime t: type<T>) -> ?T { if (self.count(t) == 0) { return null; } … }   // refused: expr-value-of-type
  ```
- **Recommendation.** (a): the decision's own reading, and the only one where `t` behaves as every other `comptime` argument.
- **Blocks.** 667's landing (B-146's third box) and B-152 (668): std's `async.failed(comptime t: type<T>, …)` and the cell `type_parameter_bound_by_token` need the token to reach run time, and it reaches none today (erlang leaves `I32` unbound, wasm refuses, commonJS and beam abort); B-146's other two boxes land without it.

#### 723-a · What `use memo` is: the run-time way a component makes its own context (decision 723; 144 B-17)
- **Proposed (opus, 2026-10-19; not built):** (a).
- **Context.** 723 names `val c = use memo({ -> createContext(Theme(…)) });` as the run-time way a component makes a context to provide. std has no `memo`, and no decision says what it keeps or when it recomputes.
- **Measured.** `use memo` is unbound on every target; the build-time form `comptime createContext(…)` works (cell `context_provide_made_in_body`).
- **Options.**
  (a) ★ `memo<T>(make: fn() -> T) -> Component<T>` in std's hooks: computed on the component's first render, kept for that component instance, never recomputed (no dependency list).
  ```bp
  component fn Page(dark: bool) -> Component<Element> { val c = use memo({ -> createContext(Theme(dark: dark)) }); use provide(c); … }
  ```
  (b) `memo` with a dependency list, recomputed when one changes.
  ```bp
  val c = use memo([dark], { -> createContext(Theme(dark: dark)) });
  ```
- **Recommendation.** (a): the one form 723 writes; a dependency list is a later decision if a program needs it.
- **Blocks.** The run-time half of 723's provide (cell `context_provide_made_at_run_time`); nothing else.

#### 723-b · May a context read name a parameter or a local of type `Context<T>`? (decisions 722, 723; 144 B-17)
- **Proposed (opus, 2026-10-19; built as (a)):** (a).
- **Context.** 722 / 723: a context is read through a context value the reader imports; the handle supplies the type and the default.
- **Measured.** As built, `use context(ctx)` with `ctx` a parameter, a local or an expression is refused at the argument, `context-not-declared` (example `context_read_of_parameter` in `conformance/docs.md`).
- **Options.**
  (a) ★ Refused: the argument names a module-level context declaration, local or imported (built).
  ```bp
  component fn Card(c: Context<Theme>) -> Component<Element> { val t = use context(c); … }   // refused: context-not-declared
  ```
  (b) Accepted: any value of type `Context<T>`; its type and its default come from the value.
  ```bp
  component fn Card(c: Context<Theme>) -> Component<Element> { val t = use context(c); … }   // accepted
  ```
- **Recommendation.** (a): the strictest reading, and the read stays resolvable at build from the text.
- **Blocks.** Nothing.

#### 723-c · `inject`'s defaults and the one-default-per-type check, now that a context is read by its handle (decisions 416, 722, 723, 379 (1))
- **Proposed (opus, 2026-10-19; built as (a)):** (a).
- **Context.** 722 drops 379 (1)'s catalogue: a read finds its default through the handle it names. 416's `use inject(Deps)` still takes each field's default as "that type's declared default", which needs the declarations found by type; 379 (1)'s `context-declared-twice` (one default per type) is what makes that lookup single.
- **Measured.** As built, `inject` and `context-declared-twice` are unchanged and still read the program's context declarations by type.
- **Options.**
  (a) ★ Keep both: `inject` resolves a field's default among the declarations the program holds, and two declarations over one type are refused (built).
  ```bp
  pub val a = comptime createContext(Theme(…)); pub val b = comptime createContext(Theme(…));   // refused: context-declared-twice
  ```
  (b) `inject` loses the declared-default step (nearest provided, else the field's own default, else an error); two declarations over one type allowed.
  ```bp
  type Deps(theme: Theme = Theme.default())   // the field's default when none is provided
  ```
- **Recommendation.** (a): 416 stands as written and 731 keeps it; (b) only if the maintainer wants no program-wide lookup anywhere.
- **Blocks.** Nothing.

#### 668-a · `compiler.meta<M>(d)` names `M` by the return alone — the call respelled `compiler.meta(d, M)`? (decisions 668, 298, 576 (3); 144 B-152)
- **Proposed (opus, 2026-10-19; built as (b)):** (a).
- **Context.** 298 / 576 (3) spell the read `compiler.meta<M>(d) -> ?M` and `compiler.metaAll<M>(d) -> M[]`: `M` occurs only in the return type, which 668 refuses.
- **Measured.** As built, the declarations take `comptime m: type<M>` (668's form) and the parser keeps accepting `compiler.meta<M>(d)`, rewriting it to the token internally.
- **Options.**
  (a) ★ The call is written as the declaration reads: `compiler.meta(d, M)`; `compiler.meta<M>(d)` refused as any explicit type argument that binds nothing.
  ```bp
  val e = compiler.meta(decl, Entity);   // ?Entity
  ```
  (b) The explicit-type-argument spelling stays, lowered to the token (built).
  ```bp
  val e = compiler.meta<Entity>(decl);   // ?Entity
  ```
- **Recommendation.** (a): one rule for every function, `compiler` included; (b) keeps a spelling no user function may have.
- **Blocks.** Nothing (B-152 is held on 667-a).

## Machine 2 — maximum priority (front 144, `machine-2/144-backends-tooling/`)

The questions that hold a step of machine 2 (backends, runtimes, std, tooling, the gate), answered with machine 1's
before every other part of this page; each holds one row, or nothing built.

#### 164-s3-m · `bytes.at` outside the range and `bytes.ofWords` over a word outside `0..255` (decision 585 (k); 164 s3 P2-d)
- **Proposed (sonnet, 2026-10-17; respelled 2026-10-18; awaiting the maintainer; built as (a)):** **(a): `bytes.at` answers `-1` for an index outside `0..length-1`, as `text.byteAt` and `string.charCodeAt` do; `bytes.ofWords` keeps the low eight bits of each word.** The review (fable, 2026-10-17) recommends (b).
- **Measured.** `modules/std-wasm/wat/bytes.wat`: `bytes.at` compares the index unsigned against `array.len` and answers `-1` past it (a negative index included), the body of `text.byteAt` (P1-a) over the same `$str` layout (`bytes` is an `i8` array, 164 s2, 346); `string.charCodeAt` (641; then `String.charCodeAt`) answers `-1` out of range on the four targets (`primitives.bp`: Erlang `_ -> -1`, Node `?? -1`, `text.zig`). `bytes.ofWords` writes each word with `array.set $str`: an `i8` slot keeps the low eight bits, so `256 + 33` is the byte `33`. No botopink operation builds a `bytes` from words (the type's members, 641 — then `behavior Bytes`: `fromUtf8`, `toUtf8`, `length`, `concat`, `slice`), so no target has an answer to compare, and 585 (k) names the three leaves without their answers. The codecs they are written for (`base64DecodeBytes`, `hexDecodeBytes`) produce words in `0..255` and read indices in `0..length-1`: through them neither answer is observable; any `std:` cell of `libs/std` (445) reaches the leaves. The unit test `wat: front 164 s3 ---- the Bytes leaves answer in a GC module` (`codegen/tests/wat.zig`) fixes `bytesOfWords([104, 105, 256 + 33])` as three bytes, `bytesAt(b, 2)` as `33`, `bytesAt(b, 3)` and `bytesAt(b, -1)` as `-1`. Without the check, `array.get_u` traps outside `0..length-1` (a `crash:` abort).
- **Options.** (a) As built. (b) Both trap: `bytes.at` is the bare `array.get_u` (a trap outside `0..length-1`, a negative index read unsigned included) and `bytes.ofWords` is `unreachable` at the first word outside `0..255`; the `.bp` codecs keep their own bounds; the unit test's three lines replaced. (c) `bytes.at` as `text.byteAt` (`-1`: one answer for one read over one layout), `bytes.ofWords` trapping.
- **Recommendation.** (b) — a leaf answers nothing outside its domain and no word is silently truncated; `text.byteAt`'s `-1` stays P1-a's until the maintainer extends the answer to it.
- **Blocks.** Nothing built waits; P2-d's `.bp` half (after B-139 and s2 P5) reads the answer before it is written.

#### 529-a · What `..` as the one spread leaves open (decisions 529 (3), 359, 37; 144)
- **Proposed (sonnet, 2026-10-14; awaiting the maintainer):** **(a) for each:** (1) no migration tool — no library writes a `...` call-site spread today (jhonstart's one `{...pairs}` is a tag spread the compiler does not implement yet); (2) 37's refusal of a non-name base is gone: 359 (6) allows any source expression, evaluated once (`record_update_base_not_a_name` answers `out 1`); (3) an enum variant's `..` update stays refused as `call-spread` (359's enum-variant row); (4) the dead decision-37 update path in `infer.zig` is deleted.
- **Measured.** 529 (3) landed: `..src` is the record spread, `...src` as a spread is `spread-dot-dot-dot` naming `..`, the formatter prints `..`, botopink-lang migrated. Merging the two spread forms moved three answers: `record_update_base_not_a_name` (a refusal under 37) now answers `out 1` under 359 (6); `Subject.Animal(..alice)` is `call-spread` (it was a type mismatch); two refusal carets moved one column (the shorter `..`). The parser refuses `...`, so the formatter cannot read an old `...` spread to migrate it.
- **Options.** Each point (a) as proposed or (b): (1) the parser keeps reading `...` for one release, the formatter rewriting it; (2) 37's restriction kept under 359; (3) an enum variant's update allowed; (4) the old path kept.
- **Recommendation.** (a) — 359 is the later rule, no library needs the old spelling.
- **Blocks.** Nothing built; `record_update_base_not_a_name`'s answer.

#### 529-b · What a record parameter `..props: R` leaves open (decision 529 (2); 144)
- **Proposed (sonnet, 2026-10-14; awaiting the maintainer):** **(a) for each:** (1) a record parameter beside a variadic refused (`record-param-variadic`) — positional variadic arguments and labelled fields clash; (2) a default on the record parameter refused (`record-param-default`) — `R`'s own field defaults are the defaults; (3) positions count the other parameters: in `fn f(a, ..p: R, b)`, `f(1, 2, x: 3)` passes `2` to `b`; (4) methods and associated functions take a record parameter as functions do (a later step builds it); (5) a generic `R` (`..p: Props<T>`) is legal, its fields typed by the call.
- **Measured.** 529 (2) landed for plain function calls: `..props: R` is an ordinary parameter of type `R`; the checker rewrites a call's labels naming `R`'s fields, and a `..src` spread, into one `R(…)` construction; four refusals 529 names have cells. Built beyond 529 and to confirm: (1) and (2) above; (3) is how positions are read today; methods and associated functions are not rewritten yet; a generic `R` parses and is untested.
- **Options.** Each point (a) as proposed or (b) its opposite.
- **Recommendation.** (a) — the strictest readings where 529 is silent, and the same rule for every callable.
- **Blocks.** A record parameter on a method; nothing built otherwise.

#### 543-a · What front 164 s1 (wasmtime) leaves open (decision 543)
- **Proposed (opus, 2026-10-14; awaiting the maintainer):** **(1) Winch with the cache** — a cold compile 315 ms against Cranelift's ~1000 ms, a run 37 against 33 ms; (2) the CLI and the LSP call `interrupt()` on SIGINT, so a runaway body ends as a located error; (3) `attempt` at build catches what it catches in a wasm program — an integer division by zero traps there, so it is excluded at build too (one answer, 434 (5)); (4) the compiled-module cache is reaped by B-77's `botopink cache`.
- **Measured.** s1 landed on wasmtime v49 with Cranelift and the compiled-module cache (warm 48 ms, cold 1.0–1.3 s for 12 builds); Winch was not one of 543's two options; no SIGINT handler is installed (Ctrl-C ends the process; `interrupt()` exists, nothing calls it); `attempt` at build also catches an integer division by zero, which traps in a wasm program; the cache has no reaping until B-77.
- **Options.** Each point (a) as proposed or (b): (1) keep Cranelift; (2) no handler; (3) keep catching at build; (4) a size bound now.
- **Recommendation.** (a) for each.
- **Blocks.** Nothing built.

#### 539-a · `throw` and a propagating `try` inside a `defer` body: refused or allowed? (decision 539 (5); 144)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(c): refuse a `throw` and a `try` that propagates, located (`defer-throw`, `defer-try`); a `try … catch` handled inside the body stays** — 539 (5)'s reason is "cannot leave the path", and a throw leaves it: in `finally` / `after` the deferred error replaces the error being propagated, masking it silently. Zig refuses `try` in a `defer`, Swift refuses throwing.
- **Measured.** 539 landed on every target with `return`, `break` / `continue` out of the body, `yield` and `await` refused; a `throw` or a propagating `try` in the body compiles, and its error replaces the block's own on commonJS, erlang and beam.
- **Options.** (a) Refuse both forms, `catch` included. (b) Allow: the deferred error replaces the block's (today, undocumented). (c) As proposed.
- **Recommendation.** (c).
- **Blocks.** Nothing built; two refusal cells once answered.

#### 537-b · `??`'s precedence against 537's parenthetical (decisions 537 (2), 28, 330)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(b): keep `??` tight; 537 (2) amended to "`catch` is the infix of the lowest precedence, below `??`"** — no program changes meaning, and 330's parenthesisation rule already covers the one ambiguous neighbour.
- **Measured.** 537 gives `catch` "`??`'s precedence, below every arithmetic operator", but `??` is the tightest binary level (decision 28), refused beside `&&` / `||` (330). std relies on it: `libs/std/src/hash.bp` (`h.at(2 * i) ?? 0 * 65536.0 + …`), `io/random.bp` (`64 + b.at(6) ?? 0 % 16`). The build made `catch` the lowest and left `??` alone.
- **Options.** (a) `??` moves to `catch`'s level, with a formatter rewrite parenthesising every `??` beside an arithmetic operator. (b) As proposed. (c) `??` at `||`'s level (JS), `catch` below it — the same migration as (a).
- **Recommendation.** (b).
- **Blocks.** Nothing built; 537's text only.

#### 535-b · Where the commonJS abort text lives: the runner's guard or the emitted program (decision 535)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(b): the entry module (the one with `main`, never a library module — a global `process.on` in a library is a side effect) emits the handler; the runner's guard kept for the browser's `.mjs`** — 535 is about what the program writes; one mechanical regeneration of the commonJS codegen snapshots.
- **Measured.** 535 landed on commonJS as a `node --import` guard that `botopink run` and the tests hand to node; the emitted `main.js` is unchanged, and a hand-run `node main.js` prints node's own report. erlang's guard is the runner's too, but an erlang build has no self-contained entry; a commonJS program has one and is run by node outside botopink.
- **Options.** (a) The runner's guard only, as landed. (b) As proposed. (c) Both.
- **Recommendation.** (b).
- **Blocks.** Nothing; the `abort_text_*` cells answer the same.

#### 532-a · The `from <file>:<line>:<col>` record extends 475 (2) (decisions 532, 475)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): 475 (2) amended with `from`, the header unchanged** — older cells are unaffected: the record appears only where frames exist.
- **Measured.** 475 (2) lists the `.snap` records exhaustively; 532's build added `from` (after `at` / `label`, innermost first, compared exactly) in the cell format and `conformance/docs.md`. 13 cells carry `from` lines; the header is still `botopink-cell 1`.
- **Options.** (a) As proposed. (b) `botopink-cell 2`. (c) The frames folded into the message.
- **Recommendation.** (a).
- **Blocks.** Nothing landed; 475's text.

#### 533-a · `comptime-badarith` names the whole expression while the caret is at the operator (decisions 533, 472)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(b): the message names the dividing operation's source (`6 / (3 - 3)`, `a / b`), text and caret agreeing; the `from` lines give the `comptime`** — low stakes.
- **Measured.** 472 reads "the operation and place"; after 533 the place is the operator but the backticked text is the `comptime`'s whole expression (`1 + 6 / (3 - 3) * 2`, `ratio(6, 0)`): `comptime_nested_division_by_zero`, `comptime_division_by_zero_in_helper`, `hole_any_call_raises`.
- **Options.** (a) The `comptime`'s text, as landed. (b) As proposed. (c) No backticked text.
- **Recommendation.** (b).
- **Blocks.** Nothing.

#### 540-b · `a.open()` requires `import {io.fs}` (decision 538; 144)
- **Proposed (fable, 2026-10-14; awaiting the maintainer):** **(a): keep the refusal `embed-open-needs-fs`** — `File` is std's type; a value whose type the module cannot name is Go's reason for `import "embed"`.
- **Measured.** 538 writes `pub fn open(self: Asset) -> File` with no import condition. The checker rewrites `a.open()` to `<fs>.openAsset(a)` (the shortest alias of `io/fs`); without the import it is refused at the call (`embed_open_without_fs_import`).
- **Options.** (a) As built. (b) An implicit import of `io/fs` where `a.open()` is written. (c) `File` ambient in `builtins.d.bp`, `open` a real method of `Asset`.
- **Recommendation.** (a).
- **Blocks.** Nothing.

#### 164-s3-g · `String.slice` (`text.slice`, `sliceFrom`, `sliceBetween`): with P1 or P2? (164 s3)
- **Proposed (fable, 2026-10-15; awaiting the maintainer):** **(a): P2, as a botopink body the codegen's `s[a..b]` / `s[i]` calls through the prelude.**
- **Measured.** The three are the codegen's own (it lowers `s[a..b]` and `s[i]` to them), not `String` methods bound by a cell.
- **Options.** (a) P2. (b) P1, as one more leaf.
- **Recommendation.** (a).
- **Blocks.** Nothing in P1.

#### B-116-k · What a `component` lambda's body allows (decision 574; 144 B-116 (i))
- **Proposed (opus, 2026-10-16; awaiting the maintainer; built as listed, the most restrictive):** (1) a `throw` or a propagating `try` in a component lambda is refused — `Component<Result<R, E>>` is B-116 (iii)'s; (2) its `use`s and `await`s join no hook node: the enclosing function's builder is cleared for its body, so its calls take 375's conservative asynchronous reading; (3) a body whose last expression ends with `;` is refused as a mismatch when `R` is not `void`, where a `component fn` would answer `rendered(null)`.
- **Measured.** 574 lowers `component { -> … }` as a `component fn` (the component-fn path, captures carried); `component_lambda_typed_val` and `component_lambda_typed_param` answer on the four targets. The three points are cases 574 does not name.
- **Options.** Each point as built, or (b): (1) a `throw` allowed as in a `component fn` (an `ErrorBoundary` catches it, 414, 504); (2) the lambda's hooks joined to the enclosing builder; (3) a `;`-ended body answering `rendered(null)` as a `component fn` does.
- **Recommendation.** (b) for (1) and (3), one rule for a `component fn` and a `component` lambda as 574 says; (2) as built until a component lambda has a builder of its own.
- **Blocks.** Nothing built waits.

#### 518-a · Two `needs:` refusals no decision states (decision 518 (1); 144 B-07)
- **Proposed (the coordinator, 2026-10-15; awaiting the maintainer):** **(a): both stay refusals, each with a cell** — `needs:` on `@External.Node` / `@External.Erlang`, and `needs:` given as anything but a list of `WasmNeed` values; the most restrictive reading (67).
- **Measured.** 518 (1) states one refusal: a `needs:` value outside `WasmNeed`. The build of 518 (7990b7de) also refuses `needs:` on a Node or Erlang form and a `needs:` that is not a list; no decision states either, and no cell pins them (B-07's Conformance analysis).
- **Options.** (a) As proposed. (b) `needs:` on another form is accepted and ignored. (c) A single value is accepted as a one-element list.
- **Recommendation.** (a).
- **Blocks.** Nothing built; two refusal cells once answered.

## Front 165 — rakun-workspace (the maintainer, 2026-10-14)

#### B-86-a · The lib-agnostic gate's `query`, and the catalogue's reach across packages (144 B-86, front 165 s4)
- **Proposed (opus, 2026-10-14; awaiting the maintainer):** (1) the gate refuses `rakun` in any case anywhere in `compiler-core/src`, and `query` only as a package — the import source `"query"` or the handle `import query`; (2) `jhonstart` leaves the gate's list, as the box says; (3) a dependency's catalogue entry has `module` = `<package>/<module>` (`plugin/root`), and a transitive dependency's declarations are listed too — built so, pinned by `modules/typeinfo_all_dependency_declarations`.
- **Measured.** `grep -riIE 'rakun|query' modules/compiler-core/src` matches about 111 lines: `query` is the catalogue's own word (`Query`, "a template body's query"). `@TypeInfo.all` already listed every module of the build, the dependencies included, and level B's journal already stores `declared` and `meta`: the new cell is green on the parent, on every target, cold and from level B. The reference says "every module of the build", while decision 242 lets a program import only its direct dependencies. Order and collisions follow the existing rule (module path, then declaration order; the key is module and name).
- **Options.** (1)(a) ★ `query` as a package only: `! grep -rIE '"query"|import query\b'`; (b) the word `query` anywhere, the catalogue's vocabulary renamed. (2)(a) ★ `jhonstart` out of the list (the box); (b) kept until 165 s2 renames it. (3)(a) ★ `<package>/<module>`, the transitive dependencies listed; (b) only the direct dependencies listed (242's import rule).
  ```bp
  #[m] pub fn hello() -> string { "plugin" }   // in package plugin, module root
  // the program: @TypeInfo.all(with: m) lists { module: "plugin/root", name: "hello" }
  ```
- **Recommendation.** (a) for each: (1) refuses every package spelling without renaming the language's own word; (2) is the box's text; (3) is what `rakun.boot()` needs — a module contributed by a package two layers down is discovered.
- **Blocks.** Nothing — built as (a); 165 s5 reads (3).

#### 548-a · Does every library's reference link its code and check the links? (decision 548; 461, 463)
- **Context.** A library's reference — the `docs.md` beside its conformance cells — shows code. Decisions 461 and 463 point at a cell's code with `<!-- example: <cell> -->`; decision 548 (2026-10-15) makes rakun's reference link its code instead, as `[src/main.bp](src/main.bp)`, and checks that every link names a file that exists. Today only rakun does that; the other libraries and botopink-lang keep the old form, and the runner they share knows neither. The question is whether every repository follows rakun.
- **Measured.** Decision 548 makes rakun's reference link its code (`[src/main.bp](src/main.bp)`, the base the `docs.md`'s directory) and rakun checks every link with its own `scripts/check-doc-links.sh`, run by its `repository-stages.sh`. The other libraries and botopink-lang keep 461 / 463's `<!-- example: <cell> -->`. The shared runner (`runner-standalone.sh`, one text across the libraries, CI check 4) knows neither form.
- **Options.**
  (a) ★ Every library and botopink-lang move to 548's form, the link check in the shared runner (and `zig build test-docs` reading `{path}`), one front per repository.
  ```text
  conformance/<feature>/docs.md, in every repository:  [src/main.bp](src/main.bp)   ← a link to a file that does not exist fails the gate
  ```
  (b) rakun alone; the others keep `<!-- example -->`.
  ```text
  rakun:                          [src/main.bp](src/main.bp)
  other libraries, botopink-lang: <!-- example: <cell> -->
  ```
- **Recommendation.** (a): one way to read a reference across the repositories.
- **Blocks.** Nothing — rakun is built as 548 says.

#### 548-b · The code names that keep a former library's name (front 165)
- **Context.** After front 165 the packages have new names — `rakun-stylesheet` for emilia, `rakun-bpp` for jhonstart, `rakun-ssr` for onze (mono-a) — but the functions, types, files, URLs and environment prefixes inside them keep the old library names, so a user of `rakun-stylesheet` still calls `emilia()`. The question is whether a front 150 step renames them to the package's vocabulary or they stay as the API.
- **Measured.** After 165 the package names are new, but the code keeps the old ones: `emilia()`, `emiliaWith`, `emiliaPlugin`, `emilia.bp`, the `emilia-hash-split` refusal, `jhonstart_*.erl` sidecars, `OnzeConfig`, `Onze.run`, `ONZE_PUBLIC_`, `/_onze/`, `.onze`, `onze_main.bp`, the example directories `examples/rakun-stylesheet/emilia-*` and `examples/rakun-bpp/jhonstart-*`.
- **Options.**
  (a) ★ A 150 step renames them to the package's vocabulary (a codemod, every consumer and cell in the same commit).
  ```bp
  // a 150 step: `emilia()`, `OnzeConfig`, `/_onze/` … get rakun-stylesheet's and rakun-ssr's names; every consumer and cell in one commit
  ```
  (b) They stay: the names are the API, the package name only moved.
  ```bp
  // a program depending on `rakun-stylesheet` still calls `emilia()`; one on `rakun-ssr` still writes `OnzeConfig`
  ```
- **Recommendation.** (a): a reader meets one name for one thing.
- **Blocks.** Nothing.

#### 165-a · Where the joined packages' rows of the version set live (decision 113; front 165 s2)
- **Measured.** rakun's `version_set.bp` holds one row per package of the rakun family; its test compares every manifest with the table. After 165 s1 the workspace holds 21 joined packages (erika, emilia, styled, jhonstart, onze and their `*-test` / sub-packages) with no row: a row naming `onze` in rakun's core `src` breaks decision 113's grep (rakun's core names no consumer), so the test reads only the `rakun*` manifests.
- **Options.** (a) ★ None until s2: after the rename every package is `rakun-*`, the rows are written then, and the filter goes. (b) A version set outside the core (a workspace-level file the gate reads), every member a row now.
- **Recommendation.** (a): s2 renames every package to a `rakun-*` name, so the rows need no exception; one version for the workspace (the README) makes the table one row per package at s2.
- **Blocks.** Nothing before s2; s2 writes the rows.

#### 165-b · Three packages outside 165's table: `onze-server`, `jhonstart-dom-test`, `rakun-cli` (front 165 s2)
- **Context.** Front 165 joins seven repositories into one `rakun` workspace and gives every package a `rakun-*` name and a row in its table (mono-a). Three packages did not fit: `onze-server` and `jhonstart-dom-test` would join a package built for a different set of targets, and `rakun-cli` has no row. The language sets targets per package, not per module or per dependency, so 165 s2 left them as packages of their own; the question is what they are called and whether the table gains their rows.
- **Measured.** 165 s2 folded every package of the table but three. `onze-server` needs `rakun` (erlang-only) while `rakun-ssr` builds for commonJS too (its CLI runs on node): folded, 21 commonJS reds (`rkReqLive` has no External for the node backend) — the language has no per-module target or per-target dependency. `jhonstart-dom-test`'s externals are node-only while `rakun-bpp` builds for erlang. `rakun-cli` is in no row of the table. Built: the three stay packages of their own (`onze-server` depending on `rakun-ssr`, `rakun-app`, `rakun-service`; `jhonstart-dom-test` on `rakun-bpp`).
- **Options.**
  (a) ★ Three packages named in the table: `rakun-ssr-server` (was `onze-server`), `rakun-bpp-dom-test` (was `jhonstart-dom-test`), `rakun-cli` as it is, each its row with its targets.
  ```text
  modules/rakun-ssr-server/     was onze-server, needs rakun (erlang)
  modules/rakun-bpp-dom-test/   was jhonstart-dom-test, node-only externals
  modules/rakun-cli/            as it is
  ```
  (b) A language feature first — a module's or a dependency's target set — and the three folded into `rakun-ssr`, `rakun-bpp` (a 144 step).
  ```text
  onze-server folded into rakun-ssr today: 21 commonJS reds — `rkReqLive` has no External for the node backend
  ```
- **Recommendation.** (a): a package is the unit of a target set today; three named rows keep 165's rule (every package a `rakun-*` name, one row each) without a new language feature.
- **Blocks.** Nothing; the names move in s5's second box or s7.

## Part 1 — What blocks tracks 00–03

### 01-compiler

`00-gate` has no open question: 114's steps wait on no decision.

#### s23-c · What a reached declaration's `Declared` holds in a decorator body
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b), and the meta read typed** — in a decorator body a reached declaration's `value` (`h.hook.value`, `c.callee.value`, `n.function.value`) is refused at the read, located (`decl-hooks-value: a reached function is no value at build`), as a template body's catalogue `value` is (`typeinfo-all-template-value`); its meta is read typed — `h.hook.meta(Route)` → `Route[]` (298, 130-s8-a), answered at build when `Route` is data and refused naming the run-time field otherwise (415 (3), 380) — never the `<decorator>.<key>` string list. Refuse over accept (67): a `null` typed as the function hides that nothing is there, and 364 (3) already says a function has no value at build; strings carrying a decorator's facts are 216 (2)'s legacy, which `builtins.d.bp` itself marks as going. Viable: the template-body refusal in `infer.zig` (guarded by `env.inTemplateFn`) widened to a decorator body, one id in `diagnostics.zig`; `hooks.zig` `declaredTerm` builds the term (it writes `value` as `undefined` and the string `meta`, and writes no `typedMeta` key today, so a direct `typedMeta` read likely fails at run time — a 144 row); the typed read follows `meta_read_at_build`'s rule for data. Changes: `Declared.meta: DeclaredMeta[]` leaves with the string meta; the comment on `Declared` in `builtins.d.bp`; one refusal cell.
- **Measured.** `HookUse.hook`, `HookCall.callee` and `HookNode.function` are `Declared<unknown>`. Built: `value` is
  `null` (no function of the program runs while it compiles, 364 (3)), and `meta` is every entry the declaration's
  decorators set so far, keyed `<decorator>.<key>` (`DeclaredMeta(key: "route.path", value: "/about")`). A template
  body's read of a catalogue entry's `value` is refused (`typeinfo-all-template-value`).
- **Options.** (a) As built: `h.value == null` is `true`; `h.meta` lists `route.path`. (b) `h.value` refused at the read
  in a decorator body, as in a template body (`decl-hooks-value: a reached function is no value at build`); `meta` as
  (a). (c) (b), and `meta` holds only the entries of the decorator reading the list (`path`), as a catalogue entry
  holds `d`'s.
- **Recommendation.** (b): refuse > accept; a `null` that type-checks as the function hides that nothing is there.
- **Blocks.** Nothing — built as (a).

#### 14s8-c · A hole known at build whose value raises there
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **(a), by 14s8-a (e).** A hole's expression is spliced into the generated code; when the compiler folds it at build (355 / 376) and it raises, the build is refused at the user's hole, located — never deferred to render.
- **Measured.** A hole known at build is evaluated on the comptime runtime as a `comptime` is (331). Built: a raise is refused at the hole — `pub val boom = raising "x"; pub val read = quote "${boom}";` (`raising` building `crash("x")`, which `@panic`s) is ``this hole is known at build (decision 355) and its value raised there: the comptime block raised: {error,{panic,<<"crash: x">>}}`` at `${boom}` (`reject/hole_known_at_build_raises`).
- **Options.** (a) Refused at the hole (as built). (b) The hole is computed at render (`known` false): `read` builds, and the program raises when it reads `boom`.
- **Recommendation.** (a) — fail > warn, at build rather than at run time.
- **Blocks.** Nothing — built as (a).

#### 14s8-e · A `comptime` reaching a component that reads a context (`comptime padAll(2)`)
- **Answered (the maintainer, 2026-10-11; awaiting its number in `decisions-taken.md`):** **`use` exists only in a `@Component` body, and a hook is a `@Component<R>` — so a `comptime` or a hole never reaches one.** (1) A hook is a component answering a value: `pub fn usePad(n: i32) -> @Component<StyledProperty> { val cfg = use context(StyleConfig); return padAll(n, cfg); }`, read in a component with `val p = use usePad(2);` (`use` runs it with the body's scope and answers `R`). (2) `use` written in a function that does not answer `@Component<R>` is refused at the `use`, located (`use` is allowed only in a component's body — `padAll` answers `StyledProperty`). (3) Calling a component or a hook without `use` only makes its lambda (504), so a loose expression never runs a `use`; only the renderer runs one — at build too, with `RenderScope.root()`, where `use context` reads the declared default (388 (4)). (4) A context is declared and read as 354 (2) spells it — `pub val styleContext = comptime createContext(StyleConfig(unit: 4));`, read by its value's type `use context(StyleConfig)`, provided by `use provide(createContext(StyleConfig(unit: 5)))` — and its value is immutable (no `var` field; one that has is refused, located), so reading its default at build is safe. (5) styled keeps its functions pure, the config a parameter (`padAll(n, cfg: StyleConfig = StyleConfig(unit: 4))`), computed at build in a hole or a `comptime`; a component reads `StyleConfig` with `use context(StyleConfig)` or uses the hook `use usePad(2)`. Today's `use context(StyleConfig); sheet.add(…)` goes: rules travel as data (`StyledProperty(className, rule)`), collected where they are used (355 / 377).
- **Measured.** Step 8's box read `comptime padAll(2).rules` as refused at `.contentHash(…)`; with
  `contentHash` carried (step 6, 341) the run now reaches styled's `styledPropertyComputed`, whose body
  is `val sheet = use context(StyledContext); … sheet.add(sheet.layer, …)` — a `comptime` has no render
  tree (354 (3)), so nothing provides `StyledContext`, and the run stopped at ``the comptime block calls
  `.add(…)` with 2 argument(s) at 144:11, which no primitive type … provides`` (botopink-lang, styled `feat`). 376 (3) makes `context` `Any`, and 355 / 376 (5) compute
  `styled "${padAll(2)}"` at build — yet at build there is no provider to read.
- **Options.** (a) ★ A `comptime` (or a hole computed at build) that reaches a `use` in a function it
  carries is refused at the `comptime`, naming the `use` and its function: ``the comptime reaches `use
  context.context(…)` at 139:17 in `__bp_tpl_styled_styled__propertyComputed`, and a `comptime` runs with
  no render tree: nothing provides what the `use` reads (decision 354 (3))`` (`reject/comptime_reaches_use`); `padAll(2)` stays at render until styled reads no
  context on that path. (b) The build provides each context's declared default (`StyledContext`'s), so
  `comptime padAll(2)` computes with the default sheet and its registration is dropped:
  `val p = comptime padAll(2);` answers `StyledProperty(className: "s_…", …)` and no sheet holds the
  rule. (c) A hole naming a call that reaches a `use` is never known at build (376's `Any` excludes a
  function reaching a `use context`): `styled "${padAll(2)}"` is computed at render, as today.
- **Recommendation.** (a) — refuse rather than answer with a provider nobody wrote (67); (c) is what
  01-checker step 36's stage gives once it lands, and agrees with (a).
- **Blocks.** Nothing — built as (a) (`block_eval.useReached`); step 8's `Any`-call box reads it.

### 02-std-and-packaging

#### 97-s16-a · Where `unicode`'s generated tables live
- **Proposed (fable, 2026-10-12; narrowed 2026-10-18; awaiting the maintainer):** **Settled: 97 s16 landed as (a), the flat private sibling `libs/std/src/unicode_tables.bp` (`status.md` `[x] 97 s16`). Left to confirm: the sibling stands as landed until 144 B-75; then, under 592 (1), (8), the file is `libs/std/src/internal/unicode_tables.bp`** — when the module model lands (B-69: a file is a module named by its path, `mod` goes; `src/internal/` is private to its package, 592 (8)) the generated tables move to `src/internal/`, `unicode.bp` writes `import {internal.unicode_tables as tables};`, and residual 11 closes structurally — an import of std's `internal/` from another package is refused, located (67: structural, no list). Viable: `resolver.zig`'s `mod` resolution and `build.zig` `collectStdModules` today; B-69's `internal/` box and B-75's std move (`collectStdModules` walks the tree instead of reading `mod` lines; the generator `libs/std/tools/unicode-gen` writes the new path). Changes: none now; a defect to file until B-69: `import {unicode_tables} from "std"` compiles (`resolver.zig` checks visibility only inside the importing package).
- **Not viable:** the former (b) — a file module declaring children in the folder of its own name (`mod tables;` in `unicode.bp`, or a `unicode/mod.bp`) — is gone with 592 (1): no `mod`, no folder child to declare; a file under `src/` is a module named by its path.
- **Measured.** `02/97` step 16 named `libs/std/src/unicode/tables.bp`. Landed (before 592, `mod` then in force): a flat sibling `libs/std/src/unicode_tables.bp`, a private `mod unicode_tables;` line in `root.bp`, `import {unicode_tables as tables};` in `unicode.bp`. The registry does not honour the `mod`'s privacy: a consumer's `import {unicode_tables} from "std"` resolves (97's compiler residual 11). Under 592 the `mod` line goes with `root.bp` (B-75) and privacy is the folder's.
- **Options.** (a) ★ As landed, then `src/internal/` with B-75:
  ```bp
  // today — libs/std/src/unicode.bp
  import {unicode_tables as tables};
  // after B-75 — libs/std/src/unicode.bp
  import {internal.unicode_tables as tables};   // libs/std/src/internal/unicode_tables.bp, private to std (592 (8))
  ```
- **Recommendation.** (a): no compiler change; the move is one generated file and the generator's output path in B-75, and residual 11 closes with `internal/`.
- **Blocks.** Nothing (B-75's std move reads the answer).

#### nat-d9 · LINQ's names in erika beside std's (98)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a), read with 312: the grammar is `query`'s one public spelling over an array, std's methods the other; the LINQ-named fluent `Query<T>` becomes `query`'s private lowering target** — `` query @`select name from xs where active order by name` `` (312: one grammar, two targets; 577: a template is called with its raw text) and std's `xs.filter(…)`, `map`, `flatMap`, `unique` are the two ways to compute over an array; the 35 public methods of `Query<T>` (`where`, `select`, `selectMany`, `orderByDescending`, `toList`, …) leave the public API, kept private as what the template builds into; `query` adds no fluent operator beside std's (137's context already says so). One way to write each thing: today `xs.filter(p)`, `query.of(xs).where(p)` (then `erika.of`) and `` query @`select * from xs where …` `` are three spellings of one read, two of them LINQ's names for std's methods (170: std takes the natural name, a library's copy goes). Viable today, `query` only: the `Query<T>` module of `repository/query` (then `erika.bp`; its methods become private `fn`s, the template's pipeline lowering keeps calling them), `modules/query-test` and `examples/query-linq` rewritten to the grammar. Changes: a 145 step (a rename and a visibility pass, no compiler change); (b) and (c) keep two public models of one thing against 283's case-by-case reading.
- **Measured.** `98-packaging-tail/README.md:47-51`; the `Query<T>` module (then `erika.bp`): `where`, `select`, `selectMany`, `orderByDescending`, `toList`; `query` is eager — every operator materializes a new array; std has `filter`, `map`, `flatMap`, `unique` (217). erika is the repository `query` (front 145; 165, decision 548), its template written `` query @`…` `` (577); the question stands for `Query<T>`'s public LINQ names.
- **Options.** (a) std's names (`filter`, `map`), `query` adding only what std lacks (`groupBy`, the aggregates). (b) LINQ's names — `query`'s identity is LINQ. (c) As is.
- **Recommendation.** none from this review: `query`'s purpose decides; (b) is a fair reading.
- **Blocks.** 145 (query).

### 03-bundled-libs

#### ctr-p · Confirmation `std-a` against confirmation `03r-e`
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Confirm `std-a`; `03r-e` lapses, and rakun's own readers go with it** — a query component or a cookie chunk whose escape is malformed or decodes to a control character is refused: `querystring.parse` / `parseForm` answer `Error` (std, already so), `http.cookie.parse` / `get` answer the chunk as absent while the refused chunk still claims its name (196, 181); nothing is kept "as written". Refuse over accept (67), one reader per header (196): rakun-app's `queryDict` already reads queries through `querystring.parse` with `try`, so the query half of `03r-e` is dead; its cookie half lives only in rakun's five readers (`request_context.bp` `decodeComponent`, `csrf.bp` `cookieValue`, `session_cookie.bp` `cookieFromHeader`, `i18n.bp` `cookieFrom`, `exchanges.bp` `sessionIdOf`), which 196 deletes. Viable: `libs/std/src/querystring.bp` and `repository/http/src/cookie.bp` exist and refuse as said; rakun declares no dependency on `http` yet — the adoption is 150's "consume http" step (rakun 04 step 5). Changes: Part 3's `03r-e` row is reversed by this confirmation; two 150 rows to file: `cookieFromHeader` takes the last duplicate against 181 / 348 (first wins), and the five readers disagree on one header.
- **Rules.** `std-a`: `querystring.parse` / `parseForm` "refuse … an escape that decodes to a control character", and rakun's `splitQuery` moves onto them. `03r-e`: a cookie or query component that would decode to a control character "stays exactly as written". 196 moves rakun's cookie readers into `http`.
- **Recommendation.** Confirm `std-a`; `03r-e` lapses when rakun reads queries via `querystring` and cookies via `http`.
- **Blocks.** rakun 04's readers; 104's consumer sweep.

#### 396-a · onze-content: "a node rendered by a component of the page's own where the page asks"
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a), in rakun-ssr's `content/` module (then onze-content), typed by 504's tree** — `toElementWith(doc: MdDoc, render: fn(node: MdNode, kids: Node) -> ?Node) -> Element` beside `toElement`: the page's function sees each node with its already-rendered children and answers the node to place — a tag, a component value (`<MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>` is the unrun lambda the renderer runs, 504) or `null` for the default element; `Item`, `Row` and `Cell` are nodes too, offered by their parents, and a tight list's paragraphs keep their `tight` rendering when the hook answers `null`. One function, one typed `case` over `MdNode`'s kinds (281: the kind is the variant, never a string), nothing per kind to keep in step with the tree ((b)'s 21-field record); (c) stays available but reproduces the default mapping's bookkeeping in every page. Viable today: `rakun-ssr/src/content/element.bp` (then `onze/modules/onze-content/src/element.bp`; `toElement`, `blockElement`, `inlineElement`, `itemElement`, `tableElement`, `rowElement` thread the hook; `markdown/src/markdown.bp`'s `MdNode` is public); rakun-bpp's `Node` (then jhonstart's) is the union a hole accepts (223, 191) and a component value in it is 504's. Changes: 158 s1's open box (was 142 step 3's second box); the entry's "markdown's `toElement`" is rakun-ssr's (396 (3): markdown names no framework).
- **Measured.** 142 step 3 built `element.toElement(doc: MdDoc) -> Element` (every `MdNode` to one fixed element, as the old `toElement`); 396 (3) and 158 s1's open box say a page may render a node with a component of its own, and fix no form. Components are functions of a props record (192/193, 593), `Element`s are values. onze-content is a module of the package `rakun-ssr` and jhonstart's `Node` is rakun-bpp's (165 s2); `Array<Element>` is written `Element[]` (641).
- **Options.** (a) `toElementWith(doc, render: fn(node: MdNode, kids: Element[]) -> ?Element)` — one function, `null` keeps the default element, the page matches the node kinds it wants (`Heading`, `Link`, `CodeBlock`, …). (b) A record of optional per-kind functions, `Components(heading: ?fn(depth, id, kids) -> Element, link: ?fn(href, title, kids) -> Element, …)`, one field per node kind. (c) Walk `MdDoc` in the page and call `toElement` for the nodes it does not render (no hook; the tree is public).
  (a) example:
  ```bp
  val page = toElementWith(doc, { node, kids -> case node { Heading(depth, id, _) -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>, _ -> null } });
  ```
  (b) example:
  ```bp
  val page = toElementWith(doc, Components(heading: { depth, id, kids -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo> }));
  ```
- **Recommendation.** (a): one reading, no field per kind to keep in step with the tree; (c) needs no code and is available today.
- **Blocks.** 158 s1's open box (only the hook; the default mapping is built).

#### 07-g · OTP release rendering
- **Proposed (fable, 2026-10-12; narrowed 2026-10-18; awaiting the maintainer):** **One library of pure renderers (`.rel`, `vm.args`, `sys.config`, the boot script, the Dockerfile and the systemd unit), written in botopink for every target, imported by `rakun-cli` and by rakun-ssr's release module (then `onze-release`); each keeps only what is its own (rakun's actuator paths and cookie env, the ssr's `assembleRelease` process run). Left: where it lives — a repository `botopink/release` (a), or a package of the one `rakun` workspace (b)** — since 165 (mono-a, 548) both consumers are packages of `rakun`, so 115's "two or more libraries" test and 326's argument for a new repository no longer follow by themselves: the two consumers are one repository, and a `release` package beside them (depending on nothing of rakun) is the workspace's own way to share code; (c) keeps two renderers whose bytes already differ (`.rel`'s `kernel` / `stdlib` versions, `vm.args`' flags), two answers for one release. Viable: `rakun/modules/rakun-cli/src/release/release.bp` (`renderRel`, `renderVmArgs`, `bootScript`, `renderDockerfile`, `renderSystemdUnit` are pure text; `renderSysConfig` calls the Erlang host `rkRelTerm` and needs the `.bp` term writer 107 s1's first box asks for) and rakun-ssr's `otp.bp` (then `onze/modules/onze-release/src/otp.bp`); under (a) the meta `.gitmodules`, § Layout and CI check 4 carry the repository as they carry `json` / `yaml`; under (b) nothing of the meta changes. Changes: 107 opens as written (its s1 reproduces both rows byte for byte from one renderer), its home reading the answer.
- **Not viable (fable, 2026-10-12):** the former (b), a `botopink` CLI feature (02) — it cannot serve the ssr's release, which has no erlang target.
- **Measured.** `rakun-cli/src/release/release.bp` (then `rakun-release`, 187) and `onze-release/src/otp.bp` render the same `.rel` / `vm.args` / `sys.config` / boot script / Dockerfile; the ssr cannot reuse rakun-cli's (rakun-cli erlang-only, the ssr also commonJS). Both are in the `rakun` workspace (165's table: `rakun-cli` a package, `onze-release` folded into `rakun-ssr`).
- **Options.** (a) A repository `botopink/release` of pure renderers (326), a dependency of both. (b) A `release` package of the `rakun` workspace, depending on nothing of rakun, imported by both. (c) Leave both.
- **Recommendation.** (a) or (b) — one renderer; between them none from this review: whether a library shared inside one workspace is a repository is 326's reading, the maintainer's.
- **Blocks.** `107-release` (a conditional front: answer it or defer 107).

### Implementation choices of tracks 00–03

Each implemented with its recommended option; the maintainer confirms or reverses (a reversal is a
local change in the named place). The full 1.0.10 text of each was under the same id in 1.0.10-beta's pending page, folded into these files on
2026-10-18 (decision 748); this table is the record.

#### 01-compiler (28)

| Id | Choice implemented | Where |
|---|---|---|
| 01c-a | A comptime module's atom is `bp@comptime@<owner path>__tpl__<decl>__<hash>` | comptime |
| 01c-b | A section leaf takes the leading-dot shorthand where the position's type is that section; with no expectation refused naming its section | checker |
| ck2-b | A section member may share a name with a top-level variant of the same enum (path and position type tell them apart); a variant declared twice at one level is `enum-variant-duplicate` | `modules/enum_section_leaf_beside_variant` |
| ck2-d | A label in a call of a function value is `label-on-function-value` | `reject/label_on_function_value` |
| ck2-e | A std decorator is reached via its module handle (`#[<handle>.<fn>]`); a leaf import of one is `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` is `unknown-annotation`; the handle is still needed after 216 (`mocks.mock`'s `addType` / `addMember` text names `mocks.invoke`, `testing/mocks.bp:212-220`), while 282/289 already leaf-import other libraries' decorators | checker |
| rc3-b | `unknown` is the host vocabulary's spelling where `any` was (tested with `is` before use) | `run/host_unknown_parameter` |
| rc3-c | Assigning a narrowed `var` checks against its declared type and ends the narrowing | `reject/narrow_ends_at_assignment` |
| 0405-b | commonJS's `__bp_show` prints `undefined` as `null` | commonJS prelude |
| onze F7 | Integer `/` integer truncates toward zero and is an integer on every target (`7.0 / 2.0` stays `3.5`); `docs.md:961-963` already states it | `run/integer_division_truncates` |
| lem-a | A host method is a real method of its type whose body is the binding, never inlined at the call site | `codegen/hostMethods.zig` |
| lem-b | `inline: true` (305's spelling; code still writes `inline = true` until 01-checker step 27) on a type method's `External.Erlang` / `Beam` accepted, changes nothing (refusing it is 01-checker's to add; recommended: refuse) | `run/external_method_local` |
| lem-c | A host method with no binding for the target refused where called (`MissingExternal` naming `Type.method`); wasm refuses every host method; an untyped receiver fails at run time (`ctr-o`) | `hostMethods.missingAt` |
| lem-d | One name per operation on every type (`Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`); constructors stay module functions | `io.net` · `regex` |
| lem-e | Private helpers taking a type stay free (`tlsEchoOnce`, `rkvPush`, `putMessageSource`, `messageSourceOr`) | std · `validation` |
| lem-f | commonJS adopts a host-built record into its class (`__bp_adopt`) directly and through `?T`, arrays and a `@Result`'s ok side, not through `@Task` | `run/external_method_on_host_record` |
| cep-a | A section path (`.Pad.All.8`) in a function of this module declared after the `comptime` that reaches it has no rewrite yet (the body is inferred later), so (a) the `comptime` is refused naming the path, its `line:col` and the function — "declare `later` before the `comptime` in this module" — as 14 step 8 refuses a template call there; (b) would infer such a function ahead of the `comptime`, inside the body being inferred. Recommended: (a) | `block_eval.unresolvedSectionPath` · `reject/comptime_section_path_declared_after` |
| cep-b | A local decorator's function that writes a section path (`fn fallback() -> Tok { return .Pad.All.8; }`) is inferred ahead of the run, once, as 371 infers one writing `same` (`infer.sameLoweredFn`), and carried rewritten; (b) would refuse the decorator at the annotation naming the path. Recommended: (a) — no remedy exists for (b) but moving the function to another module | `infer.sameLoweredFn` · `run/comptime_decorator_section_value` |
| cep-c | A comptime module's record is its untagged map, so (a) `v is Rule` and an arm naming a record test its declared keys — `is_map(V) andalso is_map_key(selector, V) andalso is_map_key(decl, V)` — and a record of another type with those keys answers `true`; (b) carry the type in the map (`#{'__bp_type' => 'Rule', selector => …}`), a change of every comptime term the evaluators read and reply; (c) refuse `is` / a record arm on the comptime runtime where two carried records share their keys. Recommended: (c), the strictest; (a) implemented, no cell has two such records | `codegen/erlang.zig` `untypedRecordTest` · `run/comptime_record_pattern` |
| 388-b | `c.run(scope)` answers `@Task<Rendered<R>>` for every component (375's mark is not in the type), declared on `builtins.d.bp`'s `Component<R>`; std's `context` declares `pub type Rendered<R>(value: R, scope: RenderScope)` and `pub type RenderScope(frames: unknown)`, its construction refused outside std (`render-scope-construction`) since botopink has no private constructor | `infer.inferComponentRun` · std `context` · `run/component_run_root`, `reject/render_scope_construction` |
| 388-c | 388 (4)'s "outside every body a value runs with `c.run(RenderScope.root())`" read as what `await c` means there: an `await` of a component value in a plain function, `main`, a test or a lambda runs it with `RenderScope.root()`; (b) would refuse it, naming `c.run(RenderScope.root())` — every test and `main` that awaits a component would be rewritten | `context_lower.zig` · `run/component_run_root` |
| 139-b | `bigint`'s surface is `primitives.bp`'s `behavior BigInt`, beside every other primitive's methods, and not a `type bigint` in `builtins.d.bp` as the front's README first said: the parser refuses a `self` method in a field-less `type` (`namespace-type-self`), and a static `declare fn` there is an `@`-builtin row of `builtins.zig`. `bigint.of(n)` / `bigint.parse(text)` are associated host primitives of decision 262's form (`String.fromCodepoint`'s), written through the type's own name (the checker renames the receiver `BigInt`); `BigInt.of(n)` types too, as `String.fromCodepoint` does. (b) would teach the parser and the drift test a primitive `type` with methods | `primitives.bp` · `infer.inferPrimitiveStaticCall` |
| 388-d | The wasm backend refuses a module the scope lowering reached, at its first component (`the wasm backend does not lower a component yet`), until 05's lowering: every component cell is a `.wasm.expect` (32 cells; `run/decl_hooks_*` among them, which ran on wasm under 354's map) | `wat.zig` `refuseScopeLowering` · `language-gaps.md` 354-wasm |
| 388-e | A body that keeps a bare `try` runs the statements after its last `use provide` as an inner closure, whose answer (the value, or the error the `try` returns early) is the result; every other body answers `rendered(v, kids)` at each `return` | `context_lower.zig` `lowerComponentBody` · `run/component_try_in_body` |
| 389-a | A declared function whose own return is no `@Component` answering one through its type arguments (`first<T>(cards)`) is 389's "what generic code answers": an edge with `callee: null`, the node asynchronous, no synchronous mark on the call | `infer.noteHookCall` · `run/decl_hooks_dynamic_call` |
| s29-c | A template annotation's outputs name a hole by its expression as written (the part's `code` placeholder `__bp_hole_q_0` becomes `id` in a recorded meta or member source); `q.fail` / `q.failAt` / `decl.fail` and a `lookup` of a name not in the text are reported at the annotation (the literal has no span map there); its `DeclAnnotation.args` is the literal as written; `decl.params` lists `self` | `infer.unplaceholderContributions` · `decorator_eval.annotationPlans` · `run/template_annotation` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01c-a:** confirm as a name and cache key only: the scheme (`__tpl__`, and `__dec__` for a decorator) lives in `template_eval.zig` `ownerId` and `decorator_eval.zig`, read by `crossModule.erlDeclAtom` / `decodeAtom`; the comptime module is still written as Erlang text that `runtime/wat/erl_parse.zig` and `lower.zig` lower to wasm (434) — the Where's "comptime" is that path, no BEAM runtime.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01c-b:** confirm (369's and 382's reading of a leading-dot path under an expected section type; not re-measured).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-b:** confirm (cell `enum_section_leaf_beside_variant`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-d:** confirm (cell `label_on_function_value`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — ck2-e:** reverse to one rule for every package (386): a std decorator is imported as a library's is — by leaf (`import {testing.mocks.mock} from "std"`, written `#[mock]`) or through its namespace (`#[mocks.mock]`) — and `std-decorator-leaf-import` goes; `#[<handle>.<not a decorator>]` stays `unknown-annotation`. Two import rules for one kind of thing is what 386 removed for libraries; `#[mocks.mock]`'s text naming `mocks.invoke` is a message to fix, not a reason. Viable: `infer.zig` `registerStdDecorators`; cells `std_decorator_leaf_import` (becomes a run cell), `std_decorator_unknown_through_handle`, `std_decorator_through_namespace`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — rc3-b:** confirm (cell `host_unknown_parameter`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — rc3-c:** confirm the rule; the cell `narrow_ends_at_assignment` now pins an optional-read refusal (`v is read off an optional ?Node — write ?.v`), not an assignment ending a narrowing — a 144 row: the cell is re-measured and rewritten to its claim (458 (2)).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 0405-b:** confirm (`codegen/js/js_prelude.zig` `__bp_show`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — onze F7:** confirm (cell `integer_division_truncates`; the text is `conformance/docs.md` § operators now).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-a:** confirm (`codegen/hostMethods.zig`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-b:** reverse to the recommendation: `inline: true` on a type method's `@External.Erlang` is refused at the annotation, located — an accepted flag that changes nothing is a lie (67); the checker already refuses an unread `inline` on `Node` / `Wasm` / `Typescript` (`infer.zig` `refuseUnreadInline`) and `hasExternalInline` is read only by the primitive dispatch, so the refusal is one more arm there; 144 B-02's step 27 takes it, the cell `external_method_local` rewritten from `inline = true` into a refusal cell.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-c:** confirm, as `ctr-o`'s one rule (`hostMethods.missingAt`); the wasm arm `binds(.wasm)` hard-coded `false` is `ctr-o`'s 144 row.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-d:** confirm (`libs/std/src/io/net.bp`; `regex.bp` `Regex.matches`); a 144 std row to weigh: the free `regex.matches(pattern, input)` beside `Regex.matches` is a second spelling of one test.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-e:** confirm; amend the Where: `tlsEchoOnce` is std's (`io/net.bp`), `rkvPush`, `putMessageSource` and `messageSourceOr` are `validation`'s (`src/binding.bp`, `src/messages.bp`) since 326.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — lem-f:** confirm (`js_prelude.zig` `__bp_adopt`; cell `external_method_on_host_record`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — cep-a:** confirm until 144 B-72, which removes it with 14s8-d's refusal (one box for both; `block_eval.unresolvedSectionPath`, cell `comptime_section_path_declared_after`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — cep-b:** confirm (`infer.sameLoweredFn`; cell `comptime_decorator_section_value`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — cep-c:** (c), the recommendation, as a 144 row: on the comptime runtime a record is still an untagged map (the comptime module is Erlang text lowered to wasm; `erlang.zig` `untypedRecordTest`, `is_map_key` served by std-wasm's term library) and `v is Rule` tests keys, so two comptime records sharing their keys answer `true` for each other — a silently wrong answer (67). Proposed: `is` and a record arm on a comptime value are refused, located, where two records carried into that comptime module share one key set, until the comptime carries the type ((b), the complete answer, on a measured need); the check sits where the module is emitted (`erlang.zig` `emitComptimeModule` knows the records it carries). Viable today; a refusal cell beside `comptime_record_pattern`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-b:** confirm (`infer.inferComponentRun`; std `context.bp` `RenderScope` / `Rendered`; cells `render_scope_construction`, `component_run_root`); under s23-j's answer an unmarked component answers its tree directly at run time and `await` on it is a no-op (375 (3)) — the type `@Task<Rendered<R>>` stays sound because `await` is always legal.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-c:** confirm (`context_lower.zig` `bpScopeRoot__`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 139-b:** confirm (501; `primitives.bp` `behavior BigInt`, `infer.inferPrimitiveStaticCall`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-d:** confirm until 144 B-25 step 4 (504: composition by data on wasm); amend the count: 38 cells carry a `snapshot/targets/wasm/main.snap` departure "does not lower a component" (the `.wasm.expect` form left with 457), all leaving with B-25 (458: a departure never records a defect — these are the `language-gaps.md` row 354-wasm, which B-25 closes).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 388-e:** confirm (`context_lower.zig` `lowerComponentBody`; cell `component_try_in_body`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 389-a:** confirm (`infer.noteHookCall`; cell `decl_hooks_dynamic_call`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — s29-c:** confirm (`infer.unplaceholderContributions`, `decorator_eval.annotationPlans`; cell `template_annotation`); the `__bp_hole_q_0` placeholder is rewritten by the step that lands 14s8-a (e) (s29-a).

##### 24-c · `iter for` / `iter while` are a prefixed `loop` (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — sugar over the prefixed `loop`, the label naming the written `for` (`LoopExprOf.prefixedKeyword`, `yield-label-not-generator`; cells `iter_loop_and_for`, `yield_label_loop`): the equivalence 125 writes, no new backend node (four lowerings to keep in agreement would be (b)'s cost for nothing). Viable, built; no change.
- **Measured.** The front's README asked for a new node `GenLoop { kind, loop }`; but each of the four backends already lowers one form of annotated loop (22-loops' `loop`), and decision 125 itself says `iter for (xs) { … }` means `iter loop { for (xs) { … }; break; }`. The parser reads it so and keeps the written keyword in `LoopExpr.prefixedKeyword`, for the formatter to give it back. The label stays where decision 105 writes it, after the loop's word.
  Today:
  ```bp
  iter for (xs) { x -> yield x * 2; }      // read as: iter loop { for (xs) { x -> yield x * 2; }; break; }
  iter loop :l { yield :l 1; }             // the label names the generator
  iter for :l (xs) { x -> break :l; }      // the label names the written `for`
  iter for :l (xs) { x -> yield :l x; }    // error[yield-label-not-generator]
  ```
- **Options.** (a) ★ Syntactic sugar over the prefixed `loop`; the label of `iter for :l` names the `for` (so `break :l` / `continue :l` keep their usual meaning).
  ```bp
  iter for :l (xs) { x -> if (x < 0) { continue :l; }; yield x; }   // continue of the `for`
  ```
  (b) A new `GenLoop` node, with a lowering of its own in each of the four backends — the same source, four more paths to keep in agreement.
  ```bp
  iter for (xs) { x -> yield x * 2; }      // becomes GenLoop { kind: For, loop: … } down to the backend
  ```
  (c) As (a), but the label of a prefixed `for` also names the generator — the parser only moves the label to the outer node.
  ```bp
  iter for :l (xs) { x -> yield :l x; }    // compiles: `:l` is the generator's scope
  ```
- **Recommendation.** (a). It is the equivalence decision 125 already writes, with no new backend.
- **Blocks.** Nothing (`01-compiler/24` step 2's confirmations).

##### 23-b · `base64`'s four functions retired, not aliased (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — the four retired; `encoding.base64Decode` / `base64UrlDecode` answer `@Result` (`libs/std/src/encoding.bp`, `base64.bp` gone): no alias hiding a refusal (67). Viable, built; no change.
- **Measured.** `base64.decode` answered a `string`; its replacement `encoding.base64Decode` answers `@Result<string, string>` because front 01 validates the input before `Buffer.from` truncates it (likewise `decodeUrlSafe` → `base64UrlDecode`). No library imported `base64`. `base64.bp` was deleted and its four tests rewritten with the `encoding` names (std keeps 417 tests). Decision 106 and `01-std/modules.md` already name the replacements.
  Today:
  ```bp
  val s = try encoding.base64Decode(text);     // @Result<string, string>: validates before decoding
  base64.decode(text)                          // no longer exists
  ```
- **Options.** (a) ★ Retire the four (`encode` / `decode` / `encodeUrlSafe` / `decodeUrlSafe`).
  ```bp
  val raw = try encoding.base64UrlDecode(token);
  ```
  (b) Keep the four in `encoding` as aliases answering `string` (they hide the refusal).
  ```bp
  val s = encoding.decode("not base64!");   // answers a truncated string, no error
  ```
- **Recommendation.** (a). Two spellings of one codec, one of them hiding the refusal, is what front 01 removed.
- **Blocks.** Nothing (`01-compiler/23` step 2's confirmations).

#### 02-std-and-packaging (10)

| Id | Choice implemented | Where |
|---|---|---|
| 01std-a | A bundled library loaded by CLI and LSP (`appendBundled`), not `expandStdImports`; compiler-core names no package but `std` | `build.zig` `bundled_packages` |
| 01std-c | `routing.pattern`'s empty pattern matches only `/`; rakun-web keeps "empty runs everywhere" at its call site (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` refuses a `redirect` disagreeing with `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` answer `@Result`, refuse a malformed escape, non-UTF-8 and a control character raw or decoded; `stringify` refuses a control character; `parse` is RFC 3986 (`+` stays), `parseForm` the form flavour (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` follows a symbolic link (dangling link is `false`) | `io/fs.bp` |
| 95-a | Front 95 relocated `jhonstart-link` and `rakun-app` as moves with no behaviour | jhonstart · rakun |
| 95-b | `rakun-app` declares its own `"targets": ["erlang"]`, as all 36 rakun manifests do (option (b); 1.0.10's "inherits the workspace" is not what the code does) | `rakun-app` manifest |
| 95-c | `erika-test` exists | erika |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01std-a:** confirm the rule (compiler-core names no package but `std`: `comptime.zig` `bundledPackage`); amend the row: the bundled set is `std` alone since 326 (`build.zig` `bundled_packages`), and `appendBundled` no longer exists (it survives only in `compiler-cli/src/cli/AGENTS.md` and `language-server/AGENTS.md`, two stale lines for 144).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01std-c:** confirm (`routing/src/pattern.bp`; `rakun-web/src/middleware.bp` `matcherAdmits`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 01std-e:** confirm (`actions/src/envelope.bp` `readEnvelope`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — std-a:** confirm (`libs/std/src/querystring.bp`); its cookie counterpart is `ctr-p`'s.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — std-b:** confirm (`libs/std/src/io/fs.bp` `exists`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 95-a:** confirm (both members exist).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 95-b:** reverse under 512 (3): `targets` is inherited from the workspace and a member writes it only to narrow; rakun's 31 identical `["erlang"]` lists (the "36" is stale) go in 150's manifest sweep, the workspace manifest keeping the one declaration — one place for one fact.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 95-c:** confirm (`erika/modules/erika-test`).

##### 24-g · The shape of `std/async` with a Task that never fails (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a), as built** — `allOf` / `all` / `race` over started tasks, `runAll` / `raceOf` / `timeout` over thunks, `failed(message)`; each form has one name (67), and the guide and 24's suite already write it; 432 later made a `@Task<@Result<T, E>>` reject, which changes no name here. Viable, built: `libs/std/src/async.bp` (the module has since grown `Gate`, `delay`, `RetryPolicy`, `retry`). Changes: none; the `beam_memory_*` note (an erlang task runs eagerly) is lg2-b's defect, not this choice's.
- **Measured.** Before front 24, `std/async` had a surface of thunks (`allOf`, `settleOf`, `raceOf`, `timeout`) and one of already-started Tasks (`all`, `allSettled`, `race`), both built on "rejected Task = failure". Now a Task never fails (decisions 120 and 121): the error goes INSIDE, `@Task<@Result<T, E>>`. The guide writes `try await async.allOf([fetchUser(1), fetchUser(2)])` — already-started Tasks whose value is a `@Result` — and front 24's suite follows the guide; the `beam_memory_*` cells, though, need unstarted thunks, because on erlang an eager Task has already run when the combinator receives it. The implementation gave the guide's form the name `allOf` and the thunks other names.
  Today:
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);   // started Tasks of @Result: stops at the first Error
  val xs = await async.runAll([{ -> work(1) }, { -> work(2) }]);     // thunks: this is where the concurrency is
  val r = await async.timeout({ -> slow() }, 100);                   // timed out → Error("timeout"), a string
  ```
- **Options.** (a) ★ Started: `allOf`, `all`, `race`; unstarted: `runAll`, `raceOf`, `timeout`; `failed(message)` answers `Error(message)`; `allSettled`, `settleOf`, `unwrapAll` and `attempt` were removed (there is no rejection to "settle"). A crash inside a task is re-raised.
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);
  async.allSettled([…])          // no longer exists
  ```
  (b) `allOf` over thunks, as the README of `01-std/02` wrote it — the guide's example is rewritten with thunks.
  ```bp
  val users = try await async.allOf([{ -> fetchUser(1) }, { -> fetchUser(2) }]);
  ```
  (c) One `allOf` overloaded for both element forms — needs overloading by type, which the language does not have.
  ```bp
  async.allOf([fetchUser(1)])            // started
  async.allOf([{ -> fetchUser(1) }])     // thunks — same name, another signature
  ```
- **Recommendation.** (a). It follows the guide and front 24's suite, and each form has one name.
- **Blocks.** Nothing — the README of `01-std/02-std-async-primitives` (1.0.10) already specifies `allOf` over started Tasks (`02/97` step 5 — the `RetryPolicy` built on `std/async`, a residue — and `01-compiler/24` step 2).

##### std-c · Decision 110's folder namespace is a rewrite of the parsed program (*implemented as (a)*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a) until B-69, which decides the folder's fate** — the rewrite stands (`comptime/std_namespace.zig`); under B-55-a (e) (1) a module is named by its path and nothing says a folder is a value, so B-69 states one rule for `import {io} from "std"`: proposed, the leaf form `import {io.fs} from "std"` is the one way and a folder is not importable (one spelling, and no rewrite that can miss a member — `io.nope.f()` today is `unbound variable 'io'`, a diagnostic that names nothing); (b)'s namespace type is not needed then. Viable: B-69 (the resolver's module naming) and the deletion of `std_namespace.zig`. Changes: a box in B-69; decision 110's folder namespace amended by it.
- **Measured.** Decision 110 allows `import {io} from "std"` and then `io.fs.readText(…)`. The implementation (`comptime/std_namespace.zig`) rewrites the already-read program to the leaf forms the checker and the four backends already lower: `io.fs.f()` becomes the namespace of `io/fs` (the item `io.fs as __bp_ns_io_fs` is added), and `collections.Dict` becomes `Dict`. Only the modules reached are imported. Limits: a missing member is `unbound variable 'io'`; a module declaring its own top-level `Dict` keeps `collections.Dict` unrewritten (refused all the same); a local named like the folder (`fn f(io: …)`) is not told apart from it. (23-a's alternative came in through here.)
  Today:
  ```bp
  import {io} from "std";
  io.fs.readText(path)       // rewritten to the leaf import `io.fs`; only the modules reached are imported
  io.nope.f()                // unbound variable 'io'
  ```
- **Options.** (a) ★ The rewrite: one file, no backend touched.
  ```bp
  import {collections} from "std";
  val d = collections.Dict.empty();   // runs on the four targets
  ```
  (b) A namespace type in the checker and a lowering of `a.b.f()` in the four backends, so the diagnostic names the folder.
  ```bp
  io.nope.f()                // error: std folder `io` has no module `nope`
  ```
- **Recommendation.** (a). (b) only if the diagnostic naming the folder is wanted.
- **Blocks.** Nothing (`01-compiler/23` step 2's confirmations); a reversal opens a step in `01-checker`.

#### Choices made by the 00-gate threads and the consolidation (5)

| Id | ★ implemented | Where |
|---|---|---|
| 111-b | the beam sidecar loader is emitted only when the build binds a host function (13 snapshots changed); the erlang backend follows the same rule (`buildBindsErlangHost`) | botopink-lang `codegen/beam_asm.zig` |
| 113-a | a target `botopink test` cannot run (wasm today — it runs commonJS, erlang and beam) is `NOT RUNNABLE` and fails `test-libs`, as `fronts.md` § Gate item 3 requires | `scripts/test-libs.sh` |
| 113-b | the restriction audit matches the refusal by its text (alternative, recommended: give the refusal an id — 07-residuals) | `lib-test-runner` |
| 110-b | the count history left `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | `format-check`'s `TREES` holds `examples` as one entry plus `modules/manifest/tests` | `scripts/format-check.sh` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 111-b:** confirm; amend the name: the erlang side is `codegen/crossModule.zig` `bindsErlangHost` (the beam side `beam_asm.zig` `bindsBeamHost` / `buildBindsBeamHost`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 113-a:** confirm as built (`scripts/test-libs.sh` counts `skipped_unsupported` as NOT RUNNABLE and fails; `test_cmd.zig` refuses `.wasm` only); two stale lines for 144: the script's legend still says "(beam, wasm)", and the wasm column of `botopink test` is B-25 / 97 s11's.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 113-b:** reverse to the alternative: the refusal gets an id (`host-binding-missing`, beside 334 (3)'s `std-unsupported-on-target`) and the audit matches the id, never the text (`lib-test-runner/src/runner.zig` `HOST_BINDING_MARK`) — a reworded message would silently pass the audit (67). 510 does not touch it (the audit spawns a build, no store).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 110-b:** obsolete: `tests/language/` left with 466 (conformance in-tree); the file does not exist.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 112-a:** confirm as it now is: `TREES=(examples libs/std modules/compiler-cli/tests modules/manifest/tests conformance)` — `examples` one entry; amend the row.

#### 03-bundled-libs (4)

| Id | Choice implemented | Where |
|---|---|---|
| 106-b | `log.consoleSink` writes one line per record on standard output through `@print` on every target (not node's `console.error` / `console.warn`, not OTP `logger`) — the one stream a wasm program also writes; `defaultSink` keeps the host's logger | `repository/log/src/sink.bp` |
| 106-c | `log.fileSink` rotates as OTP `logger_std_h` does, written once in botopink over four cells: after a write leaves the file at `maxBytes` or more, the file becomes `<path>.0`, each archive moves one up, `<path>.<maxFiles - 1>` is deleted, `maxFiles` 0 deletes the file; a failed host call raises; rakun's total size cap stays rakun's (folded into `maxFiles`) | `repository/log/src/logfile.bp` |
| 106-d | Per-name levels: `Threshold { From(level), Off }`, `Levels(root, names)`, the longest dotted prefix set wins; an empty name, an empty segment and a name set twice are refused (an `Error` when a sink is built, a panic when resolved); groups and run-time overrides are the framework's (it rebuilds the `Levels` and installs a sink again) | `repository/log/src/levels.bp` |
| 106-e | `log.captureRuntimeReports()` observes and never handles: BEAM a primary `logger` filter on the `otp` domain that hands the event on unchanged (OTP's own handler still prints it), node `uncaughtExceptionMonitor` (node still exits; `unhandledRejection` arrives as its origin under node's default mode), records of the logger `runtime` with `report.kind` (and node's stack under `error.stack_trace`), wasm a no-op binding | `repository/log/src/reports.bp` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-b:** confirm (`log/src/sink.bp` `consoleSink`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-c:** confirm the rotation; amend "a failed host call raises": under 431 / 486 / 495 the four file cells (`appendLine`, `fileBytes`, `moveFile`, `removeFile`) carry `result: true` and `fileSink` / `appendRotating` answer `Error` of `log`'s own error enum, never a raise — 144 B-08's audit names the cells, 156 takes the consumer change.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-d:** confirm (`log/src/levels.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 106-e:** confirm (`log/src/reports.bp`; its wasm cell is already `fn: captureNothing`, 481).

#### Choices made by the bugs-sweep thread (4)

| Id | ★ implemented | Where |
|---|---|---|
| bs-a | A type's associated fn is called as a std module's fn is (`planQualifiedCall`): a short call is filled from the declared defaults, a labelled one reordered, any other count is the arity error. `fn of(x: string, y: string = "d")` — (a) ★ `Bag.of("p")` is `Bag.of("p", "d")`; (b) refuse the short call, `'of' expects 2 argument(s), got 1` (before, every count but the exact one fell to a fallback that checked nothing and filled nothing) | `infer.zig` `associatedCallReturnType` · `run/associated_fn_of_type_default` |
| bs-b | An unsigned type takes no negated literal: `val x: u32 = -1;` — (a) ★ refused at the literal, ``the literal `-1` does not fit `u32` (at least 0)``; (b) accepted, and 264's run-time check aborts at the negation (`-0` is accepted either way) | `infer.zig` `refuseIntegerOutOfRange` |
| bs-c | An `erl` that printed its break handler's banner (`BREAK: (a)bort …`) is an interrupted run even though it exits 0 (SIGINT, then EOF on stdin halts the emulator with status 0): never stored in the runtime cache — the one place the harness reads the output, and only to decide not to cache. (a) ★ the banner marks it `.interrupted`; (b) spawn `erl +Bi` (SIGINT ignored): the run completes and is genuine, but a hung run then outlives Ctrl-C until the 2-minute timeout | `codegen/runtime.zig` `classifyEnd` |
| bs-d | `scripts/check-docs.sh --lib-root <dir>` replaces the default library roots; the harness test names its own. The gate keeps the default, which hashes every sibling package whole — `repository/vscode-extension` carries a `botopink.json`, so a symbolic link in its `node_modules` makes every docs check `never stored` in the meta checkout (a cost, never a verdict). (a) ★ as is; (b) the default roots take only a package with a `src` (vscode-extension's manifest is `{ "name", "version" }`); (c) the tree hash skips `node_modules` | `scripts/check-docs.sh` · `modules/compiler-cli/tests/result_store.sh` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-a:** confirm (`infer.zig` `planQualifiedCall` / `associatedCallReturnType`; the cell is `associated_fn_of_type_default`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-b:** confirm (`infer.zig` `refuseIntegerOutOfRange`; the message now cites 319).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-c:** confirm the classification (`codegen/runtime.zig` `classifyEnd`); the cache it guards — the harness's content-keyed runtime-output cache of compiler-core's snapshot tests, which short-circuits an `erl` / `node` run on a hit — is what 510 forbids read literally ("every test runs on every check"): proposed, that cache goes (a 144 row), subject to the maintainer confirming 510 reaches compiler-core's own tests; bs-c then has no object.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — bs-d:** obsolete: `check-docs.sh` takes no `--lib-root` (its options are `--doc`, `--list`, `--self-test`; it checks that `<!-- example: … -->` references name existing cells, 461), and the result store and `result_store.sh` left with 510.

#### Other tracks' choices a 00–03 step waits on

| Id | Choice implemented | Where |
|---|---|---|
| 03r-q | Locale routing lives in `rakun-app/src/i18n.bp`; no `rakun-i18n` member | 22 |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-q:** confirm (`rakun-app/src/i18n.bp`; no `rakun-i18n` member).

---

## Part 2 — The rest

### Priority — the botopink shape (`nat-*`)

#### nat-d · A second model of what the language has — case by case (decision 283)
No general rule (283): each case below is its own question, (a) the language's own, (b) both — the foreign one a thin layer over the native — or (c) as is.

#### nat-d6 · `throw "nav:not-found"` beside `noreturn` (53)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a), typed: `notFound() -> noreturn`, `redirect(url) -> noreturn`, the signal a `NavOutcome` value, caught by type, never by a `nav:` prefix** — rakun-bpp's two signals (then jhonstart's) raise `NavOutcome` (`NotFound`, `Redirect(url)`) through its one host cell (`__jhRaise` carrying the value — `#[compiler.external(.Erlang("…"), .JavaScript("…"))]`, 606 (4): an `Error` holding it on commonJS, `error({jhonstart_nav, Outcome})` on erlang) and answer `noreturn`, so `throw notFound();`, a bare `notFound();` and `val s: string = if (c) "a" else notFound();` all check (lg2-l: the code already has `noreturn` as the bottom type); a boundary reads the caught value with `case` over `NavOutcome` (`renderNotFound` catches `NotFound` only, `renderErrorBoundary` re-raises any `NavOutcome`, 414 (2)); an action redirects by its `Result` — `ActionError` gains `Redirect(url: string)` (303 amended; 303 See Other on the wire), no raise. 281 (a code fact never travels as a string), 67 (the boundary matches a type, a misspelt prefix cannot slip), and `isSignalReason`'s string test goes; (b) keeps the string under a wrapper; (c) keeps `-> string` for a value never produced. Viable now: rakun-bpp's `error_boundary.bp` (then `jhonstart/modules/jhonstart/src/`; `__jhRaise`, `notFound`, `redirect`, `__jhCapture`), `signal_runtime.mjs` / `jhonstart_signal.erl`, rakun-app's `navigation.bp` (`rkNavSignal`, `-> i32`), `actions`' `ActionError`; measured on feat that a host cell `declare fn raise(reason) -> noreturn` checks and runs on commonJS and erlang. Changes: `language-gaps.md`'s "navigation signals do not return `noreturn`" row closes (its text is stale: `throw notFound();` already checks); `31-a` (Part 3) becomes `-> noreturn`; wasm follows the cells' wasm form (B-25); with `attempt` landed (B-07, 431; 595 (8)) the boundaries' host try is 431's, the `NavOutcome` still read by type.
- **Measured.** A signal is a host-raised `nav:`-prefixed string (`contracts.md` § 5b); rakun-bpp's `notFound()` / `redirect()` declare `-> string`, rakun's `-> i32` (then `jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` by prefix; `boundaries-example.bp:89-91` (a `throw` inside `-> Result`, an `Error` value by 118, not a raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Rules.** 303: an action answers `Result<T, ActionError>` and `throw e` there is `Error(e)`; `ActionError` has `NotFound` but no redirect case — the answer must also say how an action redirects.
- **Options.** (a) `fn notFound() -> noreturn`, boundaries matching the `NavOutcome` type. (b) The string signal kept under a typed wrapper. (c) As is.
- **Recommendation.** (a). With lg2-l (lg2-h is closed by 656).
- **Blocks.** 150 s36 (then `05-jhonstart/26`), 150 s67 (then `07-onze/53`); lg2-l, 31-a.

#### nat-d7 · Lifecycle annotations beside interfaces (rakun 04)
- **Proposed (fable, 2026-10-12; rewritten 2026-10-18; awaiting the maintainer):** **(a): `type Cache(…) implement Lifecycle { fn start(self: Self) -> void { … } fn stop(self: Self) -> void { … } }`, `pub behavior Lifecycle { fn start(self: Self) -> void; fn stop(self: Self) -> void; }` declared by rakun's core; `#[component]` registers the two calls; `#[postConstruct]` / `#[preDestroy]` go (318 (8): rakun speaks botopink, no Spring name). Open inside (a): how `#[component]` learns that the annotated type implements `Lifecycle`** — `Decl` is gone (576 (1)), so the route this entry proposed, a `Decl.implements` field the compiler owes, has no object; what 576 (3), (8) give a decorator are the reads `compiler.kind(d)`, `compiler.methods(d)`, `compiler.fields(d)`, `compiler.annotations(d)`, …, none of them the `implement` clauses. Two ways remain: (a1) 626 (2)'s structurally typed handle — `pub fn component(syntax decl: Lifecycle) -> void` checks the annotated type against the behavior's members at the annotation — which types every component by `Lifecycle` and refuses a component without `start` / `stop`, unless rakun writes a second marker or a `lifecycle:` parameter for the plain component (two spellings, 67); (a2) a `compiler.*` read of the clauses — `compiler.implements(d) -> unknown[]`, the handles of the behaviors the type names — a 144 row beside 576 (8)'s reads, `#[component]` keeping `syntax decl: unknown` and registering the calls when `Lifecycle` is among them. A behavior is the language's own shape for a contract (311 (1), 617 (2)), typed and checked at the declaration (a missing `stop` is the checker's error, not a marker nobody read). Until the answer rakun keeps (c)'s markers (`rakun/src/lifecycle.bp`, `context.bp`'s `rkRegisterLifecycle` over `compiler.methods(decl)`) as its nearest form, marked a language gap.
- **Not viable:** the former "(a) on a `Decl.implements` the compiler owes" — `Decl` and `Decl<T>` are removed whole (576 (1)); a declaration is read through `compiler.*` alone (576 (3)).
- **Measured.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`. 576 (8) lists what a handle answers — `hooks`, `fields`, `methods`, `params`, `returnType`, `owner`, `annotations`, `variants` — and no `implements`; 626 (2) checks a `syntax decl: B` handle against `B`'s members structurally, no `implement` clause asked of the user's type.
- **Options.** (a) `implement Lifecycle { fn start(self: Self) -> void; fn stop(self: Self) -> void; }`, read by `#[component]` as (a1) the typed handle or (a2) a `compiler.implements(d)` read. (b) Both. (c) As is.
- **Recommendation.** (a); between (a1) and (a2) none from this review — (a1) asks nothing of the compiler but types every component by one behavior, (a2) is one read more on `compiler`.
- **Blocks.** rakun 04 (150 s1); under (a2) a 144 row.

#### nat-d8 · A `use…` hook name under `use` (53)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a): `use actionState(createPost, initial)`; a hook whose name starts with `use` is refused at its declaration** — a hook is a function answering `Component<R>` and is read with `use h(…)` (354 (1)), so `use useX(…)` spells the verb twice; the checker refuses a `Component`-answering declaration named `use<Upper…>`, located (`hook-name-use-prefix: a hook is read with use — name it actionState`). One spelling (67), and 281 already fixes the argument (the action by reference). Viable: rakun-bpp's `forms/` module (then jhonstart-forms) has `actionState(actionId: string, initial)` (`form.bp`; its first parameter becomes the action reference under 281 — a step of 150's jhonstart section, 150 s36 … s47); the refusal goes with the `use` diagnostics in `comptime/diagnostics.zig` and `infer.zig`'s `.useHook` arms (today `use useThing(2)` passes `check`), one refusal cell. Changes: 150 s67 step 7 rewrites `use useActionState(…)` to `use actionState(…)`; one 144 row for the refusal.
- **Measured.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — rakun-bpp exports no `useActionState`; its forms hook is `actionState(actionId: string, initial)` (`form.bp:182`).
- **Rules.** 281 already settles the argument: the action is passed as a reference (`createPost`), never a string — in the example and in `actionState`'s signature (150 s67 step 7 writes it so). Only the hook's name is open.
- **Options.** (a) `use actionState(createPost, initial)`; a hook named `use…` refused. (b) Both names. (c) As is.
- **Recommendation.** (a).
- **Blocks.** 150 s67 step 7's examples (then `07-onze/53`).

#### nat-f · Configuration in JSON — case by case (decision 284)
`botopink.json` as clean as possible, configuration allowed where it makes sense (284); `"bpp"` stays, an object since 338 (`{"default": "<package>", "style": …}`). Each case below is its own question.

#### nat-f2 · `onze.json`'s `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a), as one typed record** — the ssr's config file keeps its keys (284; 271 fixes `trailingSlash`, `redirects`, `markdown`, `islands`, `site`), read at build into one `OnzeConfig` record whose fields are the typed options rakun-ssr's code already has (`UrlRules`, `MarkdownOptions`, `IslandProps`, `allowedRedirects: string[]`): an unknown key, a wrong kind, an unknown variant or a bad value is an error naming the file, the key path and the expected type (49-c's refusals, typed), 299's precedent in the ssr's own loader. Configuration is allowed there (284) and the build checks it as it would code; (b) would move what 271 / 272 / 224 placed in the file and leave two homes for one fact. Viable today: rakun-ssr's `config.bp` (then `onze/modules/onze/src/config.bp`) `loadConfig` / `applyKey` / `configKeys` (hand-written, typed; `allowedRedirects` exists, the other four are added there); 299's `#[config]` binder is not built in rakun, so nothing is copied; the line in the file is "subject to" the `json` library's `decode` exposing a path's position — until then the error names the key path. Changes: 150 s66 step 1 (the four keys) and 150 s60 / s67 read `OnzeConfig`; `islands` joins `configKeys` (224 names it, the code lacks it). Doubt: the file's name — 165 s2 ticked the codemod `onze.json` → `rakun-ssr.json`, while 150 s60's and s67's boxes still write `onze.json`; which name the file keeps is not settled by rows 575–659 and follows the ssr's steps, not this question.
- **Not viable (fable, 2026-10-12):** (a) through 299's `#[config]` binder — it is not built in rakun; the proposal uses the ssr's own typed loader instead.
- **Measured.** The config file is read and validated by `loadConfig` whenever the CLI resolves the project, `onze build` included (then `onze-cli/src/resolve.bp:48-50`); an unknown key is refused (49-c) without a line. Only `allowedRedirects` exists (then `onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` are 150 s66's planned keys (then `124-bpp-cli/README.md:67-69`), which 08-h already writes; all four restate options the ssr's code types (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedent: 299 (typed record bound from a file, errors naming file, line and expected type).
- **Options.** (a) Kept in the config file, read into the typed record at build as 299 does, a wrong key or value an error at its line in the file. (b) A typed record in the app's code (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), no JSON. (c) As is.
- **Recommendation.** (a) — configuration is allowed there (284); the build checks it as code would, as 299 does for rakun.
- **Blocks.** 150 s66 step 1 (then 124); 08-h; 150 s59 / s60 (then `07-onze/49`, `50`).

#### nat-f4 · The `ONZE_PUBLIC_` prefix on environment variables (53, `contracts.md`)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(b): the declaration says it — `#[publicEnv] pub val apiUrl = env.read("API_URL");` — and the `ONZE_PUBLIC_` prefix goes** — a value the browser may see is declared once, typed, marked where it is read; the bundler inlines the build's value of a marked `val` into the client bundle and refuses, located, any `env.read` reached from a `#[client]` component that is not such a `val` (`env-non-public` kept, its message naming the marker). A fact carried by a naming convention of the environment is a string rule the code never states (281's spirit; 67: a forgotten prefix is a located error either way, but the marker is checked where the author wrote it, not where the operator named a variable); (c)'s list in the config file is a second home for a code fact. Viable: rakun-ssr's bundler module (then `onze/modules/onze-bundler/src/refusal.bp` — `env-non-public`, `env-dynamic`, `env-vars`, `env-write` — and `scan.bp`) already finds a client module's `env.read`; `config.bp`'s `isPublicEnvName` / `publicEnvPrefix` go; `publicEnv` is a decorator on a `val` (356: it runs and the `val` is found by `compiler.find`) recording the typed meta `PublicEnv(name)` (`compiler.setMeta`, 576 (11)), which the bundler reads from the scan (it scans source today) or, at build only, through `compiler.find(with: publicEnv)` (581 (3): the catalogue answers declaration handles and never reaches run time — the former `@TypeInfo.all` read is gone, 576 (7); a list the running bundler needs is written by the marker itself through `compiler.init`). Changes: 150 s60 / s67 and `contracts.md` § env; the examples' `ONZE_PUBLIC_*` names become plain names under the marker. The prefix's own name after 165 s2 (`ONZE_KEY` → `RAKUN_SSR_KEY`; 150's ssr steps still write `ONZE_PUBLIC_`) is (a)'s question alone.
- **Measured.** A variable reaches client code only when its name starts with `ONZE_PUBLIC_` (Next's `NEXT_PUBLIC_`). A missing prefix is not silent: the bundler refuses at build a client module's `env.read("X")` without it, naming the variable (`env-non-public`, then `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). What remains is a stage fact (186) carried by a naming convention the environment must follow (`client-island-example.bp:41`).
- **Options.** (a) Kept. (b) The declaration says it — `#[publicEnv] val apiUrl = env.read("API_URL")`, its use from a `#[client]` component checked at build (186); a marker of its own, since `#[clientVisible]` is 278's hydration annotation; 299's `#[env("…")]` the precedent in a record. (c) A list of public variables in the config file.
- **Recommendation.** (b).
- **Blocks.** 150 s60, s67 (then `07-onze/50`, `53`); `contracts.md`.

### 01-compiler — the language

#### lg2-l · Whether `noreturn` is a bottom type
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(2), as the code already has it: `noreturn` is the bottom type, and a `noreturn` body must not fall through** — a `noreturn` call fits any position (`val s: string = notFound();`, `throw notFound();`, an `if` branch), ends its path (`stmtsAlwaysExit` / `callNeverReturns` narrow after it), and a function declared `-> noreturn` whose body can complete is refused at the declaration, located. Measured on feat: `unify.zig` ("`noreturn` is the one-way bottom type"), cells `builtin_noreturn_any_position` and `try_catch_null_and_noreturn_narrowing` pin (2) on the four targets; (1) would break both cells for no gain — a value position a `noreturn` fills is never produced, so nothing is silently wrong, and it is what lets the signals be `-> noreturn` (nat-d6). Viable: built; the fall-through check is one more use of `stmtsAlwaysExit` on a `-> noreturn` body (`infer.zig`). Changes: a 144 row for the defect (`fn bad(c: bool) -> noreturn { if (c) { panic("x"); } }` compiles and returns — `panic` imported from `failure`, 606 (2)); the entry's Measured and `language-gaps.md`'s two `noreturn` lines are stale.
- **Measured.** `fn notFound() -> noreturn { raise("…"); }` ends the path on commonJS and erlang, but `throw notFound();` in a `Result` body and `val s: string = notFound();` mismatch → rakun-bpp's `notFound()` / `redirect()` (then jhonstart's) declare `-> string` (`error_boundary.bp:180-188`); front 53's example writes `val _gone = redirect(…)` (`server-action-example.bp:79`); the ssr's blog app calls `notFound();` as a statement. `panic(message) -> noreturn` (606 (2); `todo` is gone, `panic("not implemented")` in its place); a branch ending in a `noreturn` call already narrows — may be confirmed de facto.
- **Options.** (1) `noreturn` unifies with nothing: a call to it is a statement ending its path; the signals become `-> noreturn` called as statements (in a page: `fn() -> View`, `use params<P>()`). (2) `noreturn` is the bottom type, fits any position.
- **Recommendation.** (1).
- **Blocks.** The row; rakun-bpp's signals (then jhonstart 63, `31-a`); rakun's navigation tests.

#### lg2-n · A thunk coerced into `Node`
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(1): no thunk coercion — a deferred child is a component value, never a `fn() -> Element`** — `Node` takes an array, an `Element`, a `string` and a component value (191, 223, 504: the tree holds the unrun lambda `view()` makes); a boundary's deferred child is typed `child: Component<Element>` (414's nodes), not `fn() -> Component<Element>` as rakun-bpp (then jhonstart) writes today. Three coercions the compiler knows and nothing inferred from a lambda's shape (67); under 388 a component already is the deferred form, so a thunk is a second spelling of it. Viable: `infer.zig` `childrenCoercion` (`Children`, array, `string`, `Renderable`) stays; measured on feat `show({ -> "x" })` is `expected Children, got function`. Changes: rakun-bpp's `ErrorBoundaryNode` / `NotFoundBoundaryNode` / `suspense.Boundary` `child` fields drop the thunk (414-a is closed by 653: calling a component only makes its lambda; B-17, 150 s36).
- **Measured.** `show({ -> "x" })` against `fn show(children: Children)` (`Node` under 223) mismatches.
- **Options.** (1) No thunk coercion: a deferred child is a named field of the boundary. (2) `fn() -> Element` coerces into `Node`.
- **Recommendation.** (1): compiler-known coercions stay three (array, `Element`, `string`).
- **Blocks.** The row; rakun-bpp's boundaries (then jhonstart 30).

#### lg2-s · Module-graph reflection
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(1): no module-graph reflection; rakun-ssr's bundler (then onze-bundler) keeps `importsOf`, a scan that fails loudly** — no `compiler.*` read answers a module's imports (576 (3), (8): a handle is a declaration's, its reads `hooks`, `fields`, `methods`, `params`, …), and the former (2) is gone twice over: there is no module-level annotation (315) and no `@Decl` at all (576 (1)). The bundler reads what the compiler already resolves when a front needs it — a `botopink` CLI output of the module graph (B-69's resolver names every module by path, 592 (1)), never a comptime reflection over modules (`compiler.find` answers declarations, not modules, 581 (3)). Viable: rakun-ssr's `scan.bp` `importsOf` and `graph.bp` `loadModules` (then `onze/modules/onze-bundler/src/`); measured on feat before 576, `decl.imports` was `unknown field 'imports' on type 'Decl'`. Changes: one of `status.md`'s two lines — see Measured.
- **Not viable (fable, 2026-10-12; 576):** (2) — an `imports` field on a module-level `@Decl`: no module-level annotation (315), and `@Decl` is removed whole (576 (1)).
- **Measured.** `decl.imports` was the checker's unknown field of `Decl`, at the read (before 576; today `Decl` is an unknown type); the bundler reads imports with `importsOf`, a textual scan. Doubt: `status.md:403` lists `ctr-m (= lg2-s)` among the questions closed on 9 Oct, while `status.md:401` keeps `lg2-s` open in the same section — whether this entry is already closed by what closed ctr-m, or only the contradiction was, is not settled by rows 575–659; one of the two lines goes with the answer.
- **Options.** (1) None: `importsOf` stays a textual scan that fails loudly; the module graph, when a front needs it, is a `botopink` CLI output, not a reflection.
- **Recommendation.** (1); its old argument ("in step with `lg2-k`") fell with 216.
- **Blocks.** The row; rakun-ssr's client bundle (then onze 68).

### 02-std-and-packaging

### 03-bundled-libs

#### 07-b · Does "one library, several divergent copies" also justify a package?
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): 115's "two or more libraries" stays the only test** — a duplicate inside one library goes to std when generic, else to that library's core; rakun's five cookie readers are already 196's case (`http.cookie`, consumed by rakun and onze-server). A second test would admit a package for one consumer by counting its copies (115's exception is the maintainer's, stated per case: 396 (4), 398 (3)). Viable: `repository/http/src/cookie.bp` exists; rakun's adoption is 150's step (no rakun manifest depends on `http` yet). Changes: none.
- **Measured.** rakun has four divergent `Cookie:` readers inside itself (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, front 104). The cookie and q-value copies already qualify under 115's test (onze consumes them too).
- **Options.** (a) 115's "two or more libraries" stays the only test. (b) Add the divergence test.
- **Recommendation.** (a): a single-library duplicate goes to std or the owning library's core.
- **Blocks.** Nothing; the rule for the next candidate (front 104's `http` exists; rakun adopts it in its step 5).

### 04-rakun

#### erk-b · `#[documentQuery]` under 313 (*proposed*)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a), with its own generator: rakun-data's `#[documentRepository]` over a `behavior` whose methods carry `` #[documentQuery @`…`] ``** — the same shape as 313 (a `behavior`, one annotation per method recording typed meta, a generator producing the implementation and the by-type registration), the filter a template text handed to the store verbatim as `#[nativeQuery]` hands SQL (577: a template is called with its raw text; `:name` placeholders matched by name against the parameters, an error at the annotation when one is unmatched); not the SQL `#[repository]` (then dbcontext's, folded into rakun-data by 165 s3), whose generator emits SQL runners and refuses a method it does not know (313: "a method with neither annotation is an error"). One repository shape for every store, no second model (283); (b) a document target of `query` waits on a measured need; (c) is the shape 313 deleted. Viable as a library decorator (216, 311 (1); 604: a marker is a function with a `syntax decl` parameter): a new `rakun-data/src/nosql/` module (a `pub mod nosql;` line in `root.bp` until B-75; under 592 (1) the path alone names it) — nothing of 09 exists on feat (no `DocumentStore`, no `nosql.url`; `documentQuery` is one comment in `sql/query.bp`), and the SQL repository shape is rakun-data's since 165 s3 (`entity/`, `context/`, `repository/`), so 150 s17 step 4 opens after 150 s48 … s51 (then 143) land the shape to copy. Changes: 150 s17's README names `#[documentRepository]`; the entry's "09 step 4" is 150 s17 step 4.
- **Not viable (fable, 2026-10-12):** (a) through the SQL `#[repository]` — its generator emits SQL runners and refuses a method it does not know (313); (b) — no document target of `query` exists.
- **Measured.** 150 s17 step 4: `` #[documentQuery @`…`] `` follows `#[query]`'s shape — a member of the repository type answering the template verbatim. 313 deletes that shape for SQL: a repository is a `#[repository] behavior`, its methods carrying `` #[query @`…`] `` (then `#[erika "…"]`) or `#[nativeQuery("…")]`. `query`'s grammar is SQL's; a document store's filter is JSON (`$in`, `$gt`, …).
- **Options.** (a) The same shape: a document repository is a `#[repository] behavior` whose methods carry `` #[documentQuery @`…`] ``, the text handed to the store as `#[nativeQuery]` hands SQL to the driver (`:name` placeholders matched against the parameters, escaped by `bind`). (b) `query` gains a document target — the same `select … where …` lowered to the store's filter. (c) As is: a member of the type.
- **Recommendation.** (a) now — one repository shape for every store; (b) when a measured need asks for it.
- **Blocks.** 150 s17 step 4.

#### 03r-ab · Front 09's binary-protocol stores
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a), confirm — the record only** — 150 s17 (then 09) ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://` and `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names the driver (150 s17 step 5; 160: an in-process double or a `deferred.md` row, never a fallback to ETS). Refuse over a silent substitute (67); the Elasticsearch arm reaches HTTP through a core extension point, never a `rakun-data → rakun-restclient` edge (`ctr-w`, 185). Viable: nothing of 09 is on feat (`rakun.nosql.url` does not exist; the one URL-selected store is `rakun.datasource.url` in `rakun-data/src/datasource.bp`, whose unknown-scheme refusal — "whose scheme no arm serves — accepted: …" — and `sql_datasource_test.bp` are the pattern step 5's cells copy). Changes: none; 150 s17 follows (a) as written.
- **Measured.** The store is selected by `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase are byte protocols (`bytes`, 346, 641 — then `Bytes`, not yet built) needing OTP drivers a sidecar cannot load; ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp`; Elasticsearch is HTTP + JSON. 150 s17 is already written to (a): the former steps 4 and 7 are step 5's refusal cells plus one `deferred.md` row each — only the record is missing.
- **Options.** (a) 150 s17 ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names the driver (step 5). (b) Four protocol clients in Erlang sidecars, a front each. (c) Defer 150 s17.
- **Recommendation.** (a): never a fallback to ETS under a Mongo URL; the Elasticsearch arm without a `rakun-restclient` edge (`ctr-w`; 150 s17 step 3 still goes through it). The front already follows (a).
- **Blocks.** 150 s17 step 5 (the refusal cells).

#### 03r-af · The seven unbuilt example projects
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): retire the seven; the three on disk gain a `README.md` each** — `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (none with a README), and every member's contract is asserted by its own tests (390 (5): a value nothing verifies becomes a plain test, not an example). An example that never ran is a promise the gate cannot keep (67); (b) is seven fronts for no measured reader. Viable: three files; the workspace manifest already lists `examples/*`. Changes: 73 step 3; the 1.0.10 list is a closed record.
- **Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (gate cells); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` never started; every member's contract asserted by its own tests.
- **Options.** (a) Retire the seven (1.0.10 example list a closed record; the three on disk gain a `README.md` each). (b) Build them, one front each, after every member front. (c) Build `rest-service` only.
- **Recommendation.** (a).
- **Blocks.** 73 step 3.

#### 03r-ak · CycloneDX validation
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a′): validate the SBOM against the checked-in CycloneDX 1.5 schema with the vendored validator 399 already fixed, in the test only — not a hand-written walker** — `release_test.bp` runs `process.run("node", ["test/tools/check-schema.js", <document>])` over `test/release/fixtures/bom-1.5.schema.json`, as `repository/validation/test/json_schema_test.bp` does with Ajv's standalone 2020 build (399: vendored under `test/tools/`, version and hash in `AGENTS.md`, never shipped); `ok` or the validator's error list fails the test; no network. One validator in the ecosystem, not a second ~120-line one implementing a subset of JSON Schema (67: a subset that passes a document the real schema would refuse is a silent pass); (b) weakens the box, (c) is a std feature nobody else needs. Viable: `rakun-cli/test/release/release_test.bp` (the SBOM test asserts `bomFormat`, `specVersion`, `components` by name today; no `fixtures/` yet), std's `io.process.run` (rakun's CLI already calls it); node on rakun's CI rows as on validation's. Changes: 81 step 3's box names 399's tool; the entry's `release_test.bp:168` is stale.
- **Not viable (fable, 2026-10-12):** (c) — std has no JSON-schema validator, and 399 fixed the vendored one for tests.
- **Measured.** The box asks for validation against a checked-in CycloneDX 1.5 schema, no network; std has no JSON-schema validator; `release_test.bp:168` asserts fields by name (`rakun-cli/test/release/` after 128).
- **Options.** (a) `release_test.bp` walks the SBOM against `test/release/fixtures/bom-1.5.schema.json`'s `required`, `type`, `enum` and local `$ref`s (~120 lines), as 81 step 3 already reads. (b) Amend the box to the field-by-field list. (c) A `json.schema` in std.
- **Recommendation.** (a).
- **Blocks.** 81 step 3.

#### 03r-al · Kafka producer transactions against the in-process broker
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): confirm — the record, and the wiring** — 83's outbox relay publishes through `withProducerTransaction` on the in-process broker (sends held, released on commit, dropped on a raise; `read_committed` sees nothing after an abort); the real-broker run is a `deferred.md` row (160). Viable: `rakun-messaging/src/reliability/transaction.bp` `withProducerTransaction` (tested in `transaction_test.bp`); the outbox (`rakun-data/src/tx/outbox.bp` `publishAfterCommit`, `relayTick(ds, publisher)`) takes a publisher function and does not go through it yet — the edge `rakun-messaging → rakun-data` exists, so the glue is rakun-messaging's publisher handed to `relayTick`, 15 step 5's first box. Changes: none to the plan; the entry's `transaction.bp:39` is `:54`.
- **Measured.** `rakun-messaging/src/reliability/transaction.bp:39` provides `withProducerTransaction(prefix, body)` (sends held, released on commit, dropped on a raise; `read_committed` reader tested in `transaction_test.bp`). 15 step 5 is already written for (a): four boxes (outbox path through `withProducerTransaction`, no outbox row; nothing visible to `read_committed` after an abort; the path in the log; one `deferred.md` row for a real broker). Only the record is missing.
- **Options.** (a) 83's outbox path publishes through `withProducerTransaction` on the in-process broker; real-broker run a `deferred.md` row. (b) Delete step 5's broker boxes. (c) Leave step 5 open until a real Kafka is in the gate.
- **Recommendation.** (a).
- **Blocks.** 15 step 5 (the record only; the front follows (a)).

#### 03r-am · Where the broker and scheduler doubles live
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(c): the doubles live in rakun's `testing/` module (then the package `rakun-test` — 165: each `*-test` is its package's `testing/` module), reaching the registries only through the core's hooks — no edge to rakun-messaging, nothing to measure** — `rkOnReset("broker-double", …)` (`rakun/src/runtime.bp`) and a listener-names term the core owns are the seam; `testing/` is a module of `rakun`, so it imports nothing of `rakun-messaging` (that import would be `rakun → rakun-messaging`, the cycle itself), and `rakun-messaging`'s tests import `rakun`'s `testing` through the edge `rakun-messaging → rakun` they already have. 185's rule (the core defines the extension point); 150 s21 step 3 then runs `container_test.bp` through the double. Viable: `rkOnReset` exists; no `broker_double` / `task_double` exists in rakun (the `testing/` module's notes already describe "the broker double" it does not hold). Changes: 150 s21 steps 3–4 written for (c); the entry's `runtime.bp:215` is `:232`.
- **Measured.** `rakun-messaging`'s tests import `rakun`'s `testing/` module (then `rakun-test`, which depended on `rakun` only) through `rakun-messaging → rakun`; 150 s21 step 3 makes `container_test.bp` run through the double — a double inside `rakun/src/testing/` that imported `rakun-messaging` would be `rakun → rakun-messaging` beside `rakun-messaging → rakun`, a package cycle, unless the loader honours a test scope (none exists in `modules/manifest`; not verified). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:232`).
- **Options.** (a) Measure: add the import to the `testing/` module and `container_test.bp`'s; if `botopink test` refuses the cycle, the doubles live beside the module they double (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) and rakun's `testing/` documents them. (b) Take the edge, assuming the rule landed. (c) The doubles in rakun's `testing/` module, reaching the registries only through core hooks (`rkOnReset("broker-double", …)`, the listener-names term).
- **Recommendation.** (a), with (c)'s shape either way.
- **Blocks.** 150 s21 steps 3 and 4.

#### 03r-an · RSocket's WebSocket transport after decision 187 (*proposed*, raised as R92-1)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(b): a core extension point keyed by a transport enum — `rkRegisterTransport(.WebSocket, mount)`; `rakun-websocket` plugs in** — the core declares `enum Transport { Tcp, Tls, WebSocket }` and a registry in `rakun/src/runtime.bp`; RSocket in `rakun-messaging` asks the registry for the configured transport and refuses the boot naming the member to add when none registered it; `rakun.rsocket.server.transport` reads into the enum through 299's typed config. 185 (no member-to-member edge for what is optional; `rakun-messaging` does not depend on `rakun-websocket` today and (a) would load its tree for every messaging consumer); 281 / 299: the transport is a variant, not the string the code compares. Viable: `rakun-messaging/src/rsocket/rsocket.bp` refuses `transport == "websocket"` and speaks `tcp://` only; no registry or enum exists — 92 step 2's first and third boxes build them (the registry pattern of `rkOnReset`). Changes: the entry's `rakun-rsocket/src/rsocket.bp:69` is `rakun-messaging/src/rsocket/rsocket.bp` (187).
- **Not viable (fable, 2026-10-12):** (a) — a `rakun-messaging → rakun-websocket` edge loads the websocket tree for every messaging consumer, which 185 forbids for what is optional.
- **Measured.** R92-1 mounts the transport via `rakun-websocket`'s `#[wsEndpoint]`; after 187 RSocket lives in `rakun-messaging` → the edge would load `rakun-websocket`'s tree (security, data) for every messaging consumer; today the WebSocket transport is refused at boot (`rakun-rsocket/src/rsocket.bp:69`, TCP only).
- **Options.** (a) Take the edge `rakun-messaging → rakun-websocket`. (b) The core defines a transport extension point `rakun-websocket` plugs into (185's rule), keyed by the transport enum's variant (`rkRegisterTransport(.WebSocket, …)` — 299 types the config, 281 no string). (c) Retire the WebSocket transport: R92-1's two boxes and R92-7's `ws://` / `wss://` arms deleted, TCP and TLS only, a `deferred.md` row.
- **Recommendation.** (b).
- **Blocks.** 92 step 2's first and third boxes.

### 05-jhonstart

#### 67-a · Where the DOM-side forms boxes are asserted
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(a): `fake_dom.mjs` gains `<form>`, `<input>`, `FormData` and `submit`; the five boxes are asserted in `forms_dom_test.bp` now, and again in the ssr's browser run (150 s67, then onze 53)** — a box asserted only in a browser run no gate holds is unasserted (160, 67); (c) adds a dependency for what a few hundred lines of fake give. Viable: `fake_dom.mjs` (no form, no `FormData`, no `submit` today) in `jhonstart-dom-test`, still a package of its own while question 165-b is open — or rakun-bpp's `testing/` module once 165-b folds it; `forms_dom_test.bp`'s home (`jhonstart-dom-test/test/` or `rakun-bpp`'s `testing/`) follows that answer, not this one; `test/dom_test.bp` the pattern; org-6: the step owns the file it adds, `fake_dom.mjs` edited by one step at a time. Changes: 150 s38 steps 1–3 as written; one decision row records it (the front's header claims an answer no decision has).
- **Measured.** `fieldError` after `__jhFormState`, in-place re-render on `ok: false`, two forms' `pending`, optimistic commit / roll-back read `document` and `FormData`; `botopink test` has no DOM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only) already serves the render's browser half. Front 67's header (now 150 s38) says "`67-a` answered", but no decision records it — still open.
- **Options.** (a) Extend `fake_dom.mjs` with `<form>`, `<input>`, `FormData`, `submit`; assert the five boxes (1.0.10's 3a, 3b, 4, 5) in `forms_dom_test.bp` beside `fake_dom.mjs` now, and again in the ssr's browser run (150 s67). (b) Only in the ssr's browser run. (c) A real DOM library as a dev dependency.
- **Recommendation.** (a).
- **Blocks.** 150 s38 steps 1–3 (written for (a)); 150 s67's write path.

### 06-emilia

### 07-onze

#### 50-b · What `onze dev` does on a change
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): `onze dev` is `build` then `start`, looped over a file watcher — one code path, the bytes `start` serves** — a change rebuilds and restarts the node (1–3 s per edit); island state is lost either way (Fast Refresh a non-goal). (b)'s hot load and (c)'s fallback add a second path whose equivalence with `start` nothing proves (67); (b) returns when (a) measures too slow on the blog. Viable: `onze-cli/src/start.bp` (`erl -noshell -pa … -eval …`), `onze-bundler/src/rebuild.bp` (the invalidation, kept for the client half); `onze dev` returns 2 today (`main.bp`) and no watcher exists — the watcher is std's `fs` on commonJS / erlang with 506's `io.process.spawn` / `forwardSignals` for the child; 50 step 2 builds it. Changes: 50 step 6's "reloads the changed modules" becomes a restart; 53 step 6.
- **Not viable (fable, 2026-10-12):** (b) and (c) — the hot-load path is not written, and nothing proves its equivalence with the bytes `start` serves.
- **Context.** `onze dev` is the development command of onze's server rendering (onze is now the package `rakun-ssr`, mono-a): while the app runs, it should pick up what the user just edited. Today it returns 2 and does nothing; `onze build` compiles the server to BEAM and `onze start` runs it. The choice is whether a change restarts the server from a fresh build or loads the changed modules into the running one, and it has to be made before 50 step 2 builds the watcher (decisions 67, 140, 506).
- **Measured.** `onze build` compiles the server to BEAM (`server/beam/`), `onze start` runs `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` computes invalidated modules; the BEAM can `code:load_file/1`; UI registry and route table fill at module load (decision 140): a reloaded page re-registers, a new route file needs `onze_routes.bp` regenerated and the table rebuilt.
- **Options.**
  (a) Restart the node on every change (`build` + `start` looped over a file watcher — same bytes as `start`, 1–3 s per edit).
  ```text
  $ onze dev
  # src/app/page.bp saved → build, then start again: the node restarts (1–3 s) and serves what `onze start` would
  ```
  (b) Hot-load changed modules; regenerate and reload `onze_routes` when the app tree changes.
  ```text
  # src/app/page.bp saved → each invalidated module reloaded with code:load_file/1 in the running node
  # a new route file → onze_routes.bp regenerated, the route table rebuilt
  ```
  (c) (b), falling back to (a) when a convention file changed.
  ```text
  # page.bp saved → hot-loaded as (b); a convention file saved → restarted as (a)
  ```
  Browser island state lost either way (Fast Refresh a non-goal, `07-onze/reference-holes.md` § 29).
- **Recommendation.** (a): one code path, the same bytes `start` serves; (b) later, if (a) measures too slow on the blog.
- **Blocks.** 50 step 2; 53 step 6.

#### 49-g · `isString` — onze's own, or std's `Json`
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(b), in `json`: `Json.isString()` beside `isObject`; rakun-ssr deletes its own** — one reader per question, in the library that owns `Json` (396: the `json` library takes std's `json.bp` whole, std knows nothing of JSON; until 151 s1 lands the type is still std's, so the method is written in std's `json.bp` under 97 and travels with the move). (c) is a diagnostic text as a type test, never. Viable: `libs/std/src/json.bp` (`isObject`'s `case` is the shape), then rakun-ssr's `config.bp` `isString` and `types.bp`'s import go (then `onze/modules/onze/src/`). Changes: a one-line follow-up in rakun-ssr after the `json` line lands.
- **Measured.** 49 step 1 moved the ssr's `config.bp` and `types.bp` (then `onze/src/`) onto std's `Json` methods
  (`members`, `field`, `str`, `items`, `isObject`, `kindName`); `Json` has no string test, so
  `config.bp` keeps one `pub fn isString(v: Json) -> bool` (a `case` over `Str`), imported by
  `types.bp`. The step's grep (`membersOf`, `strOf`, `isObject`, `kindName`) is empty; its
  Mechanism line also names `isString`.
- **Options.** (a) Keep the ssr's `isString` — `if (isString(v) == false) throw wrongKind(…)`.
  (b) `json` (std's `json.bp` until 151 s1) adds `pub fn isString(self: Self) -> bool` to `Json` (97's surface), the ssr deletes its
  own — `if (v.isString() == false) throw wrongKind(…)`. (c) Read through `kindName` —
  `if (v.kindName() != "a string") throw …` (a diagnostic text as a type test).
- **Recommendation.** (b): one reader per question, in `json`, beside `isObject`; (c) never.
- **Blocks.** nothing; under (b), a one-line follow-up in `config.bp` / `types.bp` after the `json` line (151 s1).

#### 51-a · A malformed integer in a metrics sidecar or a gradient angle
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(b): refuse — `parseMetrics(…) -> Result<FontMetrics, string>` answers `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, and `gradientOf` answers its "not a two-stop linear gradient" value for a non-integer angle** — a malformed input is refused, never read as zero (67; 299's precedent: `rkPropInt("12abc") == 12` was reversed). Viable: rakun-ssr's `og/` module (then `onze-og/src/`): `metrics.bp` (`Error(_) -> 0` at three `parseInt` sites) and `svg.bp` `gradientOf`; the call sites and `og_test.bp`. Changes: the og step's `og_test.bp` boxes (150, then 51).
- **Measured.** 51 step 1 replaced the og module's two `intOf` cells with std's `string.parseInt()`;
  the old cells answered `0` for text that is not an integer, and so do the call sites now
  (`case t.parseInt() { Ok(n) -> n.toI32(); Error(_) -> 0; }` — `metrics.bp` `parseMetrics`,
  `svg.bp` `gradientOf`). A sidecar line `ascent 9x0` reads as `ascent 0`;
  `linear-gradient(9.5deg,#a,#b)` draws at 0°. An integer past `i32` now aborts (`toI32`).
- **Options.** (a) Keep `0`. (b) Refuse: `parseMetrics(…) -> Result<FontMetrics, string>`
  answers `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, and `gradientOf`
  answers its "not a two-stop linear gradient" value (`#(-1, "", "")`) for an angle that is not
  an integer.
- **Recommendation.** (b) — decision 67: a malformed input is refused, never read as zero.
- **Blocks.** nothing today; (b) is an `og_test.bp` change owned by the og step of 150 (then 51).

### 08-bpp

### 09-cardume

#### atm-c · An atom's `T` across the server/browser seam (*proposed*)
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **(b), with `#[clientOnly]` on the atom's declaration as the one spelling** — any `T` may be an atom; an island's read set is checked at build over its hooks (277: `use atomValue(x)` edges), and an atom an island reads whose `T` is not encodable (`#[validated]`'s `encode`, 327, or a type 294 accepts) must be declared `#[clientOnly] pub val draft = atom(…);` — 278's one function with one meaning, on a declaration as 186 puts it on a hook — else an error at the island's `use` naming the atom and `T`; no `clientAtom(…)`. Restrictive where it crosses, free elsewhere (354 (6) states the seam for contexts and leaves atoms to this question); (a) forbids a DOM handle in any atom, (c) finds out at run time. Viable only with cardume: `repository/cardume` does not exist (296, 136 step 0) and rakun / rakun-bpp (then jhonstart) have no request-local atoms yet; the check needs the hooks model to carry the `use`'s declaration argument (the atom `val`) — `HookUse.context` holds a declaration handle since 576 (7), but whether the argument of the `use` is among the handles is 277's `HookUse` gaining it (a 144 row if B-17 does not), else the island's read set is unknowable at build. Changes: 136 step 6 written for (b); 282 reads `#[clientOnly]` on a `val`.
- **Not viable (fable, 2026-10-12):** every option today — `repository/cardume` does not exist (136 step 0); the proposal binds 136 step 6 when it opens.
- **Measured.** The server seeds the values an island read into its payload (136 step 6); a value crossing must be encodable — after 306, a `#[validated]` type's `encode` member (`T.encode(v)`, 327; another library takes `T` only with `comptime compiler.typeInfo(T).meta(Validated)`, 606 (3) — before 606 `@typeInfo(T).meta(Validated)`), or one of the `T`s 294 accepts for a cookie (string, number, `bool`, enum, one-field record); some state is browser-only by nature (a DOM handle, a function).
- **Options.** (a) Every atom's `T` encodable, checked where the atom is declared. (b) Any `T`; an island's read set checked at build — a non-encodable atom an island reads must be declared client-only (`clientAtom(…)`, or 278's `#[clientOnly]` extended to declarations, 282). (c) Any `T`, refused only at run time.
- **Recommendation.** (b): restrictive where it matters (what crosses), free elsewhere.
- **Blocks.** 136 step 6.

#### atm-d · Which atom effects ship (*proposed*)
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): no atom effect in the first cut** — the store lands first; `persistLocal` / `syncSearchParam` are their own step after a measured need, one function per concern (281: a key is the declaration, never a string). Viable: nothing to build; cardume has no code yet (136). Changes: 136 step 8 deferred.
- **Not viable (fable, 2026-10-12):** (b) and (c) today — cardume has no code; the proposal is (a), nothing to build.
- **Measured.** Recoil's atom effects persist or sync an atom (localStorage, URL, a server push); none exists here.
- **Options.** (a) None in the first cut. (b) `persistLocal("cart")` only. (c) `persistLocal` and a search-param sync (`syncSearchParam("tab")`).
- **Recommendation.** (a): land the store first; effects as their own step after a measured need.
- **Blocks.** 136 step 8.

### 10-specs

#### 141-a · How a decision that retires a spelling keeps the specs from drifting (*proposed*)
- **Proposed (fable, 2026-10-12; narrowed 2026-10-18; awaiting the maintainer):** **(a): the decision's commit rewrites the retired spelling in `specs/<current>/**` and adds its row to 141's `inventory.md`; `scripts/land-check.py` (484 (4); 163 s12 landed) gains one check — a decision row that amends or replaces N is red while a spelling N retires is still written outside a closed milestone and the alias tables** — the drift is born in the decision's commit, so it is closed there; (b)'s allow-list excuses lines (67) and cannot tell a sentence that states a rule from one that names what it removes; (c) lets a front read the retired form for a milestone. Viable: no tool for (a)'s rewrite; `scripts/land-check.py` exists (`status.md` `[x] 163 s12`: not a fast-forward, a tracked `*.snap.new`, a scratch reference, a commit hash, an EN/PT pair whose ids or code blocks differ — each reason one line), so the check is a few lines more in it, reading the row's own words for the spelling it retires (the row names both forms, 141's inventory the files). Left: whether `land-check.py` gains that check, or the duty stays the writer's alone. Changes: 163 s3 (141 s6) writes the rule where the answer puts it.
- **Measured.** 354 retired `@Component<C, R>`; the compiler refuses it and 134's codemod rewrote the libraries (`01-compiler/134` step 6 boxes 1, 6), but about 280 spec lines in 71 files still write retired spellings (`10-specs/141-specs-sweep/inventory.md`, nine families), and 25 rows of `decisions-taken.md` still state the text an amendment replaced. Nothing ties a decision to the spec lines it retires; 575, 576, 606 and 641 since retired `.d.bp`, `@Decl` / `@Expr`, every `@name` builtin and the capitalised primitives — each a family the sweep measures the same way.
- **Options.** (a) The commit that writes such a decision also rewrites the class S lines of `specs/<current>/**` that write the old form, and adds its row to 141's `inventory.md` — a duty of whoever writes the decision; `land-check.py`'s check is the oracle at landing. (b) A meta CI check of its own: a list of retired spellings and the files allowed to name them, red on any other hit — a list that excuses lines, which decision 67's spirit refuses, and a check that cannot tell an S line from an R line. (c) Nothing: 141's sweep re-runs at each milestone close.
- **Examples.** A decision retiring `Context<T>()` for `createContext(value)` (379): (a) its commit also rewrites `08-bpp/119/README.md`'s `pub val StyledContext = Context<StyledSheet>();` to `comptime createContext(StyledSheet.missing())` and adds an F1 row to `inventory.md` — `grep -rn 'Context<StyledSheet>()' specs/1.0.12-beta` is empty when it lands, and `land-check.py` is red until it is; (b) `scripts/retired-spellings.txt` gains `Context<[A-Z][A-Za-z]*>\(\)` with `01-compiler/134/README.md` allowed, and the CI check turns red on the 119 line until someone rewrites it — and stays green on a box that names the form as what it removes only because that file is on the list; (c) the 119 line keeps `Context<StyledSheet>()` until the milestone closes, and a front opening 119 meanwhile reads the retired form.
- **Recommendation.** (a): the drift is born in the decision's commit, so it is closed there; (b) only if (a) is measured failing.
- **Blocks.** 163 s3 (141 step 6).

#### Overtaken by a later decision (front 141 step 5)

Listed for the maintainer, not closed here; each keeps its own entry and id.

| Id | Overtaken by | Closing recommended |
|---|---|---|

### From the maintainer's Portuguese record (`decisoes-pendentes.md`)

#### 07-i (revision) · Whether 163's ban on repeated names in bundled packages survives 170's alias
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **(a): still banned — a new bundled package picks a name std and the frameworks do not export** — 170's alias serves a program's own collisions, not the ecosystem's naming; one name for one thing across packages reads the same in every module (67), and `http`'s `cookie`, `actions`' `id.deriveActionId` already chose free names. Viable: nothing to build. Changes: 163's "until the toolchain line closes" becomes a standing rule; none in code.
- **Measured.** 163 bans a bundled package exporting a name std or a framework exports "until the toolchain line closes"; 170 (an import naming its module is never ambiguous; alias when both are needed) closes it.
- **Options.** (a) Still banned: a new bundled package picks a non-colliding name (`http`'s `cookie` module, `actions`' `id.deriveActionId`). (b) Ban lifted: natural names, importers alias.
- **Recommendation.** (a).
- **Blocks.** Nothing; 102, 103 and 104 already chose free names.

### 20-snap

### Ownership

### Contradictions that block no 00–03 step

#### ctr-l · Decision 186's third refusal against decision 202
- **Proposed (fable, 2026-10-12; awaiting the maintainer):** **Drop 186's third refusal** — under 202 no page declares itself prerendered, so "a `#[serverOnly]` hook in a page that declares itself prerendered" has no case: `#[page]` refuses a `#[serverOnly]` hook inside a `#[client]` component and a `#[clientOnly]` hook outside one, and renders per request a page whose hooks reach `#[serverOnly]` (186, 202, 277). Viable: 26's context already lists the two refusals only (`machine-1/150-rakun/26-jhonstart-router/context.md`). Changes: 186's row loses its third refusal; the entry's `README.md:58-59,182-183` is that context file.
- **Rules.** 186 refuses "a `#[serverOnly]` hook in a page that declares itself prerendered (`08-g`)". 202: "No declaration … no `pub val prerender` … no way to force". A page is `pub fn blog() -> View` reading `use cookie(sessionCookie)` (293, 294): rendered per request, no error.
- **Recommendation.** Drop 186's third refusal: under 202 no page declares itself prerendered. `05-jhonstart/26` step 8 already lists the two refusals only (`README.md:58-59,182-183`); only 186's row is pending.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-v · Decision 189 (org-3) against emilia's fronts opening before 118
- **Proposed (fable, 2026-10-12; re-read 2026-10-18; awaiting the maintainer):** **Record it: a comments-only carve-out is taken by the owning step; 118's residue keeps the code lines** — org-3 sequences code carve-outs between fronts, and rakun-stylesheet's bracket lines (then emilia's) are comments (today only in its `AGENTS.md`, `README.md`, `conformance/docs.md` and a cell's comment: `attributes.bp` / `emilia.bp` hold none, and `emilia-card` no longer exists). Viable: nothing to build. Changes: 189's org-3 row gains the sentence, if anything is left — see Measured; the entry's file lines are stale.
- **Rules.** org-3: 118's carve-outs land before the owning front opens. Since 165 s8 (and 165's table: emilia is the package `rakun-stylesheet`) 118 and 33 / 34 are steps of one front — 118's residue is 150 s39, 34's steps 150 s52 … s54 (`steps-emilia.md`; 33 s2 is done), all in lane "style / bpp / stylesheet" of one repository, `rakun`; the `[class]={…}` lines (then `attributes.bp:30,32,36`, `emilia.bp:185,202`) and `emilia-card/src/main.bp:5`'s `[emilia]={…}` were comments only, reworded by those steps.
- **Measured (2026-10-18).** Doubt: org-3 orders two fronts, and 118, 33 and 34 are no longer fronts but steps of 150 in one lane, ordered by 150's own text (`steps-jhonstart.md` § Order: "26 → 27 → 67 → 118's residue → 119's jhonstart half → …"; `steps-emilia.md` § Depends on); the contradiction may therefore be closed — nothing of org-3 sequences steps of one front — and what would remain is the record alone (189's row). Rows 575–659 do not say so; the maintainer closes it or keeps the record.
- **Recommendation.** Record that a comments-only carve-out is taken by the owning step; 118's residue (150 s39) keeps the code lines (its own tests, rakun-stylesheet's bridge test (then `jhonstart-emilia`'s), `document-shell`). The steps already follow it (118 § Does not touch, 150 s52, `fronts.md:49`); only org-3's row is pending — or closed, if the doubt above holds.
- **Blocks.** Nothing in the fronts; the record.

#### ctr-w · Front 09's Elasticsearch arm against decision 185
- **Proposed (fable, 2026-10-12; respelled 2026-10-18; awaiting the maintainer):** **The Elasticsearch arm reaches HTTP through a core extension point (185), never a `rakun-data → rakun-restclient` edge; answered with `03r-ab`'s arm list** — `rakun-data` depends on `rakun` and `query` only (165's table) and no arm exists, so nothing is undone. Viable: the core's registry pattern (`rkOnReset`; `03r-an`'s transport registry), or std's `io/http` directly (`fetch(req: Request)`, 623), as 65's relay does. Changes: 150 s17 step 3 written against it.
- **Rules.** 185: an optional capability goes through a core extension point, "no member-to-member edge". `04-rakun/09` § Open point (now 150 s17): the Elasticsearch arm over `rakun-restclient` (then `rakun-client`) adds a `rakun-data → rakun-restclient` edge every data consumer loads.
- **Recommendation.** The arm reaches HTTP via a core extension point (or `io/http` directly, as 65's relay does), not a `rakun-restclient` edge; answered with `03r-ab`'s arm list.
- **Blocks.** 150 s17 step 3.


#### ctr-x · Decision 337 (2), (3) against 592 (1): `mod m;` and `pub mod` after "no `mod` / `pub mod`"
- **Proposed (opus, 2026-10-18; awaiting the maintainer):** **337 (2) and (3) are overtaken by 592 (1); 337 keeps (1) and (4).**
- **Rules.** 337 (2): `mod config;` and `pub mod config;` bind `config` as a namespace in the module that declares them; (3): a folder's `mod.bp` exposes a submodule's function by `pub val`, the submodule kept private. 592 (1): every `.bp` under `src/` is a module of the package, its path its name; no `lib.bp`, no `mod` / `pub mod`. Both rows are in force in the ledger. Front 166 s3 (yaml) wrote 337's decision cell as the (1) refusal only.
- **Recommendation.** Amend 337 to its (1) `shorthand-import` refusal and its (4) migration; (2) and (3) "Overtaken by 592 (1)".
- **Blocks.** The decision cells of 337 in every repository it binds (166 s3).
---

#### ctr-af · Decision 105 against 553 (3): the spelling of a collection loop
- **Rules.** 105 (2026-09-24) wrote the collection loop as a trailing lambda, `for (xs) { x -> … }`. 553 (3) (2026-10-15) consumes an iterator with `for x in try xs` / `for await x in try xs`, and the subject file's loops sentence (105) omits the spelling.
- **Options.** (a) `for x in xs` (`for await x in xs`; `try` where the layer is a `Result`), 553 (3)'s form, 105's trailing-lambda spelling gone; (b) 105's `for (xs) { x -> … }` stays as a second spelling.
- **Recommendation.** (a) — one spelling, the later decision's.

#### ctr-ag · Decision 54 against 602: a `?T` matched by a binder arm
- **Rules.** 54 (2026-09-18): a `?T` is matched by `null` and a binder, `case x { null { … } v { … } }`. 602 (2026-10-17) with B-22: a name alone is never a pattern — `case-bare-name-arm`, in every arm shape.
- **Options.** (a) 602 whole: the non-null arm is `_` (or a typed pattern), the value read narrowed as `x!`; 54's binder arm gone; (b) 54's binder arm stays as the one exception, for `?T` alone.
- **Recommendation.** (a) — one rule for every arm.

## Part 3 — Implementation choices of tracks 04–09

### 04-rakun (21)

| Id | Choice implemented | Where |
|---|---|---|
| 03r-a | Every rakun manifest is `["erlang"]`; a built erlang program ships and loads its `.erl` sidecars (ledger half moot under 153) | every member |
| 03r-c | Front 05's readers stay botopink (`config.bp`); no `rakun_config.erl`; under 299 they feed the `#[config]` records | 04 |
| 03r-e | A cookie or query component std refuses, or that would decode to a control character, stays as written (`decodeComponent`) (`ctr-p`) | 04 |
| 03r-f | A cache key is `namespace + ":" + hash.strongCacheKey(parts)` | 12 |
| 03r-g | A private-scope read with no session runs the loader, stores nothing | 12 |
| 03r-h | A twin's key is `[method, args…]`; `#[cacheEvict(name, false)]` evicts it under every `#[cacheable(name)]` reader | 12 |
| 03r-i | Redis cache provider reuses rakun-session's RESP wire (`rkSessRedis`); `revalidateTag` deletes; unreachable Redis runs the loader uncached (health DOWN) | 12 |
| 03r-j | Outside a request `revalidateTag` / `revalidatePath` legal, `updateTag` raises; global `rakun.cache.type=none` disables every cache whatever its own type | 12 |
| 03r-k | Every messaging arm runs on the in-process broker (`transport=memory`); a real address without it refuses the boot naming the driver | 15 |
| 03r-l | A listener container is named after its destination (`#[amqpListener("orders")]` → `rakun.messaging.listener.orders.*`, `#[streamListener("audit-stream", "@next")]` → `listener.audit-stream.*`); Redis defaults to ack-mode `none` (explicit `auto` / `manual` on Redis refuses the boot). Key spellings follow 299 (`ackMode` or `#[key("ack-mode")]`) | 15 · `markers.bp:90,103` · `container.bp:125` |
| 03r-m | Inside a server action `revalidatePath` / `revalidateTag` expire at once; outside, stale-then-fresh | 12 · 22 |
| 03r-n | A JSON-RPC argument is a form-encoded field list, read in order into one form | 22 |
| 03r-p | A slot belongs to the nearest layout at or above its shortest entry; a conflict is two pages of one slot at one URL | 22 |
| 03r-r | Starters name sibling members `{ "workspace": true }` | 73 |
| 03r-s | OTLP pushed as HTTP/JSON (`json:encode` in `rakun_metrics.erl`) | 17 |
| 03r-t | Front 76's keys under `rakun.management.*`, in one `management.bp` plus the `rakun_probes` sidecar | 11 |
| 03r-u | Liveness group admits only `livenessState`, `ping`, `diskSpace`; any other name refuses the boot | 11 |
| 03r-v | Typed query builder's operator is the enum `Op` (`Eq`, `Ne`, `Lt`, `Gt`, `Le`, `Ge`, `Like`): `queryOf(City.entityMeta()).where(City.columns().state, Op.Eq, "CA")`; the column as `compiler.Field<City>` (308) is a separate question | 08 · `orm/query.bp:84-115` |
| 03r-w | OAuth2's explicit endpoints are `OAuth2Provider` fields (`authorizationUri`, `tokenUri`, `userinfoUri`, `jwksUri`); client credentials are `withClientToken(id, call)`, retrying once on 401 | 79 · 13 |
| 03r-x | Outbox relay claims by conditional `UPDATE` (a crashed relay's claims return via `reclaimStale`); saga and 2PC coordinators persist every transition and resume at boot (`resumeSagas`, `recover2pc`); job store claims triggers and takes over leases the same way | 15 |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-a:** confirm the erlang-only rule; under 512 (3) the 27 member, 8 starter and 3 example manifests repeating `"targets": ["erlang"]` drop it (the workspace declares it once) — with `95-b`, 150's manifest sweep.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-c:** confirm (`rakun/src/config.bp`, no `rakun_config.erl`); 299's `#[config]` records are not built yet (`#[configurationProperties]` and `rkProp*` remain) — rakun 04 s7.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-e:** reversed by `ctr-p`: nothing stays "as written"; `decodeComponent` goes with the readers 196 deletes.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-f:** confirm (`rakun-cache/src/cache.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-g:** confirm (`cache.bp`: a private row without a session runs the loader, stores nothing).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-h:** confirm (`cache.bp` `cacheMethod`, `cacheEvictAll`, `cacheEvictKeys`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-i:** confirm; the Redis wire is still `rakun-session`'s `rkSessRedis` imported by `rakun-cache` — a member-to-member edge 185 moves into the core when a front touches it.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-j:** confirm (`cache.bp`: `rakun.cache.type=none` beats every cache; `updateTag` outside an action panics).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-k:** confirm (`rakun-messaging/src/container.bp` accepts `memory` only, refuses naming the driver).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-l:** amend under 318 (5): one listener, `#[listen(orders)]` on a method of a `#[component]`, the destination declared once and typed (`pub val orders = Destination<OrderPlaced>("order-events")`), the container named after that destination (`rakun.messaging.listener.<destination>.*`), Redis's ack mode `none` enforced, the keys read through 299's typed config (`ackMode` / `#[key("ack-mode")]`); on feat `markers.bp` still declares `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`, `#[streamListener]`, `#[listener]` and reads `rkProp(listenerKey(…))` — 15's step for 318.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-m:** confirm (`cache.bp`'s action-phase text).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-n:** confirm (`rakun-app/src/actions.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-p:** confirm (`rakun-app/src/file_router.bp`, `slotOf`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-r:** confirm (`starters/rakun-starter/botopink.json` `"workspace": true`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-s:** confirm (`rakun_metrics.erl` `otlp_*_json`, `json:encode`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-t:** confirm (`rakun-actuator/src/management.bp`, `rakun_probes.erl`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-u:** confirm (`management.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-v:** confirm as the state on feat (`rakun-data/src/orm/query.bp` `Op`, `queryOf`, `City.columns()`); superseded in direction by 312 / 397 / 398: the typed builder leaves rakun-data when erika's `self.db.query "…"` and dbcontext land (137, 143), one query language — the `compiler.Field<City>` column question (308) is moot then.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-w:** confirm (`rakun-security/src/oauth2/provider.bp`; `client_credentials.bp` `withClientToken`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 03r-x:** confirm (`tx/outbox.bp` `reclaimStale`, `saga.bp` `resumeSagas`, `twopc.bp` `recover2pc`).

### 05-jhonstart (9)

| Id | Choice implemented | Where |
|---|---|---|
| 26-a (jhonstart) | Every router cell dual-target (a `router_runtime.mjs` twin). Id shared with 01-compiler's `26-a`, decision 242 | core |
| 29-a | What 281 leaves: the island starter table is the registry's `globals.starters`, filled per route by `registerRouteStarters(pattern, load)` (a route pattern is a URL, a string under 281); a second loader for one route fails. The per-name `registerStarter(name, start)` goes — 281 builds the starter table at comptime (`@TypeInfo.all(with: client)`, 120 step 6, 53 step 7) | core · 26 step 5 (its `docs.md` row still names `registerStarter`) |
| 30-b | `RenderPlugin` is a record of async functions; `payload` answers `Array<#(key, json)>`; `chunk(id)` runs in the boundary's own process | `streaming.bp` |
| 30-c | `render` / `renderStream` / `App` in `streaming.bp`; `compose` takes the page as a thunk, runs the layouts first — `compose(chain, { -> Page() })`; today's `route: PageContext` parameter goes with 293, the page is `fn() -> View` (276) | `streaming.bp` · `render.bp:341` |
| 30-d | `Suspense(Boundary(id, fallback, child))` registers its boundary with the render via one host cell; the page returns only the tree (`-> View`) | `suspense.bp:19-34` |
| 30-e | The segment record is `UiSegment` | core |
| 30-f | `app(…, lang = "en")`: one checked language per app. The check becomes decision 180's BCP 47 subset once 105 replaces `isLangTag` with `i18n.wellFormedTag`; a per-request `PageInput.lang` from rakun-app's existing `htmlLang()` stays additive | core · `streaming.bp:197-204` · 105 |
| 30-g | Browser half asserted in the commonJS-only member `jhonstart-dom-test` over `fake_dom.mjs` | `jhonstart-dom-test` |
| 31-a | `notFound()` / `redirect(url)` raise via one host cell (`__jhRaise`); a boundary captures via `__jhCapture`; `notFoundReason()` / `redirectReason(url)` answer the reason without raising. They declare `-> string` until `noreturn` fits a value position — waits on nat-d6 and lg2-l (if nat-d6 is (a), they become `-> noreturn`) | core · `error_boundary.bp:118-187` |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 26-a (jhonstart):** confirm (`router_runtime.mjs` beside `router.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 29-a:** confirm the reduced choice (`registerRouteStarters` + `globals.starters`); the per-name `registerStarter` is still declared in `client.bp` — it goes with 281's comptime starter table (26 step 5, 120 step 6), a 149 row.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-b:** confirm (`plugin.bp` `RenderPlugin`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-c:** confirm the thunk (`render.bp` `compose(chain, route: PageContext, page: fn() -> @Component<Element>)`); the `route: PageContext` parameter is still there — it leaves with 293 (26 step 11), when the signature becomes `compose(chain, { -> Page() })`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-d:** confirm (`suspense.bp` `Boundary`, `__jhPushBoundary`); its `child: fn() -> @Component<Element>` becomes `@Component<Element>` under 504 / lg2-n.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-e:** confirm (`routes.bp` `UiSegment`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-f:** confirm (`streaming.bp` `app(…, lang = "en")`, `isLangTag`; 105's `i18n` repository does not exist yet).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 30-g:** confirm (`jhonstart-dom-test`, `fake_dom.mjs`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 31-a:** amend under `nat-d6` (a) and `lg2-l`: `notFound()` / `redirect(url)` become `-> noreturn`, raising a typed `NavOutcome`; `notFoundReason()` / `redirectReason(url)` stay; `isSignalReason` goes.

### 06-emilia (9)

| Id | Choice implemented | Where |
|---|---|---|
| 05emilia-a | Filter reader is upstream's inline chain (`filterChain()`, `backdropFilterChain()`), not `var(--tw-filter)` | 42 |
| 05emilia-b | The backdrop section is `BackdropFilter` | 42 |
| 05emilia-c | `drop-shadow-none` follows upstream (`--tw-drop-shadow: ` and the reader) | 42 |
| 05emilia-d | Snap strictness is the fallback `var(--tw-scroll-snap-strictness, proximity)` | 46 |
| 05emilia-f | `--inset-shadow-*` entries drop upstream's leading `inset` | 41 |
| 05emilia-g | `space-*` / `divide-*` follow upstream's selector and reverse-aware margins | 35 · 40 |
| 05emilia-i | `--tw-*` transform variables are `@property` blocks with upstream's `properties` layer — `translate-*`, `skew-*` and `scale-*` (`--tw-scale-*`) alike | 45 · 54 · 56 |
| 05emilia-j | A selector-list modifier (`marker:`, `selection:`) is a list of one-`&` variants | 34 · 56 |
| 05emilia-k | Negative half step is `spacingNegHalf(n)`; `spacingHalf` refuses a negative `n` | 54 |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-a:** confirm (`emilia.bp` `filterChain`, `backdropFilterChain`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-b:** confirm (`BackdropFilter` in `emilia.bp`, `tokens.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-c:** confirm (`emilia.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-d:** confirm (`tokens.bp` / `emilia.bp` `--tw-scroll-snap-strictness`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-f:** confirm (`theme.bp` `--inset-shadow-*`; the leading-`inset` detail not re-verified).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-g:** confirm (`emilia.bp` `space-*` / `divide-*`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-i:** confirm (`@property` blocks in `emilia.bp`, `tokens.bp`, `output.bp`; the layer name not re-read).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-j:** confirm (`emilia.bp` `selectionVariants`, `tokens.bp` `Selection`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 05emilia-k:** confirm (`spacing.bp` `spacingNegHalf`; `spacingHalf` refuses a negative `n`).

### 07-onze (9)

| Id | Choice implemented | Where |
|---|---|---|
| 49-a | The core's suites render via its own `describe*` over `snapshots.assertAs`; `onze-test`'s helpers are thin wrappers | onze core |
| 49-c | `onze.json` refuses an unknown key, a duplicate, a wrong kind, a port outside `1..65535`, a non-string `allowedRedirects` entry | `config.bp` |
| 49-e | The rakun half of the boot is the erlang member `onze-server` | 49 step 2 |
| 50-a | `onze build` stages a server main, compiles it to BEAM; `onze start` runs it with `erl` — as amended: `start` calls front 71's `bin/onze` once it exists | 50 · 71 step 2 |
| 52-a | Font-metrics table has five transcribed rows; its generator is owed | 51 step 4 |
| 53-a | The blog's sources under `src/` (`appDir: "src/app"`) | 53 |
| 68-a | A client-manifest field escapes `%`, `\|`, LF and CR only | bundler |
| 68-d | The styleMap is evaluated by a probe compiled into both packages (`emilia-hash-split`, `emilia-unevaluated`) — moot once 34 step 1 and 119 step 4 land (301: `#[styled]` tokens are comptime, the class and rule computed at build over std's `contentHash`); holds until then | bundler |
| 69-a | onze-assets keeps `AssetRoot`; onze-server converts it to rakun-web's `StaticRoot` | assets · server |

- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 49-a:** confirm the own `describe*`; amend the engine: the suites write through `snap`'s `assertAs` (391; `import {assertAs} from "snap"`, a git dependency in `onze/botopink.json`), not std's `snapshots`.
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 49-c:** confirm (`onze/src/config.bp`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 49-e:** confirm (`onze-server`, erlang).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 50-a:** confirm (`onze-cli/src/start.bp` runs `erl -noshell …`; `bin/onze` waits on 71).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 52-a:** confirm (`onze-assets/src/font_metrics.bp`, five rows; the generator owed).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 53-a:** confirm (`examples/blog/onze.json` `appDir: "src/app"`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 68-a:** confirm (`onze-bundler/src/manifest.bp` `escapeField`).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 68-d:** confirm until 34 s1 / 119 s4 land (the probe and its snapshot still exist).
- **Proposed (fable, 2026-10-12; awaiting the maintainer) — 69-a:** confirm (`onze-assets/src/assets.bp` `AssetRoot`; `onze-server/src/server.bp` `staticRootOf`).
