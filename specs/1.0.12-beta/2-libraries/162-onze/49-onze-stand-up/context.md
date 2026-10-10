# Front 49 — onze stand-up tail: the request, the dispatcher, the digest and the public root reach the app

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [162-onze](../README.md): s2 → 162 s1 · s3 → 162 s1 · s4 → 162 s1 · s5 → 162 s1 · gate → 162 s1. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** critical — 53's write path, error pages, assets read what this wires · **State:** steps 1 and 6 done (onze-wave patches; land with the coordinator)
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
(117 · 120 · 122 · 124, after) windows — [`../modules.md`](../07-onze/modules.md) § Front → files ·
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
- Onze reads std's `Json` (`members`, `field`, `str`, `items`, `kindName`, `isObject`); `config.bp`
  keeps `isString` alone (`49-g`).
- `onze-test` group signatures: [`helper-signatures.md`](helper-signatures.md).

## Notes

- Step 2 changes every page's `RequestData` (blog tests re-assert); step 3 every error page's
  digest. Nothing outside onze moves.
- `/_onze/image` (51) and the OG route (rakun 66) reach `Onze.run` as one registration line each,
  handed in; this front commits them.

