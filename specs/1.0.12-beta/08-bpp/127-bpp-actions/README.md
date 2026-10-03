# Front 127 — bpp actions: an action typed by a schema

**Priority:** medium — actions exist and run; what they lack is the part the reference leads
with: an input the framework validates and types. · **State:** not started
**Depends on:** `03-bundled-libs/125-validation-zod` step 6 (`bind<T>`, written against decision
183; steps 0–2, `Schema<T>`, are merged into botopink-lang `feat`) ·
`03-bundled-libs/103-actions-id` (it owns `libs/actions` in this milestone) · `04-rakun/22`
(rakun-app), and 117 and 120 before it on that member's `botopink.json` and `root.bp` ·
`05-jhonstart/67` (jhonstart-forms) · `07-onze/49` (ONZ-49-4.5: `serveActions` is not
installed by onze yet) · 126 (`fronts.md`) · 123 for step 4 (`actionContext`) · the test file step 3 adds to
`jhonstart-dom-test` is this front's own; `fake_dom.mjs` stays `05-jhonstart/26`'s (decision 189).
**Owns:** in `repository/rakun/modules/rakun-app/src`: new `typed_action.bp`; the one registration
line of `actions.bp` it calls · in `repository/botopink-lang/libs/actions/src`: new `outcome.bp` ·
in `repository/jhonstart/modules/jhonstart-forms/src`: new `typed_call.bp` · their tests
**Does not touch:** `#[serverAction]`, the dispatcher, the id derivation (`actions.bp:170-260`);
the envelope's existing fields (`libs/actions/src/envelope.bp`); `form.bp`'s hooks.

Reference: `astro-docs/25-actions.md`.

## Goal

An action is described once by two schemas, implemented once on the server, validated and typed
for its author — form or JSON input, an `ActionOutcome` on both sides, a typed client call — beside
the existing `#[serverAction]`.

## Problem

An action today takes the raw form and checks it by hand:

```bp
// 07-onze/53-onze-example-app/examples/server-action-example.bp
#[serverAction]
pub fn createPost(form: FormData) -> @Task<ActionResult> {
    val title = form.field("title");
    val tooShort = title.length() < 3;
    if (tooShort) { return ActionResult.invalid("title", "Title must be at least 3 characters"); };
    …
```

Every field is read as a string, every rule is an `if`, every message is spelled at the call, and
what the action answers is an untyped `ActionResult`. The reference's first sentence about
actions is the opposite: "Actions realizam busca de dados, parsing de JSON e validação de input
para você" — an `input:` schema, a typed `handler`, a typed `data` on the client.

The pieces for that exist separately and nothing joins them: the action protocol
(`libs/actions`: `ActionState` with per-field errors, `ActionEnvelope`, `RpcCall`), the action
registry and HMAC ids (`rakun-app/src/actions.bp`), the form hooks (`jhonstart-forms/src/form.bp`:
`actionState`, `formStatus`, `optimistic`), and 125's `parse<T>` (the `#[schema]` decorator emits
it) and — after its step 6 — `bind<T>`.

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

**An action is described once, in a module both targets compile.** The description is a value:
its name and the two schemas.

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

**It is implemented once, on the server.**

```bp
// src/actions/comments.bp — erlang
#[action("NewComment")]
pub fn addComment(input: NewComment, ctx: ActionContext) -> @Task<@Result<Comment, ActionError>> { … }
```

`#[action("NewComment")]` registers a wrapper under the function's name, the way
`#[serverAction]` registers the function itself. The wrapper is where the reference's "for you"
happens:

| The request is | The wrapper |
|---|---|
| a form post (`accept: "form"`) | drops the framework's own fields (the action field, a CSRF token), then `bindNewComment(pairs)` |
| a scripted call (`accept: "json"`) | `parseNewComment(args[0])` |
| either, with violations | answers `ActionOutcome.InputError` — the report's violations grouped by path — **without calling the function** |
| valid | calls the function, and encodes `Ok(v)` with `encodeComment` or `Error(e)` as its code and message |

The input type is named in the decorator's argument because a function-level `@Decl` has no
parameter list; when it gains one the argument is dropped and the wrapper reads the parameter.

