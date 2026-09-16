# Front 02 — `behavior` keyword (rename `interface`)

**Priority:** critical — `interface` is a Java/C# term that carries baggage (single inheritance,
abstract methods only). `behavior` is more accurate: the declaration describes a set of methods
and fields that a type may implement, not a contract in the OO sense.
**Depends on:** none
**Owns:** `lexer/token.zig`, `lexer.zig`, `parser/**`, `ast.zig` · `snapshots/parser/`, `snapshots/lexer/`
**Does not touch:** `comptime/**` (F2), `format.zig` (F3), `codegen/**` (F4–F7), `libs/**` (F8)

---

## Problem

The `interface` keyword is a rename-only change. No semantic difference, no structural difference.
The motivation is clarity: `behavior` better describes what the declaration is — a set of
capabilities a type may exhibit, not a structural contract.

## Current state

40 `interface` declarations across std + libs (23 in std, 17 in libs). All follow the same
pattern:

```bp
interface Name extends Super1, Super2 {
    val field: Type,
    fn method(self: Self) -> Return,
    default fn helper(self: Self) { ... }
}
```

## Mechanism

Pure lexical substitution. The parser dispatches on `TokenKind.interface` today; it will dispatch
on `TokenKind.behavior` tomorrow. The AST node `InterfaceDecl` is renamed to `BehaviorDecl`. The
type environment's `TypeDef.interface` (if it exists) is renamed to `TypeDef.behavior`.

## Proposal — the `behavior` keyword

### Syntax

```bp
// Simple behavior
pub behavior Printable {
    fn print(self: Self),
}

// With extends
pub behavior Integer extends Number {
    fn toString(self: Self) -> string,
    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}

// With fields
pub behavior Request {
    val method: HttpMethod,
    val path: string,
    fn param(self: Self, name: string) -> string,
}

// Marker behavior (empty body)
pub behavior Context<ContextBase, Return> { }

// With generics
pub behavior Iterator<T, E = any, C = void> {
    fn next(self: Self) -> IteratorStep<T, E, C>
}

// With default methods
pub behavior Function {
    default fn identity<A>(x: A) -> A {
        return x;
    }
    default fn compose<A, B, C>(f: fn(a: A) -> B, g: fn(b: B) -> C) -> fn(A) -> C {
        return { a -> g(f(a)) };
    }
}
```

### `implement` clause (unchanged)

```bp
pub type Element implement @Context<Element, Element> {
    tag: string,
    children: Array<Element>,
}
```

The `implement` keyword is unchanged. It still means "this type provides the behavior named X".

### Val-form (unchanged shape, new keyword)

```bp
val Drawable = behavior {
    fn draw(self: Self),
}
```

## Migration examples

### Example 1 — Simple behavior

**Before (1.0.2-beta):**
```bp
pub interface Printable {
    fn print(self: Self),
}
```

**After (1.0.3-beta):**
```bp
pub behavior Printable {
    fn print(self: Self),
}
```

### Example 2 — Behavior with `extends`

**Before:**
```bp
interface Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,
}

interface Integer extends Number {
    fn toString(self: Self) -> string,
    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}
```

**After:**
```bp
behavior Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,
}

behavior Integer extends Number {
    fn toString(self: Self) -> string,
    default fn isEven(self: Self) -> bool {
        return self % 2 == 0;
    }
}
```

### Example 3 — Behavior with fields

**Before:**
```bp
pub interface Request {
    val method: HttpMethod,
    val path: string,
    fn param(self: Self, name: string) -> string,
}
```

**After:**
```bp
pub behavior Request {
    val method: HttpMethod,
    val path: string,
    fn param(self: Self, name: string) -> string,
}
```

### Example 4 — Marker behavior

**Before:**
```bp
pub interface Context<ContextBase, Return> { }
```

**After:**
```bp
pub behavior Context<ContextBase, Return> { }
```

### Example 5 — Behavior with generics and default methods

**Before:**
```bp
pub interface Array<T> {
    val length: i32,
    fn at(self: Self, index: i32) -> ?T,
    fn push(self: Self, item: T),
    default fn slice(self: Self, start: i32, end: i32 = null) -> Self { ... }
}
```

