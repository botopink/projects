# Front 53 — onze example app: the proof, second half

**Priority:** high — the one place a browser is in the loop and every seam of rakun, jhonstart
and emilia is exercised at once; last by construction · **State:** not started
**Depends on:** `07-onze/49` (query, headers, actions, the `log` sink, the public root), `50`
(`dev`, `prerender/`, lazy starters), `51` (the image route), `71` (the release) ·
`05-jhonstart/26` (the digest through `log` — decisions 194, 195 —, the streaming boxes), `27`
(`Link` / `applyTransition`, through 50 step 6), `67` (the forms' DOM half; `67-a`) · the
`04-rakun` track: `22-rakun-file-routing` carrying 24 (the action dispatcher, the `Origin` /
`Host` 403), 25 (route handlers), 60 (static generation), 66 (OG discovery), and the middleware
(`rakun-web`, erlang); `12-rakun-cache` (`revalidateTag`); `65-rakun-url-rules` (decision 201) ·
maintainer `50-b` (step 6) · `20-snap` step 5 (the E2E runner, `snap-a`)
**Owns:** `repository/onze/examples/blog/**` (`README.md` and `test/serve.sh` included) · this
directory (`modules/onze-test/src/e2e.bp`, the group file 49 stubs, is `20-snap` step 5's)
**Does not touch:** anything else — read-only against every other member and repository; a
needed change is reported to its owner

## Goal

Every row of [`acceptance.md`](./acceptance.md) § The acceptance script is a green assertion,
over both `onze dev` and `onze build && onze start`, with the browser rows driven by a real
browser, through the E2E runner (`20-snap` step 5).

## Mechanism

- **Today.** The blog under `src/` (53-a): `app/{layout,page,not-found}.bp`, `app/blog/**`
  (`[slug]/page.bp`, `[slug]/not-found.bp`), `app/(marketing)/about/page.bp`, `app/login/`,
  `app/dashboard/{layout,page}.bp` and `app/dashboard/posts/new/page.bp`,
  `components/{nav,post_card,like_button}.bp`, `lib/db.bp`; tests `db_test`, `render_test`,
  `tags_test` (both rows). No `middleware.bp`, `lib/actions.bp`, `app/api/posts/route.bp`,
  `loading.bp` / `error.bp`, `README.md` or `test/serve.sh`; `onze-test` has no `e2e.bp`.
- **The E2E runner** (`20-snap` step 5, `snap-a` (5)): five harness functions — `bootApp(dir,
  mode) -> @Task<RunningApp>` (mode `dev` or `start`, over 50's commands), `stopApp`, `buildApp`,
  `request(app, method, path, headers, body)`, `requestChunks` — and no snapshot writers. The
  suites assert status, headers and body over `request(…)`; the dev-vs-start gate is an equality
  property, the `dev` reply equal to the `start` reply for every static route.
- **The browser rows** run in a real browser driven by `serve.sh` (a headless browser the gate's
  environment provides; `00-gate` decides how its absence reads), not through
  `jhonstart-dom-test`.
- **Markers.** Two copied examples carry a `// LANGUAGE GAP` marker, both live and both indexed in
  `../../language-gaps.md` § Marker index (CI check 5): `examples/app-tree-example.bp`
  (`@Decl` carries no source location — lg2-q) and `examples/blog-slug-page-example.bp` (the
  navigation signals do not return `noreturn` — lg2-l). A marker goes only together with its
  index row, when its gap closes. (`lib-db-example.bp` and `app/blog/[slug]/page.bpp` mention
  the gap in prose and are not markers.)

## Open

### Step 1 — the runner and the README

- [ ] the runner is five harness functions (`bootApp`, `stopApp`, `buildApp`, `request`, …) with no
      snapshot writers; the blog E2E cases are asserts over `request(…)` and the dev/start gate an
      equality property; one `helpers_test` case per harness function, erlang for `bootApp` /
      `request` (the form `20-snap` § 9 evaluated)

- [ ] `examples/blog/README.md` names `NEXTJS-DOCS.md`'s sections, the fronts, the four commands,
      and that `remotePatterns` is empty (51's sentence)
- [ ] `examples/blog/botopink.json` has no `"alias"` key and no source imports `from "@/…"`
      (decision 218; the bundler half is 50 step 9)

### Step 2 — prerender and metadata (after 50 step 3, rakun 60)

- [ ] the four boxes of `acceptance.md` § Step 3, through the dev/start equality property and a `pages_test.bp`
      case reading the `lib/db.bp` counter

### Step 3 — streaming and boundaries (after jhonstart 26 steps 3–4, 49 step 3)

- [ ] `app/loading.bp` and `app/error.bp` exist; the two open boxes of § Step 4 (the shell before
      the list; 500 with the digest — equal to the captured log line's, 49 step 3)

### Step 4 — the write path (after 49 step 2, jhonstart 67, rakun 24 · 12, the middleware)

- [ ] `src/middleware.bp`, `src/lib/actions.bp`, `src/app/api/posts/route.bp` exist and
      `app/dashboard/posts/new/page.bp` binds its form to the action; the five open boxes of
      § Step 5 through `write_path_test.bp` and `api_test.bp`, on erlang over the socket; the
      no-JS POST row through a request with no script executed

### Step 5 — the browser (after 50 step 6, jhonstart 27)

- [ ] `test/serve.sh` boots the built app, drives a headless browser through the like button and
      a `Link` navigation, and asserts no document request on the navigation and no request on
      the click; `assets_test.bp` asserts the chunk names 50 step 6 produces

### Step 6 — the commands and the DoD (after 50 step 2, 50-b)

- [ ] `gate_test.bp`: `onze dev` serves every route of the script; the `dev` and `start` replies
      are equal for every static route (a property over `request`)
- [ ] every `// front NN` comment in `examples/blog/src/**` names a directory under
      `specs/1.0.12-beta/` (a `unit_test.bp` case walks the tree and the comments)
- [ ] `acceptance.md` § Assumed API shapes reconciled row by row against the landed surfaces;
      every row matches or is changed here
- [ ] the remaining boxes of `acceptance.md` § Definition of done
- [ ] `zig build test-libs` — `blog` green on both rows, `serve.sh` green on erlang in the gate's
      environment

## Notes

- Every failure this front finds is reported to the owning front, which is the purpose of the
  front. Combined examples live here and nowhere else (decision 114).

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` green for `blog`, `onze-test`; `serve.sh` exit 0
