# Track 02 — std and packaging

**Repos:** `repository/botopink-lang/libs/std` (and the bundled libraries' consumer edits 97 names) ·
every `repository/<lib>/botopink.json` and `modules/<lib>-test/` skeleton · the manifest carve-out
(`modules/manifest/**`, decision 75).

The track owes two things:

1. **std is the one place a shared primitive lives** — `parseInt` / `parseFloat`, the `Json`
   accessors, `pbkdf2Sha256`, `parseDuration`, `RetryPolicy` and the snapshot engine on `io/fs` are
   on feat; what is left is the `i32` binder, the conditional steps, std on wasm (group 3), the std
   bodies `01-compiler/05-wasm` step 5 waits on (decisions 259–263) and the rows that hand each
   library copy to the front that owns its file. Front
   [`97-std-dedupe`](./97-std-dedupe/README.md).
2. **The packaging rule is checked everywhere it applies** — a `-test` member with an
   `assert<Subject>(loc, …)` helper in every library, a `README.md` beside every example (29 of 29
   lack one), the `git`-dependency subdirectory question (lg2-v) and the takeover's amended decision
   79 (95-f). Front [`98-packaging-tail`](./98-packaging-tail/README.md), which runs after the library
   tracks have written their helpers and READMEs.

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`97-std-dedupe/`](./97-std-dedupe/README.md) | high | partial: steps 0–5, 8–10 on feat; step 1 box 4, step 2 box 3, step 3 box 3, step 4 box 2, step 5 box 3, steps 6, 11, 12 open; step 7 → 20-snap | the shared primitives in std; the consumer rows; std on wasm group 3 (decision 230); the std bodies of decisions 259, 260, 262, 263 | `std-d` (step 6) · `24-g` confirmed |
| [`98-packaging-tail/`](./98-packaging-tail/README.md) | medium | not started | `erika-test`'s first helper and `erika-linq`'s README; `scripts/check-packaging.sh`; `docs/botopink-json.md`; the manifest `subdir` field if lg2-v is answered (2) | every library track's `-test` and example-README steps · `95-f` · `lg2-v` |

## Order

```
97-std-dedupe ──────────┐   (alone in libs/std/src/**: every front compiles against it)
                        ├──► 03-bundled-libs consumer halves
                        ├──► 04-rakun / 05-jhonstart / 06-emilia / 07-onze "consume std" steps
   library tracks' -test helpers and example READMEs ──► 98-packaging-tail   (last: it verifies)
```

97 runs alone because a std primitive landed after its consumers were rewritten is rewritten twice;
98 is last because its acceptance is a grep over files other fronts write.

## Not yet filed

STD-11, two compiler rows found by std's own tests, are not rows of
[`language-gaps.md`](../language-gaps.md) yet: `import {io.process}` shadows Node's global `process`
in the commonJS test runner (`01-compiler/04-js`); a non-ASCII string literal reaches erlang as
latin1, and a code point above U+00FF is `illegal character` (`01-compiler/02-erlang`).

## Decisions

### To confirm

Choices 1.0.10 implemented; the text is in
[1.0.10-beta `decisions-pending.md`](../../1.0.10-beta/decisions-pending.md).

| Id | Choice | Closes on it |
|---|---|---|
| 01std-a | a bundled library is loaded by the CLI and the LSP, not `expandStdImports` | — |
| 01std-c | `routing.pattern`'s empty pattern matches only `/` | — |
| 01std-e | `actions.readEnvelope` refuses a `redirect` that disagrees with `n` | — |
| std-a · std-b · std-c | `querystring` refuses by `Error`; `fs.exists` follows a link; decision 110's folder namespace is a rewrite | — |
| 24-g | `std/async`'s started/unstarted surface (`allOf`, `all`, `race`, `runAll`, `raceOf`, `timeout`; `allSettled` gone) | 97 step 5 builds `RetryPolicy` on it |
| ck2-e | a std decorator is reached through its module handle | — |
| 95-a · 95-b · 95-c · 95-e | the relocation cuts; `rakun-app` inherits targets (amended by rakun's `["erlang"]`); `erika-test` exists; the qualified `from "rakun/request_context"` | — |
| lg2-v | a subdirectory in a git dependency — recommendation (1), none ([`../decisions-pending.md`](../decisions-pending.md)) | 98 step 4 |

### 95-f · The onze takeover happened without the orphan branch and the archive — amend decision 79

> **Measured.** `repository/onze` is the orchestrator's workspace (`"name": "onze"`,
> `"workspaces": ["modules/*", "examples/*"]`, eight members with `files`), built on the tag
> `mocking-lib-final` in the **same** repository history and remote — not the orphan branch
> `front/95-onze-orchestrator` decision 79 and 95-d described; nothing was archived or renamed.
> `.gitmodules` has one `repository/onze` entry; `grep -rn '"onze"' --include=botopink.json
> repository/` finds only the orchestrator's members.
> **Options.** (1) confirm the tree: a new decision amends 79 — the old library lives as the tagged
> history of the same repository, nothing is archived; (2) rewrite the remote to the orphan branch
> and archive the old history (destructive: every checkout of `repository/onze` re-clones).
> **Recommendation.** (1): the name resolves to the orchestrator, the tag resolves, the mocking
> surface lives in std's `testing.mocks`; (2) buys nothing `git log` does not show and costs every
> consumer a re-clone.
> **Blocks.** 98 step 3.

### std-d · `io.process` signals and a TTY reader — add, or refuse the callers

> **Raised by** 97, for onze front 50 (`onze start` forwarding `SIGTERM`; `onze create`'s prompts).
> **Measured.** `libs/std/src/io/process.bp` runs and spawns; it neither registers a signal handler
> nor forwards one to a child, and std has no line reader over a TTY. onze 50's `start` waits on
> `process.run`, so `SIGTERM` to the CLI leaves the node running; `create` without `--yes` has no
> prompt to fall back to.
> **Options.** (a) std gains `process.onSignal(name, fn)`, `process.forwardSignals(child)` and
> `io.stdin.readLine()` — three host cells on two targets; (b) no std change: `onze start` execs the
> node (front 71's `bin/onze` is PID 1 and receives the signal), and `onze create` without `--yes`
> is refused naming the flags it needs.
> **Recommendation.** (b), the most restrictive: no interactive path to get wrong, and the signal
> reaches the process that must drain it. (a) is additive later if a second consumer appears.
> **Blocks.** onze 50's `SIGTERM` and prompt boxes; 97 step 6.

`std-e` (test lifecycle hooks) is written in [`../decisions-pending.md`](../decisions-pending.md).
