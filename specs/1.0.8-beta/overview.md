# Specs — 1.0.8-beta (emilia: Tailwind CSS completo)

O milestone 1.0.8-beta expande **emilia** — a lib CSS-in-bp — para cobrir a totalidade dos recursos do Tailwind CSS v4.3. Atualmente emilia tem ~10 seções de tokens (Text, Font, Color, Bg, Pad, Margin, Layout, Flex, Border, Effect) com cobertura parcial. Este milestone adiciona **~180 novos tokens** organizados em **15 fronts**, expandindo a superfície para cobrir Layout, Grid, Sizing, Tipografia avançada, Backgrounds (gradientes), Borders (outline), Effects (shadow/text-shadow/opacity/blend/mask), Filters, Tables, Transitions, Animations, Transforms, Interactivity, SVG, Accessibility, paleta de cores completa (17 famílias × 11 tons) e novos modifiers (breakpoints Sm/2Xl, Dark, Visited, First/Last/Odd/Even, Disabled, Group/Peer, etc.).

| Front | Prioridade | Repo | Descrição |
|---|---|---|---|
| [`01-emilia-layout/`](./01-emilia-layout/README.md) | **critical** | emilia | Display expandido, position, overflow, visibility, z-index, float, clear, isolation, object-fit/position, aspect-ratio, columns, break-* |
| [`02-emilia-grid/`](./02-emilia-grid/README.md) | **critical** | emilia | Grid template columns/rows, grid column/row span, grid-auto-*, gap expandido, justify/align/place completo |
| [`03-emilia-spacing-sizing/`](./03-emilia-spacing-sizing/README.md) | **critical** | emilia | Scale completa de Pad/Margin (0–96 + px + full + auto), Width/Height/Min/Max, logical properties (inline/block-size) |
| [`04-emilia-typography/`](./04-emilia-typography/README.md) | **high** | emilia | Font-smoothing, font-stretch, font-variant-numeric, letter-spacing, line-clamp, line-height, list-*, text-decoration-*, text-transform, text-overflow, text-wrap, vertical-align, white-space, word-break, overflow-wrap, hyphens, content |
| [`05-emilia-backgrounds/`](./05-emilia-backgrounds/README.md) | **high** | emilia | Bg-attachment, bg-clip, bg-image (gradientes), bg-origin, bg-position, bg-repeat, bg-size |
| [`06-emilia-borders/`](./06-emilia-borders/README.md) | **high** | emilia | Border-radius expandido, border-style, outline-width/color/style/offset |
| [`07-emilia-effects/`](./07-emilia-effects/README.md) | **high** | emilia | Box-shadow expandido, text-shadow, opacity completa, mix-blend-mode, background-blend-mode, mask-* |
| [`08-emilia-filters/`](./08-emilia-filters/README.md) | **medium** | emilia | Blur, brightness, contrast, drop-shadow, grayscale, hue-rotate, invert, saturate, sepia + backdrop-filter |
| [`09-emilia-tables/`](./09-emilia-tables/README.md) | **low** | emilia | Border-collapse, border-spacing, table-layout, caption-side |
| [`10-emilia-transitions/`](./10-emilia-transitions/README.md) | **high** | emilia | Transition-property/behavior/duration/timing/delay, animation |
| [`11-emilia-transforms/`](./11-emilia-transforms/README.md) | **medium** | emilia | Rotate, scale, skew, translate, transform-origin, perspective, backface-visibility, transform-style |
| [`12-emilia-interactivity/`](./12-emilia-interactivity/README.md) | **medium** | emilia | Cursor, pointer-events, resize, scroll-*, touch-action, user-select, will-change, appearance, accent-color, caret-color, field-sizing, scrollbar-* |
| [`13-emilia-svg-accessibility/`](./13-emilia-svg-accessibility/README.md) | **low** | emilia | Fill, stroke, stroke-width, sr-only, forced-color-adjust |
| [`14-emilia-color-palette/`](./14-emilia-color-palette/README.md) | **critical** | emilia | Paleta completa: 17 famílias × 11 tons (50–950) + 9 neutros + black/white, com opacidade |
| [`15-emilia-modifiers/`](./15-emilia-modifiers/README.md) | **critical** | emilia | Novos modifiers: Sm, 2Xl, Dark, Visited, First, Last, Odd, Even, Disabled, Required, Invalid, FocusVisible, GroupHover, GroupFocus, PeerFocus, PeerChecked, Placeholder, Before, After, Selection, Marker, Print, MotionReduce, MotionSafe, Portrait, Landscape, Rtl, Ltr, Open, Inert |

## Order

