# prim-op-annotation — extend #[@external] to cover every primitive-method shape

**Slug**: prim-op-annotation
**Depends on**: Frente A §A keystone (the §A5 annotation-driven refactor must
  be in place — `tryEmitPrimAnnotation` exists and currently consumes
  `#[@external(target, "mod", "sym(args, self)")]`); coordinates with
  Frente A §A6 (this spec is what §A6 hands the remaining switch arms off
  to, deleting the "irreducible allow-list" carve-out)
**Files**: `modules/compiler-core/src/parser/decls.zig`
  (`parseExternalCallTemplate` extension) ·
  `modules/compiler-core/src/ast.zig` (richer `ExternalCallTemplate` AST) ·
  `modules/compiler-core/src/codegen/{erlang,beam_asm,commonJS,typescript}.zig`
  (`tryEmitPrimAnnotation` consumers + the `emitPrimMethod` switch
  deletions) · `libs/std/src/primitives.d.bp` (every prim method gains its
  full per-backend annotation set) · `libs/std/AGENTS.md` ·
  `modules/compiler-core/src/codegen/AGENTS.md` ·
  `modules/compiler-core/src/comptime/AGENTS.md` ·
  `tests/codegen/prim_op_templates.zig` (new)
**Touches docs**: `libs/std/AGENTS.md` (§"External annotation vocabulary"
  expanded) · `modules/compiler-core/AGENTS.md` (`comptime/` + `codegen/`
  subsections cite this spec) · `CHANGELOG.md`
**Status**: pending

## Background

Frente A §A's keystone refactor (v0.beta.16 §A1–§A5, last commit
`0a37fbe`) made every backend's primitive-method lowering consult the
`#[@external(target, "mod", "sym(args, self)")]` annotations on
`primitives.d.bp` instead of hardcoded switches — for the cases that
reduce to a bare `mod:sym(args)` shape. After A5, the surviving
hardcoded arms in `codegen/erlang.zig`'s `emitPrimMethod` (mirrored in
`beam_asm.zig` + partly in `commonJS.zig`) are the ones the current
two-arg `#[@external]` grammar **cannot express**:

```zig
//// these still live in the switch because the current annotation
//// vocabulary doesn't cover their shapes:
if (eq(u8, callee, "append"))    → "($self ++ [$0])"                  // binary op
if (eq(u8, callee, "prepend"))   → "[$0 | $self]"                     // list-cons
if (eq(u8, callee, "push"))      → "($self ++ [$0])"                  // binary op
if (eq(u8, callee, "contains"))  → "lists:member($0, $self)"          // arg-order swap
if (eq(u8, callee, "indexOf"))   → inline recursive fun               // inline fun
if (eq(u8, callee, "len/...") )  → "length($self)"                    // BIF, no module
if (eq(u8, callee, "isEmpty"))   → "($self =:= [])"                   // operator + literal
if (eq(u8, callee, "slice"))     → arity 1 vs 2 branch with arithmetic
if (eq(u8, callee, "join"))      → inline fun with per-element stringify
if (eq(u8, callee, "at"))        → inline fun with bounds check + lists:nth(I+1, …)
// String:
if (eq(u8, callee, "slice"))     → arity-branched string:slice with arithmetic
if (eq(u8, callee, "contains"))  → "(string:find($self, $0) =/= nomatch)"
if (eq(u8, callee, "startsWith"))→ "(string:prefix($self, $0) =/= nomatch)"
if (eq(u8, callee, "split"))     → "string:split($self, $0, all)"     // trailing literal
// Bool:
if (eq(u8, callee, "negate"))    → "(not $self)"                      // unary op
```

Frente A §A6 currently has two options: either author each remaining
method's annotation **or** document an "irreducible allow-list" for the
ops that don't fit `mod:sym(args)`. This spec is the third path — extend
the annotation grammar so every method **can** be authored, deleting the
allow-list entirely.

## Premise

`primitives.d.bp` is the single source of truth for primitive-method
lowering. After this spec lands:

- Every primitive method has an `#[@external(<target>, "<template>")]`
  per backend it supports.
