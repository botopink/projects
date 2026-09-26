# Front 06 — Context API, Lifecycle and Application Events

**Track:** B rakun
**Priority:** high — the container has no doors: nothing can resolve a bean, nothing runs at startup or shutdown, and nothing can react to anything
**Target:** erlang (server)
**Wave:** 2
**Depends on:** 04 · 05
**Owns:** `src/context.bp`, `src/events.bp`, `src/lifecycle.bp`, `src/rakun.d.bp` (removal of the `Context` stub only), `src/sidecars/rakun_context.erl` · `test/context_test.bp`, `test/events_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · conditional registration, which is front 72's
**Reference:** `02-desenvolvendo-com-spring-boot.md § Beans e Injecao de Dependencias` · `02 § Classes de Configuracao` · `03-recursos-principais.md § Eventos da Aplicacao` · `03 § Disponibilidade da Aplicacao` · `03 § Saida da Aplicacao` · <https://docs.spring.io/spring-boot/reference/using/spring-beans-and-dependency-injection.html> · <https://docs.spring.io/spring-boot/reference/features/spring-application.html#features.spring-application.application-events-and-listeners>

---

## Problem

rakun's IoC container works and is unreachable. Constructor injection resolves a field by type through
an emitted `__rkMake_<Type>()` factory (`decorators.bp:56`, `:59-61`), and that is the entire public
surface: if a value is not a field of something, nothing can get at it.

The intended door is already written down and explicitly not built. `src/rakun.d.bp:20-25` declares

```bp
behavior Context {
    fn resolve<T>(self: Self) -> ?T;
    fn has<T>(self: Self) -> bool;
}
```

under a header that says, at `rakun.d.bp:3-5`, "Declaration-only: the `Context` IoC-container
interface, kept as the intended shape for a future `ctx.resolve<T>()` API (**not yet implemented**).
SIGNATURES with no bodies — registered for inference only, emits nothing." This front is what
implements it.

Three more things are missing for the same reason — there is nowhere to hang them. A component cannot
run code after construction or before shutdown, so a cache cannot warm and a connection cannot close.
Nothing publishes or observes an application event, so the nine lifecycle events Spring documents
(`03-recursos-principais.md § Eventos da Aplicacao`) have no analogue at all. And nothing constructs
a component until something asks for it, so a misconfiguration surfaces on the first request that
touches it rather than at boot.

## Current state

| Piece | Where | State |
|---|---|---|
| `Context` behavior | `src/rakun.d.bp:22-25` | declaration-only, "not yet implemented" |
| Component factories | emitted `__rkMake_<Type>()` per stereotype, `decorators.bp:59-61` | works; one factory per type name |
| Scan registry | `rkScan`, `rkScannedNames` (`runtime.bp:19-26`) | records **names only** — no factory, no type, no way to call back |
| `#[bean]` | `decorators.bp:198-200` | placement marker only (`DeclKind.Method`), wired by `#[configuration]` at `:186-190`; **frozen** |
| Lifecycle hooks | — | none |
| Events | — | none |
| Eager initialization | — | none; `rkSingleton`'s thunk means everything is lazy already |
| Qualifiers, primary, scopes | — | none |

The scan registry row is the one that shapes the whole front. `rkScan("UserService")` stores a string.
Nothing can turn that string back into a constructor, so "resolve by name" cannot be built on top of
the scan — and the component decorators that *could* register a factory are frozen.

## Mechanism

### `#[managed]`: the one new type-level decorator, and why it is separate

The stereotype decorators (`#[component]`, `#[service]`, `#[repository]`, `#[controller]`,
`#[restController]`, `#[configuration]`) are frozen for the milestone, and every capability below needs
something they do not emit. A rakun decorator body also cannot call a sibling function
(`decorators.bp:44-46`), so there is no way to extend them from outside.

So front 06 adds one decorator that **stacks under** an existing stereotype, exactly the way
`#[route]` already stacks under `#[restController]` (`test/server_test.bp:17-18`):

```bp
#[service]
#[managed]
pub type UserService(repo: UserRepository) { … }
```

