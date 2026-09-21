> Carried from `specs/1.0.5-beta/13-module-identity/README.md`, status at carry (2026-09-20): half 1 landed (`154f3bc9`); halves 2–3 (steps 8–19) are C-01, decision 64 is C-03 (uncommitted in `.tasks/identity`), step 6's residuals are C-25. The README still reads T1 and an unticked step 0 — decisions 6, 21, 22, 23 and 62 override it

# Front 13 — module-identity

Carried into 1.0.5-beta from 1.0.4-beta's fronts **16 (module-naming)** and **19 (runtime type
identity)**, neither started, **merged into one front by the maintainer**. The measured analysis of
both is unchanged and lives in the companion documents; what changed is the numbering, the links,
the dependency section and the ordering, re-anchored to a fourteen-front milestone.

**Priority:** high — the erlang backend gives two modules with the same file basename the same
module atom, silently; eleven `libs/std` modules already carry the name of an OTP module; and no
value on any backend knows its own type, so `is`, unions, a `case` over named types and
[decision 8](../../../1.0.4-beta/08-review-backlog/decision-8-language.md) §7's per-type formatter have
nothing to test.

**Order (maintainer):** [`../14-comptime-on-beam/`](../14-comptime-on-beam/README.md) first, **this
front immediately after it**, then the four backend fronts. The reason is in § *Order*: it is the
order in which every snapshot is written once, `buildModule` is inherited rather than contested, and
the circular dependency with decision 8's run-time rows never arises.

## Why the two fronts are one

1.0.4-beta's 19 concluded it itself: its premise is to use **the atom 16 gives each declaration**,
inside the value. Every reason the two were sequenced is a reason they are one front:

| | |
|---|---|
| **The same files** | 16's steps 7–13 own `src/codegen/erlang.zig` and `src/codegen/beam_asm.zig` **wholesale**; 19 edits eight functions in each. They could never be open at the same time |
| **Overlapping snapshots** | 188 (policy 3) and 130 (the identity) in the same two directories, and 62 of the 130 erlang cells also carry policy 3's marker. Sequencing them across fronts buys nothing that sequencing them inside one front does not |
| **The helper** | 19 step 1 was a *consumer* of 16's `erlDeclAtom`. Written twice, that is two spellings of one atom — precisely the failure the front exists to remove |
| **Policy 3 pays for half of the identity** | under policy 3 the type's atom **is** a loadable module holding `format/1`, so §7's formatter is one `call_ext` and needs no dispatch table, and a crash inside it names the type in the stack trace ([`halves-and-ordering.md`](./halves-and-ordering.md) § 2) |
| **The `__v__` segment** | 19 had to ask 16 to add one `Kind` variant to the atom rule, "agreed while 16 is written". In one front that is an internal decision, taken in step 1 |

## The three halves, and why they land in this order

**No commit and no re-recorded snapshot may carry two of these reasons at once.** That is the rule
the two fronts already defended separately ([the rule 1.0.4-beta ran
under](../../../1.0.4-beta/overview.md): a re-recorded snapshot is classified,
never bulk-accepted), and it is what fixes the order.

| | Half | Steps | What moves | Snapshots | Why it cannot share a diff with its neighbours |
|---|---|---|---|---:|---|
| **1** | **the atom** | 0–6 | option A + A2: `main` stays `main`, `web/api/http` → `web@api@http`, `std/math` → `std@math`, a template → `bp@comptime@template@<hash>`, and the declaration qualifier `__t__` / `__b__` / `__im__`. Flat `out/erl/` and `out/beam/`. A collision check over the rendered atoms | **≈ 20** — a name on one line | A diff here changes **names only**. Landed on top of anything else, "the atom changed" stops being a readable classification |
| **2** | **policy 3** | 7–13 | one BEAM module per `type` and per `behavior`; `recordMethodAtom`, `interfaceAssocAtom` and `record_method_collisions` **deleted**; `codegenEmit` yields N artefacts; `build.zig` and `run.zig` follow; `botopink run --target erlang` gains `-pa`, which **opens** this half because policy 3 breaks it first | **188** — 94 erlang + 94 beam, each gaining whole emitted sections | Each of the 188 diffs gains sections. With half 1 in the same commit every one of them would carry an atom rename *and* a re-shaping, and classification becomes impossible |
| **3** | **the identity in the value** | 14–20 | the A2 atom inside the value: `'__bp_type'` as one key in a record map, and the **qualified variant tag** — free in space, no opcode and no arity change. Then `is`, a union `case`, and §7's per-type formatter | **130** — 62 erlang + 68 beam, one or two emitted lines each, and **0 `RUN LOG`s** | 62 of these 130 erlang cells are files half 2 has already re-recorded once. Landing the two together means a diff that splits a module *and* reshapes its values; landing 3 before 1 means re-recording all 130 a second time when the atom rename moves the tag |

**The measured cost of getting the order wrong**, in one line each: half 3 before half 1 costs one
full re-record of 130 cells for a reason that is half 1's
([`halves-and-ordering.md`](./halves-and-ordering.md) § 4); half 3 before half 2 costs a per-program
dispatch table written and then deleted, because policy 3 turns the tag into the module that holds
`format/1`; and half 3's `tests/language/` acceptance cells run programs through the CLI, which needs
half 2's `erl -pa` fix to exist at all
([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)).

Estimated **≈ 9 days** for halves 1 + 2 and **≈ 7** for half 3 — the second figure includes the
`is` / union-`case` / formatter lowerings, which cannot start before
[`../01-checker/`](../01-checker/README.md) lands N20/N21/N22.

## Order

**14 → 13 → the backends.** Decided by the maintainer; the full argument, with the numbers, is in
[`halves-and-ordering.md`](./halves-and-ordering.md) § 5.

```
14 comptime-on-beam (steps 0–2)
      │
      └──► 13 module-identity   half 1: the atom       (≈ 20 snapshots, names)
                                half 2: policy 3       (188, shapes)      ── 02 and 03 stall here
                                half 3: the identity   (130, value lines)
                                     │
                                     └──► 02 erlang · 03 beam — decision 8's run-time rows,
                                          named types included, against a value that knows its type

            04 js · 05 wasm — in parallel throughout
            01 checker — N19–N22 (the checker half) before steps 17–19
```

Three things this order fixes, and one it costs.

1. **`buildModule` is inherited, not contested.** 14's step 2 and this front's step 5 touch the same
   function (`template_eval.zig:329-343`, `decorator_eval.zig:227-243`). With 14 first, the comptime
   module becomes keyed by the **declaration** instead of by the call site — which is exactly the key
   this front's `erlDeclAtom(owner_path, .tpl, decl_name, hash)` wants. 1.0.4-beta's analysis already
   recommended that order; it is now the order.
2. **The circular dependency never arises.** Decision 8's run-time rows — **D8-1** (`is`), **D8-2**
   (unions), **D8-3** (`case` arms), **D8-5** (the §7 formatter) — live in the four backend fronts,
   and none of them can be written *for a named type* before a value knows its own type. With this
   front ahead of them, the identity **already exists** when they open. **The cut that 1.0.4-beta
   recorded as a pending maintainer decision is therefore no longer necessary**, and it is no longer
   owed: it is kept in [`halves-and-ordering.md`](./halves-and-ordering.md) § 5.2 as the fallback,
   which becomes necessary again only if 02 or 03 is allowed to open before halves 2–3 land.
3. **Each snapshot is written once.** With the backends first, this front would re-record 188 + 130
   cells on top of what 02 and 03 had just recorded. In this order every cell moves once.

**The price, stated plainly: `02-erlang` and `03-beam` stall while halves 2 and 3 run.** This front
owns `src/codegen/erlang.zig` and `src/codegen/beam_asm.zig` **wholesale** for steps 7–20 — 318
re-recorded cells in the two snapshot directories 02 and 03 own — so neither front can be open at the
same time. **`04-js` and `05-wasm` are unaffected and run in parallel throughout.**

