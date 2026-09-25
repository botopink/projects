# Policy 3 — one BEAM module per `type` and per `behavior`

**Decided by the maintainer, 2026-09-17.** Not an option, not "slice when it collides": **every**
`type` and `behavior` declaration gets its own BEAM module, named by the
[A2](./declaration-qualifier.md) rule — `<pathAtom>__t__<decl>`, `__b__<decl>`, `__im__<decl>`.

This document works the consequences. Every number below was measured or run; the commands are
given so each can be repeated. Line numbers at `botopink-lang` `dfc34a9`.

**Bottom line up front:** the policy is mechanically sound on both backends and buys four real
things (§ 6). It costs **188 snapshots changing shape** (§ 4, against ≈ 20 for A2 alone), it
rewrites the behavior dispatch path (§ 2), and it **breaks `botopink run --target erlang` for every
program that declares a type with a method** (§ 7, E25). § 9 recommends cutting it out of this front
into its own front for exactly those reasons — a recommendation the maintainer overruled (§ 9).

---

## 1. What comes out of each module

### 1.1 Today: one `.erl` per `.bp`, everything flat inside it

`recordForms` (`src/codegen/erlang.zig:5300-5327`) emits a type's instance methods as **flat
top-level functions** taking the receiver first, mangling the name when two types in the file
declare the same method:

```zig
// A method whose name collides with another record's
// method is mangled to `<recordtype>_<method>` so erlang's flat
// top-level fn namespace doesn't double-define it.
const mname: []const u8 = if (this.isRecordMethodCollision(r.name, m.name))
    try recordMethodAtom(&mname_buf, r.name, m.name)
else
    m.name;
```

`recordMethodAtom` (`:1841-1844`) renders `<lowercased type>_<method>`; the collision set is
`record_method_collisions` (`:1743`, filled at `:1834`).

`enumForms` (`:5329-5351`) emits an enum's methods **unmangled** — no collision set at all.

`interfaceForms` (`:5353-5384`) emits a behavior's **associated** `default fn` (no `self`) under
`interfaceAssocAtom` (`:1408-1411`), the same `<lowercased behavior>_<method>` shape. An **instance**
`default fn` (with `self`) is explicitly **not emitted here** (`:5375-5377`) — it is inlined into
each consuming module by the dispatch machinery.

`implementForms` / `extendForms` (`:5386-5424`) send their methods through `extensionForms`, which
emits `m.name` **with no mangling whatsoever** — a real collision source today.

> **Correction to a code comment.** `erlang.zig:5359` says the associated fn is mangled
> "`Interface_method` (→ quoted `'Array_range'`)". It is not quoted: `interfaceAssocAtom:1410` calls
> `std.ascii.toLower(iface[0])`, so the emitted atom is `array_range`, bare. Confirmed against the
> snapshots — `grep -rhoE "^'[A-Za-z_]+'\(" snapshots/codegen/erlang` returns only compiler
> builtins (`'_botopink_main'`, `'__bp_add'`, `'__bp_print'`, `'__bp_run_one'`,
> `'__bp_run_tests'`), never a behavior name. The comment should be fixed in the same commit.

### 1.2 After: what moves where

| Declaration part | Today | Under policy 3 |
|---|---|---|
| a `type`'s constructor | a flat `fn` in the file's module (record literal → `#{…}` inline) | **the type's module**, `<path>__t__<decl>:new/N` |
| a `type`'s instance methods | flat `m(Recv, …)`, mangled on collision | **the type's module**, `m(Recv, …)`, **never mangled** |
| an `enum`'s methods | flat, unmangled, collision-prone | **the type's module** |
| a `behavior`'s associated `default fn` | flat `<behavior>_<method>` in **every consuming module** | **the behavior's module**, `<path>__b__<decl>:<method>/N`, emitted **once** |
| a `behavior`'s instance `default fn` | not emitted; inlined per consumer | **the behavior's module** (§ 2.2) |
| an `implement` block's methods | flat `m(Recv, …)`, unmangled | **`<path>__im__<decl>`** |
| top-level `fn`/`val`, `main`, tests | the file's module | **unchanged** — the file's module stays |

