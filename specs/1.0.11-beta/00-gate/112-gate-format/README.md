# Front 112 — gate-format: every `.bp` tree canonical and in `TREES`, every `.zig` file formatted, the one unformattable fixture exempt by structure

**Priority:** high — stage 3 is green only because 226 red files sit in trees it does not walk,
and 11 `.zig` files are a red the gate meets the day a front stages one.
**Depends on:** none — lands first in group A (a reformat commit is the cheapest thing for every
other front to rebase over). `110` rebases its `asserts.bp` edit; `111` writes its new cells
formatted.
**Owns:** `scripts/format-check.sh` (`TREES`, the header) · `modules/compiler-cli/src/cli/format_cmd.zig`
(the structural exemption, gate-c) · the 11 `zig fmt` files (a `zig fmt` commit, no other change) ·
**reformat-only commits** over `libs/std/src/**` (19 files, with the 26 snapshots that quote them),
`examples/**`, `modules/compiler-cli/tests/**/*.bp`, `modules/manifest/tests/**/*.bp`,
`tests/language/{test,run,modules}/**/*.bp` (with the four `.expect` lines of the one cell whose
pinned location the reformat moves) · stage 1 of `scripts/gate.sh` (`zig fmt --check modules`) ·
`scripts/AGENTS.md` § format-check.sh · **two printer rows** of `../../01-compiler/16-formatter`,
assigned here because they block this front's trees: the record-update spread and the tail `catch`
(`modules/compiler-core/src/format.zig`, with `ast.zig`'s `tryCatch.tryKeyword` /
`spread_arg_label` and the parser's `try` arm).
**Does not touch:** any source change in the trees it reformats (a reformat commit is
`botopink format` output and nothing else — a hand edit in it is a red flag for the reviewer); the
formatter's rules (`../../01-compiler/16-formatter`'s: decision 132's `;` refusal lands *after* this
front, on the migrated trees); `wat.zig` (110), `run.sh` (111).

---

## Problem

```
$ bash scripts/format-check.sh
  ✓ examples/modules  ✓ libs/std/src/builtins.d.bp  ✓ libs/std/src/builtins_fns.d.bp  ✓ libs/routing  ✓ libs/actions  ✓ libs/validation
$ zig-out/bin/botopink format --check libs/std | grep -c "would reformat"
19
$ zig fmt --check modules | wc -l
11
```

Stage 3 walks six trees (`format-check.sh:41-48`). Outside them, measured at the open with
`botopink format --check <tree>`: `libs/std` 19 files (async, collections, encoding, erlang,
escape, hash, io/clock, io/net, io/random, json, math, path, primitives, querystring, regex,
testing/asserts, testing/mocks, testing/snapshots, url — the header at `:14-16` claims 2);
`examples/generic-loader-binding` 1; `examples/stdlib-tour` 1; `tests/language` 199 would-reformat
(modules/ 37, run/ 105, test/ 57 — the header at `:20-27` says "run/ 9 of 22, test/ 42 of 49",
two milestones stale) + 1 cannot-format (`modules/lexer_error_in_imported_module/src/pattern.bp:3`,
a deliberate bad escape); `modules/compiler-cli/tests` 5 fixtures at two-space indent. `zig fmt
--check modules` (verified at the open): `bpmp/src/commands/{self_uninstall,self_update}.zig`,
`bpmp/src/{registry,storage}.zig`, `compiler-cli/src/cli/test_cmd.zig`,
`compiler-core/src/comptime/{env,infer}.zig`, `compiler-core/src/comptime/runtime/beam/{lower,program}.zig`,
`compiler-core/src/parser/patterns.zig`, `language-server/src/engine.zig` — the gate checks staged
`.zig` only (`gate.sh:131-133`), so each is a latent red.

## Current state

On `front/112-gate-format` (each line re-measured on the working tree it describes):

