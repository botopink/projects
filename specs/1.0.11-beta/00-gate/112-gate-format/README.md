# Front 112 — gate-format: every `.bp` tree canonical and in `TREES`, every `.zig` file formatted, the one unformattable fixture exempt by structure

**Priority:** high — stage 3 is green only because 226 red files sit in trees it does not walk,
and 11 `.zig` files are a red the gate meets the day a front stages one.
**Depends on:** none — lands first in group A (a reformat commit is the cheapest thing for every
other front to rebase over). `110` rebases its `asserts.bp` edit; `111` writes its new cells
formatted.
**Owns:** `scripts/format-check.sh` (`TREES`, the header) · `modules/compiler-cli/src/cli/format_cmd.zig`
(the structural exemption, gate-c) · the 11 `zig fmt` files (a `zig fmt` commit, no other change) ·
**reformat-only commits** over `libs/std/src/**` (19 files), `examples/generic-loader-binding/**`,
`examples/stdlib-tour/**` (and `examples/yamlconf` if red — measure), `modules/compiler-cli/tests/**/*.bp`
(5 fixtures), `tests/language/{test,run,modules}/**/*.bp` (199 files) · stage 1 of `scripts/gate.sh`
(`:131-133` — `zig fmt --check` widened from staged files to `modules`) · `scripts/AGENTS.md`
§ format-check.sh.
**Does not touch:** any source change in the trees it reformats (the reformat commit is
`botopink format` output and nothing else — a hand edit in it is a red flag for the reviewer);
`format.zig` and the formatter's rules (`../../01-compiler/16-formatter`'s: decision 132's `;`
refusal lands *after* this front, on the migrated trees); `wat.zig` (110), `run.sh` (111).

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

`format-check.sh:9-10`: "a tree joins the list when its last red lands; it is not a skip list, and
there is no other way to exempt a file (decision 67)" — the rule is right and the list is what a
skip list looks like from the other side: five trees are red and named in a header instead of
being formatted. `format_cmd.zig:15-18,123-128` already exempts one fixture shape structurally
(`reject/<n>.bp` beside `<n>.expect`); the lexer-error cell is the same shape in a `modules/` cell.

## Mechanism

`botopink format` is the migrator for a tree the formatter owns (`../../01-compiler/README.md`
FC-4): the 199 `tests/language` files differ from canonical by the `;` after a braced block the
printer no longer writes (C-13) and by decision 65's method-chain and lambda rules (C-12/C-14),
which `libs/std` and the two examples also carry. None of it is a semantic change; each reformat
is verified by the cells it touches staying green before and after.

## Steps

### Step 1 — `zig fmt` the 11 files; stage 1 checks the tree

One commit: `zig fmt` over the 11 files, nothing else. `gate.sh:131-133`: the staged-file check
stays (it is the fast path for a `--staged` run) and a full run adds `zig fmt --check modules`
before stage 2 — a red file anywhere fails the gate, staged or not.

**Acceptance:**
- [ ] `zig fmt --check modules; echo $?` → `0`, no output
- [ ] `scripts/gate.sh` prints a `zig fmt --check modules` line in stage 1 and fails on a synthetic unformatted file

### Step 2 — reformat and add to `TREES`: `libs/std`, the two examples, `compiler-cli/tests`

One reformat-only commit per tree. `libs/std`: the std cell count unchanged
(`zig build test-libs -- --lib std` on both targets, before and after); the two `.d.bp` lines in
`TREES` (`:43-44`) are replaced by `libs/std`. `examples/generic-loader-binding`, `examples/stdlib-tour`
(measure `examples/yamlconf` and any other `examples/*` not in `TREES`; add every green one): each
example builds and runs the same before and after. `modules/compiler-cli/tests`: `zig build test-cli`
green before and after (the fixtures' expected outputs do not depend on indentation — verify).

**Acceptance:**
- [ ] `TREES` lists `examples/*` (every example directory), `libs/std`, `libs/routing`, `libs/actions`, `libs/validation`, `modules/compiler-cli/tests`, `tests/language` (step 3); `bash scripts/format-check.sh` → every line ✓
- [ ] `zig build test-libs -- --lib std` on commonJS and erlang: the same pass count; `zig build test-cli` green

### Step 3 — `tests/language` reformatted and in `TREES`; the lexer-error cell exempt by structure (gate-c)

`botopink format` over `tests/language/test`, `run`, `modules` (`reject/` is already structurally
outside the walk). Every cell green before and after on `--target all` and `--target beam`
(measured at the open: 1244/1/1 and 382/2/0 — the reformat changes neither number; 110 and 111
change them afterwards). `format_cmd.zig`: the `reject/` rule generalised — a `.bp` inside a
`modules/<cell>/` directory is left out of the walk when the cell's `<target>.expect` files name a
lexer/parser error located *in that file* (`src/pattern.bp:3:2` in all four `.expect` of
`lexer_error_in_imported_module`); pinned by a `format_cmd.zig` test with a synthetic cell (one
`.expect` naming the file → exempt; naming another file → walked). No list, no flag (decision 67).

**Acceptance:**
- [ ] `zig-out/bin/botopink format --check tests/language` → exit 0, and `Unchanged`/exempt lines only; `pattern.bp:3` is byte-identical to the open
- [ ] `bash tests/language/run.sh --target all` and `--target beam` print the same tallies as before the reformat (or the tallies 110/111 changed them to, if those landed first — the *difference* attributable to this commit is zero)
- [ ] the `format_cmd.zig` test for the structural exemption

### Step 4 — the header and `scripts/AGENTS.md`

`format-check.sh:5-29`: the header names `TREES` and the rule; the "red trees today" paragraph is
deleted (there are none — a red tree is a red gate). `scripts/AGENTS.md` § format-check.sh
(`:205-220`) the same.

**Acceptance:**
- [ ] `grep -c "red today\|joins TREES when" scripts/format-check.sh scripts/AGENTS.md` = 0

## Gate

- [ ] `zig build test` from a cold runtime cache, green; `zig build test-cli` green
- [ ] `bash scripts/format-check.sh` → every tree ✓; `zig fmt --check modules` → exit 0
- [ ] `bash tests/language/run.sh --target all` and `--target beam`: tallies unchanged by this front
- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `scripts/AGENTS.md`, `modules/compiler-cli/AGENTS.md` (format_cmd's exemption), `tests/language/AGENTS.md` (the tree is canonical) updated in the same commits
- [ ] commit(s) on `fix/gate-format` in `repository/botopink-lang`; no push, no merge

## Blast radius

- Every `../../01-compiler/` front that owns one of the 11 `.zig` files (01: `env.zig`, `infer.zig`,
  `patterns.zig`; 14: `runtime/beam/{lower,program}.zig`; 26: `bpmp/**`, `test_cmd.zig`,
  `engine.zig`) rebases over a `zig fmt` commit — mechanical.
- `../../01-compiler/16-formatter` C-13 step 3 loses `tests/language` from its migration count (199
  here); it keeps rakun/jhonstart/erika/onze (99 and 101 do the PK-5 trees; the rest is 16's) and
  lands decision 132's refusal after them.
- `../../02-std-and-packaging/97-std-dedupe` and `23-std-purity` rebase over the `libs/std` reformat.
- `../../01-compiler/08-hygiene` (`examples/**`) and `26-cli-tooling` (`compiler-cli/tests`) rebase.
- `110` (asserts.bp) and `111` (new cells) start from this landing.
