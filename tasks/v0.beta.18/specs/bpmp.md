# bpmp — the Boto Pink Package Manager

**Slug**: bpmp
**Depends on**: [botopink-json-deps](botopink-json-deps.md)
**Files**: `repository/botopink-lang/modules/bpmp/{build_step.zig,src/**,tests/**,AGENTS.md,docs.md,examples.md}`, `repository/botopink-lang/build.zig` (wire `bpmp` exe + `test-bpmp` step), `repository/botopink-lang/modules/AGENTS.md` (add bpmp row)
**Touches docs**: `repository/botopink-lang/AGENTS.md` (top-level toolchain map), `repository/botopink-lang/docs/botopink-json.md` (link the `requires`/`botopink` reader), this set's `README.md`
**Status**: pending

## Problem

A botopink user today reaches for a framework by:

1. Knowing which git repo it lives in.
2. Cloning it next to their project, hand-symlinking into `libs/`, or copying
   files in.
3. Hoping the framework's `from "..."` imports don't reach for a *transitive*
   dependency they haven't also installed.
4. Hoping the framework's `.bp` matches the compiler version they have.

Every step is manual and fragile. bpmp is the one-line replacement: declare
`requires: { "erika": "^0.0.1" }` in `botopink.json`, run `bpmp install`, get
a deterministic install of every transitive dependency at a known version,
and a `bpmp run` that spawns the right compiler with `BOTOPINK_LIB_ROOTS` set
to find everything bpmp put on disk.

bpmp is also the toolchain manager. `bpmp use botopink 0.0.1` downloads the
named compiler from GitHub Releases ([`release-workflows`](release-workflows.md))
and switches the project to it. `bpmp self update` swaps the bpmp binary
in-place. Both reuse the same download + verify + extract code path.

## Target — the user surface

### Manifest read/write

