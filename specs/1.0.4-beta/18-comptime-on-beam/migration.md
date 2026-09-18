# Migration — the staged plan, what proves each stage, what to fall back to

The recommendation of [`options.md`](./options.md#7-recommendation) as a sequence. Each stage lands
on its own branch, is green on its own, and is **reversible without the next one**. Stage 0 is not
optional: nothing below can be claimed without it.

---

## Stage 0 — a repeatable measurement, in the repository

Today the only way to know what the comptime path costs is to reproduce
[`evidence.md`](./evidence.md) by hand. Every later stage's acceptance is a number, so the number
needs a home.

**Do:** a script beside the others (`scripts/`) that generates the N-call-site project of
[E1](./evidence.md#e1--the-comptime-path-costs-25-ms-per-evaluation-linearly) into a temporary
directory, builds it, and prints the table — wall clock, evaluations, `.erl` bytes written, and the
in-node `compile:file` / `load_binary` / `main()` split over the modules the build left behind.

**Proves:** the 25 ms/evaluation and the 0.05 ms body, on the machine the reader is on.
**Fallback:** none needed — it changes no compiler code.
**Owner note:** `scripts/**` is [`../05-cli-residuals/`](../05-cli-residuals/README.md)'s, delivered;
this front needs one new file there as a carve-out, or it lives under `modules/compiler-core/` as a
test.

---

## Stage 1 — the host functions become a resident prelude

The 19 template and 6 decorator host functions are identical in every module the compiler has ever
produced ([E4](./evidence.md#e4--every-call-site-compiles-the-same-program-again)). They move into
one Erlang module compiled once, exactly as `botopink_comptime_server` already is
(`persistent_erl.zig:234-274`, hash-keyed directory, `erlc` skipped when warm), and the generated
body calls them as `bp_prelude:text(Q)`.

**Do:**
- `comptime/runtime/prelude.zig` (or a second `const` beside `server_erl`) holding the prelude
  source; `prepareServer` builds it in the same hashed directory and `erl -pa` finds it.
- `template_eval.hostForms` / `decorator_eval.hostForms` stop emitting the fixed functions and
  `erlang.comptime_helper_forms` stops being appended for a comptime module; the calls the body
  emits become remote calls into the prelude.
- The `unsupported_method` gate (`erlang.zig:5084` `untypedPrimCallNode`, reported through
  `ComptimeModule.unsupported_method`) must keep firing: it currently decides
  "no host form defines it" from `ComptimeModule.forms`, which will be empty. Give it the prelude's
  exported names instead — a frozen list, tested against the prelude source.

**Proves:**
- `compile:file` of the smallest generated module drops from 8.470 ms to ≈ 1.3 ms
  ([E5](./evidence.md#e5--what-each-module-shape-costs)); of erika's, from 53.25 to ≈ 47.3 ms.
- Every one of the 48 `COMPTIME ERLANG` snapshots shrinks to the body plus `main/0`, and its
  `COMPTIME REPLY` twin is **byte-identical** — the replies are the evidence that the move changed
  nothing.
- `zig build test` green; `test-libs` green.

**Fallback:** revert; nothing else depends on it. **Risk:** an unsupported-method diagnostic
regressing to `erl_lint`'s `{undefined_function, …}` — the acceptance test is the existing negative
fixture (the one template module in the suite that deliberately fails to compile,
[E2](./evidence.md#e2) footnote).

---

## Stage 2 — the capture becomes an argument, the module is compiled once per declaration

The stage that removes the cost. `main/0` becomes `main/1`; the capture map / `@Decl` handle
travels as a term; the module's content hash is taken over the code **without** the data, so the
same template compiles once however many call sites it has.

**Do:**
- An external-term-format encoder over `codegen/beam/term.zig` — atoms, binaries, small and large
  integers, floats, lists, tuples, maps — so a `Term` reaches the node through
  `binary_to_term/1`. **Not** Erlang source text re-parsed in the node: that is the
  `'__bp_erl_eval'/2` shape, measured at ≈ 50× a direct call (`codegen/beam/AGENTS.md`).
- Plain arguments travel the same way; they already resolve to values only
  (`comptime/template.zig:154-166`).
- Two commands beside cmd 1 in the frame protocol: **cmd 2** *compile and load `<path>`, answer the
  module atom*, and **cmd 3** *call `<module>:main(<term>)`, answer the reply*. Keep cmd 1 — the
  regression tests in `persistent_erl.zig:445-485` drive it, and it is the one-shot path a failure
  can fall back to.
- The evaluators keep a per-process map from declaration-hash to loaded module atom, so a second
  call site sends cmd 3 alone.

**Proves:**
- `erika/examples/erika-linq`: erl-side work from **960 ms to ≈ 49 ms** (18 evaluations, 1 compile)
  — measure with stage 0's script, not by eye.
- The N-call-site project's slope collapses: ≈ 25 ms/evaluation → ≈ 0.3 ms/evaluation; the N=200
  build from 5 255 ms to ≈ 400 ms.
- `.botopinkbuild/tmp/template/` holds **one** `.erl` per template declaration, not one per call
  site ([E13](./evidence.md#e13--what-is-left-on-disk)).
- Every `COMPTIME REPLY` snapshot byte-identical; the `COMPTIME ERLANG` listings change once, here.

**Fallback:** cmd 1 still works; the evaluator can be switched back to "one module per call site"
with a flag if a shape is found that does not survive the term round trip.
**Risk, named:** a capture that is not representable as a term. The capture is already built as a
`Term` (`template_eval.zig:372`), so by construction it is — but `@ExprCustom`'s reference tree and
the holed-template placeholders are the shapes to pin with fixtures first.

---

## Stage 3 — the module reaches the node as BEAM assembly (`.S`)

Only now is the maintainer's request a small change rather than the whole front: after stage 2 the
compiler produces **one module per template declaration**, so the gap to close is one module's
worth, not one call site's.

**Do:** `beam_asm.zig` gains what `erlang.zig:777` gates —

1. an untyped lowering mode: `+` → `'__bp_add'`, `.len`/`.length`/`.size` → `'__bp_len'`,
   `untypedPrimCallNode`'s fallbacks, and the located `unsupported_method` report;
2. host records and host enums without declarations (`Span`, `CustomNode`, `Binding`, `Source`,
   `Context`, `DeclKind`, `BindingKind`);
3. a `main/1` entry that calls the body and hands the reply back — the reply encoder itself is in
   the prelude after stage 1, so nothing of the 19 host functions needs a `.S` form;
4. `writeModule` writes `<module>.S`; cmd 2 learns `[from_asm]`.

**Proves:** erika's single compile from 47.28 ms to **9.33 ms**; the small one from 1.29 to
**0.392 ms**; `scripts/beam_export_audit.sh` still 295/295; every `COMPTIME REPLY` byte-identical.
The `COMPTIME ERLANG` snapshot sections become `COMPTIME BEAM ASSEMBLY` — a rename of 48 files,
classified in the commit message.

**Fallback — and it must be built in:** keep the `.erl` path behind the same `buildModule`, and
fall back to it per declaration when the BEAM path reports an unlowered construct. That is not a
hedge: it is what makes stage 3 landable incrementally, one construct at a time, instead of
requiring the whole untyped mode before a single body runs. The fallback rate is the stage's own
progress metric — *N of 39 distinct template bodies and 33 distinct decorator bodies in the suite
lower on beam*.

**Risk:** a second lowering of every comptime construct, diverging from the erlang one. Mitigated
by the fallback (a divergence is a fallback, not a wrong answer) and by the `COMPTIME REPLY`
snapshots (the reply is the assertion; the listing is not).

---

## Stage 4 — not proposed

`.beam` written by Zig ([option B](./options.md#2-option-b--emit-beam-bytecode-from-zig)) buys
≈ 0.4 ms per template declaration over stage 3 and costs a per-OTP-release opcode table and an
unvalidated encoder. A non-`erl` BEAM VM ([option E](./options.md#5-option-e--a-beam-vm-that-is-not-erl))
is discarded twice over. Both are recorded in [`history.md`](./history.md) so the next reader does
not re-derive them.

---

## What happens to `persistent_erl.zig`

**Kept, and narrowed by one thing only: it stops being asked to compile.**

| Today | After stage 2 | After stage 3 |
|---|---|---|
| spawns `erl`, owns the frame protocol, the group leader, the 16 MiB cap, the hashed build dir, the 10 s budget, crash recovery | unchanged, **plus** a resident prelude in the same hashed directory and two commands | cmd 2 passes `[from_asm]` |
| cmd 1 = `compile:file` + `code:load_binary` + `safe_call` per evaluation | cmd 1 kept for the fallback and the tests; cmd 2 compiles+loads once, cmd 3 calls | the same |
| never purges a loaded module | **the pressure is gone** — one module per declaration instead of one per call site; `code:purge/1` on reload of a changed declaration becomes worth adding, and closes the unowned residual front 16 recorded | the same |

Nothing in the hygiene work of `specs/1.0.4-beta/09-hygiene/` step 1 is undone
([`history.md`](./history.md#what-has-been-fixed-since-and-must-not-be-undone)).

## What happens to `.botopinkbuild/tmp/{template,decorator}/*.erl`

They stay — the `.erl` (later `.S`) still has to reach OTP as a file, because there is no supported
in-memory `from_asm` entry point ([E9](./evidence.md#e9--from_asm-in-memory-is-not-a-documented-path))
and `compile:file` is what the server calls. What changes is **how many and how often**:

| | today | after stage 2 |
|---|---|---|
| files per build | one per call site (`erika-linq`: 18) | one per template/decorator **declaration** (`erika-linq`: 1) |
| accumulation | unbounded — `repository/erika` holds 52 where a build writes 12 ([E13](./evidence.md#e13--what-is-left-on-disk)) | bounded by the number of declarations in the project |
| deletion | never | still never — but now a fixed, small, content-addressed set, which is a cache rather than litter. Add them to `botopink clean` (`cli/clean.zig`) in the same stage |

---

## Blast radius

| What moves | Size | When |
|---|---:|---|
| snapshots recording the generated Erlang (`----- COMPTIME ERLANG`) | **48** of 2 529 — 7 each in `codegen/{beam,commonJS,erlang,wasm}`, 5 each in `comptime/{beam,erlang,node,wasm}` ([E12](./evidence.md#e12--blast-radius-on-the-snapshots)) | stage 1 (shrink), stage 3 (become `.S`) |
| snapshots recording the reply (`----- COMPTIME REPLY`) | 48 — **must stay byte-identical at every stage** | never |
| snapshots recording Zig-folded comptime values (`----- COMPTIME VALUES`) | 56 — **not this front's**, `comptime/eval.zig` is untouched | never |
| compiler source | stage 1 ≈ 250 LOC · stage 2 ≈ 500 LOC · stage 3 ≈ 1 500–2 500 LOC | per stage |
| libraries | **no `.bp` change** — erika, jhonstart, onze, rakun and `libs/std` see a faster compiler and the same replies | — |
| `AGENTS.md` | `comptime/AGENTS.md`, `comptime/runtime/AGENTS.md`, `codegen/AGENTS.md`, `codegen/beam/AGENTS.md`, `meta:architecture.md` (its "O que roda onde" table names `.erl` per evaluation) | per stage |

**Libraries that feel it most**, by evaluations per build
([E2](./evidence.md#e2), [E13](./evidence.md#e13--what-is-left-on-disk)):

| Library | evaluations | erl-side today | after stage 2 |
|---|---:|---:|---:|
| `erika/examples/erika-linq` | 18 templates | ≈ 960 ms | ≈ 49 ms |
| `erika` | 12 templates | ≈ 640 ms | ≈ 48 ms |
| `rakun/examples/rakun` | 16 decorators (10 distinct) | ≈ 130 ms | ≈ 50 ms |
| `jhonstart` | 10 templates | — (not measured; its examples are known-broken, [`../13-ecosystem-migration/`](../13-ecosystem-migration/README.md)) | — |
| the compiler's own suite | 57 + 68 modules | 770 ms of `compile:file` (443.6 + 326.5) | ≈ 470 ms (39 + 33 distinct bodies) |

## Estimate

| Stage | Work |
|---|---|
| 0 measurement script | 0.5 day |
| 1 resident prelude | 1.5–2 days |
| 2 capture as a term, compile once per declaration | 3–4 days (the ETF encoder is most of it) |
| 3 `.S` from `beam_asm.zig`, with a per-declaration fallback | **2–4 weeks**, and it is the only stage whose size is a guess — the untyped lowering mode is 20 decisions in `erlang.zig` with no counterpart to copy |

Stages 0–2 are the recommendation. Stage 3 is the maintainer's literal request and should be
decided **after** stage 2's numbers are in, because stage 2 changes what it is worth.
