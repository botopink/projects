# Decisions the maintainer owes — 1.0.12-beta

**74 questions and 15 contradictions are open, and 97 implementation choices await confirmation.**

- An answer goes into [`decisions-taken.md`](./decisions-taken.md) under the next free number (kept
  there only); a lettered id is never renumbered or reused.
- Every recommendation is the most restrictive reading, no configuration bypassing it (decision 67).
- A front meeting a question it cannot answer from the code adds it here: id · title · Measured
  (observed, re-runnable) · Options · Recommendation · Blocks. *Proposed* = raised without an id.

Answered since 1.0.11 (removed): `02e-a` → 240 · `05w-c` → 259 · `05w-d` → 260 · `05w-e` → 261 ·
`05w-f` → 262 · `05w-g` → 263 · `gw-a` → 264 · `ck2-c` → 244 · `dec-e` → 254 · `lg2-k` → 216 ·
`08-b` → 203 · `08-e` → 224 · `07-n` → 257 · `rc3-a` → 159 · `26-b` → 186 · `69-b` → 201 ·
`31-b` → 194. Moot (removed): `23-a`, `01std-d` (their option (b) landed), `95-d` (replaced by `95-f`).
Answered by the maintainer's local record: `ck4-a` → 266 · `134-a` → 267 · `134-b` → 268 · `134-c` → 269.
Answered since the consolidation: `ctr-a` → 271 · `08-e2`, `ctr-b` → 272 · `ctr-c` → 273 · `03r-ad`, `ctr-d` → 274 · `bpp-f`, `ctr-e` → 275 · `hooks-a` → 277 · `dir-1`…`dir-5` → 278 · `lg2-i`, `lg2-f` → 280 · `nat-a`, `nat-0` rule 1 → 281 · `nat-b`, `nat-0` rule 2 → 282 · `nat-0` rule 3 → 283 (case by case: `nat-d1`…`nat-d9`) · `nat-0` rule 4 → 284 (case by case: `nat-f1`…`nat-f4`) · `nat-f1` → 285 · `ctr-aa` → 287 · `ctr-f` → 288 · `ctr-g`, `ctr-t` → 289 · `ctr-x` → 290 · `ctr-y` → 291 · `ctr-z` → 292.
Merged: `01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b` → `snap-a`.

## Open questions

### Priority — the botopink shape (`nat-*`)

Raised 2026-10-04 by a sweep of the spec after decision 278: concepts copied from Astro, Next.js,
React, Spring, zod, TypeScript, LINQ and Tailwind in their foreign shape where botopink already has
the feature. `nat-0`'s four rules are decisions 281–284; what remains applies them case by case; the contradictions it found are answered (287, 290, 291, 292). The Portuguese page lists every site with examples.

#### nat-c · Untyped bags where a record type would flow
- **Measured.** `params` / `searchParams` / cookies as `Array<#(string, string)>`, `pairValue(jar, "session")` answering `""` when absent (26, 53) · `StaticPath.data: Json` read back through `pageData(route, schemaOf…)` (117) · `LocalKey<T>(name: string)`, a clash refused at run time (123) · `decl.setMeta("table", "cities")`, string-only meta (216, 130) · `#[value("rakun.profiles.active")]`, `rkPropInt("12abc") == 12` (03r-b), `Event(name: string, payload: string)` (rakun) · `ThemeEntry(name: string, value: string)`, `extendTheme(th, [#("--breakpoint-md", "")])` (06-emilia).
- **Options.** (a) Typed records: `PageContext<Params, Data>`, `use params<BlogPost>()`, `Cookie<SessionId>("session")` → `?SessionId`, `#[local] type CurrentUser(…)`, `decl.setMeta(Entity(table: "cities"))`, `#[config("rakun.data")] type DataConfig(…)`, events as records, `Theme(breakpoints: Breakpoints(…))`. (b) The bags stay, typed accessors generated beside them. (c) As is.
- **Recommendation.** (a).
- **Blocks.** bpp-g, 08-j, 117, 122, 123, 130 (meta), rakun 04, 08, 15; `06-emilia/34` (05emilia-n); 03r-b.

#### nat-d · A second model of what the language has — case by case (decision 283)
No general rule (283): each case below is its own question, (a) the language's own, (b) both — the foreign one a thin layer over the native — or (c) as is.

#### nat-d1 · `ActionOutcome {data, error}` beside `@Result` (127)
- **Measured.** `typed-action-example.bp`: an action answers `ActionOutcome<T>(data: ?T, error: ?ActionError)`; nothing stops reading `data` with `error` set.
- **Options.** (a) `-> @Task<@Result<T, ActionError>>`, `InputError` a case of `ActionError`. (b) `ActionOutcome` kept as a view over the `@Result`. (c) As is.
- **Recommendation.** (a).
- **Blocks.** 127 steps 1–4; `07-onze/53`'s action examples.

#### nat-d2 · A thrown store error and a `try*` twin per method (rakun 09, 93)
- **Measured.** `09-rakun-data-nosql/README.md:50` ("driver failures raise … each with a `try*` twin"); `stores-example.bp:125,146` `raiseProblem`; `soap-client-example.bp:66-68` `throw SoapFault` inside `-> @Result`.
- **Options.** (a) One API answering `@Result<…, StoreError>`. (b) The throwing form the default, the `try*` twin kept. (c) As is.
- **Recommendation.** (a).
- **Blocks.** rakun 09 (every store), 93; lg2-h.

#### nat-d3 · `Schema<T>` value objects beside the record type (125; 257)
- **Measured.** `125/README.md:57-94`: `schemas.object([#("email", schemas.text().email()), …])` beside `type Signup(email: string, …)`; 257 put `Schema<T>` in `validation`.
- **Options.** (a) The type is the schema: `#[schema] type Signup(…)`, `Signup.parse(json)`; `Schema<T>` only where no type exists (an ad-hoc check). (b) Both, `Schema<T>` derivable from a `#[schema]` type. (c) As is.
- **Recommendation.** (b) — the type first, the value form for what is not a declared type. Reads with 07-j and ctr-u.
- **Blocks.** 125 steps 3–10; 07-j; ctr-u.

#### nat-d4 · One combinator per arity: `union2…5`, `tuple2…5` (125)
- **Measured.** `125/README.md:73-94`; the families exist because TypeScript's zod needs them; botopink has `A | B`, `#(A, B)` and variadics (267).
- **Options.** (a) The type forms (`type Pet = Cat | Dog | Fish`) and, if a value form is kept, one variadic `union(..arms)`. (b) The families kept. (c) As is.
- **Recommendation.** (a).
- **Blocks.** 125 step 8.

#### nat-d5 · TypeScript's `Partial` / `Pick` / `Omit` beside type aliases (125, 134 step 2)
- **Measured.** `#[partial("RecipePatch")]`, `#[extending("Dog")]` (now typed by 281); `partial`, `pick`, `omit`, `mergeRecords` builtins (134 step 2).
- **Options.** (a) An alias over a builtin: `type RecipePatch = partial(Recipe)`. (b) The decorator on a written type (`#[partial(Recipe)] type RecipePatch(…)`), checked. (c) As is.
- **Recommendation.** (a) — one mechanism for derived types (110).
- **Blocks.** 125 step 9; 134 step 2.

#### nat-d6 · `throw "nav:not-found"` beside `noreturn` (53)
- **Measured.** `contracts.md:280-281` `isSignal` by prefix; `boundaries-example.bp:89-91`; `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Options.** (a) `fn notFound() -> noreturn`, boundaries matching the `NavOutcome` type. (b) The string signal kept under a typed wrapper. (c) As is.
- **Recommendation.** (a). With lg2-l and lg2-h.
- **Blocks.** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

#### nat-d7 · Lifecycle annotations beside interfaces (rakun 04)
- **Measured.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`.
- **Options.** (a) `implement Lifecycle { fn start(self); fn stop(self) }`. (b) Both. (c) As is.
- **Recommendation.** (a).
- **Blocks.** rakun 04.

#### nat-d8 · A `use…` hook name under `use` (53)
- **Measured.** `new-post-form-example.bp:118`: `use useActionState(…)`; jhonstart-forms spells it `actionState`.
- **Options.** (a) `use actionState(…)`; a hook named `use…` refused. (b) Both names. (c) As is.
- **Recommendation.** (a).
- **Blocks.** `07-onze/53`'s examples.

#### nat-d9 · LINQ's names in erika beside std's (98)
- **Measured.** `98-packaging-tail/README.md:47-51`; `erika.bp`: `where`, `select`, `selectMany`, `orderByDescending`, `toList`.
- **Options.** (a) std's names (`filter`, `map`), erika adding only what std lacks (laziness, `groupBy`). (b) LINQ's names — erika's identity is LINQ. (c) As is.
- **Recommendation.** none from this review: erika's purpose decides (b) is a fair reading.
- **Blocks.** 98 (erika).

