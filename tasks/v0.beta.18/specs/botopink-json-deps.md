# botopink.json deps + BOTOPINK_LIB_ROOTS — manifest gets versions, resolver gains an env hook

**Slug**: botopink-json-deps
**Depends on**: nothing
**Files**: `modules/compiler-cli/src/cli/libs.zig`, `modules/language-server/src/project_graph.zig`, `modules/lib-test-runner/src/discovery.zig`, plus their unit tests
**Touches docs**: `modules/compiler-cli/AGENTS.md`, `modules/language-server/AGENTS.md`, `modules/lib-test-runner/AGENTS.md`, new `docs/botopink-json.md`, root `AGENTS.md` (link the schema doc)
**Status**: pending

## Problem

bpmp (v0.beta.18 spec [`bpmp`](bpmp.md)) needs two things from the compiler:

1. **A place in `botopink.json` to record dependency versions.** Today the
   manifest carries `name`/`version`/`src`/`files`/`dependencies: [string,…]`/
   `target`/`description` (see `repository/erika/botopink.json`, the schema
   the loader assumes — `LibManifest` in `libs.zig:20` only reads `src` and
   `files`; `dependencies` is consumed in
   `modules/compiler-cli/src/cli/resolver.zig`). There is no field that says
   "I want erika at `^0.0.1`" or "this project requires botopink ≥ 0.0.1".
2. **A way to tell the compiler where to look for an installed package
   without symlinking it into `libs/`.** Today the only inputs to
   `resolveLibRoots` (`libs.zig:45`) are the cwd walk-up and the three
   directory patterns hardcoded in `rootsFrom` (`libs.zig:53`). bpmp installs
   into `$BPMP_HOME/packages/<name>/versions/<ver>/`, which matches none of
   those patterns. The only zero-symlink options are (a) a config file the
   resolver reads, or (b) an environment variable. (b) is one line per
   resolver, lives in `bpmp`'s spawn-environment, leaves no on-disk artefact
   to clean up, and matches the pattern `PATH`/`LD_LIBRARY_PATH` set
   industry-wide. We pick (b).

This spec is the keystone for bpmp. It is **purely additive** — every existing
test, every existing `botopink.json`, every existing user invocation continues
to behave byte-identically. The compiler does not learn what a "version" is;
it learns to (a) ignore two more optional fields without complaint (it already
does — `LibManifest` only reads `src`/`files`), and (b) prepend an env-var's
roots before the walk-up roots.

## Target schema (`botopink.json`)

```jsonc
{
  // ── existing fields (unchanged) ─────────────────────────────────────────
  "name":         "myapp",            // string,        required for a project
  "version":      "0.1.0",            // string,        recommended
  "description":  "…",                // string,        optional
  "target":       "commonJS",         // string,        optional
  "src":          "src/",             // string,        default "src/"
  "files":        ["root.bp"],        // string[],      libs only
  "entry":        "src/main.bp",      // string,        projects only
  "dependencies": ["erika"],          // string[],      compiler-side, name-only

  // ── new in v0.beta.18 (all optional, compiler ignores) ──────────────────
  "botopink":     ">=0.0.1",          // string,        minimum compiler tag (SemVer constraint)
  "requires":     {                   // object,        per-dep version constraint
    "erika":     "^0.0.1",
    "jhonstart": "0.1.0",
    "onze":      "*"
  }
}
```

