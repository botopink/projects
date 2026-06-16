# emilia — styled / css / tw template engines + Style carrier for jhonstart

**Slug**: emilia
**Status**: **seeded — carry from Eric's authoring** (memory: `project_emilia_seed`).
Repo `botopink/emilia` already created (default `feat`, seed `f3b6ef7`).
The detailed spec lives on Eric's main work (drafted in a parallel
worktree, **NÃO committado** at v0.beta.20 open per the memory note).
This stub seats `emilia` into the v0.beta.20 scope table; pull Eric's
authored spec into this file when it is committed.

## Premise

emilia is a new sibling lib in the `repository/` family (alongside
`botopink-lang`, `jhonstart`, `rakun`, `erika`, `onze`,
`vscode-extension`). It ships the styled / CSS / tw template engines
used by the jhonstart React frontend framework, lowered via the
existing `@Expr`/`@ExprCustom` carrier (`expr-custom` v0.beta.10).

Per the memory note `project_emilia_seed`, the seed includes:

- `repository/emilia/` submodule wired in the meta (NOT committed).
- One edit on jhonstart: `attr` carrier in `libs/jhonstart/src/element.bp`
  + a `#attr` parse branch in `parser/exprs.zig` so per-component
  styles thread through the JSX-shape builders.

## Scope (carry from Eric's authoring)

The full surface description lives in Eric's authored spec — when it
lands in this file, replace this stub. The scope table row in the
v0.beta.20 README cites: `styled`/`css`/`tw` template engines + `Style`
carrier + `@Expr`/`@ExprCustom` lowering hooks; jhonstart attr carrier
+ `#attr` parse branch.

## Files (carry-forward)

- `libs/emilia/**` (new, in the new `repository/emilia/` submodule).
- `repository/emilia/` submodule wired into the meta `.gitmodules`.
- `libs/jhonstart/src/element.bp` (attr carrier).
- `parser/exprs.zig` (`#attr` branch).
- `libs/std/AGENTS.md` (sibling pointer row pointing at emilia).

## Next action

- [ ] Commit Eric's seed (`repository/emilia/` submodule pointer +
      this file replaced with the authored spec body + jhonstart attr
      edit).
- [ ] Open `.tasks/emilia/` worktree once the spec lands.

## Notes

- This stub keeps v0.beta.20's scope table row resolvable; pull Eric's
  authored content when it lands. Memory note `project_emilia_seed`
  is the authoritative pointer to the in-progress draft until then.
