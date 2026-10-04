# Front 26 — jhonstart core tail: the core member's open items (carries 1.0.10's 28 · 29 · 30 · 31)

**Priority:** high — the boundary's digest and log line through bundled `log` (decisions 194, 195)
is what `07-onze/49` step 3 completes; "no rakun in `modules/jhonstart/src`" is a gate grep, red
today · **State:** not started
**Depends on:** `08-bpp/118` landed before opening (step 0 moves its member — decision 200), with its
carve-outs here: bracket-attribute step-1 lines (only comments of `root.bp` / `elements.bp` name the
DSL; no `[name]={` in `src/`), `src/prelude.bp` (decision 270), the `Node` declaration (decision
223) · `03-bundled-libs/102` step 3's `routes.bp` commit, landed before opening (decision 188) ·
`01-compiler/01-checker`'s capability (hooks a function activates through `use`, readable from its
`@Decl` — `language-gaps.md`) for step 8 (decision 186) · `29-a` confirmed (step 5's starter-table row)
**Owns:** `repository/jhonstart/modules/jhonstart/**` (source, tests, `src/AGENTS.md`),
`modules/jhonstart-dom-test/**` (`fake_dom.mjs`, `dom_test.bp`), `docs.md`, `AGENTS.md`,
`examples/{blog-ssr,nav-shell,islands,forms,document-shell,jhonstart-counter,jhonstart-markup,jhonstart-todo}/README.md`
· step 0 only: deleting `modules/jhonstart-html/`, the workspace manifest's member list, the import
lines of `jhonstart-emilia`, `examples/jhonstart-markup`, `examples/document-shell` (decision 200) ·
this directory
**Does not touch:** `modules/jhonstart-link/**` (27) · `modules/jhonstart-forms/**`,
`examples/forms/src/**` (67) · `src/html.bp` and its tests after step 0 (`08-bpp/118`'s, then one
lowering arm each from 119, 120, 126) · `element.bp`, `hooks.bp` (frozen) · `html_attrs.bp`
(`06-emilia`) · `routes.bp`'s `page` segment walk (`:233-251`, `03-bundled-libs/102-routing-conventions`)
· `render.bp:539` `isLangTag` (`105-i18n`) · `libs/log/**` (`106-log`; called here) ·
`examples/*/botopink.json` `targets` · after landing, one front at a time: `08-bpp`'s files in this
member (116's `bpp.bp`; 120's `island_strategy.bp`, `deferred.bp` and its lines of `client.bp`,
`render.bp`, `island_runtime.mjs`; 122's `response.bp` and its lines of `server.bp`,
`error_boundary.bp`) and `fake_dom.mjs`'s additions (120, then 126 — a front owns the test file it
adds to `jhonstart-dom-test`; `fake_dom.mjs` stays this front's, decision 189)

## Goal

The core holds `html` as its default function (no `jhonstart-html`), names no rakun in `src/`,
handles a late navigation signal in one function, digests and logs a caught error through bundled
`log`, has the missing streaming cases, a `docs.md` naming the right fronts, corrected spec
examples, eight example READMEs — and, after the checker capability, knows a page's stage at compile
time (no run-time `markDynamic`).

## Mechanism

- **The grep.** Every rakun mention is a comment explaining a shape by analogy (`router.bp:59`
  "`headerOfPage` in rakun's `ssr.bp` is the shape"); none is an import. Fix: state the shape, not
  the neighbour.
- **Two signal handlers.** `registerSignal(name, allowedRedirects)` in `render.mjs` installs what a
  `data-jh-g` template's script calls; `clientApp` handles a raise via `handleSignal` in
  `client_app.bp`. Both decide "relative → `history.replaceState` + `popstate`; absolute → only if
  allowed; hop limit". Shape: one core-exported function called from both; the `.mjs` half calls it
  through the registry.
- **The digest** (decision 194): `errorDigest(module, errorClass, message, topFrames)` of bundled
  `log` — 16 hex of `strongHash` over the four parts, frames normalised. The boundary calls `log`'s
  error-logging function once per caught error; it writes the record through the injected sink and
  answers the digest, which goes into payload and fallback (fallback digest = log line's).
  `digestOf` deleted, no `RenderHooks.onError` (decision 195). `log` imported like `routing` and
  `actions`; no framework import; rakun-logging reaches it only as onze's installed sink; no sink set
  → default sink receives the record.
- **A page's stage (decisions 186, 202).** Stages: comptime (build, prerender), server (request
  time), client (browser). Unmarked hook: any stage; `#[serverOnly]` → request time; `#[clientOnly]`
  → browser. This library declares both markers and marks its hooks (`searchParams`, `cookies`,
  `headers`, `request` are `#[serverOnly]`); `#[page]` and `#[client]` read the hooks their function
  activates through `use`, transitively, and refuse at compile time, located at the `use`: a
  `#[serverOnly]` hook in a `#[client]` component, a `#[clientOnly]` hook outside one. No page
  declares its stage: `#[page]` (`routes.bp:220`) prerenders at comptime a page reaching no
  `#[serverOnly]` hook, else renders per request. The build writes the kind into `routing`'s `k`
  blob; `markDynamic` and the payload's `d` as a run-time mark go.

## Open

### Step 0 — `jhonstart-html` merges into the core (decision 200)

After `08-bpp/118` landed in `jhonstart-html`. `src/html.bp` and the member's tests move into
`modules/jhonstart`; `html` becomes the core's `pub default fn`
(`import html, {Element, renderToString} from "jhonstart";`); member deleted (decision 187's
criterion: a module every consumer needs is not its own member). Consumers `jhonstart-emilia`,
`examples/jhonstart-markup`, `examples/document-shell` import from the core. Code moves, no
behaviour change; `08-bpp/116` (`"bpp": "jhonstart"`) and later `html.bp` appends (119, 120, 126)
are written against it.

Acceptance written when the step opens: member gone, its tests in the core's cell on both rows,
`grep -rn '"jhonstart-html"' repository/jhonstart --exclude=CHANGELOG.md` empty (today also hits
`docs.md`, `README.md`, `AGENTS.md`, `jhonstart-emilia`'s manifest and bridge test, the two examples).

### Step 1 — the core's `src/` names no rakun

Reword the 26 lines of JH-30-4 (`../README.md` § What jhonstart still owes) to state the shape
without the neighbour (`streaming.bp:18` "a `Response` onze built over rakun's `ChunkWriter`" → "a
`Response` the host built over its chunk writer"; `router.bp:164` explains a target profile that no
longer exists).

- [ ] `grep -rni rakun repository/jhonstart/modules/jhonstart/src` (covers `sidecars/`) is empty;
      the same grep over `modules/jhonstart-link/src`, `modules/jhonstart-forms/src` reported (2
      lines today; not edited: 27's and 67's)
- [ ] `bridge_test.bp` gains "bridge: no file of the core's src names rakun", twin of its emilia
      case, green on both rows

### Step 2 — one late-signal handler

`client_app.bp` exports `applyLateSignal(site: ClientApp, reason: string, hops: i32)` (body of
`handleSignal`, `client_app.bp:219`); `render.mjs`'s `registerSignal` (`:199`) installs a closure
calling it through the registry (`globals().signal` stays the entry; `data-jh-g` markup unchanged).

- [ ] `render.mjs` makes no `replaceState` call (today `:213`); the relative redirect goes through
      `applyLateSignal` and the router's `replace` (`router_runtime.mjs`), so
      `grep -n "replaceState(" render.mjs client_app.mjs` prints nothing
- [ ] `dom_test.bp`: a `data-jh-g="redirect"` template with target `/x` and a raised
      `redirect("/x")` leave the same `history` and `location` records; an absolute target not in
      `allowedRedirects` refused by both with the same message; hop limit trips at the same count
- [ ] `client_app_test.bp` and `streaming_test.bp` unchanged in count

### Step 3 — the streaming boxes

- [ ] `streaming_test.bp` "stream: a boundary resolved before the shell produces no hole and no
      fill" — shell carries the resolved markup inline, `chunks.length == 1`, both rows
- [ ] sibling server components gathered through std `async.runAll` over unstarted thunks
      (`Array<fn() -> @Task<T>>`), `__jhEachCompleted` (`streaming.bp:136,810,834`) deleted — or,
      if the render's gatherer must stay (fills holes in completion order, which `runAll` does not
      report), `render.bp` states why in one comment and the box is ticked with that reason
- [ ] `streaming_test.bp` "stream: two 50 ms sibling loaders finish in under 100 ms" on
      `--target erlang` (spawned per task) and the same test on commonJS
- [ ] "stream: an already-started `@Task` handed as a sibling is refused" — render takes thunks
      only (the type refuses a started task), asserted by a `check` refusal fixture under `refusals/`

### Step 4 — the error digest and the log line through the bundled `log` (decisions 194, 195)

`error_boundary.bp` imports `log` (on botopink-lang `feat`); `digestOf` (`error_boundary.bp:77`,
used at `:83,89`) deleted; `RenderHooks` keeps its shape — no `onError`.

- [ ] `grep -n digestOf modules/jhonstart/src` is empty; `renderBoundaryChecked` calls `log`'s
      error-logging function once per caught error and writes the answered digest into
      `ErrorInfo.digest`, the fallback markup and the payload
- [ ] `error_boundary_test.bp`: with a recording sink set, a caught error writes exactly one record
      whose digest the fallback shows, client-visible `ErrorInfo` still carries no message; with no
      sink set the default sink receives the record
- [ ] every test digest literal is the 16-hex value of `log`'s known-answer fixture for the same
      four parts, identical on both rows
- [ ] `docs.md` names `07-onze/49` step 3 as where the sink is set; no rakun type in any signature

Every fallback digest changes from 8 hex to 16.

### Step 5 — `docs.md`

- [ ] `docs.md:371,393` name front 30 (this library's payload envelope), not rakun's 23; the other
      "front 23" payload mentions (`:397,784,991,1096`) likewise
- [ ] `docs.md` § The front-68 contract (`:1091`) has the starter-table row (`globals.starters`,
      `registerStarter` / `registerRouteStarters`, 29-a); the `islandAttr(ordinal)` row reads
      "exported here; onze's entry imports it"; `07-onze/50` cites the section
- [ ] `docs.md` § Error boundaries documents the digest scheme and the `log` sink

### Step 6 — the spec examples and the eight READMEs

[`examples/`](./examples/) corrected: `request-scope-example.bp` passes every untrusted value
through `escape.html` / `escape.attribute`; `blog-post-page-example.bp` hands its two loaders to
`async.runAll` as thunks; `streamed-blog-page-example.bp` follows step 3's answer
(`examples/src/**/*.bpp` show the same pages as `.bpp`). Each `examples/<p>/README.md` names the
upstream section mirrored and fronts exercised (`modules.md` § Examples).

- [ ] the three `.bp` files compile with `botopink check` against `modules/jhonstart` (front's own
      run, not a gate row)
- [ ] `find repository/jhonstart/examples -maxdepth 2 -name README.md | wc -l` is 8 (0 today)

### Step 7 — the module-level snapshot map

→ 20-snap (front 135) step 3

### Step 8 — the stage markers (decisions 186, 202, 277, 278)

Opens when `01-compiler/01-checker` step 23 lands `Decl.hooks` (decision 277). The library reads the
list against its own decorators; the compiler names no marker.

- [ ] `src/stage.bp` (new): `pub fn serverOnly(comptime decl: @Decl) {}`, `pub fn clientOnly(comptime
      decl: @Decl) {}` (markers, no output); `HookPath(through, use)`; `pathsTo(nodes, marker,
      unknownToo = false)` breadth-first over `decl.hooks`, every path, each the shortest;
      `viaText`, `crossesClient`
- [ ] hooks marked: `#[serverOnly]` on `cookies`, `headers`, `request` (`server.bp`), `searchParams`
      (`router.bp`); `#[clientOnly]` on the browser-only hooks; `state`, `effect`, `memo`, `ref`,
      `reducer` unmarked
- [ ] `#[page]` (`routes.bp`): `setMeta("seg", …)`; a `#[clientOnly]` path not crossing a `#[client]`
      refused at its `use`; `setMeta("kind", "D")` when a `#[serverOnly]` or a `hook: null` path
      exists, else `"S"`; `setMeta("why", …)` naming the hook and the chain
- [ ] `#[client]` (`client.bp`): every `#[serverOnly]` path refused at its `use`, naming the chain
      (`via UserMenu → Avatar`)
- [ ] `markDynamic` (`router.bp:186,198,276`), its import and call (`server.bp:87,254`) and
      `streaming.bp:52,703` deleted; the payload's `d` is no longer a mark
- [ ] `refusals/`: a `#[serverOnly]` hook reached by a `#[client]` component (directly and through a
      child), a `#[clientOnly]` hook outside one; `run/`: one page per kind — `S` prerendered by
      `#[page]`, `D` per request — with its kind asserted, and one reaching a hook through a function
      value (`D`)
- [ ] `AGENTS.md` describes the two markers, who reads them and `pathsTo`; `clientOnly` is also the
      tag annotation (278) — `08-bpp/120` step 1 gives it `-> Hydrate` and reads `pathsTo` from the
      `html` arm, so both stay `pub` and importable by the prelude

### Step 9 — references, not strings (decision 281)

- [ ] event handlers as `#[onClick(like)]` (a function value; 278 + 280 example 7) — no
      `data-jh-on-click="LikeButton:like"`, no `"error:reset"`; the runtime binds by position

### Step 10 — file roles are the framework's (decision 285)

- [ ] `page`, `layout`, `template`, `loading`, `error`, `notFound` callable as comptime functions over
      a function value (`page("blog/[slug]", f)`), with the decorator form's checks (the stage
      markers of step 8, the return `View`) — the decorator form stays for hand-written `.bp` routes

**Gate:** standard (fronts.md § Gate) + every jhonstart member at its count or above on both rows
(core 204; `jhonstart-dom-test` commonJS only, structural — 101) · `grep -rni rakun
modules/jhonstart/src` empty and `grep -i emilia modules/jhonstart/src` still empty · `dom_test.bp`
cases commonJS only, calling registered functions through `callFill` / `callSignal`