- `emitPrimMethod` in every codegen carries **zero** hardcoded `if (eq(
  u8, callee, …))` arms — only the annotation-driven path remains.
- Adding a new primitive method on N backends is N lines in
  `primitives.d.bp`, never any `.zig` edit.

## Target template grammar

The current `#[@external(erlang, "mod", "sym(args, self)")]` form is the
2-string short for the common `mod:sym(args)` case. The general form is a
**single template string** with substitution markers:

| Marker | Meaning | Resolution time |
|---|---|---|
| `$self` | The receiver expression (already evaluated by the caller) | render-time |
| `$0`, `$1`, … `$N` | Positional argument expression at index N | render-time |
| `$argc` | The number of arguments at the call site | comptime (integer) |
| `$stringify($expr)` | Target-idiomatic stringification of `$expr` | render-time |
| Anything else | Literal target syntax — erlang tokens, JS tokens, beam asm fragments, wat instructions | passthrough |

The 2-string form `#[@external(erlang, "mod", "sym(args, self)")]` becomes
sugar for the canonical 1-string form
`#[@external(erlang, "mod:sym($0, $self)")]` (the existing parser already
recognises the older surface — keep it as legacy sugar).

### Arity branching

For methods whose lowering depends on `$argc` (the obvious case is
`slice(start)` vs `slice(start, end)`), the template accepts an
**arity-match** form:

```bp
#[@external(erlang,
  when($argc == 1): "lists:nthtail($0, $self)",
  when($argc == 2): "lists:sublist($self, $0 + 1, $1 - $0)")]
fn slice(self, start: i32, end: i32 = $self.length) -> Self
```

Operationally: at render time, the emitter selects the first matching
`when(...)` clause and renders its template. A `when($argc == ...)` with
no match emits a comptime error (`prim-op-no-arity-match`).

### Multi-line inline-fun templates

Inline-fun templates (the `indexOf`/`at`/`join` shapes) get a separate
spelling — the `#[@external]` second arg accepts a Zig-style multi-line
raw string `"""…"""` so the host syntax stays readable:

```bp
#[@external(erlang, """
    (fun(__L, __X) ->
        __Find = fun __F(__I, [__H | __T]) ->
            case (__H =:= __X) of
                true -> __I;
                false -> __F(__I + 1, __T)
            end;
            __F(_, []) -> -1
        end,
        __Find(0, __L)
    end)($self, $0)
""")]
fn indexOf(self, x: T) -> i32
```

The raw-string body is rendered into the call site verbatim, with `$self`
/ `$0..N` / `$stringify(...)` substituted. Whitespace inside the body is
preserved; the emitter adds no extra leading/trailing newlines beyond what
the template carries. Nested-paren / nested-string handling is the target
language's responsibility — the template parser only looks for the
substitution markers.

### `$stringify` primitive

Several inline ops need to coerce mixed-type elements to text (`join`'s
per-element stringification, future `toString` cousins). `$stringify($expr)`
expands per backend:

| Target | Expansion of `$stringify($e)` |
|---|---|
| `erlang` | `(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end)($e)` |
| `beam_asm` | same as erlang (compiles to the equivalent BEAM op sequence) |
| `commonJS` (node) | `String($e)` |
| `typescript` | n/a (no body emission) |
| `wat` | not supported — using `$stringify` on a wasm target reds with `prim-op-stringify-unsupported` (record the gap; this spec doesn't ship a wasm stringifier) |

The backend reads its own `$stringify` expansion from a per-target table
in `codegen/AGENTS.md`, kept short and explicit.

### Whitespace + comments inside the template

Templates may contain arbitrary whitespace including newlines (inside the
`"""…"""` form). The parser strips a single leading newline immediately
after `"""` and a single trailing newline immediately before `"""` (the
typical "indent-the-block" convention); inner indentation is preserved.

The template body **does not** support botopink `//` comments —
everything inside is the target language. If a user wants a comment
inline with the host op, they use the host language's syntax (`%` in
erlang, `//` in JS, etc).

## Migration table — every current switch arm → annotation

