# Front 122 — bpp data: the `Astro` global, mapped

**Priority:** medium — most of the global exists under other names; three members do not exist
at all. · **State:** not started
**Depends on:** `05-jhonstart/26` (the core member) · `07-onze/49` (ONZ-49-4.3: onze fills
`RequestData.query` and `.headers` with `[]` today) · `03-bundled-libs/102` (`navigation.bp`) ·
120 (before it on the core member's `botopink.json` and `root.bp`) · `118-bpp-components` for the
examples.
**Owns:** in `repository/jhonstart/modules/jhonstart/src`: the lines of `server.bp` and
`error_boundary.bp` named in the steps, new `response.bp` (after `05-jhonstart/26`, and after 120
on the member's `botopink.json` and `root.bp`) · `botopink-lang/libs/routing/src/navigation.bp` —
one signal (after `03-bundled-libs/102`) · `onze/modules/onze/src/config.bp` — the `site` key and
its reader: this front adds it, 124 adds the other four keys (decision 189) · their tests
**Does not touch:** rakun's request context (`rakun/src/request_context.bp`); `onze-server`'s
construction of `RequestData` (49's); middleware (123).

Reference: `astro-docs/18-data-fetching.md`, `21-on-demand-rendering.md`, `08-routing.md`
§ Redirecionamentos, § Rewrites.

## Goal

Every member of Astro's `Astro` global has a counterpart — most already exist as parameters, hooks
and navigation signals — and the three that do not are added: page-side status and headers,
`rewrite` from a page, and `site` / `isPrerendered`.

## Problem

Astro gives a component one object — `Astro` — with the request, the response, the cookies, the
params, the props, the slots and the navigation helpers on it. That object cannot be ported as
it is: `Astro.cookies.set(…)` and `Astro.response.status = 404` are writes to a global with
fields, in a language where a record is immutable (`docs.md:358`) and a page already receives
what it needs as a parameter and as hooks.

The stack does not need the object. It needs the three things the object can do that nothing here
can.

## The whole global, member by member

Paths under `repository/`.

| `Astro.…` | Here | Where |
|---|---|---|
| `props` | the component's props parameter | 118 |
| `params` | `<fn>Params(route)`, emitted by `#[page]` | `jhonstart/src/routes.bp:233-262` |
| `slots.has` / `slots.render`, `self` | `hasContent(slot)`; the function's own name | 118 |
| `request` — `url`, `method`, `headers` | `use request()` → `RequestData(method, path, params, query, headers, cookies)` | `jhonstart/src/server.bp:106`, `:252` — `query` and `headers` arrive empty until `07-onze/49` |
| `cookies.get` / `.has` | `use cookies()`, `pairValue(jar, name)` | `server.bp:270` |
| `cookies.set` / `.delete` | **refused in a render** — a write belongs to a handler, an action or middleware | `rakun/src/request_context.bp:586`, `:752`; the render phase raises |
| `redirect(url, status)` | `redirect(url)` — 303 / 307 / 308 encoded in the signal | `jhonstart/src/error_boundary.bp:187`, `libs/routing` `navigation` |
| a 404 | `notFound()` | `error_boundary.bp:180` |
| `url`, `routePattern` | `route.pathname`, `route.pattern` | `PageContext`, `routes.bp` |
| `locals` | not found | 123 |
| `session` | `Session`, three stores | `rakun-session` |
| `preferredLocale`, `currentLocale` | `negotiate`, the locale filter | `rakun-app/src/i18n.bp` |
| `getActionResult`, `callAction` | `actionState`; a call | `jhonstart-forms/src/form.bp:182`; 127 |
| top-level `await`, `fetch` | `await` in a `@Component` body; `io.http.fetch(url)` — GET only | `docs.md:1592`; `libs/std/src/io/http.bp:55` |
| **`response.status`, `response.headers`** | **not found** — a render answers 200, or a navigation signal | step 1 |
| **`rewrite(path)`** | **not found** from a page; `Next.rewrite` exists in middleware | `rakun-web/src/middleware.bp:41-58` — step 2 |
| **`site`, `generator`, `isPrerendered`** | **not found** | step 3 |

## Mechanism

**Status and headers are hooks that act before the first byte.** A streamed response has sent its
status line when the shell is flushed; so `responseStatus(code)` and `responseHeader(name, value)`
are legal until then and a located error after — the rule `redirect` and `notFound` already follow
when raised late (`05-jhonstart/README.md`, JH-26-6: the late-signal handler). They record into
the render's own state; the server reads it when it writes the head.

```bp
val product = await findProduct(id);
if (product == null) { val _s = responseStatus(404); }
val _h = responseHeader("Cache-Control", "public, max-age=3600");
```

Either is a request-time hook, like any read of the request: under decisions 186 and 202 it is
`#[serverOnly]`, so a page that reaches one is rendered per request, never prerendered.

**A rewrite is a navigation signal.** `rewrite(path)` raises `nav:rewrite:<path>` beside
`nav:redirect` and `nav:not-found` in `libs/routing`'s `navigation`; the server matches `path` and
renders that route in the same response. The browser's address does not change. A rewrite to a
path that itself rewrites is followed at most once more and then refused, naming both.

**`site()` is configuration.** The deploy URL comes from `onze.json` (`site`, 124) through the
render's `app(…)` options, so jhonstart reads a value and names no config file.
`isPrerendered()` answers whether this render is a build-time one.

## Open

### Step 0 — Measure

- [ ] what a page receives today for `request().query` and `.headers` in `onze/examples/blog`
      (expected: `[]`, `onze-server/src/server.bp:76-77`)
- [ ] `redirect()` raised after the first chunk: what the response is

### Step 1 — `responseStatus`, `responseHeader`

- [ ] `examples/response-control-example.bp` passes
- [ ] either one called after the shell is written fails with the hook's name and the phase
- [ ] a header set from a `Suspense` fill is refused the same way
- [ ] `dynamicReason()` names `responseStatus` for a page that calls it

### Step 2 — `rewrite`

- [ ] `rewrite("/es/articles/introduction")` from `/es-cu/articles/introduction` answers the
      second route's markup with the first route's URL — asserted through the navigation wire on
      both targets
- [ ] a rewrite cycle is refused, naming both paths

### Step 3 — `site`, `isPrerendered`, `currentUrl`

- [ ] `site()` is `""` when unset and an absolute URL helper — `absoluteUrl(path)` — refuses to
      answer then, rather than emit a relative canonical link
- [ ] `isPrerendered()` is true under `prerenderPath` (`static_gen.bp:381`) and false on a request

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/jhonstart` and `libs/routing`
- [ ] `zig build test-libs`: jhonstart, rakun, onze green
- [ ] `contracts.md` for the new signal

## Blast radius

- **The navigation wire gains a signal.** It is read by rakun, jhonstart's server and jhonstart's
  client (`signalToWire` / `signalFromWire`); the three move together.
- **`RenderHooks` / `app(…)` gains two reads** (the recorded status and headers). `onze-server`
  is the one caller.

## Notes

- **Not added.** The `Astro` object. `Astro.cookies.set` from a render — the phase rule is the
  design; a page that must set a cookie does it in middleware or in the action
  that led to it. `fetch` with a method, headers and a body is `02-std-and-packaging`'s row.
- **Returning a `Response` from a page** is the three signals plus the two hooks; there is no
  fourth thing a page's frontmatter returns.
