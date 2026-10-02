# Front 123 — bpp middleware: `locals`, `sequence`, and a response read after `next`

**Priority:** medium — the middleware itself exists; `locals` is the one member of the reference's
context that has no equivalent, and it is what authentication examples are written with.
**Depends on:** `04-rakun/04-rakun-erlang-runtime` landed (the core and its per-request frame —
`locals.bp` is a new file in its member) · `04-rakun/65-rakun-url-rules` landed (it owns
`rakun-web`; this front runs after it — decision 189) · decision 186 for what a `local` read
does to the page's stage (it answers `49-f`).
**Owns:** new `repository/rakun/modules/rakun/src/locals.bp` · the lines of
`rakun/modules/rakun-web/src/{middleware.bp, filter.bp}` named in the steps · their tests
**Does not touch:** `rakun-app` (`actions.bp` is `04-rakun/22`'s — step 4 reads from it and adds
nothing); jhonstart; onze.

Reference: `astro-docs/17-middleware.md`, `25-actions.md` § Controlando Actions do Middleware.

---

## Problem

rakun-web has middleware: `middleware.bp` at the root of the app, `#[middleware]` with a
`#[matcher("/dashboard/:path*")]`, and `Next.pass`, `Next.redirect`, `Next.permanentRedirect`,
`Next.rewrite` (`rakun-web/src/middleware.bp:41-83`); under it, an ordered filter chain with
bands (`filter.bp:162-173`, `:319`). None of that is this front's to build.

Four things in the reference have no counterpart:

| Astro | Today |
|---|---|
| `context.locals` — data set by middleware, read by pages and endpoints | not found in any repository |
| `sequence(a, b, c)` | the chain is ordered by registration and band; there is no value that *is* three middleware in order |
| `const response = await next(); … response.text()` — read and replace the body | `Response` is a frozen record and a page response is a stream |
| `getActionContext(context)` — is this request an action, and how was it called | not found |

## Current state

Measured 2026-10-01:

- `#[middleware]`, `#[matcher]`, `#[filter]`, `#[order]`, `#[crossOrigin]`, `#[controllerAdvice]`
  live in `rakun-web/src/convention.bp` (`rakun/AGENTS.md:197-200`).
- A reply header is set through a per-request accumulator (`rkSetReplyHeader`), "because the
  frozen `Response` record has no header field of its own"
  (`07-onze/53/examples/middleware-example.bp:35-37`).
- Per-request state lives in the serving process's dictionary — the frame of 1.0.10's front 62
  (`language-gaps.md`, the "No assignment to a `self` field" row).
- Whether middleware runs for a 404 and before a 500 page is not measured.

## Mechanism

**A local is typed by its key.** Astro's `locals` is a bag typed by a global declaration
(`App.Locals` in `env.d.ts`). Here the key carries the type:

```bp
pub type LocalKey<T>(name: string)

pub fn setLocal<T>(key: LocalKey<T>, value: T) -> i32          // middleware, handlers, actions
pub fn local<T>(key: LocalKey<T>) -> ?T                        // anywhere in the same request
```

An application declares its keys once (`pub fn currentUser() -> LocalKey<User>`), so a read is
typed without a cast and a key nobody set is `null`. The values live in the request's process
frame and die with it. Two keys with one name and two types are refused at the second `setLocal`
of the request, naming both — the one place a host table could hand back the wrong type.

Reading a local from a page makes it a per-request page: a page whose output depends on what
middleware decided per request is not a prerendered page. Under decision 186 that is a
compile-time fact — a request-time read is what `#[serverOnly]` marks — and until the checker
capability lands the read marks the render through the bridge `04-rakun/22` step 4 leaves
(`ChunkWriter.markDynamic`). How `local`, a rakun function, carries a marker jhonstart defines
is not stated by the decision; step 1's third box (`dynamicReason()` says `locals`) is written
for the bridge.

**`sequence` is a value.** `sequence([validation, auth, greeting])` answers one middleware that
runs the three in order, each seeing the next one's response on the way back — the onion of the
reference. It composes functions and does not touch the registration order of the filter chain.

**The response after `next`.** `chain.next(req)` keeps answering the response as it streams.
`chain.nextBuffered(req)` answers `Buffered(status, headers, body)` after the page has finished —
it turns streaming off for that request — and `Buffered.replaceBody(text)` answers the response to
send. Buffering is asked for by name, per middleware; nothing buffers by default.

**`actionContext(req)`** answers `?ActionCall(name, calledFrom: CalledFrom)` with
`CalledFrom { Rpc, Form }`, read from the action field and header onze configures
(decision 114) — so a gate can treat a scripted call and a form post differently.

## Steps

### Step 0 — Measure

- [ ] a request to a path with no route, and a page that fails: does `#[middleware]` run, and in
      which order relative to the not-found and error boundaries
- [ ] two concurrent requests: a value set in one request's frame is not visible in the other
      (the shape `bindingIsolated()` measures in `libs/validation/src/binding.bp:79-81`)

### Step 1 — `locals`

- [ ] `examples/locals-and-sequence-example.bp` passes on erlang
- [ ] a local set in middleware is read by a page, a route handler and an action in the same
      request, and is `null` in the next request on the same process
- [ ] a page that reads a local is not prerendered, and `dynamicReason()` says `locals`

### Step 2 — `sequence`

- [ ] the reference's three-middleware example logs `validation request`, `auth request`,
      `greeting request`, `greeting response`, `auth response`, `validation response`
- [ ] a middleware that answers without calling `next` stops the ones after it

### Step 3 — `nextBuffered`

- [ ] the reference's redaction example: every `PRIVATE INFO` in a page's markup is replaced, and
      the response's headers are the page's
- [ ] the same request through `chain.next` is still streamed — asserted on the chunk count

### Step 4 — `actionContext`, and middleware around 404 and 500

- [ ] `actionContext` distinguishes an RPC call from a form post of the same action
- [ ] step 0's measurement becomes two tests; if middleware does not run for a 404 today, it does
      after this step

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun` and `modules/rakun-web`
- [ ] `zig build test-libs`: rakun, onze green; the blog's dashboard gate unchanged
- [ ] `scripts/gate.sh --cold` green
- [ ] `AGENTS.md` of every directory touched
- [ ] Commit on `front/123-bpp-middleware`; landing is the maintainer's step

## Blast radius

- **A new per-request table** in the frame. It is cleared where the frame is; step 0's second
  measurement is the regression test for a leak between requests.
- **`nextBuffered` holds a whole page in memory.** It is opt-in and per middleware; the README of
  the member says so where it documents it.
- **Nothing existing changes shape**: `Next`, `Chain` and the decorators are as they are.

## Notes

- **Not added.** `context.rewrite` and `next(request)` — `Next.rewrite` is the form.
  `defineMiddleware` — a function's signature is its type. `App.Locals` in `env.d.ts` —
  `LocalKey<T>`.
- **jhonstart does not learn about locals.** A page imports `local` from rakun, like any
  server-only function; the client graph refuses the import (`onze-bundler/src/refusal.bp:55-138`).
