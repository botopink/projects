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

- [x] `TypeRef.expr` removed; `@Expr<E>` parses as the ordinary builtin
      generic, encoded as named type `"Expr"`. `TypeRef.isExprType()` helper
- [x] Generic parameter is MANDATORY (user decision): bare `@Expr` is a parse
      error (builtins require `<…>`); a result type only the expansion knows
      is an ordinary fn generic — `fn yaml<T>(…) -> @Expr<T>` (unconstrained
      `T` = revealed per call site; the driver skips the bound unify when the
      bound derefs to a type var). `interface Expr<E>.build` and
      `Binding.ref` are generic over their result (`build<R> -> @Expr<R>`);
      `Part.Interp` holes are `@Expr<string>` (string-template holes)
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

---

# Task: stdlib-gleam

**Branch**: task/stdlib-gleam (worktree `.tasks/stdlib-gleam/`)
**Spec**: `tasks/v0.beta.2/specs/stdlib-gleam.md`
**Depends on**: nothing

**Goal**: grow `libs/std` from 4 declaration files into a Gleam-style module set
(`list`, `dict`, `set`, `option`, `result`, `order`, `bool`, `pair`, `int`, `float`,
`string`, `string_builder`, `iterator`, `function`, `io`), callable as
`import {list}; list.map(xs, f)` or via pipeline `xs |> list.map(f)`.

**Architecture (working assumption — hybrid, flippable):**
- Pure-logic modules → real `.bp` implementations (compile once, all backends):
  `list`, `dict`, `set`, `option`, `result`, `order`, `pair`, `bool`, `iterator`, `function`.
- Primitive/host-backed → declarations + externals (`.d.bp`, codegen/FFI per target):
  `int`, `float`, `string`, `io`, `bit_array`.

**Files**: `libs/std/src/*.bp`, `libs/std/src/*.d.bp` (`.bp`-only — no Zig in libs/std);
loader relocated `libs/std/src/prelude.zig` → `modules/compiler-core/src/comptime/stdlib/prelude.zig`
(+ `build.zig`); F1 (`@external`) touches `modules/compiler-core/src/{lexer,parser,ast,comptime,codegen}/*`.

**Docs to update**: `libs/std/AGENTS.md`, `libs/std/docs.md`, `libs/std/src/AGENTS.md`,
`libs/std/src/examples.md`, root `docs.md` (language reference: `@external`),
`modules/compiler-core/src/codegen/AGENTS.md`.

---

## F0 — module layout + wiring + conventions
- [x] Relocate embed/loader glue out of `libs/std/`: move `prelude.zig` to
      `modules/compiler-core/src/comptime/stdlib/prelude.zig` (next to its consumer —
      `comptime` calls `registerStdlib`); `libs/std/src/` keeps only `.bp`/`.d.bp`
- [x] Update `build.zig` for the relocated `std_prelude` Zig module path
- [x] Relocated `prelude.zig` `@embedFile`s each `.bp`/`.d.bp` — NOTE: relative
      paths escaping the module root are rejected by Zig (`embed of file outside
      package path`); instead each file is an anonymous import declared in
      `build.zig` (`std_bp_files` → `addAnonymousImport`), embedded by name
- [x] Update `libs/std/AGENTS.md` + `docs.md` (+ `src/AGENTS.md`, `src/docs.md`,
      `libs/AGENTS.md`, `modules/docs.md`, new `comptime/stdlib/AGENTS.md`,
      `comptime/AGENTS.md` tree): `src/` is `.bp`-only; loader lives in compiler-core
- [x] Calling convention DECIDED at F2: qualified `list.map(xs, f)` via real
      `"std"` package namespaces (`import {list} from "std"`); pipeline
      `xs |> list.map(f)` composes on top once qualified calls work

## F1 — annotation syntax `@[…]` + `external` builtin (FFI primitive; prerequisite for decl modules)
`@external` is NOT a parser keyword — it is a builtin function declared in
`builtins.d.bp`, invoked inside generic annotation syntax `@[ … ]` above a declaration.
- [x] Builtins: declared in `builtins.d.bp` (documentation — the file is not yet
      embedded; validation is programmatic in `comptime/infer.zig`):
      `enum Target { node, typescript, erlang, beam, wasm }` +
      `fn external(target: Target, module: string, symbol: string)`
