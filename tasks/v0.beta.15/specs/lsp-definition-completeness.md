# lsp-definition-completeness — go-to-definition lands on fields, members, builtin methods & module refs

**Slug**: lsp-definition-completeness
**Depends on**: [`lsp-project-awareness`](../../v0.beta.14/specs/lsp-project-awareness.md) (definition + local-scope + project-graph machinery, DONE), [`sublanguage-lsp`](../../v0.beta.10/specs/sublanguage-lsp.md) (engine definition/hover plumbing, DONE), [`module-system`](../../v0.beta.11/specs/module-system.md) (`mod`/`pub mod` + sibling resolution, DONE)
**Files**: `modules/language-server/src/engine.zig` (`definition`, `definitionInModules`, `findDeclLocation`, the `dotCompletion` receiver-type resolution, `builtinInterfaceForType`, the record-member enumerator), `modules/language-server/src/project_graph.zig` (`mod`-sibling → file mapping), `libs/std/src/primitives.d.bp` (jump target for builtin methods, via `comptime.zig` `array_interface_src`/`string_interface_src`), `modules/language-server/src/tests/`
**Touches docs**: `modules/language-server/AGENTS.md`, `modules/language-server/src/docs.md`
**Status**: pending

> Go-to-definition resolves **top-level names and locals**, but is blind to almost
> everything a real `.bp` file is made of: **record fields**, **member access**, **builtin
> methods**, and **`mod` references**. Click a method and you jump — to the wrong target,
> by a lucky name match; click a field, a builtin call, or a module name and nothing
> happens. The cause is structural: definition is a token-keyword scan with no notion of
> "member of a type" or "module → file", even though the LSP already resolves a receiver's
> type, enumerates its fields for **completion** and **hover**, and resolves `mod` siblings
> for the **project graph**.

## The reproductions (each must gain a regression test)

In `libs/erika/src/erika.bp`, line 78:

```botopink
pub fn reverse(self: Self) -> Query<T> {
    return Query(items: self.items.reverse());
}
```

```
R1  cursor on `Query`            → jumps to `pub val Query = record {…}`        ✓ works today
R2  cursor on `.reverse`         → jumps to `pub fn reverse` … of `Query`        ✗ WRONG TARGET
R3  cursor on `items` (the `Query(items:)` label)  → nothing                    ✗ THE BUG
R4  cursor on `items` in `self.items`              → nothing                     ✗ THE BUG
R5  two records with a same-named method/field: `.reverse` must jump to the
    method on the *receiver's* record, not the first `fn reverse` in the file    ✗ latent
```

At line 82, inside `orderBy`:

```botopink
self.items.forEach({ x -> … });
```

```
R6  cursor on `forEach`          → nothing                                       ✗ THE BUG
```

In `libs/erika/src/root.bp`, line 10:

```botopink
pub mod erika;
```

```
R7  cursor on `erika`            → nothing (should open the `erika.bp` module)    ✗ THE BUG
```

R3/R4/R6/R7 are the user-visible failures. R2 looks like it works but is **already wrong**:
`self.items` is an `Array<T>`, so `.reverse` should resolve to the builtin `Array.reverse`,
yet the name scan jumps to `Query`'s *own* `pub fn reverse` (the first `fn reverse` token in
the file) — the same first-name-wins defect that R5 pins and that leaves R6 (no `fn forEach`
anywhere in the file) with nowhere to jump.

