# Front 49 — onze stand-up tail: the request, the dispatcher, the digest and the public root reach the app

**Priority:** critical — 53's write path, error pages, assets read what this wires · **State:** not started
**Depends on:** `03-bundled-libs/102` step 3's `types.bp` commit, before this opens (decision 188) ·
step 3: `05-jhonstart/26` step 4 (boundary digests via bundled `log`, decisions 194, 195),
`04-rakun/17-rakun-logging` (the sink) · step 4: `04-rakun/65-rakun-url-rules` step 1 (fall-through,
decision 201) · step 5: `04-rakun/22-rakun-file-routing` step 4 (`ChunkWriter.markDynamic`, decision
186) · step 2's wire-name box: rakun's tests, `05-jhonstart/67` step 4 · maintainer: `49-e` · decision 323 (`49-d` confirmed as amended by 102)
**Owns:** `repository/onze/modules/onze/**`, `modules/onze-server/**`,
`modules/onze-test/{botopink.json,src/root.bp,src/core.bp,src/fixtures.bp}`, group stubs
`src/{cli,bundler,assets,og,release,e2e}.bp` (step 6), `test/helpers_test.bp`, `docs.md`,
`AGENTS.md` · the `/_onze/image` and OG registration lines 51 / rakun 66 hand in · this directory
**Does not touch:** other fronts' members and the `03/102` (before), `03/104` (after) and `08-bpp`
(117 · 120 · 122 · 124, after) windows — [`../modules.md`](../modules.md) § Front → files ·
`repository/{rakun,jhonstart}/**`

## Goal

Under `onze build && onze start`: a page sees query and headers; a server action is dispatched;
an error page's digest is in the log; `public/` served beside the fingerprinted root; a page never
reading the query stays prerenderable; `onze-test` has one group file per front.

## Mechanism

- `onze-server/src/server.bp`: `requestData(req)` — the one rakun `Request` → jhonstart
  `RequestData` (today `query: []`, `headers: []`); `responseFor` — the one `ChunkWriter` →
  `Response`; `Onze.run` — the one boot. Every step is a line in one of the three.
- Exist, uncalled: rakun's `queryDict` (`rakun-app/src/ssr.bp`), `headerNames`
  (`rakun/src/request_context.bp`), `serveActions` / `actionsConfigProblem` (`rakun-app/src/actions.bp`).
- rakun-web's `serveFrom` 404s on a miss inside a matched root (no fall-through): `/**` →
  `public/` would shadow every page until `04-rakun/65` step 1; no onze code reorders rakun-web's
  chain (decision 67).
- Filled query → rakun 23's `markDynamic("searchParams")` makes every page dynamic; decision 186
  removes run-time marks; step 5 is the bridge.
- Onze reads std's `Json` (`members`, `field`, `str`, `kindName`, `isObject`) instead of its own
  `pub` accessors in `config.bp` (`membersOf`, `isObject`, `kindName`, `isString`, `strOf`).
- `onze-test` group signatures: [`helper-signatures.md`](./helper-signatures.md).

## Open

### Step 1 — consume std (97): the Json accessors

- [ ] `config.bp` reads via `Json.members()` / `.field()` / `.str()` / `.kindName()` /
      `.isObject()`; `grep -n "pub fn membersOf\|pub fn strOf\|pub fn isObject\|pub fn kindName"
      modules/onze/src` empty; `config_test.bp` count unchanged

### Step 2 — the query, the headers, the dispatcher

- [ ] `requestData` fills `query` from `queryDict(req.query)` (malformed component → the `Error`
      `queryDict` answers → 400 via `responseFor`, asserted) and `headers` from `headerNames` /
      `req.header(name)`; `server_test.bp`: a page reading the query's `q` (`use searchParams()`)
      and the `x-test` header (`use request()`, 291) answers both over the socket
