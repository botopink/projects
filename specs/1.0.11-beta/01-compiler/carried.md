# Carried from 1.0.10-beta — the compiler carry-over, item by item

Every 1.0.10 compiler sub-front and every C-item, with where it went. **Carried** rows name the
1.0.11-beta front directory and the items it took. **Closed on tick** rows are items whose box
was unticked in 1.0.10 but whose behaviour holds at the milestone's open — the evidence is the
audit's, re-checked against `repository/botopink-lang` (compiler HEAD at the open); they are not
carried, and the 1.0.10 record stays as written. Paths are relative to `specs/1.0.10-beta/00-compiler-carry-over/`.

## Sub-fronts

| 1.0.10 sub-front | 1.0.11-beta front | Items carried | Closed on tick (evidence) |
|---|---|---|---|
| `01-checker/` | [`01-checker/`](./01-checker/README.md) | C-04's last box (ck2-c); step 2 §3.2's `[1, "a"]` / `[1, 2.5]` join (D5); step 4 (d)'s parser half (a `fn` in a section body); the language-gaps rows owned by 01 (22, 28, 29, 31–34, T5 lg-a, T9, T11, T12) and 02's captured-var write's check-time half (lg-b); the tuple label through `?T` (02 step 4's box, 04 D5); JS-4's two checker gaps (`val [..rest]`, a nested constructor); 08 items 1–2 in `env.zig`, `infer.zig`, `diagnostics.zig`, `ast.zig`, `parser.zig`, `parser/decls.zig` | `trailing-defaults.md`'s six unticked boxes — landed (C-04's cells `modules/default_argument_across_modules`, `run/pipeline_call_fill`, `run/associated_fn_default` pass); `surface-gaps.md` rows `Box<i32>(value: 1).get()` (runs), `fn get(b: Box)` (refused, C-15), `any` (`any-type-removed`), `.Circle(radius: 1)` in expression position (landed, 15's handover row 1); 01's four "decided by the maintainer" rows (landed) |
| `02-erlang/` | [`02-erlang/`](./02-erlang/README.md) | step 9 (the dead tail-`case` lowering); C-07's erlang tails (§4.1 / §4.2, §11 pin, the twins' erlang side); C-06's `KNOWN` notes; language-gaps T1, T6 (lg-b, the lowering half), T13, T14, T18 (emitter half); the new C-34, C-35 (typing half), C-36; 08 items 1–2 in `erlang.zig` (10 + 16 sites) | step 4's box moved to 01 (the checker's, as the box says); "a `@Result` method inside a closure" — not reproduced as written, the prelude case is C-35; T7 "type-only import skips the module body" — **fixed** in the probed shape (decision 140's `pub val`), and the new defect it exposed is C-34; T10 "`try` inside a `for` writing a `var`" — no longer reproduces (`I@2 unsafe in 'case'` is gone; a re-measure cell is 12's) |
| `03-beam/` | [`03-beam/`](./03-beam/README.md) | JS-4's beam twin (`{unresolved_identifier, r}`); C-07's beam tails; the two live `expected-failures.txt` lines (00-gate's fix; this front's `beam_asm.zig` afterwards); C-10's beam emission (with 17); lg-b's beam half (the stale `0` at exit 0) | step 5 (nothing to delete); the `KNOWN` notes' beam side (none) |
| `04-js/` | [`04-js/`](./04-js/README.md) | step 8 (the one `@block` IIFE site, after R7 — R7's checker half landed, the deletion is open); `$stringify` (0405-c); C-18's `tsc --noEmit` script and `42.toString()`; the redeclared binding lowered twice (after 01c-d); 24-h | step 5's last box (jhonstart's "always name the module" rule) — the library's, listed in `09`'s pointer; `pattern-binding.md` moves to 03 (the open half is beam's) |
| `05-wasm/` | [`05-wasm/`](./05-wasm/README.md) | the pinned primitive-method traps (`String.lines`/`words`, `Array.pop`/`flatMap`/`flatten`/`flat`/`chunked`/`sliding`/`fill`/`unique`) each a missing lowering; `==` between type-parameter values (re-measure); C-07's wasm twins; `run/external_wrapper_keeps_refusal` (00-gate's fix, this front's file) | 00/README C-01 step 18's note "one wasm line stays, `wasm \| run/display_print.bp`" — **stale**, no such line (the ledger has three lines, none of them); step 3's boxes (landed) |
| `07-review-backlog/` | [`07-review-backlog/`](./07-review-backlog/README.md) — the README whole | C-22: waves A (~420 rows) and B (225), the `uncertain` rows, the two `externals.zig` renames (`:55`, `:67` at HEAD), the `infer_decls.zig:147` rename | step 5 — `scripts/snap_audit.sh` already classifies `comptime/<dir>` (`:42`, `:54`): landed with the layout, the box closes on tick |
| `08-hygiene/` | [`08-hygiene/`](./08-hygiene/README.md) | items 1–4 (after each owner: 14 `primitives.d.bp` comments — `erlang.zig` ×10, `env.zig:1057`, `infer.zig:11816,12068`, `hover.zig:304` at HEAD; the `@external(<target>, …)` comments; `control_flow.zig:73,76`, `narrowing.zig:90`, `builtins.zig:365`; the transport test); 17's `docs-text.md` (parts 1–2, `docs.md` has zero `BeamMemory` mentions); C-18's five document corrections (decisions 1, 2, 10, 25, 32) | item 5 (`zig fmt`, eleven files now) → **00-gate**; `docs.md` § *Decided, not yet implemented* re-derived (the last box of the 1.0.10 status row, landed: `test-docs` green) |
| `09-ecosystem-residuals/` | [`09-ecosystem-residuals/`](./09-ecosystem-residuals/README.md) | item 1 (erika-linq's `targets` — with 00-gate's RT-1); item 2 (the `->` arms, C-14, the maintainer's word); the libraries' C-13 migration and reformat (their tracks run 16's script; 09 = erika and the pointers); the pointers' sweep | rakun's erlang story, §5.3b's section paths, the `AGENTS.md` claims (landed) |
| `11-tooling/` (closed, C-19) | no directory | the `hover.zig:304` comment → 08 item 1; `language-server/src/**` → [`26-cli-tooling/`](./26-cli-tooling/README.md) | every step landed |
| `12-language-tests/` | [`12-language-tests/`](./12-language-tests/README.md) | step 3's last box (beam joins `--target all`, the `--cold` no-new-tool check); the stale decision-29 row (`tests/language/AGENTS.md:1319`); the "Open rows" `1..9` bullet (stale — `test/case_arms.bp:21` writes `1...9`); C-06/C-07 bookkeeping; the owner rule for the ten cells the area fronts add | step 4 item 5 (DSL hygiene cells — `modules/dsl_hygiene_{private_helper,consumer_alias,consumer_double}` exist and pass) |
| `13-module-identity/` (closed, C-01) | no directory; its twelve deep dives stay in 1.0.10 | `README.md:841`'s one box (one emitted copy of a behavior's associated fn) — decision-23-gated: recorded as a decision row, not a step (it reopens only with decision 23) | halves 1–3 |
| `14-comptime-on-beam/` | [`14-comptime-on-beam/`](./14-comptime-on-beam/README.md) | the three open boxes (the located `unsupported_method` negative fixture — likely landed, `codegen/tests/comptime_module.zig:322`, to verify the location; the N=200 slope re-measure, its blocker `prelude_cache` landed at `erlang.zig:328`; the round-trip fixtures per shape); T15 (an emitted `pub val` invisible); T17 (a reflection type shadowed by an import); lg2-j/o/w | the "known gap, not this front's" `\u{…}` truncation → C-36 (02) |
| `15-language-surface/` (closed) | no directory; `decision-29-parser-half.patch` → [`16-formatter/`](./16-formatter/decision-29-parser-half.patch) | `surface-gaps.md` § *Still open*: a `fn` in a section body → 01 (01c-c); `[1, "a"]` → 01 (D5); `Option.None` unbound → 08 (C-18's documents); `$stringify` → 04 (0405-c); the parser rows of `language-gaps.md` owned by 15 (T9, T11, T12, rows 27–29 by design or 01's) → 01; lg2-m/t/r decision-gated → 01 | `Box<i32>(value: 1).get()` works; `fn get(b: Box)` refused; `any` gone; `.Circle(radius: 1)` landed |
| `16-formatter/` | [`16-formatter/`](./16-formatter/README.md) — with `c13-migrate.py` and the patch | C-13 step 3 (rakun 454 / jhonstart 40 / erika 28 / onze 1 unverified — the library tracks run the script; then the patch narrowed to `isBracedBlockStmt`, `parser.zig:969` at HEAD); the siblings' reformat after 16-a/16-b; `commaList` + the one-step pipeline (16-d); decision 61 rule 3 at `arrow_when_empty` (`format.zig:1708`, 16-c); C-11's trailing-lambda boxes (`{ -> 42 }`; `examples/jhonstart-app` is no longer in the compiler tree — re-measure) | the `tests/language` share of C-13 step 3 → **00-gate** FC-4 (`botopink format` migrates it); `libs/std` 19, `examples` ×2, `compiler-cli/tests` 5 outside `TREES` → 00-gate FC-1…3 |
| `17-beam-memory/` | [`17-beam-memory/`](./17-beam-memory/README.md) | C-10's `keyed = true` row-per-key `Dict` (refused on erlang and beam; no `Dict` literal; `comptime Dict.empty()` does not fold — 17-a); `docs-text.md` → 08 (the owner of `docs.md`, a pointer here); `rakun-migration.md` → the rakun track (a pointer here) | C-05 (all boxes; the reject cells exist: `reject/beam_memory_*`, `reject/val_assign_*`); C-10's three modes, the owner, the refusals, the cells (`run/beam_memory_{ets,persistent_term,process_dict}`) |
| `18-comptime-runtimes/` | [`18-comptime-runtimes/`](./18-comptime-runtimes/README.md) | the CI matrix run (`test.yml` on ubuntu-22.04 / macos-14 / windows-2022, `release.yml`'s five rows — the maintainer's, after the push); `test-web` on the matrix; the `comptime_bench.sh` table; `wat-runtime.md` §7's four non-parity items recorded as limits; 08 item 4 (the transport test beside `evalBeam`, `runtime.zig`) | C-26's spine; 14 box 2's prelude memo (landed: `prelude_cache`) — the 18 § Open last bullet is stale |
| `19-use-activation/` (closed, C-27) | no directory | the note "a transitive workspace dependency does not reach a dependency's modules" (jhonstart-forms → jhonstart-link) → 26 step 3, cross-checked with decision 143; "the provider stack behind `@getContext` has no front" — a design row, none opened | every step |
| `20-builtins-surface/`, `21-effect-chain/`, `22-loops/` (closed, C-28–C-30) | no directory | nothing | every step |
| `23-std-purity/` | [`23-std-purity/`](./23-std-purity/README.md) | the gate's rows (`test-language` on four targets with the import cells; `language-server` tests with the `project_graph.zig` cells; `AGENTS.md` ×5); 23-a/b/c and std-c to confirm | step 1's last box (`docs.md:756`'s grammar replaced — verified); step 4's `reject/` cell (satisfied by the `std_package_a_root_module_importing_*` error snapshots) |
| `24-effects-by-return/` | [`24-effects-by-return/`](./24-effects-by-return/README.md) | E3's guide fences (decision 134: every fence one program — waits on the rakun track's `serverAction` stubs; the three checker rows it named landed); `botopink check` over the guide re-run with jhonstart as a path dependency; 24-a/b/c/g; 24-h; the `@Result`-per-item cost on erlang and wasm (Risks) | E1, E2, E4, E5, E7, E8 and every cell |
| `25-gate-perf/` | [`25-gate-perf/`](./25-gate-perf/README.md) | § *Not a step* (the hooks in worktrees — a meta-repository script) and step 4's last paragraph (the per-cell dependency compile, ~4–6 s a cell, compiler-core's pipeline) as measured rows; the `async` delay wall-clock flake (`libs/std/src/async.bp`, the std track's) as a pointer | steps 1–4 (C-33) |
| (none — `00/README` items with no directory) | see below | | |

## C-items without a 1.0.10 directory

| C-item | 1.0.11-beta front | Carried | Closed on tick (evidence) |
|---|---|---|---|
| C-02 | — | nothing | six boxes unticked but landed: `xs[0]` types `?T`, `d["k"]` reaches `Dict.at`, `[1, 2, 3][1..].length` prints `2` on beam, `docs.md` carries the paragraph; the conformance-by-comment limit stays a row (`primitives.bp:124,372` name it) |
| C-04 | 01 | the last box (ck2-c) | the rest |
| C-06 | 02 · 12 | the `KNOWN` notes; the moved RUN LOGs' verification line | the wasm half, the erlang and beam arms |
| C-07 | 02 · 03 · 05 | the tails, the twins, §4.1 / §4.2, §11 | F1 (`run/tuple_print` on erlang), 02 step 7 |
| C-08 | — | nothing | landed, bookkeeping: the parser snapshot count box closes on tick (19 stay, new ones classified) |
| C-09 | 02 · 04 | R7's backend deletions (02 step 9, 04 step 8) | R1–R9's checker halves, `Array.range(…).map`, the N25 cells, `curried_call` |
| C-10 | 17 · 03 · 08 | `keyed = true`; the `docs.md` text; rakun's migration (pointer) | the modes, the owner, the refusals, the cells |
| C-11 | 16 · 00-gate | the trailing-lambda boxes (re-measure); `builtins.d.bp`'s `await` — verify it formats (the file is in `TREES` and green) | the walk, the gate stage |
| C-12 | 16 · 09 | 16-a/16-b to confirm, then the siblings' reformat | the predicate, the chain, the comment column |
| C-13 | 16 · 00-gate | step 3 (the siblings, then the patch) | the parser accepts both, the printer prints none, the compiler's trees migrated; `tests/language` → 00-gate FC-4 |
| C-14 | 09 (the maintainer's word) | the `->` arms in emilia, jhonstart, rakun | `Self<…>`, the five bindings, `Dict implements Display`, `case_sections` |
| C-15 | — | nothing | landed |
| C-16 | — | nothing | landed |
| C-17 | — | nothing | closed in substance (every library's erlang cells run at decision 109's atoms; the sibling sweep is 09's standing rule) |
| C-18 | 08 · 04 | the five documents; `tsc --noEmit`; `42.toString()` (verified prints `42` — a script pins it) | 44, 45, 47, 57, 31, 9 |
| C-19 | — | nothing | landed (`hover.zig:304`'s comment → 08) |
| C-20 | — | nothing | absorbed by C-26 |
| C-21 | — | nothing | landed |
| C-22 | 07 | whole | step 5 |
| C-23 | 08 | items 1–4 | item 5 → 00-gate |
| C-24 | — (the maintainer deletes `wip/br5-beam-templates`) | nothing | landed |
| C-25 | 01 (holds) · 26 | the sidecar named like an emitted ATOM (`<pkg>@<path>.erl`) never consulted (`libs.shipErlSidecars`); the `botopink clean` sentence | the checker half (`ambiguous-import-use`); the stash (gone) |
| C-26 … C-33 | 18 · 23 · 24 · 25 | as the sub-front rows above | the spines |

## New C-items, allocated by the audit

| Id | Item | Front |
|---|---|---|
| **C-34** | a module-level `val _x = @print(…)` in a dependency module emits a call to `'__bp_print'/1` that the dependency's module does not define (`undefined function`) — found while closing T7 (decision 140's `pub val`) | 02 |
| **C-35** | `Array.unique`'s prelude `default fn` body (`prev.unwrapOr(x)`, `primitives.bp:640-641`) is typed by no inference: answers `[1, 2, 1]` on commonJS, erlang and beam and **traps** on wasm | 02 (the prelude typing) · the std track (the body) · 05 (the trap) |
| **C-36** | a string lexeme carrying `\u{…}` reaches Erlang text as `\x{…}` (`codegen/beam/erl_emitter.zig:173,184` `writeStringFromLexeme` / `writeBinaryFromLexeme`), which keeps the low byte of a code point above 255; the same family as "a non-ASCII literal reaches erlang as latin1 and a codepoint above U+00FF is `illegal character`" (the std track's STD-11) | 02 |

| **C-37** | the commonJS prelude's `String.charCodeAt` lowering recurses on a non-ASCII input — `emilia/modules/emilia/src/output.bp:379-388` carries the byte walk that works around it; a `language-gaps.md` row was written at the milestone's cut (owner [`04-js/`](./04-js/README.md); cell `run/string_char_code_non_ascii`) |

The next free C-number is **C-38**.
