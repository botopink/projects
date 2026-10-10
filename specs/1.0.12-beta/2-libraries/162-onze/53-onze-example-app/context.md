# Front 53 — onze example app: the proof, second half

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [162-onze](../README.md): s1 → 162 s9 · s2 → 162 s9 · s3 → 162 s9 · s4 → 162 s9 · s5 → 162 s9 · s6 → 162 s9 · s7 → 162 s9 · s8 → 162 s9 · s9 → 162 s9 · s10 → 162 s9 · s11 → 162 s9 · s12 → 162 s9. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — the one place a browser is in the loop and every rakun/jhonstart/emilia seam
is exercised at once; last by construction · **State:** not started
**Depends on:** `07-onze/49` (query, headers, actions, `log` sink, public root), `50` (`dev`,
`prerender/`, lazy starters), `51` (image route), `71` (release) · `05-jhonstart/26` (digest via
`log` — decisions 194, 195 —, streaming boxes), `27` (`Link` / `applyTransition`, via 50 step 6),
`67` (forms' DOM half; `67-a`) · `04-rakun`: `22-rakun-file-routing` carrying 24 (action
dispatcher, `Origin` / `Host` 403), 25 (route handlers), 60 (static generation), 66 (OG
discovery), the middleware (`rakun-web`, erlang); `12-rakun-cache` (`revalidateTag`);
`65-rakun-url-rules` (decision 201) · maintainer `50-b` (step 6) · `20-snap` step 5 (E2E runner,
390)
**Owns:** `repository/onze/examples/blog/**` (`README.md`, `test/serve.sh` included) · this
directory (`modules/onze-test/src/e2e.bp`, the group file 49 stubs, is `20-snap` step 5's)
**Does not touch:** anything else — read-only elsewhere; a needed change is reported to its owner

## Goal

Every row of [`acceptance.md`](acceptance.md) § The acceptance script a green assertion, over
both `onze dev` and `onze build && onze start`, browser rows in a real browser, via the E2E runner
(`20-snap` step 5).

## Mechanism

- **Today.** Blog under `src/` (53-a): `app/{layout,page,not-found}.bp`, `app/blog/**`
  (`[slug]/page.bp`, `[slug]/not-found.bp`), `app/(marketing)/about/page.bp`, `app/login/`,
  `app/dashboard/{layout,page}.bp`, `app/dashboard/posts/new/page.bp`,
  `components/{nav,post_card,like_button}.bp`, `lib/db.bp`; tests `db_test`, `render_test`,
  `tags_test` (both rows). Absent: `middleware.bp`, `lib/actions.bp`, `app/api/posts/route.bp`,
  `loading.bp` / `error.bp`, `README.md`, `test/serve.sh`; `onze-test` has no `e2e.bp`.
- **E2E runner** (`20-snap` step 5, 390 (5)): five harness functions — `bootApp(dir,
  mode) -> @Task<RunningApp>` (mode `dev` or `start`, over 50's commands), `stopApp`, `buildApp`,
  `request(app, method, path, headers, body)`, `requestChunks` — no snapshot writers. Suites
  assert status, headers, body over `request(…)`; dev-vs-start gate = equality property (`dev`
  reply equals `start` reply for every static route).
- **Browser rows**: a real browser driven by `serve.sh` (headless browser from the gate's
  environment; `00-gate` decides how its absence reads), not `jhonstart-dom-test`.
- **Markers.** Two copied examples carry a live `// LANGUAGE GAP` marker, indexed in
  `../../language-gaps.md` § Marker index (CI check 5): `examples/app-tree-example.bp` (`@Decl`
  carries no source location — 403, by design), `examples/blog-slug-page-example.bp` (navigation signals
  do not return `noreturn` — lg2-l). A marker goes only with its index row, when its gap closes.
  (`lib-db-example.bp`, `app/blog/[slug]/page.bpp` mention the gap in prose; not markers.)

## Notes

- Every failure found is reported to the owning front — the purpose of this front. Combined
  examples live here only (decision 114).
