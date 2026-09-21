# Front 09 — emilia-tables

**Priority:** low — Tables são úteis para dashboards e data display
**Depends on:** F15 (modifiers)
**Owns:** `src/tokens.bp` (Table section) · `test/tables_test.bp`
**Does not touch:** Todas as outras seções

---

## Problem

Não há suporte a estilos de tabela CSS.

## Steps

### Step 1 — Adicionar seção Table

```bp
Table {
    BorderCollapse {
        Collapse,     // border-collapse: collapse
        Separate,     // border-collapse: separate
    }
    BorderSpacing {
        0, 1, 2, 4, 8, 16,
    }
    BorderSpacingX {
        0, 1, 2, 4, 8, 16,
    }
    BorderSpacingY {
        0, 1, 2, 4, 8, 16,
    }
    Layout {
        Auto,         // table-layout: auto
        Fixed,        // table-layout: fixed
    }
    CaptionSide {
        Top,          // caption-side: top
        Bottom,       // caption-side: bottom
    }
}
```

**Acceptance:**
- [ ] `Table.BorderCollapse.Collapse` → `border-collapse:collapse`
- [ ] `Table.BorderSpacing.__4` → `border-spacing:1rem`
- [ ] `Table.BorderSpacingX.__2` → `border-spacing:0.5rem 0`
- [ ] `Table.Layout.Fixed` → `table-layout:fixed`
- [ ] `Table.CaptionSide.Bottom` → `caption-side:bottom`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~30 linhas
- `emilia.bp`: +~40 linhas
- `test/tables_test.bp`: novo arquivo, ~10 testes