- `zig fmt --check modules` → exit 0, no file; `gate.sh` stage 1 runs it on every run (the staged
  check stays as the commit's fast path).
- `format_cmd.zig` has the second structural arm (gate-c option b): a `.bp` under `modules/<cell>/`
  that one of the cell's `<target>.expect` files names on its second line **and** that does not
  lex or parse is left out of the walk; pinned by the test "gate-c: …" with a synthetic cell. No
  list, no flag. `tests/language/modules/lexer_error_in_imported_module/src/pattern.bp` is
  byte-identical to the open.
- **The printer round-trips every tree.** Two arms printed text the parser refuses, both fixed at
  the cause with rows in `format/tests/expressions.zig`:
  - the record-update spread — `Cfg(..base, revalidate: 60)` was printed `Cfg(..: base, …)`
    ("this token cannot appear here"). The parser holds the spread as the argument labelled `..`
    (`ast.spread_arg_label`); `fmtCallWithReceiverDoc` prints it back `..base`.
  - the tail `catch` — `assert (parse(7) catch -1) == 7;` was printed with a `try` under the
    parentheses (`error[try-await-operand]`). `try e catch h` and `e catch h` are one node;
    `tryCatch.tryKeyword` (set by the parser's `try` arm, left out of the AST dump) records which
    was written, and the printer writes `try ` only then.

  Measured with the fixed binary: each tree of this checkout and each of the five sibling
  libraries, formatted as a scratch copy and checked again — every file re-parses and a second
  pass moves 0 files (508 + 673 files walked); against the parent binary's output the fix moves
  8 files, every hunk one of the two shapes (25 spreads, 2 `catch`). No third defect.
- **Every tracked `.bp` of the checkout is canonical and under `TREES`**, or structurally exempt:
  `TREES` = `examples`, `libs/std`, `libs/routing`, `libs/actions`, `libs/validation`,
  `libs/log`, `libs/http`, `modules/compiler-cli/tests`, `modules/manifest/tests`, `tests/language`
  (`libs/log` and `libs/http` joined with their packages); `format-check.sh` →
  every tree ✓ (at this front's measurement, before `libs/log` and `libs/http`: 508 files walked; the 173 `reject/` cells and `pattern.bp` are outside the walk
  by structure — 682 tracked `.bp` in all). Reformat-only, per tree:
  - `examples` — 2 files (`generic-loader-binding`, `stdlib-tour`); `modules/compiler-cli/tests`
    — 5 fixtures; `modules/manifest/tests` — 5 fixtures (`import { core }` → `import {core}`).
  - `tests/language/run` 105 and `test` 57 files; `modules` 37 files, the last of them
    `decorator_imported_function_name_conflict/src/main.bp`, whose four `.expect` files move
    their pinned location with it (`src/main.bp:17:3` → `:21:3`, the same `#[tag]`, verified on
    all four targets). `run.sh --target all` 1251 passed / 1 expected / 0 failed and
    `--target beam` 383 / 2 / 1 before and after (the beam red is `run/array_spread_literal.bp`,
    red on the parent binary too — `111`'s).
  - `libs/std` — 19 files, with the 26 snapshots that quote std source re-recorded in the same
    change: the 24 `std_package_*` codegen snapshots differ in the `SOURCE CODE --
    std/collections.bp` section alone (old section = the parent's file, new section = the
    reformatted file, every generated section byte-identical), `lsp/completion_array_methods` in
    `flatMap`'s quoted signature (now over four lines), `lsp/definition_std_module_member` in the
    line of `toInt` in the embedded source (512 → 517, the reformat's net +5 lines above it).
    `botopink test` in `libs/std`: 433 passed / 0 failed on commonJS and on erlang, before and
    after; `test-libs -- --lib std` 2 passed. `src/async.bp`'s DO-NOT-FORMAT banner is deleted in
    a commit of its own: the trailing comma after a fn-typed parameter it warned about parses.

**Remaining:** the commits. Everything above sits in the working tree of
`repository/botopink-lang` on `front/112-gate-format`; the pre-commit hook runs the whole gate,
whose stage 8 is red on the ledgers `113-gate-ledger-and-scripts` deletes. Once 113 is on `feat`:
merge `feat`, `scripts/gate.sh --cold`, commit (printer fix · one reformat commit per tree ·
`TREES` and the docs), push.

## Mechanism

`botopink format` is the migrator for a tree the formatter owns (`../../01-compiler/README.md`
FC-4): the `tests/language` files differed from canonical by the `;` after a braced block the
printer no longer writes (C-13) and by decision 65's method-chain and lambda rules (C-12/C-14),
which `libs/std` and the two examples also carried. None of it is a semantic change; each reformat
is verified by the cells it touches staying green before and after. A tree the printer cannot
round-trip is a printer defect, fixed in the printer; a reformat that moves a text something else
quotes (a snapshot, an `.expect` location) carries that with it in the same commit.

## Steps

### Step 1 — `zig fmt` the 11 files; stage 1 checks the tree

**Acceptance:**
- [x] `zig fmt --check modules; echo $?` → `0`, no output
- [x] `scripts/gate.sh` prints a `zig fmt --check modules` line in stage 1 and fails on a synthetic unformatted file

### Step 2 — reformat and add to `TREES`: `libs/std`, the examples, the fixtures

**Acceptance:**
- [x] `TREES` lists `examples`, `libs/std`, `libs/routing`, `libs/actions`, `libs/validation`, `modules/compiler-cli/tests`, `modules/manifest/tests` (and `libs/log`, `libs/http` since their packages); `bash scripts/format-check.sh` → every line ✓
- [x] `botopink test` in `libs/std` on commonJS and erlang: 433 passed before and after; `zig build test-libs -- --lib std` green; `zig build test-cli` green
- [x] the 26 snapshots that quote std source re-recorded with the reformat, each differing by the quoted text (or its line) alone

### Step 3 — `tests/language` reformatted and in `TREES`; the lexer-error cell exempt by structure (gate-c)

**Acceptance:**
- [x] the printer round-trips the tree: the spread and the tail `catch` (regression rows in `format/tests/expressions.zig`)
- [x] `zig-out/bin/botopink format --check tests/language` → exit 0, 402 `Unchanged` lines (`reject/**` and `pattern.bp` print nothing); `pattern.bp` byte-identical to the open
- [x] `bash tests/language/run.sh --target all` and `--target beam` print the same tallies before and after the reformat (1251 / 1 / 0 and 383 / 2 / 1)
- [x] the `format_cmd.zig` test for the structural exemption

### Step 4 — the header and the docs

**Acceptance:**
- [x] `scripts/format-check.sh`'s header, `scripts/AGENTS.md` § format-check.sh, `tests/language/AGENTS.md` § 66, `modules/compiler-core/src/format/AGENTS.md`, `libs/std/AGENTS.md` and `gate.sh`'s stage-3 text name no red tree and no tree that waits

## Gate

- [x] `zig build test` from a cold runtime cache, green; `zig build test-cli` green; `scripts/snap_audit.sh --mode=runtime-parity` green
- [x] `bash scripts/format-check.sh` → every tree ✓; `zig fmt --check modules` → exit 0
- [x] `bash tests/language/run.sh --target all` and `--target beam`: tallies unchanged by this front
- [x] `bash scripts/check-docs.sh`: 94 fences, 94 checked, 0 failed, before and after
- [x] `scripts/gate.sh --cold` green in this front's worktree — satisfied by the landing: `scripts/gate.sh --cold` green on the integrated `feat` (2026-10-02), zig fmt and format-check stages green
- [x] commits on `front/112-gate-format` in `repository/botopink-lang`, pushed — satisfied by the landing: on botopink-lang's remote `feat` under the green cold gate

## Blast radius

- Every `../../01-compiler/` front that owns one of the 11 `.zig` files (01: `env.zig`, `infer.zig`,
  `patterns.zig`; 14: `runtime/beam/{lower,program}.zig`; 26: `bpmp/**`, `test_cmd.zig`,
  `engine.zig`) rebases over a `zig fmt` commit — mechanical.
- `../../01-compiler/16-formatter` C-13 step 3 loses `tests/language` from its migration count
  (199 files here) and the two printer rows this front fixed (the record-update spread, the tail
  `catch`). It keeps rakun/jhonstart/emilia/onze — 285, 54, 26 and 85 files would reformat at
  their pinned commits, erika none; each round-trips with the fixed printer — and lands decision
  132's refusal after them.
- `../../02-std-and-packaging/97-std-dedupe` and `23-std-purity` rebase over the `libs/std` reformat.
- `../../01-compiler/08-hygiene` (`examples/**`) and `26-cli-tooling` (`compiler-cli/tests`) rebase.
- `110` (asserts.bp) and `111` (new cells) start from this landing.
