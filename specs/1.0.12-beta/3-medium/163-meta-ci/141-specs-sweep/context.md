# Front 141 — specs sweep: the retired spellings out of the current specs

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [163-meta-ci](../README.md): s6 → 163 s3 · gate → 163 s3. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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

Measured in [`inventory.md`](inventory.md) (2026-10-10, meta `feat`; re-measured by step 0 on
`54c8a60f`): 10 families, 276 lines in 70 spec files besides `decisions-taken.md`, and 26 rows of
`decisions-taken.md` that still state the text an amendment replaced.

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
Per-file counts and the patterns are in [`inventory.md`](inventory.md).

| Family | Decisions | Retired → in force | In code | Lines · files |
|---|---|---|---|---|
| **F1** wrapper and contexts | 354, 357, 378, 379 | `@Component<C, R>` → `@Component<R>`; `implement @Context<C>` → `implement @Renderable`; `ElementBase` / `RequestBase` / `StyledBase` as anchors → the root contexts `ElementContext` / `RequestContext` / `StyledContext`; `Context<T>()`, `provide(ctx, v)`, `use context(ctx)`, `context-unbound` → `createContext(value)`, `use provide(ctx)`, `use context(T)`, the declared default | wrapper landed (134 s6 boxes 1, 6); `ElementBase` and `RequestBase` left as phantoms to retire (`jhonstart/src/element.bp:10` by 26, `rakun/src/request_context.bp:94` by 128); 378 / 379 not landed (134 s6) | 76 · 36 |
| **F2** node type | 223 | `Children`, `JhonstartNode` → `Node` | partly: the core declares `Node` (`node.bp`, 118 s6) and the track's examples write it; `element.bp` / `elements.bp` still take `Children` (118's hand-off to `05-jhonstart`) | 14 · 7 |
| **F3** request locals | 295, 296, 354 | `LocalKey<T>(name)`, `Local<T>()`, `use setLocal(…)` → cardume's `atom(…)`, `use atomSetter(…)`; the page reads `use local(atom)` | not landed (136, 123) | 19 · 7 |
| **F4** tag annotation | 302, 364 | `comptime tag: Tag`, "`html` acts on the return type" → `comptime decl: @Decl`, typed meta | partly (130 s9) | 2 · 1 |
| **F5** styles | 338, 361, 367, 369, 381, 382 | `StyledPropertyView` → `StyledProperty`; `styledWith` / `cls` / `clsWith` → `#[emilia(…)]`; `#[styled(.Token…)]` for emilia's tokens → `#[emilia(…)]`; `#[htmlPrelude]` / `#[stylePrelude]` → `#[bpp.htmlPrelude]` / `#[bpp.stylePrelude]`; `encodeSheet` → gone; `..tokens: Token[]` → `..tokens: @Expr<Token[]>` | not landed (119, 34) | 21 · 10 |
| **F6** validation and emit | 306, 327, 373 | `#[schema]` → `#[validated]`; `schemaOfX()`, `parseX(doc)` → `X.parse(doc)`, `X.jsonSchema()`; no new `@emit` site | not landed (125 s12, 130) | 64 · 18 |
| **F7** std | 330, 336 | `json.stringify` / `json.parse` → `json.encode` / `json.decode`; `result.map(r, f)` → `r.map(f)` | 336 not landed (97 s15) | 5 · 2 |
| **F8** bracket attribute | 118 step 1 (189) | `[name]={expr}` → `name={expr}` | not landed (118 s1) | 17 · 8 |
| **F9** rakun's annotations | 234, 242, 254, 299, 318, 324 | `#[restController]`, `#[configuration]`, `#[bean]`, `#[httpExchange]`, `#[getExchange]`, `#[streamListener]`, `#[listener]` → 318's one decorator per role; `#[value("…")]`, `rkProp*` → 299's typed `#[config]` record; `__rkMake_<T>` → no generated name | not landed (the rakun fronts) | 61 · 21 |
| **F10** diagnostic codes | 384, 385 | `decorator-member-fn-imported-name`, `typeinfo-meta-expr-elsewhere` → gone (a name resolves where it was written) | not landed (01 s35, 130 s8) | 5 · 2 |

Expected split, from reading samples of each family (step 0 measures it): F1, F2, F3 and F5 are
mostly class S in prose and examples; F6, F8 and F9 are mostly class R, the open steps that remove
them; F4 and F7 are a handful of S lines.

## Measure

Re-runnable from the meta checkout. It prints `file:line` for every hit of one family's pattern
(the patterns are in [`inventory.md`](inventory.md) § Patterns):

```sh
files=$( (git ls-files 'specs/1.0.12-beta/*.md' 'specs/1.0.12-beta/*.bp'; echo AGENTS.md; echo architecture.md) \
  | grep -v '^specs/1.0.12-beta/decisions-taken.md$' | grep -v '^specs/1.0.12-beta/3-medium/163-meta-ci/10-specs/')
grep -nE -- '<pattern of the family>' $files
```

`10-specs/**` is left out of the search, because this front names every retired spelling on
purpose.

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
| `#[schema]` / `schemaOf…()` in `117-bpp-routing/examples/pagination-example.bp` and `static-paths-example.bp` | `08-bpp/117` step 8 ("`pagination-example.bp`, `static-paths-example.bp` and the two `page.bpp` rewritten") |
| `#[schema]` / `schemaOf…()` in `121-bpp-content/README.md` § Mechanism, `examples/content-collection-example.bp`, `examples/markdown-example.bp` | `08-bpp/121` step 10 ("`content-collection-example.bp` rewritten", "`markdown-example.bp`'s `Meta` is `#[validated]`") |
| `#[schema]` / `schemaOf…()` / `actionRef("…", schemaOf…, schemaOf…)` in `127-bpp-actions/README.md` § Mechanism (today's form) and `examples/typed-action-example.bp` | `08-bpp/127` step 5 ("`Signup` / `Subscribed` in the examples drop `#[schema]`") |
| `rkProp` / `rkPropInt` imports in `04-rakun/08-rakun-data-sql/examples/*.bp` | `04-rakun/08`'s box "rewritten to decision 281 … and 299 (no `rkProp` / `rkPropInt` import)" |
| `#[configuration]` / `#[bean]` (318 (3): `#[provides]`) in `04-rakun/13-rakun-http-clients/examples/http-exchange-example.bp` and `19-rakun-test-utilities/examples/controller-test-example.bp` | `04-rakun/04` step 7's box "`#[configuration]`, `#[bean]` … deleted"; 19 step 5 (the example) |
| `#[httpExchange]` comments in `13-rakun-http-clients/examples/http-exchange-example.bp` | `04-rakun/13`'s box "`#[httpExchange]`, `#[getExchange]` … deleted" |
| `#[listener]`, `__rkMake_<Template>` in `15-rakun-messaging/examples/order-listeners-example.bp` | `04-rakun/15`'s box "`#[streamListener]` and the type-level `#[listener]` deleted, every site and test rewritten" |

## Gate

No code changes, so `scripts/gate.sh` has nothing to run. The front's gate:

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
