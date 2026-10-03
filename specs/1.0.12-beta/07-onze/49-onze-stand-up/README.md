# Front 49 — onze stand-up tail: the request, the dispatcher, the digest and the public root reach the app

**Priority:** critical — front 53's write path, error pages and assets read what this front
wires · **State:** not started
**Depends on:** `03-bundled-libs/102` step 3's `types.bp` commit, landed before this front opens
(decision 188) · step 3: `05-jhonstart/26` step 4 (the boundary digests through the bundled
`log`, decisions 194, 195) and `04-rakun/17-rakun-logging` (rakun's logger, the sink) · step 4:
`04-rakun/65-rakun-url-rules` step 1 (the fall-through, decision 201) · step 5:
`04-rakun/22-rakun-file-routing` step 4 (`ChunkWriter.markDynamic`, decision 186) · step 2's
wire-name box: rakun's tests and `05-jhonstart/67` step 4 · maintainer: `49-e`, `49-d` (as
amended by 102)
**Owns:** `repository/onze/modules/onze/**`, `modules/onze-server/**`,
`modules/onze-test/{botopink.json,src/root.bp,src/core.bp,src/fixtures.bp}` and the group stubs
`src/{cli,bundler,assets,og,release,e2e}.bp` (step 6), `test/helpers_test.bp`, `docs.md`,
`AGENTS.md` · the `/_onze/image` and OG registration lines 51 / rakun 66 hand in · this directory
**Does not touch:** `modules/onze-{cli,bundler}/**`, `examples/scaffold/**` (50) ·
`modules/onze-{assets,og}/**` (51) · `modules/onze-release/**` (71) · `examples/blog/**` (53) ·
`onze/src/types.bp`'s segment classification (`03/102`, before this front) ·
`onze-server/src/server.bp` `cookiePairs` (`03/104`'s sweep, after this front) ·
`repository/{rakun,jhonstart}/**` · after landing, what `08-bpp` adds: `onze/src/paginate.bp`
(117), one line of `server.bp` (120), the `site` key (122) and the other four keys (124) of
`config.bp`

## Goal

A page served by `onze build && onze start` sees its query and headers, a server action is
dispatched, an error page's digest is in the log, `public/` is served beside the fingerprinted
root, a page that never reads the query stays prerenderable, and `onze-test` carries one group
file per front.

## Mechanism

`onze-server/src/server.bp`: `requestData(req)` is the one place a rakun `Request` becomes
jhonstart's `RequestData` (today `query: []`, `headers: []`); `responseFor` the one place a
`ChunkWriter` becomes a `Response`; `Onze.run` the one boot. Every step is a line in one of the
three. rakun's `queryDict` (`rakun-app/src/ssr.bp`), `headerNames`
(`rakun/src/request_context.bp`), `serveActions` / `actionsConfigProblem`
(`rakun-app/src/actions.bp`) exist and are not called. rakun-web's `serveFrom` answers 404 on a
miss inside a matched root (no fall-through), so `/**` → `public/` would shadow every page until
`04-rakun/65` step 1; no onze code orders rakun-web's chain around it (decision 67). Once the
query is filled, rakun 23's `markDynamic("searchParams")` would make every page dynamic; decision
186 removes run-time marks, and step 5 is its bridge. Onze reads std's `Json` methods
(`members`, `field`, `str`, `kindName`, `isObject`) instead of its own `pub` accessors in
`config.bp` (`membersOf`, `isObject`, `kindName`, `isString`, `strOf`). Helper signatures for the
`onze-test` groups: [`helper-signatures.md`](./helper-signatures.md).

## Open

### Step 1 — consume std (97): the Json accessors

- [ ] `config.bp` reads through `Json.members()` / `.field()` / `.str()` / `.kindName()` /
      `.isObject()`; `grep -n "pub fn membersOf\|pub fn strOf\|pub fn isObject\|pub fn kindName"
      modules/onze/src` is empty; `config_test.bp` unchanged in count

### Step 2 — the query, the headers, the dispatcher

- [ ] `requestData` fills `query` from `queryDict(req.query)` (a malformed component is the
      `Error` `queryDict` answers — the request is a 400 through `responseFor`, asserted) and
      `headers` from `headerNames` / `req.header(name)`; `server_test.bp`: a page reading
      `searchParams().get("q")` and `headers().get("x-test")` answers both over the socket
- [ ] `Onze.run` installs `serveActions` with the wire names it set; `server_test.bp`: a `POST`
      with the `X-Bp-Action` header reaches the action and answers the envelope; a boot with the
      action keys removed fails naming `rakun.actions.field` (the refusal is rakun's; the test is
      here)
- [ ] the two-file boot (49-e), stated in `docs.md` and true: "`integration.bp` imports jhonstart
      and the bridge; `onze-server/src/server.bp` imports rakun; no third file imports any of
      them"
- [ ] `__bp_action` and `X-Bp-Action` appear in onze's defaults and nowhere under
      `repository/rakun/` or `repository/jhonstart/` — closes when their owners drop the
      literals (today: `rakun-app/test/actions_test.bp` and the `actions-cache` fixture, `04-rakun` RX-13 → 22;
      `jhonstart-forms/test/form_test.bp` and `examples/forms`, `05-jhonstart/67` step 4); onze's
      part is the grep

### Step 3 — the error digest reaches the log

After `05-jhonstart/26` step 4 and `04-rakun/17`: the boundary logs and digests through the
bundled `log` (on `feat`), and onze sets nothing but the sink (decision 195 — no
`RenderHooks.onError`).

- [ ] `Onze.run` sets `log`'s sink to rakun's logger (through `onze-server`; the core's
      `integration.bp` imports no rakun type); `server_test.bp`: a page that throws answers 500
      whose body carries a 16-hex digest, and the same digest is in the captured log line
- [ ] `docs.md` § Errors states the one scheme (`log`'s `errorDigest`, decision 194) and where
      the sink is set

### Step 4 — the public root (decision 201)

After `04-rakun/65` step 1 (a miss falls through, only `GET` / `HEAD` are served, a refusal stays
final): `servedRoots` answers both roots; `Onze.run` registers `public/` at `/**` before the
routes, beside the fingerprinted root — no per-entry root and no `/public` prefix.

- [ ] `server_test.bp`: `/robots.txt` from `public/` is served with rakun-web's headers; a page
      URL with no file under `public/` renders the page (no 404 from the static entry); exactly two
      roots are registered and `docs.md` states there is no third
- [ ] until `04-rakun/65` step 1 lands, `docs.md` says `public/` is not served — no per-entry
      root and no `/public` prefix is written meanwhile

### Step 5 — the dynamic mark (decision 186)

The final state has no run-time mark (the build writes each route's kind; it waits on the
checker capability, `language-gaps.md`, and `05-jhonstart/26` step 8). This step is the bridge
for the meantime; deleting it follows 26 step 8 and has no box here yet.

- [ ] `responseFor` calls `ChunkWriter.markDynamic(reason)` when jhonstart's render reports `d`
      (`04-rakun/22` step 4 adds the method and removes rakun's implicit mark); `pageInput` /
      `requestData` build the query without a marking read; `server_test.bp`: a page that never
      reads the query is prerenderable (rakun's `isDynamic()` false) and one that calls
      `searchParams()` is not

### Step 6 — the `onze-test` group stubs

`src/{cli,bundler,assets,og,release,e2e}.bp` as empty modules with their `pub mod` lines in
`root.bp` and the members they need in `botopink.json`, so 50 · 51 · 71 · 53 fill files they own
without touching the root. No blocker.

- [ ] `onze-test` resolves with six more modules, each exporting nothing yet; `helpers_test.bp`
      unchanged; `zig build test-libs` `onze-test` 7 / 7 on both rows

## Notes

- Step 2 changes what every page sees in `RequestData` (the blog's tests re-assert); step 3
  changes the digest every error page shows. Nothing outside onze moves.
- The `/_onze/image` route (51) and the OG route (rakun 66) reach `Onze.run` as one registration
  line each, handed by their fronts; this front commits them.

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze` 23+, `onze-server` 10+, `onze-test` 7+, on every target its
      manifest declares (`onze-server`: erlang)
- [ ] `grep -rn "flush()" modules/onze modules/onze-server` empty (no style sink)