**Both manglings disappear**, as expected. Each becomes the module boundary instead of a name
prefix: `pessoa_greet/1` in module `main` becomes `greet/1` in module `models@user__t__pessoa`, and
`array_range/2` in every consumer becomes `range/2` in module `std@array__b__array`, emitted once.
`record_method_collisions` (`erlang.zig:1743`, `:1834`, `:1848-1852`), `recordMethodAtom`
(`:1841`) and `interfaceAssocAtom` (`:1408`) can all be deleted.

Measured inventory of what goes away — 25 distinct mangled names across the erlang snapshots:

```
$ grep -rhoE "^[a-z][A-Za-z0-9]+_[a-zA-Z][A-Za-z0-9]*\(" snapshots/codegen/erlang | sort -u | wc -l
25
$ … | sed 's/_.*//' | sort | uniq -c | sort -rn
6 pair   5 array   4 function   3 bool   2 pairish   1 string   1 number   1 integer   1 get   1 extract
```

(An upper bound: the pattern also catches a user `fn` that legitimately contains `_`. The `pair`,
`array`, `function`, `bool` groups are `libs/std` behaviors and are certainly mangles.)

## 2. The shape of a call

### 2.1 An instance method

```erlang
%% today — out/erl/main.erl
-module(main).
pessoa_greet(P) -> "hello " ++ maps:get(nome, P).
empresa_greet(E) -> "hi " ++ maps:get(razao, E).
_botopink_main() -> io:format("~s~n", [pessoa_greet(#{nome => "ana"})]).
```

```erlang
%% after — out/erl/models@user__t__pessoa.erl
-module('models@user__t__pessoa').
-export([greet/1]).
greet(P) -> "hello " ++ maps:get(nome, P).

%% out/erl/models@user__t__empresa.erl
-module('models@user__t__empresa').
-export([greet/1]).
greet(E) -> "hi " ++ maps:get(razao, E).

%% out/erl/main.erl
-module(main).
_botopink_main() ->
    io:format("~s~n", ['models@user__t__pessoa':greet(#{nome => "ana"})]).
```

Note `greet/1` twice, in two modules, with no mangling — the collision that forced
`recordMethodAtom` cannot be expressed any more.

