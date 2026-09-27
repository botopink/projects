# Front 73 — Starters and example projects (the consumer surface)

**Priority:** medium — one starter is missing, one starter breaks decision 113, three examples are build-only cells whose `botopink run` has never been asserted since the compiler started shipping sidecars, and seven planned examples need a decision
**Carries:** — (`starters/**` and `examples/**` had no 1.0.11-beta owner otherwise)
**Depends on:** maintainer 03r-af (the seven examples), 03r-r (confirmation), lg2-v / PK-7 (a git dependency with a subdirectory — the out-of-tree install; stays open) · the toolchain row re-measure (`botopink build --target erlang` ships sidecars into `out/erl/`; `botopink run` compiles them — the closed 03r-a's *compiler half*)
**Owns:** `repository/rakun/starters/**` · `repository/rakun/examples/**` · `modules/README.md` § starters and examples · `repository/rakun/README.md` § Getting started · `modules/rakun/test/starter_manifest_test.bp` (the starter cells; carve-out from 04)
**Does not touch:** `modules/**` otherwise · `repository/onze/**`

---

## Carried from 1.0.10

| Id | From | Item |
|---|---|---|
| `rakun-starter-app` | closed `modules.md` § Starters ("Front 73's eight, plus one") | `starters/rakun-starter-app/` — `rakun-starter-web`, `rakun-app`, `rakun-cache` — is not on disk |
| `rakun-starter-test` → `onze` | measured: `starters/rakun-starter-test/botopink.json` `"onze": { "path": "../../../onze" }` | a rakun manifest names an onze module; decision 113 forbids it and the mocking library it pointed at is retired (`#[mock]` is std's `testing.mocks`) |
| RX-6 | closed `README.md` § What rakun still owes | seven example projects never started — 03r-af |
| R04 "blocked" | closed `04-rakun-erlang-runtime/README.md` § Blocked · 03r-a | "`botopink run` in `examples/rakun` dies with `undef rakun_runtime:serve/2`, in `examples/rakun-ssr` with `undef rakun_file_router:register_layout/2`. The three examples build; none runs." — re-measure |
| PK-2 | `02-packaging` audit | `README.md` per example: rakun has 3 examples and none has one |
| `starters/test/**` | closed `modules.md` § Ownership | the directory does not exist; the manifest cells live in `modules/rakun/test/starter_manifest_test.bp` |

## Problem

```
$ cd repository/rakun/examples/rakun && botopink build --target erlang --out out && botopink run --target erlang
```

was `undef rakun_runtime:serve/2` when 1.0.10's front 04 closed; the compiler has since shipped
`out/erl/*.erl` and compiled them under `run`. Nobody has re-run the command. A consumer installing
`rakun-starter-test` pulls a path to `../../../onze` that does not exist outside this checkout.

## Current state

- `starters/`: 8 members, every dependency `{ "workspace": true }` except the `onze` path;
  `starters/README.md`; no `test/`. `modules/rakun/test/starter_manifest_test.bp` and
  `version_set_test.bp` assert the manifests.
- `examples/`: `rakun` (`main.bp`, `config.bp`, `posts.bp`, `users.bp`), `rakun-container`
  (`main.bp`), `rakun-ssr` (`main.bp`); each an erlang `build` cell in `test-libs`; no test file, no
  `README.md`.

## Mechanism

- `botopink run` compiles the shipped `.erl` sidecars onto the code path (the compiler's `run`
  after 1.0.10's `00 · 10`); the example's `Rakun.run` then serves. The re-measure is a cell:
  build, run headless with `rakun.main.headless=true keep-alive=false`, assert exit 0 and the
  banner line. If it still fails, the failure text goes to the milestone's `language-gaps.md`
  toolchain row and the box stays open naming it — the cell is then not written (no skip).
- `rakun-starter-app` is a manifest and a `root.bp`; `starter_manifest_test.bp` gains one row.
- The `onze` edge is deleted; `rakun-starter-test`'s `root.bp` re-exports `rakun-test` only.

## Gate stance

The three examples are build cells today and stay cells; the `run` cell is added only when it
passes (a failing one is a language-gaps row, not a red). No env-gated cell.

## Steps

### Step 1 — The starters

**Acceptance:**
- [ ] `starters/rakun-starter-app/{botopink.json,src/root.bp}` exist; `starter_manifest_test.bp` asserts the nine starters and their `brings` lists
- [ ] `starters/rakun-starter-test/botopink.json` names `rakun-starter` and `rakun-test` only; `grep -rn onze repository/rakun/starters` answers nothing
- [ ] `starters/README.md` lists nine and states the workspace rule (03r-r)

### Step 2 — The examples run

**Acceptance:**
- [ ] `examples/rakun`: `botopink build --target erlang --out out` then `botopink run` headless exits 0 and prints the banner — asserted by a cell in `modules/rakun/test/starter_manifest_test.bp` (renamed `consumer_surface_test.bp`) that drives the compiler through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`, the way `rakun-cli`'s tests do
- [ ] the same for `examples/rakun-container` and `examples/rakun-ssr` (the ssr one answers `/` over a loopback socket with the text its renderer writes)
- [ ] if any of the three fails on a sidecar load, the milestone's `language-gaps.md` toolchain row is re-pinned with the measured text and the box stays open naming it
- [ ] each example has a `README.md` (what it shows, how to run it)

### Step 3 — The seven (03r-af)

**Acceptance:**
- [ ] under (a): `modules/README.md` § Examples lists the three and says the seven were retired; the closed `test-snap-examples.md` is not referenced from any live document
- [ ] under (b)/(c): one front directory per example is opened in this milestone by the maintainer, each after the member fronts it exercises; nothing here

## Gate

- [ ] `zig build test-libs -- --target erlang --lib rakun` lists the nine starter cells and the three example cells green
- [ ] `botopink format --check` clean in `starters/**` and `examples/**`
- [ ] `modules/README.md`, `starters/README.md`, `repository/rakun/README.md` updated
- [ ] commit on `fix/73-rakun-starters`

## Blast radius

Deleting the `onze` edge affects no consumer in the repository. Adding a starter adds a manifest
cell. The `run` cells add ~3 s each to the rakun core's suite (a compiler invocation each) — under
the 60 s budget of the core cell; if they push it over, they move to a `consumer_surface` member
of their own, named here.

## Notes

- lg2-v (a git dependency with a subdirectory) is what an out-of-tree consumer needs to install a
  starter from `git`; the box from the closed 73 ("a consumer cannot ship a git dependency") stays
  open, owned by the compiler.
- PK-5 (`format --check` drift in `modules/{rakun,rakun-app}`) is 04's and 22's, in their gates.
