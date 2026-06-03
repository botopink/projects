# Modules Reorg — top-level `libs/` + `examples/`, move stdlib, scaffold server/client

**Branch**: `task/stdlib-relocate` (worktree `.tasks/stdlib-relocate`, nasce de `feat`)
**Depends on**: nothing. Path/rename + scaffold refactor — **no compiler logic,
no AST, no snapshot regeneration**.
**Status**: **planned (spec only — nothing applied yet)**

> Spec espelhada em `tasks/stdlib-relocate.md` (doc indexado em `feat`).

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

Idiomatic split — Rust (`compiler/` vs `library/`), Zig (`src/` vs `lib/std/`), Go,
Deno, Swift all separate "the toolchain" from "code written in the language". It buys:

1. **Independent change cycles.** `git log libs/` = the language's story; `git log
   modules/` = the toolchain's. Neither is noise in the other.
2. **Explicit dependency arrow.** `modules/compiler-core` → consumes `libs/std`.
   Top-level separation makes the direction obvious and hard to violate.
3. **Matches newcomer expectations.** stdlib → `libs/std`, compiler → `modules/`,
   examples → `examples/`. No `.bp` hidden inside the toolchain folder.

**Only trade-off:** more top-level dirs — which is the point. Technical cost is a
single `build.zig` path (`libs/std/src/prelude.zig`).

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

- [ ] `git mv modules/stdlib libs/std` (creates `libs/` at repo root)
- [ ] `build.zig:15` path → `b.path("libs/std/src/prelude.zig")` (keep module name
      `stdlib_prelude`)
- [ ] Root `AGENTS.md`:
  - [ ] tree block: `modules/stdlib/` + ` └── src/` → top-level `libs/` entry (Step 5)
  - [ ] "deep content" table: `modules/stdlib/docs.md` → `libs/std/docs.md`
  - [ ] "examples" table: `modules/stdlib/src/examples.md` → `libs/std/src/examples.md`
- [ ] `modules/AGENTS.md` (stdlib leaves `modules/`):
  - [ ] drop the `stdlib/` subtree (lines ~28–30)
  - [ ] drop the `stdlib/` packages row; `compiler-core` `Depends on` `stdlib` → `libs/std`
  - [ ] one-line pointer: `.bp` libs now live at root `../libs/`
- [ ] `CHANGELOG.md`: `modules/stdlib/src/builtins.d.bp` → `libs/std/src/builtins.d.bp`
- [ ] moved `Path:` headers (now `libs/std/`):
  - [ ] `libs/std/AGENTS.md:3`, `libs/std/docs.md:3` → `Path: libs/std/`
  - [ ] `libs/std/src/AGENTS.md:3`, `libs/std/src/docs.md:3` → `Path: libs/std/src/`
  - [ ] confirm `Parent: ../AGENTS.md · Root: ../../AGENTS.md` in `libs/std/AGENTS.md`
        now resolves to `libs/AGENTS.md` + root `AGENTS.md`

**Open decision (do NOT do silently):** rename package id `"name": "stdlib"` → `"std"`
in `libs/std/botopink.json`? My recommendation: **yes, rename to `std`** (one
concept = one name; folder=`std`, id=`stdlib`, module=`stdlib_prelude` is 3 names for
1 thing). Full cost measured = **7 lines**, all mechanical:
- `botopink.json` name (1)
- `stdlib_prelude` → `std_prelude`: root `build.zig` (l.14,25,35), the per-module
  `modules/compiler-core/build.zig` (l.31,48), and the single real
  `@import("stdlib_prelude")` at `modules/compiler-core/src/comptime.zig:175`.
Default if we stay conservative: **leave both ids as `stdlib`** and only move paths.
➜ **Pending your call** before applying.

## Step 2 — Scaffold `libs/server` and `libs/client`

Mirror `libs/std`'s shape, minimal content. **Not** embedded into the compiler
(no `prelude.zig`, no `build.zig` wiring) — library packages for future `.bp` code.

```text
libs/<name>/
├── AGENTS.md          ← Path header + one-paragraph purpose + tree
├── docs.md            ← what the lib provides + loading notes (stub)
├── botopink.json      ← { name, version "0.0.1", description, src "src/", files: [] }
└── src/
    ├── AGENTS.md       ← Path header for src/
    └── <name>.d.bp     ← placeholder declaration file (header comment only)
```

- [ ] `libs/server/` — purpose stub: HTTP/socket server-side interfaces
- [ ] `libs/client/` — purpose stub: HTTP/client-side request interfaces
- [ ] `botopink.json` `files: []` (or single placeholder) — claim no symbols yet

## Step 3 — Create `libs/AGENTS.md`

- [ ] group-level contract: intro + package table (`std`/`server`/`client`) with
      one-line purpose + links (style of `modules/AGENTS.md`). `Path: libs/`,
      `Root: ../AGENTS.md`.

## Step 4 — Create top-level `examples/`

```text
examples/
├── AGENTS.md          ← Path: examples/ ; what lives here; how to run a .bp
└── hello.bp           ← one tiny runnable example (smallest valid program)
```

- [ ] `examples/AGENTS.md`
- [ ] `examples/hello.bp` — minimal, compiles with `botopink`; not in any snapshot harness

## Step 5 — Root `AGENTS.md` tree + indexes

- [ ] tree shows, alongside `modules/`:

```text
libs/                                          → .bp libraries (see libs/AGENTS.md)
  ├── std/                                     → standard library (prelude + interfaces)
  ├── server/                                  → server-side interfaces (scaffold)
  └── client/                                  → client-side interfaces (scaffold)
examples/                                      → .bp example programs
```

- [ ] add rows to "deep content" / "examples" tables where useful

---

## Verify

- [ ] `grep -rn "modules/stdlib" .` (excluding task docs) → nothing
- [ ] `zig build` succeeds (prelude resolves from `libs/std/src/prelude.zig`)
- [ ] `zig build test` green — no snapshot/test churn (pre-commit enforces)
- [ ] `botopink` compiles `examples/hello.bp` (manual smoke)
- [ ] `git status`: only the `git mv` renames + doc/build edits + new
      `libs/{server,client}`, `libs/AGENTS.md`, `examples/`. No orphans.

## Notes / risks

- `stdlib_prelude` (Zig module name) + `botopink.json` `name: stdlib` are **ids**,
  not paths — see Step 1 open decision before touching them.
- `server`/`client` are **inert scaffolds** this task — no compiler registration.
  Wiring into stdlib loading / type env is a separate, explicit follow-up.
- Per repo convention, every touched/new directory needs its `AGENTS.md` updated in
  the **same commit** (root `AGENTS.md` → Conventions).
- Integrate into `feat` (not `main`) per the worktree workflow.
