# Decisions the maintainer owes — 1.0.11-beta

**Twenty-seven questions are open** — `dec-a`, `dec-b` and `dec-d` (front 130's migration), then
`ck2-c` and `lg2-a…w`, carried verbatim below from 1.0.10-beta's § Open with their ids unchanged (`ck-host`, `lg-a`, `lg-b` and this milestone's `01c-e` were answered:
decisions 146–149). Every `lg2-*` row of [`language-gaps.md`](./language-gaps.md) is a
feature the language does not have; the recommendation is always the most restrictive reading
(decision 67) — the feature stays out and the row's nearest form is the design — and no front opens
on one until it is answered. **The next free decision number is 237** ([`decisions-taken.md`](./decisions-taken.md)).

Beside the open questions, every track carries **implementation choices awaiting confirmation** —
a choice a front made, recommended and implemented, that the maintainer confirms or reverses. The
letter ids are never renumbered; their full text lives where they were raised:

| Ids | Raised by | Full text |
|---|---|---|
| 24-a, 24-b, 24-c, 24-g · 23-a, 23-b, 23-c · 01c-a, 01c-b · ck2-a, ck2-b, ck2-d, ck2-e · rc3-a, rc3-b, rc3-c · 16-a, 16-b · 0405-b | the 1.0.10 compiler fronts | [1.0.10-beta `decisions-pending.md`](../1.0.10-beta/decisions-pending.md); confirmations listed in [`01-compiler/README.md`](./01-compiler/README.md) § Decisions |
| 24-h · 26-a | `01-compiler` (new) | [`01-compiler/README.md`](./01-compiler/README.md) § Decisions (`D5`, `01c-c`, `01c-d`, `01c-e`, `0405-c`, `16-c`, `16-d`, `17-a`, `23-d` were answered: decisions 150, 151, 152, 149, 164, 165, 166, 168, 169) |
| 01std-a, 01std-c, 01std-d, 01std-e · std-a, std-b, std-c · 95-a…e | 1.0.10's `01-std` / `02-packaging` | [1.0.10-beta](../1.0.10-beta/decisions-pending.md); confirmations in [`02-std-and-packaging/README.md`](./02-std-and-packaging/README.md) |
| 01std-f · std-d · std-e · 95-f | `02-std-and-packaging` (new) | [`02-std-and-packaging/README.md`](./02-std-and-packaging/README.md) § Decisions (`std-e`: test lifecycle hooks — below) |
| 03r-a…x | 1.0.10's `03-rakun` | [1.0.10-beta](../1.0.10-beta/decisions-pending.md); confirmations in [`04-rakun/README.md`](./04-rakun/README.md) |
| 03r-ab · 03r-ad · 03r-ae · 03r-af · 03r-ag · 03r-ak · 03r-al · 03r-am (8 of the 15 raised) | `04-rakun` (new) | [`04-rakun/README.md`](./04-rakun/README.md) § What the maintainer must decide (answered: `03r-y` — 184, superseded by 187; `03r-z` — 185; `03r-aa` — 160; `03r-ac` — 187; `03r-ah` — 153; `03r-ai` — 186; `03r-aj` — 187) |
| 26-a, 26-b, 27-a, 29-a, 30-b…g, 31-a | 1.0.10's `04-jhonstart` | [1.0.10-beta](../1.0.10-beta/decisions-pending.md); confirmations in [`05-jhonstart/README.md`](./05-jhonstart/README.md) (`31-b` was answered: decision 194, with 195) |
| 30-h · 67-a | `05-jhonstart` (new) | [`05-jhonstart/README.md`](./05-jhonstart/README.md) § Decisions |
| 05emilia-a…l | 1.0.10's `05-emilia` | [1.0.10-beta](../1.0.10-beta/decisions-pending.md); confirmations in [`06-emilia/README.md`](./06-emilia/README.md) |
| 05emilia-m, 05emilia-n | `06-emilia` (new) | [`06-emilia/README.md`](./06-emilia/README.md) § Decisions |
| 49-a, 49-c, 49-d, 49-e · 50-a · 52-a · 53-a · 68-a, 68-c, 68-d · 69-a | 1.0.10's `06-onze` | [1.0.10-beta](../1.0.10-beta/decisions-pending.md); confirmations in [`07-onze/README.md`](./07-onze/README.md) (`49-d` and `50-a` amended there; `69-b` was answered: decision 201) |
| 50-b · 53-b | `07-onze` (new) | [`07-onze/README.md`](./07-onze/README.md) § Decisions (`49-f` was answered: decision 186) |
| 07-b · 07-g · 07-h | `03-bundled-libs` (new) | [`03-bundled-libs/README.md`](./03-bundled-libs/README.md) § Decisions (answered: `07-a` — 196; `07-c` — 180; `07-d` — 181; `07-e` — 182; `07-f` — 195; `07-i` — 163) |
| 07-j · 07-n | `03-bundled-libs/125-validation-zod` (new) — how much of Zod, where `Schema<T>` lives (`07-k`, `07-l` and `07-m` are decisions 145, 144 and 183) | [`03-bundled-libs/125-validation-zod/README.md`](./03-bundled-libs/125-validation-zod/README.md) § Decisions the maintainer owes |
| 08-b · 08-d · 08-e · 08-f · 08-h | `08-bpp` (new) — one routing convention or two, who scopes CSS, server-island props, where Markdown and YAML live, the config file and the commands | [`08-bpp/README.md`](./08-bpp/README.md) § Decisions the maintainer owes (answered: `08-a` and `08-i` — 198; `08-a2` — 199; `08-a3` — 200; `08-c` — 190, with 191–193; `08-g` — 202) |
| lem-a…f | `libs-external-methods` (1.0.10) | [1.0.10-beta](../1.0.10-beta/decisions-pending.md) |

