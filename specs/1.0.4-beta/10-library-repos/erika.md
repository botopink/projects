# erika — the two-parameter `loop` and a removed evaluator (7b, 7c)

> Carried from `1.0.2-beta/12-library-repos/` into 1.0.4-beta. `file:line` and counts were measured at that milestone's
> commit — re-locate by symbol. `F1…F12` and bare front numbers are the old numbering: see
> [`../fronts.md`](../fronts.md#old-front-numbers).

Paths are relative to `repository/`; compiler paths start with `botopink-lang/`.

Two defects, in two places: **7b** is a compiler bug that erika exposes, **7c** is erika's own
documentation.

> **State for 1.0.4-beta.** The 13 dead template tests were the 1.0.2-beta comptime-dispatch
> front's and closed with it. **7b** is handed to [`../02-erlang/`](../02-erlang/README.md) as its
> H3; this front verifies it in erika. **7c is written** — staged in `.tasks/library-repos/erika`
> on `fix/library-repos` together with erika's `BOTOPINK_LANG_REF` default — and cannot be committed
> until 7b lands, because erika's pre-commit hook runs `botopink test`. Line numbers below were
> measured at the 1.0.2-beta commit.

---

## 7b — the two-parameter `loop` drops its accumulator and calls `lists:foreach/2` with arity 2

### Deciding sites

One compiler defect, two deciding lines, both in
`botopink-lang/modules/compiler-core/src/codegen/erlang.zig` — which is also the comptime path
(`botopink-lang/modules/compiler-core/src/comptime/template_eval.zig:24` imports it; there is no separate loop lowering under `comptime/`).

1. **The fold is refused.** `erlang.zig:2547` —
   `if (lp.params.len != 1 or lp.indexRange != null or lp.awaitLoop) return null;`. A two-parameter
   loop never reaches `mutatingFoldExpr` (`:2551`), so the rebinding contract documented at
   `:2517-2523` ("a statement-level `if`/`loop`/`forEach` that reassigns variables bound before it
   is lowered to an expression that *returns* the new values") silently does not apply to it.
2. **The `enumerate` repair misses.** `erlang.zig:3259` —
   `if (lp.indexRange != null and lp.params.len == 2)`. The comment at `:3253-3257` explains that
   `lists:map`/`foreach` pass one element, so two loop parameters cannot be two fun parameters —
   "that raised `function_clause` at every call". But the guard requires an explicit `, 0..` range.
   erika writes `loop (cmpToks) { ct, idx -> }` with no range, so `indexRange == null`, control
   falls to `:3275-3322`, and a **2-arity fun** is handed to `lists:foreach/2`.

### Evidence

Both defects are visible in one generated body —
`erika/.botopinkbuild/tmp/template/template_097e224d193d043e.erl`:

```erlang
105        lists:foreach(fun(Ct, Idx) ->
106            LTok@2 = case (Idx =:= 0) of
...
127        end, CmpToks),
131                failAt(Q, maps:get(span, OpTok@2), …
```

`:105` is the arity-2 fun into `lists:foreach/2`; there is no `{LTok@2, OpTok@2, RTok@2} =
lists:foldl(…)` binding, and `OpTok@2` is read at `:131` outside the closure that bound it.
One-parameter loops in the same module lower correctly (`:14`, `:367`, `:427`, `:516` are all
`lists:foldl`).

### Affected source

- `erika/src/erika.bp:410` — `buildCmp` (`loop (cmpToks) { ct, idx ->`), whose only purpose is to
  mutate `lTok`/`opTok`/`rTok`, read at `:416` and `:418-420`.
- `erika/src/erika.bp:440` — the lexer (`loop (chars) { ch, i ->`), mutating five outer `var`s
  declared at `:435-439`.
- `erika/AGENTS.md:123` documents the two-parameter form as the idiom, so this is a documented API
  that does not work.

The typed backend is the *same code*, so it has the same bug wherever a two-parameter loop appears.

### Fix — in the compiler

Relax `:2547` to accept `params.len == 2` and fold over `lists:enumerate/1` with a `{Item, Idx}`
tuple parameter; relax `:3259` to fire on `params.len == 2` whether or not `indexRange` was
written. Both must go in together — fixing only `:3259` leaves the accumulator lost.

**Ownership.** `codegen/erlang.zig` is shared by [`../02-erlang/`](../02-erlang/README.md) (typed
path) and `comptime-dispatch` (1.0.2-beta, landed) (`untyped` path), and
neither lists this defect. The loop lowering is one code path serving both, so the fix is one change
— hand it to 02-erlang, sequenced against 01 per [`../fronts.md`](../fronts.md) note 2. This front
only verifies it in erika.

### Acceptance

- [ ] `loop (xs) { x, i -> acc = … }` threads `acc` out, like the one-parameter form
- [ ] No `lists:foreach/2` or `lists:map/2` ever receives a fun of arity ≠ 1
- [ ] A compiler-core regression test covers the two-parameter loop on the typed **and** the
      comptime path, so it does not depend on an erika checkout
- [ ] erika's `buildCmp` and its lexer produce their accumulated values

---

## 7c — erika documents a comptime evaluator that no longer exists

### Deciding site

`erika/AGENTS.md:108-148` ("Comptime-eval constraint") describes a **JavaScript** evaluator and
derives every rule in the file from it:

| Line | Claim | Reality |
|---|---|---|
| `:117-118` | anonymous `record {…}` "lower to plain JS object literals"; a named record "would emit `new Token(…)`, undefined in the eval" | bodies run as Erlang; records are maps |
| `:119-121` | "Native-JS ops only: `split`/`join`/`slice`/`map`/`filter`/`append`/`+`/`==`, plus array `.length` (a *property*)" | this list is **the cause of `comptime-dispatch` (1.0.2-beta, landed) step 1** — the comptime module defines only `__bp_add/2`, `__bp_len/2`, `__bp_text/1`, `__bp_json/1` |
| `:125-126` | `string.length()` "needs a JS-property rename" — use `s.split("").length` | `.len`/`.length` lower to `'__bp_len'(X, length)` (`botopink-lang/modules/compiler-core/src/codegen/erlang.zig:406-424`) |
| `:60` | "No arity overloading (the JS backend mangles same-named methods)" | unrelated to the current evaluator |

### Mechanism

The evaluator is the persistent `erl` server: `meta:architecture.md:12-13, 15` ("**Não há runtime
Node, wasm3 ou WAT para comptime.**", `:19`), `botopink-lang/modules/compiler-core/src/comptime/AGENTS.md:27, 35`,
`…/comptime/template_eval.zig:1`. The server module is on disk at
`erika/.botopinkbuild/tmp/persistent_erl/botopink_comptime_server.erl`.

### Fix — in erika

Rewrite `:108-148` against the Erlang evaluator:

- what a comptime body may call — the four `__bp_*` helpers plus whatever
  `comptime-dispatch` (1.0.2-beta, landed) step 1 adds;
- how records appear — maps, `maps:get/2`;
- which erlang-codegen gotchas apply — the two already listed in
  `botopink-lang/libs/std/AGENTS.md:152-155`.

Do it **after** that front's step 1 lands, so the constraint list is written against the fixed
surface, not the broken one. Revisit `:123` (the two-parameter idiom) once 7b lands.

### Acceptance

- [ ] No `AGENTS.md` in the workspace describes a JavaScript, wasm3 or WAT comptime runtime
- [ ] Every workaround erika documents is justified by a constraint that still exists
