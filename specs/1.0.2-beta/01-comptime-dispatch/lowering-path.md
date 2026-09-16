# The lowering path, traced

The call chain from a `.bp` call site to the `erl_lint` error, both hosts, with `file:line` at
HEAD. Paths are relative to `repository/botopink-lang/`.

## Template host

| # | Site | What happens |
|---|---|---|
| 1 | `comptime/infer.zig:3204` `expandTemplateCall` | the body is not reducible by inspection (`classifyTemplateBody` returns null), so `:3211` hands it to the runtime |
| 2 | `comptime/infer.zig:3268` `expandTemplateCallViaRuntime` | `:3331` calls `templateEval.evaluate` |
| 3 | `comptime/template_eval.zig:80` `evaluate` → `:91` `buildModule` (`:282`) | wraps the template `FnDecl` as a **one-decl `ast.Program`** (`:290-291`) |
| 4 | `comptime/template_eval.zig:298` | `erlang.emitComptimeModule(arena, "template_module", program, config)` |
| 5 | `codegen/erlang.zig:484` `emitComptimeModule` | **`:494` creates an empty `instance_lowerings` map** (and `:490`/`:492` empty `comptime_vals`/`rewrites`), then calls `:496` |
| 6 | `codegen/erlang.zig:514` `emitErlangModule` | `:527` `em.untyped = comptime_module != null` |
| 7 | a method call reaches `plainCallNode` (`:3430`); the value-receiver arm starts at `:3489` | `:3545` `this.instance_lowerings.get(loc)` — **always a miss**, the map is empty by construction |
| 8 | `:3565` `selfPrimKind` | null (`self_prim_kind` is only set inside `instanceDefaultForms`) |
| 9 | `:3569` `arrayPrimFallbackNode` (`:3904`) | answers for `forEach`/`fold`/`drop`/`take`/`toList` only |
| 10 | `:3570` | `toString` with no args only |
| 11 | **`:3571`** | `b.call(cc.callee, …)` → the bare local call `split(T, <<"\n">>)` |
| 12 | `comptime/template_eval.zig:96-98` | writes the `.erl`, `persistent_erl.evalDetailed` compiles it → `{undefined_function,{split,2}}` |
| 13 | `comptime/template_eval.zig:111` | `.err = "the template module did not compile: …"` |

## Decorator host

Identical from step 5 on.

| # | Site | What happens |
|---|---|---|
| 1 | `comptime/infer.zig:2266` | `decoratorEval.evaluate(env.arena, ctx.io, ctx.build_root, dfn, handle, plain, …)` |
| 2 | `comptime/decorator_eval.zig:58` `evaluate` → `:69` `buildModule` (`:194`) | one-decl `ast.Program` (`:203-204`) |
| 3 | `comptime/decorator_eval.zig:212` | the same `erlang.emitComptimeModule`, so steps 5–11 above are shared verbatim |
| 4 | `comptime/decorator_eval.zig:89` | `.err = "the decorator module did not compile: …"` |

**Step 11 is the whole defect. Everything else is correct.**

## Why the typed path gets it right, and what the untyped path actually lacks

On the typed path `plainCallNode:3545` reads `instance_lowerings[loc]`, written by
`comptime/infer.zig:6612` `recordInstanceCall` (call sites `:6435`, `:6527`, `:7054`, `:7067`).
The value is an `envMod.InstanceLowering` (`comptime/env.zig:294`) whose `.prim` payload is a
`PrimKind` — **one of five enum values**, `array | string | bool | int | float`
(`comptime/env.zig:283`). With it, `:3547` calls `primMethodNode` (`:3829`), whose first move
(`:3831`) is `primAnnotationNode` (`:1724`):

1. `primIfaceForKind` (`:1092`) maps the kind to its controller interface (`.string` → `"String"`),
2. `PrimIfaceWalker` (`:1108`) climbs the `extends` chain (`I32 → Signed → Integer → Number`),
3. each step looks up `"<Iface>.<method>"` in `prim_erlang_dispatch`,
4. a hit whose symbol is a `$`-template renders through `templateNode` (`:1553`) →
   `comptime/primOpTemplate.zig`.

For `s.split("")` the entry is `String.split` from `libs/std/src/primitives.bp:121`
(`@External.Erlang("string:split($self, $0, all)")`) and the rendered result is
`string:split(S, <<"">>, all)`.

**The missing information is that single `PrimKind` — not "types" in general.** Both tables the
typed lowering consults are already fully built inside a comptime module:

| Table | Built by | Called from | Present in a comptime module? |
|---|---|---|---|
| `prim_erlang_dispatch` (`<Iface>.<method>` → `@External.Erlang` ref/template) | `collectPrimErlangDispatch` (`codegen/erlang.zig:1601`), which **re-parses the embedded `primitives.bp`** (`:1617-1626`, `comptime/stdlib/prelude.zig:12`) | `codegen/erlang.zig:573`, unconditional | **yes, complete** |
| `prim_iface_chain` (`extends` parents) | `collectIfaceExtendsChain` (`:1635`), same collector | same | **yes, complete** |
| `iface_instance_defaults` (bodied `default fn`s) | `collectInterfaces` (`:1777`) — walks `program.decls` **only**, never the re-parsed prelude | `:556` | **no — empty**, the program is one fn decl |

So there are two gaps, of very different sizes:

- **G1 (the reported failure).** Every host-backed method — the whole `@External.Erlang` surface —
  is one enum value away from lowering correctly. Nothing else is missing.
- **G2 (the tail).** A `default fn` with no `@External.Erlang` annotation (`String.slice`
  `libs/std/src/primitives.bp:165`, `Array.slice` `:572`, `Array.first` `:652`, `Array.all` `:683`,
  `Array.find` `:675`, `Array.count` `:679`, `Array.unique` `:804`, …) additionally has no body in
  the module, because `collectInterfaces` never sees the prelude.

## Threading the caller's map in is not a fix

`emitComptimeModule` could be given the compiling module's `ok.instance_lowerings` (the map
`codegen/erlang.zig:332` already passes on the ordinary path), and for an in-module template that
would work — the template fn's own body *is* inferred (`comptime/infer.zig:2746` sets
`inTemplateFn` and walks the body like any other fn; nothing gates `recordInstanceCall` on it).

But every reported failure is **cross-module**: `html` lives in `repository/jhonstart/src/html.bp`
and is called from `test/html_test.bp`, and rakun's and onze's decorators are imported the same
way. `registerImportedTemplateFn` (`comptime/infer.zig:3160`) and `registerImportedDecorator`
(`comptime/infer.zig:565`) carry the `FnDecl` across the boundary and nothing else — the locs in
that body belong to a module whose `instanceLowerings` this `Env` never had. The approach also
degrades silently wherever inference bailed on a chain. **Rejected.**

## Why the failure is unreadable

`comptime.zig:76` `ComptimeOutput.outcome` carries the full `TypeError`, and all four backends
`continue` on it, so the module produces no `ModuleOutput` and the CLI can only print a count that
points at `botopink check` — which loads `src` only. That is why this front's failure surfaces as
`1 module(s) failed to compile` instead of a located diagnostic, and why `check` is green while
`test` is red. The discard sites and the fix belong to the CLI front: rows C1, C5, C6 and C7 of
[`../02-cli-gate/command-contract.md`](../02-cli-gate/command-contract.md).