- [ ] `Onze.run` installs `serveActions` with the wire names it set; `server_test.bp`: `POST` with
      `X-Bp-Action` reaches the action, answers the envelope; a boot with the action keys removed
      fails naming `rakun.actions.field` (refusal rakun's, test here)
- [ ] two-file boot (49-e) stated in `docs.md` and true: "`integration.bp` imports jhonstart
      and the bridge; `onze-server/src/server.bp` imports rakun; no third file imports any of
      them"
- [ ] `__bp_action` and `X-Bp-Action` in onze's defaults, nowhere under `repository/rakun/` or
      `repository/jhonstart/` — closes when owners drop the literals (today:
      `rakun-app/test/actions_test.bp` + `actions-cache` fixture, `04-rakun` RX-13 → 22;
      `jhonstart-forms/test/form_test.bp` + `examples/forms`, `05-jhonstart/67` step 4); onze's
      part is the grep

### Step 3 — the error digest reaches the log

After `05-jhonstart/26` step 4 and `04-rakun/17`: the boundary logs/digests via bundled `log` (on
`feat`); onze only installs one of `log`'s sinks (349; no `RenderHooks.onError`, 195).

- [ ] `Onze.run` installs `log`'s sink and calls `log.captureRuntimeReports()` (349; via `onze-server`; core `integration.bp`
      imports no rakun type); `server_test.bp`: a throwing page answers 500 with a 16-hex digest
      in the body, same digest in the captured log line
- [ ] `docs.md` § Errors states the one scheme (`log`'s `errorDigest`, decision 194) and where
      the sink is set

### Step 4 — the public root (decision 201)

After `04-rakun/65` step 1 (miss falls through, only `GET` / `HEAD` served, refusal final):
`servedRoots` answers both roots; `Onze.run` registers `public/` at `/**` before the routes,
beside the fingerprinted root — no per-entry root, no `/public` prefix.

- [ ] `server_test.bp`: `/robots.txt` from `public/` served with rakun-web's headers; a page URL
      with no file under `public/` renders the page (no 404 from the static entry); exactly two
      roots registered, `docs.md` states there is no third
- [ ] until `04-rakun/65` step 1 lands, `docs.md` says `public/` is not served — no per-entry
      root, no `/public` prefix meanwhile

### Step 5 — the dynamic mark (decision 186)

Final state (decision 277): no run-time mark — `onze build` reads each `#[page]`'s `kind` meta
(`S` / `D`) and writes it to `routing`'s `k` blob. The bridge below holds until
`05-jhonstart/26` step 8 lands.

- [ ] `responseFor` calls `ChunkWriter.markDynamic(reason)` when jhonstart's render reports `d`
      (`04-rakun/22` step 4 adds the method, removes rakun's implicit mark); `pageInput` /
      `requestData` build the query without a marking read; `server_test.bp`: a page never
      reading the query is prerenderable (rakun's `isDynamic()` false), one with
      `use searchParams()` is not
- [ ] after `05-jhonstart/26` step 8: `onze build` writes the `k` blob from the `kind` meta, prints
      `S prerendered` / `D per request (why)` per route; `responseFor`'s `markDynamic` call deleted

### Step 6 — the `onze-test` group stubs

`src/{cli,bundler,assets,og,release,e2e}.bp`: empty modules, `pub mod` lines in `root.bp`, needed
members in `botopink.json` — 50 · 51 · 71 · 53 fill their files without touching the root. No
blocker.

- [ ] `onze-test` resolves with six more modules, each exporting nothing yet; `helpers_test.bp`
      unchanged; `zig build test-libs` `onze-test` 7 / 7 on both rows

## Notes

- Step 2 changes every page's `RequestData` (blog tests re-assert); step 3 every error page's
  digest. Nothing outside onze moves.
- `/_onze/image` (51) and the OG route (rakun 66) reach `Onze.run` as one registration line each,
  handed in; this front commits them.

**Gate:** standard (fronts.md § Gate) +
- [ ] `zig build test-libs` — `onze` 23+, `onze-server` 10+, `onze-test` 7+, on every target its
      manifest declares (`onze-server`: erlang)
- [ ] `grep -rn "flush()" modules/onze modules/onze-server` empty (no style sink)
