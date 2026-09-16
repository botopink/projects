# The declared surface

What `libs/std` says it has, against what it has: a manifest naming three files that do not exist,
two modules nothing reaches, 67 tests nothing runs, and one external naming an OTP function OTP
never had.

---

## 6b — `botopink.json` `files` names three files that do not exist

`libs/std/botopink.json:8-11` lists `primitives.d.bp`, `array.d.bp`, `string.d.bp`,
`builtins.d.bp`. Only `builtins.d.bp` exists; the real core set is `primitives.bp`,
`builtins.d.bp`, `builtins_fns.d.bp` (`build.zig:35-39`). `array.d.bp` and `string.d.bp` were folded
into `primitives.bp` — `comptime.zig:615-618` binds `array_interface_src` and `string_interface_src`
to the same `primitives` blob and says so.

`files` is consumed by `compiler-cli/src/cli/libs.zig:300-312`; the read at `:302` is a bare `try`,
so the **first** missing entry aborts `loadLibModules` with an unhandled `error.FileNotFound` — no
diagnostic naming the file, unlike the manifest probe at `:289` which does `catch continue`. It is
latent only because `std` is served by the embedded prelude rather than by this loader.

**Fix in the std source:** set `files` to the three real core files, or drop the key once nothing
resolves `std` through `libs.zig` (CLI `loadDependencies`, LSP `project_graph.zig:163`). Either way
`libs.zig:302` should report the missing path instead of propagating `FileNotFound` — that half is a
CLI change and belongs to [`../02-cli-gate/`](../02-cli-gate/README.md).

The stale filename has spread: `language-server/src/engine.zig:4172` names all three phantom files
together and is the likely origin of the manifest drift. The 33 comment sites are the hygiene
front's — [`../11-hygiene/std-declarations.md`](../11-hygiene/std-declarations.md), item 5.14.

**Acceptance:**
- [ ] Every entry of every `botopink.json` `files` in the workspace resolves
- [ ] A missing `files` entry produces a located diagnostic, not a bare error name

---

## 6e — `reflect.bp` and `types.bp`

