# Front 122 — bpp data: the `Astro` global, mapped

**Priority:** medium — most of the global exists under other names; three members do not. · **State:** not started
**Depends on:** `05-jhonstart/26` (core) · `07-onze/49` (ONZ-49-4.3: onze fills
`RequestData.query`, `.headers` with `[]`) · `03-bundled-libs/102` (`navigation.bp`) · 120 (before
it on the core's `botopink.json`, `root.bp`) · `118-bpp-components` for the examples.
**Owns:** in `repository/jhonstart/modules/jhonstart/src`: step-named lines of `server.bp` and
`error_boundary.bp`, new `response.bp` (after `05-jhonstart/26`, after 120 on the member's
`botopink.json`, `root.bp`) · `botopink-lang/libs/routing/src/navigation.bp` — one signal (after
`03-bundled-libs/102`) · `onze/modules/onze/src/config.bp` — `site` key and reader (124 adds the
other four, 189) · their tests
**Does not touch:** rakun's request context (`rakun/src/request_context.bp`); `onze-server`'s `RequestData` construction (49's); middleware (123).

Reference: `astro-docs/18-data-fetching.md`, `21-on-demand-rendering.md`, `08-routing.md`
§ Redirecionamentos, § Rewrites.

## Goal

Every `Astro` member has a counterpart (mostly existing parameters, hooks, navigation signals); the
three missing are added: page-side status and headers, `rewrite` from a page, `site` / `isPrerendered`.

## Problem

`Astro.cookies.set(…)`, `Astro.response.status = 404` write fields of a global; records are
immutable (`docs.md:358`) and a page gets its inputs as a parameter and hooks. The object is not
needed — only its three capabilities nothing here has.

## The whole global, member by member

Paths under `repository/`.

| `Astro.…` | Here | Where |
|---|---|---|
| `props` | the component's props parameter | 118 |
| `params` | `<fn>Params(route)`, emitted by `#[page]` | `jhonstart/src/routes.bp:233-262` |
| `slots.has` / `slots.render`, `self` | `hasContent(slot)`; the function's own name | 118 |
| `request` — `url`, `method`, `headers` | `use request()` → `RequestData(method, path, params, query, headers, cookies)` | `jhonstart/src/server.bp:106`, `:252` — `query`, `headers` empty until `07-onze/49` |
| `cookies.get` / `.has` | `use cookies()`, `pairValue(jar, name)` | `server.bp:270` |
| `cookies.set` / `.delete` | **refused in a render** — writes belong to a handler, action or middleware | `rakun/src/request_context.bp:586`, `:752`; the render phase raises |
| `redirect(url, status)` | `redirect(url)` — 303 / 307 / 308 in the signal | `jhonstart/src/error_boundary.bp:187`, `libs/routing` `navigation` |
| a 404 | `notFound()` | `error_boundary.bp:180` |
| `url`, `routePattern` | `route.pathname`, `route.pattern` | `PageContext`, `routes.bp` |
| `locals` | not found | 123 |
| `session` | `Session`, three stores | `rakun-session` |
| `preferredLocale`, `currentLocale` | `negotiate`, the locale filter | `rakun-app/src/i18n.bp` |
| `getActionResult`, `callAction` | `actionState`; a call | `jhonstart-forms/src/form.bp:182`; 127 |
| top-level `await`, `fetch` | `await` in a `@Component` body; `io.http.fetch(url)` — GET only | `docs.md:1592`; `libs/std/src/io/http.bp:55` |
| **`response.status`, `response.headers`** | **not found** — a render answers 200 or a navigation signal | step 1 |
| **`rewrite(path)`** | **not found** from a page; `Next.rewrite` in middleware | `rakun-web/src/middleware.bp:41-58` — step 2 |
| **`site`, `generator`, `isPrerendered`** | **not found** | step 3 |

## Mechanism

**Status/headers: hooks before the first byte.** `responseStatus(code)`, `responseHeader(name,
value)` legal until the shell flushes, a located error after — the late-signal rule of `redirect`
/ `notFound` (`05-jhonstart/README.md`, JH-26-6). They record into the render's state; the server
reads it writing the head.

```bp
val product = await findProduct(id);
if (product == null) { val _s = responseStatus(404); }
val _h = responseHeader("Cache-Control", "public, max-age=3600");
```

Request-time hooks: `#[serverOnly]` under 186/202, so the page renders per request.

**Rewrite = navigation signal.** `rewrite(path)` raises `nav:rewrite:<path>` beside
`nav:redirect`, `nav:not-found` in `libs/routing`'s `navigation`; the server matches `path`, renders that
route in the same response, address unchanged. A rewrite to a rewriting path is followed at most
once more, then refused naming both.

**`site()` is configuration**: `onze.json` `site` (124) via the render's `app(…)` options;
jhonstart names no config file. `isPrerendered()`: whether this render is build-time.

## Open

### Step 0 — Measure

- [ ] what a page gets for `request().query`, `.headers` in `onze/examples/blog` (expected `[]`, `onze-server/src/server.bp:76-77`)
- [ ] `redirect()` raised after the first chunk: the response

### Step 1 — `responseStatus`, `responseHeader`

- [ ] `examples/response-control-example.bp` passes
- [ ] either called after the shell is written fails with the hook's name and the phase
- [ ] a header set from a `Suspense` fill refused the same way
- [ ] `dynamicReason()` names `responseStatus` for a page calling it

### Step 2 — `rewrite`

- [ ] `rewrite("/es/articles/introduction")` from `/es-cu/articles/introduction` answers the second
      route's markup at the first's URL — asserted via the navigation wire on both targets
- [ ] a rewrite cycle refused, naming both paths

### Step 3 — `site`, `isPrerendered`, `currentUrl`

- [ ] `site()` is `""` when unset, and `absoluteUrl(path)` then refuses rather than emit a relative canonical link
- [ ] `isPrerendered()` true under `prerenderPath` (`static_gen.bp:381`), false on a request

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/jhonstart` and `libs/routing`
- [ ] `zig build test-libs`: jhonstart, rakun, onze green
- [ ] `contracts.md` for the new signal

## Blast radius

- **Navigation wire gains a signal**, read by rakun, jhonstart's server and client (`signalToWire` / `signalFromWire`); all three move together.
- **`RenderHooks` / `app(…)` gains two reads** (recorded status, headers); `onze-server` the one caller.

## Notes

- **Not added.** The `Astro` object. `Astro.cookies.set` in a render (the phase rule is the design;
  set cookies in middleware or the action). `fetch` with method/headers/body: `02-std-and-packaging`'s row.
- **Returning a `Response` from a page** = the three signals + two hooks; nothing else.
