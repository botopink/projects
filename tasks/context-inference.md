# `@Context<B, R>` inference

**Branch**: `feat/context-inference`
**Phase**: F7
**Depends on**: `feat/use-await-prefix` (usePrefix) + `feat/extension-dispatch` (stable type tables) — **merge first**
**Status**: blocked (waiting on merges)

## Core rule

The function's **return type** decides which capabilities the body may use:

| Return implements | `use` | `await` |
|---|---|---|
| `@Context<B, R>` | ✓ | ✗ |
| `@Future<R>` | ✗ | ✓ |
| `@Context + @Future` | ✓ | ✓ |
| none | ✗ | ✗ |

- All `use` in a function must share the **same ContextBase**
- `@Context<B, R>` is a builtin interface (defined in `builtins.d.bp`) — done

## Steps

1. On entering a fn body: extract the ContextBase from the return type if it implements `@Context`
2. On each `use`: verify the expression returns `@Context<B, _>` with B == the fn's ContextBase
3. Error if `use` appears in a fn whose return doesn't implement `@Context`
4. Error if the `use` ContextBase diverges from the fn's ContextBase
5. Transitive validation: custom hooks propagate ContextBase via their return type

## Custom hooks

Functions whose return implements `@Context<B, _>` are hooks; validation is transitive.

```bp
val AuthState = struct implement @Context<Element, {user: User, isLoggedIn: bool}> {
    user: User
    isLoggedIn: bool
}
fn useAuth() -> AuthState {
    val {token} = use state(null)        // @Context<Element, _> ✓
    AuthState { user, isLoggedIn: token != null }
}
fn Dashboard() -> Element {
    val {user, isLoggedIn} = use useAuth()  // @Context<Element, _> ✓
}
```

## Test scenarios

```
context ---- use in fn -> @Context<Element, _> (pass)
context ---- use in fn -> string (error: not @Context)
context ---- ContextBase mismatch Element vs Http (error)
context ---- use without binding for void hook (pass)
context ---- use with binding for non-void hook (pass)
context ---- custom hook propagates ContextBase transitively (pass)
context ---- struct implement @Context — resolved via inline impl (pass)
context ---- struct missing @Context impl but used with use (error)
```

## Error messages

```
error: ContextBase mismatch
  function returns @Context<Element, _>
  but `connection()` returns @Context<Http, _>

error: `use` not allowed
  function returns `string` which does not implement @Context

error: `use` must be in static prefix
  `use` cannot appear after `if`, `case`, `loop`, or `return`
```