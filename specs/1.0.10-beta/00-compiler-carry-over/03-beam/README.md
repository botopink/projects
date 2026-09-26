# Front 03 — beam

**Priority:** high — beam is the backend the language suite reaches only through `--target beam`,
so a defect here is quiet unless someone runs it
**Depends on:** [`01-checker`](../01-checker/README.md), **per row, not as a front** — see
[Dependencies](#dependencies)
**Owns:** `modules/compiler-core/src/codegen/beam_asm.zig` ·
`modules/compiler-core/src/codegen/beam/**` · the beam snapshots under
`modules/compiler-core/snapshots/codegen/<runtime>/beam/**` · `scripts/beam_export_audit.sh` ·
the `KNOWN` notes and new fixtures of its rows in `modules/compiler-core/src/codegen/tests/**`
(a carve-out from [`07-review-backlog`](../07-review-backlog/README.md))
**Does not touch:** `src/comptime/**`, `src/parser/**` ([`01-checker`](../01-checker/README.md)) ·
`src/codegen/erlang.zig`, `src/codegen/crossModule.zig` ([`02-erlang`](../02-erlang/README.md)) ·
`src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`
([`04-js`](../04-js/README.md)) · `src/codegen/wat.zig`, `src/codegen/wat/**`
([`05-wasm`](../05-wasm/README.md)) · `modules/compiler-cli/**`

Paths are relative to `repository/botopink-lang/`. Carry-over items: C-03, C-06, C-07, C-24 — see
[`../README.md`](../README.md). How a beam program is run by hand: `botopink build --target beam`,
then `erlc +from_asm out/beam/*.S`, then `erl -noshell -pa out/beam -eval "'<pkg>@main':'_botopink_main'(), halt()."`;
`tests/language/run.sh --target beam` does the same for every `run/` and `modules/` cell.

---

## Steps

Decision 8 at run time holds on beam; its named-type half (records, variants, `is Person`, a union of
named types) is carried by [`13-module-identity`](../13-module-identity/README.md) — decision 109's
atoms and the identity inside the value.

### Step 1 — BR5: `@External.Erlang` templates compiled at build time — delivered (C-24)

A template is compiled into the module at build time instead of being evaluated from source through
`'__bp_erl_eval'` at run time. It reuses the comptime runtime's Erlang reader
(`comptime/runtime/wat/erl_parse.zig`) and BEAM lowering (`comptime/runtime/beam/lower.zig`) — no
second template language (`decisions-pending.md` 0203-b). A template `lower.zig` refuses keeps the
run-time path, named in `src/codegen/beam/AGENTS.md` § `@External.Erlang` templates compiled at build
time.

- [x] no `'__bp_erl_eval'` left in any beam snapshot, **and** the remaining run-time use named with its
  reason in `src/codegen/beam/AGENTS.md` — a template `lower.zig` refuses (`receive`, `!`,
  `try … of`, …; a handful of `libs/std`'s templates by text)
- [x] every RUN LOG unchanged — the beam snapshots re-record `.S` only, compared RUN LOG by RUN LOG
- [x] `scripts/beam_export_audit.sh` still assembles every module
- [x] the cost recorded in `src/codegen/beam/AGENTS.md`: a call through the compiled template costs
  about what the call written directly costs (1.06–1.16×), where the run-time evaluator cost ~50×

### Step 2 — the formatter: decision 1a and §7 — delivered

A nested string prints as `"a"` with source escapes, a tuple as `#(1, "a")`, `, ` after each
separator, `5.0`, records and variants in source shape, `Display` consulted; absent prints `null`
(decision 47). `run/tuple_print.bp`, `run/print_formatter.bp` and `run/display_print.bp` pass on beam.
No `'__bp_erl_eval'` is left: the comptime runtime's Erlang reader and BEAM lowering compile every
shipped template (177 / 177), and a refused one is a located build error (decision 141).

### Step 3 — decision 8 at run time — delivered, with C-07's tails open

| # | Row | State |
|---|---|---|
| D1–D3 | `x is T` by value; `unknown` and unions store nothing extra (§11); `==` with an `unknown` operand compares numbers by value (§2.3) | delivered; C-07's fixture tails under [Open rows](#open-rows-with-no-numbered-step) |
| D4 | `case` arms (§5): a tuple pattern, `..`, labels, literals and type names are tested; `A...B` is two `is_ge` tests (decision 53, C-06); `x is Enum.Variant` tests that variant | delivered |
| D5 | tuple labels → positional (§6 T4); an enum variant's labelled argument claims its declared slot | delivered |
| D6, D7 | a condition loop with a value `break`; `break <value>` | superseded by decision 105 (`while` / `for` are statements, `break v` only in a generator scope — [`22-loops`](../22-loops/README.md)) |

### Step 4 — a method on a type from another module — delivered

A method whose owning type came from another module is a remote call to the owning module's function,
not a `call_fun` on the record.

- [x] `modules/two_modules` and `modules/std_import`, assembled and run by hand, print `3`/`0` and `1`
- [x] a fixture in `src/codegen/tests/**` pins a method on an imported type, with a RUN LOG
- [x] `beam_export_audit.sh` still assembles every module

### Step 5 — the block-as-value lowering decision 2 leaves dead — nothing to delete

Recorded in `src/codegen/beam/AGENTS.md` § Closure values: of the places that build a fun
(`make_fun3`), none is a block as a value — `@block` runs in the frame. The row closes with 01's R7
without a beam change.

### Rows no step named — delivered

The cross-module name index reaches `beam_asm.zig` whole — an export two modules declare, a record
field and a type name two modules declare resolve by the module the import names
(`modules/{export,field,type,method}_name_collision` pass on beam); a field read or a method call the
emitter cannot place asks the value; the module body runs once, in declaration order, before `main`;
a `return` inside a loop body leaves the function; a top-level `fn` named as a value is its fun; a
non-ASCII string literal is its UTF-8 bytes; `@todo` and `@panic` raise the erlang backend's
`{todo, Msg}` / `{panic, Msg}`; each module keeps its own synthesized helpers. C-03's beam half: a
`pub` host `declare fn` whose `@External.Erlang` body is a template has a wrapper tail-calling the
template compiled at build time, so another module reaches it (`fs.exists`, `os.eol` —
`run/std_template_host_fns_across_modules`). `String.split("")` cuts into codepoints: the method runs
std's template instead of `string:split/3` (`run/string_split_empty_separator`, all four targets).

### Open rows with no numbered step

- **Decision 8's tails (C-07)** — every `tests/language` cell naming §2, §4, §5, §6 runs on beam and
  matches its `.out`, each with a beam fixture whose RUN LOG is the value run; the tuple / `..` /
  type-pattern fixtures [`02-erlang`](../02-erlang/README.md) added have beam twins; §4.1's truth
  table answered by each §4.2 form on beam.
- **A method after a `?.` link** — `run/optional_chain_method.bp`: the erlang shape through
  `erlc +from_asm` — `2`, `3`, then the run fails at the absent probe (the method after the `?.` link
  is called on the absent value).
- **JS-4's beam twin** — `val Circle(r) = s;` checks and assembles, and the run aborts with
  `{unresolved_identifier, r}`: the `.ctor` destructure binds nothing. See
  [`04-js/pattern-binding.md`](../04-js/pattern-binding.md).

## Dependencies

| This front's row | Needs from [`01-checker`](../01-checker/README.md) |
|---|---|
| C-07's tails | nothing |
| JS-4's beam twin | nothing — R5 landed |
| step 5 | step 8's R7 (no beam change) |

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree — not green for an environmental reason
  (the `test-libs` stage reads the main checkout's rakun and jhonstart, which had moved ahead of the
  front's std); every other stage green run on its own — see `02-erlang`'s gate
- [x] `scripts/beam_export_audit.sh` assembles every module, before and after each row
- [x] every re-recorded RUN LOG **verified by running the program** — the beam snapshot harness runs
  `erlc +from_asm` and `erl` itself; each moved block compared by hand; BR5 and the `@todo` reason
  moved no RUN LOG
- [x] every `tests/language` cell this front's rows touch run on beam and matched against its
  `.out` (`run.sh --target beam`); the beam lines left are the `*` reject cells of `01` and
  `run/optional_chain_method.bp`
- [x] `src/codegen/AGENTS.md` and `src/codegen/beam/AGENTS.md` updated in the same commit as each row
- [x] Commit on a branch; no push, no merge — `front/02-03-erlang-beam`

## Notes

- **beam's run-time abort on an unbound name is the backstop, not a fix.** Keep
  `{unresolved_identifier, N}`; the check is the checker's.
- **`scripts/beam_export_audit.sh` is this front's gate, not a formality.** It is the only mechanical
  proof that every emitted `.S` assembles.
- **beam is outside `run.sh --target all`** (joining it is a one-line flip in `run.sh`, scheduled as
  13's closing step — [`12-language-tests`](../12-language-tests/README.md) step 3), so a `run/` or `modules/` cell another front adds is measured on
  beam only when someone runs `--target beam`. Run it once by hand for every such cell.
- **This front moves only beam snapshots.** If a change here moves the erlang snapshots, the shared
  template reader crossed into [`02-erlang`](../02-erlang/README.md) — stop and report.