```
Phase 1 (Foundation — parallel):
  14-color-palette ──┐
  15-modifiers ──────┤
  03-spacing-sizing ─┤  (paralelo: nenhum arquivo compartilhado)
                     │
Phase 2 (Core utilities — parallel after Phase 1):
  01-layout ─────────┐
  02-grid ───────────┤
  04-typography ─────┤  (paralelo: seções distintas do Token)
  05-backgrounds ────┤
  06-borders ────────┘
                     │
Phase 3 (Advanced — parallel after Phase 2):
  07-effects ────────┐
  08-filters ────────┤
  09-tables ─────────┤  (paralelo: seções independentes)
  10-transitions ────┤
  11-transforms ─────┘
                     │
Phase 4 (Polish — parallel after Phase 3):
  12-interactivity ──┐
  13-svg-a11y ───────┘  (paralelo: seções independentes)
```

**Por que 14-color-palette é primeiro:** A paleta de cores é transversal — quase todos os outros fronts (Bg, Border.Color, Text.Color, Effect.Shadow, Filter.DropShadow, etc.) referenciam cores. Sem a paleta completa, os outros fronts ficam limitados aos 4 tons fixos atuais (Red 100–900, Blue 100–900, Green 100–900, Gray 100–900).

**Por que 15-modifiers é primeiro:** Os modifiers são wrappers que envolvem tokens de qualquer seção. Sem Sm, 2Xl, Dark, GroupHover, etc., os tokens adicionados pelos outros fronts não podem ser usados responsivamente ou em estados.

**Por que 03-spacing-sizing é primeiro:** Width, Height, Gap, Pad, Margin são usados em praticamente todos os layouts. Sem a scale completa (0–96 + px + full + auto), os fronts de Layout e Grid não podem expressar dimensões arbitrárias.

## Regras do Milestone

- **emilia-only:** Todos os fronts tocam APENAS `repository/emilia/`. Nenhum outro repo é modificado.
- **Token enum expansion:** Cada front adiciona novas seções/variantes ao `Token` enum em `tokens.bp` e os dispatchers correspondentes em `emilia.bp`.
- **Exhaustive dispatch:** Cada nova seção requer um sub-dispatcher dedicado (`xTokenToCss`) e um braço no `tokenToCss` principal. O `case` deve ser exaustivo — sem `_` catch-all.
- **Tailwind parity:** Os valores CSS emitidos devem ser idênticos aos do Tailwind CSS v4.3 (mesmas propriedades, mesmos valores).
- **Dual-target:** Tudo deve funcionar em commonJS e erlang.
- **Naming:** camelCase para fn names, PascalCase para variant names, numeric leaves com prefixo `__` (ex: `__50`, `__500`).
- **No breaking changes:** Nenhum token existente é removido ou renomeado. Apenas adições.
- **Test coverage:** Cada nova seção tem pelo menos 1 teste in-file cobrindo o dispatch + CSS emitido.

## Mapeamento emilia → Tailwind CSS

| Seção emilia (atual) | Seção Tailwind | Cobertura |
|---|---|---|
| Text | Typography | Parcial (falta letter-spacing, line-height, line-clamp, list-*, text-decoration-*, text-transform, text-overflow, text-wrap, vertical-align, white-space, word-break, overflow-wrap, hyphens, content) |
| Font | Typography | Parcial (falta font-smoothing, font-stretch, font-variant-numeric, font-feature-settings) |
| Color | Color | Mínima (4 famílias vs 17+9 no Tailwind) |
| Bg | Backgrounds | Mínima (falta gradientes, bg-image, bg-position, bg-repeat, bg-size, bg-attachment, bg-clip, bg-origin) |
| Pad | Spacing (padding) | Parcial (falta scale 0,3,6,12,20,24,32,40,48,56,64,72,80,96 + px) |
| Margin | Spacing (margin) | Parcial (mesmo gap de scale) |
| Layout | Layout | Mínima (só Block/InlineBlock/Inline/Hidden/Flex/Grid; falta position, overflow, visibility, z-index, float, clear, isolation, object-*, aspect-ratio, columns, break-*) |
| Flex | Flexbox & Grid | Parcial (falta grid-*, gap expandido, justify/align/place completo) |
| Border | Borders | Parcial (falta border-style, border-radius expandido, outline-*) |
| Effect | Effects | Mínima (falta text-shadow, opacity completa, mix-blend-mode, bg-blend-mode, mask-*) |
| (inexistente) | Filters | 0% (blur, brightness, contrast, drop-shadow, grayscale, hue-rotate, invert, saturate, sepia, backdrop-filter) |
| (inexistente) | Tables | 0% |
| (inexistente) | Transitions & Animation | 0% |
| (inexistente) | Transforms | 0% |
| (inexistente) | Interactivity | 0% |
| (inexistente) | SVG | 0% |
| (inexistente) | Accessibility | 0% |
| Hover/Focus/Active | Pseudo-classes | Parcial (falta Visited, First, Last, Odd, Even, Disabled, etc.) |
| Md/Lg/Xl | Responsive breakpoints | Parcial (falta Sm, 2Xl) |
| (inexistente) | Dark mode | 0% |
| (inexistente) | Group/Peer | 0% |
