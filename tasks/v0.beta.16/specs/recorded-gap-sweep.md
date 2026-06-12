# v0.beta.16 — recorded-gap sweep (unified spec)

**Slug**: recorded-gap-sweep
**Status**: pending.
**Premise**: every prior wave deliberately **recorded** the bits it left behind — in spec
"non-goals", in `AGENTS.md` "KNOWN GAP" / "Recorded gaps" notes, in backend "Remaining gaps".
This version collects those grounded, deferred items into **one spec**, organized by area.
Nothing is invented; each section cites the note it closes. The **keystone (§A)** is the
annotation-driven-builtins refactor; the rest build on the cleaner base it leaves.

**Coverage map** (which recorded note each section closes):

| § | Section | Closes (recorded where) | Area / files |
|---|---|---|---|
| A | annotation-driven-builtins **(keystone)** | builtin method lowering hardcoded in 4–5 `.zig` instead of read from `#[@external]`/signatures | parser · codegen ×3 · comptime · `*.d.bp` |
| B | generic-inference | `Self`→primitive kind in interface `default fn` (backends-parity-tail **E**) + generic inline-test cascade (`libs/std/AGENTS.md`) | `comptime/{infer,unify,types}.zig` |
| C | wasm-aggregates | named record-field layout (`self.id`→`i32.const 0`) + `?.` on wasm (`codegen/AGENTS.md`) | `codegen/wat.zig` |
| D | cross-backend-feature-parity | features broken on erlang **and** beam (`beam_asm.zig` "Remaining gaps") | `codegen/{erlang,beam_asm,commonJS}.zig` |
| E | lsp-definition-tail | tuple `p._0` + interface assoc dispatch (v0.beta.15 non-goals) | `language-server/src/engine.zig` |
| F | typescript-dts-templates | `.d.ts` still declares template fns (`codegen/AGENTS.md` KNOWN GAP) | `codegen/typescript.zig` |
| G | erika-dsl-extensions | interpolated queries + `var` string form (`libs/erika/AGENTS.md`) | `libs/erika/src/erika.bp` + comptime |

**Ordering / coordination** (merge-order, not file-conflict):

- **§A lands first.** It refactors the same emitters (`commonJS`/`erlang`/`beam_asm`) + `infer`
  that §B and §D touch; doing the keystone first lets them build on the annotation-driven base
  instead of extending the soon-to-be-deleted switches. Acceptance bar is **byte-identical
  output** (pure refactor) → merges ahead cleanly.
- **§B unblocks the erlang/beam emission** of erika's instance `default fn`s, also tracked by
  `backends-parity-tail` (v0.beta.14) item **E** — inference unblock lives here; emission can
  land in either; merge-order them.
- **§C** follows `backends-parity-tail` **W** (loops must compile first).
- **§D's `console.log`/`new Error`** are *already* `#[@external]`-declared in `builtins.d.bp`
  (for `print`) — once §A makes the backends consult the annotation, those become "wire the
  annotation through," not new hardcoding.
- **§E** extends the v0.beta.15 `lsp-definition-completeness` member-resolution machinery.

See [[project_spec_waves]], [[feedback_external_annotation_form]],
[[feedback_compiler_unaware_of_jhonstart]], [[feedback_no_lib_specific_in_core]].

## Cross-section consistency (no section contradicts another)

Checked each pair for conflicting claims or competing edits to the same code. Findings + how
they're reconciled:

1. **§A ↔ §B — both edit `infer.zig` primitive-method machinery.** §A deletes the
   `primMethodReturnType` return-type switch (`:4773`) and keeps `primitiveInterfaceName`
   (array→`Array`, …); §B adds `Self`→primitive-kind resolution inside interface `default fn`
   bodies (`recordInstanceCall`/`instance_lowerings`). **Not a contradiction — a synergy:** once
   §B resolves `Self` to `array`, §A's signature-driven return-type lookup *is* what types
   `self.forEach`. They touch **different functions** in the same file. Resolution: **§A lands
   first**; §B builds on the annotation-driven resolution rather than the deleted switch.
