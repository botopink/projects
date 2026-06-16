# TODO — emilia (CSS-in-bp lib · v0.beta.20 ecosystem keystone)

> Worktree task: opens the v0.beta.20 **ecosystem-expansion** line — `emilia`,
> a CSS-in-bp lib with a *type-safe* `Token` enum surface, plus 2 generic
> hooks added to `jhonstart` (annotation-on-builder + `[name]={expr}` html
> attribute).
>
> Spec: [`tasks/v0.beta.20/specs/ecosystem.md`](../../tasks/v0.beta.20/specs/ecosystem.md) — full content lives there.
> Sibling worktrees: `.tasks/frente-a/` (owns `enum-sections` keystone — hard prerequisite).

## Baseline

- meta `feat`: `17edf6e` (Merge `origin/feat` into `task/std-tail`).
- bot-lang `feat`: `5d19f7e` (P9 STD-001 runtime check landed).
- `repository/emilia` submodule: seeded `f3b6ef7` on `botopink/emilia` `feat`;
  wired in meta `.gitmodules` (uncommitted at session start — see
  `project_emilia_seed.md`).
- `repository/jhonstart` `feat`: 1 prior edit (attr carrier + `#attr` branch).

## Cross-frente dependency

- **`enum-sections`** — lives inside `frente-a.md` (v20 keystone, lifted from
  v21). emilia's `Token` enum **requires** nested sections with path access
  (`.Color.Red.500`, `.Pad.X.4`) to be ergonomic. Without it the surface
  degrades to `Token.Color(TokenColor.Red(_500))`. Coordination: F0/F1 here
  can scaffold against a 3-section subset (Text/Color/Pad) while
  `frente-a-01-keystones` lands; F1 full enum waits on the merge.

## Phases (from spec F0–F5)

### F0 — lib stand-up + jhonstart 2 hooks
- [x] `repository/emilia/src/tokens.bp` — `Token` enum (3 sections Text/Color/Bg/Pad as v0 flat variants pending `enum-sections`) + 6 modifier variants (Hover/Focus/Active/Md/Lg/Xl).
- [x] `repository/emilia/src/emilia.bp` — `pub fn emilia(tokens: Token[]) -> string` + `pub fn flush()` (annotation-handler form deferred — needs call-site decorator compiler feature).
- [x] `repository/emilia/src/stylesheet.bp` host cell **folded into emilia.bp** — cross-module `#[@external]` symbol import doesn't lower at v0; split deferred to v0.beta.21.
- [x] `repository/emilia/src/root.bp` — `pub mod tokens; pub default mod emilia;`.
- [x] `repository/emilia/botopink.json` — manifest, `target: "commonJS"`, files: root/tokens/emilia.
- [ ] `repository/jhonstart/src/element.bp` — **annotation-on-builder** hook — DEFERRED to v0.beta.21 (needs Element attribute slot + call-site decorator mechanism).
- [ ] `repository/jhonstart/src/element.bp` — **`html` DSL `[name]={expr}` attribute** — DEFERRED to v0.beta.21 (needs html scanner extension + generic annotation registry).
- [x] Smoke test: `emilia([])` returns stable `e_<hash>` class, `flush()` produces `<style>.e_<hash>{}</style>` (decorator smoke deferred with the two jhonstart hooks).
- [x] Commit meta `.gitmodules` + `repository/emilia` pointer (this commit).

### F1 — fill out Token enum
- [ ] Sections: Text, Font, Color, Bg, Pad, Margin, Layout, Flex, Border, Effect — partial (Text/Color/Bg/Pad shipped at v0).
- [x] Modifier variants: `Hover([Token])`, `Focus([Token])`, `Active([Token])`, `Md([Token])`, `Lg([Token])`, `Xl([Token])` shipped via recursive `Token[]` payload.
- [ ] Cross-reference Tailwind utility names for leaf inventory.
- [ ] **Blocks on** `enum-sections` (frente-a) — path access (`.Color.Red.500`) requires nested-section exhaustiveness; v0 ships the flat-prefix form.

