# Options — three naming schemes, compared against the proposal

Read [`erlang-atoms.md`](./erlang-atoms.md) first for the current state and why the proposal's `#`
half does not work. This file is the counter-proposal.

Throughout, **path** means the module path the compiler already carries (`ComptimeOutput.name`,
`src/comptime.zig:1198`) — `main`, `std/math`, `models/user`, `rakun/http`. It is derived from the
source tree by `scanner.zig:62` / `resolver.zig:210` / `libs.zig:323`, never written by the user.

---

## Option P — the maintainer's proposal, as stated

```
'<module>@<dir1>.<dir2>…#<Decl>'
'@comp__<module>@<dir1>.<dir2>…#<Decl>'
```

Worked, using the real paths:

| Source | Path | Atom | File on disk |
|---|---|---|---|
| `src/models/user.bp` | `models/user` | `'user@models#Pessoa'` | `user@models#Pessoa.erl` |
| `src/services/user.bp` | `services/user` | `'user@services#Pessoa'` | `user@services#Pessoa.erl` |
| `libs/std/src/math.bp` | `std/math` | `'math@std'` | `math@std.erl` |
| a template evaluation | — | `'@comp__template@…#…'` | `@comp__template@….erl` |

Mechanically valid ([E3](./evidence.md#e3--e4--the-maintainers-atom-fully-quoted-works-end-to-end),
[E17](./evidence.md#e17)). Costs B1–B7 in
[`erlang-atoms.md` § 2.2](./erlang-atoms.md#22--what-breaks): it forces the output layout flat
anyway, mandates quoting at every emission site, encodes a `#Decl` that nothing can resolve,
and breaks `make`.

---

<a id="option-a--the-path-joined-with-"></a>

## Option A — the path joined with `@` (recommended)

### Rule

```
atom(path) =
    1. lowercase the path
    2. '/' → '@'
    3. every character outside [a-z0-9_@] → '_'
    4. if the first character is not [a-z], prefix "bp@"
    5. if the result has no '@' and is in RESERVED, prefix "bp@"
```

`RESERVED` is a frozen list of OTP module names shipped in the compiler (the eleven of
[E14](./evidence.md#e14--eleven-libsstd-module-names-are-already-otp-module-names) plus the rest of
`kernel`/`stdlib`). Step 5 only fires for a **single-segment** path, because any path with a
directory already carries a prefix and cannot collide with OTP.

The result is always a legal **unquoted** erlang atom
([E10](./evidence.md#e10--what-is-and-is-not-a-legal-unquoted-atom), [E12](./evidence.md#e12--joined-atoms-need-no-quoting-anywhere)),
so nothing in the emitters, the `.S` writer, the audit script or a hand-written `.erl` has to learn
quoting.

Comptime modules take the same shape, replacing today's `template_<hash>`:

```
bp@comptime@template@<16 hex>
bp@comptime@decorator@<16 hex>
```

### Worked examples

| Source | Path | Atom | `out/erl/<file>` |
|---|---|---|---|
| `src/main.bp` (single-module program) | `main` | `main` | `main.erl` |
| nested — `src/web/api/http.bp` | `web/api/http` | `web@api@http` | `web@api@http.erl` |
| same name, two paths — `src/models/user.bp` | `models/user` | `models@user` | `models@user.erl` |
| …and `src/services/user.bp` | `services/user` | `services@user` | `services@user.erl` |
| library — `libs/std/src/math.bp` | `std/math` | `std@math` | `std@math.erl` |
| library — `rakun/src/http.bp` | `rakun/http` | `rakun@http` | `rakun@http.erl` |
| every library's `root.bp` | `std/root`, `rakun/root`, … | `std@root`, `rakun@root`, … | distinct |
| a top-level `src/math.bp` (reserved) | `math` | `bp@math` | `bp@math.erl` |
| comptime template evaluation | — | `bp@comptime@template@3f1a9c02b7e4d5f8` | under `.botopinkbuild/tmp/template/` |

A call site reads `models@user:greet(P)` — unquoted, and the directory is legible in the name. A
stack trace reads `{rakun@http, handle, 2, …}`.

### The output layout it implies

[E1](./evidence.md#e1--the-module-atom-must-equal-the-source-files-basename) forces the file's
basename to be the atom, so the mirrored `out/<path>.erl` tree
(`modules/compiler-cli/src/cli/build.zig:190`) cannot stay for the erlang and beam targets. Two
sub-variants:

| | Layout | Consequence |
|---|---|---|
| **A-flat** (recommended) | `out/<atom>.erl`, `out/<atom>.S` — one directory per target | Matches OTP's own `ebin/` shape; `erl -pa out` works; `escript out/main.erl` unchanged for a single-module program; matches the snapshot harness, which is already flat (`runtime.zig:527-537`) |
| A-nested | `out/<dir>/<atom>.erl` — directories kept for grouping, filename carries the full atom | `erlc` is satisfied (it checks the basename only, E1), but the path is stored twice and `-pa` needs one entry per directory |

**Recommend A-flat for `.erl`/`.S` only.** commonJS and typescript keep `out/<path>.js` — their
require target *is* the path (`commonJS.zig:1858-1870`), so flattening them would be a regression
for no gain. See [`js-modules.md`](./js-modules.md).

### A2 — several modules from one source file

One `.bp` file can produce more than one BEAM module — the comptime evaluators already do it on
every build, under names (`template_<hash>`, `decorator_<hash>`) that say nothing about their
origin. **[`declaration-qualifier.md`](./declaration-qualifier.md)** extends this rule with an
in-file qualifier that stays unquoted and decodes back to its source:

```
atom = erlAtom(path) [ "__" kind "__" decl [ "__" hash ] ]
```

`models@user__t__pessoa`, `std@math__b__signed`,
`jhonstart@html__tpl__html__3f1a9c02b7e4d5f8`. This is what the proposal's `#Pessoa` was reaching
for, delivered as a **real loadable module** rather than as text the BEAM never reads. It costs one
extra clause in the rule (`__` becomes reserved), a collision diagnostic, and ~30 LOC of plumbing in
the comptime evaluators.

### Why `@` and not `_`

`_` is also unquoted-legal, but `web_api_http` is ambiguous: it does not say whether the source was
`web/api/http`, `web_api/http` or `web/api_http`. Step 3 maps a stray `_` in a segment to `_`
anyway, so `@` is the only character that can carry the separator unambiguously *and* stay
unquoted. `@` already reads as "qualified by" to an erlang audience (node names, compiler-generated
variables).

---

## Option B — keep the basename, disambiguate only on collision

### Rule

```
atom(path) = basename(path), unless
  (a) another module in this build has the same basename, or
  (b) basename(path) is in RESERVED,
then basename(path) ++ "_" ++ <4 hex of the full path>
```

### Worked examples

| Source | Path | Atom |
|---|---|---|
| `src/main.bp` | `main` | `main` |
| `src/web/api/http.bp` (alone) | `web/api/http` | `http` |
| `src/models/user.bp` | `models/user` | `user_3f1a` |
| `src/services/user.bp` | `services/user` | `user_9c02` |
| `libs/std/src/math.bp` | `std/math` | `math_7b21` (reserved) |
| comptime | — | unchanged, `template_<hash>` |

### Why it is not the recommendation

- **Not stable.** Adding `src/models/user.bp` to a project that already had `src/services/user.bp`
  renames the *existing* module from `user` to `user_9c02`. Every hand-written erlang that named it,
  every `escript out/…` command, every stack trace in an issue, and every recorded snapshot moves.
  The rule makes a module's public name depend on its siblings.
- **Not derivable.** Nothing outside the compiler can compute the atom from the path, so
  `runtime.zig:451`, `beam_export_audit.sh:63`, and anyone reading `out/` must be told the mapping.
- It leaves the nested case as ambiguous as today (`web/api/http` is still just `http`).

Its one real merit is churn: it touches only the colliding modules. That merit is small here — see
[`migration.md`](./migration.md), where option A's churn measures at ~20 snapshot files.

**Variant B′** (always suffix, `user_3f1a` unconditionally) buys stability back and loses
readability entirely; it is strictly worse than A.

---

## Option C — the proposal minus `#`, dotted and quoted

```
atom(path) = '<seg1>.<seg2>.…'      e.g. 'std.math', 'models.user'
```

Legal ([E3](./evidence.md#e3--e4--the-maintainers-atom-fully-quoted-works-end-to-end) proves the
dotted quoted form compiles, loads and calls). Readable. Keeps the maintainer's intent for the path
half and drops only the part that has no meaning.

Its whole cost is [B2](./erlang-atoms.md#22--what-breaks): the quotes are mandatory at every
emission site — `beam/erl_emitter.zig:652`, every `call_ext` target in `beam_asm.zig`, every
`Mod:Fun` in `erlang.zig`, `beam_export_audit.sh`, and any hand-written erlang a library ever ships.
The `.` also makes the name un-greppable next to the record and float syntax.

Prior art, **unverified in this environment** (no `elixir` on `PATH`): Elixir compiles module
`MyApp.User` to the atom `:"Elixir.MyApp.User"` and the file `Elixir.MyApp.User.beam` in a flat
`ebin/`. If that is right, option C is the industrial-strength version of the maintainer's proposal
and option P is option C plus a `#` suffix. Worth confirming before deciding — it is the only
argument that would move the recommendation from A to C.

---

## Comparison

| | **P** (proposal) | **A** `@`-joined | **B** suffix-on-collision | **C** dotted+quoted |
|---|---|---|---|---|
| Same basename, different path | resolved | resolved | resolved | resolved |
| OTP module shadowing (11 today) | resolved | resolved | resolved via `RESERVED` | resolved |
| Legal **unquoted** atom | no (E2, E9, E10) | **yes** (E12) | yes | no |
| Emitters need a quoting rule | yes, everywhere | **no** | no | yes, everywhere |
| Safe in `make` / config formats | **no** (E11) | yes | yes | yes |
| Atom derivable from the path alone | yes | **yes** | no | yes |
| Path recoverable from the atom | yes | yes | no | yes |
| Stable when a sibling module is added | yes | **yes** | **no** | yes |
| Names a declaration inside the module | claimed, **does not work** (E8) | **yes, via A2** — a real loadable module (E19) | not attempted | not attempted |
| Forces a flat `out/` for erl/beam | yes | yes | no | yes |
| Comptime naming unified with program naming | yes | **yes** | no | yes |
| Snapshot churn (erlang + beam) | ~620 files | **~20 files** | ~20 files | ~620 files |
| Length budget (250 B cap, E7) | tightest | comfortable | comfortable | comfortable |

The churn rows differ because 303 of the 313 erlang snapshots and 302 of the 312 beam snapshots
record `-module(main).` / `{module, main}` — a single-segment path, which options A and B leave
untouched. P and C rewrite every one of them (`'main'`, `'main#…'`). See
[`migration.md`](./migration.md).

---

## Recommendation

**Option A + A2, flat `out/erl/` and `out/beam/`, with the comptime modules renamed into the same
shape.** It answers everything the proposal was aimed at — same-basename collisions, and (the
larger prize the proposal reaches by accident) the eleven `libs/std` modules that currently shadow
OTP — while staying an unquoted atom, so no emitter, script or future hand-written `.erl` needs a
quoting rule it can get wrong silently.

Drop the `#<Decl>` spelling, keep its intent: [A2](./declaration-qualifier.md) gives every module
born of the same file its own qualified atom (`models@user__t__pessoa`), which `#` could not — in
the atom `#Pessoa` would be text the BEAM never reads ([E8](./evidence.md#e8---cannot-address-anything-inside-a-module)).

**What it costs** ([`migration.md`](./migration.md) has the breakdown): one new function in
`crossModule.zig` and four call sites moved to it; a per-target output-name function in
`build.zig`; `run.zig`'s entry path; the comptime evaluators rewired to `erlDeclAtom`; ~20 snapshot files
re-recorded; **zero `.bp` changes in `libs/std` or in any sibling library**, because the atom is
derived from the path the compiler already owns and no library writes it down. Estimated 2–4 days
including the gate.

**What it does not fix, and must be said in the front's Notes:** `CrossModule.exports` is keyed by
the bare exported symbol name (`crossModule.zig:112-135`), so two libraries exporting `pub fn get`
still overwrite one another regardless of module naming
([B6](./erlang-atoms.md#22--what-breaks)). That is a separate front.
