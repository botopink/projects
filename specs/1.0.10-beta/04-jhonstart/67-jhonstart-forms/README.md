# Front 67 — Jhonstart Forms

**Track:** C jhonstart
**Priority:** high — front 24 dispatches a server action and this front is what binds a form to it in the browser: the central example of `NEXTJS-DOCS.md § 10` and `§ 14`
**Target:** js (client); the member runs both rows — its pure half renders in the server pass and every host cell is dual-target
**Wave:** 8
**Depends on:** `01-std/05-actions-lib` (`ActionState`, the `state` grammar, `parseActionState`, `writeRpcBody` — the protocol both sides import, decision 116) · 24 (the action endpoint — read-only; jhonstart imports nothing from rakun, and the action id and the wire names `actionField` / `actionHeader` reach the form from onze, decisions 113 and 114) · 29 (the client boundary and the hydration entry) · 94 (`form`, `input`, `button`, `label` — this front defines no constructor) · `01-std/06-validation-lib` (read-only — the constraints an application's client form mirrors; the application imports `from "validation"`, jhonstart imports no validation code) · 26 (navigation after a submit) · 27 (the link prefetcher) · 31 (which settled that an `ok: false` envelope is data, not a boundary) · 63 (a redirect returned from an action) · 01 (percent encoding)
**Owns:** the member `repository/jhonstart/modules/jhonstart-forms/` — `src/form.bp`, `src/root.bp`, `botopink.json`, the host halves `src/form_runtime.mjs` / `src/sidecars/jhonstart_forms.erl`, `test/form_test.bp`. There is no `form_state.bp`: `ActionState` and its decoder are the bundled library `actions` (decision 116)
**Reference:** `NEXTJS-DOCS.md § 10. Mutação de Dados` (Formulários · useActionState · Invocando via event handlers · Segurança), `§ 14. Tratamento de Erros` (Erros esperados), `§ 25. Referência de Componentes` (`<Form>`) · `contracts.md § 3` (action id and envelope, owned by front 24) ·
<https://nextjs.org/docs/app/getting-started/updating-data> ·
<https://nextjs.org/docs/app/api-reference/components/form> ·
<https://react.dev/reference/react/useActionState> ·
<https://react.dev/reference/react-dom/hooks/useFormStatus> ·
<https://react.dev/reference/react/useOptimistic>

---

## Outcome

A form bound to a server action, its state, the in-flight status, the optimistic value and the GET
search form, in the member `jhonstart-forms` (`import {formAction, formAttrs, …} from
"jhonstart-forms";` beside `import {form, input, button} from "jhonstart";`). A form is the one
interactive element that must work **before** the client bundle arrives, and the API's shape follows
from that: the un-hydrated page submits an ordinary POST, and the hydrated page posts the same body
to the same URL.

### The surface — `form.bp`

```bp
pub fn setWireNames(actionField: string, actionHeader: string) -> i32   // onze, once, at boot

pub type FormBinding(actionId: string, pathname: string, method: string, actionField: string)
pub fn formAction(actionId: string, pathname: string, actionField: string) -> FormBinding
pub fn formAttrs(binding: FormBinding) -> Array<#(string, string)>
pub fn hiddenActionField(binding: FormBinding) -> Element
pub fn actionForm(binding: FormBinding, fields: Array<Element>) -> Element   // the hidden field first, always

pub fn submitForm(binding: FormBinding, fields: Array<#(string, string)>) -> @Task<ActionState>
pub fn invokeAction(actionId: string, args: Array<string>, actionHeader: string) -> @Task<ActionState>
pub fn formMount(actionHeader: string) -> i32

pub fn actionState(actionId: string, initial: ActionState) -> @Component<ElementBase, #(ActionState, FormBinding, bool)>
pub type FormStatus(pending: bool, actionId: string, method: string)
pub fn idleFormStatus() -> FormStatus
pub fn formStatusOf(actionId: string) -> FormStatus
pub fn formStatus() -> @Component<ElementBase, FormStatus>
pub fn applyOptimistic<T>(base: T, actions: Array<T>, apply: fn(current: T, action: T) -> T) -> T
pub fn optimistic<T>(base: T, apply: fn(current: T, action: T) -> T) -> @Component<ElementBase, #(T, fn(action: T) -> i32)>

pub type SearchFormProps(action: string, prefetch: bool, replace: bool)
pub fn searchFormProps(action: string) -> SearchFormProps
pub fn searchFormAttrs(props: SearchFormProps) -> Array<#(string, string)>
pub fn searchHref(props: SearchFormProps, fields: Array<#(string, string)>) -> string
pub fn prefetchSearch(props: SearchFormProps) -> i32                     // jhonstart-link's linkPrefetch

pub fn stubResponse(text: string) -> i32      // test seam: the next cell answer
pub fn lastFormCall() -> string               // test seam: what the last cell was handed
```

**The binding is a string** — front 24's action id. An `Element`'s `attrs` slot holds string pairs,
so a function reference cannot travel through an attribute; front 24 owns the id and its derivation
(computed on the server, never in the browser), and this front echoes it and never constructs it.
`formAction` refuses an id that does not start with `a_` or contains `/`, a space or a quote, naming
the id. `formAttrs` + `hiddenActionField` are **contract 3's markup, matched exactly**:

```
<form method="post" action="<pathname>" data-jh-a="<id>">
  <input type="hidden" name="<actionField>" value="<id>">
```

**The wire names are handed in, never spelled here** (decision 114, item 7). The hidden field's name
(`actionField`) and the header of the scripted POST (`actionHeader`) are values onze passes to this
front (`setWireNames`) and, with the same values, to rakun front 24's configuration
(`rakun.actions.field`, `rakun.actions.header`). jhonstart holds no default and no literal for
either; onze's defaults are `__bp_action` and `X-Bp-Action`, and every example and fixture in this
track passes those.

That is the whole progressive-enhancement story. With no JavaScript the browser reads `action` and
`method`, posts the fields to the current pathname, and the hidden field tells front 24 which action
ran. With the bundle loaded, `formMount(actionHeader)` — called once by front 68's hydration entry
alongside front 27's `linkMount()` — intercepts the submit over `[data-jh-a]`, posts the same body
with the `actionHeader` header, and applies the answer without a document navigation. Both paths hit
the same URL through the same authorization path — front 24 admits no second door, and no
configuration key weakens its `Origin`/`Host` check.

### The envelope, and who owns which half

Front 24 writes the response envelope and this front reads it, but neither owns its text: the
envelope, the `state` grammar, `ActionState` and its decoder are the bundled library `actions`
(`libs/actions`, `01-std/05-actions-lib`, decision 116), which rakun and jhonstart both import —
neutral like `routing`, not an edge between them.

```json
{"v":1,"ok":true,"state":"<querystring>","revalidated":[…],"redirect":"…","n":"…","payload":"…"}
```

- **`__jhFormSubmit` returns the response body as it arrived.** It does no `JSON.parse` and no
  flattening; `actions`' `parseActionState(envelope)` reads the JSON and the `state` querystring
  (std's `encoding`), so there is one reader of the envelope in the stack and it is tested on both
  targets.
- **The `state` grammar is `actions`'** — `message` for the form-level message, `f.<name>` per field;
  `ok` and `redirect` come from the envelope, not from `state`. This front imports `ActionState`
  (`ok`, `message`, `redirectTo`, `fields`, `fieldError`, `hasError`) and `newActionState` from
  `"actions"` and defines neither.
- **The envelope's `n`** — the navigation signal — is read by front 26's router with `routing`'s
  `signalFromWire`; a redirect in the answer is the router's `push`, exactly once.

**An `ok: false` envelope is data, and this front handles it.** Front 31 settled that: an action that
returns a failure — a validation message, a rejected input, a conflict — produces a normal envelope
with `ok: false`, and it reaches the page as `ActionState`, rendered beside the field it belongs to.
It does **not** reach an error boundary, does not unmount the form, and does not lose what the user
typed. Only a *raised* POST — a request that never produced an envelope at all — reaches a boundary.
That is `NEXTJS-DOCS.md § 14`'s *Erros esperados* distinction, and it is why `actionState`'s state
carries a message rather than throwing: an expected failure is a value. The `state` literal is
asserted once, in `libs/actions`, on both targets; this front's tests use it as input.

### Calling an action from an event handler

`NEXTJS-DOCS.md § 10` *Invocando via event handlers*: a click handler calls an action and awaits its
state, with no form. The request is front 24's scripted path — the same POST to the current
pathname, the `actionHeader` header, and the JSON-RPC body `{"v":1,"id":…,"args":[…]}`. **This front
is the one writer of that body in the browser**: `invokeAction` builds it with `actions`'
`rpc.writeRpcBody`, hands it to `__jhFormInvoke`, and reads the answer with `parseActionState`; an
`ok: false` answer resolves with that state and raises nothing. onze's generated entry and a front
53 component call `invokeAction`; no other package spells the RPC body.

### The three hooks, and what the server render sees

`actionState`, `formStatus` and `optimistic` are hooks: `fn … -> @Component<ElementBase, _>`,
activated with `use` inside a `fn … -> @Component<ElementBase, Element>` body and called plainly for
the server-pass value (`README.md § 6`). During the server pass each yields its quiet value —
`actionState` the initial state with `pending: false`, `formStatus` idle, `optimistic` the base
value. A spinner in the server HTML is a spinner nobody can stop, and an optimistic value in it is a
lie the server told.

`actionState` answers `#(state, binding, pending)`, read positionally (`s._0`, `s._1`, `s._2`) —
`§ 10`'s `const [state, formAction, pending] = useActionState(...)` element for element. `formStatus`
is the hook a nested submit button calls to disable itself without the parent threading `pending`
down; outside any form it is idle, never an error.

The browser values come from the cells in `form_runtime.mjs`, each with an erlang twin in
`sidecars/jhonstart_forms.erl` that answers the server's quiet value and records the call for the
test (`decisions-pending.md` 27-a):

- `__jhFormSubmit(actionId, encodedBody, actionHeader) -> @Task<string>` — posts with the header and
  returns the response body unparsed; `encodedBody` is `encoding.formStringify` of the fields.
- `__jhFormInvoke(actionId, rpcBody, actionHeader) -> @Task<string>` — the scripted call of
  `invokeAction`.
- `__jhFormPending(actionId) -> string` — `"1"` while a submit for that id is in flight.
- `__jhFormState(actionId) -> string` — the last envelope received for that id, `""` before the first.
- `__jhFormMount(actionHeader)` — delegated submit interception over `[data-jh-a]`, private behind
  `formMount` (an ordinary import, not a browser global — decision 113).
- `__jhFormStub` / `__jhFormLastCall` — the test seam behind `stubResponse` / `lastFormCall`.

### Optimistic updates

`optimistic(base, apply)` returns the pair `#(value, push)`. Before hydration `value` is `base` and
`push` is a no-op. After hydration, `push(action)` records the action against the id of the
in-flight submit; `value` is `apply` folded over every recorded action. When the envelope arrives the
recorded actions are dropped and `value` collapses back to the new `base` — the roll-back path and
the commit path at once. There is no third state and no `rollback()` to call. The fold is pure
(`applyOptimistic`) and is what the tests exercise.

### `Form` — the GET form of §25

`NEXTJS-DOCS.md § 25` `<Form action="/search">` has no action id, no POST, no state: it turns its
fields into a client navigation to a path with search params (`searchHref`, over front 26's `push`)
and prefetches that path (`prefetchSearch`, over `jhonstart-link`'s `linkPrefetch`). Its markup is
`method="get"`, the `action`, and `data-jh-sf="1"` (registered in `contracts.md § 2`, owner 67) — no
`data-jh-a`, so the action interceptor never claims it. Unhydrated it is a plain GET form, which
the browser already does correctly, producing the same URL.

## Delivered

Held by `modules/jhonstart-forms/test/form_test.bp` on both rows unless noted:

- **Step 1** — `ActionState`, `newActionState` and `parseActionState` are imported from `"actions"`;
  no `fn parseActionState` / `type ActionState` in the tree; the submit cell answers the body as it
  arrived (a stub cell with a literal envelope); no test re-asserts the `state` grammar;
  `fieldError` of an absent name is `""`.
- **Step 2** — `formAttrs` is exactly `method`, `action`, `data-jh-a`, the action the current
  pathname; the hidden field is named by the `actionField` passed in; no wire-name literal under
  `src/` (`setWireNames` is the one entry); a complete form carries `method="post"` and the hidden
  field; an id that is not front 24's is refused, naming it.
- **Step 3** — `actionState`'s server pass is the initial state, a binding for the id, not pending;
  two ids give two independent states; a redirect in the envelope is the router's `push`, exactly
  once (`submitForm`).
- **Step 4** — `formStatus` is `FormStatus(pending: false, actionId: "", method: "post")` on the
  server pass and outside any form.
- **Step 5** — `optimistic`'s server pass is the base and a no-op push; `applyOptimistic` folds the
  actions and no prediction is the identity.
- **Step 6** — the search form is `method="get"` with `data-jh-sf` and no `data-jh-a`; prefetch goes
  through the link prefetcher only when asked; the GET submit's URL is the one the client navigation
  builds.
- **Step 7** — `invokeAction` hands the cell `writeRpcBody`'s body and the header passed (a
  recording stub); `ok: false` resolves with the state; no `"v":1` and no header literal under
  `src/`.
- `docs.md` § *Forms* marks `formStatus` and `optimistic` as specified from upstream React.

## Steps

Only the boxes still open are listed; the done ones are *Delivered* above.

### Step 1 — `ActionState` from `actions`

`ActionState`, `newActionState` and `parseActionState(envelope)` (decision 78's name) are imported
from the bundled library `actions`; this front writes no decoder and no `form_state.bp`. Done.

### Step 2 — `FormBinding` and the attributes

Done.

### Step 3 — `actionState`

- [ ] After `__jhFormState` returns an envelope written by `actions`' `writeEnvelope` whose `state`
      is `writeState("…", [#("title", "Too short")])`, `s._0.fieldError("title") == "Too short"`
- [ ] An `ok: false` envelope updates the state and re-renders the form **in place** — no boundary is
      entered, no field value is lost, asserted against front 31's error-boundary test which asserts
      the same envelope does not reach it

### Step 4 — `formStatus`

- [ ] Inside a form whose submit is in flight, `pending` is `true` and `actionId` is that form's id
- [ ] Two forms submitting at once give each button its own form's status, asserted with two ids

### Step 5 — `optimistic`

- [ ] When an envelope arrives the recorded actions are dropped, so a commit and a roll-back are the
      same code path, asserted by one test per outcome ending in the same assertion
- [ ] `push` called after the envelope arrives records against the next submit, not the finished one

### Step 6 — `Form`, the GET search form

Done.

### Step 7 — `invokeAction`, the scripted call

Done.

## Examples

- [`examples/create-post-form-example.bp`](./examples/create-post-form-example.bp) — the §10 form,
  end to end: the binding, the returned message rendered beside the field, and the disabled button
  while the submit is in flight.
- [`examples/optimistic-like-example.bp`](./examples/optimistic-like-example.bp) — a like button that
  shows the new count before the server answers, and a nested submit button reading `formStatus`.
- [`examples/search-form-example.bp`](./examples/search-form-example.bp) — the §25 `<Form>`: a GET
  form that becomes a client navigation with search params.

## Reference gaps

`useFormStatus` and `useOptimistic` (here `formStatus()` / `optimistic()`) are **not in this revision
of `NEXTJS-DOCS.md`**. They are specified from upstream React, and the example files cite
<https://react.dev/reference/react-dom/hooks/useFormStatus> and
<https://react.dev/reference/react/useOptimistic> rather than a section number. The rest of this
front — the form binding, `actionState`, the returned message, the GET `<Form>` — is `§ 10`, `§ 14`
and `§ 25` and is cited as such.

`NEXTJS-DOCS.md § 10` *Segurança* states the CSRF `Origin`/`Host` check and the 1 MB body limit. Both
are enforced on the server by front 24; this front neither implements nor weakens them.

## Naming under the `use` rule

Every hook here follows decisions 118 and 128 (`README.md § 6`,
[`24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/guide.md) § 4): the name
is the noun of what is yielded — `actionState`, `formStatus`, `optimistic` — activated as
`val s = use actionState(id, initial)` inside a `@Component` body and called plainly for the
server-pass value, which is what every `test` here does. The type constructors stay PascalCase
(`ActionState`, `FormStatus`); helpers take a verb (`newActionState`, `parseActionState`,
`applyOptimistic`). A binding never reuses its hook's name (`val s = use actionState(…)`): a local
would shadow the imported function for the rest of the module
(`19-use-activation/surface.md § 4`).

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Tuple labels are lost through generic instantiation, so a hook's multi-value return is read positionally | `actionState` (`s._0`/`s._1`/`s._2`) in `create-post-form-example.bp`; `optimistic-like-example.bp` destructures positionally instead | read by index and bind each element to a named `val` on the next line | preserve the written labels through instantiation |
| No assignment to a `self` field | every optimistic update | return a new record | mutable record fields, or a `with` expression |
| Declared parameter defaults are never applied | every constructor call in the examples spells `attrs:`, and `formAction` has no optional parameter | pass every argument explicitly; a second constructor per default | apply the declared default at the call site |
| A closure stored in a record field cannot be replaced after construction, so `push` must be handed out by the hook rather than rebound | `optimistic`'s `#(T, fn(action: T) -> i32)` | the host cell holds the action list and the closure reads it | see the `self`-field gap — the same fix covers it |

## Test plan

`modules/jhonstart-forms/test/form_test.bp`, run by `botopink test` in the member on both rows and by
`zig build test-libs`. The envelope and the `state` grammar are tested in `libs/actions`
(`01-std/05-actions-lib`), on both targets; this front asserts the boundary either side of the cells
— the string handed to `__jhFormSubmit` / `__jhFormInvoke` (through the recording erlang twin and
`lastFormCall`) and the `ActionState` decoded from what it returns (`stubResponse`) — plus the
attributes and the hooks' server-pass values. The submit interception itself is covered by front
53's example app, the first place a real browser is in the loop.

The progressive-enhancement claim is a *markup* assertion: a rendered form carries `method="post"`,
the current pathname in `action`, and the hidden field named by the `actionField` passed in
(`__bp_action` in the test), asserted as an exact string.

## Definition of done

- [x] `src/form.bp` exists and `botopink build` succeeds; there is no `form_state.bp` —
      `modules/jhonstart-forms/src/form.bp`
- [x] `ActionState`, `parseActionState` and the RPC body come from `"actions"` (decision 116); the
      `state` literal is asserted in `libs/actions` only
- [x] `invokeAction` is the one writer of the JSON-RPC body in the browser
- [ ] Every element constructor the examples call (`form`, `input`, `button`, `label`) is imported
      from `jhonstart` and marked `// provided by front 94`; this front's source defines none, and
      `element.bp` is unmodified
- [x] `formStatus` and `optimistic` are marked in `repository/jhonstart/docs.md` as specified
      from upstream React rather than from `NEXTJS-DOCS.md` — `docs.md` § *Forms*
- [ ] Every `// LANGUAGE GAP:` marker in the three example files appears in the table above
- [x] The front's tests are green on its assigned target — `commonJS` — and on erlang
