# Modules — `repository/emilia` as it is on disk

The tree on `feat` (`find repository/emilia -name '*.bp'`), and what each front of this track
owns in it.

## Members — two

| Member | `src/` | Tests | Targets | Depends on |
|---|---|---|---|---|
| **`emilia`** (core) | `root.bp`, `tokens.bp` (the one `Token` enum, one banner block per front), `theme.bp`, `spacing.bp`, `output.bp`, `preflight.bp`, `arbitrary.bp`, `container.bp`, `compose.bp`, `attributes.bp`, `emilia.bp` (the host cells, the entry points, `fullTheme` / `fullOptions`, `tokenToSheet`, `named`, the slot functions, one dispatcher block per utility front, and the tests — 610 inline) | inline, in each file (734 across the member); no `test/` directory | `["commonJS", "erlang"]` | std only (decision 114 — no library, dev-dependency included) |
| **`emilia-test`** | `root.bp` (one resolve test; no helper) | inline | inherits | `emilia` (`{ "workspace": true }`) |

The rules hold: `tokens.bp` is one file; the host cells and everything that needs them live in
`emilia.bp` (a cross-module bare import of an `#[@External]` declaration is `undefined` at run
time — 05emilia-h); siblings never import `from "emilia"`; `root.bp`, `botopink.json` and
`tokens.bp` append in front-number order.

## Examples — fifteen members

`emilia-backgrounds`, `emilia-borders`, `emilia-card`, `emilia-cascade`, `emilia-effects`,
`emilia-grid`, `emilia-layout`, `emilia-modifiers`, `emilia-outline-ring`, `emilia-spacing`,
`emilia-text-decoration`, `emilia-theme`, `emilia-transforms`, `emilia-transitions`,
`emilia-typography` — each `botopink.json` + `src/main.bp` with inline tests, both rows, no
`README.md` (PK-2). `emilia-card` alone depends on another library (`"jhonstart": { "path":
"../../../jhonstart/modules/jhonstart" }`), which decision 114 retires (front 33 step 2); the
repository's CI checks jhonstart out for it (`.github/workflows/test.yml:94-99`, `00-gate`'s
file). The eight cross-front examples of the map do not exist (front 33 step 4, conditional).

## Front → files

| Front | Owns | Runs beside |
|---|---|---|
| **34** (carries 1.0.10's 40 · 42 · 43 · 44 · 45 · 54 · 56) | `modules/emilia/src/**` (every file; the banner blocks of 44, 42, 43, 40, 34, 54, 45 and the hash cell of 56 are the ones it edits), `modules/emilia/AGENTS.md`, `docs.md`, `examples/emilia-{transitions,effects,outline-ring,transforms}/src/main.bp` (they pin the families step 2 moves — `grep -l 'Transition\|Backdrop\|Divide'`) | 33 steps 1–2 |
| **33** (carries the test/examples layer of 1.0.10's 35–48 · 54–59) | `modules/emilia-test/**`, `examples/*/README.md` (fifteen), `examples/emilia-card/**`, `examples/<eight new>/**` (step 4), `modules/emilia/test/**` (step 3 — new directory) | 34, for steps 1–2; after 34 for steps 3–4 |

The one file outside the repository, `repository/jhonstart/modules/jhonstart/src/html_attrs.bp`
(front 48's, emilia-unaware), has no open item and no front edits it.

## Relations

emilia imports nobody; `jhonstart-emilia` awaits `flush()` / `flushWith(o)`; onze 68 calls
`styleRule` at build time and asserts the contract-4 literal (`build_test.bp:104`). The class-name
hash becomes std's `hash.contentHash` (front 34 step 1) with the literal `e_39b87d03` unchanged —
the same djb2 fold, so no reader moves.
