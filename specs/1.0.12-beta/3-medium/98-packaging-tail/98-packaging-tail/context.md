# Front 98 — packaging tail: the rule checked across the seven repositories

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../../../1-botopink-lang/144-botopink-lang/README.md): s2 → B-27 · s3 → B-27; [145-erika](../../../2-libraries/145-erika/README.md): s1 → 145 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium — compiles nothing differently; the packaging rule holds only once it lands ·
**State:** partial: step 4 done; steps 1–3 open
**Depends on:** the library tracks' `-test` and example-README steps (`05-jhonstart/26` step 6,
`06-emilia/33` steps 1–2, `07-onze/50` step 8 and `53` step 1, `04-rakun`'s `rakun-test` front
`19-rakun-test-utilities`) · `95-f` (step 3)
**Owns:** `repository/erika/modules/erika-test/**`, `repository/erika/examples/erika-linq/README.md`,
`repository/erika/AGENTS.md` (erika has no track) · `repository/botopink-lang/scripts/check-packaging.sh`
(new) · `repository/botopink-lang/docs/botopink-json.md` · decision-75 carve-out, step 4 only:
`repository/botopink-lang/modules/manifest/**`, `bpmp/src/manifest.zig`, the `manifest.scanRoots`
call sites named in the 1.0.10 `02-packaging` README · this directory
**Does not touch:** `examples/*/README.md` or `modules/<lib>-test/**` of rakun, jhonstart, emilia,
onze (their tracks write, this front greps) · `libs/**` (97) · `scripts/test-libs.sh`, `.gitignore`,
the hooks · `compiler-core/**`, `compiler-cli/**` beyond the named call sites

## Goal

Every library: a workspace with a core, a `-test` member exposing `assert<Subject>(loc, …)` helpers
(contract: [`test-helpers.md`](test-helpers.md)), examples as members with a `README.md`; a script
proves it across `repository/*`; the onze takeover and git-subdirectory question closed.

Measured on feat:

| Rule | Holds | Does not |
|---|---|---|
| every library is a workspace; every member lists `files` | all five | — |
| every library has a `-test` member with one inline test | all five | — |
| the `-test` member exposes ≥ one `assert<Subject>(loc, …) -> @Result<void, string>` | jhonstart (11 helper files), onze (`core.bp`: 4) | **emilia** (`root.bp` only), **rakun** (`expect*` booleans only), **erika** (`src/root.bp` only, no `test/`) |
| every example carries a `README.md` naming the upstream section and the front | — (onze: one directory-level `examples/README.md`) | **29 of 29** |
| no example depends on an ecosystem library by `git` | all | — |
| a monorepo member is installable from git | `DepSpec.subdir` (step 4, decision 344) | — |

## Mechanism

Four checks (step 2's script):
1. `find repository/*/examples -maxdepth 2 -name README.md` count = `botopink.json` count;
2. every `modules/*-test/src/*.bp` holds ≥ one `pub fn assert[A-Z][A-Za-z]*(loc: SourceLocation`
   whose body hands `loc` to `snapshots.`;
3. no `examples/*/botopink.json` carries `"git"` naming `rakun`, `jhonstart`, `emilia`, `onze`, `erika`;
4. `zig build test-libs` lists every member.

## Decisions

`95-f` — [`../README.md`](../../../1-botopink-lang/144-botopink-lang/02-std-and-packaging/track.md) § Decisions; `subdir` is decision 344.

**Gate:** standard (fronts.md § Gate) + `scripts/check-packaging.sh` exit 0 in the main checkout
