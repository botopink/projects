# Trailing default parameters at the call site

> **Carried from 1.0.2-beta comptime-dispatch** (its step 3, never executed). The fix is this
> front's — [`README.md`](./README.md) Step 0, row N1. Line numbers were measured at the 1.0.2-beta
> commit; re-locate by symbol.

`pub fn h1(children: Children, attrs: Array<#(string,string)> = [])` cannot be called `h1(x)`:
`'h1' expects 2 argument(s), got 1`. Paths are relative to `repository/botopink-lang/`.

**Record methods do not expand their defaults either** — the earlier diagnosis was wrong there.
Nothing in the compiler expands a default for a method. The asymmetry is that inference *does not
arity-check instance method calls*: `methodCallReturnType` (`comptime/infer.zig:6118`) unifies
arguments only when the arity already matches (`:6144-6149`) and the unknown-method fallback
(`:7105-7114`) types the call as a fresh var. So a short method call type-checks, no default is
filled, and codegen emits the short call: `undefined` on commonJS (`commonJS.zig:1675-1686`
`buildParam` drops `p.default`, so the emitted signature has no fallback either), a missing map key
or arity error on erlang. Where a method *is* checked, it reds exactly like a free fn —
`s.slice(2)` against `libs/std/src/primitives.bp:165` fails at `comptime/infer.zig:6509-6514`,
pinned by `codegen/tests/wat.zig:86-94` and
`snapshots/codegen/commonJS/string_slice_without_end_arg_slices_to_source_length.snap.md`.

## What is complete

**The parser.** One `Param.default: ?Expr` slot (`ast.zig:1018-1042`), filled by one function for
every param list — free fns, record/struct methods, interface methods, `implement` methods,
delegates all funnel through `parseParam` (`parser/decls.zig:1348-1352`); the trailing-only rule is
enforced at parse time (`parser/decls.zig:71-85`). Record constructor fields
(`parser/decls.zig:810-815`) and enum-variant fields (`:1172-1178`) use the same slot
(`ast.zig:1821-1832`, `:1387-1392`). `parser/tests/declarations.zig:726-733` documents the slot and
names the gap as call-site auto-injection; its tests (`:735`–`:774`, `:882-902`) are parse-only.

## What is complete but unreachable

**The splice.** `expandTrailingDefaultsWithParams` (`comptime/transform.zig:834-866`) returns early
if `args.len >= params.len` (`:842`), bails if any missing trailing param lacks a default
(`:846-849`), and otherwise appends
`.{ .label = null, .value = &params[i].default.?, .is_default_inj = true }` (`:852-865`) — the
`ast.CallArgOf.is_default_inj` flag (`ast.zig:255-276`) exists solely for this. It is wired into
`rewriteCall` (`:872-903`) for free/stdlib fns via `fn_decls` (`:873`, `:903`) and for
record/struct/enum-variant constructors via `agg.ctor_params` (`:879-890`, fed from `env.ctorParams`,
`comptime/env.zig:545-551`, populated at `comptime/infer.zig:975`, `:1196`, `:1274-1276`).

It is unreachable because it runs **after** inference and inference fails first:
`comptime.zig:355-362` returns `.typeError` on `inferProgramTyped`, and only on success does
`comptime.zig:1450-1453` call `transform.transform`. Two shapes do reach it, because they skip the
arity check: builtin `@fn()` calls (`comptime/infer.zig:6881-6897`) and qualified
`Enum.Variant(args)` (`:7013-7020`).

## The arity checks that reject