Both new fields are **optional**. bpmp reads `requires` to drive resolution
and writes `botopink` so a user with the wrong compiler version gets a clear
error. The compiler **never** parses `botopink` or `requires` — it parses
`src`/`files` (loader) and forwards `dependencies` to the lib loader. So all
the work in this spec is (i) a docs-only schema bump, (ii) a one-line tolerance
check that unknown fields do not error (verify, don't change), and (iii) the
env-var hook in the three resolvers.

## Resolver behaviour change — exactly one new step

Before this spec:

```text
roots(cwd) = walk_up(cwd, [repository/botopink-lang/libs, repository, libs])
```

After:

```text
roots(cwd) =
    parse_env_roots(BOTOPINK_LIB_ROOTS)        // NEW — empty when env unset
 ++ walk_up(cwd, [repository/botopink-lang/libs, repository, libs])
 → de-duplicated, env entries first
```

`parse_env_roots`:

```text
parse_env_roots(s) =
  if s is unset or empty → []
  split s on PATH_SEPARATOR   (`:` on POSIX, `;` on Windows)
  drop empty entries
  resolve each to an absolute path (no fs check — non-existent roots are dropped silently, NOT an error)
  return in order
```

Why "drop silently": an `$BPMP_HOME` that has not been initialised yet must
not be a hard error for `botopink` — the user might be running the compiler
on a project with no packages and no bpmp configured at all. The walk-up roots
still fire; resolution proceeds.

## Examples

### env unset → byte-identical to today
```bash
$ unset BOTOPINK_LIB_ROOTS
$ botopink build src/main.bp
# resolveLibRoots returns exactly what it does today — walk_up only.
```

### env set → bpmp's store wins
```bash
$ BOTOPINK_LIB_ROOTS=/home/u/.bpmp/packages/erika/versions/0.0.1:/home/u/.bpmp/packages \
  botopink build src/main.bp
# `from "erika"` finds .../erika/versions/0.0.1/botopink.json before any walk_up root.
# `from "jhonstart"` finds .../packages/jhonstart/botopink.json (second env entry's lookup) — wait, no:
# env entries are *root* directories. bpmp lays packages out as one root per name (each version
# dir contains the lib's botopink.json directly), so bpmp sets the env to a colon-separated list
# where each entry IS a single-lib root (`.../packages/erika/versions/0.0.1`). See bpmp.md §"Env wiring".
```

### env set to a non-existent dir → no error, walk_up still wins
```bash
$ BOTOPINK_LIB_ROOTS=/tmp/nope botopink build src/main.bp
# /tmp/nope is dropped silently. Resolution proceeds as if env were unset.
```

### `requires` present, `dependencies` absent → still loads nothing
```jsonc
{ "name": "x", "version": "0.1.0", "requires": { "erika": "^0.0.1" } }
```
The compiler reads `dependencies` (empty / absent → loads nothing).
`requires` is metadata for bpmp; compilation does not consume it. If the user
ran `botopink` directly without `bpmp install` first, the project compiles
without erika — and any `import` from erika fails at name-resolution time, as
it does today.

### `botopink: ">=0.0.1"` present, current compiler is older → bpmp errors at install-time, not compiler-time
The compiler does not read `botopink`. bpmp's `install` command does — see
[`bpmp` §"Compiler version check"](bpmp.md). The compiler stays oblivious by
design: the constraint is a *deployment* concern, not a *compilation* concern.

## Steps

> Each step is one checkbox in `.tasks/botopink-json-deps/TODO.md` once the
> worktree exists.

### F0 — env-var hook in compiler-cli
- [ ] Add `parseEnvRoots(gpa, io) ![][]const u8` to `libs.zig`. Reads
      `BOTOPINK_LIB_ROOTS`; splits on `:` (POSIX) / `;` (Windows) via
      `std.fs.path.delimiter`; resolves each to abs; drops non-existent and
      empty entries; returns owned slice.
- [ ] Edit `resolveLibRoots` (`libs.zig:45`) to *prepend* env entries to the
      walk-up result, then run the same de-dup pass over the combined list.
      Keep `rootsFrom` semantics unchanged for the walk-up half.
- [ ] Add tests (in `libs.zig` `test {}` blocks): env unset → identical to
      current behaviour; env set to a synthetic two-root tmp tree → env
      entries appear first; env set with a non-existent dir → silently
      dropped; env set with a duplicate of a walk-up root → de-duped, env
      copy wins (kept first).

### F1 — mirror in language-server
- [ ] `project_graph.zig` has its own root-list producer (mirrors libs.zig).
      Apply the same `parseEnvRoots` prepend. **Same env var name** — the
      LSP and the CLI must see identical roots, or "go to definition" will
      misroute.
- [ ] Test in `language-server/tests/project_graph_test.zig` (or equivalent):
      env-set scenario matches a CLI-spawn scenario.

### F2 — mirror in lib-test-runner
- [ ] `discovery.zig`'s root walker (mirrors libs.zig) gets the same prepend.
- [ ] Add an `args.zig` flag `--lib-root <dir>` (repeatable) that **appends**
      to the env-derived roots, for ad-hoc CI use without mutating env.
      Plumbed through to `discovery.discover`. Optional.
- [ ] Test that `botopink-lib-test --lib-root /tmp/store --lib foo` finds
      `/tmp/store/foo/botopink.json`.

### F3 — schema documentation
- [ ] New file `repository/botopink-lang/docs/botopink-json.md` — the full
      schema, every field, every default, every optionality, plus the
      `botopink`/`requires` additions. Linked from root `AGENTS.md` under a
      new "Manifest schema" heading.
- [ ] `modules/compiler-cli/AGENTS.md` gains an explicit note: "**Unknown
      fields are ignored.** `LibManifest` reads only `src` and `files`; adding
      a new field to `botopink.json` requires no change here."
- [ ] `modules/compiler-cli/AGENTS.md` documents the `BOTOPINK_LIB_ROOTS` env
      contract (path separator, silent-drop, prepend order, intent) — under a
      new "Env" subsection.
- [ ] Same env section mirrored in `language-server/AGENTS.md` and
      `lib-test-runner/AGENTS.md`.

### F4 — proof of equivalence
- [ ] CI gate or scripted check: with `BOTOPINK_LIB_ROOTS` unset, `zig build
      test` is **byte-identical** to its v0.beta.17 result. No snapshot moves.
      No example output changes.

## Test scenarios

```
unit  ---- libs.zig: env unset, walk_up only — current roots returned
unit  ---- libs.zig: env set, two existing dirs — both prepended, walk_up follows
unit  ---- libs.zig: env entry does not exist — silently dropped, no error
unit  ---- libs.zig: env entry duplicates a walk_up root — de-duped, env copy first
unit  ---- libs.zig: env empty string ("") — treated as unset
unit  ---- libs.zig: env has trailing empty entry ("a::") — entry dropped, "a" kept
unit  ---- project_graph.zig: env-set behaviour matches libs.zig
unit  ---- discovery.zig: env-set behaviour matches libs.zig
unit  ---- discovery.zig: --lib-root flag appends after env-derived roots
intg  ---- compile a synthetic project where erika lives ONLY under an env root — succeeds
intg  ---- compile the same project with env unset — fails with the existing LibNotFound
intg  ---- LSP "go to definition" on `from "erika"` with env set follows the env root
intg  ---- zig build test on v0.beta.17 main vs this branch with env unset — byte identical snapshots
```

## Notes

- **Why prepend, not append?** Because bpmp's whole job is to be the source
  of truth for a project's dependencies. If a project has a vendored `libs/`
  next to bpmp packages, bpmp's choice must win — the user explicitly opted
  into bpmp.
- **Why silent-drop non-existent roots?** A typo in a user's
  `BOTOPINK_LIB_ROOTS` should not break compilation that does not use any
  package from that root. The walk-up still finds packages; if anything is
  missing, `LibNotFound` fires with the same message it does today.
- **De-dup tie-break.** First-occurrence wins (matching current behaviour
  for walk-up). Env entries are scanned before walk-up, so a duplicate is
  always resolved to the env copy.
- **Schema validation is out of scope.** This spec adds *fields*; it does
  not add a JSON Schema validator. bpmp's `botopink.json` writer guarantees
  the shape on write, and the compiler's loader still uses its existing
  permissive parser. A separate `botopink validate` command (post-v18) can
  reject malformed manifests.
- **The `botopink` field is a constraint, not a literal version.** `bpmp use
  botopink <ver>` writes the literal selected version into the lockfile, not
  into `botopink.json`. The manifest field stays a *constraint* so it does
  not need rewriting every time the toolchain ticks.
- **Cross-spec coordination.** This spec must merge **before** [bpmp](bpmp.md)
  — bpmp's "spawn `botopink` with env" step is meaningless without the hook.
  No coordination needed with [release-workflows](release-workflows.md) (file
  disjoint), [install-script](install-script.md), or
  [lib-test-workflows](lib-test-workflows.md).
