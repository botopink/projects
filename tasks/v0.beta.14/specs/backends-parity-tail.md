# backends-parity-tail — finish the wasm/erika/F3 remainder of stdlib-backends-parity

**Slug**: backends-parity-tail
**Depends on**: nothing for the wasm/F3/beam items. **erika-LINQ** depends on the
**generic-inference** spec (the long pole — instance `default fn` bodies that call
`self.<method>` on a generic `Self`). **pub-default-fn** continues from the parser
layer already on `feat`.
**Files**: `modules/compiler-core/src/codegen/wat.zig`, `beam_asm.zig`,
`erlang.zig`, `commonJS.zig`, `comptime/infer.zig`, `comptime/env.zig`,
`modules/compiler-cli/src/cli/test_cmd.zig`, `libs/std/src/primitives.d.bp`.
**Touches docs**: `modules/compiler-core/src/codegen/AGENTS.md`,
`modules/compiler-core/src/comptime/AGENTS.md`.
**Status**: pending.

> The open remainder of `stdlib-backends-parity` (`task/stdlib-backends-parity`).
> The achievable backend-parity work landed in `feat` over ~15 commits (see
> "Already landed"); what's left is either a genuine backend refactor (wasm), a
> dependency on a separate spec (erika-LINQ → generic-inference), or focused
> per-method work (beam inline-fun ops, beam std-loading). Backend-parity only —
> `commonJS`/`erlang` are the reference; record genuine limits, don't fake them.

## Already landed in `feat` (the baseline — do NOT redo)

- **A1b beam** instance-method lowering: Array `map`/`filter`/`forEach`/`reverse`/
  `contains`/`len`/`prepend`/`push`/`append`/`isEmpty` + String `length`/`toUpper`/
  `toLower`/`trim`/`split`/1-arg-`slice` → `call_ext`/`put_list`/`=:= []`. Verified
  byte-identical to erlang. Fixed the arity-0 array-literal bug (`[Elem|Elem]`) and
  several beam register-liveness bugs (gc_bif/test_heap/`min_live`/closure reset).
- **A2** `Array.range`/`repeat`: pure-botopink recursive `default fn` with an
  array-literal spread `[head, ..(recurse(...))]`, half-open `[start, stop)`. Works
  on commonJS + erlang + beam (the host externals were wrong/missing).
- **Interface associated-`default fn` emission** on erlang + beam (`emitInterface`/
  `emitInterfaceAssoc` + call resolution), mangled to avoid consumer collisions
  (erlang `array_range` lowercase-first unquoted atom; beam `'Array_range'`).
  `Pair.of`/`first`/`second`, `Function.identity`/`compose` work on all three.
- **F1** literal receivers reach codegen on every backend; **F2** commonJS
  `arr.len()`/`.size()`/`str.length()` → the `.length` PROPERTY.
- **F4** `?.` optional chaining on beam (guards on `{atom, undefined}`).
- **`a..b` range** is now half-open and consistent on commonJS/erlang/beam.
- **Follow-ups**: `Pair.of` reserved-word resolution (erlang); beam tuple `p._N`
  via `erlang:element/2`.
- **`pub default fn` / `import pkg` — parser layer only** (commit `593af55`):
  `pub default fn` parses at a module top level (`FnDecl.isDefault`); the
  `import pkg` / `import pkg from "pkg"` / `import pkg, { … }` namespace forms parse
  (`ImportDecl.package`). Resolver + codegen are unfinished (see below).

## What remains

### W — wasm wat-backend stack-discipline refactor (the wasm headline)
The wat backend is **untyped** and assumes every statement-expression leaves one
value on the stack, so `emitStmt` `drop`s every non-last statement-expr. But void
builtins (`@print` → `call $__print_i32`, which has NO result) leave nothing — so
the `drop` after `@print` in a loop body **underflows** (`expected a type but
nothing on stack`), and a value-producing expr as the *last* statement of a **void**
fn (e.g. a `loop` whose value is `i32.const 0`) **leaks** (the function has no result
type, so the stack must end empty).
- [ ] Track per-expression "produces a value" in the wat emitter (a small
      classifier: `@print`/`@panic`/`@todo`/void-returning calls produce nothing;
      everything else produces one i32). Drop only value-producing statement-exprs;
      for a **void** function (`f.returnType == null`) the last statement is NOT the
      return, so drop its value too (thread `returns_value` into `emitBody`, which
      currently ignores `result_type` and `watTypeOpt(null)` wrongly defaults to
      `"i32"`).
