# Front 127 — bpp actions: an action typed by a schema

**Priority:** medium — actions run; they lack what the reference leads with: framework-validated,
typed input. · **State:** not started
**Depends on:** `03-bundled-libs/125-validation-zod` step 6 (`bind<T>`, against decision 183; steps
0–2, `Schema<T>`, merged into botopink-lang `feat`) · `03-bundled-libs/103-actions-id` (owns
`libs/actions` this milestone) · `04-rakun/22` (rakun-app), 117 and 120 before it on the member's
`botopink.json`, `root.bp` · `05-jhonstart/67` (jhonstart-forms) · `07-onze/49` (ONZ-49-4.5:
`serveActions` not installed by onze yet) · 126 (`fronts.md`) · 123 for step 4 (`actionContext`) ·
step 3's `jhonstart-dom-test` file is this front's; `fake_dom.mjs` stays `05-jhonstart/26`'s (189).
**Owns:** in `repository/rakun/modules/rakun-app/src`: new `typed_action.bp`; the one registration
line of `actions.bp` it calls · in `repository/botopink-lang/libs/actions/src`: new `outcome.bp` ·
in `repository/jhonstart/modules/jhonstart-forms/src`: new `typed_call.bp` · their tests
**Does not touch:** `#[serverAction]`, the dispatcher, id derivation (`actions.bp:170-260`); the
envelope's existing fields (`libs/actions/src/envelope.bp`); `form.bp`'s hooks.

Reference: `astro-docs/25-actions.md`.

## Goal

An action described once by two schemas, implemented once on the server, validated and typed —
form or JSON input, `@Result<T, ActionError>` on both sides (decision 303), typed client call — beside `#[serverAction]`.

## Problem

Today an action takes the raw form and checks by hand:

```bp
// 07-onze/53-onze-example-app/examples/server-action-example.bp
#[serverAction]
pub fn createPost(form: FormData) -> @Task<ActionResult> {
    val title = form.field("title");
    val tooShort = title.length() < 3;
    if (tooShort) { return ActionResult.invalid("title", "Title must be at least 3 characters"); };
    …
```

String fields, an `if` per rule, messages at the call, untyped `ActionResult` — vs the reference's
"Actions realizam busca de dados, parsing de JSON e validação de input para você" (`input:`
schema, typed `handler`, typed client `data`). The pieces exist unjoined: `libs/actions`
(`ActionState` with per-field errors, `ActionEnvelope`, `RpcCall`), registry and HMAC ids
(`rakun-app/src/actions.bp`), form hooks (`jhonstart-forms/src/form.bp`: `actionState`,
`formStatus`, `optimistic`), 125's `parse<T>` (emitted by `#[schema]`) and, after its step 6, `bind<T>`.

## What exists

| | Where |
|---|---|
| `#[serverAction]` on `fn(form: FormData) -> @Task<ActionResult>` or `-> @Task<@Result<ActionResult, E>>`; emits `val __rkAction_<name> = rkRegisterAction("<name>", <name>);` | `rakun-app/src/actions.bp:170-196` |
| the id — `"a_" + hmacSha256(secret, module + "." + name + ":" + buildId)[0..24]` | `actions.bp:237-243` |
| `fieldName()`, `headerName()`, `bodyLimit()` from `rakun.actions.*`, set by the orchestrator | `actions.bp:199-234` |
| `ActionState(ok, message, redirectTo, fields)`, `fieldError(name)` | `libs/actions/src/state.bp:14-26` |
| `ActionEnvelope`, `writeEnvelope`, `readEnvelope` | `libs/actions/src/envelope.bp:22-147` |
| `RpcCall(id, args: Array<string>)`, `writeRpcBody`, `parseRpcBody` | `libs/actions/src/rpc.bp:14-81` |
| `formAction`, `actionForm`, `submitForm`, `invokeAction`, `actionState`, `formStatus`, `optimistic` | `jhonstart-forms/src/form.bp:119-228` |
| a decorator on a function sees its return type and not its parameters | `language-gaps.md` — "A method's own `@Decl` has no parameter list" |

## Mechanism

**Described once, in a module both targets compile** — a value: name + two schemas.

```bp
// src/actions/comments_api.bp — both targets
#[schema] #[validated]
pub type NewComment(#[coerce] postId: i32, #[trim] #[minLength(1)] #[maxLength(500)] body: string)

#[schema]
pub type Comment(id: i32, body: string)

pub fn addCommentAction() -> ActionRef<NewComment, Comment> {
    return actionRef("addComment", schemaOfNewComment(), schemaOfComment());
}
```

**Implemented once, on the server.**

```bp
// src/actions/comments.bp — erlang
#[action("NewComment")]
pub fn addComment(input: NewComment, ctx: ActionContext) -> @Task<@Result<Comment, ActionError>> { … }
```

`#[action("NewComment")]` registers a wrapper under the function's name (as `#[serverAction]`
registers the function):

| The request is | The wrapper |
|---|---|
| a form post (`accept: "form"`) | drops the framework's own fields (the action field, a CSRF token), then `bindNewComment(pairs)` |
| a scripted call (`accept: "json"`) | `parseNewComment(args[0])` |
| either, with violations | answers `Error(ActionError.Input(fields))` — violations grouped by path — **without calling the function** |
| valid | calls the function, encodes `Ok(v)` with `encodeComment` as `{data}`, or `Error(e)` as `{error}` with its case's status and message |

Input type named in the argument because a function `@Decl` has no parameter list; dropped once it
gains one (wrapper reads the parameter).