`Array` (defined on `interface Array<T>` in `primitives.d.bp`):

| Method | erlang annotation | commonJS annotation (node) |
|---|---|---|
| `append(x)` | `"($self ++ [$0])"` | `"$self.concat([$0])"` |
| `prepend(x)` | `"[$0 \| $self]"` | `"[$0].concat($self)"` |
| `push(x)` | `"($self ++ [$0])"` | (same as native — already annotation-driven via §A5) |
| `contains(x)` | `"lists:member($0, $self)"` | `"$self.includes($0)"` |
| `indexOf(x)` | (multi-line inline fun — see §"Multi-line inline-fun templates" above) | `"$self.indexOf($0)"` |
| `len()` / `length()` / `size()` | `"length($self)"` | `"$self.length"` (property, see §"Property templates" below) |
| `isEmpty()` | `"($self =:= [])"` | `"$self.length === 0"` |
| `slice(start)` | `when($argc == 1): "lists:nthtail($0, $self)"` | `when($argc == 1): "$self.slice($0)"` |
| `slice(start, end)` | `when($argc == 2): "lists:sublist($self, $0 + 1, $1 - $0)"` | `when($argc == 2): "$self.slice($0, $1)"` |
| `join(sep)` | (multi-line inline fun using `$stringify`) | `"$self.map(String).join($0)"` |
| `at(i)` | (multi-line inline fun with bounds check) | `"($0 >= 0 && $0 < $self.length ? $self[$0] : undefined)"` |

`String` (defined on `interface String` in `primitives.d.bp`):

| Method | erlang annotation | commonJS annotation (node) |
|---|---|---|
| `slice(start)` | `when($argc == 1): "string:slice($self, $0)"` | `when($argc == 1): "$self.slice($0)"` |
| `slice(start, end)` | `when($argc == 2): "string:slice($self, $0, $1 - $0)"` | `when($argc == 2): "$self.slice($0, $1)"` |
| `contains(needle)` | `"(string:find($self, $0) =/= nomatch)"` | `"$self.includes($0)"` |
| `startsWith(prefix)` | `"(string:prefix($self, $0) =/= nomatch)"` | `"$self.startsWith($0)"` |
| `split(sep)` | `"string:split($self, $0, all)"` | `"$self.split($0)"` |

`Bool`:

| Method | erlang annotation | commonJS annotation (node) |
|---|---|---|
| `negate()` | `"(not $self)"` | `"!$self"` |

`Int` / `Float`:

| Method | (none today — empty switch arms) |

### Property templates

`Array.length` (called as `arr.length` without parens — a property, not a
method-with-empty-args) is a special case the JS backend already treats
as `$self.length` (no method invocation). The annotation form for a
**property** is `#[@externalProperty(target, "$self.length")]` — the
property declaration in `primitives.d.bp` is `val length: i32`. Existing
property-handling is unchanged here; the new annotation just makes the
lowering explicit on JS where today an `isNativeProperty` table holds the
list.

(The §A5 spec already handled `val`-properties on JS; this section
documents how the same vocabulary continues to work after §A6 deletes the
remaining method switches.)

## Examples — before / after

### `Array.contains`

**Before** (in `primitives.d.bp`):

```bp
fn contains(self, x: T) -> bool;
```

**Before** (in `codegen/erlang.zig`):

```zig
if (eq(u8, callee, "contains")) {
    try this.w("lists:member(");
    try this.emitArg(cc, 0);
    try this.w(", ");
    try this.emitExpr(recv.*);
    try this.w(")");
    return;
}
```

**After** (in `primitives.d.bp`):

```bp
#[@external(erlang, "lists:member($0, $self)"),
  @external(beam,   "lists:member($0, $self)"),
  @external(node,   "$self.includes($0)")]
fn contains(self, x: T) -> bool;
```

**After** (in `codegen/erlang.zig`): the `if (eq(u8, callee, "contains"))`
arm is **deleted**; `tryEmitPrimAnnotation` reads the annotation and
emits the same bytes.

### `Array.slice` (arity branch)

**After**:

```bp
#[@external(erlang,
    when($argc == 1): "lists:nthtail($0, $self)",
    when($argc == 2): "lists:sublist($self, $0 + 1, $1 - $0)"),
  @external(beam,
    when($argc == 1): "lists:nthtail($0, $self)",
    when($argc == 2): "lists:sublist($self, $0 + 1, $1 - $0)"),
  @external(node,
    when($argc == 1): "$self.slice($0)",
    when($argc == 2): "$self.slice($0, $1)")]
fn slice(self, start: i32, end: i32 = $self.length) -> Self;
```

### `Array.indexOf` (multi-line inline fun)

**After**:

```bp
#[@external(erlang, """
    (fun(__L, __X) ->
        __Find = fun __F(__I, [__H | __T]) ->
            case (__H =:= __X) of
                true -> __I;
                false -> __F(__I + 1, __T)
            end;
            __F(_, []) -> -1
        end,
        __Find(0, __L)
    end)($self, $0)
"""),
  @external(beam, """
    (fun(__L, __X) ->
        __Find = fun __F(__I, [__H | __T]) ->
            case (__H =:= __X) of
                true -> __I;
                false -> __F(__I + 1, __T)
            end;
            __F(_, []) -> -1
        end,
        __Find(0, __L)
    end)($self, $0)
"""),
  @external(node, "$self.indexOf($0)")]
fn indexOf(self, x: T) -> i32;
```

### `Array.join` (inline fun + `$stringify`)

**After**:

```bp
#[@external(erlang, """
    iolist_to_binary(lists:join($0, lists:map(fun(__E) -> $stringify(__E) end, $self)))
"""),
  @external(beam,   /* same as erlang */),
  @external(node,   "$self.map(String).join($0)")]
fn join(self, sep: string) -> string;
```

## Adjacent surfaces — the same treatment applies

