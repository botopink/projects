# Spec 08 — Module health

**Version:** 1.0.2-beta
**Priority:** critical — four of six libraries cannot compile, and three CLI commands report success on failure
**Depends on:** spec 01 (the comptime dispatch fix is the shared cause of the library breakage)

---

## Objective

Every library in the workspace compiles and its tests run; a CLI command's exit code matches what
it actually did; and the gate exercises the libraries, so this class of breakage cannot hide again.

Paths are relative to `repository/botopink-lang/` unless they start with a sibling repo name.

## Current state

Measured against a compiler built from HEAD (the checked-in `zig-out/bin/botopink` was stale — it
predated half the 1.0.1-beta waves, which is itself worth knowing when diagnosing).

| Module | `check` | `test` | Note |
|---|---|---|---|
| emilia | pass | **17/17** | was dead (source carried markdown escapes, `#\[@External\.node(`); fixed |
| erika | fail | fail | 13 template tests dead (L1); 16/18 of the fluent layer passes with them removed |
| jhonstart | pass | fail | 8/8 pass once the module compiles (verified by running the emitted JS) |
| onze | pass | fail | 8/8 pass once the module compiles |
| rakun | **fail** | fail | fails before compiling: declares a dependency that exists nowhere (L2) |
| vscode-extension | — | **15/15** | in sync with the server; its drift is cosmetic and predates the waves |
| `libs/std` | fail | fail | does not compile; 1147 lines in 3 modules have never compiled |

**No failure is a regression of the 1.0.1-beta waves** — each reproduces byte-identically on the
compiler built from the commit the milestone started at. (One real wave regression was found and
already fixed: the wasm backend folded an unlowerable call into a constant, so a program compiled,
loaded and did nothing with exit 0.)

---

## Steps

### Step 1 — Primitive methods in a comptime body (L1)

The comptime module defines `__bp_add/2`, `__bp_len/2`, `__bp_text/1`, `__bp_json/1` and the host
glue. **Every other primitive method lowers to a bare local call that nothing defines** — swept at
HEAD: `push`, `join`, `split`, `contains`, `at`, `indexOf`, `map`, `reverse`, `toUpper`,
`startsWith`, `slice`, `append`, `trim`; only `.length` resolves. The typed path gets this right
(`--target erlang` emits `length(string:split(S, <<"">>, all))`), so the fix is to route a
primitive method through the same table in the untyped path (`codegen/erlang.zig` `Emitter.untyped`)
rather than to extend the prelude by hand.

This is one defect behind four libraries: erika (template, 26 of its 35 lint errors), jhonstart
(template), onze (decorator), rakun (decorator). **Spec 01 must widen with it**: its acceptance
names templates and `template_eval.zig` only, while onze and rakun fail through
`decorator_eval.zig`, and `push` is a *mutation*, not in its read-only list.

**Acceptance:**
- [ ] A template body and a decorator body may call any primitive method the typed path supports
- [ ] erika, jhonstart, onze and rakun compile their own test suites
- [ ] A compiler-core regression test covers both hosts, so it does not depend on a sibling checkout

### Step 2 — Mutation through a method inside a closure (L3)

`args.push(x)` inside `forEach` is emitted as a *discarded* call, while an outer-`var` assignment in
the same position is correctly folded into `lists:foldl`. Even with `push/2` defined, rakun's
constructor injection would build an empty argument list — step 1 alone does not unblock it.

**Acceptance:**
- [ ] A method that mutates its receiver inside a closure threads the value out, like assignment does
- [ ] rakun's decorators produce the arguments they collect

### Step 3 — Trailing default parameters at the call site (L4)

`pub fn h1(children: Children, attrs: Array<#(string,string)> = [])` cannot be called `h1(x)`:
`'h1' expects 2 argument(s), got 1`. Record **methods** expand their defaults; free **fns** and
record **constructor fields** do not (`comptime/infer.zig` arity checks; `transform.zig` has the
machinery and is not reached). `parser/tests/declarations.zig` states the gap.

It makes jhonstart's entire documented API uncompilable, breaks 2 of its 4 examples and the
emilia example, and is why `element.bp` writes `attrs: []` at 20+ of its own call sites.

**Acceptance:**
- [ ] A free fn and a record constructor accept a call that omits trailing defaults
- [ ] jhonstart's examples and its documented API compile

### Step 4 — A CLI command must not report success on failure (L5)

| Command | Today | Wanted |
|---|---|---|
| `build` | exits 0 on a module that failed to compile and writes nothing (a stale `out/` is left in place, and `run` then executes it) | fail like `test` does (`cli/test_cmd.zig` has the guard; `cli/build.zig` does not) |
| `test` | fail-fast at project scope: one bad module in `test/` returns before any artifact is written, so jhonstart's 6 healthy `src/` tests never run | run every module that compiles, report the ones that did not |
| `check` | scans `src/` only, so the diagnostic `test` tells you to look for is unreachable | cover `test/`, or stop pointing at it |
| lexer errors | surfaced as a bare `@errorName` with no file, line or excerpt | route through the located-diagnostic path type errors already use |
| `migrate <path> --dry-run` | writes files (the flag is matched only at `args[2]`) | honour the flag wherever it appears |
| `format --check` | exits 0, printing nothing, on unparseable source | a file that does not parse fails the check |
| `check <path>` | ignores its argument | accept it or reject it |
| `--target=erlang` | silently dropped (no flag parser has an `else` arm) | accept or reject every flag form |
| `new --target frobnicate` | accepted, written to the manifest, degrades to commonJS | reject an unknown target |
| `format`/`run` | leak their argument list (`main.zig` `parseFormatOpts`, `parseRunOpts`) — visible on every successful run | freed |

