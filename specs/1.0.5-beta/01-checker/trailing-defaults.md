# Trailing default parameters at the call site (step 7)

> Carried from 1.0.2-beta comptime-dispatch through 1.0.4-beta front 06, never executed. The
> analysis holds; it was re-probed at `botopink-lang` `c2dd780` on 2026-09-18 and the sites were
> re-located by symbol.

```
fn connect(host: string, port: i32 = 80) -> string { return host; }
@print(connect("h"));
    → error: 'connect' expects 2 argument(s), got 1  --> src/main.bp:2:24

type P(x: i32 = 0, y: i32)
val p = P(y: 2);
    → error: 'P' expects 2 argument(s), got 1        --> src/main.bp:2:25
```

Paths are relative to `repository/botopink-lang/`.

## What is already complete

**The parser.** One `Param.default: ?Expr` slot, filled by one function for every parameter list —
free fns, `type` methods, `behavior` methods, `implement` methods and delegates all funnel through
`parseParam`; the trailing-only rule is enforced at parse time. Constructor fields and enum-variant
fields use the same slot.

**The splice.** `comptime/transform.zig:865` `expandTrailingDefaultsWithParams` returns early when
`args.len >= params.len`, bails if any missing trailing parameter lacks a default, and otherwise
appends `.{ .label = null, .value = &params[i].default.?, .is_default_inj = true }`. The
`ast.CallArgOf.is_default_inj` flag exists solely for this. It is wired into `rewriteCall` for
free/stdlib fns via `fn_decls` and for `type`/enum-variant constructors via `agg.ctor_params`, fed
from `env.ctorParams`.

It is unreachable because it runs **after** inference and inference fails first: `comptime.zig`
returns `.typeError` on `inferProgramTyped`, and only on success does it call `transform.transform`.
Two shapes do reach it because they skip the arity check — builtin `@fn()` calls and qualified
`Enum.Variant(args)`.

## The arity checks that reject

`grep -n 'arityMismatch' modules/compiler-core/src/comptime/infer.zig` at `c2dd780` gives **twelve**
raise sites. They fall into three classes:

| Class | Sites (`infer.zig`, `c2dd780`) | Accounts for defaults |
|---|---|---|
| free fn **and constructor** (both are `.func` bindings) — the plain path and the four spread paths | `:7988`, `:8078`, `:8089`, `:8099`, `:8137` | **no — this is what rejects `connect("h")` and `P(y: 2)`** |
| the other callee kinds: interface `default fn` on a primitive receiver (rejects `s.slice(2)`), interface associated fn, `"std"`-package qualified call, pipeline, method | `:1150`, `:5421`, `:6979`, `:7304`, `:7751`, `:8184` | no |
| annotation / decorator application | `:2287` — `required = count(params where default == null)`, accepts `required ≤ args ≤ params.len` | **yes — the only correct one** |

Function-type unification (`comptime/unify.zig`, passing `connect` as a value) is a thirteenth and
also compares `params.len` exactly.

The diagnostic codes already describe the intended order: D3 `fn-param-default-arity-mismatch` is
documented to fire "after `expandTrailingDefaults` could not fill every missing arg". That ordering
is what is missing.

**Record constructors are the same defect, not a separate one.** A constructor is an ordinary
`.func` binding, so it takes the free-fn path and dies at the same check; arguments are zipped
positionally with the label ignored. The transform's ctor branch is therefore dead for the same
reason.

**Instance methods neither red nor expand.** Inference does not arity-check an instance method call:
it unifies arguments only when the arity already matches, and the unknown-method fallback used to
type the call as a fresh var. Since C9 (`75a6906`) that fallback reds when the receiver's type is
nominal and registered — so a short method call now reds where it used to pass silently, and it must
expand instead.

## The fix

**A checker fix**, not a parser or transform fix.

1. Relax the five free-fn/constructor sites (and, for parity, the interface, std-package and method
   sites) to the rule at `:2287`: `required ≤ args ≤ params.len`.
2. `required` is not derivable from `T.func` — the type carries no defaults. Inference needs a
   `name → []ast.Param` side table for fns, mirroring `env.stdlibFnDecls` (`comptime/env.zig:576`).
   **Constructors need no new table**: `env.ctorParams` is already keyed by the name the call path
   looks up.
3. When `args.len < params.len`, the unification loop stops at `args.len`; the omitted slots are
   typed by their default expression, checked at declaration registration.
4. Leave `transform.zig` untouched.

**No codegen change is needed** — confirmed in all four backends: the `call` node's `args` slice
simply grows to `params.len`, and commonJS, erlang and wat all walk `args` blindly. No backend emits
a parameter default in the *declaration*, so call-site injection is the only lowering that can work
at all; an "emit `= default` in the JS signature" fix is impossible for erlang.

One caveat: injected arguments are positional and appended at the tail, while user arguments may be
named. Inference zips positionally and the parser forbids positional-after-named, so tail-appending
is sound for "omit the trailing defaults". Letting a *middle* named parameter be skipped would
additionally need name-matched injection and label-aware unification — out of scope; say so in the
landing note.

## Acceptance

- [ ] a free fn, a `type` constructor and an instance method each accept a call that omits a trailing
      default, and the injected argument reaches codegen through `transform.zig`
- [ ] a missing **required** argument still reds, with D3's code and a caret on the call
- [ ] `type P(x: i32 = 0, y: i32)` then `P(y: 2)` checks, and `x` is `0` at run time on all four backends
- [ ] `s.slice(2)` against `libs/std/src/primitives.bp`'s two-parameter `slice` checks
- [ ] `commonJS | test/fn_defaults.bp` and `erlang | test/fn_defaults.bp` leave `expected-failures.txt`
- [ ] `repository/jhonstart/src/element.bp`'s 22 pure-padding `attrs: []` arguments can be deleted —
      the deletion itself is [`09-ecosystem-residuals`](../09-ecosystem-residuals/README.md)'s
