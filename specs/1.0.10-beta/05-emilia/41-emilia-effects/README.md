# Front 41 — emilia effects

**Track:** D emilia · **Priority:** high · **Level:** 3 · **Target:** comptime (commonJS and erlang)
**Depends on:** 33 (palette), 34 (modifiers, in the examples), 54 (`themeVar`, `--shadow-*`), 56 (`declSheet`)
**Code:** `repository/emilia/modules/emilia/src/tokens.bp` (`// ── front 41 — effects` block: `Effect`,
`Blend`, `Mask`, and the top-level `EffectShadowRaw`, `EffectTextShadowRaw`, `MaskImageRaw`) ·
`src/emilia.bp` (front-41 block: `effectTokenToCss`, `blendTokenToCss`, `maskTokenToCss` and their
sub-dispatchers, all taking `th: Theme`; `effectEntries`; `rawShadow`, `rawTextShadow`, `rawMaskImage`;
five `tokenToSheet` arms)
**User docs:** `repository/emilia/docs.md` § *Effect, Blend and Mask*
**Reference:** `TAILWIND_CSS_DOCS.md § 12` (shadow scale `§ 21.4`) · https://tailwindcss.com/docs/box-shadow

**Open:** none.

---

## What it delivers

`§ 12` — **102 leaves** (`Effect` 39, `Blend` 34, `Mask` 29). Every scale step is a `var(…)` reference;
the theme holds the values.

| Group | Tokens | CSS |
|---|---|---|
| Box shadow (`§ 12.1`) | `.Effect.Shadow.{X2xs, Xs, Sm, Md, Lg, Xl, X2xl, None, Inner}` | `--tw-shadow:var(--shadow-md);box-shadow:<reader>` — the `--tw-shadow` channel plus the shared five-channel reader (front 40), so a ring composes with it; `None` → `--tw-shadow:0 0 transparent` (empties only its channel); `Inner` → `inset 0 2px 4px 0 rgb(0 0 0 / 0.05)`, the one literal (upstream has no `--shadow-inner`) |
| Inset shadow | `.Effect.InsetShadow.{X2xs, Xs, Sm}` | `--tw-inset-shadow:inset var(--inset-shadow-sm);box-shadow:<reader>` |
| Text shadow (`§ 12.2`) | `.Effect.TextShadow.{X2xs, Xs, Sm, Md, Lg, None}` | `text-shadow:var(--text-shadow-sm)`; `None` → `text-shadow:none` |
| Opacity (`§ 12.3`) | `.Effect.Opacity.{0, 5, 10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90, 95, 100}` + provisional `15, 35, 45, 55, 65, 85` | `opacity:0.6` — always a leading zero; `100` → `opacity:1` |
| Blend (`§ 12.4`, `12.5`) | `.Blend.Mix.*`, `.Blend.Bg.*` — seventeen values each (`Normal` … `PlusLighter`) | `mix-blend-mode:plus-lighter`, `background-blend-mode:overlay`; the two value tables are asserted equal, in order |
| Mask (`§ 12.6`) | `.Mask.{Clip, Composite, Image, Mode, Origin, Position, Repeat, Size, Type}` | `mask-clip:padding-box` (the suffix is not the value), `mask-composite:intersect`, `mask-image:none`, …; `Position.{Top, Bottom, Left, Right}`, `Repeat.{RepeatX, RepeatY, Round, Space}`, `Size.Auto` are provisional |
| Arbitrary | `Token.EffectShadowRaw(value)`, `Token.EffectTextShadowRaw(value)`, `Token.MaskImageRaw(value)`; wrappers `rawShadow(v)`, `rawTextShadow(v)`, `rawMaskImage(v)` | `box-shadow:<v>`, `text-shadow:<v>`, `mask-image:<v>` |

- Upstream's `2xs`/`2xl` are spelled `X2xs`/`X2xl`; the emitted variable keeps upstream's name.
- **`effectEntries()`** contributes the `--inset-shadow-*` and `--text-shadow-*` entries to `fullTheme()`
  (`--shadow-*` is front 54's). `--text-shadow-*` is accepted under the `--text-` prefix because `Ns`
  has no `TextShadow` namespace.
- The three `Raw` variants are top-level because a payload leaf nested in a section cannot be
  constructed; the wrappers exist because `[.EffectShadowRaw("…")]` does not carry the typed-array
  context (a leading-dot path followed by a payload call).

## Acceptance

### Delivered

- [x] The four earlier shadow leaves (`Sm`/`Md`/`Lg`/`Xl`) keep their names and emit a theme
      reference; `box-shadow:md` and its siblings survive only in comments and negative asserts.
- [x] `Token.EffectShadowRaw(value: "0 0 0 1px red")` constructs; each `Raw` variant reaches its own
      arm; no section in this front's block holds a payload leaf.
- [x] Exactly one leaf resolves a shadow value, and it is `Shadow.Inner`; `shadowToCss` and
      `insetShadowToCss` are exhaustive with no `_` arm.
- [x] The seven scale steps are `--shadow-*` references, `None` is its channel's null shadow, `Inner`
      is the reference's literal; inset leads the inset-shadow value.
- [x] `TextShadow`: five references and the `none` keyword; `textShadowToCss` exhaustive.
- [x] `opacity:0.6` with a leading zero; the five earlier opacity leaves unchanged; the six extra
      steps marked provisional at their arm.
- [x] `Blend` has two sub-sections of seventeen leaves; `blendTokenToCss` prepends the property and
      the two value tables agree; `.Blend.Mix.PlusLighter` → `mix-blend-mode:plus-lighter`.
- [x] `Mask` has nine sub-sections, `maskTokenToCss` nine arms with no `_`; `[.Mask.Clip.Padding,
      .Mask.Mode.Luminance]` composes in list order.
- [x] Five `tokenToSheet` arms (`Blend`, `Mask`, the three `Raw` variants), each one `declSheet(…)`
      call, after front 40's; the modifier arms still close the `case`; no `_` arm.
- [x] Every dispatcher and sub-dispatcher takes `th: Theme`; `repository/emilia/AGENTS.md` records
      the sections and the shadow correction; a fixed effects list hashes to the same class on both
      targets; green on commonJS and erlang.

## Not declared

- `shadow-<color>/<opacity>` (`shadow-red-500/50`): the reference gives the class and no
  property/value pair. The mechanism exists (two declarations of one rule); the value does not, and
  the row reopens when the reference carries one.
- A real `Ns.TextShadow` namespace is front 54's to add.

## Examples

- [`./examples/effects-example.bp`](./examples/effects-example.bp) — the `Effect` / `Blend` / `Mask`
  catalogue, then a photo card layering a shadow, a blend mode and an opacity under `Hover`.