2. **§A ↔ §D — "consult the annotation" scope.** §A's mechanism is **primitive instance
   methods** (`emitPrimMethod`); §D-D1's `console.log`/`new Error` are **free host forms**, a
   different path. §D does **not** assume §A lowers them — it reuses §A's *principle*
   (declare + consult, don't hardcode) and adds its own `@external` decls. The `print` builtin
   (which already lowers via `@external`) is explicitly distinguished from the raw `console.log`
   form (which doesn't) — so the §D table ("`console.log` unlowered") and the `print` annotation
   do **not** conflict.
3. **§A "byte-identical" ↔ §A migrating annotations to `Target.Erlang`.** "Byte-identical" is the
   bar for **emitted backend output**, not the `.d.bp` *source* (which is edited: enum target,
   call templates). No contradiction — a refactor changes how output is produced, not the output.
4. **§A scope vs wasm (§C).** §A lists only `commonJS`/`erlang`/`beam_asm` because **`wat.zig`
   has no primitive-method table** to refactor (verified: no `emitPrimMethod`, no `lists:`/
   `string:` — wasm doesn't lower Array/String methods yet; that's `backends-parity-tail` **W**).
   So "single source of truth" is not violated by omitting wat — there's nothing there to be a
   second source. §C is record-field layout, orthogonal.
5. **§D ↔ §C — cross-module.** §D-D2 lowers cross-module **fn** imports on erlang/beam; §C-C4
   keeps wasm **single-module**. Different backends, no overlap.
6. **§E / §F / §G** — `language-server` / `typescript.zig` / `libs/erika` are file-disjoint from
   every other section and from each other. No shared edits.

Net: the only ordering constraint is **§A before §B and §D** (shared `infer.zig`/emitter
regions); everything else is independently shippable.

---

# §A — annotation-driven-builtins (keystone)

`#[@external]` annotations + signatures in `builtins.d.bp` / `primitives.d.bp` are the single
source of truth for builtin method lowering.

**Files**: `parser/decls.zig` (the `@external` target — parse as a `Target` enum, not a bare
`.identifier` at `:916`/`:966`), `codegen/commonJS.zig` (`isNativeProtoMethod`,
`jsBuiltinMethodName`, `jsPrototypeOwner`), `codegen/erlang.zig` + `codegen/beam_asm.zig`
(`emitPrimMethod`), `comptime/infer.zig` (`primMethodReturnType`, `jsStringMethodRename`,
`jsMethodRenames`, `primitiveInterfaceName`), `comptime/transform.zig`,
`libs/std/src/{primitives,builtins}.d.bp`.

> The primitive method tables live in **two contradicting places**. `primitives.d.bp` declares
> each method with `#[@external(erlang, "lists", "reverse"), @external(node, …)]` and a real
> signature (`fn join(self) -> string`). The emitters and inference **ignore the annotation**
> and re-hardcode the same knowledge — `erlang.zig`/`beam_asm.zig` `emitPrimMethod` is a giant
> `callee`-name `switch`, `commonJS.zig` keeps a literal `isNativeProtoMethod` list and a
> `jsBuiltinMethodName` rename table, and `infer.zig` hardcodes both the return types and a
> `{src, js, ret}` rename table. Adding a method means editing 4–5 `.zig` files instead of one
> `.d.bp` line — and the `.zig` even **overrides** the annotation (`reverse` is
> `@external(node, "./gleam_stdlib.mjs", "reverse")` yet listed in `isNativeProtoMethod`).

## The duplication (all verified on `feat`)

| Knowledge | Declared in `primitives.d.bp` | Re-hardcoded in |
|---|---|---|
| erlang lowering (`reverse`→`lists:reverse`) | `#[@external(erlang, "lists", "reverse")]` | `erlang.zig` `emitPrimMethod` switch |
| beam lowering | same annotation | `beam_asm.zig` `emitPrimMethod` switch |
| node native vs sidecar (`map` native, `at` → `.mjs`) | `#[@external(node, "./gleam_stdlib.mjs", "…")]` | `commonJS.zig` `isNativeProtoMethod` (147) |
| node rename (`append`→`concat`, `toUpper`→`toUpperCase`) | (not yet expressible) | `commonJS.zig` `jsBuiltinMethodName` (178) |
| method **return type** (`join` → `string`, `at` → `?T`) | the `fn` signature itself | `infer.zig` `primMethodReturnType` (4773) |
| string rename (`contains`→`includes`) | (not yet expressible) | `infer.zig` `jsStringMethodRename` (4840) |
| prototype owner (`Bool`→`Boolean`, numeric→`Number`) | the interface name | `commonJS.zig` `jsPrototypeOwner` (155) |

`"find", "flatMap", "reverse", "includes", "flat", "sort", "fill", "append", "toString"` —
`isNativeProtoMethod`'s list — is the canonical example, but it recurs across every table above.

## What changes (before → after)

**Before** — adding `Array.zip` means editing the `.d.bp` *and* `erlang.zig` *and*
`beam_asm.zig` *and* `infer.zig`'s return-type switch:

```botopink
// primitives.d.bp
#[@external(erlang, "lists", "zip"), @external(node, "./gleam_stdlib.mjs", "zip")]
fn zip<U>(self: Self, other: Array<U>) -> Array<Pair<T, U>>
```

```zig
// erlang.zig emitPrimMethod — must ALSO add:
if (eq(u8, callee, "zip")) { try this.w("lists:zip("); … return; }
// beam_asm.zig — another arm; infer.zig primMethodReturnType — another `if`.
```

**After** — the annotation + signature are the only edit; the emitters read them:

```botopink
// primitives.d.bp — the ONLY place
#[@external(Target.Erlang, "lists", "zip(other, self)"),
  @external(Target.Node, "./gleam_stdlib.mjs", "zip")]
fn zip<U>(self: Self, other: Array<U>) -> Array<Pair<T, U>>
```

```
erlang  → lists:zip(Other, Self)      (the `zip(other, self)` template fixes the arg order)
beam    → call_ext {extfunc, lists, zip, 2}
node    → the .mjs sidecar `zip`     (from @external(Target.Node, …))
infer   → return type read from the `-> Array<Pair<T,U>>` signature, not a switch
```

**Before** — `reverse` is double-declared and the `.zig` wins:

```zig
// commonJS.zig:147 — overrides the @external(node, "./gleam_stdlib.mjs", "reverse") annotation
const native = [_][]const u8{ "find", "flatMap", "reverse", "includes", "flat", "sort", "fill", "append", "toString" };
```

**After** — the keyword form: no `module` on node ⇒ native JS prototype; the list is deleted:

```botopink
#[@external(Target.Node, "reverse"),                       // node: emit `xs.reverse()` directly
  @external(Target.Erlang, "lists", "reverse")]            // erlang: lists:reverse(self)
fn reverse(self: Self) -> Self
```

## Design — extend the `#[@external]` vocabulary

**Sanctioned liberty (confirmed by Eric):** adding to or changing the builtin annotation
surface is *expected*, not a constraint to route around — both the annotation **vocabulary**
(new `#[@external]` shapes below) and the **per-method annotations** in `primitives.d.bp` /
`builtins.d.bp` may be freely added or modified. The whole point is that the `.d.bp` becomes
the single edit site; if a method can't be expressed today, extend the annotation rather than
re-hardcoding in `.zig`.

### Two forms, both valid

**Form A — positional shorthand** (the common case):

```bp
#[@external(Target.Erlang, "lists", "reverse")]   // runtime · module · symbol
fn reverse(self: Self) -> Self
```

The runtime/target **is an enumeration** — `Target { Erlang, Node, Beam, Wasm }` (declared in
`builtins.d.bp`) — so it is written like every other enum value in botopink: qualified
**`Target.Erlang`**, or the **dot-variant shorthand `.Erlang`** when the type is inferred
(`EnumName.Variant` explicit, `.Variant` shorthand — see [[reference_bp_parser_comptime_gotchas]]).
**Today it is wrong:** the parser reads the target as a **bare identifier** (`decls.zig:916` /
`:966` `consume(.identifier).lexeme`), so the existing annotations spell it `erlang` with **no
dot and no enum**. This spec makes the target a real enum value (a bare `erlang` stays accepted
for back-compat / migrated in place). `module` + `symbol` are strings; args follow the method's
**declaration order**. This stays the default — no labels, no template.

**Form B — keyword-argument + call template** (when you need more than the default order):

```bp
#[@external(
  runtime: Target.Erlang,    // the target/runtime enum (or `.Erlang` shorthand)
  module:  "lists",          // host module
  method:  "reverse(self)"   // call template: symbol + arg order, by param name
)]
fn reverse(self: Self) -> Self
```

It uses the language's own labeled-argument syntax (`name: value`, the same `:` botopink uses
for named call/constructor args — `ast.zig:253` "named args (`fator: 2`)"). Form A is exactly
`#[@external(runtime: Target.Erlang, module: "lists", method: "reverse")]` with the labels
dropped. Reach for Form B only to use the **call template** — the one extra axis Form A can't
express:

- **`method: "reverse"`** — bare symbol; args follow declaration order (`symbol(self, …)`).
- **`method: "map(action, self)"`** — explicit **argument order + receiver position** by param
  name. Subsumes recv-first/recv-last: `lists:map(Fun, L)` is `method: "map(action, self)"`;
  `length(L)` is `method: "length(self)"`; `lists:member(X, L)` is `method: "contains(item, self)"`.
- **`method: "reverse(param2, param1)"`** — pure reorder (Eric's example).

Same keyword form covers every backend:

- **node prototype / rename** — `#[@external(runtime: Target.Node, method: "reverse")]` with
  **no `module`** means "native JS prototype, emit `recv.reverse(args)` directly" (no patch, no
  sidecar); a rename is a different `method` symbol (`method: "concat(self, item)"` for
  `append`→`concat`). Replaces `isNativeProtoMethod` + `jsBuiltinMethodName`.
- **erlang/beam** — `module` + `method` template gives `module:symbol(args…)` in the templated
  order. Operators (`append`→`++`, `prepend`→`[X|L]`, `isEmpty`→`=:= []`) are a template whose
  "symbol" is the operator form, or kept in the marked inline allow-list.

**Irreducible cases stay inline, explicitly marked.** A few erlang/beam lowerings carry real
arithmetic/logic, not a symbol + arg order — `slice` (`Start+1`, `End-Start`), `at` (bounds
check), `join` (per-element stringify), `indexOf` (fold). Either grow the template grammar to
allow expressions, or keep these in a clearly-labelled `emitPrimMethodInline` allow-list (or a
pure-botopink `default fn` body, like `range`/`repeat`). The goal is that **symbol-map +
arg-order** cases stop being hardcoded; the computational ones are the visible exception.

## Steps

- [ ] **A1** — target becomes a real enum: declare `pub enum Target { Erlang, Node, Beam, Wasm }`
      in `builtins.d.bp`; parse `@external` target as `Target.Erlang`/`.Erlang` instead of the
      bare `.identifier` at `decls.zig:916`/`:966` (bare `erlang` accepted for back-compat).
- [ ] **A2** — parse the keyword-argument form + call template: accept
      `#[@external(runtime: Target.Erlang, module: "<m>", method: "<symbol>(<args>)")]` alongside
      Form A; parse `method` into (symbol, ordered arg names referencing declared params incl.
      `self`); bare `method: "sym"` ⇒ declaration order; omitted `module` (node) ⇒ prototype.
- [ ] **A3** — return types from the signature: resolve a primitive method's return type from
      its `fn` signature in `primitives.d.bp` (instantiate `Self`/type params); delete
      `primMethodReturnType` (`infer.zig:4773`).
- [ ] **A4** — node: drive `commonJS.zig` native-method emission from `#[@external(Target.Node,…)]`
      (no `module` ⇒ prototype; different `method` ⇒ rename); delete `isNativeProtoMethod` +
      `jsBuiltinMethodName` + `jsStringMethodRename`/`jsMethodRenames`. Keep `jsPrototypeOwner`
      (or move `Bool`→`Boolean` to an interface-level annotation).
- [ ] **A5** — erlang/beam: replace the `callee`-name switches in `erlang.zig` + `beam_asm.zig`
      with a lookup of `@external(Target.Erlang,…)` (module+symbol) + the `method` template's arg
      order; irreducible inline cases become a small explicit allow-list.
- [ ] **A6** — migrate every current case (Array `map`/`filter`/`reverse`/`append`/`prepend`/
      `push`/`contains`/`indexOf`/`len`/`isEmpty`/`slice`/`join`/`at`; String `length`/`toUpper`/
      `toLower`/`trim`/`slice`/`contains`/`startsWith`/`split`; Bool `negate`). **Byte-identical**
      output (empty snapshot diff) is the bar.
- [ ] **A7** — docs + tests: document the extended `#[@external]` vocabulary in `libs/std/AGENTS.md`
      + `codegen/AGENTS.md` + `comptime/AGENTS.md`; add a test that adds a *new* primitive method
      via one `.d.bp` annotation and asserts it lowers on all backends with **no** `.zig` edit.

**§A non-goals**: no new primitive methods (plumbing only; `Array.zip` is the example); the
genuinely-irreducible inline templates may stay inline, explicitly marked.

---

# §B — generic-inference

Resolve `Self`'s primitive kind in interface `default fn` bodies + inline tests in generic
modules. **Files**: `comptime/{infer,unify,types}.zig`, `libs/std/src/*_test.bp`,
`libs/erika/src/erika.bp`.

> The recurring blocker behind two failures. v0.beta.3 `generic-inference` F1 (per-call-site
> fresh type vars) landed, but a deeper gap survives: inference cannot resolve `Self` to a
> concrete primitive kind inside an interface `default fn` body — so `self.<method>` records no
> `instance_lowerings`, and a generic call inside a generic module's inline test still throws.

**1 — interface `default fn` bodies calling `self.<primMethod>`** (the backend long pole):
erika's Array instance `default fn`s (`fold`/`drop`/`take`/`forEach`/`toString`/`count`) call
`self.forEach`/`self.length` on a generic `Self`; inference can't resolve `Self`→`array` inside
the body, so erlang/beam have nothing to emit (`backends-parity-tail` **E** is blocked on this).
A `variable 'B' is unbound` codegen bug rides along.

**2 — inline test blocks in generic stdlib modules**: a generic module (`pair`/`list`/`iterator`/
`dict`/`sets`/`function`/`queue`) whose `test { … }` calls a generic fn hits `.generic` vars
that `unify` rejects, cascading to every `freshTestEnv` consumer. Workaround today: external
`*_test.bp` files instead of inline tests.

## What changes (before → after)

```botopink
// libs/erika/src/erika.bp
pub interface Enumerable<T> {
  default fn count(self: Self) -> i32 {
    var n = 0;
    self.forEach({ _ -> n = n + 1 });   // self: Self (generic) → no instance_lowering
    return n;
  }
}
```

```
Before:  $ zig build test-libs  →  erika ✗ variable 'B' is unbound  (self.forEach never lowered)
After:   $ zig build test-libs  →  erika ✓ (commonJS, erlang)       (instance default fns emit)
```

```botopink
// libs/std/src/dict.bp
test "insert then get" { val d = insert(empty(), "k", 0); @assert(get(d, "k") == 0); }
//  Before: must live in dict_test.bp (inline → .generic TypeError cascades to 39+ tests)
//  After:  inline test works; freshTestEnv consumers stay green
```

## Steps

- [ ] **B1** — resolve `Self`'s primitive kind inside an interface `default fn` body (bind
      `Self` to the concrete kind for the body's duration so `self.<method>` records an
      `instance_lowering`).
- [ ] **B2** — instantiate the callee's generic vars (per-call-site fresh, the v0.beta.3 F1
      path) before `unifyAt` in `inferCallExpr`, so a generic call in a `test { … }` block no
      longer throws; fold the external `*_test.bp` back to inline for generic modules.
