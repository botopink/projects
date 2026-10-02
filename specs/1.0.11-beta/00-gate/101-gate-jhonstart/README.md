# Front 101 — gate-jhonstart: no stale restriction, the dom-test cell decided, the repository's own gate hard

**Priority:** high — jhonstart's cells were green, but three of its manifests carried a
restriction the ledger tolerated (two at `0` failed, one at `1`), and its trees carried the PK-5
format drift decision 132 waits on.
**Depends on:** none to start. `113` lands after it (the three `jhonstart-*` ledger lines go with
the file).
**Owns:** `repository/jhonstart/**` for the duration of the front — `examples/jhonstart-counter/botopink.json`,
`examples/jhonstart-todo/botopink.json`, `modules/jhonstart-dom-test/**`,
`.github/workflows/test.yml`, `.gitignore`, `scripts/git-hooks/**`, a reformat-only commit over
`modules/jhonstart/**` and `modules/jhonstart-link/**`.
**Does not touch:** `repository/botopink-lang/**` (`scripts/restricted-targets.txt` is 113's);
`repository/onze/**`, `repository/rakun/**`; `modules/jhonstart-router`, `-forms`, `-link` source
beyond the reformat (`../../04-jhonstart/` fronts 26, 27, 67 own them).

---

## Current state

Measured 2026-09-26 on the front's tree with the compiler pinned for the front, by running
`botopink test --target <t>` in every member on every target its manifest declares, `botopink build`
in every example, and the repository's pre-commit hook end to end.

| Cell | Manifest | Measured |
|---|---|---|
| `jhonstart-counter·erlang` | no `targets` (inherits the workspace's two) | 4/4 |
| `jhonstart-todo·erlang` | no `targets` | 3/3 |
| `jhonstart-dom-test·erlang` | `"targets": ["commonJS"]` — structural under gate-d | not a cell: `botopink build --target erlang` refuses the member |

Every cell on its declared targets: **29/29** green — 7 members (`jhonstart` 204/204 ×2, `-link`
38 ×2, `-test` 21 ×2, `-forms` 15 ×2, `-emilia` 10 ×2, `-html` 5 ×2, `-dom-test` 9 on commonJS)
and 8 examples on both rows (`blog-ssr` 10, `nav-shell` 6, `islands` 5, `forms` 7,
`document-shell` 4, `jhonstart-counter` 4, `jhonstart-markup` 7, `jhonstart-todo` 3). The
milestone's open counted 27 cells and 3 restricted ones (two passing at `0`, one red at `1`); the
two passing ones are cells now, the red one does not exist.

The audit table gate-d asks for:

| Member | Excluded target | First refusal line of `botopink build --target <t>` |
|---|---|---|
| `jhonstart-dom-test` | `erlang` | ``error: `callGlobal` has no `#[@External.<Target>(…)]` for the erlang backend`` — `src/root.bp:37:12` |

At the open the member's only call sites of its `#[@External.Node]` cells were `test {}` blocks,
which `build` strips, so `botopink build --target erlang` exited 0 and the refusal the earlier
version of this README quoted was `botopink test`'s. The member now calls a node-only cell from
compiled code — `src/root.bp` exposes `callFill(name, id)` and `callSignal(name)` over the raw
`call` cell (module-private), and `test/dom_test.bp` calls the registered functions through them
— so the restriction is what gate-d means by structural: the module cannot exist on the BEAM.
The alternative the 04-jhonstart README offered (widen, and have the erlang row assert the erlang
twins' empty answers) is not writable: the language has no target query and no per-target test
block, so one `dom_test.bp` cannot assert a markup on commonJS and an empty string on erlang
(see *Language gaps* below).

Tolerances in this repository, all removed:

| Was | Where | Now |
|---|---|---|
| pre-commit warned and returned 0 when the compiler was not found; it ran a bare `botopink test` in `modules/*` — each manifest's default `target`, so no erlang cell and no example's tests | `scripts/git-hooks/lib/runner-standalone.sh` | one text in the five library repositories (`sha256sum` equal ×5; the meta `hook-integrity` check 4): a missing compiler fails the gate with the way out (`zig build install`, or `BOTOPINK_BIN`; a `BOTOPINK_BIN` that is not an executable fails too) — scratch clone: exit 1; `botopink test --target <t>` in every workspace member on every target its manifest declares and `botopink build --target <t>` of every example on every declared target — 29 cells, 16 builds, 3 refusals |
| `scripts/known-broken-examples.txt` branch of `runExamplesGate` | same file | deleted; an example that does not build fails |
| no `*.snap.new` guard | `.gitignore`, the hook's staged-files stage | both suffixes ignored and a staged one refused (`git add -f x.snap.new` → exit 1, verified) |
| CI: core member only (`--lib jhonstart`), examples on the commonJS row, `allow_fail` key; OTP on the erlang rows only; `ubuntu-22.04`; a windows row | `.github/workflows/test.yml` | rows `{ubuntu-24.04, macos-14} × {commonJS, erlang}`, every row hard; Erlang/OTP 28 and Node 20 on every row (building the compiler runs `erlc`); one `botopink-lib-test --target <t> --strict` per row from a scratch directory with `BOTOPINK_LIB_ROOTS` naming the repository, so the workspace's fifteen members are the rows and nothing else is (emilia, checked out under `botopink-lang/repository/emilia` for `jhonstart-emilia`'s `path` dependency, is a dependency, not a row); then the hook's other stages (examples on the row's target, refusals) from the hook's own runner; no windows row (gate-f) |
| `repro/**` — four reproductions, none reproducing | `repro/` | deleted; every line that named it states the closed defect instead |
| `botopink format --check` drift | `modules/jhonstart/**`, `modules/jhonstart-link/**` | reformatted, one commit, 28 files; `modules/jhonstart-link/src/link.bp` left as it was (below) |

## Steps

### Step 1 — widen the two examples — done

`"targets"` deleted from both manifests; both cells pass on erlang and commonJS (`counter` 4/4,
`todo` 3/3 on each).

- [x] `botopink test --target erlang` in both examples → pass; both commonJS cells unchanged
- [x] until 113 lands, `zig build test-libs` reports `restricted-targets.txt:53-54` as *stale* —
      expected; 113 deletes the file. The front's own gate is `botopink test` per member

### Step 2 — `jhonstart-dom-test` on erlang — done, (a) made structural

- [x] the audit table above
- [x] `26-jhonstart-router` (`../../04-jhonstart/26-jhonstart-router/README.md` § Notes) points here

### Step 3 — the repository's own gate — done

- [x] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` → 1 and 5; a staged
      `x.snap.new` → hook exit 1; the hook without a compiler binary → exit 1 with the build hint
- [x] `grep -c "allow_fail: true" .github/workflows/test.yml` = 0 (the key is gone)
- [x] the CI command shape verified in the workflow's layout (`botopink-lang/repository/{jhonstart,emilia}` + `libs`),
      from a scratch directory with `BOTOPINK_LIB_ROOTS` naming `repository/jhonstart`:
      `botopink-lib-test --target commonJS --strict` → 15 passed, 0 failed (the fifteen jhonstart rows and no
      other); `--target erlang --strict` → 14 passed, 0 failed, 1 skipped (`jhonstart-dom-test`, by its
      manifest); the hook-stages step → 8 builds and 3 refusals on each target
- [ ] the workflow green on GitHub: at the landed tip it was red on 4 of 5 rows (`erlc: FileNotFound` at
      `zig build install` on the three commonJS rows; `GLIBC_2.36 not found` on `ubuntu-22.04 · erlang`);
      the repaired workflow triggers on `feat` / `master` / `main` and on pull requests only, so its
      first run is the landing

### Step 3b — delete the stale `repro/**` — done

Each of the four was run before deletion: `erlang-imported-fn-field` 2/2 on both targets;
`local-binding-leaks-to-later-decls` refused (`unbound variable 'v' — a local ends with its body`);
`self-param-free-fn` refused (`self-param-outside-type`); `erlang-std-slice-shim` does not compile
(`result-member-not-a-method` on `length`).

- [x] `test ! -e repository/jhonstart/repro`; `AGENTS.md` no longer names the directory

### Step 4 — PK-5 — done but for one file

- [x] `zig build test-libs -- --lib jhonstart` and `-- --lib jhonstart-link` on both targets →
      pass (204/204, 38/38, measured with `botopink test` in each member after the reformat; a second
      `botopink format` changes nothing)
- [ ] `botopink format --check modules/jhonstart modules/jhonstart-link` → exit 0. **Exit 1 for one
      file**: the formatter rewrites the five record-update spreads in `modules/jhonstart-link/src/link.bp`
      (`LinkProps(..p, prefetch: prefetch)`, `:76,80,84,88,92`) to `LinkProps(..: p, …)`, which the parser
      refuses (``this token cannot appear here — unexpected `:` `` at `link.bp:76:24`), and the member no
      longer compiles. The file is left unformatted. Owner: `112-gate-format` (the printer of the
      record-update spread, `modules/compiler-cli/src/cli/format_cmd.zig` and the printer it calls) —
      this is the "1 that cannot be formatted" the track's open counted. Rewriting `link.bp` without the
      spread would be a source change of `27-jhonstart-link` and a workaround of a compiler defect.

## Gate

- [x] every jhonstart cell `pass` on its declared targets — 29/29 (above)
- [x] `(cd repository/jhonstart && scripts/git-hooks/pre-commit)` green: 29/29 cells (fourteen members on
      both targets, `jhonstart-dom-test` on commonJS), 16/16 example builds, 3/3 refusals; the workflow's
      command shape verified as in step 3
- [ ] the workflow green on GitHub (step 3's open box — the landing)
- [x] `repository/jhonstart/AGENTS.md` updated; commits on `front/101-gate-jhonstart` in the jhonstart
      submodule

## What is left

| Item | Owner |
|---|---|
| `link.bp`'s record-update spread through `botopink format` (step 4's open box); once the printer is fixed, `botopink format modules/jhonstart-link/src/link.bp` is the remaining PK-5 commit | `112-gate-format` |
| `restricted-targets.txt:53-55` — the three `jhonstart-*` lines are stale (two cells now run, one member now refuses the build) | `113` (deletes the file) |
| The workflow's first green run. It triggers on push / PR to `feat`, `master`, `main` only; at the landed tip it was red on 4 of 5 rows, and the repaired file is unrun until it is on `feat` | the landing |
| The linux rows are `ubuntu-24.04` because nothing built from botopink-lang starts on `ubuntu-22.04`: `build.zig:745` pins the bundled glibc at 2.38, Zig's std then calls `arc4random_buf` (glibc ≥ 2.36), and 22.04 ships 2.35 (`version 'GLIBC_2.36' not found`). The compiler's own `ubuntu-22.04` row is red for the same reason. A pin ≤ 2.35 at that line lets either runner work | `114` / `../../01-compiler/` (`build.zig`) |
| No windows row: botopink-lang has none (gate-f), and `manifest` / `lib-test-runner` discovery tests were red on windows in its last windows run. A library row returns with the compiler's | `114` |
| `botopink-lib-test` has no workspace selector (`--lib` takes one member name). The workflow gets "this workspace's members and nothing else" from a scratch working directory plus `BOTOPINK_LIB_ROOTS`; a `--workspace <dir>` flag would say it directly | `113` / `115` (`modules/lib-test-runner/**`) — optional |

## Language gaps

| Gap | Where it bit | What would close it |
|---|---|---|
| No target query at comptime or run time, and no per-target `test` block: one test file cannot assert different values on commonJS and erlang | `modules/jhonstart-dom-test/test/dom_test.bp:25` (a markup on commonJS; the erlang twins of `registerFill` / `payloadText` answer `0` / `""`, `sidecars/jhonstart_render.erl:143-145`) | a `#[target(commonJS)]`-style attribute on `test`, or a comptime target constant; until then a host-bound member restricts `targets` and the build refusal is the audit |
| `botopink format` mangles the record-update spread `T(..p, k: v)` into `T(..: p, k: v)` | `modules/jhonstart-link/src/link.bp:76` | the printer emits `..p` as parsed |
| A `#[@External.Node]`-only cell that is declared and never called from compiled code builds on erlang, so a test-only member with no compiled call site passes `botopink build --target erlang` and fails only `botopink test` | `modules/jhonstart-dom-test/src/root.bp` at the open | by design (`docs.md` § Every cell carries both targets); the gate-d audit should say so: a member whose only call sites are test blocks is audited by `botopink test`'s refusal, or restructures as this one did |

## Blast radius

- `26-jhonstart-router`, `27-jhonstart-link`, `67-jhonstart-forms` (`../../04-jhonstart/`) start
  from this front's landing (the reformat of `modules/jhonstart` and `modules/jhonstart-link`
  touches every file they own; `link.bp` is the one file untouched).
- `113` deletes `restricted-targets.txt:53-55` with the file; `04-jhonstart/modules.md:34,36`
  (the "stale restriction — `00-gate`" cells) close on this landing.
- `emilia`'s examples depend on jhonstart (`repository/emilia/.github/workflows/test.yml:136`
  checks out jhonstart for the examples gate) — 109 verifies against this tree; jhonstart's CI now
  checks out emilia the same way, for `jhonstart-emilia`.
