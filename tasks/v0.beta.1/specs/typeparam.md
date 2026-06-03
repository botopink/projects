# Typeparam constraints

**Branch**: `feat/typeparam`
**Depends on**: nothing (independent)
**Status**: pending

## Target syntax

```bp
fn build(comptime f: typeparam string | int, x: i32) -> i32 { … }
```

## Examples

### Single constraint
```bp
fn render(comptime tag: typeparam string, props: i32) -> string {
    return tag + ": " + props.to_string();
}
val a = render("div", 1);   // ok
val b = render(42, 1);      // ✗ error: 42 does not satisfy `string`
```

### Multiple constraint (pipe)
```bp
fn coerce(comptime v: typeparam string | int | bool, x: i32) -> i32 {
    return x;
}
coerce("s", 0);   // ok (string)
coerce(7, 0);     // ok (int)
coerce(true, 0);  // ok (bool)
coerce(3.14, 0);  // ✗ error: f64 not in {string,int,bool}
```

### No constraint (backwards compat)
```bp
fn id(comptime t: typeparam, x: i32) -> i32 { return x; }  // accepts any type
```

## Steps

1. Constraint syntax: `comptime f: typeparam string | int`
2. Parser: parse the `|`-separated type list after `typeparam`
3. Inference: validate the comptime argument satisfies the declared constraints
4. Error message: clear diagnostic when the constraint is violated
5. Codegen: constrained typeparam specializes correctly

## Test scenarios

```
parser ---- typeparam with single constraint
parser ---- typeparam with multiple pipe-separated constraints
parser ---- typeparam without constraint (backwards compat)
inference ---- comptime arg satisfies single constraint (pass)
inference ---- comptime arg satisfies one of multiple constraints (pass)
inference ---- comptime arg violates constraint (error)
inference ---- comptime arg with no constraint accepts any type (pass)
codegen ---- constrained typeparam specializes correctly
```