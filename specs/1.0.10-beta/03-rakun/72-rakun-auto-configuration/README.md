# Front 72 — rakun Auto-Configuration

> **Amended 2026-09-21, on landing (rakun `10b6898`, 302 → 346 · 300 → 344).** Five corrections the
> front measured rather than assumed. Three are substantive.
>
> **1 · "erlang-only, and the lib test runner is told so" is not satisfiable.** There is no per-file
> target gate. `botopink test` compiles every `test/*.bp` on **both** rows
> (`compiler-cli/src/cli/test_cmd.zig`), and the only whitelist is per-**lib** (`botopink.json`
> `targets`, `lib-test-runner/src/discovery.zig`), which for rakun core is `["commonJS"]`. An
> erlang-only host cell would therefore red the node row *and* never run in the gate — the § Test
> plan and the host-seam table are amended to front 06's precedent: both halves shipped.
>
> **2 · `rkAutoApply` / `rkAutoMatched` / `rkAutoReport` / `rkModulePresent` are botopink, not host
> cells.** Names and signatures are unchanged. Nothing this front stores is a fun — four strings per
> row — so by front 06's own measurement the host is an append-only table, and the sort, the
> evaluator, the refusals and the renderer are one implementation compiled twice. Read "a new kind of
> condition adds a branch in `rakun_autoconfig:evaluate/2`" as "a branch in `conditions.bp`'s
> `evaluateRecord`".
>
> **3 · The registration signature was missing a datum.** A `#[bean]` method's *provided type* is not
> derivable from `Type.method`, so an applied configuration would be invisible to a later
> `#[conditionalOnMissingBean]`. It landed as a separate cell (`rkAutoProvides(name, typeName)` /
> `rkAutoProvided(name)`) rather than a sixth letter in the `M|P|B|X|F` blob, specifically so
> `rkAutoConditions` stays byte-equal to what this document's examples assert.
>
> **4 · `examples/override-and-report-example.bp` contradicts its own acceptance.** Its middle tests
> call `autoConfigure()` again expecting re-evaluation after a property change; its last test asserts
> idempotence. The acceptance won — `rkAutoUnseal()` exists for a test that wants a second pass.
>
> **5 · `examples/mail-auto-configuration-example.bp` will not compile as written.**
> `RakunMailAutoConfiguration` and `RakunMailDevAutoConfiguration` both declare
> `#[bean] mailSender -> MailSender`, which emits two `pub fn __rkMake_MailSender` in one module.
>
> One narrowing, recorded in the library's `AGENTS.md` and not a spec error: `#[profile]` cannot gate
> `__rkMake_<Type>` while `decorators.bp` is frozen — it emits the factory unconditionally. The
> marker therefore leaves the component **unbuilt** (`rkBuildCount` stays 0, asserted) and emits a
> raiser carrying the diagnosis, rather than a duplicate factory. It goes away when `decorators.bp`
> unfreezes.

**Track:** B rakun
**Priority:** critical — without it every `rakun-*` module must be wired by hand in every application, and "add the module, it configures itself" — the single promise that distinguishes Spring Boot from Spring — is absent from the port
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 04 · 05 · 06
**Owns:** `src/autoconfig.bp`, `src/conditions.bp`, `src/condition_report.bp`, `src/autoconfig_registry.bp`, `src/sidecars/rakun_autoconfig.erl` · `test/autoconfig_test.bp`, `test/conditions_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — the four files frozen for the milestone. Also not `src/context.bp`/`src/events.bp`/`src/lifecycle.bp`: front 06 owns the registry, this front owns only the predicate over it.
**Reference:** `02-desenvolvendo-com-spring-boot.md § Auto-configuracao`, `§ @SpringBootApplication · Personalizando` · `11-topicos-avancados.md § Auto-configuration Classes` · `09-actuator.md § Endpoints (conditions)` · <https://docs.spring.io/spring-boot/reference/using/auto-configuration.html> · <https://docs.spring.io/spring-boot/reference/features/developing-auto-configuration.html>

---

## Problem

rakun has a container and no way to condition anything on anything. `#[component]`, `#[service]`,
`#[repository]`, `#[controller]`, `#[restController]` and `#[configuration]` each emit an
unconditional `rkScan("Name")` plus an unconditional singleton factory
(`repository/rakun/src/decorators.bp:48-193`). A type that carries one of those markers is registered,
always, in every application, on every profile. There is no form of "register this only if the
application did not supply its own", no form of "register this only if the `rakun-data` module is
actually a dependency", and no form of "register this only on the `prod` profile".

