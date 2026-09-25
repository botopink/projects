# Front 14 — Rakun Validation

> **Amended 2026-09-21, on landing (rakun `af933f7`, `modules/rakun-validation` 0 → 54/0 on both
> rows).** Five corrections and two things this front could not reach.
>
> **`registerConstraint(name: string, c: Constraint)` does not compile.** A record that
> `implement`s a behavior does not coerce to the behavior type — `type mismatch: expected Greeter,
> got En` on both rows, for a parameter, a `val` and a return position alike (the return variant
> prints the behavior body and truncates it). Shipped as `registerConstraint(name, code, check)`.
> The `behavior Constraint` is still declared and application types still `implement` it, so the
> shape stays compiler-checked. This is the **second** independent measurement of that refusal in
> one day; see `status.md`.
>
> **`#[minValue]` / `#[maxValue]` on `i64` are refused**, with a located message. An integer literal
> does not widen to `i64` in arithmetic (`x - 1000` where `x: i64` reds `expected i64, got i32`, and
> *that* diagnostic has no line or column), and there is no `i64` literal spelling at all.
> `#[positive]` / `#[positiveOrZero]` do work on `i64`, because a comparison against `0` widens, and
> `#[pastDate]` / `#[futureDate]` are `i64`-only.
>
> **`#[notNull]` is admitted only where `typeName == ""`**, which covers `?T` *and* `T[]`, because
> `@Decl.Field.typeName` cannot tell them apart. `Array<T>` spelled the long way renders `"Array"`
> and is refused outright; spelling the array form as `Array<T>` is the honest workaround and is
> documented in the library.
>
> **The helper names are `v*`, not the examples' `check*`, deliberately.** The mapping is 1:1 apart
> from `checkRange`, which merges `#[minValue]` and `#[maxValue]` into one call while the Mechanism's
> constraint table keeps them as separate markers — `#[minValue(18)]` alone has no `max` to pass.
> Renaming requires changing the table first, which is a decision, not a rename.
>
> **Both § Examples programs use forms the compiler refuses or the tree forbids**: `!report.isValid()`
> (the tree writes `== false`), `id.toString()` on an `i32`, `registerConstraint("cpf",
> CpfConstraint())` (above), and `digits.split("")` + `digits.slice(0, 1)` — `String.slice`/`chars`
> make the commonJS backend emit a self-recursive `String.prototype.charCodeAt` patch that kills the
> module before a test runs, which `config.bp`'s own header already records. They will not compile as
> written and were correctly left untouched.
>
> **Not reached.** Step 6's boot call: front 05's `config.bp` names `rkConfigValidate`, which does
> not exist, and `modules/rakun/**` is not this front's — everything the call site needs is here and
> exercised, and **front 05 owes the call** (`validate<TypeName>(bound)` +
> `refuseInvalidConfig(typeName, prefix, report)`, after binding and before the first component).
> And the halt itself: `refuseInvalidConfig` aborts the process, which a test cannot observe and
> survive, so the refusal *text* is asserted directly and the abort needs front 19's `rakun-test`
> subprocess harness.
>
> **Name collision, for whoever reads this next.** Front 05 declares a placement-only `#[validated]`
> in `modules/rakun/src/config.bp`. This front's is a different decorator in a different package; an
> application must import `validated` from `rakun-validation` and **must not import both names into
> one module**. Importing front 05's leaves `validate<TypeName>` undefined and the red lands at the
> **call site as an unbound variable**, nowhere near the annotation. Whether front 05's should be
> deleted once this landed is an open question for `03-rakun`.

