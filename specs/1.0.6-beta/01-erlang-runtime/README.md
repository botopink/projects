# Front 01 — Erlang Runtime

**Priority:** critical — without Erlang runtime, nothing can run on BEAM
**Depends on:** none
**Owns:** `src/runtime.erl`, `src/runtime.bp` (@External.Erlang declarations), `src/sidecars/runtime.erl`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun's entire host runtime is Node.js-only. Every `rk*` host cell in `src/runtime.bp` carries an `@External.Node` form and no Erlang one, so an Erlang run stops at `function rkScan/1 undefined`. The DI graph, router, and HTTP server are 231 lines of `runtime.mjs` that have no Erlang counterpart.

The compiler CLI already supports `libs.shipErlSidecars` — what is left is rakun's own work: writing the `.erl` host module and putting `@External.Erlang` on the 17 host cells.

## Current state

- `src/runtime.mjs` has 231 lines: component scan, singleton scope, cycle guard, config props, router, HTTP server (node:http)
- `src/runtime.bp` has 17 `#[@External.Node]` declarations: `rkScan`, `rkSingleton`, `rkEnter`, `rkDone`, `rkProp`, `rkPropInt`, `rkRegisterRoute`, `rkDispatch`, `rkDispatchHttp`, `rkServe`, `rkScannedNames`, `rkScannedCount`, `rkBuildCount`, `rkRouteCount`, `rkRoutePaths`, `rkSetProp`
- Only `http.bp`'s single test (which touches no host cell) passes on Erlang
- CI `erlang` rows have `allow_fail: true`

## Mechanism

Each `rk*` function in `runtime.bp` is declared as `#[@External.Node("runtime", "functionName")]`. The Erlang equivalent needs `#[@External.Erlang("rakun_runtime", "function_name")]` declarations alongside them, and a `rakun_runtime.erl` module that implements the same semantics using Erlang terms:

- **Component scan** → ETS table or process dictionary
- **Singleton cache** → ETS table (keyed by atom name)
- **Cycle guard** → process dictionary (per-construction stack)
- **Config props** → ETS table
- **Router** → ETS table + pattern matching
- **HTTP server** → `cowboy` or `ranch` (Erlang's standard HTTP server)

## Steps

### Step 1 — Create `rakun_runtime.erl` module

Write the Erlang module implementing all 17 host functions. Use ETS tables for mutable state (scan registry, singleton cache, config props, router). Use process dictionary for cycle guard (transient, per-construction).

```erlang
-module(rakun_runtime).
-export([scan/1, scanned_names/0, scanned_count/0,
         singleton/2, build_count/1,
         enter/1, done/1,
         set_prop/2, prop/1, prop_int/1,
         register_route/3, route_count/0, route_paths/0,
         dispatch/2, dispatch_http/5,
         serve/2]).

% ETS tables (created on module load)
-define(SCAN_TABLE, rakun_scan).
-define(SINGLETON_TABLE, rakun_singletons).
-define(PROPS_TABLE, rakun_props).
-define(ROUTES_TABLE, rakun_routes).

init() ->
    ets:new(?SCAN_TABLE, [set, named_table, public]),
    ets:new(?SINGLETON_TABLE, [set, named_table, public]),
    ets:new(?PROPS_TABLE, [set, named_table, public]),
    ets:new(?ROUTES_TABLE, [ordered_set, named_table, public]).
```

**Acceptance:**
- [ ] `rakun_runtime.erl` compiles with `erlc`
- [ ] All 17 functions exported with correct arities
- [ ] ETS tables created on `init()`

### Step 2 — Add `@External.Erlang` declarations to `runtime.bp`

For each of the 17 host cells, add an `@External.Erlang` form alongside the existing `@External.Node`:

```bp
#[@External.Node("runtime", "scan")]
#[@External.Erlang("rakun_runtime", "scan")]
pub fn rkScan(name: string) -> i32;
```

**Acceptance:**
- [ ] All 17 functions have both `@External.Node` and `@External.Erlang`
- [ ] `botopink check` passes on `src/runtime.bp`

### Step 3 — HTTP server via cowboy

Implement `serve/2` using cowboy. Map cowboy request to rakun's dispatch pipeline:

```erlang
serve(Port, DispatchFn) ->
    cowboy:start_clear(rakun_http, [{port, Port}], #{
        env => #{dispatch => cowboy_router:compile([
            {'_', [{'_', rakun_handler, #{dispatch_fn => DispatchFn}}]}
        ])}
    }),
    timer:sleep(infinity).  % keep alive
```

**Acceptance:**
- [ ] `Rakun.run(App(port: 8080, basePath: "/"))` starts cowboy on port 8080
- [ ] GET request to registered route returns 200
- [ ] GET request to unregistered route returns 404

### Step 4 — Router pattern matching in Erlang

Implement route matching with `:param` support:

```erlang
match(Verb, Path) ->
    Segs = string:split(Path, "/", all),
    Routes = ets:tab2list(?ROUTES_TABLE),
    find_match(Verb, Segs, Routes).

find_match(_Verb, _Segs, []) -> not_found;
find_match(Verb, Segs, [{_, RVerb, RSegs, Handler} | Rest]) ->
    case match_segs(Verb, RVerb, Segs, RSegs, #{}) of
        {ok, Params} -> {ok, Handler, Params};
        no_match -> find_match(Verb, Segs, Rest)
    end.
```

**Acceptance:**
- [ ] Path params (`:name`) extracted and passed to handler
- [ ] Multiple routes with same prefix resolve correctly
- [ ] 404 returned for unmatched paths

### Step 5 — Singleton scope in Erlang

Use ETS for singleton cache. Thread-safe by default (ETS is process-safe):

```erlang
singleton(Name, BuildFn) ->
    case ets:lookup(?SINGLETON_TABLE, Name) of
        [{_, Value}] -> Value;
        [] ->
            Value = BuildFn(),
            ets:insert(?SINGLETON_TABLE, {Name, Value}),
            Value
    end.
```

**Acceptance:**
- [ ] Same instance returned for multiple resolves
- [ ] Diamond dependency shares one instance
- [ ] `buildCount/1` returns 1 for singleton

### Step 6 — Cycle detection in Erlang

Use process dictionary for the building stack:

```erlang
enter(Name) ->
    Building = get(rakun_building) orelse [],
    case lists:member(Name, Building) of
        true -> erlang:error({rakun_cycle, Name});
        false -> put(rakun_building, [Name | Building])
    end.

done(Name) ->
    Building = get(rakun_building) orelse [],
    put(rakun_building, lists:delete(Name, Building)).
```

**Acceptance:**
- [ ] Cycle A→B→A raises error at first construction
- [ ] Non-cyclic diamond resolves correctly

### Step 7 — Tests on Erlang target

Port all existing tests to run on Erlang. Currently only `http.bp`'s test passes.

**Acceptance:**
- [ ] `botopink test --target erlang` passes all tests in `test/`
- [ ] CI `erlang` row goes from `allow_fail: true` to green
- [ ] `di_test.bp` passes on Erlang (component scan + DI)
- [ ] `router_test.bp` passes on Erlang (route matching + dispatch)
- [ ] `scopes_test.bp` passes on Erlang (singleton scope)
- [ ] `server_test.bp` passes on Erlang (HTTP dispatch pipeline)

### Step 8 — Sidecar shipping

Ensure `rakun_runtime.erl` is shipped alongside emitted modules. The CLI's `libs.shipErlSidecars` reads `atom:atom(` qualifiers from emitted Erlang and copies `src/sidecars/rakun_runtime.erl` to the output.

**Acceptance:**
- [ ] `rakun_runtime.erl` placed in `src/sidecars/`
- [ ] `botopink build --target erlang` copies sidecar to output
- [ ] Built Erlang application starts and serves HTTP

## Gate

- [ ] `botopink test --target erlang` green from cold cache
- [ ] `botopink test --target commonJS` still green (no regression)
- [ ] `rakun_runtime.erl` compiles standalone with `erlc`
- [ ] Cowboy dependency declared in example app's rebar.config
- [ ] CI erlang row green (remove `allow_fail: true`)
- [ ] AGENTS.md updated with Erlang runtime documentation

## Blast radius

- **rakun-core** `src/runtime.bp` gains 17 `@External.Erlang` declarations — no behavioral change for commonJS
- **CI** erlang row goes from red to green — all libs that depend on rakun (examples) now compile on Erlang
- **Example app** needs cowboy dependency + `rebar.config`
- **No compiler changes** — all within rakun's own source

## Notes

- Cowboy chosen over `gen_tcp` because it handles HTTP parsing, keep-alive, and SSL out of the box
- ETS tables are per-BEAM-node (one VM = one set of tables) — matches Node.js module-global semantics
- Process dictionary for cycle guard is per-process — matches the per-construction semantics (each factory call is in the calling process)
- The `serve/2` function blocks (timer:sleep(infinity)) to keep the BEAM node alive — matches Node.js's event loop behavior
- Future: consider `ranch` instead of `cowboy` for lighter weight, but cowboy's HTTP handling is worth the dependency
