> Carried from `specs/1.0.5-beta/08-hygiene/README.md`, status at carry (2026-09-20): steps 1–5 landed; 2.1's remainder, 3.1's `@external` comments and step 6 are C-23

# Front 08 — hygiene

**Priority:** low, with one exception — the transport-error one-liner (step 5) is the difference
between a comptime failure that names itself and one that says `EvalFailed`.
**Depends on:** per step. Steps 1, 2 and 4 can start now. Step 3's `docs.md` edit is a **precondition
of [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) step 1**, which is implemented and parked. Step 5
needs a carve-out from [`14-comptime-on-beam`](../14-comptime-on-beam/README.md). Step 6's comment
sweeps land after the front that owns each swept file
**Owns:** `src/comptime/runtime/persistent_erl.zig` (the residual only) · the transport-error line of
`src/comptime/{template_eval,decorator_eval}.zig` · `libs/std/botopink.json`, `libs/std/AGENTS.md` and
comments in `libs/std/**` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, and comments
**Does not touch:** any behaviour. Every edit outside step 5 is a comment, a manifest, a doc or a dead
file — see [Ownership conflicts](#ownership-conflicts), because the sweeps run through files six other
fronts own

Paths are relative to `repository/botopink-lang/`. Item numbers are kept from
[`../../1.0.1-beta/05-repo-hygiene.md`](../../../1.0.1-beta/05-repo-hygiene.md) so existing
cross-references still resolve. Everything below was re-measured at `botopink-lang` `c2dd780`
(2026-09-18).

---

## Problem

1.0.4-beta's front 09 delivered steps 1, 3 and 6 and the doc half of step 5; steps 2, 4 and 5 were
left, each "after the front that owns the swept file". **Most of those fronts have since closed**, and
re-measuring at `c2dd780` shows that two of the three open steps have largely closed with them. What
is left is smaller than the 1.0.4-beta document implies, and one item in it is new.

| 1.0.4-beta step | Group | State at `c2dd780` |
|---|---|---|
| 2 — the removed WAT runtime (5.6, 5.7) | A | **one line left**, and another front deletes it — [step 1](#step-1--close-group-a-one-line-and-one-verification) |
| 4 — `libs/std`'s declared surface (5.1–5.3, 5.14) | C | 19 stale comments in 6 files, plus one new warning — [step 2](#step-2--libsstds-names-and-one-warning-group-c) |
| 5 — vocabulary and instructions (5.8, 5.13, docs) | D | 5.8 closed, the `implement` example closed, `test-docs` green; ~30 comments and a stale `docs.md` table left — [step 3](#step-3--stop-teaching-what-the-compiler-no-longer-does-group-d) |
| 5.4 + the lib-test-runner build files | B | **closed** — [step 4](#step-4--confirm-group-b-closed-and-say-so) |
| step 1's residual (5.10) | E | half closed; `lastTransportError()` still has no caller — [step 5](#step-5--a-comptime-transport-error-reaches-a-diagnostic-group-e-residual) |

## Current state, measured

### Group A — the removed WAT runtime (5.6, 5.7)

```
$ grep -rIl 'wasm3\|wat_runtime\|wat_to_wasm\|wasm3_host' --exclude-dir=.git --exclude-dir=.botopinkbuild \
      --exclude-dir=zig-out --exclude-dir=.zig-cache .
modules/compiler-core/src/comptime/tests/helpers.zig
```

**One file, one line**: `helpers.zig:129`, inside the comment block that explains the four-copy
comptime layout — and [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1 deletes that block
(`:129-133`) as part of its own change.

The other two acceptance conditions are met without an edit:

| Condition | State |
|---|---|
| `build_options` deleted or has a named user | **deleted** — no `build_options` in `build.zig` or any `modules/*/build.zig` |
| `libcResolvedTarget` deleted, or its comment explains a reason that still exists | **kept, and the reason is live**: `build.zig:395-406` names the Zig 0.16 + glibc ≥ 2.41 `.sframe` `crt1.o` relocation bug and pins `glibc_version = 2.38` on linux-gnu only |

### Group C — `libs/std` (5.1, 5.2, 5.3, 5.14)

`libs/std/src/primitives.d.bp` no longer exists; the file is `primitives.bp`. The name survives in
comments:

```
$ grep -rIn 'primitives\.d\.bp' … | wc -l
21
```

| File | Sites | Kind |
|---|---|---|
| `modules/compiler-core/src/codegen/erlang.zig` | 11 | stale doc comments |
| `modules/language-server/src/engine.zig` | 4 | stale doc comments |
| `modules/compiler-core/src/comptime/infer.zig` | 2 | stale doc comments |
| `modules/compiler-core/src/comptime/{env,stdlib/prelude}.zig` | 1 each | stale doc comments |
| `modules/language-server/src/tests/hover.zig` | 1 | stale comment |
| `modules/compiler-cli/src/cli/resolver.zig:634`, `modules/lib-test-runner/src/discovery.zig:405` | 2 | **not stale** — the two extension-assertion tests (`expect(!isSource("primitives.d.bp"))`) the 1.0.4-beta acceptance carves out |

**19 stale, 2 legitimate.** The other three acceptance conditions are met:

- every `files` entry in every `botopink.json` in the workspace resolves (`zig build test-libs` reads
  **11 passed, 0 failed, 0 known red, 1 skipped, 2 without tests**);
- `libs/std/AGENTS.md`'s tree matches `libs/std/src/` file for file (26 `.bp` + `sidecars/random.mjs`);
- `scripts/known-red-libs.txt` carries no line.

**New, not in the 1.0.4-beta document:** every `zig build test-libs` run prints, twice,

```
warning: module not reached by any `mod` path — not compiled: src/primitives.bp
warning: 1 module(s) not reached by any `mod` path were not compiled
```

for `libs/std` itself. `primitives.bp` is a **core** file — flattened into the global type env through
`std_core_files` in `build.zig` and listed in `libs/std/botopink.json`'s `files` — so it is
deliberately not in `root.bp`'s `pub mod` chain. The warning is a false positive on the standard
library, printed on every gate run.

### Group D — vocabulary and instructions (5.8, 5.13, docs)

Closed since 1.0.4-beta:

| Item | Evidence at `c2dd780` |
|---|---|
| 5.8 — `examples/hello.bp`'s header | `botopink new demo && cp examples/hello.bp demo/src/main.bp && cd demo && botopink run` prints `hello, botopink`. Run, not read |
| `docs.md`'s `implement` example | `docs.md:194` is `type Person(name: string) implement Printable { … }` — the 1.0.3 surface |
| every botopink fence in `docs.md` compiles | `zig build test-docs`: **36 fences — 32 checked, 2 skipped, 0 failed** |

Still open:

**D1 — `@external(<target>, …)` presented as current.** 36 sites in 13 files. Four present it
correctly as retired or under test:

| Site | Presents it as |
|---|---|
| `docs.md:460` | retired — "Only `External.<Target>` is read" |
| `modules/compiler-core/src/codegen/AGENTS.md:126` | the retired form, named |
| `scripts/AGENTS.md:182` | "legacy `@external(<target>, …)`", a `snap_audit --mode=legacy` pattern |
| `tests/language/reject/external_lowercase_target.bp` | the cell that says it must be a located error |

The rest present it as the current form in doc comments — `codegen/erlang.zig` (19),
`comptime/infer.zig` (5), `comptime/{env,diagnostics}.zig` and `parser.zig` (1 each),
`comptime/tests/std_target_gating.zig:6` — plus one **fixture**,
`comptime/tests/infer_decls.zig:540`, which writes `@external(node, "./gleam_stdlib.mjs", "string_length")`
in the source it snapshots.

**D2 — `docs.md`'s "Decided, not yet implemented" table is stale, in both columns.** `docs.md:521-540`
lists twelve rules, each with a "Today" description and a "Closes with" front row. The grammar for four
of them landed (`d0c27f6`, `4a3449f`, `6c849ae`, `3b491e3`) and the table still says "not parsed":

| `docs.md` row | Says | Measured at `c2dd780` |
|---|---|---|
| `:529` union types | not parsed | **parses**; `fn f(x: i32 \| string) -> i32` then `f(1)` gives `error: type mismatch: expected \|, got i32` — a checker rule, not a parse error |
| `:530` the `unknown` type | parses as an ordinary type name | **is a type**; `val a: unknown = 5` gives `error: type mismatch: expected unknown, got i32` |
| `:531` `x is i32` | not parsed | **parses**; `if (a is i32) { … }` gives `error: type mismatch: expected bool, got void` |
| `:532` `case` arms as `Pattern { … }` | arms are `pattern -> value;` | **both forms parse**; `case a { 0 { 1 } _ { 2 } }` checks green and runs |
| `:534` inclusive ranges `1...9` | not parsed | **parses and checks green** in a `case` arm |

And every "Closes with" cell names `06 N…` — 1.0.4-beta's front 06, which is
[`01-checker`](../01-checker/README.md) in this milestone. `docs.md:18` links to
`specs/1.0.4-beta/MIGRATION.md`.

**D3 — whether a lower-case `@external` is rejected is still not decided.** It has a `reject/` cell
(`tests/language/reject/external_lowercase_target.bp`), and `expected-failures.txt` lists it against
"`06` … (fronts.md § unowned items)" — a row that names no front. See
[Decisions the maintainer owes](#decisions-the-maintainer-owes).

### Group B — 5.4 and the lib-test-runner build files

Both **closed**:

```
$ zig build test-vscode
ℹ pass 37   ℹ fail 0   ℹ skipped 0
$ ls modules/lib-test-runner/
AGENTS.md  src
```

`scripts/test-vscode.sh` exists and the step runs it. `modules/lib-test-runner/build.zig` and `.zon`
are gone; its unit tests run under the root `zig build test`.

### Group E residual — the comptime transport error

The frame-protocol guard landed (logger off `standard_io`, own group leader, 16 MiB frame cap, the
server built in a hashed dir and renamed into place), and `erl.stderr.log` is documented as shared and
best-effort in `modules/compiler-core/src/comptime/runtime/AGENTS.md:27,38,42` — the 1.0.4-beta
acceptance box is ticked.

What is left is the other half of that residual. `persistent_erl.lastTransportError()` exists
(`persistent_erl.zig:331`, exercised by three regression tests at `:455`, `:480`, `:546`) and **has no
caller outside the file**:

```
$ grep -n 'lastTransportError' modules/compiler-core/src/comptime/{template_eval,decorator_eval}.zig
(no match)
$ grep -n 'evalDetailed' modules/compiler-core/src/comptime/template_eval.zig
101:    const response = persistent_erl.evalDetailed(arena, io, path) catch return error.EvalFailed;
```

`decorator_eval.zig:84` is the same line. A frame that was too large, a server that died and a body
that corrupted the protocol all reach the user as `EvalFailed`, with the message sitting unread in
`lastTransportError()`.

## Steps

### Step 1 — close group A: one line, and one verification

`helpers.zig:129`'s `wasm3-unified-runtime` mention lives inside the comment block
[`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1 deletes. Do not edit the file; verify
after that front lands, and record the two conditions that are already met.

**Acceptance:**
- [ ] After [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1:
      `grep -rIl 'wasm3\|wat_runtime\|wat_to_wasm\|wasm3_host'` over the tree (excluding `.git`,
      `.botopinkbuild`, `zig-out`, `.zig-cache`) returns **nothing**
- [ ] `build_options` has no occurrence in any `build.zig` — recorded here, no edit
- [ ] `libcResolvedTarget` is kept and its comment (`build.zig:395-398`) names a reason that still
      holds — recorded here, no edit
- [ ] `zig build` and `zig build test` green on linux-gnu and on the CI runners

### Step 2 — `libs/std`'s names, and one warning (group C)

1. Rewrite the **19** stale `primitives.d.bp` comments to `primitives.bp`. One commit per owning file;
   `codegen/erlang.zig` is [`02-erlang`](../02-erlang/README.md)'s and
   `comptime/{infer,env}.zig` are [`01-checker`](../01-checker/README.md)'s — sweep after them, or hand
   each the one-file edit. Leave the two extension-assertion tests alone.
2. Decide and act on the `libs/std` warning. Options, in increasing cost:

   | | Change | Trade-off |
   |---|---|---|
   | A | Say nothing; document in `libs/std/AGENTS.md` that the warning is expected | Cheapest; the gate keeps printing a warning on the standard library, which trains readers to ignore warnings |
   | B | Exempt a module listed in `botopink.json`'s `files` from the "not reached by any `mod` path" check | Correct by the manifest's own meaning — `files` is the declared surface — but it is a CLI change, [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md)'s file |
   | C | Add `primitives.bp` to `root.bp`'s `pub mod` chain | Makes it importable as `std.primitives`, which it is not meant to be; changes the std surface |

   **Recommended: B**, handed to [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) as a one-row
   follow-up, with A as the interim.

**Acceptance:**
- [ ] `grep -rIn 'primitives\.d\.bp'` returns exactly the two extension-assertion tests
      (`cli/resolver.zig:634`, `lib-test-runner/src/discovery.zig:405`)
- [ ] `zig build test-libs` prints no `not reached by any mod path` line for `libs/std`, **or**
      `libs/std/AGENTS.md` says in one sentence why it does and that it is expected
- [ ] `libs/std/AGENTS.md`'s tree still matches `src/` after any change

### Step 3 — stop teaching what the compiler no longer does (group D)

1. **D1.** Rewrite the ~30 doc comments that present `@external(<target>, …)` as the current form, and
   the one fixture (`comptime/tests/infer_decls.zig:540`). A comment that describes the *legacy* form
   by name stays. Most of them are in `codegen/erlang.zig` — [`02-erlang`](../02-erlang/README.md)'s
   file; sweep after it or hand it the edit.
2. **D2.** Re-derive `docs.md:521-540` row by row against HEAD, fix the "Today" column, and repoint
   every "Closes with" cell at a 1.0.5-beta front. The five rows named in
   [Group D](#group-d--vocabulary-and-instructions-58-513-docs) are wrong today; the others are
   unverified and must each be re-run, not carried. Repoint `docs.md:18`'s `MIGRATION.md` link at the
   path the maintainer keeps it under.
3. **The `docs.md:78` import fence.** [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) step 1 is
   implemented, verified, and parked in a stash because it reds this fence — the fence is vacuously
   green today (`test-docs` checks it and passes, because an unresolved `import` is silent). Land one
   of the two edits that front specifies, so it can commit:

   ```markdown
   <!-- docs-check: skip illustrative import forms — `geometry`, `shapes.circle` and the `erika` dependency exist only inside a project that declares them -->
   ```

   or move the `geometry` and `shapes.circle` lines into the existing `project modules` group
   (`docs.md:39-62`, which already defines `src/main.bp`, `src/geometry.bp` and `src/shapes/mod.bp`;
   it would also need a `src/shapes/circle.bp` fence and a `pub mod circle;`), leaving only the `erika`
   line under a skip. **The richer alternative keeps the coverage and is recommended** — the point of
   the fence is that import forms work.

**Acceptance:**
- [ ] No comment, fixture or `.bp` file presents `@external(<target>, …)` or `@[external(…)]` as
      current; the four sites that name it as retired are unchanged
- [ ] Every row of `docs.md:521-540` re-derived by running the form at HEAD, and every "Closes with"
      cell names a 1.0.5-beta front
- [ ] `zig build test-docs` green **with** [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) step 1
      applied — that is the condition this step exists for; run it against that front's branch
- [ ] `docs.md:18`'s migration link resolves

### Step 4 — confirm group B closed, and say so

No edit. Record the measurement so the next reader does not re-open it.

**Acceptance:**
- [x] `zig build test-vscode` runs and passes (37 tests, `scripts/test-vscode.sh` exists)
- [x] `modules/lib-test-runner/` holds `AGENTS.md` and `src/` only — no `build.zig`, no `.zon`
- [ ] Both facts written into this README's current state and into
      `modules/lib-test-runner/AGENTS.md` if it still claims its own build

### Step 5 — a comptime transport error reaches a diagnostic (group E residual)

Make `template_eval.zig:101` and `decorator_eval.zig:84` read `persistent_erl.lastTransportError()`
when `evalDetailed` fails, and carry its message into the diagnostic instead of collapsing to
`error.EvalFailed`. The message exists; nothing reads it.

`src/comptime/runtime/persistent_erl.zig`'s eval-protocol half and both `*_eval.zig` files are
[`14-comptime-on-beam`](../14-comptime-on-beam/README.md)'s. **This step is a carve-out**: two call
sites and an error payload, agreed with that front or landed after it.

**Acceptance:**
- [ ] A comptime body that exceeds the 16 MiB frame cap produces a diagnostic quoting
      `lastTransportError()`'s message, not `EvalFailed` — reproduced by a test, not by reading
- [ ] The three existing `persistent_erl.zig` regression tests (`:455`, `:480`, `:546`) still pass
- [ ] `src/comptime/runtime/AGENTS.md` says who reads `lastTransportError()`

### Step 6 — the comment sweeps in other fronts' test files

Five sites left of the 1.0.4-beta list; the rest drifted out of existence. All five are in
[`07-review-backlog`](../07-review-backlog/README.md)'s files:

| Site | Says | Should say |
|---|---|---|
| `src/codegen/tests/builtins.zig:382` | commonJS "still lowers to `console.assert`" and erlang drops the message | decision 4 is implemented on all four backends |
| `src/codegen/tests/control_flow.zig:73` | "pinned, 06-wasm" | [`05-wasm`](../05-wasm/README.md) |
| `src/codegen/tests/control_flow.zig:76` | "07-checker's to land" | [`01-checker`](../01-checker/README.md) |
| `src/codegen/tests/narrowing.zig:105` | "registered with 07-checker" | [`01-checker`](../01-checker/README.md) |
| `src/codegen/tests/wat.zig:86` | "owner: 07-checker (analysed in 01-comptime-dispatch/trailing-defaults.md)" | [`01-checker`](../01-checker/README.md), and the deep dive's new path |

**Acceptance:**
- [ ] `grep -rn '06-wasm\|07-checker\|F7 checker' src/` returns nothing
- [ ] No comment in `src/codegen/tests/**` describes a lowering the four backend fronts have changed
- [ ] One commit per owning file, landed after
      [`07-review-backlog`](../07-review-backlog/README.md) or handed to it

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] Every item fixed, or closed with a written reason in this front's files
- [ ] Matching `AGENTS.md` files updated in the same commits
- [ ] Commit on `fix/hygiene`; no push, no merge

## Blast radius

Nothing in this front changes emitted output, so **no snapshot moves by content**. Three exceptions to
plan for:

- **Step 3's `docs.md` edit unblocks a front that reds real code.**
  [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) step 1 makes an unresolved `import` a located
  error. Measured across the checkout by that front: `zig build test`, `test-cli` and `test-libs`
  (11 library cells) are unaffected; the one casualty is this fence. After the edit lands, that front
  commits and every project whose `from` names nothing stops compiling.
- **5.13's fixture rewrite** (`comptime/tests/infer_decls.zig:540`) re-records one comptime snapshot:
  **four files before [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md) step 1, one after.** Land
  it after that step.
- **Step 5 changes a diagnostic's text**, so any snapshot that records a comptime transport failure
  moves. At `c2dd780` none does — the failure is not reachable from a test fixture — but re-check
  before landing.

## Ownership conflicts

The behaviour edits own their files; the sweeps do not, and the sweeps are most of the work.

| Where | What it touches | Whose file |
|---|---|---|
| Step 2.1 (19 sites), step 3.1 (~30 sites) | comments in `codegen/erlang.zig`, `comptime/{infer,env,diagnostics}.zig`, `parser.zig`, `language-server/src/engine.zig`, `comptime/tests/**`, `codegen/tests/**` | [`01-checker`](../01-checker/README.md), [`02-erlang`](../02-erlang/README.md), [`07-review-backlog`](../07-review-backlog/README.md), [`11-tooling`](../11-tooling/README.md) |
| Step 2.2 option B | the "not reached by any `mod` path" check | [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) — handed over, not taken |
| Step 3.3 | `docs.md:78` | this front; the edit is specified by [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) |
| Step 5 | `comptime/{template_eval,decorator_eval}.zig`, `comptime/runtime/persistent_erl.zig` | [`14-comptime-on-beam`](../14-comptime-on-beam/README.md) — carve-out |
| Step 6 | `src/codegen/tests/**` | [`07-review-backlog`](../07-review-backlog/README.md) |

The practical rule, unchanged: a comment-only edit in another front's file is safe to *make* and
expensive to *merge*. Do each sweep in one commit per owning file, last, after the fronts that own
those files have landed — or hand the sweep to them.

<a id="decisions-the-maintainer-owes"></a>

## Decisions the maintainer owes

1. **`docs.md:78`** — the skip directive or the richer `project modules` rewrite (step 3.3). Until one
   lands, [`10-cli-residuals`](../../../1.0.5-beta/10-cli-residuals/README.md) step 1 cannot be committed.
2. **Is a lower-case `#[@external(node, …)]` a located error?** It passes `check` today, binds no host,
   and produces no diagnostic. A `reject/` cell asserts the error and is listed as an expected failure
   against a row that names no front. The decision, and then its owner
   ([`01-checker`](../01-checker/README.md), the annotation grammar).
3. **The `libs/std` "not reached by any `mod` path" warning** — A, B or C in step 2.2.

## Notes

- 1.0.4-beta's "two of the fourteen are not hygiene" framing is spent: 5.10's dangerous half (the
  unbounded frame allocation) landed, and 5.16's silently-wrong build was deleted. What is left really
  is cosmetic, apart from step 5.
- `modules/compiler-core/AGENTS.md:19-20` describes the snapshot tree as
  `comptime/ (beam/, erlang/, node/, templates/, wasm/)`. That line is
  [`06-comptime-dedup`](../../../1.0.5-beta/06-comptime-dedup/README.md)'s to rewrite, not this front's — it is listed
  in that front's step 1 acceptance.
- `scripts/known-red-libs.txt` is empty and `scripts/known-broken-examples.txt` no longer exists in any
  library. Both are evidence that the ecosystem work closed, not hygiene rows.

---

## Rows for `fronts.md`

**Ownership table:**

```markdown
| **08** [`hygiene`](./README.md) | `src/comptime/runtime/persistent_erl.zig` (residual) · the transport-error call sites of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 14) · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after owners) | — | not started — steps 1, 2, 4 ready; step 3 blocks 10; steps 5–6 after their owners |
```

**Conflict notes** (against the other thirteen fronts):

| With | Verdict | Why |
|---|---|---|
| **01 checker** | **no** — 01 first | 08 sweeps comments in `comptime/{infer,env,diagnostics}.zig` and `parser.zig` (7 `primitives.d.bp` + `@external` sites), and step 3.2 repoints `docs.md`'s "Closes with" column at 01's rows |
| **02 erlang** | **no** — 02 first | 30 of the two sweeps' sites are in `codegen/erlang.zig` alone |
| **03 beam · 04 js · 05 wasm** | yes | No sweep site left in their files; step 6's `wat.zig:86` and `control_flow.zig:73` are in `src/codegen/tests/**`, which is 07's |
| **06 comptime-dedup** | **no** — 06 first | 06 deletes the last `wasm3` mention (step 1's verification), owns `modules/compiler-core/AGENTS.md`'s snapshot tree, and turns 5.13's fixture re-record from 4 files into 1 |
| **07 review-backlog** | **no** — 07 first | Step 6's five sites are all in `src/codegen/tests/**` |
| **09 ecosystem-residuals** | yes | 09 works in `repository/{emilia,erika,jhonstart,onze,rakun}/**`; 08 touches none of it |
| **10 cli-residuals** | **no**, both ways | 08 owns `docs.md:78`, whose edit is 10 step 1's precondition; 08 hands 10 the `libs/std` manifest-warning row. 08's comment sweep over `modules/compiler-cli/**` lands after 10 |
| **11 tooling** | **no** — 11 first | 5 `primitives.d.bp` sites are in `language-server/src/{engine.zig,tests/hover.zig}` |
| **12 language-tests** | yes | No shared file. The lower-case-`@external` decision (D3) is what lets 12 point that cell's `expected-failures.txt` line at a real row |
| **13 module-identity** | yes | No shared file; its erlang output-layout change moves no comment 08 sweeps |
| **14 comptime-on-beam** | **no** — carve-out | Step 5's two call sites and `persistent_erl.zig` are 14's. Agree the carve-out or land step 5 after it |

**Front-table row (`overview.md`):**

```markdown
| [`08-hygiene`](./README.md) | low | not started — step 3 blocks 10 | What 1.0.4-beta's hygiene front left, re-measured: the WAT runtime's last mention (one line another front deletes), 19 comments naming a `libs/std` file that was renamed, ~30 comments teaching the retired `@external(<target>, …)` form, a `docs.md` "not yet implemented" table whose Today column is wrong in five rows, the `docs.md:78` fence that blocks `10-cli-residuals`, and the comptime transport error that never reaches a diagnostic |
```