Half 1 is the exception to the stall: steps 1–6 touch only the four **module-atom sites** in
`erlang.zig`, `beam_asm.zig` and `runtime.zig` and change no emitted shape, so if the maintainer ever
wants 02 or 03 open beside it, that half is a carve-out rather than a stall.

## Depends on

- **[`../14-comptime-on-beam/`](../14-comptime-on-beam/README.md) steps 0–2**, for the reason above.
  Not a hard blocker — step 5 can thread the owner's path through the per-call-site `buildModule` if
  14 slips — but it is the order that costs least, and the maintainer has fixed it.
- **[`../01-checker/`](../01-checker/README.md)** for two things: the carve-out of the module-atom
  lines and the `buildModule` signatures of `src/comptime/{template_eval,decorator_eval}.zig`
  (step 5), and **N19–N22** for steps 17–19. In 1.0.4-beta the latter was front 06.
  **Narrowed at `c2dd780`:** the *grammar* half has landed — `unknown` as a keyword (`6c849ae`),
  `A | B` union types (`4a3449f`), `x is T` as an expression (`3b491e3`) and decision 8's `case`
  arms (`dff3446`), merged as `d0c27f6`. What steps 17–19 still wait for is the **checker** half.
- **[`../02-erlang/`](../02-erlang/README.md) and [`../03-beam/`](../03-beam/README.md)** — not as
  blockers under this order, but as the two fronts this one **stalls**: it shares `erlang.zig`,
  `beam_asm.zig` and `snapshots/codegen/{erlang,beam}/` with them and owns both files wholesale for
  steps 7–20. In 1.0.4-beta this read "after 01 closes"; the maintainer's order reverses it.
- **[`../04-js/`](../04-js/README.md)** only for the optional **step 19** (the commonJS
  unit-variant hole), which this front does not take unasked because `commonJS.zig` is 04's.
- **[`../05-wasm/`](../05-wasm/README.md)** for nothing this front does, but see the pending
  decision in § *Decisions the maintainer still owes*: wasm has no identity at all, and if 05
  designs its box independently, `is Person` will mean two different things on two backends.
- 1.0.4-beta's [`12-surface-cutover`](../../../1.0.4-beta/12-surface-cutover/README.md) is
  **delivered**; it owned all of `modules/compiler-core/src/**` and no longer blocks anything.

**Owns:** `src/codegen/crossModule.zig` (`ModuleId`, `erlAtom`, `erlDeclAtom`, `RESERVED`,
`outputStem`, the collision check, and `typeAtom` / `variantAtom` beside them) ·
`src/codegen/erlang.zig` and `src/codegen/beam_asm.zig` — the **module-atom sites** for steps 1–6
(carve-out of 02 and 03), both files **wholesale** for steps 7–20 · the module-atom sites of
`src/codegen/runtime.zig` (`:451-455`) · `modules/compiler-cli/src/cli/build.zig` and `cli/run.zig`
(output naming, and the `-pa` fix) · the module-atom lines and `buildModule` signatures of
`src/comptime/template_eval.zig` (`:329-343`) and `src/comptime/decorator_eval.zig` (`:227-243`)
(carve-out of 01) · **≈ 20 + 188 + 130 cells** of `snapshots/codegen/{erlang,beam}/` · the
`tests/language/` cells for `is`, a named-type union `case` and decision 8 §7's printed form
(coordinate with [`../12-language-tests/`](../12-language-tests/README.md))

**Does not touch:** `src/codegen/commonJS.zig` and `typescript.zig` (04) — JS output layout does not
change ([`js-modules.md`](./js-modules.md)) — **unless the maintainer assigns step 19** ·
`src/codegen/wat.zig` (05) — wasm carries no identity at all
([`representation.md`](./representation.md) § 6) and its box is
[decision 3](../../../1.0.4-beta/08-review-backlog/semantics-decisions.md)'s ·
`src/comptime/**` beyond the two naming lines (01) · `snapshots/comptime/**`
(01, [`../06-comptime-dedup/`](../../../1.0.5-beta/06-comptime-dedup/README.md)) · `libs/std/**` and
`repository/{emilia,erika,jhonstart,onze,rakun}/**` — **no `.bp` change anywhere**

**Overlaps [`../14-comptime-on-beam/`](../14-comptime-on-beam/README.md)** in
`src/comptime/{template_eval,decorator_eval}.zig`: this front's **step 5** and 14's **step 2** touch
the same `buildModule`. The 1.0.4 note still holds with the new numbers — **14 step 2 first** is the
cheaper order, because it makes the comptime module per *declaration*, which is exactly the key this
front's `erlDeclAtom(owner_path, .tpl, decl_name, hash)` wants.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/compiler-cli/`, `modules/`, `libs/`, `scripts/` or `tests/`, which are relative to
`repository/botopink-lang/`. Line numbers for halves 1–2 were read at `botopink-lang` `dfc34a9` and
for half 3 at `26d4fdc`; **re-locate by symbol**. At `c2dd780` they had drifted again — the
`-module` form is at `erlang.zig:999`, `moduleBasename` at `beam_asm.zig:930`, `variantTag` at
`erlang.zig:5189` and `beam_asm.zig:1707` — and the suite has grown to **315** erlang and **314**
beam cells, 2 573 in all, so ≈ 20 / 188 / 130 are floors, not current counts. Re-measure before
quoting a number in a commit message.