**Track:** B rakun
**Priority:** medium — it is the only front that both halves of the stack run, and front 05 cannot refuse a bad configuration at boot without it
**Target:** both — boundary (`"targets": ["erlang", "commonJS"]`, erlang first — the one rakun module that keeps commonJS, decision 113)
**Wave:** 3
**Depends on:** 01 (`regex`), 05 (config, and the boot-time contract below), 06 (context)
**Owns:** `modules/rakun-validation/src/**`, `modules/rakun-validation/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `07-io.md § Validacao` · https://docs.spring.io/spring-boot/reference/io/validation.html

---

## Problem

A rakun controller receives strings. `Request.param`, `Request.query`, `Request.header` and
`Request.body` all return `string`, and all four return `""` rather than an optional when the value is
absent (`repository/rakun/src/http.bp:30-43`). A handler that wants an integer parses it by hand; a
handler that wants to know whether a field was missing or empty cannot tell the difference; a handler
that wants to reject three bad fields at once and report all three has to write the accumulation loop
itself. `modules/rakun-validation/` is a `botopink.json` and a `src/root.bp` holding a TODO comment.

A `Validator` as a `#[service]` with a bodyless generic method inside a `type` body does not parse
(`docs.md:567`), and a `#[valid]` applied to a controller method *parameter* would hook into route
dispatch, which is emitted by `#[restController]` in `src/decorators.bp`, frozen for this milestone.
Neither can be built.

The temporal constraints are `#[pastDate]` and `#[futureDate]`; a decorator named `#[future]` would
collide with the effect marker `#[@future]` (`repository/emilia/src/emilia.bp:62`).

## Current state

- `repository/rakun/modules/rakun-validation/src/root.bp` — docblock and a TODO comment. No code.
- `repository/rakun/src/http.bp:30-43` — `Request`'s four accessors, all `-> string`, all `""` when absent. The file's own comment says this is deliberate so handlers do not deal in optionals.
- `repository/rakun/src/decorators.bp` — no `#[valid]`, no constraint markers, and frozen.
- `libs/std/src/regex.bp` already wraps `re:run/3` and returns a `Match` record. `#[pattern]` uses what is there rather than asking front 01 for a second matcher; front 01 extends that file, it does not replace it.
- `libs/std/src/time.bp:56` — `nowMillis` exists, so `#[pastDate]` and `#[futureDate]` have a clock today.
- Nothing in the tree validates configuration. `rkProp`/`rkPropInt` return a value or a default; a misconfigured application starts and fails later, at the first request that touches the bad key.

## Mechanism

### Why this front is a boundary front

The milestone's rule is that three things cross: the serialized payload, the route table, and the
validation constraints — *"the server enforces / the client mirrors"*. The usual way to do that is to
ship a constraint description to the client and write a second evaluator in the client's language,
which guarantees the two drift.

This front does not do that. `#[validated]` emits a plain botopink function whose body is string
comparisons, length checks and regex matches — no host cell, no `@External` anything. That function
compiles for **erlang and commonJS from one source**, so the server and the client run the same
predicate rather than two predicates that are supposed to agree. What crosses is the module; what is
serialized is only the constraint table, and only for a consumer that is not botopink.

That is the whole reason this front's header says `both — boundary` while every other front in this
set says `erlang (server)`.

### `#[validated]`, and the naming contract

`#[validated]` on a record-shaped `type` reflects `decl.fields`, reads each field's constraint
annotations from `f.annotations` — exactly as `#[service]` reads `#[value]`
(`repository/rakun/src/decorators.bp:52-56`) — and `@emit`s two module-level functions with
deterministic names:

```
pub fn validate<TypeName>(v: <TypeName>) -> ValidationReport
pub fn constraintsOf<TypeName>() -> string
```

The names are a contract, not a convention. **Front 05 depends on it**: when a configuration record
carries both its binding marker and `#[validated]`, front 05's generated binder calls
`validate<TypeName>(bound)` after binding and refuses to start if the report is not valid, printing
every violation with its key. Front 05 never has to know what constraints exist; it only has to know
the function's name, which it can build from the type name it already has. If either front changes the
spelling, the other breaks at compile time rather than at run time, which is the point of fixing it
here in writing.

### The constraint set

