# `std/testing/snapshots` — the snapshot engine

Step 3 of the front. `libs/std/src/testing/snapshots.bp`; `import {testing.snapshots} from "std";`
— only the leaf `snapshots` enters scope (decision 107).

## The three rules

1. `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`, where `suite` is
   the text before the first `": "` of the test name and `slug` is the slugified rest.
2. A mismatch or a missing file writes `<path>.new` and fails the test. Nothing accepts a snapshot
   but a person renaming the `.new` file. **There is no update flag** — no CLI flag, no environment
   variable, no `botopink.json` key (decision 67).
3. Every library, module and submodule owns the `__snapshots__/` beside its own tests and exposes,
   from `<lib>-test`, the `assert<Subject>(loc, …) -> @Result<void, string>` helpers that write them.

## The path rule

```
loc.file  = "src/emilia.bp"
loc.fnName = "css: modifiers ---- hover on md breakpoint"
                ^^^  suite                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  rest

path(loc) = "src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap"
```

| Piece | Rule | Why |
|---|---|---|
| directory | `dirname(loc.file)` + `/__snapshots__/` | beside the test that owns it — one directory per source directory, so two fronts editing different files never fight over one snapshot directory (`specs/__template.md` § `fronts.md`) |
| `suite` | the text before the **first** `": "` in `loc.fnName`, slugified | a sub-directory per subject keeps a library's hundreds of snapshots browsable; the same convention the compiler's harness uses for `js:`/`erlang:`/`wasm:` (`codegen/tests/helpers.zig` `slugFromSrc`) |
| `slug` | the text after that `": "`, slugified | |
| slugify | lowercase; every maximal run of `[A-Za-z0-9]` is kept, everything else becomes one `_`; no leading or trailing `_` | byte-for-byte the rule of `codegen/tests/helpers.zig` (`slugify`), so a `.snap` name reads like the compiler's `.snap.md` fixtures — `"modifiers ---- hover on md breakpoint"` → `modifiers_hover_on_md_breakpoint` |
| extension | `.snap` | the contract's; the compiler's `.snap.md` wraps sections in fences because one fixture holds source + output + run log — a std snapshot holds one body |
| no `": "` in the name | `Error("snapshots: test name needs a suite - write \"<suite>: <description>\"")` | decision 67 — refuse, do not default to `misc/` |
| `fnName == ""` | the same error, worded for module level | a `@src()` taken outside a test has no test name |
| `pathNamed(loc, name)` | `…/<slug>.<slugify(name)>.snap` | a test that records two snapshots names the second; `name` empty is refused |

`path` is pure botopink over `String` methods and is the same on every backend; it is the one
function of the module that the beam and wasm targets can run.

**Resolution at run time.** `path(loc)` is package-relative because `loc.file` is
(`src-builtin.md` § *The record*). The engine opens it relative to the process's working directory,
and `botopink test` runs from the package root — the same assumption `io/fs.bp`'s inline tests make.
Acceptance pins it: a test that reads `process.cwd()` and `path(@src())` and checks the joined file
exists after a first `.new` write.

## The `.snap` file format

```
botopink-snap 1
test: css: modifiers ---- hover on md breakpoint
subject: css

@media(min-width:768px){:hover{background:red}}
```

| Line | Content | Rule |
|---|---|---|
| 1 | `botopink-snap 1` | magic + format version; anything else → `Error("snapshots: not a snapshot file: <path>")` |
| 2 | `test: <loc.fnName>` | the full test name — a `.snap` opened on its own says which test owns it |
| 3 | `subject: <subject>` | what produced the body: `text` for `assertText` and `assertNamed`, the `<Subject>` a helper passes to `assertAs` (`css`, `js`, `html`, `route`) |
| 4 | empty | header terminator |
| 5… | the body, verbatim, to end of file | the writer appends exactly one `\n`; a body that already ends in newlines keeps them |

