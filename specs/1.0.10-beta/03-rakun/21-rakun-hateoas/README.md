# Front 21 — Rakun HATEOAS

**Track:** B rakun
**Priority:** low — no other front depends on it, and an API without links is still an API
**Target:** erlang (server)
**Wave:** 3
**Depends on:** 06 (context), 22 (the route table, for `linkTo` — see *Building a link* below)
**Owns:** `modules/rakun-hateoas/src/**`, `modules/rakun-hateoas/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone
**Reference:** `04-web.md § Spring HATEOAS` · https://docs.spring.io/spring-boot/reference/web/spring-hateoas.html

---

## Problem

A rakun `#[restController]` returns `Response.json(someString)`. Whatever a client can do next with
that resource — fetch its orders, cancel it, page forward — is knowledge the client has to hold, which
means every URL in the API is duplicated in every consumer and every URL change is a coordinated
release. HAL exists to move that knowledge into the response.

`modules/rakun-hateoas/` is a `botopink.json` and a `src/root.bp` holding a TODO comment.

Three constraints shape the design. `type` is a keyword (`modules/compiler-core/src/lexer.zig:721-767`),
so a `Link` field cannot be called `type`. `json.stringify` takes and returns `string`
(`libs/std/src/json.bp:45`), so a generic `RepresentationModel<T>` cannot be serialized through it.
And a type cannot be passed as a value, so a `linkTo(controller: type, method: string, …)` is not
writable.

## Current state

- `repository/rakun/modules/rakun-hateoas/src/root.bp` — docblock and `// Module contents will be added by the respective fronts.`
- `repository/rakun/src/http.bp:45-73` — `Response` has six builders: `ok`, `json`, `created`, `withStatus`, `notFound`, `badRequest`. No header surface, so the `application/hal+json` content type is set through front 07's response-header mechanism.
- `libs/std/src/json.bp` — `parse` and `stringify` take and return `string`; `json.decode` reads a document into a `Json` tree (decision 117), and `json.quote` / `json.array` / `json.object` write one. Nothing serializes an arbitrary record at run time ([`../../language-gaps.md`](../../language-gaps.md), *Unowned surface*), which decides this front's whole serialization strategy.
- `repository/rakun/src/runtime.bp:88-92` — `rkRouteCount()` and `rkRoutePaths()` exist. The route table holds a verb, a path and a handler closure and **does not hold the controller or method name** (`repository/rakun/src/runtime.bp:78-86`), which decides `linkTo`'s shape.

## Mechanism

### Serialization is comptime, because it cannot be run time

There is no structured JSON value in std, so nothing can walk an arbitrary record at run time. What can
walk a record is a comptime decorator: `@Decl` carries `decl.fields` with each field's name and
`typeName`, which is exactly what `#[service]` already uses to build a constructor argument list
(`repository/rakun/src/decorators.bp:52-56`).

`#[halResource]` on a record-shaped `type` reflects its fields and `@emit`s one function:

```
pub fn <typeName>ToHal(v: <TypeName>, links: Array<Link>) -> string
```

built from concatenation over the known field list, with the right quoting per `typeName` — strings
quoted and escaped, numbers and booleans bare. That is the same deterministic-name contract front 14
uses for `validate<TypeName>`, and the same twin-emission mechanism `onze` uses for `#[mock]`.

The cost is honest and is stated here rather than discovered: a field whose type this front does not
know how to render — a nested record, an array of records, an optional — fails **at comptime**, naming
the field and its type. It does not emit a function that produces `[object Object]`.

### HAL

`application/hal+json`, the format the reference names (`04-web.md § Spring HATEOAS`).

A resource is its own fields plus a `_links` object:

```json
{"id":1,"name":"Alice","_links":{"self":{"href":"/api/users/1"},"orders":{"href":"/api/users/1/orders"}}}
```

A collection is `_embedded` keyed by the relation, plus its own `_links`:

```json
{"_embedded":{"users":[{…},{…}]},"_links":{"self":{"href":"/api/users?page=2"},"next":{"href":"/api/users?page=3"}}}
```

Two rules that decide the edge cases:

- **A link with the same `rel` twice becomes an array** for that rel, which is what HAL requires and
  what a naive object build silently loses.
- **`_links` is last** in the object and `_embedded` first, so two renderings of the same resource are
  byte-identical and diff cleanly in a test.

### `Link`

```bp
pub type Link(
    rel: string,
    href: string,
    mediaType: string,
    title: string,
    templated: bool,
)

pub fn link(rel: string, href: string) -> Link
```

`mediaType`, not `type` — `type` is a keyword. Empty strings are omitted from the rendered object
rather than emitted as `""`, and `templated` is emitted only when true. Declared parameter defaults are
never applied ([`../../language-gaps.md`](../../language-gaps.md)), so `link(rel, href)` is a named constructor for
the common case rather than a default-argument form.

### Building a link

