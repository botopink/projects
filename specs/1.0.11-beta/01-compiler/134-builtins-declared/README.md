# Front 134 — builtins-declared: every builtin declared in `builtins.d.bp`, and held to it

**Priority:** high — decision 252: a builtin the user calls has its full declaration — its type, its
static and its instance methods — in `libs/std/src/builtins.d.bp`, and the compiler checks the
implementation against that declaration.
**Depends on:** nothing. `@typeInfo`'s declaration waits on the naming of its catalogue (`TypeInfo.all`
or `@typeInfo.all`) and on `dec-e` (what `all` answers); every other builtin can be declared now.
**Owns:** `libs/std/src/builtins.d.bp`, `libs/std/src/builtins_fns.d.bp`, the compiler's builtin
table and the check that ties it to the declarations (`modules/compiler-core/src/comptime/` — the
place where `@name(…)` calls are resolved), `docs.md` § builtins, the cells under
`tests/language/reject/` for a builtin whose implementation disagrees with its declaration, and the
`AGENTS.md` of each directory touched.
**Does not touch:** what a builtin does on any backend (a builtin whose behavior is wrong is its
owner front's); decorator outputs (130).

---

## Problem

Measured 2026-10-03 on `feat`: `builtins.d.bp` declares `@print`, `@println`, `@debug`, `@field`,
`@trap`, `@emit`, `@module` and `@getContext`, and the types `Declared<T>` / `DeclaredMeta` that
`@typeInfo.all` answers — but not `@typeInfo` itself, its `all`, `@src`, `@todo`, `@panic`, `@name`,
`@external`, `@expr`, and others only the compiler knows (`@block`, `@compilerError`, `@typeName`, …).
A user cannot read their signature anywhere, the editor cannot show it, and nothing keeps the
compiler's behavior and the documented surface in step.

## Decision 252

1. Every builtin reachable from a program — a `@name(…)` call, a `@name` type or value, a builtin
   type with static members (`TypeInfo.all`) — is declared in `builtins.d.bp` (or
   `builtins_fns.d.bp`): a function as `pub declare fn`, a type as `pub type` with its fields, its
   instance methods and its static methods as `declare fn` inside the type (the house rule for a
   host function with an owner).
2. The compiler refuses a builtin it implements but the declarations do not name, and a declaration
   whose signature differs from what the compiler accepts — checked once, by a unit test over the
   builtin table and the parsed declarations, so the two cannot drift.
3. `docs.md` documents each builtin from its declaration.

## Steps

### Step 1 — the inventory

Every name the compiler treats as a builtin (call, type, value, comptime-only), where it is resolved
(file:line), its accepted signature, and whether `builtins.d.bp` declares it — one table in this
README.

**Acceptance:**
- [ ] the table, complete: a builtin the compiler accepts and the table omits is a defect of this step

### Step 2 — declare them

Each undeclared builtin gets its declaration, comptime-only ones marked as such (`comptime`
parameters, a doc comment saying it never reaches run time). `@typeInfo` is declared as a type
(`TypeInfo<T>` with `name`, `module`, `fields`, `methods`, `meta` and its static catalogue) once the
catalogue's name and `dec-e` are answered.

**Acceptance:**
- [ ] every row of step 1 declared; `docs.md` § builtins generated from or checked against them

### Step 3 — the check

A unit test parses `builtins.d.bp` and walks the compiler's builtin table: every builtin declared,
every declaration implemented, signatures equal. A `reject/` cell where a program calls a builtin
with arguments the declaration refuses, located.

**Acceptance:**
- [ ] removing one declaration or changing one signature turns the test red, naming the builtin
- [ ] `zig build test`, `test-language`, `test-docs` green

## Gate

- [ ] `scripts/gate.sh --cold` green on the integrated branch
- [ ] `bash scripts/format-check.sh` and `zig fmt --check modules` before every commit
- [ ] every `AGENTS.md` of a touched directory updated in the same commit
- [ ] commits on `front/134-builtins-declared`; no push, no merge — landing is the coordinator's step
