# Blast radius — measured

Everything below was counted at `botopink-lang` `26d4fdc`, 2026-09-18, from
`modules/compiler-core/snapshots/codegen/`. Every count is a command you can re-run.

**The headline correction.** [`README.md`](./README.md) § 2.4 records "**every** record `RUN LOG` and
construct line moves" as "the largest item". The construct-line half is right. The `RUN LOG` half is
**zero**: across all 1 254 snapshots and 997 non-empty `RUN LOG` lines, **not one prints a record, a
tagged tuple, a unit variant atom, a JS class instance or a `tag:` object** (§ 3). The largest item
is 130 emitted-code diffs, all of them one or two lines each, all of them mechanical.

---

## 1. Snapshots whose emitted code changes

```console
$ cd modules/compiler-core/snapshots/codegen

# erlang — a record-shaped type decl and a map construct
$ grep -rlE '^%% type [A-Za-z0-9_]+: ' erlang | xargs grep -l '#{' | wc -l
48
# erlang — an enum-shaped type decl and a PascalCase atom in the output
$ grep -rlE '^%% type [A-Za-z0-9_]+$' erlang | xargs grep -lE "'[A-Z][A-Za-z0-9_]*'" | wc -l
15
# erlang — the union
62

# beam — the source declares a type, and the .S builds a map
$ grep -rl 'put_map_assoc' beam | xargs grep -lE '^\s*(pub )?(type|val [A-Za-z0-9_]+ = type)\b' | wc -l
39
# beam — the source declares a type, and the .S carries a PascalCase atom
$ grep -rlE "\{atom, '[A-Z]" beam | xargs grep -lE '^\s*(pub )?(type|val [A-Za-z0-9_]+ = type)\b' | wc -l
42
# beam — the union
68

# commonJS — a unit variant emitted as a bare string (only if step 19 is taken)
$ grep -rlE '^ +([A-Z][A-Za-z0-9_]*): "\1",?$' commonJS | wc -l
13
```

| Directory | Total cells | Cells whose emitted code moves | Share |
|---|---|---|---|
| `snapshots/codegen/erlang/` | 314 | **62** | 20 % |
| `snapshots/codegen/beam/` | 313 | **68** | 22 % |
| **erlang + beam, steps 15–16** | 627 | **130** | 21 % |
| `snapshots/codegen/commonJS/` | 314 | **13** (step 19 only, and only if the maintainer assigns it here) | 4 % |
| `snapshots/codegen/wasm/` | 313 | **0** — `wat.zig` is not this front's ([`options.md` § 7](./identity-options.md#7-the-other-three-backends)) | — |
| `snapshots/comptime/**` | — | **0** — no comptime cell records a value shape | — |
| LSP snapshots | — | **0** | — |

The grep above reads the whole snapshot file. Restricting it to the ```` ```erlang ```` block only
gives **60** erlang cells (46 record + 14 enum); the two counts differ because two fixtures mention a
type in their source without constructing one. Quote 62 as the reproducible upper bound and 60 as
the tight figure.

**What each diff looks like.** One or two lines, never a new section:

```diff
  make() ->
-     #{x => 3, y => 4}.
+     #{'__bp_type' => 'main__t__point', x => 3, y => 4}.
```

```diff
  makeCircle() ->
