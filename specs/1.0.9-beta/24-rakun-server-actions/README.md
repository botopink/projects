# Front 24 — Rakun Server Actions

**Track:** B rakun
**Priority:** critical — a page that can only be read is half an application; this is the only path by
which a browser changes server state, and it is the path an attacker will try first
**Target:** both — boundary. The action body runs on BEAM; the form that calls it is HTML the browser
submits; the id that names the action and the envelope that carries the result cross between them
**Wave:** 3
**Depends on:** 23 (payload, render pipeline), 22 (route table), 06 (scopes), 62 (request context —
`cookies()`, `after()`), 12 (`revalidatePath`/`revalidateTag`), 63 (`redirect`), 01 (constant-time compare, percent-encoding), 03
(build id), 14 (constraint mirroring), 67 (the browser half)
**Owns:** `repository/rakun/src/actions.bp`, `repository/rakun/src/actions.mjs`,
`repository/rakun/src/actions.erl`, `repository/rakun/test/actions_test.bp`
**Does not touch:** `repository/rakun/src/http.bp`, `src/decorators.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` (frozen), `repository/jhonstart/src/element.bp` (frozen), and the files owned by
22 · 23 · 25
**Reference:** `NEXTJS-DOCS.md § 10. Mutação de Dados`, `§ 27. Diretivas` ·
<https://nextjs.org/docs/app/getting-started/updating-data> ·
<https://nextjs.org/docs/app/api-reference/directives/use-server>
**Replaces:** `1.0.7-beta/10-rakun-server-actions`

---

## Problem

There is no way for a browser to ask a `rakun` server to change something and get a fresh page back.
A `#[postMapping]` handler exists (`repository/rakun/src/decorators.bp:226-228`), but it answers with a
`Response(status, body)` string and knows nothing about the route that rendered the form, the cache
entries the mutation invalidated, or the markup that should replace what the user is looking at. Every
application would hand-roll the same five things: a name for the mutation, a POST endpoint, a CSRF
check, a revalidation call and a re-render.

The naming is the part that is easy to get wrong quietly. The server has to recognise, from a POST
body, which of its functions the browser meant. If that identifier is the function's own name, any
exported function is callable from the internet. If it is a per-process random value, a form rendered
by one BEAM node cannot be submitted to another and the first rolling restart breaks every open tab.
It has to be derived, stable for a build, and not guessable — and it has to be the same value on the
render path and on the dispatch path, which is exactly what makes this a boundary front rather than
two server details.

The security posture is not optional and it is not configurable. Next checks `Origin` against `Host`
automatically and caps the body at 1 MB (`§ 10. Segurança`). This project's standing rule is the most
restrictive behaviour and no knob to get around it, so here the check runs before the body is read,
the rejection is a 403, and there is no setting that turns it off.

## Current state

- `repository/rakun/src/decorators.bp:222-244` — five route-mapping decorators, method-level, no
  function-level marker of any kind and no `'use server'` equivalent.
- `repository/rakun/src/http.bp:35-43` — `Request.body()` returns the whole body as one `string`.
  There is no incremental reader, so "enforce the size limit while reading" has to be done in the
  host cell, not in botopink.
- `repository/rakun/src/http.bp:45-73` — `Response` carries no headers, so no `Set-Cookie`, which is
  what a session-writing action needs. Frozen; see *Blocked*.
- `repository/jhonstart/src/element.bp:10-53` — no `form`, `input`, `button` or `label` constructor.
  `Element` is a public record, so this front builds them without touching the frozen file.
- `libs/std/src/crypto.bp:38` — `hmacSha256(key, data) -> string` already exists, so the id
  derivation needs no new primitive. What does not exist is a constant-time compare; front 01 adds it.
- `libs/std/src/querystring.bp` exists; percent-encoding of a form body does not, and front 01 adds
  that too.
- `repository/rakun/src/actions.bp` does not exist.

