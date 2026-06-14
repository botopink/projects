# TODO — frente-c-distribution (v0.beta.19)

> Branch: `task/frente-c-distribution` · Worktree: `.tasks/frente-c-distribution/`
> Spec: [`tasks/v0.beta.19/specs/frente-c-distribution.md`](tasks/v0.beta.19/specs/frente-c-distribution.md)
> Set umbrella: [`tasks/v0.beta.19/README.md`](tasks/v0.beta.19/README.md)
> Reasoning + decisions: [`tasks/v0.beta.19/plan.md`](tasks/v0.beta.19/plan.md)
>
> Edit code **inside this worktree only**. Pre-commit runs zig fmt +
> build + test (no `--no-verify`).

## Internal ordering

```text
§H ──▶ §I ──▶ §J
§K — independent, parallel; environment plumbing only
```

- **§H first** — §I's mergeback wants the online path live so the smoke
  test is end-to-end.
- **§I before §J** — `module-auto-tag` reads `botopink.json` versions;
  submodule pointers must be stable before the workflow fires.
- **§K fire-and-forget** — scripts + `build.zig` only.

---

## §H — bpmp online (v0.beta.18 "pinned for follow-up")
- [x] **H1** — `download.fetch` wired to `std.http.Client` (streaming +
      retry max 3, backoff). Cache-hit fast path preserved.
- [x] **H2** — `extract.extractTarGz` / `extractZip` use `std.tar` /
      `std.zip`. Round-trip a known archive in tests (system `tar`-gated
      so non-POSIX runners skip cleanly).
- [x] **H3** — `bpmp self update` POSIX path: `$BPMP_HOME/bin/bpmp.new` →
      `rename` over `bpmp` while running. Windows deferred-swap helper
      prints the exact `cmd /c move` swap line.
- [x] **H4** — `bpmp use botopink <ver>` / `latest` → 4-binary toolchain
      install via `release.installOne`; `bpmp sync` → live `liveTags`
      drift reporting.
- [x] **H5** — `bpmp pack` tar writer (`std.tar.Writer` +
      `std.compress.flate.Compress` gzip) + `.sha256` sidecar.
      End-to-end verified.
- [x] **H6** — `bpmp install` warns when active toolchain (from `stable`
      sentinel) is outside the manifest's `botopink` range.
- [x] **H7** — Lib-repo `test.yml` opt-in release fast-path
      (`vars.BOTOPINK_USE_RELEASE_FASTPATH`); 4 libs updated + bumped.
- [ ] **H8** — `botopink.dev/install.sh` redirect (v18 spec C1.F3) — ops
      step, post-merge. **Confirm with Eric before flipping.**

## §I — distribution submodule mergeback

> **Gotcha:** one PR at a time per sibling; bump root after each. No
> automation races the 6 merges. Per memory rule
> `feedback_user_works_in_parallel`, re-check `git status` immediately
> before each merge / bump.

> **Closed early.** The v0.beta.18 mergebacks already landed (parent's
> `b4b3098 merge: task/distribution into feat` + the per-sibling pushes
> directly to `feat`); no `task/distribution` branch remains on any
> sibling's remote. §H's commits exercised the same merge-into-feat +
> bump workflow on 5 of the 6 sibling submodules (botopink-lang, erika,
> jhonstart, onze, rakun); vscode-extension was already in sync.

- [x] **I1a** — `repository/botopink-lang` — task/distribution already on
      feat (5f02b03); §H1–§H6 + §J added on top, merged to feat, pushed
      (botopink-lang feat = 745a2ef after §K commit).
- [x] **I1b** — `repository/erika` — no task/distribution branch; feat
      bumped by §H7 to 4b722be.
- [x] **I1c** — `repository/jhonstart` — feat bumped by §H7 to 925634b.
- [x] **I1d** — `repository/onze` — feat bumped by §H7 to 3345c20.
- [x] **I1e** — `repository/rakun` — feat bumped by §H7 to 6dce324.
- [x] **I1f** — `repository/vscode-extension` — feat bumped by §J to
      b7a5829.
- [x] **I2** — six submodule SHAs bumped across §H1–§H6 / §H7 / §J / §K
      commits (one commit per logical bump; convention preserved).

## §J — module-auto-tag (v0.beta.18 spec 6 receipt)

> Spec is **immutable**: see
> [`tasks/v0.beta.18/specs/module-auto-tag.md`](tasks/v0.beta.18/specs/module-auto-tag.md).
> This section is the implementation receipt.

- [x] **J0** — Skipped sub-worktree spawn (no `.tasks/module-auto-tag/`);
      §J landed inside this worktree alongside §H7+§I bumps. Submodule
      pointers were stable when §J committed (5/6 had just been bumped).
- [x] **J1** — implemented `module-auto-tag.md` **as authored**:
      - [x] path-scoped tags `compiler-core/<ver>[-feat]` +
            `compiler-cli/<ver>[-feat]` in
            `repository/botopink-lang/.github/workflows/tag.yml`
      - [x] `<ver>[-feat]` tags in
            `repository/vscode-extension/.github/workflows/tag.yml`
            (with package.json drift check)
      - [x] new `botopink.json` carrying `version` for each of the three
            units (compiler-core, compiler-cli, vscode-extension)
            + a Tagging section in each unit's AGENTS.md.
- [ ] **J2** — fork smoke-test deferred to the maintainer (requires GH
      Actions runs against a fork; the YAML is identical to v18 spec).
- [x] **J3** — merged into feat (botopink-lang 5aa68da, vscode-extension
      b7a5829) + bumped from the parent worktree (commit `chore(...)
      module-auto-tag`).

## §K — v0.beta.17 environment deferreds
- [x] **K1** — `scripts/test-libs.sh` wrapper pre-flights
      node/escript/erlc/wasmtime with install hints; `install-tooling.sh`
      gains the same advisory probe; `repository/botopink-lang/AGENTS.md`
      documents the runtime requirements matrix. `zig build test-libs`
      routes through the wrapper.
- [x] **K2** — `scripts/test-vscode.sh` lazy-runs `npm ci` gated on
      `repository/vscode-extension/node_modules/.botopink-installed`;
      `zig build test-vscode` routes through the wrapper.

---

## Done gate (whole frente)

- [x] §H 7 of 8 ticked (H8 is an ops step pending Eric's confirmation).
- [x] §I 6 sibling merges + 6 submodule SHA bumps committed (across the
      §H1–§H6 / §H7 / §J / §K commits, one per logical bump).
- [x] §J `module-auto-tag` implemented + merged. Fork smoke (J2)
      deferred to maintainer.
- [x] §K env-aware gating in place (wrappers + AGENTS.md matrix).
- [x] `zig build test` + `zig build test-bpmp` green; `zig build
      test-libs --target commonJS --lib std` end-to-end smoke green
      through the new wrapper; `zig build test-vscode` ready (will
      `npm ci` on first run).
- [x] every touched AGENTS.md updated in the same commit as the code.
- [x] commit message convention: `feat(...)` / `chore(submodules): ...` /
      `ci(...)`; English; no `--no-verify`.

## Per-memory reminders

- SSH for all git remote ops (`feedback_always_ssh_git`); origin is
  `git@github.com:botopink/projects.git`.
- Re-check `git status` immediately before every merge / bump
  (`feedback_user_works_in_parallel`).
- Worktree paths for Read/Edit (`project_worktree_workflow`); this
  worktree is at `.tasks/frente-c-distribution/`.
- After each commit, advance to the next checkbox (`feedback_continue_after_commit`).
