# expr-templates — comptime template strings via `type` / `expr` meta-kinds

**Slug**: expr-templates
**Depends on**: nothing
**Files**: modules/compiler-core/src/{lexer.zig,lexer/token.zig,parser/*,ast.zig,comptime/*,format.zig,codegen/*}, libs/std/src/syntax.bp (new), examples/
**Touches docs**: docs.md (meta-kinds, interpolation, tagged calls, `expr` literal), modules/compiler-core/src/parser/{AGENTS.md,examples.md}, modules/compiler-core/src/comptime/AGENTS.md, modules/compiler-core/src/codegen/AGENTS.md, libs/std/AGENTS.md

**Status**: pending

> **Goal**: library functions that receive caller source as **unevaluated typed
> expressions**, inspect the caller's scope, and return expressions that are
> **spliced and re-type-checked at the call site** — enabling zero-runtime-cost
> DSLs (`html """<Button/>"""`, `yaml """..."""`) whose result types the
> language fully understands after expansion.
>
> The whole feature stands on **two meta-kind keywords**:
>
> | keyword | reads as | replaces |
> |---|---|---|
> | `type` | "this parameter **is a type**" | `typeparam` |
> | `expr T` / `expr` | "this **is an expression** of `T` (unevaluated / to splice)" | `syntaxparam` (input) **and** `compvalue` (output) — one unified concept |
>
> Design rule (settled): **no new `@`-builtins**. Keywords cover what belongs to
> the language (type forms, the `expr { … }` literal); the data model
> (`Part`, `Binding`, `Span`) lives in the stdlib as ordinary types.

## Target syntax

```bp
// generics — `type` replaces `typeparam` (same constraint grammar)
pub fn parse(comptime T: type string | int, raw: string) -> T;

// a template function: "receives an expression of string, returns an expression of Component"
pub fn html(comptime template: expr string) -> expr Component {
    val button = template.lookup("Button") catch
        template.fail("component not found in caller scope");
    return expr { ${button.ref()}() };       // `expr { … }` literal builds code
}

// bare `expr`: the result type is revealed per call site, after splicing
pub fn yaml(comptime template: expr string) -> expr;

// `expr T` composes in any type position
fn emit(node: YamlNode) -> expr;
val children: array<expr Element> = [];
```

Grammar:

```
metaKindType  ::= "type" typeConstraint?            // type position; param requires `comptime`
              |   "expr" typeExpr?                  // bare `expr` = type revealed at splice
typeConstraint::= typeExpr ("|" typeExpr)*
exprLiteral   ::= "expr" block                      // expression position: builds an expr value
splice        ::= "${" expr "}"                     // inside string literals AND inside exprLiteral
taggedCall    ::= postfixExpr (stringLiteral | multilineStringLiteral)
                                                    // sugar: f """…""" ⇒ f("""…""")
```

- `type` / `expr` are **contextual keywords**: keyword in type position (after
  `:` / `->` / inside generics) and, for `expr`, when immediately followed by a
  block in expression position. Plain identifier elsewhere (`val expr = …` keeps
  working).
- A parameter whose type is a meta-kind (`type` / `expr T`) **must** carry the
  `comptime` modifier — one rule for all meta-kinds.
- `taggedCall` only fires when the string literal immediately follows a postfix
  expression (today that juxtaposition is a parse error, so the syntax space is
  free).

### Core semantic rules

1. **Unevaluated passing.** An argument bound to a `comptime p: expr T`
   parameter is not evaluated; it is captured as an expression of type `T`
   (type-checked in the caller, then handed over).
2. **Provenance + hygiene.** Every `expr` value carries where it was written.
   `lookup`/`fail` resolve against the expression's **origin scope**: a caller
   template resolves in the caller's file; an `expr { … }` written in the
   library resolves in the library. Macro hygiene falls out of this one rule.
3. **Value lifting.** Any comptime value of type `T` coerces to `expr T` — a
   constant *is* an expression. (This is why `yaml` can just build a record and
   return it; no quoting needed.)
4. **Splice + re-check.** A call whose callee returns `expr …` is expanded at
   comptime; the resulting expression replaces the call and is type-checked in
   the caller's context.
   - Bounded form `-> expr Component`: callers are inferred against `Component`
     immediately (LSP-friendly); the splice is verified against the bound after
     expansion.
   - Bare form `-> expr`: caller inference suspends until expansion; each call
     site gets its own structural type (the `yaml` case — "the type is
     specified later, and the language understands it").
5. **Memoization.** Expansion is cached by hash of (template text, used-binding
   signatures); unchanged templates never re-expand across builds / LSP saves.

### stdlib surface (`libs/std/src/syntax.bp` — ordinary types, no builtins)

```bp
pub struct Span { start: int, end: int, line: int }

pub enum Part {
    Text(string, Span),
    Interp(expr, Span),          // a ${…} hole, already typed in the caller
}

pub enum BindingKind { Fn, Val, Struct, Enum, Interface }

pub struct Binding {
    name: string,
    kind: BindingKind,
}
```

Compiler-provided extensions on `expr` (declared here, dispatched via the
existing extension-dispatch mechanism; instances only exist at comptime):

```bp
// On any expr value:
fn text(self: expr) -> string;                       // raw source text
fn parts(self: expr) -> array<Part>;                 // text/interp alternation
fn lookup(self: expr, name: string) -> @Option<Binding>;  // origin-scope resolution
fn fail(self: expr, msg: string) -> never;           // diagnostic at the expr's span
fn failAt(self: expr, span: Span, msg: string) -> never;  // diagnostic INSIDE the template

// On Binding:
fn ref(self: Binding) -> expr;                       // spliceable reference to the binding
```

`@Option` here is the language's ordinary option type — no new builtin is
introduced.

## Examples

### Model 1 — `html` (scope-aware DSL, bounded return)

```bp
// lib jonhstar
import { std.syntax.Part };

pub fn html(comptime template: expr string) -> expr Component {
    val root = parseTags(template.parts()) catch err ->
        template.failAt(err.span, err.message);
    val button = template.lookup("Button") catch
        template.fail("component not found in caller scope");
    return expr { ${button.ref()}(label: ${root.attr("label")}) };
}
```

```bp
// main.bp
import { html } from "jonhstar";
import { Button };

val titulo = "Send";

val component = html """
    <Button label=${titulo}></Button>
""";
```

Lowers to (conceptually): `val component = Button(label: titulo);`
- `<Button>` resolved **in main.bp's scope** (hygiene via provenance);
- `${titulo}` crosses the template as a typed hole — if `Button.label` is not
  `string`, the error is the ordinary type error, pointing at the interpolation;
- an unknown `<Buttom>` produces a rustc-style diagnostic pointing at the line
  **inside the `"""…"""` in main.bp**, not inside the jonhstar lib.

### Model 2 — `yaml` (type-revealing data DSL, bare return)

```bp
// lib yamlconf
pub fn yaml(comptime template: expr string) -> expr {
    val doc = parseYaml(template.text()) catch err ->
        template.failAt(err.span, err.message);
    return toValue(doc);     // builds a plain record; value→expr lifting (rule 3)
}
```

```bp
// main.bp
import { yaml } from "yamlconf";

val config = yaml """
    server:
      host: "0.0.0.0"
      port: 8080
    debug: true
    origins:
      - "https://app.example.dev"
""";

config.server.port + 1     // ok: int
if config.debug { … }      // ok: bool
config.server.prot         // COMPILE ERROR: no field `prot` in { host: string, port: int }
```

After expansion the structural type is fully known:
`{ server: { host: string, port: int }, debug: bool, origins: array<string> }`.
Two `yaml` calls with the same shape unify structurally (existing `unify.zig`),
so `fn start(cfg: { server: { port: int } })` accepts it — the YAML doesn't
declare a type, it just *fits* one.

### Interpolation in ordinary strings (prerequisite, useful standalone)

```bp
val name = "world";
val greeting = "hello ${name}";          // lowers to concat per backend
val block = """
    multi ${name}
    line
""";
```

### Tagged-call sugar

```bp
html """<Button/>"""        // ⇒ html("""<Button/>""")
sql "SELECT 1"              // ⇒ sql("SELECT 1") — works for single-line too
```

### Keyword rename (F0, mechanical)

```bp
// before                                   // after
fn f(comptime T: typeparam) { … }           fn f(comptime T: type) { … }
fn g(comptime T: typeparam string | int)    fn g(comptime T: type string | int)
```

## Steps

### F0 — rename `typeparam` → `type`
- [ ] Lexer/parser: accept `type` in constraint position (contextual keyword)
- [ ] Remove `typeparam` (hard rename — pre-1.0, no alias kept)
- [ ] Update all `.bp` sources, snapshots, docs.md, parser examples
- [ ] Formatter round-trips `comptime T: type string | int`

### F1 — string interpolation `${…}`
- [ ] Lexer: scan `${` inside `stringLiteral` and `multilineStringLiteral`; emit part streams
- [ ] AST: `stringTemplate { parts: []Part }` where Part = text | expr
- [ ] Infer: every interp part unifies with `string`-convertible (decide: implicit `toString` vs `string`-only — default **string-only**, explicit conversion required)
- [ ] Codegen: lower to concat per backend (commonJS, erlang, beam_asm, typescript)
- [ ] Escape: `\${` produces literal `${`
- [ ] Formatter + snapshots: `parser/string_interp`, `codegen/*/string_interp`

### F2 — `expr` type form
- [ ] Parser (type grammar): `expr typeExpr?` in any type position; bare `expr` allowed only in return position and local inference contexts
- [ ] `comptime/types.zig`: new TypeKind `exprOf(?inner)` (a type form, **not** a named builtin)
- [ ] Unify: `expr T ~ expr U` iff `T ~ U`; bare `expr` unifies as a deferred variable
- [ ] Rule: meta-kind params require the `comptime` modifier (reuse `ParamModifier`; parser error otherwise)
- [ ] Snapshots: `parser/expr_type_positions`, `comptime/expr_unify`

### F3 — tagged-call sugar
- [ ] Parser: postfixExpr followed immediately by string/multiline literal ⇒ call with one arg
- [ ] Formatter: preserve the tagged form (do not expand to parens)
- [ ] Snapshots: `parser/tagged_call_single`, `parser/tagged_call_multiline`, `format/tagged_call_roundtrip`

### F4 — unevaluated passing + `std.syntax` + scope snapshot
- [ ] Capture: argument to `comptime p: expr T` is type-checked in caller then captured unevaluated, with provenance (file, span, scope handle)
- [ ] `libs/std/src/syntax.bp`: `Span`, `Part`, `BindingKind`, `Binding` as ordinary types
- [ ] Extensions on `expr` (`text`, `parts`, `lookup`, `fail`, `failAt`) and `Binding.ref()` via the existing extension-dispatch mechanism; comptime-only
- [ ] Scope snapshot (V1): at the call site, collect **top-level decls + imports** visible to the caller into a serializable map (name → kind → opaque handle) for `lookup`; integrate with `comptime/snapshot.zig`
- [ ] `fail`/`failAt`: abort expansion with a rustc-style diagnostic whose span maps into the caller's template text
- [ ] Snapshots: `comptime/expr_param_capture`, `comptime/lookup_hit_miss`, `comptime/fail_span_in_template`

### F5 — `expr { … }` literal + composition + lifting
- [ ] Parser: `expr block` in expression position; `${…}` inside splices other `expr` values
- [ ] Hygiene: identifiers inside the literal resolve in the **library's** scope (provenance rule 2)
- [ ] Value lifting: comptime value of `T` coerces to `expr T` (records/arrays/scalars; function values lift as references)
- [ ] `Binding.ref()` and `Part.Interp` holes splice as references into the caller's scope
- [ ] Snapshots: `comptime/expr_literal_splice`, `comptime/value_lifting`, `comptime/hygiene_two_scopes`

### F6 — call-site expansion + re-typecheck + memoization
- [ ] Expansion driver: calls returning `expr …` whose args are comptime-known expand during the existing transform/specialization pass
- [ ] Bounded `-> expr T`: caller inferred against `T` eagerly; post-splice check against the bound
- [ ] Bare `-> expr`: suspend the caller's inference on the call's type var; resume with the expanded expression's structural type
- [ ] Memoize by hash(template text + used-binding signatures); invalidate on either change
- [ ] Codegen: expanded output is ordinary AST — all backends work unchanged; add one end-to-end snapshot per backend
- [ ] Snapshots: `comptime/splice_bounded_ok`, `comptime/splice_bound_violation`, `comptime/splice_bare_reveals_type`, `codegen/*/template_end_to_end`

### F7 — canonical examples + docs
- [ ] `examples/jonhstar/` — minimal `html` component lib (Model 1)
- [ ] `examples/yamlconf/` — `yaml` config lib (Model 2), including the structural-fit demo
- [ ] docs.md: meta-kinds (`type`, `expr`), interpolation, tagged calls, `expr { … }`, hygiene & provenance, limits
- [ ] Update every file in `Touches docs:`

## Test scenarios

```
lexer ---- string_interp_parts            ("a ${x} b" → text/expr/text)
lexer ---- string_interp_escape           (\${ stays literal)
parser ---- type_keyword_constraint       (comptime T: type string | int)
parser ---- expr_type_positions           (param, return, array<expr T>, bare expr return)
parser ---- expr_requires_comptime        (error: expr param without comptime)
parser ---- tagged_call_single
parser ---- tagged_call_multiline
parser ---- expr_literal_with_splices
format ---- tagged_call_roundtrip
format ---- expr_literal_roundtrip
comptime ---- expr_param_capture          (arg arrives unevaluated, typed)
comptime ---- lookup_hit_miss             (Button found; Buttom → @Option none)
comptime ---- fail_span_in_template       (diagnostic points inside """…""" in caller file)
comptime ---- hygiene_two_scopes          (lib expr{} resolves in lib; template in caller)
comptime ---- value_lifting               (record value returned where expr expected)
comptime ---- splice_bounded_ok           (-> expr Component, fits)
comptime ---- splice_bound_violation      (expanded expr not a Component → error at call)
comptime ---- splice_bare_reveals_type    (yaml: field access checked post-expansion)
comptime ---- splice_memoized             (same template+bindings → single expansion)
codegen/node ---- template_end_to_end     (html + yaml compile and run)
codegen/erlang ---- template_end_to_end
```

## Notes

- **Settled decisions (from design discussion):**
  - One meta-kind for code (`expr`) covering input, output and literal — the
    earlier `syntaxparam`/`compvalue` split collapsed once provenance was made
    the hygiene rule and value-lifting made "any comptime-created value" a
    valid result.
  - **No new `@`-builtins.** `@`-types (`@Result`, `@Option`, `@Future`) are
    data types; meta-kinds are type *forms* (like `fn(…) -> R`). The data model
    is plain stdlib.
  - `type`/`expr` are contextual keywords to avoid stealing common identifiers.
- **V1 limits (explicitly out of scope, recorded for the future):**
  - Expressions only. Declaration-generating macros (derive) are a separate
    future feature; the name `decl` is reserved for that meta-kind.
  - `lookup` sees top-level decls + imports only (snapshot model). Locals of
    the calling function are not visible. A host-callback model (V2) can lift
    this if snapshots prove too coarse.
  - Source-capable templates require a **literal** string argument at the call
    site (`html """…"""` or via tagged sugar). Passing a string variable is an
    error in V1 (no spans/scope to attach).
  - Template functions are not first-class values (cannot be stored/passed);
    they are always expanded at comptime.
- **Collisions:** rewrites the compiler front-end (lexer/parser/builtins) —
  must **not** run in parallel with `stdlib-gleam` or `test-blocks` (same wave
  rule already recorded in plan.md). `libs/std/src/syntax.bp` lands cleanly
  either before or after stdlib-gleam.
- **Open points:**
  - Interp typing in ordinary strings: `string`-only (explicit conversion) vs
    implicit `toString` — default written into F1 is string-only; revisit with
    stdlib-gleam's conversion helpers.
  - Should bare `expr` be allowed on helper fns only inside libs that also
    expose a bounded entry point? (LSP latency concern — measure first.)
- Everything in English, including this file.
