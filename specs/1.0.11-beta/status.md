# Status — 1.0.11-beta

**Updated:** 2026-09-27 · **Progress:** ~5 % (4 of 65 fronts landed: 99-rakun, 100-onze, 112-format, 114-docs-and-ci; 110 at 2 of 3 steps; the milestone opened today at
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

- [ ] `00-gate/99-gate-rakun` — critical · steps 1–7 done on `front/99-gate-rakun` (rakun submodule): 25 / 25 modules green under `botopink test` erlang with the pinned compiler (1,817 / 0), 3 / 3 examples build, hook and CI are refusals only, `modules/{rakun,rakun-app}` format-clean; left: the workflow green on `feat` (the landing step) and the meta gate's stage 8 (113 reads it)

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
- [ ] `00-gate/110-gate-wasm` — critical · blocked on `ck-host` for its last step only
- [ ] `00-gate/100-gate-onze` — critical · blocked on nothing
- [ ] `00-gate/101-gate-jhonstart` — high · blocked on nothing
- [ ] `00-gate/108-gate-erika` — medium · blocked on nothing
- [ ] `00-gate/109-gate-emilia` — medium · blocked on nothing
- [ ] `00-gate/114-gate-docs-and-ci` — high · any time · `gate-e`, `gate-f`, `gate-j`
- [ ] `02-std-and-packaging/97-std-dedupe` — high · after `00-gate` · blocked on nothing
- [ ] `01-compiler/01-checker` · `02-erlang` · `03-beam` · `04-js` · `05-wasm` · `14-comptime-on-beam` · `26-cli-tooling` — group A · after `00-gate`
- [ ] `01-compiler/12-language-tests` · `18-comptime-runtimes` · `23-std-purity` · `24-effects-by-return` · `25-gate-perf` — group B · after `00-gate`
- [ ] `03-rakun` group A: `04-rakun-erlang-runtime` (critical) · `74-rakun-tls-ssl-bundles` · `08-rakun-data-sql` · `15-rakun-messaging` · `79-rakun-oauth2-sso` · `81-rakun-packaging-release` · `93-rakun-soap-webservices` · `19-rakun-test-utilities` step 1 — after `99-gate-rakun`
- [ ] `04-jhonstart/26-jhonstart-router` (high) · `27-jhonstart-link` — after `101-gate-jhonstart`
- [ ] `05-emilia/34-emilia-modifiers` (high) · `33-emilia-color-palette` steps 1–2 — after `109-gate-emilia` and 97 (`contentHash`)
- [ ] `06-onze/49-onze-stand-up` (critical) · `50-onze-cli` · `51-onze-image` · `71-onze-release-packaging` — after `100-gate-onze`

## Deferred out of this milestone

- `03-rakun/91-rakun-pulsar`'s data plane → a decision (`03r-ad`, recommendation: defer until a
  broker double exists); the front carries the codec and admin arm only.
- `03-rakun/79`'s SAML ACS → `03r-ae` (no Exclusive XML c14n on OTP or std).
- The snapshot maps of rakun, jhonstart, emilia, std → one answer for all (`03r-ag`, `30-h`,
  `05emilia-m`, `01std-f`; recommendation: retire, keep the helpers a contract needs).
- Everything in [`deferred.md`](./deferred.md), carried.
