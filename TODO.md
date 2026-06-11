# TODO — extension-discipline  (v0.beta.12)

> Task branch `task/extension-discipline` · spec
> [`tasks/v0.beta.12/specs/extension-discipline.md`](../../tasks/v0.beta.12/specs/extension-discipline.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.**

Two rules:
- **A.** `extend Type { … }` without an interface is rejected; methods are added only via `implement <Interface> for <Type>`.
- **B.** A locally-declared `implement` is auto-applied in its module — `Name*` is only for imports; bare local `Name*;` is an error.

## F0 — reject contract-free `extend` (Rule A)
- [x] infer `.extend` path → `extendRequiresInterface(target)` instead of registering an entry
- [x] error.zig: add `extendRequiresInterface(typeName)` with `implement` fix hint
- [x] parser keeps accepting `extend` (unchanged) so the error has a source location
- [x] drop `ExtEntry.isExtend` (no path builds it; nothing read it) — env.zig + infer.zig

## F1 — auto-apply local implements; restrict `*` to imports (Rule B)
- [x] confirmed: `extensions.put` only runs in `registerExtensions` over the module's own
      `program.decls` — **every `ExtEntry` is local**; imports never register. So the "local vs
      imported" flag the spec hedged on is unnecessary; the crux collapsed as the spec Note predicted.
- [x] dispatch Rule 2: every entry is auto-applied (dropped `isActivated`/`inactiveSym`/Rule 3)
- [x] activation validation: bare local `Name*;` → `redundantActivation`; non-extension → `notAnExtension`; `import { Name* }` stays valid
- [x] error.zig: add `redundantActivation(name)`

## F2 — codegen + test migration
- [x] codegen extend-emit branches left untouched — unreachable post-infer (extend never type-checks);
      removing them would force `else`/`unreachable` on the decl switches for no behavioral gain
- [x] migrate `js_dispatch` extension test to no-`*` form; delete the `extend` dispatch test
- [x] migrate infer tests: drop `*;` from local-impl tests; add 2 negative tests (extend-no-iface, redundant `*`); ambiguity test now two local impls
- [x] helpers.zig: render the two new error kinds; regenerate snapshots; remove orphans
- [x] AGENTS.md/docs: none reference extend/activation (grep clean) — nothing to sync

## F3 — library sweep
- [x] reworded `libs/onze/src/onze.bp:68` comment; `grep -rn '\bextend\b' libs/` clean

## Done gate
- [x] `zig build && zig build test` green; new test scenarios pass