`#[managed]` is a type-level decorator, so it sees `decl.name`, `decl.annotations` and `decl.methods`
with each method's own annotations and parameter list (`libs/std/src/builtins.d.bp:459-477`). That is
everything the rest of this front needs, and it emits all of it in one pass:

```bp
val __rkBean_UserService = rkRegisterBean("UserService", "", false, false, { -> __rkMake_UserService() });
val __rkLc_UserService_warm = rkRegisterLifecycle("UserService", "post", 0, { -> __rkMake_UserService().warm() });
val __rkLc_UserService_close = rkRegisterLifecycle("UserService", "pre", 0, { -> __rkMake_UserService().close() });
val __rkEv_UserService_onReady = rkRegisterListener("ApplicationReady", "UserService", { ev -> __rkMake_UserService().onReady(ev) });
```

The five arguments of `rkRegisterBean` are the type name, the qualifier (from `#[qualifier("name")]`),
the primary flag (`#[primary]`), the lazy flag (`#[lazy]`), and the factory **as a value**. A registry
holding factories, not names, is what makes resolution, eager initialization and the shutdown pass all
possible from the same table.

When `decorators.bp` unfreezes, `#[managed]`'s body folds into the stereotypes and the extra line goes
away. Until then the extra line is the honest price, and the README of every front that needs a
registered bean says so.

### Method-level markers

`#[postConstruct]`, `#[preDestroy]` and `#[eventListener("ApplicationReady")]` are **placement checks
only**. They emit nothing, because a method-level `@Decl` carries no owner and no parameter list —
`Decl` exposes `kind`, `name`, `returnType` and `annotations`, and `params` exists only on the
`Method` entries inside a *type* decl (`builtins.d.bp:459-477`), so `decl.parameters[0].typeName`
inside an `#[eventListener]` body cannot be written.

This is not a workaround, it is the pattern the whole library already follows: `#[getMapping]` checks
placement (`decorators.bp:222-224`) and `#[restController]` does the wiring (`:152-159`). Front 06
uses the same split for lifecycle and events.

### `#[provides]`: a factory function, and why it is not `#[bean]`

The fold-in asks for a `#[bean]` decorator on a function whose return value enters the registry under
its type. `#[bean]` already exists and is frozen at `DeclKind.Method` (`decorators.bp:198-200`), so
front 06 delivers the function form under a second name:

```bp
#[provides]
pub fn systemClock() -> Clock {
    return Clock(zone: "UTC");
}
```

emits

```bp
pub fn __rkMake_Clock() -> Clock { return rkSingleton("Clock", { -> systemClock() }); }
val __rkBean_Clock = rkRegisterBean("Clock", "", false, false, { -> __rkMake_Clock() });
```

`decl.returnType` is available on a `Fn` decl, which is the same field `#[configuration]` already
reads off its `#[bean]` methods (`decorators.bp:189`). Two `#[provides]` functions with the same
return type collide on `__rkMake_<Type>` and the build fails on a duplicate definition — which is the
right failure and is also where qualifiers earn their place.

### Qualifiers, primary, and the tie

Constructor injection resolves a field by emitting `__rkMake_<FieldType>()` (`decorators.bp:56`), and
that name is unique by construction — there is exactly one factory per type name, so field injection
cannot be ambiguous. A tie is only reachable through the registry: two `#[provides]` functions or two
`#[bean]` methods producing the same type under different qualifiers.

`rkRegisterBean` therefore keys on `(typeName, qualifier)` and `rkResolve(typeName)` fails with

```
rakun: two beans of type 'Clock' ('systemClock', 'fixedClock') and neither is #[primary];
       resolve by qualifier, or mark one #[primary]
```

`rkResolveNamed(typeName, qualifier)` picks one. `#[primary]` marks a default for the unqualified
lookup. A tie is an error and never a silent first-wins.

### `Context`

```bp
pub type Context(scopePath: string) {
    pub fn resolve<T>(self: Self, typeName: string) -> ?T;
    pub fn resolveNamed<T>(self: Self, typeName: string, qualifier: string) -> ?T;
    pub fn has(self: Self, typeName: string) -> bool;
    pub fn beanNames(self: Self) -> Array<string>;
    pub fn child(self: Self, name: string) -> Context;
    pub fn publish(self: Self, event: Event) -> i32;
}
```