| Marker | Applies to | Holds when |
|---|---|---|
| `#[notNull]` | any field | the value is not `null` |
| `#[notBlank]` | `string` | trimmed length > 0 |
| `#[notEmpty]` | `string`, array | length > 0 |
| `#[sizeBetween(min, max)]` | `string`, array | `min <= length <= max` |
| `#[minValue(n)]` / `#[maxValue(n)]` | `i32`, `i64`, `f64` | numeric bound |
| `#[positive]` / `#[positiveOrZero]` | numeric | sign |
| `#[email]` | `string` | matches the address grammar |
| `#[pattern(regex)]` | `string` | front 01's `regex` matches |
| `#[pastDate]` / `#[futureDate]` | epoch millis | compared against front 01's `clock` |
| `#[constraint(name)]` | any field | the registered constraint named `name` returns `""` |

`#[sizeBetween]` takes both bounds because declared parameter defaults are never applied
(`docs.md:502-505`); Spring's single `@Size(min=…, max=…)` with either half optional has no botopink
spelling, and pretending otherwise would produce a decorator that silently drops an argument.

### The constraint SPI

An application adds its own constraint without touching this module:

```bp
pub behavior Constraint {
    fn code(self: Self) -> string;
    // "" when the value is acceptable; otherwise the message template.
    fn check(self: Self, field: string, value: string) -> string;
}

pub fn registerConstraint(name: string, c: Constraint) -> i32
```

`check` returns a `string` rather than `?Violation` on purpose: an empty string is unambiguous, and it
keeps the SPI free of optionals, which are the thing most likely to behave differently under a comptime
body. A registered constraint is reached from a field with `#[constraint("cpf")]`.

### Message interpolation

Every violation carries a `code` and a message built from a template. Templates resolve in order:

1. `rakun.validation.messages.<locale>.<code>` (front 05)
2. `rakun.validation.messages.<code>`
3. the built-in default for that code

Placeholders are `{field}`, `{value}` and the constraint's own parameters — `{min}`, `{max}`, `{regex}`
— substituted by name. A template naming a placeholder the constraint does not have is left as written
rather than blanked, because a visible `{limit}` in an error message is a bug report and an empty
string is not.

### Typed coercion of path, query and form values

`Request` hands out strings; a handler wants an `i32`, a `bool`, an epoch, an enum. Coercion that fails
must produce a violation, not a zero. Records are immutable — there is no assignment to a `self` field
anywhere in the real libraries — so the accumulator cannot be a field on a binder record. It is where
every other accumulator in rakun lives: the host, keyed on the request process.

```bp
pub fn bindInt(field: string, raw: string) -> i32       // 0 and a violation on failure
pub fn bindBool(field: string, raw: string) -> bool
pub fn bindRequired(field: string, raw: string) -> string
pub fn bindEpochMillis(field: string, raw: string) -> i64
pub fn bindingReport() -> ValidationReport              // and clears the accumulator
```

The pattern is: bind everything, then ask once. A handler never branches per field, which is what makes
"all violations, not fail-fast" the default rather than an option.

### Where enforcement happens

Not in route dispatch — `src/decorators.bp` is frozen and this front does not get to rewrite the
emitted handler. Enforcement is explicit and has two shapes, both visible in the examples:

1. **In the handler.** Bind, validate, and return `report.toProblemDetail()` when invalid. Three lines,
   no magic, and the failure path is readable in the handler that owns it.
2. **In a filter.** Front 07's chain can carry a `ValidationFilter` that runs a route's registered
   binder before the handler. That is the closest thing to Spring's `@Valid` parameter, and it belongs
   to front 07's chain rather than to this module's decorators.

### The violation report on the wire

`ValidationReport.toProblemDetail()` produces an RFC 9457 problem document — the format front 07 uses
for every other error — with `status: 400`, `title: "Validation failed"`, and an `errors` array of
`{ field, code, message }`. One error shape for the whole application, not a second one for validation.

## Steps