**After:**
```bp
pub behavior Array<T> {
    val length: i32,
    fn at(self: Self, index: i32) -> ?T,
    fn push(self: Self, item: T),
    default fn slice(self: Self, start: i32, end: i32 = null) -> Self { ... }
}
```

### Example 6 — Behavior with `#[mock]` annotation

**Before:**
```bp
#[mock]
interface UserRepo {
    fn find(self: Self, id: i32) -> string,
    fn all(self: Self) -> Array<string>,
}
```

**After:**
```bp
#[mock]
behavior UserRepo {
    fn find(self: Self, id: i32) -> string,
    fn all(self: Self) -> Array<string>,
}
```

## Steps

### Step 1 — Lexer: add `behavior` keyword, remove `interface`

Add `behavior` to `TokenKind` in `lexer/token.zig`. In `lexer.zig:keywordOrIdent`, map `"behavior"`
to the new token. Remove `interface` from the keyword table — it is no longer recognized.

**Acceptance:**
- [ ] `behavior` tokenizes as `TokenKind.behavior`
- [ ] `interface` is removed from the keyword table — using it produces a parse error
- [ ] `lexer/tests/` updated with the new token

### Step 2 — Parser: rename `parseInterfaceDecl` to `parseBehaviorDecl`

In `parser/decls.zig`, rename `parseInterfaceDecl` → `parseBehaviorDecl`,
`parseShorthandInterfaceDecl` → `parseShorthandBehaviorDecl`, `parseInterfaceBody` →
`parseBehaviorBody`, `parseInterfaceMethod` → `parseBehaviorMethod`. The parsing logic is
unchanged; only the names and the keyword token differ.

**Acceptance:**
- [ ] `behavior Name { ... }` parses as a `BehaviorDecl`
- [ ] `interface Name { ... }` produces a parse error (keyword removed)
- [ ] All parser tests pass

### Step 3 — AST: rename `InterfaceDecl` to `BehaviorDecl`

In `ast.zig`, rename `InterfaceDecl` → `BehaviorDecl`, `InterfaceField` → `BehaviorField`,
`InterfaceMethod` → `BehaviorMethod`. Update `DeclKind.interface` → `DeclKind.behavior`.

Keep the old names as internal AST nodes for one milestone to ease the migration of downstream consumers (comptime, formatter, codegen), but the parser no longer produces them — all interface declarations produce `BehaviorDecl`.

**Acceptance:**
- [ ] `DeclKind` has a `.behavior` variant carrying `BehaviorDecl`
- [ ] `DeclKind.interface` is removed
- [ ] All AST consumers (comptime, formatter, codegen) updated to use the new names

### Step 4 — Comptime: update type environment

In `comptime/env.zig`, rename `TypeDef.interface` → `TypeDef.behavior` (if it exists). Update
`registerInterface` → `registerBehavior`. The type-checking logic is unchanged.

**Acceptance:**
- [ ] All comptime tests pass
- [ ] Diagnostic messages that mention "interface" updated to "behavior"

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `interface` is completely removed — using it produces a parse error
- [ ] `behavior` parses with the same semantics as the old `interface`
- [ ] No runtime behavior change — only the AST node and diagnostic text differ
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/behavior-keyword`; no push, no merge

## Blast radius

40 declarations in std + libs must be migrated (F8) — there is no deprecation path, the old
keyword is removed immediately. Every snapshot test that pins parser output, comptime
diagnostics, or codegen text will need re-recording (F2–F7). The migration is mechanical
(`interface` → `behavior`), and the volume is lower than the `type` migration.

The hard cutover (no deprecation period) is chosen because the migration is fully mechanical
and the volume is manageable. A deprecation period would double the maintenance cost (two
keywords, two AST paths, two sets of diagnostics) for one milestone with no benefit.

## Notes

This is a pure rename. No semantic change, no structural change. The motivation is clarity:
`behavior` better describes the concept than `interface`.

The `implement` keyword is unchanged. The `extends` keyword is unchanged. The method syntax
(`fn`, `default fn`, `declare fn`) is unchanged. The field syntax (`val`) is unchanged.

The only visible change is the keyword: `interface` → `behavior`.
