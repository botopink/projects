# Mutation through a method inside a closure

`args.push(x)` inside a closure is emitted as a *discarded* expression, while an outer-`var`
assignment in the same position threads out through `lists:foldl`. Even with `push/2` defined by
the dispatch fix, rakun's constructor injection builds an empty argument list — resolving the
method name alone does not unblock it. Paths are relative to `repository/botopink-lang/`.

## The two fold paths, and why `push` misses both

| Path | Entry | What it matches | `push`? |
|---|---|---|---|
| Fold fusion (peephole) | `detectFoldFusion` `codegen/erlang.zig:2424`, from `bodyNode:2403` | `var acc = init;` immediately followed by `recv.forEach({ p -> … })` | `classifyFoldStmt` (`:75`) **does** recognise `push` at `:91-101` and lowers it via `foldBodyExpr:2500` to `Acc ++ [X]` — but `:2464` requires the closure body to be **exactly one statement**, `:2445` requires the callee to be `forEach` (never `loop`), and `identName` (`:128`) requires a bare identifier receiver |
| Mutation threading (general) | `mutatingExpr` `codegen/erlang.zig:2531`, from `bodyNode:2412` | any closure/branch/loop that assigns to an outer local | `collectMutations` (`:2592`) counts **only** `.binding.assign` with a `.name` target (`:2595-2605`). `args.push(x)` is a `.call`, so `:2613` merely recurses into nested `forEach` bodies and the receiver is never marked. With no names, `:2556` returns null and the whole `forEach` degrades to a discarded `lists:foreach` |

The accumulator is a tuple of the mutated names (`varGroupExpr:2632`, version-bumped by
`bindVarGroupExpr:2643`), threaded by `mutatingFoldExpr:2734` and closed by `armWithGroup:2690`.

## What the fold needs to thread a receiver mutation out — two changes, not one

1. **Analysis.** `collectMutations` (`:2592`) needs a `.call` arm that, for a statement-position
   call whose callee is a known mutating method, takes `identName(cc.receiver.*)` (`:128`) and
   appends it under the same three guards as the assign arm (`this.locals.contains(n)`,
   not shadowed, not already collected). The `.branch` recursion and `mutatingIfExpr`'s name
   collection (`:2538-2539`) need the same.
2. **Rewrite — required; marking the name is not enough.** `armWithGroup` (`:2690`) appends
   `varGroupExpr(names)` (`:2695`) at whatever `var_current` versions the body left behind. Since
   `args.push(x)` lowers through `stmtExpr` (`:2872`) → `callNode` (`:3323`) to a bare
   `(Args ++ [X])` that binds nothing, `var_current["args"]` is never bumped, the group-out
   expression is the same `Args` the fun received, and `lists:foldl` faithfully returns the initial
   value. The statement must be lowered as a rebinding — `Args@1 = (Args ++ [X])` — the way
   `bindExpr` (`:2060`, version allocation at `:2083-2085`) does for `.assign`. After that the
   existing tuple/versioning machinery works unchanged.

## Scope and soundness

- Sound only when the receiver is a local `var` (`this.locals.contains(n)` plus the `.localBind`
  `mutable` bit read at `:2435`). A `push` onto a parameter or a field-access receiver
  (`identName` returns null) must keep today's behaviour or be diagnosed.
- The same dead store exists at **function-body** level, not only inside closures:
  `var out = []; out.push(1); return out;` has the identical shape.
- **Backends:** erlang and beam_asm are broken; commonJS is correct by accident (JS arrays mutate
  in place — `commonJS.zig` has no `push` handling at all); wat does not implement array iteration.
  `beam_asm.zig` has no `collectMutations`, no `mutatingExpr` and no fusion — `emitLoop:4169`
  always picks `map`/`foreach`, and `primAppendElem:2754` computes `lists:append/2` into `x0` and
  drops it. `codegen/beam_asm.zig` belongs to the beam front
  ([`../04-beam/README.md`](../04-beam/README.md)), so this front either hands it the shape to fix
  or scopes beam out explicitly in its acceptance.
- **There is no notion of a mutating method anywhere in the compiler.** No marker in `ast.zig`,
  `infer.zig` or any backend; the only mutability bit is `mutable: bool` on bindings
  (`ast.zig:540`, `:555`). The concept exists solely as the hardcoded string `"push"` at
  `codegen/erlang.zig:93` and `codegen/beam_asm.zig:2573`. And `push` is declared
  **without a return type** — `libs/std/src/primitives.bp:564-566`, `fn push(self: Self, item: T)` —
  so there is semantically nothing to bind either. The principled version of this fix gives `push`
  `-> Self` and/or introduces a real receiver-mutation marker, so the analysis becomes
  declaration-driven instead of name-driven. Changing `primitives.bp` is the std front's file
  ([`../03-std-surface/README.md`](../03-std-surface/README.md)); the name-driven version is
  self-contained here.
- `libs/std` already documents this as a trap and routes around it by hand:
  `libs/std/src/path.bp:19-21`, `:91`, `:148`; `libs/std/src/base64.bp:44`. `primitives.bp` itself
  still contains the broken shape — `Array.append:695` and `Array.prepend:702` both write
  `other.forEach({ y -> out.push(y); })` and are saved only by their `@External.Erlang` overrides
  (`:691`, `:699`) bypassing the body.

## The fixture

The bug is already golden-committed: `codegen/tests/features.zig:694`
`test "js: iterator fromList yields array items"` (source at `:711`, `out.push(item)` inside
`loop (iter) { item -> … }`) and
`snapshots/codegen/erlang/iterator_fromlist_yields_array_items.snap.md:34-39`, whose run log at
`:51-54` is `<<>>` where commonJS gives `1,2,3`. The fix flips that run log; the beam copy likewise.

No fixture covers the multi-statement-closure shape rakun actually uses (the one `:2464` rejects) —
add one in `codegen/tests/features.zig` (4 snapshot files, one per backend directory) plus a
substring test next to `codegen/tests/comptime_module.zig:72`, since rakun goes through
`emitComptimeModule`, not the ordinary codegen path.

## rakun's site

`repository/rakun/src/decorators.bp:46-58` (`component`; repeated verbatim in `service:63`,
`repository:80`, `cargs:114`, `rargs:139`, `gargs:172` — decorator bodies cannot call sibling fns,
`:42-45`): `args.push(f.name + ": " + expr)` inside a 4-statement `decl.fields.forEach` closure,
consumed at `:59` by `args.join(", ")`. It fails twice over — `:2464` rejects the multi-statement
closure, and `collectMutations` never marks `args`. Note the *inner*
`f.annotations.forEach({ a -> … valKey = … })` at `:51` **is** a `.binding.assign` and threads
correctly, so the inner mutation survives while the outer `push` silently vanishes.
