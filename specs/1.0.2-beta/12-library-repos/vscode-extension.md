# vscode-extension — retired syntax, unfiltered test targets, a CI blind to the compiler (7e, 7f, 7g)

Paths are relative to `repository/`. Compiler paths start with `botopink-lang/`; bare `lexer.zig`,
`parser.zig`, `parser/…` and `print.zig` are under `botopink-lang/modules/compiler-core/src/`.

The extension's own suite passes **15/15** and is in sync with the language server; its drift is in
what it offers the user. The three items share a cause: nothing in the extension's CI has ever seen a
botopink parser (7g), which is why 7e and 7f went unnoticed.

---

## 7e — two snippets and one keyword for syntax the parser rejects

### Deciding sites

Snippets live in a single root file, `vscode-extension/snippets.json` (wired at
`package.json:56-58`), not `snippets/`.

| Site | Ships | Parser at HEAD |
|---|---|---|
| `snippets.json:52-56` | prefix `*fn`, body `*fn ${1:name}(…) -> @Iterator<…> { yield $0 }` | hard-removed. `parser.zig:88-90` `deprecatedStarFn` ("Deprecation window was v0.beta.12; the prefix is hard-removed in v0.beta.19"), raised at `parser/decls.zig:322-326` and `parser/exprs.zig:976`; message at `print.zig:89-95` — *"the `*fn` prefix was removed in v0.beta.19"*, hint *"rewrite as `#[@<effect>] fn <name>(...) -> @<Wrapper><...> { ... }`"* |
| `snippets.json:71-82` | prefix `struct`, body `struct ${1:Name} { … }` | `struct` is not a keyword. `lexer.zig:693-745` `keywordOrIdent` has `record` at `:730` and no `struct` entry; it falls through to `:745` `return .identifier` |
| `syntaxes/botopink.tmLanguage.json:47` | `struct` in the `keyword.declaration.botopink` alternation | same — and the same regex also lists `const`, which `lexer.zig:700` explicitly calls out: *"'const' is not a surface keyword in botopink; use 'val' instead."* |

The correct record snippet already sits directly above the broken one (`snippets.json:66-70`).

### Fix — in the extension

Delete the `struct` snippet; rewrite the `*fn` snippet to the `#[@iterator]` form named by
`print.zig:94`; drop `struct` and `const` from the grammar alternation at `:47`. Cross-check the
whole alternation against `lexer.zig:693-745` while there.

### Acceptance

- [ ] Every snippet body and every grammar keyword parses against the compiler at HEAD
- [ ] A test asserts the grammar's declaration-keyword list against `keywordOrIdent`

---

## 7f — the Test Explorer forwards targets `botopink test` refuses

### Deciding sites

`vscode-extension/src/testExplorer.ts:243` builds `["test", "--target", targets.target]` with no
filtering, and `src/targetConfig.ts:6` defines `TARGETS = ["commonJS", "erlang", "beam", "wasm"]`.

### Mechanism

Selecting `beam` or `wasm` in the status-bar target picker and running a test yields
`botopink-lang/modules/compiler-cli/src/cli/test_cmd.zig:58-63`:

```
`botopink test` currently supports only the commonJS and erlang targets
hint: run with `--target commonJS` or set "target": "commonJS" in botopink.json
```

exit 1, surfaced as an opaque test-run failure. `botopink-lang/libs/std/AGENTS.md:117` states the
same restriction, so it is intended, not a CLI gap.

### Fix — in the extension

Add `TEST_TARGETS = ["commonJS", "erlang"]` to `targetConfig.ts`, gate `testExplorer.ts:243` on it,
and when the active target is outside that set either fall back to `commonJS` with a visible notice
or disable the run action with the reason.

### Acceptance

- [ ] No Test Explorer action can produce the `test_cmd.zig:60` error
- [ ] The two target sets (build vs test) are declared in one place and tested

---

## 7g — the extension's CI never builds against this compiler

### Deciding sites

`BOTOPINK_LANG_REF` appears in every sibling's workflow and in **none** of `vscode-extension/`:

| Workflow | Sites | Default |
|---|---|---|
| `onze/.github/workflows/test.yml` | `:57` | `'main'` |
| `jhonstart/.github/workflows/test.yml` | `:48` | `'main'` |
| `rakun/.github/workflows/test.yml` | `:8` (comment), `:58`, `:120` | `'main'` |
| `erika/.github/workflows/test.yml` | `:8` (comment, "default `main`"), `:61-63` (checkout), `:125` (echo) | `'feat'` at `:63`, but `'main'` in the `:8` comment and the `:125` echo — the file disagrees with itself |
| `vscode-extension/.github/workflows/test.yml` | — | — |

The extension's `test.yml` is 37 lines and never checks out botopink-lang at all: checkout
(`:21-22`), setup-node 22 (`:24-30`), `npm ci` (`:32-33`), `npm test` (`:35-36`). The header says
so (`:1-4`): the extension-host suite "is out of scope here; this gate guards the TypeScript modules
behind the extension."

### Mechanism

Nothing in the extension's CI has ever seen a botopink parser, so snippets and grammar for removed
syntax (7e) and a target the CLI refuses (7f) pass it. The siblings' default of `'main'` does not
exercise `feat` either — erika's checkout is the only one pinned to the branch the work happens on.

### Fix — in the extension

Add a job that checks out botopink-lang at `${{ vars.BOTOPINK_LANG_REF || 'feat' }}`, builds
`zig-out/bin/botopink`, and asserts that every snippet body and the `examples/` sources parse.
Settle the `'main'` vs `'feat'` default across all five workflows in the same change — including
erika's `:8` and `:125`, so each file names one branch.

`botopink-lang/build.zig:301` runs the extension's suite through a script that does not exist; that
step is [`../11-hygiene/build-files.md`](../11-hygiene/build-files.md) item 5.4, which recommends
deleting it because the extension runs `npm test` in its own repo — this job is what makes that
deletion safe.

### Ownership

The onze and jhonstart workflows are outside this front's four repos
([`../fronts.md`](../fronts.md)). The change there is one default string per file; make it in the
same sweep, one commit per repo, and say so in each repo's commit.

### Acceptance

- [ ] The extension's CI compiles at least one `.bp` file with the compiler from this workspace
- [ ] All five `BOTOPINK_LANG_REF` defaults name the same branch

---

## Order

7e before or with 7g: 7g's parse check reds the extension's CI on the 7e snippets otherwise.
7f is independent.