bpmp reads and writes the `botopink.json` shape defined in
[`botopink-json-deps` §"Target schema"](botopink-json-deps.md). The
compiler-touched fields (`name`, `version`, `src`, `files`, `entry`,
`dependencies`, `target`) are passed through verbatim; bpmp owns
`botopink` (compiler-version constraint) and `requires` (per-dep version
constraint). When `bpmp install <name>@<ver>` adds a dependency, it
**also** appends to the `dependencies` array (so the compiler's loader
picks it up — bpmp is consistent with the compiler's view of the world).

### Lockfile (`botopink.lock.json`) — commit-addressed

The lockfile is named `botopink.lock.json` (matches the `botopink.json`
family, explicit `.json` extension). It pins every package and the
toolchain by **git commit SHA**, not by tag — the tag is recorded as a
hint for humans, but the *fetch URL* and the *integrity check* both go
through the SHA. This matters because the framework lib repos use a
moving `<version>-feat` tag (see [`lib-test-workflows`](lib-test-workflows.md)
§"auto-tag"): a teammate running `bpmp install` two hours after the
lockfile was written must still get the *same* tree, even if the tag
has since moved.

```jsonc
{
  "schema": 1,
  "generated_at": "2026-06-12T15:42:11Z",
  "botopink": {
    "version": "0.0.1",
    "commit":  "a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4",   // botopink-lang commit SHA
    "tag":     "v0.0.1",                                       // hint, NOT used for fetch
    "sha256":  "<64hex>",                                      // sha256 of the bpmp tarball
    "source":  "github.com/botopink/botopink-lang"
  },
  "packages": {
    "erika": {
      "version":  "0.0.1",
      "commit":   "ff1122334455667788aabbccddeeff0011223344",  // erika commit SHA at resolve time
      "tag":      "0.0.1",                                       // resolved tag, hint only
      "constraint": "^0.0.1",                                    // what the manifest's `requires` asked for
      "sha256":   "<64hex>",                                     // sha256 of the resolved git-archive tarball
      "source":   "github.com/botopink/erika",
      "requires": []                                             // erika's own dep NAMES, flattened
    },
    "jhonstart": {
      "version":  "0.0.1-feat",
      "commit":   "0011aabb22ccddeeff334455667788991122ccdd",   // pinned to the feat commit at resolve time
      "tag":      "0.0.1-feat",                                   // moving tag — present-day; lock uses commit
      "constraint": "feat",
      "sha256":   "<64hex>",
      "source":   "github.com/botopink/jhonstart",
      "requires": []
    }
  }
}
```

The lockfile is **the** source of truth at install time. `bpmp install`
without args reads the lockfile and reproduces exactly that tree:

- For each package, fetch
  `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz` — a
  commit-addressed URL GitHub serves for any reachable SHA. **Never** via
  the tag (the tag may have moved).
- Verify sha256 against the recorded digest. Fail loudly with both
  digests on mismatch.

`bpmp sync` rebuilds the lockfile from the manifest by re-resolving each
`requires` constraint to the **current** highest matching tag, then
recording the tag's *current* commit SHA. This is the only command that
moves the commit pin forward. `bpmp install <name>[@<spec>]` modifies
the manifest and re-resolves only the added name (and its transitive
deps), preserving every other package's existing commit pin.

`constraint` records the manifest's `requires.<name>` literal at resolve
time. It is informational — bpmp does **not** re-check it on replay
(replay is commit-pinned). It surfaces in `bpmp list` so the user can
see *why* a particular commit was picked.

### Storage (`$BPMP_HOME` — see [plan §D5](../plan.md))

```text
$BPMP_HOME/                                  # default: $HOME/.bpmp  (Windows: %USERPROFILE%\.bpmp)
├── bin/
│   └── bpmp                                 # shim → active version's bpmp
├── botopink/
│   └── versions/
│       ├── 0.0.1/                           # whatever the user "bpmp use" selected
│       │   ├── botopink
│       │   ├── botopink-lsp
│       │   ├── botopink-lib-test
│       │   └── bpmp                         # bundled with the toolchain (see release-workflows §F2)
│       ├── dev/                             # populated by `bpmp use botopink dev` linking a local zig-out
│       └── stable -> 0.0.1                  # POSIX symlink, Windows directory junction
├── packages/
│   └── erika/
│       └── versions/
│           └── 0.0.1/
│               ├── botopink.json
│               └── src/                     # exactly what the lib's git tree ships
├── cache/
│   ├── tarballs/
│   │   └── <sha256>.tar.gz                  # content-addressed download cache
│   └── manifests/
│       └── botopink-erika.<sha7>.json       # GH Releases / git-archive metadata cache
└── lock                                     # fs flock for "one bpmp at a time on this $BPMP_HOME"
```

### Command surface

```text
bpmp init [--target <commonJS|erlang|beam|wasm|node>] [--name <s>] [--version <s>]
                                # writes botopink.json + botopink.lock.json; refuses if either exists
bpmp install [<name>[@<spec>]]  # no args: replay lockfile.
                                # with name: resolve spec → highest matching tag → add to manifest's
                                #   `dependencies` AND `requires`, download, extract, update lockfile.
                                # `@feat` is a literal spec — resolves to the moving feat tag
                                # (see lib-test-workflows §"auto-tag").
bpmp uninstall <name>           # removes name from manifest + lockfile; leaves the on-disk
                                # cache untouched (still in $BPMP_HOME/packages — reused if reinstalled)
bpmp use botopink <spec>        # downloads the named compiler from botopink-lang's GitHub Releases,
                                # extracts to $BPMP_HOME/botopink/versions/<v>/, updates `stable`
                                # symlink, writes lockfile.botopink.version. <spec> = exact version,
                                # `latest`, or `dev` (linking ./zig-out from the cwd's botopink-lang
                                # clone — for compiler hackers).
bpmp list                       # prints manifest + lockfile rollup: installed compiler, deps, versions
bpmp list --installed           # prints what's in $BPMP_HOME (across projects)
bpmp pack                       # tars the current project per botopink.json `files` array (for
                                # contributing back a lib release); writes dist/<name>-<version>.tar.gz
bpmp sync                       # reads manifest, recomputes lockfile (highest tag matching each
                                # constraint), reports drift; `--update` to write
bpmp run [-- <botopink args>]   # exec `<$BPMP_HOME>/botopink/versions/<active>/botopink <args>`
                                # with BOTOPINK_LIB_ROOTS set to the current project's resolved
                                # package roots (one per installed package)
bpmp self update                # downloads latest bpmp from botopink-lang's GH Releases, verifies
                                # sha256, atomically replaces the running bpmp binary (see plan §D7).
                                # `--toolchain` also updates the active botopink version.
bpmp self uninstall             # removes $BPMP_HOME interactively (prompts unless --yes)
bpmp version                    # bpmp own version + active botopink version
bpmp env                        # prints export PATH=…/.bpmp/bin:$PATH + BOTOPINK_LIB_ROOTS …
                                # in a shell-source-able form ($SHELL detected; --shell flag overrides)
```

### Env wiring (what `bpmp run` exports)

```text
PATH                = $BPMP_HOME/bin:$PATH                          (so child processes still see bpmp)
BOTOPINK_LIB_ROOTS  = <root_1>:<root_2>:…                            (POSIX ':' / Windows ';')
                      where root_i = $BPMP_HOME/packages/<dep_i>/versions/<v_i>
                      one entry per top-level dep + each transitive dep, in deterministic order
                      (lockfile order, top-deps first)
```

The compiler's resolver (see [`botopink-json-deps`](botopink-json-deps.md))
prepends env roots — each `<dep_i>` directory contains `botopink.json`
directly, so `from "erika"` lands on the right one without further walking.

### Version constraint algebra (recap from plan §D6)

```text
"*"          → any
"0.1.0"      → exactly 0.1.0
"^0.1.0"     → >=0.1.0, <0.2.0           (0.x SemVer: minor bumps allowed; 1.x+: major would be allowed)
"~0.1.0"     → >=0.1.0, <0.2.0
">=0.1.0"    → at least 0.1.0
"feat"       → the literal moving tag <version>-feat (lib-test-workflows §"auto-tag")
"latest"     → highest stable tag (no -<x> suffix)
```

Resolution is **first-fit on highest tag** — bpmp lists the repo's tags
(`GET /repos/botopink/<name>/tags`), filters to ones matching the
constraint, sorts SemVer-descending, picks the first. No backtracking.

### Conflict resolution

When two deps require incompatible versions of a transitive dep:

```text
$ bpmp install erika      # erika requires foo "^0.1.0"
$ bpmp install jhonstart  # jhonstart requires foo "^0.2.0"
error: foo: incompatible constraints
  erika      → ^0.1.0    (would resolve to 0.1.4)
  jhonstart  → ^0.2.0    (would resolve to 0.2.1)
hint: pin a version manually in `requires.foo` to override both transitive constraints.
```

No SAT solver. The user pins. Two transitive constraints that *do* overlap
get the highest tag in the intersection.

## Examples

### a fresh project
```bash
$ mkdir my-app && cd my-app
$ bpmp init --target commonJS --name my-app
# writes:
#   botopink.json   { "name": "my-app", "version": "0.0.1", "target": "commonJS",
#                     "entry": "src/main.bp", "dependencies": [], "requires": {} }
#   botopink.lock.json       { "schema": 1, "botopink": { … current active …}, "packages": {} }
$ bpmp install erika
resolving erika via github.com/botopink/erika …
  → tag 0.0.1
  → sha256 a1b2c3d4…
downloaded 12 KB
extracted to ~/.bpmp/packages/erika/versions/0.0.1/
updated botopink.json: dependencies += ["erika"], requires.erika = "^0.0.1"
updated botopink.lock.json
$ bpmp run -- build src/main.bp
running ~/.bpmp/botopink/versions/0.0.1/botopink build src/main.bp
  with BOTOPINK_LIB_ROOTS=~/.bpmp/packages/erika/versions/0.0.1
…compile output…
```

### locked reinstall on a different machine
```bash
$ git clone repo && cd repo
$ bpmp install            # no args — replays botopink.lock.json byte-for-byte
installing 3 packages from botopink.lock.json …
  erika      0.0.1 (sha256 a1b2c3d4… verified)
  jhonstart  0.1.2 (sha256 9f8e7d6c… verified)
  rakun      0.0.4 (sha256 1234abcd… verified)
all packages installed
$ bpmp run -- build src/main.bp
…
```

### self update
```bash
$ bpmp self update
current bpmp: 0.0.1
querying github.com/botopink/botopink-lang/releases/latest …
  → 0.0.2
downloading bpmp-v0.0.2-linux-x86_64.tar.gz …
verified sha256 (e4d909c2…)
extracted to ~/.bpmp/botopink/versions/0.0.2/
swapping in new bpmp binary …
done. bpmp is now 0.0.2.
hint: run `bpmp use botopink 0.0.2` to switch the active compiler to 0.0.2.
```

### `--toolchain` rolls both bpmp + active compiler forward
```bash
$ bpmp self update --toolchain
current bpmp: 0.0.1, active botopink: 0.0.1
querying … → 0.0.2
…installs both binaries, updates ~/.bpmp/botopink/versions/stable → 0.0.2
hint: existing projects keep using their lockfile-pinned compiler until you run `bpmp use` in them.
```

### conflict reported, user pins manually
```bash
$ bpmp install rakun
error: erika: incompatible constraints
  my-app      → ^0.0.1
  rakun       → ^0.0.2   (rakun's own `requires.erika`)
hint: edit botopink.json:
  "requires": { "erika": "^0.0.2", … }
then re-run bpmp install.
$ # user edits, re-runs:
$ bpmp install
resolving erika …  → 0.0.2
…
```

### env command for sourcing into a shell rc file
```bash
$ bpmp env
# Add this to your ~/.bashrc:
export PATH="$HOME/.bpmp/bin:$PATH"
# (BOTOPINK_LIB_ROOTS is set per-project by `bpmp run` — do not export globally.)
$ bpmp env --shell fish
set -gx PATH $HOME/.bpmp/bin $PATH
```

### dev compiler — for compiler hackers
```bash
$ cd repository/botopink-lang
$ zig build install --prefix /tmp/dev-bp
$ bpmp use botopink dev --from /tmp/dev-bp
linking ~/.bpmp/botopink/versions/dev → /tmp/dev-bp
$ cd ~/projects/my-app
$ bpmp run -- build src/main.bp    # spawns /tmp/dev-bp/bin/botopink
```

## Steps

### F0 — module scaffold (Zig)
- [ ] Create `modules/bpmp/src/main.zig` (entry, args dispatch).
- [ ] Create `modules/bpmp/src/cli.zig` (subcommand parser — table-driven).
- [ ] Create `modules/bpmp/src/storage.zig` ($BPMP_HOME path resolution,
      mkdir-p, fs lock, atomic file moves).
- [ ] Create `modules/bpmp/src/manifest.zig` (read/write `botopink.json`
      preserving existing field order on write — uses `std.json` Tree API).
- [ ] Create `modules/bpmp/src/lockfile.zig` (read/write `botopink.lock.json`,
      schema-versioned).
- [ ] Create `modules/bpmp/src/semver.zig` (parser + constraint matcher +
      ordering — see plan §D6).
- [ ] Create `modules/bpmp/src/registry.zig` (GitHub Releases API client —
      list tags, fetch release metadata, resolve asset URLs — `http.Client`
      against `api.github.com`; respects `GITHUB_TOKEN` if set for rate
      limits but does not require auth).
- [ ] Create `modules/bpmp/src/download.zig` (HTTPS download with retry,
      content-addressed cache).
- [ ] Create `modules/bpmp/src/extract.zig` (tar.gz via `std.tar` +
      `std.compress.gzip`; zip via `std.zip`).
- [ ] Create `modules/bpmp/src/sha256.zig` (file hashing,
      sidecar verification — wraps `std.crypto.hash.sha2.Sha256`).
- [ ] Create `modules/bpmp/src/resolver.zig` (constraint solver: read
      manifest → fetch tag lists → produce lockfile).
- [ ] Create `modules/bpmp/src/commands/{init,install,uninstall,use,list,pack,sync,run,self_update,self_uninstall,version,env}.zig`.
- [ ] Create `modules/bpmp/AGENTS.md`, `docs.md`, `examples.md` following
      the existing modules' shape.

### F1 — wire into workspace `build.zig`
- [ ] Add `bpmp` executable target after `botopink-lib-test` (around
      `build.zig:201`). No `compiler-core` import — bpmp is a separate
      Zig program that *spawns* `botopink`, not a library that imports
      it.
- [ ] Add `test-bpmp` step that runs `addTest` over the bpmp source root.
      Keep it out of `zig build test` until bpmp's tests stabilise (same
      reasoning as `test-libs`/`test-vscode`).
