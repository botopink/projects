# botopink-install-from-deps — `bpmp install` from `botopink.json` `dependencies` (object form with git+branch)

**Slug**: botopink-install-from-deps
**Depends on**: nothing in v0.beta.20 — file-disjoint with every other v0.beta.20 spec at the source level. Builds on v0.beta.18 `distribution` (bpmp scaffold, `BPMP_HOME`, `BOTOPINK_LIB_ROOTS`) and v0.beta.11 `libs-module-migration` (lib surface is `root.bp` + `files`).
**Files**:
  - **Schema**:
    - `repository/botopink-lang/modules/compiler-cli/src/cli/config.zig` — extend `dependencies` parser to accept both `[]const []const u8` (legacy) and `{ "<name>": DepSpec }` (new). `DepSpec` carries `git: ?[]const u8`, `branch: ?[]const u8`, `rev: ?[]const u8`, `tag: ?[]const u8`, `path: ?[]const u8`.
  - **Install command**:
    - `repository/botopink-lang/modules/bpmp/src/commands/install.zig` (NEW — replaces the `dummy` wired in `cli.zig:52`):
      - argv: `bpmp install` (no-args → read project's `botopink.json` and install all deps); `bpmp install <name>` (single dep, must exist in `botopink.json`).
      - For each declared dep: resolve `git`/`branch` (or `rev`/`tag`/`path`) → clone (or symlink, for `path:`) into `$BPMP_HOME/<name>/<rev-shortsha-or-branch>/` → record resolved commit SHA in lockfile.
    - `repository/botopink-lang/modules/bpmp/src/dep/{spec,resolver,clone}.zig` (NEW — internal helpers; one file per concern, file-disjoint from any other spec).
  - **Lockfile**:
    - `repository/botopink-lang/modules/bpmp/src/lock.zig` (NEW) — writes/reads `botopink.lock` (sibling of `botopink.json`); format = sorted JSON object `{ "<name>": { "git": "...", "rev": "<full-sha>", "fetched_at": "<ISO-8601>" } }`.
  - **Resolver hook**:
    - `repository/botopink-lang/modules/compiler-cli/src/cli/libs.zig` — extend `loadDependencies` to consult `$BPMP_HOME/<name>/<lock-rev>/` when local `libs/<name>/` and `BOTOPINK_LIB_ROOTS` lookup misses, **before** raising `LibsRootNotFound`.
  - **Migration of consumer fixtures** (one-line/few-line edits, file-disjoint):
    - `repository/emilia/examples/emilia-card/botopink.json` — object form for `jhonstart` + `emilia` (fixed + committed `af1c66d` on `emilia` feat, 2026-06-16).
    - `repository/erika/examples/erika-linq/botopink.json` — object form for `erika`.
    - `repository/jhonstart/examples/jhonstart-{counter,html,todo}/botopink.json` — object form for `jhonstart` (3 fixtures).
    - `repository/onze/examples/onze/botopink.json` — object form for `onze` + its declared deps.
    - `repository/rakun/examples/rakun/botopink.json` — object form for `rakun` + its declared deps.
    - `repository/botopink-lang/examples/generic-loader-binding/botopink.json` — object form for `erika` (consumer of `from "erika"`).
    - `repository/botopink-lang/examples/stdlib-tour/botopink.json` — already `[]`; leave (no deps).
  - **Tests**:
    - `repository/botopink-lang/modules/compiler-cli/src/cli/tests/config_deps.zig` (NEW) — parser accepts both schemas; rejects malformed forms (DEP-001/DEP-002/DEP-003 below).
    - `repository/botopink-lang/modules/bpmp/src/tests/install_dryrun.zig` (NEW) — `bpmp install --dry-run` resolves deps from a fixture `botopink.json` without touching disk.
  - **Snapshots**:
    - `repository/botopink-lang/modules/compiler-cli/snapshots/cli/install_e2e.snap.md` (NEW) — full smoke: scratch project + 1 git dep + `bpmp install --offline-fixture <local-bare-repo>` + `botopink build`.
**Touches docs**:
  - `repository/botopink-lang/modules/bpmp/AGENTS.md` (new `install` section; `dummy` → real wiring)
  - `repository/botopink-lang/modules/bpmp/docs.md` (user-facing schema table + lockfile semantics + `$BPMP_HOME` layout)
  - `repository/botopink-lang/modules/compiler-cli/src/cli/AGENTS.md` (`config.zig` row: object-form `dependencies`; `libs.zig` row: `$BPMP_HOME` fallback)
  - `repository/botopink-lang/AGENTS.md` (one bullet under the **Project surface** §)
  - `tasks/v0.beta.20/status.md` (this row reaches **done** when F0–F6 land)
**Status**: **pending (F0–F2, F4–F6); F3 DONE** — spec authored 2026-06-16 in `325472a`. F3 complete (8/8 consumer fixtures on object form): emilia-card (`af1c66d`), erika-linq (`abfcfe4`), jhonstart-{counter,html,todo} (`7a9b0ae`), onze (`ab7788b`), rakun (`ee798f8`), generic-loader-binding (`3aecd65`). All other phases unstarted.

## Premise

`bpmp install` is currently a `dummy` handler (`modules/bpmp/src/cli.zig:52` wires
the name to a no-op). Every project today either bundles its dep source via
git submodule (the meta workspace's pattern) or relies on the resolver
finding `libs/<name>/` on a shared parent (`BOTOPINK_LIB_ROOTS`). For
**external consumers** of botopink libs (e.g. `repository/emilia/examples/emilia-card/`,
which depends on `jhonstart` + `emilia` — both published on GitHub), there
is no first-class way to declare *where* a dep lives or *which ref* of it
to consume. The botopink.json `dependencies` field today is an array of
bare names — pure resolver hint, no source coordinates.

The schema below makes the source coordinates first-class and lets
`bpmp install` materialise them deterministically into `$BPMP_HOME`,
shared across projects on the same host.

## Schema

```json
{
  "name": "emilia-card",
  "version": "0.0.1",
  "target": "commonJS",
  "dependencies": {
    "jhonstart": {
      "git": "https://github.com/botopink/jhonstart.git",
      "branch": "feat"
    },
    "emilia": {
      "git": "https://github.com/botopink/emilia.git",
      "branch": "feat"
    }
  }
}
```

**`DepSpec` fields** (at least one of `git`/`path` required; `branch`/`rev`/`tag` mutually exclusive — `branch` wins if both present, with a DEP-003 warning):

| Field | Type | Meaning |
|---|---|---|
| `git` | `string` | Clone URL (HTTPS or SSH). Mandatory when no `path`. |
| `branch` | `string` | Branch to track; resolved to the tip-commit SHA at install time, recorded in lockfile. |
| `rev` | `string` | Pinned commit SHA (40-char). Overrides `branch`. |
| `tag` | `string` | Pinned annotated tag. Overrides `branch`. |
| `path` | `string` | Local path (absolute or relative to project root). Bypasses clone — `bpmp install` symlinks. Mutually exclusive with `git`. |

**Legacy form preserved**: `"dependencies": ["foo", "bar"]` still parses
(array of bare names → resolver-only, no install). Config loader normalises
both forms into `[]DepEntry { name, spec: ?DepSpec }` internally.

## Lockfile (`botopink.lock`)

Plain JSON, sibling of `botopink.json`, machine-written by `bpmp install`:

```json
{
  "generated_by": "bpmp 0.0.1",
  "lockfile_version": 1,
  "deps": {
    "jhonstart": {
      "git": "https://github.com/botopink/jhonstart.git",
      "rev": "0691d0b2cce78c11512aaa18bbf7a2bc95ec0e96",
      "fetched_at": "2026-06-16T18:00:00Z"
    },
    "emilia": {
      "git": "https://github.com/botopink/emilia.git",
      "rev": "10ea69eef3a2693fa6ddafb905312155a45a1897",
      "fetched_at": "2026-06-16T18:00:00Z"
    }
  }
}
```

- Lockfile **wins** over `branch` resolution on subsequent installs (reproducible builds).
- `bpmp install --update` re-resolves branches and rewrites the lockfile.
- `bpmp install --frozen` errors if any dep has no lockfile entry (CI mode).

## Disk layout

Two concerns kept separate: a global content-addressable store (one
checkout per resolved commit, shared across projects on the host) and a
project-local `.botopinkbuild/deps/` directory of symlinks (one entry per
declared dep, resolved from the project's lockfile).

### Global store — `$BPMP_HOME/` (one host, many projects)

```
$BPMP_HOME/
  store/
    <name>/
      <full-rev-40>/            # immutable checkout from <git> at <rev>
        botopink.json
        root.bp
        src/…
        …
  index.json                    # { "<name>": { "<rev>": "<fetched_at-ISO>" } }
```

- **CAS semantics**: the leaf directory `<name>/<rev-40>/` is keyed by
  the resolved commit SHA, so two projects depending on the same
  `(<name>, <rev>)` share the checkout.
- **Immutable**: once a checkout lands, it is never mutated in place.
  Re-resolution writes a new sibling under `<name>/<other-rev-40>/`.
- **GC**: `bpmp gc` (out of scope here — separate v21 spec) prunes
  entries not referenced by any lockfile under `$BPMP_HOME/projects-index/`.
- **Default `$BPMP_HOME`**: `${XDG_CACHE_HOME:-$HOME/.cache}/bpmp`.

### Project layout — `.botopinkbuild/deps/` + `botopink.lock`

```
<project>/
  botopink.json
  botopink.lock                 # generated by `bpmp install`
  .botopinkbuild/
    deps/
      <name>  ->  $BPMP_HOME/store/<name>/<rev-from-lockfile>/
      <name2> ->  $BPMP_HOME/store/<name2>/<rev2>/
      …
  src/…
```

- One symlink per declared dep, target = the store path implied by
  `botopink.lock`. Created fresh on every `bpmp install` (existing
  symlinks are unlinked and rewritten — safe because they point into
  the immutable store).
- `.botopinkbuild/deps/` is **`.gitignore`d** (already ignored as part
  of the existing `.botopinkbuild/` rule).
- Read-only from the compiler's perspective: the resolver never writes
  into this tree.

### Resolver lookup order in `libs.zig:loadDependencies`

1. Project-local `libs/<name>/` (existing behaviour — kept for the meta
   workspace, where libs are first-class siblings, not deps).
2. Each entry of `BOTOPINK_LIB_ROOTS` (existing behaviour).
3. **New**: `<project>/.botopinkbuild/deps/<name>/` (this spec — primary
   path for object-form deps; resolves via the per-project symlink).
4. **New (fallback)**: `$BPMP_HOME/store/<name>/<lockfile-rev>/` directly
   (used when `.botopinkbuild/deps/` was deleted by `clean` but lockfile
   is still authoritative — avoids re-symlinking on a check-only path).
5. Error `LibsRootNotFound` (existing — message gains a `bpmp install` hint).

## Diagnostics

| Code | Trigger | Message shape |
|---|---|---|
| **DEP-001** | `dependencies` is neither an array of strings nor an object of `DepSpec` | `botopink.json:dependencies: must be string-array (legacy) or object of <name>: { git, branch?, rev?, tag?, path? }` |
| **DEP-002** | A `DepSpec` has neither `git` nor `path` | `botopink.json:dependencies.<name>: must declare 'git' or 'path'` |
| **DEP-003** | Multiple ref fields present (`branch` + `rev`, etc.) | `botopink.json:dependencies.<name>: 'rev'/'tag' wins over 'branch'; remove the ambiguity` (warning, not error) |
| **DEP-004** | `bpmp install --frozen` finds a dep without a lockfile entry | `botopink.lock: missing entry for <name>; run 'bpmp install' first` |
| **DEP-005** | Network/clone failure | `bpmp install <name>: failed to clone <git>: <git-error>` |

## DAG

```
01-keystones (3, parallel)
  F0-schema      (config.zig parser + DepSpec + DEP-001/002/003 diagnostics + tests)
  F1-bpmp-install (commands/install.zig + dep/{spec,resolver,clone}.zig + lock.zig)
  F2-resolver-hook (libs.zig $BPMP_HOME fallback + LibsRootNotFound message)

02-consumers
  F3-fixture-migration  ← F0 + F2 (emilia-card + generic-loader-binding to object form)
  F4-snapshot           ← F1 + F2 (install_e2e.snap.md offline-fixture smoke)
  F5-frozen-mode        ← F1 (--frozen flag + DEP-004 + CI hint)

03-closeout
  F6-agents-docs (AGENTS.md sweep + docs.md user-facing table + status.md row → done)
```

---

## F0 — schema (parser + DepSpec + DEP-001/002/003)

**Files**: `compiler-cli/src/cli/config.zig` · `compiler-cli/src/cli/tests/config_deps.zig` (NEW).
**Status**: pending.

Replace the field type with a normalised representation:

```zig
pub const DepRef = union(enum) {
    branch: []const u8,
    rev: []const u8,
    tag: []const u8,
    none,
};

pub const DepSpec = struct {
    git: ?[]const u8 = null,
    path: ?[]const u8 = null,
    ref: DepRef = .none,
};

pub const DepEntry = struct {
    name: []const u8,
    spec: ?DepSpec = null, // null = legacy bare-name form
};

dependencies: []DepEntry = &.{},
```

Parser branches on JSON node type:
- **Array** → each element must be string → `DepEntry { name, spec=null }`.
- **Object** → each pair = name + DepSpec; reject anything else with DEP-001.

Tests (`tests/config_deps.zig`) cover: legacy array, new object, mixed
absent dep block, DEP-001 on a malformed mix, DEP-002 on a spec without
`git`/`path`, DEP-003 warning on `branch`+`rev`.

---

## F1 — `bpmp install`

**Files**:
  - `modules/bpmp/src/commands/install.zig` (NEW)
  - `modules/bpmp/src/dep/spec.zig` (NEW — `DepSpec` mirrors `config.zig` for use without the compiler-cli dep)
  - `modules/bpmp/src/dep/clone.zig` (NEW — wraps `git clone --depth 1 --branch <branch>` then `git rev-parse HEAD` to capture the SHA; symlink path for `path:`)
  - `modules/bpmp/src/dep/resolver.zig` (NEW — given a `DepSpec`, computes the install target path under `$BPMP_HOME/<name>/<short-sha>/` and the lockfile entry)
  - `modules/bpmp/src/lock.zig` (NEW — read/write `botopink.lock`)
  - `modules/bpmp/src/cli.zig` — flip `install` row from `.run = dummy` to `.run = install.run`.
**Status**: pending.

CLI surface:

```
bpmp install            # all deps from project's botopink.json
bpmp install <name>     # single dep
bpmp install --update   # re-resolve branches, rewrite lockfile
bpmp install --frozen   # error if lockfile incomplete (DEP-004)
bpmp install --dry-run  # print plan, no clone
```

Failure mode: a transient network failure (`DEP-005`) leaves any partial
clone behind under `$BPMP_HOME/<name>/.tmp-<pid>/`; the resolver retries
on next invocation by detecting the `.tmp-` prefix and rm-rf-ing it.

---

## F2 — resolver hook (`$BPMP_HOME` fallback in `libs.zig`)

**Files**: `compiler-cli/src/cli/libs.zig` · `compiler-cli/src/cli/AGENTS.md`.
**Status**: pending.

Extend `loadDependencies` to consult `$BPMP_HOME/<name>/<lockfile-rev>/`
after the existing `libs/<name>/` + `BOTOPINK_LIB_ROOTS` lookups and
before raising `LibsRootNotFound`. The lockfile is parsed once per
invocation (small JSON, no caching needed). When the project has no
lockfile, this fallback is silently skipped.

`LibsRootNotFound` message gains a hint:

```
project declares dependencies but no libs/ directory was found in this or
any parent directory. If your botopink.json uses the new object form
({"<name>": {"git": ...}}), run `bpmp install` to fetch deps into
$BPMP_HOME first.
```

---

## F3 — consumer fixture migration

**Files**:
  - `repository/emilia/examples/emilia-card/botopink.json` (`emilia af1c66d`)
  - `repository/erika/examples/erika-linq/botopink.json` (`erika abfcfe4`)
  - `repository/jhonstart/examples/jhonstart-{counter,html,todo}/botopink.json` (`jhonstart 7a9b0ae`)
  - `repository/onze/examples/onze/botopink.json` (`onze ab7788b`)
  - `repository/rakun/examples/rakun/botopink.json` (`rakun ee798f8`) — `rakun` + `server` both shifted to object form; `server` keeps the canonical `https://github.com/botopink/server.git, feat` shape pending its eventual publish (still resolves via `BOTOPINK_LIB_ROOTS` → `libs/server/`).
  - `repository/botopink-lang/examples/generic-loader-binding/botopink.json` (`botopink-lang 3aecd65`)
**Status**: **DONE** — 8/8 consumer fixtures shifted from legacy bare-name array to the new `{ "<name>": { "git": ..., "branch": ... } }` schema across the 5 submodules touching consumer examples. Schema-only change; resolver behaviour unaffected until F0 (parser) and F2 (`$BPMP_HOME` fallback) land.

---

## F4 — install snapshot (offline-fixture smoke)

**Files**: `modules/compiler-cli/snapshots/cli/install_e2e.snap.md` (NEW).
**Status**: pending.

End-to-end: scratch project under `.tmp-exec-*/` with a `botopink.json`
referencing a *local bare repository* (created in-fixture, no network)
+ `bpmp install --offline-fixture <bare-repo>` resolves → `botopink build`
type-checks the import.

---

## F5 — `--frozen` mode + DEP-004

**Files**: `modules/bpmp/src/commands/install.zig` (DEP-004 path) ·
  `modules/compiler-cli/src/cli/tests/config_deps.zig` (additional case).
**Status**: pending.

`bpmp install --frozen` is the CI mode: errors with DEP-004 if any
declared dep is missing from `botopink.lock`. Pairs with
`bpmp install --update` for local re-resolution.

---

## F6 — AGENTS.md + docs sweep + closeout

**Files**: `modules/bpmp/{AGENTS.md, docs.md}` · `compiler-cli/src/cli/AGENTS.md` ·
  `repository/botopink-lang/AGENTS.md` · `tasks/v0.beta.20/status.md`.
**Status**: pending.

## Exit gate

- `bpmp install` clones `emilia-card`'s 2 deps (`jhonstart`, `emilia`) into `$BPMP_HOME/`.
- `botopink build` in `repository/emilia/examples/emilia-card/` resolves both deps without `libs/` on disk.
- `botopink.lock` round-trips through `--frozen` and `--update`.
- DEP-001…DEP-005 fire on the right shapes; tests pin them.
- Legacy `[…]` array form still works (no breaking change).
- AGENTS.md per affected module updated in the same commit as the code.
