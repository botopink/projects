# Front 26 — jhonstart core tail (carries 28 · 29 · 30 · 31)

**Priority:** high — `RenderHooks.onError` (31-b) is the seam `06-onze/49` wires and `07-f`
decides against; "no rakun in `modules/jhonstart/src`" is a gate grep of front 30 that is red today
**Depends on:** maintainer answer to `31-b` (step 4; recommendation (a)) · `30-h` (step 7,
conditional) · `29-a` confirmed (step 5's starter-table row) · nothing from `02-std-and-packaging`
· `00-gate` for the two stale ledger lines and the `dom-test` erlang cell
**Owns:** `repository/jhonstart/modules/jhonstart/**` (source, tests, `src/AGENTS.md`),
`modules/jhonstart-dom-test/**` (`fake_dom.mjs`, `dom_test.bp`), `docs.md`, `AGENTS.md`,
`examples/{blog-ssr,nav-shell,islands,forms,document-shell,jhonstart-counter,jhonstart-markup,jhonstart-todo}/README.md`
· step 7 only: every member's `test/__snapshots__/` · this directory
**Does not touch:** `modules/jhonstart-link/**` (27) · `modules/jhonstart-forms/**`,
`examples/forms/src/**` (67) · `modules/jhonstart-html/**`, `element.bp`, `hooks.bp` (frozen) ·
`html_attrs.bp` (`05-emilia`) · `routes.bp:178-195` (`07-bundled-libs/102-routing-conventions`) ·
`render.bp:453` `isLangTag` (`105-i18n`) · `error_boundary.bp:77`'s hash beyond the `onError`
default (`106-log`, if `07-f` chooses the package) · `examples/*/botopink.json` `targets` and
`scripts/restricted-targets.txt` (`00-gate`)
**Carried from 1.0.10:** `04-jhonstart/26-jhonstart-router/README.md` § Step 6 ·
`28-jhonstart-server-components/README.md` § Definition of done boxes 4–5 (the examples) ·
`29-jhonstart-client-directive/README.md` § Step 5 box 2, § Definition of done boxes 4 and 6 ·
`30-jhonstart-streaming/README.md` § Step 4 (the rakun grep), § Step 8 (two boxes), § Definition
of done box 3 · `31-jhonstart-error-boundaries/README.md` § Definition of done box 4 (31-b) ·
`04-jhonstart/test-snap.md` (step 7; copied here) · `02-packaging` step 3 (the READMEs)

---

## Problem

Five items, each reproducible:

1. `grep -rn rakun repository/jhonstart/modules/jhonstart/src` prints 21 lines (comments in
   `router.bp`, `server.bp`, `streaming.bp`, `metadata.bp`, `client.bp`, `src/AGENTS.md`). Front
   30's step 4 box says the grep is empty; the bridge test asserts the same for `emilia` and passes.
2. A late navigation signal is handled by two functions: `render.mjs:194-208` (what
   `registerSignal` installs under `globals().signal` for the `data-jh-g` template) and
   `client_app.bp:177-193` (`handleSignal`, for a `redirect` raised in a client-only app). A
   `data-jh-g="redirect"` template and a raised `redirect` with the same target must take the
   same path; today each has its own hop counting and allow-list check.
3. `streaming_test.bp` has no case for a boundary that resolves before the shell is written, and
   no timing case on erlang for two sibling loaders; the siblings are gathered by the render's
   own `__jhEachCompleted` rather than std's `async.runAll`, and an already-started `@Task` handed
   as a sibling has no regression test (on erlang it has already run — decision 120).
4. `error_boundary.bp:77` `digestOf(message)` is `hash.contentHash(message)` (8 hex); no log line
   carries it (the render imports no logger — decision 113), and rakun-logging's `errorDigest` is
   another function over four parts. The fallback shows a digest nobody can grep for.
5. `docs.md:371,393` attribute the payload envelope to "rakun's front 23"; since decision 117 the
   envelope is this library's (front 30), and `docs.md` § The front-68 contract (`:1093`) lacks
   the starter-table row of 29-a.

## Current state

`jhonstart` 204 / 204 on commonJS and erlang; `jhonstart-dom-test` 1 red on erlang by
construction (30-g); no `// LANGUAGE GAP` marker in the code. Measured by `zig build test-libs`
in 1.0.10's closing audit and by the greps above on the tree at `repository/jhonstart`.

## Mechanism

- **The grep.** Every rakun mention is a comment explaining a shape by analogy to rakun's code
  (`router.bp:59` "`headerOfPage` in rakun's `ssr.bp` is the shape"). None is an import. The fix
  is wording: state the shape, not the neighbour.
- **Two signal handlers.** `registerSignal(globals().signal, allowedRedirects)` installs a
  function in `render.mjs`; `clientApp` (front 26, decision 117) handles a raise in `client_app.bp`
  through `handleSignal`. Both decide "relative → `history.replaceState` + `popstate`; absolute →
  only if allowed; hop limit". One function, exported by the core and called from both, is the
  shape; the `.mjs` half calls it through the registry like every other browser function.
- **The digest.** `app(plugins, allowedRedirects, lang)` is the one place onze hands values to
  the render (30-f); `RenderHooks(headExtra, bodyExtra)` the other. 31-b (a) adds
  `onError: fn(message: string) -> string` beside them: the boundary calls it once per caught
  error, puts the answer in the payload and the fallback, and the default is today's
  `contentHash`. onze 49 sets it to `logErrorWithDigest` — one call site that logs and answers.

## Steps

### Step 1 — the core's `src/` names no rakun

Reword the 21 comment lines and `src/AGENTS.md:45,62` to state the shape without the neighbour
(`streaming.bp:18` "a `Response` onze built over rakun's `ChunkWriter`" → "a `Response` the host
built over its chunk writer"; `router.bp:165` explains a target profile that no longer exists).

**Acceptance:**
- [ ] `grep -rni rakun repository/jhonstart/modules/jhonstart/src` is empty; the same grep over
      `modules/jhonstart-link/src`, `modules/jhonstart-forms/src` reported (not edited: 27's and
      67's)
- [ ] `bridge_test.bp` gains "bridge: no file of the core's src names rakun", the twin of its
      emilia case, green on both rows

### Step 2 — one late-signal handler

`client_app.bp` exports `applyLateSignal(site: ClientApp, reason: string, hops: i32)` (the body
of `handleSignal`), and `render.mjs`'s `registerSignal` installs a closure that calls it through
the registry (`globals().signal` stays the entry point; `data-jh-g` markup unchanged).

**Acceptance:**
- [ ] `grep -c "replaceState" render.mjs client_app.mjs` is 1 across both files
- [ ] `dom_test.bp`: a `data-jh-g="redirect"` template with target `/x` and a raised
      `redirect("/x")` leave the same `history` and `location` records; an absolute target not in
      `allowedRedirects` is refused by both with the same message; the hop limit trips at the same
      count for both
- [ ] `client_app_test.bp` and `streaming_test.bp` unchanged in count

### Step 3 — the streaming boxes

**Acceptance:**
- [ ] `streaming_test.bp` "stream: a boundary resolved before the shell produces no hole and no
      fill" — the shell carries the resolved markup inline, `chunks.length == 1`, on both rows
- [ ] sibling server components are gathered through std `async.runAll` over unstarted thunks
      (`Array<fn() -> @Task<T>>`), and `__jhEachCompleted` is deleted — or, if the render's own
      gatherer must stay (it fills holes in completion order, which `runAll` does not report),
      `render.bp` states why in one comment and this box is ticked with that reason
- [ ] `streaming_test.bp` "stream: two 50 ms sibling loaders finish in under 100 ms" on
      `--target erlang` (spawned per task) and the same test on commonJS
- [ ] "stream: an already-started `@Task` handed as a sibling is refused" — the render takes
      thunks only; a started task cannot be passed (the type refuses it), asserted by a `check`
      refusal fixture under `refusals/`

### Step 4 — the error digest through `RenderHooks.onError` (31-b, option a)

**Acceptance:**
- [ ] `RenderHooks` gains `onError: fn(message: string) -> string`; `defaultHooks()` answers
      `hash.contentHash(message)`; `renderBoundaryChecked` calls `hooks.onError` once per caught
      error and writes the answer into `ErrorInfo.digest`, the fallback markup and the payload
- [ ] `error_boundary_test.bp`: with `setHooks(RenderHooks(…, onError: { m -> "D-" + m.length() }))`
      the fallback shows `D-<n>` and the client-visible `ErrorInfo` still carries no message
- [ ] the default is unchanged: every existing digest literal in the tests stays byte-identical
- [ ] `06-onze/49` step 3 is named in `docs.md` as the place `onError` is set to the logger; no
      rakun type appears in the signature

### Step 5 — `docs.md`

**Acceptance:**
- [ ] `docs.md:371,393` name front 30 (this library's payload envelope), not rakun's 23
- [ ] `docs.md` § The front-68 contract has the starter-table row (`globals.starters`,
      `registerStarter` / `registerRouteStarters`, 29-a) and the `islandAttr(ordinal)` row reads
      "exported here; onze's entry imports it"; `06-onze/50` cites the section
- [ ] `docs.md` § Error boundaries documents `onError`

### Step 6 — the spec examples and the eight READMEs

The three examples copied to [`examples/`](./examples/) are corrected here (the 1.0.10 record is
frozen): `request-scope-example.bp` passes every untrusted value through `escape.html` /
`escape.attribute`; `blog-post-page-example.bp` hands its two loaders to `async.runAll` as
thunks; `streamed-blog-page-example.bp` follows step 3's answer. Each `examples/<p>/README.md`
names the upstream section it mirrors and the fronts it exercises (`02-packaging` § 6).

**Acceptance:**
- [ ] the three `.bp` files compile with `botopink check` against `modules/jhonstart` (they are
      spec examples; the check is the front's own run, not a gate row)
- [ ] `find repository/jhonstart/examples -maxdepth 2 -name README.md | wc -l` is 8

### Step 7 — conditional on `30-h`: the module-level snapshot map

Only under (b): realise [`test-snap.md`](./test-snap.md) for every member's `test/` through
`jhonstart-test`'s helpers, recorded by renaming `.new` files, after 27 and 67 have landed
(this step re-records every member's directory and runs alone). Under (a) — the recommendation —
`AGENTS.md` § Tests says the inline literals, `helpers_test.bp`'s snapshots and the examples' 32
are the evidence.

**Acceptance:**
- [ ] under (b): every `.snap` the map names exists, identical on both rows, no `.new` left
- [ ] under (a): the `AGENTS.md` paragraph

## Gate

- [ ] `zig build test-libs` — every jhonstart member at its count or above, both rows
      (`jhonstart-dom-test` erlang per `00-gate`'s rule)
- [ ] `grep -rni rakun modules/jhonstart/src` empty; `grep -i emilia` still empty
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/26-jhonstart-router`; no push, no merge — landing is the maintainer's step

## Blast radius

Step 4 changes `RenderHooks`' shape: `06-onze/49`'s `bootSite` fills the new field (a labelled
argument with a default keeps every existing call compiling — C-04). Step 3's `runAll` switch
moves no snapshot (the chunks are byte-identical; only the gatherer changes). Step 7 (b) adds
~150 files.

## Notes

- 31-b (a) keeps the render free of any logger type; `07-f` may later replace the *default* with
  a bundled `log`'s digest, which lands in `106-log` after this front.
- The `dom-test` erlang cell stays a `00-gate` matter; this front adds cases to `dom_test.bp` on
  commonJS only.