**One outcome type, both sides: the language's `@Result` (decision 303).** No `ActionOutcome` — the
server function returns `@Result<T, ActionError>` and the caller receives the same `@Result<T, ActionError>`.
Exactly one of a value and an error exists, the `case` is exhaustive, nothing needs `!!`.

```bp
pub type ActionError {
    Input(fields: Dict<string, Array<string>>),   // isInputError(error) / error.fields — written by the wrapper
    BadRequest(message: string),
    Unauthorized(message: string),
    Forbidden(message: string),
    NotFound(message: string),
    Conflict(message: string),
    TooManyRequests(message: string),
    Internal(message: string),
}

// the function — `return v` is `Ok(v)`; `throw e` is an `Error(e)` value, not a raise (118)
if (ctx.cookie("user-session") == "") { throw Unauthorized("User must be logged in."); }
return Subscribed(email: input.email);

// the caller — the reference's `if (error) … else data`
case (await callAction(newsletterAction(), input)) {
    Ok(s) -> show(s);
    Error(Input(fields)) -> markFields(fields);
    Error(Unauthorized(_)) -> goToLogin();
    Error(e) -> warn(e);
}
```

Each case is an HTTP status in the envelope. The envelope's JSON stays the reference's — `{"data": …}`
or `{"error": {"code", "message", "fields"}}` — as protocol only; bp code on either side sees the `@Result`.

**Client calls through the reference.** `callAction(addCommentAction(), input)` in a `#[client]`
component encodes with the input schema, posts the RPC body to the payload's id for that name,
decodes with the output schema. Forms: `formAction(addCommentAction())`; after a no-script post the
page reads `actionResult(addCommentAction())`. The client imports the description module, never
the server-only implementation (refused by `onze-bundler/src/refusal.bp:55-138`).

## Open

### Step 0 — Measure

- [ ] how the browser learns an action's id — payload `a` key (`jhonstart/src/render.bp:479-523`)
      or hand-threaded (`07-onze/53/examples/new-post-form-example.bp:45`: `val createPostId = "a_9f31…"`)
- [ ] what a form post carries besides user fields, by name — the list `bind<T>` must not see

### Step 1 — `ActionError` and the envelope's typed payload (decision 303)

- [ ] `libs/actions/src/outcome.bp`, both targets: `ActionError` (the sum type above) and the `@Result<T, ActionError>` ↔ `{data}` / `{error}` codec; no `ActionOutcome`, no `ActionErrorCode`; it travels in the envelope's existing `payload` field, no reader changes
- [ ] an `Error(Input(fields))` written and read back keeps every path and message; each other case keeps its status and message
- [ ] a payload with both `data` and `error`, or neither, is refused by the reader (never decoded into a `@Result`)

### Step 2 — `#[action]` and the wrapper

- [ ] `examples/typed-action-example.bp` passes on erlang
- [ ] invalid input never reaches the function — asserted with a counter the function bumps
- [ ] `#[action]` on a function not returning `@Task<@Result<T, ActionError>>`, or naming a type
      with no `bind<T>` / `parse<T>` in scope, fails at the annotation
- [ ] the function answers with `return v` / `throw e`; `throw Input(…)` from the function itself is allowed (a check only the server can make, e.g. a taken e-mail)

### Step 3 — The client call and the form binding

- [ ] `callAction` over `jhonstart-dom-test`'s fake transport answers `@Task<@Result<T, ActionError>>`: `Ok`, `Error(Input)` and each other `Error` case decode to their variant
- [ ] a form bound with `formAction(ref)` submits without JavaScript; the next render's `actionResult(ref)` holds the outcome — `?@Result<T, ActionError>`, `null` until posted
- [ ] `fieldError(name)` (`libs/actions/src/state.bp:21`) answers the path's first message, so
      existing form components work over a typed action

### Step 4 — `actionContext` for middleware

- [ ] 123's `actionContext(req)` names a typed action and how it was called

### Step 5 — references, not strings (decision 281)

- [ ] `#[action]` without a string: input and output from the signature (280 (2)); `actionRef("…",
      schemaOf…, schemaOf…)` replaced by the function value; the wire id derived at comptime

### Step 6 — a cookie is declared once, typed (decision 294)

- [ ] an action sets or clears a cookie through hooks over its declaration (`use setCookie(decl)` → a
      setter, `use clearCookie(decl)`; 295), the attributes from the declaration; actions return
      `@Component<RequestBase, …>` so they may `use`

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `libs/actions` and `jhonstart-forms`; on erlang in `rakun-app`
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `#[serverAction]`'s tests unchanged

## Blast radius

- **Nothing existing changes.** `#[serverAction]` over `FormData` stays; `#[action]` beside it, same registration door.
- **`libs/actions` is bundled**: outcome types reach every consumer via a rebuilt compiler, both targets.
- **The blog's `createPost`** (`onze/examples/blog`) becomes typed in `07-onze/53`'s tree, by that front, after this lands.

## Notes

- **Not added.** `defineAction` as one object (description and implementation compile for
  different targets). `.orThrow()` — `callAction(…)` answers `@Task<@Result<T, ActionError>>`,
  so `try` works on it directly (303). Nested action objects (`actions.user.getUser`) — the module path.
- **File inputs.** No `z.instanceof(File)`: no byte type (lg2-a); rakun answers multipart with 415.
- **Security.** Id unguessable, name not secret; authorisation in the function (`ctx`) or middleware.
