# Decisions the maintainer owes — 1.0.11-beta

**These questions are open** — `lg2-a…w`, `02e-a` (raised by `01-compiler/02-erlang`), `dec-e` (raised by `01-compiler/130-decorator-outputs` step 5), `05w-c…f` (raised by `01-compiler/05-wasm` step 5), `05w-g` (raised by `00-gate` on `macos-14`) and `17-b`, `17-c` (raised by `01-compiler/17-beam-memory`); `ck2-c` was answered (decision 244); the `lg2-*` rows are carried verbatim below from 1.0.10-beta's

**Twenty-seven questions are open** — `ck2-c`, `lg2-a…w`, `02e-a` (raised by `01-compiler/02-erlang`), `dec-e` (raised by `01-compiler/130-decorator-outputs` step 5) and `gw-a` (raised by `front/gate-wasm-wrong-answers`); the first twenty-four carried verbatim below from 1.0.10-beta's
§ Open with their ids unchanged (`ck-host`, `lg-a`, `lg-b` and this milestone's `01c-e` were answered:
decisions 146–149). Every `lg2-*` row of [`language-gaps.md`](./language-gaps.md) is a
feature the language does not have; the recommendation is always the most restrictive reading
(decision 67) — the feature stays out and the row's nearest form is the design — and no front opens
on one until it is answered. **The next free decision number is 254** ([`decisions-taken.md`](./decisions-taken.md)).

Beside the open questions, every track carries **implementation choices awaiting confirmation** —
a choice a front made, recommended and implemented, that the maintainer confirms or reverses. The
letter ids are never renumbered; their full text lives where they were raised:

| Ids | Raised by | Full text |
|---|---|---|
| 24-a, 24-b, 24-c, 24-g · 23-a, 23-b, 23-c · 01c-a, 01c-b · ck2-a, ck2-b, ck2-d, ck2-e · rc3-a, rc3-b, rc3-c · 16-a, 16-b · 0405-b | the 1.0.10 compiler fronts | [1.0.10-beta `decisions-pending.md`](../1.0.10-beta/decisions-pending.md); confirmations listed in [`01-compiler/README.md`](./01-compiler/README.md) § Decisions |
| 17-b · 17-c | `01-compiler` (new) — the per-row increment of a `keyed = true` `Dict`; what else names one | [`01-compiler/README.md`](./01-compiler/README.md) § Decisions (`D5`, `01c-c`, `01c-d`, `01c-e`, `0405-c`, `16-c`, `16-d`, `17-a`, `23-d`, `24-h`, `0405-d`, `26-a` were answered: decisions 150, 151, 152, 149, 164, 165, 166, 168, 169, 179, 239, 242) |
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
raised, because their answer reaches std (`05w-a`, `05w-b`, answered: decisions 238, 241; `05w-c`, `05w-d`, `05w-e`, `05w-f`, `05w-g`, open — below), and one that `01-compiler/14-comptime-on-beam`
step 2 raised, because its answer changes what a template body receives (`14-a`, answered: decision 237):

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

### dec-e · How the boot registers beans whose types differ (decision 234)