- [ ] Add `bpmp` to the artifacts that `release-workflows` ships (see
      release-workflows §F2).

### F2 — manifest + lockfile read/write
- [ ] `manifest.zig`: `read(path) -> Manifest`, `write(path, m)` preserving
      key order. Field set per `botopink-json-deps.md` §"Target schema".
- [ ] `lockfile.zig`: `read(path) -> Lockfile`, `write(path, l)` —
      file is `botopink.lock.json`. Schema version 1; on version
      mismatch print an explicit "regenerate with `bpmp sync`" hint.
      Records `{version, commit, tag, constraint, sha256, source,
      requires}` per package and `{version, commit, tag, sha256,
      source}` for the toolchain.
- [ ] Tests: round-trip both files (including unknown fields preserved
      on write).

### F3 — registry + download + cache
- [ ] `registry.zig`: `listTags(owner, repo) -> []Tag`,
      `releaseAsset(owner, repo, tag, name) -> AssetURL`. Uses GitHub
      REST; respects `GITHUB_TOKEN` rate-limit auth header.
- [ ] `download.zig`: streams to a temp file, moves into
      `$BPMP_HOME/cache/tarballs/<sha256>.<ext>` after verification.
      Re-uses cache on hit. Retries on transient network errors
      (exponential backoff, max 3 attempts).
