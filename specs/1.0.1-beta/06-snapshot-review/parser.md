# Parser snapshot review — `modules/compiler-core/snapshots/parser/`

Repo: `/home/ericfillipe/develop/botopink-lang/repository/botopink-lang` (paths below relative to `modules/compiler-core/` unless noted).
Scope: all 213 `snapshots/parser/*.snap.md`, the tests in `src/parser/tests/{declarations,expressions,destructuring,imports,errors,effect_rejections}.zig`, harness `src/parser/tests/helpers.zig`, and `src/parser/exprs.zig` (no inline `test` blocks there — verified by grep).
Method: read-only. Every snapshot was decoded from JSON and read next to its test source (a compacted rendering was used for reading; every finding below was re-checked against the raw JSON). Columns were recomputed by hand for every `loc` in every snapshot.

> **Status (1.0.1-beta close):** closed classes: the **whole location class** (multi-line and `\\` token lines, interpolation hole spans, the tagged-call loc key, and the col-stored-as-byte-offset bug that put every parse error on line 1), the **4 legacy-syntax rows** (spec 05 items 5.12/5.13 - `@[` is now rejected with its own diagnostic and the fixtures use `#[@External.<Target>(...)]` and camelCase), and both vacuous `errors.zig` tests (the helper now fails when no `parseError` is filled). What is left is test-quality. Residuals in [`1.0.4-beta/08-review-backlog/README.md`](../../1.0.4-beta/08-review-backlog/README.md). The tables below are the audit record and are kept verbatim.

## Re-check summary (second pass, at HEAD `96ff203` of `botopink-lang`)

Every non-`ok` row and every cross-cutting note was re-derived from scratch against the current
tree: locations recomputed from the test sources, every cited file:line re-opened, and the parser's
error locations reproduced **empirically** with `zig-out/bin/botopink format --check` / `check` on
throwaway projects in a scratch directory (no build, no test run, nothing inside the repo).

| classification | count | where |
|---|---|---|
| confirmed | 27 | 8 wrong-output, 4 legacy-syntax, 8 wrong-test, 2 weak, 3 duplicate, 2 errors.zig |
| corrected | 7 | 1 wrong-output (root cause), 2 wrong-test (wording), 2 weak (evidence/fix), 1 errors.zig (kind name + scope), 1 uncertain → `ok` |
| withdrawn | 0 | — |
| uncertain | 0 | the single uncertain row resolved to `ok` (see below) |

(34 items in total: 30 non-`ok` snapshot rows + 3 `errors.zig` findings + the 1 uncertain row.)

Notable outcomes:
- The `use`-after-`return` mis-location is **reproducible**: a 4-line project whose `use` sits on
  line 3 renders ` --> src/main.bp:1:5` with the carets under `pp(` of `fn App() {`. The same
  happens for `reservedWord` (`auto` on line 3 → `1:11`) and `novalBinding` (`y: i32 = 4` on line 3
  → `1:3`). The pattern is not a handful of sites: **every** parse error in the parser sets
  `.start = <token>.col - 1` (20 sites).
- The `\\` line-string root cause is no longer uncertain — same end-line bug as `"""`
  (`src/lexer.zig:131-148`).
- The `enum_section_*` uncertainty is resolved: both readers canonicalise the order (bare variants
  first, then section wrappers), so the snapshot is `ok`. A separate, real bug surfaced while
  checking it: `botopink format` **drops enum sections entirely** (see the note under that row).
- Two other incidental (non-snapshot) findings while running the CLI: `botopink format` rewrites
  `pub declare fn f() -> i32;` into `pub fn f() -> i32 {}` (drops `declare`), and
  `parseFormatOpts` (`modules/compiler-cli/src/main.zig:232`) leaks its file list. Out of scope
  here; recorded so they are not lost.

## Verdict counts (213 snapshots)

| verdict | count |
|---|---|
| ok | 183 |
| wrong-output | 9 |
| wrong-test | 10 |
| legacy-syntax | 4 |
| weak | 4 |
| duplicate | 3 |
| uncertain | 0 |
| orphan | 0 |

Plus 3 non-snapshot findings in `errors.zig` (1 wrong-output, 2 wrong-test/vacuous) — see the section on errors.zig tests.

## Findings: snapshots that are not `ok`

JSON `loc` objects are multi-line in the files (`"loc": {` / `"line": N,` / `"col": M` / `}`); they are quoted below joined on one line, with the file line number of the `"line"` key.

### wrong-output