**Acceptance:**
- [ ] Every command's exit code matches its outcome, with a CLI test per row

### Step 5 — The gate must cover what ships (L6)

`zig build test` depends on four things: compiler-core tests, a grep gate, LSP tests and
compiler-cli **unit** tests. Everything below is reachable by no automated check:

- compiling a `.bp` library — `test-libs` is in no gate, is 8/8 red today, and in CI runs after a
  checkout of botopink-lang alone, so it only ever sees `libs/std`
- program **output** on erlang/beam/wasm — assertions are return values via `--invoke`/`-eval`,
  never stdout; that is exactly the blind spot the wasm regression slipped through
- the CLI end to end — no step runs the binary against a real project
- `zig build test-vscode` — invokes `../../scripts/test-vscode.sh`; the meta repo has no `scripts/`
- `zig build test-backends` — in no gate, and one of its two "pinned red" escape hatches is stale
  (the beam cell now prints that the case-dispatch codegen looks fixed)
- `modules/compiler-cli/tests/`: 3 of 4 scripts are wired to nothing; `test_tooling.sh` asserts a
  banner no runner emits and has rotted red undetected
- a module no `mod` tree reaches is a **warning**, so 1147 lines of `libs/std` vanish silently
- `hook-integrity` is referenced as a gate and **no such build step exists**

**Acceptance:**
- [ ] The documented gate is `zig build test && zig build test-libs`, and CI runs both with the
      sibling repos checked out
- [ ] At least one snapshot per backend asserts on stdout
- [ ] Every script under `modules/compiler-cli/tests/` is either wired to a build step or deleted
- [ ] A module not reached by a `mod` path fails, or is counted and reported

### Step 6 — `libs/std` (L7)

- `primitives.bp`, `reflect.bp`, `types.bp` are in no `mod` tree, and none of the three compiles:
  `reflect.bp` uses the keyword `and` (the parser has only `&&`), `types.bp`/`reflect.bp` read
  `info.Record.fields` although `TypeInfo` is an enum, `primitives.bp` hits a known generic gap
- `random.bp` defines `pub fn pick<T>` and the comptime builtin `pick` claims the name first, so
  `libs/std` does not compile even as configured
- `botopink.json` `files` lists three `.d.bp` that do not exist, so every `from "std"` consumer is
  short three declaration modules
- `primitives.bp` declares 22 primitives against `@External.Node("./gleam_stdlib.mjs", …)` and that
  file exists nowhere and is never shipped — any `.slice()`-backed op throws at require time
  (2 of erika's 18 fluent tests, and jhonstart/onze paths)

**Acceptance:**
- [ ] `libs/std` compiles and its tests run (the 67 in `primitives.bp` included)
- [ ] No declaration in `libs/std` names a file that is not shipped

### Step 7 — Library repos (L2, L8, L9, L10)

- **rakun** declares `"dependencies": ["server"]` and no `server` library exists in any root, in any
  commit, in any submodule — `check`, `test` and `build` all fail at step zero. Vendor it, make it a
  submodule, or drop the dependency
- **erika**: the two-parameter `loop (coll) { item, index -> }` form loses the accumulator (it
  degenerates to `lists:foreach/2` with an arity-2 fun — a lint error *and* a runtime `badarg`);
  the typed backend has the same bug. Its `AGENTS.md` still documents a JavaScript comptime
  evaluator, so every documented workaround is now the cause of L1
- **emilia**: no pre-commit hook and no CI — nothing would have caught the escaped source
- **vscode-extension**: `struct` and `*fn` snippets and the `struct` grammar keyword are for syntax
  the parser rejects; the Test Explorer forwards `beam`/`wasm` to a `botopink test` that refuses
  them; its CI pins `BOTOPINK_LANG_REF || 'main'`, so it never exercises the `feat` compiler
- **bpmp** is the healthiest module in the workspace (builds, genuinely offline, 94 tests) but has
  three git-dependency bugs: `install --frozen` symlinks a store path it never checks, a first
  install of a `branch:`/`tag:` dep clones default HEAD, and `sync` resolves every dep to
  `botopink/<name>`

**Acceptance:**
- [ ] Every sibling library's pre-commit hook runs and passes
- [ ] No library documents an API that does not compile

## Notes

- The sibling hooks are installed but the documented install path is dead: both `AGENTS.md`s point
  at `scripts/install-hooks.sh` in the meta repo, which has no `scripts/` directory. See spec 05.
- A library repo cannot be committed to while its hook is red — that currently blocks jhonstart,
  onze, rakun and erika, including unrelated maintenance.
