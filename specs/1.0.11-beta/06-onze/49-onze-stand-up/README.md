# Front 49 — onze stand-up tail (carries 69)

**Priority:** critical — the query, the headers, the action dispatcher, the error digest and the
public root are what front 53's write path, error pages and assets read; nothing in the blog's
second half can be asserted before this lands
**Depends on:** `02-std-and-packaging/97` (step 1 only) · `04-jhonstart/26` step 4 (`RenderHooks.onError`,
step 3) · the `03-rakun` track: `65-rakun-url-rules` carrying 82's fall-through (69-b, step 4),
`22-rakun-file-routing` carrying 23's mark (49-f, step 5) and 24's dispatcher (step 2 — landed:
`rakun-app/src/actions.bp` has `serveActions` / `actionsConfigProblem`) · `17-rakun-logging`
(`logErrorWithDigest`, landed) · maintainer: `49-e` (the wording), `49-f`, `69-b` · `00-gate`
for the `onze-server commonJS` ledger line
**Owns:** `repository/onze/modules/onze/**`, `modules/onze-server/**`,
`modules/onze-test/{botopink.json,src/root.bp,src/core.bp,src/fixtures.bp}` and the group stubs
`src/{cli,bundler,assets,og,release,e2e}.bp` (step 6), `test/helpers_test.bp`, `docs.md`,
`AGENTS.md` · the `/_onze/image` registration line 51 hands in · this directory
**Does not touch:** `modules/onze-{cli,bundler}/**`, `examples/scaffold/**` (50) ·
`modules/onze-{assets,og}/**` (51) · `modules/onze-release/**` (71) · `examples/blog/**` (53) ·
`onze/src/types.bp:101-127` (`07/102`) · `onze-server/src/server.bp:61` (`cookiePairs`,
`07/104`) — the two 07 fronts and this one never run together · `repository/{rakun,jhonstart}/**`
· `scripts/restricted-targets.txt` (`00-gate`)
**Carried from 1.0.10:** `49-onze-stand-up/README.md` § Step 4 boxes 3, 5, 6 · § Where it stands
(the three "open, and why" items) · `69-onze-styling-pipeline/README.md` § Definition of done (the
two-roots box) and § Where it stands (the public root) · `status.md`'s "the dynamic mark has two
writers" row · `test-snap.md` § Helper signatures (copied as
[`helper-signatures.md`](./helper-signatures.md))

---

## Problem

Reproducible on `examples/blog` through `onze build && onze start`:

1. A page reading `searchParams()` sees no query: `onze-server/src/server.bp:76-77` builds
   `RequestData(query: [], headers: [])`. rakun's page `Request` answers `query(name)` and
   `header(name)` by name; enumerating them needed `queryDict` (`rakun-app/src/ssr.bp:276`) and
   `headerNames` (`rakun/src/request_context.bp:402`), which exist now and are not called.