## Mechanism

### What Next.js does

A function marked `'use server'` becomes callable from the client (`§ 27`). The marker works two ways:
file-level, where every export of the file becomes an action, and inline, where one function opts in
from inside its own body. A form calls it with `<form action={createPost}>`; the browser POSTs
`FormData`; the function mutates, calls `revalidatePath` and usually `redirect`s (`§ 10`). The same
function can be called from an event handler and awaited for its return value. Action ids are
encrypted at build time; `Origin`/`Host` is checked automatically; the body is capped at 1 MB.

### How it maps onto botopink

**`#[serverAction]` is the marker, and it is one marker with two spellings.**

```bp
#[serverAction]
#[@future]
pub fn createPost(form: FormData) -> @Future<ActionResult> { … }
```

That is the inline `'use server'`. The file-level directive is the same decorator applied by the CLI:
`onze13 build` (front 50) reads a file whose first declaration is `pub val useServer = true;` and
attaches `#[serverAction]` to every `pub fn` in it, producing byte-identical registrations to the
hand-written form. There is exactly one registration path, and the acceptance below asserts the two
spellings produce the same thing — a file-level directive that took a different path would be a second
mechanism to audit.

The decorator `@emit`s the rakun-idiom registration, a module-level `val` that runs at module load:

```bp
val __rkAction_createPost = rkRegisterAction("createPost", createPost);
```

**The action id.** `rkRegisterAction` computes it on the server:

```
id = "a_" + crypto.hmacSha256(buildSecret, module + "." + name + ":" + buildId).slice(0, 24)
```

`crypto.hmacSha256` exists in std today (`libs/std/src/crypto.bp:38`) and needs nothing from front 01;
what this front does need from front 01 is the **constant-time compare** used when the id from a
request is checked against the registry, so that id lookup does not leak a prefix through timing.
`buildId` is front 03's content hash of the build, and `buildSecret` is a per-deployment secret from
front 05's config. The properties that matter:

- **stable for a build** — the id stamped into a form by one node resolves on any other node of the
  same build, so rolling restarts and multi-node deployments do not break open tabs;
- **not guessable** — the function's name is not enough to call it, so a `pub fn` that was never
  marked is not reachable by naming it;
- **computed in one place** — only the server computes it. The client never derives an id, it echoes
  the one it was given, so there is nothing to keep in sync and nothing to reimplement in JS.

Why the id is not computed at comptime: a decorator body cannot call sibling functions — the
evaluator emits only the decorator into the eval script (`repository/rakun/src/decorators.bp:44-46`) —
so `crypto.hmacSha256` is unreachable from inside it. Deriving the id at module load is not a workaround, it is the
only place all three inputs exist at once.

**The form.** Built through the public `Element` record, because `element.bp` is frozen:

```bp
pub fn actionForm(action: string, children: Children, attrs: Array<#(string, string)>) -> Element
pub fn hiddenField(name: string, value: string) -> Element
pub fn textField(name: string, placeholder: string) -> Element
pub fn submitButton(label: string) -> Element
```

`actionForm` renders:

```html
<form method="post" action="/blog" data-onze-a="a_9f2c1b7e">
  <input type="hidden" name="__onze_action" value="a_9f2c1b7e">
  …fields…
</form>
```

Void elements render correctly because front 23's walker knows the void set; jhonstart's
`renderToString` would emit `<input></input>`, which is one more reason nothing in this front calls it.

**Two dispatch paths, one authorization path.**

| | Progressive (no JS) | Scripted (front 67) |
|---|---|---|
| transport | `POST` to the current pathname, `application/x-www-form-urlencoded` | `POST` to the same pathname, `Accept: application/onze-action` |
| names the action | the `__onze_action` field | the `X-Onze-Action` header, falling back to the field |
| the server answers with | a full document, or a 303 to the redirect target | the action result envelope, JSON |
| runs | CSRF check, size check, decode, resolve, invoke, revalidate | the same six steps, same code |

