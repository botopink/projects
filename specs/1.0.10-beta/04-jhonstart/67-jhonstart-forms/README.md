# Front 67 — Jhonstart Forms

**Track:** C jhonstart
**Priority:** high — front 24 dispatches a server action and nothing in the browser binds a form to it, so the central example of `NEXTJS-DOCS.md § 10` and `§ 14` has no client half and no page can submit anything
**Target:** js (client)
**Wave:** 8
**Depends on:** `01-std/05-actions-lib` (`ActionState`, the `state` grammar, `parseActionState`, `writeRpcBody` — the protocol both sides import, decision 116) · 24 (the action endpoint — read-only; jhonstart imports nothing from rakun, and the action id and the wire names `actionField` / `actionHeader` reach the form from onze, decisions 113 and 114) · 29 (the client boundary and the hydration entry) · 94 (`form`, `input`, `button`, `label` — this front defines no constructor) · `01-std/06-validation-lib` (read-only — the constraints an application's client form mirrors; the application imports `from "validation"`, jhonstart imports no validation code) · 26 (navigation after a submit) · 31 (which settled that an `ok: false` envelope is data, not a boundary) · 63 (a redirect returned from an action) · 01 (percent encoding)
**Owns:** `repository/jhonstart/src/form.bp`, `repository/jhonstart/test/form_test.bp` — `form_state.bp` and its test are not written: `ActionState` and its decoder are the bundled library `actions` (decision 116)
**Does not touch:** `repository/jhonstart/src/element.bp`, `src/hooks.bp`, `src/html.bp` (frozen for the milestone), `src/elements.bp` (front 94), `src/router.bp` (front 26), `src/link.bp` (front 27), `src/client.bp` (front 29), `repository/rakun/src/actions.bp` (front 24)
**Reference:** `NEXTJS-DOCS.md § 10. Mutação de Dados` (Formulários · useActionState · Invocando via event handlers · Segurança), `§ 14. Tratamento de Erros` (Erros esperados), `§ 25. Referência de Componentes` (`<Form>`) · `contracts.md § 3` (action id and
envelope, owned by front 24) ·
<https://nextjs.org/docs/app/getting-started/updating-data> ·
<https://nextjs.org/docs/app/api-reference/components/form> ·
<https://react.dev/reference/react/useActionState> ·
<https://react.dev/reference/react-dom/hooks/useFormStatus> ·
<https://react.dev/reference/react/useOptimistic>

---

## Problem

Front 24 registers a server action, gives it an id, and exposes an endpoint that accepts a form
encoding and returns a result. Nothing calls it. In the browser there is no `<form>` whose submit is
intercepted, no place to put the message the action returned, no flag that says a submit is in
flight, and no way to show the new value before the server has agreed to it. A developer following
`NEXTJS-DOCS.md § 10` writes `<form action={formAction}>` and `useActionState` [now `actionState()`], and in this ecosystem
both of those are names with nothing behind them.

The absence is worse than a missing component, because a form is the one interactive element that
must work *before* the client bundle arrives. Next routes mutations through `<form action>` precisely
so that the un-hydrated page still submits — the browser performs an ordinary POST, the server runs
the same action, and the response is a fresh document. If jhonstart's form is a `div` with an
`onclick` handler, a page that fails to hydrate is a page whose forms are decoration. The
progressive-enhancement path is not a nicety here; it is the reason the API has this shape.

And `repository/jhonstart/src/element.bp` has no `form`, no `input`, no `button` and no `label`
(`element.bp:10-53` — the complete constructor set is `text, fragment, div, span, p, h1, ul, li`).
**Front 94 (`jhonstart-element-surface`) owns `form`, `input`,
`button`, `label`, `select` and `textarea` in `repository/jhonstart/src/elements.bp`.** Front 67 adds
no constructor of its own and defines none locally; it imports them from `jhonstart` and marks each
import `// provided by front 94`. `element.bp` stays frozen.

## Current state

Examples use the pre-118 effect annotations; front 24's codemod rewrites them ([`00 · 24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/README.md)).

- `repository/jhonstart/src/element.bp:10-53` — eight constructors, none of them a form control.
  `element.bp:3-8` — `Element(tag, value, children, attrs)`; the `attrs` slot exists, so a form
  element needs no compiler or `element.bp` change once a constructor exists.
- `repository/jhonstart/src/hooks.bp:23-60` — `state`, `effect`, `memo`, `ref`, `reducer`. Every one
  models the first render only: `state` yields its initial value and `set` is a no-op closure
  (`hooks.bp:31-33`). There is no hook that reads anything back from the server.
- `repository/jhonstart/src/server.d.bp:21-26` — `request()` is declared, gated, and server-side; it
  is not the form's input.
- Nothing in the repository mentions `FormData`, a submit, a pending flag or an optimistic value.
  `grep -rn "form" repository/jhonstart/src/` returns only the `#fragment` tag name.
- `libs/std/src/querystring.bp:35,48` — `parse` and `stringify` over
  `Array<#(string, string)>`, pure botopink on every backend. Its own header records that percent
  encoding is not implemented yet and that a value containing `&` or `=` round-trips incorrectly;
  front 01 owns the escape primitives this front needs because of that.

## Mechanism

Upstream, a form is three separate things wearing one tag. The **binding** turns a function reference
into a submit target. The **transport** encodes the fields and posts them. The **state** is what the
action gave back, plus whether a submit is currently in flight, plus a value the UI shows before the
answer arrives. React fuses them behind `<form action={fn}>` because it can pass a function through
the tree. botopink cannot: an `Element`'s `attrs` slot holds `#(string, string)` pairs
(`element.bp:7`), so an attribute value is a string and nothing else.

So the binding is a **string**, and it is front 24's action id. Front 24 owns that id and its
derivation — `"a_" + crypto.hmacSha256(buildSecret, module + "." + name + ":" + buildId)` truncated to
24 characters, computed on the server and never derived in the browser. This front echoes it and
never constructs it.

`formAction(id, pathname, actionField)` produces a `FormBinding`; `formAttrs(binding)` produces the
`attrs` array a `form` element carries, and it is **front 24's markup, matched exactly**:

```
<form method="post" action="<pathname>" data-jh-a="<id>">
  <input type="hidden" name="<actionField>" value="<id>">
```

**The wire names are handed in, never spelled here** (decision 114, item 7). The hidden field's name
(`actionField`) and the header of the scripted POST (`actionHeader`) are values onze passes to this
front and, with the same values, to rakun front 24's configuration (`rakun.actions.field`,
`rakun.actions.header`). jhonstart holds no default and no literal for either; onze's defaults are
`__bp_action` and `X-Bp-Action`, and every example and fixture in this track passes those.

