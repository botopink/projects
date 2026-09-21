# Front 61 — Rakun Parallel and Intercepting Routes

**Track:** B rakun
**Priority:** high — front 22's one-liner promises `@slots`, and without this front `@slot` is a folder
name the scanner recognizes and nothing more: layouts never receive named slot props, `default.bp` has
no meaning, and the modal-over-a-feed pattern of `§ 21` — the reason most real Next apps use the App
Router at all — is unbuildable
**Target:** both — boundary. The server resolves slots and decides interception; the client must tell
it which navigation this is, and the two halves are named below
**Wave:** 6
**Depends on:** 22 (the `RouteNode` tree and the table), 23 (layout nesting and the payload), 27
(client navigation, which sets the soft-navigation marker), 30 (per-slot `loading` boundaries),
62 (the request frame the marker is read from)
**Owns:** `repository/rakun/src/route_slots.bp`, `repository/rakun/src/route_intercept.bp`,
`repository/rakun/src/sidecars/rakun_route_slots.erl`,
`repository/rakun/test/route_slots_test.bp`, `repository/rakun/test/route_intercept_test.bp`, and two
`pub mod` lines in `repository/rakun/src/root.bp`
**Does not touch:** `repository/rakun/src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`,
`src/runtime.mjs` — frozen; `src/file_router.bp` (front 22) and `src/ssr.bp` (front 23) are read-only
here; this front adds no file to `repository/jhonstart/`
**Reference:** `NEXTJS-DOCS.md § 21. Rotas Paralelas e Interceptadas`,
`§ 3. Estrutura do Projeto` (`default` file convention), `§ 5. Layouts e Páginas` (Props das páginas e
layouts) · <https://nextjs.org/docs/app/api-reference/file-conventions/parallel-routes> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/intercepting-routes> ·
<https://nextjs.org/docs/app/api-reference/file-conventions/default>
**Replaces:** `new` — 1.0.7-beta's file-routing front named `@slots` and specified nothing behind it

---

## Problem

Front 22 classifies `@team` as `SegmentKind.Slot` and records the slot name in the route table's third
field. That is where it stops, deliberately: front 22's job is the table and this front's job is what
a slot means. Today nothing does the second job, so four things are missing.

A layout cannot receive a slot. `§ 5`'s layout signature is
`Layout({ children, analytics, team })` — three independently-rendered subtrees composed by one
layout — and front 23 has one slot, `children`. A slot has no independent match: `@team` should match
the current URL on its own and keep its own `loading.bp` and `error.bp`, which means the pipeline runs
N matches per request, not one. `default.bp` has no meaning: `§ 3` lists it as a file convention and
`§ 21` explains why it exists — a slot with no match for the active URL must render *something*, and
on a hard reload every slot except the one the URL names is in that position. And interception —
`(.)`, `(..)`, `(..)(..)`, `(...)` — is entirely absent, so the photo-detail-over-a-feed overlay that
`§ 21` builds its whole example on cannot be expressed.

The last one is the one that breaks naively. Interception is not a routing rule, it is a routing rule
*plus a condition*: the intercepted route renders only on a client navigation, and a direct request or
a reload renders the full route. That condition is a boundary fact, and a server that guesses it
serves a modal to someone who pasted a URL.

## Current state

- `repository/rakun/src/file_router.bp` (front 22) — `SegmentKind.Slot`, `slotOf(segments)`, and the
  table's `slot` field. `matchPath` explicitly does not match slot entries: front 22's *Step 4* says
  "a slot entry is matched separately against the same URL by front 61".
- Front 22's table has a `D` kind letter reserved for `default.bp` and a `#[defaultView(seg)]`
  decorator that registers one. Nothing consumes either.
- `repository/rakun/src/ssr.bp` (front 23) — composes the layout chain around one child. `LayoutProps`
  carries `children` and nothing else.
- `repository/jhonstart/src/element.bp:3-8` — `Element(tag, value, children, attrs)`. A layout that
  places two slots places two `Element` values; nothing about the element model is in the way.
- `repository/rakun/src/route_slots.bp` and `route_intercept.bp` do not exist.

## Mechanism

### What Next.js does

A `@folder` renders into a named prop of the parent layout and does not affect the URL (`§ 21`). Each
slot matches the URL independently and keeps its own boundaries. `default.tsx` renders when a slot has
no match. An intercepting folder `(.)photo` inside `feed/[id]/` claims the route `/photo/...` when the
user arrives by client navigation, and yields to the real `/photo/[id]` page on a direct request
(`§ 21` Intercepted Routes). The marker's prefix counts levels: `(.)` same level, `(..)` one up,
`(..)(..)` two up, `(...)` from the root.

