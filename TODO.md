# TODO — generic-loader-binding  (keystone · Wave 1)

> Task branch `task/generic-loader-binding` · spec
> [`tasks/v0.beta.8/specs/generic-loader-binding.md`](../../tasks/v0.beta.8/specs/generic-loader-binding.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** Start now. Unblocks the two sub-language DSLs
> (`jhonstart-html`, `erika`) — land this first.
>
> Generic core work, std-exempt, **no lib name** in `compiler-core`. ⚠ Touches
> `comptime/infer.zig` — same file as `stdlib-backends-parity` (different regions;
> the later merge resolves the overlap).

## F0 — pin the two gaps
- [ ] Confirm baseline: bare value/fn import already binds + runs (`examples/erika-linq`).
- [ ] Pin the two failing paths: a bare template-fn import, and a `Lib.member(...)`
      namespace call on a disk lib (`resolveImports` in `comptime.zig` + import case
      in `infer.zig` + namespace emission in codegen). Add a failing test/example each.

## F1 — bind bare template fns
- [ ] A bare imported template fn (`comptime _: @Expr<…>`) rehydrates via
      `registerImportedTemplateFn` so `name "…"` / `name """…"""` expands in the
      importing module (disk-loader mirror of the same-project path + `registerImportedDecorator`).

## F2 — emit the disk lib's namespace object
- [ ] `Lib.member(...)` for a disk lib resolves at runtime: codegen emits the lib's
      namespace object in the consumer output (today only bare symbols emit, so
      `erika.of` is `undefined`). Parity with the bare form.

## F3 — close the recorded consumers
- [ ] `erika "…"` after `import {erika} from "erika"` binds + expands (re-enable the
      erika SQL scenario — F1 of erika).
- [ ] Path ready for jhonstart's `html "…"` (consumed by jhonstart-html).

## Done gate
- [ ] bare value/fn (baseline) + bare template-fn + `Lib.member(...)` all run from a disk lib.
- [ ] `grep -riE "rakun|jhonstart|erika" modules/compiler-core/src` returns nothing (std exempt).
- [ ] `comptime/AGENTS.md` updated; `zig build && zig build test` green.
