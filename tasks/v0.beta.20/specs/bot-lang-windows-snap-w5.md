# bot-lang-windows-snap-w5 — defer bot-lang windows-2022 `allow_fail` to v0.beta.21

**Slug**: bot-lang-windows-snap-w5
**Depends on**: `ci-tail-02-backends-parity (W half)` — the in-flight `snap.zig` `normalizeForCompare` pass (CRLF → LF + `\\` → `/` on path-bearing lines, landed in bot-lang `531b884`) collapses most CRLF / path-sep drift at compare time, but a residual of recorded snapshots was authored on an LF host and any line the normaliser does not catch still mismatches under windows-2022. Until a green windows-2022 cycle confirms zero residual drift, the bot-lang `test (windows-2022)` row keeps `allow_fail: true`.
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/utils/snap.zig`
    (W3 landed; tighten the path-bearing heuristic only if W4 surfaces a residual the current pass misses)
  - `repository/botopink-lang/modules/compiler-core/snapshots/**/*.snap.md`
    (regen the residual baselines on the windows-2022 runner via the W4 diagnostic upload — `.snap.md.new` capture step)
  - `repository/botopink-lang/.github/workflows/test.yml`
    (W5: drop the `windows-2022` `allow_fail: true` row once W4 confirms green)
**Touches docs**: `tasks/v0.beta.20/status.md` (ci-tail row) · `tasks/v0.beta.21/status.md` (created when v21 opens).
**Status**: **deferred to v0.beta.21** — this spec is the audit + ticket; the
W4 regen sweep + W5 row drop do not land in v0.beta.20.

## Why deferred

The W3 normalisation is a source-side change that ships as part of ci-tail
without observing a windows-2022 runner. Determining whether it closes
every residual line of drift requires:

1. A windows-2022 cycle running under the new normalisation, with the
   diagnostic `.snap.md.new` upload step active (W4 path inside the
   ci-tail spec, §W4 lines 673-683).
2. A walk of the uploaded `.snap.md.new` files; any mismatch is either
   - a path-separator case the normaliser does not yet catch (tighten
     `normalizeForCompare` heuristic in W3 source), or
   - a baseline that genuinely needs a windows-side LF regen.
3. Commit the regen as a separate bot-lang commit (W4 closeout).
4. Flip `allow_fail: true` → `false` on the `windows-2022` row of
   `repository/botopink-lang/.github/workflows/test.yml` (W5).

Steps 1-4 chain linearly; running them inside ci-tail would couple CI
hygiene to a runner observation cycle that this spec wave has no slot
for. The ci-tail exit gate calls this out as residual #1 and points
here as the audit; W4+W5 land under v0.beta.21 once a runner cycle
provides the regen data.

## What landed in ci-tail (and why W4+W5 still need a runner)

- **W1** — `shell: bash` on the 4 sibling-lib source-test step:
  landed in the four sibling submodule bumps (erika `2000be7` ·
  jhonstart `765596b` · onze `e4448b4` · rakun `7aa92c8`).
- **W2** — drop sibling-lib `windows-2022` commonJS `allow_fail`:
  landed in the four sibling rebumps (erika `b84bd3e` ·
  jhonstart `0691d0b` · onze `c56c729` · rakun `99916fd`) bundled
  under meta `6c5e4e1`.
- **W3** — `snap.zig` `normalizeForCompare`: landed in bot-lang
  `531b884`. Compares now collapse CRLF + path-sep drift in-flight.

W4 + W5 are the residual closure path described above.

## Reproducing the residual (when v21 opens)

```bash
# 1. Push any noop change to bot-lang feat with W4's `.snap.md.new`
#    upload step temporarily active (gated on a workflow_dispatch input
#    `upload-snap-new=true`).
# 2. After the windows-2022 cycle completes:
gh run download <run-id> --repo botopink/botopink-lang \
  --name snap-new-windows-2022 --dir /tmp/snap-new-windows-2022
# 3. Walk the downloaded tree; each `.snap.md.new` whose paired
#    `.snap.md` differs after running the W3 normaliser locally is a
#    regen candidate.
# 4. Commit the regen.
# 5. Flip `allow_fail: true` → `false` on the windows-2022 row.
```

## Single ticket vs split

W4 + W5 belong together — W5 cannot land until W4 confirms the runner
goes green under the new normalisation. Recommendation: **single
follow-up spec under `v0.beta.21`** named `bot-lang-windows-snap-close`
that ships both W4 (regen sweep) and W5 (`allow_fail` drop) in a single
bot-lang commit pair, mirroring the W1+W2 grouping the sibling libs
already shipped under ci-tail.

## Why not in v0.beta.20

ci-tail's exit gate calls this out as DEFERRED residual #1 — the spec
text already documents the W3+W4+W5 chain at `ci-tail.md` §W3-W5 (lines
642-702), but landing W4+W5 without a runner cycle observation means
either:
- shipping the row drop blind (risks reintroducing a red on every push
  if residual drift exists); or
- gating the row drop on a separate validation step inside ci-tail
  (couples CI hygiene to runner cadence the spec wave is not paced
  for).

Neither matches the ci-tail charter. This audit + ticket carries the
residual forward to v0.beta.21 where a fresh wave can absorb the
runner cycle.

## Exit gate (for v0.beta.21)

- `gh run list --repo botopink/botopink-lang --workflow test --branch
  feat --limit 1` reports `success`, with the `windows-2022` axis green
  and no `continue-on-error` / `allow_fail` row.
- `repository/botopink-lang/.github/workflows/test.yml` shows
  `runner: windows-2022` with `allow_fail: false` (or returns to the
  simple list form ci-pipelines-green inherited if every entry is now
  `false`).
- Any snapshot files touched by the W4 regen carry an LF-only baseline
  on disk and round-trip identically under both linux and windows runs.
