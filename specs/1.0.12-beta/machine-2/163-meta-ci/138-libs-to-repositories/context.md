# Front 138 — the shared libraries leave the compiler: one repository each

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [136-cardume](../../136-cardume/README.md): s1 → 136 s9 · s2 box 2 → 136 s9 · s5 boxes 1, 2, 3 → 136 s9. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — every other front of this track and every consumer commit (102 step 3, 103 step
2, 104 step 5, 105, 106 step 2, 107, 125 steps 4–12) is written against where the packages live;
moving them first means each of those commits is written once · **State:** steps 1–5 done but cardume; step 6 (specs) done 
done — the five repositories' trees wait to be pushed; the compiler, consumer and meta changes are
patches that land after the pushes (§ Notes, *Landing*); `cardume` waits on its scaffold
**Depends on:** decision 326 · the six GitHub repositories created by the maintainer (step 1 — an
organisation action, not a front's) · no front editing `libs/{actions,http,log,routing,validation}/**`
while steps 2–4 run (they land between two waves; the track's other fronts rebase onto them)
**Owns:** the extraction of `repository/botopink-lang/libs/{actions,http,log,routing,validation}/**`
into `repository/{actions,http,log,routing,validation}`; `repository/cardume` (the scaffold 136
builds on) as a submodule; in botopink-lang: `build.zig`'s `bundled_packages` /
`bundledPkgFiles`, `modules/compiler-cli/src/cli/libs.zig`'s bundled-package arms,
`scripts/{format-check,tsc-check,check-docs}.sh`'s library roots, `.github/workflows/test.yml`'s job
`libs` checkout list, `libs/AGENTS.md`, `docs.md` / `docs/botopink-json.md` § bundled packages; the
`botopink.json` `dependencies` lines of the consumers (rakun, jhonstart, onze members); in the meta
repository: `.gitmodules`, `AGENTS.md` § Layout and § CI check 4's list,
`.github/workflows/hook-integrity.yml`'s library list (a carve-out of `00-gate/114`'s file, named in
the commit)
**Does not touch:** any `.bp` source of the moved packages (moved byte for byte, history kept) ·
`libs/std/**` (std stays embedded: the one package the compiler ships) · the consumers' code beyond
the manifest line (the import sources do not change: `from "routing"` stays `from "routing"`) ·
136's `cardume` code

## Goal

Decision 326: `actions`, `http`, `log`, `routing` and `validation` stop being bundled — compiled into
the compiler's binary and importable with no declaration (decisions 115–117) — and become ordinary
libraries, each in its own repository beside emilia and erika; `cardume` joins as a submodule the
same way. A program that imports one declares it in `dependencies` (242); the compiler embeds std
alone.

| Package | Today | After | Consumers today |
|---|---|---|---|
| `actions` | `botopink-lang/libs/actions` (11 `.bp`) | `repository/actions` · `botopink/actions` | jhonstart 10 files, rakun 1; imports `routing` |
| `http` | `botopink-lang/libs/http` (13) | `repository/http` · `botopink/http` | none yet (104 step 5) |
| `log` | `botopink-lang/libs/log` (10) | `repository/log` · `botopink/log` | none yet (106 step 2) |
| `routing` | `botopink-lang/libs/routing` (19) | `repository/routing` · `botopink/routing` | rakun 23 files, jhonstart 8, onze 1, `actions` |
| `validation` | `botopink-lang/libs/validation` (26) | `repository/validation` · `botopink/validation` | rakun 5 files |
| `cardume` | scaffold (0.0.1), no remote | `repository/cardume` · `botopink/cardume` | none (136) |

## Notes

- **Order.** Steps 2–5 land between two waves: no front has an open commit in the five `libs/<pkg>/`
  directories while they run. The track's fronts (102 step 3, 103 step 2, 104, 105, 106, 107, 125
  steps 4–12) branch from the result and write their package commits in the new repositories.
- **Names stay.** The packages keep their names, so no import source changes; decision 163's rule (no
  name std or a framework already exports) still applies to what they export.
- **std stays.** std is the language's library — embedded, importable with no declaration, the one
  bundled package left.
- **Landing.** (1) push the five staged repositories (`feat` and `main`); (2) the botopink-lang
  patch (std alone in the binary) and the rakun, jhonstart and onze manifest patches, together — a
  consumer that declares `routing` while the compiler still bundles it is refused
  (`BundledDependency`), and one that does not declare it after is 242's unresolved source; (3) the
  meta patch (`.gitmodules`, `AGENTS.md`, `hook-integrity.yml`) with the submodule pointers at the
  pushed tips (CI checks 1 and 2). `cardume`'s submodule, its job-`libs` checkout and its layout and
  check-4 entries are a separate patch that lands once its scaffold is pushed.
- **Shorthand reach (`138-a`).** With `routing` a dependency, decision 170's exclusion — the
  shorthand never reaches a bundled package — has no package left to cover (std's modules are
  reached: measured); `tests/language/modules/shorthand_import_beside_bundled_package` answers
  `ambiguous-import-use` until `138-a` is decided.
