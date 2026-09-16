# Spec 05 — Repo hygiene

**Version:** 1.0.2-beta
**Priority:** low, except 5.10 (see below) — the fourteen items are cosmetic apart from one
protocol bug and one silently-wrong build
**Depends on:** none. Group A overlaps the codegen-hardening spec (the WAT-execution decision);
5.10 its `persistent_erl` tests; 5.1/5.2/5.3 the module-health spec's step 6, which owns the
compile order for `libs/std` — this spec owns only the declarations and the names

---

## Objective

The **fourteen** hygiene items the 1.0.1-beta milestone did not reach (the previous revision of
this spec said thirteen and listed fourteen): orphan std files, broken scripts/manifests/hooks,
dead build files, retired vocabulary in comments, the stdout/protocol collision in the comptime
runtime, license. Item numbers are kept from
[`1.0.1-beta/05-repo-hygiene.md`](../1.0.1-beta/05-repo-hygiene.md) (5.11, 5.12, 5.15 and the
parser half of 5.13 closed there) so existing cross-references still resolve.

Every row below was re-derived at HEAD. Paths are relative to `repository/botopink-lang/` unless
they start with `meta:`.

---

## Current state

Two items are not hygiene and should not be scheduled as such:

| Item | Why it is not cosmetic |
|---|---|
| **5.10** | A comptime body that writes to stdout corrupts the `persistent_erl` frame protocol, and `readFrame` then allocates whatever the corrupted length prefix says — up to 4 GiB — with no bound. `meta:erl_crash.dump` is the artefact of exactly this |
| **5.16** | `modules/compiler-core/build.zig` builds a compiler with **5 of 23** std modules and succeeds. `modules/compiler-core/AGENTS.md:28-31` tells the reader to use it |

Everything else is comments, dead files and one missing license decision.

## Groups

The fourteen items are five branches plus two decisions. Items inside a group share files and
must land together; the groups are file-disjoint from each other.

