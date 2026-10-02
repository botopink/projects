# Track 01 — compiler

**Repos:** `repository/botopink-lang/modules/**` (compiler-core, compiler-cli, bpmp, language-server,
lib-test-runner, test-shard, wasm3), `repository/botopink-lang/tests/language/**`,
`repository/botopink-lang/scripts/**` (the runners and audits, not the ledgers — those are
`00-gate`'s), `repository/botopink-lang/docs.md` and the compiler's `AGENTS.md` files.
**Carried from:** `specs/1.0.10-beta/00-compiler-carry-over/` — every open item of the 1.0.10 compiler
carry-over, sub-front by sub-front; the mapping is [`carried.md`](./carried.md).
**Depends on:** [`../00-gate/`](../00-gate/) for everything under § *Handed to 00-gate* — the gate lands
first, and every front here names the files it may not touch until it does.

1.0.10-beta is frozen. What the compiler still owes is not a feature; it is the tail of eight
fronts that landed their spine and left rows: decision 8's run-time tails on erlang and beam
(C-07), the last checker rows around `case` and bindings, the beam target that ships no erlang host
sidecar, the `;` the ecosystem still writes after a braced block (C-13), `@BeamMemory`'s
`keyed = true`, the review backlog nobody opened (C-22), the comment sweeps (C-23), and the
toolchain rows the rakun sweep measured (`language-gaps.md` T1–T19). Every one of them is stated
below as behaviour with a cell, and cut by file ownership so that seven fronts can run at once.

The 1.0.10 sub-front numbers are kept (`01-checker` … `25-gate-perf`); one number is new,
`26-cli-tooling`, because `compiler-cli/**`, `bpmp/**` and `language-server/src/**` had no owner
among the carried fronts and four open rows live there. The closed 1.0.10 sub-fronts (11, 13, 15,
19, 20, 21, 22) have no directory; their residual rows sit with the front that owns the file
(`carried.md` says which).

## What the compiler still owes

| Area | Open, in one line | Front |
|---|---|---|
| checker | `[1, "a"]` join (D5); function-typed `case` arms; a record value called; one name bound twice; `throw` in a `case` arm under `@Result`; a `fn` in a section body; a section-typed value standalone; a label read through `?T`; `try` in a lambda (lg-a); ck2-c; the parser rows the surface front left (lambda parameter annotation, a tuple after `??`, a postfix read on `( … )`, `unknown` as a binding name) | [`01-checker/`](./01-checker/README.md) |
| erlang | C-07's tails; the dead tail-`case` lowering; C-06's `KNOWN` notes; a module fn named like a BIF; `__Loop`; a module-level `@print` in a dependency (C-34); `Array.unique` (C-35); `\u{…}` and non-ASCII literals (C-36); `string.indexOf` in bytes; the captured-`var` write (lg-b); the sibling loader outside test mode (T1) | [`02-erlang/`](./02-erlang/README.md) |
| beam | JS-4's beam twin; C-07 on beam; the erlang host sidecar the beam build does not ship; `keyed = true` on beam | [`03-beam/`](./03-beam/README.md) |
| commonJS | the one `@block` IIFE site; `$stringify` in a Node template; the redeclared binding lowered twice; `tsc --noEmit` as a script; `42.toString()` re-verified | [`04-js/`](./04-js/README.md) |
| wasm | the primitive-method traps (`Array.unique` among them); `==` between type-parameter values; C-07's wasm twins; the host-wrapper rule (00-gate's) | [`05-wasm/`](./05-wasm/README.md) |
| comptime | three fixtures (a located `unsupported_method`, the N=200 slope, the ETF round trip per shape); an emitted `pub val` invisible (T15); a reflection type shadowed by an import (T17); lg2-w/j/o | [`14-comptime-on-beam/`](./14-comptime-on-beam/README.md) · [`18-comptime-runtimes/`](./18-comptime-runtimes/README.md) |
| formatter | C-13 step 3 (the siblings' migration, then the parser refuses the `;`); the siblings' reformat at C-12's rules; `arrow_when_empty`; `commaList` and the one-step pipeline | [`16-formatter/`](./16-formatter/README.md) |
| BEAM memory | `keyed = true` row-per-key `Dict`; the `docs.md` text (08's to place); rakun's migration (04-rakun's) | [`17-beam-memory/`](./17-beam-memory/README.md) |
| tooling | the beam sidecar's CLI half; a sidecar named like an emitted atom (C-25); `shipErlSidecars` reading a folder as a package (T16); a transitively reached package not importable (T4, 26-a); `botopink clean`; `Env.warnings` printed by `build` / `test` / the LSP | [`26-cli-tooling/`](./26-cli-tooling/README.md) |
| std purity | the gate's rows (four targets, the LSP cells, five `AGENTS.md`); 23-a/b/c confirmed | [`23-std-purity/`](./23-std-purity/README.md) |
| effects | the guide's three fences (E3); 24-a/b/c/g confirmed; `unwrapOrThrow` (24-h); the `@Result`-per-item cost measured | [`24-effects-by-return/`](./24-effects-by-return/README.md) |
| tests | beam in `--target all`; the `--cold` no-new-tool check; two stale `AGENTS.md` rows; the owner rule for the ten new cells | [`12-language-tests/`](./12-language-tests/README.md) |
| review | C-22 whole: waves A and B, the `uncertain` rows, two renames, `snap_audit.sh` | [`07-review-backlog/`](./07-review-backlog/README.md) |
| hygiene | C-23 items 1–4; the `@BeamMemory` text into `docs.md`; C-18's five document corrections | [`08-hygiene/`](./08-hygiene/README.md) |
| ecosystem | erika-linq's `targets` lifted with its ledger line; the `->` arms (C-14, the maintainer's word); the pointers' sweep | [`09-ecosystem-residuals/`](./09-ecosystem-residuals/README.md) |
| gate perf | two follow-ups: the per-cell dependency compile, the hooks in worktrees | [`25-gate-perf/`](./25-gate-perf/README.md) |

## Fronts

| Front | Priority | Carries | Parallel group |
|---|---|---|---|
| [`01-checker/`](./01-checker/README.md) | high | C-04 (ck2-c) · 01 step 2 §3.2 (D5) · 01 step 4 (d) parser half · language-gaps rows 22, 28, 29, 31–34 and T5, T9, T11, T12 · JS-4's two checker gaps · 08 items 1–2 in its files | A |
| [`02-erlang/`](./02-erlang/README.md) | high | C-06 (notes) · C-07 (erlang half) · C-09 R7 (step 9) · T1, T6 (lg-b), T13, T14, T18 · C-34 · C-35 · C-36 · 08 items 1–2 in `erlang.zig` | A |
| [`03-beam/`](./03-beam/README.md) | high | JS-4 beam twin · C-07 (beam half) · the two beam `expected-failures.txt` lines (with 00-gate and 26) · C-10's beam half (with 17) · lg-b on beam | A |
| [`04-js/`](./04-js/README.md) | medium | 04 step 8 · `$stringify` (0405-c) · C-18's `tsc` and `42.toString()` · the redeclared binding (after 01c-d) · 24-h | A |
| [`05-wasm/`](./05-wasm/README.md) | high | the pinned primitive-method traps · type-parameter `==` · C-07 wasm twins · `run/external_wrapper_keeps_refusal` (00-gate's fix, this front's file) | A |
| [`14-comptime-on-beam/`](./14-comptime-on-beam/README.md) | medium | 14's three open boxes · T15 · T17 · lg2-j/o/w (decision-gated) | A |
| [`26-cli-tooling/`](./26-cli-tooling/README.md) | high | the beam sidecar's CLI half · C-25 · T4 (26-a) · T16 · `Env.warnings` in `build` / `test` / the LSP · `botopink clean` · lg2-v's bpmp half (with 98-packaging-tail) | A |
| [`12-language-tests/`](./12-language-tests/README.md) | medium | 12 step 3's last box (beam in `all`, `--cold`) · two stale `AGENTS.md` rows · C-06/C-07 bookkeeping lines · the owner rule for the ten new cells | B |
| [`18-comptime-runtimes/`](./18-comptime-runtimes/README.md) | low | 18's CI matrix / `test-web` / bench rows · wat-runtime §7 as limits · 08 item 4 (the transport test) | B |
| [`23-std-purity/`](./23-std-purity/README.md) | low | 23's gate rows · 23-a/b/c, std-c confirmations | B |
| [`24-effects-by-return/`](./24-effects-by-return/README.md) | medium | E3's three fences · 24-a/b/c/g · 24-h · the per-item cost | B |
| [`25-gate-perf/`](./25-gate-perf/README.md) | low | the per-cell dependency compile (measured row) · the hooks in worktrees (meta) | B |
| [`17-beam-memory/`](./17-beam-memory/README.md) | medium | C-10's `keyed = true` (17-a) · pointers to the text (08) and rakun's migration (04-rakun) | after 02 and 03 |
| [`16-formatter/`](./16-formatter/README.md) | medium | C-13 step 3 · 16-a/b then the siblings' reformat · 16-c · 16-d · C-11's trailing-lambda boxes | after 00-gate and the library tracks' migrations |
| [`07-review-backlog/`](./07-review-backlog/README.md) | low | C-22 whole | after 02–05 |
| [`08-hygiene/`](./08-hygiene/README.md) | low | C-23 items 1–4 (after each owner) · 17's `docs-text.md` · C-18's documents | after every owner |
| [`09-ecosystem-residuals/`](./09-ecosystem-residuals/README.md) | low | erika-linq's `targets` · C-14's `->` arms · the pointers' sweep | after 16 and 00-gate |
| [`130-decorator-outputs/`](./130-decorator-outputs/README.md) | high | decision 216: a decorator's four places (`decl.addMember`, `decl.setMeta` + `@typeinfo`, `decl.addType`, `@typeinfo.all`), the 119 library sites, then module-level `@emit` removed | new · beside A (its compiler files are `comptime/`'s decision-216 parts; the library migration rebases on 129) |

**Group A** shares no source file and no snapshot directory across its seven fronts, with the
carve-outs each README names (the C-07 twins in per-backend test files; `codegen/beam/{erl_ast,erl_emitter}.zig`
to 02; `erlang.zig:2405-2415`'s loader to 02 with 26 consuming it). **Group B** edits runners,
cells, documents and configuration only, and runs beside A. The four fronts after the groups each
touch files a group-A front owns and are sequenced behind it.

## Order

```
00-gate ─────────────────────────────────────────────────────────────┐  runs alone: the three lines,
                                                                     │  zig fmt ×11, TREES, the ledgers
                                                                     ▼
group A   01-checker · 02-erlang · 03-beam · 04-js · 05-wasm · 14-comptime-on-beam · 26-cli-tooling   (7 in parallel)
group B   12-language-tests · 18-comptime-runtimes · 23-std-purity · 24-effects-by-return · 25-gate-perf (beside A)
                                                                     │
            02 · 03 ──► 17-beam-memory        (one emission site per BEAM backend)
            00-gate (tests/language reformat) · the library tracks' c13-migrate.py runs · 01's parser rows ──► 16-formatter
            02 · 03 · 04 · 05 ──► 07-review-backlog   (it renames in their snapshot directories)
            every owner ──► 08-hygiene        (one comment commit per owned file)
            16 · 00-gate ──► 09-ecosystem-residuals   (erika's reformat and the pointers, last)
```

`00-gate` is first because nothing here can be verified against a gate that tolerates a red: a
front whose cell passes cannot tell its pass from a listed failure, and a front that stages one of
the eleven `zig fmt` files meets the gate's staged-file check before its own change is judged.
Group A is second because every other front reads its output — the cells 12 lists, the snapshots
07 renames, the comments 08 sweeps, the sources 16 migrates.

## Handed to 00-gate

Every item that is today a pinned red, a latent gate red or a stale ledger line. `00-gate` owns
the files for these fixes; the front named in the last column owns the same files afterwards and
lists the item under *Does not touch until 00-gate lands*. Measured at the milestone's open in
`repository/botopink-lang` (`tests/language/expected-failures.txt`, `scripts/restricted-targets.txt`,
`scripts/format-check.sh`, `zig fmt --check modules`, `botopink format --check <tree>`).

| Item | File | Fix | Front on the same files |
|---|---|---|---|
| **EF-1, EF-2** — the beam build ships no erlang host sidecar: `beam \| modules/erlang_host_sidecar_shipped` and `beam \| modules/erlang_sidecar_named_like_a_module` (`text:shout/1` is `undef` under `erl`; erlang prints the value) | `modules/compiler-cli/src/cli/{build,run,test_cmd}.zig` (the beam path calls no `shipErlSidecars`), `modules/compiler-cli/src/cli/libs.zig` (`shipErlSidecars` is erlang-only), `modules/compiler-core/src/codegen/beam_asm.zig` (a `__bp_load_siblings` twin of `erlang.zig:2405-2415`, so the `.S` module loads the sidecar beside it) | the beam build ships every `.erl` sidecar the erlang build ships, into `out/beam/`, and the assembled module loads it; both cells pass on `run.sh --target beam`; the two lines deleted | [`03-beam`](./03-beam/README.md) (`beam_asm.zig`) · [`26-cli-tooling`](./26-cli-tooling/README.md) (`cli/**`, `libs.zig`) |
| **EF-3** — `wasm \| run/external_wrapper_keeps_refusal.bp`: the strict rule (a wrapper around a host call with no wasm binding is refused even if nothing calls it, `docs.md` § host bindings) meets wasm's lazy `collectHostBound` (`wat.zig:1445`), which drops such a function and refuses only its call — ck-host | `modules/compiler-core/src/codegen/wat.zig` (`collectHostBound`), `libs/std/src/testing/asserts.bp` (`deepEquals` reaches `canonical`, which has no wasm binding — the reason the lazy rule was written) | ck-host answered (a), the recommendation: `collectHostBound` becomes strict; `deepEquals` is restructured so no wasm-less host function is reachable from `asserts` on wasm (or `canonical` gets a wasm lowering); the line deleted; `asserts` still builds on wasm (`zig build test-libs`) | [`05-wasm`](./05-wasm/README.md) (`wat.zig`) · the std track (`asserts.bp`, `../02-std-and-packaging/`) |
| **ZF-1…11** — `zig fmt --check modules` red on 11 files: `bpmp/src/commands/{self_uninstall,self_update}.zig`, `bpmp/src/{registry,storage}.zig`, `compiler-cli/src/cli/test_cmd.zig`, `compiler-core/src/comptime/{env,infer}.zig`, `compiler-core/src/comptime/runtime/beam/{lower,program}.zig`, `compiler-core/src/parser/patterns.zig`, `language-server/src/engine.zig` — the gate checks staged `.zig` files only (`scripts/gate.sh:132`), so each is a red waiting for the front that next stages it | the eleven files | `zig fmt` each, one commit, no other change; the gate stage widened from staged files to `zig fmt --check modules` | 01 (`env.zig`, `infer.zig`, `patterns.zig`) · 14 (`runtime/beam/{lower,program}.zig`) · 26 (`bpmp/**`, `test_cmd.zig`, `engine.zig`) |
| **FC-1** — `libs/std` outside `format-check.sh`'s `TREES` (only its two `.d.bp` are listed, `scripts/format-check.sh:43-44`): 19 files would reformat | `scripts/format-check.sh`, `libs/std/src/**` (19 files) | `botopink format libs/std`, then `libs/std` in `TREES`; the std cell count unchanged (`zig build test-libs -- --lib std`) | the std track (`libs/std/src/**`) · [`23-std-purity`](./23-std-purity/README.md) (`libs/std/AGENTS.md`) |
| **FC-2** — `examples/generic-loader-binding` and `examples/stdlib-tour` outside `TREES` (`format-check.sh:17-18` names the method chains, which C-12 opened since) | `scripts/format-check.sh`, `examples/{generic-loader-binding,stdlib-tour}/src/main.bp` | reformat, add both to `TREES` (`examples/yamlconf` measured and added with them) | [`08-hygiene`](./08-hygiene/README.md) (`examples/**`) |
| **FC-3** — `modules/compiler-cli/tests` outside `TREES`: 5 fixture `.bp` files at two-space indent | `scripts/format-check.sh`, `modules/compiler-cli/tests/**/*.bp` | reformat; the CLI contract scripts still pass (`zig build test-cli`); the directory in `TREES` | [`26-cli-tooling`](./26-cli-tooling/README.md) |
| **FC-4** — `tests/language` outside `TREES`: 199 files would reformat (the `;` after a braced block that the printer no longer writes — C-13's `tests/language` migration, `botopink format` being the migrator for a tree the formatter owns) and 1 cannot format — `modules/lexer_error_in_imported_module/src/pattern.bp`, a deliberate lexer error | `scripts/format-check.sh`, `tests/language/{test,run,modules}/**` (`reject/**` is exempt structurally) | `botopink format` over the three directories, every cell green before and after on `--target all` and `--target beam`; the one cannot-format cell exempted **structurally** (a cell whose `.expect` names a lexer error, or the directory's own rule — never a skip list, decision 67); `tests/language` in `TREES`; C-13's `tests/language` count (275 in the 1.0.10 record, 199 files now) closes with it | [`12-language-tests`](./12-language-tests/README.md) (the cells) · [`16-formatter`](./16-formatter/README.md) (C-13 step 3 loses this tree) |
| **RT-1…3** — `scripts/restricted-targets.txt` lines that outlived their reason: `erika-linq erlang 0`, `jhonstart-counter erlang 0`, `jhonstart-todo erlang 0` — each pinned at `0` failed, so the restriction restricts nothing | `scripts/restricted-targets.txt`; `repository/erika/examples/erika-linq/botopink.json`, `repository/jhonstart/examples/{counter,todo}/botopink.json` (`"targets": ["commonJS"]`) | drop `"targets"` in the three manifests and delete the three lines in one landing (the runner refuses a stale line and a restriction with no line alike); `jhonstart-dom-test erlang 1` stays until its front closes the red | [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) (erika, the pointers) · the jhonstart track (its two manifests) |

beam is one of `run.sh --target all`'s four targets (111, after EF-1/EF-2; 12's step 1).
`scripts/known-red-libs.txt`
is at its header (measured: no line).

## Decisions the maintainer owes

The lettered ids are 1.0.10's and are not renumbered; the answers move to
[`../decisions-taken.md`](../decisions-taken.md) with the next free number (**146**). New questions
continue each front's series. Every recommendation is the most restrictive behaviour with no
configuration that bypasses it (decision 67).

**Open from 1.0.10, unchanged in text** (the full statement is in
[`../../1.0.10-beta/decisions-pending.md`](../../1.0.10-beta/decisions-pending.md) under the same id):

| Id | Question | Blocks |
|---|---|---|
| ck2-c | a leading default on a free `fn` (recommendation (a): keep the asymmetry) | nothing — C-04's last box closes on the answer |
| lg-a | where a `try` inside a lambda may appear (recommendation (1): the lambda's return is its expected type's; `try` there is `effect-try-without-fallible-channel`) | 01 step 6 |
| lg-b | what a lambda's write to a captured `var` means on the BEAM (recommendation (1): refuse at check time outside a `forEach` body or a local closure at statement position) | 01 step 7 · 02 step 8 · 03 step 4 |
| ck-host | a function around a host call with no binding for the target (recommendation (a): strict everywhere) | EF-3 (00-gate) · 05 |
| D5 | mismatched `case` arms: a union or an error (01's own; §3.2 says the union) | 01 step 1 |
| 16-a, 16-b | C-12's argument list with its enclosing constructs; one element per line — chosen, to confirm | the siblings' reformat (16 step 4, 09) |
| 23-a, 23-b, 23-c, std-c | the `collections` leaf (landed both ways), `base64` retired, the two `botopink test` folder fixes, the namespace rewrite — to confirm | nothing |
| 24-a, 24-b, 24-c, 24-g | the effect codes, `@Task`'s methods, the prefixed loop's label, `std/async`'s shape — to confirm | nothing |
| 01c-a, 01c-b | the comptime module's atom; a section leaf's shorthand — to confirm | nothing |
| 0405-b | commonJS prints `undefined` as `null` — landed, to confirm | nothing |
| lg2-a … lg2-w | the twenty-three language questions of the rakun sweep | see the note below |

**New in this milestone:**

### 01c-c. Does a `fn` belong in an enum section body?

**Raised by:** `01-checker` step 3 (1.0.10's 01 step 4 (d), "a section body carrying a `fn` does not parse, and `EnumSection` has no method slot — §5.3b leaves that unimplemented on purpose").
**Measured.** `type Token { Text { Bold, Italic  fn label(self: Self) -> string { … } } }` → `this token cannot appear here · unexpected fn` (`parser/decls.zig`, the section body loop). A method on the enum itself parses; only the section body refuses.
**Options.** (a) refuse by name: `section-body-method` at the `fn`, naming the enum's own method list as the place; (b) admit methods in a section body, with `EnumSection` gaining a method slot, `infer.zig` dispatching on the section type, and the four emitters emitting per-section methods.
**Recommendation.** (a) — a named refusal, no new surface: a section is a namespace of leaves (decision 8 §5.3b), and a method on the enum can `case` on the section. (b) is four emitters and the LSP for a form no library writes.
**Blocks.** 01 step 3.

### 01c-d. A second binding of one name in one body

**Raised by:** `01-checker` step 5 (language-gaps row 34).
**Measured.** `var n: i32 = 1; n = n + 1; var n: i32 = 10; return n;` checks; erlang answers `10`, node does not load (`SyntaxError: Identifier 'n' has already been declared`); `fn f(root: string) { val root = …; }` emits `const root` beside the parameter. Two backends, two answers, no diagnostic.
**Options.** (a) refuse the redeclaration at the second binding, located, naming the first (`binding-redeclared`), parameters included; (b) lower every rebinding as a fresh binding on commonJS (a renamed `const`), keeping erlang's shadowing semantics.
**Recommendation.** (a) — one name per binding in a body is what every backend already agrees on for the cases that work; (b) makes commonJS agree with erlang on a program the language never defined.
**Blocks.** 01 step 5; 04 step 4 (which becomes a no-op under (a)).

### 0405-c. `$stringify` in an `@External.Node` template

**Raised by:** `04-js` step 2 (1.0.10's `15-language-surface/surface-gaps.md`, last row).
**Measured.** `#[@External.Node("$stringify($0)")]` is `PrimOpStringifyUnsupported` on node (`comptime/primOpTemplate.zig`, the commonJS ctx); the erlang target accepts the same template. One template marker, two answers.
**Options.** (a) refuse `$stringify` in every template with a located diagnostic naming the marker (the marker exists for the compiler's own primitive templates, not for user templates); (b) lower it on commonJS as `__bp_show($0)` so the four targets agree.
**Recommendation.** (a) — the marker's documented surface is `$self`, `$N`, `$args`; a user template that needs a printed form calls a botopink function that prints. (b) widens a surface no document names.
**Blocks.** 04 step 2.

### 16-c. Decision 61 rule 3's one-line rule past `arrow_when_empty`

**Raised by:** `16-formatter` step 5.
**Measured.** `h1 { "my blog" }` prints open over three lines because rule 3 stops at `arrow_when_empty` (`format.zig:1708-1730`) — the parse error it guarded against (a trailing lambda's one-line body) is gone since the one-line body needs no `;`. Every trailing-lambda call in the frontend library moves when the rule extends.
**Options.** (a) a trailing lambda whose body is one expression and fits prints on one line, `{ "my blog" }`, arrow or not; (b) keep the open form for the arrow-less lambda.
**Recommendation.** (a), as its own commit after 16-a/16-b are confirmed, measured on the six trees before it is turned on: one rule for every one-expression lambda body, and the output stays a function of content.
**Blocks.** 16 step 5.

### 16-d. `commaList` and the one-step pipeline stay pinned flat

**Raised by:** `16-formatter` step 6 (decision 65 part 4's staging).
**Measured.** Generic, parameter, pattern, import and type lists, and a one-step pipeline, are pinned flat; none holds a call, so none is a wrong middle today (measured over the six trees: 0 lines past 80 columns caused by one).
**Options.** (a) leave them pinned and write the exemption into `src/format/AGENTS.md` as the rule; (b) enable each with its own `groupMeasured`, one commit per construct.
**Recommendation.** (a) — a group that never breaks measured is a group that never breaks pinned; enabling it moves nothing and adds a rule to keep. Revisit when a tree measures a line one of them causes.
**Blocks.** 16 step 6 (closes on the answer).

### 17-a. The seed of a `keyed = true` `Dict`

**Raised by:** `17-beam-memory` step 1 (C-10's last row).
**Measured.** `#[@BeamMemory.Ets(keyed = true)] var counts: Dict<string, i32> = Dict.empty();` is refused on erlang and beam: the `Ets` initialiser must be a literal or `isComptimeExpr()`, there is no `Dict` literal, and `comptime Dict.empty()` does not fold. The annotation validates and nothing can satisfy it.
**Options.** (a) `Dict.empty()` (and `Dict.fromList([…])` of literals) is the accepted seed of a keyed `Ets` var, folded at compile time by the checker as the empty table; (b) a `Dict` literal in the language; (c) refuse `keyed = true` until (b).
**Recommendation.** (a) — no new syntax; the seed of a row-per-key table is its rows, and an empty table needs none. (b) is a language change for one annotation; (c) leaves the argument decision 51 defined with nothing it can be written on.
**Blocks.** 17 step 1.

### 23-d. One unit for every string index

**Raised by:** `02-erlang` step 6 (language-gaps row T18).
**Measured.** On erlang `"a—bXc".indexOf("X")` is `5`, `.length()` is `5`, `.slice(5, 5)` and `.at(5)` are empty: `indexOf` counts bytes (`string:str/2` over the binary), `at` / `slice` / `length` count codepoints. On commonJS all four count UTF-16 units and agree with each other.
**Options.** (a) codepoints everywhere: `indexOf` (and `lastIndexOf`) on erlang answer the codepoint index, as `at` / `slice` / `length` already do; (b) bytes everywhere on erlang; (c) leave it and document.
**Recommendation.** (a) — an index that cannot be handed back to `at` is not an index; the change is one erlang template in `primitives.bp` (the std track's file) plus the cell.
**Blocks.** 02 step 6 (the cell), the std track's `primitives.bp` row.

### 24-h. Does an `unwrapOrThrow` ship for JavaScript callers?

**Raised by:** `24-effects-by-return` § Open (the JS interop helper).
**Measured.** A botopink `@Task<@Result<T, E>>` resolves its Promise with `Error(e)` and never rejects (decision 120; `run/task_throw_resolves_error`); a JavaScript caller that `await`s it reads a tagged value. Nothing today turns that value back into a rejection.
**Options.** (a) no helper: JavaScript callers read the value, as `CHANGELOG.md` says; (b) a std function `unwrapOrThrow(t)` written in botopink over the commonJS host; (c) a helper in the JS runtime prelude.
**Recommendation.** (a) — a Task that never fails is the contract; a helper that rejects is a second contract for one target, and nothing in the ecosystem asks for it (measured: no `.mjs` sidecar unwraps a result).
**Blocks.** Nothing; the 24 README's open bullet closes on the answer.

### 26-a. Is a transitively reached package importable?

**Raised by:** `26-cli-tooling` step 3 (language-gaps row T4).
**Measured.** The import-source check (`compiler-cli/src/cli/sources.zig:52,104`, `proj.dependencyNames`) admits the manifest's own dependencies only; decision 143 loads every package the build resolves. An application declaring only `rakun-starter-web` gets "unresolved import source" for `import {rkProp} from "rakun"` although `rakun` is loaded for it.
**Options.** (a) only direct dependencies are importable — a starter is a version set, not a dependency line, and every package a module imports from is declared; (b) every resolved package is an import source.
**Recommendation.** (a) — the most restrictive, and the one where reading a manifest tells the reader what a module may import; (b) makes an import depend on a dependency's dependency list. The diagnostic names the package to declare.
**Blocks.** 26 step 3; the rakun track's starter fronts read the answer.

### The decision-gated rows (lg2-*)

The twenty-three `lg2-*` questions (a byte type, `@Task` on the BEAM, decorator bodies and
arguments, `@typeName<T>()`, typed raise, comptime state and reflection, `noreturn`, module-level
annotations, thunks into `Children`, comptime filesystem access, cancellation, `@Decl`'s location,
decorator-supplied bodies, module-graph reflection, a negative enum leaf, expression-position
decorators, a git subdirectory, a host function from a decorator body) **open no front here until
answered**. Each is a language-gaps row with a 1.0.10 owner that maps to a front in this track
(01 for lg2-a/f/q/e; 14 for lg2-j/o/w; 26 for lg2-v; the parser rows lg2-m/r/t to 01), and the
front's README lists the row under *Depends on* so that an answer opens a step there rather than a
new front. `lg2-l` may be answered de facto (`@panic` / `@todo` are `noreturn` and a branch ending
in a `noreturn` call narrows — 1.0.10's 01 "decided by the maintainer" row 2); the maintainer
confirms and the row closes.

## Rules carried forward

- A backend builds a model and an emitter renders it; a snapshot is evidence, not a baseline —
  re-record only a value verified by running.
- The gate runs from a cold runtime cache; no check is skipped to be fast (decision 67), no
  configuration bypasses a refusal, and a list of tolerated reds does not exist in this milestone.
- The compiler knows no library: a library's need is a `language-gaps.md` row with a front here, and
  a workaround in the library until the front lands.
- Two fronts share no source file and no snapshot directory; a shared file is a named carve-out
  with a sequence, never a merge.
- `status.md` is the only file that carries status; every README here states current state and
  remaining work, cites `file:line` at HEAD and says when it measured.