That is not a missing convenience. It is what makes a framework module impossible to ship. Suppose
`rakun-data` wants to provide a default `DataSource` built from `rakun.datasource.url`. Today it has
exactly two options: mark it `#[component]`, in which case it is built in every application that pulls
the module in, including the ones that already declare their own `DataSource` and the ones that have
no database at all; or do not mark it, in which case every application writes the wiring by hand and
the module is a library of types rather than a subsystem that configures itself. Spring's answer to
that is `@ConditionalOnMissingBean` plus `@ConditionalOnClass`, and it is the reason a Spring Boot
application is thirty lines instead of three hundred.

The second half is the report. Spring's `--debug` prints which auto-configurations matched, which did
not, and the reason for each (`02 § Descobrindo o que esta sendo auto-configurado`), and the actuator
serves the same data at `conditions`. Without it, conditional registration is a black box: a bean that
was not created is indistinguishable from a bean that was created and then overwritten, and the
developer's only tool is deleting code until something changes.

## Current state

| Piece | Where it is today |
|---|---|
| Component markers, all unconditional | `src/decorators.bp:48-193` — six near-identical bodies, duplicated because a decorator body cannot call a sibling fn |
| Field-level annotation reading (the pattern this front reuses) | `src/decorators.bp:52-53` — `f.annotations.forEach({ a -> if (a.name == "value") … })` |
| Method-level annotation reading (the pattern for `#[bean]`) | `src/decorators.bp:108-193` — `#[controller]` walks `decl.methods` looking for `#[getMapping]` |
| The reflection handle | `libs/std/src/builtins.d.bp:465-477` — `kind`, `name`, `fields`, `variants`, `methods`, `returnType`, `annotations`, `fail`, `failAt` |
| What is registered at run time | `rkScan`/`rkScannedNames`/`rkScannedCount` (`src/runtime.bp:19-26`) — a flat ordered list of names |
| Conditions | none |
| Ordering between configurations | none — registration order is module load order and nothing controls it |
| `conditions` actuator endpoint | nothing behind it; front 11 lists the endpoint |
| `#[profile]` | does not exist |

`rkScannedNames()` is the one piece worth naming precisely, because this front is built on it: it
already returns every registered component name, comma-joined in declaration order. That is exactly
the input `#[conditionalOnBean]` and `#[conditionalOnMissingBean]` need, and it means the bean-presence
predicate costs no new registry — only a decision about *when* it is evaluated.

## Mechanism

### What Spring actually does, in four steps

1. Every auto-configuration class is named in a `META-INF/spring/…AutoConfiguration.imports` file, so
   the set is known before any of them is loaded.
2. Each is filtered by its `@Conditional*` annotations, evaluated against the classpath and against
   the bean factory as it stands at that moment.
3. `@AutoConfigureBefore`/`@AutoConfigureAfter` order the survivors, so a later one can ask "did
   anybody already define a `DataSource`" and get a true answer.
4. The `@Bean` methods of the survivors are registered, and every decision — matched or not, and why —
   is recorded for the report.

### What replaces each step here

**Step 1 — the import file becomes comptime.** botopink has no classpath and no reflective scan, and
it does not need one: `#[autoConfiguration]` is a decorator, so the compiler hands the body the
declaration it sits on, at compile time, with its annotations already reflected. The body emits a
`rkAutoRegister(...)` call into the module, so the set of auto-configurations is exactly the set of
annotated types in the modules the build actually compiled. This is strictly more reliable than
Spring's version — there is no file to forget to update, and a typo is a compile error rather than a
silently-missing configuration.

**Step 2 — the classpath check becomes a manifest check.** `@ConditionalOnClass` asks "is this type on
the classpath". The botopink equivalent is "is this module a declared dependency", which the manifest
answers: `botopink.json`'s `dependencies` field, normalised by
`modules/compiler-cli/src/cli/config.zig:64-73` into `[]DepEntry` whichever of the two on-disk shapes
it uses. `#[conditionalOnModule("rakun-data")]` is that question. It is evaluated at run time rather
than comptime because the host can read the manifest and the decorator body cannot — see *What the
decorator body may not do* below.

