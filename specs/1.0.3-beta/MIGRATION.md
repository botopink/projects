# Migration Summary — 1.0.3-beta Hard Cutover

This document summarizes the keyword changes in 1.0.3-beta. **There is no deprecation period.**
The old keywords are removed immediately and produce parse errors.

## Keyword Changes

| Old Keyword | New Keyword | Status |
|---|---|---|
| `record` | `type` | **Removed** — produces parse error |
| `enum` | `type` | **Removed** — produces parse error |
| `interface` | `behavior` | **Removed** — produces parse error |
| `auto` | — | **Removed** — becomes valid identifier |
| `derive` | — | **Removed** — becomes valid identifier |
| `macro` | — | **Removed** — becomes valid identifier |
| `get` | — | **Removed** — becomes valid identifier |
| `opaque` | — | **Removed** — becomes valid identifier |
| `private` | — | **Removed** — becomes valid identifier |
| `set` | — | **Removed** — becomes valid identifier |
| — | `type` | **Added** — replaces `record`/`enum` |
| — | `behavior` | **Added** — replaces `interface` |
| — | `constructor` | **Added** — for record form 2 |

## What Changes

### 1. Type Declarations (`record`/`enum` → `type`)

**Before (1.0.2-beta):**
```bp
pub record Point { x: i32, y: i32 }
pub enum Color { Red, Green, Blue }
```

**After (1.0.3-beta) — Form 1 (preferred):**
```bp
pub type Point(x: i32, y: i32) {}
pub type Color { Red, Green, Blue }
```

**After (1.0.3-beta) — Form 2 (alternative):**
```bp
pub type Point { constructor(x: i32, y: i32) }
pub type Color { Red, Green, Blue }
```

The parser distinguishes record vs enum by:
- `(fields)` before `{` OR `constructor(...)` inside `{` → record
- Only `{variants}` → enum

### 2. Type Literals (`record { … }` → `type { … }`)

**Before:**
```bp
val p = record { x: 10, y: 20 };
```

**After:**
```bp
val p = type { x: 10, y: 20 };
```

Note: literals still use `{ }`, not `( )`. Only declarations use `( )` for fields.

### 3. Interface Declarations (`interface` → `behavior`)

**Before:**
```bp
pub interface Printable {
    fn print(self: Self),
}
```

**After:**
```bp
pub behavior Printable {
    fn print(self: Self),
}
```

## What Does NOT Change

- `implement` keyword — unchanged
- `extends` keyword — unchanged
- Method syntax (`fn`, `default fn`, `declare fn`) — unchanged
- Field syntax (`val`) — unchanged
- Constructor call syntax (`Point(x: 10, y: 20)`) — unchanged
- Pattern matching syntax — unchanged
- Runtime representation (maps, classes, atoms, tagged tuples) — unchanged

## Migration Scope

| Category | Count | Effort |
|---|---|---|
| `record` declarations in std + libs | 70 | Mechanical: `record Name { fields }` → `type Name(fields) {}` OR `type Name { constructor(fields) }` |
| `enum` declarations in std + libs | 30 | Mechanical: `enum` → `type` |
| `interface` declarations in std + libs | 40 | Mechanical: `interface` → `behavior` |
| `record { … }` literals | ~50 | Mechanical: `record` → `type` (still uses `{ }`) |
| Snapshot tests to re-record | All | Automated: re-run tests with `--re-record` |
| Dead keywords removed | 7 | No migration needed (never used) |

**Total: ~190 declarations + ~50 literals + all snapshots**

The 7 dead keywords (`auto`, `derive`, `macro`, `get`, `opaque`, `private`, `set`) are never
used in any `.bp` file, so no library code needs migration for them. They simply become valid
identifiers.

Records have two equivalent forms — choose one style per codebase:
- **Form 1** (preferred): `type Name(fields) { methods }` — fields in parentheses
- **Form 2** (alternative): `type Name { constructor(fields); methods }` — constructor in body

## Why Hard Cutover (No Deprecation)?

1. **Mechanical migration** — every change is a simple keyword substitution
2. **Manageable volume** — ~240 total changes across std + libs
3. **No semantic change** — runtime behavior is identical
4. **Avoids double maintenance** — no need to support two keywords, two AST paths, two sets of diagnostics for one milestone

## Acceptance Criteria

All old keywords must produce parse errors:

```bp
record Point { x: i32 }     // ERROR: unknown keyword 'record'
enum Color { Red }          // ERROR: unknown keyword 'enum'
interface Printable { }     // ERROR: unknown keyword 'interface'
```

Dead keywords become valid identifiers:

```bp
val auto = 10;              // OK: 'auto' is a valid identifier
val derive = "test";        // OK: 'derive' is a valid identifier
val macro = fn() {};        // OK: 'macro' is a valid identifier
val get = 42;               // OK: 'get' is a valid identifier
val set = 99;               // OK: 'set' is a valid identifier
```

All new keywords must work (both record forms):

```bp
type Point(x: i32, y: i32) {}               // OK: record-shaped TypeDecl (form 1)
type Point { constructor(x: i32, y: i32) }  // OK: record-shaped TypeDecl (form 2)
type Color { Red }                          // OK: enum-shaped TypeDecl
behavior Printable { }                      // OK: BehaviorDecl
```

## Migration Checklist

- [ ] Lexer: add `type`, `behavior`, `constructor` keywords; remove `record`, `enum`, `interface`
- [ ] Lexer: remove dead keywords (`auto`, `derive`, `macro`, `get`, `opaque`, `private`, `set`)
- [ ] Parser: unify `parseRecordDecl`/`parseEnumDecl` → `parseTypeDecl`
- [ ] Parser: support both record forms — `type Name(fields) {}` and `type Name { constructor(fields) }`
- [ ] Parser: rename `parseInterfaceDecl` → `parseBehaviorDecl`
- [ ] AST: introduce `TypeDecl`, remove `RecordDecl`/`EnumDecl`
- [ ] AST: rename `InterfaceDecl` → `BehaviorDecl`
- [ ] Comptime: update `registerRecord`/`registerEnum` to accept `TypeDecl`
- [ ] Comptime: rename `registerInterface` → `registerBehavior`
- [ ] Formatter: update `fmtRecord`/`fmtEnum` → `fmtType`, `fmtInterface` → `fmtBehavior`
- [ ] Codegen: update all backends to read `TypeDecl` and `BehaviorDecl`
- [ ] Libraries: migrate all `.bp` files (mechanical substitution)
- [ ] Tests: re-record all snapshots
- [ ] Tooling: update LSP completions, syntax highlighting, error messages
