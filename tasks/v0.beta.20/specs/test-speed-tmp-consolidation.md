# test-speed-tmp-consolidation — consolidate per-test scratch dirs under `.botopinkbuild/tmp/` + speed up zig test loop

**Slug**: test-speed-tmp-consolidation
**Depends on**: nothing — file-disjoint with every other v0.beta.20 spec at the source level. Touches `runtime.zig`'s `makeScratchDir` (single callsite) + the `.gitignore` rule already covering `.botopinkbuild/`.
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/runtime.zig` — `makeScratchDir` rewrite (lines 41–51): scratch dirs now land under `<modules/compiler-core>/.botopinkbuild/tmp/<hex>/`, not as `.tmp-exec-<hex>/` siblings of the cwd.
  - `repository/botopink-lang/.gitignore` — confirm `.botopinkbuild/` already swallows the new path (no edit needed beyond verification).
  - `repository/botopink-lang/.gitignore` — remove the now-redundant `**/.tmp-exec-*/` line (added by v0.beta.20 std-tail; no longer fires).
  - `repository/botopink-lang/modules/compiler-core/src/codegen/AGENTS.md` — one bullet under **runtime** §: new tmp path + cleanup contract.
  - `repository/botopink-lang/build.zig` — add a `clean-tmp` step (optional helper: `find .botopinkbuild/tmp -type d -mindepth 1 -mtime +1 -exec rm -rf {} +`) so leaked dirs from crashed tests don't accumulate.
  - `repository/botopink-lang/modules/compiler-core/src/codegen/tests/runtime_scratch.zig` (NEW, ~30 LOC) — pin the new path layout + assert cleanup on success.
**Touches docs**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/AGENTS.md` (runtime § layout note).
  - `repository/botopink-lang/AGENTS.md` (one bullet under **Build & test** if it references scratch dirs).
  - `repository/botopink-lang/CHANGELOG.md`.
  - `tasks/v0.beta.20/status.md` (this row reaches **done** when F0–F4 land).
**Status**: done — pending merge to `feat`

## Problem

Two symptoms surfaced in the workspace today:

1. **Pollution at the module-core root.** `repository/botopink-lang/modules/compiler-core/` collects sibling dirs of the form `.tmp-exec-<hex16>/` whenever a backend-exec test crashes (or is killed) before the `defer deleteTree` fires. Today's snapshot:
   ```
   modules/compiler-core/.botopinkbuild
   modules/compiler-core/.tmp-exec-94a10fc927be8d94
   modules/compiler-core/.tmp-exec-922f9ea881df7003
   modules/compiler-core/.tmp-exec-bec56372251b9551
   modules/compiler-core/.tmp-exec-f4a8d4ee28740b17
   ```
   These leak past test runs, slow down `ls`/IDE indexers, and confuse `git status` (caught by `.gitignore **/.tmp-exec-*/` only because std-tail added that rule late — a workaround for the symptom, not the cause).
2. **`zig build test` is slow.** Each test that needs a runtime (node / erl / wasmtime) creates a fresh dir, writes 1+ files into it, spawns a subprocess, deletes the dir. With ~150 backend-exec snaps per run, that's 150+ `createDirPath` + write + `deleteTree` cycles, each at the filesystem root. Even on tmpfs the syscall churn is measurable.

## Intent