**Step 3 — ordering is a real topological sort, not a hope.** `rkAutoApply/1` builds the edge set from
the `before`/`after` lists, sorts, and *then* evaluates conditions in that order. Evaluating in
registration order would make `#[conditionalOnMissingBean]` answer differently depending on module
load order, which is the class of bug that makes people distrust a framework.

**Step 4 — the report is a value, not a log line.** `rkAutoReport/0` returns the whole decision table
as a string; `condition_report.bp` renders it for `--debug` and front 11 serves the same string at
`/actuator/conditions`. One producer, two consumers.

### The wire format for conditions

A decorator body can emit one string literal per `@emit`, and `libs/std/src/json.bp:36` is
`string -> @Result<string, string>` with no structured walker, so JSON would have to be re-parsed by
hand on the far side. The conditions therefore travel as a line-oriented blob, the same choice front 22
made for the route table and for the same reason:

```
M|rakun-data        the named module is a declared dependency
P|rakun.mail.host|* the property is set; `*` means "any non-empty value", otherwise an exact match
B|DataSource        a component of this name is registered
X|DataSource        no component of this name is registered
F|prod              the named profile is active
```

Records are joined with `;`, fields with `|`. Neither character may appear in a module name, a
property key, a type name or a profile name, and `#[conditionalOnProperty]` rejects a key containing
either at comptime rather than emitting a blob that cannot be parsed back.

### What the decorator body may not do

This front is the most comptime-heavy in track B, so the constraints are load-bearing rather than
trivia. All of them are in the ground truth, and all of them are visible in `src/decorators.bp` as
things that file works around:

- **No sibling calls.** `decorator_eval` emits only the decorator function into the eval script, so a
  helper is undefined at run time (`src/decorators.bp:44-46` says so, and is why six bodies are
  copy-pasted). The condition-serialisation loop is inlined in `autoConfiguration`'s body, not shared
  with `conditions.bp`'s markers — those only enforce placement.
- **No `//` comment inside any block of the body.** The emitter flattens a block to one line joined by
  `;`, and a `//` swallows the rest of it. Every explanation lives above the `pub fn`.
- **Native-JS operations only.** `split`, `join`, `slice`, `trim`, `indexOf`, `forEach`, `map`,
  `append`, `length`, `+`, `==` and `loop` are available. `.at(i)`, `.pop()`, `.unwrapOr(…)` and
  anything else returning `?T` are not — they are undefined in the eval script and the failure
  surfaces as a bare "parse error in <module>". Reading the last element of a list in a body is
  `xs.slice(n - 1, n).join("")`.
- **No `(expr).method()`.** Bind first.
- **No named record constructors.** The body works on strings and arrays.
- **A nested `loop` may not be the tail of an if/else branch** — it lowers to a `for` statement, and
  `return for (…)` is a JavaScript syntax error. Use `.forEach({ x -> … })` where a loop is a branch
  tail.

The practical shape that follows: the body accumulates `var conds: Array<string> = []`, pushes one
record per matching annotation inside a single `decl.annotations.forEach({ a -> … })`, and emits
`conds.join(";")`. That is one loop, no helpers, no optionals.

### The interface other fronts lean on

Every `rakun-*` module that wants to configure itself uses exactly this surface, so it is stated once
here and not restated in the fronts that consume it. Fronts 73, 74, 75, 76, 77 and 78 each ship at
least one `#[autoConfiguration]` type against it.

**Comptime markers** — `src/conditions.bp`, `src/autoconfig.bp`:

```bp
pub fn autoConfiguration(comptime decl: @Decl);
pub fn conditionalOnModule(comptime decl: @Decl, moduleName: string);
pub fn conditionalOnProperty(comptime decl: @Decl, key: string, havingValue: string);
pub fn conditionalOnBean(comptime decl: @Decl, typeName: string);
pub fn conditionalOnMissingBean(comptime decl: @Decl, typeName: string);
pub fn profile(comptime decl: @Decl, name: string);
pub fn autoConfigureBefore(comptime decl: @Decl, typeName: string);
pub fn autoConfigureAfter(comptime decl: @Decl, typeName: string);
```

**Application surface** — `src/autoconfig.bp`, plain botopink over the seams:

```bp
pub fn autoConfigure() -> i32;
pub fn autoConfigureExcept(names: string[]) -> i32;
pub fn autoConfigurationReport() -> string;
pub fn isAutoConfigured(name: string) -> bool;
```

**Host seams** — `src/autoconfig_registry.bp`, `#[@External.Erlang("rakun_autoconfig", …)]` only, no
Node form:

| Cell | Shape | What it is for |
|---|---|---|
| `rkAutoRegister` | `(name, conditions, before, after) -> i32` | Emitted once per annotated declaration at module load. `name` is `Type` for a configuration and `Type.method` for a `#[bean]` method |
| `rkAutoApply` | `(excluded: string) -> i32` | Sort, evaluate, record. Returns the number of configurations applied |
| `rkAutoMatched` | `(name) -> bool` | The gate an emitted factory checks before building |
| `rkAutoReport` | `() -> string` | The whole decision table, for `--debug` and for front 11's `conditions` endpoint |
| `rkAutoConditions` | `(name) -> string` | The registered condition blob, verbatim — the comptime half's assertion point |
| `rkAutoAfter` | `(name) -> string` | The registered `after` list, comma-joined; `""` when none |
| `rkModulePresent` | `(name) -> bool` | Reads the manifest's normalised dependency list |

A front that needs a new *kind* of condition adds a record letter and a branch in
`rakun_autoconfig:evaluate/2`. It does not add a second registry.

### Where the apply pass is called from

`src/bootstrap.bp` is frozen, so `Rakun.run` cannot be taught to run the apply pass. The application
calls it, once, before `Rakun.run`:

```bp
val _ = autoConfigure();
Rakun.run(App(port: 8080, basePath: "/api"));
```

This is a narrowing, and it is deliberate. The alternative — having `rkAutoRegister` lazily apply on
the first `rkAutoMatched` read — would make the result depend on which component happened to be
resolved first, which is exactly the ordering bug step 3 exists to prevent. A follow-up that unfreezes
`bootstrap.bp` moves the call inside `Rakun.run` and deletes the line from every application; until
then the line is explicit and the report says plainly when it was never called.

### What this front does not own

Front 06 owns the registry: scopes, programmatic resolution, lifecycle hooks, application events. This
front never writes to it. It reads the registered-name list through `rkScannedNames()` (front 04,
existing surface) and it decides whether a factory is permitted to build. If front 06 lands a richer
presence query than a comma-joined string, this front consumes it and deletes its own splitting; the
predicate is the deliverable, not the storage.

## Steps

### Step 1 — `#[autoConfiguration]` and the registration it emits

Placement: a record-shaped `type` (`decl.kind == DeclKind.Type` and `decl.variants.length == 0`), the
same rule the six existing component markers enforce. The body emits three things: the scan
registration, the singleton factory (identical in shape to `#[configuration]`'s, so an auto-config can
carry `#[value]` fields and injected dependencies), and the condition registration.

```bp
// src/autoconfig.bp — the marker a module author writes on a configuration holder.
#[autoConfiguration]
#[conditionalOnModule("rakun-mail")]
#[conditionalOnProperty("rakun.mail.host", "*")]
#[autoConfigureAfter("RakunCoreAutoConfiguration")]
type RakunMailAutoConfiguration(
    #[value("rakun.mail.host")] host: string,
    #[value("rakun.mail.port")] port: i32,
) {
    #[bean]
    #[conditionalOnMissingBean("MailSender")]
    pub fn mailSender(self: Self) -> MailSender {
        return MailSender(host: self.host, port: self.port);
    }
}
```

**Acceptance:**
- [x] `#[autoConfiguration]` on a `fn`, a `behavior`, a field or an enum-shaped `type` fails with a located message naming the placement rule — held: `src/autoconfig.bp` `autoConfiguration` — `decl.fail` off `DeclKind.Type` and on an enum (code; a compile failure has no cell)
- [x] The emitted `__rkMake_<Name>` is byte-identical in shape to the one `#[configuration]` emits, so a `#[value]` field and an injected field behave the same way in both — held: `src/autoconfig.bp` emits the same `__rkMake_<Name>` body as `src/decorators.bp` `configuration` (code)
- [x] A type with no condition annotations registers with an empty condition blob and always matches — held: `test/conditions_test.bp` "a type with no condition registers an always-matching blob"
- [x] `rkAutoRegister` is emitted exactly once per annotated type, and its first argument is `decl.name` — held: `src/autoconfig.bp` `autoConfiguration` — one `rkAutoRegister("<decl.name>", …)` line per type (code)
- [x] A property key or type name containing `;` or `|` fails at comptime, at the annotation, rather than emitting an unparsable blob — held: `src/autoconfig.bp` `autoConfiguration` + each marker in `src/conditions.bp` `decl.fail` on `;`/`|` (code)

