# frente-c-distribution — bpmp online, submodule mergeback, module-auto-tag, env deferreds

**Slug**: frente-c-distribution
**Depends on**: nothing for §H/§K (independent of Frentes A/B); §I depends on
  §H having shipped at least one online-fetch round (so the mergeback can be
  smoke-tested end-to-end); §J depends on §I (the submodule pointers must
  be stable before the auto-tag workflow reads them)
**Files**:
  - **§H bpmp online:** `modules/bpmp/src/{download,extract,sha256,registry,resolver}.zig`
    · `modules/bpmp/src/commands/{install,use,sync,pack,self_update}.zig` ·
    `modules/bpmp/AGENTS.md` · `modules/bpmp/docs.md`
  - **§I submodule mergeback:** each sibling repo's `feat` branch
    (cross-repo, not in `repository/botopink-lang`) · the submodule pointer
    bumps at the root
  - **§J module-auto-tag:** see `tasks/v0.beta.18/specs/module-auto-tag.md`
    for the immutable intent · this section is the implementation receipt ·
    `repository/botopink-lang/.github/workflows/tag.yml` ·
    `repository/vscode-extension/.github/workflows/tag.yml` · 3 new
    `botopink.json` files (`compiler-core`, `compiler-cli`,
    `vscode-extension`)
  - **§K env deferreds:** `scripts/install-tooling.sh` ·
    `scripts/test-libs.sh` (new) · `build.zig` (gate `test-vscode` /
    `test-libs` steps on env presence) ·
    `repository/botopink-lang/AGENTS.md`
**Touches docs**: `modules/bpmp/AGENTS.md` · `modules/bpmp/docs.md` ·
  `repository/botopink-lang/AGENTS.md` · `repository/AGENTS.md`
  (workspace overview) · `CHANGELOG.md`
**Status**: pending

## Background

v0.beta.18 (`distribution`) shipped the language as installable: release
pipeline, installer, bpmp, lib-test workflows. Tail items:

- **Pinned offline-safe stubs** in `modules/bpmp/AGENTS.md` "Pinned
  offline-vs-online status" — HTTP / tar wiring / self-update swap are
  scaffolded but error with `OnlineUnavailable`.
- **Lib-submodule SHA bumps** — each lib repo's `task/distribution` head
  needs to merge into its sibling repo's `feat` first; then
  `repository/botopink-lang`'s pointers move forward.
- **`module-auto-tag`** — the 6th v18 spec, explicitly deferred out of
  `distribution`. Path-scoped tags for `compiler-core` / `compiler-cli` and
  own-repo tags for `vscode-extension`.
- **v0.beta.17 environment deferreds** — `zig build test-libs` cross-root
  needs `node`/`escript`; `zig build test-vscode` needs `npm install`.

This frente owns all four. Four internal sections:

| Section | Closes | Description |
|---|---|---|
| **§H** | v0.beta.18 pinned follow-ups | bpmp online — HTTP / tar / self-update swap / online resolution |
| **§I** | v0.beta.18 distribution tail | merge `task/distribution` → `feat` in each sibling repo; bump submodule SHAs |
| **§J** | v0.beta.18 spec 6 | implement `module-auto-tag.md` as authored |
| **§K** | v0.beta.17 F6 deferreds | env-aware gating for `test-libs` + `test-vscode` |

## Internal ordering

```text
§H ──▶ §I ──▶ §J
§K — independent, parallel with everything; environment plumbing only
```

- **§H first.** §I's mergeback wants the online path live so the smoke test
  is end-to-end.
- **§I before §J.** `module-auto-tag` reads the `botopink.json` version
  fields; the submodule pointers must be stable before the workflow fires.
- **§K is fire-and-forget.** Touches scripts + build.zig only; no
  dependency on the distribution track.

---

## §H — bpmp online (close v0.beta.18 "pinned for follow-up")

**Files**: `modules/bpmp/src/{download,extract,sha256,registry,resolver}.zig`
· `modules/bpmp/src/commands/{install,use,sync,pack,self_update}.zig` ·
`modules/bpmp/AGENTS.md` · `modules/bpmp/docs.md`

