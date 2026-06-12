# v0.beta.18 — plan (reasoning scratchpad)

Mutable. The set's *why*, the blast-radius survey the five specs derive from,
and the small set of decisions that shape every spec. Authored intent lives in
`specs/`; this file is the thinking around them.

## Premise

Until v0.beta.17 the language was a single git tree: clone, `zig build`, run.
v17 turned that tree into a `repository/` workspace of one project per
directory; v18 is the *consequence* — once frameworks are sibling projects, you
need a way to **declare** which framework you want at which version, **find**
its source on disk without hand-symlinking, **install** the toolchain without
cloning, and **CI** each repo independently. So this set is five orthogonal
infrastructure pieces, each a one-shot keystone.

## What's already true (v0.beta.17)

These facts are load-bearing for every spec and are stated here once so the
specs themselves don't repeat them:

- The compiler's lib resolver is **already multi-root**:
  `resolveLibRoots` (`modules/compiler-cli/src/cli/libs.zig:45`) walks up from
  cwd and collects `D/repository/botopink-lang/libs`, `D/repository`, and
  `D/libs`, nearest-first, de-duped. The language server mirrors this in
  `project_graph.zig`; `botopink-lib-test` mirrors it in `discovery.zig`.
- The compiler's lib loader **already reads `botopink.json`**, but only two
  fields: `src` (default `"src/"`) and `files: [".bp", …]`
  (`LibManifest`, `libs.zig:20`). Unknown fields are ignored — schema additions
  are safe by construction.
- A project's `dependencies` field is **a flat array of strings** (names only),
  consumed by `loadDependencies` (`libs.zig:106`). Rakun uses
  `"dependencies": ["server"]`. No version metadata exists in the schema today.
- Tarball naming and target tuples have **never been established** — there
  are no releases to constrain a convention. v18 sets the convention.

## The big decisions, recorded here so every spec is consistent

### D1. `botopink.json` shape, additive only

`dependencies` stays a string array — it is the runtime resolution input, and
breaking it would break every existing lib. **Version metadata is added as
parallel optional fields**, ignored by the compiler:

```jsonc
{
  "name": "myapp",
  "version": "0.1.0",
  "botopink": ">=0.0.1",          // NEW — min compiler version (bpmp+install-script)
  "src": "src/",
  "files": ["root.bp"],
  "dependencies": ["erika"],       // unchanged — compiler reads this
  "requires": {                     // NEW — bpmp reads this
    "erika": "^0.0.1"
  }
}
```

`requires` is optional. When absent, bpmp treats every name in `dependencies`
as `"*"` — bpmp will refuse to install without an explicit version unless
`--allow-unlocked` is passed. The compiler never reads `requires` or
`botopink`. (Why not embed version in the array as `"erika@^0.0.1"`? Because
the compiler's loader splits on the array element directly and we want zero
parser surgery there.)

### D2. `BOTOPINK_LIB_ROOTS` — the one compiler hook bpmp needs

Without it, bpmp would have to symlink installed packages into `libs/`. Symlinks
on Windows require admin or developer mode; junction points are clunky; both
break `git status`. So the resolver gains a single environment-variable hook:

```text
roots(cwd) =
  [ parse(BOTOPINK_LIB_ROOTS), split on path separator, kept in order ]
  ++ existing walk-up roots
```

When `BOTOPINK_LIB_ROOTS` is unset (the default — every existing test,
checkout, IDE session), behaviour is byte-identical. When set, bpmp puts
`$BPMP_HOME/packages` first, and `from "<name>"` finds the installed package
before any other root. **Path separator is `:` on POSIX, `;` on Windows** —
matches `PATH`. Trailing empty entries are dropped silently.

The hook lives in three files in lockstep — `compiler-cli/src/cli/libs.zig`,
`language-server/src/project_graph.zig`, `lib-test-runner/src/discovery.zig`.
The `botopink-json-deps` spec covers all three under one branch so they cannot
drift.

### D3. Targets — exactly these five

| Tuple | Zig target string | Archive |
|---|---|---|
| `linux-x86_64` | `x86_64-linux-gnu` | `.tar.gz` |
| `linux-aarch64` | `aarch64-linux-gnu` | `.tar.gz` |
| `macos-x86_64` | `x86_64-macos` | `.tar.gz` |
| `macos-aarch64` | `aarch64-macos` | `.tar.gz` |
| `windows-x86_64` | `x86_64-windows-gnu` | `.zip` |

`linux-musl` and `windows-aarch64` are deliberately out — neither is on Eric's
short list and dropping them halves CI minutes. Either can be added later by
appending one matrix entry; no spec changes.

### D4. Tarball naming + URL convention

