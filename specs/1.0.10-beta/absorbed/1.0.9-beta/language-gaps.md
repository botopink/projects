# Language gaps — 1.0.9-beta

The compiler is frozen for this milestone. Every front here is built from plain botopink plus
`@Decl`, comptime, `@emit` and `#[@external]`, and a front that needs a compiler change does not get
one. What it does instead is write the nearest form that parses today, mark the line
`// LANGUAGE GAP:`, and record the gap here.

This file is the feed for `specs/1.0.10-beta/`. The exit gate in [`fronts.md`](./fronts.md) requires
every `// LANGUAGE GAP:` marker left in an example to appear in a spec there — a gap that exists
only as a comment in a `.bp` file is a gap nobody will fix.

Rows are added as fronts are written. A row names the gap, where it bites, what the nearest valid
form is today, and what surface would close it.

## Confirmed gaps

| Gap | Bites | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **No bitwise operators** — `&`, `\|`, `^`, `<<`, `>>` do not exist | 01 · 03 · 68 | Push the whole operation into an `#[@External]` host template, once per target | The five operators on the integer behaviors |
| **No `toString(radix)`** on the integer behaviors | 01 · 03 | Same — a host template per target | A radix argument, or a `std/fmt` module that does it in botopink |
| **No byte or binary type** | 01 · 13 · 15 · 24 · 25 · 70 · 71 | Every host cell marshals through `string`, so `net.recv` answers UTF-8 for a byte stream. Front 25 refuses `multipart/form-data` with 415 rather than read it lossily | A `Bytes` primitive with a declared encoding boundary. Without it no file upload, no file download and no image endpoint is expressible |
| **A std module cannot call another std module** — a cross-module bare import of an `#[@External]` symbol is `undefined` at runtime | 01 | Each module re-declares its own host cell | Fix the lowering so a bare import of an external symbol resolves |
| **No array destructuring in a binding** — `val [a, b] = xs;` does not parse | 02 | `xs.at(0)`, `xs.at(1)` | Destructuring patterns in `val`/`var` |
| **`@Future<T>` lowers eagerly on erlang** — the type carries no concurrency on the server target (`libs/std/src/http.bp:16-18`) | 02 · 23 · 25 · 28 · 30 · 60 | Design over **unstarted thunks** (`Array<fn() -> @Future<T>>`) and spawn one BEAM process per task, gathering by index — which is what front 02 now provides | A real scheduler behind `@Future` on BEAM, or an explicit `spawn`/`join` pair in the language |
| **A decorator cannot rewrite or wrap the body it annotates** — `@emit` only adds module-level declarations (`rakun/src/decorators.bp:48-240` is the proof: every decorator emits `val`s and `fn`s and touches no body) | 06 · 07 · 08 · 10 · 12 · 16 · 83 — **the headline gap for track B** | `#[transactional]`, `#[secured]`, `#[cacheable]` are delivered as **emitted proxy types** (`<Type>Tx`, `<Type>Sec`) injected by name; `'use cache'` on a plain fn becomes the `cacheThrough(policy, keys, load)` combinator | A decorator form that receives and returns the annotated body |
| **A decorator cannot read the body of the declaration it annotates** — `@Decl` exposes kind/name/fields/methods/params/annotations and no statements | 83 | A saga is a value pairing each step with its compensation, not a decorated fn | Statement access on `@Decl`, or a body-walking comptime API |
| **A method-level `@Decl` carries no owner and no parameter list** — `Param` exists only on `Method` entries of a *type* decl (`builtins.d.bp:459-477`) | 06 · 07 · 08 · 09 · 10 · 29 | Method-level markers are placement-only; the **type-level decorator does every `@emit`** — the pattern `#[restController]`/`#[getMapping]` already uses. Front 29 needed a second decorator on the props record to check serializability | `owner` and `params` on a method-level `@Decl` |
| **A function cannot forward a `@Result` value** — `-> @Result<…>` requires `#[@result]`, and inside it `return r` re-wraps | 04 · 08 · 09 · 79 | The doubled `query`/`tryQuery` surface | A `return` that passes a `@Result` through unchanged |
| **Explicit generic arguments do not parse at a call site** — `ctx.resolve<UserRepository>()` is unwritable | 06 | The type comes from an annotated binding: `val repo: UserRepository = ctx.resolve();` | Turbofish or angle-bracket call arguments |
| **A decorator argument cannot name a type** — arguments are ordinary values and there is no type-of-type, so `#[conditionalOnMissingBean(MailSender)]` does not compile | 72 · 78 | The type's name as a string (Spring's own `excludeName` spelling) | Type-valued decorator arguments |
| **No `@typeName<T>()`** — a registry key cannot be derived from a type | 06 | The key travels as an unchecked string beside `T` | A comptime type-name intrinsic |
| **No typed raise and no catch by type** — `throw` is legal only in `#[@result]` and yields a value; `try/catch` works over `@Result` alone | 07 · 31 · 63 | `#[exceptionHandler("string.tag")]` instead of by type; navigation signals are `erlang:throw` on the host side | Typed error values, or a `catch` arm that matches on a tag |
| **A decorator argument is a raw lexeme** — an array literal there is unverified | 07 | `#[crossOrigin("origin", "GET,POST")]` — comma-joined strings | Typed decorator arguments |
| **A decorator body cannot accumulate comptime state across invocations** | 05 | Front 05's key catalogue is a run-time registry dumped from a headless boot, not a comptime document | Comptime mutable state scoped to a compilation |
| **No comptime reflection over the project** — no way to enumerate a package's modules or read its manifest | 81 | The release's application list and SBOM component set are hand-written or discovered by a build-time filesystem walk | A comptime `@project()` intrinsic |
| **No bottom/never type** — `notFound()` and `redirect()` cannot return, but must declare a return type | 63 | Every call site binds `val _gone = notFound();` to a value never produced | `never`, making code after a signal a compile error |
| **No record-update expression** — "override the ancestor field by field" cannot be a mutation | 60 | A constructor over seven `case` results | `SegmentConfig(base, revalidate: 60)` |
| **No module-level annotation** — Next's file-level `'use cache'` has no spelling | 12 | A module-level `val` holding the default policy | An inner attribute, `#![useCache]` |
| **`use` is legal only on `@Context<Element, _>` inside a `-> Element` body** — a server component returns `@Future<Element>`, so `use request()` cannot be written; this is why `server.d.bp` stayed gated | 28 | Request-scoped values come from front 62's accessors as ordinary calls | `use` inside a `#[@future]` component body |
| **`Children` coerces from array, `Element` and `string` but not from a thunk** (`infer.zig:4228-4239`) | 30 | A Suspense boundary takes its child as a named field, not as a child | Thunk coercion into `Children` |
| **`await` is unusable as a lambda's last statement** — nothing can `map` over resolves | 28 · 30 | Lift into a named `#[@future]` fn | Allow `await` in closure tail position |
| **`pub val` of a user record type is unexercised** — only primitive `pub val`s exist in the tree (`math.bp:16`, `path.bp:13`) | 32 | Metadata exports are functions, not values | Verify or reject `pub val` of a record at module scope |
| **A comptime body has no filesystem access** — it sees only a minimal native-JS prelude, so a `wsdl """…"""` template cannot read a schema file | 88 · 93 | `rakun ws generate` emits checked-in `.bp`; scaffolding is a runtime copy | A sandboxed comptime build-input read |
| **Tuple labels are lost through generic instantiation** | 89 | Positional access after a generic hop | Preserve labels on instantiated tuple types |
| **No cancellation** — a losing racer and an expired timeout keep running | 02 | Document it; let the work complete and discard the result | Cancellation tokens, or linked processes with a kill path |
| **`@Decl` carries no source location** — a decorator cannot learn which file it annotates | 22 | The app-relative segment is an explicit decorator argument, generated and verified by front 50's CLI | A source-location field on `@Decl`. This is the defining premise of file-system routing, so the workaround is a CLI that must stay in step with the tree |
| **No `await` inside a `loop` or a closure** — the effect marker attaches to the fn, not the closure | 23 · 24 · 25 | Lift the awaited call out of the loop, or move the body into its own `#[@future]` fn | Allow the marker on a closure, or infer it |
| **Declared parameter defaults are never applied** | every front | Pass every argument explicitly — this is why every jhonstart call spells `attrs:`, and why `LayoutProps` is one record rather than three parameters | Apply declared defaults at the call site |
| **No assignment to a `self` field** | 18 · 26 · 27 · 31 · 32 · 62 · 67 · 69 · 70 · 71 · 78 · 83 · 87 | Return a new value; `withAttribute` + explicit `store.save` for sessions (forgetting the save is uncatchable); front 62's request frame lives in the host process dictionary because of it | Either a mutable field form, or a documented statement that records are immutable by design |
| **No bodyless method in a `type` body** | 08 · 09 · 78 | Give the method a body that calls a generated helper, or declare it at module level as `pub declare fn` with a host cell | Bodyless method declarations inside a `type`, as the natural shape for `#[query]`-style decorators |
| **A dot-shorthand path followed by a payload call does not propagate the typed-array context inside an array literal** — `[.Color.Hex("#abc")]`, `[.Arb.Value(prop: …)]`, `[.Container.At.Md(inner)]` do not parse (`repository/emilia/src/emilia.bp:498-503`) | 33 · 34 · 40 · 41–48 · 57 · 58 — every consumer of a payload-carrying token | A typed `val` intermediate, or a wrapper fn returning the token | Let the array's element type drive dot-shorthand resolution through the call |
| **A payload leaf nested inside an enum section cannot be constructed by any spelling** — verified against `zig-out/bin/botopink`: `Tok.Color.Hex("#abc")` → `'Hex' is not declared in any behavior implemented for 'Tok'`; `val h: Tok = .Color.Hex("#abc")` → `unbound variable 'Color'`. A top-level `Tok.Raw("#abc")` constructs, destructures and runs. **So `Color.Hex(value: string)` in today's `tokens.bp` is dead surface — declared, pattern-matched, unreachable.** | 33 · 40 · 46 · 47 · 57 | Every payload-carrying variant is a **top-level `Token` variant** (`Token.Arb(prop, value)`, `Token.InteractAccent(value)`), never a section leaf | Let the section-path resolver accept a trailing payload call |
| **A section-typed value cannot be constructed standalone** — `val a: Tok.Alpha = .50;` → `this token cannot appear here` — so a payload variant cannot take a section-typed field | 33 | Payload fields are builtin-typed (`i32`, `string`, `Token[]`): `Token.Alpha(percent: 50, inner: xs)` | Dot-shorthand rooted at the parameter's declared section type |
| **`#[@future]` and `#[@iterator]` cannot both mark one fn** — a streamed render is a per-chunk callback, not an async iterator | 69 | `collectChunk(sink, holeId)` called per boundary | Composable effect markers |
| **No module-graph reflection** — `@Decl` exposes declarations, not imports | 68 | `importsOf` is a textual scan that fails loudly on an unparsable line | An `imports` field on the module `@Decl` |
| **`if (a && b)` does not parse in condition position** — a compound boolean must be bound first | 53 · 60 | `val ok = a && b; if (ok) { … }` | Accept a boolean expression directly as the condition |
| **A package import alias is parsed and then ignored** — `parser/decls.zig:242-258` reads `as`, nothing downstream reads `.alias` for a package import, so `import {main as mainTag}` still binds `main` | 94 | Ship the constructor under a non-colliding name (`htmlTag`, `timeTag`) and document the `main` collision with `el("main", …)` as the remedy | Honour the alias in the binder |
| **No spelling for a negative numeric enum leaf** — numeric leaves are bare digits, so `-rotate-12`, `-translate-y-2` and every negative utility have no direct token | 35 · 36 · 45 | A `Neg { … }` sub-section convention (front 45 ships it) | A signed numeric leaf, or a unary `-` on enum paths |
| **No expression-position decorator** — a decorator is `@Decl`-first and annotates a declaration, so `#[emilia([.Pad.All.4])] div(…)` cannot exist; compounded by the sibling-fn rule, since a decorator body cannot call `emilia()` | 48 | Plain function calls | Expression-position decorators, or a comptime call form that runs in the eval script |
| **`xs[0]` silently drops the index on the BEAM backend** | every server front | `.at(i)`, `.first()`, `.slice(…)` | Fix the beam lowering, or reject the index expression at compile time rather than mis-compiling it |