- [x] Lexer/parser: annotation block `@[ <builtin-call> ("," <builtin-call>)* ]`
      (no lexer change needed — `.at` + `.leftSquareBracket`; `parseAnnotations`
      handles both `#[…]` and `@[…]`; `skipAnnotationsLookaheadFrom` + top-level
      dispatch extended; `parseFnBody` allows bodyless fn when `external` present)
- [x] AST: reuses existing `decl.annotations: []Annotation { name, args }`;
      added `FnDecl.isExternal()` / `FnDecl.externalFor(target)` + `ast.ExternalRef`
- [x] Inference: `validateExternalAnnotation` (arity 3, target ∈ Target,
      module/symbol string literals); bodyless external fn typed from signature
- [x] Codegen: erlang lowers calls to remote `module:symbol(Args)` (decl emits
      nothing, excluded from export); commonJS emits
      `const { symbol: name } = require("module")` (+ `exports.name` for pub);
      no matching target → `error.MissingExternalTarget` at the call site;
      beam/wasm untouched for now (external fn emits as empty local fn — F6 scope)
- [x] Tests: parser `annotation_block_at_bracket` (+ decl-then-next-decl),
      comptime `external_builtin_typechecks_args` + `external_wrong_arity` +
      `external_fn_no_body_typechecks`, codegen `external_call_emits_module_symbol`
      + `external_import_binds_symbol` (all 4 targets snapshotted)

## F2 — `option` + `result` (effect types over built-ins)
> **DECIDED (2026-06-04)** — real namespaces, imported from the `"std"` package:
>
> ```bp
> import {list, option} from "std";   // cross-package: std exports its modules
> val y = option.map(x, { v -> v + 1 });
> ```
>
> - `from "std"` marks the **package boundary** — it is the only way to reach
>   stdlib modules (exporting from outside the package).
> - Bare `import {x};` stays **same-package only** (project-root resolution);
>   it never resolves stdlib modules.
> - Inference gains a module→exports table: importing `option` binds a module
>   namespace whose members resolve to that module's `pub` fns.

### F2a — `"std"` package namespacing (mechanism)
- [ ] Load stdlib impl modules (`option.bp`, `result.bp`, …) per module: parse +
      infer each into its own exports table (`std` package registry), instead of
      flattening into the global env
- [ ] `import {option} from "std"` → bind `option` as a module-namespace symbol
      backed by that table; unknown module name → clear type error
- [ ] Inference: qualified call `option.map(args)` where the receiver is an
      imported std module → look up `map` in the module's exports, infer as a
      direct fn call (error when missing/not-pub)
- [ ] Codegen commonJS: emit imported std modules to `out/std/<mod>.js` and lower
      `option.map(args)` → `require` of that module + call
- [ ] Codegen erlang: emit `out/std/<mod>.erl`; `option.map(args)` → remote call
      `option:map(Args)`
- [ ] Bare `import {x};` unchanged (root resolution only); `from "std"` with a
      non-module symbol → error
- [ ] Tests: comptime `std_import_binds_namespace` + `std_member_missing_errors`;
      codegen `std_qualified_call_lowers` (node + erlang); cli run E2E

- [ ] `option.bp`: `map`, `then` (flat_map), `unwrap`, `or`, `is_some`, `is_none`, `to_result`
- [ ] `result.bp`: `map`, `map_error`, `then`, `unwrap`, `unwrap_error`, `or`, `is_ok`, `from_option`
- Note: build on the EXISTING `@Option`/`@Result` method work (`map`/`flatMap`/`unwrapOr`
  from the stdlib-result task) — extend, don't duplicate.

## F3 — `order` + `bool` + `pair` (small foundations)
- [ ] `order.bp`: `enum Order { Lt, Eq, Gt }` + `reverse`, `negate`, `to_int`
- [ ] `bool.bp`: `negate`, `and`, `or`, `to_string`, `guard`
- [ ] `pair.bp`: `first`, `second`, `map_first`, `map_second`, `swap`