#### nat-e · Spring's annotation zoo
- **Measured.** `#[service]`, `#[repository]`, `#[restController]`, `#[configuration]` + `#[bean]`, `#[managed]`, `#[provides]` stacked for one meaning (rakun 04, 09, 13, 19) · `findByNameAndStateAllIgnoringCase` parsed into SQL (08; R78-1) · `#[amqpListener]` / `#[kafkaListener]` / `#[redisListener]` with string destinations (15, 91) · `#[httpExchange]` wired through `#[configuration]` (13) · `MockMvc`, `@MockBean`, `UserDetailsService` (19, 79).
- **Options.** (a) One decorator per role that adds behaviour: `#[provides]` on functions, one `#[component]` on types (laziness an argument); queries as comptime expressions over `Columns` (`City.where(.state == s)`); `#[listen(destination)]`, the transport from typed config; rakun's own names. (b) Spring's names kept as aliases of (a). (c) As is.
- **Recommendation.** (a). Absorbs 130-c.
- **Blocks.** 130 step 5; rakun 04, 08, 13, 15, 19, 79, 91, 93; 130-b, 130-c.

#### nat-f · Configuration in JSON — case by case (decision 284)
`botopink.json` as clean as possible, configuration allowed where it makes sense (284); `"bpp": "<package>"` stays. Each case below is its own question.

#### nat-f2 · `onze.json`'s `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h)
- **Measured.** The keys restate options onze's code already types (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`); a misspelt value is seen when the server boots.
- **Options.** (a) Kept in `onze.json`, read into the typed record at build, a wrong key or value an error at its line in the file. (b) A typed record in the app's code (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), no JSON. (c) As is.
- **Recommendation.** (a) — configuration is allowed there (284); the build checks it as code would.
- **Blocks.** 124; 08-h; `07-onze/49`, `50`.