**One outcome type, on both sides.**

```bp
pub type ActionOutcome<T> {
    Data(value: T),
    InputError(fields: Dict<string, Array<string>>),      // isInputError(error) / error.fields
    Failed(error: ActionError),
}
pub type ActionError(code: ActionErrorCode, message: string)
pub type ActionErrorCode { BadRequest, Unauthorized, Forbidden, NotFound, Conflict, TooManyRequests, Internal }
```

Each code is an HTTP status in the envelope, and `ActionOutcome` is read with `case` — the
`if (error) … else data` of the reference, exhaustive.

**The client calls through the reference.** `callAction(addCommentAction(), input)` in a
`#[client]` component encodes with the input schema, posts the RPC body to the id the payload
carries for that name, and decodes the answer with the output schema. A form is bound with
`formAction(addCommentAction())`; after a no-script post, the page reads
`actionResult(addCommentAction())`.

The client imports the description module, never the implementation: the implementation is
server-only code, and the bundler already refuses it in the client graph
(`onze-bundler/src/refusal.bp:55-138`).

## Open

### Step 0 — Measure

- [ ] how the browser learns an action's id today — the payload's `a` key
      (`jhonstart/src/render.bp:479-523`) or a value threaded by hand
      (`07-onze/53/examples/new-post-form-example.bp:45`: `val createPostId = "a_9f31…"`)
- [ ] what a form post carries besides the user's fields, by name — the list `bind<T>` must not
      see

### Step 1 — `ActionOutcome`, `ActionError`, the envelope's typed payload

- [ ] `libs/actions/src/outcome.bp`, both targets; the outcome travels in the envelope's existing
      `payload` field, so no reader of the envelope changes
- [ ] an `InputError` written and read back keeps every path and message

### Step 2 — `#[action]` and the wrapper

- [ ] `examples/typed-action-example.bp` passes on erlang
- [ ] an invalid input never reaches the function — asserted with a counter the function bumps
- [ ] `#[action]` on a function whose return is not `@Task<@Result<T, ActionError>>`, or naming a
      type with no `bind<T>` / `parse<T>` in scope, fails at the annotation

### Step 3 — The client call and the form binding

- [ ] `callAction` over the fake transport of `jhonstart-dom-test`: a `Data`, an `InputError` and
      a `Failed` each decode to their variant
- [ ] a form bound with `formAction(ref)` submits without JavaScript and the next render's
      `actionResult(ref)` holds the outcome
- [ ] `fieldError(name)` (`libs/actions/src/state.bp:21`) answers the first message of that path,
      so every existing form component keeps working over a typed action

### Step 4 — `actionContext` for middleware

- [ ] 123's `actionContext(req)` names a typed action and how it was called

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `libs/actions` and `jhonstart-forms`; on erlang in
      `rakun-app`
- [ ] `zig build test-libs`: rakun, jhonstart, onze green; `#[serverAction]`'s tests unchanged

## Blast radius

- **Nothing that exists changes.** `#[serverAction]` over `FormData` stays, for an action that
  wants the raw form; `#[action]` is beside it and registers through the same door.
- **`libs/actions` is bundled**: the outcome types reach every consumer through a rebuilt
  compiler, on both targets.
- **The blog's `createPost`** (`onze/examples/blog`) becomes a typed action in `07-onze/53`'s
  tree, by that front, once this one lands.

## Notes

- **Not added.** `defineAction` as one object holding handler and schema — the description and
  the implementation are two modules because they compile for different targets.
  `.orThrow()` — `try` over a `@Result` is the language's form; `callAction(…)` answers a
  `@Task<ActionOutcome<T>>`, and `outcome.orError()` turns it into a `@Result` for `try`.
  Nested action objects (`actions.user.getUser`) — the module path.
- **File inputs.** `z.instanceof(File)` has no counterpart: there is no byte type
  (`language-gaps.md` lg2-a), and rakun answers a multipart body with 415.
- **Security.** An action's id is unguessable and its name is not secret; authorisation belongs
  in the function (`ctx`) or in middleware, as the reference says of its own.
