# beam — what still bypasses the emitter

> Carried from `1.0.2-beta/04-beam/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

The rule carried from 1.0.1-beta is that **a backend builds a model and an emitter renders it**; no
backend prints target syntax. Three backends hold it with no exception. `beam_asm.zig` is the one
that does not.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`. Every `file:line` is at
HEAD.

## Current state

Target-text writer calls left in the backends, found with
`rg -n '\.(print|writeAll|writeByte)\(' src/codegen/beam_asm.zig src/codegen/erlang.zig` (the writer
grep needs the real receiver spelling, `aw.writer.`, not `w.`):

| File | Calls | What they are |
|---|---|---|
| `src/codegen/wat.zig` | 0 | — |
| `src/codegen/typescript.zig` | 0 | — |
| `src/codegen/commonJS.zig` | 3 | none of them target text: `:472` is a `std.debug.print` warning to stderr, `:1302` and `:1475` compose a **comment**'s wording into an arena buffer |
| `src/codegen/erlang.zig` | 2 | `:1584` / `:1587` — the `$stringify(…)` wrapper, owned by [`../02-erlang/raw-rows.md`](../02-erlang/raw-rows.md) |
| `src/codegen/beam_asm.zig` | **12** | 9 at `:603-617` (the `.S` module preamble, below) + 3 at `:2690`, `:2693`, `:2710` (the `#[@External.Beam]` verbatim passthrough, which stays) |

## The `.S` module preamble — 9 calls

`emitBeamAsm` (`src/codegen/beam_asm.zig:603-617`) writes the module preamble by hand:

| Form | What it writes |
|---|---|
| `{module, …}.` | the module atom |
| `{exports, [{f, N}, …]}.` | every exported function, with **its own `atomName` quoting** per export |
| `{attributes, []}.` | the empty attributes form |
| `{labels, N}.` | the label count |

Two of the nine are the `writeAll`s at `:615` and `:617` that splice the already-rendered body and
the deferred lambdas into the output. Everything else in the file already goes through
`src/codegen/beam/beam_emitter.zig`.

**What to do:** give the emitter `writeModuleForm` / `writeExports` / `writeAttributes` /
`writeLabels` — it already owns atom quoting through `writeAtomOperand` — and call them. This is a
refactor: **beam snapshots land byte-identical**. A diff is a bug found, and it moves into
[`causes.md`](./causes.md) as a numbered cause rather than being re-recorded.

## The three calls that stay

`:2690`, `:2693` and `:2710` are the `#[@External.Beam]` verbatim passthrough: a template body that
is genuine host text, which is the one thing a `raw`-style path is for. They stay, and they must be
named in `src/codegen/beam/AGENTS.md` as the single documented exception, so "no backend prints
target syntax" reads as an invariant with one stated carve-out rather than as an aspiration.

## Ordering

| Before | Why |
|---|---|
| [`causes.md` § the full-export audit](./causes.md#the-full-export-audit) | The narrow `{exports, …}` form this code writes is exactly what hides two loader rejections, because `erlc +from_asm` drops unexported functions before validating them. Land `scripts/beam_export_audit.sh` first, or "byte-identical" is verified against a tree whose rejections are still invisible |
| [`../02-erlang/raw-rows.md`](../02-erlang/raw-rows.md) § dead scaffolding | That step deletes `Form.raw` / `Body.raw_block` / `Form.attribute` from `src/codegen/beam/erl_ast.zig` and `erl_emitter.zig`; this step adds methods to `beam_emitter.zig`. Different files in the same directory, but anything that drifts re-records `snapshots/codegen/beam/` — sequence them, erlang first |

## Acceptance

- [ ] 9 writer calls gone from `emitBeamAsm`; `rg -n '\.(print|writeAll|writeByte)\(' src/codegen/beam_asm.zig`
      returns exactly the 3 `#[@External.Beam]` passthrough calls
- [ ] Those 3 are documented in `src/codegen/beam/AGENTS.md` as the exception, with the reason
- [ ] Beam snapshots byte-identical