The scripted path is the JSON-RPC entry point for calling an action from an event handler
(`§ 10. Invocando via event handlers`): the body is `{"v":1,"id":"a_…","args":["…","…"]}` and the
answer is the same envelope. It differs from the form path in encoding only. Sharing the authorization
path is not an optimization; a second entry point with its own checks is how the check gets skipped.

**CSRF, and why there is no setting.** Before the body is read: if the request carries an `Origin`
header, its host must equal the `Host` header; if it carries none, the request is rejected. 403, no
body read, no action resolved, no log line that suggests retrying with a flag. The rule follows the
project's standing principle — the most restrictive behaviour, and no knob to get around it — so
`actions.bp` exposes no configuration for it and front 05 defines no key. A deployment behind a proxy
that rewrites `Host` fixes its proxy.

**Encodings accepted.** `application/x-www-form-urlencoded` and this front's JSON-RPC body. Not
`multipart/form-data`: there is no byte or binary type in botopink and every `#[@External]` cell
marshals through `string`, so a multipart body would arrive as lossy UTF-8. A 415 is the honest
answer; see *Language gaps*.

**Body size.** Default 1 MiB, raisable through front 05 (`onze13.actions.bodyLimit`) and not
lowerable below 4 KiB. Enforced *while reading*, in `actions.erl`, by counting bytes as they arrive
and closing the connection at the limit — not by reading the body and then measuring it, which is the
version that lets a 2 GB upload exhaust the node before the check runs.

**The result envelope.** The one thing the scripted path returns:

```json
{"v":1,"ok":true,"state":"message=","revalidated":["/blog"],"redirect":"","payload":""}
```

| Key | Meaning |
|---|---|
| `v` | envelope version, `1` |
| `ok` | whether the action returned rather than threw |
| `state` | the action's returned state, querystring-encoded — the `useActionState` value front 67 renders |
| `revalidated` | the paths and tags the action invalidated, echoed so the client can drop its own caches |
| `redirect` | the target of a `redirect()` raised inside the action (front 63), or `""` |
| `payload` | a fresh front-23 payload for the current route when the action requested a refresh, or `""` |

`state` is querystring-encoded for the same reason front 23's params are: both halves must read it
with the same botopink code and `std/json` has no structured walker.

**Revalidation on mutation.** `revalidatePath(path)` and `revalidateTag(tag)` are front 12's. This
front records every call made during an action in the request scope (front 62) and echoes the list in
`revalidated`. On the progressive path, revalidation happens before the re-render, so the document the
user gets back is built from the invalidated-and-refilled cache rather than from the entry the
mutation just made stale. The ordering is the whole point and it is tested.

**`router.refresh()`.** Front 26 owns the client call; this front owns the endpoint. A POST with
`X-Onze-Action: refresh` and no action id re-renders the current route through front 23 and returns
an envelope whose `payload` is the new payload and whose `state` is empty. The client re-reconciles
without a document load. It runs the CSRF check like every other POST.

## Steps

### Step 1 — `#[serverAction]`, both spellings

```bp
pub type FormData(
    fields: Dict<string, string>,
) {
    pub fn field(self: Self, name: string) -> string {
        return self.fields.lookup(name).unwrapOr("");
    }
}

pub type ActionResult(
    state: Dict<string, string>,
) {
    pub fn done() -> ActionResult
    pub fn invalid(field: string, message: string) -> ActionResult
}

pub fn serverAction(comptime decl: @Decl)
```

`field` returns `""` for an absent field rather than `?string`, matching `Request.param`'s decision
and its reasoning (`repository/rakun/src/http.bp:30-34`): a form field that is not there and a form
field that is empty are the same thing to a validator, and optional unwrapping at the boundary buys
nothing. `ActionResult.state` is a `Dict` in botopink and is querystring-encoded on the wire.