That set is not an implementation detail — it is the whole progressive-enhancement story. With no
JavaScript the browser reads `action` and `method`, posts the fields to the current pathname, and the
hidden `actionField` field tells front 24 which action ran. With the bundle loaded, front 68's
hydration entry finds every `[data-jh-a]`, attaches a submit listener, cancels the default, posts
the same body with `fetch` plus the `actionHeader` header, and applies the answer without a document
navigation. Both paths hit the same URL through the same authorization path — front 24 admits no
second door, and no configuration key weakens its `Origin`/`Host` check. This front adds neither.

`hiddenActionField(binding) -> Element` is what produces the hidden input, so a form that forgets it
is a form that does not compile rather than a form that posts to nothing.

### The envelope, and who owns which half

Front 24 writes the response envelope and this front reads it, but neither owns its text: the
envelope, the `state` grammar, `ActionState` and its decoder are the bundled library `actions`
(`libs/actions`, `01-std/05-actions-lib`, decision 116), which rakun and jhonstart both import —
neutral like `routing`, not an edge between them.

```json
{"v":1,"ok":true,"state":"<querystring>","revalidated":[…],"redirect":"…","n":"…","payload":"…"}
```

- **`__jhFormSubmit` returns the response body as it arrived.** It does no `JSON.parse` and no
  flattening; `actions`' `parseActionState(envelope)` reads the JSON (an inline template on each
  target) and the `state` querystring (std's `encoding`), so there is one reader of the envelope in
  the stack and it is tested on both targets.
- **The `state` grammar is `actions`'** — `message` for the form-level message, `f.<name>` per field;
  `ok` and `redirect` come from the envelope, not from `state`. This front imports `ActionState`
  (`ok`, `message`, `redirectTo`, `fields`, `fieldError`, `hasError`) and `newActionState` from
  `"actions"` and defines neither.
- **The envelope's `n`** — the navigation signal — is read by front 26's router with `routing`'s
  `signalFromWire` when this front hands it the parsed result.

**An `ok: false` envelope is data, and this front handles it.** Front 31 settled that: an action that
returns a failure — a validation message, a rejected input, a conflict — produces a normal envelope
with `ok: false`, and it reaches the page as `ActionState`, rendered beside the field it belongs to.
It does **not** reach an error boundary, does not unmount the form, and does not lose what the user
typed. Only a *raised* POST — a request that never produced an envelope at all — reaches a boundary.
That is the whole of `NEXTJS-DOCS.md § 14`'s *Erros esperados* distinction, and it is why
`actionState`'s state carries a message rather than throwing: an expected failure is a value.
`contracts.md § 3` is the envelope this rests on.

The `state` literal the two sides once pinned separately
(`message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short`) is asserted once, in
`libs/actions`, on both targets; this front's tests use it as input and do not re-assert the grammar.

### Calling an action from an event handler

`NEXTJS-DOCS.md § 10` *Invocando via event handlers*: a button's click handler calls an action and
awaits its state, with no form. The request is front 24's scripted path — the same POST to the
current pathname, the `actionHeader` header onze names, and the JSON-RPC body
`{"v":1,"id":…,"args":[…]}`. **This front is the one writer of that body in the browser**: it builds
it with `actions`' `rpc.writeRpcBody` and reads the answer with `parseActionState`, over one more
browser-only cell:

```bp
#[@future]
pub fn invokeAction(actionId: string, args: Array<string>, actionHeader: string) -> @Future<ActionState>
```

`__jhFormInvoke(actionId, body, actionHeader) -> string` posts the body and returns the response body
as it arrived. onze's generated entry and a front 53 component call `invokeAction`; no other package
spells the RPC body.

### The three hooks, and what the server render sees

All three are hooks in the existing sense: `#[@use] fn … -> @Use<ElementBase, _>` (decision 102),
legal under `use` inside a `#[@use] fn … -> @Component<Element>` body (decision 104; `hooks.bp:23-60`).
During the server pass each yields its quiet value —
`actionState` yields the initial state with `pending: false`, `formStatus` yields idle,
`optimistic` yields the base value. That is not a stub; it is the correct first render. A spinner
in the server HTML is a spinner nobody can stop, and an optimistic value in the server HTML is a lie
the server told.

The browser values come from five `#[@External.Node]` cells, all of them browser-only, none with an
erlang twin:

- `__jhFormSubmit(actionId, encodedBody, actionHeader) -> string` — posts with the header onze named
  and returns the response body unparsed; `encodedBody` is `encoding.formStringify` of the fields.
- `__jhFormInvoke(actionId, rpcBody, actionHeader) -> string` — the scripted call of
  `invokeAction`, the body written by `actions`' `writeRpcBody`, the response body returned unparsed.
- `__jhFormPending(actionId) -> string` — `"1"` while a submit for that id is in flight.
- `__jhFormState(actionId) -> string` — the last envelope received for that id, `""` before the first.
- `__jhFormMount(actionHeader)` — delegated submit interception over `[data-jh-a]`. It is private;
  the entry imports the `pub fn formMount(actionHeader: string)` over it (an ordinary import, not a
  browser global — decision 113), called once by front 68's hydration entry alongside front 27's
  `linkMount()`, with the header name onze passes (decision 114).

### Optimistic updates

`optimistic(base, apply)` returns the pair `#(value, push)`. Before hydration `value` is `base`
and `push` is a no-op. After hydration, `push(action)` records the action against the id of the
in-flight submit; `value` is `apply` folded over every recorded action. When the envelope arrives the
recorded actions are dropped and `value` collapses back to the new `base` — which is the roll-back
path and the commit path at once, because both are "forget the predictions and take the server's
answer". There is no third state and no `rollback()` to call.

The fold function is pure and lives here, not in the host cell: `applyOptimistic(base, actions, apply)`
is what the tests exercise, and `__jhFormOptimistic` only supplies the action list.

### `Form` — the GET form of §25

`NEXTJS-DOCS.md § 25` `<Form action="/search">` is a different mechanism with the same tag: no action
id, no POST, no state. It turns its fields into a client navigation to a path with search params, and
it prefetches that path. It is four lines over front 26's `push` and front 27's prefetch, and it
belongs here because it is a form. Unhydrated it is a plain `method="get"` form, which the browser
already does correctly — this is the one case where progressive enhancement costs nothing.

## Steps

### Step 1 — `ActionState` from `actions`

`ActionState`, `newActionState` and `parseActionState(envelope)` (decision 78's name) are imported
from the bundled library `actions`; this front writes no decoder and no `form_state.bp`.

**Acceptance:**
- [ ] `form.bp` imports `ActionState`, `newActionState` and `parseActionState` from `"actions"`, and
      `git grep -n "fn parseActionState\|type ActionState" modules/jhonstart/` is empty
- [ ] `__jhFormSubmit`'s Node template contains no `JSON.parse`; the string it returns reaches
      `parseActionState` unchanged — asserted by a stub cell returning a literal envelope
- [ ] no test under `modules/jhonstart/test/` asserts the `state` literal against the grammar; the
      grammar's test is `libs/actions`'
- [ ] `fieldError` of an absent name is `""` — through the imported type, one absence convention for
      the whole stack (rakun's `Request.param`, front 49's `Params.param`)

### Step 2 — `FormBinding` and the attributes

`src/form.bp`.

```bp
pub type FormBinding(actionId: string, pathname: string, method: string, actionField: string)

pub fn formAction(actionId: string, pathname: string, actionField: string) -> FormBinding
pub fn formAttrs(binding: FormBinding) -> Array<#(string, string)>
pub fn hiddenActionField(binding: FormBinding) -> Element
```

The markup is `contracts.md § 3`'s, matched exactly and not restated differently here: `method="post"`,
`action` the current pathname, `data-jh-a` the action id, plus the hidden field named by
`actionField`. `formAction` takes the pathname and the field name explicitly because there is no assignment to a `self` field and a
declared default would never be applied — a builder pair would be two functions to get one string.

**Acceptance:**
- [ ] `formAttrs` emits exactly three pairs, in the order `method`, `action`, `data-jh-a`
- [ ] `formAttrs(formAction("a_9f…", "/blog/hello", "__bp_action"))` has `action="/blog/hello"` — the current
      pathname, never a synthesized endpoint
- [ ] `hiddenActionField` renders `<input type="hidden" name="<actionField>" value="<id>">` — with
      `"__bp_action"` passed, `name="__bp_action"` — and a form built without it fails its own test;
      the un-hydrated POST is unroutable without it
- [ ] no `__bp_action`, `X-Bp-Action` or other wire-name literal appears under `src/` — the names
      reach this front only as `actionField` / `actionHeader` (grep in the gate)
- [ ] `renderToString` of a complete form contains `method="post"` and the hidden field
- [ ] An action id that does not start with `a_`, or contains `/`, a space or a quote, is rejected by
      `formAction` naming the id — this front echoes front 24's id and never constructs one

### Step 3 — `actionState`

```bp
#[@use]
pub fn actionState(
    actionId: string,
    initial: ActionState,
) -> @Use<ElementBase, #(ActionState, FormBinding, bool)>
```

Read positionally — `s.0` the state, `s.1` the binding, `s.2` the pending flag — because the labels of
a labeled tuple return are lost through generic instantiation and jhonstart already documents that at
`hooks.bp:75-77`. The three-element shape matches `§ 10`'s
`const [state, formAction, pending] = useActionState(...)` element for element, so a reader of the
upstream doc finds the same three things in the same order.

**Acceptance:**
- [ ] On the server pass, `s.0` is the `initial` argument unchanged and `s.2` is `false`
- [ ] `s.1` is a `FormBinding` for `actionId`, so the component never names the endpoint
- [ ] After `__jhFormState` returns an envelope written by `actions`' `writeEnvelope` whose `state`
      is `writeState("…", [#("title", "Too short")])`, `s.0.fieldError("title") == "Too short"`
- [ ] `s.0.redirectTo` non-empty makes the browser half call front 26's `push` exactly once, and the
      form is not re-rendered with a stale state afterwards
- [ ] An `ok: false` envelope updates the state and re-renders the form **in place** — no boundary is
      entered, no field value is lost, asserted against front 31's error-boundary test which asserts
      the same envelope does not reach it
- [ ] A component that calls `actionState` twice with different ids gets two independent states

### Step 4 — `formStatus`

```bp
pub type FormStatus(pending: bool, actionId: string, method: string)

#[@use]
pub fn formStatus() -> @Use<ElementBase, FormStatus>
```

The hook a nested submit button calls to disable itself, without the parent threading `pending` down
through every intermediate component. Absent from this doc revision — see *Reference gaps*.

**Acceptance:**
- [ ] The server pass yields `FormStatus(pending: false, actionId: "", method: "post")`
- [ ] Inside a form whose submit is in flight, `pending` is `true` and `actionId` is that form's id
- [ ] Outside any form, `pending` is `false` and `actionId` is `""` — never an error
- [ ] Two forms submitting at once give each button its own form's status, asserted with two ids

### Step 5 — `optimistic`

```bp
#[@use]
pub fn optimistic<T>(
    base: T,
    apply: fn(current: T, action: T) -> T,
) -> @Use<ElementBase, #(T, fn(action: T))>

pub fn applyOptimistic<T>(base: T, actions: Array<T>, apply: fn(current: T, action: T) -> T) -> T
```

**Acceptance:**
- [ ] The server pass yields `#(base, <no-op>)` and rendering it twice gives identical HTML
- [ ] `applyOptimistic(0, [1, 1, 1], { c, a -> c + a }) == 3`
- [ ] `applyOptimistic(base, [], apply) == base` — no prediction is the identity
- [ ] When an envelope arrives the recorded actions are dropped, so a commit and a roll-back are the
      same code path, asserted by one test per outcome ending in the same assertion
- [ ] `push` called after the envelope arrives records against the next submit, not the finished one

### Step 6 — `Form`, the GET search form

```bp
pub type SearchFormProps(action: string, prefetch: bool, replace: bool)

pub fn searchFormProps(action: string) -> SearchFormProps
pub fn searchFormAttrs(props: SearchFormProps) -> Array<#(string, string)>
```

**Acceptance:**
- [ ] `searchFormAttrs` emits `method="get"` and `action="/search"`, and `data-jh-a` is absent —
      a GET form is not an action submit and front 24's interceptor must not claim it
- [ ] `data-jh-sf="1"` marks it for the navigation interceptor instead — a `data-jh-*` marker,
      because jhonstart writes it (decision 113), registered in `contracts.md § 2` with owner 67
- [ ] With `prefetch: true` the target path is prefetched through front 27's `__jhLinkPrefetch`
- [ ] Un-hydrated, the browser's own GET submit produces the same URL the hydrated path produces,
      asserted by comparing `encoding.formStringify` of the field list against the built URL

### Step 7 — `invokeAction`, the scripted call

**Acceptance:**
- [ ] `invokeAction("a_9f2c1b7e", ["x"], "X-Bp-Action")` hands `__jhFormInvoke` exactly the body
      `writeRpcBody(RpcCall(id: "a_9f2c1b7e", args: ["x"]))` answers and the header name passed —
      asserted by a recording stub cell
- [ ] the answer is `parseActionState` of what the cell returned; an `ok: false` envelope resolves
      the future with that state and raises nothing
- [ ] `git grep -n '"v":1' modules/jhonstart/src` is empty — the body is written by `actions` only
- [ ] no `X-Bp-Action` or other header literal under `src/`; the name is the `actionHeader` passed in

## Examples

- [`examples/create-post-form-example.bp`](./examples/create-post-form-example.bp) — the §10 form,
  end to end: the binding, the returned message rendered beside the field, and the disabled button
  while the submit is in flight.
- [`examples/optimistic-like-example.bp`](./examples/optimistic-like-example.bp) — a like button that
  shows the new count before the server answers, and a nested submit button reading `formStatus`.
- [`examples/search-form-example.bp`](./examples/search-form-example.bp) — the §25 `<Form>`: a GET
  form that becomes a client navigation with search params.

## Reference gaps

`useFormStatus` and `useOptimistic` [now `formStatus()` / `optimistic()`] are **not in this revision of `NEXTJS-DOCS.md`** — a grep for
either name returns nothing, and the coverage audit records both as absent. They are specified here
from upstream React, not from the local doc, and the example files cite
<https://react.dev/reference/react-dom/hooks/useFormStatus> and
<https://react.dev/reference/react/useOptimistic> rather than a section number they would otherwise
have to invent. The rest of this front — the form binding, `actionState`, the returned message,
the GET `<Form>` — is `§ 10`, `§ 14` and `§ 25` and is cited as such.

`NEXTJS-DOCS.md § 10` *Segurança* states the CSRF `Origin`/`Host` check and the 1 MB body limit. Both
are enforced on the server and are fold-ins to front 24; this front neither implements nor weakens
them, and a form that posts to the endpoint gets the check whether or not it came from here.

## Naming under the `use` rule

Every hook of this front is spelled by [`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md) and decisions 102/104: `#[@use] fn <noun>(…) -> @Use<ElementBase, _>`, the keyword `use` is the
activation, the name is the noun of what is yielded, never `use`-prefixed — `actionState`, `formStatus`,
`optimistic`; activated as `val s = use actionState(id, initial)` inside a `#[@use] fn … -> @Component<Element>`
body, called plainly (`actionState(id, initial)`) for the server-pass value, which is what every `test` here
does (a `test` body carries no `#[@use]`, so `use` is illegal there).

| Name | Rule |
|---|---|
| `actionState(actionId, initial)` — the hook owns the noun; `newActionState(message)` — the helper takes a verb, like its sibling `parseActionState` | the type constructor stays `ActionState(ok:, message:, redirectTo:, fields:)` — PascalCase, four required fields (declared defaults are not applied, see below), which is why a helper exists at all |
| `formStatus()` / `FormStatus(…)`, `optimistic()` / `applyOptimistic(…)` | no collision — a constructor is PascalCase, the helper carries a verb |

A binding never reuses its hook's name (`val s = use actionState(…)`, not `val actionState = …`): the
checker's bindings are one flat map and a local would shadow the imported fn for the rest of the module
(`19-use-activation/surface.md § 4`, derived).

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Tuple labels are lost through generic instantiation, so a hook's multi-value return is read positionally | `actionState` (`s.0`/`s.1`/`s.2`) in `create-post-form-example.bp`; `optimistic-like-example.bp` destructures positionally instead | read by index and bind each element to a named `val` on the next line | preserve the written labels through instantiation (`hooks.bp:75-77` already files this) |
| Tuple destructuring from a `use` binds fresh type vars — `val #(shown, push) = use optimistic(…)` parses (`parser/exprs.zig:661-676`) and lowers (`codegen/tests/features.zig:209`), but `shown`/`push` take no type from `R` (`infer.zig:8194-8196`); front 01 records the labeled half | `optimistic-like-example.bp` — `shown` is typed only by flowing into `likeWidget`'s `i32` | the destructure, with each element used where its type is fixed; or `o.0` | bind each element to `R`'s tuple element — [`19-use-activation`](../../00-compiler-carry-over/19-use-activation/README.md) step 3 |
| No assignment to a `self` field | `withBasePath`, and every optimistic update | return a new record | mutable record fields, or a `with` expression |
| Declared parameter defaults are never applied | every constructor call in the examples spells `attrs:`, and `formAction` has no optional second parameter | pass every argument explicitly; a second constructor per default | apply the declared default at the call site |
| A closure stored in a record field cannot be replaced after construction, so `push` must be handed out by the hook rather than rebound | `optimistic`'s `#(T, fn(action: T))` | the host cell holds the action list and the closure reads it | see the `self`-field gap — the same fix covers it |

## Test plan

`repository/jhonstart/test/form_test.bp`, run by `botopink test` from `repository/jhonstart/` and by
`zig build test-libs`. The envelope and the `state` grammar are tested in `libs/actions`
(`01-std/05-actions-lib`), on both targets; this front asserts only that it hands them the body it
received and the body it sends.

`form_test.bp` is the attributes and the hooks' server-pass values: `formAttrs`'s three pairs and
their order, the hidden field under the `actionField` passed in, the idle `FormStatus`, and
`applyOptimistic`'s fold. The four `#[@External.Node]` cells cannot be exercised by
`botopink test` — there is no DOM — so what is asserted is the boundary either side of them: the
string handed to `__jhFormSubmit` and the `ActionState` decoded from what it returns. The submit
interception itself is covered by front 53's example app, which is the first place a real browser is
in the loop.

The progressive-enhancement claim is checked as a *markup* assertion, not a browser one: a rendered
form must carry `method="post"`, the current pathname in `action`, and the hidden field named by
the `actionField` passed in (`__bp_action` in the test), and a test asserts the exact string. That is the property that makes the un-hydrated path
work, and it is falsifiable without a browser.

## Definition of done

- [ ] `src/form.bp` exists and `botopink build` succeeds in `repository/jhonstart/`; there is no
      `form_state.bp`
- [ ] `ActionState`, `parseActionState` and the RPC body come from `"actions"` (decision 116); the
      `state` literal is asserted in `libs/actions` only
- [ ] `invokeAction` is the one writer of the JSON-RPC body in the browser
- [ ] Every element constructor the examples call (`form`, `input`, `button`, `label`) is imported
      from `jhonstart` and marked `// provided by front 94`; this front's source defines none, and
      `element.bp` is unmodified
- [ ] `formStatus` and `optimistic` are marked in `repository/jhonstart/docs.md` as specified
      from upstream React rather than from `NEXTJS-DOCS.md`
- [ ] Every `// LANGUAGE GAP:` marker in the three example files appears in the table above
- [ ] The front's tests are green on its assigned target — `commonJS`
