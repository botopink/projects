# snapshots/codegen

> Path: `modules/compiler-core/snapshots/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Snapshots for codegen output and codegen-time error rendering.

## Tree

```text
codegen/
├── AGENTS.md
├── erlang/erlang/         ← Erlang outputs   (164 .snap.md)
├── node/commonJS/         ← CommonJS outputs (164 .snap.md)
├── beam/beam/             ← BEAM assembly    (164 .snap.md)
├── wasm/wasm/             ← WASM text        (164 .snap.md)
└── errors/                ← codegen-time error rendering
    ├── erlang/erlang/     ← (1 .snap.md)
    └── node/commonJS/     ← (1 .snap.md)
```

Each scenario in `codegen/tests.zig` emits one snapshot per target, so keep
file names in sync across `erlang/erlang/`, `node/commonJS/`, `beam/beam/`, and
`wasm/wasm/` for target-agnostic scenarios.
