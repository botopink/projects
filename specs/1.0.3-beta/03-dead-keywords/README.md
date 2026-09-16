# Front 03 — Remove dead keywords

**Priority:** medium — the lexer carries 8 keywords that are never consumed by the parser, never
appear in `.bp` files, and never reach the AST. They are noise in the keyword table and confusion
for language users.
**Depends on:** F1 (parser + AST)
**Owns:** `lexer/token.zig`, `lexer.zig` · `snapshots/lexer/`
**Does not touch:** `parser/**` (F1), `comptime/**` (F2), `format.zig` (F3), `codegen/**` (F4–F7), `libs/**` (F8)

---

## Problem

The lexer maps 48 strings to keyword tokens. Eight of them are never consumed:

| Keyword | TokenKind | Parser usage | .bp usage | AST | Reserved |
|---|---|---|---|---|---|
| `auto` | `.auto` | ❌ | ❌ | ❌ | ✅ |
| `const` | — (not mapped) | ❌ | ❌ | ❌ | — |
| `derive` | `.derive` | ❌ | ❌ | ❌ | ✅ |
| `get` | `.get` | ❌ | ❌ | ❌ | ❌ |
| `macro` | `.macro` | ❌ | ❌ | ❌ | ✅ |
| `opaque` | `.@"opaque"` | ❌ | ❌ | ❌ | ❌ |
| `private` | `.private` | ❌ | ❌ | ❌ | ❌ |
| `set` | `.set` | ❌ | ❌ | ❌ | ❌ |

These keywords add cognitive load (users wonder what they do), increase the keyword table size,
and serve no purpose.

## Current state

Measured at HEAD:

- `auto`, `derive`, `macro` are in `isReservedWord` (cannot be used as identifiers) but are
  never consumed by the parser
- `const` is not even mapped in `keywordOrIdent` (comment: "reserved, not used in surface syntax;
  use `val` instead")
- `get`, `opaque`, `private`, `set` are mapped to tokens but never matched by the parser

## Mechanism

The lexer's `keywordOrIdent` function (`lexer.zig:693–746`) maps strings to tokens. The parser
matches tokens in `parser.zig` and `parser/decls.zig`/`parser/exprs.zig`. A keyword is "dead"
if:

1. It is mapped in `keywordOrIdent` (or exists as a `TokenKind`)
2. No parser code matches that token
3. No `.bp` file uses it
4. No AST node references it

## Proposal — remove dead keywords

### Step 1 — Remove from `keywordOrIdent`

In `lexer.zig:693–746`, delete the `if` branches for:

```zig
if (std.mem.eql(u8, text, "auto")) return .auto;           // DELETE
if (std.mem.eql(u8, text, "derive")) return .derive;       // DELETE
if (std.mem.eql(u8, text, "get")) return .get;             // DELETE
if (std.mem.eql(u8, text, "macro")) return .macro;         // DELETE
if (std.mem.eql(u8, text, "opaque")) return .@"opaque";    // DELETE
if (std.mem.eql(u8, text, "private")) return .private;     // DELETE
if (std.mem.eql(u8, text, "set")) return .set;             // DELETE
```

`const` is already not mapped (no action needed).

### Step 2 — Remove from `TokenKind` enum

In `lexer/token.zig:64–113`, delete the token variants:

```zig
auto,        // DELETE
derive,      // DELETE
get,         // DELETE
macro,       // DELETE
@"opaque",   // DELETE
private,     // DELETE
set,         // DELETE
```

### Step 3 — Remove from `isReservedWord`

In `lexer.zig:753`, update `isReservedWord` to remove:

```zig
.auto, .derive, .macro   // DELETE from the switch
```

After removal, `auto`, `derive`, `macro` become valid identifiers (they are no longer reserved).

### Step 4 — Update tests

- `lexer/tests/` — remove any tests that reference the dead keywords
- `parser/tests/` — remove any tests that reference the dead keywords
- Snapshot tests — re-record if any diagnostic text mentioned these keywords

**Acceptance:**
- [ ] `auto`, `derive`, `macro`, `get`, `opaque`, `private`, `set` are no longer keywords
- [ ] They can be used as identifiers: `val auto = 10;` compiles
- [ ] `const` remains unmapped (no change)
- [ ] `zig build test` green
- [ ] Lexer snapshot tests updated

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] The 7 dead keywords are no longer recognized
- [ ] They can be used as identifiers
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/dead-keywords`; no push, no merge

## Blast radius

Low. These keywords are never used in any `.bp` file, so no library code needs migration. The
only impact is on lexer/parser tests that may reference them.

## Notes

The reserved words `auto`, `derive`, `macro` were likely planned for future features but never
implemented. Removing them now does not close the door forever — they can be re-added if needed.
The cost of re-adding is low (one line in `keywordOrIdent`, one variant in `TokenKind`); the
cost of keeping dead keywords is ongoing cognitive load and maintenance.

`const` is intentionally not mapped (the comment says "use `val` instead"). No action needed.