### How it maps onto botopink

**Slot resolution is N independent matches, joined by the layout that owns them.**
`slotsOf(table, layoutPattern)` answers the slot names declared under a layout. For each, the pipeline
runs front 22's `matchPath` over a *view* of the table filtered to that slot. Three outcomes, in
order: a match, the slot's `default.bp` (`D` entry) if it has one, or `null`. A `null` slot renders as
nothing and is not an error — `§ 21` has slots that are legitimately empty on some URLs.

**`default.bp` is what makes a hard reload work.** On a client navigation the previous slot content is
still in the browser, so an unmatched slot can keep what it had. On a direct request there is nothing
to keep, and without a `default` the layout would receive a hole. So the rule is asymmetric and stated
as such: on a soft navigation an unmatched slot resolves to *unchanged* (the payload says so and front
27 keeps the DOM); on a hard request it resolves to `default.bp`, or to nothing when there is none.
That asymmetry is the whole reason the convention exists and it is where naive implementations lose
their content on refresh.

**Interception is parsed, resolved, and then gated.** `parseIntercept("(.)photo")` answers
`Intercept(kind: InterceptKind.Same, target: "photo")`. `resolveIntercept(i, fromPattern)` turns the
marker plus the pattern it sits in into the pattern it claims — `(..)` drops one segment from
`fromPattern` before joining, `(...)` starts at `/`. Resolution is pure and total, and it is the
half that is easy.

The gate is the half that is not. `interceptFor(table, fromPattern, toPattern, soft)` answers the
intercepting entry only when `soft` is true. `soft` is not inferred: front 27's client router sets the
request header `x-rakun-nav: soft` on a navigation fetch, and front 62's `headers()` is where this
front reads it. A missing header is a hard request — the restrictive direction, because serving a
modal to a pasted URL is the failure that gets noticed and serving a full page to a client navigation
is the failure that does not.

**Conflicts fail the scan, not the render.** Two slots claiming the same URL under one layout, an
interception whose resolved target is not in the table, and a `default.bp` registered outside a slot
are all scan-time failures with the offending names in the message. Rendering an empty slot instead
would be a silent wrong answer, and `§ 21`'s own example has four folders that could collide.

### The boundary, and its two halves

**Server half (erlang).** Slot enumeration, per-slot matching, `default` fallback, interception parsing
and resolution, the conflict checks, and the composition of the slot results into front 23's
`LayoutProps`.

**Boundary half (erlang and js).** Two artifacts, both tiny, both pure botopink with no host cell:

1. `x-rakun-nav: soft` — the request marker front 27 sets and this front reads. One header name, one
   value, written down here so neither side spells it differently.
2. The slot section of front 23's payload: `slot|pattern|state` lines, `state` being `M` matched,
   `D` default, `U` unchanged, `E` empty. Front 27 reads `U` and keeps the DOM it has; anything else
   it replaces. `parseSlotStates`/`writeSlotStates` are the shared functions and they compile for both
   targets.

This front tests the round trip — a soft navigation producing `U` for a slot the URL does not name,
and a hard request for the same URL producing `D` — rather than testing each side alone.

### Target and sidecar naming

The server half declares `#[@External.Erlang]` cells only; the two boundary artifacts are pure
botopink. **The sidecar module atom is `rakun_route_slots`**, not `route_slots`: `shipErlSidecars`
skips a qualifier whose atom matches a module this build emitted
(`modules/compiler-cli/src/cli/libs.zig:596`) and rakun emits `rakun/route_slots`. Same rule as front
04's `rakun_runtime`.

## Steps

### Step 1 — Slot enumeration and per-slot matching

```bp
pub type SlotEntry(
    slot: string,
    pattern: string,
)

pub type SlotState {
    Matched,
    Defaulted,
    Unchanged,
    Empty,
}

pub type SlotResolution(
    slot: string,
    state: SlotState,
    entry: ?RouteEntry,
    params: Dict<string, string>,
)

pub fn slotsOf(table: RouteEntry[], layoutPattern: string) -> string[]
pub fn tableForSlot(table: RouteEntry[], slot: string) -> RouteEntry[]
pub fn resolveSlot(table: RouteEntry[], slot: string, layoutPattern: string, pathname: string, soft: bool) -> SlotResolution
pub fn resolveSlots(table: RouteEntry[], layoutPattern: string, pathname: string, soft: bool) -> SlotResolution[]
```

