# Front 123 — bpp middleware: `locals`, `sequence`, and a response read after `next`

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s0 → 150 s22 · s1 → 150 s22 · s2 → 150 s22 · s3 → 150 s22 · s4 → 150 s22 · s5 → 150 s22 · s6 → 150 s22 · s7 → 150 s22. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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

// middleware — a hook context: `-> @Component<Response>` (354)
val setUser = use atomSetter(currentUser);    // fn(User) — cardume's hook (296)
setUser(u);

// page, component, handler, action
val user = use local(currentUser);            // ?User — null when nobody set it this request
```

Values live in the request's process frame, die with it. Middleware, route handlers and actions
return `@Component<Response>` (354) so they may `use`; the request is the root context
`RequestContext`, provided by rakun's pipeline (354); rakun's hooks (`atomSetter`, `cookie`,
`cookieSetter`) and jhonstart's (`local`, `cookie`) act over the same atoms. `LocalKey<T>(name)` and its run-time name clash go.

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