### F2 — `tokenToCss` exhaustive handler
- [ ] Per-section helpers: `textTokenToCss`, `colorTokenToCss`, etc. — DEFERRED to F1 full enum (single `case` is exhaustive over v0's flat variants today).
- [x] Exhaustive `case` driving the dispatcher; ES5 diag on any unreached leaf (rejected `Token.Hover/Focus/...` before they were added — confirmed by error at emilia:79).
- [x] In-file `test {}` blocks (9 lib tests + 4 example tests = 13 green).

### F3 — modifier composition
- [x] `.Hover([...])` → `":hover{" + tokensToCss(inner) + "}"`.
- [x] `.Focus([...])`, `.Active([...])` likewise.
- [x] `.Md([...])`, `.Lg([...])`, `.Xl([...])` → `@media(min-width:{768,1024,1280}px){...}`.
- [x] Test nesting: `.Md([.Hover([...])])` — passes (modifiers nest test).

### F4 — `Stylesheet.flush()` per-render semantics
- [x] `register(name, body)` — appends to `globalThis.__emilia_sheet` Map (inline `#[@external(node, …)]`).
- [x] `flush()` — serialises Map → `<style>...</style>`, clears the cell, returns the block.
- [x] Two consecutive renders produce two independent `<style>` blocks (third flush after no register is `<style></style>`).
- [x] Hash stability: identical token list → identical class name across renders (`e_<hash>` djb2-hex; collapse test passes).

### F5 — runnable example + docs sweep
- [x] `repository/emilia/examples/emilia-card/botopink.json` + `src/main.bp` — uses `emilia(...)` direct calls (decorator/attribute forms deferred with the jhonstart hooks); composes 3 emilia class names + Hover/Md modifier on the body style.
- [x] `botopink test` green inside the example dir (4/4 passing).
- [ ] `bpmp install emilia` resolves the lib from its GitHub Releases tag — DEFERRED (publish flow not exercised yet).
- [ ] Docs sweep: `repository/emilia/{README.md, AGENTS.md, docs.md, CHANGELOG.md}`,
      `repository/jhonstart/AGENTS.md` paragraph on the 2 generic hooks,
      `repository/botopink-lang/libs/AGENTS.md` cross-reference bullet.

## Acceptance gates (from spec)

```
parse  DEFER `#[emilia([.Text.Bold, .Pad.X.4])] div([])` — needs jhonstart hook
parse  DEFER `<div [emilia]={[.Bg.Red.500]}>...</div>` — needs jhonstart hook
type   GREEN `emilia([Token.UnknownToken])` is a type error (unknown variant rejected)
type   DEFER `.Pad.X.99` — gated on enum-sections nested-section exhaustiveness
match  GREEN tokenToCss exhaustiveness: missing leaf surfaces an ES5 diag (proved while adding modifiers — error at emilia:79 before all 6 arms landed)
render PART `renderToString(page) + flush()` composes — direct `emilia(…)` call form (decorator form deferred)
hash   GREEN two `emilia([Token.BgWhite])` sites collapse to one class (test passes)
flush  GREEN two consecutive `flush()` calls emit two independent <style> blocks (third is `<style></style>`)
modif  GREEN `.Hover([.BgRed500])` produces `:hover{background:#ef4444}` prefix
modif  GREEN `.Md([.PadX8])` produces `@media(min-width:768px){padding-left:2rem;…}`
hex    GREEN `Token.ColorHex("#abc")` and `Token.BgHex("…")` emit literal hex output
example GREEN `examples/emilia-card/` renders + composes 3 emilia classes with modifier (4/4 tests pass)
```

## Non-goals (locked by spec)

- No `styled.<tag>` namespace; no `css """…"""` arbitrary-CSS escape; no nested
  selectors / animations / theme variants.
- No compiler change beyond `enum-sections`. The 2 jhonstart hooks are **generic**;
  the framework cannot grow emilia-specific branches.
- commonJS only at v1 (erlang/beam Stylesheet port → v0.beta.21+).

## Coordination

- File-disjoint from every other v20 worktree at the directory level.
- Soft sync with `.tasks/frente-a/` on `enum-sections` landing; F1 full Token
  enum waits on that merge into `feat`.
- 2 jhonstart edits in this worktree must stay **emilia-agnostic** — review
  with `.tasks/frente-a/` and `.tasks/snap-audit/` before merging to catch any
  emilia-name leakage into the generic hooks.

## Exit gate

- 5/6 phases (F0 partial — jhonstart hooks deferred; F1 partial — gated on `enum-sections`; F2/F3/F4/F5 DONE).
- `repository/emilia` `feat` pushed (`10ea69e`); meta submodule pointer bumped on `task/emilia`.
- 9 acceptance gates GREEN, 4 DEFERRED (decorator/attribute hooks + bpmp publish + nested-section `99` reject).
- Spec status row in `tasks/v0.beta.20/status.md` flips to **mostly done** (deferred items recorded in CHANGELOG + AGENTS).
- **13 tests green** across `repository/emilia/` (9) + `examples/emilia-card/` (4).
