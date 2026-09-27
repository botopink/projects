# Front 53 — onze example app: the proof, second half

**Priority:** high — the one place a browser is in the loop and every seam of rakun, jhonstart
and emilia is exercised at once; last by construction
**Depends on:** `06-onze/49` (query, headers, actions, `onError`, the public root), `50` (`dev`,
`prerender/`, lazy starters), `51` (the image route), `71` (the release) · `04-jhonstart/26`
(`onError`, the streaming boxes), `67` (the forms' DOM half; `67-a`) · the `03-rakun` track:
`22-rakun-file-routing` carrying 24 (the action dispatcher, the `Origin` / `Host` 403), 25 (route
handlers), 60 (static generation), 66 (OG discovery), and the middleware (`rakun-web`, erlang);
`12-rakun-cache` (`revalidateTag`); `65-rakun-url-rules` carrying 82 (69-b) · maintainer `53-a`
confirmed, `53-b` (the E2E runner is unconditional) · `00-gate` (the two stale markers in the
copied examples are removed here; lg2-q's stays)
**Owns:** `repository/onze/examples/blog/**` (`README.md` included), `examples/blog/test/serve.sh`,
`modules/onze-test/src/e2e.bp` (the group file 49 stubs) · this directory
**Does not touch:** anything else — read-only against every other member and repository; a
needed change is reported to its owner (the template's rule)
**Carried from 1.0.10:** `53-onze-example-app/README.md` whole (copied as
[`acceptance.md`](./acceptance.md) — the app, the acceptance script, the assumed API shapes, the
mechanism) · its § Step 3 (4 boxes), § Step 4 (2), § Step 5 (5), § Step 6 (2), § Step 7 (3),
§ Definition of done (5) · `examples/*.bp` (thirteen, copied) · `test-snap-examples.md` (copied
whole; the E2E runner § and the blog's six suites) · `51`'s hand-off (the README's `remotePatterns`
sentence) · `02-packaging` step 3 (`README.md`)

---

## Problem

Nineteen of 41 boxes hold: the store, the read path, `/`, `/blog/hello-world`, `/about` served by
`onze start`, the post's not-found boundary (404, nearest wins), the dashboard's gating layout (in
process and over the socket), the `LikeButton` island in the `shared` chunk and out of reach of
`lib/db` (a build refusal), the content-hashed script tag; `examples/blog/test/` green on both
rows. Open, each a row of [`acceptance.md`](./acceptance.md) § The acceptance script:

| Group | Boxes | Waits on |
|---|---|---|
| prerender and metadata | `/blog/<slug>` prerendered for the three posts and no others; served without invoking the page (a counter in `lib/db.bp`); `generateMetadata` for the post, merged with the root layout's | 50 step 3, rakun 60 |
| streaming and boundaries | a slow `loadPosts` flushes the shell and the fallback first; a throwing page renders `app/error.bp` with 500 and the digest | jhonstart 26 steps 3–4, 49 step 3 |
| the write path | `/dashboard` without a session cookie → `/login` from the middleware, before the layout; the new-post form re-renders with the message beside the field; a valid submit writes and `/blog` shows it (`revalidateTag("posts")` reaches the store); the form works with scripting disabled; an `Origin` ≠ `Host` action is 403 | 49 step 2, jhonstart 67, rakun 24 · 12, the middleware |
| the browser | clicking the like button increments without a request; `Link` between `/blog` and `/blog/<slug>` does not re-request the document | 50 step 6, jhonstart 27 |
| the commands | `onze dev` serves every route; `build && start` serves the same bytes for every static route; every `// front NN` names a front that exists | 50 step 2, 50-b |
| DoD | every file of the script exists with a green *Proves* column; both command paths; the assumed-API table reconciled; the `// front NN` checker; the markers; both rows | all of the above |

Three of the copied examples carry a `// LANGUAGE GAP` marker: `app-tree-example.bp:43`
(`@Decl` carries no source location — lg2-q, a row) and two "no bottom type" markers
(`blog-slug-page-example.bp:84`, `lib-db-example.bp:88`) that are stale: `@panic` / `@todo`
answer `noreturn` since 01-checker; whether a user function may declare it is lg2-l.

## Current state

The blog under `src/` (53-a): `app/{layout,page,not-found}.bp`, `app/blog/**`, `app/dashboard/**`,
`components/{nav,post_card,like_button}.bp`, `lib/db.bp`; `db_test`, `render_test`, `tags_test`.
No `middleware.bp`, no `lib/actions.bp`, no `app/api/posts/route.bp`, no `loading.bp` /
`error.bp`, no `README.md`, no `serve.sh`; `onze-test` has no `e2e.bp`.

## Mechanism

The E2E runner of [`test-snap-examples.md`](./test-snap-examples.md) § The E2E runner:
`bootApp(dir, mode) -> @Task<RunningApp>` (mode `dev` or `start`, over 50's commands),
`stopApp`, `request(app, method, path, headers, body)`, `assertResponse(loc, r)` (status +
headers + body, hashes literal, the build id masked only in `assertServeGate`), `assertBundle`,
`assertCss`, `assertServeGate(loc, dir)` (the dev-vs-start diff over every static route). The
browser rows run in a real browser driven by `serve.sh` (a headless browser the gate's
environment provides; `00-gate` decides how its absence reads), not through `jhonstart-dom-test`.

## Steps

### Step 1 — the runner, the README, the markers

**Acceptance:**
- [ ] `onze-test/src/e2e.bp` exports the six helpers above; `test/helpers_test.bp` (49's) gains
      one case per helper over the scaffold; erlang for `bootApp` / `request`, both rows for the
      writers
- [ ] `examples/blog/README.md` names `NEXTJS-DOCS.md`'s sections, the fronts, the four commands,
      and that `remotePatterns` is empty (51's sentence)
- [ ] the two stale markers are removed from the copied examples here; `app-tree-example.bp:43`
      keeps lg2-q's

### Step 2 — prerender and metadata

**Acceptance:**
- [ ] the four boxes of `acceptance.md` § Step 3, through `assertServeGate` and a `pages_test.bp`
      case reading the `lib/db.bp` counter

### Step 3 — streaming and boundaries

**Acceptance:**
- [ ] `app/loading.bp` and `app/error.bp` exist; the two boxes of § Step 4 (the shell before the
      list; 500 with the digest — the digest equal to the captured log line's, 49 step 3)

### Step 4 — the write path

**Acceptance:**
- [ ] `src/middleware.bp`, `lib/actions.bp`, `app/dashboard/new/**` (the form), `app/api/posts/route.bp`
      exist; the five boxes of § Step 5 through `write_path_test.bp` and `api_test.bp`, on erlang
      over the socket; the no-JS POST row through a request with no script executed

### Step 5 — the browser

**Acceptance:**
- [ ] `test/serve.sh` boots the built app, drives a headless browser through the like button and
      a `Link` navigation, and asserts no document request on the navigation and no request on
      the click; `assets_test.bp` asserts the chunk names 50 step 6 produces

### Step 6 — the commands and the DoD

**Acceptance:**
- [ ] `gate_test.bp`: `onze dev` serves every route of the script; `assertServeGate` shows no
      diff between `dev` and `start` for every static route
- [ ] every `// front NN` comment in `examples/blog/src/**` names a directory under
      `specs/1.0.11-beta/` (a `unit_test.bp` case walks the tree and the comments)
- [ ] `acceptance.md` § Assumed API shapes reconciled row by row against the landed surfaces;
      every row matches or is changed here
- [ ] `zig build test-libs` — `blog` green on both rows, `serve.sh` green on erlang in the gate's
      environment

## Gate

- [ ] `zig build test-libs` green for `blog`, `onze-test`; `serve.sh` exit 0
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/53-onze-example-app`; no push, no merge — landing is the maintainer's step

## Blast radius

None: the front changes an example and a test member. Every failure it finds is reported to the
owning front, which is the purpose of the front.

## Notes

- The record of what the app is and the full acceptance script stay in `acceptance.md` verbatim
  (its status lines are the 1.0.10 record's); this README lists only what is open.
- Combined examples live here and nowhere else (decision 114).
