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
- [x] Lexer: `scanInterpolation` keeps `${…}` inside the string token (brace-depth
      + nested-string aware) — single token, NOT part streams; the parser re-scans
- [x] AST: `LiteralExprOf.Kind.stringTemplate { multiline, parts: []StringTemplatePartOf }`
- [x] Parser: `makeStringExpr` splits content, sub-lexes/sub-parses each hole
      (hole locs are slice-relative until F6 span mapping); `badInterpolation`
      parse error + print.zig message
- [x] Infer: desugars to a `+` concatenation chain (typed AST never holds the
      node) — NOTE deviation from spec: holes follow `+` coercion semantics
      (`"n=${1}"` works), not string-only; consistent with the language's `+`
- [x] Codegen: desugared to the same `+` chain in transform's rewriteExpr (codegen
      is untyped and runs on transform output) — all 5 backends untouched;
      `.stringTemplate => unreachable` guards in codegen×4 + eval runtimes×3
- [x] Escape: `\$` added to valid escapes; `\${` stays literal (parser skips it)
- [x] Formatter reconstructs the original template form (round-trip tested)
- [x] Snapshots: 5× `parser/string_interpolation_*`, 4× `codegen/*/string_interpolation_lowers_to_concat`
- [x] DISCOVERED GAP (pre-existing, not interp-specific): erlang/beam backends emit
      `<<"a">> + B` for string `+` — invalid Erlang, runtime output empty. Same for
      hand-written concat; needs a string-concat lowering in those backends (separate fix)

## F2 — `expr` type form
- [x] Parser: `TypeRef.expr: ?*TypeRef` — contextual keyword `expr [T]` in any type
      position (param, return, generic arg); bare `expr` = null inner. NOTE
      deviation: parser is position-permissive; the bare-expr positional
      restriction will be a semantic check when expansion lands (F6)
- [x] Types: encoded as named type `"expr"` with one arg (same idiom as
      `optional`/`array`) — structural unification gives `expr T ~ expr U iff
      T ~ U` for free; bare `expr` resolves its arg to a fresh var (defers to F6)
- [x] Unify: covered by named-type structural unification (infer test: identity
      fn returning its `expr string` param against an `expr string` bound)
- [x] Meta-kind params (`type`/`expr`) without `comptime` → new parse error
      `metaKindRequiresComptime` (message + hint in print.zig, error test)
- [x] Formatter + LSP hover render `expr [T]`; typescript codegen erases to `any`
- [x] Snapshots: 3× `parser/expr_meta_kind_*`; format round-trips; infer test
- [x] DISCOVERED QUIRK (pre-existing): `echo` cannot be used as a fn name —
      parse error; not in the keyword list, needs investigation (separate fix)

## F3 — tagged-call sugar
- [x] Parser: string/multiline literal immediately after a plain identifier or
      `a.b` access ⇒ call with one arg (`is_tagged` flag on the call node;
      interpolation inside the tagged string works). NOTE V1 limits: not after
      call results (`f(1) "x"` stays an error) and not in pipeline rhs position
- [x] Formatter: `is_tagged` single-string calls round-trip without parens
- [x] Snapshots: `parser/tagged_call_{single_line_string,multiline_string,method_receiver}`,
      format round-trips (incl. interpolated multiline); 58 existing snapshots
      regenerated (new `is_tagged` field in call JSON)

## F4 — unevaluated passing + `std.syntax` + scope snapshot
- [x] Capture: `inferFnDecl` registers expr params (`env.fnExprParams`); call sites
      run `captureExprArg` — arg unifies against the *inner* `T` of `expr T`
      (typed in caller), V1 literal rule enforced (must be literal string; vars
      → custom TypeError), capture stored in `env.exprCaptures` keyed by call
      loc with `{node (untyped, unevaluated), text?, multiline, opening loc,
      modulePath, scope}`. NOTE: lexer stamps multiline literals with their
      *closing* line — capture recovers the opening line by newline count
      (`${…}` holes assumed single-line in V1); spread-arg calls keep ordinary
      unification (templates + spread unsupported V1)
- [x] `libs/std/src/syntax.d.bp` (new prelude module; wired in build.zig +
      prelude.zig + registerStdlib): `Span`, `Part{Text,Interp}`, `BindingKind`,
      `Binding`. NOTE deviations from spec sketch: named variant fields
      (language has no positional ones), `i32` not `int` (constraint category,
      not a type)
- [x] Extensions on `expr` (`text`, `parts`, `lookup`, `fail`, `failAt`) +
      `Binding.ref()` — resolved by `inferTemplateMethod` like the
      `@Result`/`@Option` builtins (NOT extension-dispatch blocks; consistent
      with the stdlib method idiom), recorded in `env.templateLowerings`
      (loc-keyed) for F6; `fail`/`failAt` return a fresh var (bottom)
- [x] Scope snapshot V1: `buildScopeSnapshot` in `inferProgram*` → new
      `comptime/template.zig` `ScopeSnapshot` (top-level decls + imports,
      decl order, `toJsonAlloc` serializable handle); import kinds derived
      from the bound type (fn vs val). NOTE: lives in `template.zig`, not
      `snapshot.zig` (that file is test-snapshot infra)
- [x] `fail`/`failAt`: `template.failDiagnostic` + `mapSpanToLoc` — diagnostic
      points inside the caller's `"""…"""` (line derived from span.start when
      text is contiguous; line-based fallback with holes)
- [x] Snapshots/tests (`tests/templates.zig`): capture (plain + multiline-with-
      hole), `lookup` hit/miss + JSON handle, 6 lowerings typecheck,
      `comptime/templates/fail_span_in_template`, 2 error snaps (non-literal
      arg V1, caller-side inner-T mismatch), pipeline snap ×4 runtimes

## F5 — `expr { … }` literal + composition + lifting
- [x] Parser: new token `${` (`dollarLeftBrace` — `$` was free in code position);
      `expr { … }` via exact `expr`+`{` juxtaposition in expression position
      (contextual — `val expr = 1; expr + 2` keeps working); both are
      `Expr.comptime_` kinds (`exprLiteral { body }`, `splice: *Expr`). NOTE
      V1 limit: a splice is a *primary* — `${b.ref()}(args)` (call on splice)
      does not parse; bind it first (`val f = …` at expansion handles the
      canonical html case in F6)
- [x] Infer: literal types as `expr<T>` of the trailing expression, body
      inferred in the *defining* scope (hygiene by provenance — V1 holds by
      construction; cross-module two-scope proof lands with F6 expansion);
      splice requires an `expr U` operand and types as `U`; splice outside a
      literal → custom TypeError (`env.exprLiteralDepth`)
- [ ] Value lifting: comptime value of `T` coerces to `expr T` — DEFERRED to
      F6: pre-expansion there is no unification point (fn returns are not
      unified against declared types today), so lifting is an expansion-time
      coercion, not a type rule
- [x] `Binding.ref()` splices inside literals typecheck (`expr { ${b.ref()} }`);
      actual reference splicing into the caller's scope is the F6 expansion
- [x] Codegen ×2 (commonJS, erlang): `.exprLiteral/.splice => unreachable`
      guards (comptime-only; other backends use `else`); transform/specialize
      walkers recurse the new kinds
- [x] Snapshots: 3× `parser/expr_literal_*`, format round-trip with splice,
      infer ok (compose + ref), 3× error snaps (splice outside literal,
      splice of non-expr, unbound name in defining scope = hygiene V1);
      `comptime/value_lifting` + full `hygiene_two_scopes` move to F6

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