**Acceptance:**
- [ ] `#[serverAction]` on a `#[@future] fn(form: FormData) -> @Future<ActionResult>` compiles and
      registers.
- [ ] `#[serverAction]` on a type fails with `#[serverAction] must annotate a function`.
- [ ] `#[serverAction]` on a function that is not `#[@future]` fails, naming the required return
      type — an action is always async so the dispatcher has one shape.
- [ ] A file carrying `pub val useServer = true;` produces, for each of its `pub fn`s, the same
      registration record as the hand-written decorator — compared field by field, not by eyeball.
- [ ] A `pub fn` in a file without the directive and without the decorator is not registered, and
      POSTing its name produces 404, not 500.

### Step 2 — Action ids

```bp
pub fn actionId(module: string, name: string, buildId: string) -> string

#[@External.Erlang("rakun_actions", "register")]
#[@External.Node("./actions.mjs", "register")]
pub declare fn rkRegisterAction(
    name: string,
    run: fn(form: FormData) -> @Future<ActionResult>,
) -> i32;
```

**Acceptance:**
- [ ] `actionId` is deterministic: the same three inputs give the same id in two processes.
- [ ] Changing the build id changes every id.
- [ ] The id is 26 characters, `a_` plus 24 hex, and contains no character that needs escaping in an
      HTML attribute.
- [ ] Two functions with the same name in different modules get different ids.
- [ ] The function's name alone does not resolve: POSTing `__onze_action=createPost` is a 404.

### Step 3 — The form

**Acceptance:**
- [ ] `actionForm` emits `method="post"`, the current pathname as `action`, and the hidden
      `__onze_action` field carrying the id.
- [ ] The form renders through front 23's walker: `<input>` has no closing tag and a field value
      containing `"` is escaped.
- [ ] The rendered form is submittable with scripting disabled — the progressive path is tested by
      driving the raw POST, not by assuming it.
- [ ] `actionForm` refuses an id that is not registered, at render time, with the function name in the
      message. A form pointing at nothing is a bug that should not reach a browser.

### Step 4 — Dispatch, and the checks that come before it

```bp
#[@future]
pub fn dispatchAction(
    pathname: string,
    origin: string,
    host: string,
    contentType: string,
    body: string,
) -> @Future<ActionOutcome>
```

**Acceptance:**
- [ ] `Origin` whose host differs from `Host` gives 403, and the test asserts the body was never read.
- [ ] A POST with no `Origin` header gives 403.
- [ ] `Origin` equal to `Host` proceeds.
- [ ] There is no configuration key, environment variable or decorator argument that disables either
      check. Asserted by the absence of the key in front 05's schema, which is a test, not a promise.
- [ ] A body over the limit is refused at the limit: the connection is closed after at most
      `limit + 8 KiB` bytes have been read, measured in `actions.erl`'s own suite.
- [ ] The limit defaults to 1 MiB, can be raised by config, and cannot be set below 4 KiB.
- [ ] An unknown id gives 404 with an empty body — not a message naming known ids.
- [ ] The id from the request is compared against the registry with front 01's constant-time compare.
- [ ] `Content-Type: multipart/form-data` gives 415. botopink has no byte type — every host cell
      marshals through `string` — so a multipart body cannot be read without corrupting its binary
      parts, and this front refuses it rather than mangling it. File upload is a 1.0.10-beta item.

### Step 5 — The envelope, revalidation and redirect

**Acceptance:**
- [ ] A successful action returns `ok: true` and its state in `state`.
- [ ] An action that throws returns `ok: false`, a `state` carrying the message, and status 200 — a
      validation failure is a rendered form, not an HTTP error.
- [ ] `revalidatePath("/blog")` inside an action puts `/blog` in `revalidated`.
- [ ] On the progressive path, the re-render observes the invalidation: an action that writes a value
      and revalidates its path produces a document containing the new value, and the same test with
      revalidation removed produces the old one. That negative half is what proves the ordering.