### Step 1 — Violations and the report

```bp
pub type Violation(field: string, code: string, message: string, invalidValue: string)

pub type ValidationReport(violations: Array<Violation>) {
    pub fn isValid(self: Self) -> bool {
        return self.violations.length == 0;
    }

    pub fn merge(self: Self, other: ValidationReport) -> ValidationReport {
        return ValidationReport(violations: self.violations.append(other.violations));
    }

    pub fn toJson(self: Self) -> string {
        val rows = self.violations.map({ v ->
            "{\"field\":\"" + v.field + "\",\"code\":\"" + v.code + "\",\"message\":\"" + v.message + "\"}";
        });
        return "{\"errors\":[" + rows.join(",") + "]}";
    }
}
```

**Acceptance:**
- [ ] An empty report is valid; a report with one violation is not.
- [ ] `merge` preserves order: the receiver's violations come first.
- [ ] `toJson` escapes a message containing a quote or a backslash.
- [ ] A field that fails two constraints produces two violations, not one.

### Step 2 — The constraint markers and `#[validated]`

```bp
#[validated]
pub type CreateUserRequest(
    #[notBlank]
    #[sizeBetween(2, 50)]
    name: string,

    #[notBlank]
    #[email]
    email: string,

    #[minValue(18)]
    #[maxValue(120)]
    age: i32,
)
```

**Acceptance:**
- [ ] `#[validated]` emits `validateCreateUserRequest` and `constraintsOfCreateUserRequest` into the annotated type's module, and both are callable there.
- [ ] Every constraint marker on anything but a field fails with a located message.
- [ ] `#[validated]` on an enum-shaped `type` fails, the same way `#[service]` does (`decl.variants.length > 0`).
- [ ] A field with no constraint contributes no violation and no constraint-table row.
- [ ] Constraints on one field are evaluated in declaration order, and all of them run — the first failure does not stop the second.

### Step 3 — The constraint table, and what crosses

```bp
pub fn constraintsOfCreateUserRequest() -> string
// -> {"type":"CreateUserRequest","fields":[
//      {"name":"name","constraints":[{"code":"notBlank"},{"code":"sizeBetween","min":2,"max":50}]},
//      … ]}
```

**Acceptance:**
- [ ] The table names every constrained field, every code, and every parameter, and nothing else.
- [ ] `validateCreateUserRequest` compiles and runs on **both** targets, and returns the same report for the same input on each.
- [ ] The round-trip test is one test running the same twenty inputs through the same function on erlang and on commonJS and comparing reports — not two tests asserting each side separately.
- [ ] The table is stable across rebuilds: the same source produces byte-identical JSON.
- [ ] The client bundle (front 68) can obtain the table without importing anything that reaches a socket or the filesystem.

### Step 4 — Typed coercion

**Acceptance:**
- [ ] `bindInt("age", "")` yields `0` and a violation with code `typeMismatch` naming `age`.
- [ ] `bindInt("age", "12x")` yields `0` and a violation; `bindInt("age", "12")` yields `12` and none.
- [ ] `bindBool` accepts `true`/`false`/`1`/`0` and rejects everything else with a violation.
- [ ] `bindRequired` on `""` produces a `required` violation — the distinction `Request` cannot make.
- [ ] `bindingReport()` returns every violation accumulated during the request and leaves the accumulator empty, so the next request on the same process starts clean.
- [ ] Two concurrent requests do not see each other's violations.

### Step 5 — The SPI and message interpolation

**Acceptance:**
- [ ] A registered constraint reached through `#[constraint("cpf")]` produces a violation with code `cpf`.
- [ ] An unregistered name in `#[constraint(...)]` fails at the first validation call with the name in the message, not silently.
- [ ] `rakun.validation.messages.sizeBetween` overrides the built-in template for every field using it.
- [ ] `rakun.validation.messages.pt-BR.email` is preferred over `rakun.validation.messages.email` when the locale resolves to `pt-BR`.
- [ ] `{min}` and `{max}` are substituted from the constraint's arguments; an unknown placeholder survives verbatim.