Two items the milestone's own cut raised are written here rather than in a track, because they
cross tracks (`gate-a…j`, the zero-tolerance policy of `00-gate`, were answered: decisions 153–162),
and three that the audit of the `00-gate` fronts on the integrated `feat` raised (`gate-k…p`, answered: decisions 225–228, 230, 231), and two that `01-compiler/05-wasm` step 5
raised, because their answer reaches std (`05w-a`, `05w-b`, open):

### std-e · Test lifecycle hooks

> **Raised by:** `02-std-and-packaging` (asserts-api's inventory) and every `-test` member that
> resets state at the top of each `test`.
> **Measured.** rakun-test's `resetSingletons` / `resetContext` are called by hand in 40+ test
> bodies; jhonstart-dom-test installs its document the same way.
> **Options.** (a) no hooks: a test body calls its reset helper, and a missing call is the test's
> bug; (b) a `#[before]` / `#[after]` decorator on a module-level fn that the runner calls around
> every `test` of the module; (c) `beforeEach { … }` blocks as a grammar form.
> **Recommendation.** (a) — nothing implicit runs around a test; the runner stays a list of bodies.
> The cost is one line per test, which the libraries already pay.
> **Blocks.** `language-gaps.md` row "No test lifecycle hooks".

### 05w-a · What an `@External.Wasm` binding names, and which WASI

> **Raised by:** `01-compiler/05-wasm` step 5 (decision 230).
> **Measured.** `builtins.d.bp` declares `Wasm(template: string)` and nothing else: no binding in the
> ecosystem writes one, `docs.md` § Host bindings defines the two shapes for Node and Erlang only
> (`("module", "symbol")` and a target-text template over `$0`, `$1`, …), and the wasm backend reads
> none (`#[@External.Wasm("x")]` today reaches `lowerPlainCall`'s "bodyless `declare fn` with no
> `#[@External.<Target>(…)]`" refusal). The std cells groups 1–2 need are of three kinds: an opcode
> (`math`: `f64.floor`, `f64.sqrt`, `f64.min` …), an algorithm wasm has no instruction for (`hash`'s
> sha1/sha256/sha512/md5/hmac/pbkdf2, `json`'s validator, `unicode`'s four normalisations, `encoding`'s
> base64/hex/percent, `io/clock`'s ISO-8601 and civil-date arithmetic), and a WASI call
> (`clock_time_get`, `random_get`, `poll_oneoff`, `path_open`/`fd_read`/`fd_write`, `fd_readdir`,
> `path_create_directory`, `path_symlink` …). A WASI function's ABI is pointers and an errno
> (`random_get(buf, len) -> errno`), which no botopink signature can bind, since botopink has no
> memory access. The backend already imports `wasi_snapshot_preview1.fd_write` (the print path), and
> `wasmtime run` runs preview1 with no flag.
> **Options.**
> (a) the target's text, as Node and Erlang: a folded WAT expression over `$0…`, and the two-string
> form as a raw import —
> ```botopink
> #[@External.Wasm("(f64.floor $0)")]
> pub declare fn floor(x: f64) -> f64;
> #[@External.Wasm("(call $sha256Body $0)")]          // a bp fn of the same module
> declare fn sha256Hex(s: string) -> string;
> #[@External.Wasm("(call $__clock_ns (i32.const 0))")] // a prelude helper: its name becomes a contract
> declare fn systemNanos() -> i64;
> ```
> The backend parses the expression into its instruction model (an unknown opcode or name refused at
> the annotation); WASI calls go through prelude helpers whose `$__` names std now depends on.
> (b) a closed vocabulary of three tagged forms, arguments always the declared parameters in order —
> ```botopink
> #[@External.Wasm("op:f64.floor")]          // one opcode; its type checked against the signature
> pub declare fn floor(x: f64) -> f64;
> #[@External.Wasm("fn:sha256Body")]         // a botopink fn of the same module, same signature
> declare fn sha256Hex(s: string) -> string;
> #[@External.Wasm("wasi:clockNow")]         // one of a documented list of compiler WASI adapters
> declare fn systemTimeWithUnit(unit: i32) -> i64;
> ```
> The adapters (`clockNow(unit)`, `monotonicNow(unit)`, `randomBytes(n)`, `sleep(ms)`, `readText`,
> `writeText`, `exists`, `list`, `mkdir`, `rm`, `copy`, `stat`, `symlink` …) are a table in `docs.md`,
> each a prelude group over WASI preview1; anything else is refused at the annotation. No raw import,
> no WAT parser, and the algorithms stay in std as private `fn` bodies.
> (c) no wasm binding at all for computation: std gives the cell a plain botopink body for every
> target (`hash`, `json`, `unicode` written once in bp), and `@External.Wasm` is only (b)'s `op:` and
> `wasi:` — a public-surface-neutral but large std rewrite, and the node/erlang host speed is lost.
> **WASI version.** preview1 (`wasi_snapshot_preview1`) in every option: it is what the print path
> imports and what `wasmtime run` runs unflagged; preview2 is the component model, a different
> module format.
> **Recommendation.** (b) — a closed list checked at the annotation is the strictest form (an unknown
> opcode, a misspelt `fn:` or an adapter that does not exist is a located error, never text the
> backend trusts); no `$__` name of the prelude becomes std's contract; nothing exposes raw memory; and
> the algorithms stay in the library (the compiler knows no library), reached by name.
> **Blocks.** All of `05-wasm` step 5: no `@External.Wasm` can be written or read until the form is
> fixed.

### 05w-b · The std cells WASI preview1 has no answer for, and the directory a wasm program sees

> **Raised by:** `01-compiler/05-wasm` step 5 (decision 230).
> **Measured.** WASI preview1 has no time zone, no working directory and no temporary directory, and
> a wasm module reaches the file system only through directories the runner pre-opens —
> `runtime.zig` and `botopink run` call `wasmtime run <module>` with no `--dir`, so today every
> `path_open` would answer `EBADF`. Cells with no preview1 answer: `io/clock.offsetMinutes` (local
> offset), `io/fs.workingDir`, `io/fs.scratchDir`. Under decision 146 one such cell refuses its whole
> module, so `io/clock`, `io/fs` and with it `testing/snapshots` cannot leave the refused list while
> it stays.
> **Options.**
> (a) the cells are refused on wasm, so their modules stay refused and move to group 3
> (`02-std-and-packaging`'s, to restructure or keep out of a wasm build) —
> ```
> error: `offsetMinutes` has no `#[@External.<Target>(…)]` for the wasm backend
> ```
> (b) WASI's own meaning answers them — the offset is `0` (WASI time is UTC), the working directory
> is `.` (the pre-opened one), the scratch directory is `./.botopinkbuild/tmp` — and `botopink run`
> / the test runner pre-open the project directory (`wasmtime run --dir .`);
> (c) as (a) for the three cells, which std moves to modules of their own (`io/clock` and `io/fs`
> build on wasm without them) — a public-surface change, `02-std-and-packaging`'s.
> And, whichever is taken, for `io/fs`'s other cells: (i) the runner pre-opens the project directory
> and a path outside it is an `Error(…)` from the cell; (ii) nothing is pre-opened and every `io/fs`
> cell answers `Error(…)` on wasm.
> **Recommendation.** (a) with (i): a value WASI does not define is refused, never invented (a `0`
> offset on a machine in UTC-3 is a wrong answer at exit 0, the class this backend exists to keep
> out); the project directory is the one grant a program needs to read its own files, and a path
> outside it fails as a missing file does on node. `05-wasm`'s acceptance then reads "refuses only
> group 3 and the modules (a) moved there".
> **Blocks.** `05-wasm` step 5's group 2 (`io/clock`, `io/fs`, `testing/snapshots`); `io/random`
> is not blocked by it.

### C-37 · The commonJS prelude's `charCodeAt` recursion

Not a question — a row allocated here so the id exists: `emilia/modules/emilia/src/output.bp:379-388`
works around a commonJS prelude method that calls itself on a non-ASCII input. Owner
[`01-compiler/04-js`](./01-compiler/04-js/README.md); the cell to write is
`tests/language/run/string_char_code_non_ascii.bp`.

---

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

### dec-a · Where a function's decorator puts per-function code

> **Raised by:** `01-compiler/130-decorator-outputs` step 5 (its open question 1)
> **Measured.** Decision 216's four places hang off a type; `decl.addMember` from a `fn`'s decorator
> is `decorator-member-without-type`. jhonstart's `#[page]` writes `pub fn <Page>Params(route)` per
> page (`routes.bp`), rakun's `#[middleware]` a gate lambda per function.
> **Options.** (a) a page becomes a type (`#[page] pub type BlogPost(route: Route) { pub fn
> render(self: Self) -> Element { … } }`), and `BlogPost.Params` is an associated type; (b) the
> per-function code becomes library code written once, fed by meta (`decl.setMeta("seg",
> "[slug]")`, `paramsOf(@typeinfo(BlogPost).meta.page.seg, route)`); (c) a fifth place, a member
> hung on a function.
> **Recommendation.** (b) — no fifth mechanism, the page is written as today, and the helper is
> code the library owns instead of code generated per page.
> **Blocks.** jhonstart `routes.bp` (5 sites), rakun's `#[middleware]`, step 6 of front 130.

### dec-b · One `@typeinfo.all` over several decorators

> **Raised by:** `01-compiler/130-decorator-outputs` step 5 (its open question 4)
> **Measured.** A query answers one decorator. rakun's stereotypes (`#[component]`, `#[service]`,
> `#[repository]`, `#[controller]`, `#[configuration]`, …) are one kind of thing — a managed
> singleton — and its registrations (`__rkScan_`, `__rkRoute_`, `__rkEntityReg_`, `__rkQueryReg_`,
> … ~45 sites) all move to a catalogue an entry point builds.
> **Options.** (a) one query per decorator, concatenated by the entry point; (b) `with: [component,
> service, repository]`, one answer in the one order (module path, then declaration order), a
> declaration carrying two of them answered once; (c) each stereotype delegates to one shared marker
> the query names.
> **Recommendation.** (b) — with (a) the catalogue's order is the order of the concatenations, not
> the rule the query states.
> **Blocks.** Every rakun registration site (~45) and jhonstart's four registrations.

### dec-d · What a constructor-injected field resolves through

> **Raised by:** `01-compiler/130-decorator-outputs` step 5 (rakun's DI factories)
> **Measured.** A stereotype emits `pub fn __rkMake_<T>()` and injects each field with
> `__rkMake_<FieldType>()`, so the factory's NAME is the injection contract — and three other
> decorators write or name a factory for a type they do not annotate: `#[provides] fn systemClock()
> -> Clock` (a `fn`), `#[bean]` (a method of a `#[configuration]` type) and `#[imports("A,B")]`
> (Spring's `@Import`, naming `__rkMake_A`). With
> decision 216 a stereotyped type's factory is the member `T.make()`, but a provider cannot add a
> member to `Clock` (`decorator-member-without-type`; a member joins the annotated type only), and
> the stereotype that writes `clock: Clock`'s injection cannot tell a stereotyped `Clock` from a
> provided one. 29 `__rkMake_` emit sites, ~120 references in 36 rakun files.
> **Options.** (a) a field resolves through the type: `Clock.make()`; a provider is refused (no
> `#[provides]` / `#[bean]` for a type the application does not own); (b) a field resolves through
> the context by type name (`clock: rkResolve("Clock")`, the field's type fixing the answer's), the
> context filled at boot from `@typeinfo.all(with: component, member: "make")` and
> `@typeinfo.all(with: provides)`; (c) a fifth place: a provider adds `make()` to the type it
> returns (dec-a's (c), across declarations).
> **Recommendation.** (b) — Spring's own model, no generated name is a contract, and the two-providers
> case (`#[qualifier]`, `#[primary]`) becomes a rule of the context instead of a collision on one
> function name; the cost is that a missing bean is a boot failure, not an unbound-function build
> error (the boot already refuses the cycle and the ambiguity there).
> **Blocks.** The 29 `__rkMake_` sites and everything that injects through them: `#[transactional]`'s
> and `#[methodSecurity]`'s proxies, the route, scheduler, listener and endpoint registrations that
> call `__rkMake_<T>()`.

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