| # | Site | Callee kind | Accounts for defaults |
|---|---|---|---|
| 1 | `comptime/infer.zig:7151-7155` | free fn **and record/struct constructor** (both are `.func` bindings), no spread — `f.params.len != call.args.len` | no — **this is what rejects `h1(x)`** |
| 2–4 | `:7204-7208`, `:7216-7219`, `:7226-7229` | same, spread paths | no |
| 5 | `:6509-6514` | interface `default fn` on a primitive receiver (`resolveStdArrayMethod`) — rejects `s.slice(2)` | no |
| 6 | `:1113-1118` | interface associated fn (`Pair.of`) | no |
| 7 | `:6952-6956` | `"std"`-package qualified call | no |
| 8 | `comptime/unify.zig:74-77` | fn-type ↔ fn-type unification (passing `h1` as a value) | no |
| 9 | `:2205-2213` | annotation / decorator application | **yes — the only correct one**: `required = count(params where default == null)`, accepts `required ≤ args ≤ params.len` |

Message: `TypeError.arityMismatch` (`comptime/error.zig:193-194`), rendered at `:295`. The
diagnostic codes already exist and describe the intended order —
`comptime/diagnostics.zig:187-219`, where D3 `fn-param-default-arity-mismatch` is documented to fire
"after `expandTrailingDefaults` could not fill every missing arg". That ordering is precisely what
is missing.

**Record constructors are the same defect, not a separate one.** A record ctor is an ordinary
`.func` binding (`comptime/infer.zig:960-969`), so `Config(host: "x")` takes the free-fn path and
dies at check #1; args are zipped positionally at `:7161-7167` with the label ignored. The
transform's ctor branch (`transform.zig:888-890`) is therefore dead for records for the same reason.

## The fix

**This is a checker fix**, not a parser or transform fix.

1. Relax check #1 (and #2–#4, #5, and for parity #6/#7) to the rule already implemented at
   `comptime/infer.zig:2205-2213`: `required ≤ args ≤ params.len`.
2. `required` is not derivable from `T.func` — the type carries no defaults. Inference needs a
   `name → []ast.Param` side table for fns, mirroring `env.stdlibFnDecls` (`comptime/env.zig:539-544`).
   **Constructors need no new table**: `env.ctorParams` (`:545-551`) is already keyed by the name
   `:7117` looks up.
3. When `args.len < params.len`, the unification loop at `:7161-7182` must stop at `args.len`; the
   omitted slots are typed by the default expression, checked at decl registration.
4. Leave `transform.zig` untouched.

**What the call site looks like afterwards:** exactly what the transform already produces — the
`call` node's `args` slice grows to `params.len`, with each injected entry
`.{ .label = null, .value = &decl.params[i].default.?, .is_default_inj = true }`
(`transform.zig:858-863`). **No codegen change is needed**, confirmed in all four backends:
commonJS maps `cc.args` blindly (`commonJS.zig:2636-2637`, `:2773-2774`, `:1920`), erlang the same
for plain calls (`erlang.zig:1756`) and by label/position for record ctors (`erlang.zig:3455-3461`),
wat walks them positionally (`wat.zig:2400-2411`), typescript emits declarations only. No backend
emits a parameter default in the *declaration*, so call-site injection is the only lowering that
can work at all — an "emit `= default` in the JS signature" fix is impossible for erlang.

One caveat: injected args are positional and appended at the tail, while user args may be named
(`h1(x, attrs: [])`). Since inference zips positionally (`:7161`) and the parser forbids
positional-after-named (`parser/exprs.zig:1488-1491`), tail-appending is sound for "omit the
trailing defaults". Allowing a *middle* named param to be skipped would additionally need
name-matched injection in `expandTrailingDefaultsWithParams` and label-aware unification.

## Impact

`repository/jhonstart/src/element.bp` carries **24** occurrences of `attrs: []`, of which 22 are
pure arity padding at call sites (2 are genuine forwarding, `:15`, `:19`); 29 repo-wide across
`element.bp`, `hooks.bp`, `html.bp`. The declarations that should make them unnecessary are
`element.bp:14`, `:18`, `:22-27`. `element.bp:59` pads four times in one expression. The same file
shows the constructor half: `Element` (`:3-8`) declares no field defaults because adding one would
hit check #1.

## Ownership

The whole fix lands in `comptime/infer.zig`, which this front owns and which moves the typed AST
every backend consumes. The comptime-dispatch front that wrote this analysis has landed; nothing else
holds `infer.zig`.
