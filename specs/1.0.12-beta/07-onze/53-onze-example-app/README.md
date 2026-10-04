# Front 53 — onze example app: the proof, second half

**Priority:** high — the one place a browser is in the loop and every rakun/jhonstart/emilia seam
is exercised at once; last by construction · **State:** not started
**Depends on:** `07-onze/49` (query, headers, actions, `log` sink, public root), `50` (`dev`,
`prerender/`, lazy starters), `51` (image route), `71` (release) · `05-jhonstart/26` (digest via
`log` — decisions 194, 195 —, streaming boxes), `27` (`Link` / `applyTransition`, via 50 step 6),
`67` (forms' DOM half; `67-a`) · `04-rakun`: `22-rakun-file-routing` carrying 24 (action
dispatcher, `Origin` / `Host` 403), 25 (route handlers), 60 (static generation), 66 (OG
discovery), the middleware (`rakun-web`, erlang); `12-rakun-cache` (`revalidateTag`);
`65-rakun-url-rules` (decision 201) · maintainer `50-b` (step 6) · `20-snap` step 5 (E2E runner,
`snap-a`)
**Owns:** `repository/onze/examples/blog/**` (`README.md`, `test/serve.sh` included) · this
directory (`modules/onze-test/src/e2e.bp`, the group file 49 stubs, is `20-snap` step 5's)
**Does not touch:** anything else — read-only elsewhere; a needed change is reported to its owner

## Goal

Every row of [`acceptance.md`](./acceptance.md) § The acceptance script a green assertion, over
both `onze dev` and `onze build && onze start`, browser rows in a real browser, via the E2E runner
(`20-snap` step 5).

## Mechanism

- **Today.** Blog under `src/` (53-a): `app/{layout,page,not-found}.bp`, `app/blog/**`
  (`[slug]/page.bp`, `[slug]/not-found.bp`), `app/(marketing)/about/page.bp`, `app/login/`,
  `app/dashboard/{layout,page}.bp`, `app/dashboard/posts/new/page.bp`,
  `components/{nav,post_card,like_button}.bp`, `lib/db.bp`; tests `db_test`, `render_test`,
  `tags_test` (both rows). Absent: `middleware.bp`, `lib/actions.bp`, `app/api/posts/route.bp`,
  `loading.bp` / `error.bp`, `README.md`, `test/serve.sh`; `onze-test` has no `e2e.bp`.
- **E2E runner** (`20-snap` step 5, `snap-a` (5)): five harness functions — `bootApp(dir,
  mode) -> @Task<RunningApp>` (mode `dev` or `start`, over 50's commands), `stopApp`, `buildApp`,
  `request(app, method, path, headers, body)`, `requestChunks` — no snapshot writers. Suites
  assert status, headers, body over `request(…)`; dev-vs-start gate = equality property (`dev`
  reply equals `start` reply for every static route).
- **Browser rows**: a real browser driven by `serve.sh` (headless browser from the gate's
  environment; `00-gate` decides how its absence reads), not `jhonstart-dom-test`.
- **Markers.** Two copied examples carry a live `// LANGUAGE GAP` marker, indexed in
  `../../language-gaps.md` § Marker index (CI check 5): `examples/app-tree-example.bp` (`@Decl`
  carries no source location — lg2-q), `examples/blog-slug-page-example.bp` (navigation signals
  do not return `noreturn` — lg2-l). A marker goes only with its index row, when its gap closes.
  (`lib-db-example.bp`, `app/blog/[slug]/page.bpp` mention the gap in prose; not markers.)

## Open

### Step 1 — the runner and the README

- [ ] runner = five harness functions (`bootApp`, `stopApp`, `buildApp`, `request`, …), no
      snapshot writers; blog E2E cases are asserts over `request(…)`, dev/start gate an equality
      property; one `helpers_test` case per harness function, erlang for `bootApp` / `request`
      (the form `20-snap` § 9 evaluated)

- [ ] `examples/blog/README.md` names `NEXTJS-DOCS.md`'s sections, the fronts, the four commands,
      and that `remotePatterns` is empty (51's sentence)
- [ ] `examples/blog/botopink.json` has no `"alias"` key, no source imports `from "@/…"`
      (decision 218; bundler half 50 step 9)

### Step 2 — prerender and metadata (after 50 step 3, rakun 60)

- [ ] the four boxes of `acceptance.md` § Step 3, via the dev/start equality property and a
      `pages_test.bp` case reading the `lib/db.bp` counter

### Step 3 — streaming and boundaries (after jhonstart 26 steps 3–4, 49 step 3)

- [ ] `app/loading.bp`, `app/error.bp` exist; § Step 4's two open boxes (shell before the list;
      500 with the digest — equal to the captured log line's, 49 step 3)

### Step 4 — the write path (after 49 step 2, jhonstart 67, rakun 24 · 12, the middleware)

- [ ] `src/middleware.bp`, `src/lib/actions.bp`, `src/app/api/posts/route.bp` exist;
      `app/dashboard/posts/new/page.bp` binds its form to the action; § Step 5's five open boxes
      via `write_path_test.bp` and `api_test.bp`, erlang over the socket; the no-JS POST row via
      a request with no script executed

### Step 5 — the browser (after 50 step 6, jhonstart 27)

- [ ] `test/serve.sh` boots the built app, drives a headless browser through the like button and
      a `Link` navigation; asserts no document request on the navigation, no request on the
      click; `assets_test.bp` asserts the chunk names 50 step 6 produces

### Step 6 — the commands and the DoD (after 50 step 2, 50-b)

- [ ] `gate_test.bp`: `onze dev` serves every route of the script; `dev` and `start` replies equal
      for every static route (a property over `request`)
- [ ] every `// front NN` comment in `examples/blog/src/**` names a directory under
      `specs/1.0.12-beta/` (a `unit_test.bp` case walks the tree and comments)
- [ ] `acceptance.md` § Assumed API shapes reconciled row by row against landed surfaces; every
      row matches or is changed here
- [ ] the remaining boxes of `acceptance.md` § Definition of done
- [ ] `zig build test-libs` — `blog` green on both rows, `serve.sh` green on erlang in the gate's
      environment

## Notes

- Every failure found is reported to the owning front — the purpose of this front. Combined
  examples live here only (decision 114).

### Step 7 — references, not strings (decision 281)

- [ ] the examples rewritten: `use actionState(createPost, initial)` (no `"createPost"`, no `use`
      prefix), `<form action={createPost}>` (no `formAction("a_9f31…", …, "__bp_action")`),
      starters from the catalogue (no `registerStarter("…")`), handlers `#[onClick(…)]`

### Step 8 — a role in the decorator, not in an export's name (decision 282)

- [ ] the examples rewritten: `generateStaticParams` / `blogStaticParams` + `registerStaticParams("blog/[slug]", …)`
      → `#[page("blog/[slug]", paths: allPosts)]`; `generateMetadata` → `head: postHead`;
      `acceptance.md`'s rows (122, 126) name the decorator arguments

### Step 9 — no segment configuration (decision 290)

- [ ] `registerSegmentConfig` gone from the examples (`app/page.bpp`, `app-page-example.bp`,
      `app/blog/[slug]/page.bpp`, `blog-slug-page-example.bp` — rewritten with 290);
      `acceptance.md` row 60 names `#[page("blog/[slug]", revalidate: hours(1), dynamicParams: true)]`;
      the home page prerendered by its hooks alone

### Step 10 — route parameters and page data are hooks (decision 293)

- [ ] `app-page-example.bp`, `app-tree-example.bp`, `blog-list-page-example.bp`, `blog-slug-page-example.bp`, `new-post-form-example.bp`, `acceptance.md`: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

### Step 11 — a cookie is declared once, typed (decision 294)

- [ ] `lib/cookies.bp` declares `sessionCookie = Cookie<SessionId>("session", …)`; the dashboard
      layout reads `use cookie(sessionCookie)` (no `pairValue(jar, "session")`), the login action
      and the logout action write and clear it with `use setCookie` / `use clearCookie` (295)

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` green for `blog`, `onze-test`; `serve.sh` exit 0
