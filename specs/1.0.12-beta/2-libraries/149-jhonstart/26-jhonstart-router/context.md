# Front 26 — jhonstart core tail: the core member's open items (carries 1.0.10's 28 · 29 · 30 · 31)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [149-jhonstart](../README.md): s0 → 149 s1 · s1 → 149 s1 · s2 → 149 s1 · s3 → 149 s1 · s4 → 149 s1 · s5 → 149 s1 · s6 → 149 s1 · s8 → 149 s1 · s9 → 149 s1 · s10 → 149 s1 · s11 → 149 s1 · s12 → 149 s1 · s13 → 149 s1. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — the boundary's digest and log line through bundled `log` (decisions 194, 195)
is what `07-onze/49` step 3 completes; "no rakun in `modules/jhonstart/src`" is a gate grep, red
today · **State:** not started
**Depends on:** `08-bpp/118` landed before opening (step 0 moves its member — decision 200), with its
carve-outs here: bracket-attribute step-1 lines (only comments of `root.bp` / `elements.bp` name the
DSL; no `[name]={` in `src/`), `src/prelude.bp` (decision 270), the `Node` declaration (decision
223) · `03-bundled-libs/102` step 3's `routes.bp` commit, landed before opening (decision 188) ·
`01-compiler/01-checker`'s capability (hooks a function activates through `use`, readable from its
`@Decl` — `language-gaps.md`) for step 8 (decision 186) · `29-a` (reduced: `registerRouteStarters` +
`globals.starters`) for step 5's starter-table row
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
  → browser. This library declares both markers and marks its hooks (`searchParams`, `cookie`
  (294), `headers`, `request`, `response` (291) are `#[serverOnly]`); `#[page]` and `#[client]` read
  the hooks their function activates through `use`, transitively (277), and refuse at compile time,
  located at the `use`: a `#[serverOnly]` hook in a `#[client]` component, a `#[clientOnly]` hook
  outside one — the two refusals only (186's third, "a page that declares itself prerendered", has
  no case under 202: `ctr-l`, only the record is missing). No page
  declares its stage: `#[page]` (`routes.bp:220`) prerenders at comptime a page reaching no
  `#[serverOnly]` hook, else renders per request. The build writes the kind into `routing`'s `k`
  blob; `markDynamic` and the payload's `d` as a run-time mark go.