What the header deliberately does **not** carry: the line number (tests move; a snapshot must not
churn because a test above it grew), the date, the compiler version, the target. A snapshot is
evidence, not a baseline, and its bytes are a pure function of `(test name, subject, body)` — the
same body recorded on commonJS and on erlang is the same file, which is what makes a cross-target
divergence a mismatch rather than two files.

**Comparison.** Header lines compare exactly. Bodies compare after `\r\n → \n` normalisation and
trimming of trailing newlines on both sides — the two normalisations `utils/snap.zig` applies, for
the same windows-runner reason. Nothing else is normalised: whitespace inside the body
is the body.

## Mismatch, missing, match

| Case | The engine does | Answers |
|---|---|---|
| `<path>` missing | creates `dirname(path)` (recursive), writes `<path>.new` with the full file (header + body) | `Error("snapshots: missing <path> - candidate written to <path>.new; review it and rename it to record")` |
| `<path>` present, differs | writes `<path>.new` | `Error("snapshots: mismatch <path> - candidate written to <path>.new (first difference at body line N)")`; `N` counts from the first body line; a header-only difference says `(header differs)` |
| `<path>` present, equal | deletes `<path>.new` if one is lying around from an earlier run | `Ok` |
| `<path>` unreadable / not a snapshot file | nothing written | `Error("snapshots: not a snapshot file: <path>")` |
| write of `.new` fails | — | `Error("snapshots: cannot write <path>.new: <host error>")` — a full disk is a test failure, not a silent pass |

A person accepts a snapshot by **renaming `<path>.new` to `<path>`** — `mv`, an editor, a review
tool. That is the whole acceptance protocol (decision 67: the strict side, no knob). The compiler's
own harness additionally records a missing snapshot when `BOTOPINK_SNAP_CREATE=1` is set
(`utils/snap.zig`); the std engine does **not** copy that switch, and step 3's acceptance greps the
module for any code path that writes `<path>` itself. Whether the compiler harness should lose its
switch too is for the front that owns `utils/snap.zig`, recorded in `README.md` § *Not in this front*.

## The API

```bp
//// std/testing/snapshots — the snapshot engine every `<lib>-test` writes through.

// The path rule. Pure; every backend.
pub fn path(loc: SourceLocation) -> string
pub fn pathNamed(loc: SourceLocation, name: string) -> string
pub fn suiteOf(testName: string) -> string        // "" when there is no ": "
pub fn slugOf(text: string) -> string             // the slugify rule

// The four entry points. All `-> @Result<void, string>`.
pub fn assertText(loc: SourceLocation, actual: string)                          // subject "text"
pub fn assertAs(loc: SourceLocation, subject: string, actual: string)           // what a <lib>-test helper calls
pub fn assertNamed(loc: SourceLocation, name: string, actual: string)           // two snapshots in one test
pub fn assertNamedAs(loc: SourceLocation, name: string, subject: string, actual: string)
```

The plain entry point is `assertText`, not `assert`: `assert` is a reserved keyword statement (the
reason the module beside this one is `asserts`), and `assertText` is the `assert<Subject>` spelling
for the subject the header records. The wrappers use the `try inner(); return;` shape every `-test`
helper uses, because `return r` inside a `@Result`-returning body re-wraps (`language-gaps.md`).

**Host cells — private, Node and Erlang.** A std module cannot call another std module, so
`snapshots.bp` cannot use `fs.readText`/`fs.writeText`/`fs.rm` or `path.dirname`. It re-declares
private cells in the `io/fs.bp` shape and writes `dirname`/`join` inline over `String.split`/`join`:

| Private cell | Node | Erlang |
|---|---|---|
| `readFile(p) -> @Result<string, string>` | `fs.readFileSync(p, 'utf8')` in an IIFE try/catch | `file:read_file/1` |
| `writeFile(p, text) -> @Result<i32, string>` | `fs.mkdirSync(dirname, {recursive: true}); fs.writeFileSync(p, text)` | `filelib:ensure_dir/1` + `file:write_file/2` |
| `removeFile(p) -> @Result<i32, string>` | `fs.rmSync(p, {force: true})` | `file:delete/1`, `enoent` is `ok` |
| `exists(p) -> bool` | `fs.existsSync(p)` | `filelib:is_file/1` |

Two more private cells serve the engine's own tests: `removeTree` and `tmpDir`. Private, so STD-001
does not fire and `import {testing.snapshots} from "std"` type-checks on beam and wasm; the four
`assert*` are unresolved there at lowering, which does not matter because no test runs there. The
docblock says so.

**No panic anywhere.** The engine's failure channel is the `@Result` it answers; a host error
inside a cell is an `Error` string, never a throw. That is what lets a test record two snapshots
and see both `.new` files in one run.

## How a library exposes `assert<Subject>` helpers

The contract: every `<lib>-test` submodule exposes `assert<Subject>(loc, …) -> @Result<void,
string>` helpers, and each is a thin wrapper that (a) turns the domain value into a string, (b)
calls `snapshots.assertAs(loc, "<subject>", text)`. The `loc` **must be the caller's `@src()`**,
taken inside the `test` body — a `@src()` written inside the helper would name the helper, and every
snapshot would land in `__snapshots__/<helper's suite>/…` beside the helper's own file.

```bp
//// emilia-test — modules/emilia-test/src/root.bp
import {testing.snapshots} from "std";
import {styleRule, defaultTheme, Token} from "emilia";

// The encoded sheet a token list produces under the default theme —
// `styleRule`'s second half (emilia `output.bp` `encodeSheet`).
pub fn assertSheet(loc: SourceLocation, tokens: Token[]) -> @Result<void, string> {
    val rule = styleRule(tokens, defaultTheme());
    try snapshots.assertAs(loc, "sheet", rule._1);
    return;
}

// The whole utility: the content-derived class name and the sheet it names.
pub fn assertUtility(loc: SourceLocation, tokens: Token[]) -> @Result<void, string> {
    val rule = styleRule(tokens, defaultTheme());
    try snapshots.assertAs(loc, "utility", rule._0 + "\n" + rule._1);
    return;
}
```

The same shape for every track:

| Track | `-test` | Helper | Subject | Body |
|---|---|---|---|---|
| D emilia | `emilia-test` | `assertSheet(loc, tokens)` · `assertUtility(loc, tokens)` | `sheet` · `utility` | the encoded sheet · the class name and the sheet |
| C jhonstart | `jhonstart-test` | `assertHtml(loc, element)` | `html` | `renderToString(element)` |
| B rakun | `rakun-test` | `assertRoute(loc, table)` · `assertResponse(loc, response)` | `route` · `response` | the `kind\|pattern\|slot\|verb` lines (contract 1) · status line + headers + body |
| E onze | `onze-test` | `assertManifest(loc, m)` · `assertPayload(loc, p)` | `manifest` · `payload` | `formatManifest(m)` (contract 6) · the payload JSON (contract 2, `globals.payload`) |
| the compiler, written in botopink | — | `assertJsSingle(loc, source)` | `js` | the JavaScript the source lowers to — the `.bp` twin of `codegen/tests/helpers.zig` `assertJsSingle` |

A helper never calls `readFile`/`writeFile` itself and never computes a path itself. If it needs a
second snapshot per test it calls `assertNamedAs`.

## How the runner discovers the failure

Nothing new. `assertAs` answers `Error(msg)`; the helper propagates it with `try`; the `test` body
propagates it with `try`; the test body is a fallible context (`src-builtin.md`) and the runner
prints

```
FAIL css: modifiers ---- hover on md breakpoint  (snapshots: mismatch src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap - candidate written to src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap.new (first difference at body line 1))  at src/emilia.bp:442
```

