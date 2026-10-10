# Front 141 — specs sweep: the retired spellings out of the current specs

**Priority:** high — every front opens from its README, and a README that writes a retired form
sends its worker to write it: `08-bpp/123` still writes middleware `-> @Component<RequestBase,
Response>`, `08-bpp/116` writes `View` as `@Component<ElementBase, Element>`, `09-cardume/136`
anchors its hooks at `ElementBase` / `RequestBase`, while the compiler refuses the base since 354
(`01-compiler/134` step 6 box 1) and the libraries were rewritten by its codemod.
· **State:** not started · ready to open
**Depends on:** nothing · step 6: `141-a`
**Owns:** the text of `specs/1.0.12-beta/**` (`.md` files and the examples' `.bp`) for the lines
§ Inventory lists, under the carve-out of § Ownership; the text of `decisions-taken.md`'s amended
rows (step 1 — the wording, never the rule)
**Does not touch:** any repository under `repository/` — the code moves with the front that
implements each decision (`01-compiler/134`'s codemod, `05-jhonstart/26`, `04-rakun/128`,
`08-bpp/118` …); the closed milestones (`specs/1.0.0-beta` … `specs/1.0.11-beta`, frozen); a line
another front's README holds a box to rewrite (§ Hand-offs); the meaning of any decision, question,
step or acceptance box — a spelling changes, never a rule; the answer to any pending question.

Measured in [`inventory.md`](./inventory.md) (2026-10-10, meta `feat`): 9 families, 282 lines in
71 spec files besides `decisions-taken.md`, and 25 rows of `decisions-taken.md` that still state
the text an amendment replaced.

## Goal

Every current spec writes the language and the libraries the way the decisions in force spell them.
When this front lands, a retired spelling appears in `specs/1.0.12-beta/` only as one of:

- an open step's work that removes it from the code ("`LocalKey`, `setLocal(key, value)`,
  `local(key)` gone");
- a Mechanism sentence that describes what the code holds today, cited `file:line`;
- a decision row that says what it retires ("`StyledPropertyView` goes");
- a pending question's Measured, or a `## Done` line.

No front then reads a signature, an example or an expected form in a spelling the compiler or the
decisions have retired.

## What counts — four classes

Each hit of § Measure is one of four classes. The class, not the word, decides the action.

| Class | The line | Action |
|---|---|---|
| **S — stale** | writes the old form as how it works or will work: an example, a signature, a Goal or Mechanism sentence, the expected form of an acceptance box, a summary row of a table | rewritten to the form in force, citing the decision |
| **R — remaining work** | names the old form as what a step removes, or as today's code at a cited line | kept. When the code has already moved (§ Inventory column *in code*), the sentence is rewritten to today's state, unless the owning front holds a box for it (§ Hand-offs) |
| **H — record** | a row of `decisions-taken.md`, a pending question's Measured, a `## Done` line | kept; `decisions-taken.md`'s amended rows are step 1 |
| **P — overtaken question** | a pending question that a later decision answers or makes moot | listed for the maintainer (step 5), never closed by this front |

The four classes in today's text:

| Line | Class | Becomes |
|---|---|---|
| `08-bpp/123-bpp-middleware/README.md:53` — `// middleware — a hook context: -> @Component<RequestBase, Response>` | S | `-> @Component<Response>`; the request is the root context `RequestContext` (354, amending 295) |
| `08-bpp/116-bpp-file-format/README.md:109` — `View` (= `@Component<ElementBase, Element>`, decision 276) | S | `View` (= `@Component<Element>`, 276 as amended by 354) |
| `08-bpp/117-bpp-routing/examples/pagination-example.bp:21` — `import html, {page, PageContext, Element, ElementBase, renderToString} from "jhonstart";` | S | `ElementBase` dropped: nothing in the example uses it since 354 |
| `08-bpp/119-bpp-styling/README.md:95` — `pub val StyledContext = Context<StyledSheet>();` | S | `pub val StyledContext = comptime createContext(StyledSheet.missing());`, read `use context(StyledSheet)` (378, 379) |
| `08-bpp/123-bpp-middleware/README.md:130` — "`LocalKey`, `setLocal(key, value)`, `local(key)` gone" | R | kept: the step's own work |
| `01-compiler/134-builtins-declared/README.md:125` — `[x]` `@Component<C, R>` a type-arity error | H | kept |
| `decisions-pending.md` `24-a` — "`effect-wrapper-mismatch` only for a component whose `T` implements `@Context<B>` …" | P | listed: the code and `@Context` went with 354 (`01-compiler/134` step 6 box 1) |

## Inventory — summary

Lines and files exclude `decisions-taken.md` (step 1). *In code* is the state at the repositories'
`feat`: landed (the code writes the new form), partly, or not (a front still has to move it).
Per-file counts and the patterns are in [`inventory.md`](./inventory.md).

| Family | Decisions | Retired → in force | In code | Lines · files |
|---|---|---|---|---|
| **F1** wrapper and contexts | 354, 357, 378, 379 | `@Component<C, R>` → `@Component<R>`; `implement @Context<C>` → `implement @Renderable`; `ElementBase` / `RequestBase` / `StyledBase` as anchors → the root contexts `ElementContext` / `RequestContext` / `StyledContext`; `Context<T>()`, `provide(ctx, v)`, `use context(ctx)`, `context-unbound` → `createContext(value)`, `use provide(ctx)`, `use context(T)`, the declared default | wrapper landed (134 s6 boxes 1, 6); `ElementBase` and `RequestBase` left as phantoms to retire (`jhonstart/src/element.bp:10` by 26, `rakun/src/request_context.bp:94` by 128); 378 / 379 not landed (134 s6) | 74 · 36 |
| **F2** node type | 223 | `Children`, `JhonstartNode` → `Node` | partly: the core declares `Node` (`node.bp`, 118 s6) and the track's examples write it; `element.bp` / `elements.bp` still take `Children` (118's hand-off to `05-jhonstart`) | 14 · 7 |
| **F3** request locals | 295, 296, 354 | `LocalKey<T>(name)`, `Local<T>()`, `use setLocal(…)` → cardume's `atom(…)`, `use atomSetter(…)`; the page reads `use local(atom)` | not landed (136, 123) | 20 · 8 |
| **F4** tag annotation | 302, 364 | `comptime tag: Tag`, "`html` acts on the return type" → `comptime decl: @Decl`, typed meta | partly (130 s9) | 2 · 1 |
| **F5** styles | 338, 361, 367, 369, 381 | `StyledPropertyView` → `StyledProperty`; `styledWith` / `cls` / `clsWith` → `#[emilia(…)]`; `#[styled(.Token…)]` for emilia's tokens → `#[emilia(…)]`; `#[htmlPrelude]` / `#[stylePrelude]` → `#[bpp.htmlPrelude]` / `#[bpp.stylePrelude]`; `encodeSheet` → gone | not landed (119, 34) | 28 · 13 |
| **F6** validation and emit | 306, 327, 373 | `#[schema]` → `#[validated]`; `schemaOfX()`, `parseX(doc)` → `X.parse(doc)`, `X.jsonSchema()`; no new `@emit` site | not landed (125 s12, 130) | 64 · 18 |
| **F7** std | 330, 336 | `json.stringify` / `json.parse` → `json.encode` / `json.decode`; `result.map(r, f)` → `r.map(f)` | 336 not landed (97 s15) | 5 · 2 |
| **F8** bracket attribute | 118 step 1 (189) | `[name]={expr}` → `name={expr}` | not landed (118 s1) | 17 · 8 |
| **F9** rakun's annotations | 234, 242, 254, 299, 318, 324 | `#[restController]`, `#[configuration]`, `#[bean]`, `#[httpExchange]`, `#[getExchange]`, `#[streamListener]`, `#[listener]` → 318's one decorator per role; `#[value("…")]`, `rkProp*` → 299's typed `#[config]` record; `__rkMake_<T>` → no generated name | not landed (the rakun fronts) | 61 · 21 |