### Step 2 — the condition set

Five markers in `src/conditions.bp`. Each enforces placement and nothing else; `#[autoConfiguration]`
reads them off `decl.annotations` and `#[bean]`-carrying entries off `decl.methods[i].annotations`.

| Marker | Signature | Sits on | Record emitted |
|---|---|---|---|
| `#[conditionalOnModule(name)]` | `(comptime decl: @Decl, moduleName: string)` | type or method | `M\|<name>` |
| `#[conditionalOnProperty(key, value)]` | `(comptime decl: @Decl, key: string, havingValue: string)` | type or method | `P\|<key>\|<value>` |
| `#[conditionalOnBean(typeName)]` | `(comptime decl: @Decl, typeName: string)` | type or method | `B\|<typeName>` |
| `#[conditionalOnMissingBean(typeName)]` | `(comptime decl: @Decl, typeName: string)` | type or method | `X\|<typeName>` |
| `#[profile(name)]` | `(comptime decl: @Decl, name: string)` | type or method | `F\|<name>` |

Two argument shapes deserve a note. `havingValue` has no default, because declared parameter defaults
are never applied at a call site — so `"*"` is written out, and it means "set and non-empty". A type is
named by a string rather than by the type itself, because a decorator argument is an ordinary value and
there is no type-of-type; this is a language gap and it is recorded below. Spring reaches the same
spelling from the other direction with `excludeName`.

Several conditions on one declaration are conjunctive. There is no `anyOf`, no `@ConditionalOnExpression`
and no escape hatch: a configuration that needs a disjunction splits into two configurations, which is
also the form that reads correctly in the report.

**Acceptance:**
- [x] Each marker on a wrong declaration kind fails with a message naming the marker and the kinds it accepts — held: `src/conditions.bp` — each marker `decl.fail`s naming itself and the kinds it accepts (code)
- [ ] `#[conditionalOnProperty("k")]` — one argument — is rejected by the compiler's own arity check, with no code in this front
- [ ] `#[conditionalOnProperty("k", 1)]` is rejected by the type check, with no code in this front
- [x] Three conditions on one type produce three records in the blob, in source order — held: `test/conditions_test.bp` "three conditions produce three records, in source order"
- [x] A condition marker used without `#[autoConfiguration]` on the same declaration fails, naming the missing marker — a condition that nothing reads is a silent no-op otherwise — held: `src/conditions.bp` companion check ("needs #[autoConfiguration], a stereotype or #[bean]…") — widened to stereotypes/`#[bean]` for `#[profile]` (code)

### Step 3 — the apply pass: order, then evaluate

`rkAutoApply/1` takes the exclusion list, and in one pass:

1. Builds the edge set from every registration's `before`/`after` names. An edge naming an
   unregistered configuration is dropped, not an error — Spring's `@AutoConfigureAfter` routinely names
   a class that is not present.
2. Topologically sorts. A cycle is a startup failure naming the members of the cycle, routed through
   front 04's failure-diagnostic table.
3. Walks the sorted list, evaluating each configuration's conditions against the property table
   (`rkProp`), the manifest dependency list, the active profile set and the names registered so far.
4. Records the decision and, for a failure, the first condition that failed and the value it saw.
5. For a match, marks the name so `rkAutoMatched/1` answers true and the emitted bean factories are
   permitted to build.

`#[conditionalOnBean]`/`#[conditionalOnMissingBean]` see the state as of their own position in the
sorted order, which is the whole reason the sort happens first.

**Acceptance:**
- [x] `autoConfigure()` is idempotent: a second call re-evaluates nothing and returns the same report — held: `test/autoconfig_test.bp` "the pass is idempotent - a second call re-evaluates nothing"
- [x] `A` declaring `#[autoConfigureAfter("B")]` is evaluated after `B`, whatever order the modules loaded in — held: `test/autoconfig_test.bp` "the pass sorts first, so `after` beats module load order"
- [x] An `#[autoConfigureAfter]` naming an unregistered configuration is ignored and does not appear as a failure reason — held: `test/autoconfig_test.bp` "an ordering edge naming an unregistered configuration is dropped"
- [x] `A` after `B` and `B` after `A` halts at startup naming both, rather than picking one — held: `test/autoconfig_test.bp` "a cycle halts the pass and names both members"
- [x] A configuration whose `#[conditionalOnMissingBean("DataSource")]` is true only because it ran before the configuration that provides `DataSource` is a test in this front, and it asserts the *ordered* answer — held: `test/autoconfig_test.bp` "the ordered answer, not the registration-order one" + "the sort runs BEFORE the evaluation…"
- [x] A bean factory belonging to an unmatched configuration raises when called, naming the configuration and the condition that failed — it does not return a half-built value — held: `test/autoconfig_test.bp` "an applied bean builds and an unapplied one raises"
- [x] `autoConfigure()` never called: `rkAutoMatched` answers false for everything and the report says "not applied", rather than reporting an empty table — held: `test/autoconfig_test.bp` "with no pass run, nothing matches and the report says why"

