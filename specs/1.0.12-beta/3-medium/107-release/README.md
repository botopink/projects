# Front 107 — release: a shared `release`, the OTP release text both frameworks render (conditional on `07-g`)

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** `repository/release/**` when born (`botopink/release`), the consumer lines step 2 names.
**Depends on:** `07-g` (a) · rakun 150 s7 (81) · onze 162 s4 (71). Goal: [`03-bundled-libs/107-release`](107-release/context.md).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `107-release` s1 | 107 s1 |
| `107-release` s2 | 107 s2 |

## Steps

### 107 s1 — the package

#### Step 1 — the package (was `107-release` s1)

`rel(spec)`, `vmArgs(spec)`, `sysConfig(props)` (a `.bp` Erlang-term writer — strings, atoms,
integers, lists, tuples, maps — replacing the `rkRelTerm` sidecar cell), `bootScript(spec)`,
`dockerfile(spec)`, `appup(from, to)`.

- [ ] each renderer byte-identical to rakun's release output for one fixed spec, both rows
- [ ] onze-release's two recorded snapshots reproduced byte for byte (390 (3)):
      `modules/onze-release/test/__snapshots__/release/text_rel_sys_config_vm_args_and_the_boot_script.snap`
      (`.rel`, `sys.config`, `vm.args`, boot script) and
      `dockerfile_two_stages_non_root_erts_bundled_and_not.snap` (Dockerfile with and without ERTS) —
      kept as recorded, this front's contract
- [ ] the term writer round-trips through `erl -eval 'file:consult(...)'` in an erlang test cell

### 107 s2 — consumers

#### Step 2 — consumers (was `107-release` s2)

- [ ] rakun-cli's release imports the package; `rkRelTerm` deleted; its tests green
- [ ] onze-release imports the package; `otp.bp` / `docker.bp` / `spec.bp` keep only onze's spec
      shape; onze-release's 9 tests green on both rows