| Group | Items | What it is | Order |
|---|---|---|---|
| [E](#group-e--the-comptime-frame-protocol-510) | 5.10 | The frame-protocol guard | 1st — correctness |
| [A](#group-a--the-removed-wat-runtime-56-57) | 5.6, 5.7 | Every trace of the removed wasm3/`wat_runtime` runtime, in source, comments and CI | 2nd — 5.7 is unactionable until 5.6's decision is made |
| [B](#group-b--build-files-that-lie-54-516-517) | 5.4, 5.16, 5.17 | Build files and root scripts that do not work, or work wrongly | 3rd |
| [C](#group-c--libsstd-declarations-and-one-stale-filename-51-52-53-514) | 5.1, 5.2, 5.3, 5.14 | `libs/std`'s declared surface, and the 33 comments still naming `primitives.d.bp` | after module-health step 6 |
| [D](#group-d--instructions-and-vocabulary-that-do-not-work-58-513) | 5.8, 5.13 | An example header and ~24 comments teaching forms the compiler rejects | any time |
| [Decisions](#decisions-not-work) | 5.9, 5.5 | License; whether the meta repo needs a gate at all | before their groups can close |

---

## Group E — the comptime frame protocol (5.10)

`comptime/runtime/persistent_erl.zig`. Three gaps that compound into one failure mode.

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| E1 | `:71-89` `safe_call/1` — `spawn_monitor(fun() -> … Mod:main() … end)` at `:72-73` | No `group_leader/2` call anywhere in the file (`grep logger\|group_leader\|error_logger` → 0 matches) | Spawn `Mod:main()` with its own group leader that captures or discards its output. Today it inherits the server's, which **is** `standard_io` — the frame channel — so one `io:format/1` in a comptime body desynchronises the protocol |
| E2 | `:224-225` `const len = std.mem.readInt(u32, &len_buf, .big); const payload = try allocator.alloc(u8, len);` | A `u32` read straight into an `alloc` with no bound | Cap the length (compare `libs.zig:289`, which uses `.limited(64 * 1024)`) and treat an oversize value as a transport failure, not an allocation |
| E3 | `:185-193` — erl's stderr goes to `erl.stderr.log` | Nothing in the tree ever reads that path (one grep hit: the site that writes it) | Either surface the tail of the log on a comptime failure, or say in `comptime/runtime/AGENTS.md` that it is write-only debris. The rationale for not inheriting stderr (`:182-184`, the orphan-holds-stdio deadlock) is sound and must be kept |

The logger is a fourth, smaller mouth on the same channel: the server sets `latin1` correctly at
`:46` but never moves the default handler off `standard_io`. Reproduced on OTP 29 —
`erl -noshell -eval 'os:cmd("kill -TERM "++os:getpid()), timer:sleep(2000), halt().'` prints
`=INFO REPORT==== … SIGTERM received` on **stdout**, stderr empty; the four bytes `=INF` are
`0x3D494E46` ≈ 1.02 GiB at `:224`. `AGENTS.md:223-224` recommends `pkill -f
botopink_comptime_server` (a SIGTERM) as the routine cleanup, i.e. the docs recommend the trigger.

**Steps**
1. At server start, move the default logger handler to `standard_error` or remove it.
2. Run `Mod:main()` under its own group leader (E1).
3. Cap the frame length (E2).
4. Decide E3 and write the answer down.
5. Delete `meta:erl_crash.dump` (2 MB, already git-ignored via `meta:.gitignore:24`, untracked).
6. Restore the `AGENTS.md:223-224` hint once a SIGTERM no longer corrupts anything.

**Acceptance**
- [ ] A comptime body that calls `io:format/1` compiles; its output does not reach the frame stream
- [ ] A frame length above the cap fails as a transport error with a message, not an OOM
- [ ] A test in the codegen-hardening spec's `persistent_erl` set covers both
- [ ] `meta:erl_crash.dump` is gone

---

## Group A — the removed WAT runtime (5.6, 5.7)

`wasm3` and `wat_runtime` are gone: no file named `wasm3*`, `wat_runtime*` or `wat_to_wasm*`
exists, there is no `vendor/`, and nothing in the tree calls `linkLibC`, `link_libc` or `@cImport`.
What is left is dead code, comments asserting the removed architecture in the present tense, and a
CI step that downloads a binary nothing invokes.

**Settle first (codegen-hardening spec):** whether a WAT runtime is wired back in. `executeWat`
(`codegen/runtime.zig:547-558`) returns `""` unconditionally and is honestly documented as a stub —
it is the only accurate wasm3-adjacent comment in the tree. Everything below reads differently
depending on that answer, so do not start until it is made.

### A1 — dead code (5.6)

| Site | What a reader sees | Fix |
|---|---|---|
| `build.zig:13-15`, imported at `:96` and `:108` | A `build_options` module with **no options registered** (`b.addOptions()` then `createModule()`; no `addOption` anywhere) and **no importer** — `grep 'import("build_options")'` over the tree matches only the *comment* at `:13` | Delete the module and both `addImport` calls |
| `build.zig:95` | `// wasm3 headers are accessed via @cImport in` — a sentence with no object; its referent was deleted | Delete the line |
| `build.zig:17-23`, `libcResolvedTarget` at `:334-347` (glibc pinned to 2.38 at `:345`), consumed at `:102, 162, 182, 201, 217` | A glibc pin whose entire justification is "wasm3 needs libc" | Drop it if `zig build` + `zig build test` pass without it on Linux-gnu (Arch glibc ≥ 2.42 and the CI runner). If a runner still needs it, keep it with a comment that does not mention wasm3 |
| `codegen/wat.zig:130` `pub fn emitFnWat` | **Zero callers** — `grep "emitFnWat("` over the whole tree returns the definition only. Not re-exported from `modules/compiler-core/src/root.zig`. Its doc comment names a caller (`comptime/template_eval.zig`) that no longer calls it | Delete, unless the WAT-execution step adopts it |
| `libs/std/src/builtins.d.bp:269-279` (`#[@Host]`) | `:272` — "the raw-infra WAT in `wat_runtime.zig` provides the actual implementation". The `Host` enum is still parsed (`ast.zig:1090`), so a `#[@Host]` fn is still **skipped at codegen** and nothing supplies a body | No `.bp` in the tree uses `#[@Host]`. Delete the annotation, or keep it and make the wat backend reject it instead of silently emitting nothing |

`wat.zig:2416-2419` is a self-documented known gap in the same family (`$__emit`,
`$__compilerError`, `$__binding_ref` "are defined by the `wat_runtime` prelude … In the
whole-program path nothing defines them"). It belongs to the WAT-execution decision, not to this
spec — cross-reference it rather than editing it here.

### A2 — comments asserting the removed architecture (5.6)

`codegen/config.zig:20-24` is the one that actively misleads: `:23` says "every comptime val
expression **now runs** through the embedded wasm3 interpreter". It runs on the persistent `erl`
server (`meta:architecture.md:15` — "Não há runtime Node, wasm3 ou WAT para comptime").

Remaining sites, all comments: `codegen/wat.zig:127, 129, 138, 442, 965, 968, 2417`;
`codegen/wat/wat_ast.zig:265, 494`; `codegen/AGENTS.md:508-514, 520-521, 605`;
`codegen/tests/features.zig:927`; `codegen/tests/wat.zig:402-403`;
`comptime/tests/helpers.zig:127`.

### A3 — CI (5.7)

`.github/workflows/test.yml`, 148 lines.

| Site | What a reader sees | Fix |
|---|---|---|
| `:82-100` | wasmtime installed on `ubuntu-22.04` (a pinned v45.0.1 tarball, `:86-96`) and `macos-14` (`brew`, `:98-100`), justified at `:71-73` as feeding "26 wasm-codegen snapshot tests". Only the `test` job installs it; `test-libs` (`:114-147`) does not. `executeWat` returns `""`, so **nothing invokes it** | Keep or drop per the WAT-execution decision. If kept, say what will use it and when |
| `:44` | Step named "Install Zig (pinned to `build.zig.zon` `minimum_zig_version`)" with `version: 0.16.0` hardcoded at `:47`. **There is no root `build.zig.zon`** — the only `.zon` files are under `modules/*/` | Name the real source of the pin, or add the root manifest the name claims |
| `:49` | "60 tests under `comptime/runtime/erlang.zig`". That file does not exist; the directory holds `AGENTS.md` and `persistent_erl.zig` | Rewrite to the real file. The OTP 27+ reason it gives (`json:encode/1`) still holds |
| `:1-6` | calls `test-libs` "opt-in"; it is a job with `needs: test` and `allow_fail: false` on linux/macOS | Rewrite |

**Acceptance (group A)**
- [ ] No `wasm3` / `wat_runtime` / `wat_to_wasm` / `wasm3_host` mention left in the tree
- [ ] `build_options` and `emitFnWat` deleted, or each has a named user
- [ ] `libcResolvedTarget` deleted, or its comment explains a reason that still exists
- [ ] Every comment about the comptime runtime names the persistent `erl` server
- [ ] `zig build` and `zig build test` green on Linux-gnu and on the CI runners

---

## Group B — build files that lie (5.4, 5.16, 5.17)

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| 5.4 | `build.zig:301` — `b.addSystemCommand(&.{ "bash", "../../scripts/test-vscode.sh" })`, cwd `.` at `:302` | The path resolves to `meta:scripts/test-vscode.sh`; **`meta:scripts/` does not exist** and `find -name test-vscode.sh` returns nothing. The step fails on every checkout, meta or standalone. `modules/AGENTS.md:65` lists it as working; the comment at `:294-300` describes an `npm ci` marker file that is never written | Delete the step (the extension runs `npm test` in its own repo — see module-health 7g), or inline `npm ci && npm test` with cwd `../vscode-extension` behind an existence check. The sibling `test-libs` step at `:285` shows the in-tree pattern this one violates. Update `AGENTS.md`, `modules/AGENTS.md:65` and the `:294-300` comment |
| 5.16a | `meta:build.zig` (107 lines, tracked, Portuguese) | Every path dangles — `:15` `modules/stdlib/src/prelude.zig`, `:22`, `:32`, `:54`, `:72`, `:88` — because `meta:modules/` does not exist. It declares the **same step names** as the real build (`test` at `:48`, `run` at `:105`), so `zig build test` typed one directory too high fails with a confusing path error instead of "no build.zig". It left `meta:.zig-cache/` and `meta:zig-out/` behind | Delete the file and both directories. `meta:AGENTS.md` already says the repo holds no code |
| 5.16b | `modules/compiler-core/build.zig:58-64` | `std_pkg_files` hardcodes **5** modules (`order, dict, sets, string_builder, queue`) — the first five of `root.bp:13-35`, which now declares 23. A build from inside `modules/compiler-core/` **succeeds** and produces a compiler that rejects `from "std"` for the other 18. Its `:57` tells the reader to maintain two lists; the root `build.zig:46-53` says `root.bp` is "the single source of truth … (no build.zig edit)". `modules/compiler-core/AGENTS.md:15-16` presents it as an entry point and `:28-31` gives commands that use it | Delete `modules/compiler-core/build.zig` + `.zon` and the same pair under `compiler-cli`, `language-server`, `lib-test-runner` unless a use is found (`compiler-cli` and `language-server` depend on compiler-core by `path = "../compiler-core"`; `lib-test-runner/build.zig:9` deliberately does not; `modules/bpmp` has a `.zon` and **no** `build.zig`, and builds only from the root at `build.zig:247-253`). Then fix `modules/compiler-core/AGENTS.md:15-16, 25-32` and `comptime/stdlib/AGENTS.md` |
| 5.17 | root `test_pub.zig` and `test_format.zig` | `test_pub.zig:2` imports `modules/core/src/parser.zig` — `modules/core/` does not exist — and calls a two-generations-old API (`parser.tokenize`, `Parser.init(alloc, tokens)`). `test_format.zig:16` uses `std.heap.GeneralPurposeAllocator`, the pre-0.15 spelling. Both define `pub fn main()`, neither is in `build.zig`, and `AGENTS.md:22-23` lists them between the build graph and `.github/` as first-class root artefacts | Delete both; remove `AGENTS.md:22-23` |

The `modules/compiler-core/build.zig` header is unmodified `zig init` boilerplate with a global
`fu`→`f` corruption (`fnction` at `:3, 5, 111, 121`) — a reason to delete rather than repair.

**Acceptance (group B)**
- [ ] `zig build test-vscode` runs and passes, or the step and every reference to it are gone
- [ ] `zig build` from any directory either works or fails with "no build.zig"
- [ ] No second list of std modules exists anywhere
- [ ] No unreachable `.zig` file sits at a repo root, and `AGENTS.md` trees match the disk

---

## Group C — `libs/std` declarations and one stale filename (5.1, 5.2, 5.3, 5.14)

The compile order for `libs/std` belongs to the module-health spec, step 6. This group owns what
is left once that lands: the declared surface and the name.

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| 5.1 | `libs/std/src/root.bp:13-35` (23 `pub mod`, neither `reflect` nor `types`); `build.zig:35-39` `std_core_files` (three entries, neither) | `reflect.bp` (`mergeRecords`) and `types.bp` (`mapFields`, `partial`, `omit`, `pick`) are embedded by nothing: `stdPkgFilesFromRoot` (`build.zig:56`) derives the package set from `root.bp` alone. `libs/std/AGENTS.md:27-29` already lists them as "not declared". Neither has tests | Follow module-health 6e, which establishes that four of the five functions already exist as Zig builtins and the fifth (`mapFields`) exists nowhere. Recommended: delete both files and the `AGENTS.md:27-29` lines |
| 5.2 | `build.zig:36` + `comptime/stdlib/prelude.zig:12` | `primitives.bp`'s 67 `test` blocks (from `:296`) are `@embedFile`d as a source string and never compiled in test mode. `libs/std/test/` holds only `result_test.bp`. `pub mod primitives;` is not the fix — it would put the file in `std_core_files` **and** `std_pkg_files`, declaring the primitive interfaces twice | Module-health 6f owns the move. This spec closes when the file is in exactly one of the two sets |
| 5.3 | `libs/std/botopink.json:8-11` | `files` names `primitives.d.bp`, `array.d.bp`, `string.d.bp`, `builtins.d.bp`; only the last exists. `array.d.bp`/`string.d.bp` were folded into `primitives.bp` — `comptime.zig:615-618` binds both interface sources to the same blob. Read at `cli/libs.zig:300-312`; the `try` at `:302` aborts on the first miss with a bare `FileNotFound` and no diagnostic, unlike the manifest probe at `:289` | Module-health 6b. Additionally: make `libs.zig:302` name the missing path |
| 5.14 | 33 comment sites | `primitives.d.bp` was renamed to `primitives.bp`. Two sites assert a location rather than just a name: `codegen/tests/features.zig:926` gives the full path `libs/std/src/primitives.d.bp`, and `language-server/src/engine.zig:4172` names all three phantom files together — the likely origin of the `botopink.json` drift. Full list: `libs/std/src/{root.bp:9, erlang.bp:22, math.bp:27}`; `comptime/stdlib/prelude.zig:7`; `comptime/env.zig:622`; `comptime/infer.zig:6558, 6620`; `comptime.zig:378, 615`; `test_warmup.zig:3`; `codegen/erlang.zig:1085, 1113, 1168, 1280, 1607, 1632, 1634, 1645, 2188, 3825`; `codegen/beam_asm.zig:58, 832, 917`; `codegen/commonJS.zig:779`; `codegen/tests/std_package.zig:11`; `codegen/tests/features.zig:825, 926`; `language-server/src/engine.zig:1100, 1113, 4172, 4448`; `language-server/src/tests/hover.zig:181` | Rename in comments. Fix the `root.bp:9` header — the ambient files are `primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`. **Leave** `compiler-cli/src/cli/resolver.zig:635` and `lib-test-runner/src/discovery.zig:384`: both assert that the `.d.bp` *extension* is not a compilable source, so the string is an example of the extension, not a reference to a file |

**Acceptance (group C)**
- [ ] `grep -rn 'primitives\.d\.bp'` returns only the two extension-assertion tests
- [ ] Every `files` entry in every `botopink.json` in the workspace resolves
- [ ] `libs/std/AGENTS.md`'s tree matches `src/`

---

## Group D — instructions and vocabulary that do not work (5.8, 5.13)

| # | Deciding site | What a reader sees | Smallest fix |
|---|---|---|---|
| 5.8 | `examples/hello.bp:3-4` | `botopink run examples/hello.bp` and `botopink check examples/hello.bp`. The CLI is project-based: `main.zig:116-118` calls `check_cmd.run` without slicing `args[2..]` at all, so the path is ignored and `check.zig:14-16` reports "botopink.json not found — are you in a botopink project?"; `parseRunOpts` (`main.zig:175-200`) has **no final `else`**, so a bare positional falls through every branch silently. These are the first two lines a new user reads | Replace the header with the sequence `examples/AGENTS.md:56-58` already documents: `botopink new demo && cp examples/hello.bp demo/src/main.bp && cd demo && botopink run`. Rejecting unexpected positionals belongs to module-health step 4 |
| 5.13 | `comptime/tests/infer_decls.zig:518` | `@external(node, "./gleam_stdlib.mjs", "string_length")`, sitting next to a correct `@External.Erlang(…)` on `:517`. `ast.zig:1796` (`FnDecl`) and `:1099` (`InterfaceMethod`) both gate on `startsWith(a.name, "External.")`, so the lowercase form **can never match** — it parses, type-checks, and is silently ignored by every backend. The test passes only because its sibling annotation carries the load | Rewrite the fixture to `#[@External.Node(…)]` and re-record its snapshot. Then decide whether a lowercase `@external` should be a parse error rather than silently inert — `codegen/tests/externals.zig:51` is named *"External.\<Target\> ---- template equivalent to @external(target, template)"*, which asserts an equivalence `ast.zig:1796` does not implement |
| 5.13 (cont.) | ~24 comment sites | `@external(<target>, …)` described as the live form: `codegen/erlang.zig:1069, 1156, 1163, 1268, 1275, 1388, 1394, 1438, 1484, 1596, 1643, 1653, 1718, 1742, 1761, 3402, 3446, 3825, 3842`; `codegen/commonJS.zig:206, 716, 735, 744, 747, 826, 898, 946, 1367, 2600, 2608, 2678`; `codegen/beam_asm.zig:46, 830, 917, 2565, 2586`; `comptime/infer.zig:89, 6639, 6702, 7083`; `comptime/env.zig:503`; `comptime/diagnostics.zig:172`; `codegen/AGENTS.md:175`; `comptime/AGENTS.md:68`; `codegen/tests/externals.zig:117, 135`; `comptime/tests/std_target_gating.zig:6`; `codegen.zig:26`; `parser/decls.zig:400`. An even older bracket form `@[external(…)]` survives at `commonJS.zig:206, 716`, `erlang.zig:1156` and `parser/tests/errors.zig:148, 156` | Rewrite to `#[@External.<Target>(…)]`. **`libs/std/src/http.bp:62` is the one user-visible site** — do it first. Leave the sites that already label it as legacy: `infer.zig:2099, 2107, 2113` (error messages suggesting the correct form) and `beam_asm.zig:740` (explicitly "(or legacy `external(beam,`)") |

**Acceptance (group D)**
- [ ] No comment, fixture or `.bp` file presents `@external(<target>, …)` or `@[external(…)]` as current
- [ ] `examples/hello.bp`'s header works when pasted into a shell
- [ ] Whether a lowercase `@external` is rejected or accepted is decided and written down

---

## Decisions (not work)

These two do not have a smallest fix; they have an answer someone has to give. Nothing in their
groups can close until they do.

### 5.9 — the license

`README.md:74` says `MIT`. There is no `LICENSE` file in **any** of the seven repos
(`find -maxdepth 3 -iname 'LICENSE*'` over the workspace returns nothing), and
`vscode-extension/package.json` has no `license` field (211 lines; keys run `name … dependencies`,
no `license`), so `vsce package` warns and the Marketplace listing shows none. Each sibling README
also carries a License section with no file behind it.

**Decide:** the license, and whether all seven repos take the same one. Then add `LICENSE` to all
seven and `"license"` to the extension's `package.json`. Until it is decided, the extension is
published unlicensed.

### 5.5 — whether the meta repo needs a gate, and how a hook gets installed

Two separable questions. The facts:

| | |
|---|---|
| Hook source | `scripts/git-hooks/pre-commit` exists in all six code repos (23 lines, byte-identical), plus `scripts/git-hooks/lib/runner-standalone.sh`. **emilia has neither** (module-health 7d) |
| Delegation | `pre-commit:12-17` prefers `$META_ROOT/scripts/git-hooks/lib/test-runner.sh`; `meta:scripts/` does not exist, so the branch is dead and `:21-22` always takes the standalone fallback. `runner-standalone.sh:2-4` still calls itself a mirror of `botopink/projects'` runner — a repo that is not in this workspace |
| Installed hooks | **None, anywhere.** Every `.git/hooks/` holds only `*.sample`; `core.hooksPath` is unset in the meta repo and in all six submodules |
| meta | `meta:.git/hooks/pre-commit` is a **dangling symlink** to `../../scripts/git-hooks/pre-commit`, beside a stale `pre-commit.bak.20260614-175956`. Meta commits run no gate |
| Documented install path | Both `AGENTS.md`s point at `scripts/install-hooks.sh` in the meta repo, which has no `scripts/` |

**Decide (a):** does the meta repo need a pre-commit gate? It holds no code — only submodule
pointers and `specs/`. If no, delete the dangling symlink and the `.bak`; if yes, the gate has to
be something a specs-only repo can run.

**Decide (b):** is the hook self-contained per repo, or does a shared runner come back? Everything
today points at a meta script that does not exist. Self-contained is the smaller change: drop the
`pre-commit:12-17` meta branch in all six repos, fix the `runner-standalone.sh:2-4` header, and
document `git config core.hooksPath scripts/git-hooks` in each `AGENTS.md` §Local gate.

Note that "the sibling hooks are installed" is **false at HEAD** — nothing is installed anywhere,
so no sibling gate has ever run locally. The module-health spec's note that a red hook blocks
commits in jhonstart/onze/rakun/erika describes what will happen once (b) is answered, not today.

**Acceptance (decisions)**
- [ ] `LICENSE` in all seven repos; `"license"` in `vscode-extension/package.json`
- [ ] `git config core.hooksPath scripts/git-hooks` (or the chosen equivalent) documented in every
      repo's `AGENTS.md`, and the hook demonstrably runs after following it
- [ ] `meta:.git/hooks/pre-commit` either resolves or is gone
- [ ] No script or `AGENTS.md` references `meta:scripts/` or `botopink/projects`

---

## Acceptance

- [ ] Every item fixed, or closed with a written reason in this file
- [ ] Matching `AGENTS.md` files updated in the same commits
- [ ] `zig build`, `zig build test` and `zig build test-libs` green (group C may add known
      failures, registered by name in the codegen-hardening spec)
