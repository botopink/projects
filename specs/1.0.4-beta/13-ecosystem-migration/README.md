# Front 13 — Ecosystem migration

**Delivered** 2026-09-17/18. All five libraries are on the 1.0.3 surface — emilia `63f62d1`, erika
`4a75280`, jhonstart `f2bf0e8`, onze `557fd9f`, rakun `0814492` — and
`scripts/known-red-libs.txt` has had no line since `botopink-lang` `aa24146`. Every library's
`scripts/known-broken-examples.txt` is empty too: the examples that front 10's gate exposed
(emilia `emilia-card`; jhonstart `-counter`, `-html`, `-todo`; the `jonhstar` leftover) all build.

Carried from 1.0.3-beta front 03, amended by
[decision 8](../08-review-backlog/decision-8-language.md). The counts below were measured at the meta
repository's `6ecfd7cf` and re-measured at each library's `origin/feat` after 10 and 11 landed —
unchanged ([`../12-surface-cutover/remeasure.md`](../12-surface-cutover/remeasure.md) §4; the
"113 declarations" of the blast radius is 53 by that table).

**Owned:** `repository/{emilia,erika,jhonstart,onze,rakun}/**` — sources, `.d.bp`, tests, examples,
their markdown docs and `AGENTS.md` · the submodule pointers of those five in the meta repository.

---

## What had to move

Measured at the meta repository's `feat` (`6ecfd7cf`):

| Library | `record` | `enum` | `interface` | `record { }` literals | Notes |
|---|---|---|---|---|---|
| emilia | 0 | 1 | 0 | 0 | `Token` with nested sections (`src/tokens.bp:37`) |
| erika | 7 | 0 | 0 | 6 | `src/erika.bp:570` generates `record { … }` **text** for the `select` projection |
| jhonstart | 2 | 0 | 2 | 10 | `hooks.bp` capabilities (`record { }`, `current`, `state`/`dispatch`); `html.bp` tokens; `@Context<Element, {}>` types |
| onze | 4 | 0 | 3 | 0 | `#[mock] interface` synthesis |
| rakun | 30 (3 in `src/`) | 1 | 2 | 0 | annotated fields `#[value("app.timezone")]`; 10 records with methods and no fields |

Markdown teaching the old syntax: 12 files, 29 occurrences.

## Delivered, per library

| Library | Commits | What it took |
|---|---|---|
| **emilia** | `63f62d1`, `d90922b`, `72108f2`, `d14310c`, `e30228f`, `a02b6e8` | `Token` becomes an enum-shaped `type`; the 27 section annotations become path names (`TokenText` → `Token.Text`, decision 8 §5.3b) in the same sweep as 06's C8/N28; `register` returns `void` (`unit` is not a type); `emilia.bp` names the sibling module `Token` comes from; **the erlang cell is measured by CI, 17/17** (`8f93475`) |
| **erika** | `4a75280`, `f189774`, `a8dd983`, `97971a7` | types, tuple rows, a positional SQL AST — the generated projection is `#( … )` text now; every empty array literal is born with its element type; **the erlang rows are hard cells, 31/31** (`81e1f1c`) |
| **jhonstart** | `f2bf0e8`, `a65fffd`, `2aefaf5`, `4b85b43`, `f8f9b0e`, `08e4744` | `type`, `behavior`, labeled-tuple hook shapes; `@Context<Element, {}>` → `#()`; `hooks.bp` and `html.bp` name the sibling module `Element` comes from; **jhonstart runs on erlang too, 8/8** |
| **onze** | `557fd9f`, `4707c83`, `c4098c3`, `7735d19` | `#[mock] behavior`, `type MockXxx`, `OnzeStub` a type; the mock host cells gain an erlang form; **the erlang cell is green** once `targets` names it |
| **rakun** | `0814492`, `dcf1938`, `4cc417b`, `1dd40ac`, `db7e99c` | its 15 `DeclKind.Record` checks read `DeclKind.Type`; annotated fields keep their annotations inside the field list; records with no fields become `type Name { methods }`; the example imports the `http` types its signatures name, and the whole type closure of each module it uses |

## Gate

- [x] No `record`, `enum`, `interface` keyword and no `record {` literal left in any of the five
- [x] `zig build test-libs`: **11 passed, 0 failed, 1 skipped** — the skip is rakun's erlang cell
- [x] Every example builds; each `scripts/known-broken-examples.txt` is empty
- [x] Meta submodule pointers bumped for the five libraries; each library's own gate ran on every
      commit (no `--no-verify`)
- [x] `AGENTS.md` of every directory touched, updated in the same commit

## What it left, and where

Everything below is **1.0.5-beta `09-ecosystem-residuals`** unless a row names another front. The
compiler defects this front found are listed against the front that owns the *file*; the row here is
the library re-test that follows each fix.

| Residual | Owner in 1.0.5-beta |
|---|---|
| **`botopink format --check` does not pass on erika and jhonstart, and emilia's `format` reorders `Token`** (payload variants move before sections, an end-of-line comment on a field moves to the next line, blank lines inside `loop` bodies and `if` branches are dropped). The parser keeps no member positions or trailing trivia; `format` output compiles and is stable (`6bf0817`), which is as far as the AST allows | `01-checker` (the parser half), then `09-ecosystem-residuals` re-runs `--check` |
| **Decision 8's remaining items in the libraries** — `Self<T>` in generic declarations, `@Result<T, E>` returns on effect fns, annotations on the `[]` declarations (18 in erika, 4 in jhonstart) — wait on the checker step that was moved out of 12 and never ran | after `01-checker` step 9 |
| **rakun's erlang cell is skipped** — `botopink test` cannot run the target for it, or the library's `targets` list excludes it. The row that named missing `.erl` host-module shipping as its blocker is retired: front 20 landed `shipErlSidecars` (`c01695f`), wired into `botopink test` | `09-ecosystem-residuals`, re-test |
| **Importing a type requires importing the whole type closure its declaration mentions** — a field's type and a method signature's types must each be imported by name, or the consumer reds with `unknown type '<Name>'`. Found migrating `examples/rakun`, worked around by naming every type in the `from` clause | `01-checker` |
| **A type error's location names the wrong module** — `unknown type 'UserService'` reported at `src/main.bp:48:14` for a declaration in `src/users.bp:48:14` | `01-checker` |
| **commonJS emits `require("../module")` for a sibling-module import inside a dependency** — emilia and jhonstart route around it by naming the sibling module in the import (`d14310c`, `2aefaf5`) | `04-js` |
| **A label access in an untyped comptime body lowers to `maps:get`** (`badmap`) — jhonstart's html reads tokens positionally (`t.0…t.6`) to route around it. 06's N24 struck the two sibling rows by probe; this one was not among them | `01-checker` |

The compiler defects this front found and that **closed inside 1.0.4-beta**: `MissingExternalTarget`
had no location or function name (06 C13, `7b1db40`); labels were lost when a generic labeled return
was instantiated, and a fn-typed tuple label called as a method was not rewritten (06 N24,
`174e0e4`); an imported host-backed `declare fn` with an inline template had nothing to call on
erlang (`84a944b`); a library could not ship an erlang host module (20 step 3, `c01695f`).

## Blast radius as delivered

53 declarations and 16 literals in `.bp` files, 12 markdown files. Runtime changes only where
anonymous records were built: erika rows and tokens, jhonstart capabilities and tokens — all read by
label inside `.bp` code, so the `baseline/` outputs captured before the migration are the check.