- [ ] `sha256.zig`: read sidecar `.sha256`, compare to computed digest,
      error with both hashes on mismatch.
- [ ] Tests: mock HTTP client (`std.http.Server` over loopback) so the
      cache and retry paths run hermetically.

### F4 — semver + resolver
- [ ] `semver.zig`: parse, compare, matchConstraint. Cover `*`, exact,
      `^`, `~`, `>=`, plus the special aliases `feat` (→ literal
      `<version>-feat` lookup) and `latest` (→ highest non-prerelease).
- [ ] `resolver.zig`: walk top-level deps from manifest, fetch each
      package's `botopink.json` (from the resolved tag's git archive,
      not from a registry index — keeps it indexless), recurse for
      transitive deps, detect conflicts. Output: a `[]ResolvedPackage`
      ready to write to lockfile.
- [ ] Tests: synthetic two-package graph with conflict; same with
      satisfiable intersection; transitive depth ≥ 3.

### F5 — commands
- [ ] `commands/init.zig`. Refuses if either file exists. `--name`
      defaults to cwd basename; `--target` defaults to `commonJS`;
      `--version` defaults to `0.0.1`. Writes `entry: "src/main.bp"`,
      `src: "src/"`, empty `dependencies` and `requires`.
- [ ] `commands/install.zig`. With no args: replay lockfile —
      download each package from
      `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz` (never
      via tag), verify sha256, extract. With a `<name>[@<spec>]` arg:
      resolve constraint → highest matching tag → fetch tag's commit
      SHA → pin commit + sha256 → mutate manifest, append to lockfile,
      install delta.