> Note: a sibling **highlighting** bug (the `mod` keyword was missing from the TextMate
> grammar's keyword alternation, `syntaxes/botopink.tmLanguage.json`) was fixed alongside
> R7 — `mod` is lexical, not LSP, so it is not a step here, only noted for context.

## Root cause (verified on `feat`)

- **`definition`** (`engine.zig:486`) tries `localDefinition` (params / `val` / `var` /
  closure binders) then **`findDeclLocation`** and stops.
- **`findDeclLocation`** (`engine.zig:438`) scans `tokens` for a **declaration keyword**
  — `{ val, var, fn, record, struct, enum, interface }` (`engine.zig:447`) — immediately
  followed by an identifier equal to the name. A **record field** is spelled
  `items: Array<T>` with **no preceding keyword**, so it is *never* a candidate → R3/R4.
  `mod` is likewise absent from the keyword set, and a module name does not even *have* a
  same-file declaration token — the declaration *is the sibling file* → R7.
- **Methods resolve by accident**: `.reverse()` matches `pub fn reverse` purely because
  the bare lexeme `reverse` appears after an `fn` keyword *somewhere* in the file. The
  receiver type is never consulted → R2 works but R5 fails (first `fn`-of-that-name wins).
- **Builtin-type methods have no `fn` in the file at all** (R6): `forEach`/`map`/`filter`
  live on the `Array<T>` builtin interface, whose source is the embedded
  `array_interface_src` / `string_interface_src` (`comptime.zig:351-352`), backed by the
  **real file `libs/std/src/primitives.d.bp`**. The name scan finds no `fn forEach` in
  `erika.bp`, so it returns nothing — even though hover already resolves these methods via
  `builtinInterfaceForType` (`engine.zig:3360`) + `builtinReceiverCompletion`
  (`engine.zig:3531`).
- The information needed already exists, just not on the definition path:
  - **`dotCompletion`** (`engine.zig:2992`, "Case 2 — the receiver is a value")
    resolves a receiver value to its **named type**, then enumerates that type's members.
  - **`builtinInterfaceForType`** (`engine.zig:3360`) maps `Array`/`string`/`i32`/`bool`/…
    to the embedded interface source that hover and completion already consume.
  - The **record-member enumerator** behind document symbols (`engine.zig:610` region,
    `decl_values` at `engine.zig:622`) already walks a `record { … }` body and yields
    each field/method **name token + location**.
  - **`project_graph.zig`** already maps `mod`/`pub mod` siblings to every `.bp` under the
    project's `src/` tree (`project_graph.zig:12,142`).
  Definition must reuse these: resolve the receiver type and point at the member's declared
  name token (inside the record body for user types, inside `primitives.d.bp` for builtin
  receivers), and resolve a `mod` name to its sibling file via the project graph.

## Steps

### F0 — reproductions first
- [ ] Add failing tests under `modules/language-server/src/tests/` for R2–R7 using the
      **real erika shape** (a `record` with fields + methods, a `Name(field: …)`
      constructor call, `self.field` inside a method, a builtin call `xs.forEach(…)`, and a
      `pub mod <name>;` over a sibling file). They must fail on `feat` — including R2, which
      asserts the jump lands on `Array.reverse`, not `Query`'s own `reverse`.

### F1 — member-access definition (`recv.field` / `recv.method`) — R2, R4, R5
- [ ] When the cursor sits on the **member name** of a `recv.member` access (detect the
      `.` to the left, mirroring `dotContext`/`prefixAt` used by completion), resolve the
      receiver's **named type** with the same logic as `dotCompletion` Case 2, then locate
      the field-or-method named `member` **inside that record's body** and return its name
      token location. This makes resolution type-aware (fixes R5, corrects R2) and reaches
      fields (fixes R4). Falls back to the current name scan only when the receiver type is
      unknown (so today's same-file jumps never regress).

### F1b — builtin-receiver methods → `primitives.d.bp` — R6
- [ ] When the receiver's type is a **builtin** (`Array`/`string`/numeric/`bool`/…), route
      through `builtinInterfaceForType` (`engine.zig:3360`) to the embedded interface source
      and run `findDeclLocation` over **`libs/std/src/primitives.d.bp`** to return the
      method's declaration there. This reuses the exact resolution hover already performs
      (`builtinReceiverCompletion`/the builtin hover at `engine.zig:3560`); the jump target
      is a real on-disk URI, so no virtual-document plumbing is needed.

### F2 — `self.field` — R4 (the erika case)
- [ ] Resolve `self` (param `self: Self`) to the **enclosing record** declaration, so
      `self.items` inside a method jumps to the `items` field. `Self` ⇒ the record whose
      body lexically encloses the cursor.

### F3 — named constructor-argument labels (`Name(field: …)`) — R3
- [ ] When the cursor is on a **labeled argument name** in a constructor/record-literal
      call `Name(field: …)`, resolve `Name` to its record declaration and jump to the
      `field` declaration. (The label is an identifier followed by `:` inside a call whose
      callee is a record type.)

### F4 — `mod` reference → sibling module file — R7
- [ ] When the cursor is on the **name of a `mod` / `pub mod` declaration**, resolve it
      through `project_graph.zig`'s sibling map to the backing file (`<name>.bp` or
      `<name>/mod.bp`) and return a Location at the file's start (or its `pub mod`/root
      decl). This is a file-level jump, not a token scan — the module *is* the file.

### F5 — cross-module fields
- [ ] Extend `definitionInModules` (`engine.zig:504`) so a field/method on a receiver
      whose type is declared in **another module** (or an embedded `"std"` module) jumps
      there too, honoring `require_pub` for the field's owning declaration.

### F6 — docs + tests
- [ ] Note the new member/module resolution paths in `modules/language-server/AGENTS.md`
      and `docs.md`. Keep `zig build test` + `botopink-lib-test` green; add snapshot/unit
      coverage for F1–F5.

## Non-goals

- No new LSP capability is added (`definitionProvider` already advertised). No language
  surface changes.
- Tuple-field access (`p._0`) and interface associated-function dispatch are out of scope;
  this spec is records (fields + methods), builtin methods, named constructor labels, and
  `mod` references only.

## Done

R2–R7 resolve in `libs/erika/src/{erika,root}.bp` (and the regression fixtures), method
go-to-def is type-aware (builtin and user types) without regressing the existing name-based
jumps, `mod` names open their backing file, and the full suite (`zig build test` +
`botopink-lib-test`) stays green.