## Toolchain gaps — not the language, the compiler-cli

| Gap | Bites | Nearest form today | Fix |
|---|---|---|---|
| **A built erlang program cannot load its `.erl` sidecars** — `__bp_load_siblings/0` is emitted only under the test flag (`codegen/erlang.zig:1650-1670`) | 04 · 81 · 85 — every server front that ships a host module | Fully green under `botopink test --target erlang`; **cannot demonstrate `botopink run` serving HTTP on the BEAM**. Front 81's "the tarball starts and serves" acceptance is gated on it | One emitter change in `codegen/erlang.zig`: emit the sibling loader for `build` entry points too. Belongs to whoever owns the erlang entry-point emitter, not to rakun |
| **A sidecar cannot reach an external OTP application** — the sidecar path loads `.erl` files beside the emitted module, not a dependency tree | 04 (why `gen_tcp` and not cowboy) · 85 (why the default SMTP client is over `std/net` and `gen_smtp` is an adapter that fails loudly) | Dependency-free implementations over OTP's own applications (`gen_tcp`, `ssl`, `crypto`) | A dependency declaration in `botopink.json` that the erlang build resolves into the release's application list |
| **`DepSpec` has no subdirectory field** — a dependency is `{git, path, ref}`, and every `rakun-*` module is a directory inside one repository, so an out-of-tree consumer cannot install a starter from git | 73 | A `path` dependency; front 73 cannot ship a git-installable starter this milestone | A `subdir` field on `DepSpec`, resolved by `bpmp` |
| **Sidecar module atoms collide with emitted basenames** — `shipErlSidecars` skips any atom matching a module this build emitted (`libs.zig:596`), and the failure is silent: the build succeeds and the program dies with `undefined function runtime:scan/1` | every front naming a sidecar | **Every sidecar is `src/sidecars/rakun_<name>.erl`**, never a bare `<name>.erl` that shadows an emitted `rakun/<name>` module | Make the collision a build error |

