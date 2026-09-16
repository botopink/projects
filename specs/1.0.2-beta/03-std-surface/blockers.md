# The two blockers

`libs/std` has six defects, but five of them are invisible until one is fixed, and four modules
never reach their first test until a second one is. Both blockers have their fix outside
`libs/std` — see [Ownership](./README.md#ownership).

---

## 6a — the comptime type-manipulation intercept claims `pick` before any module can

`comptime/infer.zig:6901` runs `tryResolveTypeManipulationCall` on the **bare callee name**, with no
`env.lookup(call.callee)` guard and no receiver guard:

```zig
6901:  if (try tryResolveTypeManipulationCall(env, call.callee, typedArgs, typedTrailing, loc)) |result| {
```

`tryResolveTypeManipulationCall` (`:4041-4073`) matches five names and dispatches four of them —
`mergeRecords` (`:4059`), `partial` (`:4062`), `omit` (`:4065`), `pick` (`:4068`). `mapFields` falls
through to `return null` (`:4071-4072`, "takes a lambda transform — not yet implemented"). So
**any** call named `pick`/`omit`/`partial`/`mergeRecords` anywhere in any module is intercepted,
including `libs/std/src/random.bp:141`, which calls its own
`pub fn pick<T>(xs: Array<T>) -> ?T` (`random.bp:73`). The error text — `pick expects a type and
field names` — comes from `resolvePick` (`:4242`, `:4245`).

The correct pattern is eleven lines below, in the `result` namespace: `infer.zig:6911` gates on
`env.lookup(recvName) == null`, and `:6919` repeats it for associated fns, precisely so a value
binding of the same name keeps normal dispatch.

`pick` is documented public std surface (`libs/std/AGENTS.md:47`), so renaming it is an API break,
not a fix. **Fix in the compiler:** guard `:6901` with `env.lookup(call.callee) == null` (and
`call.receiver == null`), so a user declaration of any of the five names wins.

### What compiles once it is freed

With `random.bp`'s `pick` renamed in a scratch copy, the 23-module tree checks clean in 113 ms and
`botopink test` reaches 131 tests:

| | before 6a | after 6a alone |
|---|---|---|
| `botopink check` | fails at `random:141:13` | clean, 24 modules |
| `botopink test` | not reached | 131 discovered · 113 pass · 18 fail · exit 1 |
| modules that crash before their first test | — | `env`, `os`, `process`, `random` (4) |
| failing assertions | — | 18, **all** `Cannot find module './gleam_stdlib.mjs'` |

So the whole remaining surface of this front is two numbers: **18 assertions**, every one of them
[`node-externals.md`](./node-externals.md)'s four broken declarations, and **4 modules** that never
start, all of them 6d below.

### It closes two review rows

This is the same defect spec 06 report `codegen-comptime-misc` records as "the `pick`/`omit`/
`partial`/`mergeRecords` builtin intercept shadowing user fns", and report `codegen-wat-narrowing`
as "user `pick` vs the builtin". Fixing it here closes both.

**Acceptance:**
- [ ] A module that declares `pick`/`omit`/`partial`/`mergeRecords`/`mapFields` calls its own
- [ ] `mergeRecords(A, B)`, `partial(T)`, `omit(T, n)`, `pick(T, ns)` still resolve where no user
      declaration shadows them (they do today with no `.bp` declaration anywhere)
- [ ] `botopink check` in `libs/std` is clean

---

## 6d — four std modules emit JavaScript that does not parse

Independent of the `./gleam_stdlib.mjs` row, and only visible once 6a lets the tests run. `env`,
`os`, `process` and `random` abort with a Node `SyntaxError` before their first test, because a
template-form `@External.Node` on an imported `declare fn` is lowered as a destructuring import
whose *key* is the template:

```javascript
env.js:71      const { (process.argv.slice(2)): args } = require("");
os.js:55       const { require('os').hostname(): hostname } = require("");
process.js:66  const { process.cwd(): cwd } = require("");
random.js:66   const { require('./sidecars/random.mjs').seededFloat(): seededFloat } = require("");
```

Note the empty module specifier — a 1-arg (`module == ""`) annotation reaches the import emitter,
which has nothing to put in `require(…)`. 31 tests are lost this way (`env` 5, `os` 7, `process` 4,
`random` 14, minus the ones already counted).

This is spec 06 report `codegen-comptime-misc`'s "dangling import for template-only symbols" with a
reproduction. **Fix in the compiler:** `commonJS.zig` must not emit an import binding for a symbol
whose `@External.Node` is a template or a 1-arg native name; those render at the call site.

`random.js:66` is worth reading twice: the sidecar it names, `./sidecars/random.mjs`, **does** exist
and **is** shipped (`shipMjsSidecars` probes `<lib>/src/sidecars/<base>`). The module is broken by
the import emitter alone, not by a missing file — which is the cleanest demonstration that this
defect and the `gleam_stdlib.mjs` one are unrelated.

**Acceptance:**
- [ ] `env`, `os`, `process` and `random` run their tests
- [ ] A `declare fn` whose `@External.Node` is a template or 1-arg form emits no `require(…)`
- [ ] A codegen test covers each of the two shapes
