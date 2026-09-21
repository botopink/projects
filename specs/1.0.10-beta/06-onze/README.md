# Track E — onze

**Track:** E — onze · **Repo:** `repository/onze` (name taken over from the retired mocking lib —
[`../01-std/onze-migration.md`](../01-std/onze-migration.md)) · **Reference:** Next.js docs, framework
half — `NEXTJS-DOCS.md` §§ 2 · 3 · 7 · 15 · 16 · 17 · 18 · 24 · 28 · 29

The full-stack orchestrator and bundler: `onze dev / build / start`, the CLI, the client bundle, the
styling pipeline, image and font optimisation, release packaging, and the app that proves it. Files
in this directory: [`modules.md`](./modules.md) (the package cut), [`unification.md`](./unification.md)
(the 1.0.7 → 1.0.9 → 1.0.10 loss check), [`test-snap.md`](./test-snap.md) and
[`test-snap-examples.md`](./test-snap-examples.md) (the snapshot-test maps).

## Fronts, in blocking order

Ordered by the `Depends on` lines of the front READMEs, not by number:
`49 → 68 → 69 → 52 → 51 → 70 → 71 → 50 → 53` (decision 77). A front sits below everything it
consumes. **Wave** is the milestone-wide level from [`../fronts.md § Waves`](../fronts.md#waves),
computed over every track's `Depends on` lines — not the `**Wave:**` header inside each front
README, which is still the 1.0.9 value and is left as written so the 1.0.9 cross-references keep
resolving. The row order is the chain the track reads in, not a schedule: 71 needs only 68 and 69
and is therefore ready one wave before 70, which waits on 52.

| # | Front | Priority | Wave | Submodule | Depends on (track E) | Depends on (other tracks) |
|---|---|---|---|---|---|---|
| 1 | [`49-onze-stand-up`](./49-onze-stand-up/README.md) | **critical** | 0 | `modules/onze/` | — | std [`01`](../01-std/) (`env`, `path`) |
| 2 | [`68-onze-client-bundle`](./68-onze-client-bundle/README.md) | **critical** | 6 | `modules/onze-bundler/` | 49 | jhonstart [`29`](../04-jhonstart/29-jhonstart-client-directive/README.md) · [`27`](../04-jhonstart/27-jhonstart-link/README.md) · rakun [`23`](../03-rakun/23-rakun-ssr-pipeline/README.md) · [`22`](../03-rakun/22-rakun-file-routing/README.md) · [`20`](../03-rakun/20-rakun-websocket/README.md) · emilia [`48`](../05-emilia/48-emilia-attributes/README.md) · [`56`](../05-emilia/56-emilia-cascade-and-output/README.md) · std 01 · 03 |
| 3 | [`69-onze-styling-pipeline`](./69-onze-styling-pipeline/README.md) | medium | 7 | `modules/onze-assets/` | 49 · 68 (the `Y` records) | rakun [`23`](../03-rakun/23-rakun-ssr-pipeline/README.md) · jhonstart [`30`](../04-jhonstart/30-jhonstart-streaming/README.md) · emilia [`48`](../05-emilia/48-emilia-attributes/README.md) · [`56`](../05-emilia/56-emilia-cascade-and-output/README.md) · std 01 · 03 |
| 4 | [`52-onze-font`](./52-onze-font/README.md) | low | 8 | `modules/onze-assets/` | 49 · 69 (head seam, asset manifest) | std 01 · 03 |
| 5 | [`51-onze-image`](./51-onze-image/README.md) | low | 8 | `modules/onze-assets/` | 49 · 69 (`public/`, asset manifest) | rakun [`25`](../03-rakun/25-rakun-route-handlers/README.md) · [`12`](../03-rakun/12-rakun-cache/README.md) · std 01 · 03 |
| 6 | [`70-onze-image-response`](./70-onze-image-response/README.md) | low | 9 | `modules/onze-og/` | 49 · 52 (metrics sidecar) | rakun [`66`](../03-rakun/66-rakun-metadata-file-routes/README.md) · [`12`](../03-rakun/12-rakun-cache/README.md) · jhonstart [`32`](../04-jhonstart/32-jhonstart-metadata/README.md) · std 01 · 03 |
| 7 | [`71-onze-release-packaging`](./71-onze-release-packaging/README.md) | medium | 8 | `modules/onze-release/` | 68 · 69 | rakun [`04`](../03-rakun/04-rakun-erlang-runtime/README.md) · [`05`](../03-rakun/05-rakun-config-profiles/README.md) · [`11`](../03-rakun/11-rakun-actuator/README.md) · [`60`](../03-rakun/60-rakun-static-generation/README.md) · [`62`](../03-rakun/62-rakun-request-context/README.md) · std 01 · 03 |
| 8 | [`50-onze-cli`](./50-onze-cli/README.md) | medium | 9 | `modules/onze-cli/` | 49 · 68 · 69 · 71 | rakun [`22`](../03-rakun/22-rakun-file-routing/README.md) · [`04`](../03-rakun/04-rakun-erlang-runtime/README.md) · [`60`](../03-rakun/60-rakun-static-generation/README.md) · std 01 · 03 |
| 9 | [`53-onze-example-app`](./53-onze-example-app/README.md) | medium | 10 | `examples/blog/` | all eight above | rakun 22 · 23 · 24 · 25 · 62 · 63 · 60 · 07 · 65 · 12 · jhonstart 26–32 · 67 · 94 · emilia 33 · 35 · 40 · 48 · 56 · std 01 · 03 |

Two `Depends on` lines in 1.0.9 form cycles and are read as **soft** citations here (the 1.0.9
`fronts.md` rule: a citation, not an edge): 68 → 50 ("the CLI that invokes it") and 71 → 50 ("the
CLI entry points"). Both libraries are tested against fixture strings without the CLI, and the CLI is
what consumes them — so 50 sits below 68 and 71. 51 and 52 carry wave 3 in their own headers while
depending on 69, which no reading places that early; the table follows the dependency lines and the
headers are left as written.

## Dependency graph

```
                       std 01 · 03
                            │
                            ▼
                    49-onze-stand-up  ◄──────────────── rakun 22 (vocabulary it documents)
                            │
        ┌───────────────────┤
        ▼                   ▼
 68-onze-client-bundle   (jhonstart 29 · 27 · rakun 23 · 20 · emilia 48 · 56)
        │
        ▼
 69-onze-styling-pipeline  ◄── rakun 23 · jhonstart 30 · emilia 48 · 56
        │
        ├──────────────┬───────────────────┐
        ▼              ▼                   ▼
   52-onze-font   51-onze-image      71-onze-release-packaging ◄── rakun 04 · 05 · 11 · 60 · 62
        │           (rakun 25 · 12)         │
        ▼                                   │
 70-onze-image-response ◄── rakun 66 · 12 · jhonstart 32
        │                                   │
        └──────────────┬────────────────────┘
                       ▼
                  50-onze-cli  ◄── rakun 22 · 04 · 60
                       │
                       ▼
               53-onze-example-app  ◄── everything
```

Cross-track edges point **into** onze only. The three 1.0.9 seams that reached the other way —
front 23 calling 69's sink, front 23 calling 68's `headScriptTags`/`scriptTags`, and front 29
sharing 68's `islandAttr` — are gone (decision 77): rakun's front 23 declares
`RenderHooks(headExtra, bodyExtra, islandAttr, openSink, collectHead, collectChunk, closeSink)`
with working defaults, `Onze.run` fills it at boot from 68 and 69, and `islandAttr` is defined in
jhonstart (front 29) and imported by 68's entry generator. The per-seam record is in
[`modules.md`](./modules.md); the graph above is the one that follows from it.

## Numbering

Front numbers are 1.0.9 identifiers and are preserved: 49–53 were allocated to track E in the
first cut and 68–71 were admitted by the Next.js coverage audit. Directory names keep their 1.0.9
spelling (`NN-onze-<name>`); every one was drafted under `onze13` and carries that as a one-line note
under its title. No number is reused and the gap 54–67 belongs to tracks C and D.
