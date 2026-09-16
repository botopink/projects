# Spec 01 — Comptime untyped dispatch and the library gate

**Version:** 1.0.2-beta
**Priority:** critical — every library that uses a template is uncompilable, and no gate catches it
**Depends on:** none

---

## Objective

A template or decorator body may call a primitive's `default fn` (`split`, `join`, `slice`,
`indexOf`, `append`, `trim`, …) and the module it runs in must define those functions. The
library suites (`zig build test-libs`, the sibling repos' `botopink test`) run in the same gate
as the compiler suite, so this class of break cannot land unnoticed again.

Paths are relative to `repository/botopink-lang/` unless stated otherwise.

## Current state

`botopink test` in `repository/jhonstart` fails: 5 modules compile, 1 does not.

```
{undefined_function,{split,2}} {undefined_function,{slice,3}}
{undefined_function,{join,2}}  {undefined_function,{indexOf,2}}
{undefined_function,{append,2}} {undefined_function,{trim,1}}
   … at html_test:4:16
```

`html_test.bp:4` is `val page = html """<div><p>hi</p></div>""";` — the `html` template body
(`repository/jhonstart/src/html.bp`) runs on the persistent `erl` at compile time, through
`comptime/template_eval.zig` → `codegen/erlang.zig` `emitComptimeModule`.

**Not a regression of the 1.0.1-beta waves.** The same failure reproduces with compilers built
from `beb19e9` (before any of that work) and from `788f3d3` (before the erlang backend wave).

**Cause.** A comptime module is lowered in `untyped` mode (`erlang.zig` `em.untyped`,
`ComptimeModule` != null), so a method call has no receiver type. The regular path records a
reached interface default in `iface_instance_defaults` and `instanceDefaultForms` emits its body;
in untyped mode nothing is recorded, so `t.text().split("\n")` lowers to a local call `split/2`
that the module never defines. `erl_lint` rejects the module and the whole evaluation fails.

## Steps

### Step 1 — Primitive `default fn`s reachable from a comptime body

Decide how an untyped receiver dispatches, and make the comptime module carry what it calls:

- emit the `default fn` bodies a comptime body reaches (the untyped analogue of
  `instanceDefaultForms`), or
- lower a primitive method in untyped mode to a runtime-dispatching helper next to
  `'__bp_add'`/`'__bp_len'` (`comptime_helper_forms`), which already solve the same problem for
  `+` and `.len`.

**Acceptance:**
- [ ] A template body calling `split`/`join`/`slice`/`indexOf`/`append`/`trim` on a string or an
      array evaluates
- [ ] `repository/jhonstart` `botopink test` passes
- [ ] A regression test in `compiler-core` (a template body that calls a primitive `default fn`),
      so this does not depend on a sibling repo being checked out

### Step 2 — A failing test module must say why

`botopink test` prints `error: 1 module(s) failed to compile — run 'botopink check' for
diagnostics`, but `check` only loads `src/` (it passes), so the diagnostic is unreachable: it was
only visible by copying `test/html_test.bp` into `src/` by hand. The test command must render the
diagnostic it already has.

**Acceptance:**
- [ ] `botopink test` prints the located diagnostic of the module that failed
- [ ] `botopink check` covers `test/` too, or its message stops pointing at a command that does not
      look there

### Step 3 — The gate must include the libraries

`zig build test` (1575 tests) never compiles a `.bp` library, so a compiler change can break every
library and stay green. `zig build test-libs` exists and is not part of any wave's gate; the
sibling repos' pre-commit hooks run `botopink test` and are the only thing that noticed.

**Acceptance:**
- [ ] The gate documented in `AGENTS.md` (and used by every task) is
      `zig build test && zig build test-libs`
- [ ] `test-libs` covers `libs/std` and the sibling libraries that are checked out, and says which
      it skipped
- [ ] CI runs it on the same matrix as `test`

## Notes

- The sibling pre-commit hook blocks any commit in `repository/jhonstart` while this is open —
  including unrelated maintenance (an ignore rule for `out/` is waiting on it).
- Related: spec 05 of 1.0.1-beta lists the hook installation and `test-libs` wiring problems
  (5.2, 5.4, 5.5).