```text
<binary>-<version>-<target>.<ext>          # the artifact
<binary>-<version>-<target>.<ext>.sha256   # 64-hex-char sidecar (one line, no newline)
```

`<binary>` is one of `botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp`.
`<version>` is the git tag (`v0.0.1`). Asset URLs:

```
https://github.com/botopink/botopink-lang/releases/download/<tag>/<file>
https://github.com/botopink/botopink-lang/releases/latest/download/<file>     # GH-hosted alias
```

This is the **only** URL shape bpmp and the install script know. No registry
index needed — the tag itself is the index.

### D5. `$BPMP_HOME` layout — exactly as Eric specified

```text
$BPMP_HOME/                                  # default: $HOME/.bpmp  (Windows: %USERPROFILE%\.bpmp)
├── bin/
│   └── bpmp                                 # shim → active version's bpmp
├── botopink/
│   └── versions/
│       ├── v0.0.1/
│       │   ├── botopink
│       │   ├── botopink-lsp
│       │   ├── botopink-lib-test
│       │   └── bpmp
│       ├── dev/                             # local "zig build install" overlay
│       └── stable -> v0.0.1                 # symlink (junction/copy on Windows)
├── packages/
│   └── erika/
│       └── versions/
│           └── 0.0.1/
│               ├── botopink.json            # the package's own manifest, verbatim
│               └── src/                     # whatever the lib ships
├── cache/
│   └── <sha256>.{tar.gz,zip}                # download cache, content-addressed
└── lock
```

`$BPMP_HOME/lock` is a fs-level flock for cross-process safety (no two `bpmp
install` runs touching the same package directory). Project-local vendoring
(a `bpmp/` directory beside `botopink.json` with the same layout) is supported
via `bpmp install --vendor` but not the default — the default is the shared
home store for cache reuse across projects.

### D5b. Lockfile pins commit SHA, not tag — file is `botopink.lock.json`

`bpmp` writes `botopink.lock.json` (sibling of `botopink.json`, explicit
`.json` extension). Every locked package records `{version, commit, tag,
constraint, sha256, source, requires}` where:

- `version` and `tag` are *informational* — they're what `bpmp list`
  prints to humans.
- **`commit` is the immutable pin.** Lockfile replay (`bpmp install`
  with no args) fetches from
  `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz` —
  **never** via `archive/refs/tags/<tag>.tar.gz`. The latter would
  drift the moment a feat tag moved (D10).
- `sha256` is recomputed on the downloaded bytes — a mismatch is a
  hard error (cache poisoning / network corruption catcher).
- `constraint` is the literal `requires.<name>` string at resolve time,
  kept for explainability in `bpmp list` / `bpmp sync` drift output.

Only `bpmp sync` advances the commit pin — by re-resolving the
manifest's `requires` constraints to the current highest matching tag
and recording the tag's current commit. `bpmp install <name>` only adds
new pins; it never moves existing ones.

### D6. SemVer subset bpmp implements

```text
constraint   := "*"
              | exact_version             // "0.1.0"  →  exactly 0.1.0
              | "^" version               // "^0.1.0" →  >=0.1.0, <0.2.0  (0.x: minor bumps)
              | "~" version               // "~0.1.0" →  >=0.1.0, <0.2.0
              | ">=" version              // "≥"
```

Selection rule: **highest tag on the project's GitHub Releases page satisfying
the constraint**. No backtracking, no SAT solver — if two packages disagree on
a common transitive dep, bpmp fails with a *report* (which package asks for
which range) and the user pins manually in `requires`. This is enough for v18;
the language and ecosystem are too young to need Cargo-grade resolution.

### D7. Self-update mechanism

`bpmp self update` queries the GitHub Releases API for the latest release of
`botopink/botopink-lang`, downloads `bpmp-<latest>-<target>.tar.gz` into the
cache, verifies the sha256, extracts to `$BPMP_HOME/botopink/versions/<v>/`,
and updates `stable`. To replace the **currently running** bpmp binary it
writes the new binary to `$BPMP_HOME/bin/bpmp.new`, then atomically renames
`bpmp.new` → `bpmp`. On POSIX this is safe even while the old bpmp is running
(open file handle survives the rename). On Windows it stages the swap by
spawning a tiny `cmd /c` helper that runs after the current bpmp exits — same
trick rustup uses.

### D8. Install-script vs `bpmp self update` — when each runs

- `install.sh` (rustup-style) — **bootstrap**. The user has no bpmp yet; one
  curl line downloads bpmp + the toolchain + creates `$BPMP_HOME`.
- `bpmp self update` — **subsequent**. The user already has bpmp; updates
  bpmp itself plus optionally the active compiler.