and, under `--json`, the same text in `error_message`. `zig build test-libs` sees a red cell. A
reviewer opens the `.new`, diffs it against the `.snap`, and either fixes the code or renames the
file. The `.new` files a red run leaves behind are the review artefact; a green run deletes them.

## Git rules

- `*.snap.new` in the `.gitignore` of every repository that holds a `__snapshots__/` —
  `botopink-lang` (which already ignores `*.snap.md.new`), `rakun`, `jhonstart`, `emilia`, the new
  `onze`, `erika`.
- `__snapshots__/**/*.snap` is **committed**. A snapshot that is not in git is not evidence.
- each repository's `scripts/git-hooks/pre-commit` refuses a staged path matching `*.snap.new`
  (the hook already refuses conflict markers; this is one more pattern) — the belt behind the
  `.gitignore` braces, for the case of `git add -f`.
- a `.snap` is reviewed in the same PR as the test that produced it. A `.snap` changed without a
  test or source change in the same diff is the review signal that a baseline moved.

## Two examples

### 1 · `assertJsSingle(@src(), \\ …)` — a `\\` line-string source, snapshotted as JavaScript

```bp
test "js: task ---- an async fn returns its argument" {
    try assertJsSingle(@src(),
        \\fn fetch(x: i32) -> @Task<i32> {
        \\    return x;
        \\}
    );
}
```

`loc.file` is `test/codegen_test.bp`, say. `path(loc)` =
`test/__snapshots__/js/task_an_async_fn_returns_its_argument.snap`, and the file recorded is — the
body being what the compiler's commonJS backend emits for that source:

```
botopink-snap 1
test: js: task ---- an async fn returns its argument
subject: js

async function fetch(x) {
    return x;
}
```

### 2 · the enum one — `assertSheet(@src(), …)` over emilia tokens

`[.Md([.Hover([.Bg.Red.500])])]` inline does not parse (`language-gaps.md`: a dot-shorthand path
followed by a payload call does not propagate the typed-array context inside an array literal). The
valid spelling binds each level to a typed `val`:

```bp
test "css: modifiers ---- hover on md breakpoint" {
    val leaf: Token[] = [.Bg.Red.500];
    val hovered: Token[] = [Token.Hover(leaf)];
    val tokens: Token[] = [Token.Md(hovered)];
    try assertSheet(@src(), tokens);
}
```

`loc.file` is `src/emilia.bp`. `path(loc)` = `src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap`,
with the header `test: css: modifiers ---- hover on md breakpoint` / `subject: sheet` and, as body,
the encoded sheet `styleRule` answers for the three tokens. The same tokens through `assertUtility`
record `src/__snapshots__/utility/modifiers_hover_on_md_breakpoint.snap`. When emilia changes what a
token list encodes to, that `.snap` mismatches, a `.new` appears, and a person reads it — which is
the mechanism working.

## Inline tests of the engine itself

At the foot of `snapshots.bp`, against a scratch `__snapshots__/` under the host tmpdir so the
package tree is not written to. `test-snap.md` lists them. Two things they must pin beyond the
table above: that a stale `.new` is deleted on a match, and that the header's `test:` line is the
full name with its `----` intact (the slug is for the filename, the header is for the reader).

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A std module cannot call another std module | the private cells duplicate `io/fs.bp`; `dirname` duplicates `path.bp` | re-declare | the cross-module bare-import fix `01-std-lib-enablement` records |
| A function cannot forward a `@Result` | every `assert*` wrapper and every `-test` helper | `try inner(); return;` | pass-through `return` |
| A dot-shorthand payload call inside an array literal does not parse | example 2's token list | typed `val` intermediates (example 2) | let the element type drive resolution through the call |
| Test bodies run in one process per module, in order | two tests writing the same `.new` in the same run cannot both be seen | `assertNamed` | a runner that isolates tests, or a per-test scratch directory |
