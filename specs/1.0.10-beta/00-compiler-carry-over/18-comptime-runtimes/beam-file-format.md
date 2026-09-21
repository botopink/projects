# The `.beam` container, from `beam_asm.zig`'s model

What a minimal loadable module contains, how the pieces map onto the types `beam_emitter.zig`
already has, what `erlc -S` computes that the emitter does not, and how the result is validated.
Chunk sets and sizes below are read off the three resident modules this project builds today
([`evidence.md`](./evidence.md) E-5); the format itself is OTP's (`beam_lib`, `beam_asm.erl`,
`beam_dict.erl`), stable since OTP 20 except the `Code` opcode table.

## 1. The container

```
"FOR1" <u32 BE size> "BEAM"            IFF header; size = bytes after this field
( <4 ascii id> <u32 BE len> <len bytes> <pad to 4> )*
```

Chunks measured on `bp_comptime_template.beam` (3 200 B, `erlc` OTP 29):

| Chunk | Bytes | Needed to load? | Holds |
|---|---:|---|---|
| `AtU8` | 565 | **yes** | atom table, UTF-8: `<u32 count>` then `<u8 len><bytes>` each; index 1 is the module atom |
| `Code` | 1 255 | **yes** | `<u32 subsize=16> <u32 instruction_set=0> <u32 opcode_max> <u32 label_count> <u32 function_count>` then the compact-term-encoded instruction stream |
| `StrT` | 0 | yes (may be empty) | the string table for `bs_put_string`; empty for these modules |
| `ImpT` | 148 | **yes** | `<u32 count>` of `{module atom idx, function atom idx, arity}` — every `call_ext` target |
| `ExpT` | 256 | **yes** | `<u32 count>` of `{function atom idx, arity, entry label}` |
| `FunT` | 28 | yes if any `make_fun*` | `<u32 count>` of `{fun atom idx, arity, label, index, num_free, old_uniq}` |
| `LitT` | 123 | yes if any `{literal, …}` | `<u32 uncompressed size>` + zlib stream of `<u32 count>` × `<u32 len><ETF term>` |
| `Line` | 171 | **yes** for OTP ≥ 19 (loader expects it) | `<u32 ver=0> <u32 bits> <u32 num_line_instrs> <u32 num_lines> <u32 num_fnames>` + compact-encoded line refs + file names |
| `Meta` | 45 | no | features list (`{enabled_features, …}`) |
| `LocT` | 52 | no | local functions (debug) |
| `Attr` | 39 | no | `vsn` etc. as ETF |
| `CInf` | 235 | no | compile info as ETF (options, source path, time) |
| `Dbgi` | 126 | no | abstract code / debug info |
| `Type` | 19 | no (OTP 25+, optional) | type-based optimisation hints |

The assembler emits the first eight. `code:load_binary/3` accepts a module without `Meta`, `LocT`,
`Attr`, `CInf`, `Dbgi`, `Type`; `beam_lib:chunks(Beam, [attributes])` on such a module answers
`[]`, which is fine.

## 2. From the `.S` model to the tables

`beam_emitter.zig` spells operands and instructions; it never assigns numbers. The assembler adds a
`Dict` (the same role as `beam_dict.erl`) that the emitter's write functions feed instead of a
`Writer`:

