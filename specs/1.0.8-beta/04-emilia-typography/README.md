# Front 04 — emilia-typography

**Priority:** high — Tipografia avançada é essencial para textos profissionais
**Depends on:** F14 (colors), F15 (modifiers)
**Owns:** `src/tokens.bp` (Text/Font expansion) · `test/typography_test.bp`
**Does not touch:** Layout, Grid, Color, Bg, Pad, Margin, Border, Effect sections

---

## Problem

Text/Font atuais cobrem apenas o básico (Bold, Italic, Underline, LineThrough, alignment, Size). Falta: font-smoothing, font-stretch, font-variant-numeric, letter-spacing, line-clamp, line-height, list-*, text-decoration-*, text-transform, text-overflow, text-wrap, vertical-align, white-space, word-break, overflow-wrap, hyphens, content.

## Current state

`tokens.bp:38-57` — Text com Bold/Italic/Underline/LineThrough/Left/Center/Right/Justify + Size{Xs..X4xl}.
`tokens.bp:59-70` — Font com Sans/Serif/Mono + Weight{Light,Normal,Medium,Bold,Black}.

## Mechanism

Expandir Text/Font com novas sub-seções.

## Steps

### Step 1 — Expandir seção Text

```bp
Text {
    // existing
    Bold,
    Italic,
    Underline,
    LineThrough,
    Left,
    Center,
    Right,
    Justify,
    Start,            // NEW: text-align: start
    End,              // NEW: text-align: end
    Size { Xs, Sm, Base, Lg, Xl, X2xl, X3xl, X4xl, X5xl, X6xl, X7xl, X8xl, X9xl },

    // NEW sub-sections
    Transform {
        Uppercase,
        Lowercase,
        Capitalize,
        None,
    }
    Overflow {
        Ellipsis,     // text-overflow: ellipsis
        Clip,         // text-overflow: clip
    }
    Truncate,         // NEW: overflow:hidden; text-overflow:ellipsis; white-space:nowrap
    Wrap {
        Wrap,         // text-wrap: wrap
        Nowrap,       // text-wrap: nowrap
        Balance,      // text-wrap: balance
        Pretty,       // text-wrap: pretty
    }
    Indent {          // text-indent
        0, 1, 2, 4, 8,
    }
    Decoration {
        Underline,
        Overline,
        LineThrough,
        None,
    }
    DecorationStyle {
        Solid,
        Double,
        Dotted,
        Dashed,
        Wavy,
    }
    DecorationThickness {
        Auto,
        FromFont,
        0, 1, 2, 4, 8,
    }
    UnderlineOffset {
        Auto,
        0, 1, 2, 4, 8,
    }
    LineClamp {
        1, 2, 3, 4, 5, 6,
        None,
    }
}
```

### Step 2 — Expandir seção Font

```bp
Font {
    Sans,
    Serif,
    Mono,
    Weight {
        Thin,         // 100
        Extralight,   // 200
        Light,        // 300
        Normal,       // 400
        Medium,       // 500
        Semibold,     // 600
        Bold,         // 700
        Extrabold,    // 800
        Black,        // 900
    }
    Smoothing {       // NEW
        Antialiased,  // -webkit-font-smoothing: antialiased
        Auto,         // -webkit-font-smoothing: auto
    }
    Stretch {         // NEW
        UltraCondensed,
        ExtraCondensed,
        Condensed,
        SemiCondensed,
        Normal,
        SemiExpanded,
        Expanded,
        ExtraExpanded,
        UltraExpanded,
    }
    VariantNumeric {  // NEW
        Normal,
        Ordinal,
        SlashedZero,
        LiningNums,
        OldstyleNums,
        ProportionalNums,
        TabularNums,
        DiagonalFractions,
        StackedFractions,
    }
}
```

### Step 3 — Adicionar seções auxiliares

```bp
Leading {             // line-height
    3, 4, 5, 6, 7, 8, 9, 10,
    None,             // 1
    Tight,            // 1.25
    Snug,             // 1.375
    Normal,           // 1.5
    Relaxed,          // 1.625
    Loose,            // 2
}

Tracking {            // letter-spacing
    Tighter,          // -0.05em
    Tight,            // -0.025em
    Normal,           // 0em
    Wide,             // 0.025em
    Wider,            // 0.05em
    Widest,           // 0.1em
}

List {                // list-style
    None,
    Disc,
    Decimal,
    Inside,           // list-style-position: inside
    Outside,          // list-style-position: outside
}

Align {               // vertical-align
    Baseline,
    Top,
    Middle,
    Bottom,
    Sub,
    Super,
    TextTop,
    TextBottom,
}

Whitespace {
    Normal,
    Nowrap,
    Pre,
    PreLine,
    PreWrap,
    BreakSpaces,
}

Break {               // word-break
    Normal,
    Words,            // overflow-wrap: break-word
    All,              // word-break: break-all
    Keep,             // word-break: keep-all
}

Hyphens {
    None,
    Manual,
    Auto,
}

Content {             // content (for ::before/::after)
    None,
}
```

**Acceptance:**
- [ ] `botopink test` green
- [ ] `Text.Transform.Uppercase` → `text-transform:uppercase`
- [ ] `Text.Truncate` → `overflow:hidden;text-overflow:ellipsis;white-space:nowrap`
- [ ] `Text.LineClamp.__3` → `overflow:hidden;display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:3`
- [ ] `Text.Decoration.Underline` → `text-decoration-line:underline`
- [ ] `Font.Weight.Thin` → `font-weight:100`
- [ ] `Font.Smoothing.Antialiased` → `-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale`
- [ ] `Leading.Tight` → `line-height:1.25`
- [ ] `Tracking.Wide` → `letter-spacing:0.025em`
- [ ] `List.Disc` → `list-style-type:disc`
- [ ] `Align.Middle` → `vertical-align:middle`
- [ ] `Whitespace.Nowrap` → `white-space:nowrap`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto
- [ ] Tokens existentes não quebrados
- [ ] `AGENTS.md` atualizado

## Blast radius

- `tokens.bp`: +~150 linhas
- `emilia.bp`: +~250 linhas
- `test/typography_test.bp`: novo arquivo, ~40 testes
