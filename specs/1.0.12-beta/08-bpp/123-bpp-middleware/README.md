# Front 123 — bpp middleware: `locals`, `sequence`, and a response read after `next`

**Priority:** medium — middleware exists; `locals` is the one context member with no equivalent,
and authentication examples use it. · **State:** not started
**Depends on:** `04-rakun/04-rakun-erlang-runtime` (core, per-request frame) · `04-rakun/65-rakun-url-rules`
(owns `rakun-web`; this runs after it — 189) · `09-cardume/136` step 7 (`rakun-cardume`, the request
store locals live in — 295, 296). Written against decision 186.
**Owns:** ~~new `repository/rakun/modules/rakun/src/locals.bp`~~ — the request store is
`rakun-cardume`'s (296, `09-cardume/136`) · step-named lines of
`rakun/modules/rakun-web/src/{middleware.bp, filter.bp}` · their tests
**Does not touch:** `rakun-app` (`actions.bp` is `04-rakun/22`'s — step 4 reads, adds nothing); jhonstart; onze.

Reference: `astro-docs/17-middleware.md`, `25-actions.md` § Controlando Actions do Middleware.

## Goal

Middleware hands typed per-request data to pages, handlers, actions (`locals`), composes as a value
(`sequence`), reads/replaces a finished response (`nextBuffered`), tells how an action was called
(`actionContext`); whether it runs around 404 and 500 is stated and tested.

## Problem

Existing, not this front's: `middleware.bp` at the app root, `#[middleware]` with
`#[matcher("/dashboard/:path*")]`, `Next.pass`, `Next.redirect`, `Next.permanentRedirect`,
`Next.rewrite` (`rakun-web/src/middleware.bp:41-83`); an ordered filter chain with bands
(`filter.bp:162-173`, `:319`). Missing:

| Astro | Today |
|---|---|
| `context.locals` — data set by middleware, read by pages and endpoints | not found in any repository |
| `sequence(a, b, c)` | chain ordered by registration and band; no value that *is* three middleware in order |
| `const response = await next(); … response.text()` — read and replace the body | `Response` is a frozen record; a page response is a stream |
| `getActionContext(context)` — is this request an action, and how was it called | not found |

## What exists

- `#[middleware]`, `#[matcher]`, `#[filter]`, `#[order]`, `#[crossOrigin]`, `#[controllerAdvice]`
  in `rakun-web/src/convention.bp` (`rakun/AGENTS.md:197-200`).
- Reply headers via a per-request accumulator (`rkSetReplyHeader`), "because the frozen `Response`
  record has no header field of its own" (`07-onze/53/examples/middleware-example.bp:35-37`).
- Per-request state in the serving process's dictionary — the request frame (`language-gaps.md`,
  "No assignment to a `self` field" row).
- Middleware for a 404 / before a 500 page: not measured.

## Mechanism

**A local is an atom** (295, Recoil's shape with `use`): declared once, its identity the
declaration — no string key — any `T`:

```bp
pub val currentUser = atom<?User>(null);     // cardume's atom (296); rakun-cardume holds the request's store

// middleware — a hook context: `-> @Component<RequestBase, Response>`
val setUser = use setLocal(currentUser);      // fn(User)
setUser(u);

// page, component, handler, action
val user = use local(currentUser);            // ?User — null when nobody set it this request
```

Values live in the request's process frame, die with it. Middleware, route handlers and actions
return `@Component<RequestBase, Response>` (128) so they may `use`; rakun's hooks (`setLocal`,
`cookie`, `setCookie`) anchor at `RequestBase`, jhonstart's (`local`, `cookie`) at `ElementBase`, over
the same atoms. `LocalKey<T>(name)` and its run-time name clash go.

A page reading a local is per-request (a request-time read is what `#[serverOnly]` marks, 186);
until the checker capability lands, the read marks the render through `04-rakun/22` step 4's
bridge (`ChunkWriter.markDynamic`). The page reads through jhonstart's own hook (`use local(atom)` —
cardume's `atomValue`, 296), which jhonstart marks with its `#[serverOnly]` (277, 295); rakun and
jhonstart import neither the other (113). Step 1's third box is written for the final form — the
kind `#[page]` records (277) —, with the bridge's `dynamicReason()` accepted only while `04-rakun/22`
step 4's bridge stands.

**`sequence` is a value.** `sequence([validation, auth, greeting])` = one middleware running the
three in order, each seeing the next one's response on the way back (the onion); composes
functions, leaves the filter chain's registration order alone.