| Emitter type / function (`src/codegen/beam/beam_emitter.zig`) | Becomes | Table |
|---|---|---|
| `Operand.x`, `.y` (`:29-31`) | compact term tag 3 / 4 (`x`, `y` register) | — |
| `Operand.f` (`:33`) — label | tag 5 (`f`), resolved to the label's code offset at the end | `Code` (label map) |
| `Operand.term = Term.atom` (`:35`, `term.zig`) | tag 2 (`a`) with the atom's index | `AtU8` |
| `Operand.term = Term.integer` | tag 1 (`i`) small or extended | — |
| `Operand.term` compound, `.lexeme` binary (`:37`), `writeLiteral` (`:226`), `writeMove` of a literal (`:233`) | tag 7 ext (`z`) subtag 4 `{literal, Idx}`; the term encoded by **`etf.zig`** (`comptime/runtime/etf.zig:43`) — already pinned to OTP's byte vectors | `LitT` |
| `Operand.bare` (tuple arity, element index) | tag 0 (`u`) | — |
| `writeModuleForm` (`:271`) | atom index 1 | `AtU8` |
| `writeExports` (`:278`, `Export`) | `ExpT` rows; entry label → offset | `ExpT` |
| `writeAttributes` (`:290`) | dropped (optional chunk) | — |
| `writeLabels` (`:295`) | `label_count` in the `Code` header | `Code` |
| `writeLabel` (`:300`) | `label N` opcode 1; records offset | `Code` |
| `writeFunctionHeader` (`:305`) | `func_info` opcode 2 with `{atom module}{atom name}{u arity}`; `function_count++` | `Code`, `AtU8` |
| `writeFuncInfo` (`:312`) | same | |
| `writeLine` (`:321`) | `line` opcode 153 with a line-table index | `Line` |
| `writeCall` (`:424`, `CallKind`, `Callee`) | `call`/`call_last`/`call_only` (4/5/6) to a label, or `call_ext`/`call_ext_last`/`call_ext_only` (7/8/9) with an `ImpT` index | `ImpT` |
| `writeGcBif` (`:391`, `GcBif`) | `gc_bif1/2/3` (124/125/152) with `{f fail}{u live}{ImpT idx of erlang:<bif>}` | `ImpT` |
| `writeBif` (`:402`) | `bif0/1/2` (9/10/11) | `ImpT` |
| `writeTest` (`:367`, `TestOp`) | `is_*` opcodes (39–58, 159, …) | |
| `writeAllocate`/`writeDeallocate`/`writeInitYregs` (`:346-365`) | `allocate` 12, `deallocate` 18, `init_yregs` 172 (list operand) | |
| `writeTestHeap`/`writeTestHeapAlloc` (`:377-389`) | `test_heap` 16, `allocate_heap` 14 | |
| `writeTry`/`writeTryEnd`/`writeTryCase` (`:446-459`) | 104 / 105 / 106 | |
| `writeCallFun` (`:461`) | `call_fun` 75 | |
| `writeMakeFun3` (`:468`) | `make_fun3` 171 with a `FunT` index | `FunT` |
| `writePutList`/`writePutTuple2`/`writeGetTupleElement` (`:475-500`) | 69 / 164 / 66 | |
| `writeMoveOp`/`writeJump`/`writeReturn` (`:326-344`) | `move` 64, `jump` 61, `return` 19 | |

Opcode numbers above are OTP's `genop.tab` (stable across releases for existing opcodes; new
releases only append). The assembler carries the table as `beam/opcodes.zig`, generated once from
`genop.tab` of the pinned release (question 4 of the README), with `opcode_max` written into the
`Code` header as the highest opcode actually used — the loader refuses a module whose `opcode_max`
exceeds what it knows, which is the version check.

**Compact term encoding** (the `Code` stream): every operand is `<value:5 bits><tag:3 bits>` for
values < 16; values < 2048 use one extension byte (`tag | 0b01000`); larger values carry a byte
count. Tags: 0 `u`, 1 `i`, 2 `a`, 3 `x`, 4 `y`, 5 `f`, 6 `h`, 7 `z` (extended: 1 list, 2 float
register, 3 alloc list, 4 literal, 5 type-tagged register). `beam_emitter.zig` already knows which
operand kind each argument is; the encoding is the only new knowledge.

## 3. Building the tables