### Step 4 — exclusion

Two channels, one resolution path. `rakun.autoconfigure.exclude` is a comma-separated property read
through front 05's table; `autoConfigureExcept(names)` passes an explicit list. Both end at
`rkAutoApply/1`'s single argument, so their union is what is excluded and the report shows the reason
as `excluded` with the channel that named it.

An excluded name that matches no registered configuration is a startup failure, not a warning. A typo
in an exclusion silently disables nothing and leaves the developer believing they turned something off.

**Acceptance:**
- [ ] `rakun.autoconfigure.exclude=RakunMailAutoConfiguration` leaves the mail configuration unapplied and its beans unbuildable
- [x] `autoConfigureExcept(["RakunMailAutoConfiguration"])` has the same effect with no property set — held: `test/autoconfig_test.bp` "autoConfigureExcept does the same with no property set"
- [x] Both together are a union, not a conflict — held: `test/autoconfig_test.bp` "the two channels are a union, not a conflict"
- [ ] `rakun.autoconfigure.exclude=Nonexistent` halts at startup naming the value and listing the registered names
- [x] An excluded configuration's conditions are not evaluated at all — a property read it would have done does not appear in the report — held: `test/autoconfig_test.bp` "an excluded configuration's conditions are never evaluated"

### Step 5 — the condition report

`condition_report.bp` renders `rkAutoReport()` into three blocks — applied, not applied, excluded —
each row naming the configuration and, for a failure, the condition record that failed and the value
observed. It is printed at boot when `rakun.main.debug=true` (the `--debug` analogue; front 04 owns the
boot-option plumbing) and returned verbatim to front 11 for `/actuator/conditions`.

The value observed is the part that makes the report worth having. "did not match: `P|rakun.mail.host|*`"
is a restatement of the source. "did not match: `P|rakun.mail.host|*` — property is empty" is a
diagnosis.

