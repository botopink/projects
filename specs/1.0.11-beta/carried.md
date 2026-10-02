# Carried — 1.0.10-beta → 1.0.11-beta

The map from the closed milestone to this one. 1.0.10-beta is frozen
([`closure.md`](../1.0.10-beta/closure.md)); every open item there has exactly one owner here. A
front keeps its global number when it is carried (front 53 is still `07-onze/53-onze-example-app/`);
a front that consolidates several tails is named after the lowest number it carries and lists the
others; the numbers allocated new in this milestone are **97–101 and 108+** (`00-gate`, `02-std-and-packaging`),
**102–107** and **125** (`03-bundled-libs`), **116–124**, **126**, **127** (`08-bpp`), and **128** (`04-rakun`, the consolidation of decision 187; next free **129**). Carry-over ids `C-01…C-33` keep their ids; `C-34…C-37` were
allocated at the cut (next free **C-38**). Compiler sub-fronts keep `01…25`; `26-cli-tooling` is new.

The per-item map — which box of which 1.0.10 README went where, and which boxes closed on tick
with their evidence — is each track's `carried.md`:

| 1.0.10-beta | 1.0.11-beta | Per-item map |
|---|---|---|
| the gate as it stood at the close (8 / 10 stages; 36 red library cells; 3 expected-failure lines; 21 ledger lines; 226 files outside `format-check`; 11 `zig fmt` reds; 9 docs-check skips; windows `allow_fail`) and every "Handed to 00-gate" item of the tracks | [`00-gate/`](./00-gate/README.md) — one front per red or tolerant repository (rakun, onze, jhonstart, erika, emilia), one per compiler area (wasm link loop, beam sidecar + `run.sh`), the formatter trees, the ledger and guards, docs-check and CI rows, gate performance | [`00-gate/carried.md`](./00-gate/carried.md) |
| `00-compiler-carry-over/` 01…25, items C-01…C-33 | [`01-compiler/`](./01-compiler/README.md) — 17 fronts: the 16 sub-fronts with open work under their 1.0.10 numbers, plus `26-cli-tooling`; DONE sub-fronts 11, 13, 15, 19, 20, 21, 22 have no directory (their residual rows went to the front that owns the file) | [`01-compiler/carried.md`](./01-compiler/carried.md) |
| `01-std/` (01…06), `02-packaging/`, front 95 | [`02-std-and-packaging/`](./02-std-and-packaging/README.md) — `97-std-dedupe` (the std side of decisions 115–117's "what is generic goes to std", and every std tail) and `98-packaging-tail`; none of `01-std/01…06` is a front here — all their boxes close on tick, on confirmation, or are steps of 97 | [`02-std-and-packaging/carried.md`](./02-std-and-packaging/carried.md) |
| `03-rakun/` 04…25, 60…66, 72…93 (51 fronts) | [`04-rakun/`](./04-rakun/README.md) — 19 carried fronts cut by member, behind one new front, `128-rakun-consolidation` (decision 187: nine members merge before any of them opens): 04 (carries 05 · 06 · 14 · 62), 08 (77 · 78), 09, 11 (76 · 87), 12 (18), 13 (21), 15 (16 · 83 · 86 · 89 · 90), 17 (75), 19, 22 (23 · 24 · 25 · 60 · 61 · 63 · 64 · 66), 65 (07 · 82), 73, 74, 79 (10), 81, 88, 91, 92 (20), 93; `modules.md` re-derived from the tree | [`04-rakun/carried.md`](./04-rakun/carried.md) |
| `04-jhonstart/` 26…32, 67, 94 | [`05-jhonstart/`](./05-jhonstart/README.md) — 26 (carries 28 · 29 · 30 · 31), 27, 67; 94 and 32 closed | [`05-jhonstart/carried.md`](./05-jhonstart/carried.md) |
| `05-emilia/` 33…48, 54…59 | [`06-emilia/`](./06-emilia/README.md) — 34 (carries 40 · 42 · 43 · 44 · 45 · 54 · 56), 33 (the test and examples layer of 35–48, 54–59) | [`06-emilia/carried.md`](./06-emilia/carried.md) |
| `06-onze/` 49…53, 68…71 | [`07-onze/`](./07-onze/README.md) — 49 (carries 69), 50 (68), 51 (52 · 70), 71, 53 | [`07-onze/carried.md`](./07-onze/carried.md) |
| — (opened by the cut's audit of what the frameworks copy from each other) | [`03-bundled-libs/`](./03-bundled-libs/README.md) — 102 routing conventions, 103 actions id, 104 http, 105 i18n, 106 log (decision 195), 107 release (conditional on `07-g`) | its README § Order |
| — (new in this milestone; reference: Zod 4) | [`03-bundled-libs/125-validation-zod/`](./03-bundled-libs/125-validation-zod/README.md) — `validation` gains the function it lacks: `#[schema]` derives `parse<T>` / `decode<T>` / `bind<T>` / `encode<T>` / `jsonSchemaOf<T>` from a type, `Schema<T>` is the composable value, and the checks grow from 13 markers to 71. Decisions `07-j…n` | [`surface.md`](./03-bundled-libs/125-validation-zod/surface.md) — 205 reference rows |
| — (new in this milestone; reference: the Astro documentation) | [`08-bpp/`](./08-bpp/README.md) — 11 fronts over jhonstart, onze, rakun and emilia: 118 the template language, 121 content, 120 islands, 117 routing, 119 scoped styles, 127 typed actions, 122 the request surface, 123 middleware, 126 view transitions, 116 the `.bpp` file kind, 124 the CLI. Decisions `08-a…i` | [`surface.md`](./08-bpp/surface.md) — 160 reference rows |
| `contracts.md`, `deferred.md` | carried whole, re-pointed | — |
| `language-gaps.md` | carried whole, re-owned, ten rows added at the end of each table | — |
| `decisions-pending.md` § Open (26) + `ck-host` | [`decisions-pending.md`](./decisions-pending.md), verbatim; the lettered choices indexed to the track that confirms them | — |
| `decisions-taken.md` 68–143 | stays in 1.0.10-beta; [`decisions-taken.md`](./decisions-taken.md) here starts at 144 | — |
| `unification.md` | stays (the 1.0.6–1.0.9 map); this file is its successor | — |
| `status.md` | frozen there; [`status.md`](./status.md) here opens with every carried item under Open | — |