#### nat-f3 · `files` and `workspaces` in `botopink.json` (98)
- **Measured.** `files` lists what a package ships (npm's); `workspaces` / `{ "workspace": true }` list members (`98-packaging-tail/README.md:27`, `docs/botopink-json.md:52`).
- **Options.** (a) Both kept — packaging, not code. (b) `files` derived from `pub` modules (an internal module marked in code, `#![internal]`, lg2-m); `workspaces` kept. (c) Both derived.
- **Recommendation.** (a): what ships is a packaging fact.
- **Blocks.** 98.

#### nat-f4 · The `ONZE_PUBLIC_` prefix on environment variables (53, `contracts.md`)
- **Measured.** A variable reaches client code only when its name starts with `ONZE_PUBLIC_` (Next's `NEXT_PUBLIC_`); a stage fact (186) carried by a naming convention.
- **Options.** (a) Kept. (b) The declaration says it: `#[clientVisible] val apiUrl = env("API_URL")`, reaching it from a `#[client]` component checked at comptime (186). (c) A list of public variables in `onze.json`.
- **Recommendation.** (b).
- **Blocks.** `07-onze/50`, `53`; `contracts.md`.

#### nat-g · Foreign syntax inside an annotation
- **Measured.** `#[@BeamMemory.Ets(keyed = true)]`, `inline = true` — Rust's `key = value` (17) · `#[@External.Erlang("fn:tanBody")]`, `"op:…"`, `"wasi:…"` — a function named by a prefixed string (238, 263).
- **Options.** (a) botopink's labels (`keyed: true`) and a typed target (`External.Erlang(fn: "tanBody")` or an enum of kinds). (b) As is.
- **Recommendation.** (a).
- **Blocks.** 17 (with 17-b, 17-c); the backends' host cells.

### 01-compiler — the language

Each `lg2-*` is a [`language-gaps.md`](./language-gaps.md) row for a missing feature; option (1)
keeps it out, making the row's nearest form the design. No front opens on one until answered; the
owning front lists the row under *Depends on*.

#### lg2-a · A byte type
- **Measured.** No primitive, std type or literal holds bytes (`val b: Bytes = "a";` mismatches everywhere); every host cell marshals via `string`.
- **Options.** (1) None: a binary payload refused where it enters. (2) A `Bytes` primitive with an explicit, fallible boundary (`Bytes.fromUtf8`, `toUtf8 -> @Result`), no implicit conversion. (3) `string` also carries raw bytes.
- **Recommendation.** (1). Cost: every upload, download, image endpoint; under (2) no conversion without a fallible call; (3) stays refused (how `Socket.recv` mangles UTF-8 today).
- **Blocks.** The row; rakun 01, 13, 15, 24, 25, 70, 71; `03r-ab`.

#### lg2-b · What `@Task<T>` means on the BEAM
- **Measured.** On erlang and beam a Task body runs to completion where created: two `async.delay(300, …)` created before either is awaited take ≥ 600 ms (under 600 ms on commonJS).
- **Options.** (1) A Task promises the value, nothing about when its body runs; concurrency = `std/async`'s explicit process per unstarted thunk, documented. (2) A scheduler behind `@Task` on the BEAM (a process per Task, `await` a receive). (3) `spawn` / `join` in the language.
- **Recommendation.** (1) — the restrictive reading of 1.0.10's 120.
- **Blocks.** The row; rakun 02, 23, 25, 28, 30, 60.

#### lg2-c · A decorator that rewrites or wraps the body it annotates
- **Measured.** A decorator reads its declaration as `@Decl` data, answers only decision 216's outputs (members, meta, associated types, catalogue entries); no form returns a replacement body.
- **Options.** (1) None: a decorator adds beside its target (members, proxies, combinators), never changes what it does. (2) A form receiving the body and returning its replacement. (3) Fixed before / after / around hooks the compiler composes.
- **Recommendation.** (1).
- **Blocks.** The row; rakun 06, 07, 08, 10, 12, 16, 83.

#### lg2-d · A decorator that reads the body it annotates
- **Measured.** `decl.body` is `{error,{badkey,body}}` at the annotation; the handle carries kind, name, fields, variants, methods, return type, annotations.
- **Options.** (1) No statement access. (2) A read-only statement tree on `@Decl`. (3) A body-walking comptime API.
- **Recommendation.** (1); rakun 83's saga stays a value pairing each step with its compensation.
- **Blocks.** The row; rakun 83.

#### lg2-e · A method-level `@Decl`'s owner and parameters
- **Measured.** `decl.owner` / `decl.params` on a method-level decorator are `badkey`; only a type-level handle lists its methods' parameters.
- **Options.** (1) Method-level markers stay placement-only; the type-level decorator reads its methods. (2) `owner` and `params` on a method-level `@Decl`.
- **Recommendation.** (1).
- **Blocks.** The row (marker in `08-bpp/127`'s `typed-action-example.bp`); rakun 06–10, 29.

#### lg2-g · `@typeName<T>()`
- **Measured.** `@typeName<User>()` does not parse; explicit type arguments parse at every call (1.0.10's 8 §1.3, 255) — only the intrinsic is missing.
- **Options.** (1) None: a registry key travels as a string beside `T` (254's `rkResolve<T>(name)`). (2) A comptime `@typeName<T>()` answering the declared name.
- **Recommendation.** (1).
- **Blocks.** The row; rakun 06.

#### lg2-h · Raising and catching by type
- **Measured.** `try load(p) catch { e: NotFound -> … }` does not parse; a `@Result<T, E>`'s error is typed by `E`, read with `case` in the `catch` body; a host exception is not an `E`.
- **Options.** (1) An error is a `@Result`'s `E` (1.0.10's 121): a typed error is an enum matched with `case`. (2) A `catch` arm per type. (3) Typed host exceptions.
- **Recommendation.** (1) — the row becomes documentation of 121.
- **Blocks.** The row; rakun 07, 31, 63.

#### lg2-j · Comptime state across decorator invocations
- **Measured.** A module-level `var` written by a decorator body is refused at the annotation; each invocation is its own module call.
- **Options.** (1) Each invocation independent. (2) Comptime mutable state scoped to one compilation.
- **Recommendation.** (1): a decorator's answer depends on its declaration alone; a catalogue is 256's entry-point registry.
- **Blocks.** The row; rakun 05.

#### lg2-l · Whether `noreturn` is a bottom type
- **Measured.** `fn notFound() -> noreturn { raise("…"); }` ends the path on commonJS and erlang, but `throw notFound();` in a `@Result` body and `val s: string = notFound();` mismatch → jhonstart's `notFound()` / `redirect()` declare `-> string`. `@panic` / `@todo` are `noreturn`; a branch ending in a `noreturn` call already narrows — may be confirmed de facto.
- **Options.** (1) `noreturn` unifies with nothing: a call to it is a statement ending its path; the signals become `-> noreturn` called as statements. (2) `noreturn` is the bottom type, fits any position.
- **Recommendation.** (1).
- **Blocks.** The row; jhonstart's signals (63, `31-a`); rakun's navigation tests.

#### lg2-m · A module-level annotation
- **Measured.** `#![useCache]` at a module's top is "this token cannot appear here".
- **Options.** (1) None: a module-level policy is a module-level `val`. (2) An inner attribute `#![name(…)]` a decorator receives with the module's `@Decl`.
- **Recommendation.** (1).
- **Blocks.** The row; rakun 12.

#### lg2-n · A thunk coerced into `Node`
- **Measured.** `show({ -> "x" })` against `fn show(children: Children)` (`Node` under 223) mismatches.
- **Options.** (1) No thunk coercion: a deferred child is a named field of the boundary. (2) `fn() -> Element` coerces into `Node`.
- **Recommendation.** (1): compiler-known coercions stay three (array, `Element`, `string`).
- **Blocks.** The row; jhonstart 30.

#### lg2-o · Filesystem access from a comptime body
- **Measured.** `fs.readText("schema.txt")` in a decorator body refused at the annotation.
- **Options.** (1) None: generated `.bp` is checked in (`rakun ws generate`). (2) A sandboxed read of declared build inputs, keyed into the build cache.
- **Recommendation.** (1): a build reads only its sources.
- **Blocks.** The row; rakun 88, 93.

#### lg2-p · Cancellation
- **Measured.** `std/async` has no cancel handle; a losing racer and an expired timeout run to completion.
- **Options.** (1) None: losing work completes, result discarded, documented. (2) Explicit cancellation tokens. (3) Linked processes with a kill path on the BEAM.
- **Recommendation.** (1), in step with `lg2-b` (1).
- **Blocks.** The row; rakun 02.

#### lg2-q · `@Decl`'s source location
- **Measured.** `decl.loc.file` is `badkey` at the annotation.
- **Options.** (1) None: the app-relative segment is an explicit decorator argument. (2) A `loc` field on `@Decl` (`@src()`'s `SourceLocation`).
- **Recommendation.** (1): a decorator's output never depends on where its file sits.
- **Blocks.** The row; rakun 22.

#### lg2-r · A body a decorator supplies for a declared method
- **Measured.** A bodyless `declare fn` method with no `#[@External.<Target>]` is refused at the call on every target (`run/bodyless_method_without_binding`); no decorator can supply the body.
- **Options.** (1) A bodyless method is a host binding only; a `#[query]`-style decorator adds a member the method's body calls (216). (2) A decorator-supplied body for a declared method.
- **Recommendation.** (1).
- **Blocks.** The row; rakun 08, 09, 78.

#### lg2-s · Module-graph reflection
- **Measured.** `decl.imports` is `badkey` at the annotation.
- **Options.** (1) None: `importsOf` stays a textual scan that fails loudly. (2) An `imports` field on a module-level `@Decl`.
- **Recommendation.** (1); its old argument ("in step with `lg2-k`") fell with 216 — `ctr-m`.
- **Blocks.** The row; rakun 68.

#### lg2-t · A negative numeric enum leaf
- **Measured.** `type Tok { Rotate { 12, -12 } }` refused at the `-`.
- **Options.** (1) None: a `Neg { … }` sub-section is the convention (emilia 35, 40, 45). (2) A signed numeric leaf (`-12`, `.__N12` in expression position). (3) A unary `-` on an enum path.
- **Recommendation.** (1): a leaf name stays a name.
- **Blocks.** The row; emilia 35, 36, 45.

#### lg2-u · An expression-position decorator
- **Measured.** `val x = #[deco] 1;` refused (`loop-annotation-not-generator`).
- **Options.** (1) None: expression-level work is a call. (2) Expression-position decorators run in the eval script.
- **Recommendation.** (1).
- **Blocks.** The row; rakun 48.

#### lg2-v · A subdirectory in a git dependency
- **Measured.** `DepSpec` is `{git, path, ref, workspace}` (`modules/manifest/src/root.zig`); a package inside a repository is reachable by `path` only.
- **Options.** (1) None: a git dependency is a repository root; a monorepo member installs by `path`. (2) A `subdir` field on a git `DepSpec`, resolved by `bpmp`.
- **Recommendation.** (1). Cost: no `rakun-*` starter installs from git outside the meta checkout. Under (2) a `subdir` without `git`, or escaping the checkout (`..`), is refused.
- **Blocks.** The row; rakun 73; `02/98` step 4 (conditional); `07-h`'s argument.

#### lg2-w · A host function called from a decorator body
- **Measured.** `json.quote(…)` in a decorator refused as a method nothing provides; via `import {json.quote}` it is `call to undefined function quote/1` on both comptime runtimes; a project's own host `declare fn` fails the same — only bodied functions travel into the decorator module.
- **Options.** (1) A comptime body calls bodied functions only; a host call there refused at the call, located, naming the function, on every target. (2) The Erlang cell travels into the decorator module on the BEAM runtime, refused on wat. (3) Decorators reaching a host cell run on the BEAM runtime whatever the target.
- **Recommendation.** (1): the answer never depends on the runtime the target selected (1.0.10's 84).
- **Blocks.** The row; rakun 16 (`#[scheduled]`); every decorator that would reuse std.

#### 17-b · The per-row increment of a `keyed = true` `Dict`
- **Measured.** A row is written `counts = counts.insert(k, v)`; a row computed from the var's own rows is 1.0.10's 40 §5(b) refusal; `counts.at(k)` is a `?V`; `counts.at(k) += 1` / `counts[k] += 1` are not assignment targets.
- **Options.** (a) None: a keyed row written whole; a per-key counter refused; a counter several processes bump is one `#[@BeamMemory.Ets] var n: i32` each. (b) A std `Dict.bump(key, by) -> Dict<K, V>` (integer `V`, absent key counts from 0), lowered under `keyed = true` to `ets:update_counter(T, K, By, {K, 0})`. (c) An index assignment `counts[k] += 1` in the grammar.
- **Recommendation.** (a).
- **Blocks.** `17-beam-memory` step 1, fourth box.

#### 17-c · What else names a `keyed = true` var
- **Measured.** Built: only `counts.at(k)` (`ets:lookup`) and `counts = counts.insert(k, v)` (`ets:insert`); everything else (`counts[k]`, `hasKey`, `delete`, `size()`, passing it on) refused at the identifier; a keyed var is never `pub`. 1.0.10's 63 defines `d[k]` as `d.at(k)`, yet the index form is refused.
- **Options.** (a) The two forms, as built. (b) (a) plus `counts[k]`. (c) (b) plus `hasKey` (`ets:member`) and `delete` (`ets:delete`), each a new `std/beam` primitive.
- **Recommendation.** (a).
- **Blocks.** Nothing — the built surface stands until widened.

#### 134-d · `@is(…)` written by hand
- **Measured.** `x is T` parses as builtin call `is` carrying the tested type; the lexer also makes `@is(1)` that call with no tested type — checks as `bool`, lowers to nothing meaningful.
- **Options.** (a) Refuse `@is(…)` as a call (`unknown-builtin`, naming `x is T`). (b) Declare `is(value: unknown) -> bool`.
- **Recommendation.** (a).
- **Blocks.** The last undeclared builtin-call row of 134 step 1.

#### 130-b · Two `#[provides]` of one type in a registry keyed by type name (decisions 254, 256)
- **Measured.** 256's snippet keys a provider by `b.returnTypeName`. Two qualified providers of one type (`#[provides] #[qualifier("fast")] fn fastDye() -> Dye` beside `#[qualifier("slow")]`), and a `#[primary]` beside a plain one, collide on `"Dye"` → refused as a duplicate, where `__rkMake_Dye` let the unqualified or `#[primary]` one own the injection and kept the others reachable by `ctx.resolveNamed("Dye", "fast")` (`rakun/test/context_test.bp`, `examples/rakun-container`).
- **Options.** (a) A qualified provider is keyed `Type@qualifier` (the decorator records `setMeta("qualifier", …)`); the plain name is the unqualified or `#[primary]` one; two owners of the plain name are the duplicate (`d = d.insert(rkBeanKey(b), b.value)`). (b) The registry holds only what injection by type reads; qualified providers stay in the context table their load-time registration fills. (c) The snippet as written: any two providers of one type are a duplicate. (d) *Added under 281:* a qualifier is a distinct type (`type FastDye(dye: Dye)`, `#[provides] fn fastDye() -> FastDye`), so the registry is keyed by type alone; `#[qualifier("…")]` and `resolveNamed` go.
- **Recommendation.** (d) under decision 281 — (a)'s `Type@qualifier` keeps a string beside the type; (a) if a string label is wanted after all.
- **Blocks.** rakun's `#[provides]` / `#[qualifier]` / `#[primary]` migration (130 step 5: `context.bp`, its test, rakun-container).

#### 130-c · A `#[configuration]`'s `#[bean]` methods in the registry (decision 234)
- **Measured.** 234 fills the context from `@TypeInfo.all(with: provides)` / the `#[bean]` methods, but `@TypeInfo.all` answers top-level declarations and a `#[bean]` is a method of a `#[configuration]` type. Today `#[configuration]` emits `__rkMake_<ReturnType>()` per `#[bean]` (rakun `autoconfig.bp`, `conditions.bp`, `config.bp`, rakun-client `settings.bp`, rakun-security `oauth2/provider.bp`, `examples/rakun`).
- **Options.** (a) `#[bean]` methods become `#[provides]` free functions (the configuration record keeps its `#[value]` fields; a provider reads them through `rkResolve`). (b) The configuration records each bean as meta and adds a member `Config.bean(name) -> unknown`; the entry adds a third loop. (c) `@TypeInfo.all` gains `methods: true`.
- **Recommendation.** (a): one way to provide a bean, already in the registry's loop, no new reflection.
- **Blocks.** rakun's `#[configuration]` migration and every `__rkMake_` a `#[bean]` defines (130 step 5).

#### imp-a · Two aliased imports of two same-named types (*proposed*)
- **Measured.** Decision 170 makes `import {m1.T as A}; import {m2.T as B};` legal; the checker refuses it for types (`import-name-collision`, `modules/import_two_types_one_name`) because backends do not tell types apart by module (`01-checker/README.md`, rows other fronts found).
- **Options.** (a) Types stay refused: 170's alias rule covers values only. (b) Backends qualify types by module; the form becomes legal.
- **Recommendation.** (b): 170 is the maintainer's rule, the refusal a backend limit, held as a `language-gaps.md` row until built.
- **Blocks.** Nothing open; a 01-checker row.

### 02-std-and-packaging

#### std-d · `io.process` signals and a TTY reader
- **Measured.** `io/process.bp` neither registers nor forwards a signal; std has no TTY line reader; `onze start` waits on `process.run` → `SIGTERM` leaves the node running; `onze create` without `--yes` has no prompt to fall back to.
- **Options.** (a) `process.onSignal(name, fn)`, `process.forwardSignals(child)`, `io.stdin.readLine()` — three host cells on two targets. (b) No std change: `onze start` execs the node (71's `bin/onze` is PID 1); `onze create` without `--yes` refused naming the flags it needs.
- **Recommendation.** (b).
- **Blocks.** onze 50 steps 4 and 7; 97 step 6 (conditional).

#### std-e · Test lifecycle hooks
- **Measured.** rakun-test's `resetSingletons` / `resetContext` called by hand in 40+ test bodies; jhonstart-dom-test installs its document the same way.
- **Options.** (a) None: a test body calls its reset helper. (b) `#[before]` / `#[after]` on a module-level fn the runner calls around every `test`. (c) `beforeEach { … }` blocks in the grammar.
- **Recommendation.** (a): nothing implicit runs around a test.
- **Blocks.** The `language-gaps.md` row "No test lifecycle hooks".

#### 95-f · The onze takeover — amend decision 79
- **Measured.** `repository/onze` is the orchestrator's workspace, built on tag `mocking-lib-final` in the same history and remote — not decision 79's orphan branch; nothing archived or renamed; the name resolves only to the orchestrator's members.
- **Options.** (1) Confirm the tree: a new decision amends 79 — the old library lives as the tagged history of the same repository. (2) Rewrite the remote to an orphan branch, archive the old history (every checkout re-clones).
- **Recommendation.** (1).
- **Blocks.** `02/98`'s record boxes (01-std step 5's four, 95 step 2's first two) close on (1).

### 03-bundled-libs

#### 07-b · Does "one library, three or more divergent copies" also justify a package?
- **Measured.** The cookie and q-value copies already qualify under 115's test (onze consumes them too).
- **Options.** (a) 115's "two or more libraries" stays the only test. (b) Add the divergence test.
- **Recommendation.** (a): a single-library duplicate goes to std or the owning library's core.
- **Blocks.** Nothing; the rule for the next candidate.

#### 07-g · OTP release rendering
- **Measured.** `rakun-release/release.bp` (into `rakun-cli` under 187) and `onze-release/otp.bp` render the same `.rel` / `vm.args` / `sys.config` / boot script / Dockerfile; onze cannot reuse rakun's (rakun erlang-only, onze-release also commonJS).
- **Options.** (a) A bundled `release` of pure renderers. (b) A `botopink` CLI feature (02). (c) Leave both.
- **Recommendation.** (a); the CLI may adopt the package later.
- **Blocks.** `107-release` (a conditional front: answer it or defer 107).

#### 07-h · Bundled, or a separate shared repository
- **Measured.** Wires both frameworks must agree on byte for byte ship with the compiler that embeds them; a separate repository = a git dependency, constrained by `lg2-v` (no `subdir`) and 242 (only a direct dependency importable).
- **Options.** (a) Bundled — versioned with the compiler, no `dependencies` entry. (b) A shared `botopink/common` repository with its own cadence.
- **Recommendation.** (a).
- **Blocks.** Nothing waits; the track is cut as (a).

#### 07-j · How much of Zod is front 125
- **Measured.** `125-validation-zod/surface.md`: 205 reference rows — 27 already the language or library, 151 buildable with existing decorator and reflection surface, 7 needing a compiler row, 18 meaningless here; steps 0–2 merged.
- **Options.** (a) The markers only (step 3). (b) Steps 0–3. (c) Every step.
- **Recommendation.** (c), landed in step order.
- **Blocks.** The size of 125 (steps 3–10).

### 04-rakun

#### 03r-ab · Front 09's binary-protocol stores
- **Measured.** MongoDB, Neo4j, Cassandra, Couchbase are byte protocols (`lg2-a`) needing OTP drivers a sidecar cannot load; ETS and Mnesia are in the VM; Redis is RESP over `gen_tcp`; Elasticsearch is HTTP + JSON over 13's client.
- **Options.** (a) 09 ships `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` with the behavior suite against all four in the gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` are recognised schemes whose boot refusal names `lg2-a` and the driver; steps 4 and 7's 12 boxes become the refusal cells plus one `deferred.md` row each. (b) Four protocol clients in Erlang sidecars, a front each. (c) Defer 09.
- **Recommendation.** (a): never a fallback to ETS under a Mongo URL.
- **Blocks.** 09 steps 4 and 7.

#### 03r-ae · SAML 2.0 ACS
- **Measured.** Verifying an IdP signature needs Exclusive XML Canonicalisation, which neither OTP's `xmerl` nor std provides; `saml2/saml2.bp` answers 501.
- **Options.** (a) exc-c14n over `xmerl`'s tree in `src/sidecars/rakun_saml2.erl` (~300 lines), the three boxes closed by a fixture signed with a checked-in key. (b) Retire the SP: the three boxes go, `saml2/` keeps 501 with a `deferred.md` row. (c) Leave them open.
- **Recommendation.** (a) if 79 is staffed this milestone, else (b); never (c).
- **Blocks.** 79 step 3.

#### 03r-af · The seven unbuilt example projects
- **Measured.** `examples/` holds `rakun`, `rakun-container`, `rakun-ssr` (gate cells); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` never started; every member's contract asserted by its own tests.
- **Options.** (a) Retire the seven (1.0.10 example list a closed record; the three on disk gain a `README.md` each). (b) Build them, one front each, after every member front. (c) Build `rest-service` only.
- **Recommendation.** (a).
- **Blocks.** 73 step 3.

#### 03r-ak · CycloneDX validation
- **Measured.** The box asks for validation against a checked-in CycloneDX 1.5 schema, no network; std has no JSON-schema validator; `sbom.bp` asserts required fields by name.
- **Options.** (a) `release_test.bp` walks the SBOM against the checked-in `bom-1.5.schema.json`'s `required` arrays and `type` keywords (local definitions only, ~120 lines). (b) Amend the box to the field-by-field list. (c) A `json.schema` in std.
- **Recommendation.** (a).
- **Blocks.** 81 step 3.

#### 03r-al · Kafka producer transactions against the in-process broker
- **Measured.** `rakun-messaging/src/reliability/transaction.bp` already provides `withProducerTransaction` with `read_committed` hold and drop, tested; 83's path choice held minus the broker; two boxes still read "with a Kafka broker" and "a consumer in `read_committed` mode".
- **Options.** (a) 83's Kafka path enrols in the existing producer transaction; boxes reworded to the broker double; real-broker run a `deferred.md` row. (b) Delete the two boxes. (c) Leave them open.
- **Recommendation.** (a).
- **Blocks.** 15 step 5.

#### 03r-am · Where the broker and scheduler doubles live
- **Measured.** `rakun-test` depends on `rakun` only; `rakun-messaging/test/*.bp` imports `rakun-test`; an edge `rakun-test → rakun-messaging` is a package cycle unless the loader honours test scope (not verified landed).
- **Options.** (a) Measure: add the edge; if `botopink test` refuses the cycle, the doubles live beside the module they double (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) and `rakun-test` documents them. (b) Take the edge, assuming the rule landed. (c) The doubles in `rakun-test`, reaching the registries only through core hooks (`rkOnReset`, the listener-names term).
- **Recommendation.** (a), with (c)'s shape either way.
- **Blocks.** 19 steps 3 and 4.

#### 03r-an · RSocket's WebSocket transport after decision 187 (*proposed*, raised as R92-1)
- **Measured.** R92-1 mounts the transport via `rakun-websocket`'s `#[wsEndpoint]`; after 187 RSocket lives in `rakun-messaging` → the edge would load `rakun-websocket`'s tree (security, data) for every messaging consumer; today the WebSocket transport is refused at boot (TCP only).
- **Options.** (a) Take the edge `rakun-messaging → rakun-websocket`. (b) The core defines a transport extension point `rakun-websocket` plugs into (185's rule). (c) Keep the refusal; WebSocket transport a `deferred.md` row.
- **Recommendation.** (b).
- **Blocks.** 92 step 2's first box.

#### 03r-ao · `01-compiler/130`'s rakun sites against 128 (*proposed*, raised by the 04-rakun consolidation)
- **Measured.** 130 step 5 (decision 216) still plans edits to files 128 moves or the rakun fronts own (core's `decorators.bp`, `autoconfig.bp`, `config.bp`, `context.bp`, `lifecycle.bp`, `conditions.bp`; `rakun-web/src/convention.bp`; `rakun-app`; `rakun-scheduling`; `rakun-messaging`; `rakun-cli`; `rakun-data`; `rakun-security`; `rakun-websocket`; `rakun-client`; `rakun-actuator-api`, which 128 moves into `modules/rakun/src/actuator_api/`); no decision orders them.
- **Options.** (a) 128 first and alone; 130's rakun sites re-pointed at post-128 paths; after 128 each is a consumer commit under 188 (never in a wave with the owning front); the frozen-files rule excepts 130's rewrite of `src/decorators.bp` ([`04-rakun/README.md`](./04-rakun/README.md) § Order). (b) 130's rakun sites before 128 opens. (c) 128 performs 130's rewrite of the files it moves.
- **Recommendation.** (a): 128 holds all of rakun, and (b) holds every rakun front on 130.
- **Blocks.** 128's opening; 130 step 5's rakun rows.

### 05-jhonstart

#### 67-a · Where the DOM-side forms boxes are asserted
- **Measured.** `fieldError` after `__jhFormState`, in-place re-render on `ok: false`, two forms' `pending`, optimistic commit / roll-back read `document` and `FormData`; `botopink test` has no DOM; `jhonstart-dom-test` (`fake_dom.mjs`, commonJS only) already serves the render's browser half.
- **Options.** (a) Extend `fake_dom.mjs` with `<form>`, `<input>`, `FormData`, `submit`; assert the five boxes (1.0.10's 3a, 3b, 4, 5) in `jhonstart-dom-test/test/forms_dom_test.bp` now, and again in onze 53's browser. (b) Only in onze 53's browser. (c) A real DOM library as a dev dependency.
- **Recommendation.** (a).
- **Blocks.** 67 steps 1–3 (written for (a)); onze 53's write path.

### 06-emilia

#### 05emilia-n · The unplaced Tailwind rows
- **Measured.** Five rows have no owner: named `:has()` / `:not()` / ARIA / data / `in-[…]` forms (reachable via `arbSel` only); named groups and peers; `@theme inline`; negative translate (`TranslateX/Y.Neg` absent); and a hole — a cleared `--breakpoint-*` emits `@media (width >= )` instead of refusing, as 58 refuses an emptied container size.
- **Options.** (a) The refusal only (a cleared breakpoint panics naming the entry); the four feature rows out of scope in `docs.md` § Deviations. (b) (a) plus negative translate and named groups / peers. (c) All five, `@theme inline` included (a second render mode).
- **Recommendation.** (a) — the refusal is decision 67, not optional; (b) is the feature answer if any is wanted.
- **Blocks.** 34 step 4 (conditional); step 3 (the refusal) is not conditional.

### 07-onze

#### 50-b · What `onze dev` does on a change
- **Measured.** `onze build` compiles the server to BEAM (`server/beam/`), `onze start` runs `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` computes invalidated modules; the BEAM can `code:load_file/1`; UI registry and route table fill at module load (decision 140): a reloaded page re-registers, a new route file needs `onze_routes.bp` regenerated and the table rebuilt.
- **Options.** (a) Restart the node on every change (`build` + `start` looped over a file watcher — same bytes as `start`, 1–3 s per edit). (b) Hot-load changed modules; regenerate and reload `onze_routes` when the app tree changes. (c) (b), falling back to (a) when a convention file changed. Browser island state lost either way (Fast Refresh a non-goal, `07-onze/reference-holes.md` § 29).
- **Recommendation.** (a): one code path, the same bytes `start` serves; (b) later, if (a) measures too slow on the blog.
- **Blocks.** 50 step 2; 53 step 5.

### 08-bpp

#### 08-d · Who scopes CSS
- **Measured.** emilia compiles `Token[]`, "not a CSS processor"; onze-assets renames `*.module.css` classes (`style_module.bp`); decision 113.
- **Options.** (a) emilia gains `scopeCss(scope, css)`, reached via `jhonstart-emilia`. (b) onze-assets, beside the module renamer. (c) jhonstart scopes its own `<style>`.
- **Recommendation.** (a): (c) puts a CSS parser in the HTML library; (b) leaves scoped styles unavailable without onze.
- **Blocks.** 119, every step — on the critical chain 118 → 119 → 120 → 126 → 127 → 124.

#### 08-f · Where Markdown and YAML live
- **Measured.** No Markdown code anywhere; one YAML-subset reader, in rakun's `config.bp`; `03-bundled-libs` sends config readers to std "when a second consumer appears".
- **Options.** (a) Both in a new member `onze-content`. (b) Markdown in `onze-content`; YAML in std as `yaml`, rakun's reader deleted by rakun's front. (c) A bundled `markdown` package.
- **Recommendation.** (b): frontmatter is YAML's second consumer; Markdown has one (115). Until std's `yaml` lands, 121 step 3 reads frontmatter with its own copy and deletes it then.
- **Blocks.** 121 step 3; a row for `02/97`.

#### 08-h · The config file and the commands
- **Measured.** `onze.json` exists, refuses unknown keys (`49-c`); `onze create | info | build | start` exist, `dev` is a stub; `botopink` has no framework command.
- **Options.** (a) `onze.json` and `onze <command>`. (b) A second file (`bpp.json`) and `botopink dev` / `preview`.
- **Recommendation.** (a): the compiler's CLI is not a framework's.
- **Blocks.** 124.

#### 08-j · How rakun's `local()` carries a jhonstart marker (*proposed*)
- **Measured.** 123's `local<T>(key)` is a request-time read → a page reading it renders per request (186); `#[serverOnly]` is jhonstart's marker; rakun and jhonstart never import each other (113); 123 step 1's third box is written for the bridge (`ChunkWriter.markDynamic`, `dynamicReason()` says `locals`), which 186 deletes once the checker capability lands.
- **Options.** (a) Stage markers move to a package both import (bundled `routing`, under 115's two-library test); both libraries mark with the same `#[serverOnly]`. (b) rakun declares its own marker; the capability reads markers by a manifest-declared name. (c) `local` readable only in middleware, handlers, actions, never from a page.
- **Recommendation.** (a): one marker, and no library names another.
- **Blocks.** 123 step 1's third box; any rakun request-time read a page reaches.

#### bpp-g · How a `page.bpp` gets its `route: PageContext` and its `params`
- **Measured.** 221 gives a `page.bpp` its decorator; the unfold answers `fn <Name>(props: Props)` or `fn <Name>()`; a `.bp` page takes `route: PageContext` and binds its segments with `paramsOf(…meta.page.seg, route)` (236); jhonstart's router calls a page with a `PageContext`, cannot build an application's `Props`.
- **Options.** (a) A `bppKinds` entry names the parameter too (`"page": {"decorator": "page", "parameter": "route: PageContext"}`): the unfold writes `pub default fn page(route: PageContext)`, the header reads `route`, the prelude brings `PageContext` and a `params(route)` helper (`ctr-g`: `page` then names both function and decorator). (b) The header declares `type Props(route: PageContext)`; the router requires that shape. (c) `#[page]`'s decorator output adds the parameter (01-compiler/130).
- **Since 285 and 289.** (a) is gone — no `bppKinds`, the toolchain knows only `"bpp"`, `html` and the prelude, and the default function is anonymous; (b) and (c) remain.
- **Recommendation.** (b): the page's parameter is ordinary header code (`type Props(route: PageContext<BlogParams, Post>)`), the router calls the function with it, the prelude brings `PageContext`.
- **Blocks.** 116 step 6; 117 step 1.

#### props-d · A native tag's attributes (*proposed*)
- **Measured.** 192 covers component tags only; a native tag is `fn <tag>(children: Children, attrs: Array<#(string, string)> = [])` in jhonstart (118 § Notes).
- **Options.** (a) A native tag's attributes = fields of a props type jhonstart declares per element (unknown attribute or wrong type refused, as 192). (b) Any attribute name, a `string` value or a 191 hole. (c) A global attribute set plus per-tag lists, `string` values.
- **Recommendation.** (a): one rule for every tag, the most restrictive.
- **Blocks.** 118 steps 1 and 4.

#### props-e · A named slot (*proposed*)
- **Measured.** 193 names the `children` field, no other; Astro writes `<p slot="footer">` / `<slot name="footer">` (118 § Notes).
- **Options.** (a) A named slot is a props field of type `Node`, written as an attribute (`footer={…}`); `slot="…"` refused. (b) `slot="footer"` on a child routes it to props field `footer`. (c) No named slots.
- **Recommendation.** (a): 192 already covers it, no second routing mechanism.
- **Blocks.** 118's slot boxes (steps 1 and 4).

#### props-f · A spread on a component (*proposed*)
- **Measured.** 118 step 1 refuses `{...expr}` on a component for a reason 192 removes (attributes are now one record's fields); 118 § Notes lists the props spread under "What is not added".
- **Options.** (a) Still refused: the attributes are the form. (b) `{...p}` with `p` of the props type, explicit attributes overriding.
- **Recommendation.** (a).
- **Blocks.** 118 step 1.

### From the maintainer's Portuguese record (`decisoes-pendentes.md`)

#### pkg-b · A package importing itself by name
- **Measured.** 206 is built (129): `from` names a package only. 12 test files import their own package by name (log 1, routing 1, validation 2, std 8), e.g. `libs/log/test/digest_test.bp`: `import {errorDigest} from "log";`.
- **Options.** (a) Legal: it is a package and `from` names packages. (b) Refused: inside the package it is `import {digest.errorDigest};`.
- **Recommendation.** (a): a package test reads the public surface as an outside user does.
- **Blocks.** Nothing (an item of `01-compiler/26` step 8).

#### 07-i (revision) · Whether 163's ban on repeated names in bundled packages survives 170's alias
- **Measured.** 163 bans a bundled package exporting a name std or a framework exports "until the toolchain line closes"; 170 (an import naming its module is never ambiguous; alias when both are needed) closes it.
- **Options.** (a) Still banned: a new bundled package picks a non-colliding name (`cookie`, `deriveActionId`). (b) Ban lifted: natural names, importers alias.
- **Recommendation.** (a).
- **Blocks.** Nothing; 102 and 103 already chose free names.

#### 110-a · `testing.asserts` on wasm under the strict rule (146)
- **Measured.** A wasm program importing `testing.asserts` is refused: 4 of its 27 functions reach host cells with no wasm binding (`deepEquals → canonical`, `matches → regexMatches`, `throws`/`throwsWith → tryCatch`); uses: throwsWith 280, throws 4, deepEquals 2, matches 1; 133 files import the module.
- **Options.** (1) ★ As is: not importable on wasm. (2) The four move to their own module; the other 23 import on wasm (changes decision 74's API). (3) The three cells gain wasm versions (a regex engine in the wasm prelude; a catchable `@panic`).
- **Recommendation.** (1) now; (2) if wasm must run asserts.
- **Blocks.** Nothing in the gate; "std compiles on wasm" (05-wasm step 5, 97 step 11).

### Ownership

#### own-a · Who owns the test runners (*proposed*)
- **Measured.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (beyond 114's budget lines), `tests/language/run.sh` (beyond 12's report), `modules/test-shard/**`, `modules/lib-test-runner/**`, the meta `scripts/**` were owned by `25-gate-perf`, 113, 115, 133, all closed (`fronts.md` § Ownership, open item).
- **Options.** (a) `01-compiler/07-residuals`, which already holds 25's open step (the per-cell dependency compile). (b) `00-gate/114`, the gate's residue. (c) none: each front names a carve-out per commit.
- **Recommendation.** (a): one owner, the one already holding the open runner work.
- **Blocks.** Any front step editing a runner (07-residuals step 12, 114 steps 5 and 7).

### 20-snap — the second test layer

#### snap-a · The snapshot maps — retired; the snapshots that exist or that a contract reads stay (replaces `01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b`)
- **Measured.** The nine maps carried from 1.0.10 (history under `../1.0.11-beta/`; re-evaluated case by case in [`20-snap/README.md`](./20-snap/README.md)) hold 473 cases plus helper tables: 27 obsolete (renamed, deleted or changed by decisions 186, 194, 200, 218, 34 step 2, 50-a, or deferred by `03r-ad`); 418 verified today by a named inline test or an existing `.snap`; 21, in five groups, verified nowhere and worth a plain test. 24 `.snap` already realise onze's §§ 50 · 51 · 52 · 70 · 71 via `snapshots.assertAs`; jhonstart holds 39, std 4. The maps' recorded literals predate the code (slug separator, `_links` order, `normalize`, emilia classes) — not expected values. Contract 7, `snapshots.md` rule 3 and 98 check (2) require at least one `assert<Subject>(loc, …)` in every `<lib>-test`.
- **Options.** (a) As proposed: (1) maps are closed records — no front records a `.snap` because a map names it; (2) existing `.snap` files stay (std 4, jhonstart 39, onze 50), change only with their test; (3) a new snapshot only where its exact bytes are a contract another package reads — this milestone, onze-release's `text_…` and `dockerfile_…` (on disk) for `107-release`; (4) helpers, no more than a consumer uses: `emilia-test`'s `assertClassName` (under `defaultTheme()`, recording `e_39b87d03`) and `assertCss(loc, tokens, th)`, `rakun-test`'s `assertResponse(loc, res)` over `MockMvc.perform`, jhonstart's and onze's existing helpers (onze's `assertAlias` goes with 218), no other map helper; (5) the 21 unverified values become plain tests — std's `mocks.verify` message with `throwsWith` on both targets, onze-release's tree as a path table, `emilia-card`'s repeat collapse, onze 53's blog E2E boxes as asserts over `request(…)` and the dev/start gate as an equality property (runner = five harness functions, no snapshot writers); (6) 97 step 7, 26 step 7, 33 steps 3–4, 50 step 8 and 51 step 7 close with an `AGENTS.md` line ("the inline literals and the existing `__snapshots__/` are the evidence"). (b) Build the whole layer: every map's helpers and `.snap` (~2 500 files), recorded literals re-derived first. (c) Keep the maps open per library: each answers its own former question and keeps its map until then.
- **Recommendation.** (a): one rule for every library, every value verified once, only three new `.snap` (emilia-test 2, rakun-test 1).
- **Blocks.** Front 135 ([`20-snap`](./20-snap/README.md)) steps 1–5, which own 97 step 7 · 19 step 6 · 26 step 7 · 33 steps 1, 3, 4 · 50 step 8 · 51 step 7 · 53 step 1's runner and steps 2–6's wording · 71 step 6; 98 check (2) stands unchanged.

## Contradictions

Rule pairs that cannot both hold, or a later rule changing an earlier one silently. Decision text
left as recorded; the maintainer picks the resolution.

#### ctr-h · Decision 149 against decisions 210 and 211
- **Rules.** 149: "`==` is reference equality on an array and is refused on a record … a record that wants equality implements `behavior Eq`". 210: "structural equality on every target"; 211: "a type cannot define its own equality". 210 does not cite 149.
- **Recommendation.** Record 149 as superseded by 210, its `behavior Eq` clause by 211; code on `feat` follows 210 / 214 (`run/record_structural_equality`).
- **Blocks.** Nothing; the record.

#### ctr-i · Codepoints (169, 240) against `string:length/1` (197)
- **Rules.** 169: erlang's `indexOf` answers "the codepoint index, as `at` / `slice` / `length` already do"; 240: wasm counts "codepoints, as erlang and beam", walking UTF-8 sequences. 197 (1): erlang answers "`string:length/1` of the text before the match". OTP's `string:length/1` and `string:slice/3` (used by `primitives.bp`'s `length`, `at`, `slice`, `indexOf`) count grapheme clusters: `"é"` has length 1 on erlang, 2 under a UTF-8 walk.
- **Recommendation.** One unit: (a) codepoints — erlang's templates count codepoints, a cell with a combining mark pins four targets; or (b) grapheme clusters — 169 / 240 restated, wasm needs a segmenter. (a) is what 169 and 240 say and what 260 hashes.
- **Blocks.** 02-erlang step 6's cell; 05-wasm's string lowering.

#### ctr-j · Decision 264 against decision 176 and "the same value on every target"
- **Rules.** 264: "on commonJS an `i64`'s representable range is ±(2^53−1) … a result outside it aborts too", and "decision 247 already refuses an `l` literal beyond it". 176: "an integer beyond ±(2^53 − 1) is `Error` on every target"; the delegation's principle: same value on every target. Under 264, `i64` arithmetic past 2^53 aborts on commonJS, answers on erlang, beam, wasm. 247 says nothing of a literal's range.
- **Recommendation.** (a) `i64` is ±(2^53−1) on every target (176's reading), or (b) commonJS lowers `i64` to `BigInt`, full range. Either way 264's citation of 247 is corrected.
- **Blocks.** The range checks of 04-js, 02-erlang, 03-beam; the checker's `l` literal rule.

#### ctr-k · Decision 187 against decision 195
- **Rules.** 187: "the core absorbs `rakun-actuator-api` and `rakun-logging` … the core calls its own logger and no failure-report plugin exists". 195 (later): "rakun-logging keeps its erlang cells and installs itself as the sink".
- **Recommendation.** Read 195 as "rakun's core logging (after 128) installs its erlang logger as `log`'s sink at boot", and record it.
- **Blocks.** 04-rakun/17 · 128 · 106.

#### ctr-l · Decision 186's third refusal against decision 202
- **Rules.** 186 refuses "a `#[serverOnly]` hook in a page that declares itself prerendered (`08-g`)". 202: "No declaration … no `pub val prerender` … no way to force".
- **Recommendation.** Drop 186's third refusal: under 202 no page declares itself prerendered.
- **Blocks.** 05-jhonstart/26 step 8's refusal list.

#### ctr-m · Question `lg2-s`'s argument against decision 216
- **Rules.** `lg2-s`: recommendation (1) "in step with `lg2-k` and `lg2-m`". 216 (4): project reflection at comptime, which "closes … No comptime reflection over the project" — `lg2-k` answered the other way.
- **Recommendation.** Re-argue `lg2-s` on its own (a module's imports stay a textual scan), or answer it as 216 did with an `imports` field.
- **Blocks.** `lg2-s`.

#### ctr-n · Decision 170's example against decision 206
- **Rules.** 170: "`import {x as a} from "m1"; import {x as b} from "m2";` is legal in one module", `m1` a module path. 206: "`from` names a package, never a module of the importing package" — module form is `import {m1.x as a};`. 206 does not amend 170; the type half is `imp-a`.
- **Recommendation.** Restate 170's example in 206's form; answer `imp-a`.
- **Blocks.** `imp-a`.

#### ctr-o · Decision 146 against confirmation `lem-c`
- **Rules.** 146: a function whose body reaches a host function with no binding for the target "is refused at its declaration, called or not". `lem-c` (built, to confirm): a host method with no binding "is refused where it is CALLED" — refusing the declaration was the option not taken; `lg2-r` measures the same at the call.
- **Recommendation.** Confirm `lem-c` for a bodyless host declaration (a type declared once still compiles for a target its method lacks); state that 146 governs any bodied function, free or method, reaching one; `docs.md` says both.
- **Blocks.** `lem-c`'s confirmation.

#### ctr-p · Confirmation `std-a` against confirmation `03r-e`
- **Rules.** `std-a`: `querystring.parse` / `parseForm` "refuse … an escape that decodes to a control character", and rakun's `splitQuery` moves onto them. `03r-e`: a cookie or query component that would decode to a control character "stays exactly as written". 196 moves rakun's cookie readers into `http`.
- **Recommendation.** Confirm `std-a`; `03r-e` lapses when rakun reads queries via `querystring` and cookies via `http`.
- **Blocks.** rakun 04's readers; 104's consumer sweep.

#### ctr-q · Decision 234 ("at boot") against decision 256 ("at comptime")
- **Rules.** 234: the context is "filled at boot from `@typeinfo.all`". 256: the registry is "built at comptime, at the program's entry point … rakun uses this form", citing 254, not 234.
- **Recommendation.** Read 234's "at boot" as "from 256's comptime registry", and record it.
- **Blocks.** 130 step 5.

#### ctr-r · Decision 189 (org-3) against decision 200
- **Rules.** org-3: "front 118 rewrites the bracket attributes outside `jhonstart-html` itself". 200: "the member `jhonstart-html` is deleted" (26 step 0, before 118).
- **Recommendation.** Read org-3 against the core's `html.bp` after 26 step 0.
- **Blocks.** 118's carve-outs.

#### ctr-s · Decision 166 against decision 243
- **Rules.** 166: "a list written without [a trailing comma] stays on one line". 243: "without it, the width rules (`16-a` / `16-b`) decide", while saying it "extends" 166.
- **Recommendation.** Record 243 as amending 166's no-comma half; the confirmation of `16-a` / `16-b` then covers it.
- **Blocks.** 16-formatter step 6.

#### ctr-u · Decision 216 against front 125's `#[schema]`
- **Rules.** 216: a decorator produces members, comptime meta, associated types, project reflection — "the loose `@emit` goes"; `#[validated]` follows (`validate()`, `constraints()`). `#[schema]`, on feat and in 125's design, still `@emit`s free `parse<T>` / `decode<T>` / `schemaOf<T>` (later `bind<T>`, `encode<T>`, `jsonSchemaOf<T>`); `125-validation-zod/surface.md` still names `constraintsOf<T>` / `validate<T>`.
- **Recommendation.** `#[schema]`'s outputs become members (`Player.parse(input)`), as `#[validated]`'s did; surface.md's rows follow.
- **Blocks.** 125 steps 3–10.

#### ctr-v · Decision 189 (org-3) against emilia's fronts opening before 118
- **Rules.** org-3: 118's carve-outs land before the owning front opens. `06-emilia/34` step 1 and `33` step 2 open now and reword emilia's `[class]={…}` comment lines themselves (`attributes.bp`, `emilia.bp`, `emilia-card/src/main.bp:5`), which 118 no longer owns.
- **Recommendation.** Record that a comments-only carve-out is taken by the owning front; 118 keeps the code lines (its own tests, `jhonstart-emilia`'s bridge test, `document-shell`).
- **Blocks.** 34 step 1; 33 step 2; 118 § Owns.

#### ctr-w · Front 09's Elasticsearch arm against decision 185
- **Rules.** 185: an optional capability goes through a core extension point, "no member-to-member edge". `04-rakun/09` § Open point: the Elasticsearch arm over `rakun-client` adds a `rakun-data → rakun-client` edge every data consumer loads.
- **Recommendation.** The arm reaches HTTP via a core extension point (or `httpc` directly, as 65's relay does), not a `rakun-client` edge; answered with `03r-ab`'s arm list.
- **Blocks.** 09 step 3.

## Implementation choices awaiting confirmation

Each implemented with its recommended option; the maintainer confirms or reverses (a reversal is a
local change in the named place). Full 1.0.10 text under the same id in
[`../1.0.10-beta/decisions-pending.md`](../1.0.10-beta/decisions-pending.md).

### 01-compiler (22)

| Id | Choice implemented | Where |
|---|---|---|
| 24-a | Annotation-only effect codes deleted; `effect-throw-without-fallible-channel` merges into `effect-try-without-fallible-channel`; `effect-wrapper-mismatch` only for a component whose `T` implements `@Context<B>` with `B` other than its `C`; `for-over-stream` / `for-await-expects-stream` are the renamed generator codes | `comptime/diagnostics.zig` |
| 24-b | `@Task`'s methods are `map` and `then`; no `flatMap` alias | `builtins.d.bp` |
| 24-c | `iter for` / `iter while` parse as prefixed `loop { for (…) { … }; break; }` (keyword kept in `LoopExpr.prefixedKeyword`); `iter loop :l` labels the generator scope, `iter for :l` the written `for` | parser |
| 23-b | `base64`'s four functions retired, not aliased; `encoding.base64Decode` / `base64UrlDecode` answer `@Result` | `libs/std/src/encoding.bp` |
| 23-c | `botopink test` for a project with folder modules: a module whose source is in the project's own `src` is the project's; type units written beside the declaring module | compiler-cli |
| 01c-a | A comptime module's atom is `bp@comptime@<owner path>__tpl__<decl>__<hash>` | comptime |
| 01c-b | A section leaf takes the leading-dot shorthand where the position's type is that section; with no expectation refused naming its section | checker |
| ck2-a | `@module()` refused at the call (`builtin-not-lowered`) until a rule says what a module value is | `builtins.d.bp` · `reject/builtin_module_not_lowered` |
| ck2-b | A section member may share a name with a top-level variant of the same enum (path and position type tell them apart); a variant declared twice at one level is `enum-variant-duplicate` | `modules/enum_section_leaf_beside_variant` |
| ck2-d | A label in a call of a function value is `label-on-function-value` | `reject/label_on_function_value` |
| ck2-e | A std decorator is reached via its module handle (`#[<handle>.<fn>]`); a leaf import of one is `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` is `unknown-annotation`; the emit-through-the-handle half lapses with 216's `@emit` removal | checker |
| rc3-b | `unknown` is the host vocabulary's spelling where `any` was (tested with `is` before use) | `run/host_unknown_parameter` |
| rc3-c | Assigning a narrowed `var` checks against its declared type and ends the narrowing | `reject/narrow_ends_at_assignment` |
| 16-a | C-12's argument list enabled with the constructs around it — binary run, brace-less `if`, argument list, array / tuple / behavior literals — one all-or-nothing `groupMeasured` each, outer deciding first | formatter; the libraries' reformat (16 step 4) |
| 16-b | An array literal's open form is one element per line | formatter |
| 0405-b | commonJS's `__bp_show` prints `undefined` as `null` | commonJS prelude |
| lem-a | A host method is a real method of its type whose body is the binding, never inlined at the call site | `codegen/hostMethods.zig` |
| lem-b | `inline = true` on a method's `External.Erlang` / `Beam` accepted, changes nothing (refusing it is 01-checker's to add) | `run/external_method_local` |
| lem-c | A host method with no binding for the target refused where called (`MissingExternal` naming `Type.method`); wasm refuses every host method; an untyped receiver fails at run time (`ctr-o`) | `hostMethods.missingAt` |
| lem-d | One name per operation on every type (`Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`); constructors stay module functions | `io.net` · `regex` |
| lem-e | Private helpers taking a type stay free (`tlsEchoOnce`, `rkvPush`, `putMessageSource`, `messageSourceOr`) | std · `validation` |
| lem-f | commonJS adopts a host-built record into its class (`__bp_adopt`) directly and through `?T`, arrays and a `@Result`'s ok side, not through `@Task` | `run/external_method_on_host_record` |

### 02-std-and-packaging (11)

| Id | Choice implemented | Where |
|---|---|---|
| 24-g | `std/async`: started `allOf` over `@Task<@Result<T, E>>` (stops at the first `Error` in input order), `all`, `race`; unstarted `runAll`, `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` (`Error("timeout")`); `failed(message)` answers `Error`; `allSettled`, `settleOf`, `unwrapAll`, `attempt` removed | `libs/std/src/async.bp` |
| 01std-a | A bundled library loaded by CLI and LSP (`appendBundled`), not `expandStdImports`; compiler-core names no package but `std` | `build.zig` `bundled_packages` |
| 01std-c | `routing.pattern`'s empty pattern matches only `/`; rakun-web keeps "empty runs everywhere" at its call site (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` refuses a `redirect` disagreeing with `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` answer `@Result`, refuse a malformed escape, non-UTF-8 and a control character raw or decoded; `stringify` refuses a control character; `parse` is RFC 3986 (`+` stays), `parseForm` the form flavour (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` follows a symbolic link (dangling link is `false`) | `io/fs.bp` |
| std-c | Decision 110's folder namespace is a rewrite of the parsed program | `comptime/std_namespace.zig` |
| 95-a | Front 95 relocated `jhonstart-link` and `rakun-app` as moves with no behaviour | jhonstart · rakun |
| 95-b | `rakun-app` inherits the workspace's `targets` — as amended by rakun 04: `["erlang"]` | `rakun-app` manifest |
| 95-c | `erika-test` exists | erika |
| 95-e | A member importing the core's request context names the module: `from "rakun/request_context"` | `rakun-app/src/ssr.bp` |

### 04-rakun (24)

| Id | Choice implemented | Where |
|---|---|---|
| 03r-a | Every rakun manifest is `["erlang"]`; a built erlang program ships and loads its `.erl` sidecars (ledger half moot under 153) | every member |
| 03r-b | `rkPropInt("12abc")` is `12` (the leading-integer rule `toI32` states) | 04 |
| 03r-c | Front 05's readers stay botopink; no `rakun_config.erl` | 04 |
| 03r-d | The configuration check runs in `bootSequenceFor`, lazy initialization included | 04 |
| 03r-e | A cookie or query component std refuses, or that would decode to a control character, stays as written (`decodeComponent`) (`ctr-p`) | 04 |
| 03r-f | A cache key is `namespace + ":" + hash.strongCacheKey(parts)` | 12 |
| 03r-g | A private-scope read with no session runs the loader, stores nothing | 12 |
| 03r-h | A twin's key is `[method, args…]`; `#[cacheEvict(name, false)]` evicts it under every `#[cacheable(name)]` reader | 12 |
| 03r-i | Redis cache provider reuses rakun-session's RESP wire (`rkSessRedis`); `revalidateTag` deletes; unreachable Redis runs the loader uncached (health DOWN) | 12 |
| 03r-j | Outside a request `revalidateTag` / `revalidatePath` legal, `updateTag` raises; global `rakun.cache.type=none` disables every cache whatever its own type | 12 |
| 03r-k | Every messaging arm runs on the in-process broker (`transport=memory`); a real address without it refuses the boot naming the driver | 15 |
| 03r-l | A listener container is named after its destination; Redis defaults to ack-mode `none` (explicit `auto` / `manual` on Redis refuses the boot) | 15 |
| 03r-m | Inside a server action `revalidatePath` / `revalidateTag` expire at once; outside, stale-then-fresh | 12 · 22 |
| 03r-n | A JSON-RPC argument is a form-encoded field list, read in order into one form | 22 |
| 03r-o | ~~A segment config field equal to `defaultSegmentConfig()`'s is inherited~~ — moot: 290 deletes the segment config | 22 |
| 03r-p | A slot belongs to the nearest layout at or above its shortest entry; a conflict is two pages of one slot at one URL | 22 |
| 03r-q | Locale routing lives in `rakun-app/src/i18n.bp`; no `rakun-i18n` member | 22 |
| 03r-r | Starters name sibling members `{ "workspace": true }` | 73 |
| 03r-s | OTLP pushed as HTTP/JSON (`json:encode` in `rakun_metrics.erl`) | 17 |
| 03r-t | Front 76's keys under `rakun.management.*`, in one `management.bp` plus the `rakun_probes` sidecar | 11 |
| 03r-u | Liveness group admits only `livenessState`, `ping`, `diskSpace`; any other name refuses the boot | 11 |
| 03r-v | Typed query builder's operator is the enum `Op` (`Eq`, `Ne`, `Lt`, `Gt`, `Le`, `Ge`, `Like`) | 08 |
| 03r-w | OAuth2's explicit endpoints are `OAuth2Provider` fields (`authorizationUri`, `tokenUri`, `userinfoUri`, `jwksUri`); client credentials are `withClientToken(id, call)`, retrying once on 401 | 79 · 13 |
| 03r-x | Outbox relay claims by conditional `UPDATE` (a crashed relay's claims return via `reclaimStale`); saga and 2PC coordinators persist every transition and resume at boot (`resumeSagas`, `recover2pc`); job store claims triggers and takes over leases the same way | 15 |

### 05-jhonstart (10)

| Id | Choice implemented | Where |
|---|---|---|
| 26-a (jhonstart) | Every router cell dual-target (a `router_runtime.mjs` twin). Id shared with 01-compiler's `26-a`, decision 242 | core |
| 27-a | A browser cell in a two-target member is dual-target, its erlang twin answering the server's truth | `jhonstart-link` · core |
| 29-a | Island starter table = the registry's `globals.starters`, filled by `registerStarter(name, start)` and `registerRouteStarters(pattern, load)`; a second starter or loader for one name fails | core · 26 step 5 |
| 30-b | `RenderPlugin` is a record of async functions; `payload` answers `Array<#(key, json)>`; `chunk(id)` runs in the boundary's own process | `streaming.bp` |
| 30-c | `render` / `renderStream` / `App` in `streaming.bp`; `compose` takes the page as a thunk, runs the layouts first | `streaming.bp` · `render.bp` |
| 30-d | `Suspense` registers its boundary with the render via one host cell | `streaming.bp` |
| 30-e | The segment record is `UiSegment` | core |
| 30-f | `app(…, lang = "en")`: one checked language per app | core |
| 30-g | Browser half asserted in the commonJS-only member `jhonstart-dom-test` over `fake_dom.mjs` | `jhonstart-dom-test` |
| 31-a | `notFound()` / `redirect(url)` raise via one host cell (`__jhRaise`); a boundary captures via `__jhCapture`; `notFoundReason()` / `redirectReason(url)` answer the reason without raising | core |

### 06-emilia (12)

| Id | Choice implemented | Where |
|---|---|---|
| 05emilia-a | Filter reader is upstream's inline chain (`filterChain()`, `backdropFilterChain()`), not `var(--tw-filter)` | 42 |
| 05emilia-b | The backdrop section is `BackdropFilter` | 42 |
| 05emilia-c | `drop-shadow-none` follows upstream (`--tw-drop-shadow: ` and the reader) | 42 |
| 05emilia-d | Snap strictness is the fallback `var(--tw-scroll-snap-strictness, proximity)` | 46 |
| 05emilia-e | `fullTheme()` rides on `fullOptions()` in `emilia.bp`; `defaultOptions()` stays palette-free | 56 |
| 05emilia-f | `--inset-shadow-*` entries drop upstream's leading `inset` | 41 |
| 05emilia-g | `space-*` / `divide-*` follow upstream's selector and reverse-aware margins | 35 · 40 |
| 05emilia-h | Sibling modules never import `from "emilia"`; `named()` and `lookupRule` live in `emilia.bp` | 55 · 57–59 |
| 05emilia-i | `--tw-*` transform variables are `@property` blocks with upstream's `properties` layer | 45 · 54 · 56 |
| 05emilia-j | A selector-list modifier (`marker:`, `selection:`) is a list of one-`&` variants | 34 · 56 |
| 05emilia-k | Negative half step is `spacingNegHalf(n)`; `spacingHalf` refuses a negative `n` | 54 |
| 05emilia-l | Confirming a column moves its whole family to upstream's form, one helper per shape | 35–45; 34 step 2 moves five families under it |

### 07-onze (11)

| Id | Choice implemented | Where |
|---|---|---|
| 49-a | The core's suites render via its own `describe*` over `snapshots.assertAs`; `onze-test`'s helpers are thin wrappers | onze core |
| 49-c | `onze.json` refuses an unknown key, a duplicate, a wrong kind, a port outside `1..65535`, a non-string `allowedRedirects` entry | `config.bp` |
| 49-d | `chainFor(patterns)` takes rakun's ancestor patterns — as amended by `03-bundled-libs/102`: onze consumes `routing.conventions` | 49 |
| 49-e | The rakun half of the boot is the erlang member `onze-server` | 49 step 2 |
| 50-a | `onze build` stages a server main, compiles it to BEAM; `onze start` runs it with `erl` — as amended: `start` calls front 71's `bin/onze` once it exists | 50 · 71 step 2 |
| 52-a | Font-metrics table has five transcribed rows; its generator is owed | 51 step 4 |
| 53-a | The blog's sources under `src/` (`appDir: "src/app"`) | 53 |
| 68-a | A client-manifest field escapes `%`, `\|`, LF and CR only | bundler |
| 68-c | Island starters decode `#[clientProps]` from the component's source | bundler |
| 68-d | The styleMap is evaluated by a probe compiled into both packages (`emilia-hash-split`, `emilia-unevaluated`) | bundler |
| 69-a | onze-assets keeps `AssetRoot`; onze-server converts it to rakun-web's `StaticRoot` | assets · server |

### Choices made by the 00-gate threads and the consolidation (7) — see `decisoes-pendentes.md` Parte 5

| Id | ★ implemented | Where |
|---|---|---|
| 111-b | the beam sidecar loader is emitted only when the build binds a host function (13 snapshots changed) | botopink-lang `codegen/beam_asm.zig` |
| 111-c | `botopink build --target beam` runs the host-module probe and exits 1 when `erl` fails | `compiler-cli` build |
| 113-a | a target `botopink test` cannot run is `NOT RUNNABLE` and fails `test-libs` | `scripts/test-libs.sh` |
| 113-b | the restriction audit matches the refusal by its text (alternative, recommended: give the refusal an id — 07-residuals) | `lib-test-runner` |
| 110-b | the count history left `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | `format-check`'s `TREES` holds `examples` as one entry plus `modules/manifest/tests` | `scripts/format-check.sh` |
| 103-a | the package function is `deriveActionId`; rakun-app's `actionId` wraps it | `03-bundled-libs/103` |
