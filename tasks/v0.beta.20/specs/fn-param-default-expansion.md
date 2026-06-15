# fn-param-default-expansion — unify call-site default injection across calls / annotations / record + enum constructors

**Slug**: fn-param-default-expansion
**Depends on**: `prim-op-annotation` commit `4c2e62c` (the unified
`Param.default: ?Expr` + `EnumVariantField.default: ?Expr` AST slot,
parsed by `parser/decls.parseParam` + `parseEnumBody`); commit `5f0f1d9`
(the partial `expandTrailingDefaults` helper in `comptime/transform.zig`
+ the `CallArg.is_default_inj` flag in `ast.zig`).
**Files**:
- `modules/compiler-core/src/comptime.zig` (extend `registerStdlib` so
  `prelude.builtins` enters the parse path without tripping inference on
  the pre-defined `Result<R, E>` / `Future<T, E>` / `Iterator<T>` /
  `Generator<T, R>` / `AsyncIterator<T, E>` / `Context<B, R>` interfaces).
- `modules/compiler-core/src/comptime/transform.zig` (extend
  `expandTrailingDefaults` to handle: receiver method calls; trailing
  lambdas + positional args mix; named-arg label `name: value` with
  defaults sitting before / between supplied args).
- `modules/compiler-core/src/comptime/infer.zig`
  (`recordFieldsAsParams` / `structFieldsAsParams` /
  `enumVariantAsParams` already pass `f.default` through unchanged after
  `4c2e62c`; this spec wires the **arity check + injection** at the
  record / enum constructor call site, mirroring `expandTrailingDefaults`
  for fn calls).
- `modules/compiler-core/src/codegen/{erlang,beam_asm,commonJS,wat}.zig`
  (collapse the two-branch `argc==0`/`argc==1` inline seeds for `todo` /
  `panic` to one branch; remove the `when(argc == N)` clause from
  `Array.slice` + `String.slice` in `libs/std/src/primitives.d.bp` once
  the inference path can inject `end: i32 = self.length()` defaults).
- `libs/std/src/builtins.d.bp` + `libs/std/src/primitives.d.bp` (the
  surface migrations once the compiler path is ready).
- `modules/compiler-core/src/parser/tests/declarations.zig` +
  `modules/compiler-core/src/codegen/tests/*` (per-surface regression
  tests; see §"Tests" below).
- `tests/codegen/fn_param_defaults.zig` (new — gate every default-
  injection shape against a snapshot bank).