The bpmp pinned stubs from `modules/bpmp/AGENTS.md` "Pinned
offline-vs-online status". `bpmp.md` (v0.beta.18) already documents the
*intent* — this section wires it.

- [ ] **H1** — `download.fetch` wired to `std.http.Client` with streaming +
      retry (max 3, backoff). Cache-hit fast path (already in) preserved.
- [ ] **H2** — `extract.extractTarGz` / `extractZip` use `std.tar` /
      `std.zip` (the strip-leading-dir helper is already in + tested).
      Round-trip a known archive in tests.
- [ ] **H3** — `bpmp self update` POSIX path: write `$BPMP_HOME/bin/bpmp.new`
      → `rename` over `bpmp` while running. Windows deferred-swap helper:
      write `.new`, run a shim that swaps on next launch. Document the
      Windows manual test.
- [ ] **H4** — `bpmp use botopink <ver>` / `bpmp sync` online resolution.
      Today both error with `OnlineUnavailable`; with H1 in, resolve from
      GitHub Releases.
- [ ] **H5** — `bpmp pack` tar writer (manifest validation already in).
- [ ] **H6** — `bpmp install`'s live diff against the active toolchain: the
      manifest write already records the constraint; surface a warning when
      the active compiler is outside the range.
- [ ] **H7** — Lib-repo `test.yml` release fast-path (v18 spec B2.F2): once
      A2 has published one tag, each lib's CI can `curl … | sh install.sh`
      instead of building from source.
- [ ] **H8** — `botopink.dev/install.sh` redirect (v18 spec C1.F3) — ops
      step, post-merge. Confirm with Eric before flipping.

### Test scenarios — §H

```
H1  ---- bpmp install <pkg> reaches github.com over HTTPS, streams the tarball, verifies sha
H2  ---- extractTarGz round-trips a known archive; extractZip same on a Windows asset
H3  ---- bpmp self update swaps the live binary; subsequent `bpmp version` reads the new
H4  ---- `bpmp use botopink 0.0.1` resolves online; `bpmp sync` reports drift
H5  ---- `bpmp pack` produces a valid `dist/<name>-<ver>.tar.gz`
H6  ---- `bpmp install` warns when active compiler is outside `botopink.json.botopink` range
```

## §I — distribution submodule mergeback

**Files**: each sibling repo's `feat` branch (cross-repo, not in
`repository/botopink-lang`) · the submodule pointer bumps at the root

After §H lands, the v0.beta.18 work currently on `task/distribution` in
each sibling has to migrate into each sibling's `feat`, then the root's
submodule pointer follows.

- [ ] **I1** — Merge `task/distribution` → `feat` inside each of
      `repository/{botopink-lang,erika,jhonstart,onze,rakun,vscode-extension}`.
      Each sub-repo's `task/distribution` is a one-PR mergeback — no
      surprise conflicts expected (the workflows are wholly under
      `.github/workflows/`, none of which `feat` touched).
- [ ] **I2** — Bump the 6 submodule SHAs in `repository/botopink-lang`'s
      `feat` to point at each sibling's freshly-merged `feat` head. One
      commit per submodule, conventional message
      `chore(submodules): bump <name> for v0.beta.18 mergeback`.

### Test scenarios — §I

```
I1  ---- each sibling repo's `task/distribution` has merged into `feat`; `git log feat..task/distribution` is empty
I2  ---- `git submodule status` in repository/botopink-lang reports 6 clean SHAs all on each sibling's `feat`
```

### Notes — §I

- **One PR at a time per sibling, bump root after each.** A partial state
  still bisects cleanly. No automation races the 6 merges.
- **Per memory rule `feedback_user_works_in_parallel`:** re-check
  `git status` immediately before each merge / bump — Eric may have
  advanced something in another terminal.

## §J — module-auto-tag (v0.beta.18 spec 6, deferred)

