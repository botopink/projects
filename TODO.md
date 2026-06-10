# TODO — generic-loader-binding  (keystone · Wave 1)

> Task branch `task/generic-loader-binding` · spec
> [`tasks/v0.beta.8/specs/generic-loader-binding.md`](../../tasks/v0.beta.8/specs/generic-loader-binding.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** Start now. Unblocks the two sub-language DSLs
> (`jhonstart-html`, `erika`) — land this first.
>
> Generic core work, std-exempt, **no lib name** in `compiler-core`.

## F0 — pin the two gaps  ✅
- [x] Confirmed baseline: bare value/fn import binds + runs (`examples/erika-linq`, 4 green).
- [x] Re-pinned empirically against the current `feat`:
      - **bare template fn already binds** — `import {erika}…; erika "…"` *expands*
        (the disk loader's `registerExports` → `templateRegistry` → `registerImportedTemplateFn`
        path is live). It only failed on `unbound 'of'` because erika's expansion
        emits **unqualified** `of(...)`, which the consumer must also import — an
        erika-design choice, not a core gap. So F1 is **already closed** in core.
      - **namespace member does NOT codegen** — `import {erika}…; erika.of(...)`
        type-checks but runs as `erika is not defined`: the disk lib's namespace
        object is never emitted in the consumer. This was the one real gap.

## F1 — bind bare template fns  ✅ (already worked)
- [x] A bare imported template fn rehydrates via `registerImportedTemplateFn` so
      `name "…"` / `name """…"""` expands in the importing module. Verified live;
      no core change needed (the disk loader already mirrors the same-project path).

## F2 — emit the disk lib's namespace object  ✅
- [x] `Lib.member(...)` for a disk lib resolves at runtime. Fix is codegen-only
      (`codegen/commonJS.zig` `emitUse`): when the import names the lib itself
      (`import {Lib} from "Lib"`) and that name has **no emitted symbol** of its own
      (a comptime template fn → no cross-module export home), bind the lib's whole
      module object — `const Lib = require("./<pkg>/<mod>.js");` (or
      `Object.assign({}, …)` across the lib's modules) — so `Lib.member(...)`
      resolves, parity with the destructured bare form. Pub fns are always
      exported, so fn members link. Generic: the core names no specific lib.
      (No `comptime.zig`/`infer.zig`/`template_eval.zig` change was needed — the
      spec's file list pre-dated the empirical re-pin; the gap was in emission.)

## F3 — close the recorded consumers  ✅
- [x] `erika "…"` after `import {of, erika} from "erika"` binds + expands + runs
      (erika emits unqualified `of(...)`, so the consumer imports `of` too).
- [x] Path ready for jhonstart's `html "…"` (same bare template-fn + namespace shapes).
- [x] New runnable example `examples/generic-loader-binding` exercises all three
      forms (bare value, bare template fn, namespace member) — 3 green tests.

## Done gate  ✅
- [x] bare value/fn (baseline) + bare template-fn + `Lib.member(...)` all run from a disk lib.
- [x] `grep -riE "rakun|jhonstart|erika" modules/compiler-core/src` returns nothing (std exempt).
- [x] `codegen/AGENTS.md` + `codegen/tests/AGENTS.md` + `examples/AGENTS.md` updated;
      `zig build && zig build test` green.
