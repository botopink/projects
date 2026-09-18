# Front 16 — module-naming

**Priority:** high — the erlang backend gives two modules with the same file basename the same
module atom, silently, and eleven `libs/std` modules already carry the name of an OTP module
**Depends on:** [`../12-surface-cutover/`](../12-surface-cutover/README.md) landed (it owns all of
`modules/compiler-core/src/**`); may run beside
[`../06-checker/`](../06-checker/README.md) only if 06 has not claimed `src/codegen/**` — it has
not ([`../fronts.md`](../fronts.md#ownership))
**Owns:** `src/codegen/crossModule.zig` · the module-atom sites of `src/codegen/erlang.zig`
(`:962-968`), `src/codegen/beam_asm.zig` (`:907-913`) and `src/codegen/runtime.zig` (`:451-455`)
(carve-out of [`../01-backend-residuals/`](../01-backend-residuals/README.md)) ·
`modules/compiler-cli/src/cli/build.zig` and `cli/run.zig` (output naming only) ·
the module-atom lines and `buildModule` signatures of `src/comptime/template_eval.zig`
(`:329-343`) and `src/comptime/decorator_eval.zig` (`:227-243`) (carve-out of 06) · the ≈ 20 snapshots its rename moves
in `snapshots/codegen/{erlang,beam}/`
**Does not touch:** the rest of `src/codegen/**` (01) · `src/comptime/**` beyond the two naming
lines (06) · `snapshots/comptime/**` (06, 07) · `src/codegen/commonJS.zig`, `typescript.zig`,
`wat.zig` — JS and wasm output layout does not change ([`js-modules.md`](./js-modules.md)) ·
`libs/std/**` and `repository/{emilia,erika,jhonstart,onze,rakun}/**` — no `.bp` change is needed

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/compiler-cli/`, `libs/` or `scripts/`, which are relative to `repository/botopink-lang/`.
Line numbers read at `botopink-lang` `dfc34a9`; re-locate by symbol.

This front exists to answer a maintainer proposal. The proposal, the evidence for and against it,
and the counter-proposal are in [`erlang-atoms.md`](./erlang-atoms.md),
[`evidence.md`](./evidence.md), [`options.md`](./options.md) and
[`declaration-qualifier.md`](./declaration-qualifier.md). **No decision is taken here** — the
front's step 0 is the maintainer choosing a scheme.

---

## Problem

Two botopink modules whose source files share a basename become the same Erlang/BEAM module.

```
src/models/user.bp     →  out/models/user.erl     →  -module(user).
src/services/user.bp   →  out/services/user.erl   →  -module(user).
```

Reproduced with erlang directly ([E13](./evidence.md#e13--what-collides-today-two-modules-one-atom)) —
the same output directory is a silent overwrite, separate directories on one code path are silent
shadowing:

```
$ erlc -o ebin models/user.erl ; erlc -o ebin services/user.erl   # both exit 0, no warning
$ erl -pa ebin -eval 'io:format("~s~n",[user:who()])'
services/user
```

Nothing in the compiler diagnoses it. `resolver.Error.DuplicateModule`
(`modules/compiler-cli/src/cli/resolver.zig:117`) fires when the same *file* is reached twice, never
when two different files share a basename.

The same mechanism aims a second, sharper gun at OTP. Eleven of `libs/std`'s twenty-seven modules
are named after an OTP module ([E14](./evidence.md#e14--eleven-libsstd-module-names-are-already-otp-module-names)):
`math`, `os`, `crypto`, `base64`, `queue`, `sets`, `dict`, `json`, `unicode`, `random`, `erlang`.
Loading one wins over `stdlib` and makes every other function of that OTP module `undef`
([E15](./evidence.md#e15--what-shadowing-an-otp-module-actually-does)):

```
$ erl -pa shadow -eval 'io:format("~s~n",[code:which(math)]), io:format("~p~n",[math:pi()])'
which(math) = .../shadow/math.beam
math:pi()   = {'EXIT',{undef,[{math,pi,[],[]},…]}}
```

`snapshots/codegen/erlang/import_multi_module_pub_fn_import.snap.md:10` already records
`-module(math).`, and `import_cross_module_record_construct_and_assoc_fn.snap.md:18` records
`-module(http).`

## Current state

Measured at `dfc34a9`. Full trace in [`erlang-atoms.md` § 1](./erlang-atoms.md#1-current-state).

| | Today |
|---|---|
| Module identity in the compiler | the module **path** (`std/math`, `models/user`) — `src/comptime.zig:1198` |
| Erlang/BEAM module atom | the path's **basename** — `crossModule.zig:81`, `erlang.zig:964-968`, `beam_asm.zig:913` |
| Where the atom is written | `-module({s}).` at `src/codegen/beam/erl_emitter.zig:652`, never quoted |
| Cross-module call resolution | `CrossModule.ownerModuleAtom(symbol)` → a flat map keyed by the **bare exported symbol name** (`crossModule.zig:74-77`, `:112-135`) |
| Output layout | `out/<module path><ext>` — **mirrors the source tree**, `build.zig:190` |
| Snapshot harness | flat: `<scratch>/<basename>.erl`, `erlc -o .`, `erl -pa . -s <basename>` — `runtime.zig:451-455`, `:527-590` |
| `botopink run --target erlang` | `escript out/<mod>.erl`, **no `-pa`** — `cli/run.zig:66-71` |
| Comptime modules | content-addressed `template_<16 hex>` / `decorator_<16 hex>` — `template_eval.zig:340`, `decorator_eval.zig:238`; loaded with `code:load_binary/3` and never purged (`runtime/persistent_erl.zig:63-73`) |
| Collisions live in the tree | 6 × `-module(root)`, 2 × `-module(http)`, 11 OTP names |
| Snapshots recording a non-`main` atom | **9** of 313 erlang (303 are `-module(main)`), 9 of 312 beam |

## Mechanism

`erlc` will not compile a `.erl` whose `-module` atom differs from the file's basename, and the
`.beam` produced under `+no_error_module_mismatch` is unloadable
([E1](./evidence.md#e1--the-module-atom-must-equal-the-source-files-basename)). So the atom **is**
the filename, and a path cannot be carried by the directory and the atom at once. The backend's
answer today is to throw the directory away, which makes the atom non-unique. Every downstream
site — the cross-module call target, the snapshot harness's scratch filenames, the audit script's
`<n>/<module>.S` split (`scripts/beam_export_audit.sh:80`) — inherits that.

## The proposal on the table

```
'namemodule@caminho1.caminho2...#Pessoa.erl'
'@comp__namemodule@caminho1.caminho2...#Pessoa.erl'
```

Evaluated in [`erlang-atoms.md` § 2](./erlang-atoms.md#2-the-proposal-point-by-point). In short:

**Holds** — the atom is legal, compiles, loads, remote-calls, answers `?MODULE` /
`function_exported/3` / `code:which/1`, shows readably in a stack trace, works identically for the
BEAM `.S` backend, and does remove both the basename collision and the OTP shadowing
(E3, E4, E5, E9, E17). It does **not** make the atom table worse: one atom per module against a
1 048 576 limit (E6); the unbounded growth that exists is the comptime server's never-purged
modules, which this proposal neither helps nor hurts.

**Breaks** —

1. the atom decides the filename (E1), so the proposal is an **output-layout change**, not just a
   naming change, and it does not say so;
2. `.`, `#` and a leading `@` all force quoting (E2, E9, E10) — every emitter, every `call_ext`
   target and every future hand-written `.erl` needs a quoting rule;
3. **`#` cannot address anything inside a module** — `mod#Pessoa:g()` is a syntax error and the
   quoted form is one opaque 22-character atom (E8). Erlang's own `#` means *record*, used two lines
   away from such a call (E5). The suffix would be text the BEAM never reads;
4. `make` truncates a name at `#` (E11) — `SRC := user@app.models#Pessoa.erl` expands to
   `user@app.models`;
5. the practical length cap is **250 bytes**, not 255, because `<atom>.beam` must be a filename
   (E6, E7), and the proposal's `@comp__` + path + `#Decl` is the one shape that could reach it;
6. it fixes the module name space and leaves the **symbol** name space untouched —
   `CrossModule.exports` is keyed by the bare exported name (`crossModule.zig:112-135`).

## Counter-proposal

Three alternatives with worked examples and a comparison table in
[`options.md`](./options.md). **Recommended: option A** — the path joined with `@`, which is a legal
*unquoted* erlang atom (E10, E12), with a flat `out/erl/` and `out/beam/`:

```
atom(path) = lowercase(path), '/' → '@', [^a-z0-9_@] → '_',
             prefix "bp@" when the first char is not [a-z] or when a
             single-segment name is an OTP module name
```

| Source | Path | Atom |
|---|---|---|
| `src/main.bp` | `main` | `main` (unchanged — 303 of 313 snapshots) |
| `src/web/api/http.bp` | `web/api/http` | `web@api@http` |
| `src/models/user.bp` / `src/services/user.bp` | `models/user` / `services/user` | `models@user` / `services@user` |
| `libs/std/src/math.bp` | `std/math` | `std@math` (no OTP shadow) |
| a template evaluation | — | `bp@comptime@template@3f1a9c02b7e4d5f8` |

Keeps the maintainer's `@`-path intent. The `#<Decl>` half is kept in **intent** and dropped in
**spelling**: **A2**, in [`declaration-qualifier.md`](./declaration-qualifier.md), qualifies every
extra module a single file produces, still unquoted and now decodable back to its source.

```
atom = erlAtom(path) [ "__" kind "__" decl [ "__" hash ] ]
```

| Source | What it is | Atom |
|---|---|---|
| `src/models/user.bp` | the file's own module | `models@user` |
| `src/models/user.bp` | `type Pessoa` | `models@user__t__pessoa` |
| `src/models/user.bp` | `behavior Greeter` | `models@user__b__greeter` |
| `jhonstart/src/html.bp` | the `html` template, one evaluation | `jhonstart@html__tpl__html__3f1a9c02b7e4d5f8` |

Where `#Pessoa` would have been text the BEAM never reads
([E8](./evidence.md#e8---cannot-address-anything-inside-a-module)), `__t__pessoa` is a **real
loadable module** ([E19](./evidence.md#e19--four-sibling-modules-from-one-source-file)) whose atom
decodes back to `{decl,"models/user","t","pessoa"}`
([E19b](./evidence.md#e19b--the-atom-decodes-back-with-no-ambiguity)). `__` as the boundary between
a source-derived name and generator discriminators is OTP's own convention — `escript` names its
synthesised module `whoami_escript__escript__1789__696388__940472__2306`
([E20](./evidence.md#e20--otps-own-escript-uses-__-the-same-way)).

## Steps

### Step 0 — the maintainer picks a scheme

Read [`options.md`](./options.md) and choose P, A, B or C. Nothing below starts first; every later
step's acceptance is written against the chosen rule. If the answer is A, also decide **A-flat**
(`out/erl/<atom>.erl`, recommended) or **A-nested**.

One open question that could move the recommendation from A to C: Elixir compiles `MyApp.User` to
the atom `:"Elixir.MyApp.User"` and a flat `Elixir.MyApp.User.beam`. `elixir` is **not installed**
in this environment, so that is unverified. If it is right, C is industrial prior art for the
maintainer's dotted form and the quoting cost is a known, paid-for cost elsewhere.

**Acceptance:**
- [ ] The chosen rule is written in this README as prose a second person can implement from
- [ ] The Elixir claim is verified or explicitly dropped

### Step 1 — one canonical identity, one renderer per backend

Add to `src/codegen/crossModule.zig`: `ModuleId` (the path), `erlAtom(alloc, id)` implementing the
chosen rule, `RESERVED` (the OTP module names, frozen as a source list), and
`outputStem(target, alloc, id)`. Move the four truncation sites to it —
`erlang.zig:962-968`, `beam_asm.zig:907-913`, `runtime.zig:451-455`, and `ownerModuleAtom`
(`crossModule.zig:74-77`). Keep `moduleBasename` only if a caller still needs a basename
(`wat.zig:211` compares an import segment and is not a naming site).

**Acceptance:**
- [ ] `grep -rn 'lastIndexOfScalar(u8, module_name' src/codegen/` returns nothing
- [ ] `zig build test` green; the 303 `-module(main).` snapshots are **byte-identical**
- [ ] A unit test on `erlAtom` covering: single segment, two segments, three segments, a reserved
      name, a segment with a character outside `[a-z0-9_]`, a segment containing `__`
      ([E21](./evidence.md#e21--__-has-to-be-reserved)), and a name that would exceed 250 bytes
- [ ] `erlDeclAtom(alloc, id, kind, decl, ?hash)` with a `Kind` enum — `kind` is never a free string
- [ ] **A collision check over the rendered atoms** in `crossModule.build` (`crossModule.zig:86`):
      a duplicate atom, a `RESERVED` hit or a name over 250 bytes is a located diagnostic, not a
      silent winner — this is the check whose absence is the whole front
      ([`declaration-qualifier.md` § 4](./declaration-qualifier.md#4-__-is-reserved-and-what-that-costs))

### Step 2 — the output layout follows the atom

`modules/compiler-cli/src/cli/build.zig:184-208` writes `out/<outputStem><ext>`;
`removeStaleArtifacts` (`:157-166`) uses the same stem; `cli/run.zig:51,66-71` builds the erlang
entry path from it. **commonJS, typescript and wasm keep `out/<module path><ext>`** — their require
target is the path (`commonJS.zig:1858-1870`) and flattening them breaks every multi-module JS
program ([`js-modules.md` § 2](./js-modules.md#2-what-the-erlang-decision-implies-here)).

**Acceptance:**
- [ ] `botopink build --target erlang` on `examples/modules` writes one flat directory; every
      `.erl` basename equals its `-module` atom
- [ ] `erlc -o ebin out/erl/*.erl` compiles every module with no overwrite
- [ ] `botopink build --target commonJS` output tree is byte-identical to before this front
- [ ] `botopink clean` still removes everything (`cli/clean.zig:8`)

### Step 3 — the snapshot harness and the audit script

`runtime.zig` writes `<atom>.erl` / `<atom>.S` and passes `-s <atom>` (`:527-590`, `:600-682`); the
aux loop must reject a **duplicate atom among aux modules**, which today it silently overwrites
(`:559`, `:654` skip only against the entry). `scripts/beam_export_audit.sh:63-80` derives a
filename from the recorded atom — under option A it needs no change; under P or C it needs quote
stripping, and note that `erlc +from_asm` prints a name-mismatch error but **exits 0**
([E17](./evidence.md#e17)), so the check cannot read the exit code alone.

**Acceptance:**
- [ ] `scripts/beam_export_audit.sh` at 295/295
- [ ] A harness test: two aux modules with the same atom fail loudly instead of overwriting

### Step 4 — the tests that prove the collision is gone

The collisions being fixed are latent: no gate cell today runs two libraries in one erlang node, so
nothing currently red turns green. Add the cells that can see it.

**Acceptance:**
- [ ] A fixture with `models/user.bp` and `services/user.bp`, both called from `main`, executing
      correctly on erlang and beam (today it cannot exist)
- [ ] A fixture importing `libs/std`'s `math` and calling an OTP `math` function in the same
      program — proves the shadow is gone (E15 is the failure it pins)
- [ ] A library cell that builds `libs/std` and one sibling library into one erlang output
      directory with no filename collision

### Step 5 — comptime modules into the same shape

`template_eval.zig:340` and `decorator_eval.zig:238` stop building a flat `template_<hash>` and call
`erlDeclAtom(owner_path, .tpl, decl_name, hash)`. This is the one piece of real plumbing A2 adds:
`buildModule` (`template_eval.zig:329-343`, `decorator_eval.zig:227-243`) sees only the generated
code today and must also receive **the owning module's path and the declaration's name** — two
strings threaded through, ~30 LOC. The Wyhash stays exactly as it is, so the content-addressing that
makes a re-evaluation a no-op (`runtime/persistent_erl.zig:63-73`) is preserved.

Touches two literals plus two test assertions (`codegen/tests/comptime_module.zig:17`/`:45`,
`decorator_eval.zig:370`); **no comptime snapshot records the hash**
(`grep -rl 'template_[0-9a-f]\{16\}' snapshots` → 0).

**Acceptance:**
- [ ] `zig build test` green with `snapshots/comptime/**` byte-identical
- [ ] A template evaluation's module atom names its file and its template:
      `jhonstart@html__tpl__html__<hash>`, not `template_<hash>`
- [ ] Re-evaluating an identical body still yields the identical atom (content-addressing intact)
- [ ] The decoder of [`declaration-qualifier.md` § 5](./declaration-qualifier.md#5-it-decodes-back)
      as a test, so reversibility is pinned

### Step 6 — the residuals this front will not take

Record, do not fix:

- `CrossModule.exports` keyed by the bare symbol name (`crossModule.zig:112-135`) — two libraries
  exporting `pub fn get` still collide. A separate front.
- `botopink run --target erlang` is `escript out/<mod>.erl` with no `-pa`
  (`cli/run.zig:66-71`), so a cross-module erlang program is not runnable from the CLI. Decide
  here whether step 2 fixes it or it becomes an unowned item.
- The comptime server never purges a loaded module (`runtime/persistent_erl.zig:63-73`, no
  `code:purge/1`) and never deletes `.botopinkbuild/tmp/{template,decorator}/*.erl`. Unbounded in a
  long-lived process; irrelevant for a one-shot build. Not this front's, but found by it.

**Acceptance:**
- [ ] Each residual is a row in [`../fronts.md` § Unowned items](../fronts.md#unowned-items) or in a
      named front, with its file and its finder

## Gate

- [ ] `scripts/gate.sh --cold` green in this front's worktree (zig build · cold `zig build test` ·
      `test-bpmp` · beam export audit · `test-cli` · `test-libs` · `test-language`)
- [ ] `scripts/beam_export_audit.sh` 295/295
- [ ] The 303 `-module(main).` erlang snapshots and their 302 beam twins **byte-identical**; each of
      the ≈ 20 that moved classified in the commit message (atom rename vs. behaviour change) and
      its `RUN LOG` re-verified by executing, not by accepting
- [ ] `AGENTS.md` updated in the same commit for `src/codegen/`, `modules/compiler-cli/src/cli/` and
      `src/comptime/` — `src/codegen/AGENTS.md:64` currently documents
      `ownerModuleAtom(name)` / `moduleBasename(path)` as "`web/http` → `http`" and would be wrong
- [ ] Every library still builds (`zig build test-libs`, `scripts/known-red-libs.txt` still empty)
- [ ] Commit on `fix/module-naming`; no push, no merge

## Blast radius

| What moves | Size |
|---|---|
| Snapshots re-recorded, option A | **≈ 20** of 2519 (the 9 multi-module erlang fixtures + their beam twins) |
| Snapshots re-recorded, option P or C | **≈ 620** — every `-module(main).` becomes `'main'` |
| Compiler source, option A + A2 | ≈ 180 LOC across 9 files |
| `.bp` source in `libs/std` or any sibling library | **none** — no library writes a module atom |
| commonJS / typescript / wasm output | unchanged by construction |
| `out/` layout for erlang and beam | flat — anything scripted against `out/std/math.erl` breaks |

The breakdown, with the commands that produced each number, is in
[`migration.md`](./migration.md). Estimated **≈ 3.5 days** for option A + A2, 5–6 for P or C.

The risk worth naming: this front fixes latent failures. Nothing red today turns green, so step 4's
new cells are the only evidence the work did anything — a front that skips them lands 150 LOC and
620 snapshot churn with no proof.

## Notes

- The proposal's strongest result is one it was not aimed at: the eleven `libs/std` modules that
  shadow OTP. That is a live, silent, node-wide failure ([E15](./evidence.md#e15--what-shadowing-an-otp-module-actually-does)),
  worse than the same-basename collision, and any scheme chosen in step 0 must close it.
- `libs/std/src/erlang.bp` would emit `-module(erlang)` if it ever gained a `pub fn`. `erlang` is
  preloaded and cannot be replaced — the module would compile, load without complaint, and be
  unreachable. It is declaration-only today (`@External.Erlang` catalogue), which is the only
  reason this has not bitten.
- `erlc` stages its output through `<name>.bea#` (visible in
  [E7](./evidence.md#e7--the-real-length-cap-is-the-filename-not-the-atom)). A `#` in a module name
  is a character the toolchain already spends on its own temporary files.
- Not tested, because not installed: `rebar3`, `elixir`. Both are named in the analysis with that
  caveat.

---

## Rows to add to `fronts.md` and `overview.md`

Paste as-is; this front does not edit either file.

### `overview.md` — the front table

```markdown
| [`16-module-naming`](./16-module-naming/README.md) | high | not started | The erlang/BEAM module atom is the source path's basename, so two modules with the same file name collide silently and eleven `libs/std` modules shadow an OTP module. Evaluates the maintainer's `'name@path#Decl'` proposal and counter-proposes an unquoted `@`-joined path atom |
```

### `overview.md` — the Order diagram

```markdown
12 surface-cutover (alone) ──► 06 checker ──► 01 steps 5–6 ──► 08 wave A
                                   │
                                   ├──► 07 comptime-dedup ──► 08 wave B
                                   └──► 16 module-naming (codegen atom sites + CLI output layout)
```

### `fronts.md` — Ownership

```markdown
| **16** [`module-naming`](./16-module-naming/README.md) | `src/codegen/crossModule.zig` · the module-atom sites of `src/codegen/{erlang.zig,beam_asm.zig,runtime.zig}` (carve-out of 01) · `modules/compiler-cli/src/cli/{build.zig,run.zig}` (output naming only) · the module-atom lines of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 06) | ≈ 20 files in `snapshots/codegen/{erlang,beam}/` | not started — after 12; needs step 0, a maintainer decision |
```

### `fronts.md` — Conflict matrix

Add a `16` column and row; the existing rows gain one cell each.

```markdown
|  | 01 (5–6) | 06 | 07 | 08 | 09 | 12 | 13 | 14 | 16 |
|---|---|---|---|---|---|---|---|---|---|
| **01 (5–6)** | — | no¹ | yes | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ | no⁹ |
| **06** | no¹ | — | no³ | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ | no¹⁰ |
| **07** | yes | no³ | — | no⁴ | no⁵ | no⁶ | seq⁷ | seq⁷ | yes |
| **08** | no⁴ | no⁴ | no⁴ | — | no⁵ | no⁶ | seq⁷ | seq⁷ | no⁴ |
| **09** | no⁵ | no⁵ | no⁵ | no⁵ | — | no⁶ | no⁸ | no⁸ | no⁵ |
| **12** | no⁶ | no⁶ | no⁶ | no⁶ | no⁶ | — | no⁸ | no⁸ | no⁶ |
| **13** | seq⁷ | seq⁷ | seq⁷ | seq⁷ | no⁸ | no⁸ | — | yes | seq¹¹ |
| **14** | seq⁷ | seq⁷ | seq⁷ | seq⁷ | no⁸ | no⁸ | yes | — | yes |
| **16** | no⁹ | no¹⁰ | yes | no⁴ | no⁵ | no⁶ | seq¹¹ | yes | — |
```

New notes:

```markdown
9. **01 × 16 share `erlang.zig`, `beam_asm.zig`, `runtime.zig` and
   `snapshots/codegen/{erlang,beam}/`.** 16 takes only the module-atom sites as a carve-out, but it
   re-records ≈ 20 snapshots in directories 01 owns. Sequence them: 16 after 01 step 6, or 01 step 6
   after 16 — not both at once.
10. **06 × 16 share `src/comptime/{template_eval,decorator_eval}.zig`.** 16 changes two literals in
    them (the comptime module atom); 06 owns the files. 16 after 06, or the maintainer hands 16 the
    two lines as a carve-out.
11. **13 × 16.** The libraries need no source change, but a library's erlang cell executes the
    output whose layout 16 changes; 13 re-runs after 16 lands.
```

### `fronts.md` — Unowned items (rows this front hands back)

```markdown
| **`CrossModule.exports` is keyed by the bare exported symbol name** — two libraries each exporting `pub fn get` overwrite one another regardless of module naming; 16 fixes the module name space only | `src/codegen/crossModule.zig:112-135` | 16 module-naming | a follow-up front, or 01 |
| **The comptime server never purges a loaded module and never deletes `.botopinkbuild/tmp/{template,decorator}/*.erl`** — bounded for a one-shot build, unbounded for a long-lived process (LSP, watch) | `src/comptime/runtime/persistent_erl.zig:63-73` | 16 module-naming | 09 hygiene, or 06 |
| **`botopink run --target erlang` is `escript out/<mod>.erl` with no `-pa`** — a cross-module erlang program is not runnable from the CLI | `modules/compiler-cli/src/cli/run.zig:66-71` | 16 module-naming | 16 step 2, or 05's successor |
```
