# Track 07 — onze

**Repo:** `repository/onze` · **Reference:** Next.js docs, framework half · tree on disk:
[`modules.md`](./modules.md) · uncovered Next.js rows: [`reference-holes.md`](./reference-holes.md).

onze wires (decision 113): the one package importing jhonstart, rakun and the `jhonstart-emilia`
bridge together; where the libraries meet in an example (decision 114). Its eight members and the
blog (`examples/blog`, `onze build && onze start`) exist. Owed: the wiring that waited on rakun,
`onze dev`, the release end to end, the image/font/OG tails, the blog acceptance script's second
half. Five fronts, cut by member.

## Fronts

| Front | Priority | State | What | Depends on (open) |
|---|---|---|---|---|
| [`49-onze-stand-up/`](./49-onze-stand-up/README.md) | **critical** | not started | `onze`, `onze-server`, `onze-test`'s root: std's Json accessors, query/headers, `serveActions`, the `log` sink, the public root (decision 201), the dynamic-mark bridge (decision 186), the `-test` group stubs | 102 step 3 (`types.bp`); jhonstart 26 step 4 · `04-rakun/17` (step 3); `04-rakun/65` step 1 (step 4); `04-rakun/22` step 4 (step 5); 49-e |
| [`50-onze-cli/`](./50-onze-cli/README.md) | **high** | not started (step 7: the defaults record already drives `--help`) | `onze-cli`, `onze-bundler`, `examples/scaffold`: `dev`, `prerender/`, the signal, the defaults table, lazy starters, `assetPrefix`, `<Script>` callbacks | 102 step 3 (`scan.bp`, `chunk.bp`); 50-b; `std-d`; 71 step 2 (step 5); jhonstart 27 step 1 (step 6); 49 step 6 |
| [`51-onze-image/`](./51-onze-image/README.md) | low | not started | `onze-assets`' image and font files, `onze-og`: single flight, the route, the § 16 prop table, the metrics generator, the OG defaults, the 2 % test | `04-rakun/22` (25, 66); 52-a; 49 step 6 |
| [`71-onze-release-packaging/`](./71-onze-release-packaging/README.md) | medium | not started (step 6's snapshots on disk) | `onze-release`, `examples/static-site`: the ERTS copy, `bin/onze`, the shutdown over real cells, static export, the four gate boxes over a real release | 49 step 6; `04-rakun` 11 · 04 (62) · 81 (step 3); 50 · 53 (step 5) |
| [`53-onze-example-app/`](./53-onze-example-app/README.md) | **high** — the proof of the whole stack; last | not started | `examples/blog/**`: the acceptance script's second half, the browser (the E2E runner `onze-test/src/e2e.bp` is `20-snap` step 5's) | every front above; `20-snap` step 5; jhonstart 26 · 27 · 67; `04-rakun` 22 (24 · 25 · 60 · 66) · 12 · 65 |

Unblocked: the "consume std" first steps of 49, 50, 51 (`97` on `feat`); 49 step 3's half needing
the bundled `log` (`106` on `feat`).

Handed in by `01-compiler/129`: decision 218 (onze's `@/` alias goes; an app writes
`import {lib.db.findPost};`), not built — `50` step 9 (bundler `AliasMap`, scaffold, `docs.md`),
`53` step 1 (the blog's `botopink.json`).

## Order

```
03-bundled-libs/102 step 3 (types.bp, onze-cli/scan.bp, onze-bundler/chunk.bp) ──► before 49 and 50 open (decision 188)

49 step 6 (the onze-test group stubs) first: 50 · 51 · 71 · 53 each fill the file it creates for them
49 · 50 · 51 · 71 steps 1, 2, 4 ── parallel (disjoint members, modules.md § Front → files)
   50 step 5 waits on 71 step 2 · 50 step 6 on 05-jhonstart/27 step 1 · 71 step 3 on 04-rakun 11 / 04 (62) / 81
   └──► 53 (needs 49's wiring, 50's dev, 51's image route, 71's release)
          └──► 71 step 5 (the four gate boxes over the blog's real release)

inbound:  05-jhonstart/26 step 4 · 04-rakun/17 ──► 49 step 3 (the sink)
          04-rakun/65 step 1 (the fall-through, decision 201) ──► 49 step 4
          04-rakun/22 (rakun 23's mark, 24, 25, 60, 66) ──► 49 · 50 · 51 · 53
outbound: 03-bundled-libs/104's consumer sweep (onze-server/server.bp `cookiePairs`, image_handler.bp's MIME table) — after 49 and 51
          03-bundled-libs/107 (onze-release/{otp,docker,spec}.bp) — after 71 (decision 188)
          08-bpp 117 · 120 · 121 · 122 · 124 — each after the front that owns the member (modules.md)
```

49 first: query, headers, action dispatcher and error digest are what 53's write path and error
pages read. 51, 71: independent members. 53: read-only against every other member.

## Decisions

Ids kept from 1.0.10 ([`../../1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md) § Track E); new questions continue
each front's letter sequence. Open: `50-b` (below), `std-d` (`02-std-and-packaging`), `snap-a`;
from the naturalness review ([`decisions-pending.md`](../decisions-pending.md) § nat): `nat-f2`
(`onze.json`'s planned keys — 49, 50), `nat-f4` (the `ONZE_PUBLIC_` prefix — 50, 53; a client
module's unprefixed `env.read` is already refused at build, `onze-bundler/src/refusal.bp`),
`nat-d6` (`notFound` / `redirect` vs `noreturn` — 53), `nat-d8` (the `use…` hook name — 53's
examples).

### To confirm

Built as recommended; full rows in [`decisions-pending.md`](../decisions-pending.md) § Implementation
choices / 07-onze: `49-a` · `49-c` · `49-e`
(closes 49 step 2's wording box) · `50-a` (amended: `start` calls 71's `bin/onze`; closes 50) ·
`52-a` (closes 51 step 4) · `53-a` · `68-a` · `68-d` (moot once `06-emilia/34` step 1 and 119 step 4
land — 301's `#[styled]` tokens are comptime, class and rule computed at build; holds until then) ·
`69-a`. `68-c` closed (280, 281): starters and client props found by type at comptime
(`#[clientProps]`, 120 step 6), never by name.

### 50-b · What `onze dev` does on a change — reload into the running node, or restart it

Raised by front 50 step 2; full question in [`decisions-pending.md`](../decisions-pending.md) § 50-b.
Recommendation (a): restart the node per change (`build` + `start` over a file watcher).
**Blocks.** 50 step 2 (written for (a)); 53 step 6 ("`dev` serves every route"). Today
`onze-cli/src/main.bp:101`'s "not available yet" text describes (b) (reload into the running node)
and cites "front 50 step 6" — 1.0.10's numbering; here it is 50 step 2, which removes the text.

Module-level snapshot maps of §§ 50 · 51 · 52 · 70 · 71 and 53's runner: [`decisions-pending.md`](../decisions-pending.md) `snap-a`, worked by [`20-snap`](../20-snap/README.md) step 5.
