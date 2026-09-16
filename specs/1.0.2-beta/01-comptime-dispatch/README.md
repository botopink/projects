# Front 01 — comptime dispatch

**Priority:** critical — four of six libraries are uncompilable on this one defect, and no gate catches it
**Depends on:** none
**Owns:** `codegen/erlang.zig` (the `untyped` path only) · `comptime/template_eval.zig` ·
`comptime/decorator_eval.zig` · `snapshots/comptime/**` (1009) · the fixtures it adds in
`codegen/tests/comptime_module.zig` and `codegen/tests/features.zig`
**Does not touch:** `codegen/erlang.zig`'s typed path and `codegen/beam/**`
([`../05-erlang/`](../05-erlang/README.md)), `codegen/beam_asm.zig` ([`../04-beam/`](../04-beam/README.md)),
`libs/std/**` ([`../03-std-surface/`](../03-std-surface/README.md)), `modules/compiler-cli/**`
([`../02-cli-gate/`](../02-cli-gate/README.md)). Step 3 needs `comptime/infer.zig`, which
[`../07-checker/`](../07-checker/README.md) owns — see *Notes*.

Paths are relative to `repository/botopink-lang/` unless stated otherwise.

---

## Problem

A template or a decorator body may call a primitive's method (`split`, `join`, `slice`,
`indexOf`, `append`, `trim`, `map`, `push`, …). The Erlang module it is lowered into defines none
of them, so the module does not compile and the host library is dead.

`botopink test` in `repository/jhonstart` fails before any test runs — `test/html_test.bp` does not
compile, and the project-scope fail-fast returns before the healthy modules are executed, so
**0 tests run**. `botopink check` is green, because it loads `src/` only.

```
{undefined_function,{split,2}} {undefined_function,{slice,3}}
{undefined_function,{join,2}}  {undefined_function,{indexOf,2}}
{undefined_function,{append,2}} {undefined_function,{trim,1}}
   … at html_test:4:16
```

`html_test.bp:4` is `val page = html """<div><p>hi</p></div>""";`. This is not a regression: the
same failure reproduces on compilers built from before the 1.0.1-beta waves.

Two further shapes ride on the same untyped path and are in this front because they are the rest of
what stops the libraries compiling: a mutation through a method inside a closure is emitted and
discarded, and a call that omits a trailing default parameter is rejected before the splice that
would fill it can run.

## Current state

Measured against a compiler built from HEAD (the checked-in `zig-out/bin/botopink` was stale — it
predated half the 1.0.1-beta waves, which is itself worth knowing when diagnosing).

| Module | `check` | `test` | Note |
|---|---|---|---|
| emilia | pass | **17/17** | no comptime body; unaffected |
| erika | fail | fail | 13 template tests dead; 16/18 of the fluent layer passes with them removed |
| jhonstart | pass | fail | 8/8 pass once the module compiles (verified by running the emitted JS) |
| onze | pass | fail | 8/8 pass once the module compiles |
| rakun | **fail** | fail | fails before compiling: declares a dependency that exists nowhere |
| `libs/std` | fail | fail | does not compile — [`../03-std-surface/`](../03-std-surface/README.md) |

**No failure is a regression of the 1.0.1-beta waves** — each reproduces byte-identically on the
compiler built from the commit the milestone started at.