**After `next`.** `chain.next(req)` answers the streaming response. `chain.nextBuffered(req)`
answers `Buffered(status, headers, body)` after the page finishes (streaming off for that request);
`Buffered.replaceBody(text)` answers the response to send. Opt-in per middleware; nothing buffers by default.

**`actionContext(req)`** → `?ActionCall(name, calledFrom: CalledFrom)`, `CalledFrom { Rpc, Form }`,
from the action field and header onze configures (114).

## Open

### Step 0 — Measure

- [ ] request to a path with no route, and a failing page: does `#[middleware]` run, in what order vs the not-found and error boundaries
- [ ] two concurrent requests: a value set in one frame invisible in the other (shape of
      `bindingIsolated()`, `libs/validation/src/binding.bp:79-81`)

### Step 1 — `locals`

- [ ] `examples/locals-and-sequence-example.bp` passes on erlang
- [ ] a local set in middleware is read by a page, a route handler and an action in the same
      request; `null` in the next request on the same process
- [ ] a page reading a local is not prerendered: its kind is `D`, its `why` says `locals`
      (`@typeInfo(Page).meta(PageMeta)`, 277; jhonstart's hook carries `#[serverOnly]`, 295)

### Step 2 — `sequence`

- [ ] the reference's three-middleware example logs `validation request`, `auth request`,
      `greeting request`, `greeting response`, `auth response`, `validation response`
- [ ] a middleware answering without `next` stops the later ones

### Step 3 — `nextBuffered`

- [ ] the reference's redaction example: every `PRIVATE INFO` in the markup replaced; headers are the page's
- [ ] the same request through `chain.next` still streams — asserted on the chunk count

### Step 4 — `actionContext`, and middleware around 404 and 500

- [ ] `actionContext` distinguishes an RPC call from a form post of the same action
- [ ] step 0's measurement becomes two tests; if middleware skips a 404 today, it runs after this step

### Step 5 — route parameters and page data are hooks (decision 293)

- [ ] `locals-and-sequence-example.bp`: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

### Step 6 — a cookie is declared once, typed (decision 294)

- [ ] middleware writes and clears through hooks over the declaration: `val setSession = use
      setCookie(sessionCookie); setSession(SessionId(value: t))`, `use clearCookie(sessionCookie)` (295;
      rakun's response, `http`'s `cookie.write`); the example's login middleware rewritten

### Step 7 — locals are atoms (decision 295)

- [ ] cardume's `Atom<T>` (296) through `rakun-cardume` (`09-cardume/136` step 7): rakun's `use setLocal(atom) -> fn(T)` and jhonstart's `use local(atom) -> ?T` (names: `atm-a`);
      `LocalKey`, `setLocal(key, value)`, `local(key)` gone
- [ ] `#[middleware]` functions, route handlers and actions return `@Component<RequestBase, Response>`
      (`rakun-web/src/middleware.bp`, `convention.bp`); a plain `-> Response` keeps working without `use`
- [ ] two atoms of one `T` are distinct; an unset atom reads `null`; values die with the request
- [ ] `examples/locals-and-sequence-example.bp` and `examples/src/app/orders/page.bpp` rewritten to atoms (the page reads `use local(currentUser)` through jhonstart's hook, never `import {local} from "rakun"` — 113, 295)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test --target erlang` green in `modules/rakun` and `modules/rakun-web`
- [ ] `zig build test-libs`: rakun, onze green; the blog's dashboard gate unchanged

## Blast radius

- **New per-request table** in the frame, cleared with it; step 0's second measurement is the leak regression test.
- **`nextBuffered` holds a whole page in memory**; opt-in, per middleware; the member README says so where documented.
- **Nothing existing changes shape**: `Next`, `Chain`, decorators as they are.

## Notes

- **Not added.** `context.rewrite`, `next(request)` — `Next.rewrite`. `defineMiddleware` — the
  signature is the type. `App.Locals` in `env.d.ts` — an atom declaration (295; `LocalKey<T>` goes).
- **jhonstart and rakun import neither the other** (113). The per-request store is
  `rakun-cardume`'s (296); a page reads through jhonstart's own hook (`use local(atom)` / cardume's
  `atomValue`), marked by jhonstart's `#[serverOnly]` (277, 295); a `#[client]` reaching it is
  refused (277; today `onze-bundler/src/refusal.bp:55-138`).
