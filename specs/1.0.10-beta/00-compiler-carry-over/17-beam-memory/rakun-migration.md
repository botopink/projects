# rakun's migration onto `@BeamMemory` — step 8 of front 17, handed to `03-rakun`

Front 17 edits no library. This is the migration, written against rakun at submodule commit
`10c63974` and emilia at `9c19e22` (the pins of `.tasks/17-beam-memory` on 2026-09-25), with the
line ranges re-derived there rather than carried from the README. It is registered against
[decision 17](../../../1.0.5-beta/decisions-taken.md#17-rakuns-erlang-story)'s container-and-router
half and opens the moment C-10 lands the three modes; nothing here can be done before that.

## What moved since the README was measured

Two facts changed between `bef762b` and `10c63974`, and one of them changes the shape of the payoff:

1. **The paths.** `rakun/src/runtime.mjs` is `modules/rakun/src/runtime.mjs` (the 1.0.10 packaging
   made rakun a workspace). It is **still 231 lines** and the five registry ranges are unchanged.
   `runtime.bp` is `modules/rakun/src/runtime.bp`, still **16** host declarations.
2. **The erlang twin exists.** `modules/rakun/src/sidecars/rakun_runtime.erl` — **850 lines** — is
   the hand-written BEAM half of the same seam: every one of the 16 declarations now carries
   `@External.Node("./runtime.mjs", …)` **and** `@External.Erlang("rakun_runtime", …)`. Its
   registries are six `named_table, public, read_concurrency` ETS tables owned by a supervised
   `gen_server` registered as `rakun_registry`, under a `one_for_one` supervisor, under an
   `application` loaded from a term (`ensure_started/0`, one `ets:whereis/1` on the warm path). In
   other words: rakun built **decision 39's registered owner** by hand, once, for itself. The
   per-request state (the cycle-guard stack, the reply-header accumulator) is in the process
   dictionary — `ProcessDict` by hand.

So the migration no longer *ports* the registries to the BEAM; that happened. It **deletes two
implementations of the same five registries** and replaces them with five annotated `var`s whose
storage the compiler emits — which is what the front promised, and the erlang half is now the
larger of the two.

## The registries, mode by mode

| registry | `runtime.mjs` (lines) | `rakun_runtime.erl` (lines) | write pattern | mode | `runtime.bp` declarations that go |
|---|---|---|---|---|---|
| `scanned` | `:16-32` (17) | `:171-186` (`scan/1`, `scanned_names/0`, `scanned_count/0`; `?SCAN` ordered_set) | once at load, decorator-emitted | **`PersistentTerm`** — a `string[]` appended at load; read by `Rakun.run` | `rkScan`, `rkScannedNames`, `rkScannedCount` (`:31-40`) |
| `building` + `builds` | `:33-63` (31) | `:188-218` (`enter/1`, `done/1`, `build_count/1`; `?BUILDS` set + `rakun_building` in the pd) | repeatedly at run time | `building` is **`ProcessDict`** (the construction stack is per request — the `.erl` already says so, `:189-190`); `builds` is **`Ets(keyed = true)`** on a `Dict<string, i32>` (`+=` per type name is `ets:update_counter`, the atomic form decision 40 keeps) | `rkEnter`, `rkDone`, `rkBuildCount` (`:47-52`, `:66-67`) |
| `singletons` | `:64-79` (16) | `:220-238` (`singleton/2`; `?SINGLE` set, `insert_new`) | repeatedly at run time, one write per miss | **`Ets(keyed = true)`** on a `Dict<string, T>` — with the caveat below | `rkSingleton` (`:62-63`) |
| `props` | `:80-98` (19) | `:240-274` (`set_prop/2`, `prop/1`, `prop_int/1`, `prop_int_default/2`; `?PROPS` set) | at bootstrap, before the first request | **`PersistentTerm`** on a `Dict<string, string>`; `propInt` becomes a pure botopink reader over it | `rkSetProp`, `rkProp`, `rkPropInt` (`:75-84`) |
| `routes` | `:107-108`, `:113-123` (13) | `:276-297` (`register_route/3`, `route_count/0`, `route_paths/0`; `?ROUTES` ordered_set) | once at load, decorator-emitted | **`PersistentTerm`** on a `Route[]`, the handler stored by **name** (decision 43 / design §5(c) — a `fun` dies with its module version on reload; policy 3's one-module-per-type atom is the stable address) | `rkRegisterRoute`, `rkRouteCount`, `rkRoutePaths` (`:98-111`) |

**Totals, re-derived:** `runtime.mjs` sheds **96 of 231 lines** (17 + 31 + 16 + 19 + 13); the 135
that stay are `split`/`match`/`makeRequest`/`dispatch`/`dispatchHttp`/`serve` — host binding.
`rakun_runtime.erl` sheds the five registry sections (**`:171-297`, 127 lines**) **and** the owner
it built for them — `?SCAN`/`?SINGLE`/`?BUILDS`/`?PROPS`/`?ROUTES` (`:71-75`), the `registry`
role of `init/1` (`:150-163`) and `start_registry/0` (`:126-130`), and the part of `ensure_started/0`
that exists to give the tables an owner — while `?FAILURES`, the acceptor, the connection supervisor
and the reply-header accumulator stay, because they are host behaviour and not registry
maintenance. `runtime.bp` sheds **13 of 16** declarations; `rkDispatch`, `rkDispatchHttp` and
`rkServe` (`:114-141`) stay, each keeping both `@External` arms.

**What the compiler has to emit for this to hold**, in C-10's terms: `PersistentTerm` on a list and
a `Dict` (three of the five), `Ets(keyed = true)` on a `Dict` (two), `ProcessDict` on a list (one),
and `+=` → `ets:update_counter` on a keyed `Dict<string, i32>` row. The `Ets` five-request fixture
of C-10 (five processes × three increments reading `15`) is exactly `builds` under load.

## The caveat that only `singletons` has

`rakun_runtime.erl:221-224` documents the one thing the node half never had to think about: two
request processes can miss the singleton cache at the same instant, so the insert is
`ets:insert_new/2` and the **loser discards its value** — "one instance per type" holds without a
lock, and `build_count/1` is then `1` or `2`, never a function of the number of readers. A
`Dict` under `Ets(keyed = true)` written as `singletons = singletons.insert(name, v)` is an
`ets:insert`, which **overwrites**: the loser's instance replaces the winner's, and a caller holding
the winner's has a different object from every later caller. Nothing in the design's read/write
lowering expresses insert-if-absent.

Three honest answers, for C-10 to pick when it gets here — this front recommends the third:

1. keep `rkSingleton` as the fourteenth host declaration (the payoff becomes 80 lines and 12
   declarations, and the `.erl` keeps `?SINGLE` and its owner — the owner it was going to shed);
2. accept overwrite semantics and document that a diamond may build twice under contention
   (`build_count` stays 1 or 2; the instances differ — the test that proves the scope,
   `runtime.mjs:58-59`, would pass on node and be a coin flip on erlang);
3. give the `Ets(keyed = true)` lowering one more recognised form, `d = d.insertNew(k, v)` or
   the equivalent spelling the `Dict` API settles on, lowered to `ets:insert_new` with the
   existing row as the answer — the same shape decision 40 gave `+=` (a named form the emitter
   recognises, atomic on the table, refused nowhere). It is one more row of the recomposition
   rule, and it is the only answer under which `singletons` moves at all.

## emilia — the validation case for `ProcessDict`, not an entry of this front

`modules/emilia/src/emilia.bp:53-55` (`register`: `get('__emilia_sheet')` + `lists:keystore` +
`put`) and `:58-60` (`drainRules`: `erase('__emilia_sheet')`, then join) are a read-modify-write
and a reset over one process-dictionary key, per-process **on purpose** (`:18-23`: the stylesheet is
per render, and a render is a process). `erase` is not a blocker: the reader guards
`undefined -> []`, so absent and `[]` are indistinguishable and `sheet = []` reproduces it. The
blocker is unchanged from the README: the value is a host list of 2-tuples with `keystore`
**upsert** semantics (insertion order kept, a re-registered name updated in place), which needs
an ordered dict in `libs/std` — decision 17's half, `01-std`'s row, not this one's. When that
exists, `#[@BeamMemory.ProcessDict] var sheet: OrderedDict<string, string> = …;` replaces both
`@External` arms of `register` and `drainRules`, and the commonJS half (`globalThis.__emilia_sheet`,
`:53`, `:58`) goes with them.
