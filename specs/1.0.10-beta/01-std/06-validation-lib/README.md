# Front 06 (std track) — the bundled `validation` library

The directory number is this front's index inside `01-std`, beside `04-routing-lib` and
`05-actions-lib`; it is not a milestone front number — rakun's front 06 is
`03-rakun/06-rakun-context-api`. Everywhere else it is named `01-std/06-validation-lib`.

**Track:** A std
**Priority:** high — the same constraints run in the server's handler and in the client's form;
their old home imported rakun's core, which is erlang-only since decision 113, so a browser build
that reached it pulled an erlang-only package
**Target:** both — erlang and commonJS, every module
**Depends on:** `01-std` step 2 (`testing.asserts`) · `01-std/01-std-lib-enablement` Step 11
(`json.quote`) · `01-std/04-routing-lib` Step 2 (the bundled-package list, for Step 5 only)
**Owns:** `repository/botopink-lang/libs/validation/**` (`botopink.json`, `AGENTS.md`,
`src/root.bp`, `src/report.bp`, `src/table.bp`, `src/messages.bp`, `src/spi.bp`,
`src/constraints.bp`, `src/binding.bp`, `src/decorators.bp`, `test/**`) · the `validation` row of
`repository/botopink-lang/libs/AGENTS.md` · the name `validation` in `build.zig`'s bundled-package
list (one entry, by `04-routing-lib`'s carve-out)
**Does not touch:** `libs/std/**`, `libs/routing/**`, `libs/actions/**`; `repository/rakun/**` —
rakun keeps the boot-time configuration check (`config_check.bp`) and sets the message source at
boot; `repository/onze/**` — onze sets the browser's message source in its
generated entry (front 68); `repository/jhonstart/**` — jhonstart names no validation code (the
client form's application code imports it)
**Reference:** [decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rule 5 (validation is a bundled library; the message lookup is injected; the member leaves rakun) ·
[decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rules 8 and 9 (`.bp` files only, target-native code inline; every rakun
manifest `["erlang"]`) ·
decision 113 item 8 (rakun's core is erlang-only — the fact that broke the old home) · decision 115
(a bundled library is neutral and resolves like `from "std"`) · rakun front
[14](../../03-rakun/14-rakun-validation/README.md) (the constraints, `#[validated]`, the SPI, the
report, typed coercion — every behaviour this library keeps) · rakun front
[05](../../03-rakun/05-rakun-config-profiles/README.md) (the boot-time call by name, `contracts.md
§ 5c` 05 ↔ 14)

---

## Problem

Validation is the one piece of rakun both halves of an application run: the handler refuses what the
form should have refused, and the form refuses it first. One source compiled twice runs the same
predicate on both sides. Its home as a rakun member imported rakun's core for one function — the
property reader behind message templates — and decision 113 made the core erlang-only, so a browser
build that imported it reached a package with no commonJS target, which front 68's server-only
refusal rejects by design.

The maintainer answered with a library of its own, bundled like `routing` (decision 116 rule 5):
rakun, onze and application code import `validation` by name, the library imports std and nothing
else, and the one thing it took from rakun — where a message template comes from — is handed to it.

## State

`libs/validation/` — `report`, `table`, `messages`, `spi`, `constraints`, `binding`, `decorators`,
pure `.bp` with the host state as inline templates; the message lookup injected; JSON through std;
54 tests, green on erlang and on commonJS; bundled. rakun's member is deleted and rakun installs its
`MessageSource` at boot. Open: Step 2's diff box.

## Mechanism

**Moved, not rewritten.** Seven of the rakun member's eight modules are in `libs/validation/src/`
with their functions, names and tests; four changes only:

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
   // rakun, at boot
   setMessageSource(MessageSource(
       locale: { -> rkProp("rakun.validation.locale") },
       template: { key -> rkProp("rakun.validation.messages." + key) },
   ));
   ```

   onze sets the browser's in the entry it generates (front 68); with none set, the built-in texts
   answer. The library spells no `rakun.` key.
2. **JSON is std's.** `violationJson` and `constraintTableJson` write with `json.quote` /
   `json.object` / `json.array`, and escape every control character.
3. **The host tables are inline templates, not a sidecar.** A bundled library ships `.bp` files
   only (decision 117 rule 8), so the cells of `spi.bp` and `binding.bp` are
   `#[@External.Erlang(…)]` / `#[@External.Node(…)]` templates, as std's cells are: on erlang the
   registry is a `persistent_term` entry keyed `{validation, constraints}` (written at registration,
   read per validation), the message source one keyed `{validation, messages}`, and the accumulator
   the serving process's dictionary under `{validation, acc}`; on node they are fields of one
   `globalThis.__bp_validation` cell, the shape std's `testing.mocks` uses. `bindingIsolated()`'s
   measurement (spawn, push in the child, compare) is one template expression. A cell that cannot be
   expressed as a template stops the work and is recorded in `decisions-pending.md` rather than
   shipped as a sidecar.
4. **The boot check is rakun's.** Its refusal names rakun's configuration (`"rakun config: …"`,
   property keys), so it lives in rakun's core as `modules/rakun/src/config_check.bp` with its tests,
   beside front 05's binder, which owes the call (`validate<TypeName>(bound)` then
   `refuseInvalidConfig(typeName, prefix, report)`).

The manifest is `"name": "validation"`, `"target": "erlang"`, `"targets": ["erlang",
"commonJS"]`, no `dependencies`. The emitted code's imports read `from "validation"`, and the
decorator's docblock rule is: import `validated` from `"validation"`, never front 05's
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
├── src/constraints.bp  the v* predicates (std `regex`, `io.clock`)
├── src/binding.bp    bindInt, bindBool, bindRequired, bindEpochMillis, … (accumulator as a template)
├── src/decorators.bp #[validated] and the constraint markers
└── test/             report · table · messages · spi · constraints · binding · parity
```

Module atoms follow decision 109: `validation@report`, `validation@report@@ValidationReport`.

## Steps

### Step 1 — Scaffold `libs/validation`

**Acceptance:**
- [x] `libs/validation/botopink.json` reads `"name": "validation"`, `"targets": ["erlang",
      "commonJS"]` with erlang first, no `dependencies`, and lists the eight `src/*.bp` in import order
      (a module before the siblings that import it — the order `rakun-validation/src/root.bp:26-30`
      documents)
- [x] `grep -rn "rakun\|jhonstart\|onze\|emilia" libs/validation/src` finds no import and no key —
      only `////` prose citing rakun front 14 as the origin
- [x] no `*.erl` or `*.mjs` file under `libs/validation/`
- [x] `libs/AGENTS.md` names `validation/`

### Step 2 — Move the seven modules and their tests

`report`, `table`, `constraints`, `decorators` byte-for-byte except their import lines and
`from "rakun-validation"` in prose; `spi` and `binding` with their host cells re-expressed (change 3);
`messages` with the injected source (change 1). The tests move with them, suite `validation:`; the
four that set a key with `rkSetProp` set a `MessageSource` over a test table instead.

**Acceptance:**
- [x] the 48 tests of `binding_test`, `constraints_test`, `parity_test`, `report_test`, `spi_test`
      and `table_test` keep their assertions and are green on erlang and on commonJS; the rest of the 54 are `messages_test` (5) and the U+0001 case
- [ ] `diff` of every moved function body against `modules/rakun-validation/src/` shows only the
      four changes of *Mechanism* — **open:** function bodies change only by the four changes, but `botopink format` re-wrapped several bodies and the prose headers were rewritten, so a plain `diff` shows more than four
- [x] `bindingIsolated()` is `true` on erlang, measured by the template, and two concurrent
      processes binding at once see only their own violations — the template spawns, pushes in the child and compares; on node it answers `true` as a stated fact (one thread)

### Step 3 — The injected message source

**Acceptance:**
- [x] with no source set, `templateFor("size", builtInTemplate("size"))` answers the built-in text
- [x] with a source whose table holds `pt.size` and `size`, locale `pt` answers `pt.size`'s text,
      locale `en` answers `size`'s, and a table with neither answers the built-in — the resolution
      order front 14 specified, asserted three ways
- [x] the rakun-shaped source of *Mechanism* reproduces every message `spi_test.bp` and
      `parity_test.bp` assert, literal for literal
- [x] `grep -rn "rakun\." libs/validation/src` is empty

### Step 4 — JSON through std

**Acceptance:**
- [x] `violationJson` and `constraintTableJson` answer the literals `report_test.bp` and
      `table_test.bp` assert, byte for byte
- [x] a message containing U+0001 and a `"` produces JSON std's `json.decode` accepts
- [x] `grep -n "fn jsonEscape" libs/validation/src` is empty

### Step 5 — Bundle it

`validation` is in the bundled-package list (`std`, `routing`, `actions`, `validation`).

**Acceptance:**
- [x] a scratch project with no `dependencies` and a `#[validated]` record builds on `--target
      erlang` and `--target commonJS`, `validate<TypeName>` answers the same report on both, and the
      program imports only `from "validation"` and `from "std"` — `validateReq` answers `{"errors":[{"field":"name","code":"sizeBetween",…}]}` on both
- [x] the erlang output names `validation@constraints`; the commonJS output requires
      `./validation/constraints.js`
- [x] a manifest listing `validation` in `dependencies` is refused with a located error
- [x] `grep -rn '"validation' modules/compiler-core/src` is empty; `snapshots/codegen/**`
      byte-identical

### Step 6 — Both targets, in the gate

**Acceptance:**
- [x] `botopink test --target erlang` and `--target commonJS` from `libs/validation/` green;
      `zig build test-libs` reads `validation · erlang: pass` and `validation · commonJS: pass`
- [x] `libs/validation` is in `scripts/format-check.sh`'s `TREES`, green

### Step 7 — The consumers switch

| Consumer | Front | What changes |
|---|---|---|
| rakun | 14 Step 7 | the member deleted; the boot check in `modules/rakun/src/config_check.bp`; `setMessageSource` at boot over `rakun.validation.*`; rakun's workspace root `["erlang"]` |
| rakun config | 05 | the boot call `validate<TypeName>(bound)` + `refuseInvalidConfig`, emitted code importing from `"validation"` |
| rakun-web request binding | 07 | `bind*` from `"validation"` |
| onze | 68 | the generated entry sets the browser's `MessageSource` |
| application code | onze 53 | `#[validated]` records and the client form import `from "validation"` |

**Acceptance:**
- [x] `grep -rn "rakun-validation" repository/ --include=*.bp --include=botopink.json` is empty — the boot check is rakun's `config_check.bp` with `config_check_test.bp`; `Rakun.run` installs rakun's `MessageSource`
- [x] `grep -rn "fn vNotBlank\|fn constraintTableJson\|fn registerConstraint" --include=*.bp
      repository/` finds only `repository/botopink-lang/libs/validation/src/`
- [x] no `botopink.json` under `repository/` lists `validation` in `dependencies`, and the CLI refuses one that does

## Test plan

`libs/validation/test/*.bp`, suite `validation:`, run on both targets from `libs/validation/` and by
`zig build test-libs`. The 48 moved tests keep their assertions; Step 3 adds the source's three-way
resolution; Step 4 the control-character case. The configuration-check tests are rakun's, beside
`config_check.bp`. The bundling is tested where `04-routing-lib`'s is.

## Gate

- [x] `zig build test-libs` green — `validation` on both targets; rakun green with the member gone
- [x] the Step 5 compiler test green from a cold cache; `snapshots/codegen/**` byte-identical
- [x] `libs/AGENTS.md`, `libs/validation/AGENTS.md`, and (with rakun front 14 Step 7)
      `repository/rakun/AGENTS.md`, `modules/README.md` and `docs.md` in the same commits

## Blast radius

- **rakun:** one member fewer; the workspace root and every member, `rakun-test` included, are
  `["erlang"]` (decision 117 rule 9); the boot check is in the core. An application imports
  `from "validation"`.
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
