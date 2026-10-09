# Front 138 — the shared libraries leave the compiler: one repository each

**Priority:** high — every other front of this track and every consumer commit (102 step 3, 103 step
2, 104 step 5, 105, 106 step 2, 107, 125 steps 4–12) is written against where the packages live;
moving them first means each of those commits is written once · **State:** steps 2–5 staged, step 6
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

## Open

### Step 1 — the repositories (maintainer)

- [ ] `botopink/actions`, `botopink/http`, `botopink/log`, `botopink/routing`, `botopink/validation`,
      `botopink/cardume` created on GitHub, empty, with `feat` and `main` as in every library repository

### Step 2 — extraction with history

- [ ] for each of the five: `git subtree split --prefix=libs/<pkg>` from botopink-lang `feat`, pushed to
      the new repository's `feat` and `main`; `git log` of a moved file shows its history
- [ ] `cardume`'s scaffold pushed as is
- [ ] each repository shaped as a library repository: `AGENTS.md` naming
      `git config core.hooksPath scripts/git-hooks`; `scripts/git-hooks/pre-commit` and
      `scripts/git-hooks/lib/runner-standalone.sh` byte-identical to emilia's; `.gitignore` naming
      `*.snap.new` and `*.snap.md.new`; its own CI on push/PR to `feat`/`main` running `botopink test`
      on the targets its manifest declares
- [ ] `botopink.json`: the description loses "Bundled library —"; `actions` declares `routing` in
      `dependencies` (the one package-to-package edge); `files` unchanged

### Step 3 — the compiler embeds std alone (botopink-lang)

- [ ] `libs/{actions,http,log,routing,validation}` deleted; `build.zig`'s `bundled_packages` is
      `{ "std" }` and the non-std half of `bundledPkgFiles` and the generated table goes (the table may
      keep its shape with std as its one row)
- [ ] `libs.zig`: the refusal "dependency is bundled with the compiler" applies to `std` only; the
      bundled-order walk (`routing` before `actions`) goes — the dependency closure orders packages;
      `from "routing"` with no dependency is 242's `unresolved import source "routing" — declare it in
      botopink.json "dependencies"`
- [ ] `scripts/format-check.sh` `TREES`, `scripts/tsc-check.sh`, `scripts/check-docs.sh`'s roots read
      `libs/std` alone; `.github/workflows/test.yml`'s job `libs` checks out the five and `cardume`
      beside emilia, erika, jhonstart, onze, rakun
- [ ] `libs/AGENTS.md`, `docs.md` and `docs/botopink-json.md` say the compiler ships std only and show
      a dependency on `routing` as any other library's
- [ ] the binary's size before and after recorded in the commit (it shrinks by the five packages)
- [ ] the language server (`project_graph.zig`) and `bpmp` (`lockfile.zig`) lose their bundled-name
      arms or keep std's alone; their tests green

### Step 4 — consumers declare what they import

- [ ] every member of rakun, jhonstart and onze that imports one of the five declares it: a sibling in
      the meta checkout resolves through `repository/<pkg>` (`libs.zig`'s roots), elsewhere through
      `{ "git": "https://github.com/botopink/<pkg>.git", "branch": "feat" }`; one commit per repository
- [ ] `zig build test-libs` from a cold cache: every cell that was green stays green, the five new
      repositories and `cardume` appear as rows (`discovery.zig` reads `repository/*`)

### Step 5 — the meta repository

- [ ] `.gitmodules` gains `repository/{actions,http,log,routing,validation,cardume}`, each pointer an
      ancestor of its remote `feat` (CI check 1)
- [ ] `AGENTS.md` § Layout: the libraries row reads
      `repository/{emilia,erika,jhonstart,onze,rakun,actions,http,log,routing,validation,cardume}/`
      (CI check 2 needs every path on disk — this lands with the submodules, never before)
- [ ] `AGENTS.md` § CI check 4 and `hook-integrity.yml` cover every library repository, the six new ones
      included
- [ ] `scripts/language-gap-markers.sh` exits 0 (it reads every submodule of `.gitmodules`)

### Step 6 — the specs follow

- [x] the track's fronts (102, 103, 104, 105, 106, 107, 125) point at `repository/<pkg>/…` instead of
      `repository/botopink-lang/libs/<pkg>/…`; `105-i18n` and `107-release` create their packages as
      repositories (`botopink/i18n`, `botopink/release`) under the same rule
- [x] this track's README: the three shared registration lines (`build.zig`'s `bundled_packages`,
      `libs/AGENTS.md`'s table, `format-check.sh`'s `TREES`) go — a new package is a new repository;
      `fronts.md` § Ownership names the six repositories under `03-bundled-libs`
- [x] `09-cardume/136` reads `repository/cardume` as a submodule this front added

**Gate:** standard (fronts.md § Gate) — `zig build test` and `zig build test-libs` from a cold cache in
botopink-lang, every library repository's own `botopink test`, and the meta repository's
`hook-integrity` job green.

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