- [ ] `commands/uninstall.zig`. Removes name from
      manifest.dependencies/requires + lockfile.packages. Does **not**
      delete `$BPMP_HOME/packages/<name>` (cache reuse). `--purge`
      removes the on-disk cache too.
- [ ] `commands/use.zig` for `botopink <spec>`. Downloads the four
      botopink-lang binaries (botopink, botopink-lsp, botopink-lib-test,
      bpmp) at the resolved tag; verifies sha256; extracts to
      `$BPMP_HOME/botopink/versions/<v>/`; updates `stable` symlink.
      `dev` spec links a user-provided path (--from <dir>).
- [ ] `commands/list.zig`. Pretty table — three sections: active
      compiler, current project deps, all installed packages
      ($BPMP_HOME-wide with `--installed`).
- [ ] `commands/pack.zig`. Validates manifest, runs `git archive` if in a
      git repo, else `tar -czf` honoring `botopink.json.files`. Output
      goes to `dist/<name>-<version>.tar.gz`.
- [ ] `commands/sync.zig`. Recomputes lockfile from manifest by
      re-resolving each constraint to the **current** highest matching
      tag and recording its **current** commit SHA. Without `--update`
      prints drift (per-package: old commit → new commit) and exits
      non-zero; with `--update` writes the new lockfile.
