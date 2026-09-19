# Front 14 — emilia-color-palette

**Priority:** critical — Paleta completa é pré-requisito para todos os fronts que usam cores
**Depends on:** none
**Owns:** `src/tokens.bp` (Color/Bg full palette expansion) · `test/colors_test.bp`
**Does not touch:** Layout, Grid, Pad, Margin, Flex, Border, Effect, Text, Font sections

---

## Problem

Color/Bg atuais têm apenas 4 famílias (Red, Blue, Green, Gray) com tons limitados. O Tailwind tem 17 famílias de cores + 9 neutros + black/white, cada uma com 11 tons (50–950).

## Current state

`tokens.bp:72-138` — Color com Red{100..900}, Blue{100..900}, Green{100,300,500,700,900}, Gray{100..900}, White, Black, Hex.
`tokens.bp:118-138` — Bg com Red{100,500,700}, Blue{100,500,700}, Gray{100,200,500,900}, White, Black, Hex.

## Mechanism

Expandir Color e Bg para cobrir todas as 17 famílias + 9 neutros, cada uma com 11 tons. Adicionar suporte a opacidade.

## Steps

### Step 1 — Expandir seção Color

Adicionar todas as famílias de cores com 11 tons cada:

```bp
Color {
    // existing (expand to 11 tones)
    Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Orange { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Amber { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Yellow { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Lime { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Green { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Emerald { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Teal { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Cyan { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Sky { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Blue { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Indigo { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Violet { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Purple { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Fuchsia { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Pink { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Rose { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }

    // neutrals
    Slate { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Gray { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Zinc { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Neutral { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
    Stone { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }

    White,
    Black,
    Transparent,      // NEW
    Hex(value: string),
}
```

### Step 2 — Expandir seção Bg

Mesma estrutura que Color, mas para background-color.

### Step 3 — Adicionar valores CSS

Cada tom mapeia para um valor hex específico (usando a paleta Tailwind):

```bp
// Exemplo de mapeamento (valores reais do Tailwind):
// Red 50: #fef2f2
// Red 100: #fee2e2
// Red 200: #fecaca
// Red 300: #fca5a5
// Red 400: #f87171
// Red 500: #ef4444
// Red 600: #dc2626
// Red 700: #b91c1c
// Red 800: #991b1b
// Red 900: #7f1d1d
// Red 950: #450a0a
```

**Acceptance:**
- [ ] `Color.Red.__50` → `color:#fef2f2`
- [ ] `Color.Red.__500` → `color:#ef4444`
- [ ] `Color.Red.__950` → `color:#450a0a`
- [ ] `Color.Blue.__500` → `color:#3b82f6`
- [ ] `Color.Orange.__500` → `color:#f97316`
- [ ] `Color.Amber.__500` → `color:#f59e0b`
- [ ] `Color.Yellow.__500` → `color:#eab308`
- [ ] `Color.Lime.__500` → `color:#84cc16`
- [ ] `Color.Green.__500` → `color:#22c55e`
- [ ] `Color.Emerald.__500` → `color:#10b981`
- [ ] `Color.Teal.__500` → `color:#14b8a6`
- [ ] `Color.Cyan.__500` → `color:#06b6d4`
- [ ] `Color.Sky.__500` → `color:#0ea5e9`
- [ ] `Color.Indigo.__500` → `color:#6366f1`
- [ ] `Color.Violet.__500` → `color:#8b5cf6`
- [ ] `Color.Purple.__500` → `color:#a855f7`
- [ ] `Color.Fuchsia.__500` → `color:#d946ef`
- [ ] `Color.Pink.__500` → `color:#ec4899`
- [ ] `Color.Rose.__500` → `color:#f43f5e`
- [ ] `Color.Slate.__500` → `color:#64748b`
- [ ] `Color.Gray.__500` → `color:#6b7280`
- [ ] `Color.Zinc.__500` → `color:#71717a`
- [ ] `Color.Neutral.__500` → `color:#737373`
- [ ] `Color.Stone.__500` → `color:#78716c`
- [ ] `Color.Transparent` → `color:transparent`
- [ ] `Bg.Red.__500` → `background-color:#ef4444`
- [ ] `Bg.Blue.__500` → `background-color:#3b82f6`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto
- [ ] Tokens existentes não quebrados
- [ ] `AGENTS.md` atualizado

## Blast radius

- `tokens.bp`: +~300 linhas (expansão massiva de Color/Bg)
- `emilia.bp`: +~400 linhas (valores CSS para cada tom)
- `test/colors_test.bp`: novo arquivo, ~50 testes
- Todos os fronts que usam cores (F05, F06, F07, F12, F13) dependem desta paleta

## Notes

- Valores hex são da paleta oficial Tailwind CSS v4.3
- Transparent é adicionado como variante simples (sem payload)
- Opacity modifier (ex: `Color.Red.__500/50`) é tratado no F15 (modifiers)