| Table | Build rule |
|---|---|
| `AtU8` | first insertion wins the index; index 1 must be the module atom — insert it before anything else. Every atom the emitter would write with `writeAtomOperand` (`:195`), every module/function name in `ImpT`/`ExpT`/`FunT`. |
| `ImpT` | `(module, name, arity)` triples in first-use order; `call_ext*` and `bif*`/`gc_bif*` operands carry the index. The resident prelude's functions (`bp_comptime_template:text/1`, …) are `ImpT` rows — this is where step 1b's `-import` becomes `call_ext`. |
| `ExpT` | one row per `ComptimeModule.exports` (`main/1`) and per lowered `fn` the erlang path exports (`erlang.zig` exports the lowered decls; `-export([main/1, conf/1])` in the on-disk sample). |
| `LitT` | one entry per distinct compound literal, deduplicated by ETF bytes; the chunk is zlib-compressed — Zig `std.compress.zlib` (or store the literal uncompressed with the same framing: the loader inflates whatever `uncompressed size` promises — verify against `beam_lib` in the test, do not assume). |
| `Line` | one line-table entry per `writeLine`; `num_fnames = 1`, the file name being the module's `.bp` basename so a BEAM stack trace names the source. |
| `Code` header | `opcode_max`, `label_count` (= `writeLabels`' count), `function_count` (= `writeFunctionHeader` calls). Labels are resolved in a second pass over a list of `(offset, label)` fix-ups; each `f` operand is patched with the label's byte offset. |

## 4. What `erlc -S` has that the emitter does not compute yet

Read off `erlc +to_asm` output against `beam_asm.zig`'s `.S`:

| In `erlc -S` | In `beam_asm.zig` today | Needed for the `.beam`? |
|---|---|---|
| `{attributes, []}` | `writeAttributes` writes it | no |
| `{labels, N}` | `writeLabels` | yes — the `Code` header's `label_count` |
| `{line, [{location, "file", L}]}` | `writeLine(module, n)` writes a line index only | yes — `Line` chunk; the file name must be added |
| `{literal, …}` operands | written as Erlang source text via `erl_emitter` | yes — replaced by `etf.encode` bytes (`LitT`) |
| `{extfunc, M, F, A}` operands | spelled inline in `call_ext` | yes — becomes an `ImpT` index |
| `{f, 0}` as the "no fail label" | written as `{f, 0}` | yes — encoded as `f` 0 |
| `func_info` per function | `writeFuncInfo` | yes |
| `{make_fun3, {f,L}, Index, OldUniq, {x,0}, {list, Env}}` | `writeMakeFun3(label, env)` — no `Index`/`OldUniq` | yes — `FunT` needs `index` (sequential) and `old_uniq` (any stable u32; `erlc` uses a hash of the module) |
| `int_code_end` (opcode 3) closing the stream | not written | yes — the last instruction of `Code` |
| `beam_validator` pass (`erlc +from_asm` runs `beam_validator_weak` before assembling) | none | **no, and this is the risk**: a mis-typed register use crashes the VM at load or at run instead of failing `erlc`. The assembler's test therefore loads every module through `beam_lib:info/1` + `code:load_binary/3` *and* runs `erts_debug`-free `beam_validator:validate/2` once per fixture in the parity test — `beam_validator` is a stdlib module, callable from the resident server with the disassembled form from `beam_disasm:file/1`. |

## 5. Validation, in order

1. `beam_lib:info(Beam)` — chunk ids and sizes; refuses a wrong `FOR1` size or padding.
2. `beam_lib:chunks(Beam, [atoms, imports, exports, labeled_locals])` — decodes the tables.
3. `beam_disasm:file(Beam)` — decodes `Code` against the running release's opcode table; a bad
   operand tag or an unknown opcode fails here, not in the VM.
4. `code:load_binary(Mod, "", Beam)` — the loader's own checks (`opcode_max`, label ranges,
   `func_info` consistency).
5. `Mod:main(Term)` — the parity test's byte-identical `COMPTIME REPLY`.

Steps 1–4 run in the resident server behind a **cmd 5** (`verify`) used only by tests; the
production path runs 4 and 5.