The atoms need quotes here only because these examples carry `__` after a `@`-joined path; option A
renders them unquoted whenever the path is a plain identifier chain. Both spellings are legal
unquoted per [E18](./atom-evidence.md#e18--the-in-file-separator-candidates) —
`models@user__t__pessoa` scans as one atom. The quotes above are belt-and-braces in hand-written
evidence files, not a requirement.

### 2.2 Behavior dispatch

Three paths change, and they are the part of this policy that is **not** a rename:

| Path | Today | Under policy 3 |
|---|---|---|
| associated `default fn` (`Array.range(1,9)`) | `interfaceForms` emits `array_range/2` **into every module that consumes the behavior** — the behavior decl is inlined per consumer (`erlang.zig:5355-5358`) | emitted **once**, in `std@array__b__array`; every consumer does `std@array__b__array:range(1,9)` |
| instance `default fn` (`x.abs()` falling back to the behavior's body) | not emitted by `interfaceForms` at all (`:5375-5377`); the dispatch machinery inlines the body at each call site | emitted once in the behavior's module, taking the receiver first; the call site becomes a `call_ext` |
| `implement` / `extend` (`extensionForms`, `:5416-5424`) | flat `m(Recv, …)`, unmangled, in the file's module | `<path>__im__<decl>:m(Recv, …)` |

The `extends` chain is unaffected in *meaning* — it is resolved at compile time by the checker, and
policy 3 only changes where the resolved function is emitted. But the **inlining stops**, and that
is the behavioural change to test: today a behavior consumed by five modules has five copies of its
associated fn; after, it has one, reached remotely. That is a correctness improvement (one
definition) and a linkage risk (the consumer now depends on a module that must be on the code path
— § 7).

## 3. The cross-module index

`crossModule.build` (`crossModule.zig:86`) indexes `pub` symbols by their **bare name** into one
flat map (`:112-135`), and `ownerModuleAtom` (`:74-77`) answers the owning module.

What it must learn:

1. **A type's methods need an owner of their own.** `ExportInfo.methods` already records a type's
   method names (`crossModule.zig` `ExportInfo.methods`, "A consumer calling one on an imported
   value (`stub.thenReturn(v)`) emits no local definition of it: erlang resolves the owning module
   from here"). Today that resolves to the *file's* module; it must resolve to
   `erlDeclAtom(info.module, .t, type_name)`. That is a one-line change at the consumption site,
   because the information is already indexed — **the index does not need a new key**.
2. **A behavior's associated fns become exports.** They are not in `exports` today (they are
   inlined, not imported). They must be, or a consumer cannot link to the single copy.
3. **`is_external` and `is_class` keep their meaning**, but `is_class` (construction needs the
   owner's map shape) now points at the type's module rather than the file's.

**Does the bare-name key get worse?** No — and it does not get better either. The key is the
exported *symbol* name; policy 3 changes the *value* (`module`), not the key. Two libraries
exporting `pub type User` collide in that map exactly as they do today
([B6](./erlang-atoms.md#22-what-breaks)). The one thing that improves: a **method** name no longer
has to be globally unique per file, because the module boundary separates them — so the pressure on
the flat namespace drops even though the map's shape is unchanged.

## 4. Snapshot cost — measured

The marker is the doc comment `recordForms`/`enumForms`/`interfaceForms`/`implementForms` emit
(`%% type …`, `%% behavior …`, `%% implement …`), which is exactly the set of snapshots whose
emitted **shape** changes, not just a name:

```
$ cd modules/compiler-core/snapshots/codegen
$ grep -rl '^%% type '      erlang | wc -l      #  77
$ grep -rl '^%% behavior '  erlang | wc -l      #  25
$ grep -rl '^%% implement ' erlang | wc -l      #   5
$ grep -rl '^%% \(type\|behavior\|implement\) ' erlang | wc -l   #  94  (union)
$ find erlang -name '*.snap.md' | wc -l         # 313
```

Every one of the 94 has a beam twin, confirmed by intersecting the file names:

```
$ grep -rl '^%% \(type\|behavior\|implement\) ' erlang | sed 's|^erlang/||' | sort > /tmp/e94
$ find beam -name '*.snap.md' | sed 's|^beam/||' | sort > /tmp/ball
$ comm -12 /tmp/e94 /tmp/ball | wc -l           #  94
```

| | Files |
|---|---|
| erlang snapshots changing **shape** | **94** of 313 (30%) |
| beam snapshots changing **shape** | **94** of 312 (30%) |
| **total under policy 3** | **188** |
| total under A2 alone (name only) | ≈ 20 |

**Policy 3 is 9× the A2 churn**, and the difference is qualitative: A2's 20 files change an atom on
one line; these 188 change *how many modules the fixture emits*, so each snapshot gains whole
`----- ERLANG -- <file>.erl` sections. Every one has to be executed and classified, not
bulk-accepted ([the rule 1.0.4-beta ran under](../../../1.0.4-beta/overview.md)).

commonJS (313) and wasm (312) are **unaffected** — the policy is a BEAM module-boundary decision and
neither JS nor wasm has a module atom ([`js-modules.md`](./js-modules.md)).

## 5. Runtime cost — measured

Every instance method call becomes a `call_ext` instead of a local `call`. Micro-benchmark: the same
one-line body, 10 000 000 calls, best of 5 `timer:tc` runs after warm-up
([E26](./atom-evidence.md#e26--local-call-vs-remote-call)).

```
N            = 10000000 calls
local  call  = 22234 us  (2.223 ns/call)
remote call  = 25953 us  (2.595 ns/call)
overhead     = 3719 us total, 0.372 ns/call, 16.7%
```

Machine: Linux 7.2.4-arch1-2, Erlang/OTP 29 (`erts-17.0.6`).

**Read it in absolute terms, not relative.** 16.7% sounds large because the body is a single `+`,
which makes the call itself nearly the whole cost — this is the *upper bound* of the relative
overhead. In absolute terms it is **0.37 nanoseconds per call**: ten million method calls cost
3.7 ms more. No program this compiler generates today does ten million method calls; the erlang
fixtures do tens to hundreds. The cost is irrelevant at the scale of the generated programs, and
saying so with the number is the honest statement.

## 6. What is gained — each verified

| Gain | Evidence |
|---|---|
| **A stack trace names the owner.** Today the type's name is fused into the function name and the module is the file; after, the module *is* the type and the function keeps the name the programmer wrote | [E24](./atom-evidence.md#e24--a-stack-trace-names-the-owning-type): `{main, pessoa_greet, [notamap], …}` → `{models@user__t__pessoa3, greet, [notamap], [{file,…},{line,3}]}` |
| **Hot-swap per type.** One type can be recompiled and reloaded on its own, leaving its siblings — and the file's own module — untouched | [E23](./atom-evidence.md#e23--hot-swapping-one-type-module): `code:load_file(models@user__t__pessoa)` → `{module,…}`, the caller's tuple goes `{file_module,pessoa_v1,greeter_v1}` → `{file_module,pessoa_v2_HOTSWAPPED,greeter_v1}` |
| **The mangling ends.** `recordMethodAtom`, `interfaceAssocAtom` and `record_method_collisions` are deleted; 25 mangled names in the snapshots become plain method names | § 1.2 |
| **Method collision between types stops existing.** Two types can each declare `greet/1`; the module boundary separates them, so there is no collision set to maintain and no name for the checker to reject | § 2.1 |
| **A behavior's associated fn is emitted once**, not copied into every consumer | § 2.2 |

## 7. Layout and CLI

N files per `.bp` in one flat directory per target — E1 leaves no choice
([`options.md` A-flat](./atom-options.md#the-output-layout-it-implies)):

```
src/models/user.bp   →   out/erl/models@user.erl
                         out/erl/models@user__t__pessoa.erl
                         out/erl/models@user__t__empresa.erl
                         out/erl/models@user__b__greeter.erl
```

`modules/compiler-cli/src/cli/build.zig:184-208` writes **one artifact per `ModuleOutput`** today.
Policy 3 means one `ModuleOutput` must yield **several files**, so `writeOutputs` and
`removeStaleArtifacts` (`:157-166`) both need a list of emitted units rather than a single
`o.name` + ext. That is a signature change through `codegenEmit`, not a formatting tweak.

**The blocker.** `cli/run.zig:66-71` runs the erlang target as `escript out/<mod>.erl` with **no
`-pa`**. escript compiles only the file it is handed, so the moment a program's type has a method,
`botopink run --target erlang` fails ([E25](./atom-evidence.md#e25--botopink-run-breaks-under-policy-3)):

```
$ escript main.erl
escript: exception error: undefined function models@user__t__pessoa:greet/1
```

This was recorded as an unowned item in [`README.md`](./README.md) step 6 ("a cross-module erlang
program is not runnable from the CLI"). **Under policy 3 it stops being a residual and becomes a
blocker**, because policy 3 makes *every* type-bearing program a cross-module program. `run.zig`
must compile the directory and run `erl -pa <dir> -s <entry> _botopink_main -s init stop` — which is
what `runtime.zig:581` already does for snapshots and can be lifted from there.

## 8. The BEAM `.S` backend

The same policy, confirmed end to end. Four sibling `.S` modules standing for one source file
assemble, load, and `call_ext` into each other
([E22](./atom-evidence.md#e22--four-sibling-s-modules-from-one-source-file)):

```
$ erlc +from_asm 'models@user.S' 'models@user__t__pessoa.S' 'models@user__t__empresa.S' 'models@user__b__greeter.S'
erlc +from_asm exit=0
$ erl -pa . -eval 'io:format("~p~n",[caller3:go()])'
{file_module,pessoa_v1,greeter_v1}
```

and one of them hot-swaps alone ([E23](./atom-evidence.md#e23--hot-swapping-one-type-module)). `beam_asm.zig`
needs the same "one output per declaration" restructuring as `erlang.zig`, and
`scripts/beam_export_audit.sh:63-80` — which already splits a snapshot into `<n>/<module>.S` per
recorded module atom — handles N modules per fixture without change, because it keys on the
`{module, …}` form, not on the fixture.

Watch the quirk from [E17](./atom-evidence.md#e17): `erlc +from_asm` prints a name/file mismatch but
**exits 0**. With N files per source the chance of a mismatch rises, so the audit must assert on the
output text, not the exit code.

## 9. Sequencing — **decided 2026-09-17: one front, not two**

**The maintainer decided that policy 3 runs inside this front** ("16 e 16b fazer junto" — said when
the front was numbered 16, in 1.0.4-beta; it is **13** in 1.0.5-beta). The steps
below are this front's steps 7–13, the estimate is **≈ 9 days**, and the snapshot rule below is the
constraint the front has to meet rather than an argument for splitting: **the atom rename lands
first and alone** (steps 1–6, ≈ 20 snapshots, names only), and the emitter split lands after it
(188 snapshots, shapes). One commit never carries both reasons, so every re-recorded snapshot is
still classifiable — which is what the split was protecting. The rest of this section is the
analysis that led there, kept because it is what the ordering rests on.

This front as written is a **naming** front: it renames atoms, moves where files are written, and
re-records ≈ 20 snapshots, with no change to what any module contains. Policy 3 is a **code
generation** change: it changes what each module contains, rewrites the behavior dispatch path
(§ 2.2), changes the `codegenEmit` signature (§ 7), and re-records 188 snapshots that each gain
sections.

Landing them together would make every one of those 188 diffs carry two reasons at once — an atom
rename and a re-shaping — and [the rule 1.0.4-beta ran
under](../../../1.0.4-beta/overview.md) is that a re-recorded snapshot is
classified, not bulk-accepted. With both changes in one commit, classification is not possible.

**The two halves, as one front:**

| Half | Scope | Cost |
|---|---|---|
| **steps 1–6** (the atom) | option A + A2: the atom, the flat per-target output, the collision diagnostic, the comptime rename. Snapshots change **names only** | ≈ 3.5 days, ≈ 20 snapshots |
| **steps 7–13** (the split) | policy 3: the emitter split, behavior dispatch, `codegenEmit`/`build.zig` multi-artifact, `run.zig` `-pa`, mangling deleted | ≈ **5–7 days**, 188 snapshots |

The second half uses `erlDeclAtom` from the first, so the order inside the front is fixed. Because
the front owns `erlang.zig` and `beam_asm.zig` **wholesale** for the second half — not as the
module-atom carve-out the first half needs — it runs after
[`../02-erlang/`](../02-erlang/README.md) and [`../03-beam/`](../03-beam/README.md) have closed, and
neither front's rows may be open when it starts. (In 1.0.4-beta this read "after 01 has closed"; 01's
erlang and beam halves are now 02 and 03.)

### Steps of the second half

1. **`run.zig` first** — `erl -pa` instead of `escript`, lifted from `runtime.zig:581`. It is the
   blocker (§ 7) and it is testable before anything else moves.
   *Acceptance:* an existing multi-module erlang example runs through `botopink run` (today none can).
2. **`codegenEmit` yields N artifacts per module**; `build.zig:184-208` and `:157-166` write and
   clean a list.
   *Acceptance:* a fixture emitting two files per `.bp` on erlang, byte-identical commonJS output.
3. **`recordForms` / `enumForms` split** into per-type modules; delete `recordMethodAtom`,
   `record_method_collisions`, `isRecordMethodCollision`.
   *Acceptance:* two types declaring `greet/1` in one file compile and both run; the 25 mangled
   names are gone from the snapshots.
4. **`interfaceForms` / `implementForms` / `extensionForms` split**; the associated `default fn` is
   emitted once and imported; delete `interfaceAssocAtom` **and fix the stale comment at `:5359`**.
   *Acceptance:* a behavior consumed by three modules has exactly one emitted copy; `libs/std` green
   on erlang and beam.
5. **`crossModule` consumption sites** resolve a method to the type's module (§ 3).
   *Acceptance:* an imported type's method called from another module links to
   `<path>__t__<decl>`, executed.
6. **`beam_asm.zig`** the same, § 8.
   *Acceptance:* `beam_export_audit.sh` green at its new total.
7. **Re-record the 188**, classified: which gained a module, which changed a call from local to
   `call_ext`, which changed a `RUN LOG` (none should).