Expected split, from reading samples of each family (step 0 measures it): F1, F2, F3 and F5 are
mostly class S in prose and examples; F6, F8 and F9 are mostly class R, the open steps that remove
them; F4 and F7 are a handful of S lines.

## Measure

Re-runnable from the meta checkout. It prints `file:line` for every hit of one family's pattern
(the patterns are in [`inventory.md`](./inventory.md) § Patterns):

```sh
files=$( (git ls-files 'specs/1.0.12-beta/*.md' 'specs/1.0.12-beta/*.bp'; echo AGENTS.md; echo architecture.md) \
  | grep -v '^specs/1.0.12-beta/decisions-taken.md$' | grep -v '^specs/1.0.12-beta/10-specs/')
grep -nE -- '<pattern of the family>' $files
```

`10-specs/**` is left out of the search, because this front names every retired spelling on
purpose.

## Steps

### Step 0 — Measure and classify

Run § Measure for each family, then classify every hit S / R / H / P in the worktree's `todo.md`
(never committed), file by file. A decision taken after this front was written that retires a
spelling gets a new row in `inventory.md` (its decision, the two forms, *in code*, the count) before
any step rewrites it.

- [ ] every hit § Measure prints has a class in `todo.md`
- [ ] `inventory.md`'s counts re-measured on the meta `feat` the worktree opens from

