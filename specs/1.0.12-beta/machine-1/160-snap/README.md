# Front 160 — snap: the snapshot engine; consumer commits only

**Priority:** high — the library tier (decision 433); runs after the 144 steps it names.
**Repository:** `snap` — worktree `--repo snap` (§ Worktree strategy); a step that carries consumer commits runs in a full worktree, one commit per repository, producer first (decision 188)
**Model:** sonnet — a library step whose README fixes the design (`AGENTS.md` § Which model a thread runs on); a step that names another tier keeps it; the Conformance step opus
**Owns:** `repository/snap/**`
**Depends on:** nothing open
**Does not touch:** `repository/botopink-lang/**` — a compiler or std gap is a `language-gaps.md` row and this
front pauses on the 144 step that fixes it (fronts.md rules 1, 9); another library's files except a consumer
commit (decision 188), producer first.
**Gate:** standard (fronts.md § Gate); a moved block keeps its own `**Gate:**` additions.

135 s0 is done (391). The snapshot steps write through it in their own repositories: std 144 B-27 (135 s1),
rakun 150 s24, jhonstart 150 s45, emilia 150 s55, onze 150 s68; the coordination is machine-1/135-snap. It receives
consumer commits only: 144 B-08 (17 sites), B-20, B-28.

### 160 — the caller's location (decisions 718, 719, 756: `file` is `src/main.bp`, not the module path)

**Repository:** snap · **Model:** sonnet · **After:** 144 B-156 (landed), B-149 P1b (the `code` template: the body writes `code @`…``, never `compiler.build` over text, 625), B-137's `compiler.src()` (718), question 160-b (the test's name), and the erlang `Source` constructor (machine 2, B-147)

- [x] every snapshot function that names or places a snapshot is written in 719's shape — `pub fn matches(syntax value: unknown) -> anyvalue { val at = compiler.source(value); return code @`snap.matchesAt(${value}, ${at})`; }` over a run-time `matchesAt(value: unknown, at: Source) -> void` — so the test writes `snap.matches(render(page));` and the snapshot carries the test's file and line; the reference and the engine's own tests updated; front 166's snap cells promote on it (s4); the four public names (`assertText`, `assertAs`, `assertNamed`, `assertNamedAs`) and their consumers (rakun-bpp, …) migrate in the same landing, or the package root keeps them until the consumers move
      — built as: `matches` over `code @`…`` and `compiler.source`, the snapshot named by the running test (772); the four `assert*` names kept and delegating to the engine; `botopink.json` regained `"files": ["snap.bp"]` (its loss left every `import … from "snap"` unbound in rakun); cell `conformance/test/snapshot_named_by_running_test`; rakun-bpp's `src/testing/assert_*.bp`, rakun-ssr's `src/testing/core.bp` and 18 test files and five rakun-bpp examples still call `assertAs` and the like
- [ ] snap's README and AGENTS written with the module-qualified call `snap.matches(x)` — which 144 B-156's last box makes work; the place of a library's test-driven cell (`conformance/test/<cell>/`, which `cell check` does not run) is a question for the coordinator

### 160 — `matchesRefused`: a loaded file's refusals as a snapshot (decision 784)

**Machine:** 2 (decision 785 — machine 1 does not open it) · **Repository:** snap (`--repo snap`) · **Model:** sonnet · **After:** `machine-1/144` B-158 (`compiler.load`, 780, 782, 783)

- [x] `pub fn matchesRefused(syntax loaded: Result<void, Diagnostic[]>) -> anyvalue`, 719's shape like `matches`, over a run-time
      `matchesRefusedAt`: on `Error(ds)` the body is one block per `Diagnostic` — `refused <message>`, `at <file>:<line>:<column>`,
      `label <text>` when there is one —, subject `refused`, through the path rule, `botopink-snap 1` and the `.new` flow; on `Ok` the
      test fails naming the file that compiled
      — built as: `matchesRefusedAt(loaded, written, at)` — `written` the load call as the test wrote it (`compiler.text`),
      the path in the Ok failure being its first string literal, since `Result<void, Diagnostic[]>` carries none; one blank line
      between blocks; the run-time body reads the `Result` with `case`, beam's `try … catch` over it being B-158's open row
- [x] cell `snap_matches_refused` (784): a refused file recorded, a `.new` on a changed refusal, a file that compiles failing the test;
      README and AGENTS name the call
      — built as: `conformance/test/snap_matches_refused/` (a parse error with its label, a type mismatch; the `.new` on a changed
      refusal and the compiled file's failure proved by running — the test runner has no expected-failure form), the loaded files
      under `cases/` until `botopink test` leaves them out of `src/` (B-158's open row), the test calling the bare imported
      `matchesRefused` until B-156's module-qualified call; front 166's `snap_matches_refused-784/` draft beside it

- [ ] 786: `matchesRefused(syntax loaded: Result<Module, Refused>)` — `Ok(m)` fails naming `m.path` (the `written` argument and
      `loadedPath` go); `Error(r)` writes `loaded: <path>` and one `dependency: <name> <source>` per dependency in the header
      after `subject:`, the body unchanged; the cell's two `.snap` re-recorded, their bodies byte-identical · after B-158's 786 box

### 160 Conformance — the front's last step (decision 465)

**Repository:** snap (`--repo snap`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `snap/conformance/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can