## F4 — `list` (the core module, over `Array<T>`)
- [ ] Folds: `fold`, `fold_right`, `reduce`
- [ ] Transform: `map`, `index_map`, `filter`, `filter_map`, `flat_map`, `flatten`
- [ ] Query: `length`, `is_empty`, `contains`, `find`, `all`, `any`, `count`
- [ ] Build/slice: `append`, `prepend`, `reverse`, `take`, `drop`, `first`, `rest`, `range`
- [ ] Combine: `zip`, `unzip`, `intersperse`, `sort` (with `order`)
- Note: confirm list patterns `[]` / `[x, ..rest]` are accepted by the parser
  (used in every impl).

## F5 — `dict` + `set`
- [ ] `dict.bp`: `new`, `get`, `insert`, `delete`, `keys`, `values`, `size`, `merge`, `fold`, `map_values`
- [ ] `set.bp`: `new`, `insert`, `contains`, `delete`, `union`, `intersection`, `to_list` (on top of `dict`)

## F6 — `int` + `float` (declarations + externals, via F1 `@[external(…)]`)
- [ ] `int.d.bp`: `parse`, `to_float`, `to_string`, `absolute_value`, `min`, `max`, `clamp`, `power`, `is_even`
- [ ] `float.d.bp`: `parse`, `round`, `floor`, `ceiling`, `truncate`, `to_string`, `power`, `square_root`

## F7 — `string` (+ `string_builder`, via F1 `@[external(…)]`)
- [ ] Extend `string.d.bp` to Gleam's surface: `length`, `reverse`, `replace`, `split`,
      `join`, `pad_left`, `pad_right`, `slice`, `contains`, `starts_with`, `to_graphemes`
- [ ] `string_builder.bp`: `new`, `append`, `from_strings`, `to_string` (efficient concat)

## F8 — `iterator` (lazy sequences)
- [ ] `iterator.bp`: `from_list`, `map`, `filter`, `take`, `fold`, `to_list`, `range`, `repeat`
- [ ] Build on botopink's `@Iterator<_>` / `*fn` generators

## F9 — `function` + `io` (`io` via F1 `@[external(…)]`)
- [ ] `function.bp`: `identity`, `compose`, `flip`, `const`
- [ ] `io.d.bp`: `print`, `println`, `debug` (host-backed)

## F10 — extended modules (optional)
- [ ] `bit_array`, `uri`, `regexp`, `dynamic`, `queue` — scope per demand

---

## Test scenarios

```
comptime ---- option_map_some_none           (inference: ?T threads through)
comptime ---- result_then_chains_error
comptime ---- list_fold_map_filter_infer
comptime ---- list_sort_with_order
comptime ---- dict_get_returns_option
comptime ---- iterator_range_map_to_list
codegen/node ---- list_map_filter            (CommonJS output)
codegen/erlang ---- list_fold                 (Erlang output)
codegen/beam ---- option_unwrap               (BEAM output)
codegen/wasm ---- int_clamp                   (WAT output / external)
parser ---- module_qualified_call list.map(xs, f)
parser ---- annotation_block_at_bracket            (@[ external(…), external(…) ] over a decl)
comptime ---- external_builtin_typechecks_args     (external(target, module, symbol) vs builtins.d.bp)
comptime ---- external_fn_no_body_typechecks
codegen/erlang ---- external_call_emits_module_symbol  (string:length/1)
codegen/node ---- external_call_emits_import           (import {string_length})
```

## Notes
- Architecture is the one open decision. Hybrid is the assumption; declarations-only
  fallback = turn every `.bp` impl into a `.d.bp` signature + push bodies into codegen.
- Each new file MUST get a matching `@embedFile` in the relocated `prelude.zig`
  (under `modules/compiler-core/src/comptime/stdlib/`) or inference won't see it.
- Keep signatures additive/stable — renames churn every codegen/comptime snapshot.
- Update the matching `AGENTS.md` for every code/layout change in the same commit.
