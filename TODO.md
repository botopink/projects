# TODO — expr-templates

> Live checklist for branch `task/expr-templates` (worktree `.tasks/expr-templates/`).
> Spec (intent, immutable): [`tasks/v0.beta.2/specs/expr-templates.md`](tasks/v0.beta.2/specs/expr-templates.md)
>
> **Goal**: comptime template strings — `type`/`expr` meta-kinds, `${…}`
> interpolation, tagged calls (`html """…"""`), hygienic splice with caller-scope
> lookup. Canonical models: `html` (bounded `-> expr Component`) and `yaml`
> (bare `-> expr`, type revealed per call site). No new `@`-builtins.

## F0 — rename `typeparam` → `type`
- [x] Lexer/parser: `type` was already a reserved token (`TokenKind.type`); the
      meta-kind branch in `parser/types.zig:parseBaseTypeRef` now consumes `.type`
      instead of the contextual identifier `typeparam`
- [x] Remove `typeparam` (hard rename — pre-1.0, no alias kept); internal AST/type
      names (`TypeRef.typeparam`, `typeparamConstraint`) intentionally kept
- [x] Update `.bp` sources (`builtins.d.bp`), snapshots (9 regenerated under new
      slugs), README.md, comptime/AGENTS.md, src/docs.md; error message now says
      "type constraint"
- [x] Formatter round-trips `comptime T: type string | int` (fmtTypeRef prints `type`)
- [x] Note: `-> type` in return position now parses as the meta-kind (was: named
      type `type`) — a fn returning a type, consistent with the spec

## F1 — string interpolation `${…}`
- [ ] Lexer: scan `${` inside `stringLiteral` and `multilineStringLiteral`; emit part streams
- [ ] AST: `stringTemplate { parts: []Part }` where Part = text | expr
- [ ] Infer: interp parts are `string`-only (explicit conversion required)
- [ ] Codegen: lower to concat per backend (commonJS, erlang, beam_asm, typescript)
- [ ] Escape: `\${` produces literal `${`
- [ ] Formatter + snapshots: `parser/string_interp`, `codegen/*/string_interp`

## F2 — `expr` type form
- [ ] Parser (type grammar): `expr typeExpr?` in any type position; bare `expr` only in return/inference positions
- [ ] `comptime/types.zig`: new TypeKind `exprOf(?inner)` (type form, not a named builtin)
- [ ] Unify: `expr T ~ expr U` iff `T ~ U`; bare `expr` as deferred variable
- [ ] Meta-kind params require `comptime` modifier (parser error otherwise)
- [ ] Snapshots: `parser/expr_type_positions`, `comptime/expr_unify`

## F3 — tagged-call sugar
- [ ] Parser: postfixExpr + immediate string/multiline literal ⇒ call with one arg
- [ ] Formatter: preserve the tagged form
- [ ] Snapshots: `parser/tagged_call_single`, `parser/tagged_call_multiline`, `format/tagged_call_roundtrip`

## F4 — unevaluated passing + `std.syntax` + scope snapshot
- [ ] Capture arg to `comptime p: expr T` unevaluated, with provenance (file, span, scope handle)
- [ ] `libs/std/src/syntax.bp`: `Span`, `Part`, `BindingKind`, `Binding`
- [ ] Extensions on `expr` (`text`, `parts`, `lookup`, `fail`, `failAt`) + `Binding.ref()` (comptime-only)
- [ ] Scope snapshot V1: top-level decls + imports of the caller → serializable map (`comptime/snapshot.zig`)
- [ ] `fail`/`failAt`: rustc-style diagnostic with span mapped into the caller's template
- [ ] Snapshots: `comptime/expr_param_capture`, `comptime/lookup_hit_miss`, `comptime/fail_span_in_template`

## F5 — `expr { … }` literal + composition + lifting
- [ ] Parser: `expr block` in expression position; `${…}` splices inside
- [ ] Hygiene: literal resolves in the library's scope (provenance rule)
- [ ] Value lifting: comptime value of `T` coerces to `expr T`
- [ ] `Binding.ref()` / `Part.Interp` holes splice as caller-scope references
- [ ] Snapshots: `comptime/expr_literal_splice`, `comptime/value_lifting`, `comptime/hygiene_two_scopes`

## F6 — call-site expansion + re-typecheck + memoization
- [ ] Expansion driver in the transform/specialization pass
- [ ] Bounded `-> expr T`: eager caller inference against `T`; post-splice bound check
- [ ] Bare `-> expr`: suspend caller inference; resume with expanded structural type
- [ ] Memoize by hash(template text + used-binding signatures)
- [ ] End-to-end codegen snapshot per backend
- [ ] Snapshots: `comptime/splice_bounded_ok`, `comptime/splice_bound_violation`, `comptime/splice_bare_reveals_type`, `codegen/*/template_end_to_end`

## F7 — canonical examples + docs
- [ ] `examples/jonhstar/` — minimal `html` component lib
- [ ] `examples/yamlconf/` — `yaml` config lib + structural-fit demo
- [ ] docs.md: meta-kinds, interpolation, tagged calls, `expr { … }`, hygiene, limits
- [ ] Update every file in the spec's `Touches docs:`