**Acceptance:**
- [x] Every registered configuration appears in exactly one of the three blocks — held: `test/autoconfig_test.bp` "every registered name is in exactly one of the three blocks"
- [x] A failed row names the failing condition record and the value seen (the property's value, the module list, the bean name) — held: `test/autoconfig_test.bp` "a failed row names the record and the value observed"
- [ ] Only the *first* failing condition is reported per configuration — evaluation short-circuits, and the report says so rather than implying the rest passed
- [x] The report is stable across runs given the same inputs: the sorted order, not a hash order — held: `test/autoconfig_test.bp` "the report is stable across runs…" (Kahn's walk, ties by registration order)
- [x] `rakun.main.debug=false` prints nothing at boot and `rkAutoReport()` still returns the full table — held: `test/autoconfig_test.bp` "…and debug only gates the printing"

### Step 6 — `#[profile]` on an ordinary component

`#[profile("prod")]` is the same machinery pointed at an ordinary `#[component]`/`#[service]` type
rather than at an auto-configuration: the marker registers the type with a single `F|prod` condition
and the apply pass gates its factory the same way. Folding it in here rather than into front 05 is the
point — a second conditional mechanism with its own report would be two ways to answer the same
question.

The profile set itself is front 05's (`rakun.profiles.active`, `rakun.profiles.default`,
`rakun.profiles.include`, and groups). This front reads it and does not define it.

**Acceptance:**
- [x] `#[profile("prod")]` on a `#[service]` type leaves it unbuilt when `rakun.profiles.active=dev` — held: `test/autoconfig_test.bp` "a #[profile] component off its profile is left unbuilt" + `test/conditions_test.bp` "F reads front 05's set…" (`dev,local` misses `F|prod`)
- [x] The same type appears in the condition report's "not applied" block with `F|prod` as the reason and the active set as the value observed — held: `test/autoconfig_test.bp` "a failed row names the record and the value observed" + `test/conditions_test.bp` "F reads front 05's set…" (observed `active profiles: dev,local`)
- [x] `#[profile]` with no active profile set at all uses front 05's default profile, and the report names which — held: `test/conditions_test.bp` "a named default profile is the one the report names"
- [x] Two `#[profile]` markers on one type are conjunctive and therefore unsatisfiable — this is rejected at comptime with a message saying to use one marker — held: `src/conditions.bp` `profile` — `seen > 1` → `decl.fail("two #[profile] markers … Use one marker…")` (code)

## Examples

- [`examples/mail-auto-configuration-example.bp`](./examples/mail-auto-configuration-example.bp) — the
  module author's side: an auto-configuration for a hypothetical `rakun-mail` module, gated on the
  module being a dependency, on a property being set, and on the application not having supplied its
  own `MailSender`.
- [`examples/override-and-report-example.bp`](./examples/override-and-report-example.bp) — the
  application author's side: the same configuration overridden by an application bean, the exclusion
  property, and the report read back and asserted on.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A decorator argument cannot name a type** — decorator arguments are ordinary values type-checked against the signature, and there is no type-of-type, so `#[conditionalOnMissingBean(MailSender)]` does not compile. **New row; not yet in [`language-gaps.md`](../../language-gaps.md).** Also bites front 78 (`#[entityRepository]`, `#[belongsTo]`). | `examples/mail-auto-configuration-example.bp` — every `conditionalOn*Bean` marker | The type's name as a string literal: `#[conditionalOnMissingBean("MailSender")]`, which is also Spring's `excludeName` spelling | A `@Type` decorator-parameter kind that accepts a type name in argument position and reflects it to `{ name, fields }`, so the marker is checked against a type that exists rather than against a string |

One further row already in [`language-gaps.md`](../../language-gaps.md) shapes this front and is not
restated: *declared parameter defaults are never applied*, which is why
`#[conditionalOnProperty("rakun.mail.host", "*")]` spells out `"*"` where Spring writes nothing — a
decorator cannot have an optional argument.

## Test plan

`test/autoconfig_test.bp` and `test/conditions_test.bp`, run with `botopink test --target erlang` from
`repository/rakun/`, and in the gate as `zig build test-libs -- --target erlang --lib rakun`.

`conditions_test.bp` covers the comptime half: that each marker enforces its placement, that the blob a
given annotation set produces is exactly the expected string, and that a key containing a separator
fails. Placement failures and arity failures cannot be expressed as a runtime `assert` — they are
compile errors — so those cases live in the compiler's own Zig suites the way
`repository/rakun/test/di_test.bp:14-16` records for the existing markers, and this front's `.bp` file
asserts only the cases that produce a value.

`autoconfig_test.bp` covers the run-time half: ordering, short-circuit evaluation, exclusion from both
channels, the gated factory raising for an unmatched configuration, idempotence, and the report's three
blocks. Every test calls `autoConfigure()` explicitly, which is also the documentation of step 3's
narrowing.

This front is erlang-only. The commonJS row compiles — the markers are comptime and the host cells are
declarations — but `rkAutoRegister` and its siblings have no Node form, so a commonJS test run of this
front's files fails at the first call. That is the target split working as designed, and
`scripts/known-red-libs.txt` is not the place to record it: the tests are declared erlang-only and the
lib test runner is told so, rather than being allowed to fail.

The sidecar module atom is `rakun_autoconfig`, not `autoconfig`. Front 04 established why: the shipper
skips any qualifier whose atom matches a module this build emitted, and rakun emits `rakun/autoconfig`,
basename `autoconfig` — naming the host module `autoconfig` ships nothing and fails silently at run
time.

## Definition of done

- `#[autoConfiguration]` plus the five condition markers exist, enforce their placement, and are
  exported from `src/root.bp`'s module tree
- The condition blob format is documented in `src/conditions.bp`'s module docblock and tested against
  literal expected strings
- `rkAutoApply/1` sorts before it evaluates, and there is a test that fails if that order is reversed
- The condition report distinguishes applied, not applied and excluded, and names the value observed
  for every failure
- Front 11 can serve `/actuator/conditions` from `rkAutoReport()` with no further work in this front
- `#[profile]` works on an ordinary component and appears in the same report
- Both language gaps above appear in a `specs/1.0.10-beta/` spec
- The front's tests are green on its assigned target