A grep of `codegen/{erlang,beam_asm,wat}.zig` shows two **more** families
of hardcoded `mem.eql(callee, "...")` switch arms that have the exact same
shape as `emitPrimMethod` (cross-checked 2026-06-13 against the current
HEAD of `task/frente-a-compiler`'s base):

### Family 2 — `emitResultOptionOp` synthetic ops

`@Result<R, E>` / `@Option<T>` runtime ops are lowered today by a
parallel switch in each backend (`erlang.zig:1580`, `beam_asm.zig:~2576`,
`wat.zig:~1417`). Nine synthetic callees the compiler injects at type-
check time, each with a fixed lowering shape per backend:

| Synthetic callee | erlang shape | commonJS shape (node) | beam shape | wat shape |
|---|---|---|---|---|
| `__bp_ok($v)` | `{ok, $v}` | `({ok: $v})` | `put_tuple2 {atom,ok} $v` | record tag 0 + slot |
| `__bp_error($e)` | `{error, $e}` | `({error: $e})` | `put_tuple2 {atom,error} $e` | record tag 1 + slot |
| `__bp_result_map($r, $f)` | `(fun(R) -> case R of {ok, V} -> {ok, ($f)(V)}; _ -> R end end)($r)` | `($r.ok !== undefined ? {ok: $f($r.ok)} : $r)` | erlang-shaped inline `case` | branch on tag |
| `__bp_result_flatMap($r, $f)` | `(fun(R) -> case R of {ok, V} -> ($f)(V); _ -> R end end)($r)` | `($r.ok !== undefined ? $f($r.ok) : $r)` | similar | similar |
| `__bp_result_unwrapOr($r, $d)` | `(fun(R) -> case R of {ok, V} -> V; _ -> $d end end)($r)` | `($r.ok ?? $d)` | similar | similar |
| `__bp_result_isOk($r)` | `(fun(R) -> case R of {ok, _} -> true; _ -> false end end)($r)` | `('ok' in $r)` | tag-test | tag-test |
| `__bp_result_isError($r)` | `(fun(R) -> case R of {error, _} -> true; _ -> false end end)($r)` | `('error' in $r)` | tag-test | tag-test |
| `__bp_option_map($o, $f)` / `__bp_option_flatMap($o, $f)` | `(fun(O) -> case O of undefined -> undefined; V -> ($f)(V) end end)($o)` | `($o == null ? undefined : $f($o))` | null-test | null-test |
| `__bp_option_unwrapOr($o, $d)` | `(fun(O) -> case O of undefined -> $d; V -> V end end)($o)` | `($o ?? $d)` | null-test | null-test |

Each of these is **exactly** the multi-line-inline-fun shape §"Multi-line
inline-fun templates" above already handles. The migration is the same:
move the lowering string from the switch arm to an annotation on the
`@Result` / `@Option` runtime declarations (or, since these are
compiler-synthesised callees with no user-facing surface, to a new
`#[@runtimeOp(target, "...")]` annotation block in `builtins.d.bp`).

**Authoring location.** Today there is no user-facing `__bp_ok` etc — the
compiler synthesises the names. Two paths:

1. **Annotate the `Result` / `Option` enum methods** in `builtins.d.bp`
   (the `map` / `flatMap` / `unwrapOr` / `isOk` / `isError` lines already
   in §"@Result type" comment block become real `fn` declarations
   carrying the `#[@external(...)]` annotation). The synthetic `__bp_…`
   callees stay as the comptime-internal handle, but their lowering
   table is read from the declared method's annotation.
2. **Introduce a sibling annotation** `#[@runtimeOp(<callee>, target,
   "<template>")]` attached to a marker declaration (e.g. `enum Result`
   itself) that the comptime reads when emitting the synthetic call.

This spec picks **path 1** — it keeps `#[@external]` as the single
annotation vocabulary across both user-facing prim methods and the
synthetic Result/Option ops. The `__bp_…` mangled names become an
implementation detail of how comptime emits the call; the lowering table
lives on the `enum Result` / `Option` declaration's methods.

### Family 3 — top-level builtin calls (`@todo`, `@panic`, `@block`)

A third smaller family lives in `erlang.zig:1789–1821`,
`beam_asm.zig:2524–2543`, `wat.zig:1306–1320`. After §A5 made `@print`
annotation-driven, three siblings remain hardcoded:

| Callee | erlang shape | commonJS shape | beam shape | wat shape |
|---|---|---|---|---|
| `@todo` | `erlang:error(undef)` | `(()=>{throw new Error('todo')})()` | `call_ext erlang:error/1 undef` | `unreachable` |
| `@panic` | `erlang:error($0)` | `(()=>{throw new Error($0)})()` | `call_ext erlang:error/1 $0` | `unreachable` (after $0 is loaded for error reporting) |
| `@block($body)` | `(fun() -> $body() end)()` | `(() => $body())()` | inline fun | inline block |

Same migration shape: each `@<builtin>` already has a `declare fn` (or
should — `@todo` / `@panic` are currently parser-level keywords that
synthesise calls). Add the `#[@external(...)]` annotation set; delete
the per-backend switch arm.

`@todo` and `@panic` are declared in `libs/std/src/builtins.d.bp` as
`fn panic(message: string) noreturn` + (implicit) `@todo` — the
annotation set lands on those declarations. `@block` is a
control-flow helper currently authored as the builtin `block<T>(body:
fn() -> T) T` (which Frente A §U flagged as **unused-builtin candidate**
— if §U deletes it, this row drops out of the migration table; if §U
keeps it, this annotation table applies).

### Out of scope — `runtime.zig` and `typescript.zig`

- **`runtime.zig`** lives under `codegen/` but is **host-side**: it
  invokes `node` / `erlc` / `wasmtime` / `+from_asm` via
  `std.process.run` and captures their output. There is no per-callee
  lowering to migrate — `runtime.zig`'s `mem.eql` hits are all on
  module / target / shell-arg strings, not on op names. Out of scope.
- **`typescript.zig`** has zero `mem.eql(callee, …)` switches. It emits
  declarations (`.d.ts` decl signatures), not call sites — there is no
  prim-method-lowering layer to migrate. Out of scope. (Frente B §F's
  `@Expr<>` / `@ExprCustom<>` template-fn skip is the relevant TS work
  for v0.beta.19; that spec stands.)

### Migration cost summary

| Family | Backends | Methods / callees | Switch arms to delete |
|---|---|---|---|
| 1 — `emitPrimMethod` (prim instance methods) | erlang + beam + node | 13 (Array) + 5 (String) + 1 (Bool) = 19 | ~19 × 3 = 57 |
| 2 — `emitResultOptionOp` | erlang + beam + node + wat | 9 synthetic callees | ~9 × 4 = 36 |
| 3 — `@todo` / `@panic` / `@block` | erlang + beam + node + wat | 3 callees | ~3 × 4 = 12 |
| **Total** | | **31 user-facing + 9 synthetic** | **~105 switch arms** |

After this spec lands and §A6 / §D5 close, every backend's per-callee
switch chain shrinks to one entry: the final `// Unmapped` fallback that
emits a bare local call (kept as the safety net for any future authored
prim method whose annotation hasn't been written yet).

## Diagnostics

| # | Author wrote | Diagnostic |
|---|---|---|
| RP1 | `#[@external(erlang, "lists:member($999, $self)")]` (out-of-range `$N`) | `prim-op-arg-index-out-of-range: template references $999 but the fn has 2 args.` |
| RP2 | `#[@external(erlang, when($argc == 3): "...")]` on a fn that can never be called with 3 args | `prim-op-no-arity-match: no `when(...)` clause matched the call-site arity 1.` |
| RP3 | `$stringify($foo)` in a `wat` template | `prim-op-stringify-unsupported: target 'wat' does not support $stringify(...). Use a target with native stringification, or scope this method to non-wat backends.` |
| RP4 | `$argc` outside a `when(...)` clause (i.e. used as a literal in the template body) | `prim-op-argc-only-in-when: $argc is only valid inside a when(...) clause for arity branching.` |
| RP5 | Multi-line `"""…"""` template with an unclosed inner brace tracked by the target language | (Not detected here — passes through; target-language errors surface from the host compiler later. Documented in `codegen/AGENTS.md` as a passthrough escape hatch.) |

## Steps

### F0 — extend the AST + parser
- [ ] `ast.zig`: `ExternalCallTemplate` gains a `kind` field that
      distinguishes:
      - `legacy_2_arg` — the existing `#[@external(target, "mod", "sym(args, self)")]` (kept as sugar)
      - `template` — single-string body with `$self` / `$N` / `$stringify(...)`
      - `arity_branch` — list of `when($argc == N): "template"` clauses
- [ ] `parser/decls.zig`: `parseExternalCallTemplate` extension:
      - Accept the new single-string form: `#[@external(<target>, "<template>")]`.
      - Accept `"""…"""` raw strings (Zig-style triple-quote, the existing
        sublanguage path already tokenises these — reuse).
      - Accept `when($argc == N): "<template>"` clauses (comma-separated
        inside the same `#[@external(...)]`).
      - The legacy 2-arg form keeps parsing exactly as today.

### F1 — `tryEmitPrimAnnotation` extended
- [ ] In each of `codegen/{erlang,beam_asm,commonJS,typescript}.zig`,
      extend the annotation reader:
      - For `legacy_2_arg`: emit `mod:sym($0, $self)` (the existing path).
      - For `template`: render the body, substituting `$self`,
        `$0..$argc-1`, and per-target `$stringify($expr)`.
      - For `arity_branch`: select the first matching `when($argc == N)`;
        render its body. No match ⇒ RP2.
- [ ] Shared rendering routine in
      `comptime/primOpTemplate.zig` (new) — takes the template AST + the
      call's `recv` + `args` + a per-target `stringifier` callback;
      returns the rendered bytes. Backends call into this with their own
      stringifier.

### F2 — migrate Family 1 switch arms (`emitPrimMethod`)
- [ ] For each row in the §"Migration table" above:
      - [ ] Author the annotation in `primitives.d.bp`.
      - [ ] Run `zig build test` and diff snapshots — must be **byte-
            identical** (this is a pure refactor; behaviour unchanged).
      - [ ] Delete the corresponding `if (eq(u8, callee, "<name>"))` arm
            in every backend that had one.
      - [ ] One commit per method:
            `refactor(codegen): drive <interface>.<method> from annotation`.
- [ ] After all rows migrate, `emitPrimMethod` in `erlang.zig` /
      `beam_asm.zig` / `commonJS.zig` has **zero** `if (eq(u8, callee, …))`
      arms — only the final `// Unmapped primitive method: bare local
      call` fallback remains as a safety net.

### F2-R — migrate Family 2 (`emitResultOptionOp`)
- [ ] In `libs/std/src/builtins.d.bp`, convert the `@Result` / `@Option`
      method documentation comment block (lines 44–88) into real `fn`
      declarations on the respective enums, each carrying its full
      per-backend `#[@external]` annotation set per §"Family 2" table
      above. The synthetic callee names (`__bp_ok` etc) become
      comptime-internal handles; the lowering table moves to the
      declaration.
- [ ] In `comptime/{infer,transform}.zig`, the emission path for
      `@Result` / `@Option` methods looks up the annotation set on the
      receiver's enum (rather than the synthetic `__bp_…` mangled name)
      and feeds it to the shared template renderer from F1.
- [ ] Delete `emitResultOptionOp` (or stub it to a single delegating
      call to `tryEmitPrimAnnotation`) in `codegen/erlang.zig`,
      `codegen/beam_asm.zig`, `codegen/wat.zig`, `codegen/commonJS.zig`.
      Snapshot diff: empty.
- [ ] One commit per synthetic callee migration:
      `refactor(codegen): drive @Result.<op> from annotation`.

### F2-B — migrate Family 3 (`@todo` / `@panic` / `@block`)
- [ ] In `libs/std/src/builtins.d.bp`, the `panic` declaration gains the
      `#[@external(...)]` set from §"Family 3" table; `@todo` gains a
      proper `fn todo() noreturn` declaration (if not already present)
      with its set; `@block` gains its set on the existing `block` fn
      (coordinate with Frente A §U — if §U deletes `block`, this row
      drops).
- [ ] Delete the matching `if (eq(u8, cc.callee, "...todo|panic|block"))`
      arms in `codegen/{erlang,beam_asm,wat,commonJS}.zig`. `@print` is
      already annotation-driven (§A5) — same path now picks up the
      siblings.
- [ ] One commit per builtin:
      `refactor(codegen): drive @<builtin> from annotation`.

### F2-X — `runtime.zig` / `typescript.zig` confirmed out of scope
- [ ] Verify (at execution time) that `runtime.zig` has zero
      callee-keyed switches — its `mem.eql` hits are all on module
      / target / shell-arg strings. Document in `codegen/AGENTS.md`
      §"Annotation-driven lowering" that `runtime.zig` is host-side
      and out of scope.
- [ ] Verify `typescript.zig` has no `mem.eql(callee, …)` switches
      to migrate; Frente B §F (template-fn skip) is the relevant TS
      work. Same documentation note.

### F3 — diagnostics + tests
- [ ] Reserve RP1–RP5 diagnostic codes in `comptime/diagnostics.zig`.
- [ ] `tests/codegen/prim_op_templates.zig`:
      - Valid: every shape from the §"Migration table" renders correctly.
      - Invalid: each RP-code reds with the expected text.
      - Multi-line: an inline-fun template preserves whitespace and
        substitutes correctly.
      - Arity branch: a 1-arg call selects the 1-arg `when`; a 2-arg
        call selects the 2-arg `when`; a 3-arg call reds with RP2.

### F4 — docs
- [ ] `libs/std/AGENTS.md` §"External annotation vocabulary" gains a
      "Template grammar" subsection with the marker table + arity-branch
      syntax + `"""…"""` form.
- [ ] `modules/compiler-core/src/codegen/AGENTS.md` adds a per-target
      `$stringify` expansion table.
- [ ] `modules/compiler-core/src/comptime/AGENTS.md` documents
      `comptime/primOpTemplate.zig` as the shared rendering routine.
- [ ] `CHANGELOG.md`: one line under v0.beta.19 —
      `feat(stdlib): primitive-method lowering driven entirely by
      annotations; no more hardcoded switches.`

## Test scenarios

```
F0       ---- new template forms parse; legacy 2-arg form still parses identically
F1-erl   ---- a contains() call renders `lists:member(X, L)` from the annotation alone
F1-node  ---- same contains() call renders `L.includes(X)` from the node annotation
F1-multi ---- indexOf() inline fun renders byte-identically to the prior switch arm output
F1-arity ---- xs.slice(2) renders the 1-arg template; xs.slice(2, 5) renders the 2-arg template
F1-strify ---- [1,2,"a"].join(",") renders the per-element stringifier inline
F2-byte    ---- diff snapshots/codegen/ against pre-F2 HEAD: empty (byte-identical migration)
F2-empty   ---- post-F2 `git grep 'if (eq(u8, callee,' codegen/erlang.zig codegen/beam_asm.zig codegen/commonJS.zig codegen/wat.zig` finds zero hits
F2-R       ---- @Result and @Option ops emit byte-identical bytes on erlang/beam/node/wat after the switch in emitResultOptionOp is deleted
F2-R-snap  ---- a fixture exercising .map / .flatMap / .unwrapOr / .isOk / .isError / option counterparts diffs empty against pre-F2-R HEAD
F2-B       ---- @todo / @panic / @block emit byte-identical bytes on every backend after the hardcoded arms are deleted
F2-B-snap  ---- a fixture exercising @todo() / @panic("x") / block({ ... }) diffs empty against pre-F2-B HEAD
F2-X       ---- runtime.zig and typescript.zig touched only by the AGENTS.md note (no code changes)
F3-RP1   ---- `$5` in a 2-arg fn template reds with prim-op-arg-index-out-of-range
F3-RP2   ---- arity-branch with no matching when reds with prim-op-no-arity-match
F3-RP3   ---- $stringify(...) in a wat template reds with prim-op-stringify-unsupported
F4-docs  ---- AGENTS.md sweep across libs/std + codegen + comptime in the same commit as F1+F2
gate     ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
```

## Notes

- **Cross-spec interaction with Frente A §A6.** This spec **replaces**
  §A6's "irreducible allow-list" carve-out. After this lands, §A6's
  acceptance bar tightens: every primitive method is annotation-driven;
  no method is "irreducible". Update Frente A's spec / TODO accordingly
  at merge time.
- **Cross-spec interaction with Frente A §D-D5.** §D-D5 lists the BEAM
  inline-fun array/string methods to add (`join`, `indexOf`, `at`, 2-arg
  `slice`, string `contains`/`startsWith`). Once this spec ships, those
  methods are authored as annotations in `primitives.d.bp` instead of
  hand-coded in `beam_asm.zig`'s `emitPrimMethod`. §D-D5's checklist
  becomes "author the annotation + verify BEAM render" instead of
  "write BEAM helper funs".
- **Why a sibling spec, not just §A6 expansion.** §A6 was authored to
  finish the §A5 keystone with the existing 2-arg grammar; introducing
  a richer grammar is a discrete design step that deserves its own spec
  for downstream readers (a new contributor reading
  `primitives.d.bp` later needs to understand the marker syntax — they
  read this spec, not §A6's bullet).
- **Why not just emit Zig host functions per backend.** The current
  switch arms could be moved to per-target helper modules (e.g.
  `codegen/erlang/prim_ops.zig`) and the switch would only dispatch.
  That refactors the location but doesn't make the surface configurable;
  adding a new method still needs a `.zig` edit. The annotation grammar
  is the single-source-of-truth payoff.
- **What this spec is NOT.** Not a new effect, not a new type system
  feature, not a runtime change. It's purely a refactor that moves a
  fact from `.zig` switch arms to `.d.bp` annotations. Byte-identical
  output is the bar at every commit.
- **Per-memory:** SSH for git remote ops; AGENTS.md updated in the same
  commit as the code; commit messages in English; functions in
  camelCase.