### Step 1 — `decisions-taken.md`: each amended row states only what is in force

The file's own header rule: "a row amended by a later one states only what is in force and cites
the amendment; a row fully replaced is one line". 25 rows still state the replaced text and append
`**Amended by N:** …`:

193, 200, 270, 276, 277, 280, 284, 285, 295, 296, 300, 301, 302, 338, 351, 352, 353, 354, 355,
356, 360, 364, 369, 376, 378.

Each is rewritten as the rule in force, citing the amendment by number in place, for example 276:
"`pub type View = @Component<Element>;` (354) …", not "`@Component<ElementBase, Element>` …
**Amended by 354:** `View` is `@Component<Element>`". A "goes" clause stays: retiring a form is a
rule in force. A fully replaced row (269, 279, 366) is one line naming its replacement and the
spelling in force: 269 becomes "Replaced by 354 and 379: `@getContext(T)` goes; a context is read
`use context(T)`". The *binds* column does not change.

- [ ] `grep -c '\*\*Amended by' specs/1.0.12-beta/decisions-taken.md` → `0`
- [ ] every row's number, id and *binds* column unchanged (`git diff --word-diff` shows no change
      in the first two and the last cell)
- [ ] no rule added or dropped: the commit message lists the 25 rows, and the maintainer reviews
      them before landing (§ Gate)

### Step 2 — The milestone's central files

`README.md`, `fronts.md`, `status.md` (the decision summary lines of lane L1 — 295's still reads
"`Local<T>()`, `use local` / `use setLocal`; middleware `@Component<RequestBase, Response>`"),
`contracts.md`, `language-gaps.md` (row prose only: the ids, the Marker index and the counts stay,
meta CI check 5), `deferred.md`, every track `README.md`, `08-bpp/surface.md`,
`03-bundled-libs/125-validation-zod/surface.md`.

- [ ] § Measure over these files prints only lines classed R, H or P in `todo.md`
- [ ] `scripts/language-gap-markers.sh` exits 0

### Step 3 — The fronts' READMEs, one commit per track

Tracks 01 to 09 and 20, one commit each, in track order: every S line rewritten. An R line whose
code has already moved is rewritten to today's state, unless the owning front holds a box for it
(§ Hand-offs). A track with a front in a worktree (`git worktree list`, or the front shown as in
progress in `status.md`) is skipped and taken after that front lands, or its S lines are handed to
that front's owner (§ Ownership).

- [ ] § Measure over each track's READMEs and topic files prints only R, H or P lines
- [ ] no acceptance box changes what it checks: a box's expected spelling may change, its condition
      never does

### Step 4 — The examples

`specs/1.0.12-beta/**/examples/**/*.bp`: imports, signatures and calls written in the form in force
(F1's `ElementBase` imports, `@Component<…, T>`; F7's `json.stringify`; F5's `StyledPropertyView`
where 119 holds no box …). An example states its target, and it is code, not prose (`README.md`
§ Rules in force), so it is written for the decision even where the library has not landed it yet,
as every `08-bpp` example already is. A `// LANGUAGE GAP` marker keeps its line and its row.

- [ ] § Measure over the examples prints only lines left to a § Hand-offs front
- [ ] `scripts/language-gap-markers.sh` exits 0; the Marker index counts are unchanged

