# Front 13 — Ecosystem migration

**Status:** not started. Carried whole from 1.0.3-beta front 03; the counts below were measured at
the meta repository's `6ecfd7cf` — re-measure after 10 and 11 land (both edit these libraries).

**Priority:** high — after [`../12-surface-cutover/`](../12-surface-cutover/README.md) the five
libraries do not compile against the compiler.
**Depends on:** [`../12-surface-cutover/`](../12-surface-cutover/README.md) (the compiler that accepts
only the 1.0.3 surface) · [`../11-dead-keywords-residual/`](../11-dead-keywords-residual/README.md)
(jhonstart's `.d.bp` accessors) · [`../10-library-repos/`](../10-library-repos/README.md) (erika's
7b/7c and emilia's gate)
**Owns:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` — sources, `.d.bp`, tests, examples,
their markdown docs and `AGENTS.md` · the submodule pointers of those five in the meta repository
**Does not touch:** `repository/botopink-lang/**` (12, 14), `repository/vscode-extension/**` (14)

---

## Current state

Measured at the meta repository's `feat` (`6ecfd7cf`):

| Library | `record` | `enum` | `interface` | `record { }` literals | Notes |
|---|---|---|---|---|---|
| emilia | 0 | 1 | 0 | 0 | `Token` with nested sections (`src/tokens.bp:37`) |
| erika | 7 | 0 | 0 | 6 | `src/erika.bp:570` generates `record { … }` **text** for the `select` projection |
| jhonstart | 2 | 0 | 2 | 10 | `hooks.bp` capabilities (`record { }`, `current`, `state`/`dispatch`); `html.bp` tokens; `@Context<Element, {}>` types |
| onze | 4 | 0 | 3 | 0 | `#[mock] interface` synthesis |
| rakun | 30 (3 in `src/`) | 1 | 2 | 0 | annotated fields `#[value("app.timezone")]` (`examples/rakun/src/config.bp:22`, `test/scopes_test.bp:64`); 10 records with methods and no fields (`examples/rakun/src/posts.bp:15`, `src/bootstrap.bp:30`) |

Markdown teaching the old syntax: 12 files, 29 occurrences.

## Steps — one worktree per library, in any order

For each library:

1. Migrate manually (beta phase — no automated codemod): `src/`, `test/`, `examples/`; `.md` files.
2. Library-specific edits:
   - **erika** — `erika.bp:570`: the generated projection becomes `#( … )` (`"#(" + parts.join(", ") + ")"`); the `Array<record { name, pop }>` comment in `examples/erika-linq/src/main.bp:95` becomes `Array<#(name: …, pop: …)>`. Rows are now tuples at runtime; the example's printed output is re-checked, not assumed.
   - **jhonstart** — `@Context<Element, {}>` → `@Context<Element, #()>`; `record { }` → `#()`.
   - **onze** — `#[mock] behavior`; confirm the mock synthesis reads `DeclKind.behavior`.
   - **rakun** — annotated fields keep their annotations inside the field list; records with no fields become `type Name { methods }`.
3. `botopink format` over the library; `botopink format --check` passes.
4. The library's test cell passes.

**Acceptance (per library):**
- [ ] No `record`, `enum`, `interface` keyword and no `record {` literal left (manual verification)
- [ ] `botopink format --check` passes
- [ ] `zig build test-libs` cell green, or no worse than its state when fronts 01–10 closed, with each remaining red linked to the front item that owns it
- [ ] Example programs run and their output matches the pre-migration output (captured before step 1)

## Gate

- [ ] Every library's acceptance above
- [ ] Meta repository submodule pointers bumped for the five libraries in one sweep commit, after each library's branch is merged into its own `feat`
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Branches `fix/1.0.3-syntax` in each library; no push, no merge

## Blast radius

113 declarations and 16 literals in `.bp` files, 12 markdown files. Runtime changes only where
anonymous records were built: erika rows and tokens, jhonstart capabilities and tokens — all read by
label inside `.bp` code.
