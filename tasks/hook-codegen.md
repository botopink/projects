# Hook codegen (`use`)

**Branch**: `feat/hook-codegen`
**Phase**: F8
**Depends on**: `feat/context-inference` (F7) — **merge first**
**Status**: blocked (waiting on merge)

## Steps

### CommonJS (React-like target)
1. `val {v, s} = use state(0)` → `const {v, s} = useState(0)`
2. `val [v, s] = use state(0)` → `const [v, s] = useState(0)`
3. `val d = use memo({ -> v*2 })` → `const d = useMemo(() => v*2, [v])` (inferred deps)
4. `use effect({ -> cleanup() })` → `useEffect(() => cleanup(), [])`
5. Hook name mapping (`state` → `useState`) — see open point P1

### TypeScript `.d.ts`
6. Emit `@Context` interface types in the `.d.ts`
7. ContextBase erased — emit no code for the phantom type

### Erlang / BEAM / WAT
8. Erlang: `use` → slot in the process dictionary or gen_server state
9. BEAM ASM: `use` → hook slot management
10. WAT: `use` → load/store at a fixed offset in linear memory

## Test scenarios

```
codegen ---- val {v,s} = use state(0) → const {v,s} = useState(0)
codegen ---- val [v,s] = use state(0) → const [v,s] = useState(0)
codegen ---- val d = use memo(...) → const d = useMemo(..., [deps])
codegen ---- use effect() → useEffect(() => …, [])
codegen ---- inline implement erased at runtime (no code for phantom)
```

## Open point
- **P1**: framework-specific hook name. `state` → `useState` via convention
  (`"use" + Capitalize`) or a config table?