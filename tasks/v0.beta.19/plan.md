# v0.beta.19 — plan (reasoning scratchpad)

Mutable. The *why* behind v0.beta.19's shape and the trade-offs each frente
chose. Authored intent lives in `specs/`; this file is the thinking around
them.

## Premise

After v0.beta.18 every keystone has shipped: the language is distributable
(release pipeline + installer + bpmp), the workspace is restructured into
sibling projects, the LSP is project-aware + definition-complete,
sub-languages have a custom-AST carrier, and the effect annotations replaced
the deprecated `*fn` prefix byte-identically. The compiler runs every backend
(commonJS, erlang, beam, wasm) — but each prior wave deliberately *recorded*
the items it deferred, in spec non-goals, in `AGENTS.md` "KNOWN GAP" notes,
in backend "Remaining gaps", and in `pinned for follow-up` lists.

v0.beta.19 is the **closing wave**: collect every deliberately-deferred item
into three file-disjoint frentes, each carrying a coherent set of tracks
that can run in parallel on its own worktree. Once this set lands, every
spec authored before it is fully closed.

## What this set is NOT

- **Not a new language wave.** No new keywords or syntax. Frente A §A–§G
  only close recorded codegen gaps; §S/§U delete dead surface; Frente B §1G
  formalises a *general* rule (default generics) that the wrappers in
  Frente B's other sections rely on; the effect rules §1/§1F/§1I/§1C are
  hand-authored by the user as addenda, not spec inventions; §E/§F/§T are
  tooling slices.
- **Not a bpmp rewrite.** Frente C §H wires `std.http` + `std.tar` into the
  existing offline-safe stubs; the v0.beta.18 spec `bpmp.md` already nails
  the design.
- **Not a `module-auto-tag` re-design.** Frente C §J implements the v0.beta.18
  spec `module-auto-tag.md` *as authored*; that spec is immutable.
- **Not the place to add effect composition.** `#[@result] #[@asyncGenerator]`
  composed bodies are explicitly out of scope per Frente B's §3 ; record
  the hook for a future spec.

## Big decisions

### D1. Three frentes instead of one spec or eleven

The original plan was either:
1. **One consolidating spec** (`final-sweep.md` + 5 ortogonal cleanups) —
   five specs total, mixed concerns inside `final-sweep`'s 11 sections.
2. **One spec per section** (~11 worktrees) — DAG overhead duplicated.

Picked **three frentes**: each is a coherent unit of work that one
worktree can carry from start to ship, internal tracks are file-disjoint,
and the only inter-frente coordination is one hand-off (Frente A §D-D4 ↔
Frente B Rules §1F).

Why three:
- **Frente A** is the compiler: parser / ast / comptime / codegen ×4. One
  worktree, one Zig build, internal DAG (§A keystone first).
- **Frente B** is the developer-facing surface: language rules + LSP +
  `.d.ts` + test runner output. Touches comptime + language-server +
  CLI driver. Internal DAG is Rules-track-only; §E/§F/§T are parallel.
- **Frente C** is the ops surface: bpmp networking + submodule
  housekeeping + CI/CD workflows + env plumbing. Touches `modules/bpmp/`
  + workflow files + scripts. Internal DAG is §H → §I → §J; §K is
  independent.

### D2. Cleanups (§S `*fn`, §U unused builtins) live in Frente A, not in their own frente

Both edit `modules/compiler-core/src/`. Splitting them off would create a
fourth frente touching the same file tree as Frente A — guaranteed merge
contention. Keeping them inside Frente A as parallel tracks (file-disjoint
from §A–§G inside the frente) costs nothing and avoids the cross-frente
merge.

### D3. The Rules track (§0–§4) lives in Frente B alongside LSP/`.d.ts`/test runner

The Rules track is **authoritative language-surface** — it dictates the
`#[@result]` auto-wrap behaviour, the `@Future<T, E = any>` dual contract,
the `@Iterator<T, E, C>` three-channel shape, and the `#[@context]` Anchor
isolation. Pairing it with LSP/`.d.ts`/test runner output makes the
"developer-facing surface" frente coherent: this is what a botopink author
*reads* (the rules), what their IDE *shows them* (LSP), what the host
*sees* (`.d.ts`), and what their tests *log* (run-log).

