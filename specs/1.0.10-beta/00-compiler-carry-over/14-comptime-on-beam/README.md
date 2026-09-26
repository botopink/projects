# Front 14 — comptime-on-beam

**Track:** compiler (carry-over item **C-20**, step 3; steps 0–2 were 1.0.5-beta's)
**State:** landed. Decision 24 (*no Erlang source in the compile path*) holds. Open: three
acceptance boxes of steps 1–2 (§ *Open*), and the CI matrix run shared with
[`18-comptime-runtimes`](../18-comptime-runtimes/README.md).
**Owns:** `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` ·
`src/comptime/runtime/beam/` (the lowering) · `src/codegen/beam/asm_text.zig` (the listing) ·
`src/comptime/runtime/prelude.zig` (the resident preludes) · `scripts/comptime_bench.sh`.
**Does not touch:** `src/comptime/eval.zig` (the Zig-folded `COMPTIME VALUES`), the typed
`beam_asm.zig`, `libs/std/**` and the libraries — no `.bp` changes.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless they start with
`modules/`, `libs/` or `scripts/`, which are relative to `repository/botopink-lang/`.

---

## What holds

**One module per declaration.** A template or decorator body becomes one comptime module keyed by
the declaration (`crossModule.erlDeclAtom(COMPILER_PACKAGE, .tpl|.dec, decl, hash)` →
`bp@comptime__{tpl,dec}__<decl>__<16 hex>`), the hash taken over the code without the call site's
data. The capture map and the `@Decl` handle travel as an external-term-format argument
(`comptime/runtime/etf.zig`) to `main/1`; one module serves every call site.

**The host glue is resident.** The template and decorator host functions live in
`bp_comptime_template` / `bp_comptime_decorator` (`runtime/prelude.zig`), loaded once per node; a body
reaches them by `call_ext`.

**A comptime body reaches the node as BEAM bytes.** The Erlang `erlang.zig`'s untyped mode produces
(`emitComptimeModule`) is an in-memory intermediate: read back by `comptime/runtime/wat/erl_parse.zig`
(the reader the wat runtime uses), lowered to BEAM instructions (`comptime/runtime/beam/lower.zig`),
assembled in Zig (`codegen/beam/beam_file.zig`) and loaded with cmd 4 (`code:load_binary/3`) by
`persistent_beam.zig`. Nothing writes the Erlang and nothing compiles it; the node has cmds 3 and 4
only. The same instructions rendered as `.S` text (`codegen/beam/asm_text.zig`) are the
`COMPTIME BEAM ASSEMBLY` listing a snapshot shows, so bytes and listing describe one program, and
`scripts/beam_export_audit.sh` hands the listing to `beam_validator`, which the load path does not run.

**The code shape** is plain: every value in a Y register, operators and calls through `call_ext`, so
errors are the BEAM's own (`badmatch`, `case_end`, `function_clause`, `{badarg, V}` from `andalso`,
`bad_generator`…); guards on `bif`/`gc_bif` with fail labels; a `fun` lifted with its captures as
trailing parameters; a named `fun` calling itself as a direct tail call; a list comprehension as an
in-line loop. Decision 86: a computed binary is `iolist_to_binary/1` over segments each type-checked
as the segment would be (`bs_create_bin` is OTP 25). Detail in `src/comptime/runtime/AGENTS.md` and
`src/codegen/beam/AGENTS.md`.

**What it refuses it names**, as a compile error of that comptime module — the wat runtime's channel
(decision 67: refuse, do not fall back). There is no `.erl` fallback; every body in the suite
(17 template, 19 decorator) and in `test-libs` (2 template, 61 decorator) lowers. The refusal list is
in `src/codegen/beam/AGENTS.md` § *Comptime lowering*.

**Snapshots.** `COMPTIME REPLY` is the assertion and is byte-identical across both comptime runtimes;
`COMPTIME BEAM ASSEMBLY` is the listing (7 files in each `codegen/beam/{beam,commonJS,erlang,wasm}`,
5 in `comptime/runtime/beam`); `COMPTIME VALUES` is Zig-folded and not this front's.

**Measurement lives in the repository:** `scripts/comptime_bench.sh` generates the N-call-site
project, builds it and prints the breakdown. Re-measure; do not quote numbers.

## Open

- [ ] A located "no primitive type and no host function provides `.foo(…)`" diagnostic has its
      negative fixture: the method call a body cannot make produces the compiler's own located
      message (`unsupported_method`), not a runtime's
- [ ] The generated N-call-site project's slope ≤ 1 ms per evaluation, N=200 build ≤ 600 ms (step 0's
      script). What stands in the way is not this front's: each `emitComptimeModule` re-parses the
      embedded `primitives.bp` and `erlang_bifs.d.bp` preludes (`collectPrimErlangDispatch`,
      `loadAutoImportedBifsFromPrelude`); the memo belongs in the shared body of
      [`02-erlang`](../02-erlang/README.md)'s `emitErlangModule`
- [ ] A fixture for each shape that must survive the term round trip: a holed template (`${…}`
      parts), an `@ExprCustom` return with its reference tree, a decorator whose `@Decl` handle
      carries fields, methods, variants and annotations

The step-1 box "`compile:file` of the smallest generated module ≤ 1.5 ms" left with step 3
(decision 24): nothing compiles a comptime module any more.

**Known gap, not this front's:** a flat argument whose lexeme carries `\u{…}` stays a literal in the
module — `erl_emitter.writeStringFromLexeme` renders it as Erlang's `\x{…}`, which truncates the code
point to one byte. It belongs to whoever owns `writeBinaryFromLexeme`.

## Delivered

- `scripts/comptime_bench.sh` reproduces the cost on the runner's machine, writing nothing inside a
  repository
- the host functions resident; the capture an ETF argument; one module per declaration; a broken
  node stream says what broke instead of collapsing into `EvalFailed`
- `COMPTIME REPLY` byte-identical at every step; every re-recorded listing classified, never
  bulk-accepted
- erika-linq's single compile, text to loaded code, within the ≤ 12 ms budget; the node does
  `code:load_binary` only
- `COMPTIME ERLANG` renamed `COMPTIME BEAM ASSEMBLY`, every other section unchanged
- `scripts/beam_export_audit.sh` green, the comptime listings included;
  `scripts/snap_audit.sh --mode=runtime-parity` green
- no `.erl` written for any declaration: the staging and cmds 1/2 are deleted
- `botopink clean` removes `.botopinkbuild/` whole
- `AGENTS.md` of `src/comptime/`, `src/comptime/runtime/`, `src/codegen/`, `src/codegen/beam/` and
  `meta:architecture.md`'s "O que roda onde" table name the shape
- `scripts/gate.sh --cold` green

## Notes

- **The resident node stays.** BEAM bytecode runs on a BEAM VM; what left the compile path is the
  Erlang *compiler*, not `erl`. A build whose target is commonJS, typescript or wasm evaluates on the
  wat runtime instead and spawns nothing (decision 84, front 18).
- **One lowering of Erlang per runtime** (BEAM here, wasm in front 18), cross-checked by the
  `COMPTIME REPLY` snapshots, the codegen harness's `runtime.parity` on every fixture, and the
  semantics test in `beam/program.zig`.
