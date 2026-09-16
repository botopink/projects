# Front 02 — Migration tooling

**Priority:** critical — the cutover rewrites about 530 declarations and literals by hand otherwise,
and re-records about 700 snapshots with no way to tell a source-only diff from a behaviour change.
**Depends on:** none — parallel with F1
**Owns:** `modules/compiler-cli/src/cli/migrate_syntax.zig` (new), the `--syntax` flag wiring in
`modules/compiler-cli/src/cli/migrate.zig` and `main.zig`, `modules/compiler-cli/tests/**` for the
new command · `scripts/snap_audit.sh` (new mode) · their `AGENTS.md`
**Does not touch:** `modules/compiler-core/**` (F1, F3), `language-server/**`, library repositories

---

## Problem

The change is mechanical in intent but not in shape: record fields move from the body into a
parenthesised list, fields interleave with methods (25 records in libraries, 27 in tests), carry
comments (16) and annotations (3), anonymous records become labeled tuples in expressions and in
type positions, and behavior signatures change separators. By hand this is about 660 edits across
`.bp` files, Zig `\\` blocks and markdown. The snapshot side has no bulk tool: a mismatch writes
`<name>.snap.md.new` (`utils/snap.zig`) and `BOTOPINK_SNAP_CREATE=1` only records missing
snapshots.

`botopink migrate` exists today and derives an explicit module tree (`cli/migrate.zig`); this front
adds a syntax mode next to it.

## Step 1 — `botopink migrate --syntax`

A **token-level** rewriter built on the compiler-core lexer (comments are tokens, so they survive).
It does not use the parser: it must run on 1.0.2 sources before the cutover and on library
repositories after F3 has removed the old grammar.

Rewrites:

| Source (1.0.2) | Result (1.0.3) |
|---|---|
| `record Name<G> implement B { fields and methods }` | `type Name<G>(fields) implement B { methods }` — fields collected at brace depth 1 outside method bodies, in source order, with their leading comments and annotations; `val ` prefix dropped. No fields → no parentheses. No methods → no body. The field list keeps the layout the source had: a trailing comma after the last field (open) stays open, none stays compact; a field with a leading comment forces open. |
| `val Name = record<G> { … }` | `val Name = type<G>(…) { … }` |
| `enum Name … { … }` / `val Name = enum …` | `type Name … { … }` — methods found before a variant are moved after the last variant, with a report line; an enum with no variant and no section is reported (it would become a record). |
| `interface Name … { … }` / `val Name = interface …` | `behavior Name … { … }` — member separators normalised: `,` or nothing after a bodyless member → `;`; `,` after a member with a body → removed. |
| `record { a: x, b: y }` (expression) | `#(a: x, b: y)`; `record { }` → `#()` |
| `{ a: T, b: U }` in type position | `#(a: T, b: U)`; `{}` → `#()` |

Type-position detection: a `{` directly after `:` (parameter, field, `val` annotation), `->`, `<`
or `,` inside generic arguments, followed by `}` or by `Name :`. A `{` followed by `Name ->`, `->`
or a statement is a lambda or block and is left alone. Any `{` the rewriter cannot classify is left
untouched and listed.

Modes:
- `botopink migrate --syntax [paths…]` — rewrite `.bp`/`.d.bp` files in place (default: the project's `src/`, `test/`, `examples/`).
- `--zig` — rewrite `\\` multiline-string blocks inside `.zig` files: each run of consecutive `\\` lines is unprefixed, rewritten as a unit, re-prefixed with the original indentation. Single-line Zig strings containing a keyword are reported, not rewritten.
- `--markdown` — rewrite fenced ```` ```botopink ```` / ```` ```bp ```` blocks in `.md` files.
- `--check` — rewrite nothing; exit 1 and list every site that would change or could not be classified.
- `--dry-run` — print the diff.

Idempotent: running it twice changes nothing the second time.

**Acceptance:**
- [ ] Golden tests (`.bp` in → `.bp` out) for each row of the table, including: fields interleaved with methods; a field with a leading comment and an annotation; a record with no fields; a record with no methods; generics + `implement`; an enum with a method before a variant; an enum with sections; a behavior with `,`, `;` and no separator; nested literals `record { a: record { b: 1 } }`; a lambda value `record { f: { x -> x } }` left as a lambda inside the tuple
- [ ] `--zig` golden test on a Zig file with two `\\` blocks and one single-line string (reported)
- [ ] `--markdown` golden test with a `botopink` fence and a non-botopink fence (untouched)
- [ ] Running over `libs/std` at `41981e3` produces zero "unclassified" reports; second run is a no-op
- [ ] `erika/src/erika.bp:570` (`"record { "` built inside a string) is reported as a string-literal hit

## Step 2 — `snap_audit.sh --mode=cutover`

Classifies every `<name>.snap.md.new` against its `<name>.snap.md`, section by section (`SOURCE CODE`,
generated-code sections, `TYPESCRIPT TYPEDEF`, `RUN LOG`, JSON dumps):

| Class | Condition | Action |
|---|---|---|
| **A** source-only | only `SOURCE CODE` differs, after normalising parser ids (`(record|enum|type)_\d+` → `type_#`, `(interface|behavior)_\d+` → `behavior_#`) and typed-AST keys (`record_def`/`enum_def` → `type_def`, `interface_def` → `behavior_def`) | `--accept` promotes it |
| **B** output-changed | a generated-code section differs; `RUN LOG` identical | listed per backend directory for review; `--accept-reviewed <list>` promotes a reviewed list |
| **C** behaviour-changed | `RUN LOG` differs, or a diagnostic differs beyond the words `record`/`enum`/`interface` → `type`/`behavior` | listed; never promoted by the script |

Writes `build/snap-audit/cutover.tsv` (path, class, backend, sections changed), like the existing
modes.

**Acceptance:**
- [ ] Fixture set with one `.new` per class is classified correctly
- [ ] `--accept` touches only class A; `--accept-reviewed` only the listed files
- [ ] Read-only by default (no flag → report only), as the other modes

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `botopink migrate --syntax --check` on `libs/std` at the front's base lists every site and exits 1
- [ ] `AGENTS.md` of `compiler-cli/src/cli` and `scripts`, updated in the same commit
- [ ] Branch `fix/migration-tooling`; no push, no merge

## Notes

The command stays through 1.0.3-beta so external projects can migrate, and is removed in the next
milestone.