Spring writes `linkTo(methodOn(UserController.class).show(id))` and derives the URL by reflecting over
the controller. rakun's route table cannot support that: `rkRegisterRoute(verb, path, handler)` stores
a closure, not a controller name and a method name (`repository/rakun/src/runtime.bp:78-86`), and
`src/runtime.bp` belongs to front 04.

So `linkTo` takes the pattern:

```bp
pub fn linkTo(rel: string, pattern: string, params: Array<#(string, string)>) -> Link
// linkTo("self", "/api/users/:id", [#("id", "1")])  ->  href "/api/users/1"
```

and validates it against what is registered: a pattern that is not in the route table raises with the
pattern and the closest registered path in the message. That turns the weakness into the useful half of
what Spring's version buys — a link that names a route nobody serves fails loudly instead of shipping a
404 to a client.

The method-reference form stays possible later without changing this API: when front 04's route table
carries controller and method names, `linkToMethod(rel, "UserController", "show", params)` resolves to
a pattern and calls this function. That is a fold-in to front 04, recorded here, not a blocker.

Path parameters are substituted by name; a `:param` with no matching entry raises with its name, and an
entry with no matching `:param` raises too — a silently ignored argument is how a link ends up pointing
at the wrong resource.

### Content negotiation

`rakun.hateoas.use-hal-as-default-json-media-type` defaults to `true`, matching upstream: a request
accepting `application/json` is answered `application/hal+json`. Setting it false answers plain
`application/json` with the same body. The key exists because the reference documents it; the body does
not change either way, so it is a negotiation setting rather than a second format.

### Target

erlang. Serialization is comptime and the rest is string building; the module declares no host cell at
all.

## Steps

### Step 1 — `Link` and the link set

**Acceptance:**
- [x] `link("self", "/api/users/1")` renders `{"href":"/api/users/1"}` under the key `self`. — held: `modules/rakun-hateoas/test/hal_test.bp` "a link renders its href under its rel" (rakun `7dfec03`)
- [x] Empty `mediaType` and `title` are omitted; non-empty ones are emitted. — held: `modules/rakun-hateoas/test/hal_test.bp` "empty mediaType and title are omitted, non-empty ones written; templated only when true"
- [x] `templated` is emitted only when true. — held: `modules/rakun-hateoas/test/hal_test.bp` "empty mediaType and title are omitted…templated only when true"
- [x] Two links with the same `rel` render as an array under that key, in insertion order. — held: `modules/rakun-hateoas/test/hal_test.bp` "two links with one rel are an array, in insertion order"
- [x] An `href` containing a quote or a backslash is escaped. — held: `modules/rakun-hateoas/test/hal_test.bp` "a quote or a backslash in an href is escaped"
- [x] No field in this module is named `type`. — held: `modules/rakun-hateoas/src/hal.bp` (`Link.mediaType`)

### Step 2 — `#[halResource]`

```bp
#[halResource]
pub type UserResource(
    id: i32,
    name: string,
    active: bool,
)
```

**Acceptance:**
- [x] `#[halResource]` emits `userResourceToHal(v, links)` into the annotated type's module. — held: `modules/rakun-hateoas/test/hal_test.bp` "#[halResource] emits <typeName>ToHal - fields in order, bare scalars, _links last"
- [x] `#[halResource]` on an enum-shaped `type` fails, the same way `#[service]` does. — held: `modules/rakun-hateoas/src/hal.bp` `halResource` — `decl.fail` on an enum (code)
- [x] Strings are quoted and escaped; `i32`, `i64`, `f64` and `bool` are rendered bare. — held: `modules/rakun-hateoas/test/hal_test.bp` "#[halResource] emits…" + "the scalar renderers"
- [x] A field of an unsupported type — a nested record, an array of records, an optional — **fails at comptime** naming the field and its type, and emits nothing. — held: measured — `botopink build` of a scratch member: "#[halResource] cannot render the field home: Address …" at the annotation
- [x] Field order in the output matches declaration order, and `_links` is last. — held: `modules/rakun-hateoas/test/hal_test.bp` "#[halResource] emits <typeName>ToHal - fields in order, bare scalars, _links last"
- [x] Two renderings of the same value are byte-identical. — held: `modules/rakun-hateoas/test/hal_test.bp` "#[halResource] emits…" (rendered twice, compared)

### Step 3 — Collections

```bp
pub fn halCollection(rel: string, items: Array<string>, links: Array<Link>) -> string
```

`items` are already-rendered resource strings, because there is no way to take an array of arbitrary
records and render each one at run time.

**Acceptance:**
- [x] `_embedded` comes first, keyed by `rel`, and `_links` last. — held: `modules/rakun-hateoas/test/hal_test.bp` "a collection is _embedded first and _links last; empty is []"
- [x] An empty collection renders `"_embedded":{"users":[]}` rather than omitting the key — a client that branches on presence should not have to branch on emptiness too. — held: `modules/rakun-hateoas/test/hal_test.bp` "a collection is _embedded first and _links last; empty is []"
- [x] Paging links (`self`, `first`, `prev`, `next`, `last`) round-trip through the link set in that order. — held: `modules/rakun-hateoas/test/hal_test.bp` "paging links keep their order"

