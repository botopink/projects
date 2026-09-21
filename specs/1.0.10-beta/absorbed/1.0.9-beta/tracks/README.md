# Tracks — the per-library documents of 1.0.9-beta

A front (`../NN-<name>/README.md`) is the unit of work: one worktree, one branch, one owner. A
**track** is the library the fronts of one letter deliver into. This directory holds what is decided
per library rather than per front, so that a front never has to repeat it and two fronts never
decide it differently.

| Track | Directory | Files |
|---|---|---|
| A — std | [`std/`](./std/) | `asserts.md` (the canonical assertion API), `snapshots.md` (the `.snap` format and path rules), `modules.md` |
| B — rakun | [`rakun/`](./rakun/) | `modules.md`, `unification.md`, `test-snap.md`, `test-snap-examples.md` |
| C — jhonstart | [`jhonstart/`](./jhonstart/) | `modules.md`, `unification.md`, `test-snap.md`, `test-snap-examples.md` |
| D — emilia | [`emilia/`](./emilia/) | `modules.md`, `reference-coverage.md`, `test-snap.md`, `test-snap-examples.md` |
| E — onze | [`onze/`](./onze/) | `modules.md`, `unification.md`, `test-snap.md`, `test-snap-examples.md` |

## What each file is

| File | Holds |
|---|---|
| `modules.md` | The package cut: `repository/<lib>/modules/**` (core, `<lib>-test`, domain submodules) and `repository/<lib>/examples/**`, with the dependency graph, the target of each submodule, what `<lib>-test` exposes, and the front → directory ownership table that `../fronts.md` copies. |
| `unification.md` | The proof that nothing was lost when the 1.0.6 / 1.0.7 / 1.0.8 drafts were merged into this milestone: per old front, what the new front carries and what had to be appended (`## Carried from …` sections in the front READMEs), plus the reference coverage rows the merge still misses. |
| `reference-coverage.md` | For emilia, whose draft closure lives in [`../../1.0.8-beta/closure.md`](../../1.0.8-beta/closure.md): the Tailwind v4 walk, section by section, against the track D fronts. |
| `test-snap.md` | The preventive snapshot-test map of the library's modules: `<lib>-test` helper signatures, test cases written in `.bp` with `@src()` and `\\` line strings, and the exact `.snap` file each one produces. |
| `test-snap-examples.md` | The same map for the library's `examples/**` projects. |

## The test contract every track writes against

Front [`96-src-builtin-and-snapshots`](../96-src-builtin-and-snapshots/README.md) specifies it;
[`std/snapshots.md`](./std/snapshots.md) and [`std/asserts.md`](./std/asserts.md) are the reference.

```bp
type SourceLocation(file: string, line: i32, column: i32, fnName: string)   // @src(), comptime

test "css: modifiers ---- hover on md breakpoint" {
    try assertCss(@src(), [.Md([.Hover([.Bg.Color.Red.500])])]);
}
```

- `snapshots.path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap`, where `suite` is the
  text before the first `": "` of the test name and `slug` is the slugified rest.
- A mismatch or a missing file writes `<path>.new` and fails the test. Nothing accepts a snapshot but
  a person renaming the `.new` file; there is no update flag.
- Every library, module and submodule owns the `__snapshots__/` beside its own tests and exposes,
  from `<lib>-test`, the `assert<Subject>(loc, …) -> @Result<void, string>` helpers that write them.