### Step 6 — Boot-time configuration validation

**Acceptance:**
- [ ] A configuration record carrying `#[validated]` is validated after binding and before the first request.
- [ ] An invalid configuration stops startup with every violation printed, each naming its property key rather than its field name.
- [ ] A valid configuration adds no measurable startup cost beyond one pass over the record's fields.
- [ ] Front 05 calls `validate<TypeName>` by name and nothing else; changing that name breaks the build, not a test.

## Examples

- [`examples/request-validation-example.bp`](./examples/request-validation-example.bp) — a controller that binds path and query values, validates a request record, and returns one problem document for every failure at once.
- [`examples/custom-constraint-example.bp`](./examples/custom-constraint-example.bp) — a registered application constraint, an interpolated message, a validated configuration record that stops the boot, and the constraint table the client mirrors.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied, so a constraint decorator cannot have optional arguments. Spring's `@Size(min = 8)` omits `max`; `#[sizeBetween]` cannot. | `#[sizeBetween(2, 50)]` in both examples | One decorator per shape, every argument passed. | Apply declared defaults at call sites (`docs.md:502-505`) |
| There is no assignment to a `self` field, so a binder record cannot accumulate violations as it goes. This shapes the design rather than appearing as a marked line: the accumulator was moved to the host instead. | *Mechanism · Typed coercion*; no example line is blocked by it | Keep the accumulator in the host, keyed on the request process, and read it once with `bindingReport()`. | Mutable record fields, or a linear binder value threaded through each call |

## Test plan

`modules/rakun-validation/test/` on **both** targets, since this is a boundary front:
`zig build test-libs -- --lib rakun` runs the erlang and commonJS cells, and both must be green.

| File | Target | Asserts |
|---|---|---|
| `test/report_test.bp` | both | Report algebra, ordering, JSON escaping |
| `test/constraints_test.bp` | both | Every marker's true and false case, multiple violations per field, declaration order |
| `test/parity_test.bp` | both | The same twenty inputs produce the same report — this is the boundary test, and it is the reason the front exists in this shape |
| `test/table_test.bp` | both | Constraint-table content and byte stability |
| `test/binding_test.bp` | erlang | Coercion failures, the accumulator's lifetime, process isolation |
| `test/spi_test.bp` | both | Registration, unknown names, message resolution order, placeholder substitution |
| `test/config_test.bp` | erlang | Boot refusal, key names in the output |

The binding accumulator is request-scoped and therefore erlang-only; everything else runs on both. A
commonJS-only regression in `parity_test.bp` is a release blocker, not a known red — the two halves
agreeing is the deliverable.

## Out of scope

- **Method-level validation** (`@Validated` on a service, constraints on parameters — `07-io.md § Validacao de Metodos`) — it needs interception of an arbitrary method call, which is the same gap front 12 records. Explicit `validate…` calls cover it until that gap closes.
- **Group and sequence validation** (`@GroupSequence`) — no consumer in this milestone.
- **Cross-field constraints** (`@AssertTrue` on a derived getter) — expressible today as a registered constraint over a serialized pair; a first-class form waits for a consumer.
- **The client-side evaluator's packaging** — front 68 ships the bundle; this front ships the function it bundles.

## Definition of done

- `validate<TypeName>` and `constraintsOf<TypeName>` are emitted with exactly those names, and front 05's boot path calls the first by name.
- `parity_test.bp` is green on erlang and on commonJS, and the reports it compares are equal, not merely both non-empty.
- Every constraint in the table above has a passing and a failing test case.
- The SPI admits an application constraint with no edit to this module.
- No decorator in this module is named `#[future]`.
- Every `// LANGUAGE GAP:` marker in the examples appears in the table above.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface in the same commit.
- The front's tests are green on both of its assigned targets.
