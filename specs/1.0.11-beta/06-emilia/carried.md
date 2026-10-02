# Carried — `05-emilia` (1.0.10-beta) → track 06 (1.0.11-beta)

One row per 1.0.10 front or track file; the items it still owed; where each went. **Closed on
tick** = true on disk when 1.0.10 was frozen (measured), ticked in the record, not carried.
**Closed on confirmation** = closes when the maintainer confirms the lettered choice.

| 1.0.10 front / file | 1.0.11-beta front | Carried | Closed on tick · on confirmation · handed |
|---|---|---|---|
| 33 color-palette | **33** (name only — the lowest number of the examples/test layer; its own boxes are closed) | — | its `examples/palette-example.bp:108` marker → **00-gate** (EM-10) |
| 34 modifiers | **34** | EM-9's modifier rows (named `:has` / `:not` / ARIA / data / `in-[…]`; named groups and peers) — conditional on 05emilia-n | 05emilia-j → confirmation |
| 35 spacing-sizing · 36 layout · 37 grid · 38 typography · 39 backgrounds · 41 effects · 46 interactivity · 47 svg-accessibility · 55 preflight · 57 escape-hatches · 58 container-queries · 59 custom-utilities | **33** (their sections of `test-snap.md` / `test-snap-examples.md`, conditional on 05emilia-m) | — | no open box in any of their READMEs (measured: `grep '^- \[ \]'` over the 22 READMEs finds boxes in 48 and 56 only); 05emilia-g, -h, -k → confirmation; 41's `effects-example.bp:45` and 40's `borders-example.bp:80` markers → **00-gate** (EM-10) |
| 40 borders | **34** | EM-8: `divide-*` without `border-*-style:var(--tw-border-style)` | — |
| 42 filters | **34** | EM-8: backdrop filters without `-webkit-backdrop-filter`; `backdrop-opacity` as `opacity(0.5)` | 05emilia-a, -b, -c → confirmation |
| 43 tables | **34** | EM-8: `border-spacing-*` writes the property, not `--tw-border-spacing-{x,y}` | — |
| 44 transitions | **34** | EM-8: the presets' `var(--ease-out)` / `150ms` for upstream's `var(--tw-ease, …)` / `var(--tw-duration, …)` | — |
| 45 transforms | **34** | EM-9: negative translate (no `Neg` under `TranslateX` / `TranslateY`) — conditional on 05emilia-n | 05emilia-i → confirmation; the transform families themselves moved in 1.0.10 |
| 48 attributes | — | — | box "the literal fixture is asserted by the bridge test and onze 68" → closed on tick: `jhonstart/modules/jhonstart-emilia/test/bridge_test.bp` "bridge: the contract-4 literal on a rendered document" and `onze/modules/onze-cli/test/build_test.bp:104` both assert `e_39b87d03` (EM-2) |
| 54 theme | **34** | EM-9: a cleared `--breakpoint-*` must refuse (step 3, not conditional); `@theme inline` (conditional) | box "the unknown-prefix refusal of `extendTheme` is in the compiler's Zig suite" → closed on tick: the refusal is asserted by its message in `emilia.bp`'s front-54 tests (status row "front 54's refusal asserted by its message") and the compiler's `reject/` cells pin the panic form |
| 56 cascade-and-output | **34** step 1 | EM-1 (`hashHex` → `hash.contentHash`, fixture unchanged) | 05emilia-e, -f → confirmation |
| `modules.md` § `emilia-test` ("the helpers are not written yet") | **33** step 1 | EM-3 (PK-4) | — |
| `modules.md` § examples ("`emilia-card` still depends on jhonstart") | **33** step 2 | EM-7 (decision 114; supersedes `02-packaging` step 3's "prints what it printed", PK-3) | — |
| `test-snap.md` (2 341 lines) | **33** steps 3 (copied whole) | EM-4 — conditional on **05emilia-m** (recommendation: retire) | — |
| `test-snap-examples.md` (735 lines) | **33** step 4 (copied whole) | EM-5 — conditional on **05emilia-m** | — |
| `reference-coverage.md` § Missing and partial | **34** (`reference-rows.md`) | EM-9 — the (c) rows; conditional on **05emilia-n** except the breakpoint refusal | the (b) rows stay out of scope by design |
| `tailwind-mapping.md` | — | — | stays in the record; 34 updates its rows for the four families in `repository/emilia/docs.md`, the user-facing reference |
| `unification.md` § Open boxes (five) | — | — | two closed on tick (48's jhonstart-side boxes: `bridge_test.bp` asserts both), one carried (56's `hashHex` → 34), one closed on tick (54's compiler refusal), one → 34 step 1 (the `output.bp:386` comment, whose compiler row is **00-gate**'s to file) |
| `01-std/examples/emilia-test-{submodule,consumer}-example.bp` | **33** (`examples/`) | the worked example of the helper shape | — |
| `02-packaging` step 3 — fifteen `README.md` | **33** step 2 | PK-2 | — |
| `02-packaging` — `emilia-card` `targets` | — | — | closed on tick: `["commonJS", "erlang"]`, 4 / 4 on both rows |