## Unowned surface — not language gaps, but nobody's front

These came out of writing the fronts and have no owner. Each needs a decision before the wave that
needs it starts.

| Missing thing | First needed by | Note |
|---|---|---|
| **A std JSON walker** | 24 · 25 | `std/json` has no structured value, so a route handler can validate a body and return raw text and nothing more. Candidate for 1.0.10-beta, or a fold-in to a std front |
| ~~A `Request` test double~~ | — | **Closed: front 19 owns it** as a stable API (method, path, query, headers, cookies, body, response assertion helpers) |
| ~~New jhonstart element constructors~~ | — | **Closed: front 94 `jhonstart-element-surface` owns `repository/jhonstart/src/elements.bp`.** Fronts 24, 27, 31, 67, 85 and 53 switch to importing from it |
| ~~The client-navigation reconciler~~ | — | **Closed: front 27 owns it** — `repository/jhonstart/src/reconcile.bp`, `layoutKeys(segments)` and `sharedDepth(current, target)` as pure functions; front 68 generates the entry that calls it |
| **Module-level `pub val` of a user-defined type** — fronts 32 (`metadata`) and 70 (`§18`'s route surface) both export one, and it is unverified in the tree | 32 · 70 | Both use the same answer: a zero-argument `pub fn` | Verify or reject at the language level |
| **`pairValue`** — imported from `"jhonstart"` by fronts 26, 28 and 32, one name, no stated owner | 26 · 28 · 32 | **Assigned to front 26** (the router; it is the first consumer and owns the pair-list decoding) | — |
| ~~A response-header surface on `Response`~~ | — | **Closed: front 07 owns `withHeader`/`withHeaders`** over front 04's `rkSetReplyHeader/2` (replace-by-name; `Set-Cookie` through it is a boot-time rejection naming front 62's list API; `Vary` is the one union exception) |