| snapshot | test | verdict | evidence (quoted JSON + source) | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| `string_multiline_interpolation` | expressions.zig:630 | wrong-output · **confirmed** | Source `val s = """` (opens at 1:9), `hello ${name}` on line 2, `""";` on line 3. JSON L15: `"loc": { "line": 3, "col": 9 }` on the `stringTemplate` literal. L29: `"loc": { "line": 1, "col": 1 }` on `"ident": "name"` | Literal should be **1:9**, but the snapshot has 3:9: the line comes from the *closing* line and the column from the opening. The hole `name` should be **2:9**, but it is 1:1. | Lexer: `scanMultilineString` (`src/lexer.zig:372-410`) bumps `self.line` on every embedded newline (`:388`) and only then calls `addToken` (`:380`), which stamps `.line = self.line` (the end line) and `.col = self.start - self.lineStart + 1` (the opening line's column base, `src/lexer.zig:619-626`). Record `startLine` at token start. For holes, see `makeStringExpr` below. |
| `tagged_call_multiline_string` | expressions.zig:650 | wrong-output · **confirmed** | Source `val component = html """` (the string opens at 1:22), `<Button label=${title}></Button>` on line 2. L31: `"loc": { "line": 3, "col": 22 }` (string literal). L45: `"loc": { "line": 1, "col": 1 }` (`"ident": "title"`) | Literal should be **1:22**, but it is 3:22. `title` should be **2:17**, but it is 1:1. The call loc 1:17 is correct. | Same two root causes as above. |
| `line_string_backslash_lines_join_with_newlines` | expressions.zig:690 | wrong-output · **corrected (root cause found)** | Source: `val page =` then `\\` lines on lines 2–4 (col 5), then `;`. L15: `"loc": { "line": 4, "col": 5 }` on `"stringLit": "<div>\n  <p>hello</p>\n</div>"` | Should be **2:5** (first `\\` line), but it is 4:5 (last line). The content is correct. | Root cause confirmed on re-check: the `\\` path (`src/lexer.zig:131-148`) bumps `self.line` for each continued line (`:142`) and calls `addToken(.linesStringLiteral)` (`:148`) afterwards — exactly the same end-line bug as `scanMultilineString`. Record the token's start line there too. |
| `line_string_tagged_call` | expressions.zig:716 | wrong-output · **confirmed** | Source `val page = html` then `\\<div>` (2:5), `\\  <p>${name}</p>` (line 3), `\\</div>`. L31: `"loc": { "line": 4, "col": 5 }` (template literal). L45: `"loc": { "line": 1, "col": 1 }` (`"ident": "name"`) | Literal should be **2:5**, but it is 4:5. `name` should be **3:14**, but it is 1:1. | As above. |
| `string_interpolation_parts` | expressions.zig:612 | wrong-output · **confirmed** | Source `val s = "a ${x} b";`. L29: `"loc": { "line": 1, "col": 1 }` on `"ident": "x"` | `x` is at **1:14**, but the snapshot has 1:1. | `src/parser/exprs.zig:1727-1730` says: *"Hole sources are sub-lexed/sub-parsed in place; their locs are relative to the hole slice (good enough until F6 maps spans into the template)"*. The sub-lex/sub-parse is `makeStringExpr` (`exprs.zig:1750`, holes at `:1788-1795`): a fresh `Lexer`/`Parser` over the hole slice, so every hole loc restarts at 1:1. Offset hole token line/col by the hole's absolute position (`tok.line/col` + offset of `start+2` in content, counting newlines) before sub-parsing — and for `\\` strings also by the prefixes `materializeLineString` (`exprs.zig:1735-1748`) stripped. |
| `string_interpolation_expression_hole` | expressions.zig:618 | wrong-output · **confirmed** | Source `val s = "sum ${1 + 2}!";`. L29 binaryOp `{ "line": 1, "col": 3 }`; L36 `numberLit "1"` `{ "line": 1, "col": 1 }`; L47 `numberLit "2"` `{ "line": 1, "col": 5 }` | Expected `1`@**1:16**, `+`@**1:18**, `2`@**1:20**. Actual: 1:1, 1:3, 1:5 (relative to the hole). | Same as above. |
| `string_interpolation_nested_string_in_hole` | expressions.zig:638 | wrong-output · **confirmed** | Source `val s = "v=${pick("a", key)}";`. L29 call `{ "line": 1, "col": 1 }`; L45 `stringLit "a"` `{ "line": 1, "col": 6 }`; L61 `ident "key"` `{ "line": 1, "col": 11 }` | Expected `pick`@**1:14**, `"a"`@**1:19**, `key`@**1:24**. Actual: 1:1, 1:6, 1:11. | Same as above. |
| `line_string_interpolation_hole` | expressions.zig:704 | wrong-output · **confirmed** | Source line 2 `    \\<p>${name}</p>`. L15 literal `{ "line": 2, "col": 5 }` is correct; L29 `{ "line": 1, "col": 1 }` on `"ident": "name"` | `name` should be **2:12**, but it is 1:1. | Same hole-offset fix. |
| `tagged_call_method_receiver` | expressions.zig:658 | wrong-output (span convention) · **confirmed** | Source `val q = db.sql "SELECT 1";`. L15: call `"loc": { "line": 1, "col": 9 }`; L23: receiver `"loc": { "line": 1, "col": 9 }` `"ident": "db"`; `"callee": "sql"` | For all other method calls, the call loc is the **callee** position: `precos.forEach` → 3:16, `Console.WriteLine` → 5:17, `console.log` → 4:17, `obj.value(1).count()` → 2:18 / 2:27. Here `sql` is at **1:12**, but the call loc points at the receiver (1:9). | The tagged-call sugar (`exprs.zig:1096-1121`) rebuilds the call with `makeCall(tok, …)`, where `tok` is the *head* identifier of the chain, while the ordinary method-call link uses `makeCall(fieldTok, …)` (`exprs.zig:1076-1080`) precisely because "method lowering is loc-keyed". So the tagged call and its receiver node now carry the identical loc 1:9 (both visible in this snapshot, L15 and L23) — a loc-key collision, not just a diagnostic offset. Make the tagged path use the callee token. |

### legacy-syntax

| snapshot | test | verdict | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| `annotation_block_hash_bracket_builtin` | declarations.zig:396 | legacy-syntax · **confirmed** | Source line 2 `  @external(node, "./gleam_stdlib.mjs", "string_length")]`. JSON L25-27: `"name": "external",` / `"args": [` / `"node",` | The lowercase target-first `@external(<target>, …)` vocabulary has been replaced by `@External.Node(...)`. `FnDecl.externalFor` / `InterfaceMethod.externalFor` (`src/ast.zig:1097-1107`, `1794-1804`) only match names starting with `"External."` (and `hasExternal`, `ast.zig:1081`/`1767`, uses the same prefix test), so this annotation is inert — there is no reader for the lowercase form anywhere in the tree. The unit test right below the snapshot tests (`declarations.zig:645`, *"externalFor resolves extended @external vocabulary"*) claims to cover "the back-compat bare form", but it only exercises `@External.*` spellings. The snapshot locks in dead vocabulary. | Rewrite as `@External.Node("./gleam_stdlib.mjs", "string_length")`, or drop it. If back-compat parsing of `@external(node,…)` is still intended, add a test that asserts that explicitly. |
| `interface_with_default_method_and_external_declare_member` | declarations.zig:592 | legacy-syntax · **confirmed** | Source `      @external(node, "./bp_stdlib.mjs", "list_reverse")]`. JSON L119-121: `"name": "external",` / `"args": [` / `"node",` | Same retired `@external(node, …)` form inside an interface method; `InterfaceMethod.externalFor` ignores it. | Use `@External.Node("./bp_stdlib.mjs", "list_reverse")`. |
| `annotation_block_external_decl_then_next_decl` | declarations.zig:404 | legacy-syntax · **confirmed** | Source `pub declare fn absolute_value(n: i32) -> i32;` … `absolute_value(-5);`. JSON L11 `"name": "absolute_value",`, L73 `"callee": "absolute_value",` | snake_case fn name; the language uses camelCase. | Rename to `absoluteValue`. The AST is otherwise correct: `unaryOp neg`@5:20 and literal `5`@5:21 are right. |
| `optional_chaining_method_call` | expressions.zig:681 | legacy-syntax · **confirmed** | Source `val up = s?.to_upper();`. JSON L83 `"callee": "to_upper",` | snake_case method name; the std string method is camelCase (`toUpper`). | Use `s?.toUpper()`. The AST is correct: `optional: true`, callee at 3:17. |

### wrong-test (the test name does not describe its source, or the test comment contradicts the AST)

| snapshot | test | verdict | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| `lambda_plain_positional_call_print_hello` | expressions.zig:41 | wrong-test · **corrected** | Test `"parser: lambda: plain positional call ---- print(\"hello\")"`; source is `print("hello");` inside `val Test = interface { default fn run() { … } }`; the JSON has `"callee": "print"`, one positional arg, and `"trailing": []` (L57 — empty, i.e. no trailing lambda) | The name puts it in the "lambda" group, but there is no lambda in the source. | Rename to `call: plain positional call` or move it to a call group. |
| `lambda_named_argument_call_calcular_fator_2` | expressions.zig:51 | wrong-test · **corrected** | Source `calcular(fator: 2);` (same interface/`default fn` wrapper); JSON has `"label": "fator"` and `"trailing": []` (L57) | Same: no lambda. | Rename to `call: named argument`. |
| `lambda_binary_addition_a_b` | expressions.zig:103 | wrong-test · **confirmed** | Source `a + b;`; JSON is `binaryOp add` | No lambda. It is also redundant with `operator_precedence_*`. | Rename or delete. |
| `pub_fn_type_meta_kind_single_constraint` | declarations.zig:493 | wrong-test · **confirmed** | Name "pub fn ---- type meta-kind single constraint"; source `fn render(comptime tag: type string, props: i32) -> string {`; JSON has no `"isPub": true` (`"isPub": false`) | The name says `pub fn`, but the source is not `pub`. The AST is correct (`typeparam: [named string]`, `modifier: comptime`). | Add `pub` to the source or fix the name. |
| `pub_fn_type_meta_kind_multiple_pipe_constraints` | declarations.zig:501 | wrong-test · **confirmed** | Source `fn coerce(comptime v: type string \| int \| bool, x: i32) -> i32 {`; `"isPub": false` | Same name mismatch. The AST is correct (3 typeparam constraints, in order). | Same. |
| `star_fn_async_declaration` | imports.zig:152 | wrong-test (retired surface in name) · **confirmed** | Name "star fn ---- async declaration"; source `#[@future]\nfn fetch(url: string) -> @Future<Response>`; JSON `"effect": "future"` | `*fn` was hard-removed in v0.beta.19 (see `errors.zig:122`). The source was migrated but the name still describes the retired surface. The file is also wrong (`imports.zig`). | Rename to `effect fn ---- #[@future] declaration` and move it to declarations.zig. |
| `star_fn_generator_declaration` | imports.zig:161 | wrong-test · **confirmed** | Source `#[@iterator] fn fib() -> @Iterator<Int>`; `"effect": "iterator"` | Same. | Same. |
| `star_fn_async_generator_declaration` | imports.zig:170 | wrong-test · **confirmed** | Source `#[@asyncGenerator] pub fn stream() -> @AsyncIterator<Int, Error>`; `"effect": "asyncGenerator"` | Same. | Same. |
| `star_fn_label_after_return_type` | imports.zig:179 | wrong-test · **confirmed** | Source `#[@iterator] fn gen() -> @Iterator<Int> :gen {`; `"label": "gen"` | Same. The AST is correct (`yield :gen 1`, literal at 3:16). | Same. |
| `declare_fn_bodyless_param_with_default_literal_fn_param_default_expansion` | declarations.zig:870 | wrong-test · **confirmed (line fixed)** | The test comment says: *"`declare fn` must accept `param: type = expr` defaults so std/erlang BIFs … collapse N arity overloads … The parser path is shared with `fn`"*. Source `pub declare fn slice(s: string, start: i32, end: i32 = -1) -> string;`. JSON L5 `"delegate": {` … L65 `"returnType": "string"`. The same signature with an annotation (`declare_fn_external_param_default`) yields `"fn": {` with `"isDeclare": true` and a `TypeRef` return type. | An unannotated top-level `declare fn` is parsed as a **DelegateDecl** (a single-method interface alias; `src/parser.zig:274-277` → `parseShorthandDelegateDecl`; an *annotated* `declare fn` takes the `fn` branch at `parser.zig:319-320`), and its `returnType` is a raw string (`ast.zig:1136`). The default does land in `params[2].default` (`unaryOp neg`@1:56, `1`@1:57, both correct), but this is not the `fn` path the comment claims. The BIF form (annotated → `fn`) is covered only by `declare_fn_external_param_default`. | Fix the comment ("bare `declare fn` → delegate type alias"), or change the source so it exercises the `fn` path. |

### weak

| snapshot | test | verdict | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| `declare_fn_multiple_trailing_defaults` | declarations.zig:881 | weak · **confirmed** | Source `pub declare fn open(path: string, mode: string = "r", buffer: i32 = 4096) -> i32;`. JSON L5 `"delegate": {`, L66 `"returnType": "i32"` | This is the same delegate-vs-fn issue: it tests trailing defaults only on the delegate alias node, not on the FFI `fn` form that BIFs use. The locs `"r"`@1:50 and `4096`@1:69 are correct. | Add `#[@External.Erlang(...)]` so the `fn`/`isDeclare` path is covered, or rename it to "delegate". |
| `external_keyword_argument_form` | declarations.zig:615 | weak · **corrected** | Source `#[@External.Erlang( module: "lists", method: "reverse(self)")]`. JSON: `"args": [` `"\"lists\"",` `"\"reverse(self)\""` `]` | The labels `module:`/`method:` are dropped by design (`src/parser.zig:721-735`: "The label is cosmetic at this layer; the value lands positionally"). The AST is therefore what the positional form `#[@External.Erlang("lists", "reverse(self)")]` would produce (no such twin snapshot exists — corrected from the first pass, which implied one), so the snapshot cannot tell whether the keyword form was parsed as keywords. | Add a unit assertion that `externalFor("erlang")` returns `("lists","reverse(self)")` — the `ast: externalFor …` test at `declarations.zig:645` is the natural home — or serialise labels. |
| `external_qualified_enum_variant_annotation_form` | declarations.zig:634 | weak · **corrected** | Source `#[@External.Erlang("lists", "search", inline: true),`; JSON L21 `"true"` (label `inline` dropped) | The feature that distinguishes this test from `external_qualified_enum_target_and_call_template` is the `inline:` flag, but the name does not mention it. Correction to the first pass: the *value* does survive as a third positional arg (`"true"`, L21) — only the `inline:` label is dropped — and `externalFor` strips it via `isBoolFlagArg` (`ast.zig:1259`, used at `1101`/`1798`). So the snapshot does pin the flag's arity effect, just not its meaning. | Rename it to "… with `inline: true` flag". An `hasExternalInline` assertion is not available from here — that helper is private to codegen (`codegen/erlang.zig:1060`, `codegen/beam_asm.zig:637`); assert the trailing `"true"` arg plus `externalFor` ignoring it instead. |
| `interface_with_multiple_abstract_methods_canvas` | declarations.zig:178 | weak · **confirmed** | The source is identical to `interface_with_methods_of_varying_param_counts` (declarations.zig:63) except for `,` separators. The only JSON difference is L16 `"trailingComma": true,` vs `"trailingComma": false,` | The two names ("multiple abstract methods (Canvas)" vs "varying param counts") do not say that the real difference is comma-separated members with a trailing comma. | Rename to `interface members comma-separated with trailing comma`. |

### duplicate

| snapshot | test | verdict | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|---|
| `implement_two_interfaces_with_qualified_method_disambiguation` | declarations.zig:210 | duplicate · **confirmed** | Same shape as `implement_with_two_interfaces_and_qualified_methods` (declarations.zig:165): 2 interfaces, `qualifier` `UsbCharger`/`SolarCharger`, same method name, `self: Self`, a call with `"…" + self.batteryLevel`. The only differences are English vs Portuguese strings and `@print(...)` (builtin) vs `Console.WriteLine(...)` (method call). | Same coverage twice. | Keep one. |
| `record_with_two_fields_and_a_tostring_method` | declarations.zig:188 | duplicate · **confirmed** | Same source as `full_gpscoordinates_record_two_fields_tostring_method` (declarations.zig:126) minus `pub` on the method. The JSON differs only at L171 `"isPub": true` (in the `full_…` snapshot). | Near-duplicate. | Merge them, or rename one to "…method visibility (pub)". |
| `use_multiple_hooks_in_function` | expressions.zig:31 | duplicate · **confirmed** | Its 3 statements are exactly the sources of `use_prefix_with_destructuring_val` (destructuring.zig:15), `use_prefix_in_val_binding` (expressions.zig:23) and `use_void_hook` (expressions.zig:15). The JSON sub-trees are identical except for line numbers. | Its only unique value is "several `use` in static prefix", which is not asserted beyond parsing. | Keep it and delete the three single-hook tests, or vice versa. |

### uncertain → resolved to `ok` on re-check

| snapshot | test | verdict | evidence | resolution |
|---|---|---|---|---|
| `enum_section_single_section_sibling_bare_variant` | declarations.zig:772 | ok · **corrected** (was `uncertain`) | Source: section `Text { Bold, Italic, Underline, }` is declared **before** `Hover(inner: Token),`. JSON L15 `"variants": [` (Hover) is emitted before L32 `"sections": [` (Text). | `EnumDecl` (`ast.zig:1435-1472`) does store `variants` and `sections` in separate slices, but **both** downstream readers canonicalise the same way — `infer.zig:1225-1250` builds `variants ++ section_wrappers`, and `comptime.zig:224-241` (`enrichEnumWithSectionWrappers`) `@memcpy`s the user variants first and the synthesised `Section(_inner: __Enum__Section)` wrappers after. Tag numbering is therefore deterministic and identical on both paths; the interleaved source order is simply not part of the AST contract. Snapshot is `ok`. **Separate bug found while checking this**: `botopink format` on this exact enum emits `val Token = enum { Hover(inner: Token) };` — the whole `Text { … }` section is silently dropped. Formatter, not parser; worth its own issue. |

## Findings: `errors.zig` parse-error tests (no snapshot files; expected text is inline)

| test | verdict | evidence | expected vs actual | suggested fix |
|---|---|---|---|---|
| `parser error: use after return (static prefix violation)` errors.zig:47 | **wrong-output** (the test locks in a bug) · **corrected** (error kind named, scope widened, reproduced) | Source: `fn App() {` / `    return 1;` / `    use state(0);` / `}`. Expected text: ` --> <test>:1:5` / `1 \| fn App() {` / `  \|     ^^^ \`use\` must be in static prefix` | The offending `use` is at **3:5**. The rendered diagnostic says 1:5, echoes line 1 (`fn App() {`), and puts the carets under `pp(`. Root cause: the `.useAfterBranch` error at `src/parser.zig:510-519` sets `.start = tok.col - 1` (a column), and `src/print.zig:155` `findLocation(source, info.start)` (`print.zig:231-252`) treats `start` as a **byte offset**, so every error whose column is smaller than the line's start offset lands on line 1. **Reproduced at HEAD** with `botopink format --check` on a scratch project: the 4-line source above prints ` --> src/main.bp:1:5` with `^^^` under `pp(` of `fn App() {`. Two more, same way: `auto` as a value on line 3 → `1:11`; `y: i32 = 4` on line 3 → `1:3`. Scope correction: this is not a handful of sites — **every** `ParseErrorInfo` built in the parser uses `.start = <token>.col - 1` (20 sites: parser.zig 513/907/999; decls.zig 84/172/337/409/443/659/1124/1393; exprs.zig 72/253/752/1034/1520/1757; types.zig 31/135/170/218/268). Errors raised from `consume()` are unaffected only because they carry no `parseError` at all. The other `expectParseError` tests all use 1-line sources, so the bug is masked there. | Use the token's byte offset for `start`/`end` (or have `render` use `info.line/info.col`, which every site already fills in), then fix the expected text to `3:5` / `3 \|     use state(0);`. Add a multi-line test for at least one other kind. |
| `parser error: assignment without val` errors.zig:66 | **wrong-test (vacuous)** · **confirmed** | Expected text begins `error comptime: syntax error`; source `wibble = 4` | At top level, `wibble` falls into the `else` branch of `Parser.parse` (`src/parser.zig:333-346`). That branch sets `parseError` only for anonymous implement/extend or reserved words, so it returns `UnexpectedToken` with `parseError == null`. `helpers.expectParseError` then hits `const pe = p.parseError orelse return;` (helpers.zig:109) and passes without comparing anything. Reproduced at HEAD: `botopink format --check` on `wibble = 4` prints only the `parser: UnexpectedToken at token[0] = identifier 'wibble'` debug line (parser.zig:345) and no rendered diagnostic — i.e. `parseError == null`. The expected header `error comptime: syntax error` is the `printListSpreadError` stderr format (parser.zig:1215-1224). `print.render` never emits it, so the test would *fail* if the comparison ever ran. `novalBinding` is only raised for `ident :` inside `parseExpr` (exprs.zig:71). | Make `expectParseError` fail when `parseError` is null. Then either emit `novalBinding` for top-level `ident =`, or change the source and expected text to the real format (`error: There must be a 'val' or 'var'…`). |
| `parser error: reserved word in expression` errors.zig:94 | **wrong-test (vacuous + contradictory)** · **confirmed** | Source `"echo"`; the expected text claims reservedWord | `echo` is not a reserved word: `lexer.isReservedWord` (lexer.zig:719-731) lists auto/delegate/else/implement/macro/test/derive, and there is no `echo` token. `expressions.zig:730` ("echo is a plain identifier (keyword removed)") explicitly asserts that. Parsing fails with `parseError == null`, so the test passes vacuously through the same early return (reproduced: `format --check` on `echo` prints only the UnexpectedToken debug line). It is also a top-level position, not "in expression". | Use a real reserved word inside an expression (e.g. `fn f() { val x = auto; }`), and harden `expectParseError` as above. |
| `parser: anonymous implement rejected` :15, `anonymous extend rejected` :31, `reserved word at top-level` :80, `removed error union syntax T!E` :108 (col 16 checked), `deprecated *fn prefix` :122 | ok | The locations match the source (all on line 1). | — | — |

`effect_rejections.zig` checks error `kind` only (no text/location); its kinds match the test names. Out of snapshot scope; no issues seen.

## Mapping / orphans

**Method** (script `scratchpad/run-parser/map.py`, output `tests.json`):
1. `helpers.assertParser` derives the snapshot name from `@src().fn_name`: strip `test.`, keep the text after the first `": "`, then `slugify` (lowercase ASCII alphanumerics; each run of other characters becomes a single `_`; leading and trailing separators dropped). The file is `snapshots/parser/<slug>.snap.md`. The serialised value is the whole `Program` via `pretty.formatAlloc` → JSON. `Annotation.loc` is deliberately excluded (`ast.zig:1161`).
2. I parsed every `test "…" {` block in `src/parser/tests/*.zig` and `src/parser/exprs.zig`, counted `assertParser` calls per block, and re-implemented `slugify` in Python exactly as in `helpers.zig:15-59`.
3. I compared the resulting slug set with `ls snapshots/parser/*.snap.md` and checked that each test has at most one call and that no two slugs collide.

**Results** (re-counted at HEAD with a fresh script — every number below reproduced: 268 blocks = declarations 99, expressions 84, destructuring 17, imports 30, errors 22, effect_rejections 16; 213 `assertParser` = declarations 84, expressions 84, destructuring 17, imports 28; 213 snapshot files on disk)
- 268 test blocks in total; 213 call `assertParser` (exactly one call each); 55 are non-snapshot tests (unit tests, `expectParseError`, `expectParseFails`, `effect_rejections`).
- 213 snapshot files, **0 orphan snapshots**, **0 tests expecting a missing snapshot**, 0 slug collisions, 0 tests with multiple `assertParser` calls.
- `src/parser/exprs.zig` has no `test` blocks (the only "snapshot" hit is a comment at line 413).
- `src/parser/tests.zig` registers all six test files. All 213 snapshots are tracked by git and clean (`git status` shows nothing).
- Snapshot ↔ test file distribution: declarations.zig 84, expressions.zig 84, destructuring.zig 17, imports.zig 28 (incl. 4 delegate + 4 effect-fn tests that belong elsewhere).

**Byte-identical snapshot pairs (all intentional equivalence checks; ok)**
- `empty_program` ≡ `whitespace_only_source` (`{"decls": []}`)
- `interface_extends_val_form_single` ≡ `interface_extends_shorthand_single`
- `interface_extends_val_form_multiple` ≡ `interface_extends_shorthand_multiple`
- `interface_extends_pub_val_form_multiple` ≡ `interface_extends_pub_shorthand_multiple`
- `delegate_val_form_simple` ≡ `delegate_shorthand_simple`

Note: `RecordDecl`, `InterfaceDecl` and `DelegateDecl` carry no `shorthand` flag (only `implement`/`extend` do). So these snapshots show the two forms converge, but they cannot detect a form being mis-parsed into a different, equally valid node of the same kind.

## Cross-cutting observations (not counted as per-snapshot verdicts)

All seven re-checked at HEAD; classifications in bold.

1. **Comment attachment is never tested.** · **confirmed** (re-verified mechanically: no `//`, `///` or `////` in any `assertParser` source; across the 213 files, 231 `"comment": null`, 231 `"docComment": null`, 231 `"moduleComment": null`, and every one of the 185 `emptyLinesBefore` fields is `0`.) Attachment of these to the right node has no coverage, even though `parseBlock` has `handleComments = true` (`parser.zig:482`, set at `:543`/`:577`).
2. **Id uniqueness is never tested.** · **confirmed** `nextId` is a per-kind counter (`parser.zig:199-204`). Re-checked by decoding all 213 snapshots: 57 `"id"` fields, all `1`, and **no** snapshot contains two id-carrying nodes of the same kind — so increment and uniqueness are untested. `implement`/`extend`/`fn`/`val` nodes have no `id`.
3. **The retired `@[name]` top-level annotation opener is still accepted** · **confirmed (line corrected)** by `Parser.parse` (`src/parser.zig:305-306`: `this.check(.hash) or (this.check(.at) and this.peekAt(1).kind == .leftSquareBracket)`), and the code comment at parser.zig:319 still shows `@[external(…)]`. Reproduced: `@[external(node, "x", "y")] pub declare fn f() -> i32;` parses, and `botopink format` rewrites it to `#[@external(node, "x", "y")]`. No test asserts that it is rejected.
4. **Lexer column drift after multi-line tokens.** · **confirmed** `scanMultilineString` bumps `line` but never `lineStart` (only the `'\n'` arm of `scanToken`, `lexer.zig:95-98`, moves `lineStart`; the `\\` path documents the same choice at `lexer.zig:129-130`), so tokens that follow on the closing line get columns measured from the *opening* line's base. Measured: in `val s = """\nhi\n"""; val t = 1;` the `=` on line 3 carries `col = 25`, i.e. its byte offset + 1. Not visible in the AST snapshots, but it feeds diagnostics — and it is why a `consume()`-path error after a `"""` still renders on the right line (col-1 happens to equal the byte offset there).
5. **Lossy representations locked in by design (documented in code, left as ok):** · **confirmed** (each spot-checked in `ast.zig` / `decls.zig` at HEAD)
   - `true`/`false` are `identifier` nodes. The AST has no bool literal (`ast.zig` literal kinds: `stringLit`/`numberLit`/`null_`).
   - Interface fields store only a `typeName` lexeme (`ast.InterfaceField`, `ast.zig:942`/`959`/`1022`), not a `TypeRef`.
   - `syntax fn(...)` params use `typeRef: {"named": "fn"}` plus legacy `fnType` strings (`decls.zig:1348-1381` comment).
   - Annotation args are raw lexemes (`"\"lists\""`) with labels dropped (`parser.zig:721-735`); `Annotation.loc` is deliberately not serialised (`ast.zig:1155-1161`).
   - `DelegateDecl.returnType` is a raw string (`ast.zig:1136`: `returnType: ?[]const u8`).
   - `try X catch H` and `X catch H` produce the same `tryCatch` node (only `loc` differs: `try` vs `catch` keyword).
   - `stringLit` keeps raw escapes (`"price \\${USD}"`), matching the comment "escape sequences resolve in the target".
   - `"""` template text keeps the leading and trailing `\n` (`"\nhello "`, `"\n"`). Whether the first newline should be stripped is a language-semantics question, not verified here.
6. **Non-canonical type names in sources** (`int`, `float`, `Int`, `Bool`, `String`, `number`) are harmless to the parser, but they are not the i32/f64/string/bool primitives the rest of the toolchain uses. · **confirmed** (e.g. `number` in declarations.zig:103/112/118, `Int` in imports.zig:164/173/182).
7. **Misfiled tests:** `shorthand_*` and `use_prefix_with_destructuring_val` are in destructuring.zig; delegate and effect-fn tests are in imports.zig. · **confirmed** (destructuring.zig:15-67; imports.zig:128-185).

## Location checks performed

Every `loc` in all 213 snapshots was recomputed column by column from the test source. Conventions confirmed as consistent (outside the wrong-output rows above):
- binaryOp → operator column
- call → callee column (including builtins `@name`)
- identAccess → member column; dotIdent → the leading `.`
- binding / jump / assert → keyword or first-token column
- `val assert` → the `assert` keyword
- tryCatch → `try` if present, else `catch`
- collection → `[` / `#` / `case` / `record` keyword
- interfaceLit → `@Decl`
- useHook → `use`
- test → `test` keyword

Precedence and associativity were checked in `operator_precedence_*`, the GPS `+` chains, `assert_*`, `call_as_binary_operand`, `method_chain_as_binary_operand`, and `test_anonymous`: `* / %` bind tighter than `+ -`, which bind tighter than `< > <= >=`, which bind tighter than `== !=`; all are left-associative.

## `ok` snapshots (183 — `enum_section_single_section_sibling_bare_variant` added on re-check)

- `empty_program` — parser/tests/declarations.zig:15
- `whitespace_only_source` — parser/tests/declarations.zig:19
- `empty_interface` — parser/tests/declarations.zig:23
- `interface_with_one_field` — parser/tests/declarations.zig:51
- `abstract_method_with_1_param_self_self` — parser/tests/declarations.zig:55
- `abstract_method_with_multiple_params` — parser/tests/declarations.zig:59
- `interface_with_methods_of_varying_param_counts` — parser/tests/declarations.zig:63
- `full_drawable_interface_field_abstract_default_method` — parser/tests/declarations.zig:73
- `implement_generic_interface_for_type` — parser/tests/declarations.zig:85
- `enum_with_inline_implement` — parser/tests/declarations.zig:95
- `record_with_inline_implement` — parser/tests/declarations.zig:101
- `empty_record_no_fields_no_methods` — parser/tests/declarations.zig:107
- `record_with_two_fields_and_no_methods` — parser/tests/declarations.zig:111
- `record_with_one_method` — parser/tests/declarations.zig:115
- `full_gpscoordinates_record_two_fields_tostring_method` — parser/tests/declarations.zig:126
- `record_with_declare_fn_abstract_method_declaration` — parser/tests/declarations.zig:138
- `enum_with_declare_fn_abstract_method_declaration` — parser/tests/declarations.zig:147
- `implement_with_one_interface_and_one_unqualified_method` — parser/tests/declarations.zig:157
- `implement_with_two_interfaces_and_qualified_methods` — parser/tests/declarations.zig:165
- `implement_single_interface_with_method_body` — parser/tests/declarations.zig:200
- `implement_shorthand_named` — parser/tests/declarations.zig:223
- `implement_shorthand_named_pub` — parser/tests/declarations.zig:231
- `extend_shorthand_named` — parser/tests/declarations.zig:239
- `extend_explicit_named` — parser/tests/declarations.zig:247
- `enum_simple_unit_variants` — parser/tests/declarations.zig:285
- `enum_with_payload_variant` — parser/tests/declarations.zig:296
- `interface_extends_val_form_single` — parser/tests/declarations.zig:307
- `interface_extends_val_form_multiple` — parser/tests/declarations.zig:313
- `interface_extends_pub_val_form_multiple` — parser/tests/declarations.zig:319
- `interface_extends_shorthand_single` — parser/tests/declarations.zig:325
- `interface_extends_shorthand_multiple` — parser/tests/declarations.zig:331
- `interface_extends_pub_shorthand_multiple` — parser/tests/declarations.zig:337
- `annotation_fn_no_args` — parser/tests/declarations.zig:343
- `annotation_fn_with_dot_ident_arg` — parser/tests/declarations.zig:350
- `annotation_fn_multiple_annotations` — parser/tests/declarations.zig:357
- `annotation_val_form_fn` — parser/tests/declarations.zig:365
- `annotation_record_shorthand` — parser/tests/declarations.zig:371
- `annotation_enum_shorthand` — parser/tests/declarations.zig:378
- `annotation_interface_shorthand` — parser/tests/declarations.zig:389
- `val_local_binding_with_case_expression` — parser/tests/declarations.zig:415
- `val_top_level_constant_integer` — parser/tests/declarations.zig:427
- `val_top_level_constant_comptime_float_mul` — parser/tests/declarations.zig:433
- `val_top_level_constant_comptime_string_concat` — parser/tests/declarations.zig:439
- `val_top_level_constant_comptime_block` — parser/tests/declarations.zig:445
- `pub_fn_comptime_params` — parser/tests/declarations.zig:453
- `pub_fn_syntax_bool_param` — parser/tests/declarations.zig:461
- `pub_fn_syntax_fn_type_param_returning_generic` — parser/tests/declarations.zig:469
- `pub_fn_syntax_fn_type_param_returning_bool` — parser/tests/declarations.zig:477
- `pub_fn_type_meta_kind_no_constraint` — parser/tests/declarations.zig:485
- `val_top_level_call_expression` — parser/tests/declarations.zig:509
- `empty_array_literal` — parser/tests/declarations.zig:516
- `val_with_array_type_annotation` — parser/tests/declarations.zig:522
- `val_with_tuple_type_annotation` — parser/tests/declarations.zig:528
- `test_anonymous` — parser/tests/declarations.zig:534
- `test_named` — parser/tests/declarations.zig:542
- `test_named_with_message_assert` — parser/tests/declarations.zig:551
- `expr_builtin_type_param_and_bounded_return` — parser/tests/declarations.zig:568
- `expr_builtin_type_generic_return` — parser/tests/declarations.zig:576
- `expr_builtin_type_composed_type_position` — parser/tests/declarations.zig:584
- `external_qualified_enum_target_and_call_template` — parser/tests/declarations.zig:607
- `external_node_prototype_shorthand_module_omitted` — parser/tests/declarations.zig:622
- `fn_decl_param_with_default_literal` — parser/tests/declarations.zig:721
- `fn_decl_param_with_default_int` — parser/tests/declarations.zig:729
- `fn_decl_multiple_trailing_defaults` — parser/tests/declarations.zig:737
- `record_field_default_mirrors_fn_param_default` — parser/tests/declarations.zig:745
- `enum_variant_field_default` — parser/tests/declarations.zig:751
- `fn_decl_param_default_external_target_annotation` — parser/tests/declarations.zig:760
- `enum_section_single_section_sibling_bare_variant` — parser/tests/declarations.zig:772
- `enum_section_nested_sections_numeric_leaves` — parser/tests/declarations.zig:785
- `enum_section_path_access_dot_chain_color_red_500` — parser/tests/declarations.zig:830
- `declare_fn_external_param_default` — parser/tests/declarations.zig:887
- `type_guard_snapshot_round_trip` — parser/tests/declarations.zig:915
- `use_prefix_with_destructuring_val` — parser/tests/destructuring.zig:15
- `shorthand_enum_simple` — parser/tests/destructuring.zig:23
- `shorthand_enum_pub_with_generics_and_payload` — parser/tests/destructuring.zig:32
- `shorthand_record_simple` — parser/tests/destructuring.zig:41
- `shorthand_record_pub_with_generics` — parser/tests/destructuring.zig:47
- `shorthand_interface_simple` — parser/tests/destructuring.zig:53
- `shorthand_interface_pub_with_generics` — parser/tests/destructuring.zig:61
- `destructure_record_val_binding` — parser/tests/destructuring.zig:69
- `destructure_record_parameter` — parser/tests/destructuring.zig:78
- `destructure_mixed_params` — parser/tests/destructuring.zig:86
- `val_tuple_destructuring` — parser/tests/destructuring.zig:94
- `var_tuple_destructuring` — parser/tests/destructuring.zig:102
- `tuple_destructuring_as_function_parameter` — parser/tests/destructuring.zig:111
- `try_catch_with_tuple_destructure` — parser/tests/destructuring.zig:119
- `assign_simple_number_literal` — parser/tests/destructuring.zig:127
- `assign_expression` — parser/tests/destructuring.zig:136
- `assign_string_value` — parser/tests/destructuring.zig:145
- `use_void_hook` — parser/tests/expressions.zig:15
- `use_prefix_in_val_binding` — parser/tests/expressions.zig:23
- `lambda_trailing_lambda_with_no_params_executar_ok` — parser/tests/expressions.zig:61
- `lambda_named_arg_trailing_lambda_with_two_params_and_addition` — parser/tests/expressions.zig:71
- `lambda_two_trailing_lambdas_second_labeled_executar_erro` — parser/tests/expressions.zig:83
- `lambda_method_call_with_two_param_trailing_lambda_precos_foreach_fruta_valor_fruta` — parser/tests/expressions.zig:93
- `case_wildcard_and_ident_patterns` — parser/tests/expressions.zig:113
- `case_variant_with_field_bindings` — parser/tests/expressions.zig:126
- `case_list_patterns` — parser/tests/expressions.zig:139
- `case_or_patterns` — parser/tests/expressions.zig:154
- `case_guard_clauses` — parser/tests/expressions.zig:167
- `operator_precedence_mul_binds_tighter_than_add` — parser/tests/expressions.zig:181
- `operator_precedence_left_to_right_associativity_for_add` — parser/tests/expressions.zig:191
- `operator_precedence_add_binds_tighter_than_compare` — parser/tests/expressions.zig:201
- `operator_precedence_compare_binds_tighter_than_eq` — parser/tests/expressions.zig:211
- `operator_precedence_all_arithmetic_operators` — parser/tests/expressions.zig:221
- `operator_precedence_comparison_operators` — parser/tests/expressions.zig:231
- `operator_precedence_equality_operators` — parser/tests/expressions.zig:244
- `builtin_zero_arg_call` — parser/tests/expressions.zig:255
- `builtin_single_arg_call` — parser/tests/expressions.zig:265
- `builtin_multi_arg_call` — parser/tests/expressions.zig:277
- `builtin_in_expression_context` — parser/tests/expressions.zig:289
- `builtin_as_val_initializer` — parser/tests/expressions.zig:297
- `array_literal` — parser/tests/expressions.zig:305
- `tuple_literal` — parser/tests/expressions.zig:311
- `nested_array_type` — parser/tests/expressions.zig:317
- `array_prepend_with_empty_array` — parser/tests/expressions.zig:323
- `array_prepend_with_single_element_array` — parser/tests/expressions.zig:329
- `array_prepend_with_multiple_elements_array` — parser/tests/expressions.zig:335
- `array_prepend_with_identifier` — parser/tests/expressions.zig:341
- `try_expression` — parser/tests/expressions.zig:348
- `try_catch_expression` — parser/tests/expressions.zig:356
- `catch_as_tail_operator_without_try` — parser/tests/expressions.zig:364
- `catch_as_tail_operator_with_return` — parser/tests/expressions.zig:372
- `if_with_null_check_binding` — parser/tests/expressions.zig:380
- `assert_simple_assertion` — parser/tests/expressions.zig:391
- `assert_with_equality_comparison` — parser/tests/expressions.zig:399
- `assert_with_addition` — parser/tests/expressions.zig:407
- `assert_with_message` — parser/tests/expressions.zig:415
- `assert_array_equality` — parser/tests/expressions.zig:423
- `assert_arithmetic_comparison` — parser/tests/expressions.zig:431
- `assert_pattern_with_catch_throw` — parser/tests/expressions.zig:439
- `assert_pattern_with_catch_default_value` — parser/tests/expressions.zig:447
- `assert_pattern_with_list_pattern` — parser/tests/expressions.zig:455
- `assert_pattern_with_wildcard_pattern` — parser/tests/expressions.zig:463
- `assert_pattern_with_string_literal` — parser/tests/expressions.zig:471
- `assert_pattern_with_number_literal` — parser/tests/expressions.zig:479
- `assert_pattern_with_enum_variant` — parser/tests/expressions.zig:487
- `assert_pattern_with_multiple_bindings` — parser/tests/expressions.zig:495
- `assert_pattern_with_nested_pattern` — parser/tests/expressions.zig:503
- `assert_pattern_with_empty_list` — parser/tests/expressions.zig:511
- `assert_pattern_with_multiple_element_list` — parser/tests/expressions.zig:519
- `assert_pattern_with_list_and_rest` — parser/tests/expressions.zig:527
- `await_prefix_expression` — parser/tests/expressions.zig:535
- `await_chained_with_try` — parser/tests/expressions.zig:545
- `loop_await_async_iteration` — parser/tests/expressions.zig:555
- `loop_with_label` — parser/tests/expressions.zig:566
- `yield_without_label` — parser/tests/expressions.zig:576
- `call_as_binary_operand` — parser/tests/expressions.zig:586
- `method_chain_as_binary_operand` — parser/tests/expressions.zig:595
- `assert_on_call_equality` — parser/tests/expressions.zig:603
- `string_interpolation_escaped_dollar_stays_literal` — parser/tests/expressions.zig:624
- `tagged_call_single_line_string` — parser/tests/expressions.zig:644
- `expr_stays_a_plain_identifier_in_expressions` — parser/tests/expressions.zig:664
- `optional_chaining_member_access` — parser/tests/expressions.zig:671
- `echo_is_a_plain_identifier_keyword_removed` — parser/tests/expressions.zig:730
- `interface_literal_basic` — parser/tests/expressions.zig:739
- `interface_literal_multiple_fields` — parser/tests/expressions.zig:745
- `interface_literal_with_array_field` — parser/tests/expressions.zig:751
- `interface_literal_with_nested_record` — parser/tests/expressions.zig:757
- `import_from_root` — parser/tests/imports.zig:15
- `import_from_module` — parser/tests/imports.zig:19
- `import_empty` — parser/tests/imports.zig:23
- `import_multiple_names` — parser/tests/imports.zig:27
- `import_trailing_comma` — parser/tests/imports.zig:31
- `import_dotted_path` — parser/tests/imports.zig:35
- `import_activate_suffix` — parser/tests/imports.zig:39
- `import_dotted_activate` — parser/tests/imports.zig:43
- `import_activate_with_alias` — parser/tests/imports.zig:47
- `import_mixed_plain_and_activate` — parser/tests/imports.zig:51
- `activate_statement` — parser/tests/imports.zig:55
- `activate_dotted_statement` — parser/tests/imports.zig:59
- `multiple_import_declarations` — parser/tests/imports.zig:63
- `mod_decl_private` — parser/tests/imports.zig:73
- `pub_mod_decl` — parser/tests/imports.zig:77
- `multiple_mod_decls` — parser/tests/imports.zig:81
- `mod_alongside_imports` — parser/tests/imports.zig:89
- `pub_default_mod_decl` — parser/tests/imports.zig:103
- `default_mod_decl_private` — parser/tests/imports.zig:107
- `pub_default_mod_parses_at_any_module_top_level` — parser/tests/imports.zig:111
- `delegate_val_form_simple` — parser/tests/imports.zig:128
- `delegate_val_form_with_return_type` — parser/tests/imports.zig:134
- `delegate_shorthand_simple` — parser/tests/imports.zig:140
- `delegate_shorthand_pub_with_return_type` — parser/tests/imports.zig:146
