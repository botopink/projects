# Hook codegen (`use`)

**Branch**: `feat/hook-codegen`
**Phase**: F8
**Depends on**: `feat/context-inference` (F7) — merged into `feat`
**Status**: ✅ done (rebased onto `feat`)

`use` is a **prefix operator**; binding is done by the enclosing `val`/`var`.
The AST collapsed to `Expr.useHook { inner }` (the old bind/destruct variants
were removed). A parser bug was fixed along the way: no-param trailing lambdas
`{ -> … }` weren't consuming the arrow (`parseTrailingLambdas`).

## Steps

### CommonJS (React-like target)
1. ✅ `val {v, s} = use state(0)` → `const { v, s } = useState(0)`
2. ✅ `val #(v, s) = use state(0)` → `const [ v, s ] = useState(0)` (tuple `#(…)` → JS array destructure)
3. ✅ `val d = use memo { -> return v*2; }` → `const d = useMemo(() => { … }, [v])` (inferred deps)
4. ✅ `use effect { -> cleanup(); }` → `useEffect(() => { … }, [])`
5. ✅ Hook name mapping — convention `"use" + Capitalize` (`state`→`useState`),
   custom hooks already in `useXxx` form pass through (P1 resolved → convention).

### TypeScript `.d.ts`
6. ✅ `@Context<B, R>` erased to its Return type `R` in emitted type refs.
7. ✅ ContextBase phantom struct erased — emits no class (JS) / no typedef (`.d.ts`).

### Erlang / BEAM / WAT
8. ✅ Erlang: `use` is transparent — the call result lands in a bound variable.
9. ✅ BEAM ASM: transparent — result stored into the `val`/`var` y-slot.
10. ✅ WAT: transparent — result stored into the binding's local slot.

(8–10 use the existing `val`/destructure binding paths; dedicated process-dict /
fixed-memory-offset hook stores are deferred until runtime hook dispatch exists.)

## Test scenarios — all green (`codegen ---- …` in `codegen/tests.zig`)

```
codegen ---- use object destructure state to useState
codegen ---- use tuple destructure state to useState
codegen ---- use memo infers dependency array
codegen ---- use effect void hook empty deps
codegen ---- inline implement context base erased at runtime
```

## Notes
- Deps inference: a deps-taking hook's lambda dep array is the reactive names
  (bound by earlier `use` hooks in the same fn) the lambda references.
- Inline lambda args don't unify with `fn(…) -> T` params (resolved to a named
  `function` type, not `.func`); hooks taking a lambda use the **trailing**
  form, which isn't arity-checked. Fixing that unification is inference work
  outside this task.