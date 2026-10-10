# Modules — `repository/emilia` as it is on disk

The tree on `feat` (`find repository/emilia -name '*.bp'`) and what each front owns in it.

## Members — two

| Member | `src/` | Tests | Targets | Depends on |
|---|---|---|---|---|
| **`emilia`** (core) | `root.bp`, `tokens.bp` (the one `Token` enum, one banner block per front), `theme.bp`, `spacing.bp`, `output.bp`, `preflight.bp`, `arbitrary.bp`, `container.bp`, `compose.bp`, `attributes.bp`, `emilia.bp` (the host cells, the entry points, `fullTheme` / `fullOptions`, `tokenToSheet`, `named`, the slot functions, one dispatcher block per utility front, and the tests — 610 inline) | inline, in each file (734 across the member); no `test/` directory | `["commonJS", "erlang"]` | std only (decision 114 — no library, dev-dependency included) |
| **`emilia-test`** | `root.bp` (one resolve test; no helper) | inline | inherits | `emilia` (`{ "workspace": true }`) |

Rules: `tokens.bp` is one file; host cells and all that needs them live in `emilia.bp` (a
cross-module bare import of an `#[@External]` declaration is `undefined` at run time);
siblings never import `from "emilia"` — a module of the package is imported by its path (05emilia-h
→ 206: `from "<module of this package>"` is an error); `root.bp`, `botopink.json`, `tokens.bp` append in
front-number order.

## Examples — fifteen members

`emilia-backgrounds`, `emilia-borders`, `emilia-card`, `emilia-cascade`, `emilia-effects`,
`emilia-grid`, `emilia-layout`, `emilia-modifiers`, `emilia-outline-ring`, `emilia-spacing`,
`emilia-text-decoration`, `emilia-theme`, `emilia-transforms`, `emilia-transitions`,
`emilia-typography` — each `botopink.json` + `src/main.bp` with inline tests, both rows, no
`README.md` (PK-2). Only `emilia-card` depends on another library (`"jhonstart": { "path":
"../../../jhonstart/modules/jhonstart" }`), retired by decision 114 (front 33 step 2); CI checks
jhonstart out for it (`.github/workflows/test.yml:94-99`, `00-gate`'s file). The eight cross-front
examples of the 1.0.10 map do not exist (`20-snap` step 4, 390).

## Front → files

| Front | Owns | Runs beside |
|---|---|---|
| **34** (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56) | `modules/emilia/src/**` (every file; the banner blocks of 44, 42, 43, 40, 34, 54, 45 and the hash cell of 56 are the ones it edits), `modules/emilia/AGENTS.md`, `docs.md`, `examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` (they pin the families step 2 moves — `grep -l 'Transition\|Backdrop\|Divide'`) | 33 step 2 |
| **33** (carries the test/examples layer of 1.0.10's 35–48 · 54–59) | `examples/*/README.md` (fifteen), `examples/emilia-card/**` (`modules/emilia-test/**` and the snapshot layer are `20-snap` step 4's) | 34, for step 2 |

The one outside file, `repository/jhonstart/modules/jhonstart/src/html_attrs.bp` (front 48's,
emilia-unaware), has no open item; no front edits it.

## Relations

emilia imports nobody; `jhonstart-emilia` awaits `flush()` / `flushWith(o)` (until `08-bpp/119` deletes it and emilia's sheet goes out through `jhonstart-styled`'s sink, decision 338); onze 68 calls
`styleRule` at build time, asserts the contract-4 literal (`build_test.bp:104`). Class-name hash →
std `hash.contentHash` (34 step 1), literal `e_39b87d03` unchanged — same djb2 fold, no reader moves.
