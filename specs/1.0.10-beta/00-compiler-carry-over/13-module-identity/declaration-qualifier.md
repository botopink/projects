# A2 — naming every module a package produces

The maintainer accepted [option A](./atom-options.md#option-a--the-path-joined-with-) and asked for the
half the `#Pessoa` suffix was reaching for: **when one `.bp` file produces more than one BEAM
module, the atoms must say which declaration each one came from.** He then asked that every atom
start with the package it belongs to. This file is the rule, as
[decision 109](../../decisions-taken.md#109-a-module-atom-starts-with-its-package-and-the-declaration-boundary-is-)
spells it.

---

## 1. Who produces a module

| Producer | Atom | Where |
|---|---|---|
| a source file | `<package>@<path>` — `myapp@main`, `std@math` | `crossModule.erlAtom`, the `-module` of every erlang and BEAM file |
| a `type` (policy 3, half 2) | `<package>@<path>@@<Type>` — `myapp@main@@SourceLocation` | `crossModule.declAtom` / `typeAtom`, emitted by `erlang.zig` and `beam_asm.zig` as `GenerateResult.units` |
| an `implement` bound to a `val` | `<package>@<path>@@<val>` — `pond_pkg@pond@@PatoNada` | the name rule only: an `implement` block emits no module today, its methods stay in the file's module |
| a `behavior` | none | decision 23 — a behavior has no run-time representation; were it reopened, `<package>@<path>@@<Behavior>` |
| a template body evaluated at compile time | `bp@comptime__tpl__<template>__<16 hex>` | `comptime/template_eval.zig` |
| a decorator body evaluated at compile time | `bp@comptime__dec__<decorator>__<16 hex>` | `comptime/decorator_eval.zig` |

An inline clause, `type Pato(…) implement Swimmer { … }`, is part of the type's declaration: its
methods are `pond_pkg@pond@@Pato`'s.

The comptime atoms keep the `__<kind>__` qualifier and live in the compiler's own package, `bp`.
Their path half, `comptime`, is a placeholder for the owning module, which does not reach the
evaluator (step 5, § 7).

## 2. The rule

```
atom(module)  = sanitise(package) ++ "@" ++ sanitise(path)             option A + decision 109
atom(decl)    = atom(module) ++ "@@" ++ <Decl>                          decision 109
atom(variant) = atom(decl) ++ "__v__" ++ lower(variant)                  half 3, the value tag
atom(gen)     = atom(module) ++ "__" ++ kind ++ "__" ++ decl ++ "__" ++ hash

sanitise: lowercase, '/' → '@', [^a-z0-9_@] → '_', a run of '_' collapsed to one
```

- `package` — the `name` of the `botopink.json` the module was loaded under. A dependency's module
  path is already `<dep>/<stem>` (that is how `from "<dep>"` resolves), so the package is not written
  twice: `std/math` is `std@math`. The embedded `std` is a dependency of every compilation.
  Without a `botopink.json` there is no package, and an erlang or beam compilation is refused
  (§ 6); the compiler's own tests compile under an implicit manifest named `test`.
- `"@@"` — `crossModule.DECL_SEP`, the **declaration boundary** (§ 4).
- `<Decl>` — the declaration's own name **with its case kept**; only a character outside
  `[A-Za-z0-9_]` folds to `_`. A `type`'s name, or the `val` an `implement` is bound to.
- `__v__<variant>` — a variant is a value tag, not a module: it qualifies the enum's atom, the
  variant lowercased and its `_` runs collapsed, so it never holds `__`.
- `kind` — `tpl` or `dec` (`crossModule.Kind`), never a free string. `hash` — 16 hex, the Wyhash
  of the generated body, so an identical body is the identical module and re-loading it is a no-op.

Every form is a legal **unquoted** atom: it starts with the package's lowercase letter and holds
only `[a-zA-Z0-9_@]` ([E10](./atom-evidence.md#e10--what-is-and-is-not-a-legal-unquoted-atom)).
A package whose `name` does not start with a lowercase letter is refused, never quoted (§ 6). The
module half stays lowercase because it is also a file name; the declaration half keeps its case
because that is what makes the atom decode back to its source.

## 3. Worked examples

| Package | Source | What it is | Atom |
|---|---|---|---|
| `myapp` | `src/main.bp` | the file's own module | `myapp@main` |
| `myapp` | `src/main.bp` | `type SourceLocation` | `myapp@main@@SourceLocation` |
| `myapp` | `src/models/user.bp` | `type Pessoa` | `myapp@models@user@@Pessoa` |
| `myapp` | `src/services/user.bp` | `type Pessoa` (same name, other file) | `myapp@services@user@@Pessoa` |
| `std` | `src/math.bp` | the file's own module (`pub val PI` lives in it) | `std@math` |
| `std` | `src/io/fs.bp` | `type File` | `std@io@fs@@File` |
| `std` | `src/dict.bp` | `type Dict` | `std@dict@@Dict` |
| `pond_pkg` | `src/pond.bp` | `val PatoNada = implement Swimmer for Pato { … }` | `pond_pkg@pond@@PatoNada` |
| `pond_pkg` | `src/pond.bp` | `type Pato(…) implement Swimmer { … }` | `pond_pkg@pond@@Pato` |
| `myapp` | `src/main.bp` | `Shape.Circle`, the value tag | `myapp@main@@Shape__v__circle` |
| `acme-web` | `src/main.bp` | the file's own module | `acme_web@main` |
| `test` (implicit) | `main` in a compiler test | the file's own module | `test@main` |
| — | the `html` template, one evaluation | comptime | `bp@comptime__tpl__html__3f1a9c02b7e4d5f8` |

The file is the atom (decision 6's flat `out/erl/` and `out/beam/`): `out/erl/std@io@fs@@File.erl`,
`out/beam/myapp@main@@SourceLocation.S`. The type's atom is also the tag inside every value it
builds (decision 21, T2): `{'std@io@fs@@File', …}` on erlang — the quotes are the emitter's habit,
not a need — and `{myapp@main@@Shape__v__circle, 5}` for a variant. A host template that builds such
a value spells the same atom (`{'std@regex@@Match', …}` in `libs/std/src/regex.bp`). commonJS and
wasm carry no atom: a commonJS value's identity is its class prototype (decision 5), a wasm value's
is its descriptor's address (decision 22), so there is no second spelling to keep in step, and their
artifact paths stay the module path.

Sibling modules of one file compile, load and answer independently
([E19](./atom-evidence.md#e19--four-sibling-modules-from-one-source-file),
[E22](./atom-evidence.md#e22--four-sibling-s-modules-from-one-source-file)); `botopink run --target
erlang` in a package `pond` whose `main.bp` declares `type Pato(…) implement Swimmer`,
`type SourceLocation` and `type Duck` writes `pond@main.erl`, `pond@main@@Pato.erl`,
`pond@main@@SourceLocation.erl` and `pond@main@@Duck.erl`, and runs `pond@main:main([])` with
`erl -pa`.

## 4. Why the package, and why `@@`

1. **The package keeps libraries apart and every module off OTP's namespace.** Two libraries' `main`,
   `http` or `root` are two atoms, and every atom holds an `@`, which no OTP module name does. Option
   A's `RESERVED` list and its `bp@` prefix for a single-segment `math` have nothing left to do and
   are deleted.
2. **`@@` cannot collide.** A path segment is never empty, so `@@` never occurs in a module atom; and
   the sanitiser maps every foreign character to `_`, so no source name produces `@`. The decoder
   needs no qualifier table.
3. **The declaration keeps its case.** A lowercased declaration (`main__t__sourcelocation`, the
   spelling decision 109 replaced) stops decoding back to its source.
4. **One rule for every declaration kind.** A `type`, an `implement` and — if decision 23 is ever
   reopened — a `behavior` are all `<package>@<path>@@<Decl>`. Should the language ever nest a
   declaration inside another, each `@@` descends one level; no construct does today, and the
   decoder refuses a second boundary.

`__` stays reserved for the comptime qualifier, which is why a run of `_` collapses:
`my__mod/user` and `my_mod/user` both render `<package>@my_mod@user`
([E21](./atom-evidence.md#e21--__-has-to-be-reserved)), and `crossModule.build` refuses the pair.
OTP's own `escript` uses `__` the same way
([E20](./atom-evidence.md#e20--otps-own-escript-uses-__-the-same-way)).

## 5. It decodes back

`crossModule.decodeAtom` recovers the origin — `split("@@")` for a declaration, the last `__v__` of
the declaration half for a variant, the `__` qualifier for a comptime module, and the module half's
first `@` for the package:

```
myapp@models@user                         {module,  package "myapp", "models/user"}
std@io@fs@@File                           {decl,    package "std",   "io/fs", "File"}
pond_pkg@pond@@PatoNada                   {decl,    package "pond_pkg", "pond", "PatoNada"}
myapp@app@models@@Shape__v__circle        {variant, package "myapp", "app/models", "Shape", "circle"}
bp@comptime__tpl__panel__3f1a9c02b7e4d5f8 {gen,     package "bp", "comptime", "tpl", "panel", "3f1a…"}
```

An atom with no `@` (`main`), `a@b@@B@@C`, `@@B` and `a@b@@` are refused (`error.UndecodableAtom`).
The round trip is a unit test in `crossModule.zig` ("decodeAtom: every shape round-trips to its
origin").

This is what the maintainer's `#Pessoa` was aiming at, and more than `#` could deliver: `#`
produced text the BEAM never reads ([E8](./atom-evidence.md#e8---cannot-address-anything-inside-a-module)),
while `@@` names a **real module** that can be loaded, called and hot-swapped on its own
([E23](./atom-evidence.md#e23--hot-swapping-one-type-module-siblings-untouched)).

## 6. What the compiler refuses

A module of no package — compiled without a `botopink.json` — renders no atom
(`MissingPackage`), and `build` turns that into the `no_package` fault: an erlang or beam
compilation without a manifest is refused, with no fallback name. `manifest` refuses a `name` that
does not start with a lowercase letter
(`"name" must start with a lowercase letter — every erlang module atom of the package starts with
it`) and the name `bp`, located at the key, for every tool; `botopink new` refuses the same names
before it scaffolds. `crossModule.build` then renders every atom once and turns each collision into
a located diagnostic (`AtomFault`, raised by the erlang and beam `codegenEmit`s; the module fails as
a whole):

| Reason | When |
|---|---|
| `duplicate` | two module paths render one atom (`my__mod/user`, `my_mod/user`) |
| `no_package` | the module belongs to no package — compiled without a `botopink.json` |
| `invalid_package` | the package cannot start an atom — for a driver that did not read a manifest |
| `too_long` | a module or declaration atom over 250 bytes, the `<atom>.bea#` filename cap ([E7](./atom-evidence.md#e7--the-real-length-cap-is-the-filename-not-the-atom)) |
| `duplicate_decl` | two types of one module whose atoms are equal **ignoring case** |

`duplicate_decl` is case-insensitive on purpose (decision 67): `Person` and `person` are two atoms,
`myapp@main@@Person` and `myapp@main@@person`, but one `.erl` on a case-insensitive file system, so
the pair is refused and the message names both atoms. `Foo-Bar` and `Foo_Bar` fold to one atom,
and the message says so. `FooBar` and `Foo_Bar` are two atoms no file system folds together, and
build.

## 7. Where it lives

| Step | What |
|---|---|
| 1 | `crossModule.zig`: `ModuleId{path, package, package_in_path}`, `Packages{root, deps}.idOf`, `erlAtom`, `declAtom`, `typeAtom`, `variantAtom`, `erlDeclAtom` (comptime only), `decodeAtom`, `DECL_SEP`, `QUALIFIER_SEP`, `COMPILER_PACKAGE`, `TEST_PACKAGE` / `test_packages`, `EMBEDDED_PACKAGE`, `Kind { tpl, dec }`, and the collision check in `build` / `buildIn`. `Config.packages` carries the packages into the erlang and beam `codegenEmit`s; `cli/libs.zig`'s `packagesOf` fills it from `botopink.json` for `build` and `test`, and `run` renders the entry's atom from it |
| 5 | the comptime evaluators render `erlDeclAtom(comptime_owner, .tpl \| .dec, name, hash)`. `comptime_owner` is `comptime` of package `bp` because neither evaluator is handed the owning module's path: the template registry in `comptime.zig` is a `StringHashMap(ast.FnDecl)` and a `Loc` has no file. Threading the path onto `env.TemplateEvalCtx` is `env.zig` and `comptime.zig`, front 01's files |
| 8–13 | `erlang.zig` / `beam_asm.zig` open one unit per `type` under `typeAtom`; `cli/build.zig` writes each flat and `removeStaleUnits` deletes a failed module's by the `<module atom>@@` prefix |
| 14–16 | the same `typeAtom` / `variantAtom` is the tag inside the value |
