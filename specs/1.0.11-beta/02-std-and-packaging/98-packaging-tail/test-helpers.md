# The `-test` helper contract — `01-std/snapshots.md` §§ The API · How a library exposes `assert<Subject>` helpers (1.0.10). Front 98 checks every `<lib>-test` member against it; the helpers themselves are written by each library track.

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

**Host cells — private, Node and Erlang.** `snapshots.bp` re-declares private cells in the
`io/fs.bp` shape and writes `dirname`/`join` inline over `String.split`/`join`; a std module may
import another now, so moving them onto `io/fs` and `path` is open:

| Private cell | Node | Erlang |
|---|---|---|
| `readFile(p) -> @Result<string, string>` | `fs.readFileSync(p, 'utf8')` in an IIFE try/catch | `file:read_file/1` |
| `writeFile(p, text) -> @Result<i32, string>` | `fs.mkdirSync(dirname, {recursive: true}); fs.writeFileSync(p, text)` | `filelib:ensure_dir/1` + `file:write_file/2` |
| `removeFile(p) -> @Result<i32, string>` | `fs.rmSync(p, {force: true})` | `file:delete/1`, `enoent` is `ok` |
| `exists(p) -> bool` | `fs.existsSync(p)` | `file:read_file_info/1` (a path of any kind) |

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