**Acceptance:**
- [ ] `slotsOf` for a layout with `@analytics` and `@team` answers both, in registration order, and
      does not include the children slot.
- [ ] `resolveSlot` for a slot whose subtree matches the URL answers `SlotState.Matched` with the
      bound params.
- [ ] `resolveSlot` for an unmatched slot on a **hard** request answers `SlotState.Defaulted` when the
      slot has a `D` entry and `SlotState.Empty` when it does not.
- [ ] `resolveSlot` for an unmatched slot on a **soft** navigation answers `SlotState.Unchanged`,
      whether or not the slot has a `D` entry.
- [ ] Two slots match two different URLs independently: `/dashboard/settings` matches `@team`'s
      `settings` page while `@analytics` falls back, in one call to `resolveSlots`.
- [ ] A slot's own `loading.bp` (`S`) and `error.bp` (`E`) entries are found within that slot's
      filtered table and not inherited from the children slot.
- [ ] `resolveSlots` preserves declaration order, because the layout binds them positionally in the
      payload.

### Step 2 — `default.bp`

**Acceptance:**
- [ ] A `D` entry registered under `@analytics` is found for that slot and not for `@team`.
- [ ] A `D` entry registered outside any slot fails the scan, naming the directory.
- [ ] Two `D` entries under one slot fail the scan.
- [ ] The hard-reload case is asserted end to end: a request for `/dashboard/settings` with no
      `x-rakun-nav` header resolves `@analytics` to its `default.bp`, and the rendered layout contains
      the default's output rather than a hole.

### Step 3 — Interception markers

```bp
pub type InterceptKind {
    Same,
    Up1,
    Up2,
    Root,
}

pub type Intercept(
    kind: InterceptKind,
    target: string,
    raw: string,
)

pub fn parseIntercept(folder: string) -> ?Intercept
pub fn resolveIntercept(marker: Intercept, fromPattern: string) -> string
```

**Acceptance:**
- [ ] `parseIntercept("(.)photo")` is `Same`/`photo`; `(..)photo` is `Up1`; `(..)(..)photo` is `Up2`;
      `(...)photo` is `Root`.
- [ ] `parseIntercept("(marketing)")` answers `null` — a route group is not an interception, and the
      two spellings share an opening character, which is the parse that goes wrong first.
- [ ] `parseIntercept("photo")` answers `null`.
- [ ] `parseIntercept("(....)photo")` raises, naming the folder — an unrecognized marker is a typo, and
      treating it as a static folder named `(....)photo` would create a route nobody asked for.
- [ ] `resolveIntercept(Same/photo, "/feed/[id]")` answers `/feed/[id]/photo`.
- [ ] `resolveIntercept(Up1/photo, "/feed/[id]")` answers `/feed/photo`.
- [ ] `resolveIntercept(Up2/photo, "/feed/[id]")` answers `/photo`.
- [ ] `resolveIntercept(Root/photo, "/feed/[id]")` answers `/photo` regardless of depth.
- [ ] `resolveIntercept(Up2/photo, "/feed")` raises: the marker climbs past the root, and a silent
      clamp would claim a route the developer did not write.

### Step 4 — The soft/hard gate

```bp
pub fn isSoftNavigation() -> bool
pub fn interceptFor(table: RouteEntry[], fromPattern: string, toPattern: string, soft: bool) -> ?RouteEntry
```

`isSoftNavigation()` reads `x-rakun-nav` through front 62's `headers()` and therefore raises outside a
request, which is front 62's rule and is inherited, not restated.

**Acceptance:**
- [ ] `interceptFor(..., soft: true)` answers the intercepting entry for a URL a marker claims.
- [ ] `interceptFor(..., soft: false)` answers `null` for the same inputs, so the full route renders.
- [ ] `isSoftNavigation()` is false with no header, false for `x-rakun-nav: hard`, true only for
      `x-rakun-nav: soft`, and the header name is compared case-insensitively.
- [ ] An interception whose resolved target is not in the table fails the scan, naming both patterns.
- [ ] Two interceptions resolving to the same target from different origins do not conflict — the
      origin pattern is part of the key — while two from the *same* origin do, and fail the scan.
- [ ] The round trip: one test issues the same URL twice, once with the header and once without, and
      asserts the two different entries. Asserting only one half is how this front's central bug ships.

### Step 5 — The payload slot section

```bp
pub fn writeSlotStates(rs: SlotResolution[]) -> string
pub fn parseSlotStates(wire: string) -> Array<#(string, string, SlotState)>
```

`slot|pattern|state`, one record per line, `state` one letter: `M`, `D`, `U`, `E`.

