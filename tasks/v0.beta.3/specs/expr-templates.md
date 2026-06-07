# Comptime template strings — `expr` meta-kind + spliced expansion

**Slug**: `expr-templates`
**Depends on**: `generic-inference` (comptime expansion calls generic fns internally)
**Files**: `modules/compiler-core/src/{lexer,parser,ast,comptime,codegen}/*`; `libs/std/src/syntax.bp`
**Touches docs**: `docs.md` (meta-kinds, interpolation, tagged calls, hygiene); `modules/compiler-core/src/codegen/AGENTS.md`
**Status**: pending

> Carried over from v0.beta.2 (full spec written there; zero implementation).
> v0.beta.3 is the implementation wave. The design is final — do not change the
> spec below without a new spec file.

## Goal

Library functions that receive caller source as **unevaluated typed expressions**,
inspect the caller's scope, and return expressions **spliced and re-type-checked
at the call site** — enabling zero-runtime-cost DSLs (`html`, `yaml`) whose
result types the language fully understands.

## Target syntax

```bp
// Library side (libs/std/src/syntax.bp already has the data model)
pub fn html(comptime template: expr string) -> expr string {
    // inspects `template` at comptime, validates tags, returns spliced output
    ...
}

// Call site
val page = html`<h1>${title}</h1>`;
// Equivalent: val page = html("<h1>${title}</h1>")
```

## Core semantic rules

1. **Unevaluated passing** — `comptime p: expr T` receives the caller's
   AST, not a runtime value; `T` must be check-able without evaluating.
2. **Provenance / hygiene** — references inside the template resolve in the
   *library's* scope; interpolations `${ … }` resolve in the *caller's* scope.
3. **Value lifting** — a plain `T` value coerces to `expr T` at the call site.
4. **Splice / re-check** — a function returning `expr T` has its return
   expression spliced into the call site and re-type-checked there.
5. **Memoization** — expansions are memoized by `hash(template + bindings)`;
   identical call sites share the expanded AST.

## Steps

### F0 — Rename `typeparam` → `type` (contextual keyword in constraint position)

- [ ] Lexer: accept `type` in constraint position (contextual — not a hard keyword)
- [ ] Remove `typeparam` keyword (hard rename, no deprecation period)
- [ ] Update all `.bp` sources and snapshots using `typeparam`
- [ ] Formatter round-trips stable

### F1 — String interpolation `${ }` in string literals

- [ ] Lexer: scan `${` inside string literals; emit `StringPart` stream
      (`Literal(text)`, `Interp(expr)`)
- [ ] AST: `Expr.stringTemplate { parts: []Part }`
- [ ] Inference: each interp part must unify with `string`-convertible (or `T`
      with a `toString` method); whole template has type `string`
- [ ] Codegen: lower to string concat per backend (JS: template literal or `+`;
      Erlang: `io_lib:format` or `++`; WASM: runtime concat)
- [ ] Escape: `\${` → literal `${` in string
- [ ] Formatter: round-trips stable
- [ ] Snapshots: `parser/string_interp_simple`, `codegen/node/string_interp_scope`

### F2 — `expr T` meta-kind in type grammar

- [ ] Parser (type grammar): `expr typeExpr?` — parsed as a type annotation
- [ ] `comptime/types.zig`: `TypeKind.exprOf(?inner)` (inner = None for bare `expr`)
- [ ] Unify rules: `expr T` unifies with `expr T` (same inner); bare `expr`
      unifies with any `expr T`
- [ ] Rule: parameters typed `expr T` require `comptime` keyword on the fn param
- [ ] Snapshots: `comptime/expr_type_annotation`

### F3 — Tagged template call syntax

- [ ] Parser: postfixExpr followed directly by a string literal → call with
      that literal as first argument; `f"…"` ≡ `f("…")`
- [ ] Formatter: preserve tagged form (don't desugar to `f("…")` on format)
- [ ] Snapshots: `parser/tagged_template_call`

### F4 — Comptime capture of unevaluated `expr` arguments

- [ ] Inference: when an arg is passed to `comptime p: expr T`, capture the
      unevaluated AST + infer its type; do NOT evaluate
- [ ] `libs/std/src/syntax.bp`: confirm `Span`, `Part`, `BindingKind`, `Binding`,
      `Source`, `Context`, and `interface Expr<E>` are complete and correct
- [ ] Extensions on `expr`: `.parts` (interpolation parts), `.source` (raw text)
- [ ] `Binding.ref()`: emit a reference to the binding in the output expr
- [ ] Scope snapshot: collect top-level decls + imports reachable from call site
- [ ] `fail(msg)` / `failAt(span, msg)`: abort expansion with a diagnostic at
      a specific source location
- [ ] Snapshots: `comptime/expr_capture_unevaluated`

### F5 — Splicing expr-valued expressions at call sites

- [ ] Parser: `expr block` in expression position (anonymous expr literal)
- [ ] Hygiene: name resolution in the expr block uses the *library's* scope;
      `${ … }` interpolations use the *caller's* scope
- [ ] Value lifting: plain `T` value in `expr T` position auto-wraps
- [ ] `Binding.ref()` + `Part.Interp` splice into the output AST
- [ ] Snapshots: `comptime/expr_splice_hygiene`

### F6 — Expansion driver + memoization

- [ ] Expansion driver: when a function call's return type is `expr …`, trigger
      comptime expansion of the function body with the captured args
- [ ] Bounded `-> expr T` (eager): run expansion; post-splice type-check the
      result against `T`; replace call node with the spliced AST
- [ ] Bare `-> expr` (structural): suspend call; resume after structural type
      from context is known; then expand and splice
- [ ] Memoize by `hash(template_source + binding_types)` — reuse if identical
- [ ] Codegen: expanded output is ordinary AST; existing codegen handles it
      with no special-casing
- [ ] Snapshots: `comptime/expr_expansion_eager`, `comptime/expr_expansion_structural`

### F7 — Examples + docs

- [ ] `examples/jonhstar/` — minimal HTML component library using `html\`…\``
- [ ] `examples/yamlconf/` — YAML config library + structural type fit demo
- [ ] `docs.md`: document meta-kinds (`expr`, `type`), interpolation syntax,
      tagged calls, hygiene rules, memoization
- [ ] Update all AGENTS.md files touched by the implementation

## Test scenarios

```
parser ---- typeparam removed; type keyword in constraint position
parser ---- string interpolation: simple literal
parser ---- tagged template call: f"..." desugars correctly
comptime ---- expr type annotation accepted
comptime ---- unevaluated capture: arg not evaluated before passing
comptime ---- scope snapshot contains top-level decls
comptime ---- hygiene: library scope vs caller scope
comptime ---- splice: re-type-checked at call site
comptime ---- expansion: memoized on identical template + bindings
codegen/node ---- string interpolation emits template literal
codegen/node ---- expanded expr is ordinary AST output
codegen/node ---- jonhstar html example compiles and runs
```

## Notes

- `libs/std/src/syntax.bp` already exists with the data model (`Span`, `Part`,
  `Binding`, `BindingKind`, `Source`, `Context`, `Expr<E>`) — verify completeness
  before F4 rather than rewriting.
- `generic-inference` must land first: expansion internally calls generic fns
  and the `.generic` unification error would surface in F6.
- `typeparam` rename (F0) is a hard break — update all `.bp` files, snapshots,
  docs, and tests in the same commit (no deprecation alias).
- Tagged template syntax (`f"…"`) is syntax sugar only — the desugaring happens
  in the parser, not the type system.
- WASM string concat codegen may need separate investigation; track in backend-parity.
