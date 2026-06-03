# compiler-core/src/parser

> Path: `modules/compiler-core/src/parser/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Parser tests. The parser implementation itself is at `../parser.zig`.

## Tree

```text
parser/
├── AGENTS.md      ← you are here
├── docs.md        ← parser strategy, helpers, error policy
├── examples.md    ← `.bp` declarations / expressions / statements
├── tests.zig      ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/         ← parser tests, split by feature
    ├── helpers.zig       ← shared harness (`assertParser`/`expectParseError`/…)
    ├── imports.zig       ← import/activate/delegate/star declarations
    ├── declarations.zig  ← struct/record/enum/interface/implement, val/pub/fn
    ├── expressions.zig   ← operator/lambda/array/tuple/case/builtin/control-flow
    ├── destructuring.zig ← destructure/shorthand/assign
    └── errors.zig        ← parse errors & cross-stage error-message units
```

## Testing pattern

```zig
test "import decl" {
    try assertParser(std.testing.allocator, @src(), "import {std.List as L, X*};");
}
```

- Snapshot path: `../../snapshots/parser/<slug>.snap.md`
- Error tests: `expectParseError(source, "expected message")`

## Notes

- AST nodes are `union(enum)`; always call `deinit(alloc)` on heap-allocated
  branches.
- `Parser.init(tokens)` does **not** store an allocator; parse methods receive
  `alloc: std.mem.Allocator`.
