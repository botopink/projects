# Front 12 — emilia-interactivity

**Priority:** medium — Interactivity é essencial para UX (cursor, scroll, touch, user-select)
**Depends on:** F15 (modifiers)
**Owns:** `src/tokens.bp` (Interact section) · `test/interactivity_test.bp`
**Does not touch:** Todas as outras seções

---

## Problem

Não há suporte a propriedades de interatividade CSS.

## Steps

### Step 1 — Adicionar seção Interact

```bp
Interact {
    Cursor {
        Auto,
        Default,
        Pointer,
        Wait,
        Text,
        Move,
        Help,
        NotAllowed,
        None,
        ContextMenu,
        Progress,
        Cell,
        Crosshair,
        VerticalText,
        Alias,
        Copy,
        NoDrop,
        Grab,
        Grabbing,
        AllScroll,
        ColResize,
        RowResize,
        NResize,
        EResize,
        SResize,
        WResize,
        NeResize,
        NwResize,
        SeResize,
        SwResize,
        EwResize,
        NsResize,
        NeswResize,
        NwseResize,
        ZoomIn,
        ZoomOut,
    }
    PointerEvents {
        None,
        Auto,
    }
    Resize {
        None,
        Y,            // vertical
        X,            // horizontal
        Both,
    }
    ScrollBehavior {
        Auto,
        Smooth,
    }
    ScrollbarWidth {
        Auto,
        Thin,
        None,
    }
    ScrollbarGutter {
        Auto,
        Stable,
        StableBothEdges,
    }
    ScrollMargin {
        0, 1, 2, 4, 8, 16,
    }
    ScrollMarginX { /* same */ }
    ScrollMarginY { /* same */ }
    ScrollPadding {
        0, 1, 2, 4, 8, 16,
    }
    ScrollPaddingX { /* same */ }
    ScrollPaddingY { /* same */ }
    SnapAlign {
        Start,
        End,
        Center,
        None,
    }
    SnapStop {
        Normal,
        Always,
    }
    SnapType {
        None,
        X,
        Y,
        Both,
    }
    SnapStrictness {
        Mandatory,
        Proximity,
    }
    TouchAction {
        Auto,
        None,
        PanX,
        PanLeft,
        PanRight,
        PanY,
        PanUp,
        PanDown,
        PinchZoom,
        Manipulation,
    }
    UserSelect {
        None,
        Text,
        All,
        Auto,
    }
    WillChange {
        Auto,
        Scroll,
        Contents,
        Transform,
    }
    Appearance {
        None,
        Auto,
    }
    AccentColor {
        Auto,
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Green { /* same */ }
        Gray { /* same */ }
        White,
        Black,
    }
    CaretColor {
        Red { 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950 }
        Blue { /* same */ }
        Green { /* same */ }
        Gray { /* same */ }
        White,
        Black,
    }
    FieldSizing {
        Fixed,
        Content,
    }
    ColorScheme {
        Normal,
        Light,
        Dark,
        LightDark,
        OnlyDark,
        OnlyLight,
    }
}
```

**Acceptance:**
- [ ] `Interact.Cursor.Pointer` → `cursor:pointer`
- [ ] `Interact.Cursor.NotAllowed` → `cursor:not-allowed`
- [ ] `Interact.PointerEvents.None` → `pointer-events:none`
- [ ] `Interact.Resize.Y` → `resize:vertical`
- [ ] `Interact.ScrollBehavior.Smooth` → `scroll-behavior:smooth`
- [ ] `Interact.ScrollbarWidth.Thin` → `scrollbar-width:thin`
- [ ] `Interact.SnapType.X` → `scroll-snap-type:x var(--tw-scroll-snap-strictness)`
- [ ] `Interact.SnapAlign.Center` → `scroll-snap-align:center`
- [ ] `Interact.TouchAction.None` → `touch-action:none`
- [ ] `Interact.UserSelect.None` → `user-select:none`
- [ ] `Interact.WillChange.Transform` → `will-change:transform`
- [ ] `Interact.Appearance.None` → `appearance:none`
- [ ] `Interact.AccentColor.Blue.__500` → `accent-color:#3b82f6`
- [ ] `Interact.CaretColor.Red.__500` → `caret-color:#ef4444`
- [ ] `Interact.FieldSizing.Content` → `field-sizing:content`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~120 linhas
- `emilia.bp`: +~180 linhas
- `test/interactivity_test.bp`: novo arquivo, ~30 testes