- [ ] Once loops compile: **F5** wire `botopink test --target wasm` (the
      `wasmtime` runner) — `test_cmd.zig:46` gates to commonJS/erlang; wasm
      test-mode codegen must emit the `__bp_run_tests` entry and the CLI must
      invoke it via `wasmtime` (single-module).
- [ ] **wasm `?.`**: needs named record-field access in linear memory first
      (`self.id` is a `i32.const 0` stub today) — implement field layout, then the
      `?.` undefined-guard. Record the limit if field-layout is out of scope.

### E — erika-LINQ on erlang/beam (the long pole — depends on generic-inference)
`erika` reds on erlang are Array **instance** `default fn`s (`fold`/`drop`/`take`/
`forEach`/`toString`/`count`) that aren't emitted, and whose bodies call
`self.forEach`/`self.length` on a **generic `Self`** — inference records no
`instance_lowerings` for those (it can't resolve `Self` to the concrete `array`
inside the interface body). Plus a `variable 'B' is unbound` codegen bug.
- [ ] (generic-inference spec) Resolve `Self`'s primitive kind inside an interface
      `default fn` body so `self.<primMethod>` lowers (the blocker).
- [ ] Emit the primitive interfaces' **instance** `default fn`s on erlang/beam
      (mangled, like the associated ones), once the bodies lower.
- [ ] Fix the `unbound 'B'` codegen bug surfaced by the LINQ pipeline.

### F3 — beam load the std modules the same way node does
- [ ] erlang/beam should resolve `from "std"` imports + run the std modules the
      same way node does (erlang partial; beam pending).

### B — beam inline-fun / arithmetic array methods
- [ ] `join` (`iolist_to_binary∘lists:join` + a per-element stringify fun),
      `indexOf`, `at` (bounds-safe `lists:nth`), 2-arg `slice` (`lists:sublist`
      with `start+1`/`end-start` arithmetic), `string contains`/`startsWith`. Each
      needs an emitted helper fun or arity arithmetic on BEAM — mirror the erlang
      `emitPrimMethod` shapes.

### P — `pub default fn` / `import pkg` resolver + codegen (parser already landed)
`<pkg> "…"` (the DSL form, e.g. `erika "select …"`) parses to a tagged call
`pkg(<string>)` and resolves to a function literally named `pkg` in scope. The
clean design: **`import pkg` binds the package's `root.bp` `pub default fn` under
the name `pkg`**, so the existing tagged-call machinery works unchanged.
- [ ] Module resolver: `import pkg` (internal, same package) and
      `import pkg from "pkg"` (external) load the package's `root.bp`, find its
      `pub default fn`, and bind `pkg` → that fn. Decide internal (local call) vs
      external (cross-module) codegen.
- [ ] Inference: a tagged `pkg "…"` call resolves the callee to the bound default
      fn; integrate with the `@Expr`/`@ExprCustom` template machinery the existing
      `erika "…"` already uses.
- [ ] Codegen ×3 for the bound default fn (emit once in the package root).

## Done gate
- [ ] wasm: `loop (0..3) { i -> @print(i) }` compiles + runs `0,1,2` under
      `wasmtime`; `Array.range(0,3)` and `[1,2,3].map(f)` materialize as valid wasm.
- [ ] `botopink test --target wasm` runs a test module.
- [ ] `erika` is green on erlang under `zig build test-libs` (or its blockers are
      precisely attributed to the generic-inference spec).
- [ ] `zig build && zig build test` green; `zig build test-libs` parity recorded.