- [ ] **B3** — fix the `variable 'B' is unbound` codegen bug the erika LINQ pipeline surfaces.
- [ ] **B4** — emit the primitive interfaces' **instance** `default fn`s on erlang/beam (mangled),
      once the bodies lower (coordinates with `backends-parity-tail` **E** — merge-order).
- [ ] **B5** — drop the generic-module inline-test caveat in `libs/std/AGENTS.md`; add inference
      unit tests for the interface-body `Self` resolution.

---

# §C — wasm-aggregates

Named record-field layout in linear memory (unblocks `self.field`, `?.`, method bodies).
**Depends on** `backends-parity-tail` **W** (the wat loop/stack fix). **Files**: `codegen/wat.zig`.

> The wat backend lays tuples/arrays/enum payloads out as contiguous 4-byte slots, but **named
> record fields have no layout** — `self.id` emits `i32.const 0`. Every method body reading a
> field, and `?.`, are dead on wasm (recorded in `codegen/AGENTS.md`).

## What changes (before → after)

```botopink
pub val Post = record { id: i32, title: string };
pub fn idOf(self: Post) -> i32 { return self.id; }
```

```wat
;; Before:  (func $idOf (param $self i32) (result i32) i32.const 0)   ;; stub, always 0
;; After:   (func $idOf (param $self i32) (result i32) local.get $self i32.load offset=0)
```

