# Front 10 — emilia-transitions

**Priority:** high — Transitions e animations são essenciais para UX interativa
**Depends on:** F15 (modifiers)
**Owns:** `src/tokens.bp` (Transition section, Animate section) · `test/transitions_test.bp`
**Does not touch:** Todas as outras seções

---

## Problem

Não há suporte a transições CSS nem animações.

## Steps

### Step 1 — Adicionar seção Transition

```bp
Transition {
    None,             // transition-property: none
    All,              // transition-property: all
    Default,          // transition: color, bg, border, text-decoration, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter
    Colors,           // transition-property: color, bg, border-color, text-decoration-color, fill, stroke
    Opacity,          // transition-property: opacity
    Shadow,           // transition-property: box-shadow
    Transform,        // transition-property: transform
    Behavior {
        Discrete,     // transition-behavior: allow-discrete
        Normal,       // transition-behavior: normal
    }
    Duration {
        0, 75, 100, 150, 200, 300, 500, 700, 1000,
    }
    Delay {
        0, 75, 100, 150, 200, 300, 500, 700, 1000,
    }
    Ease {
        Linear,
        In,           // cubic-bezier(0.4, 0, 1, 1)
        Out,          // cubic-bezier(0, 0, 0.2, 1)
        InOut,        // cubic-bezier(0.4, 0, 0.2, 1)
    }
}
```

### Step 2 — Adicionar seção Animate

```bp
Animate {
    None,
    Spin,             // spin 1s linear infinite
    Ping,             // ping 1s cubic-bezier(0, 0, 0.2, 1) infinite
    Pulse,            // pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite
    Bounce,           // bounce 1s infinite
}
```

**Acceptance:**
- [ ] `Transition.None` → `transition-property:none`
- [ ] `Transition.All` → `transition-property:all;transition-timing-function:cubic-bezier(0,0,0.2,1);transition-duration:150ms`
- [ ] `Transition.Colors` → `transition-property:color,background-color,border-color,text-decoration-color,fill,stroke;...`
- [ ] `Transition.Duration.__300` → `transition-duration:300ms`
- [ ] `Transition.Delay.__150` → `transition-delay:150ms`
- [ ] `Transition.Ease.InOut` → `transition-timing-function:cubic-bezier(0.4,0,0.2,1)`
- [ ] `Animate.Spin` → `animation:spin 1s linear infinite`
- [ ] `Animate.Pulse` → `animation:pulse 2s cubic-bezier(0.4,0,0.6,1) infinite`
- [ ] `Animate.Bounce` → `animation:bounce 1s infinite`

## Gate

- [ ] `botopink test` green em commonJS e erlang
- [ ] Todos os novos tokens mapeados para CSS correto

## Blast radius

- `tokens.bp`: +~50 linhas
- `emilia.bp`: +~80 linhas
- `test/transitions_test.bp`: novo arquivo, ~20 testes

## Notes

- Animate.Spin/Pulse/Bounce requerem @keyframes no CSS output
- Os @keyframes são emitidos como parte do <style> block no flush()
