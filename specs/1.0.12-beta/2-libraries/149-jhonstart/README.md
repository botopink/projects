# Front 149 — jhonstart: the core, link, forms, and Astro's template, styling, islands, data and transitions

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Owns:** `repository/jhonstart/**`
**Depends on:** 144 B-07 (26 s14), B-14 (118 s1), B-15 (118 s4–5, 119), B-16 (26 s13), B-17 (26 s8, s11), B-27 (116), B-10 G3
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

Order: 26 → 27 → 67 → 118's residue → 119's jhonstart half → 120 → 122 → 126 (the chains 118 → 26 → 67 → 127
and 118 → 119 → 120 → 126). Consumer commits it receives: B-02, B-07, B-08 (12), B-20 (129's imports).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `26-jhonstart-router` s0 | 149 s1 |
| `26-jhonstart-router` s1 | 149 s1 |
| `26-jhonstart-router` s2 | 149 s1 |
| `26-jhonstart-router` s3 | 149 s1 |
| `26-jhonstart-router` s4 | 149 s1 |
| `26-jhonstart-router` s5 | 149 s1 |
| `26-jhonstart-router` s6 | 149 s1 |
| `26-jhonstart-router` s8 | 149 s1 |
| `26-jhonstart-router` s9 | 149 s1 |
| `26-jhonstart-router` s10 | 149 s1 |
| `26-jhonstart-router` s11 | 149 s1 |
| `26-jhonstart-router` s12 | 149 s1 |
| `26-jhonstart-router` s13 | 149 s1 |
| `27-jhonstart-link` s1 | 149 s2 |
| `27-jhonstart-link` s2 | 149 s2 |
| `67-jhonstart-forms` s1 | 149 s3 |
| `67-jhonstart-forms` s2 | 149 s3 |
| `67-jhonstart-forms` s3 | 149 s3 |
| `67-jhonstart-forms` s4 | 149 s3 |
| `67-jhonstart-forms` s5 | 149 s3 |
| `118-bpp-components` open | 149 s4 |
| `118-bpp-components` gate | 149 s4 |
| `119-bpp-styling` s2 | 149 s5 |
| `119-bpp-styling` s3 | 149 s5 |
| `119-bpp-styling` s4 boxes 1, 3, 5 | 149 s5 |
| `119-bpp-styling` s5 | 149 s5 |
| `120-bpp-islands` s0 | 149 s6 |
| `120-bpp-islands` s1 | 149 s6 |
| `120-bpp-islands` s2 | 149 s6 |
| `120-bpp-islands` s3 | 149 s6 |
| `120-bpp-islands` s4 | 149 s6 |
| `120-bpp-islands` s5 | 149 s6 |
| `120-bpp-islands` s6 | 149 s6 |
| `120-bpp-islands` s7 | 149 s6 |
| `120-bpp-islands` gate | 149 s6 |
| `122-bpp-data` s0 box 2 | 149 s7 |
| `122-bpp-data` s1 | 149 s7 |
| `122-bpp-data` s2 | 149 s7 |
| `122-bpp-data` s4 | 149 s7 |
| `122-bpp-data` s5 | 149 s7 |
| `126-bpp-view-transitions` s1 | 149 s8 |
| `126-bpp-view-transitions` s2 | 149 s8 |
| `126-bpp-view-transitions` s3 | 149 s8 |
| `126-bpp-view-transitions` s4 | 149 s8 |
| `116-bpp-file-format` s6 | 149 s9 |
| `20-snap` s3 | 149 s10 |

## Steps

### 149 s1 — the core (26)

#### Step 0 — `jhonstart-html` merges into the core (decision 200) (was `26-jhonstart-router` s0)

After `08-bpp/118` landed in `jhonstart-html`. `src/html.bp` and the member's tests move into
`modules/jhonstart`; `html` becomes the core's `pub default fn`
(`import html, {Element, renderToString} from "jhonstart";`); member deleted (decision 187's
criterion: a module every consumer needs is not its own member). Consumers `jhonstart-emilia`,
`examples/jhonstart-markup`, `examples/document-shell` import from the core. Code moves, no
behaviour change; `08-bpp/116` (`"bpp": {"default": "jhonstart"}`, decision 338) and later `html.bp` appends (119, 120, 126)
are written against it.

Acceptance written when the step opens: member gone, its tests in the core's cell on both rows,
`grep -rn '"jhonstart-html"' repository/jhonstart --exclude=CHANGELOG.md` empty (today also hits
`docs.md`, `README.md`, `AGENTS.md`, `jhonstart-emilia`'s manifest and bridge test, the two examples).

#### Step 1 — the core's `src/` names no rakun (was `26-jhonstart-router` s1)

Reword the 26 lines of JH-30-4 (`../README.md` § What jhonstart still owes) to state the shape
without the neighbour (`streaming.bp:18` "a `Response` onze built over rakun's `ChunkWriter`" → "a
`Response` the host built over its chunk writer"; `router.bp:164` explains a target profile that no
longer exists).

- [ ] `grep -rni rakun repository/jhonstart/modules/jhonstart/src` (covers `sidecars/`) is empty;
      the same grep over `modules/jhonstart-link/src`, `modules/jhonstart-forms/src` reported (2
      lines today; not edited: 27's and 67's)
- [ ] `bridge_test.bp` gains "bridge: no file of the core's src names rakun", twin of its emilia
      case, green on both rows

#### Step 2 — one late-signal handler (was `26-jhonstart-router` s2)

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

#### Step 3 — the streaming boxes (was `26-jhonstart-router` s3)

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

#### Step 4 — the error digest and the log line through the bundled `log` (decisions 194, 195) (was `26-jhonstart-router` s4)

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

#### Step 5 — `docs.md` (was `26-jhonstart-router` s5)

- [ ] `docs.md:371,393` name front 30 (this library's payload envelope), not rakun's 23; the other
      "front 23" payload mentions (`:397,784,991,1096`) likewise
- [ ] `docs.md` § The front-68 contract (`:1091`) has the starter-table row: the per-route loaders
      `registerRouteStarters(pattern, load)` over `globals.starters` (29-a, reduced); no per-name
      `registerStarter` — 281 builds the starter table at comptime (`@TypeInfo.all(with: client)`,
      `08-bpp/120` step 6, `07-onze/53` step 7); the `islandAttr(ordinal)` row reads
      "exported here; onze's entry imports it"; `07-onze/50` cites the section
- [ ] `docs.md` § Error boundaries documents the digest scheme and the `log` sink

#### Step 6 — the spec examples and the eight READMEs (was `26-jhonstart-router` s6)

[`examples/`](26-jhonstart-router/examples) corrected: `request-scope-example.bp` passes every untrusted value
through `escape.html` / `escape.attribute`; `blog-post-page-example.bp` hands its two loaders to
`async.runAll` as thunks; `streamed-blog-page-example.bp` follows step 3's answer
(`examples/src/**/*.bpp` show the same pages as `.bpp`). Each `examples/<p>/README.md` names the
upstream section mirrored and fronts exercised (`modules.md` § Examples).

- [ ] the three `.bp` files compile with `botopink check` against `modules/jhonstart` (front's own
      run, not a gate row)
- [ ] `find repository/jhonstart/examples -maxdepth 2 -name README.md | wc -l` is 8 (0 today)
- [ ] `examples/request-scope-example.bp` rewritten to decision 294 (the locale cookie a
      `Cookie<string>` declared once, read with `use cookieValue(decl)`; no `RequestData.cookies` pairs,
      no `pairValue`)

#### Step 8 — the stage markers (decisions 186, 202, 277, 278) (was `26-jhonstart-router` s8)

Opens when `01-compiler/01-checker` step 23 lands `Decl.hooks` (decision 277). The library reads the
list against its own decorators; the compiler names no marker.

- [ ] `src/stage.bp` (new): `pub fn serverOnly(comptime decl: @Decl) {}`, `pub fn clientOnly(comptime
      decl: @Decl) {}` (markers, no output); `HookPath(through, use)`; `pathsTo(nodes, marker,
      unknownToo = false)` breadth-first over `decl.hooks`, every path, each the shortest;
      `viaText`, `crossesClient`
- [ ] hooks marked: `#[serverOnly]` on `cookie` (294), `headers`, `request`, `response` (291; `server.bp`), `searchParams`
      (`router.bp`); `#[clientOnly]` on the browser-only hooks; `state`, `effect`, `memo`, `ref`,
      `reducer` unmarked
- [ ] `#[page]` (`routes.bp`): `setMeta(PageMeta(seg, kind, why))` (298; `RouteKind { S, D }`); a
      `#[clientOnly]` path not crossing a `#[client]` refused at its `use`; `kind: .D` when a
      `#[serverOnly]` or a `hook: null` path exists, else `.S`; `why` naming the hook and the chain;
      read `@typeInfo(Page).meta(PageMeta)`
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

#### Step 9 — references, not strings (decision 281) (was `26-jhonstart-router` s9)

- [ ] event handlers as `#[onClick(like)]` (a function value; 278 + 280 example 7) — no
      `data-jh-on-click="LikeButton:like"`, no `"error:reset"`; the runtime binds by position

#### Step 10 — file roles are the framework's (decision 285) (was `26-jhonstart-router` s10)

- [ ] `#[page]` (and its function form) takes `revalidate: ?Duration = null`, `headers: #(string,
      string)[] = []` (a fixed header of an `S` page, 291) and `dynamicParams: bool
      = true` beside `paths:` / `head:` / `partial:` (282, 290) and records them in its meta; no other
      route configuration exists
- [ ] `page`, `layout`, `template`, `loading`, `error`, `notFound` callable as comptime functions over
      a function value (`page("blog/[slug]", f)`), with the decorator form's checks (the stage
      markers of step 8, the return `View`) — the decorator form stays for hand-written `.bp` routes

#### Step 11 — route parameters and page data are hooks (decision 293) (was `26-jhonstart-router` s11)

- [ ] `use params<P>()` and `use pageData<D>()` (`routes.bp`), unmarked — known at build for a
      prerendered page, so neither makes a page `D`; `searchParams` stays `#[serverOnly]`
- [ ] a page function takes no parameter: `#[page]` and its function form expect `fn() -> View`;
      `route: PageContext` and `paramsOf(…seg, route)` (236) go
- [ ] `#[page]` checks every `use params<P>()` its `Decl.hooks` reach: `P`'s fields are the pattern's
      segments, each parsed to its field's type (`id: i32` → `/produto/abc` answers 404 without
      rendering); every `use pageData<D>()` matches `paths:`'s `D`; a mismatch refused at the page,
      naming the chain (`via BlogPost → Breadcrumb`)
- [ ] the examples of this track rewritten (`route.params.lookup(…)`, `PageContext` parameters)

#### Step 12 — a cookie is declared once, typed (decision 294) (was `26-jhonstart-router` s12)

- [ ] `use local(atom: Atom<T>) -> ?T` (295; `Local<T>` is cardume's `Atom<T>`, 296), jhonstart's own
      hook, `#[serverOnly]` by jhonstart's marker (277) beside `cookie` — the value middleware set for
      this request, held in `rakun-cardume`'s store per request (296; `08-j` closed by 295)
- [ ] `use cookieValue(decl: Cookie<T>) -> ?T`, `#[serverOnly]` (186): `null` when absent or undecodable;
      the jar (`use cookies()` → pairs) and `pairValue` go from page code; a render writes no cookie (122)

#### Step 13 — the native builders in props form (decision 362) (was `26-jhonstart-router` s13)

After step 0, `01-checker` s28 and the props-filling lowering (**Template-built code cannot build an
inline props type**):

```bp
pub val AnchorProps = Type.merge(Type.merge(GlobalAttrs, AriaAttrs), AnchorAttrs);
pub fn a(props: AnchorProps) -> Element { return el("a", props.children, attrsOf(props)); }
// markup:     <a hreff="/x">  →  error: `a` has no field `hreff`, at the attribute
// by hand:    a(AnchorProps(href: "/", children: ["Home"]))
```

- [ ] every builder of `elements.bp` and `element.bp`'s eight (unfrozen for this step) takes its
      element's props record — `GlobalAttrs`, `AriaAttrs`, the element's own, layered with
      `Type.merge`; content in the props' `children` (360); a void element's props have none
- [ ] 351's refusals at build: an unknown attribute, a value of the wrong type, content in a void
      element, a tag the `#[bpp.htmlPrelude]` module does not name (361); the element spread typed (359)
- [ ] the 78 hand-written callers rewritten in the same landing — jhonstart 51, onze 27, a consumer
      commit per library (188); the `(children, attrs:)` form gone, `el(…)` the escape hatch
- [ ] 118 step 1's handed box closed against this step

### 149 s2 — link: the reconciler driver (27)

#### Step 1 — the driver (was `27-jhonstart-link` s1)

`reconcile.bp`'s `applyTransition(current, target, dom: DomOps) -> @Task<@Result<Navigation,
string>>`; `DomOps` is a record of the entry's six functions (`markup(href)`,
`replaceSubtree(depth, html)`, `startIslands(depth)`, `mountCount(name)`, `scrollTo(depth)`,
`markPending(href, pending)` — `27-b` ★) — pure, testable without a document. Additive: the entry
(`07-onze/50` step 6) adopts it in its own step.

- [ ] a transition to a route of a different kind (`k` flag differs) reads the flag from the target
      payload through `routing.routeKindOf`; `grep -n "kindOf\|routeKind" reconcile.bp` shows one
      call, no recomputation (waits until `04-rakun/22`'s flag is in the payload; the driver reads
      `k` as the router already does)
- [ ] 1.0.10's DoD box "the reconciler decides remount vs re-render" re-ticked only when both cases
      above are green on both rows (the driver is pure; no erlang twin — 363)
- [ ] `sidecars/jhonstart_link.erl` deleted; `linkStatus` declared `#[clientOnly]` (186, 363); the
      member's erlang build emits neither the hook nor its cell

#### Step 2 — `use linkStatus()` only in the client (decisions 354, 363) (was `27-jhonstart-link` s2)

Opens when `05-jhonstart/26` step 8 lands `#[clientOnly]` (`src/stage.bp`) over `01-checker` step
23's `Decl.hooks` (`language-gaps.md`, "A function's `@Decl` does not say which hooks it
activates").

- [ ] `refusals/`: `use linkStatus()` in a component that is not `#[client]` refused at the `use`
      (186's check, 363)

### 149 s3 — forms: the DOM-side boxes (67)

#### Step 1 — `actionState` in the document (was `67-jhonstart-forms` s1)

- [ ] `forms_dom_test.bp` "forms: fieldError after an envelope": with `fetch` answering
      `writeEnvelope(ok: false, state: writeState("…", [#("title", "Too short")]))`, submitting the
      create-post form leaves `fieldError("title") == "Too short"` in the re-rendered form
- [ ] "forms: ok:false re-renders in place": same submit keeps the typed `title`, enters no boundary
      (`data-jh-e` absent after), form element identity unchanged (`===` on the recorded node)

#### Step 2 — `formStatus` for two forms (was `67-jhonstart-forms` s2)

- [ ] "forms: pending is per form": two forms submitted with `fetch` held open — each button's
      `pending` is `true`, its `actionId` its own form's; resolving one leaves the other pending

#### Step 3 — `optimistic` (was `67-jhonstart-forms` s3)

- [ ] "forms: commit and roll-back are one path": a like with `push(+1)` shows `n+1` before the
      envelope; an `ok: true` envelope carrying `n+1` and an `ok: false` one carrying `n` both end in
      `optimistic()` equal to the envelope's value, recorded actions empty — two tests, same final
      assertion
- [ ] "forms: a late push records against the next submit": `push` after the envelope leaves the
      settled value and one recorded action for the next submit

#### Step 4 — the wire names are handed in (was `67-jhonstart-forms` s4)

- [ ] `form_test.bp`, `examples/forms/src/like.bp`, `examples/forms/src/main.bp`,
      `examples/forms/test/forms_test.bp` take field and header names from a fixture
      (`stubWireNames()` in `jhonstart-test/harness.bp`, values unequal to onze's defaults) through
      `setWireNames`; the four `examples/forms` snapshots carrying the field name re-record
      (renaming the `.new` files); `grep -rn "__bp_action\|X-Bp-Action" repository/jhonstart` is empty
- [ ] `07-onze/49`'s last box for the jhonstart side is closable on that grep

#### Step 5 — the examples (was `67-jhonstart-forms` s5)

[`examples/create-post-form-example.bp`](67-jhonstart-forms/examples/create-post-form-example.bp) and
[`optimistic-like-example.bp`](67-jhonstart-forms/examples/optimistic-like-example.bp) are the shapes steps 1–3
assert (`examples/src/**/*.bpp` show them as `.bpp`); corrected here if the surface moves. Neither
carries a `// LANGUAGE GAP` marker.

- [ ] `botopink check` over both against `modules/jhonstart-forms` passes

**Gate:** standard (fronts.md § Gate) + `jhonstart-forms` at 15 or above on both rows;
`jhonstart-dom-test` on commonJS with the new file; `examples/forms` green on both rows with its
four re-recorded snapshots

### 149 s4 — the template language's residue (118)

What 118 built alone is done; each item below waits on the 144 step it names: s1's component spread (B-14),
s4's slots and s5's 302 arm (B-15), s6's `-> @ExprCustom<View>` and the `@Component` alias (B-10 G3), the
`@ExprCustom` LSP snapshot (B-27), native props (149 s1, 26 s13, 362).

#### Open (was `118-bpp-components` open)

- Step 1 — native-tag props: **handed to `05-jhonstart/26` step 13 (decision 362)**; 118 lands with
  351's html-side rules (names, `data-*`, `onClick` refused, no pair spread on an element). What 26
  builds (351 (1), (2), (4), (5)): each builder takes its element's
  props record (`GlobalAttrs`, `AriaAttrs` and the element's own, layered with `Type.merge`), lowered
  as a component tag, so an unknown attribute, a value of the wrong type and content in a void
  element are refused; a tag the prelude does not name refused at the tag; the element spread takes
  the element's props type. Blocked three ways, measured on botopink-lang `56d4bc29`:
  `pub val AnchorProps = Type.merge(GlobalAttrs, AnchorAttrs);` used as a parameter type is
  `'AnchorProps' is a value, not a type` (`01-checker` s28); a named props record is filled by no
  labelled call (`<anchor href="/x">` → `'anchor' expects 1 argument(s), got 2`, by hand too —
  **Template-built code cannot build an inline props type**, `01-checker`); the builders are
  `element.bp` (frozen) and `elements.bp` (`05-jhonstart/26`'s, which opens after 118) — 362 gives the rewrite to 26.
  `html`'s `lookup` answers `(name, kind)`, so a prelude builder and a local function of the same
  name are one to it (4).
- Slots on a component — decision 360 (step 4). Spread on a component — decision
  359 (`<Card {...p} featured />` is `CardProps(...p, featured: true)`), step 1, on `01-checker` step 34.
- Step 4 — slots as 360: `<Slot />`, `<Slot name="x">fallback</Slot>`, a child `#[slot("x")]`,
  `<Fragment #[slot("x")]>`, the transfer `<Slot name="x" #[slot("x")] />` through two layouts,
  `use hasSlot("x")`; `Slot` and `slot` are jhonstart functions with `comptime` parameters in
  302's shape (`slot(comptime decl: @Decl, comptime name: string)`), `html` reading their metas —
  on `01-compiler/130` step 9 (a tag's `@Decl`), as step 5; a slot name the component does not write and content for an absent default slot
  refused at the child; lowercase `<slot>` the native element; the hidden slot argument. The props
  as one record (192, `props: type(…)`, 207) still wait on **Template-built code cannot build an
  inline props type** (`01-checker`); slots no longer do.
- Step 5 — the 302 arm (build a tag's `@Decl`, call every annotation, read its meta by type; two
  annotations in order on `<Carousel>`; an argument of the wrong type at the argument): **A tag
  annotation cannot be called by the template function** (`01-compiler/130` step 9). The box "an
  annotation whose first parameter is `@Decl` written on an element fails" is 278's, replaced by 302
  (every annotation takes `@Decl`; on a tag its `kind` says element or component).
- Step 6 — the language server's `@ExprCustom` snapshot: hand-off to `01-compiler/26`. `html`
  declared `-> @ExprCustom<View>`: **A template function declared `-> @ExprCustom<View>` refuses
  built code of type `Element`**, and **A type alias of `@Component<…>` is not the effect in a
  return** (`01-checker`). `#[client]` comparing the resolved type: hand-off to `05-jhonstart/26`
  (decision 276 names it).
- Gate: `zig build test-libs` over jhonstart, emilia, erika, onze is the coordinator's cold gate.

#### Gate additions (was `118-bpp-components` gate)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test --target commonJS` and `--target erlang` green in `modules/jhonstart-html`
- [ ] `zig build test-libs`: jhonstart, emilia, erika, onze — the 12 DSL files — green

### 149 s5 — `jhonstart-styled`, the template arm, one sheet (119, jhonstart's half)

#### Step 2 — `jhonstart-styled` and the template arm (was `119-bpp-styling` s2)

- [ ] new member `jhonstart-styled`: its `pub default fn` over the section text → scoped
      `StyledView`; the scope id from `q.source()`; constant and run-time holes as § Mechanism
- [ ] `html.bp`: a `use` of a scoped style in the function's hooks → `data-s` on every element the
      function's template writes; two `use`s → two attributes; `<style #[isInline]>` accepted —
      the arm before 118's refusal of every other `<style>` (`refusals/html_style_element`)
- [ ] `examples/scoped-style-example.bp` passes on both targets
- [ ] two components both writing `.title` render two rules and two attributes; neither rule
      matches the other's element — asserted on the rendered document with a `jhonstart-dom-test` selector matcher
- [ ] a parent's style does not reach a child component's own elements
- [ ] a component rendered twenty times registers its sheet once — `compose` provides
      `StyledContext` (`jhonstart/src/styled_sheet.bp`, written with step 1, held: § State); below an
      `error` / `not-found` segment and in a `Suspense` fill too, once a `@Component` thunk a host cell
      calls is run by jhonstart's renderer with the scope it kept (388, `01-compiler/134` step 6)
- [ ] head order: `<link>`, emilia's layers, scoped styles
- [ ] a run-time hole's value containing `;` or `}` is escaped in the root's `style`; the test injects one

#### Step 3 — A streamed boundary's styles (was `119-bpp-styling` s3)

A component first rendered in a `Suspense` fill needs its sheet in that fill.

- [ ] a boundary's fill carries the scoped sheet of a component the shell did not render, as
      emilia's flush does today (`jhonstart-emilia/src/root.bp:95`)
- [ ] jhonstart's renderer keeps the boundary's scope with its child and runs it in the fill with
      `child.run(scope)` (388), so a fill reads `StyledContext` and every provider above the boundary

#### Step 4 — `#[styled(..)]` in `jhonstart-styled`, and the reader of `#[emilia(..)]`'s meta (decisions 301, 338, 369) — part (was `119-bpp-styling` s4 boxes 1, 3, 5)

- [ ] `jhonstart-styled` declares `pub fn styled(comptime decl: @Decl, comptime ..items: Styleable[])`
      — no return (302): it records `decl.addMeta(ClassName(names: […]))`; `ClassName(names:
      string[])` is jhonstart's (the core; `html` merges every `ClassName` meta into the tag's `class`,
      after a static `class`); `html` names no emilia or `styled` (113)
- [ ] the item list is comptime (280): its order is the class's identity (`contracts.md` § 4) by
      construction; class and rules computed at build once `hashHex` is std's pure
      `hash.contentHash` (`06-emilia/34` step 1) — this makes `68-d` (the bundler's styleMap probe)
      moot (301)
- [ ] `class={emilia(tokens)}` leaves markup: refused in a template, naming `#[emilia(…)]` (369: emilia
      has no run-time entry point); a style chosen at run time picks among annotated branches
      (`{if (urgent) { <p #[emilia(.Color.Red.600)]>…</p> } else { … }}`)

#### Step 5 — one sheet; `jhonstart-emilia` deleted (after `06-emilia/34` step 5) (was `119-bpp-styling` s5)

- [ ] emilia's components are `styled` components, written by `jhonstart-styled`'s sink with the
      scoped styles — one `<style>` in the head; payload key `s` and the boundary fill carry it;
      `07-onze/53`'s "exactly one non-empty `<style>`" (acceptance step 2) holds
- [ ] `modules/jhonstart-emilia/**` deleted — its flush plugin (`root.bp:95`), its annotation (moved
      in step 4), its bridge test (the contract-4 literal `e_f51c2501`, 367, is asserted by
      `jhonstart-styled`'s test); onze registers `jhonstart-styled`'s sink, exported as `styledSink()` (`contracts.md` § 6a)
- [ ] an application using `#[emilia]` / `#[styled]` without `"bpp".style` renders emilia's sheet (the annotation
      is an ordinary import; the key is only the style section's)

### 149 s6 — islands (120)

#### Step 0 — Measure (was `120-bpp-islands` s0)

- [ ] what `#[clientProps]` emits (`client.bp:137`): an encoder, or pairs hand-written as in `examples/islands/src/like_button.bp:17-19`
- [ ] an island inside an island's `serverSlot` — hydrated once, twice or not at all
- [ ] `hydrate()` re-run after client navigation: does an island start twice

#### Step 1 — `Hydrate`, `mountIslandWhen`, the payload column (was `120-bpp-islands` s1)

- [ ] `island_strategy.bp`: `Hydrate`, `mountIslandWhen`; `mountIsland` is `mountIslandWhen(…, Hydrate.Load)`
- [ ] the annotations `clientLoad`, `clientIdle(comptime timeoutMs: i32 = 200)`, `clientVisible(comptime
      rootMargin: string = "")`, `clientMedia(comptime query: string)` — each `(comptime decl: @Decl,
      …)`, returning nothing and recording a `Hydrate` meta (280, 302) — and `stage.bp`'s `clientOnly`
      recording `Hydrate.Only` on a tag, still the hook marker `05-jhonstart/26` step 8 reads (278);
      all imported by `prelude.bp`
- [ ] payload row's fourth column on both targets; `contracts.md` § 2 and onze's `build_test.bp:104` literal amended together
- [ ] `client_test.bp`: one case per strategy, asserting the row

#### Step 2 — The runtime scheduler (was `120-bpp-islands` s2)

- [ ] `island_runtime.mjs`: one scheduler per strategy; an island started at most once
- [ ] `jhonstart-dom-test`: `fake_dom.mjs` gains `IntersectionObserver`, `matchMedia`,
      `requestIdleCallback`; five cases, each asserting **not** started before its trigger, started after
- [ ] `#[clientOnly(fallback: …)]` on a tag renders the fallback on the server, the component in the
      browser (287)

#### Step 3 — The `Hydrate` arm of `html` (278) (was `120-bpp-islands` s3)

- [ ] `examples/hydration-directives-example.bp` passes
- [ ] `#[clientVisible]` on an element fails at the annotation (its first parameter is `@Decl`); on
      a component without `#[client]` fails at the annotation, checked by `Decorator.same` (371); an unseen
      island fails the build in the bundler's island check (`entry.bp`) with its name — never a
      mount that starts nothing
- [ ] two `Hydrate` annotations on one tag fail at the second
- [ ] a component whose `hooks` reach `#[clientOnly]`: refused under `#[clientLoad]`, `#[clientIdle]`,
      `#[clientVisible]`, `#[clientMedia]` and with no annotation, the message naming the chain and
      `#[clientOnly]`; accepted under `#[clientOnly]`
- [ ] a `#[clientOnly]` tag adds no node of its component to the page's `hooks` (a `refusals/` cell
      in 26's form: the page stays `S`)
- [ ] a library annotation recording `Hydrate` (`clientMobile` in the example) mounts and gets the
      same checks

#### Step 4 — Server islands (modes `sealed` and `server`, decision 272) (was `120-bpp-islands` s4)

- [ ] `examples/server-island-example.bp` passes on erlang
- [ ] `server_islands.bp`: `serveIslands(prefix)`, `seal` / `unseal`; tampered or truncated `p` answers 400, renders nothing
- [ ] `GET` under 2 048 bytes and `POST` over it answer the same markup
- [ ] the containing page reads no cookie: its kind is `S` (`@typeInfo(Page).meta(PageMeta)?.kind`, 277), page prerenders (`static_gen.bp`)
- [ ] `serverDefer(comptime decl: @Decl, comptime fallback: ?View = null)` recording `Defer` (287, 302;
      `deferred.bp`, imported by the prelude); on a
      non-`#[deferred]` component it fails at the annotation, at compile time, naming it
- [ ] `seal` / `unseal` take the mode as a plain value — `onze.json`'s `"islands": {"props": …}`,
      read by onze's config (124) — default `sealed` (224)
- [ ] mode `server`: the props stored server-side under a random id, the URL carries only `?id=…`;
      an unknown or expired id answers 400 and renders nothing; two instances without a shared
      store do not serve each other's ids (stated in `AGENTS.md`)

#### Step 5 — The network (waits on ONZ-68-split) (was `120-bpp-islands` s5)

- [ ] in `07-onze/53`'s browser run: a below-the-fold `#[clientVisible]` island's chunk is not
      requested until scrolled to; a non-matching `#[clientMedia]` island's chunk is never requested

#### Step 6 — references, not strings (decision 281) (was `120-bpp-islands` s6)

- [ ] `Island(component: "LikeButton", props: [#("likes", "3")])` → the function and its typed
      `#[clientProps]` record; the starter table built at comptime (`@TypeInfo.all(with: client)`);
      `mountIslandWhen("Carousel", …)` in `hydration-directives-example.bp` likewise
- [ ] the `<Component>Props` encoder reached as a member (`LikeButtonProps.encode`, 216), not by name
- [ ] `#[deferred]`'s registration (`"Avatar"` → renderer at module load) → the comptime catalogue
      (`@TypeInfo.all(with: deferred)`); the URL keeps the component's name as the wire id

#### Step 7 — route parameters and page data are hooks (decision 293) (was `120-bpp-islands` s7)

- [ ] `server-island-example.bp`: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

#### Gate additions (was `120-bpp-islands` gate)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/jhonstart`; on commonJS in `jhonstart-dom-test`; on erlang in `rakun-app`
- [ ] `zig build test-libs`: jhonstart, rakun, onze green; the blog's hydrated island still hydrates
- [ ] `contracts.md` § 2

### 149 s7 — the `Astro` global, jhonstart's half (122)

#### Step 0 — Measure — part (was `122-bpp-data` s0 box 2)

- [ ] `redirect()` raised after the first chunk: the response

#### Step 1 — `use response()` (decision 291) (was `122-bpp-data` s1)

- [ ] `examples/response-control-example.bp` passes
- [ ] either called after the shell is written fails with the hook's name and the phase
- [ ] a header set from a `Suspense` fill refused the same way
- [ ] `response` marked `#[serverOnly]`: a page using it is `D` (`@typeInfo(Page).meta(PageMeta)?.kind`),
      its `why` naming `response`; a call written without `use` is no hook (the checker's ordinary
      error for a hook outside `use`)
- [ ] `#[page(headers: …)]` on an `S` page: the headers served with the prerendered file

#### Step 2 — `rewrite` (was `122-bpp-data` s2)

- [ ] `rewrite("/es/articles/introduction")` from `/es-cu/articles/introduction` answers the second
      route's markup at the first's URL — asserted via the navigation wire on both targets
- [ ] a rewrite cycle refused, naming both paths

#### Step 4 — route parameters and page data are hooks (decision 293) (was `122-bpp-data` s4)

- [ ] `response-control-example.bp` and its `.bpp` page: pages take no `route: PageContext`; parameters through `use params<P>()`, page data through `use pageData<D>()`

#### Step 5 — a cookie is declared once, typed (decision 294) (was `122-bpp-data` s5)

- [ ] `response-control-example.bp` and its `.bpp` page read a declared `Cookie<T>` with `use cookieValue(decl)`; `use cookies()` / `pairValue(jar, "…")` gone from page code

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/jhonstart` and `repository/routing`
- [ ] `zig build test-libs`: jhonstart, rakun, onze green
- [ ] `contracts.md` for the new signal

### 149 s8 — view transitions (126)

#### Step 1 — `transitions.bp` and the stylesheet (was `126-bpp-view-transitions` s1)

- [ ] `ViewTransitions()`, `TransitionAnimation`, `fade(…)`, `slide(…)`, the four annotations
      `transitionName`, `transitionAnimate`, `transitionPersist`, `transitionPersistProps` with the
      meta types they record (302), both targets
- [ ] `transitions_test.bp`: the stylesheet is one literal; an annotation's attributes are literals

#### Step 2 — The runtime (was `126-bpp-view-transitions` s2)

- [ ] swap wrapped in `startViewTransition` when flagged — `link_runtime.mjs`'s two document-replacing call sites
- [ ] `jhonstart-dom-test`: a `startViewTransition` double recording its callback; cases forward,
      back, `#[reload]`, `#[history(.Replace)]`, a browser without the API
- [ ] the five hooks fire in order, once per navigation, with typed events; `onBeforePreparation`'s
      wrapped loader runs around the fetch; a `#[client]` component's `use onBeforeSwap` registered
      once per mount (292)
- [ ] `#[reload]` / `#[history(…)]` lower to `data-jh-reload` / `data-jh-history`; a hand-written
      `data-jh-reload` refused at the attribute, naming `#[reload]`

#### Step 3 — `#[transitionPersist]` (was `126-bpp-view-transitions` s3)

- [ ] a persisted element is the **same node** after the swap (identity, not equality) in the fake DOM; a persisted island is not re-hydrated
- [ ] `#[transitionPersistProps]` keeps old props; without it the island re-renders with the new page's props and keeps its state

#### Step 4 — The transition arm of `html`, `navigate`, the announcer (was `126-bpp-view-transitions` s4)

- [ ] `examples/view-transitions-example.bp` passes
- [ ] `#[transitionAnimate(.Slide)]` (a variant or a `TransitionAnimation`, 281 — no `"slide"`); an
      unknown one (`.Spin`) fails at the argument as a missing variant
- [ ] `<Counter #[clientLoad, transitionPersist] />` carries both (two types); two
      `#[transitionName]` on one tag fail at the second
- [ ] announcer text for a page with a title, without one, and with neither

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `jhonstart-link`; on commonJS in `jhonstart-dom-test`
- [ ] `zig build test-libs`: jhonstart, onze green
- [ ] in `07-onze/53`'s browser run: two pages sharing a `#[transitionName]` animate, no page load triggered

### 149 s9 — a project of `.bpp` files (116 s6, after 149 s5)

#### Step 6 — A project of `.bpp` files (a page reads its route by hook: 293) (was `116-bpp-file-format` s6)

- [ ] this front's `examples/` and every track front's `examples/src/` compile as an onze test
      project whose `botopink.json` carries `"bpp": {"default": "jhonstart"}`
- [ ] `119-bpp-styling/examples/src/components/` (`Box.bpp`, `Post.bpp`, which carry style
      sections) compile with `"bpp": {"default": "jhonstart", "style": "jhonstart-styled"}` — once
      119 step 2 has landed
- [ ] so do other tracks' `.bpp` forms: `05-jhonstart/{26-jhonstart-router, 27-jhonstart-link,
      67-jhonstart-forms}/examples/src/` and `07-onze/53-onze-example-app/examples/{app,
      components}/` — `07-onze/53`'s blog, every markup-holding app file kind
- [ ] `examples/PostCard.bpp` unfolds to what `examples/PostCard-desugared-example.bp` spells;
      both render the same markup on both targets

### 149 s10 — jhonstart's snapshot paragraph (135 s3)

#### Step 3 — jhonstart (390) (was `20-snap` s3)

- [ ] `AGENTS.md` paragraph: 204 inline asserts and the 39 existing `.snap` are the evidence; the
      helpers that exist stay (§ 3)