`?.` — Before: `post?.title` short-circuits to `0` with `;; (unsupported on wasm)`. After: guards
on the record base (`post == 0 ? 0 : load title slot`) like the other backends.

## Steps

- [ ] **C1** — record field layout: each `record`/`struct` field gets a stable slot offset
      (4-byte slots, the tuple scheme); construction stores each named arg at its offset.
- [ ] **C2** — `recv.field` (incl. `self.field`) loads `base + offset(field)`; field assign stores.
- [ ] **C3** — `?.` guards the base against null then reads the slot; remove the short-circuit.
- [ ] **C4** — cross-module-linking note: wasm stays **single-module**; keep the explicit
      `;; cross-module import not linked (wasm single-module)` comment — don't build linking here.
- [ ] **C5** — update `codegen/AGENTS.md` (drop the `self.id`/`?.` gap notes); add wat snapshots.

---

# §D — cross-backend-feature-parity

Features broken on **erlang AND beam at once** — not implemented on the reference erlang backend
either, so beam has nothing to mirror. **Depends on §A** (the keystone) landing first.
**Files**: `codegen/{erlang,beam_asm,commonJS}.zig`, `comptime/infer.zig`.

| Surface | Today | Target |
|---|---|---|
| `new Error(…)` | unlowered on erlang+beam | host error value per backend |
| `console.log` | unlowered on erlang+beam | erlang `io:format` / beam `call_ext` |
| cross-module **fn** imports | unlowered on erlang+beam | remote call into owner module |
| `*fn` async / `await` | unlowered on erlang+beam | effect-runtime lowering |
| typed-value method dispatch (`p.parse()`) | unlowered on erlang+beam | resolve receiver's declared type → its method |