Neither is in `root.bp` nor in `build.zig:35-39` `std_core_files`, so neither is embedded by
anything; `stdPkgFilesFromRoot` (`build.zig:56`) derives the importable set from `root.bp` alone.
Declaring them does not help, because each fails on its own **and** because the four functions they
define already exist in Zig and would be intercepted by the
[6a](./blockers.md#6a--the-comptime-type-manipulation-intercept-claims-pick-before-any-module-can)
code path regardless:

| File | Defines | Zig implementation | Compiles today |
|---|---|---|---|
| `reflect.bp:19` | `mergeRecords` | `infer.zig:4076` `resolveMergeRecords` | no |
| `types.bp:17` | `mapFields` | **none** (`infer.zig:4071-4072`) | no |
| `types.bp:37` | `partial` | `infer.zig:4062` `resolvePartial` | no |
| `types.bp:52` | `omit` | `infer.zig:4065` `resolveOmit` | no |
| `types.bp:68` | `pick` | `infer.zig:4068` `resolvePick` | no |

Verified: with no `.bp` declaration anywhere, `mergeRecords(User, Stamps)`, `partial(User)`,
`omit(User, "id")` and `pick(User, ["name"])` all check clean; `mapFields(...)` reports
`unbound variable 'mapFields'`.

Why each fails, precisely — **the recorded cause for `reflect.bp` is incomplete**:

| Site | What a reader sees | Real cause |
|---|---|---|
| `types.bp:23` (also `:55`, `:71`) | `error: unknown field 'Record' on type 'TypeInfo' at types:23:16` | `TypeInfo` is an **enum** with a `Record(fields: RecordField[])` variant (`comptime.zig:594-605`). `info.Record.fields` is variant-payload access written as nested field access; the payload is reachable only through `case info { TypeInfo.Record(fields) -> … }` |
| `reflect.bp:26` | `error: parse error in reflect` — **no location** (parse and lexer errors are unlocated; that is the CLI front's row) | Two independent blockers. (1) `and` is not a keyword: `lexer.zig:693-745` has no entry for it, so it lexes as an identifier. (2) **Rewriting it to `&&` does not fix it** — `exprs.zig:136` parses an `if` condition at `prec.equality`, which `parser.zig:1134-1140` defines as level 2, *below* `\|\|` (0) and `&&` (1), and documents as "operand positions where `\|\|`/`&&` are not accepted (if-conditions, yields, ranges, assignments…)". `if (a && b)` is a parse error for every operand shape. No `.bp` in the workspace uses it; `libs/std/src/path.bp:83` and `primitives.bp:102` show the two forms that do work (`val c = a == b && …;` and `return … && …;`) |
| `reflect.bp:24-25,37,40,42` | — | the same `info.Record.fields` as `types.bp`, behind the parse error |
| `primitives.bp:473` | `error: type mismatch: expected string, got i32 at primitives:473:21` | Exactly **one** error in 1019 lines. `val always42 = Function.constant(42)` is not generalised, so its parameter type is a single unification variable: `:472` binds it to `string`, `:473` then offers `i32`. A let-generalisation gap, not a `Function` bug |

**This is a shipping decision.** Recommended: delete `reflect.bp` and `types.bp`. They are 1129 lines
of unreachable source that shadow working implementations and give a false impression that the std
has `.bp` type functions. If [`../07-checker/`](../07-checker/README.md)'s std-type-functions step
wants `.bp` sources instead, it owns all five fixes above plus an implementation of `mapFields`, and
it must decide first whether the Zig intercept or the `.bp` module is the definition.
[`../11-hygiene/std-declarations.md`](../11-hygiene/std-declarations.md) item 5.1 tracks the same
file pair from the hygiene side.

The `if (a && b)` finding is not a std defect — it is a parser restriction that no `.bp` in the
workspace has ever hit. It is recorded here because it is the reason `reflect.bp` cannot be revived
by a one-line rewrite; the restriction itself belongs to whoever owns the precedence table.

**Acceptance:**
- [ ] `reflect.bp` and `types.bp` are deleted, or declared in `root.bp` with tests that run
- [ ] `libs/std/AGENTS.md:27-29` matches the outcome
- [ ] `mapFields` either works or is documented as not existing

---

## 6f — `primitives.bp`'s 67 tests are unreachable

`primitives.bp` is embedded as a core file only (`build.zig:36`, `comptime/stdlib/prelude.zig:12`),
i.e. as a source string flattened into the global type env. It is never compiled in test mode, so
its 67 `test` blocks (`:296` onward) never run. `libs/std/test/` holds one unrelated file,
`result_test.bp`.

`pub mod primitives;` would put it in **both** sets — `std_core_files` (`build.zig:35-39`, embedded
into the prelude) and `std_pkg_files` (`build.zig:56-83`, registered as the importable package
`std/primitives`) — so the primitive interfaces would be declared twice and
`import {primitives} from "std"` would become a surface nobody wants.

**Fix in the std source plus the harness:** move the tests to `libs/std/test/primitives_test.bp`
(`test/` is scanned directly and sees the global env), or add a compiler-core test that compiles
`primitives.bp` in test mode. Expect one failure to carry over — 6e's `primitives.bp:473` — plus
whatever the 66 remaining tests find; register those by name rather than fixing them in this front.
[`../11-hygiene/std-declarations.md`](../11-hygiene/std-declarations.md) item 5.2 is the hygiene
half of the same move.

**Acceptance:**
- [ ] The 67 tests run on commonJS and erlang, with their failures registered by name
- [ ] `primitives.bp` is in exactly one of `std_core_files` / `std_pkg_files`
- [ ] A module in `libs/std/src/` that no `mod` path reaches fails the gate (the gate step is
      [`../02-cli-gate/`](../02-cli-gate/README.md)'s)

---

## E3 — `string:suffix/2` is not an OTP function

`libs/std/src/primitives.bp:143` carries `#[@External.Erlang("string", "suffix")]` and `:144`
`@External.Beam(""" {call_ext, 2, {extfunc, string, suffix, 2}}.""")` — `erl` answers
`undef [{string,suffix,[<<"foobar">>,<<"bar">>],[]}]`. Not a codegen gap at all: the annotation names
a function OTP never had.

Replace with a real suffix test — `binary:longest_common_suffix/1`, or `string:find(S, Suf,
trailing)` compared against `Suf`. Fixture:
`endswith_lowers_via_external_beam_single_line_body`, which is one of the seven fixtures where
**erlang** is the backend that is wrong (it crashes; commonJS prints `true`).

It closes 1 erlang fixture and is `libs/std` only, which is why it is here and not in
[`../05-erlang/`](../05-erlang/README.md).

**Acceptance:**
- [ ] `endswith_lowers_via_external_beam_single_line_body` runs on erlang and beam and prints `true`
- [ ] No `@External.Erlang` / `@External.Beam` in `libs/std` names a function `erl` answers `undef` to