Alternative considered: put the Rules track in Frente A (since it touches
comptime + codegen). Rejected because the *contract* surface (validation,
diagnostics, the `builtins.d.bp` mirror) is reader-facing, not
backend-facing. The codegen pieces that the Rules track requires
(`#[@result]` auto-wrap rewrite in `transform.zig`) are small and can land
parallel to Frente A's §A keystone.

### D4. Hard delete for `*fn` and unused builtins, no soft deprecation

The "deprecated for one release, removed the next" pattern fits external
APIs with downstream consumers. `*fn` and the unused builtins have **zero
authored consumers** in `repository/**.bp` (verified by grep). Soft
deprecation pays for a behaviour change no one is making.

Counter-argument: an out-of-tree user might author `*fn`. Response: the
warning was v0.beta.12 (commit `d09e4ea`), and an out-of-tree user is
already living with v0.beta.13–.18 of breaking changes. The
`deprecated-star-fn` parser diagnostic carries a migration hint inline —
that's the out-of-tree user's documentation.

### D5. The `#[@result]` auto-wrap (§1) belongs in the Rules track, not in Frente A

§1 of Frente B's Rules track says `return r;` → `return @Result.Ok(r);`
(internal AST rewrite). This is a *rules* change, not a recorded gap — no
prior spec recorded it as deferred. Putting it in Frente A would conflate
"close recorded items" with "lock down rules", and the latter deserves the
reader-facing frente.

Trade-off: the auto-wrap touches `comptime/transform.zig`, which Frente A
§A also touches. Coordinate at merge time — §A's keystone is the
byte-identical refactor (no semantic change) so the auto-wrap rewrite
slots in afterwards cleanly.

### D6. The Portuguese addenda in §1 / §1F / §1I / §1C

Per memory rule `feedback_everything_english`, every file in the project is
English. The four addenda blocks are the **only exceptions**: the
user-supplied rulesets are reproduced verbatim (Portuguese) so the
authoritative wording has zero translation drift. The surrounding spec is
English; the surrounding diagnostic tables (R-codes) are English; only
the indented blockquotes inside §1, §1F, §1I, §1C are bilingual.

§1G (default generic parameters) is **fully English** — the user did not
supply a Portuguese addendum for it; the spec authored it from the
`@Future<T, E = any>` + `@Iterator<T, E = any, C = void>` examples plus
the "trailing only" rule the §1F addendum stated.

### D7. `module-auto-tag` is Frente C §J, not a top-level v19 spec

Two paths considered:

1. Top-level: `tasks/v0.beta.19/specs/module-auto-tag.md` re-authors the
   intent.
2. §J of Frente C: implementation receipt, references
   `tasks/v0.beta.18/specs/module-auto-tag.md` as the immutable intent.

Picked (2). The v18 spec is immutable (per universal contract) —
re-authoring would split the source of truth. §J is the *receipt* of
running that spec; the spec itself stays where it lives.

Same reasoning applies to v17's two F6 deferreds (now §K of Frente C).

### D8. Submodule mergeback (§I) before module-auto-tag (§J)

`module-auto-tag` tags `compiler-core` / `compiler-cli` /
`vscode-extension` on their own version stream. If the lib submodules in
`repository/botopink-lang` aren't on each lib's `feat` head yet, the
auto-tag could read a stale version field. §I lands the merges + bumps;
§J runs after the bumps are in place.

## Risk surface

