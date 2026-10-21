# Front 107 — release: a shared `release`, the OTP release text both frameworks render (conditional on `07-g`)

**Priority:** medium (decision 433) — opens after the library tier, or in a free thread when nothing it needs
is open.
**Repository:** `rakun` (`modules/rakun-release`, a package of the workspace born in s1, decision 917) — worktree `--repo rakun`; s2's consumer commits (`rakun-cli`, `rakun-ssr`) are the same repository's
**Model:** sonnet — the README fixes the design (`AGENTS.md` § Which model a thread runs on); the Conformance step opus
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.
**Owns:** `repository/release/**` when born (`botopink/release`), the consumer lines step 2 names.
**Depends on:** `07-g` (a) · rakun 150 s7 (81) · onze 150 s62 (71). Goal: [`03-bundled-libs/107-release`](107-release/context.md).

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `107-release` s1 | 107 s1 |
| `107-release` s2 | 107 s2 |

## Steps

### 107 s1 — the package

**Repository:** `rakun` (`--repo rakun`, `modules/rakun-release`; decision 917) · **Model:** sonnet

#### Step 1 — the package (was `107-release` s1)

`rel(spec)`, `vmArgs(spec)`, `sysConfig(props)` (a `.bp` Erlang-term writer — strings, atoms,
integers, lists, tuples, maps — replacing the `rkRelTerm` sidecar cell), `bootScript(spec)`,
`dockerfile(spec)`, `appup(from, to)`.

- [ ] each renderer byte-identical to rakun's release output for one fixed spec, both rows
- [ ] rakun-ssr's release's two recorded snapshots reproduced byte for byte (390 (3)):
      `modules/onze-release/test/__snapshots__/release/text_rel_sys_config_vm_args_and_the_boot_script.snap`
      (`.rel`, `sys.config`, `vm.args`, boot script) and
      `dockerfile_two_stages_non_root_erts_bundled_and_not.snap` (Dockerfile with and without ERTS) —
      kept as recorded, this front's contract
- [ ] the term writer round-trips through `erl -eval 'file:consult(...)'` in an erlang test cell

### 107 s2 — consumers

**Repository:** rakun, onze — the consumer commits, a full worktree (decision 188) · **Model:** sonnet

#### Step 2 — consumers (was `107-release` s2)

- [ ] rakun-cli's release imports the package; `rkRelTerm` deleted; its tests green
- [ ] rakun-ssr's release imports the package; `otp.bp` / `docker.bp` / `spec.bp` keep only rakun-ssr's spec
      shape; its 9 tests green on both rows

### 107 Conformance — the front's last step (decisions 465, 474, 477, 478, 479, 480)

**Repository:** release (`--repo release`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `release/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can