- **One canonical scratch root**: `<compiler-core>/.botopinkbuild/tmp/<hex>/`. Already gitignored by the umbrella `.botopinkbuild/` rule; no per-test path leaks out of the build dir.
- **No more `.tmp-exec-*` siblings of the module root**, ever — the existing `.gitignore **/.tmp-exec-*/` rule becomes dead and is dropped in F3.
- **Optional reuse across runs**: keep `.botopinkbuild/tmp/` between runs so the kernel page cache stays warm for repeated `node` / `escript` / `wasmtime` invocations on the same fixture; on each run, **clean only dirs older than 1 day** (`clean-tmp` step) so a crashed test never leaks more than a day.
- **Atomic cleanup contract**: on success the per-test dir is deleted (today's behaviour); on crash the leak lives under `.botopinkbuild/tmp/` and is reaped by `clean-tmp`.

## Disk layout (proposed)

```
repository/botopink-lang/modules/compiler-core/
  .botopinkbuild/                       # already exists
    tmp/                                # NEW — single root for all scratch
      <hex-id-1>/                       # per-test
        tmp_run.js
        <aux-1>.js
        …
      <hex-id-2>/                       # per-test
        main.erl
        main.beam
        …
```

Today's leaked siblings (`modules/compiler-core/.tmp-exec-*/`) **disappear** —
the implementation chooses the new path; the rule that was hiding them
becomes redundant and is removed.

## DAG

```
F0-runtime-zig            (the one-callsite path rewrite)
F1-gitignore-cleanup      (remove the now-dead .tmp-exec-*/ rule + verify .botopinkbuild/ swallows tmp/)
F2-build-clean-tmp        (build.zig clean-tmp step + 1-day TTL reap)
F3-tests-pin-layout       (runtime_scratch.zig snap: assert path under .botopinkbuild/tmp/<hex>/)
F4-agents-and-changelog   (AGENTS.md + CHANGELOG.md sweep)
```

---

## F0 — `runtime.zig` `makeScratchDir` rewrite

**Files**: `modules/compiler-core/src/codegen/runtime.zig` (lines 41–51).
**Status**: done — pending merge to `feat`

Current:
```zig
fn makeScratchDir(io: anytype, buf: *[64]u8) ![]const u8 {
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const id = std.mem.readInt(u64, &rand_bytes, .little);
    const tmp_dir = std.fmt.bufPrint(buf, ".tmp-exec-{x}", .{id}) catch unreachable;
    try std.Io.Dir.cwd().createDirPath(io, tmp_dir);
    return tmp_dir;
}
```

After:
```zig
const TMP_ROOT = ".botopinkbuild/tmp";

fn makeScratchDir(io: anytype, buf: *[96]u8) ![]const u8 {
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const id = std.mem.readInt(u64, &rand_bytes, .little);
    const tmp_dir = std.fmt.bufPrint(buf, "{s}/{x}", .{ TMP_ROOT, id }) catch unreachable;
    try std.Io.Dir.cwd().createDirPath(io, tmp_dir);
    return tmp_dir;
}
```

Buffer grows from 64 to 96 to fit the longer prefix.

## F1 — `.gitignore` cleanup

**Files**: `repository/botopink-lang/.gitignore`.
**Status**: done — pending merge to `feat`

Remove the line:
```
# BEAM/runner scratch dirs left behind by exec-style tests (per-run hex suffix).
**/.tmp-exec-*/
```

The umbrella `.botopinkbuild/` rule (already present) covers the new tmp
path. Keep a 30-second post-merge sweep to delete any stray
`.tmp-exec-*/` dirs left over from before this spec.

## F2 — `build.zig` `clean-tmp` step (1-day TTL reap)

**Files**: `repository/botopink-lang/build.zig`.
**Status**: done — pending merge to `feat`

Add a step `clean-tmp` that runs (cross-platform-safe):
```
find .botopinkbuild/tmp -type d -mindepth 1 -maxdepth 1 -mtime +1 -exec rm -rf {} +
```

Wire it as a dependency of `zig build test` (`b.getInstallStep().dependOn(&clean_tmp_step.step)`) so it runs at the start of every test cycle. A 1-day TTL means active runs never delete each other's dirs.

## F3 — `runtime_scratch.zig` pin (NEW test)

**Files**: `repository/botopink-lang/modules/compiler-core/src/codegen/tests/runtime_scratch.zig` (NEW, ~30 LOC).
**Status**: done — pending merge to `feat`

Pin the new path layout. Test outline:

```zig
test "makeScratchDir lands under .botopinkbuild/tmp/<hex>/" {
    // make a scratch dir, assert path starts with ".botopinkbuild/tmp/", assert dir exists
}

test "executeJavaScript cleans up on success" {
    // run trivial JS, assert no .botopinkbuild/tmp/<hex>/ left behind
}

test "executeJavaScript leaks dir only inside .botopinkbuild/tmp/ on simulated crash" {
    // force a crash via aux file syntax error, assert leaked dir is under .botopinkbuild/tmp/, NOT a root sibling
}
```

## F4 — AGENTS.md + CHANGELOG.md sweep

**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/AGENTS.md` — runtime § bullet on tmp layout.
  - `repository/botopink-lang/AGENTS.md` — bullet under Build & test referencing the new path.
  - `repository/botopink-lang/CHANGELOG.md` — entry.
  - `tasks/v0.beta.20/status.md` (row → done).

## Optional follow-ups (out of scope; tracked here for v0.beta.21)

- **Aggressive cache reuse**: today every test writes a fresh `tmp_run.js` for the same source compile. If we hash the (source + backend) tuple and reuse the dir name when the hash hits, repeat invocations of identical fixtures can skip the file write entirely. Belongs in a separate spec — scope here is path consolidation + cleanup.
- **Parallel test workers**: the test runner is already concurrent (per-binary), but `node`/`escript` invocations serialize on subprocess fork. A per-worker subprocess pool would reduce fork cost. Belongs to a separate runtime-perf spec.
- **erl_crash.dump suppression**: `modules/compiler-core/erl_crash.dump` is a leaked artifact from `escript` crashes. `runtime.zig` could `ERL_CRASH_DUMP=/dev/null` before forking. Trivial, ~3 LOC, but separate scope.

## Exit gate

- `repository/botopink-lang/` has zero `.tmp-exec-*/` dirs after `zig build test` on a fresh clone.
- All per-test scratch lives under `<compiler-core>/.botopinkbuild/tmp/<hex>/`.
- `runtime_scratch.zig` pin tests pass on every backend.
- `git status` is clean after `zig build test` (no untracked siblings of `modules/compiler-core/`).
- `clean-tmp` step reaps leaks older than 1 day; manual `zig build clean-tmp` works.
- AGENTS.md per affected module updated in the same commit as the code.