## What changes (before → after)

```botopink
import { parseUrl } from "web/http";
val u = parseUrl("/posts/1");     // Before: unlowered  →  After (erlang): U = http:parseUrl(<<"/posts/1">>).
val p = Parser();
val ast = p.parse(src);           // Before: unlowered  →  After (erlang): Ast = 'Parser_parse'(P, Src).
```

## Steps

- [ ] **D1** — `console.log` + `new Error(…)` **declared, not switched**: the `print`/`println`/
      `debug` *builtins* already lower via `#[@external(node,"console","log"),
      @external(erlang,"io","format")]` in `builtins.d.bp` — the gap is the **raw** `console.log`
      / `new Error` host forms (used by framework/external code), which have no `@external` decl.
      Declare them as `@external` builtins and lower by consulting the annotation (the same
      *consult-don't-hardcode* principle §A establishes for methods), not a new hardcoded case.
      `new Error(m)` ⇒ `{error, M}` / `error(M)`.
- [ ] **D2** — cross-module fn imports lower to a remote call into the owner module (basename
      atom; mirror `crossModule.zig`'s record/assoc-fn path); erlang first, then beam.
- [ ] **D3** — typed-value method dispatch: inference tags a method call on a declared
      record/struct value with its owner; codegen lowers `p.parse(x)` → `'Parser_parse'(P, X)`.
- [ ] **D4** — `*fn` async/`await`: lower the effect-runtime form on erlang/beam, or scope to a
      follow-up and record the precise boundary (don't fake it).
- [ ] **D5** — update the `beam_asm.zig`/`erlang.zig` AGENTS "Remaining gaps"; add codegen
      snapshots on **both** backends for each lowered surface.

---

# §E — lsp-definition-tail

Tuple-field access + interface associated-function dispatch in go-to-definition — the explicit
**non-goals** of v0.beta.15 `lsp-definition-completeness`. **Files**: `language-server/src/engine.zig`.

## What changes (before → after)

```botopink
val pair = (1, "a");   val n = pair._0;     // Before: Ctrl+Click `_0` → nothing.  After: → tuple slot 0.
val r = Array.range(0, 3);                  // Before: Ctrl+Click `range` → nothing. After: → `default fn range`.
```

## Steps

- [ ] **E1** — tuple-field `recv._N`: resolve the receiver's tuple/struct type, return the Nth
      element's declaration (or the literal's Nth element).
- [ ] **E2** — interface associated-function dispatch: a call through an interface's associated
      `default fn` returns the `default fn` declaration in the interface source (reuse the
      v0.beta.15 `builtinInterfaceForType` + `findDeclLocation` routing).
- [ ] **E3** — note the two paths in `language-server/AGENTS.md` + `docs.md`; add regression
      tests for `p._0` and an `Interface.method(...)` jump.

---

# §F — typescript-dts-templates

Drop comptime template fns from the `.d.ts` emitter. **Files**: `codegen/typescript.zig`.

> KNOWN GAP in `codegen/AGENTS.md`: template fns (`-> @Expr<…>`) are comptime-only — the
> transform pass substitutes call sites and **drops the declarations** — but the `.d.ts` emitter
> still **declares** them, rendering an `Expr<>` type with no runtime existence.

## What changes (before → after)

```botopink
pub fn erika(q: string) -> @Expr<Query> { … }   // comptime-only template fn
```

```ts
// Before — erika.d.ts:  export function erika(q: string): Expr<Query>;   (WRONG, Expr<> not real)
// After  — erika.d.ts:  (the template fn is gone, like the runtime emitters already drop it)
```

## Steps

- [ ] **F1** — in `typescript.zig`, skip any fn whose return type is `@Expr<…>`/`@ExprCustom<…>`
      when emitting `.d.ts` (mirror the transform-pass drop); never render `@expr`/`@code`.
- [ ] **F2** — remove the KNOWN GAP note in `codegen/AGENTS.md`; add a `.d.ts` snapshot test
      asserting a template-fn module emits no `Expr<>`.

---

# §G — erika-dsl-extensions

Interpolated queries + the string form seeing `var` collections. **Files**:
`libs/erika/src/erika.bp` (and, for the `var` form, `comptime/` scope-snapshot capture).

> Two recorded `erika` extensions ("record, don't build" in `libs/erika/AGENTS.md`).

**1 — interpolated queries** `erika "… where age >= ${min}"` via `q.parts()` Text/Interp (the
parser exposes parts; the lowering doesn't yet weave interpolated runtime values in).
**2 — string form sees only `val`**: `erika "select … from listas"` where `listas` is a `var`
doesn't resolve (the template reads the caller's comptime scope snapshot, which captures `val`
only; the fluent `of(listas)` form already queries any `var`/`val`).

## What changes (before → after)

```botopink
val min = 18;
val adults = erika "select name from people where age >= ${min}";   // Before: ${min} not bound. After: woven in.

var listas = [1, 2, 3];
val xs = erika "select n from listas";   // Before: does NOT resolve (var). After: resolves.
```

## Steps

- [ ] **G1** — lower `${expr}` interpolations: `q.parts()` yields Text/Interp; weave each
      Interp's runtime value into the lowered query operands; add `where age >= ${min}` tests.
- [ ] **G2** — string form resolves `var` (core comptime scope-snapshot captures `var`, not just
      `val`); keep it generic — no `erika`-specific coupling in core.
- [ ] **G3** — update the "Recorded gaps" in `libs/erika/AGENTS.md`; add `.bp` tests for both forms.

---

## Done gate (whole version)

- §A: adding/renaming a builtin method is a single `.d.bp` edit; `isNativeProtoMethod`,
  `jsBuiltinMethodName`, `jsStringMethodRename`, `jsMethodRenames`, `primMethodReturnType` are
  gone; `emitPrimMethod` reduced to annotation-lookup + a marked inline allow-list; **output
  byte-identical** (snapshots unchanged).
- §B: erika green on erlang under `zig build test-libs`; generic stdlib modules carry inline tests.
- §C: `self.field` reads/writes the right slot on wasm; `?.` guards; AGENTS gap notes removed.
- §D: `console.log`/`new Error`/cross-module fn/typed dispatch lower on erlang+beam with snapshot
  parity; `*fn` async/await lowered or its boundary recorded.
- §E: `p._0` + interface assoc calls resolve in go-to-def without regressing v0.beta.15.
- §F: `.d.ts` no longer mentions template fns.
- §G: interpolation woven; `var` string form resolves.
- Throughout: `zig build test` + `botopink-lib-test` + `zig build test-libs` stay green; touched
  `AGENTS.md` updated in the same commits.