**Acceptance:**
- [ ] `parseSlotStates(writeSlotStates(rs))` recovers the slot name, pattern and state of each
      resolution, compared field by field.
- [ ] A slot name containing `|` fails the scan (front 22 already forbids it in a segment name; this
      step asserts the same rule reaches the slot field).
- [ ] The same assertions run green on `--target erlang` and `--target commonJS` from the same test
      file — this is the boundary half.
- [ ] An unknown state letter parses as `SlotState.Empty` rather than raising: a malformed payload
      arriving from the network must not be able to crash the client router.

### Step 6 — Composition into `LayoutProps`

This front does not own `LayoutProps`; front 23 does. It owns the function front 23 calls:

```bp
pub fn slotElements(rs: SlotResolution[]) -> Array<#(string, Element)>
```

**Acceptance:**
- [ ] A layout declaring `@analytics` and `@team` receives two named elements, in declaration order.
- [ ] An `Empty` slot contributes an element that renders to the empty string, not a missing entry —
      a layout that indexes its slots positionally must not shift.
- [ ] An `Unchanged` slot contributes no element and the payload carries `U` for it; front 27 is what
      keeps the DOM, and this front's test asserts the payload rather than the DOM.

## Examples

- [`examples/parallel-routes-example.bp`](./examples/parallel-routes-example.bp) — `§ 21`'s dashboard:
  a layout that places `@analytics` and `@team` beside `children`, the two slot pages, and the
  `default.bp` that keeps a hard reload whole.
- [`examples/intercepting-routes-example.bp`](./examples/intercepting-routes-example.bp) — the
  modal-over-a-feed: `(.)photo/[photoId]` rendering as an overlay on a client navigation and the full
  `/photo/[id]` page on a direct request, with the marker resolution asserted in a `test` block that
  runs on both targets.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| Tuple labels are lost through generic instantiation (`repository/jhonstart/src/hooks.bp:75-77`), so `slotElements`' `Array<#(string, Element)>` is read as `.0`/`.1` by every consumer rather than by name | `slotElements` in *Step 6*, and front 23's composition | read the pair positionally, or introduce a named record and pay a construction per slot | preserve tuple labels through instantiation |
| Declared parameter defaults are never applied, so `resolveSlot` takes `soft` explicitly at every call site rather than defaulting to the restrictive value | *Step 1* and *Step 4* signatures | pass `soft` explicitly; the default that would have been applied is `false` | apply a declared default at the call site when the argument is omitted |

One gap front 01 already recorded applies and is cited rather than re-filed: there is no array
destructuring in a binding, so both wire formats are parsed with `split` and `.at(i)`.

## Test plan

`repository/rakun/test/route_slots_test.bp` and `repository/rakun/test/route_intercept_test.bp`, run by
`botopink test --target erlang` from `repository/rakun/` and by
`zig build test-libs -- --target erlang --lib rakun`.

*Step 3* (marker parsing and resolution) and *Step 5* (the payload slot section) additionally run on
`--target commonJS`, because both are pure botopink the browser half needs. Everything that reads a
header or the route registry is erlang only.

What the tests assert, by step: slot enumeration and per-slot matching including independent
`loading`/`error` boundaries; the `default.bp` rules and the hard-reload case end to end; the four
marker spellings, the route-group near-miss, and the two raising cases; the soft/hard gate as a round
trip over one URL; the payload round trip on both targets plus the unknown-letter tolerance; and the
composition's ordering and empty-slot stability.

Scan-time conflicts (two slots on one URL, a stray `default.bp`, an interception with no target) are
startup failures and cannot be written as a runtime `assert`; they go in the CLI's suite under front
50, and the expected message text is specified in the acceptance lists above. That split follows the
precedent front 22 sets and `repository/rakun/test/di_test.bp:14-16` before it.

## Definition of done

- `src/route_slots.bp` and `src/route_intercept.bp` compile, and the marker parser and payload codec
  carry no host cell so they build for both targets.
- `src/sidecars/rakun_route_slots.erl` compiles under `erlc` with `-Werror` and its atom does not
  collide with a module rakun emits.
- The `x-rakun-nav` header name, the four state letters and the soft/hard asymmetry are written down
  here once and cited by fronts 23, 27 and 30 rather than re-derived.
- A hard request never renders an intercepted route, and there is no property that changes that.
- `repository/rakun/AGENTS.md` names `route_slots.bp`, `route_intercept.bp` and the slot wire format.
- The front's tests are green on its assigned target — here, erlang for the server half and both for
  the two boundary artifacts.
