# Front 06 (std track) — the bundled `validation` library

The directory number is this front's index inside `01-std`, beside `04-routing-lib` and
`05-actions-lib`; it is not a milestone front number — rakun's front 06 is
`03-rakun/06-rakun-context-api`. Everywhere else it is named `01-std/06-validation-lib`.

**Track:** A std
**Priority:** high — the same constraints run in the server's handler and in the client's form, and
the module that holds them imports rakun's core, which is erlang-only since decision 113: a browser
build that reaches `rakun-validation` today pulls an erlang-only package, and onze front 68's
server-only refusal would reject it
**Target:** both — erlang and commonJS, every module
**Wave:** 0 — beside `01-std`'s steps; Steps 1–4 need only `01-std` step 2; Step 5 bundles it after
`04-routing-lib` Step 2; rakun front 14's Step 7 (the member leaves rakun) follows Step 4
**Depends on:** `01-std` step 2 (`testing.asserts`) · `01-std/07-std-json-writers` (`json.quote`,
which replaces `report.bp:80`'s `jsonEscape`) · `01-std/04-routing-lib` Step 2 (the bundled-package
registry, for Step 5 only). The code is landed (rakun front 14, rakun `af933f7`); this front moves
it, so it waits on nothing of rakun's
**Owns:** `repository/botopink-lang/libs/validation/**` (`botopink.json`, `AGENTS.md`,
`src/root.bp`, `src/report.bp`, `src/table.bp`, `src/messages.bp`, `src/spi.bp`,
`src/constraints.bp`, `src/binding.bp`, `src/decorators.bp`, `test/**`) · the `validation` row of
`repository/botopink-lang/libs/AGENTS.md` · the name `validation` in the bundled-package list of
`build.zig` (one entry, by `04-routing-lib`'s carve-out)
**Does not touch:** `libs/std/**`, `libs/routing/**`, `libs/actions/**`; `repository/rakun/**` —
rakun front 14 Step 7 deletes `modules/rakun-validation`, moves `boot.bp` into the core and sets the
message source at boot; `repository/onze/**` — onze sets the browser's message source in its
generated entry (front 68); `repository/jhonstart/**` — jhonstart names no validation code (the
client form's application code imports it)
**Reference:** [decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rule 5 (validation is a bundled library; the message lookup is injected; the member leaves rakun) ·
decision 113 item 8 (rakun's core is erlang-only — the fact that broke the old home) · decision 115
(a bundled library is neutral and resolves like `from "std"`) · rakun front
[14](../../03-rakun/14-rakun-validation/README.md) (the constraints, `#[validated]`, the SPI, the
report, typed coercion — every behaviour this library keeps) · rakun front
[05](../../03-rakun/05-rakun-config-profiles/README.md) (the boot-time call by name, `contracts.md
§ 5c` 05 ↔ 14)

---

## Problem

Validation is the one piece of rakun both halves of an application run: the handler refuses what the
form should have refused, and the form refuses it first. Front 14 made it a boundary member,
`modules/rakun-validation`, `"targets": ["commonJS", "erlang"]`, with one source compiled twice so
the two sides run the same predicate. It works, 54 tests on both rows. But the member imports rakun's
core for one function — `import {rkProp} from "rakun"` (`messages.bp:22`), the property reader behind
message templates — and decision 113 made the core erlang-only. A browser build that imports
`rakun-validation` now reaches a package with no commonJS target, which front 68's server-only
refusal rejects by design.

The maintainer answered with a library of its own, bundled like `routing` (decision 116 rule 5):
rakun, onze and application code import `validation` by name, the library imports std and nothing
else, and the one thing it took from rakun — where a message template comes from — is handed to it.

## Current state

Measured 2026-09-25 on `repository/rakun` `a8ba8bd` (front 14 landed at `af933f7`) and
`repository/botopink-lang` `52843fd5`.

| Piece | State | Evidence |
|---|---|---|
| The member | 9 `.bp` sources, 1 184 lines, plus two host halves | `modules/rakun-validation/src/`: `report.bp` 102 · `table.bp` 104 · `messages.bp` 120 · `spi.bp` 115 · `constraints.bp` 253 · `binding.bp` 173 · `boot.bp` 55 · `decorators.bp` 219 · `root.bp` 43; `validation_host.mjs` 85; `sidecars/rakun_validation.erl` 200 |
| Its manifest | `"target": "commonJS"`, `"targets": ["commonJS", "erlang"]`, a workspace dependency on `rakun` | `modules/rakun-validation/botopink.json` — commonJS first, against decision 113's "erlang first in every list" |
| Its one rakun import | `rkProp`, for the locale and the message catalogue | `messages.bp:22`, used at `:42-54` (`currentLocale`, `templateFor`: `rakun.validation.messages.<locale>.<code>`, then `rakun.validation.messages.<code>`, then the built-in) |
| Its tests | 54, green on both rows at landing | `test/binding_test.bp` 10 · `config_test.bp` 6 · `constraints_test.bp` 14 · `parity_test.bp` 3 · `report_test.bp` 7 · `spi_test.bp` 8 · `table_test.bp` 6; four of them import `rkSetProp` from `"rakun"` to set a message key (`binding_test.bp:22`, `parity_test.bp:26`, `spi_test.bp:19`, `config_test.bp:30`) |
| rakun-specific text | the boot refusal | `boot.bp:37-55` (`configProblem` — `"rakun config: \`<Type>\` is not valid - the application will not start"`, `refuseInvalidConfig`), and `config_test.bp`, which drives rakun's `#[configurationProperties]` binder |
| Host state | two tables | `spi.bp:35-61` (seven cells — the constraint registry, ETS owned by a process on erlang, `rakun_validation.erl:36-148`) · `binding.bp:32-50` (five cells — the per-request accumulator, the serving process's dictionary, `rakun_validation.erl:150-200`); the node twin is `validation_host.mjs` |
| JSON | a private escaper | `report.bp:80` (`jsonEscape` — `\\`, `"`, `\n`, `\r`, `\t` only), used by `violationJson` and `table.bp:32` |
| Consumers | none in code | no `from "rakun-validation"` outside the member's own sources and tests; `rakun/docs.md`, `AGENTS.md`, `modules/README.md` and `CHANGELOG.md` name it |
| The emitted code's imports | the application imports from `"rakun-validation"` | `decorators.bp:28-35` — `validate<TypeName>` and `constraintsOf<TypeName>` reference `ValidationReport`, `Violation`, the `v*` helpers and `constraintTableJson` at the application site |
| Bundled packages | `std`, then `routing`, `actions` | `04-routing-lib` Step 2; `05-actions-lib` Step 6 |

## Mechanism

**Moved, not rewritten.** Seven of the member's eight modules move to `libs/validation/src/` with
their functions, names and tests; four changes only:

1. **The message source is injected.** `messages.bp` stops importing rakun. The resolution order is
   the library's; the keys are the source's:

   ```bp
   pub type MessageSource(locale: fn() -> string, template: fn(key: string) -> string)
   pub fn setMessageSource(source: MessageSource) -> i32
   pub fn builtInOnly() -> MessageSource          // the source in force until one is set
   ```

   `templateFor(code, builtIn)` asks `template(locale() + "." + code)` when the locale is not `""`,
   then `template(code)`, then answers `builtIn`; a `""` from the source means "no entry". rakun sets
   the source at boot over its own keys, so its messages are unchanged:

   ```bp
   // rakun, at boot (front 14 Step 7)
   setMessageSource(MessageSource(
       locale: { -> rkProp("rakun.validation.locale") },
       template: { key -> rkProp("rakun.validation.messages." + key) },
   ));
   ```

   onze sets the browser's in the entry it generates (front 68); with none set, the built-in texts
   answer. The library spells no `rakun.` key.
2. **`jsonEscape` leaves** for std's `json.quote` (`07-std-json-writers`); `violationJson` and
   `constraintTableJson` write with `json.quote` / `json.object` / `json.array`, and escape every
   control character.
3. **The host tables are inline templates, not a sidecar.** A bundled library embeds its `.bp`
   files only (`04-routing-lib` Step 2), so the twelve cells of `spi.bp` and `binding.bp` are
   re-expressed as `#[@External.Erlang(…)]` / `#[@External.Node(…)]` templates, as std's cells are:
   on erlang the registry is a `persistent_term` entry keyed `{validation, constraints}` (written at
   registration, read per validation) and the accumulator the serving process's dictionary under
   `{validation, acc}`; on node both are fields of one `globalThis` cell, the shape std's
   `testing/mocks` uses. `bindingIsolated()`'s measurement (spawn, push in the child, compare) is one
   template expression. `validation_host.mjs` and `rakun_validation.erl` are not carried. If a cell
   cannot be expressed as a template, the front stops and records it in `decisions-pending.md`
   rather than shipping a sidecar.
4. **`boot.bp` does not move.** Its refusal names rakun's configuration (`"rakun config: …"`,
   property keys), so it is rakun's: rakun front 14 Step 7 moves it into the core as
   `modules/rakun/src/config_check.bp` with `config_test.bp`, beside front 05's binder, which owes the
   call (`validate<TypeName>(bound)` then `refuseInvalidConfig(typeName, prefix, report)`).

The manifest becomes `"name": "validation"`, `"target": "erlang"`, `"targets": ["erlang",
"commonJS"]`, no `dependencies`. The emitted code's imports read `from "validation"`, and the
decorator's docblock rule becomes: import `validated` from `"validation"`, never front 05's
placement-only `#[validated]` from `"rakun"`, and never both.

```
libs/validation/
├── botopink.json     "name": "validation", "target": "erlang", "targets": ["erlang", "commonJS"]
├── AGENTS.md
├── src/root.bp       pub mod report; pub mod table; pub mod messages; pub mod spi;
│                     pub mod constraints; pub mod binding; pub mod decorators;
├── src/report.bp     Violation, ValidationReport, violationJson (json.quote)
├── src/table.bp      constraintTableJson and the blob grammar
├── src/messages.bp   Arg, MessageSource, setMessageSource, builtInOnly, templateFor, interpolate, message
├── src/spi.bp        Constraint, registerConstraint, vConstraint, … (registry as a template)
├── src/constraints.bp  the v* predicates (std `regex`, `time`)
├── src/binding.bp    bindInt, bindBool, bindRequired, bindEpochMillis, … (accumulator as a template)
├── src/decorators.bp #[validated] and the constraint markers
└── test/             report · table · messages · spi · constraints · binding · parity
```

Module atoms follow decision 109: `validation@report`, `validation@report@@ValidationReport`.

## Steps

### Step 1 — Scaffold `libs/validation`

**Acceptance:**
- [ ] `libs/validation/botopink.json` reads `"name": "validation"`, `"targets": ["erlang",
      "commonJS"]` with erlang first, no `dependencies`, and lists the eight `src/*.bp` in import order
      (a module before the siblings that import it — the order `rakun-validation/src/root.bp:26-30`
      documents)
- [ ] `grep -rn "rakun\|jhonstart\|onze\|emilia" libs/validation/src` finds no import and no key —
      only prose may cite rakun front 14 as the origin
- [ ] no `*.erl` or `*.mjs` file under `libs/validation/`
- [ ] `libs/AGENTS.md` names `validation/`

### Step 2 — Move the seven modules and their tests

`report`, `table`, `constraints`, `decorators` byte-for-byte except their import lines and
`from "rakun-validation"` in prose; `spi` and `binding` with their host cells re-expressed (change 3);
`messages` with the injected source (change 1). The tests move with them, suite `validation:`; the
four that set a key with `rkSetProp` set a `MessageSource` over a test table instead.

**Acceptance:**
- [ ] the 48 tests of `binding_test`, `constraints_test`, `parity_test`, `report_test`, `spi_test`
      and `table_test` keep their assertions and are green on erlang and on commonJS
- [ ] `diff` of every moved function body against `modules/rakun-validation/src/` shows only the
      four changes of *Mechanism*
- [ ] `bindingIsolated()` is `true` on erlang, measured by the template, and two concurrent
      processes binding at once see only their own violations

### Step 3 — The injected message source

**Acceptance:**
- [ ] with no source set, `templateFor("size", builtInTemplate("size"))` answers the built-in text
- [ ] with a source whose table holds `pt.size` and `size`, locale `pt` answers `pt.size`'s text,
      locale `en` answers `size`'s, and a table with neither answers the built-in — the resolution
      order front 14 specified, asserted three ways
- [ ] the rakun-shaped source of *Mechanism* reproduces every message the member's `spi_test.bp`
      and `parity_test.bp` assert today, literal for literal
- [ ] `grep -rn "rakun\." libs/validation/src` is empty

### Step 4 — JSON through std

**Acceptance:**
- [ ] `violationJson` and `constraintTableJson` answer the literals `report_test.bp` and
      `table_test.bp` assert today, byte for byte
- [ ] a message containing U+0001 and a `"` produces JSON std's `json.parse` accepts
- [ ] `grep -n "fn jsonEscape" libs/validation/src` is empty

### Step 5 — Bundle it

`validation` joins the bundled-package list (`std`, `routing`, `actions`, `validation`). Opens after
`04-routing-lib` Step 2.

**Acceptance:**
- [ ] a scratch project with no `dependencies` and a `#[validated]` record builds on `--target
      erlang` and `--target commonJS`, `validate<TypeName>` answers the same report on both, and the
      program imports only `from "validation"` and `from "std"`
- [ ] the erlang output names `validation@constraints`; the commonJS output requires
      `./validation/constraints.js`
- [ ] a manifest listing `validation` in `dependencies` is refused with a located error
- [ ] `grep -rn '"validation' modules/compiler-core/src` is empty; `snapshots/codegen/**`
      byte-identical

### Step 6 — Both targets, in the gate

**Acceptance:**
- [ ] `botopink test --target erlang` and `--target commonJS` from `libs/validation/` green;
      `zig build test-libs` reads `validation · erlang: pass` and `validation · commonJS: pass`
- [ ] `libs/validation` is in `scripts/format-check.sh`'s `TREES`, green

### Step 7 — The consumers switch

| Consumer | Front | What changes |
|---|---|---|
| rakun | 14 Step 7 | `modules/rakun-validation` deleted; `boot.bp` → `modules/rakun/src/config_check.bp` with `config_test.bp`; `setMessageSource` at boot over `rakun.validation.*`; rakun's workspace root `["erlang"]` |
| rakun config | 05 | the boot call `validate<TypeName>(bound)` + `refuseInvalidConfig`, emitted code importing from `"validation"` |
| rakun-web request binding | 07 | `bind*` from `"validation"` |
| onze | 68 | the generated entry sets the browser's `MessageSource` |
| application code | onze 53 | `#[validated]` records and the client form import `from "validation"` |

**Acceptance:**
- [ ] `grep -rn "rakun-validation" repository/ --include=*.bp --include=botopink.json` is empty
- [ ] `grep -rn "fn vNotBlank\|fn constraintTableJson\|fn registerConstraint" --include=*.bp
      repository/` finds only `repository/botopink-lang/libs/validation/src/`
- [ ] no `botopink.json` under `repository/` lists `validation` in `dependencies`

## Test plan

`libs/validation/test/*.bp`, suite `validation:`, run on both targets from `libs/validation/` and by
`zig build test-libs`. The 48 moved tests keep their assertions; Step 3 adds the source's three-way
resolution; Step 4 the control-character case. `config_test.bp`'s six stay rakun's, beside
`config_check.bp`. The bundling is tested in the compiler's suite beside `04-routing-lib`'s.

## Gate

- [ ] `zig build test-libs` green — `validation` on both targets; rakun green with the member gone
- [ ] the Step 5 compiler test green from a cold cache; `snapshots/codegen/**` byte-identical
- [ ] `libs/AGENTS.md`, `libs/validation/AGENTS.md`, and (with rakun front 14 Step 7)
      `repository/rakun/AGENTS.md`, `modules/README.md` and `docs.md` in the same commits

## Blast radius

- **rakun:** one member fewer; the workspace root drops commonJS; `boot.bp` joins the core. An
  application that imported `from "rakun-validation"` imports `from "validation"`.
- **onze:** the client can validate without reaching an erlang-only package; the entry sets one
  message source.
- **Compiler:** one more bundled name; nothing else.

## Notes

- **Why a library and not a rakun member on std alone.** The maintainer's choice (decision 116 rule
  5 (b)): a member of rakun that the browser imports is still a rakun package on the client graph,
  and the question of which rakun packages a client may reach would come back with the next one.
- **Why the source is a record of two functions and not a map.** A catalogue may be computed (a
  locale negotiated per request, front 64), and a function is what both rakun's `rkProp` and a
  shipped client table can be.