**Touches docs**: `modules/compiler-core/AGENTS.md` (`parser/` +
  `comptime/` subsections) · `libs/std/AGENTS.md` (§"Default values in
  fn-decl param lists") · `CHANGELOG.md` (one line under v0.beta.20).
**Status**: pending

## Background

`prim-op-annotation` (v0.beta.19) needed `Param.default: ?Expr` so the
documented `fn todo(message: string = "not implemented") noreturn`
annotation surface in `libs/std/src/builtins.d.bp` could be a single
1-arity template under `@External.<Target>(...)`. The AST + parser
landed (commit `4c2e62c`), the call-site injection helper
`expandTrailingDefaults` landed too (commit `5f0f1d9`), but **two**
follow-up gaps blocked the full surface from landing:

1. `libs/std/src/builtins.d.bp` is **not** in the `registerStdlib` parse
   path — adding `prelude.builtins` to it trips inference on the
   pre-defined `Result<R, E>` / `Future<T, E>` / `Iterator<T>` /
   `Generator<T, R>` / `AsyncIterator<T, E>` / `Context<B, R>` interfaces
   the compiler synthesises before the user program is parsed. So
   `todo` / `panic` have no `FnDecl` entry in the `fn_decls` map
   `expandTrailingDefaults` consults; the inline-seeded dispatch in
   `erlang.zig` / `commonJS.zig` is forced to keep its two-branch
   (`argc==0` / `argc==1`) form, with `when(argc == N)` semantics
   reproduced in-Zig rather than in the `.bp` surface.

2. `Array.slice(self, start, end)` + `String.slice(self, start, end)` in
   `libs/std/src/primitives.d.bp` want `end: i32 = self.length()` as the
   default — a **non-literal** default (a method call on `self`). The
   `expandTrailingDefaults` helper today copies a *reference* to the
   `FnDecl.params[i].default` Expr; that Expr is owned by the decl's
   arena, and the method-receiver self is unbound at the call site. So
   the slice migrations away from `when(argc == N)` (the only surviving
   uses in the codebase) cannot land until the receiver-bound default
   path is wired.

This spec closes both gaps and ships the surface migrations they unblock.

## Premise

A `default` value on a param is the **same fact** whether it lives on a
fn call, an annotation, a record constructor, or an enum variant
constructor — à la Kotlin's named-arg + default rules. The only thing
that changes across surfaces is the brace / paren framing and the named-
arg sigil (`label: value` in bp). The compiler honours that uniformity:
one AST slot, one injection helper, one set of diagnostics.

The injection happens **before dispatch**, so the codegen sees a fully-
specified arg list and renders the same template every time. No backend
needs an `argc`-branch arm; no `when(argc == N)` syntax survives in the
surface.

## Target surface

### 1 — fn-decl call with trailing literal default (`todo`)

**Before** (built-ins surface, the doc-only file
`libs/std/src/builtins.d.bp`):

```bp
#[External.Erlang("erlang:error({todo, $0})"),
  External.Node("(() => { throw new Error($0) })()")]
fn todo(message: string = "not implemented") noreturn

#[External.Erlang("erlang:error({panic, $0})"),
  External.Node("(() => { throw new Error($0) })()")]
fn panic(message: string = "panic") noreturn
```

**Before** (codegen inline-seeded dispatch, two-branch shape currently
held in `erlang.zig` + `commonJS.zig`):

```zig
try this.putInlineErlangBuiltin("todo", &.{
    .{ .argc = 0, .template = "erlang:error({todo, \"not implemented\"})" },
    .{ .argc = 1, .template = "erlang:error({todo, $0})" },
});
```

**After** (codegen one-branch shape — the default flows from
`prelude.builtins`'s `FnDecl.params[0].default` into the call's args at
`expandTrailingDefaults` time):

```zig
try this.putInlineErlangBuiltin("todo", &.{
    .{ .argc = 1, .template = "erlang:error({todo, $0})" },
});
```

**Caller surface** — unchanged. `todo()` / `todo("not yet")` / `panic()`
/ `panic("boom")` all parse, type-check, and lower correctly through the
single 1-arity template.

### 2 — fn-decl call with receiver-bound default (`slice`)

**Before** (`primitives.d.bp`, the only surviving `when(argc == N)`
clauses in the codebase):

```bp
#[@External.Erlang(
    when(argc == 1): "string:slice($self, $0)",
    when(argc == 2): "string:slice($self, $0, (($1) - ($0)))"),
  @External.Node("./gleam_stdlib.mjs", "string_slice")]
fn slice(self: Self, start: i32, end: i32) -> string
```

**After**:

```bp
#[@External.Erlang("string:slice($self, $0, (($1) - ($0)))"),
  @External.Node("./gleam_stdlib.mjs", "string_slice")]
fn slice(self: Self, start: i32, end: i32 = self.length()) -> string
```

**Caller surface** — `s.slice(2)` and `s.slice(2, 5)` both parse; the
1-arg call expands to `s.slice(2, s.length())` at inference time and
renders through the single template.

### 3 — record constructor with default field

```bp
record Config(
    host: string = "localhost",
    port: i32 = 8080,
    tls: bool = false,
)

val cfg1 = Config()                          // → Config("localhost", 8080, false)
val cfg2 = Config(host: "example.com")       // → Config("example.com", 8080, false)
val cfg3 = Config(port: 9000, tls: true)     // → Config("localhost", 9000, true)
```

### 4 — enum variant constructor with default field

```bp
enum Level {
    Info(message: string = "info"),
    Warn(message: string = "warning"),
    Error(message: string, code: i32 = -1),
}

val a = Level.Info()                  // → Level.Info("info")
val b = Level.Warn()                  // → Level.Warn("warning")
val c = Level.Error("boom")           // → Level.Error("boom", -1)
val d = Level.Error("boom", code: 42) // → Level.Error("boom", 42)
```

### 5 — annotation with default field (Kotlin parity)

```bp
struct ServiceOpts(
    name: string,
    replicas: i32 = 1,
    public: bool = false,
)

#[ServiceOpts(name: "api")]              // replicas=1, public=false
record ApiService(...)

#[ServiceOpts(name: "auth", replicas: 3)] // public=false
record AuthService(...)
```

This is the rule the `infer.zig` decorator validator already approximates
(via `recordFieldsAsParams` / `structFieldsAsParams`) — this spec wires
the *injection* of the missing trailing fields, not just the arity
check.

### 6 — named args + defaults (skip-middle is the error)

Kotlin-style: trailing defaults are auto-injected; **middle** defaults
require the call to either supply that arg positionally or use the
named-arg label for the trailing arg(s).

```bp
fn connect(host: string, port: i32 = 80, timeout: i32 = 30) -> bool { ... }

connect("example.com")                       // ok → connect("example.com", 80, 30)
connect("example.com", 8080)                 // ok → connect("example.com", 8080, 30)
connect("example.com", timeout: 60)          // ok → connect("example.com", 80, 60)
connect("example.com", 8080, 60)             // ok
connect("example.com", port: 8080, timeout: 60) // ok
```

The rule mirrors the §1G strict-trailing-position rule already enforced
for generic type-parameter defaults: defaults occupy **trailing**
positions only (a non-defaulted param after a defaulted one is rejected
at parse time, with diagnostic code `D5`).

## Compiler path

### F0 — `prelude.builtins` parse path (gap #1)

The current `registerStdlib` parses only `prelude.primitives`. Parsing
`prelude.builtins` trips inference because the file declares the
`Result<R, E>` / `Future<T, E>` / `Iterator<T>` / `Generator<T, R>` /
`AsyncIterator<T, E>` / `Context<B, R>` interfaces that the compiler
already synthesises before user code runs.

Two paths to pick from:

- **Path A** — split `builtins.d.bp` into a "decl-only fn block" file
  (`builtins_fns.d.bp` carrying only `fn todo`, `fn panic`, `fn emit`,
  `fn module`, `fn getContex<T>`, the runtime `fn trap`, and any future
  fn additions) and have `registerStdlib` parse just that. The
  interface-bearing chunks (`Result`, `Future`, …) stay declarative-only
  and the inference-side synthetic registration stays untouched.

- **Path B** — extend the parser with a `#[skipSeed]` marker on each
  pre-defined interface so `registerStdlib` can skip them during the
  builtins parse. More invasive (parser marker + skip table + diagnostic
  for an unknown marker) and reads less obviously.

**Picks Path A.** The file split is straightforward, keeps every doc
co-located in `builtins.d.bp` (the interface decls), and gives the
synthetic-fn parse path one small input that's known-clean.

After F0 lands, the `fn_decls` map in `comptime.zig` (lines 893 + 1062)
carries entries for `todo` / `panic` / `emit` / `module` / `trap` /
`getContex<T>` with their full `[]Param` lists; `expandTrailingDefaults`
finds them and injects the defaults.

### F1 — receiver-bound defaults (gap #2)

`expandTrailingDefaults` today reuses the param's own `Expr` slot:

```zig
new_args[i] = .{
    .label = null,
    .value = @constCast(&fn_decl.params[i].default.?),
    .comments = &.{},
    .is_default_inj = true,
};
```

That works for literal defaults (string / int / float / bool) but
mishandles receiver-bound defaults like `end: i32 = self.length()` —
`self` inside the default refers to the param decl's `self`, not the
call site's receiver, so the injected Expr can't be rendered correctly
in every call context.

**Rewrite path**: when the default Expr contains a `self` identifier,
walk the Expr at injection time and rewrite each `self` reference to the
call's receiver Expr (cloned shallow into the spec arena). The walk is
target-agnostic — same code, all four backends benefit.

The walk must:
- Recurse through `binaryOp`, `unaryOp`, `methodCall`, `fieldAccess`,
  `subscript`, `case`, `if`, lambdas, etc.
- Stop at **inner** fn-decl boundaries (a lambda's own `self` if it
  declared one shouldn't be rebound).
- Preserve the loc of every rewritten node so diagnostics still point
  at the param's default-expression position.

### F2 — diagnostics

| # | Author wrote | Diagnostic |
|---|---|---|
| D1 | `fn f(a: i32 = 1, b: i32)` | `fn-param-default-trailing-only: a defaulted parameter must be followed only by other defaulted parameters. Move \`a\` to the end of the list or give \`b\` a default.` |
| D2 | `Config(host: "x", "y")` (positional after named) | `fn-param-positional-after-named: positional argument supplied after a named one. Convert \`"y"\` to a named arg.` |
| D3 | `connect()` when `host` has no default | `fn-param-default-arity-mismatch: \`connect\` requires 1 argument (\`host\`), got 0.` |
| D4 | `Color.Rgb()` when the variant has 3 non-defaulted fields | `enum-variant-arity-mismatch: \`Color.Rgb\` expects 3 fields (\`r\`, \`g\`, \`b\`), got 0.` (D3 wording with the enum-variant tail) |
| D5 | `fn f(a: i32 = 1, b: i32)` at parse time (same source as D1) — the parse-time companion that fires before D1 at decoration of an interface method or struct getter. | `fn-param-default-trailing-only-parse: same wording, fires from `parser/decls.parseParam`.` |
| D6 | `s.slice(2, 5, 99)` (more args than params) | `fn-param-arity-exceeded: \`String.slice\` takes 2 arguments (after the receiver), got 3.` |

## Steps

### F0 — split `builtins.d.bp`
- [ ] Extract `fn todo`, `fn panic`, `fn emit`, `fn module`, `fn trap`,
      `fn getContex<T>`, `fn field<T,F>` from `libs/std/src/builtins.d.bp`
      into a new `libs/std/src/builtins_fns.d.bp`. Keep the interface +
      enum + struct decls in `builtins.d.bp` unchanged (they remain
      doc-only for now).
- [ ] `comptime/std_prelude.zig` (or the embed-path equivalent) imports
      `builtins_fns.d.bp` alongside `primitives.d.bp` and exposes it as
      `prelude.builtin_fns`.
- [ ] `registerStdlib` in `comptime.zig` parses both `prelude.primitives`
      and `prelude.builtin_fns` into `env.arena`; `inferProgram` runs
      against both so the synthetic-fn binding lands in `env.bindings`
      and reaches the `fn_decls` map.
- [ ] Confirm that `expandTrailingDefaults` now matches a bare `todo()`
      call to the parsed `FnDecl` and injects `"not implemented"` into
      the args slice.

### F1 — receiver-bound default rewrite
- [ ] `comptime/transform.zig`: extend `expandTrailingDefaults` so when
      `c.receiver` is non-null and the default Expr contains a `self`
      reference, clone the Expr shallow into `spec_cache.arena` and walk
      it rebinding `self` to a shallow-clone of the receiver.
- [ ] `comptime/expr_walk.zig` (new): tiny visitor that recurses through
      every Expr variant and applies a rewrite predicate at each
      `identifier` node. Re-usable for the F4 instance-method default
      case below.
- [ ] Test: `s.slice(2)` on a `string s = "hello"` lowers to the same
      bytes that `s.slice(2, s.length())` would lower to.

### F2 — diagnostics
- [ ] Reserve D1–D6 in `comptime/diagnostics.zig`.
- [ ] `parser/decls.parseParam`: emit D5 when a non-defaulted param
      appears after a defaulted one (parse-time fail-fast).
- [ ] `comptime/infer.zig`: emit D1 / D3 / D4 / D6 at arity-check time.
- [ ] D2 fires from `parser/decls.parseAnnotationCall` +
      `parser/expressions.parseCallExpr` when a positional arg follows a
      named one.

### F3 — surface migrations
- [ ] `libs/std/src/builtins.d.bp` — `todo` / `panic` keep their
      one-template `@External.<Target>(...)` annotations + the
      `= "not implemented"` / `= "panic"` defaults.
- [ ] `libs/std/src/primitives.d.bp` — `Array.slice` + `String.slice`
      drop their `when(argc == N)` clauses, gain `end: i32 = self.length()`
      defaults, and the templates collapse to one each.
- [ ] `codegen/{erlang,commonJS}.zig` — `registerInlineBuiltinErlangDispatch`
      / `registerInlineBuiltinDispatch` collapse to single-branch entries
      for `todo` and `panic` (the `argc==0` branches die).
- [ ] The arity-branch infra in `ast.zig`
      (`ArityBranch` / `parseArityBranchArg` /
      `externalHasArityBranches` / `externalArityBranchFor`) + the
      backend dispatch glue is **kept** as the safety net for any third-
      party host fn that still wants per-arity templates; the migration
      removes only stdlib usages.

### F4 — extend to record + enum + struct constructors
- [ ] `comptime/infer.zig`: record / struct / enum variant constructor
      calls walk through `expandTrailingDefaults` (or a sibling that
      takes the synthetic param list returned by `recordFieldsAsParams`
      / `structFieldsAsParams` / `enumVariantAsParams`).
- [ ] Receiver-bound defaults inside record-method default expressions
      (e.g. `record Counter(value: i32 = 0) { fn step(self, by: i32 = 1) }`)
      rewrite `self` against the method-call receiver via the F1 walk.

### F5 — tests
- [ ] `tests/codegen/fn_param_defaults.zig` (new):
      - Trailing literal default (`todo` / `panic`).
      - Receiver-bound default (`slice`).
      - Record constructor 0-arg / 1-named / mid-positional cases.
      - Enum variant 0-arg / pre-supplied / named-suffix cases.
      - Annotation `#[ServiceOpts(name: "api")]` resolves defaults.
- [ ] `parser/tests/declarations.zig`: D5 fires on
      `fn f(a: i32 = 1, b: i32) { }`.
- [ ] `comptime/tests/diagnostics.zig`: D1–D4 + D6 each pair with their
      author-error source.
- [ ] `lib-test`: a smoke `.bp` in `libs/std/test/` calls
      `panic()` + `s.slice(2)` and asserts behaviour matches the
      pre-spec snapshot bank byte-for-byte.

### F6 — docs
- [ ] `modules/compiler-core/AGENTS.md` §"parser/" — `parseParam` reads
      `= <expr>` default; `parseEnumBody` reads variant-field defaults.
- [ ] `modules/compiler-core/AGENTS.md` §"comptime/" — `transform.zig
      expandTrailingDefaults` is the unified default-injection point.
- [ ] `libs/std/AGENTS.md` §"Default values in fn-decl param lists" —
      explain the rule + the unified surface across calls / annotations
      / record + enum constructors.
- [ ] `CHANGELOG.md` — one line under v0.beta.20:
      `feat(stdlib): fn-param defaults injected at every call surface;
       arity-branch \`when(argc == N)\` retired from libs/std.`

## Test scenarios

```
F0         ---- a bare `todo()` call resolves to the parsed FnDecl in fn_decls and `expandTrailingDefaults` injects "not implemented" as args[0]
F0-erl     ---- the erlang inline-seeded dispatch collapses to one branch (argc=1) and renders `erlang:error({todo, <<"not implemented">>})` byte-identical to the pre-spec two-branch path
F0-node    ---- the commonJS inline-seeded dispatch collapses to one branch (argc=1) and renders `(() => { throw new Error("not implemented") })()`
F1         ---- `s.slice(2)` lowers to the same bytes as `s.slice(2, s.length())`; receiver `self` rebinds to `s` inside the default Expr
F1-erl     ---- erlang template renders `string:slice(<<"hello">>, 2, ((string:length(<<"hello">>)) - (2)))`
F1-node    ---- node template renders the same expansion via gleam_stdlib's string_slice
F2-D1      ---- `fn f(a: i32 = 1, b: i32)` reds with `fn-param-default-trailing-only`
F2-D2      ---- `Config(host: "x", "y")` reds with `fn-param-positional-after-named`
F2-D3      ---- `connect()` reds with `fn-param-default-arity-mismatch`
F2-D4      ---- `Color.Rgb()` reds with `enum-variant-arity-mismatch`
F2-D5      ---- D1's wording fires from parse path before infer ever sees the fn
F2-D6      ---- `s.slice(2, 5, 99)` reds with `fn-param-arity-exceeded`
F3-byte    ---- diff snapshots/codegen/ against pre-F3 HEAD: empty (byte-identical migration)
F3-empty   ---- post-F3 `git grep "when(argc ==" libs/std/src/` finds zero hits
F4         ---- `Config(port: 9000, tls: true)` injects host="localhost" and emits the 3-arg record constructor
F4-enum    ---- `Level.Error("boom")` injects code=-1 and emits the 2-arg variant
F4-annot   ---- `#[ServiceOpts(name: "api")]` injects replicas=1, public=false and reaches the decorator validator with a complete arg list
F5-libtest ---- the libs/std smoke calls behave identically to the pre-spec snapshot bank
F6-docs    ---- AGENTS.md sweep across compiler-core + libs/std + CHANGELOG.md in the same commit as F3
gate       ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

## Notes

- **Cross-spec interaction with `prim-op-annotation`.** This spec closes
  the two deferred items recorded in `prim-op-annotation`'s commit
  `5f0f1d9`:
  - "`when(argc == N): \"...\"` arity-branch syntax stays valid for the
    two Array/String `slice` methods in primitives.d.bp" → resolved by
    §F1 + §F3.
  - "`todo`/`panic` inline-seeded dispatch in erlang.zig + commonJS.zig
    still ships two arity branches" → resolved by §F0 + §F3.
- **Why a sibling spec, not a `prim-op-annotation` extension.** The two
  gaps are not template-grammar problems — they are *call-site*
  problems (default injection + receiver-bound default rewrite). They
  fit the broader Kotlin-style uniformity of defaults that record / enum
  constructors + annotations already partly enjoy; bundling them under
  `prim-op-annotation` would muddle the spec's scope (it stays focused
  on the template grammar). A separate spec keeps both stories crisp
  for a future reader.
- **Cross-spec interaction with Frente B §1G.** Frente B §1G already
  enforces "defaults occupy trailing positions" for generic type
  parameters (`<T, U = string>`). This spec extends the same rule to
  fn-decl value params (a non-defaulted param after a defaulted one
  reds D5), so the language stays consistent: defaults trail everywhere.
- **What this spec is NOT.**
  - Not a new effect, type-system feature, or runtime change.
  - Not a backwards-compat shim — the legacy `when(argc == N)` clause
    keeps parsing so third-party libs (libs/onze, libs/rakun, etc.) can
    migrate at their own pace, but the stdlib drops it.
  - Not concerned with `comptime` defaults (a default expression that
    needs comptime evaluation to land — that's a `@comptime`-marked
    param's job; out of scope here, gated behind its own future spec).
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.