| Deep dive | Half | Holds |
|---|---|---|
| [`erlang-atoms.md`](./erlang-atoms.md) | 1 | how a module is named today, and the maintainer proposal point by point |
| [`atom-options.md`](./atom-options.md) | 1 | options A, P and C with worked examples and a comparison table |
| [`declaration-qualifier.md`](./declaration-qualifier.md) | 1 | A2 — the declaration suffix, why `__` is reserved, and the decoder |
| [`js-modules.md`](./js-modules.md) | 1 | why JS and wasm output layout does not change |
| [`atom-evidence.md`](./atom-evidence.md) | 1–2 | E1–E26: 17 `erlc` experiments, the length cap, the four sibling `.S` modules, the 0.372 ns `call_ext` benchmark |
| [`policy-3-module-per-type.md`](./policy-3-module-per-type.md) | 2 | the full working-out of one module per `type` and per `behavior`, each claim measured or run |
| [`migration.md`](./migration.md) | 1–2 | the blast-radius breakdown with the command that produced each number |
| [`representation.md`](./representation.md) | 3 | what a record and an enum value are on each of the five backends, measured, and what each decision-8 feature needs |
| [`identity-options.md`](./identity-options.md) | 3 | the four identities (a)–(d), T1/T2, and the variant-tag spelling, each with its cost |
| [`identity-evidence.md`](./identity-evidence.md) | 3 | E1–E20: Part 1 (hand-written fixtures) and Part 2 (the compiler's own output) |
| [`identity-blast-radius.md`](./identity-blast-radius.md) | 3 | the 130, with the command that produced each count |
| [`halves-and-ordering.md`](./halves-and-ordering.md) | all | what each half gives the next, the ordering, and the circular dependency the milestone still has to break |

Two things are **already decided** and are not reopened: option A + A2 (the atom), and
[**policy 3**](./policy-3-module-per-type.md) — one BEAM module per `type` and per `behavior`. What
step 0 still owes is one layout call; the rest of the open decisions are in
§ *Decisions the maintainer still owes*.

---

## Half 1 — the atom

### A1 — the problem

Two botopink modules whose source files share a basename become the same Erlang/BEAM module.

```
src/models/user.bp     →  out/models/user.erl     →  -module(user).
src/services/user.bp   →  out/services/user.erl   →  -module(user).
```

Reproduced with erlang directly ([E13](./atom-evidence.md#e13--what-collides-today-two-modules-one-atom)) —
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
are named after an OTP module ([E14](./atom-evidence.md#e14--eleven-libsstd-module-names-are-already-otp-module-names)):
`math`, `os`, `crypto`, `base64`, `queue`, `sets`, `dict`, `json`, `unicode`, `random`, `erlang`.
Loading one wins over `stdlib` and makes every other function of that OTP module `undef`
([E15](./atom-evidence.md#e15--what-shadowing-an-otp-module-actually-does)):

```
$ erl -pa shadow -eval 'io:format("~s~n",[code:which(math)]), io:format("~p~n",[math:pi()])'
which(math) = .../shadow/math.beam
math:pi()   = {'EXIT',{undef,[{math,pi,[],[]},…]}}
```

`snapshots/codegen/erlang/import_multi_module_pub_fn_import.snap.md:10` already records
`-module(math).`, and `import_cross_module_record_construct_and_assoc_fn.snap.md:18` records
`-module(http).`

### A2 — current state

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

> **Re-measured at `c2dd780` (2026-09-18), carrying into 1.0.5-beta.** The suite has grown: **315**
> erlang and **314** beam cells, of which **305** record `-module(main).`, out of **2 573** snapshots
> in all. The shape of every claim above is unchanged — the counts are not. Re-measure before quoting
> a number in a commit message; the ratios (≈ 20 for the rename, 188 for policy 3) are the
> quantities the plan is built on and both moved with the suite (the `%% type` / `%% behavior` /
> `%% implement` marker now matches **98** erlang cells, not 94).

### A3 — mechanism

`erlc` will not compile a `.erl` whose `-module` atom differs from the file's basename, and the
`.beam` produced under `+no_error_module_mismatch` is unloadable
([E1](./atom-evidence.md#e1--the--module-atom-must-equal-the-source-files-basename)). So the atom **is**
the filename, and a path cannot be carried by the directory and the atom at once. The backend's
answer today is to throw the directory away, which makes the atom non-unique. Every downstream
site — the cross-module call target, the snapshot harness's scratch filenames, the audit script's
`<n>/<module>.S` split (`scripts/beam_export_audit.sh:80`) — inherits that.

### A4 — the proposal on the table

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

### A5 — counter-proposal

Three alternatives with worked examples and a comparison table in
[`options.md`](./atom-options.md). **Recommended: option A** — the path joined with `@`, which is a legal
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
([E8](./atom-evidence.md#e8---cannot-address-anything-inside-a-module)), `__t__pessoa` is a **real
loadable module** ([E19](./atom-evidence.md#e19--four-sibling-modules-from-one-source-file)) whose atom
decodes back to `{decl,"models/user","t","pessoa"}`
([E19b](./atom-evidence.md#e19b--the-atom-decodes-back-with-no-ambiguity)). `__` as the boundary between
a source-derived name and generator discriminators is OTP's own convention — `escript` names its
synthesised module `whoami_escript__escript__1789__696388__940472__2306`
([E20](./atom-evidence.md#e20--otps-own-escript-uses-__-the-same-way)).

---

## Half 2 — policy 3

### B1 — decided: one module per `type` and per `behavior`

**Maintainer, 2026-09-17.** Not "slice when it collides" and not today's inlining: **every** `type`
and `behavior` declaration gets its own BEAM module, named by A2 —
`<pathAtom>__t__<decl>`, `__b__<decl>`, `__im__<decl>`. The full working-out, each claim measured or
run, is [`policy-3-module-per-type.md`](./policy-3-module-per-type.md). In summary:

| | |
|---|---|
| **Mechanically sound** | four sibling `.S` modules from one source assemble, load and `call_ext` into each other ([E22](./atom-evidence.md#e22--four-sibling-s-modules-from-one-source-file)); one hot-swaps alone ([E23](./atom-evidence.md#e23--hot-swapping-one-type-module)) |
| **Runtime cost** | `call_ext` vs local call = **0.372 ns/call**, 16.7% on a one-`+` body (the upper bound). Ten million calls cost 3.7 ms more ([E26](./atom-evidence.md#e26--local-call-vs-remote-call)) — irrelevant at the scale of the generated programs |
| **Both manglings die** | `recordMethodAtom` (`erlang.zig:1841`), `interfaceAssocAtom` (`:1408`) and `record_method_collisions` (`:1743`) are deleted; 25 mangled names leave the snapshots |
| **Stack traces name the owner** | `{main, pessoa_greet, …}` → `{models@user__t__pessoa, greet, …, [{file,…},{line,3}]}` ([E24](./atom-evidence.md#e24--a-stack-trace-names-the-owning-type)) |
| **Snapshot cost** | **188 files change shape** — 94 erlang + 94 beam, measured, against ≈ 20 for A2 alone ([`policy-3-module-per-type.md` § 4](./policy-3-module-per-type.md#4-snapshot-cost--measured)) |
| **It breaks something** | `botopink run --target erlang` is `escript out/<mod>.erl` with no `-pa`, so **every** type-bearing program stops running ([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)). The recorded residual becomes a blocker |

**Sequencing.** Half 1 is a *naming* half — 20 snapshots changing an atom on one line. Policy 3
is a *code generation* front — 188 snapshots each gaining whole emitted sections, plus the behavior
dispatch path and a `codegenEmit` signature change. Landing them together makes every one of those
188 diffs carry two reasons at once, and a re-recorded snapshot must be **classified, not
bulk-accepted** ([the rule 1.0.4-beta ran under](../../../1.0.4-beta/overview.md)).
**Decided 2026-09-17 by the maintainer: one front, not two.** Policy 3 runs inside this front as
steps 7–13, and the estimate goes from ≈ 3.5 days to **≈ 9** for halves 1 + 2. The classification problem is met by
ordering rather than by splitting: the atom rename lands first and alone (steps 1–6, ≈ 20 snapshots,
names only), the emitter split after it (steps 7–13, 188 snapshots, shapes), so no commit and no
re-recorded snapshot ever carries both reasons. The steps are in
[`policy-3-module-per-type.md` § 9](./policy-3-module-per-type.md#9-sequencing--decided-2026-09-17-one-front-not-two).

---

## Half 3 — the identity inside the value

### C1 — the problem

Nothing in a record value names its type, on any backend; and where a variant *is* tagged, the tag is
the variant's bare name, which is not unique. Reproduced by compiling one program and running every
backend ([E11](./identity-evidence.md#e11--one-program-five-backends)):

```botopink
type Person(name: string, age: i32) { fn greet(self: Self) -> string { … } }
type Vec(name: string, age: i32)                 // same fields, different type
type Shape { Circle(radius: i32), Dot }
```

| | erlang / beam | commonJS | wasm |
|---|---|---|---|
| `Person(name:"Ana", age:30)` | `#{name => <<"Ana">>, age => 30}` — no tag | `new Person(…)` | a bare heap pointer |
| `Person(…) == Vec(…)` | **`true`** | `false` (reference identity, so two *equal* Persons are also `false`) | `false` (pointer) |
| `Shape.Circle(radius: 5)` | `{'Circle', 5}` | `{ tag: "Circle", radius: 5 }` | ordinal `0` in a cell |
| `Shape.Dot` | `'Dot'` | `"Dot"` — **a bare string** | ordinal `1` in a cell |
| `Color.Red` (all-unit enum) | `'Red'` | `"Red"` | **`i32.const 0`** — the value *is* the number |
| `@print(p)` | `#{name => …,age => 30}` | `Person { name: 'Ana', age: 30 }` | `272` — the pointer |

Decision 8 §7 asks for `Person(name: "Ana", age: 30)` on all four. `'__bp_show'/2`
(`erlang.zig:554`) prints a map because a map is all it is given.

#### C1.1 Three corrections to the first draft of this half

Kept because the first draft asserted them and they are wrong.

| First draft said | Measured at `26d4fdc` |
|---|---|
| "commonJS already has the identity — this is an erlang/beam gap" (§ 1.4) | **Two thirds true.** A record is a class and a payload variant carries `.tag`, but a **unit** variant is the bare string `"Dot"` (`commonJS.zig:1563-1566`), so `d is string` would answer `true` for an enum value, and the emitted `.d.ts` declares `{ tag: "Dot" }` for the same value ([E12](./identity-evidence.md#e12--the-dts-contradicts-the-js-for-a-unit-variant)) — a live `.js`/`.d.ts` contradiction with **0** snapshots covering it |
| "Every record `RUN LOG` and construct line moves — the largest item" (§ 2.4) | **The `RUN LOG` half is zero.** Across all 1 254 snapshots and 997 non-empty `RUN LOG` lines, none prints a record, a tagged tuple, a unit variant atom, a JS class instance or a `tag:` object ([E19](./identity-evidence.md#e19--the-snapshot-blast-radius)). Steps 15–16 change **no `RUN LOG`**, and one that moves is a bug |
| "T1 costs nothing measurable; T2 is 2.5× faster" ([E10](./identity-evidence.md#e10--build-and-match-2-000-000-iterations)) | **Not reproducible.** `erlc +to_asm` shows the compiler **deletes the test entirely** when the value's shape is statically known ([E18](./identity-evidence.md#e18--the-honest-timing)). Through an opaque call the three `is` lowerings are within 0.5 ns. What is real: T1 = +2 words per record and +0.165 ns per construct; the enum half is free |

And one thing the first draft did not consider, which changes the shape of steps 15–16: **qualify the
variant tag instead of prefixing the variant term** (§ 2.2). It is free in space, changes no opcode
and no arity, and makes step 16's "`is_tagged_tuple`'s arity argument grows by one" unnecessary.

### C2 — the proposal

#### C2.1 The identity is the A2 atom

```
typeAtom(path, decl)             = erlAtom(path) ++ "__t__" ++ lower(decl)
variantAtom(path, decl, variant) = typeAtom(path, decl) ++ "__v__" ++ lower(variant)
```

The first line is [A2](./declaration-qualifier.md) verbatim —
`erlDeclAtom(alloc, id, .t, decl, null)`, written by
[step 1](#step-1--one-canonical-identity-one-renderer-per-backend) of half 1.
The second is the **one thing half 3 asks half 1 for**: a `__v__` segment so a variant tag decodes
the same way — in 1.0.4-beta that was a cross-front agreement between 16 and 19; in one front it is
an internal decision, taken here. Both are legal **unquoted** atoms and both decode with one extra clause on A2 § 5's
decoder ([E15](./identity-evidence.md#e15--the-qualified-variant-tag)).

The other three identities are ruled out, each by a measurement, in [`identity-options.md`](./identity-options.md) § 1:
(b) a non-atom tag costs the same words and needs a whole-program id pass `codegenEmit` cannot do;
(c) an identity reached through a carried function **cannot be read in a guard**
(`illegal guard expression`, [E17](./identity-evidence.md#e17--a-carried-function-cannot-be-read-in-a-guard)),
so decision 8 §5.4's exhaustive `case` is impossible under it; (d) structural typing already fails on
real code — 6 field-sets are shared by 18 differently-named types and `Circle` is declared in 5 files
([E14](./identity-evidence.md#e14--how-often-the-names-already-collide)).

#### C2.2 Where it sits

| | Recommended | Cost |
|---|---|---|
| a **record** | **T1** — one key, `#{'__bp_type' => 'app@models__t__person', name => …}` | +2 words; `maps:get` and `#{x := X}` patterns keep working unchanged ([E1](./identity-evidence.md#e1), re-confirmed on the compiler's own output in [E13](./identity-evidence.md#e13--both-spellings-applied-to-the-compilers-own-output)) |
| an **enum variant** | **qualify the tag atom**, not prefix the term: `{'app@models__t__shape__v__circle', 5}` and `'app@models__t__shape__v__dot'` | **zero words** — an atom is an immediate and the tuple keeps its arity ([E16](./identity-evidence.md#e16--the-size-of-every-candidate)). No opcode changes: `is_eq` stays `is_eq`, `is_tagged_tuple` keeps `fields.len + 1` |
| an **anonymous** record / tuple | untagged | decision 8 §6 — positional, compared without labels; `is #(i32, string)` stays an arity-plus-element test |
| `{ok, V}` / `{error, E}` | untouched | built by the `#[@result]` transform, already special-cased in both `variantTag`s |

T2 (the whole record as a tagged tuple, 7 words instead of 13) stays open as step 20, and the reason
to take it is **space, not time** — see the E10 correction above.

#### C2.3 What each decision-8 item becomes

```erlang
%% x is Person
is_map(X) andalso maps:get('__bp_type', X, undefined) =:= 'app@models__t__person'

%% x is Shape          — the checker knows the variant list; every test is guard-legal (E15)
X =:= 'app@models__t__shape__v__dot'
  orelse (is_tuple(X) andalso tuple_size(X) > 0
          andalso element(1, X) =:= 'app@models__t__shape__v__circle')

%% case v { Person { p -> … } Car { c -> … } }   — exhaustive, no `_` (E4)
case V of
    #{'__bp_type' := 'app@models__t__person'} = P -> …;
    #{'__bp_type' := 'app@models__t__car'}    = C -> …
end

%% @print(p)  →  §7's `Person(name: "Ana", age: 30)`
'__bp_show'(#{'__bp_type' := T} = M, _) -> T:format(M);   %% under policy 3: one call_ext, no table
```

The last line is the reason the identity must be the **module** atom and not any injective tag:
under [policy 3](./policy-3-module-per-type.md) the tag *is* the module that holds
`format/1`, so §7's per-type formatter needs no dispatch table and a crash inside it names the type
in the stack trace ([`halves-and-ordering.md`](./halves-and-ordering.md) § 2).

#### C2.4 What it fixes that was not asked for

`Person(name:"Ana", age:30) == Vec(name:"Ana", age:30)` is **`true`** on erlang and beam today and
becomes `false` (E11, E13). commonJS already answers `false`, but by reference identity, so it also
answers `false` for two *equal* Persons — the same mechanism 1.0.4-beta's front 15
([`language-tests`](../../../1.0.4-beta/15-language-tests/README.md), delivered) already pins for tuples
(`tests/language/expected-failures.txt`, two `tuple_equality.bp` rows, now
[`../04-js/`](../04-js/README.md)'s). No row in [`../02-erlang/`](../02-erlang/README.md) or
[`../03-beam/`](../03-beam/README.md) names the record case.

#### C2.5 Costs, named

| Cost | Size |
|---|---|
| 130 erlang + beam snapshots change one or two emitted lines each | [`identity-blast-radius.md`](./identity-blast-radius.md) § 1 — classify, never bulk-accept ([the rule 1.0.4-beta ran under](../../../1.0.4-beta/overview.md)) |
| `RUN LOG`s that move | **0** — and one that moves is a bug (E19) |
| Between step 16 and step 18 the printed form of a record is *worse* than today (it shows `'__bp_type'`) | both steps must land in the same release; step 18's acceptance closes it |
| +2 words per record value, +0.165 ns per construct; the enum half free | E16, E18 |
| 142 new atoms for the whole ecosystem | against 10 397 in a bare node and a 1 048 576 limit (E14) |
| A user field literally named `__bp_type` | the `__` prefix is reserved by [A2 § 4](./declaration-qualifier.md); half 1's collision check rejects it |
| `.bp` source change in any library | **none** |

---

## Steps

### Half 1 — the atom (steps 0–6)


### Step 0 — the maintainer picks a scheme

**Option A + A2 is chosen and policy 3 is decided.** What remains for step 0 is one layout call and
one open question. Layout: **A-flat** (`out/erl/<atom>.erl`, recommended) or **A-nested** —
policy 3 pushes hard toward A-flat, since one `.bp` now yields N files
([`policy-3-module-per-type.md` § 7](./policy-3-module-per-type.md#7-layout-and-cli)). The
sequencing call is closed: one front, ≈ 9 days.

One open question that could move the recommendation from A to C: Elixir compiles `MyApp.User` to
the atom `:"Elixir.MyApp.User"` and a flat `Elixir.MyApp.User.beam`. `elixir` is **not installed**
in this environment, so that is unverified. If it is right, C is industrial prior art for the
maintainer's dotted form and the quoting cost is a known, paid-for cost elsewhere.

**Acceptance:**
- [ ] A-flat or A-nested recorded here in one line
- [x] The split is rejected — policy 3 is this front's steps 7–13 (maintainer, 2026-09-17)
- [ ] The Elixir claim is verified or explicitly dropped (it no longer changes the recommendation —
      option A is chosen — but it is still an unverified sentence in [`options.md`](./atom-options.md))

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
      ([E21](./atom-evidence.md#e21--__-has-to-be-reserved)), and a name that would exceed 250 bytes
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
([E17](./atom-evidence.md#e17)), so the check cannot read the exit code alone.

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
- ~~`botopink run --target erlang` is `escript out/<mod>.erl` with no `-pa`~~ — **promoted to a
  blocker by policy 3** ([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)): every
  type-bearing program becomes multi-module, so this must be fixed before policy 3 lands. It is
  **step 7** of this front ([the second half](./policy-3-module-per-type.md#9-sequencing--decided-2026-09-17-one-front-not-two)),
  not a residual.
- The comptime server never purges a loaded module (`runtime/persistent_erl.zig:63-73`, no
  `code:purge/1`) and never deletes `.botopinkbuild/tmp/{template,decorator}/*.erl`. Unbounded in a
  long-lived process; irrelevant for a one-shot build. Not this front's, but found by it.

**Acceptance:**
- [ ] Each residual is a row in [`../fronts.md` § Unowned items](../../../1.0.5-beta/fronts.md#unowned-items) or in a
      named front, with its file and its finder

### Half 2 — policy 3 (steps 7–13)

The seven steps, each with its acceptance, are in
[`policy-3-module-per-type.md` § 9](./policy-3-module-per-type.md#9-sequencing--decided-2026-09-17-one-front-not-two).
**Step 7 is the `botopink run --target erlang` `-pa` fix**, which opens this half because policy 3
breaks that command for every type-bearing program until it lands
([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)).

### Half 3 — the identity in the value (steps 14–20)


### Step 14 — `typeAtom` / `variantAtom`, no behaviour change

Beside step 1's `erlDeclAtom` in `crossModule.zig`, reusing its `Kind` enum and its `RESERVED` /
250-byte checks. Extend step 1's collision check (`crossModule.build`, `crossModule.zig:86`) to the type and
variant atoms. **Nothing consumes them yet.**

**Acceptance:**
- [ ] Every snapshot in all four codegen directories byte-identical (`zig build test`)
- [ ] Unit tests: a single-segment path, a multi-segment path, a reserved name, a type whose name
      needs escaping, a variant whose name needs escaping, a name over 250 bytes
- [ ] Two declarations rendering the same atom is a **located diagnostic**, with a test
- [ ] A2 § 5's decoder, extended with the `__v__` clause, is a test — `variantAtom` round-trips to
      `{variant, path, "t", decl, variant}` (E15)

### Step 15 — the tag in the value, erlang

`erlang.zig:4702-4708` adds `'__bp_type' => typeAtom(owner, cc.callee)`, where `owner` is
`Emitter.module_name` (`:1586`) for a local type and `ExportInfo.module` (`crossModule.zig:30-50`,
read at `:2840-2841`) for an imported one — **no new cross-module index key**
([`options.md` § 6](./identity-options.md#6-cross-module--verified-and-free)). `variantTag` (`:5073-5076`)
returns the qualified atom, which covers the construct sites (`:4194-4199`, `:4776-4782`) and the
pattern sites (`:5030`, `:5038-5048`) at once. Access, destructuring and `case` machinery are
**untouched**.

**Acceptance:**
- [ ] A new fixture: two types with identical fields are `!=`, executed on erlang (today `true`,
      E11)
- [ ] A new fixture: two enums declaring the same variant name, both `case`d in one program,
      executed — today they produce the same term (E14)
- [ ] Existing `#{x := X}` destructuring, `maps:get` access and every `case` cell still run
      (E13 pins this on real emitted output)
- [ ] The 62 erlang cells re-recorded and classified one by one; **no `RUN LOG` moves**
- [ ] An imported type constructed in a consumer carries the **owner's** atom, executed
      (`import_cross_module_record_construct_and_assoc_fn.snap.md` is the fixture to extend)

### Step 16 — the same on beam

`lowerRecordConstruct` (`:4516-4536`, called from `:3482-3494` where `cc.callee` is the type name),
`variantTag` (`:1684-1689`), the unit-variant construct (`:6212-6225`, where `rn` is the enum's
name), and the two tests (`:5272-5286` `is_eq`, `:5333` `is_tagged_tuple`). Under the recommended
spelling **no arity and no opcode changes** — only the atom the tests compare against.

**Acceptance:**
- [ ] `scripts/beam_export_audit.sh` green at its current total
- [ ] The erlang and beam `RUN LOG`s of every shared fixture agree, line for line
- [ ] The 68 beam cells re-recorded and classified; no `RUN LOG` moves
- [ ] `grep -c is_tagged_tuple` over `snapshots/codegen/beam/` is unchanged, and no
      `is_tagged_tuple` arity argument differs from before — the check that the free spelling was
      actually taken

### Step 17 — `is` and `case` over a named type — **after [`../01-checker/`](../01-checker/README.md)'s N20/N21/N22**

`x is T` for a named type and a variant; a `case` arm that is a named type or a union of them
(decision 8 §4.2, §3.3, §5.1, §5.3b). These are the **D8-1** and **D8-3** rows of
[`../02-erlang/`](../02-erlang/README.md) and [`../03-beam/`](../03-beam/README.md), for the
named-type half — the split the maintainer still owes (§ *Decisions*, and
[`halves-and-ordering.md`](./halves-and-ordering.md) § 5).

**Acceptance:**
- [ ] `tests/language/` cells for `x is Point`, `x is Option.Some(v)`, and a `case` over
      `Person | Car` with **no `_`**, passing on erlang and beam
- [ ] The matching lines leave `tests/language/expected-failures.txt`
- [ ] A `case` over a union is emitted as erlang patterns only — **no type test of the backend's
      own**, and no catch-all ([E4](./identity-evidence.md#e4))
- [ ] erlang, beam and commonJS agree on every cell

### Step 18 — §7's formatter — **after step 17**

`'__bp_show'/2` dispatches on the tag. Under policy 3 that is `T:format(M)`, one `call_ext`; the
per-type `format/1` is emitted into the type's own module. Hide `'__bp_type'` from user-visible
output. This is the **D8-5** row of [`../02-erlang/`](../02-erlang/README.md) and
[`../03-beam/`](../03-beam/README.md) for the `record` and `variant` rows of §7's table, plus
`Display` — again the pending split.

**Acceptance:**
- [ ] `@print(Point(x: 1, y: 2))` prints `Point(x: 1, y: 2)` on erlang and beam, `@print(Shape.Dot)`
      prints `Shape.Dot`, `@print(Shape.Circle(radius: 4))` prints `Shape.Circle(radius: 4)` — new
      `tests/language/` cells, because **no existing snapshot prints a composite value** (E19)
- [ ] A type implementing `Display` prints its `display()`, also when nested (decision 8 §7)
- [ ] `'__bp_type'` appears in no printed output
- [ ] The four backends produce the same text for the same program

### Step 19 — the commonJS unit-variant hole — **only if the maintainer assigns it**

`commonJS.zig:1563-1566` emits a unit variant as a bare string, so `Shape.Dot === "Dot"` and the
emitted `.d.ts` (`typescript.zig:115-127`) describes a shape the emitter does not produce (E12).
Two ways out, and this front does not choose unilaterally because `commonJS.zig` is
[`../04-js/`](../04-js/README.md)'s:

| | Cost |
|---|---|
| emit `{ tag: "Dot" }` and make `is` / `case` read `.tag` uniformly | 13 commonJS snapshots; the `.d.ts` becomes true |
| keep the string and make the checker refuse `is string` on an enum value | 0 snapshots; contradicts decision 8 §4.1 ("`is` tests the value, not the origin") |

**Acceptance (either way):**
- [ ] The `.js` and the `.d.ts` of the same program agree — a new fixture with a `pub` mixed enum,
      which no snapshot has today
- [ ] `x is string` answers `false` for a unit variant on commonJS, as it does on erlang

### Step 20 — decide T2

Re-measure on a wide record from a real program (erika's rows, jhonstart's html tree) before
committing. If the space win holds, rewrite construct + access + destructure + patterns to the
tagged tuple in one mechanical commit.

**Acceptance:**
- [ ] A maintainer decision recorded here, whichever way it goes, with the re-measured numbers —
      **not** E10's, which do not survive (E18)


## Gate

### Halves 1 and 2

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
- [ ] The stale comment at `erlang.zig:5359` is corrected — it claims the associated fn is quoted
      `'Array_range'`; `interfaceAssocAtom:1410` lowercases the first character, so the emitted atom
      is bare `array_range` ([`policy-3-module-per-type.md` § 1.1](./policy-3-module-per-type.md#11-today-one-erl-per-bp-everything-flat-inside-it))
- [ ] Commit on `fix/module-identity`; no push, no merge

**Policy 3's half (steps 7–13) adds:**

- [ ] `botopink run --target erlang` executes a type-bearing program (today it cannot —
      [E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3))
- [ ] `recordMethodAtom`, `isRecordMethodCollision`, `record_method_collisions` and
      `interfaceAssocAtom` are **deleted**, not bypassed
- [ ] Two types in one file both declaring `greet/1` compile and run on erlang and beam
- [ ] A behavior consumed by three modules has exactly **one** emitted copy of its associated fn
- [ ] The 188 re-recorded snapshots classified one by one — which gained a module, which turned a
      local call into a `call_ext`; **no `RUN LOG` should change**, and one that does is a bug

### Half 3

- [ ] `scripts/gate.sh --cold` green in this front's worktree
- [ ] `zig build test-libs` at its baseline — `9 passed, 0 failed, 0 known red, 3 skipped, 2 without
      tests` (measured at `26d4fdc`); `scripts/known-red-libs.txt` still empty (re-checked at `c2dd780`: header comments only)
- [ ] `scripts/beam_export_audit.sh` green at its current total
- [ ] Every re-recorded snapshot classified (construct line / variant atom / nothing else); **no
      `RUN LOG` re-recorded in steps 14–16**, and one that is, is a bug with an explanation in the
      commit message
- [ ] erlang, beam and commonJS agree on `is`, on a union `case`, and on §7's print text
- [ ] The invariant, as a test: **two values carry the same identity if and only if they were built
      by the same declaration** — one cell per backend
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] The same branch, `fix/module-identity`; no push, no merge


## Blast radius

### Halves 1 and 2

| What moves | Size |
|---|---|
| Snapshots re-recorded, option A + A2 (**name only**) | **≈ 20** of 2519 (the 9 multi-module erlang fixtures + their beam twins) |
| Snapshots changing **shape**, policy 3 | **188** — 94 erlang + 94 beam, measured (`grep -rl '^%% \(type\|behavior\|implement\) '`); commonJS (313) and wasm (312) unaffected |
| Snapshots re-recorded, option P or C | **≈ 620** — every `-module(main).` becomes `'main'` |
| Compiler source, option A + A2 | ≈ 180 LOC across 9 files |
| Compiler source, policy 3 | `recordForms`/`enumForms`/`interfaceForms`/`implementForms` split, `codegenEmit` yields N artifacts, `build.zig` + `run.zig`, `beam_asm.zig` mirrored, three mangling helpers deleted |
| Runtime, policy 3 | **+0.372 ns per method call** ([E26](./atom-evidence.md#e26--local-call-vs-remote-call)) — 3.7 ms per ten million calls |
| `.bp` source in `libs/std` or any sibling library | **none** — no library writes a module atom |
| commonJS / typescript / wasm output | unchanged by construction |
| `out/` layout for erlang and beam | flat — anything scripted against `out/std/math.erl` breaks |

The breakdown, with the commands that produced each number, is in
[`migration.md`](./migration.md). Estimated **≈ 3.5 days** for option A + A2 and **+5–7 days** for policy 3 — **≈ 9 days** for the
front, which is how it runs (decided 2026-09-17: one front, not two).

Two risks worth naming. First, the naming half fixes **latent** failures: nothing red today turns
green, so step 4's new cells are the only evidence the work did anything. Second, policy 3 is the
opposite — it turns something green **red on the way**: `botopink run --target erlang` stops working
for every type-bearing program until its `-pa` fix lands
([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)), which is why that fix opens the
second half instead of being a residual.


### Half 3

| What moves | Size |
|---|---|
| Snapshots changing **one or two emitted lines** | **130** — 62 erlang + 68 beam, measured ([`identity-blast-radius.md`](./identity-blast-radius.md) § 1) |
| `RUN LOG`s that move | **0** — and one that moves is a bug ([E19](./identity-evidence.md#e19--the-snapshot-blast-radius)) |
| commonJS snapshots | **13**, and only if the maintainer assigns step 19 |
| Runtime | +2 words per record value, +0.165 ns per construct; the enum half **free** ([E16](./identity-evidence.md#e16--the-size-of-every-candidate), [E18](./identity-evidence.md#e18--the-honest-timing)) |
| New atoms for the whole ecosystem | **142**, against 10 397 in a bare node and a 1 048 576 limit |
| Compiler source | ≈ 40 LOC in `crossModule.zig`, the value-shape sites in both emitters, ≈ 250 for the `is` / union-`case` / formatter lowerings |
| `.bp` source in any library | **none** |

Of the 130, **62 are erlang cells half 2 has already re-recorded once** — which is the whole reason
the halves are ordered rather than merged into one commit.

## Ownership conflicts

Against the fourteen fronts of 1.0.5-beta. `yes` = may run at the same time · `no` = shares a file
or a snapshot directory, sequence them · `seq` = no shared file, but the milestone orders them.

| Against | | Why |
|---|---|---|
| **01** checker | **no** | 01 owns `src/comptime/**`; this front needs the module-atom lines and the `buildModule` signatures of `{template_eval,decorator_eval}.zig` as a carve-out (step 5). 01 may also re-record all four codegen directories. Steps 17–19 additionally *depend* on 01's N19–N22 — the checker half; the grammar half landed at `c2dd780` |
| **02** erlang | **no** | shares `src/codegen/erlang.zig` and `snapshots/codegen/erlang/`. Steps 1–6 are a four-site carve-out that changes no shape; **steps 7–20 own the file wholesale, and under the maintainer's order 02 stalls while they run** — then opens against a value that already knows its type, so its decision-8 rows D8-1/D8-2/D8-3/D8-5 need no split |
| **03** beam | **no** | the same, for `src/codegen/beam_asm.zig`, `src/codegen/beam/**` and `snapshots/codegen/beam/`: **03 stalls while halves 2–3 run** |
| **04** js | **yes**, except step 19 | JS output layout does not change ([`js-modules.md`](./js-modules.md)). Step 19 edits `commonJS.zig:1563-1566` and `typescript.zig:115-127` and re-records 13 cells — only if the maintainer assigns it here rather than to 04 |
| **05** wasm | **yes** | this front does not write `wat.zig`. It *supplies* 05 with the atom list its box should carry, so that `is Person` means the same thing on both backends — see the pending decision below |
| **06** comptime-dedup | **yes** | 06 owns `src/comptime/snapshot.zig` and `snapshots/comptime/**`; this front touches neither |
| **07** review-backlog | **no** | 07 owns `src/codegen/tests/**`, where this front adds fixtures, and its wave A reads the snapshots this front re-records. A fixture carve-out, as 02 and 03 have; wave A runs after |
| **08** hygiene | **no** | 08 owns comments and `AGENTS.md` sweeps across the directories this front rewrites; sequence the `AGENTS.md` edits |
| **09** ecosystem residuals | **seq** | no library needs a source change — measured: 0 of 115 `.bp` files writes a module atom or a value shape — but every library's erlang and beam cell executes output this front renames and reshapes. 09 re-runs after |
| **10** cli residuals | **no** | shares `modules/compiler-cli/src/cli/{build.zig,run.zig}`: this front changes the output layout and adds `-pa`. Sequence them |
| **11** tooling | **yes** | `scripts/beam_export_audit.sh` derives a filename from the recorded atom and must stay green at its current total; no source file is shared |
| **12** language tests | **yes** | 12 adds no source change and re-records no snapshot. The shared files are `tests/language/expected-failures.txt` (delete-only here) and the `tests/language/` cells steps 17–18 add — coordinate them |
| **14** comptime-on-beam | **no**, and **14 runs first** | shares `buildModule` in `src/comptime/{template_eval,decorator_eval}.zig` (step 5 against 14's step 2 — 14 first, so this front inherits a module keyed by the declaration) and the file `src/codegen/erlang.zig` in disjoint functions (14's `ComptimeModule` / `emitComptimeModule` against this front's atom and value-shape sites). Snapshot overlap **measured at 0**: none of 14's 48 `COMPTIME ERLANG` cells is one of this front's 318 |

## Notes

- The proposal's strongest result is one it was not aimed at: the eleven `libs/std` modules that
  shadow OTP. That is a live, silent, node-wide failure ([E15](./atom-evidence.md#e15--what-shadowing-an-otp-module-actually-does)),
  worse than the same-basename collision, and any scheme chosen in step 0 must close it.
- `libs/std/src/erlang.bp` would emit `-module(erlang)` if it ever gained a `pub fn`. `erlang` is
  preloaded and cannot be replaced — the module would compile, load without complaint, and be
  unreachable. It is declaration-only today (`@External.Erlang` catalogue), which is the only
  reason this has not bitten.
- `erlc` stages its output through `<name>.bea#` (visible in
  [E7](./atom-evidence.md#e7--the-real-length-cap-is-the-filename-not-the-atom)). A `#` in a module name
  is a character the toolchain already spends on its own temporary files.
- Not tested, because not installed: `rebar3`, `elixir`. Both are named in the analysis with that
  caveat.

---


- The identity half's strongest result is also one it was not aimed at:
  `Person(name:"Ana", age:30) == Vec(name:"Ana", age:30)` is **`true`** on erlang and beam today
  ([E11](./identity-evidence.md#e11--one-program-five-backends)) and becomes `false`. No row in
  [`../02-erlang/`](../02-erlang/README.md) or [`../03-beam/`](../03-beam/README.md) names it.
- Three claims of the identity half's first draft were **wrong and are corrected in place**
  (§ C1.1): commonJS does not already have the identity, the `RUN LOG` blast radius is **zero**, and
  the "T2 is 2.5× faster" figure is **withdrawn** — `erlc +to_asm` shows the compiler deletes the
  test entirely when the shape is statically known ([E18](./identity-evidence.md#e18--the-honest-timing)).

## Decisions the maintainer still owes this front

1. ~~**The circular dependency, and the cut that breaks it.**~~ **Withdrawn — the maintainer's
   order removes it.** With **14 → 13 → the backends**, the identity exists before 02, 03, 04 and
   05 open, so none of decision 8's run-time rows has to be split and nothing waits for something
   that waits for it. The cut below is kept only as the **fallback**, and it becomes necessary again
   only if 02 or 03 is allowed to open before halves 2–3 land. Nothing here is owed while the order
   holds. What follows is the record.

   The run-time half of [decision 8](../../../1.0.4-beta/08-review-backlog/decision-8-language.md) —
   rows **D8-1** (`x is T`), **D8-2** (`unknown` and unions), **D8-3** (`case` arms) and **D8-5**
   (the §7 formatter) — now lives in the four backend fronts
   [`../02-erlang/`](../02-erlang/README.md), [`../03-beam/`](../03-beam/README.md),
   [`../04-js/`](../04-js/README.md) and [`../05-wasm/`](../05-wasm/README.md). None of those rows
   can be written **for a named type** before a value knows its own type — which is half 3 of this
   front. And halves 2–3 of this front run **after 02 and 03 close**. That is a cycle:

   ```
   02 / 03  ──►  their decision-8 rows  ──►  need a value that knows its type
      ▲                                                    │
      └──────────  13 halves 2–3 run after 02/03 close  ◄──┘
   ```

   **The fallback cut, if the order is ever reversed:**

   | Row | Stays with the backend fronts (02, 03, 04, 05) | Moves to this front, half 3 |
   |---|---|---|
   | D8-1 `x is T` | `i32`/`i64`/`f64`/`string`/`bool` by range and kind; `#(i32, string)` by arity; wasm reads decision 3's box tag | `x is Point`, `x is Option.Some(v)`, `x is Box<unknown>` on erlang and beam |
   | D8-2 `unknown` / unions | the wasm box, §2.3 numeric equality | a union whose members are **named types** on erlang and beam |
   | D8-3 `case` arms | literal, range, tuple, `_`, guards, `..` | an arm that is a named type or a section (§5.3b) |
   | D8-4 `row.label` → index | all of it | — |
   | D8-5 the formatter | the primitive, array and tuple text; `f64` always `5.0` | the `record` and `variant` rows of §7's table, and `Display` |
   | D8-6 `loop (condition)` | all of it (already delivered by 1.0.4's 06 G0) | — |

   **What each ordering costs.**
   - *The maintainer's order (14 → 13 → backends).* No cut, every snapshot written once,
     `buildModule` inherited. Cost: **02 and 03 stall** while halves 2–3 run — 318 re-recorded
     cells in the two directories they own. 04 and 05 run throughout.
   - *Take the cut.* The order becomes acyclic — 02/03 land the primitive, tuple, wasm-box and
     `loop` halves, close, and this front lands the named-type halves in steps 17–18. Cost: rows
     move between front READMEs this front does not edit, and decision 8's run-time table is
     delivered in two pieces, in two releases.
   - *Refuse the cut and keep D8 whole in 02/03.* Then 02 and 03 cannot close until a value knows
     its type, so half 3 must land **inside** them — which puts the atom rename, the module split
     and the value reshaping in the same front as the primitive `is` lowerings, and re-records the
     318 + 130 cells under two owners at once. Cost: the classification rule breaks, which is the
     one rule both original fronts were built around.
   - *Refuse the cut and run this front first.* Then halves 2–3 open `erlang.zig` and `beam_asm.zig`
     wholesale before 02 and 03 have started, and every 02/03 row lands on top of a re-shaped
     emitter. Cost: 02 and 03 are rewritten against a moving file; the 318 cells are re-recorded
     once by this front and again by them.

   **Decided: the maintainer's order.** It is the only one of the four that keeps one reason per
   diff *and* writes every snapshot once.

2. **A-flat or A-nested** (step 0). `out/erl/<atom>.erl` flat, or a nested tree. Policy 3 pushes hard
   toward A-flat, since one `.bp` now yields N files. One line, recorded in step 0.
3. **The carve-out for half 1** — whether 02 and 03 hand this front the four module-atom sites while
   they are open, or the whole front waits for them to close. This decides whether the ≈ 20-snapshot
   rename can start in parallel at all.
4. **The carve-out from 01** — the module-atom lines and the `buildModule` signatures of
   `src/comptime/{template_eval,decorator_eval}.zig` (step 5).
5. **commonJS's unit variant** (step 19). Either 13 snapshots and a `.d.ts` that is finally true, or
   a checker rule that contradicts decision 8 §4.1. `commonJS.zig` is
   [`../04-js/`](../04-js/README.md)'s, so this front will not take it unasked.
6. **T1 or T2 as the end state** (step 20). T1 now, T2 later is the recommendation; the remaining
   argument for T2 is 6 words per record value, **not** speed — the 2.5× figure is withdrawn
   ([E18](./identity-evidence.md#e18--the-honest-timing)).
7. **wasm's identity** ([`representation.md`](./representation.md) § 6). wasm has *no* identity — a
   record is a raw pointer and `Color.Red` is literally the integer `0`. The sketch in
   [`identity-options.md`](./identity-options.md) § 7 (an index into a per-module table of the atoms,
   so index and atom agree by construction) is untested and is
   [`../05-wasm/`](../05-wasm/README.md)'s to design. **If 05 designs it independently, `is Person`
   will mean two different things on two backends.**
8. **Does a `behavior` need an atom too?** Nothing in decision 8 asks to test "implements `Show`" at
   run time. A2 reserves `__b__`; this front does not use it for an identity.
9. **The Elixir claim** (step 0), verified or explicitly dropped. `elixir` is still **not installed**
   in this environment (re-checked at `c2dd780`), so the sentence in
   [`atom-options.md`](./atom-options.md) is still unverified. It no longer changes the
   recommendation.

## Rows for `fronts.md`

This front is **new to 1.0.5-beta's `fronts.md`** — 1.0.4's rows are part of the closed record and
carry the old numbers 16 and 19. Paste the three below; this front edits neither `fronts.md` nor
`overview.md`, both of which are the maintainer's.

### 1. The ownership row

```markdown
| **13** [`module-identity`](./README.md) | `src/codegen/crossModule.zig` · `src/codegen/{erlang.zig,beam_asm.zig,runtime.zig}` — the **module-atom sites** for steps 1–6 (carve-out of 02 and 03), the two emitters **wholesale** for steps 7–20 · `modules/compiler-cli/src/cli/{build.zig,run.zig}` (the output layout, and `botopink run --target erlang`'s `-pa`) · the module-atom lines and `buildModule` signatures of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 01) · the `tests/language/` cells for `is`, a named-type union `case` and decision 8 §7's printed form (coordinate with 12) | `snapshots/codegen/{erlang,beam}/`: **≈ 20** (half 1, names) then **188** (half 2, shapes) then **130** (half 3, value lines) | not started — **runs immediately after 14**; **02 and 03 stall while halves 2–3 run** (both emitters owned wholesale); steps 17–19 additionally after 01's N19–N22. Merged from 1.0.4-beta's 16 and 19 |
```

### 2. The conflict notes

```markdown
- **13 × 02 and 13 × 03 — 02 and 03 stall while 13's halves 2–3 run.** 13 owns
  `src/codegen/erlang.zig` and `src/codegen/beam_asm.zig` **wholesale** for steps 7–20 and
  re-records **318** cells in the two snapshot directories 02 and 03 own, so neither front may be
  open at the same time. Half 1 (steps 1–6) is the exception: four module-atom sites, no emitted
  shape — a carve-out if 02 or 03 needs to be open beside it. The ordering rule inside 13 is the
  milestone's own: the atom rename lands first and alone, the module split second, the value
  reshaping third, so no commit and no re-recorded snapshot carries two reasons. **Because 13 runs
  before them, 02 and 03 write their decision-8 rows against a value that already knows its type —
  no split of D8-1/D8-2/D8-3/D8-5 is needed** ([`13-module-identity/halves-and-ordering.md`](./halves-and-ordering.md) § 5).
- **13 × 01 (checker).** 13 takes the module-atom lines and the `buildModule` signatures of
  `src/comptime/{template_eval,decorator_eval}.zig` as a carve-out of 01, which owns
  `src/comptime/**`; 01 may also re-record all four codegen directories. Steps 17–19 additionally
  *depend* on 01's N19–N22 — the checker half; decision 8's grammar landed at `c2dd780`.
- **13 × 04 and 13 × 05.** Unaffected by the stall — both run in parallel with 13 throughout.
- **13 × 04.** `yes`, except step 19 (the commonJS unit-variant hole, 13 cells), which 13 takes only
  if the maintainer assigns it here rather than to 04.
- **13 × 05.** `yes` for the files. But wasm carries no identity at all, and 13 supplies the atom
  list 05's box should agree with; designed independently, `is Person` means two different things on
  two backends.
- **13 × 07.** 07 owns `src/codegen/tests/**`, where 13 adds fixtures, and its wave A reads the
  snapshots 13 re-records. 13 needs the same fixture carve-out 02 and 03 have; wave A runs after 13.
- **13 × 10.** They share `modules/compiler-cli/src/cli/{build.zig,run.zig}`: 13 changes the output
  layout and adds `-pa`. Sequence them.
- **13 × 12.** `yes` — the shared files are `tests/language/expected-failures.txt` (delete-only from
  13's side) and the `tests/language/` cells 13's steps 17–18 add.
- **13 × 14.** They share `buildModule` in `src/comptime/{template_eval,decorator_eval}.zig`:
  13 step 5 changes the module atom and threads the owner's path and declaration name through the
  same function 14 step 2 restructures. **14 step 2 first** — it makes the comptime module per
  declaration, which is exactly the key 13's `erlDeclAtom(owner_path, .tpl, decl_name, hash)` wants.
  They also share `src/codegen/erlang.zig` in disjoint functions; snapshot overlap is **0, measured**.
- **13 × 09.** `seq` — no library writes a module atom or a value shape (0 of 115 `.bp` files), but
  every library's erlang and beam cell executes output 13 renames and reshapes. 09 re-runs after 13.
```

### 3. The front-table row

```markdown
| [`13-module-identity`](./README.md) | high | not started — **immediately after 14**; 02 and 03 stall while halves 2–3 run | Two botopink modules whose files share a basename become the same Erlang/BEAM module, silently, and eleven `libs/std` modules shadow an OTP module node-wide; and no value on any backend knows its own type, so `is`, unions, a `case` over named types and decision 8 §7's per-type formatter have nothing to test. One front, three halves that land in order: **the atom** (option A + A2, ≈ 20 snapshots, names only), **policy 3** (one BEAM module per `type` and per `behavior` — both name manglings deleted, 188 snapshots, shapes), and **the identity in the value** (the qualified atom inside the term, 130 snapshots, 0 `RUN LOG`s). Merged from 1.0.4-beta's fronts 16 and 19 |
```

### The residual the policy-3 decision changed

`fronts.md` — Unowned items: the `botopink run` row 1.0.4's front 16 filed is **not** a residual. It
is **step 7's blocker**: under policy 3 every type-bearing program is multi-module, so
`escript out/<mod>.erl` fails with `undefined function …:greet/1`
([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)). The fix is the
`erl -noinput -pa <dir> -s <entry>` shape `runtime.zig:581` already runs.

---

## Handed over by `14-comptime-on-beam` (2026-09-18, `bef762b`)

**Step 3 of front 14 waits on this front, and its blocker is measurable here today.** The untyped
comptime mode on beam cannot be written while the **typed** backend fails the same case:
`"a b".split(" ").map({ x -> x.toUpper() })` with `--target beam` assembles and then dies at run time
with `{unresolved_method, toUpper, 1}`, while straight-line typed code (`.trim()`, `.slice()`,
`.split()`, `.join()`, a record field, an `if`) runs. In a comptime body **every** receiver is untyped,
so that path is the whole feature. `beam_asm.zig` is 6 401 lines with **0** occurrences of
`ComptimeModule`, `'__bp_len'`, `'__bp_json'` or `'__bp_prim_'`, and ~80 type-directed sites would have
to grow an untyped arm.

**And the prize shrank**, measured after 14's step 2 landed: step 3 would save ≈ 39 ms of a 645 ms
erika-linq build (≈ 6 %), because the erl-side cost is now paid once per build instead of 18 times.
