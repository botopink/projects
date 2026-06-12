# v0.beta.15 — go-to-definition lands where real code lives

> A single keystone spec ([`lsp-definition-completeness`](specs/lsp-definition-completeness.md)),
> the direct follow-up to v0.beta.14's [`lsp-project-awareness`](../v0.beta.14/specs/lsp-project-awareness.md).
> v0.beta.14 made completion/definition/hover **survive real project files** (multi-module,
> decorator-emitting, `from "<lib>"`). This version makes **go-to-definition actually land on
> the things a `.bp` file is made of**: record fields, member access, builtin methods, and
> `mod` references — not just top-level names and locals.

## Why this exists

Definition today is a **token-keyword scan** with no notion of "member of a type" or
"module → file". It only matches a declaration keyword (`val/var/fn/record/struct/enum/
interface`) followed by the name. So:

| Click on | Today | Should |
|---|---|---|
| `.reverse` on an `Array<T>` | jumps to `Query`'s own `fn reverse` (lucky name match) | `Array.reverse` in `primitives.d.bp` |
| `items` in `Query(items: …)` | nothing | the `items` field decl |
| `items` in `self.items` | nothing | the `items` field decl |
| `.forEach` (builtin, no `fn` in file) | nothing | the builtin interface method |
| `pub mod erika;` | nothing | opens `erika.bp` |

The information needed **already exists** on the completion/hover path (receiver-type
resolution, the record-member enumerator, `builtinInterfaceForType`, the project graph) —
it's just not wired into the definition path.

## Scope

| Spec | Area | Files |
|---|---|---|
| [lsp-definition-completeness](specs/lsp-definition-completeness.md) | member-access def · builtin-method def → `primitives.d.bp` · `self.field` · named ctor labels · `mod` → sibling file · cross-module fields | `modules/language-server/src/{engine,project_graph}.zig`, `libs/std/src/primitives.d.bp` (jump target), `modules/language-server/src/tests/` |

This is **LSP-side** work. It adds no language surface — only makes go-to-definition
type-aware and reach the members it currently misses.

## Goal

In `libs/erika/src/{erika,root}.bp` (and the regression fixtures), R2–R7 all resolve:
methods jump type-aware (builtin and user types), fields and named ctor labels jump to their
declaration, `self.field` jumps to the enclosing record, and `mod` names open their backing
file — without regressing today's name-based jumps. `zig build test` + `botopink-lib-test`
stay green.
