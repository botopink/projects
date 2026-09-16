# bpmp — three git-dependency bugs (7h)

Paths are relative to `repository/botopink-lang/modules/bpmp/`, except `build.zig` (the root
`repository/botopink-lang/build.zig`) and paths starting with `compiler-cli/`, which are under
`repository/botopink-lang/modules/`.

bpmp is not a separate repo: it lives inside `botopink-lang`, so its commit lands there.
[`../fronts.md`](../fronts.md) assigns `modules/bpmp/**` to no front; this front claims it with its
spec row.

---

## Current state

The healthiest module in the workspace: it builds, it is genuinely offline, and it has **90**
`test "…"` declarations, run by `zig build test-bpmp` (`build.zig:267`).

Two facts explain where the bugs are:

- `build.zig:255-259`: the step is **kept out of `zig build test`** ("until the suite stabilises").
- `src/commands/install.zig` and `src/commands/sync.zig` have **zero** tests between them — and all
  three bugs are in exactly those two files and the resolver they call.

## (a) `install --frozen` symlinks a store path it never checks exists

### Deciding sites

- `src/dep/resolver.zig:93` comments "CAS hit *if the store dir exists*", but the only test performed
  is `le.rev.len == 40` (`:96`); the file imports no `std.Io` and calls no `access`/`openDir`.
- `:116` goes further — under `--frozen` a spec-pinned `rev:` dep is forced to `.reuse_cas` even on
  a cold store, skipping the clone.
- `src/commands/install.zig:192-202` then symlinks it, and `ensureSymlink` (`:280-290`) does not stat
  the target either.

### Mechanism

With a lockfile and a pruned `$BPMP_HOME/store`, `bpmp install --frozen` prints
`✓ <name> (CAS) @ <rev>`, exits 0, and leaves a **dangling symlink** at
`.botopinkbuild/deps/<name>` — which the compiler later reports as
`compiler-cli/src/cli/libs.zig:295` `LibNotFound`, i.e. the misleading *"a declared dependency was
not found under the libs root"*. `src/dep/clone.zig:100` and `:180` do check; the `reuse_cas` path
just never runs them.

### Fix

Thread `io` into `resolver.zig` so `:97` and `:113` can probe the path, and make a miss under
`--frozen` a named error rather than a silent success.

## (b) A first install of a `branch:`/`tag:` dependency clones default HEAD

### Deciding sites

- `src/dep/clone.zig:127-137` handles refs correctly (`--branch` for both `.branch` and `.tag`) —
  but the ref never reaches it.
- `src/dep/resolver.zig:20-29` — `Action` has no `branch`/`tag`/`ref` field; the fresh-clone action
  at `:127-134` drops it.
- `src/commands/install.zig:205-206` re-derives a spec from `act.rev` alone.

### Mechanism

With no lockfile `s.ref` stays `.none`, `clone.zig:136` matches `.rev, .none => {}`, and the command
is `git clone --depth 1 -- <url> <tmp>`. `clone.zig:169` then records that wrong SHA into the
lockfile, so every later install faithfully reuses the wrong commit. The resolver's own test
(`resolver.zig:160-168`) asserts only `Kind.clone`, never that the branch survives.

### Fix

Add `ref: spec.DepRef` to `Action`, populate it at `:128-133`, use it at `install.zig:205-206` — or
carry the original `DepEntry` and delete the re-derivation.

## (c) `sync` resolves every dependency to `botopink/<name>`

### Deciding site

`src/commands/sync.zig:60` — `allocPrint("botopink/{s}", .{d})` — for every dep, regardless of its
declared `git:` URL.

### Mechanism

A dep at `github.com/acme/widgets` is queried at `botopink/widgets`, which either 404s (`:66-69`
prints `fetch failed` and continues) or silently resolves against an unrelated repo. The real source
is already in the manifest: `src/dep/spec.zig` parses `git`/`path` per entry and
`compiler-cli/src/cli/config.zig:43-47` mirrors the shape — `sync.zig:36` just iterates the
bare-name list from `m.dependencies()` instead of `dep_spec.parseFromManifest`, which
`install.zig:96` does use.

Compounding it, `sync.zig:99-100` makes `--update` a no-op while `install.zig:384` tells users to run
`bpmp sync --update` to regenerate the lockfile on a schema mismatch — dead-end advice.

### Fix

Iterate `parseFromManifest` entries and derive `RepoSpec` from `entry.spec.git`, falling back to a
configurable default org only where no `git:` is declared; then either implement `--update` or stop
advertising it.

## Acceptance

- [ ] `bpmp install --frozen` against an empty store fails with a named error, not a dangling symlink
- [ ] A first install of a `branch:`/`tag:` dep checks out the named ref, asserted by a test
- [ ] `sync` resolves each dep from its own declared source; no org name is hardcoded
- [ ] `install.zig` and `sync.zig` have tests; `zig build test-bpmp` is in the documented gate
      or the reason it is not is written down

## Ownership

Wiring `test-bpmp` into the gate is a `build.zig` / CI change, owned by
[`../02-cli-gate/`](../02-cli-gate/README.md) (see its
[`gate-coverage.md`](../02-cli-gate/gate-coverage.md)). This front writes the tests that make the
step worth gating; that front decides whether it joins `zig build test`.
