# backends-parity-erlang — emit `-compile({no_auto_import,…}).` for shadowed BIFs

**Slug**: backends-parity-erlang
**Depends on**: ci-pipelines-green (the erlang allow_fail rows in each
sibling lib's test.yml were authored there). No code-level dependency
on ci-pipelines-green-tail.
**Files**:
  - `repository/botopink-lang/modules/compiler-core/src/codegen/erlang.zig`
    (emit `-compile({no_auto_import,[…]}).` for any user function
    whose name matches an auto-imported BIF)
  - `repository/botopink-lang/modules/compiler-core/src/codegen/beam_asm.zig`
    (parity — the BEAM Assembly backend reads the same fixtures)
  - regenerate every `repository/botopink-lang/modules/compiler-core/
    snapshots/codegen/erlang/erlang/*.snap.md` that gains the prelude
    directive (audit + regen)
  - regenerate every `repository/botopink-lang/modules/compiler-core/
    snapshots/codegen/beam_asm/beam/*.snap.md` same shape
  - `repository/erika/.github/workflows/test.yml` (drop the
    `allow_fail: true` on erlang + beam axes)
  - `repository/jhonstart/.github/workflows/test.yml` (same)
  - `repository/onze/.github/workflows/test.yml` (same)
  - `repository/rakun/.github/workflows/test.yml` (same)
**Touches docs**: `tasks/v0.beta.20/status.md`
**Status**: pending

## Problem

The codegen test fixture `if_with_else_branch` is one example, not the
only one. Several botopink test programs define functions whose names
clash with Erlang's auto-imported BIFs:

- `abs/1` (the residual that ci-pipelines-green's investigation
  exposed)
- `length/1`, `size/1`, `element/2`, `tuple_size/1`, … (every BIF
  listed in https://www.erlang.org/doc/man/erlang.html#auto-imported-bifs)

Newer Erlang/erlc versions (OTP 28+, possibly OTP 27 depending on the
specific BIF) treat the diagnostic
`ambiguous call of overridden pre Erlang/OTP R14 auto-imported BIF`
as a **compile error**, not a warning. The botopink-lang `runtime.zig`
chain returns empty RUN LOG on `erlc` failure → snapshot mismatch.

ci-pipelines-green pinned OTP 28 (where the diagnostic is a warning
for at least `abs/1`), but the moment another fixture introduces a
function whose shadowing is upgraded to an error, the residual
reappears. The proper fix is in the **codegen**, not in the OTP pin:

> Emit `-compile({no_auto_import,[abs/1,length/1,…]}).` in the
> generated module's prelude for every function whose name + arity
> matches an auto-imported BIF.

This is exactly the directive erlc's diagnostic message recommends:

```
use erlang:abs/1 or "-compile({no_auto_import,[abs/1]}).\" to resolve
name clash
```

The lib workflows (erika/jhonstart/onze/rakun) currently mark erlang
+ beam axes `allow_fail: true` so the workflow conclusion can be
`success`. Once the codegen emits the directive and snapshots are
regenerated, those allow_fail rows go away.

## Goal

After this spec lands:

- `repository/botopink-lang/.../codegen/erlang.zig` emits the
  `-compile({no_auto_import,…}).` directive in the generated module
  prelude whenever any user function in the module shadows an
  auto-imported BIF.
- `codegen/beam_asm.zig` does the same (the BEAM Assembly backend
  shares the same erlc compile step).
- Every regenerated snapshot under
  `snapshots/codegen/{erlang,beam_asm}/` carries the new prelude line
  where applicable.
- All four sibling lib `test.yml` files drop their `allow_fail: true`
  rows for erlang + beam axes; the workflow conclusion is `success`
  on every push.
- bot-lang's own `test` workflow goes green on the regenerated
  snapshots without re-introducing any allow_fail.

## Solution

### F1 — extend `codegen/erlang.zig` with a BIF auto-import audit

The audit table (build it once, comptime if possible — the BIF list
is fixed per OTP release):

```
abs/1, adler32/1, adler32/2, adler32_combine/3, alias/0, alias/1,
apply/2, apply/3, atom_to_binary/1, atom_to_binary/2, atom_to_list/1,
binary_part/2, binary_part/3, binary_to_atom/1, binary_to_atom/2,
…
element/2, error/1, error/2, error/3, exit/1, exit/2, float/1,
float_to_binary/1, float_to_binary/2, float_to_list/1,
float_to_list/2, garbage_collect/0, garbage_collect/1,
garbage_collect/2, get/0, get/1, get_keys/0, get_keys/1, group_leader/0,
group_leader/2, halt/0, halt/1, halt/2, hd/1, integer_to_binary/1,
integer_to_binary/2, integer_to_list/1, integer_to_list/2,
iolist_size/1, iolist_to_binary/1, iolist_to_iovec/1, is_alive/0,
is_atom/1, is_binary/1, is_bitstring/1, is_boolean/1, is_float/1,
is_function/1, is_function/2, is_integer/1, is_list/1, is_map/1,
is_map_key/2, is_number/1, is_pid/1, is_port/1, is_process_alive/1,
is_record/2, is_record/3, is_reference/1, is_tuple/1, length/1,
link/1, list_to_atom/1, list_to_binary/1, list_to_bitstring/1,
list_to_existing_atom/1, list_to_float/1, list_to_integer/1,
list_to_integer/2, list_to_pid/1, list_to_port/1, list_to_ref/1,
list_to_tuple/1, make_ref/0, map_get/2, map_size/1, max/2,
memory/0, memory/1, min/2, monitor/2, monitor/3, monitor_node/2,
monitor_node/3, node/0, node/1, nodes/0, nodes/1, nodes/2,
now/0, open_port/2, pid_to_list/1, port_close/1, port_command/2,
port_command/3, port_connect/2, port_control/3, port_info/1,
port_info/2, port_to_list/1, ports/0, pre_loaded/0, process_flag/2,
process_flag/3, process_info/1, process_info/2, processes/0,
purge_module/1, put/2, ref_to_list/1, register/2, registered/0,
round/1, self/0, send/2, send/3, send_after/3, send_after/4,
setelement/3, size/1, spawn/1, spawn/2, spawn/3, spawn/4,
spawn_link/1, spawn_link/2, spawn_link/3, spawn_link/4,
spawn_monitor/1, spawn_monitor/2, spawn_monitor/3, spawn_monitor/4,
spawn_opt/2, spawn_opt/3, spawn_opt/4, spawn_opt/5, spawn_request/1,
spawn_request/2, spawn_request/3, spawn_request/4, spawn_request/5,
spawn_request_abandon/1, split_binary/2, start_timer/3, start_timer/4,
statistics/1, term_to_binary/1, term_to_binary/2, term_to_iovec/1,
term_to_iovec/2, throw/1, time/0, tl/1, trunc/1, tuple_size/1,
tuple_to_list/1, unalias/1, unique_integer/0, unique_integer/1,
unlink/1, unregister/1, whereis/1
```

(Subject to OTP-version drift. Source the list from
`erlang:get_module_info(erlang, exports)` at codegen comptime, or
hardcode and add a single unit test that compares against the runtime
list and warns on drift.)

For each module that codegen emits:
1. Collect the set of `{FunctionName, Arity}` declared in the source.
2. Intersect with the BIF table above.
3. If the intersection is non-empty, prepend
   `-compile({no_auto_import,[abs/1, length/1, ...]}).` to the module
   prelude (after `-module(...).` and before `-export([...]).`).

### F2 — `codegen/beam_asm.zig` parity

The BEAM Assembly backend goes through the same `erlc +from_asm`
pipeline. Audit the BEAM ASM emitter for the same shadowing risk; if
the same diagnostic fires (it shouldn't, since BEAM ASM compiles the
already-disambiguated assembly), add a parity check. If not, add a
comment pointing at this spec so a future reader understands the
asymmetry.

### F3 — regenerate snapshots

After F1 + F2, every snapshot whose ERLANG section now carries the
`-compile({no_auto_import,…}).` line needs the recorded snapshot
updated:

```bash
cd repository/botopink-lang
# Walk snapshots/codegen/erlang/erlang and snapshots/codegen/beam_asm/beam
# Run `zig build test` once; for every test that writes `.snap.md.new`,
# `mv` the .new over the recorded file.
for f in modules/compiler-core/snapshots/codegen/erlang/erlang/*.snap.md.new; do
  mv "$f" "${f%.new}"
done
for f in modules/compiler-core/snapshots/codegen/beam_asm/beam/*.snap.md.new; do
  mv "$f" "${f%.new}"
done
```

Commit the regen separately from the codegen change for clean review.

### F4 — drop `allow_fail` from sibling lib workflows

In each of `repository/{erika,jhonstart,onze,rakun}/.github/workflows/test.yml`:

```yaml
- { runner: ubuntu-22.04, target: erlang,   allow_fail: true  }
- { runner: macos-14,     target: erlang,   allow_fail: true  }
```

→

```yaml
- { runner: ubuntu-22.04, target: erlang,   allow_fail: false }
- { runner: macos-14,     target: erlang,   allow_fail: false }
```

Same for beam axes (rakun + onze have explicit beam rows; erika has
beam too).

Push each lib's commit; verify the workflow goes green.

### F5 — meta pointer bump + status.md

One meta commit advances all four sibling lib pointers + bot-lang
(carrying F1–F3) + flips this set's row in `tasks/v0.beta.20/status.md`
to `done`.

## Steps

1. **F1** — `codegen/erlang.zig` change in bot-lang; gate ran in the
   pre-commit hook (zig build test will produce regen `.new` files;
   commit *together* with F3 to avoid a transitional red).
2. **F2** — `codegen/beam_asm.zig` parity check in the same bot-lang
   commit.
3. **F3** — snapshot regen committed as a second bot-lang commit
   (separate review surface; pure data change).
4. **F4** — four sibling lib commits, one per repo, dropping the
   allow_fail rows.
5. **F5** — one meta commit bumping 5 submodule pointers + closing
   row in `status.md`.

## Test scenarios

- After F1+F3 + F5 land: `gh run list --repo botopink/botopink-lang
  --workflow test --branch feat --limit 1` shows `success`; the
  `codegen/erlang/erlang/if_with_else_branch.snap.md` and
  `codegen/erlang/erlang/*.snap.md` files all carry the new prelude
  line where their source code shadows a BIF.
- After F4 lands on each lib: `gh run list --repo botopink/<lib>
  --workflow test --branch feat --limit 1` shows `success`, with the
  erlang + beam axes contributing green.

## Notes

- **OTP version is now decoupled from this spec.** Once the codegen
  emits the directive, the residual is closed regardless of how strict
  the host's `erlc` is. ci-pipelines-green-tail's F0 still verifies the
  current OTP 28 pin holds; this spec makes the codegen
  forward-compatible to OTP 29, 30, … .
- **The auto-imported BIF list drifts across OTP releases.** When
  generating the table, prefer comptime introspection
  (`erlang:get_module_info(erlang, exports)`) over a hardcoded list —
  the latter rots silently.
- **Don't emit the directive unconditionally.** Modules with no
  shadowing functions should not carry the line — keeps the
  generated code minimal and the snapshot diffs small.

## Exit gate

This spec is **done** when:

- `repository/botopink-lang` `feat` carries F1+F2 (codegen emit) +
  F3 (snapshot regen) without any allow_fail re-introduction.
- Each of `repository/{erika,jhonstart,onze,rakun}` `feat` carries
  F4 (allow_fail rows removed for erlang + beam axes).
- meta `feat` carries F5 (pointer bumps + status.md row → `done`).
- Every affected `gh run list` reports `success` on the latest push.
