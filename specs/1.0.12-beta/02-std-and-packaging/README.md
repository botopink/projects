# Track 02 — std and packaging

**Repos:** `repository/botopink-lang/libs/std` (+ the bundled libraries' consumer edits 97 names) ·
every `repository/<lib>/botopink.json` and `modules/<lib>-test/` skeleton · the manifest carve-out
(`modules/manifest/**`, decision 75).

Owes:

1. **std is the one place a shared primitive lives** — `parseInt` / `parseFloat`, `Json` accessors,
   `pbkdf2Sha256`, `parseDuration`, `RetryPolicy`, the snapshot engine on `io/fs` are on feat. Left:
   the `i32` binder, the conditional steps, std on wasm (group 3), the std bodies
   `01-compiler/05-wasm` step 5 waits on (decisions 259–263), the rows handing each library copy to
   its file's front. Front [`97-std-dedupe`](./97-std-dedupe/README.md).
2. **The packaging rule checked everywhere** — a `-test` member with an `assert<Subject>(loc, …)`
   helper per library, a `README.md` beside every example (29 of 29 lack one), the `git`-dependency
   subdirectory question (lg2-v), amended decision 79 (95-f). Front
   [`98-packaging-tail`](./98-packaging-tail/README.md), after the library tracks' helpers and READMEs.

## Fronts

| Front | Priority | State | What | Depends on |
|---|---|---|---|---|
| [`97-std-dedupe/`](./97-std-dedupe/README.md) | high | partial: steps 0–5, 8–10, 12 on feat; step 1 box 4, step 2 box 3, step 4 box 2, steps 6, 11, 13–17 open (11's questions: 97-a/b → 334, 97-c open); step 7 → 20-snap | the shared primitives in std; the consumer rows; std on wasm group 3 (decision 230); the std bodies of decisions 259, 260, 262, 263 | `std-d` (step 6) · `24-g` confirmed |
| [`98-packaging-tail/`](./98-packaging-tail/README.md) | medium | not started | `erika-test`'s first helper and `erika-linq`'s README; `scripts/check-packaging.sh`; `docs/botopink-json.md`; the manifest `subdir` field if lg2-v is answered (2) | every library track's `-test` and example-README steps · `95-f` · `lg2-v` |

## Order

```
97-std-dedupe ──────────┐   (alone in libs/std/src/**: every front compiles against it)
                        ├──► 03-bundled-libs consumer halves
                        ├──► 04-rakun / 05-jhonstart / 06-emilia / 07-onze "consume std" steps
   library tracks' -test helpers and example READMEs ──► 98-packaging-tail   (last: it verifies)
```

97 alone: a primitive landed after its consumers means rewriting them twice. 98 last: its acceptance
greps files other fronts write.

## Decisions

### To confirm

Implemented in 1.0.10; text in [1.0.10-beta `decisions-pending.md`](../../1.0.10-beta/decisions-pending.md).

| Id | Choice | Closes on it |
|---|---|---|
| 01std-a | a bundled library is loaded by the CLI and the LSP, not `expandStdImports` | — |
| 01std-c | `routing.pattern`'s empty pattern matches only `/` | — |
| 01std-e | `actions.readEnvelope` refuses a `redirect` that disagrees with `n` | — |
| std-a · std-b · std-c | `querystring` refuses by `Error`; `fs.exists` follows a link; decision 110's folder namespace is a rewrite | — |
| 24-g | `std/async`'s started/unstarted surface (`allOf`, `all`, `race`, `runAll`, `raceOf`, `timeout`; `allSettled` gone) | 97 step 5 builds `RetryPolicy` on it |
| ck2-e | a std decorator is reached through its module handle | — |
| 95-a · 95-b · 95-c | the relocation cuts; `rakun-app` inherits targets (amended by rakun's `["erlang"]`); `erika-test` exists (`95-e` closed 9 Oct: the `percentDecode` collision left the code, rakun uses `encoding.percentDecode`) | — |
| lg2-v | a subdirectory in a git dependency — recommendation (1), none ([`../decisions-pending.md`](../decisions-pending.md)) | 98 step 4 |

### 95-f · The onze takeover happened without the orphan branch and the archive — amend decision 79

> **Measured.** `repository/onze` is the orchestrator's workspace (`"name": "onze"`,
> `"workspaces": ["modules/*", "examples/*"]`, eight members with `files`), built on tag
> `mocking-lib-final` in the **same** history and remote — not the orphan branch
> `front/95-onze-orchestrator` of decision 79 / 95-d; nothing archived or renamed. `.gitmodules` has
> one `repository/onze` entry; `grep -rn '"onze"' --include=botopink.json repository/` finds only the
> orchestrator's members.
> **Options.** (1) confirm the tree: a new decision amends 79 — the old library is the tagged history
> of the same repository, nothing archived; (2) rewrite the remote to the orphan branch and archive
> the old history (destructive: every checkout of `repository/onze` re-clones).
> **Recommendation.** (1): name and tag resolve, mocking lives in std's `testing.mocks`; (2) buys
> nothing `git log` lacks and costs every consumer a re-clone.
> **Blocks.** 98 step 3.

### std-d · `io.process` signals and a TTY reader — add, or refuse the callers

> **Raised by** 97, for onze front 50 (`onze start` forwarding `SIGTERM`; `onze create`'s prompts).
> **Measured.** `libs/std/src/io/process.bp` runs and spawns; no signal handler, no forwarding to a
> child, no TTY line reader. onze 50's `start` waits on `process.run`, so `SIGTERM` to the CLI leaves
> the node running; `create` without `--yes` has no prompt.
> **Options.** (a) std gains `process.onSignal(name, fn)`, `process.forwardSignals(child)`,
> `io.stdin.readLine()` — three host cells on two targets; (b) no std change: `onze start` execs the
> node (front 71's `bin/onze` is PID 1 and receives the signal), `onze create` without `--yes` is
> refused naming the flags it needs.
> **Recommendation.** (b), most restrictive; (a) additive later if a second consumer appears.
> **Blocks.** onze 50's `SIGTERM` and prompt boxes; 97 step 6.

`std-e` (test lifecycle hooks) is in [`../decisions-pending.md`](../decisions-pending.md).
