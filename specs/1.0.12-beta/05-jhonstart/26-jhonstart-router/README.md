# Front 26 — jhonstart core tail: the core member's open items (carries 1.0.10's 28 · 29 · 30 · 31)

**Priority:** high — the boundary's digest and log line through the bundled `log` (decisions 194,
195) is what `07-onze/49` step 3 completes; "no rakun in `modules/jhonstart/src`" is a gate grep
that is red today · **State:** not started
**Depends on:** `08-bpp/118` landed before this front opens (step 0 moves the member it lands in —
decision 200), with its carve-outs in this member: the bracket-attribute step-1 lines (in the core
only comments of `root.bp` / `elements.bp` name the DSL; no `[name]={` exists in `src/`), the
core's `src/prelude.bp` and the type `Children` (decision 266) · `03-bundled-libs/102` step 3's `routes.bp` commit,
landed before this front opens (decision 188) · `01-compiler/01-checker`'s capability — the hooks
a function activates through `use`, readable from its `@Decl` (`language-gaps.md`) — for step 8
(decision 186) · `30-h` (step 7) · `29-a` confirmed (step 5's starter-table row)
**Owns:** `repository/jhonstart/modules/jhonstart/**` (source, tests, `src/AGENTS.md`),
`modules/jhonstart-dom-test/**` (`fake_dom.mjs`, `dom_test.bp`), `docs.md`, `AGENTS.md`,
`examples/{blog-ssr,nav-shell,islands,forms,document-shell,jhonstart-counter,jhonstart-markup,jhonstart-todo}/README.md`
· step 0 only: the deletion of `modules/jhonstart-html/`, the workspace manifest's member list,
the import lines of `jhonstart-emilia`, `examples/jhonstart-markup` and `examples/document-shell`
(decision 200) · step 7 only: every member's `test/__snapshots__/` · this directory
**Does not touch:** `modules/jhonstart-link/**` (27) · `modules/jhonstart-forms/**`,
`examples/forms/src/**` (67) · `src/html.bp` and its tests after step 0 (`08-bpp/118`'s, then one
lowering arm each from 119, 120, 126) · `element.bp`, `hooks.bp` (frozen) · `html_attrs.bp`
(`06-emilia`) · the segment walk in `routes.bp`'s `page` (`:233-251`,
`03-bundled-libs/102-routing-conventions`) · `render.bp:539` `isLangTag` (`105-i18n`) ·
`libs/log/**` (`106-log` — this front calls the package) · `examples/*/botopink.json` `targets` ·
after this front has landed, one front at a time: the files `08-bpp` adds to this member (116's
`bpp.bp`; 120's `island_strategy.bp`, `deferred.bp` and its lines of `client.bp`, `render.bp`,
`island_runtime.mjs`; 122's `response.bp` and its lines of `server.bp`, `error_boundary.bp`) and
`fake_dom.mjs`'s additions (120, then 126 — a front owns the test file it adds to
`jhonstart-dom-test`; `fake_dom.mjs` stays this front's, decision 189)

## Goal

The core member holds `html` as its default function (no `jhonstart-html`), names no rakun in
`src/`, handles a late navigation signal in one function, digests and logs a caught error through
the bundled `log`, has the streaming cases it lacks, a `docs.md` that names the right fronts,
corrected spec examples and eight example READMEs — and, after the checker capability, knows a
page's stage at compile time (no run-time `markDynamic`).

## Mechanism

- **The grep.** Every rakun mention is a comment explaining a shape by analogy to rakun's code
  (`router.bp:59` "`headerOfPage` in rakun's `ssr.bp` is the shape"). None is an import. The fix
  is wording: state the shape, not the neighbour.
- **Two signal handlers.** `registerSignal(name, allowedRedirects)` in `render.mjs` installs the
  function a `data-jh-g` template's script calls; `clientApp` handles a raise in `client_app.bp`
  through `handleSignal`. Both decide "relative → `history.replaceState` + `popstate`; absolute →
  only if allowed; hop limit". One function, exported by the core and called from both, is the
  shape; the `.mjs` half calls it through the registry like every other browser function.
- **The digest.** One scheme, one implementation (decision 194): `errorDigest(module, errorClass,
  message, topFrames)` of the bundled `log` — 16 hex of `strongHash` over the four parts, frames
  normalised. The boundary calls `log`'s error-logging function once per caught error; that call
  writes the record through the injected sink and answers the digest, which goes into the payload
  and the fallback — so the digest a fallback shows is the one on the log line. `digestOf` is
  deleted and no `RenderHooks.onError` is added (decision 195). The render imports `log` like
  `routing` and `actions`; it still imports no framework, and rakun-logging reaches it only as the
  sink onze installs. With no sink set the default sink receives the record.
- **The stage of a page (decisions 186, 202).** A page is produced along three stages — comptime
  (the build, where a page is prerendered), server (request time), client (the browser). A hook
  with no marker may run at any stage; `#[serverOnly]` restricts one to request time,
  `#[clientOnly]` to the browser. This library declares the two markers and puts them on its hooks
  (`searchParams`, `cookies`, `headers`, `request` are `#[serverOnly]`); `#[page]` and `#[client]`
  read the hooks their function activates through `use`, transitively, and refuse at compile
  time, located at the `use`: a `#[serverOnly]` hook inside a `#[client]` component, a
  `#[clientOnly]` hook outside one. No page declares its stage: `#[page]` (`routes.bp:220`)
  prerenders at comptime a page that reaches no `#[serverOnly]` hook and leaves one that reaches
  one to be rendered per request. The build writes the kind into `routing`'s `k` blob;
  `markDynamic` and the payload's `d` as a run-time mark go.

## Open

### Step 0 — `jhonstart-html` merges into the core (decision 200)

After `08-bpp/118` has landed in `jhonstart-html`. `src/html.bp` and the member's tests move into
`modules/jhonstart`; `html` becomes the core's `pub default fn`, imported
`import html, {Element, renderToString} from "jhonstart";`; the member is deleted (decision 187's
criterion: a module every consumer needs is not a member of its own). The three consumers —
`jhonstart-emilia`, `examples/jhonstart-markup`, `examples/document-shell` — import from the
core. The step moves code and changes no behaviour; `08-bpp/116` (`"bpp": "jhonstart"`) and the
later appends to `html.bp` (119, 120, 126) are written against it.

The acceptance is written by the front when the step opens: the member is gone, its tests run in
the core's cell on both rows, and `grep -rn '"jhonstart-html"' repository/jhonstart
--exclude=CHANGELOG.md` is empty (today it also hits `docs.md`, `README.md`, `AGENTS.md`,
`jhonstart-emilia`'s manifest and bridge test, and the two examples).

### Step 1 — the core's `src/` names no rakun

Reword the 26 lines `grep -rni rakun modules/jhonstart/src` prints today — `router.bp:59,103,164,
313,373,375,404`, `server.bp:23,34,49,50,115,116,187,307`, `streaming.bp:18`,
`metadata.bp:12,34,35`, `client.bp:87`, `src/AGENTS.md:44,45,62`, and the `.erl` sidecars
`sidecars/jhonstart_server.erl:17,26` and `sidecars/jhonstart_router.erl:20` — to state the shape
without the neighbour (`streaming.bp:18` "a `Response` onze built over rakun's `ChunkWriter`" →
"a `Response` the host built over its chunk writer"; `router.bp:164` explains a target profile
that no longer exists).

- [ ] `grep -rni rakun repository/jhonstart/modules/jhonstart/src` (which covers `sidecars/`) is
      empty; the same grep over `modules/jhonstart-link/src`, `modules/jhonstart-forms/src`
      reported (2 lines today; not edited: 27's and 67's)
- [ ] `bridge_test.bp` gains "bridge: no file of the core's src names rakun", the twin of its
      emilia case, green on both rows

### Step 2 — one late-signal handler

`client_app.bp` exports `applyLateSignal(site: ClientApp, reason: string, hops: i32)` (the body
of `handleSignal`, `client_app.bp:219`), and `render.mjs`'s `registerSignal` (`:199`) installs a
closure that calls it through the registry (`globals().signal` stays the entry point; `data-jh-g`
markup unchanged).

- [ ] `render.mjs` makes no `replaceState` call (today `:213`); the relative redirect goes
      through `applyLateSignal` and the router's `replace` (`router_runtime.mjs`), so
      `grep -n "replaceState(" render.mjs client_app.mjs` prints nothing
- [ ] `dom_test.bp`: a `data-jh-g="redirect"` template with target `/x` and a raised
      `redirect("/x")` leave the same `history` and `location` records; an absolute target not in
      `allowedRedirects` is refused by both with the same message; the hop limit trips at the same
      count for both
- [ ] `client_app_test.bp` and `streaming_test.bp` unchanged in count

### Step 3 — the streaming boxes

- [ ] `streaming_test.bp` "stream: a boundary resolved before the shell produces no hole and no
      fill" — the shell carries the resolved markup inline, `chunks.length == 1`, on both rows
- [ ] sibling server components are gathered through std `async.runAll` over unstarted thunks
      (`Array<fn() -> @Task<T>>`), and `__jhEachCompleted` (`streaming.bp:136,810,834`) is
      deleted — or, if the render's own gatherer must stay (it fills holes in completion order,
      which `runAll` does not report), `render.bp` states why in one comment and this box is
      ticked with that reason
- [ ] `streaming_test.bp` "stream: two 50 ms sibling loaders finish in under 100 ms" on
      `--target erlang` (spawned per task) and the same test on commonJS
- [ ] "stream: an already-started `@Task` handed as a sibling is refused" — the render takes
      thunks only; a started task cannot be passed (the type refuses it), asserted by a `check`
      refusal fixture under `refusals/`

### Step 4 — the error digest and the log line through the bundled `log` (decisions 194, 195)

`error_boundary.bp` imports `log` (landed on botopink-lang `feat`); `digestOf`
(`error_boundary.bp:77`, used at `:83,89`) is deleted; `RenderHooks` keeps its shape — no
`onError`.

- [ ] `grep -n digestOf modules/jhonstart/src` is empty; `renderBoundaryChecked` calls `log`'s
      error-logging function once per caught error and writes the digest it answers into
      `ErrorInfo.digest`, the fallback markup and the payload
- [ ] `error_boundary_test.bp`: with a recording sink set, a caught error writes exactly one
      record, its digest is the one the fallback shows, and the client-visible `ErrorInfo` still
      carries no message; with no sink set the default sink receives the record
- [ ] every digest literal in the tests is the 16-hex value `log`'s known-answer fixture gives
      for the same four parts, identical on both rows
- [ ] `07-onze/49` step 3 is named in `docs.md` as the place the sink is set; no rakun type
      appears in any signature

Every digest a fallback shows changes from 8 hex to 16.

### Step 5 — `docs.md`

- [ ] `docs.md:371,393` name front 30 (this library's payload envelope), not rakun's 23; the
      other "front 23" payload mentions (`:397,784,991,1096`) read the same
- [ ] `docs.md` § The front-68 contract (`:1091`) has the starter-table row (`globals.starters`,
      `registerStarter` / `registerRouteStarters`, 29-a) and the `islandAttr(ordinal)` row reads
      "exported here; onze's entry imports it"; `07-onze/50` cites the section
- [ ] `docs.md` § Error boundaries documents the digest scheme and the `log` sink

### Step 6 — the spec examples and the eight READMEs

The three examples in [`examples/`](./examples/) are corrected here: `request-scope-example.bp`
passes every untrusted value through `escape.html` / `escape.attribute`;
`blog-post-page-example.bp` hands its two loaders to `async.runAll` as thunks;
`streamed-blog-page-example.bp` follows step 3's answer (`examples/src/**/*.bpp` show the same
pages as `.bpp` files). Each `examples/<p>/README.md` names the upstream section it mirrors and
the fronts it exercises (`modules.md` § Examples).

- [ ] the three `.bp` files compile with `botopink check` against `modules/jhonstart` (the front's
      own run, not a gate row)
- [ ] `find repository/jhonstart/examples -maxdepth 2 -name README.md | wc -l` is 8 (0 today)

### Step 7 — the module-level snapshot map (on `30-h`)

- Under (b): realise [`test-snap.md`](./test-snap.md) for every member's `test/` through
  `jhonstart-test`'s helpers, recorded by renaming `.new` files, after 27 and 67 have landed
  (this step re-records every member's directory and runs alone; ~150 files).
  - [ ] every `.snap` the map names exists, identical on both rows, no `.new` left
- Under (a) — the recommendation:
  - [ ] `AGENTS.md` § Tests says the inline literals, `helpers_test.bp`'s snapshots and the
        examples' 32 are the evidence

### Step 8 — the stage markers (decisions 186, 202)

Opens when `01-compiler/01-checker` lands the capability its `language-gaps.md` row names. This
library then declares `#[serverOnly]` and `#[clientOnly]`, marks its hooks, and validates in
`#[page]` and `#[client]` (§ Mechanism; the `#[client]` code already records comptime meta —
decision 216); `#[page]` prerenders at comptime the pages that reach no `#[serverOnly]` hook.
`markDynamic` (`router.bp:186,198,276`, `server.bp:87,254`, `streaming.bp:52,703`) goes, the
payload's `d` stops being a mark, and the build writes each route's kind. `07-onze/49` step 5 and
`04-rakun/22` step 4 delete their halves of the run-time bridge after this step.

The acceptance is written by the front when the step opens. It needs one refusal fixture under
`refusals/` per rule of decision 186 — a `#[serverOnly]` hook inside a `#[client]` component, a
`#[clientOnly]` hook outside one (no case for a page declaring itself prerendered: no such
declaration exists — decision 202) — and one page of each stage whose route kind is asserted, the
comptime one prerendered by `#[page]`.

**Gate:** standard (fronts.md § Gate) + every jhonstart member at its count or above on both rows
(core 204; `jhonstart-dom-test` commonJS only, structural — 101) · `grep -rni rakun
modules/jhonstart/src` empty and `grep -i emilia modules/jhonstart/src` still empty · `dom_test.bp`
cases are commonJS only, calling the registered functions through `callFill` / `callSignal`