- [ ] `commands/run.zig`. Reads lockfile, builds
      `BOTOPINK_LIB_ROOTS=root_1:root_2:…` from each installed package's
      version dir, execs the active compiler with the user's args.
      Anything after `--` is forwarded verbatim.
- [ ] `commands/self_update.zig`. See plan §D7. Two flags:
      `--check` (no install, just report current vs latest);
      `--toolchain` (also update active botopink).
- [ ] `commands/self_uninstall.zig`. Interactive (prompts to confirm
      removal of `$BPMP_HOME`); `--yes` to skip. Prints PATH-cleanup
      instructions.
- [ ] `commands/env.zig`. Shell detected from `$SHELL` (POSIX) or
      `$PSModulePath` heuristic (Windows). `--shell <bash|zsh|fish|ps>`
      overrides.
- [ ] `commands/version.zig`. Prints `bpmp <ver>` + `botopink <active-ver>` (or "no active toolchain").

### F6 — compiler version check
- [ ] During `bpmp install`, if `botopink.json.botopink` is set and the
      active compiler's version is outside that range, **warn** (don't
      block) — install still proceeds; the warning suggests `bpmp use
      botopink <spec>`.
- [ ] During `bpmp run`, the same check runs and prints the warning
      once per session.

### F7 — self-update binary swap
- [ ] POSIX path: write new bpmp to `$BPMP_HOME/bin/bpmp.new`,
      `std.os.rename` to `$BPMP_HOME/bin/bpmp`. Verified to work while
      the old process is still running (handle survives the rename).
- [ ] Windows path: spawn a tiny `cmd /c` deferred-swap helper that
      polls until the old bpmp exits, then renames; `bpmp self update`
      exits immediately after spawning the helper, prints "swap will
      complete on next bpmp invocation".
- [ ] Tests: integration test on POSIX simulates a "self update under
      running process" scenario; Windows test is manual (documented).

### F8 — docs + AGENTS
- [ ] `modules/bpmp/AGENTS.md` — module ownership, the storage layout
      diagram, the command surface table, the env-export contract.
- [ ] `modules/bpmp/docs.md` — for end users: the storage diagram, a
      `bpmp init → install → run` tutorial, the conflict-resolution UX.
- [ ] `modules/bpmp/examples.md` — three worked examples mirroring
      the §Examples above.
- [ ] `modules/AGENTS.md` gains a bpmp row.

## Test scenarios

```
unit  ---- manifest round-trip preserves unknown fields and key order
unit  ---- botopink.lock.json schema-version mismatch produces "run bpmp sync" hint
unit  ---- lockfile round-trip preserves {version, commit, tag, constraint, sha256} per pkg
unit  ---- lockfile replay fetches via /archive/<commit>.tar.gz, NOT /archive/refs/tags/<tag>
unit  ---- lockfile replay errors when commit-pinned sha256 mismatches the resolved archive
unit  ---- bpmp sync drifts when the feat tag has moved: reports old→new commit per package
unit  ---- semver "^0.1.0" accepts 0.1.1, rejects 0.2.0
unit  ---- semver "^1.2.0" accepts 1.3.0, rejects 2.0.0
unit  ---- semver "feat" matches only the literal <version>-feat tag
unit  ---- semver "latest" picks the highest non-prerelease tag
unit  ---- resolver: A->B^0.1, A->C->B^0.1.5 — intersection picked
unit  ---- resolver: A->B^0.1, A->C->B^0.2 — conflict reported with both edges named
unit  ---- registry: GitHub API mock returns 3 tags, listTags returns them sorted
unit  ---- download: cache hit short-circuits — no http call made
unit  ---- download: sha256 mismatch errors with both digests in the message
intg  ---- bpmp init in empty dir creates both files
intg  ---- bpmp install erika in a fresh project: file tree under $BPMP_HOME matches §plan
intg  ---- bpmp install (no args) reproduces lockfile byte-for-byte
intg  ---- bpmp run executes the active compiler with BOTOPINK_LIB_ROOTS set
intg  ---- bpmp run compiles a hello.bp depending on a bpmp-installed lib
intg  ---- bpmp use botopink 0.0.2 swaps active compiler; bpmp version reflects
intg  ---- bpmp use botopink dev --from <path> links the dev tree
intg  ---- bpmp self update --check reports current vs latest without writing
intg  ---- bpmp self update swaps the binary atomically on POSIX
intg  ---- bpmp self uninstall --yes removes $BPMP_HOME
intg  ---- bpmp env --shell bash prints a source-able line
intg  ---- two bpmp processes touching the same $BPMP_HOME: second blocks on the fs lock
e2e   ---- a full lifecycle: install script → bpmp init → install erika → run hello.bp
```

