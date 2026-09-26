# Front 58 — emilia container queries

**Track:** D emilia · **Priority:** medium · **Level:** 2 · **Target:** comptime (commonJS and erlang)
**Depends on:** 54 (the `--container-*` namespace), 56 (`Variant`, hoisted at-rules), 57 (the `cssIdent` reject set for names)
**Code:** `repository/emilia/modules/emilia/src/container.bp` (`ContainerSize`, `containerKey`, the
builders, `containerAtRule`, the `…ToSheet` helpers) · `src/tokens.bp` (`// ── front 58 — container
queries`: the `Container` section and three top-level variants) · `src/emilia.bp` (four contiguous
`tokenToSheet` arms)
**User docs:** `repository/emilia/docs.md` § *Container queries*
**Reference:** `TAILWIND_CSS_DOCS.md § 3.3` (container-size table), `§ 3.5` · https://tailwindcss.com/docs/responsive-design#container-queries

**Open:** none.

---

## What it delivers

Component-scoped responsiveness: a parent declares itself a container, a descendant queries its width.

```bp
    Container { Inline, Normal, Size }                       // payload-free markers
    ContainerNamed(name: string),                            // top-level
    ContainerAt(size: string, inner: Token[]),               // top-level
    ContainerAtNamed(size: string, name: string, inner: Token[]),

pub type ContainerSize { X3xs, X2xs, Xs, Sm, Md, Lg, Xl, X2xl, X3xl, X4xl, X5xl, X6xl, X7xl }
```

| Token / builder | CSS |
|---|---|
| `.Container.Inline` / `.Normal` / `.Size` | `container-type:inline-size` / `normal` / `size` |
| `containerName("main")` → `ContainerNamed` | `container-type:inline-size;container-name:main` — one rule, type then name |
| `containerAt(size, inner)`, `containerAt3xs(inner)` … `containerAt7xl(inner)` → `ContainerAt` | `@container (width >= 28rem){.e_x{…}}` for `Md`, hoisted |
| `containerNamed(size, name, inner)` → `ContainerAtNamed` | `@container main (width >= 24rem){.e_x{…}}` for `Sm` |

- **Sizes come from the theme**: `containerAtRule(key, name, th)` reads `themeValue(th, "--container-" + key)`
  — `3xs` 16rem, `2xs` 18rem, `xs` 20rem, `sm` 24rem, `md` 28rem, `lg` 32rem, `xl` 36rem, `2xl` 42rem,
  `3xl` 48rem, `4xl` 56rem, `5xl` 64rem, `6xl` 72rem, `7xl` 80rem under the default theme. Narrowing
  `--container-md` moves that query and nothing else. An unresolvable size (a cleared namespace, an
  unknown key through the bare constructor) panics — never `@container (width >= )`.
- `containerKey` is the only place a size key is written; the builders take `ContainerSize`. Syntax is
  `width >=`, never `min-width:`; the unnamed form has exactly one space after `@container`.
- Container names are refused by front 57's `cssIdent` reject set, in the builder, the named builder
  and the dispatcher.
- A container query is a `Variant`, so it nests with breakpoints in both orders, with states
  (`Hover([containerAtSm(inner)])` → `@container (width >= 24rem){.e_x:hover{…}}`) and with a front 57
  arbitrary selector, without special cases.
- Top-level variants and builders for the usual reasons: a nested payload leaf and a section-typed
  field cannot be constructed, and `[.ContainerAt(size: "md", inner: xs)]` does not parse.

## Acceptance

### Delivered

- [x] `.Container.Inline` → `.e_x{container-type:inline-size}`; `Normal` and `Size` asserted;
      `ContainerNamed` renders one rule, type then name; names refused by the `cssIdent` set.
- [x] The thirteen widths asserted against the `§ 3.3` table, from the theme; `containerAtMd` is a
      hoisted rule; `containerKey` has thirteen keys and an unknown key panics at dispatch; narrowing
      `--container-md` moves only that query; a cleared namespace panics; no `min-width`.
- [x] `containerNamed(ContainerSize.Sm, "main", inner)` → `@container main (width >= 24rem){…}`; the
      unnamed form has one space; a named and an unnamed query are two rules.
- [x] Nesting with a breakpoint in both orders and with a state; wrapping a front 57 arbitrary selector.
- [x] The parent's `container-type` and the child's query land in one `@layer utilities` body of one
      flushed document.
- [x] `container.bp` is declared in `root.bp` and listed in `botopink.json`; four contiguous arms; no
      container width literal outside `theme.bp`; green on commonJS and erlang.

## Examples

- [`./examples/container-queries-example.bp`](./examples/container-queries-example.bp) — a card that is
  a column in a narrow slot and a row in a wide one, plus a named container so a nested card queries
  the page shell.