`resolve` takes the type name as a string because the type argument is not reachable at run time:
there is no `@typeName<T>()`, and explicit generic arguments do not parse at a call site. The type
therefore comes from the annotated binding —

```bp
val repo: ?UserRepository = self.ctx.resolve("UserRepository");
```

— and the pairing of `T` with the string is unchecked. Both halves of that are language gaps and both
are in the table below. The alternative, dropping the generic and returning `any`, loses the type
everywhere; the string is the smaller cost.

`Context` is itself injectable: `context.bp` emits `pub fn __rkMake_Context() -> Context`, so a field
of type `Context` wires with no extra step, and it is exempt from the cycle guard because it is
constructed before the scan runs and depends on nothing.

`child(name)` returns a context whose `resolve` looks in its own registry first and delegates upward
on a miss — Spring's parent/child contexts, and what front 62 builds the per-request scope on.

### Scopes

```bp
pub type Scope { Singleton, Prototype, Request }
```

`#[scope("prototype")]` on a `#[managed]` type or a `#[provides]` function changes what the registered
factory does: `Singleton` goes through `rkSingleton` (the default, and what field injection always
gets), `Prototype` calls the constructor on every resolve, `Request` caches in the *request process's*
dictionary so two resolves inside one request share an instance and two requests do not.

Request scope is the piece front 62 needs, and it is nearly free on the BEAM: a request is a process,
so "per request" and "per process" are the same statement. Front 06 ships the scope kind and the
storage; **front 62 owns the accessors** (`cookies()`, `headers()`, `after()`, per-request
memoization) and front 06 defines none of them.

A `Prototype` or `Request`-scoped bean cannot be a constructor-injected field, because the frozen
factory name is singleton-shaped. It is reached through `ctx.resolve`. The decorator rejects the
combination at comptime rather than letting it silently behave as a singleton.

### Events

```bp
pub type Event(
    name: string,
    source: string,
    payload: string,
    timestampMillis: i64,
)
```

One record, a string name, a string payload. The alternative — a type per event with typed listener
dispatch — needs the listener's parameter type at the method decorator, which is the reflection gap
above. A stringly event is what can actually be built, and the boundary it crosses (a `fun` in an ETS
table) is scalar anyway.

The nine lifecycle events of `03-recursos-principais.md § Eventos da Aplicacao` are published in
order by `context.bootSequence()`, which `main` calls:

`ApplicationStarting` → `ApplicationEnvironmentPrepared` (after front 05's load) →
`ApplicationContextInitialized` → `ApplicationPrepared` → `ApplicationStarted` (after the eager pass)
→ `AvailabilityChanged(LivenessCorrect)` → `ApplicationReady` (after the listener binds) →
`AvailabilityChanged(ReadinessAcceptingTraffic)`. `ApplicationFailed` is published instead of
everything after the point of failure.

Dispatch is synchronous and in registration order. A listener that raises does not stop the sequence:
the failure is logged with the listener's owner and the event continues, because a broken audit
listener must not take the boot down.

### Eager initialization is the deliverable; lazy is the default

Spring's `spring.main.lazy-initialization=true` is an opt-in because Spring is eager. rakun is the
other way round: `rkSingleton` takes a thunk (`runtime.mjs:73-78`), so nothing is constructed until
something resolves it, and an unresolved component is never built at all.

So what is missing is eagerness. `context.eagerInit()` walks the bean registry and calls every
registered factory, in registration order, skipping anything marked `#[lazy]`, and is on by default —
`rakun.main.lazy-initialization=true` skips it entirely. This is what turns a missing property or a
dependency cycle into a boot failure with front 04's diagnostics instead of a 500 on the first request
that happens to touch it.

### Shutdown, the pre-destroy pass, and exit codes

On `SIGTERM` the OTP application stops, and `rakun_context:terminate/2` runs the `pre` lifecycle
entries in **reverse registration order**, which is reverse dependency order because a component is
registered after the components it was constructed from.

Request draining is **front 07's**: it stops accepting, flips readiness false first, waits out
in-flight requests, and only then hands control here. Front 06 owns the callback pass, not the
socket.

`#[exitCode]` on a module-level function whose return is `i32` registers an exit-code generator; the
highest value returned by any generator becomes the argument to `init:stop/1`. With none registered
the status is 0 on a clean stop and 1 on a failed boot.

### `#[imports]` and additional scan roots

`#[imports("DatabaseConfig,SecurityConfig")]` on a `#[configuration]` type emits a `rkRegisterBean`
line for each named type, so a configuration record in a module the application does not otherwise
reference is still wired. This is Spring's `@Import`. "Additional scan roots" in botopink is a `pub mod`
line — module resolution is already explicit (`docs.md:34-37`) — so `@ComponentScan(basePackages=…)`
has no analogue and needs none; the README says that rather than inventing one.

## Steps

### Step 1 — The bean registry

`rkRegisterBean/5`, `rkResolve/1`, `rkResolveNamed/2`, `rkHasBean/1`, `rkBeanNames/0` in
`src/context.bp`, backed by `src/sidecars/rakun_context.erl` over an ETS table keyed
`{TypeName, Qualifier}` holding `{Primary, Lazy, Scope, Factory}`.

**Acceptance:**
- [x] `#[managed]` on a `#[service]` registers exactly one bean — held: `test/context_test.bp` "rakun context: #[managed] on a #[service] registers exactly one bean"
- [x] `rkBeanNames()` lists registered beans in declaration order — held: `test/context_test.bp` "rakun context: beanNames lists registered beans in declaration order"
- [x] Registering the same `(type, qualifier)` twice fails at boot naming both declaration sites — held: `test/context_test.bp` "rakun context: registering the same type and qualifier twice names both owners"
- [x] `rkResolve` of an unregistered type answers `null`, and `rkHasBean` answers `false` — held: `test/context_test.bp` "rakun context: an unregistered type resolves to null and has answers false"

### Step 2 — `Context`

**Acceptance:**
- [x] `val repo: ?UserRepository = ctx.resolve("UserRepository");` returns the same instance field injection returns — held: `test/context_test.bp` "rakun context: a resolved bean is the same instance field injection gives"
- [x] `ctx.has("UserRepository")` is `true`, `ctx.has("Nonexistent")` is `false` — held: `test/context_test.bp` "rakun context: ctx.resolve returns what field injection returns"
- [ ] `ctx.beanNames()` matches `rkScannedNames()` filtered to `#[managed]` types
- [x] A field of type `Context` is injected without any extra declaration — held: `test/context_test.bp` "rakun context: a field of type Context is injected with no extra declaration"
- [x] `Context` does not appear in its own `beanNames()` and does not participate in the cycle guard — held: `test/context_test.bp` "rakun context: Context is not a bean of its own registry and is not in the cycle guard"
- [x] `ctx.child("request").resolve(…)` finds a bean registered only in the parent — held: `test/context_test.bp` "rakun context: a child context finds a bean registered only in the parent"

### Step 3 — `#[provides]`, qualifiers and primary

**Acceptance:**
- [x] `#[provides] pub fn systemClock() -> Clock` makes `Clock` injectable by type — held: `test/context_test.bp` "rakun context: #[provides] makes the return type injectable by type"
- [ ] Two `#[provides]` of the same type without qualifiers fail the build naming both functions
- [x] Two with distinct `#[qualifier]`s both register, and `resolveNamed` picks each — held: `test/context_test.bp` "rakun context: two #[provides] of one type are told apart by qualifier"
- [x] An unqualified `resolve` with two candidates and no `#[primary]` fails with the message above, naming both — held: `test/context_test.bp` "rakun context: two candidates and no #[primary] name both owners"
- [x] With one marked `#[primary]`, the unqualified `resolve` returns it — held: `test/context_test.bp` "rakun context: with one candidate marked #[primary] the unqualified resolve returns it"
- [x] `#[provides]` on a function returning `void` fails at comptime — held: `src/context.bp` `provides` → `decl.fail("… returns a value …")`

### Step 4 — Lifecycle

**Acceptance:**
- [ ] `#[postConstruct]` runs after the instance is constructed and before `eagerInit` returns
- [x] It runs exactly once for a singleton, no matter how many sites resolve it — held: `test/context_test.bp` "rakun lifecycle: the post pass runs a hook exactly once and it sees its dependencies"
- [x] It can use every injected dependency — held: `test/context_test.bp` "rakun lifecycle: the post pass runs a hook exactly once and it sees its dependencies"
- [x] `#[preDestroy]` runs on shutdown, in reverse registration order — held: `test/context_test.bp` "rakun shutdown: the pre pass runs in reverse order and answers the exit code"
- [x] `#[postConstruct]` on a non-method fails at comptime with a located message — held: `src/lifecycle.bp` `postConstruct` → `decl.fail` on `decl.kind != DeclKind.Method`
- [x] A `#[postConstruct]` that raises fails the boot naming the component and the method — held: `test/context_test.bp` "rakun lifecycle: a #[postConstruct] that raises fails the boot naming both"

### Step 5 — Events

**Acceptance:**
- [x] `#[eventListener("ApplicationReady")]` receives the event — held: `test/events_test.bp` "rakun events: the eight boot events publish in the documented order" (listener log carries `ApplicationReady:`)
- [x] Two listeners for one event both run, in registration order — held: `test/events_test.bp` "rakun events: two listeners for one event both run, in registration order"
- [x] A listener for an event that is never published never runs and is not an error — held: `test/events_test.bp` "rakun events: a listener for an event never published never runs and is not an error"
- [x] `ctx.publish(Event(name: "OrderPlaced", …))` reaches an application listener — held: `test/events_test.bp` "rakun events: ctx.publish reaches an application listener"
- [x] A listener that raises is logged with its owner and does not stop the sequence or the other listeners — held: `test/events_test.bp` "rakun events: a listener that raises is logged with its owner and stops nothing"
- [x] The eight boot events are published in the documented order, and `ApplicationFailed` replaces the tail when the boot fails — held: `test/events_test.bp` "rakun events: the eight boot events publish in the documented order" + "ApplicationFailed replaces the tail when a #[postConstruct] raises"

### Step 6 — Scopes

**Acceptance:**
- [x] A `Prototype` bean returns a distinct instance per `resolve` — held: `test/context_test.bp` "rakun scope: a prototype bean is constructed on every resolve"
- [x] A `Request` bean returns one instance within a request and a different one in the next request — held: `test/context_test.bp` "rakun scope: a request bean is one instance within a request and another in the next"
- [x] Two concurrent requests each get their own `Request` instance — held: `test/context_test.bp` "rakun scope: two concurrent requests each get their own request instance" (rakun `d982052`)
- [ ] `#[scope("request")]` on a type whose factory is constructor-injected somewhere fails at comptime naming the injection site's limitation

### Step 7 — Eager initialization and lazy

**Acceptance:**
- [ ] With defaults, every registered bean is constructed before `Rakun.run` returns
- [ ] A component whose `#[value]` key is missing fails the boot, not the first request
- [x] `rakun.main.lazy-initialization=true` constructs nothing at boot — held: `test/context_test.bp` "rakun eager: rakun.main.lazy-initialization=true constructs nothing at boot"
- [x] `#[lazy]` on one component excludes only that one — held: `test/context_test.bp` "rakun eager: #[lazy] excludes only the bean that carries it"
- [x] Eager initialization of a cyclic graph reports the cycle through front 04's diagnostics — held: `test/context_test.bp` "rakun eager: a cyclic graph fails the boot through front 04's cycle guard"

### Step 8 — Shutdown and exit codes

**Acceptance:**
- [x] `SIGTERM` runs every `#[preDestroy]` in reverse registration order before the node stops — held: `modules/rakun-web/test/shutdown_test.bp` "SIGTERM runs the installed hook instead of stopping the node" (`installShutdownHook` = `gracefulShutdown()` then halt) + "the #[preDestroy] pass runs after the drain" + `modules/rakun/test/context_test.bp` "the pre pass runs in reverse order and answers the exit code"
- [x] `#[exitCode]` functions are consulted and the highest value is the process status — held: `test/context_test.bp` "rakun shutdown: the highest generator wins and none means zero"
- [ ] With no generator, a clean stop is status 0 and a failed boot is non-zero
- [x] A `#[preDestroy]` that raises is logged and does not prevent the remaining ones from running — held: `test/context_test.bp` "rakun shutdown: a #[preDestroy] that raises is logged and the rest still run"

### Step 9 — Retire the `rakun.d.bp` stub

`src/rakun.d.bp:20-25` declares a declaration-only `behavior Context` that this front replaces with a
concrete `pub type Context`. `rakun.d.bp` is loaded for consumers through `botopink.json`'s `files`
list, so leaving the stub in place puts **two** `Context` declarations into every consumer's
namespace. The stub goes, and the file's docblock — which currently advertises `Context` as "the
intended shape for a future `ctx.resolve<T>()` API (not yet implemented)" (`rakun.d.bp:3-5`) — is
updated to say it was implemented and where.

This front touches nothing else in `rakun.d.bp`.

**Acceptance:**
- [x] `behavior Context` is gone from `src/rakun.d.bp` and the docblock no longer calls it unimplemented — held: `src/rakun.d.bp` declares nothing; docblock records the stub as removed
- [x] `import {Context} from "rakun"` in a consumer resolves to the concrete record, with no ambiguity diagnostic — held: `examples/rakun-container/src/main.bp` (`import {Context, Event, event, __rkMake_Context} from "rakun"`), built by the pre-commit examples gate
- [ ] A consumer that previously named the behavior in a signature still compiles, because the concrete type carries `resolve`/`has` with the same names
- [x] `botopink.json`'s `files` list still loads `rakun.d.bp`, and nothing else in it changed — held: `modules/rakun/botopink.json` `files` still lists `rakun.d.bp`

## Examples

- [`examples/context-lifecycle-example.bp`](./examples/context-lifecycle-example.bp) — a developer
  using `#[managed]`, `#[postConstruct]`, `#[preDestroy]`, `#[provides]` with a qualifier,
  programmatic `ctx.resolve`, and an application event published from a controller and observed by a
  listener.

## Language gaps

The milestone register is [`language-gaps.md`](../../language-gaps.md); the rows below are this front's entries in it, and the cross-front wire formats they touch are in [`contracts.md`](../../contracts.md).

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A method-level `@Decl` exposes no owner and no parameter list. `Decl` carries `kind`/`name`/`fields`/`variants`/`methods`/`returnType`/`annotations` (`builtins.d.bp:459-477`) and `Param` lives only on `Method` entries of a *type* decl, so `#[eventListener]` cannot read its event parameter's type and `#[postConstruct]` cannot name its owner's factory. | `examples/context-lifecycle-example.bp` — every method marker is placement-only; the wiring is emitted by the type-level `#[managed]` | Put the wiring in the type-level decorator, which does see `decl.methods[].params` | `decl.owner` and `decl.params` on a `DeclKind.Method` handle. Then `#[managed]` is unnecessary and the stereotypes need no stacking partner |
| Explicit generic arguments do not parse at a call site, so `ctx.resolve<UserRepository>()` is not writable; the type must come from an annotated binding. | `examples/context-lifecycle-example.bp`, `val repo: ?UserRepository = ctx.resolve("UserRepository");` | Annotate the binding and pass the name as a string | `f<T>(args)` at a call site |
| There is no way to obtain a type's name from a type parameter — no `@typeName<T>()` — so the registry key has to be passed as a string that nothing checks against `T`. | same line | Pass the string; accept that `resolve<Foo>("Bar")` type-checks and returns `null` | `@typeName<T>() -> string`, which would also remove the string from `resolve` entirely |
| A decorator cannot rewrite or wrap the body of the declaration it annotates; `@emit` only adds new module-level declarations (`decorators.bp:48-240` — every rakun decorator emits `val`s and `fn`s and touches no body). | Not visible in this front's example, because every hook here is a *registration*. It is why front 08's `#[transactional]` needs a proxy type. | Emit a wrapper declaration and route callers through it | A body-rewriting emission, or `decl.wrapBody(expr)` |

## Test plan

`test/context_test.bp` and `test/events_test.bp`, `botopink test --target erlang` from
`repository/rakun/`, and `zig build test-libs -- --target erlang --lib rakun` in the gate.

`context_test.bp` covers the registry, resolution, qualifiers, scopes and eager initialization.
`events_test.bp` covers listener dispatch, ordering, the boot sequence and the failure path. The boot
sequence is asserted by registering a listener for every one of the eight events that appends its name
to an ETS list, then comparing the list to the documented order — which also catches a reordering that
a per-event test would not.

Shutdown is tested by calling the terminate pass directly rather than by sending a real `SIGTERM`, so
the test does not take the runner down. The real signal path is covered once, in front 07's graceful
shutdown tests, where it belongs.

Erlang-only. The commonJS row has no bean registry and is not expected to grow one.

## Adjacent fronts

- **72-rakun-auto-configuration** is the conditional layer: `#[conditionalOnMissingBean]`,
  `#[conditionalOnProperty]`, `#[profile]`, ordering and the condition report. Front 06 builds the
  registry those conditions read and **no conditions of its own**.
- **62-rakun-request-context** owns the per-request accessors. Front 06 ships the `Request` scope and
  its storage; it defines no accessor.
- **07-rakun-middleware** owns graceful shutdown and request draining, and calls this front's
  pre-destroy pass after the drain.
- **11-rakun-actuator** serves `beans` by reading `ctx.beanNames()`.
- **17-rakun-logging** owns the startup summary line; front 06 publishes the event it fires on.

## Contradictions with fronts.md

1. **Resolved:** `src/rakun.d.bp` is now in this front's ownership row, scoped to removing the
   declaration-only `Context` (Step 9). The sidecar is `src/sidecars/rakun_context.erl`, per the
   mandated `rakun_<name>` form.
2. **Resolved:** `src/root.bp` and `botopink.json` belong to **front 04**. This front appends
   `pub mod context;`, `pub mod events;` and `pub mod lifecycle;` to `root.bp`, and its declaration
   surface to the manifest's `files` list, in front-number order and reordering nothing.

## Definition of done

- [x] `src/context.bp`, `src/events.bp`, `src/lifecycle.bp` exist; `src/sidecars/rakun_context.erl`
      compiles under `erlc` — held: the three modules exist; `erlc -Werror src/sidecars/rakun_context.erl` is clean
- [x] `rakun.d.bp`'s declaration-only `Context` is gone and the concrete one is reachable as
      `import {Context} from "rakun"` — held: `src/rakun.d.bp` empty of declarations; `examples/rakun-container/src/main.bp` imports `Context` from `"rakun"`
- [x] `#[managed]`, `#[provides]`, `#[qualifier]`, `#[primary]`, `#[lazy]`, `#[scope]`, `#[imports]`,
      `#[postConstruct]`, `#[preDestroy]`, `#[eventListener]`, `#[exitCode]` all exist with placement
      checks and located failure messages — held: `src/context.bp` / `src/lifecycle.bp` / `src/events.bp` — every marker's body opens with a `decl.fail` placement check
- [x] The eight boot events publish in order, with `ApplicationFailed` replacing the tail on failure — held: `test/events_test.bp` "rakun events: the eight boot events publish in the documented order" + "ApplicationFailed replaces the tail …"
- [x] Eager initialization is on by default and turns a misconfiguration into a boot failure — held: `src/context.bp` `bootSequenceFor/1` (eager unless `rakun.main.lazy-initialization`); `test/context_test.bp` "rakun eager: a cyclic graph fails the boot through front 04's cycle guard"
- [x] The pre-destroy pass runs in reverse registration order — held: `test/context_test.bp` "rakun lifecycle: the pre pass runs in reverse registration order"
- [x] `repository/rakun/AGENTS.md` documents `#[managed]` and why it stacks rather than replaces — held: `repository/rakun/AGENTS.md` § `#[managed]` stacks, it does not replace
- [x] The front's tests are green on its assigned target — held: `modules/rakun` `botopink test --target erlang` 310/0