## Notes

- **Why `git archive`, not a release tarball, for lib packages?** Per
  [`lib-test-workflows`](lib-test-workflows.md), the four lib repos do
  not publish release tarballs — only auto-tag. GitHub serves
  `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz` for any
  reachable commit SHA; bpmp fetches that (commit-addressed, **not**
  tag-addressed) and treats it as the package tarball. `sha256` is
  computed on the bytes received and stored in the lockfile.
- **Why commit-pin the lockfile, not tag-pin?** Because feat tags
  *move* (see [`lib-test-workflows`](lib-test-workflows.md) §"auto-tag":
  `<version>-feat` is force-updated on every push). A tag-pinned
  lockfile would silently drift between teammates depending on when
  they ran `bpmp install`. Commit pinning is immutable by construction
  — GitHub never reassigns a commit SHA, and the sha256 of the
  resulting tarball catches any tampering. Stable tags
  (`<version>`, immutable per [`lib-test-workflows`](lib-test-workflows.md))
  could be tag-pinned safely, but using one rule (commit-pin) for
  every package keeps the resolver simple.
- **Why is bpmp bundled with the botopink-lang release?** They evolve
  together — bpmp knows the env-hook contract, the manifest schema, the
  asset-URL convention. Shipping them in lockstep means a `bpmp self
  update` always picks a bpmp that matches its embedded compiler. The
  cost is a bigger release (4 binaries × 5 targets); the win is no
  drift.
- **Why does `bpmp install` mutate `dependencies` AND `requires`?**
  Because the compiler only reads `dependencies` — if bpmp wrote
  `requires` but not `dependencies`, the compiler would not find the
  lib even with `BOTOPINK_LIB_ROOTS` set (the env hook controls
  *where* to look, not *what* to look for). Keeping both in sync is
  bpmp's responsibility.
- **GitHub rate limits.** Unauthenticated GitHub API gets 60 req/h per
  IP — enough for a few `bpmp install` runs but tight for CI. bpmp reads
  `GITHUB_TOKEN` if set and sends it as `Authorization: Bearer`; CI
  workflows already have one available. No new secret.
- **Why no project-local `bpmp/` by default?** Eric's original spec
  showed `bpmp/` as the layout dir, but a per-project copy would
  multiply downloads across projects and waste disk. The shared
  `$BPMP_HOME` is the default. `bpmp install --vendor` writes the same
  layout into `./bpmp/` for users who want everything reproducible
  inside the project tree (CI, offline, isolated machines). The
  resolver does not know the difference — it follows
  `BOTOPINK_LIB_ROOTS`, which `bpmp run` sets to whichever path is
  populated.
- **Why no SAT solver?** With ≤ 10 packages in the ecosystem there is
  no version-conflict density that justifies a backtracking solver.
  Cargo took years to add one; bpmp can grow into it. First-fit makes
  the failure mode (conflict) loud and forces the user to pin —
  which is the right thing while the schema is still settling.
- **Cross-spec coordination.**
  - [`botopink-json-deps`](botopink-json-deps.md) **must** land
    first. bpmp's `run` and `install` both rely on
    `BOTOPINK_LIB_ROOTS` existing.
  - [`release-workflows`](release-workflows.md) is the publisher
    bpmp consumes. If `release-workflows` ships before bpmp lands,
    its matrix uploads 3 binaries × 5 targets (no `bpmp` artifact);
    `bpmp self update` is non-functional until bpmp itself is in
    the matrix. F2 in `release-workflows` is written to make the
    bump trivial.
  - [`install-script`](install-script.md) bootstraps bpmp on the
    user's machine. The install script's contract with bpmp is
    "leave a runnable bpmp at `$BPMP_HOME/bin/bpmp`" — anything
    bpmp does past that is its own.