2. A `POST` to a server action is not dispatched: `serveActions` is not installed by `Onze.run`,
   and the refusal when `rakun.actions.field` is missing ("rakun refuses to start its action
   dispatcher naming the key") is not asserted — `actionsConfigProblem` exists.
3. An error page's digest is `contentHash(message)` and no log line carries it (31-b).
4. `public/` is not served: registering `/**` → `public/` with rakun-web 82 would answer every
   page URL (`static.bp:44-49` — a miss inside a matched root is a 404 from the entry, not a
   fall-through). `Onze.run` registers the fingerprinted root only (`servedRoots`).
5. Once (1) fills the query, rakun 23's `markDynamic("searchParams")` fires on every request
   (49-f).
6. `onze/src/config.bp:98-130` declares `pub` Json accessors std now provides (97).

## Current state

`onze` 22 / 22 on both rows, `onze-server` 10 / 10 on erlang over a real listener, `onze-test`
7 / 7. `Onze.run` writes the five `rakun.*` keys, copies the UI table, registers one
`PageRenderer` per page, the fingerprinted static root, rakun-web's static entry, `bootWeb`, and
calls `Rakun.run`; a layout's `redirect` is a 307 over the socket.

## Mechanism

`server.bp`'s `requestData(req)` is the one place a rakun `Request` becomes jhonstart's
`RequestData`; `responseFor` the one place a `ChunkWriter` becomes a `Response`; `Onze.run` the
one boot. Every item here is a line in one of the three. The public root waits on rakun changing
`serveFrom`'s miss into a fall-through (69-b (a)) — no onze code can order rakun-web's chain
around it without a flag, which decision 67 refuses.

## Steps

### Step 1 — consume std (97): the Json accessors

**Acceptance:**
- [ ] `config.bp` reads through `Json.members()` / `.field()` / `.str()` / `.kindName()` /
      `.isObject()`; `grep -n "pub fn membersOf\|pub fn strOf\|pub fn isObject\|pub fn kindName"
      modules/onze/src` is empty; `config_test.bp` unchanged in count

### Step 2 — the query, the headers, the dispatcher

**Acceptance:**
- [ ] `requestData` fills `query` from `queryDict(req.query)` (a malformed component is the
      `Error` rakun's `queryDict` answers — the request is a 400 through `responseFor`, asserted)
      and `headers` from `headerNames` / `req.header(name)`; `server_test.bp`: a page reading
      `searchParams().get("q")` and `headers().get("x-test")` answers both over the socket
- [ ] `Onze.run` installs `serveActions` with the wire names it set; `server_test.bp`: a `POST`
      with the `X-Bp-Action` header reaches the action and answers the envelope; a boot with the
      action keys removed fails naming `rakun.actions.field` (the refusal is rakun's; the test is
      here)
- [ ] step 4's third box of 1.0.10 is reworded to the two-file boot (49-e) and ticked:
      "`integration.bp` imports jhonstart and the bridge; `onze-server/src/server.bp` imports
      rakun; no third file imports any of them"

### Step 3 — the error digest reaches the log

**Acceptance:**
- [ ] `bootSite` passes `onError: logErrorWithDigest(log, …)` (rakun-logging's, through
      `onze-server` — the core's `integration.bp` takes it as a function value like
      `allowedRedirects`); `server_test.bp`: a page that throws answers 500 whose body carries a
      16-hex digest, and the same digest is in the captured log line
- [ ] `docs.md` § Errors states the one scheme (rakun-logging's) and where it is set

### Step 4 — the public root (69-b (a))

After rakun-web's miss falls through: `servedRoots` answers both roots; `Onze.run` registers
`public/` before the routes.

**Acceptance:**
- [ ] `server_test.bp`: `/robots.txt` from `public/` is served with rakun-web's headers; a page
      URL with no file under `public/` renders the page (no 404 from the static entry); exactly two
      roots are registered and `docs.md` states there is no third
- [ ] until rakun lands (a): the box stays open and `docs.md` says `public/` is not served — no
      per-entry workaround (69-b (b)) is written

### Step 5 — one writer of the dynamic mark (49-f (a))

**Acceptance:**
- [ ] `responseFor` hands jhonstart's `d` to rakun on the first write (the shape 49-f settles);
      `pageInput` / `requestData` build the query without rakun's marking read; `server_test.bp`:
      a page that never reads the query is prerenderable (rakun's `isDynamic()` false) and one
      that calls `searchParams()` is not

### Step 6 — the `onze-test` group stubs

`src/{cli,bundler,assets,og,release,e2e}.bp` as empty modules with their `pub mod` lines in
`root.bp` and the members they need in `botopink.json`, so fronts 50 · 51 · 71 · 53 fill files
they own without touching the root. The signatures are [`helper-signatures.md`](./helper-signatures.md).

**Acceptance:**
- [ ] `onze-test` resolves with six more modules, each exporting nothing yet; `helpers_test.bp`
      unchanged; `zig build test-libs` `onze-test` 7 / 7 on both rows

## Gate

- [ ] `zig build test-libs` — `onze` 22+, `onze-server` 10+ (erlang; commonJS per the ledger),
      `onze-test` 7+, both rows where declared
- [ ] `grep -rn "flush()" modules/onze modules/onze-server` empty (no style sink — 69's gate test
      stays)
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/49-onze-stand-up`; no push, no merge — landing is the maintainer's step

## Blast radius

Step 2 changes what every page sees in `RequestData` — the blog's tests (53) that assumed empty
query/headers re-assert. Step 3 changes the digest every error page shows. Nothing outside onze
moves.

## Notes

- The `/_onze/image` route (51) and the OG route (rakun 66) reach `Onze.run` as one registration
  line each, handed by their fronts; this front commits them.
- `types.bp:101-127` is `102-routing-conventions`'; 49-d is confirmed as amended by it.