Counts, per library and per method, measured by re-linting each repo's generated modules under
`.botopinkbuild/tmp/{template,decorator}/`: **136 bare-call errors across the ecosystem**, plus 14
residual scoping errors that are a different defect (case-arm variable rebinding). Only onze is
fully unblocked by step 1. Full table in
[`primitive-surface.md`](./primitive-surface.md#blast-radius-measured).

The whole surface has **zero** snapshot coverage: not one of the 36 `COMPTIME ERLANG` sections
contains a primitive method call, and there is no decorator section at all.

## Mechanism

In a comptime module `instance_lowerings` is **empty by construction** — `emitComptimeModule`
creates it that way at `codegen/erlang.zig:494` — so the method-call arm of `plainCallNode` misses
at `:3545`, falls through `:3565` (`selfPrimKind`, null), `:3569` (`arrayPrimFallbackNode`, five
names), `:3570` (`toString`) and lands on **`:3571`, a bare local call `m(Recv, args)`**.

The single missing datum is the receiver's `PrimKind` (`comptime/env.zig:283`, five enum values).
Both tables the typed path consults — `prim_erlang_dispatch` and `prim_iface_chain` — are already
built complete inside a comptime module, because `collectPrimErlangDispatch`
(`codegen/erlang.zig:1601`) re-parses the embedded `primitives.bp`.

The full chain for both hosts, why the typed path gets it right, and why threading the caller's map
in is not a fix: [`lowering-path.md`](./lowering-path.md).

## Steps

### Step 1 — Primitive methods reachable from a comptime body

Make the untyped path resolve a primitive method through the same table the typed path uses.
Three options are costed in [`fix-options.md`](./fix-options.md); the recommendation is **(a) a
per-method runtime-dispatch shim generated from the typed table**, whose clause bodies are
`primMethodNode`'s own output, guarded per `PrimKind` the way `'__bp_len'/2` already is. That
reaches the bodied-`default fn` tail (G2) for free and only for what is used, keeps
`libs/std/src/primitives.bp` the single source of truth, and sits behind the `cm.listing` gate so
no green `COMPTIME ERLANG` section moves.

Fix `codegen/erlang.zig:3053` in the same change: it tests `len`/`length` while its typed sibling
at `:3042` also accepts `size`.

**Acceptance:**
- [ ] A template body and a decorator body may call any primitive method the typed path supports —
      the same `prim_erlang_dispatch` entry answers both
- [ ] `split`, `join`, `slice`, `indexOf`, `append`, `trim`, `map`, `at`, `contains`, `reverse`,
      `toUpper`, `startsWith` evaluate from a comptime body on a string or an array receiver
- [ ] A method whose name collides with an auto-imported BIF (`length`, `abs`, `round`, `floor`,
      `ceil`, `size`) dispatches on the receiver instead of calling the BIF
- [ ] An unsupported method raises a located comptime error instead of `{undefined_function,…}`
- [ ] `repository/onze` `botopink test` passes (0 residual errors); `repository/jhonstart` is down
      to its 5 `unbound_var` errors and `repository/erika` to its 9 — both then tracked as the
      case-arm rebinding defect, not here
- [ ] Regression tests in `codegen/tests/comptime_module.zig` (next to `:52`, which pins
      `'__bp_add'`/`'__bp_len'`), covering **both** hosts, so this does not depend on a sibling repo
      being checked out
- [ ] A new fixture adds the first decorator `COMPTIME ERLANG` section (4 files, one per backend
      directory)
- [ ] The 36 existing `COMPTIME ERLANG` sections are unchanged
- [ ] A test asserts `prim_erlang_dispatch` is non-empty, so a parse regression in
      `primitives.bp` cannot silently empty it (`codegen/erlang.zig:1617-1620` is `catch return`)

### Step 2 — Mutation through a method inside a closure

`args.push(x)` inside a closure misses both fold paths: the peephole
(`detectFoldFusion:2424`) rejects a multi-statement closure at `:2464`, and the general threading
(`collectMutations:2592`) counts only `.binding.assign`, so the receiver name is never marked and
the `forEach` degrades to a discarded `lists:foreach`. Two changes are needed — mark the receiver
in the analysis, **and** lower the statement as a rebinding `Args@1 = (Args ++ [X])` so the
group-out expression picks the new version up. The mechanism, the soundness scope, the backend
split and rakun's site are in [`closure-mutation.md`](./closure-mutation.md).

**Acceptance:**
- [ ] A method that mutates its receiver inside a closure threads the value out, like assignment
      does, on erlang — and on beam, or beam is explicitly scoped out here and handed to
      [`../04-beam/`](../04-beam/README.md)
- [ ] The same holds in straight-line function-body position, not only inside a closure
- [ ] `snapshots/codegen/erlang/iterator_fromlist_yields_array_items.snap.md` run log matches
      commonJS's (`1,2,3` instead of `<<>>`)
- [ ] A new fixture covers a multi-statement closure that pushes, on all four backends, plus a
      substring test next to `codegen/tests/comptime_module.zig:72` for the `emitComptimeModule`
      path rakun actually takes
- [ ] rakun's decorators produce the arguments they collect

### Step 3 — Trailing default parameters at the call site

`h1(x)` against `pub fn h1(children: Children, attrs: Array<#(string,string)> = [])` reds with
`'h1' expects 2 argument(s), got 1`. The parser fills `Param.default` for every param list and
`transform.expandTrailingDefaultsWithParams` already produces exactly the injected call node every
backend consumes unchanged — but the transform runs *after* inference, and inference rejects the
call first. Nine arity checks are listed in [`trailing-defaults.md`](./trailing-defaults.md); one of
them (`comptime/infer.zig:2205-2213`, decorator application) already implements the correct rule
`required ≤ args ≤ params.len`. Relax the others to it. Record constructors are the same defect,
not a separate one. No codegen change is needed, confirmed in all four backends.

**Acceptance:**
- [ ] A free fn accepts a call that omits trailing defaults, and the injected arg reaches codegen
      through `transform.zig` unchanged
- [ ] A record constructor accepts a call that omits a defaulted field
- [ ] An instance method with a trailing default expands it too — today it neither errors nor
      expands, which is worse than either
- [ ] A genuinely missing *required* argument still reds, as D3 (`comptime/diagnostics.zig:202-219`)
- [ ] `jhonstart`'s examples and its documented API compile; `element.bp`'s 22 padding `attrs: []`
      can be deleted

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-libs` green — or, until [`../02-cli-gate/`](../02-cli-gate/README.md) lands,
      `botopink test` run by hand in each checked-out sibling, with the residual counts above
      matching
- [ ] `repository/onze` `botopink test` passes; erika and jhonstart are down to their residual
      `unbound_var` counts (9 and 5)
- [ ] The 36 existing `COMPTIME ERLANG` sections byte-identical; new sections only ever new files
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/comptime-dispatch`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Snapshots.** Step 1 changes none, measured: the shims sit behind the `!cm.listing` gate
  (`codegen/erlang.zig:806`) and no existing section contains a primitive method call. Step 1 adds
  4 new files for the first decorator section. Step 2 re-records
  `iterator_fromlist_yields_array_items` on erlang (and beam, if beam is in scope) and adds 4 new
  files. Step 3 can move any snapshot whose fixture omits a trailing default; none does today.
- **Libraries.** onze goes green. erika and jhonstart drop from 36/87 lint errors to 9/5
  `unbound_var` and still do not compile — the case-arm rebinding defect is a different fix and is
  not closed here. rakun stays blocked behind its missing `server` dependency, which the
  library-repos front owns.
- **Runtime failure mode.** A shim's last clause raises at evaluation time on an unexpected
  receiver type, where today the whole module is rejected by `erl_lint`. That is the same trade
  `'__bp_add'`/`'__bp_len'` already make.
- **Other fronts.** Step 3 moves the typed AST; the checker front must re-record after it, or it
  must be sequenced into the checker front. Step 2's beam half belongs to the beam front.

## Notes

- **Step 3 does not fit this front's ownership.** It lands entirely in `comptime/infer.zig`, which
  the checker front owns and which moves the typed AST every backend consumes. The two cannot hold
  that file at once: either the checker front takes step 3 with this analysis, or this front takes
  it and the checker front starts after it lands. The milestone's conflict matrix marks
  comptime-dispatch × checker as "no" for exactly this reason.
- **Step 2's beam half is the beam front's file.** `codegen/beam_asm.zig` has no `collectMutations`,
  no `mutatingExpr` and no fusion; either the beam front fixes it in parallel or this front scopes
  beam out in its acceptance and says so.
- A principled version of step 2 gives `push` a return type (`-> Self`, `libs/std/src/primitives.bp:564-566`)
  or introduces a real receiver-mutation marker, so the analysis stops keying on the hardcoded
  string `"push"` (`codegen/erlang.zig:93`, `codegen/beam_asm.zig:2573`). Both edits are the std
  front's file; the name-driven version is self-contained here.
- The sibling pre-commit hook blocks any commit in `repository/jhonstart` while this is open —
  including unrelated maintenance (an ignore rule for `out/` is waiting on it).
- The failure reads as a count rather than a diagnostic because all four backends discard
  `ComptimeOutput.outcome`. That is rows C1/C5/C6/C7 of
  [`../02-cli-gate/command-contract.md`](../02-cli-gate/command-contract.md), not this front's work;
  the analysis is kept in [`lowering-path.md`](./lowering-path.md#why-the-failure-is-unreadable)
  because it is why `check` is green while `test` is red.