- Re-running `install.sh` over an existing `$BPMP_HOME` **fails** with a
  pointer to `bpmp self update` (unless `BOTOPINK_INSTALL_FORCE=1`). This
  prevents accidental clobber and gives a single place to look for upgrade
  surprises.

### D9. Lib repos: CI, not releases

Eric ruled out release artifacts for the four framework libs:

> erika, jhonstart, onze, rakun não precisa gerar nem target só adicione
> actions para testes unitários em vários targets

So `lib-test-workflows.md` produces one `.github/workflows/test.yml` per lib
and **does not** add a release workflow there. `bpmp install erika` reaches
the lib's repo by git tag (`git archive` over GitHub's `tarball/<tag>`
endpoint), not by hitting a release page. This keeps lib repos lean. If a lib
later wants release-side-cars (signed tarballs, changelog), it's a one-spec
follow-up.

### D10. Auto-tagging the lib repos on push

Eric also asked for **automatic git tagging on push**:

> crie tags automaticas ao subir repository/erika /jhonstart /onze /rakun
> 0.0.1-feat para master e main 0.0.1

The convention:

| Push to | Tag | Mutability |
|---|---|---|
| `feat`           | `<version>-feat`    | **moving** — force-updated on every push to feat |
| `master` or `main` | `<version>`         | **immutable** — created once; subsequent pushes that would re-tag the same version are no-ops |

`<version>` is read from the lib's own `botopink.json` (the existing `version`
field — no new schema). This means every push gets a stable, addressable git
ref:

- `bpmp install erika` (no version) resolves through `requires` →
  `^0.0.1` → highest tag matching → `0.0.1` (the master tag).
- `bpmp install erika@feat` resolves to the moving `0.0.1-feat` tag —
  always the latest feat HEAD.
- `bpmp install erika@0.0.1` resolves to the immutable master tag.

Why **moving** on feat: feat is the development branch (where Eric works in
parallel), `<version>-feat` is the "edge" alias. A new tag per push would
flood the tag list; one moving tag stays clean. SemVer treats the `-feat`
suffix as a *pre-release* (lower-precedence than the stable `0.0.1`), so
bpmp's constraint solver picks the stable tag by default unless a user
explicitly asks for the pre-release.

Why **immutable** on master/main: a published version must not change under
users. If the lib's `botopink.json` bumps to `0.0.2` and master is pushed,
a new `0.0.2` tag is created; the old `0.0.1` tag stays put on its commit.
If the version field is *not* bumped and master is pushed again, the workflow
skips re-tagging (warns, exits 0).

Both `master` and `main` are accepted because none of the four lib repos has
standardised — some use one, some the other.

This is a small, focused workflow (`tag.yml` in each lib repo); folded into
[`lib-test-workflows`](specs/lib-test-workflows.md) since it lives in the same
four repos and shares no files with anything else in this set.

## What stays out (and why)

- **Cosigning / supply-chain signatures.** sha256 is good enough for v18.
  Sigstore + cosign is a one-spec follow-up — it lives entirely inside
  `release-workflows` (add steps; no other spec moves).
- **Mac notarisation.** The macOS binaries will be **unsigned** in v18 — Eric
  is not paying for an Apple Developer ID yet. The install script prints a
  hint about `xattr -d com.apple.quarantine`.
- **Linux package manager surfaces (apt/rpm/AUR).** Post-v18.
- **Plain `botopink` (no-bpmp) compiler usage.** Still fully supported; the
  env hook is opt-in and the manifest schema additions are optional. Nothing
  about the existing usage pattern changes.

## Dependency edges (recap)

```text
botopink-json-deps  ─── compiler keystone for ───▶  bpmp
release-workflows   ─── publishes artifacts to ──▶  bpmp, install-script
bpmp                ─── installs into store for ──▶ install-script
release-workflows   ─── enables the published-compiler path of ──▶ lib-test-workflows
```

Concretely:

- `bpmp.md` cannot land before `botopink-json-deps.md` is merged — bpmp's
  `bpmp install` needs `BOTOPINK_LIB_ROOTS` to exist.
- `install-script.md` cannot land before `bpmp.md` (it installs bpmp).
- `lib-test-workflows.md` can land *before* `release-workflows.md` by
  building botopink-lang from source; the release-fetch fast-path becomes
  available once releases exist.

## Working order

1. **Parallel:** `botopink-json-deps` + `release-workflows`
   (file-disjoint, independent acceptance gates).
2. **Parallel after #1:** `bpmp` + `lib-test-workflows`
   (bpmp needs `botopink-json-deps`; lib CI is independent).
3. **After bpmp lands:** `install-script`.

Each spec is one branch `task/<slug>` per the tasks/AGENTS.md universal
contract.
