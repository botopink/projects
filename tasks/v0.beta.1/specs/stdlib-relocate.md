# Modules Reorg — top-level `libs/` + `examples/`, move stdlib, scaffold server/client

**Branch**: `task/stdlib-relocate` (worktree `.tasks/stdlib-relocate`)
**Depends on**: nothing. Path/rename + scaffold refactor — **no compiler logic,
no AST, no snapshot regeneration**.
**Status**: **planned (spec only — nothing applied yet)**

## Decision (agreed)

Separate **toolchain implementation** from the **language ecosystem**. Today
`modules/` mixes the Zig/TS toolchain (`compiler-cli`, `compiler-core`,
`language-server`, `vscode-extension`) with code written *in* botopink (the `.bp`
stdlib). We lift the `.bp` world to the repo root.

```text
repo/
├── modules/            ← toolchain implementation (Zig + TS) — UNCHANGED
│   ├── compiler-cli/
│   ├── compiler-core/
│   ├── language-server/
│   └── vscode-extension/
├── libs/               ← .bp libraries (NEW top-level group)
│   ├── std/            ← moved from modules/stdlib
│   ├── server/         ← NEW scaffold
│   └── client/         ← NEW scaffold
└── examples/           ← NEW top-level: .bp example programs
```

### Why this layout (rationale — confirmed)

This is the idiomatic split — Rust (`compiler/` vs `library/`), Zig (`src/` vs
`lib/std/`), Go, Deno, Swift all separate "the toolchain" from "code written in the
language". Concretely it buys:

1. **Independent change cycles.** The Zig compiler and the `.bp` libraries evolve
   for different reasons at different rates. Split, `git log libs/` tells the story
   of *the language*, `git log modules/` the story of *the toolchain* — neither is
   noise in the other.