-     {'Circle', 5}.
+     {'main__t__shape__v__circle', 5}.
```

Contrast [policy 3](./policy-3-module-per-type.md), whose 188 diffs each gain whole
`----- ERLANG -- <file>.erl` sections. That is why the two fronts sequence
([`halves-and-ordering.md`](./halves-and-ordering.md) § 4) rather than land together.

## 2. Overlap with the other fronts' snapshot sets

```console
$ grep -rl '^----- COMPTIME ERLANG' . | wc -l          # front 14's set
48
```

| Against | Shared cells | Verdict |
|---|---|---|
| **18** comptime-on-beam (48 `COMPTIME ERLANG` cells) | **0** — measured by intersecting the file lists | snapshot-disjoint; the only contact is the file `erlang.zig`, in disjoint functions |
| **half 2** policy 3 (188 cells carrying a `%% type`/`%% behavior`/`%% implement` marker) | **large** — 81 of the 314 erlang cells carry the marker and 62 of them build a value | must sequence inside the front; half 2 first |
| **02** erlang and **03** beam (own `erlang.zig`, `beam_asm.zig` and both snapshot directories) | all of them | halves 2–3 run after 02 and 03 close |
| **01** checker (may move all four codegen directories) | all of them | halves 2–3 run after 01 |
| **07** (`snapshots/comptime/**`) | **0** | may run in parallel |
| **17** (adds no snapshot) | **0** | may run in parallel |

## 3. `RUN LOG` — zero, and why

```console
$ # 611 non-empty RUN LOG blocks (erlang 151, beam 149, commonJS 151, wasm 160),
$ # 997 non-empty lines. Scanned for a printed record / variant:
  erlang map  #{         0
  erlang tuple {'X       0
  erlang unit  'X'       0
  js class  Name {       0
  js variant tag:        0
```

Not one fixture prints a composite user-typed value. The RUN LOGs of type-bearing cells print the
*results* of methods and field reads — `Ana`, `3 4`, `5`, `120`, `true false 4` — never the value
itself. So:

- **Steps 2–3 (the tag) change no `RUN LOG` at all.** A `RUN LOG` that moves is a bug, and that is
  the strongest acceptance condition this front has.
- **Step 5 (§7's formatter) also changes no existing `RUN LOG`.** Decision 8 §7's new text
  (`Point(x: 1, y: 2)`) has no snapshot to move into; its evidence has to be **new cells** in
  `tests/language/` ([`../../1.0.4-beta/15-language-tests/`](../../../1.0.4-beta/15-language-tests/README.md)'s directory,
  [`../12-language-tests/`](../12-language-tests/README.md)'s to extend).

One `RUN LOG` class *does* move and is not in the snapshots: the equality of two record values.
Measured on the compiler's own output ([E13](./identity-evidence.md#e13--both-spellings-applied-to-the-compilers-own-output)),
`Person(name:"Ana", age:30) == Vec(name:"Ana", age:30)` goes from `true` to `false` on erlang and
beam. No snapshot exercises it; a new cell must.

## 4. Libraries

| | Measured |
|---|---|
| `.bp` files in the seven repositories | 115 (`libs/std` 30, jhonstart 14, rakun 15, onze 5, emilia 4, erika 3, plus examples and tests) |
| `.bp` files that write a value shape | **0** — no library constructs a map or a tuple standing for a `type`; they all go through the constructor |
| Library cells that `@print` or assert on a user-type value directly | **0** (scan for `@print(` / `assert…(` whose first token is a PascalCase constructor or `Type.Variant`) |
| Libraries that stop compiling | **0 expected** — no source change is required anywhere ([`README.md` § Does not touch](./README.md)) |
| Libraries that start compiling | **0** — this half fixes latent failures, exactly as [halves 1–2 do](./README.md#blast-radius); its new cells are the only evidence the work did anything |

`scripts/known-red-libs.txt` is empty and must stay empty. `zig build test-libs` is the front's
gate row for this; the **baseline to hold**, run at `26d4fdc` on 2026-09-18:

```
test-libs: 9 passed, 0 failed, 0 known red, 3 skipped, 2 without tests
```

(the three skips are jhonstart, onze and rakun on erlang — `botopink test` cannot run that target
for them, or their `targets` list excludes it; unrelated to this front.)

## 5. Compiler source

| File | Sites | Rough LOC |
|---|---|---|
| `src/codegen/crossModule.zig` | `typeAtom` / `variantAtom` beside step 1's `erlDeclAtom`; the collision check extended to type and variant atoms | ≈ 40 |
| `src/codegen/erlang.zig` | 8: `:4702-4708`, `:4194-4199`, `:4776-4782`, `:5030`, `:5038-5048`, `:5073-5076`, `:554`, `:2840-2841` | ≈ 90 |
| `src/codegen/beam_asm.zig` | 7: `:4516-4536`, `:3300-3315`, `:6212-6225`, `:5272-5286`, `:5333`, `:1684-1689`, `:3482-3494` | ≈ 90 |
| `src/codegen/commonJS.zig`, `typescript.zig` | step 19 only: `commonJS.zig:1563-1566`, `:3874`; `typescript.zig:115-127` | ≈ 30 |
| the `is` / union-`case` / formatter lowerings (steps 17–18) | new code in both backends, after 01's N19–N22 | ≈ 250 |
| `src/codegen/tests/**` | new fixtures (08's files — a carve-out must be agreed) | ≈ 120 |
| `tests/language/**` | new cells for `is`, a named-type union `case`, §7's printed form, record equality (17's files — coordinate) | ≈ 150 |

Estimated **≈ 3–4 days** for steps 14–16 and 19, **+3–4 days** for steps 17–18 (which cannot start before
01 lands N20/N21/N22), so **≈ 7 days** total. That is on top of halves 1–2's ≈ 9.

## 6. What a user sees change

| Before | After | Where it is visible |
|---|---|---|
| `@print(p)` → `#{name => <<"Ana">>,age => 30}` | step 16: `#{name => …,'__bp_type' => main__t__person,age => 30}`; step 18: `Person(name: "Ana", age: 30)` | any program that prints a record on erlang or beam |
| `@print(Shape.Dot)` → `'Dot'` | step 16: `main__t__shape__v__dot`; step 18: `Shape.Dot` | idem |
| `Person(…) == Vec(…)` with the same fields → `true` | `false` | erlang and beam only — commonJS already answers `false`, for the wrong reason ([`representation.md` § 4](./representation.md#4-commonjs--two-thirds-of-the-identity-and-one-hole)) |
| a raw term in a stack trace | carries the type atom | a **readability gain**; needs a line in the migration notes, not a decision |
| `out/` layout, module names, `.js` / `.wat` output | unchanged by this half | half 1 owns the layout |

**The one user-visible regression risk**: between step 16 and step 18 the printed form of a record is
*worse* than today (it shows the internal key). The two steps should land in the same release even
if they land in different commits, and step 18's acceptance is what closes it.
