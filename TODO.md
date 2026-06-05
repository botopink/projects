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
- [x] `libs/std/src/syntax.bp` (new prelude module; wired in build.zig +
      prelude.zig + registerStdlib): `Span`, `Part{Text,Interp}`, `BindingKind`,
      `Binding`. NOTE deviations from spec sketch: named variant fields
      (language has no positional ones), `i32` not `int` (constraint category,
      not a type)
- [x] Extensions on `expr` (`text`, `parts`, `lookup`, `fail`, `failAt`) +
      `Binding.ref()` — resolved by `inferTemplateMethod` like the
      `@Result`/`@Option` builtins (NOT extension-dispatch blocks; consistent
      with the stdlib method idiom), recorded in `env.templateLowerings`
      (loc-keyed) for F6; `fail`/`failAt` return a fresh var (bottom)
- [x] Second-layer surface (user feedback, post-F6): `Source` (declaration
      position) + `Context` (source/text/shape) structs in std.syntax;
      `source()`/`context()`/`bindings()` extensions expose provenance and
      the enumerable origin scope; `build(source) -> expr` parses generated
      text into code in the receiver's origin scope (the DSL "emit" path —
      `expr { … }` stays for fixed patterns with holes);
      `template.contextJsonAlloc` serializes the whole handle for the
      F6-full runtime; docs examples de-emphasize the no-op
      `return expr { ${template} }` in favor of `return template;`
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
- [x] Expansion driver (V1) — NOTE deviation from spec: lives in *inference*
      (`expandTemplateCall` in inferCallExpr), not the transform pass — that is
      where the env exists for splice + re-check; the transform pass only
      substitutes the untyped AST from `env.templateExpansions` (loc-keyed,
      same idiom as method/dispatch lowerings) and drops template fns
      (`-> expr [T]` decls are comptime-only: never specialized, never emitted)
- [x] V1-expandable bodies: `return <expr param>` (identity splice),
      `return expr { … }` with a whole-body `${param}` hole, or any splice-free
      expression (value lifting — covers `return 8080` / `return expr { 42 }`);
      anything richer (template-method bodies, control flow, partial-splice
      substitution needing deep copy) → clear TypeError pointing at F6-full
- [x] Bounded `-> expr T`: expansion re-inferred in the caller's env and
      unified against `T`; the call types as the expansion (transparent —
      `val c = html """…"""` is `string`, not `expr<string>`)
- [x] Bare `-> expr`: the shared ret var is left untouched; each call site
      reveals the expansion's own type (`answer()` → i32; `n + 1` checks)
- [ ] F6-full: runtime-backed evaluation of template bodies (text/parts/
      lookup/fail via the comptime eval runtime, serialized CapturedExpr +
      scope handle), partial splice substitution (deep copy), cross-module
      template fns (registry only exports types today — imported template
      calls don't expand), `${…}` hole loc mapping (still slice-relative)
- [ ] Memoize by hash(template text + used-binding signatures) — V1 expansion
      is pure substitution (loc-keying dedupes per site); memoization becomes
      meaningful with the runtime-backed evaluator
- [x] End-to-end codegen snapshots: `codegen/*/template_end_to_end_*` ×4
      backends ×2 (bounded html expansion — runs, prints `<p>world</p>`;
      bare + lifting `port() + 1`); typed-AST pipeline snaps ×4 regenerated
- [x] Snapshots: bounded-ok/bare-reveals/lifting as zig infer tests,
      `splice_bound_violation` + `template_body_not_expandable` error snaps
- [x] DISCOVERED GAP: typescript `.d.ts` emitter still declares template fns
      and renders `TypeRef.expr` params as empty (`html(template: )`) — the
      typedef generator needs the same template-fn drop + an `expr` rendering
      (separate fix)

## F7 — canonical examples + docs
- [ ] `examples/jonhstar/` — minimal `html` component lib — BLOCKED on F6-full
      (needs runtime-backed template bodies + cross-module template fns)
- [ ] `examples/yamlconf/` — `yaml` config lib + structural-fit demo — BLOCKED
      on F6-full (needs comptime yaml parsing + anonymous record lifting)
- [x] docs.md (language reference): new `String Interpolation` and
      `Expr Templates` sections — meta-kinds, tagged calls, capture rule,
      `std.syntax` surface, `expr { … }`/splices, expansion (bounded/bare/
      lifting), hygiene & provenance, V1 limits
- [x] `Touches docs:` — parser/AGENTS.md (exprs.zig row) +
      parser/examples.md (expr-templates section), comptime/AGENTS.md
      (F4/F5/F6 sections), codegen/AGENTS.md (template rule + .d.ts gap),
      libs/std/src/AGENTS.md (syntax.bp)

## F8 — redesign: `@Expr<E>` builtin type (user decision, 2026-06-05)

> Supersedes the F2/F5 *surface*: there is **no `expr` keyword**. `@Expr<E>`
> (builtin generic, like `@Result`) marks types; code values are constructed
> only explicitly. The F4/F6 machinery (capture, scope snapshot, methods,
> expansion driver) carries over unchanged under the new encoding.

- [x] `TypeRef.expr` removed; `@Expr<E>` / bare `@Expr` parse as the ordinary
      builtin generic (`<…>` made optional for builtins); encoded as named
      type `"Expr"` (bare resolves a fresh arg). `TypeRef.isExprType()` helper
- [x] `expr` keyword gone from BOTH positions: type form (F2) and the
      `expr { … }` literal + `${…}` code splice + `dollarLeftBrace` token
      (F5) — `${…}` lives only inside string literals again; `expr` is a
      plain identifier everywhere
- [x] No implicit value lifting — construction is explicit via new builtins:
      `@expr(value)` (lift; result `@Expr<typeof value>`) and `@code(text)`
      (parse source text; result `@Expr<fresh>`), both only valid inside a
      template fn (`env.inTemplateFn`); `comptime` requirement for `@Expr`
      params is now a semantic check in `inferFnDecl` (parser keeps it only
      for the `type` meta-kind)
- [x] `interface Expr<E>` declared in std.syntax (per user sketch, incl.
      `val value: E` member — interface bodies accept val fields) typing the
      comptime surface; `value()` added to TemplateOp/inferTemplateMethod
- [x] V1 expansion driver re-targeted: `return <@Expr param>` |
      `return @expr(E)` | `return @code("…")` (sub-parsed at expansion);
      formatter renders bare builtins without `<>`
- [x] Tests/snapshots migrated (~30 files); orphans removed; docs.md +
      parser examples + AGENTS ×4 rewritten
- [x] DISCOVERED GAPS (pre-existing, separate fixes): nested generics
      `A<B<C>>` lex `>>` as shift; array suffix `[]` does not apply to
      `@X<…>` builtins; `.d.ts` renders bare builtin as `Expr<>`