### Step 5 — The pending questions

`decisions-pending.md` and `decisoes-pendentes.md`: in an open question, an option or example
written in a retired spelling is rewritten when the question does not turn on the old form. The
class P questions are listed once, under a heading of their own, each as the id, the decision that
overtakes it and the closing recommended. The answer stays the maintainer's. Known today: `24-a`'s
last clause (`effect-wrapper-mismatch` for `@Context<B>`), whose code went with 354
(`01-compiler/134` step 6 box 1).

- [ ] both files keep the same order and the same ids; their header counts match
- [ ] every P question of `todo.md` is in the list; none is removed by this front

### Step 6 — The rule that keeps it from drifting (on `141-a`)

The answer to `141-a` is written into `fronts.md` § Rules for a front, or into this track's
README. With (a), the recommendation, the rule reads: "the commit that writes a decision retiring a
spelling rewrites the class S lines of `specs/<current>/**` that write it, and adds its row to
`10-specs/141-specs-sweep/inventory.md`".

- [ ] `141-a` answered, and its rule written where the answer puts it

## Ownership

A front's README is that front's, and the milestone's top-level files are the coordinator's
(`fronts.md` § Ownership, meta repo row). This front works under one carve-out: it edits another
front's README, topic files and examples **only on class S lines** (and class R lines whose code
has moved), **only while that front is not in a worktree**, one commit per track, so that a front
opening later starts from text already swept. When a front opens while 141 is on its track, 141's
commit for that track lands first, or its lines go to that front as a hand-off. The two never
edit one file at once. Central files (step 2) and the pending files (step 5) it edits as the
coordinator's.

## Hand-offs — lines this front leaves to their owner

A front that already holds a box to rewrite a line keeps it. This front does not rewrite the line;
it lists it in `todo.md` as class R.

| Line(s) | The owning box |
|---|---|
| `08-bpp/123-bpp-middleware/examples/locals-and-sequence-example.bp`, `examples/src/app/orders/page.bpp` to atoms | `08-bpp/123`'s box "rewritten to atoms" |
| `StaticPath.data`, `pageData(route, schemaOf…)` (`117-bpp-routing/examples/static-paths-example.bp:53`) | `08-bpp/117` step 3 |
| `StyledPropertyView` in `119-bpp-styling/examples/styled-example.bp` | `08-bpp/119`'s box "`StyledPropertyView` gone" |
| `styledWith` / `cls` / `clsWith` callers | `06-emilia/34` ("every caller moves in this step"); `07-onze/53`'s examples follow 34 |
| `[name]={expr}` attributes | `08-bpp/118` step 1 |

## Gate

No code changes, so `scripts/gate.sh` has nothing to run. The front's gate:

- [ ] the meta `hook-integrity` workflow green: check 2 (every § Layout path exists) and check 5
      (`scripts/language-gap-markers.sh` exit 0)
- [ ] `git diff --stat` on the meta branch touches `specs/1.0.12-beta/**` only (plus `AGENTS.md` if a
      § Layout row's text names a retired spelling)
- [ ] every step's § Measure acceptance re-run on the tip that lands
- [ ] the commits are on `front/141-specs-sweep`; landing is the maintainer's, who reviews step 1's
      rows line by line

## Blast radius

Text only: no compiler, library, test, snapshot or CI file changes. About 280 lines across about
70 files, plus 25 rows of `decisions-taken.md`. A front opened at the same time as one of its
tracks rebases on one small commit. `decisoes-pendentes.md`'s header counts move only if the
maintainer closes a P question.

## Notes

- **Why now.** The compiler is ahead of the specs. 354's wrapper and 357's rules of hooks landed
  (`01-compiler/134` step 6, boxes 1, 5 and 6), and the codemod rewrote botopink-lang, jhonstart,
  onze, styled, rakun and the VS Code extension. Meanwhile 116, 123, 127, 136, 53's acceptance and
  16 examples still write the base or import it.
- **Again after each batch.** Until `141-a` is answered, step 0 re-runs after each batch of
  decisions, and `inventory.md` gains a row per spelling a decision retires.
- **Not this front's.** The code (each decision's front), the closed milestones, and the
  submodules' `AGENTS.md` and docs, which describe their code as it stands and move with it.