| Risk | Mitigation |
|---|---|
| Frente A §A6 byte-identical bar fails | §A6's gate is `diff -r snapshots/codegen/ <pre-§A6>` is empty. If it's not, debug the keystone refactor before adding cases. Pre-existing snapshot suite is the safety net. |
| Frente A §A → §B coupling on `infer.zig` | §A lands first (D1 hands-off rule); §B reads the post-A `infer.zig` and extends, never reverts. |
| Frente A §U deletes something the LSP relies on for hover/completion | F4 gates: `botopink-lib-test` + LSP semantic-tokens snapshot. Any drift surfaces in the gate. |
| Frente A §S rewrite of `js_control_flow.zig` introduces a fixture diff | F4 gate: each rewrite re-runs `zig build test`; byte-identical promise from v12 covers this. |
| Frente B Rules §1 auto-wrap rewrites a `return @Result.Ok(r);` someone wrote thinking they were being explicit | R11 diagnostic catches this at author time. No silent transformation. |
| Frente B §T fence collision (user's test prints the sentinel) | Documented as user's responsibility; no escaping. The runtime captures the byte stream literally. |
| Frente C §H bpmp HTTP wiring depends on `std.http.Client` API stability across Zig versions | Pin `minimum_zig_version` via `mlugg/setup-zig@v1` (already done in v18 §A2). |
| Frente C §I lib mergeback surfaces a conflict (a lib's `feat` advanced past `task/distribution`) | One PR at a time per sibling, resolve in the sibling's `feat`, then bump. Per memory rule `feedback_user_works_in_parallel`, re-check `git status` immediately before each merge. |
| Frente C §J `module-auto-tag` smoke-test in a fork burns CI quotas | Use Eric's own fork (per memory rule `feedback_always_ssh_git`). |
| Cross-frente: Frente A §D-D4 starts before Frente B Rules §1F lands | §D-D4 has a "scope to follow-up" clause; if §1F isn't in yet, Frente A records the gap in `codegen/AGENTS.md` and ships without the future emitter. |

## Order of work — recommended

Three worktrees in parallel; weave the work as follows:

**Frente A worktree:**
1. §S (`*fn` removal) — pure deletion, byte-identical. Land first, push.
2. §A (keystone) — byte-identical refactor that §B/§D consume.
3. §B/§C/§D/§G in parallel after §A — file-disjoint after the keystone.
4. §U (unused builtins) — late in cycle, after §S and the Rules track
   have locked the effect tags.

**Frente B worktree:**
1. Rules track §0 → §1 → §1F → §1I → §1C → §1G — sequential, locks the
   contract.
2. Rules track §2 → §3 → §4 → Steps F0–F7 (diagnostics, mirror, tests).
3. §E / §F / §T in parallel any time — file-disjoint.

**Frente C worktree:**
1. §H bpmp online — wire HTTP / tar / swap.
2. §I submodule mergeback — one PR at a time per sibling, bump after each.
3. §J module-auto-tag — its own `.tasks/module-auto-tag/` sub-worktree.
4. §K in parallel any time — env plumbing.

## What's deliberately deferred to v0.beta.20+

- **Effect composition** (`#[@result] #[@asyncGenerator]` etc.) — recorded
  in Frente B Rules §3.
- **bpmp registry / index server** — recorded in v18 `bpmp.md` non-goals.
- **Multi-package workspaces** — recorded in v18 README non-goals.
- **wasm cross-module linking** — recorded in Frente A §C5.
- **Composing `#[@future]` with `#[@result]` for fallible futures** —
  Frente B Rules §1F notes the boundary.
- **`#[@context]` runtime reflection on `any`-typed rejection payloads** —
  Frente B Rules §1G hints at the follow-up.

## Per-memory reminders applicable to v19 work

- All commits in English; conversation here in pt-br.
- AGENTS.md updated in the same commit as the code it documents.
- SSH for all git remote ops (no gh/https).
- Worktree paths for Read/Edit during execution; `rtk git` for status (not
  the bare `git` whose output rtk filters).
- `rtk proxy` when reading large file diffs (the rtk default strips them).
- Pre-commit gate (zig fmt + build + test) on every commit; **no
  `--no-verify`** ever.
- Functions in camelCase.
- Implement in `.bp` when possible; `.d.bp` only for markers / FFI /
  abstract interface.
- After commit, advance to the next checkbox.