2. **Explicit dependency arrow.** `modules/compiler-core` → consumes `libs/std`.
   Top-level separation makes the direction obvious and hard to violate (the
   compiler never reaches *into* a lib's internals, and a lib never depends on Zig).
3. **Matches newcomer expectations.** "Where's the stdlib?" → `libs/std`. "The
   compiler?" → `modules/`. "Examples?" → `examples/`. No need to know `.bp` hides
   inside the toolchain folder.

**Only trade-off:** more top-level dirs (`modules/` + `libs/` + `examples/`) — which
is the point: the repo root should reflect the project's real domains. Technical
cost is a single `build.zig` path (`libs/std/src/prelude.zig`).

## Key invariant (why this is safe)

Mechanical move + new empty-ish scaffolds. The only thing that reads the stdlib by
**path** is `build.zig` (the `stdlib_prelude` module's `root_source_file`). The Zig
module *name* `stdlib_prelude` and the `@import("stdlib_prelude")` call-sites in
`compiler-core` are **identifiers, not paths** — untouched. The package id
`"name": "stdlib"` in `botopink.json` is also an id, not a path.

➜ **Zero `.snap.md` churn. No `test "…"` renamed. `zig build` + `zig build test`
stays green.** `server`/`client`/`examples` are **not** wired into the compiler in
this task (they carry no embedded prelude), so they cannot affect the build.

---

## Step 1 — Move stdlib → `libs/std`

```bash
git mv modules/stdlib libs/std      # creates libs/ at repo root
```

Then fix the single build wiring **path** (keep the module name `stdlib_prelude`):

- `build.zig:15`
  `b.path("modules/stdlib/src/prelude.zig")` → `b.path("libs/std/src/prelude.zig")`

Doc/path references to update (no logic):

- **Root `AGENTS.md`**
  - Tree block: replace the `modules/stdlib/` + ` └── src/` lines with a top-level
    `libs/` entry (see Step 4 for the tree shape).
  - "Where deep content lives" table: `modules/stdlib/docs.md` → `libs/std/docs.md`.
  - "Where concrete examples live" table: `modules/stdlib/src/examples.md`
    → `libs/std/src/examples.md`.
- **`modules/AGENTS.md`** — stdlib is leaving `modules/`, so **remove** it here:
  - Tree: drop the `stdlib/` subtree (lines ~28–30).
  - Packages table: drop the `stdlib/` row; change `compiler-core`'s
    `Depends on` cell from `stdlib` to `libs/std`.
  - Add a one-line pointer noting `.bp` libs now live at root `../libs/`.
- **`CHANGELOG.md`** — `modules/stdlib/src/builtins.d.bp`
  → `libs/std/src/builtins.d.bp`.
- **Moved file `Path:` headers** (now at `libs/std/`):
  - `libs/std/AGENTS.md:3` `Path: modules/stdlib/` → `Path: libs/std/`
  - `libs/std/docs.md:3` same
  - `libs/std/src/AGENTS.md:3` `Path: modules/stdlib/src/` → `Path: libs/std/src/`
  - `libs/std/src/docs.md:3` same
  - In `libs/std/AGENTS.md` the `Parent: ../AGENTS.md · Root: ../../AGENTS.md`
    links now resolve to `libs/AGENTS.md` and the root `AGENTS.md` — correct as-is,
    just confirm.

**Open decision (do NOT do silently):** rename package id `"name": "stdlib"` →
`"std"` in `libs/std/botopink.json`? Leaving it avoids touching any name-based
lookup. Default for this task: **leave it `stdlib`**; flag for a follow-up if we
want the id to match the folder.

## Step 2 — Scaffold `libs/server` and `libs/client`

Mirror `libs/std`'s shape, minimal content. **Not** embedded into the compiler
(no `prelude.zig`, no `build.zig` wiring) — these are library packages for future
`.bp` code. Each gets:

```text
libs/<name>/
├── AGENTS.md          ← Path header + one-paragraph purpose + tree
├── docs.md            ← what the lib provides + loading notes (stub)
├── botopink.json      ← { name, version "0.0.1", description, src "src/", files: [] }
└── src/
    ├── AGENTS.md       ← Path header for src/
    └── <name>.d.bp     ← placeholder declaration file (header comment only)
```

- `server` — purpose stub: HTTP/socket server-side interfaces (`.bp` declarations).
- `client` — purpose stub: HTTP/client-side request interfaces (`.bp` declarations).
- `botopink.json` `files: []` (or the single placeholder) so nothing claims to
  export symbols that don't exist yet.

## Step 3 — Create `libs/AGENTS.md`

New group-level contract for the `.bp` libraries directory: short intro + a
package table (`std`, `server`, `client`) with one-line purpose + links, following
the style of `modules/AGENTS.md`. `Path: libs/` header; `Root: ../AGENTS.md`.

## Step 4 — Create top-level `examples/`

```text
examples/
├── AGENTS.md          ← Path: examples/ ; what lives here; how to run a .bp
└── hello.bp           ← one tiny runnable example (smallest valid program)
```

Keep it minimal and runnable so `botopink` can compile it. Do not add it to any
snapshot harness.

## Step 5 — Root `AGENTS.md` tree + indexes

Reflect the new top level. The tree should now show, alongside `modules/`:

```text
libs/                                          → .bp libraries (see libs/AGENTS.md)
  ├── std/                                     → standard library (prelude + interfaces)
  ├── server/                                  → server-side interfaces (scaffold)
  └── client/                                  → client-side interfaces (scaffold)
examples/                                      → .bp example programs
```

Add corresponding rows to the "deep content" / "examples" doc tables where useful
(`libs/AGENTS.md`, `examples/AGENTS.md`).

---

## Verify

- `grep -rn "modules/stdlib" .` (excluding this task doc) → nothing.
- `zig build` succeeds (prelude path resolves from `libs/std/src/prelude.zig`).
- `zig build test` green — no snapshot or test churn (pre-commit hook enforces this).
- `botopink` compiles `examples/hello.bp` (manual smoke).
- `git status` shows only: the `git mv` renames, the doc/build edits, and the new
  `libs/{server,client}`, `libs/AGENTS.md`, `examples/` files. No orphans.

## Notes / risks

- `stdlib_prelude` (Zig module name) and `botopink.json` `name: stdlib` are **ids**,
  not paths — intentionally left alone to avoid breaking `@import` and lookups.
- `server`/`client` are **inert scaffolds** this task — no compiler registration.
  Wiring them into stdlib loading / type env is a separate, explicit follow-up.
- Per repo convention, every touched/new directory needs its `AGENTS.md` updated in
  the **same commit** (see root `AGENTS.md` → Conventions).
- Integrate into `feat` (not `main`) per the worktree workflow.