> **Raised by:** `01-compiler/130-decorator-outputs` step 5, rakun's dependency injection (decision 234).
> **Measured.** `@typeInfo.all(…)` answers one array literal, so every entry's `value` must have one
> type. Decision 234's boot reads `@typeInfo.all(with: [stereotypes…], member: "make")`, and a
> stereotype's `make()` returns its own type: two of them are `type mismatch: expected Mailer, got
> Orders` at the query (measured on the compiler of 130). `@typeInfo.all(with: provides)` is the same
> refusal for two `#[provides]` functions returning `Clock` and `Ledger` — each `value` is the
> function itself. The language has no `any`, and a function's decorator writes no per-function code
> (decision 236), so a `#[provides]` function cannot carry a registration of its own either.
> **Options.** (a) **library only** — the stereotype adds a second member, `T.register() -> i32`,
> which registers `{ -> T.make() }` under the type's name with the qualifier / primary / scope / lazy
> its annotations carry; the boot reads `@typeInfo.all(with: [stereotypes…], member: "register")` and
> calls each value. `#[provides]` functions become `#[bean]` methods of a `#[configuration]` type
> (Spring's `@Bean`), registered by the configuration's own `register()`; the free-function
> `#[provides]` goes (41 annotations in rakun). (b) **compiler** — `@typeInfo.all(…, each: f)` applies
> a generic `f` to every entry where the answer is spliced (`[f(Declared(…Mailer…)), f(Declared(…Orders…))]`),
> each call typed alone, the answer `R[]`: rakun writes
> `@typeInfo.all(with: [service, …], member: "make", each: rkBean)` and
> `@typeInfo.all(with: provides, each: rkProvided)`. (c) **keep the load-time registration** — each
> stereotype emits `val __rkBean_T = rkRegisterBean(…, { -> T.make() })`; this is an `@emit`, which
> step 6 removes, so (c) only defers the question.
> **Recommendation.** (a) — no language feature, and the registration is a member like every other
> output of decision 216; `#[bean]` inside `#[configuration]` is the one provider form Spring has.
> **Blocks.** Decision 234's boot (the catalogue that fills the context): the `T.make()` factories and
> the `rkResolve("<Field type>")` injection can be written, but nothing fills the context they read.

### 05w-c · How exactly wasm's `std/math` agrees with the hosts

> **Raised by:** `01-compiler/05-wasm` step 5 (decision 238's `fn:` bodies of `math.bp`).
> **Measured.** Node 25.8 (V8 14.1) answers `Math.exp`/`log`/`log2`/`log10`/`sin`/`cos`/`tan`/
> `asin`/`acos`/`atan`/`atan2`/`sinh`/`cosh`/`tanh` with fdlibm (not correctly rounded: 212 of 2 000
> random `exp` inputs differ from the correctly rounded value) and `Math.pow` with the C library's
> `pow` (`v8_flags.use_std_math_pow`; glibc, ≤ 0.52 ulp). erlang and beam call glibc for all of them,
> so commonJS and erlang already differ in the last bit for ~10 % of `exp` inputs. wasm today ports
> fdlibm (bit-identical to commonJS on 6 539 fuzzed inputs, 1 200 of them `pow`) and computes `pow`
> in double-double, correctly rounded — which differs from glibc's for ~1 input in 450:
> `math.pow(158.42161580281933, 2.853827476501465)` is `1896229.4525711867` on commonJS and erlang,
> `1896229.4525711865` on wasm.
> **Options.** (a) wasm's contract is commonJS bit for bit: port glibc's `pow` too (a fixed algorithm
> since glibc 2.28, with its 128-entry `log` and `exp` tables); (b) correctly rounded wherever wasm
> has no instruction: replace the fdlibm port with double-double — wasm then differs from commonJS on
> ~10 % of `exp` inputs; (c) keep today's split and record the ~0.2 % `pow` difference as a
> `language-gaps.md` row.
> **Recommendation.** (a) — the strictest reading of "the same answers as commonJS"; no cell compares
> a `pow` at an input where (a) and (c) differ. The commonJS × erlang divergence (fdlibm × glibc) is a
> row of its own, not this question's.
> **Blocks.** Nothing today; it decides `math.bp`'s `powBody`.

### 05w-d · What `hash.contentHash` folds for a character above U+FFFF

> **Raised by:** `01-compiler/05-wasm` step 5 (`hash.bp`'s `contentHashBody`).
> **Measured.** The three hosts answer three values for `contentHash("🎉")` (U+1F389). erlang folds
> the code point: `djb2([127881])`. The Node cell loops over UTF-16 indices calling `charCodeAt`,
> which the commonJS runtime answers with the code point there, so it folds the code point and then
> the low surrogate: `djb2([127881, 57225])` = `9aae77`. `hash.bp`'s own comment says two UTF-16
> units (`djb2([55356, 57225])` = `76298a`), which no target answers. wasm's body copies commonJS
> (`9aae77`); a 180-input fuzz is then identical to commonJS on every cell.
> **Options.** (a) the code points, as decision 169 counts a string: erlang's answer; the Node cell
> folds `Array.from(s)`'s code points; wasm's body drops the surrogate step — every `contentHash`
> over astral text changes on commonJS; (b) the UTF-16 units the comment names: the Node cell reads
> the native `charCodeAt` (`String.prototype.charCodeAt.call`), erlang and wasm split a code point
> into its surrogates — erlang's answers change; (c) keep commonJS's fold as the contract (wasm
> already answers it) and port it to erlang.
> **Recommendation.** (a) — one rule for every string index, and the djb2 of text is a function of
> its characters; a cached key over astral text changes once.
> **Blocks.** Nothing on wasm today (it answers commonJS); a `run/` cell over astral text on four
> targets.

### 05w-e · How much memory a wasm program has

> **Raised by:** `01-compiler/05-wasm` step 5 (`std/hash` on wasm).
> **Measured.** Every module declares `(memory (export "memory") 1)` — one 64 KiB page — and the heap
> is a bump pointer that never frees and never grows (no `memory.grow` anywhere). A program traps
> (`out of bounds memory access`) once it has allocated ~60 KiB: `s = s + "ab"` 2 000 times traps;
> one program cannot print every `std/hash` digest (the cell is three cells), and
> `hash.pbkdf2Sha256("password", "salt", 9, 32)` already traps where commonJS answers (8 iterations fit). A trap is not a wrong value, but
> the ceiling is the backend's, not the program's.
> **Options.** (a) the heap grows: every bump (`$__alloc`, `$__str_concat`, `$__str_slice`,
> `allocSlots`, `allocResultPair`) goes through one helper that calls `memory.grow` when the new
> pointer passes `memory.size` (a failed grow traps) — two new `Instr`s, `memory.size` and
> `memory.grow`, which `wasm_binary_emitter.zig` (front 18's file) must encode in two lines; every
> wasm snapshot (652 of 710) changes its helpers' text; (b) a larger fixed memory
> (`(memory … 256)`, 16 MiB) — one line per snapshot, no new instruction, a higher ceiling of the
> same kind; (c) keep one page.
> **Recommendation.** (a) — a program's memory is bounded by the host, as on the other three
> targets; (b) moves the trap, it does not remove it.
> **Blocks.** PBKDF2 at a real iteration count on wasm; any std body over text longer than a few
> KiB; one `run/` cell per module instead of three for `hash`.

### 05w-f · How a wasm body makes text from a code point

> **Raised by:** `01-compiler/05-wasm` step 5 (`unicode`, `json`, `encoding`, `querystring`).
> **Measured.** A `fn:` body reads a string's code points (`charCodeAt`, `chars`), but nothing it can
> call makes a string from one: no primitive member does (`String` has `charCodeAt`, no inverse), a
> string literal escape is `\u{…}` of a fixed code point, and decision 238 gives the vocabulary no
> form that answers a string (`op:` is numeric, an adapter's slots are numbers). `unicode`
> (`fromCodepoint`, every normalisation's output), `json` (`codepointText`, a parsed `\u` escape),
> `encoding` (`base64Decode`, `hexDecode`, `percentDecode` answer the text of decoded bytes) and so
> `querystring` all need it; a wasm build importing any of them is refused (STD-001).
> **Options.** (a) a primitive: `String.fromCodepoint(cp: i32) -> string` in `primitives.bp` (Node
> `String.fromCodePoint`, erlang `<<Cp/utf8>>`, a wasm prelude lowering writing the UTF-8 bytes),
> `charCodeAt`'s inverse on every target; the four modules' bodies build text from it, and
> `unicode.fromCodepoint` becomes `fn:` over it; (b) an adapter answering a string —
> `wasi:codepoint_text` (no WASI call), with string slots added to the adapter signatures —
> bound by each module's private `codepointText` cell; (c) leave the four modules refused on wasm
> (they join group 3).
> **Recommendation.** (a) — the language reads a code point and should write one; it is no std
> name the backend owns (decision 238's rule) but a member of `String` with an answer on every
> target, as `charCodeAt` is.
> **Blocks.** `unicode`, `json`, `encoding`, `querystring` on wasm (step 5's last group-1 box).

### 05w-g · Whether `std/math` answers the same bits on every OS

> **Raised by:** `00-gate` (`gate-macos-cells`), CI run 37092813045, job `macos-14`: `[erlang]` and
> `[beam] run/std_math_on_every_target` print `false` on lines 15 and 16 — `math.tan(1.0) ==
> 1.5574077246549023` and `math.asin(0.5) == 0.5235987755982989 && math.acos(0.5) ==
> 1.0471975511965979`; Ubuntu and the local gate print `true`. 05w-c's "commonJS × erlang row of its
> own", now across operating systems.
> **Measured.** erlang and beam bind `math.tan`/`asin`/`acos`/… to `math:tan/1`…, which OTP answers
> with the platform C library: glibc on Linux, Apple's libm on macOS. The three expected values are
> the correctly rounded doubles (mpmath, 200 bits): `tan(1)` = 1.5574077246549022305…, 0.28 ulp from
> it; `asin(0.5)` = π/6 and `acos(0.5)` = π/3 lie 0.48 ulp from theirs — almost a tie, where a libm
> that is faithful (< 1 ulp) but not correctly rounded may return the neighbour (`0.5235987755982988`,
> `1.0471975511965976`). IEEE 754-2019 §9.2 recommends correct rounding for these functions and C
> Annex F does not require it; only `sqrt` and the basic operations are required to be correctly
> rounded. glibc happens to round these inputs correctly, Apple's libm does not; commonJS answers
> fdlibm on both (V8 ships its own `ieee754` code) except `Math.pow`, which is the platform `pow`
> (05w-c), and wasm answers std's own fdlibm port on both.
> **Options.** (a) `std/math` is one function on every target and every OS: erlang and beam call the
> same private botopink bodies wasm calls through `fn:` (`tanBody`, `asinBody`, … — the fdlibm port,
> already bit-identical to commonJS on 6 539 inputs), and `pow` is the body 05w-c chooses on every
> target, commonJS included; `sqrt`, `floor`, `abs`… stay host calls, since IEEE 754 makes them
> exact everywhere; the cell stays as it is; (b) the platform libm is the contract: the cell asserts
> only what every IEEE 754 libm guarantees (exact `sqrt`, `floor`, `2^10`; transcendentals within
> 1 ulp of the reference), and a program's last bit depends on the OS it runs on; (c) the cell keeps
> exact values and erlang/beam on macOS are excluded from it (a per-OS exception in the matrix).
> **Recommendation.** (a) — one std answer per input, whatever target or OS runs it, is the reading
> the wasm port already chose; (b) turns a wrong last bit into a passing cell, and (c) is a
> tolerated red by another name (decisions 153–162). Cost: erlang/beam run botopink bodies instead of
> one C call for the transcendentals.
> **Blocks.** `[erlang]`/`[beam] run/std_math_on_every_target` on `macos-14` (red until answered);
> a `run/` cell comparing any other transcendental at a near-tie input.

---

## Open

Questions the language-gaps sweeps (`front/compiler-gaps-rakun`, the rakun rows of
[`language-gaps.md`](./language-gaps.md); `front/gaps-sweep-2`, every other row) could not answer from
`docs.md` or the decisions taken. Each `lg2-*` row of `language-gaps.md` is a feature the language does
not have; the recommendation is always the most restrictive reading — the feature stays out and the
row's nearest form is the design — and the cost of that reading is named where it is high.

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


### 02e-a · The unit of a string index on wasm

> **Raised by:** `01-compiler/02-erlang` step 6 (the `run/string_index_of_codepoints` cell, four
> targets) and step 5 (`.length()` of a non-ASCII string).
> **Measured.** Decision 169 fixed codepoints on erlang (beam agrees) and kept UTF-16 units on
> commonJS; it says nothing of wasm. On wasm every string index counts **bytes**: for
> `val s = "a—bXc";` (an em dash, three bytes) `s.length()` is `7`, `s.indexOf("X")` is `5`,
> `s.at(5)` is `X` — and `s.at(1)` / `s.slice(1, 2)` hand out the dash's first byte alone, a
> string that is not UTF-8 (erlang: `5`, `3`, `X`, `—`, `—`). No front owns the row: `05-wasm`'s
> README has no string-unit row, and `02-erlang` step 5's "bytes, 05's row" points at nothing.
> **Options.**
> (a) codepoints on wasm, as on erlang and beam — `length`, `at`, `slice`, `indexOf`,
> `lastIndexOf` walk UTF-8 sequences; the cell's `.out` is one file for four targets:
> ```botopink
> val s = "a—bXc";
> @print(s.indexOf("X"));      // 3 on commonJS, erlang, beam, wasm
> @print(s.at(1));             // — everywhere
> ```
> (b) bytes on wasm, documented as wasm's unit beside commonJS's UTF-16 — the four functions
> agree with each other, but `at` / `slice` may split a character:
> ```botopink
> @print(s.indexOf("X"));      // 3 on erlang/beam/commonJS, 5 on wasm
> @print(s.at(1));             // — on erlang, one invalid byte on wasm
> ```
> and the cell prints `s.at(s.indexOf("X"))` only (`X` everywhere), the index itself left out;
> (c) bytes on wasm, and `at` / `slice` refused at run time (a trap) when an index lands inside a
> character.
> **Recommendation.** (a) — decision 169's own reason ("one unit for every string index … so an
> index can be handed back to `at`") read onto the fourth target; (b) keeps a string that is not
> UTF-8 reachable from safe code, and (c) makes an index's validity depend on the text.
> **Blocks.** `02-erlang` step 6's cell on four targets (until then it cannot be written: wasm
> accepts the program, so no `.targets` may leave it out); the `05-wasm` row it would open.


### gw-a · What an integer that leaves its type is

> **Raised by:** `front/gate-wasm-wrong-answers` (the wasm wrong-answer sweep; `wat/AGENTS.md`
> § Numbers).
> **Measured.** No document says what `i32` / `i64` arithmetic does past the type's range, and the
> four targets answer four ways for `val big: i32 = 2147483647; @print(big + 1)`: commonJS
> `2147483648` (a JS number, never wrapped; an `i64` past `2^53` loses digits —
> `9223372036854775807` prints `9223372036854776000`), erlang and beam `2147483648` (bignums: an
> `i64` never overflows either), wasm `-2147483648` (two's complement) — a wrong value at exit 0.
> The sweep made wasm **trap** on an `i32` / `i64` `+`, `-`, `*` (and a negation, a `+=`) whose
> result leaves the type (`int_chk`), the one choice that is not a wrong number with exit 0; the
> other targets still answer the wide value, so the four disagree by an abort rather than a value.
> **Options.**
> (a) overflow is a program error on every target — commonJS and erlang check the result against
> the declared type's range and raise, as wasm traps now:
> ```botopink
> val big: i32 = 2147483647;
> @print(big + 1);   // aborts on commonJS, erlang, beam, wasm
> val w: i64 = 4611686018427387904;
> @print(w * 2);     // aborts everywhere (2^63 is not an i64)
> ```
> (b) integers wrap at their width on every target — commonJS `(a + b) | 0` (and a `BigInt.asIntN`
> path for `i64`), erlang/beam a `band` and sign fold, wasm its native ops (the checks dropped):
> ```botopink
> @print(big + 1);   // -2147483648 everywhere
> ```
> (c) integers are unbounded (the declared width is advisory) — erlang's answer; commonJS needs
> `BigInt` for every `i64`, and wasm cannot hold the result in a word, so it keeps trapping there:
> ```botopink
> @print(big + 1);   // 2147483648 on commonJS, erlang, beam; wasm aborts
> ```
> **Recommendation.** (a) — the most restrictive reading (decision 67): the value the program
> asked for does not exist in its declared type, so no target invents one; it is what wasm does
> now, and the checks on commonJS / erlang are a range test per operation. (b) makes `+` disagree
> with arithmetic every user expects; (c) leaves wasm permanently divergent.
> **Blocks.** A four-target cell for integer overflow (today only `tests/wat.zig`'s RUN LOG pins
> wasm's trap); `01-compiler/04-js` and `02-erlang` / `03-beam`'s range checks under (a).