**Files**: see `tasks/v0.beta.18/specs/module-auto-tag.md` for the
**immutable** intent · this section is the implementation receipt ·
`repository/botopink-lang/.github/workflows/tag.yml` ·
`repository/vscode-extension/.github/workflows/tag.yml` · 3 new
`botopink.json` files

- [ ] **J0** — Spin a `.tasks/module-auto-tag/` worktree from `feat` (after
      §I lands so the submodule pointers are stable).
- [ ] **J1** — Implement `module-auto-tag.md` **as authored**: path-scoped
      tags `compiler-core/<ver>[-feat]` + `compiler-cli/<ver>[-feat]`
      inside `repository/botopink-lang/.github/workflows/tag.yml`;
      `<ver>[-feat]` inside `repository/vscode-extension/.github/workflows/tag.yml`;
      new `botopink.json` carrying `version` for each of the three units.
- [ ] **J2** — Smoke-test in a fork (feat push moves the tag; master push
      cuts an immutable; no-bump push reds the gate).
- [ ] **J3** — Merge `task/module-auto-tag` → `feat`, push, bump the
      `compiler-core` / `compiler-cli` submodule SHAs.

### Test scenarios — §J

```
J2  ---- module-auto-tag fork smoke green on all three move/immutable/red scenarios
J3  ---- `task/module-auto-tag` merged + the three new botopink.json files are on `feat`
```

### Notes — §J

- **Spec is immutable.** Re-authoring would split the source of truth.
  This section's checklist is the *receipt* of executing
  `tasks/v0.beta.18/specs/module-auto-tag.md`, not a re-design.
- **Worktree per universal contract.** §J runs in its own
  `.tasks/module-auto-tag/`.

## §K — v0.beta.17 environment deferreds (close `repo-restructure` F6 tail)

**Files**: `scripts/install-tooling.sh` · `scripts/test-libs.sh` (new) ·
`build.zig` (gate `test-vscode` / `test-libs` on env presence) ·
`repository/botopink-lang/AGENTS.md`

Two follow-ups recorded by v0.beta.17 F6 — both purely environment / driver,
not language work.

- [ ] **K1** — `zig build test-libs` discovers + runs all frameworks across
      sibling repos. Today it needs `node` and `escript` on PATH; document
      the requirement in `repository/botopink-lang/AGENTS.md` and add an
      `install-tooling.sh` check + a clean error when missing.
- [ ] **K2** — `zig build test-vscode` green from the new path. Needs
      `npm install` in `repository/vscode-extension/`; add a one-shot step
      that runs `npm ci` on first invocation, gated on a marker file.

### Test scenarios — §K

```
K1  ---- zig build test-libs reports a clear "needs node/escript" error when missing
K2  ---- zig build test-vscode green from a fresh clone (with one-shot npm ci)
```

---

## Test scenarios (whole frente)

```
H1+H4  ---- bpmp online: install + use/sync from GitHub Releases
H3     ---- bpmp self update swaps the live binary
I2     ---- repository/* submodule SHAs all point at the sibling's `feat` head
J2     ---- module-auto-tag fork smoke green on all three scenarios
J3     ---- compiler-core / compiler-cli / vscode-extension cut their own tags after a bump
K1+K2  ---- zig build test-libs + zig build test-vscode green from a fresh clone
gate   ---- `zig build test` + `zig build test-libs` + `botopink-lib-test` all green
docs   ---- every touched AGENTS.md updated in the same commit (memory rule)
```

## Notes

- **§H before §I before §J.** §H ships the HTTP code; §I uses that path
  end-to-end (a smoke install reaching the freshly-merged lib repo);
  §J's auto-tag workflow assumes the submodule pointers are stable.
- **§K is fire-and-forget.** No dependency on the distribution track.
- **No `--no-verify` ever.** Pre-commit gate stays green.
- **AGENTS.md in the same commit as the code it documents.** Memory rule.
- **Per-memory:** SSH for all git remote ops (`feedback_always_ssh_git`);
  re-check `git status` before every merge / bump
  (`feedback_user_works_in_parallel`); commit messages in English.
