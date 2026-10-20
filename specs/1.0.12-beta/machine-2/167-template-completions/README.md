# Front 167 — template completions: a template's own syntax answers the editor's completion

**Priority:** later (the maintainer, 2026-10-20: "uma frente com essa ideia para ser feita depois") — opened in no queue; it
starts when the maintainer moves it into one.
**Repository:** two (the maintainer, 2026-10-20), each step in one of them:
- `repository/botopink-lang` (`--lang`) — the `compiler` module's build surface (`libs/std/src/compiler.bp` and its readers) and
  the language server, `modules/language-server/` (`textDocument/completion`, today `Server.completionItems` / `engine.completion`);
  its build steps are front 144's (433, `fronts.md` § rule 1), this front holding the design and the order;
- `repository/vscode-extension` (`--repo vscode-extension`) — the client (`src/extension.ts`'s `LanguageClient`), the grammar
  (`syntaxes/botopink.tmLanguage.json`) and the extension's defaults, so completion fires inside a template's text; beside front
  161's steps, in that repository's lane.

A library that answers completions for its template (rakun-bpp's `html`, `query`) does it in its own front, after s2.
**Model:** `fable` for s0 (a design step, `Plan` agent), then opus for the surface (s1) and sonnet for the language server's
half, the extension and the cells (s2, s3, s3b).
**Depends on:** decision 802 — no hole is the language's; a template reads its text raw and decides its syntax with the
compiler's build methods directly (`compiler.text`, `compiler.lookup`, `compiler.ast`), `code` optional — and B-149 P2 – P4 built
over it.
**Owns:** nothing until s0 names it.
**Gate:** standard (`fronts.md` § Gate).

---

## Problem

A template's text is a language of its own (802, 577 (5)): `` html @`<div class="${c}">…</div>` ``, `` query @`from User where …` ``,
`` box @`section name` ``. The language server knows botopink, not those languages, so inside `` @`…` `` the editor offers
nothing. Only the template knows its syntax, so only the template can say what fits where the cursor stands.

## The idea (the maintainer, 2026-10-20)

When the editor asks for completion with the cursor `|` inside a template's text, the language server runs that template's body
at build on the text as written so far, telling it where the cursor is, and the template answers a list of suggestions through
the build surface — "um `comptime.sugestoes([…])` algo assim":

```bp
pub fn box(syntax t: string) -> anyvalue {
    val text = compiler.text(t);
    val at = compiler.cursor(t);                       // ?i32 — set only when the editor asks
    if (at != null) {
        val word = wordBefore(text, at!);
        // the caller's names in scope that start with what is typed
        compiler.suggestions(compiler.bindings(t)
            .filter({ b -> compiler.name(b)!.startsWith(word) })
            .map({ b -> Suggestion(label: compiler.name(b)!, kind: .Value) }));
    }
    // … the ordinary body, building the code
}
```

```
box @`section na|`      →  the editor offers  name · names · navItems
```

Every name here (`compiler.cursor`, `compiler.suggestions`, `Suggestion`) is a sketch; s0 fixes them.

## What s0 answers

1. **The surface**: the call that answers the suggestions (`compiler.suggestions(items)` or the template's return in a
   completion run), how the cursor reaches the body (`compiler.cursor(t) -> ?i32`, an offset into `compiler.text(t)`), and what a
   suggestion carries — a label, a kind, a detail, the text inserted, the range it replaces.
2. **The completion run**: the body runs with no output kept — no `addMember`, `addType`, `init` and no code answered (or its
   answer discarded) —, on a text that may not parse yet; a body that fails gives no suggestion and no diagnostic.
3. **Cost**: a run per keystroke — the cache (767, 793 (4)), a deadline, and what the language server keeps between runs.
4. **The compiler's own help**: what `compiler.bindings(t)` / `compiler.lookup` answer in a completion run, so a template
   suggests the caller's names without walking the scope itself (686's word rule read against a text still being typed).
5. **`code`**: whether std's `code` answers completions for its own `${…}` text (botopink names and members), as the first
   template that does.
6. **The editor**: VS Code offers no quick suggestion inside a string by default (`editor.quickSuggestions.strings` off), and the
   grammar paints `` @`…` `` as one region; what the extension sets — the template text scoped apart from a plain string, a
   `configurationDefaults` for `[botopink]`, the trigger characters the server declares — so suggestions appear as the user types.
7. **Beyond completion**: hover and diagnostics inside the text by the same route — named, not built here.

## Steps

### s0 — the plan (`fable`, `Plan` agent)

- [ ] the answers to § What s0 answers, the pieces in landable order with each piece's oracle, the model per piece; its open
      points filed as questions in `decisions-pending.md` (English, then the Portuguese page)

### s1 — the build surface (144, `compiler.bp` and the readers)

- [ ] the cursor and the suggestions as s0 fixes them; outside a completion run the cursor is `null` and the suggestions are
      ignored; cells: a template answering suggestions, the same template's ordinary build unchanged

### s2 — the language server

- [ ] `textDocument/completion` inside a template's text: the call found, its body run in a completion run with the cursor's
      offset, the suggestions mapped to LSP items; outside a template text, completion as today
- [ ] tests in `modules/language-server/src/tests/` (a template's suggestions at a cursor, a failing body answering none)

### s3 — the VS Code extension (`repository/vscode-extension`)

- [ ] completion inside a template's text as s0 (6) fixes it: the grammar's scope for `` @`…` ``, the `[botopink]` defaults, the
      client passing the server's trigger characters; `test/grammar.test.ts` (the scope) and `test/unit.test.ts` (the defaults);
      the extension's `AGENTS.md` and `CHANGELOG.md`
- [ ] by hand in VS Code: `` box @`section na|` `` offers the caller's names as the user types

### s3b — std's `code`

- [ ] `code` answers completions inside its own text, if s0 says so (5)

### s4 — Conformance (459)

- [ ] the whole suite green; the front's changes against the cells; the cells written, the missing ones proposed
