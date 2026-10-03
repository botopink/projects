# The `-test` helper contract

Front 98 checks every `<lib>-test` member against it; each library track writes its helpers.

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

- Plain entry is `assertText`, not `assert` (reserved keyword statement — hence the sibling module
  `asserts`); it is the `assert<Subject>` spelling for the header's subject.
- Wrappers use `try inner(); return;` like every `-test` helper: `return r` in a `@Result` body
  re-wraps (`language-gaps.md`).
- **Filesystem:** through `io/fs` and `path` (front 97 step 4); scratch dir `bpsnap-<pid>-<n>` under
  `BOTOPINK_TEST_TMPDIR`. `import {testing.snapshots}` refused on wasm (STD-001 through `io/fs`).
- **No panic anywhere:** failure is the answered `@Result`; a host error in a cell is an `Error`
  string, never a throw — so one test can record two snapshots and see both `.new` files in one run.

## How a library exposes `assert<Subject>` helpers

Every `<lib>-test` submodule exposes `assert<Subject>(loc, …) -> @Result<void, string>` helpers, each
a thin wrapper: (a) domain value → string, (b) `snapshots.assertAs(loc, "<subject>", text)`. `loc`
**must be the caller's `@src()`**, taken in the `test` body — a `@src()` inside the helper names the
helper, landing every snapshot in `__snapshots__/<helper's suite>/…`.

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

Same shape per track:

| Track | `-test` | Helper | Subject | Body |
|---|---|---|---|---|
| D emilia | `emilia-test` | `assertSheet(loc, tokens)` · `assertUtility(loc, tokens)` | `sheet` · `utility` | the encoded sheet · the class name and the sheet |
| C jhonstart | `jhonstart-test` | `assertHtml(loc, element)` | `html` | `renderToString(element)` |
| B rakun | `rakun-test` | `assertRoute(loc, table)` · `assertResponse(loc, response)` | `route` · `response` | the `kind\|pattern\|slot\|verb` lines (contract 1) · status line + headers + body |
| E onze | `onze-test` | `assertManifest(loc, m)` · `assertPayload(loc, p)` | `manifest` · `payload` | `formatManifest(m)` (contract 6) · the payload JSON (contract 2, `globals.payload`) |
| the compiler, written in botopink | — | `assertJsSingle(loc, source)` | `js` | the JavaScript the source lowers to — the `.bp` twin of `codegen/tests/helpers.zig` `assertJsSingle` |

Shape only; which helpers each library writes is `snap-a` (4) in
[`../../decisions-pending.md`](../../decisions-pending.md), worked by [`20-snap`](../../20-snap/README.md):
`emilia-test`'s `assertClassName` · `assertCss`, `rakun-test`'s `assertResponse`, jhonstart's and
onze's existing helpers.

A helper never calls `readFile`/`writeFile` nor computes a path; a second snapshot per test →
`assertNamedAs`.
