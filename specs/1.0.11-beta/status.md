# Status — 1.0.11-beta

**Updated:** 2026-09-26 · **Progress:** ~1 % (0 of 65 fronts landed, 110 at 2 of 3 steps; the milestone opened today at
1.0.10-beta's close — [`closure.md`](../1.0.10-beta/closure.md))

Count: `00-gate` 11 · `01-compiler` 17 · `02-std-and-packaging` 2 · `03-rakun` 19 · `04-jhonstart` 3 ·
`05-emilia` 2 · `06-onze` 5 · `07-bundled-libs` 6. A front in analysis counts for its ticked steps.
Order inside each list follows [`overview.md`](./overview.md) § Order (most blocking first).

**The gate at the open** (measured 2026-09-26, `scripts/gate.sh --cold` forced past reds): 8 of 10
stages green; `test-libs` 84 passed / **36 failed** (rakun 25, onze 11); `test-language` 1244 / 1
expected / **1 failed** (wasm); 3 `expected-failures.txt` lines; 21 `restricted-targets.txt` lines
(3 dead, 21 cells unledgered, 9 counts moved); 226 files outside `format-check`'s trees; 11 `zig
fmt` reds; 9 `docs-check: skip`; windows `allow_fail`. Each repository under its own gate: emilia,
erika, jhonstart, vscode-extension **green**; onze ~29 %; rakun ~17 % and its pre-commit fails at
the grep stage before any test.

## Done

- (none)

## In analysis

- [ ] `00-gate/114-gate-docs-and-ci` — high · steps 1–4 done in the front's worktree: `check-docs.sh` has `reject`/`project` and no `skip` (`docs: 94 fences — 94 checked, 0 skipped, 0 failed`, self-tested), the windows row of botopink-lang's `test.yml` is deleted (gate-f: the drift was not measured — no windows runner; the row returns hard or not at all), the meta `hook-integrity.yml` exists with five hard checks · the botopink-lang commits wait, staged, on a green gate (stage 8 `test-libs` red at the `feat` tip — 99, 100) · checks 4 and 5 of the meta workflow go green with 99, 100, 109, 113
- [ ] `00-gate/110-gate-wasm` — critical · steps 1–2 done (the link loop mangles every colliding declaration; every silent-degradation site refuses; `run.sh --target wasm` 0 failed) · step 3 blocked on `ck-host` — measured: `asserts` has three host cells (`canonical`, `regexMatches`, `tryCatch`), two with no possible wasm lowering, so (a) as recommended does not build `asserts` on wasm

## Pending

- [ ] `00-gate/111-gate-beam-and-targets` — ready · waits on 110 and 112 (`run.sh`, the wasm line)
- [ ] `00-gate/113-gate-ledger-and-scripts` — ready · waits on 99–109, 111, 112 (the counts) and on `gate-a`, `gate-b`, `gate-d`
- [ ] `00-gate/115-gate-perf` — ready · waits on every other `00-gate` front (it times a green gate)
- [ ] `07-bundled-libs/102-routing-conventions` · `103-actions-id` · `104-http` — ready · wait on `00-gate` green and `97-std-dedupe`; 104 on `07-a`, `07-d`, `07-e`
- [ ] `07-bundled-libs/105-i18n` — waits on 104 and `07-c`
- [ ] `07-bundled-libs/106-log` · `107-release` — wait on `07-f` / `07-g` (conditional fronts)
- [ ] `03-rakun` group B (13 · 17 · 22 · 12 · 11 · 65 · 09 · 91 · 92 · 73) — wait on `99-gate-rakun` and group A's `04` step 1
- [ ] `03-rakun` group C (88 · 19 steps 3–5) — wait on group B
- [ ] `04-jhonstart/67-jhonstart-forms` — waits on 26 (the fake DOM) and 103 (`form.bp`)
- [ ] `05-emilia/33-emilia-color-palette` steps 3–4 — wait on `05emilia-m` and on 34
- [ ] `06-onze/53-onze-example-app` — waits on 49 · 50 · 51 · 71 and on `03-rakun` 22 / 65 (the write path, the public root)
- [ ] `02-std-and-packaging/98-packaging-tail` — waits on every library track (it verifies across seven repositories)
- [ ] `01-compiler/17-beam-memory` — waits on 02, 03 and `17-a`
- [ ] `01-compiler/16-formatter` — waits on `00-gate` (112), the libraries' migrations and 01's parser rows
- [ ] `01-compiler/07-review-backlog` · `08-hygiene` · `09-ecosystem-residuals` — wait on 02–05, on every owner, on 16

## Open

- [ ] `00-gate/112-gate-format` — critical · lands first inside wave 0 · blocked on nothing
- [ ] `00-gate/99-gate-rakun` — critical · blocked on nothing (`gate-g` confirms `rc3-a`; the migration proceeds under the recommendation)
- [ ] `00-gate/100-gate-onze` — critical · blocked on nothing
- [x] `00-gate/101-gate-jhonstart` — done: 29/29 cells, hook and CI hard, `repro/` gone, PK-5 reformat but for `link.bp` (the formatter mangles `..p` — `112`)
- [x] `00-gate/108-gate-erika` — done: 6/6 cells (`erika-linq` widened to erlang), hook and CI hard, no `beam` row, guard files byte-identical to jhonstart's
- [ ] `00-gate/109-gate-emilia` — medium · blocked on nothing
- [ ] `02-std-and-packaging/97-std-dedupe` — high · after `00-gate` · blocked on nothing
- [ ] `01-compiler/01-checker` · `02-erlang` · `03-beam` · `04-js` · `05-wasm` · `14-comptime-on-beam` · `26-cli-tooling` — group A · after `00-gate`
- [ ] `01-compiler/12-language-tests` · `18-comptime-runtimes` · `23-std-purity` · `24-effects-by-return` · `25-gate-perf` — group B · after `00-gate`
- [ ] `03-rakun` group A: `04-rakun-erlang-runtime` (critical) · `74-rakun-tls-ssl-bundles` · `08-rakun-data-sql` · `15-rakun-messaging` · `79-rakun-oauth2-sso` · `81-rakun-packaging-release` · `93-rakun-soap-webservices` · `19-rakun-test-utilities` step 1 — after `99-gate-rakun`
- [ ] `04-jhonstart/26-jhonstart-router` (high) · `27-jhonstart-link` — after `101-gate-jhonstart`
- [ ] `05-emilia/34-emilia-modifiers` (high) · `33-emilia-color-palette` steps 1–2 — after `109-gate-emilia` and 97 (`contentHash`)
- [ ] `06-onze/49-onze-stand-up` (critical) · `50-onze-cli` · `51-onze-image` · `71-onze-release-packaging` — after `100-gate-onze`

## Deferred out of this milestone

- botopink-lang CI on windows: the row is deleted (114, gate-f), so nothing measures the compiler on
  windows until the snapshot capture's CRLF / path-separator drift is measured on a windows runner and
  normalised in the test framework (114 step 3, carried); the libraries' own windows rows stay hard.
- `03-rakun/91-rakun-pulsar`'s data plane → a decision (`03r-ad`, recommendation: defer until a
  broker double exists); the front carries the codec and admin arm only.
- `03-rakun/79`'s SAML ACS → `03r-ae` (no Exclusive XML c14n on OTP or std).
- The snapshot maps of rakun, jhonstart, emilia, std → one answer for all (`03r-ag`, `30-h`,
  `05emilia-m`, `01std-f`; recommendation: retire, keep the helpers a contract needs).
- Everything in [`deferred.md`](./deferred.md), carried.