### Step 4 — `linkTo`

**Acceptance:**
- [x] `linkTo("self", "/api/users/:id", [#("id", "1")])` yields `/api/users/1`. — held: `modules/rakun-hateoas/test/hal_test.bp` "linkTo substitutes by name over a registered route"
- [x] A pattern not in the route table raises, naming the pattern and the nearest registered path. — held: `modules/rakun-hateoas/test/hal_test.bp` "a pattern nobody serves raises, naming it and the nearest path"
- [x] A `:param` with no matching entry raises with its name. — held: `modules/rakun-hateoas/test/hal_test.bp` "a missing entry and an unused entry both raise with the name"
- [x] An entry with no matching `:param` raises with its name. — held: `modules/rakun-hateoas/test/hal_test.bp` "a missing entry and an unused entry both raise with the name"
- [x] A param value containing `/`, `?` or `#` is percent-encoded — front 01's encoding, not a private copy. — held: `modules/rakun-hateoas/test/hal_test.bp` "a value holding / ? or # is percent-encoded"

### Step 5 — The response helper and negotiation

```bp
pub fn halResponse(body: string) -> Response
```

**Acceptance:**
- [x] `halResponse` produces a 200 whose content type is `application/hal+json`, set through front 07's header mechanism rather than by a second `Response` type. — held: `modules/rakun-hateoas/test/hal_test.bp` "halResponse is 200 application/hal+json through the header surface"
- [x] With `use-hal-as-default-json-media-type=false`, the same body is served as `application/json`. — held: `modules/rakun-hateoas/test/hal_test.bp` "with the default off, plain JSON - unless the client asks for HAL"
- [x] A client sending `Accept: application/hal+json` gets it in both modes. — held: `modules/rakun-hateoas/test/hal_test.bp` "with the default off, plain JSON - unless the client asks for HAL" + "halResponse is 200 application/hal+json"

## Examples

- [`examples/hal-resource-example.bp`](./examples/hal-resource-example.bp) — a controller returning a HAL resource and a paged HAL collection: `#[halResource]`, `linkTo` against registered patterns, self and relation links, and the paging set.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| std's `Json` tree (`libs/std/src/json.bp`) has a reader (`json.decode`) and no writer, and a record cannot be reflected at run time, so nothing can serialize an arbitrary record. Recorded in [`../../language-gaps.md`](../../language-gaps.md) under *Unowned surface*. | `examples/hal-resource-example.bp`, every `…ToHal` call and `halCollection` | Reflect the record at comptime with `#[halResource]` and emit a concrete renderer; refuse a field type the renderer does not know. Collections take already-rendered strings. | A writer for std's `Json`, which would also let `halCollection` take records |

## Test plan

`modules/rakun-hateoas/test/` on the **erlang** target, via
`zig build test-libs -- --target erlang --lib rakun`.

| File | Asserts |
|---|---|
| `test/link_test.bp` | Rendering, omission of empty attributes, duplicate-rel arrays, escaping |
| `test/resource_test.bp` | Emission and naming, per-type rendering, the unsupported-field comptime refusal, field order, byte stability |
| `test/collection_test.bp` | `_embedded` and `_links` order, the empty case, the paging set |
| `test/linkto_test.bp` | Substitution, the unregistered-pattern failure, both parameter mismatches, percent-encoding |
| `test/response_test.bp` | Content type in both negotiation modes, and `Accept` honoured in both |

Every assertion compares a **literal JSON string**, not a parsed structure — there is nothing to parse
it with, and a literal is the stronger assertion anyway: it catches a key-order change that a
structural comparison would pass.

There is no commonJS row; this front is server-only by the milestone's target split.

## Out of scope

- **Affordances** — links carrying a method, an input schema and a content type (HAL-FORMS). No consumer in this milestone, and it needs the JSON value model to express an input schema.
- **Other hypermedia formats** — JSON:API, Collection+JSON, Siren, UBER. Spring supports several; the reference documents HAL as the default, and one format that works beats four that are sketched.
- **Link relation registries and CURIEs** — a naming convention on top of a format that does not exist yet here.
- **`linkTo` by method reference** — blocked on front 04's route table carrying controller and method names; recorded above as a fold-in to that front rather than as work here.

## Definition of done

- `#[halResource]` emits `<typeName>ToHal` and refuses an unsupported field type at comptime.
- HAL output is byte-stable, with `_embedded` first and `_links` last, and duplicate rels rendered as arrays.
- `linkTo` validates against the registered route table and fails on an unknown pattern.
- Content negotiation follows `rakun.hateoas.use-hal-as-default-json-media-type`.
- No field or binding in the module is named `type`.
- Every `// LANGUAGE GAP:` marker in the example appears in the table above.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module's surface in the same commit.
- The front's tests are green on erlang.
