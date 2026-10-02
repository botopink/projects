# Track 02 — std and packaging

**Repos:** `repository/botopink-lang/libs/{std,routing,actions,validation}` (the bundled libraries) ·
every `repository/<lib>/botopink.json` and `modules/<lib>-test/` skeleton · the manifest carve-out
(`modules/manifest/**`, decision 75) · **Carried from:** `specs/1.0.10-beta/01-std/` and
`specs/1.0.10-beta/02-packaging/` — the mapping is [`carried.md`](./carried.md).

What 1.0.10 landed here stays landed: `@src()`, `testing.asserts`, `testing.snapshots`,
`testing.mocks`, the std tree of decision 106, the three std enablement fronts, JSON in std, the
bundled `routing` / `actions` / `validation`, the manifest model, every library a workspace with
its `-test` member, the `onze` takeover in code. What this track still owes is small and of two
kinds:

1. **std is not yet the one place a shared primitive lives.** The bundled-libs extraction analysis
   found `parseInt` / `parseFloat` hand-rolled in 21 files, the `Json` accessors copied eight times
   (`libs/actions/src/{envelope,rpc}.bp`, `onze/src/config.bp`, `onze-cli/src/{build,info}.bp`,
   `onze-bundler/src/entry.bp`, rakun's `jwt.bp` and `autoconfig_registry.bp`), four retry/backoff
   loops, two duration parsers, no `pbkdf2Sha256`, and std's own snapshot engine carrying private
   `readFile` / `writeFile` / `exists` / `removeTree` / `tmpDir` cells (`snapshots.bp:4-38`) that
   `io/fs` and `path` already provide. That is front [`97-std-dedupe`](./97-std-dedupe/README.md),
   and it lands **before** `03-bundled-libs` wave 1 (extraction decision D10): the consumer edits
   in library files are "consume std X" steps of the library front that owns the file.
2. **The packaging rule is not yet checked everywhere it applies.** A `-test` member with no
   `assert<Subject>(loc, …)` helper (erika, rakun, emilia), examples without a `README.md` (30 of
   31), the `git`-dependency subdirectory question (lg2-v) and the takeover's amended decision 79.
   That is front [`98-packaging-tail`](./98-packaging-tail/README.md), which runs after the library
   tracks have written their helpers and READMEs and verifies the rule across the seven repositories.

None of the six 1.0.10 std sub-fronts (`01-std/01…06`) is carried as a front: every open box of
theirs is closed on tick, closed on a decision confirmation, or a step of 97 (`carried.md`).

## Fronts

| Front | Priority | Carries | Parallel group | What |
|---|---|---|---|---|
| [`97-std-dedupe/`](./97-std-dedupe/README.md) | **high** — `03-bundled-libs` wave 1 and every library's "consume std" step wait on it | `01-std/01-std-lib-enablement` step 14 · `01-std` step 3's engine cells · the std-level cleanup of the extraction analysis | A (runs alone: it edits `libs/std/src/**`, which every other front compiles against) | `string.parseInt` / `parseFloat`, the `Json` accessors as methods, `hash.pbkdf2Sha256`, `clock.parseDuration`, `async.RetryPolicy`, the snapshot engine on `io/fs`; the bundled libraries' own copies deleted; the std snapshot map (conditional on `01std-f`) |
| [`98-packaging-tail/`](./98-packaging-tail/README.md) | medium — closes `02-packaging` steps 3 and 4 across the repositories | `02-packaging` steps 2–4 and gate · `95` step 2 (as a confirmation) · `-test` helpers of the libraries that have no track (erika) | B (after every library track's `-test` and `README.md` steps; alone, because it reads all seven repositories) | The cross-repository check of the packaging rule; `erika-test`'s first helper and `erika-linq`'s README; the manifest `subdir` field if lg2-v is answered (2); `docs/botopink-json.md` |

## Order

```
97-std-dedupe ──────────┐   (alone: libs/std/src/** is every front's dependency)
                        ├──► 03-bundled-libs wave 1 (routing · actions · http)
                        ├──► 04-rakun / 05-jhonstart / 06-emilia / 07-onze "consume std" steps
                        │
   library tracks' -test helpers and example READMEs ──► 98-packaging-tail   (last: it verifies)
```

97 is first because a std primitive that lands after its consumers were rewritten is rewritten
twice; 98 is last because its acceptance is a grep over files other fronts write.

## Handed to 00-gate

Items that are today a tolerated red, a stale or missing ledger line, a missing guard or a marker
without a row. The gate track owns the files; this track's fronts depend on the gate for them.

| Item | File | Fix |
|---|---|---|
| STD-1 / EM-6 — the `*.snap.new` guard exists in `botopink-lang` only | `repository/{rakun,jhonstart,emilia,onze,erika}/.gitignore` and `scripts/git-hooks/pre-commit` (each holds `pre-commit` but no `*.snap.new` line — measured with `grep -c snap.new`: 0 in all five) | add `*.snap.new` / `*.snap.md.new` to each `.gitignore`; each hook refuses a staged `*.snap.new` (`git add -f` included), as `botopink-lang`'s `scripts/gate.sh --staged` does |
| PK-1 / ONZ-0 — three restricted onze cells have no ledger line, so a full `zig build test-libs` run fails | `repository/botopink-lang/scripts/restricted-targets.txt` | `00-gate/113-gate-ledger-and-scripts` — under `gate-a` the ledger file is **deleted**, not extended: a manifest's `targets` is the single source of truth, `test-libs` generates no cell for an excluded target, and an audit proves the exclusion is a host-binding refusal (`botopink build --target <excluded>` fails). No line is measured or added |
| PK-5 — `botopink format --check` drift | `repository/jhonstart/modules/{jhonstart,jhonstart-link}/**/*.bp`, `repository/rakun/modules/{rakun,rakun-app}/**/*.bp` (multi-line imports collapsed, braces dropped around one-statement `if` bodies) | run the formatter over the four trees in one commit per repository; then decision 132's refusal of the `;` after a braced block can land (`00 · 16-formatter`) |
| STD-10 — a `// LANGUAGE GAP` marker without a row | `specs/1.0.10-beta/01-std/02-std-async-primitives/examples/parallel-fetch-example.bp:31` (array destructuring in a binding) | the record is frozen: the gate's marker grep excludes `specs/1.0.10-beta/**`, and the row is written in this milestone's `language-gaps.md` — with the rows `01-std/asserts-api.md` § Migration table names and no marker carries: test lifecycle hooks (`setup` / `teardown`), `isOkAnd`, `throwsType` (lg2-h), `typeOf` (lg2-g), a `@Result` pass-through return, structural `==` |
| STD-4 — the `01-std` README's *Gate* (seven boxes) and `02-packaging`'s "seven remotes unified" | `zig build test` cold, `botopink test` in `libs/std` on both targets, `zig build test-libs` green, codegen snapshots byte-identical, `AGENTS.md`, `docs.md`, the seven remotes | these are the gate's definition; nothing of this track re-measures them |
| 95 — "step 2 closed, with the onze rows in the same run" | `00-gate/113-gate-ledger-and-scripts` | closes when `gate-a` lands: the three restricted cells are audited structurally, no ledger row exists to add |
| STD-11 — compiler rows found by `01-std-lib-enablement` step 14 | `import {io.process}` shadows Node's global `process` in the commonJS test runner (`00 · 04-js`); a non-ASCII string literal reaches erlang as latin1 and a codepoint above U+00FF is `illegal character` (`00 · 02-erlang`) | not gate items — compiler rows for this milestone's `language-gaps.md`; listed here so they are not lost |

## Maintainer decisions

Confirmations of choices 1.0.10 implemented (ids kept; the text is in
`specs/1.0.10-beta/decisions-pending.md`), and the questions this track adds, continuing each
sequence. Numbered decisions continue from 146 when the maintainer answers.

### To confirm

| Id | Choice | Front that closes on it |
|---|---|---|
| 01std-a | a bundled library is loaded by the CLI and the LSP, not `expandStdImports` | `04-routing-lib` step 2 box 6 (closed on confirmation) |
| 01std-c | `routing.pattern`'s empty pattern matches only `/` | `04-routing-lib` step 8 box 1 (closed on confirmation) |
| 01std-d | the decorator registry keyed by module (landed) | — |
| 01std-e | `actions.readEnvelope` refuses a `redirect` that disagrees with `n` | — |
| std-a · std-b · std-c | `querystring` refuses by `Error`; `fs.exists` follows a link; decision 110's folder namespace is a rewrite | — |
| 24-g | `std/async`'s started/unstarted surface (`allOf`, `all`, `race`, `runAll`, `raceOf`, `timeout`; `allSettled` gone) | `02-std-async-primitives` README's thunk-shaped `allOf` (closed on confirmation; 97 step 5 builds `RetryPolicy` on this surface) |
| ck2-e | a std decorator is reached through its module handle | — |
| 95-a · 95-b · 95-c · 95-e | the relocation cuts; `rakun-app` inherits targets (superseded by rakun 04's `["erlang"]` — confirm as amended); `erika-test` exists; the qualified `from "rakun/request_context"` | — |
| 95-d | the takeover's tag and orphan branch — **the premise changed**, see 95-f | 98 |
| lg2-v | a subdirectory in a git dependency — recommendation (1), none | 98 step 4 (conditional) |

### 95-f · The onze takeover happened without the orphan branch and the archive — amend decision 79

> **Raised by:** this track, from the tree at `repository/onze`
> **Measured.** `repository/onze` is the orchestrator's workspace (`botopink.json` `"name": "onze"`,
> `"workspaces": ["modules/*", "examples/*"]`, eight members with `files`), built on top of the tag
> `mocking-lib-final` in the **same** repository history and the same remote — not the orphan branch
> `front/95-onze-orchestrator` decision 79 and 95-d described, and no repository was archived or
> renamed. `.gitmodules` has one `repository/onze` entry. `grep -rn '"onze"' --include=botopink.json
> repository/` finds only the orchestrator's members.
> **Options.** (1) confirm the tree as it is: decision 79 is amended by a new number saying the
> old library lives as the tagged history of the same repository, and nothing is archived;
> (2) rewrite the remote to the orphan branch and archive the old history (destructive: every
> checkout of `repository/onze` since the takeover re-clones).
> **Recommendation.** (1). The observable contract holds (the name resolves to the orchestrator,
> the tag resolves, the mocking surface lives in std's `testing.mocks`); (2) buys nothing a reader
> of `git log` cannot see today and costs every consumer a re-clone.
> **Blocks.** `01-std` step 5's four boxes and `95` step 2's first two boxes (closed on tick under
> (1)); `02-packaging` step 2's onze `-test` box (already true on disk).

### 01std-f · std's own snapshot map — realise or retire

> **Raised by:** front 97, from `01-std/test-snap.md` (copied to `97-std-dedupe/test-snap.md`)
> **Measured.** The map names ~40 `.snap` files over `testing/asserts.bp`, `testing/snapshots.bp`,
> `testing/mocks.bp`, `escape.bp`, `hash.bp`, `encoding.bp`, `path.bp`; four exist. Every message
> the map would pin is already asserted as a literal by an inline test at the foot of the file (the
> `asserts.<fn>: <what>` strings through `errorText`; the engine's own `.new` behaviour by the
> `engine ----` tests), on both targets.
> **Options.** (a) retire the map: the inline literals are the evidence, and a `.snap` of a std
> message proves no contract another library reads (a library reads the message through
> `errorText`, whose value the inline test already pins); (b) realise it: ~40 files under
> `libs/std/src/__snapshots__/`, re-recorded whenever a message changes, beside the same literal in
> the inline test.
> **Recommendation.** (a). The rule for this milestone is to realise a module-level snapshot only
> where it proves a contract another library reads; none here does.
> **Blocks.** 97 step 7 (conditional).

### std-d · `io.process` signals and a TTY reader — add, or refuse the callers

> **Raised by:** front 97, for onze front 50 (`onze start` forwarding `SIGTERM`; `onze create`'s
> interactive prompts)
> **Measured.** `libs/std/src/io/process.bp` runs and spawns; it neither registers a signal handler
> nor forwards one to a child, and std has no line reader over a TTY. onze 50's `start` waits on
> `process.run`, so `SIGTERM` to the CLI leaves the node running; `create` without `--yes` has no
> prompt to fall back to.
> **Options.** (a) std gains `process.onSignal(name, fn)` and `process.forwardSignals(child)` with
> Node and Erlang templates, and `io.stdin.readLine()` — three host cells on two targets;
> (b) no std change: `onze start` execs the node (front 71's `bin/onze` is PID 1 and receives the
> signal itself), and `onze create` without `--yes` is refused naming the flags it needs.
> **Recommendation.** (b) — the most restrictive: no interactive path exists to get wrong, and a
> signal reaches the process that must drain it, not a wrapper. (a) is additive later if a second
> consumer appears.
> **Blocks.** onze 50's `SIGTERM` and prompt boxes (their shape follows the answer); 97 step 6
> (conditional).
