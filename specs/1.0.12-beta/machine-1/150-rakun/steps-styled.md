# 150 rakun — the open steps of the former front 148 (styled: the base for CSS components — `styled`'s half of 119)

Front 148 was refiled under 150 rakun by 165 s8: its open steps are 150 s32 … s35, in the workspace
package `rakun-style` (`rakun/modules/rakun-style/`, 165's table); its context folders moved into `2-libraries/150-rakun/`. A step
here edits `rakun/modules/rakun-style/` (and what its text names), in lane "style / bpp / stylesheet" of `fronts.md` § Ownership; a done step stays in `status.md` Done.

**Depends on:** 144 B-10 G2 (8 markers), B-17 (355 holes at build, 14 s8), B-19 (353 / 356 catalogue)
**Order:** Runs after css (147); its step 1 unblocks emilia 34 s5 (150 s52). jhonstart's halves of 119 are 150 s40.

## Alias table

Old ids stay valid in `decisions-taken.md`'s *Where* column, `language-gaps.md`'s owners and the
closed records: each resolves here. A "box n" counts the old step's open boxes, in order.

| Old id | Step here |
|---|---|
| `119-bpp-styling` s1 | 150 s32 |
| `119-bpp-styling` s4 boxes 2, 4 | 150 s33 |
| `119-bpp-styling` gate | 150 s33 |
| `148 s1` | 150 s32 |
| `148 s2` | 150 s33 |
| `148 s3` | 150 s34 |
| `148 Conformance` | 150 s35 |

## Steps

### 150 s32 — `styled`: records, holes at build, the sheet, the theme (119 s1)

**Repository:** rakun (`--repo rakun`) · **Model:** sonnet

#### Step 1 — the repositories `css` and `styled` (was `119-bpp-styling` s1)

`css` reader scope: comments, strings, `{ }` nesting, rule-holding at-rules (`@media`, `@supports`,
`@layer`, `@container`), others (`@keyframes` — percentage selectors; `@font-face`), selector
lists, compounds, combinators, pseudo-classes/elements (attribute before a pseudo-element),
`:global(…)`, `:is(…)` and `:where(…)` (scoped inside).

- [x] `botopink/styled` carries a first commit on `feat`; submodule at `repository/rakun/modules/rakun-style`; meta
      `.gitmodules` and `AGENTS.md` § Layout row in the same commit; manifest `["erlang",
      "commonJS"]`, erlang first, imports std and `css` only
- [x] `examples/styled-example.bp` passes on both targets: `styledProperty "padding: --spacing(4);"`
      renders `.s_<hash>{padding:calc(var(--spacing) * 4)}`; `&:hover`, `@media` and `@variant md`
      nest under the class; `${p}` of a `StyledPropertyView` inlines its declarations; the same rules
      share one class; the layer's prefix; a sheet renders its layers in declaration order
- [x] `styledProperty` refuses `{`, `&`, `@` at the character; `@utility` and `@theme` refused in
      either literal, each error naming the botopink form
- [x] a component with no run-time hook is computed at build (the emitted module holds the class as
      a constant); one reaching a run-time hook registers at render through `use context(StyledContext)` (352, 354:
      the render's sheet and layer, no store in `styled`); a literal whose every hole is known at build is computed at build
      (355, built: `styled.bp` `atBuild` over `Part.known` / `Part.value`; `repository-stages.sh` reads
      `tabRed`'s constant) — a hole naming an imported `val` stays computed at render until
      `01-compiler/14` step 8's last boxes, the same CSS
- [x] `styled`'s reader keeps source order (368): a declaration after a nested rule opens a new rule of
      the class, as CSS Nesting's nested-declarations rule — `styled "${bg} &:focus { ${gray} } ${pad}"`
      renders `.k{background:#ffffff}.k:focus{…}.k{padding:…}` on both targets (`reader.bp`
      `readBlock`); before `06-emilia/34` step 5, which keeps emilia's CSS byte-identical through it
- [ ] `styledProperty "…"` answers the record `StyledProperty` (381): built by a pure function, reading no
      context, registering nothing; `StyledPropertyView` gone; a property used alone (`use p`,
      `#[styled(p)]`) refused at the use naming `styled`; `examples/styled-context` and
      `test/context_test.bp` reversed ("a property standing alone registers itself" no longer); `fn
      padAll(n: i32) -> StyledProperty` compiles and `comptime padAll(2)` is a value
- [ ] a literal with render holes is built at build into a template with slots (377): parsed and checked,
      its known holes — an `Any` call with build arguments included (376) — written in, the render filling
      the slots, hashing, registering; a hole's mark (`p.hole.known`, `p.hole.why`) is the compiler's
- [ ] a `styled` value registers in the render's sheet where it is used — `use x`, `#[styled(x)]` —, never
      where it is made (377): `pub val codigo = styled "${padAll(2)}";` legal (a constant), and every path
      that writes a class on a tag measured to pass through one of the two; `StyledContext` declared
      `comptime createContext(StyledSheet.missing())`, read `use context(StyledSheet)` (378, 379), `missing().add` panicking with
      the provider's text
- [ ] the theme mechanism (300) in `styled`: `#[theme]` found at comptime, two refused, none a
      compile error at the first literal naming the fix (358); `--theme(--breakpoint-md)` and `@variant md` read it; a cleared breakpoint refused
      at compile time · row 134 (a library's template function cannot read the program's catalogue),
      built by `01-compiler/130` step 10 (353)
- [x] `grep -rn "bpp\|jhonstart\|emilia" repository/css repository/rakun/modules/rakun-style` empty — the shared
      hook text names emilia (`119-a`)

### 150 s33 — `StyledMeta` and the cleared breakpoint (119 s4, `styled`'s half)

**Repository:** rakun (`--repo rakun`) · **Model:** sonnet

#### Step 4 — `#[styled(..)]` in `jhonstart-styled`, and the reader of `#[emilia(..)]`'s meta (decisions 301, 338, 369) — part (was `119-bpp-styling` s4 boxes 2, 4)

```bpp
<h1 #[emilia(.Text.Size.X3xl, .Text.Bold, .Color.Gray.900)]>{post.title}</h1>
<button #[styled(btn)] #[emilia(.Pad.All.4)]>Salvar</button>
```

`#[emilia(…)]` is emilia's (`..tokens: @Expr<Token[]>`, 382, so a leading-dot path resolves against `Token`; under
`Styleable[]` it names no enum) and runs at build (369); this step owns the meta it records — a type
`styled` declares, holding the class and the rules — and its reader in jhonstart.

- [ ] `styled` declares `pub type StyledMeta(layer: Layer, className: string, rules: string)` (383), the
      meta `#[emilia(…)]` sets (`setMeta`, one per tag — a second `#[emilia]` refused); `html` reads it
      beside `ClassName` and merges `className` into the tag's `class` in annotation order; the sink
      writes `rules` in the meta's `layer`; jhonstart names no emilia (113)
- [ ] a token naming a cleared breakpoint refused at compile time (300, now `styled`'s)

#### Gate additions (was `119-bpp-styling` gate)

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `repository/css`, `repository/rakun/modules/rakun-style` and `jhonstart-styled`
- [ ] `zig build test-libs`: emilia, jhonstart, onze green
- [ ] `grep -rn "bpp\|jhonstart" repository/css repository/rakun/modules/rakun-style repository/rakun/modules/rakun-stylesheet/modules` empty (338)

### 150 s34 — `Sheet.add` over a component (from 144 B-10 G2)

**Repository:** rakun (`--repo rakun`) · **Model:** sonnet

- [ ] `Sheet.add` takes what `toStyled()` answers — a component — once a method's behavior-typed parameter takes an
      implementer (144 B-10, `method_behavior_parameter_implementer`); styled's marker for it and its gap row go

### 150 s35 — Conformance of the former front 148 (decision 465)

**Repository:** rakun (`--repo rakun`) · **Model:** opus

After every other step of this front has landed on `feat`; it holds back no front that builds on them (479).

- [ ] `feat`'s GitHub pipeline green after the front landed (477): `scripts/gate.sh` with conformance — `botopink cell
      check conformance/` over every cell of `rakun/conformance/rakun-style/` on the targets the manifests declare; a red reproduced
      locally, fixed at once (430), pushed again; no cell edited to match the code
- [ ] the front's changes to the library's behaviour analysed against the cells (a table in this README)
- [ ] the cells that behaviour calls for written (decision 463's shape), red on the front's base, green on its tip
- [ ] the missing cells found beyond the front's change proposed as rows
- [ ] the reference updated (480): `conformance/docs.md` and the `docs.md` of each cell written or whose answer changed
- [ ] the GitHub pipeline read (474, 477, `gh` read only): the runs on `feat` since the front's base, after it landed, green
      or each red named and fixed or filed; the pipeline's state in the step's report
- [ ] for each red, the cheap test the hook runs that would have caught it written beside the fix (478), or why none can
