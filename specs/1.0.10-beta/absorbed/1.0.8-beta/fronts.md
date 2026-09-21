# Fronts — 1.0.8-beta

## Ownership

| Front | Repo | Source it owns | Tests it owns |
|---|---|---|---|
| **F01 emilia-layout** | emilia | `src/tokens.bp` (Layout section expansion) | `test/layout_test.bp` |
| **F02 emilia-grid** | emilia | `src/tokens.bp` (Grid section), `src/emilia.bp` (gridTokenToCss) | `test/grid_test.bp` |
| **F03 emilia-spacing-sizing** | emilia | `src/tokens.bp` (Pad/Margin expansion, Size section), `src/emilia.bp` (sizeTokenToCss) | `test/spacing_test.bp` |
| **F04 emilia-typography** | emilia | `src/tokens.bp` (Text/Font expansion, new sections), `src/emilia.bp` (typography dispatchers) | `test/typography_test.bp` |
| **F05 emilia-backgrounds** | emilia | `src/tokens.bp` (Bg expansion, Gradient section), `src/emilia.bp` (bgTokenToCss expansion) | `test/backgrounds_test.bp` |
| **F06 emilia-borders** | emilia | `src/tokens.bp` (Border expansion, Outline section), `src/emilia.bp` (borderTokenToCss expansion) | `test/borders_test.bp` |
| **F07 emilia-effects** | emilia | `src/tokens.bp` (Effect expansion, Blend section, Mask section), `src/emilia.bp` (effectTokenToCss expansion) | `test/effects_test.bp` |
| **F08 emilia-filters** | emilia | `src/tokens.bp` (Filter section, BackdropFilter section), `src/emilia.bp` (filterTokenToCss) | `test/filters_test.bp` |
| **F09 emilia-tables** | emilia | `src/tokens.bp` (Table section), `src/emilia.bp` (tableTokenToCss) | `test/tables_test.bp` |
| **F10 emilia-transitions** | emilia | `src/tokens.bp` (Transition section, Animate section), `src/emilia.bp` (transitionTokenToCss) | `test/transitions_test.bp` |
| **F11 emilia-transforms** | emilia | `src/tokens.bp` (Transform section), `src/emilia.bp` (transformTokenToCss) | `test/transforms_test.bp` |
| **F12 emilia-interactivity** | emilia | `src/tokens.bp` (Interact section), `src/emilia.bp` (interactTokenToCss) | `test/interactivity_test.bp` |
| **F13 emilia-svg-accessibility** | emilia | `src/tokens.bp` (Svg section, A11y section), `src/emilia.bp` (svgTokenToCss, a11yTokenToCss) | `test/svg_a11y_test.bp` |
| **F14 emilia-color-palette** | emilia | `src/tokens.bp` (Color/Bg full palette expansion) | `test/colors_test.bp` |
| **F15 emilia-modifiers** | emilia | `src/tokens.bp` (modifier variants expansion), `src/emilia.bp` (modifier dispatch) | `test/modifiers_test.bp` |

## Conflict Matrix

|  | F01 | F02 | F03 | F04 | F05 | F06 | F07 | F08 | F09 | F10 | F11 | F12 | F13 | F14 | F15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **F01** | — | no¹ | no¹ | no¹ | no¹ | no¹ | no¹ | yes | yes | yes | yes | yes | yes | no¹ | no¹ |
| **F02** | no¹ | — | no¹ | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | no¹ | no¹ |
| **F03** | no¹ | no¹ | — | no¹ | no¹ | no¹ | no¹ | yes | yes | yes | yes | yes | yes | no¹ | no¹ |
| **F04** | no¹ | yes | no¹ | — | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | no¹ |
| **F05** | no¹ | yes | no¹ | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | no¹ | no¹ |
| **F06** | no¹ | yes | no¹ | yes | yes | — | yes | yes | yes | yes | yes | yes | yes | no¹ | no¹ |
| **F07** | no¹ | yes | no¹ | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | no¹ | no¹ |
| **F08** | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes | yes |
| **F09** | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes | yes |
| **F10** | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes | yes |
| **F11** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes | yes |
| **F12** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes | yes |
| **F13** | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | — | yes | yes |
| **F14** | no¹ | no¹ | no¹ | yes | no¹ | no¹ | no¹ | yes | yes | yes | yes | yes | yes | — | no¹ |
| **F15** | no¹ | no¹ | no¹ | no¹ | no¹ | no¹ | no¹ | yes | yes | yes | yes | yes | yes | no¹ | — |

### Conflict Notes

1. **tokens.bp shared:** Todos os fronts tocam `tokens.bp` (adicionando seções ao Token enum) e `emilia.bp` (adicionando dispatchers). **Sequenciamento obrigatório:** cada front adiciona APENAS sua seção e seu dispatcher — sem tocar nas seções de outros fronts. O `tokenToCss` principal ganha um novo braço por front. Merge manual necessário se dois fronts rodarem em paralelo (cada um em branch separada, merge no feat).
2. **F14 (colors) + F15 (modifiers) + F03 (spacing) são pré-requisitos:** Os outros fronts referenciam cores, modifiers e spacing scale. Rodar em Phase 1 garante que Phase 2 tenha tudo disponível.
3. **F08–F13 são independentes entre si:** Cada um adiciona uma seção nova e isolada. Podem rodar em paralelo sem conflito de conteúdo (apenas merge do `tokenToCss` switch).

## Order

```
Phase 1 (Foundation — 3 in parallel):
  F14 (colors) ──┐
  F15 (modifiers) ┤
  F03 (spacing/sizing) ─┘
                        │
Phase 2 (Core utilities — 5 in parallel):
  F01 (layout) ────────┐
  F02 (grid) ──────────┤
  F04 (typography) ────┤
  F05 (backgrounds) ───┤
  F06 (borders) ───────┘
                        │
Phase 3 (Advanced — 5 in parallel):
  F07 (effects) ───────┐
  F08 (filters) ───────┤
  F09 (tables) ────────┤
  F10 (transitions) ───┤
  F11 (transforms) ────┘
                        │
Phase 4 (Polish — 2 in parallel):
  F12 (interactivity) ─┐
  F13 (svg/a11y) ──────┘
```

**Critical path:** F14 → F05 (backgrounds usam cores) → F07 (effects usam cores para shadow)

**Parallelism:**
- Phase 1: F14 ∥ F15 ∥ F03 (seções distintas: Color/Bg, modifiers, Pad/Margin/Size)
- Phase 2: F01 ∥ F02 ∥ F04 ∥ F05 ∥ F06 (seções distintas: Layout, Grid, Text/Font, Bg, Border)
- Phase 3: F07 ∥ F08 ∥ F09 ∥ F10 ∥ F11 (seções distintas: Effect, Filter, Table, Transition, Transform)
- Phase 4: F12 ∥ F13 (seções distintas: Interact, Svg/A11y)

## Rules for a Front

1. **One worktree, one branch, one `todo.md`** — `git worktree add .tasks/<front-name> -b fix/<front-name>` from `repository/emilia/`
2. **Only edit your sections** — add new sections to `tokens.bp`, add dispatchers to `emilia.bp`, add tests to `test/<front>_test.bp`. Never modify another front's section.
3. **Exhaustive case** — every new section must have a complete `case` with no `_` catch-all.
4. **Tailwind values** — CSS output must match Tailwind CSS v4.3 exactly.
5. **Dual-target** — verify on commonJS and erlang.
6. **Verify by running** — `botopink test` green with new tests included.
7. **Land:** merge into `feat`, suite green, push, submodule bump in meta repo.
