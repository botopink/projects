# Front 08 — hygiene

**Priority:** low — no program is wrong; comments, documents and one text to place.
**Depends on:** each item lands after the front that owns its file (C-23): `01-checker` (its step
14), `02-erlang` (step 11), `07-review-backlog` (step 5), `18-comptime-runtimes` (the transport
test, its step 4), `17-beam-memory` step 1 (part 2 of the `@BeamMemory` text publishes only when
`keyed = true` lands) · `00-gate` (FC-2: `examples/**`'s two trees are reformatted and join `TREES`
by the gate; this front edits `examples/**` afterwards).
**Owns:** `repository/botopink-lang/docs.md`, `README.md`, `examples/**`, every `AGENTS.md` of the
compiler tree, the relative links of `specs/`, `libs/std/botopink.json` and `libs/std/AGENTS.md`
(with 23) · [`beam-memory-docs-text.md`](./beam-memory-docs-text.md) · comments in other fronts'
files, only after their owners
**Does not touch:** any behaviour. Every edit is a comment, a manifest, a document or a link.
**Does not touch until 00-gate lands:** `examples/generic-loader-binding/**`, `examples/stdlib-tour/**`
(FC-2).

Paths are relative to `repository/botopink-lang/`. Item numbers are 1.0.1-beta's
`05-repo-hygiene.md` groups, kept so old references resolve.

## Carried from 1.0.10

| Item | 1.0.10 spec | Heading |
|---|---|---|
| items 1–4 | `08-hygiene/README.md` | § Open (item 5, `zig fmt`, → 00-gate ZF-1…11) |
| the `@BeamMemory` text | `17-beam-memory/docs-text.md` | parts 1 and 2 |
| C-18's five document corrections | `00/README.md` | § C-18, last box (decisions 1, 2, 10, 25, 32) |
| the `hover.zig` comment | `11-tooling/README.md` | § Notes |

## What holds

Every group of the 1.0.10 README's table (A–E, links) holds at the open: `wasm3` in the tree by
design, `lib-test-runner` built by the workspace `build.zig`, every `files` entry resolves,
`zig build test-docs` green, the transport-error diagnostic reads `lastTransportError()`
(`comptime/runtime/runtime.zig`), every relative link resolves. `docs.md` § *Decided, not yet
implemented* (`docs.md:2279`) is re-derived. Measured at the open.

## Open

**1. `primitives.d.bp` in comments** (group C). The file is `primitives.bp`. At HEAD:
`codegen/erlang.zig` ×10 (`:2535`, `:2566`, `:2699`, `:2951`, `:3300`, `:3320`, `:3322`, `:3333`,
`:4732`, `:8878` — 02's), `comptime/env.zig:1057`, `comptime/infer.zig:11816,12068` (01's),
`language-server/src/tests/hover.zig:304` (07's). Two mentions are legitimate and stay:
`cli/resolver.zig:1017` and `lib-test-runner/src/discovery.zig:418` (extension-assertion tests).

**2. `@external(<target>, …)` / `@[external(…)]` taught as current** (group D). Only
`External.<Target>` is read. At HEAD `grep -c '@external('` over the 1.0.10 sites answers 0 — the
comments may spell the form differently (`external(node`, `@[external`) or have closed with the
owners' later commits; each owner re-measures at its sweep step (01 step 14, 02 step 11, 07 step 5)
and this front verifies. What stays: the sites that name a retired form **as retired** (`docs.md`
§ Host bindings, `codegen/AGENTS.md`, `comptime/AGENTS.md`'s R3 note, `scripts/AGENTS.md`'s `legacy`
audit mode, the R3 refusal in `infer.zig`, `tests/language/reject/external_lowercase_target.bp`,
the parser error fixtures, and the two test **names** in `codegen/tests/externals.zig:55,67` until
07 step 4 renames them).

**3. Test-file comments that describe a lowering or an owner that moved.** `codegen/tests/control_flow.zig:73,76`,
`narrowing.zig:90`, `builtins.zig:365` — 07 step 5's, verified here.

**4. The transport error's diagnostic has no test** (group E). `persistent_beam.zig`'s tests assert
the transport message; nothing asserts that the message reaches the user through `runtime.zig`'s
`evalBeam`. The test belongs beside `evalBeam` — 18's file, 18 step 4.

**5. The `@BeamMemory` text.** `docs.md` has zero `BeamMemory` mentions (measured: `grep -c`).
[`beam-memory-docs-text.md`](./beam-memory-docs-text.md) part 1 (the `val` rule, the module `var`,
the validated annotation — true at the open) goes into `docs.md` § Bindings now; part 2 (the three
mode paragraphs, with decision 42's "no warning" and the measured figures) goes in when 17 step 1
lands `keyed = true`, not before — a paragraph describing an emission the backend refuses would be
the failure decision 41 was taken against.

**6. C-18's five document corrections.** Decision 1 (the async sequence type is `@Stream<T>`),
2 (`?T` only — `Option.None` / `Some(1)` are unbound, as `surface-gaps.md` measured), 10 (the
`@code` annotation renamed), 25 (`is` does not bind), 32 (no `Option.Some` value names): each
row of `docs.md` and `README.md` that still writes the old form corrected, measured by running the
fence (`zig build test-docs`).

**Acceptance:**
- [ ] `grep -rIn 'primitives\.d\.bp' modules` returns exactly the two extension-assertion tests
- [ ] no comment presents a retired `@external` form as current; the sites listed under item 2 as naming it retired are unchanged
- [ ] `grep -rn '06-wasm\|07-checker\|F7 checker' modules/compiler-core/src/` returns nothing
- [ ] 18's test drives a comptime body past the 16 MiB frame cap and asserts the diagnostic quotes `lastTransportError()`'s message
- [ ] `docs.md` § Bindings carries part 1; § `@BeamMemory` carries part 2 after 17 step 1 (`grep -c BeamMemory docs.md` > 0); `zig build test-docs` green with the new fences
- [ ] no `docs.md` / `README.md` fence spells `Option.Some`, `Option.None`, `AsyncIterator`, `AsyncGenerator` or `is` binding a payload; `test-docs` green

## Gate

- [ ] `zig build test-docs` and `scripts/check-docs.sh` green after every commit (this front's commits are documents and comments; `zig build test` cold on the last)
- [ ] every relative link of the documents this front owns resolves
- [ ] matching `AGENTS.md` files updated in the same commits
- [ ] Commits on `fix/08-hygiene`; no push, no merge

## Ownership

A comment-only edit in another front's file is safe to make and expensive to merge: each sweep is
one commit per owning file, after that file's front lands.

| Item | Files | Owner (lands the sweep) |
|---|---|---|
| 1, 2 | `codegen/erlang.zig` | `02-erlang` step 11 |
| 1, 2 | `comptime/{infer,env,diagnostics}.zig`, `ast.zig`, `parser.zig`, `parser/decls.zig` | `01-checker` step 14 |
| 1, 2, 3 | `comptime/tests/**`, `codegen/tests/**`, `language-server/src/tests/hover.zig` | `07-review-backlog` step 5 |
| 4 | `comptime/runtime/runtime.zig` | `18-comptime-runtimes` step 4 |
| 5, 6 | `docs.md`, `README.md` | this front |
| (former 5) | the eleven `zig fmt` files | `00-gate` ZF-1…11 |
