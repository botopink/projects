# Front 127 — bpp actions: an action typed by its `#[validated]` types

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s0 → 150 s23 · s1 → 150 s23 · s2 → 150 s23 · s3 → 150 s23 · s4 → 150 s23 · s5 → 150 s23 · s6 → 150 s23. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — actions run; they lack what the reference leads with: framework-validated,
typed input. · **State:** not started
**Depends on:** `03-bundled-libs/125-validation-zod` step 6 (`bind<T>`, against decision 183; steps
0–2 merged into botopink-lang `feat`) and step 12 (`#[schema]` merged into `#[validated]`, 306; step 5) · `03-bundled-libs/103-actions-id` (owns
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

An action described once by its input and output types (`#[validated]`, 306), implemented once on the server, validated and typed —
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
`formStatus`, `optimistic`), 125's `parse<T>` (emitted by `#[schema]` today; a member of the
`#[validated]` type after 306) and, after its step 6, `bind<T>`.

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

**Described once, in a module both targets compile** — today's form below: a value, name + two
schemas. Step 5 replaces it (281, 306): the types are `#[validated]` only (no `#[schema]`, no
`Schema<T>`, no `schemaOf…()`), `actionRef("…", schemaOf…, schemaOf…)` gives way to the function
value, and `#[action]` takes no string — input and output come from the signature (280 (2)).

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

Input type named in the argument because a function `@Decl` has no parameter list; dropped in step
5, where the wrapper reads input and output from the signature (280 (2)). The wrapper's `bind…` /
`parse…` / `encode…` become the `#[validated]` types' own members (306; `T.parse` / `T.encode`, 327).

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
val session = use cookieValue(sessionCookie);       // declared once, typed (294)
if (session == null) { throw Unauthorized("User must be logged in."); }
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
component encodes with the input type, posts the RPC body to the payload's id for that name,
decodes with the output type (their `#[validated]` members, 306). Forms: `formAction(addCommentAction())`; after a no-script post the
page reads `actionResult(addCommentAction())`. The client imports the description module, never
the server-only implementation (refused by `onze-bundler/src/refusal.bp:55-138`).

## Blast radius

- **Nothing existing changes.** `#[serverAction]` over `FormData` stays; `#[action]` beside it, same registration door.
- **`libs/actions` is bundled**: outcome types reach every consumer via a rebuilt compiler, both targets.
- **The blog's `createPost`** (`onze/examples/blog`) becomes typed in `07-onze/53`'s tree, by that front, after this lands.

## Notes

- **Not added.** `defineAction` as one object (description and implementation compile for
  different targets). `.orThrow()` — `callAction(…)` answers `@Task<@Result<T, ActionError>>`,
  so `try` works on it directly (303). Nested action objects (`actions.user.getUser`) — the module path.
- **File inputs.** No `z.instanceof(File)` until 346's `Bytes` is built (`01-checker` step 32); rakun answers multipart with 415.
- **Security.** Id unguessable, name not secret; authorisation in the function (`ctx`) or middleware.