- [ ] `redirect("/blog")` inside an action gives 303 with `Location: /blog` on the progressive path,
      and `redirect: "/blog"` in the envelope on the scripted path, from one raise (front 63).
- [ ] The envelope names `v: 1` first.

### Step 6 — The JSON-RPC entry point and `router.refresh()`

**Acceptance:**
- [ ] `{"v":1,"id":"a_…","args":["x"]}` invokes the same function as the equivalent form POST and
      produces the same `state`.
- [ ] The RPC path runs the same CSRF and size checks — asserted by the same test bodies, parameterised
      over the two encodings, so the paths cannot drift.
- [ ] An RPC body with an unknown `v` is a 400.
- [ ] `X-Onze-Action: refresh` returns an envelope whose `payload` parses as a front-23 payload with
      the current pathname, and whose `state` is empty.

## Examples

- [`examples/form-action-example.bp`](./examples/form-action-example.bp) — a form whose submission
  mutates and revalidates: the action, the form that calls it, the validation failure that comes back
  as state, and the assertion that the invalidation happened before the re-render.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Declared parameter defaults are never applied | every `attrs:` in the example, and the reason `actionForm` takes all three arguments | pass every argument explicitly | apply declared defaults at call sites |
| A `#[@future]` fn cannot `await` inside a closure, and `@Future<T>` lowers eagerly on erlang (both stated in full in front 23) | validating N fields with an async check | build `Array<fn() -> @Future<T>>` and await front 02's `async.all` once | see front 23 |
| No byte or binary type — every host cell marshals through `string` | reading a `multipart/form-data` body, whose parts are bytes | the body reaches botopink as a UTF-8 `string`, so this front supports `application/x-www-form-urlencoded` and the JSON-RPC encoding only, and rejects `multipart/form-data` with 415 rather than corrupting it silently | a `bytes` type, or `@External` cells that can marshal a binary |
| `@Decl` carries no source location (stated in full in front 22) | the module half of the action id has to be supplied by the registration cell rather than read off the declaration | the host cell knows the module it was loaded from | `decl.source() -> Source` |

## Blocked

- `repository/rakun/src/http.bp` is frozen and `Response` has no header list, so an action cannot set
  a cookie through it. Cookie writes go through front 62's queue, which front 23 applies when it
  builds the `RenderedPage`. When `http.bp` unfreezes, that queue should become a header list on
  `Response`.
- The body-size limit is enforced in `actions.erl` rather than in botopink, because `Request.body()`
  hands over the whole body as one string and there is no incremental reader in the frozen `http.bp`.

## Test plan

`repository/rakun/test/actions_test.bp`. The decorator, id derivation, dispatch, CSRF, size limit,
revalidation ordering and redirect run on `botopink test --target erlang`. The envelope reader and the
form serializer run on `botopink test --target commonJS` against the same fixture strings. The exit
gate names 24 as a boundary front, so both rows are required.

The round-trip test is the one that matters: the erlang row renders a form and writes the markup to a
fixture; the commonJS row parses the markup, extracts the id, builds the POST body the browser would
send, and the erlang row dispatches it. Testing the two halves separately would pass with an id the
two sides spell differently, which is the exact failure this front exists to prevent.

CSRF and size-limit behaviour that cannot be expressed as a runtime `assert` — the byte count at which
the connection closes — lives in `actions.erl`'s own suite, invoked from the same test file.

## Definition of done

- One registration path for both spellings of the directive, proven by comparing records.
- One authorization path for both encodings, proven by parameterising the same tests.
- No configuration key exists that weakens the `Origin`/`Host` check, and a test asserts its absence.
- The envelope key table above is final for the milestone and is cited by fronts 63, 67 and 68 rather
  than re-derived.
- `repository/rakun/AGENTS.md` names `actions.bp`, the id derivation and the envelope version.
- The front's tests are green on its assigned target — here, on both.
