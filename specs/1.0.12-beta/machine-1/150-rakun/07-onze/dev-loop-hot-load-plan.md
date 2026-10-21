# The dev loop — hot load on every target, measured (the evidence of decisions 766 and 767)

A read-only fable plan of 2026-10-19, asked by the maintainer before answering question 50-b ("como seria (b) para os múltiplos targets"), kept here as the topic file of 150 step 2. It describes the code as it was that day; the rules in force are decisions 766 and 767 in `specs/decisions-taken.md` § rakun-ssr.


## 0. What exists today (measured)
- rakun-ssr: 62 .bp under src/, manifest "target": "commonJS" (the CLI runs on node); cli/ 2,086 lines: main.bp answers `dev` with exit 2; build.bp (525), start.bp (221); bundler/rebuild.bp (112) = the client-side invalidation (5 tests).
- build: rm -rf out, stage the server package, `botopink build --target erlang` (.erl only; dependencies' .beam stay in the level-A cache, not materialised by build), then erlc over EVERY erl/*.erl (~4,000 modules for a scaffold, "~80 s in one erlc", dealt to P CPUs), the client package, link, stylesheet, build id (hash of every staged source), client-manifest.
- start: `erl -noshell -pa out/server/beam -eval '<pkg>@onze_main':main([])`; the generated onze_main.bp still writes `jhRegisterRoutes(@TypeInfo.all(with: page), …)` and `onze_routes.routeModules()` — stale vs 665 and 660/677 (question 50-g).
- The server is erlang-only: onze-server declares ["erlang"], rakun is ["erlang"] (117), rakun/src/runtime.bp has 0 .JavaScript/.Wasm cells, std's io/http has no listener. "rakun-ssr builds for commonJS too" = the CLI and the client bundle; no server runs on commonJS or wasm today.
- A hot-load path already exists on the BEAM: rakun-data's devtools (rakun_devtools.erl: watch_start polling mtimes, compile_project, load_dir = compile:file, same_code by md5, code:soft_purge (deferred, never kills), drop_module (rakun_routes/rakun_singletons/rakun_scan rows), code:load_binary, re-run Mod:'_botopink_init'/0). It does NOT drop: rakun-bpp's UI table (jhonstart_routes: add appends, lookup answers the FIRST registration), rakun's registry of #[rakun.module] (var modules, a one-row ETS table), the persistent_term cache of effectful module vals, rakun's ?PROPS.
- std has no file watcher; io.fs.stat answers mtime (seconds); io.process.spawn/wait/kill/forwardSignals exist (506).
- Compiler caches: level A (dependencies' .beam, erlang/beam only), level B (dependencies' analysis). The package under build is always analysed and generated whole (509 (1)); no per-module incremental compile of the app.

## 1. The unit of reload, per target
| Target | A .bp module becomes | Live-swap primitive | Status |
|---|---|---|---|
| erlang | one Erlang module `<pkg>@<path>` (109); `_botopink_init/0` when the body has effects (140) | code:soft_purge + code:load_binary (what load_dir does) | exists (front 80's devtools) |
| beam | the same module (.S → erlc +from_asm, or beam_file.zig's bytes) | same | exists at the VM level; rakun-ssr does not build for beam today |
| commonJS/node | one out/<path>.js per module; importers hold `const {x} = require(…)` bindings | delete require.cache + re-require — importers keep old bindings; the sound unit is a Worker/process restart | no server on node; the only sound unit is a restart = (a) in-process |
| wasm | no module unit: the whole program is one .wasm (static link) | re-instantiate = a restart | no function-level swap; no server on wasm |

## 2. State residue (BEAM) that survives a swap and must not
- effectful module vals cached in persistent_term under {<module>, <name>} — load_binary leaves the key (50-e);
- module vars: one-row ETS table re-seeded only when missing (547) — a changed initialiser is not seen;
- registries the init executors wrote (665): rakun's dropped by drop_module; rakun-bpp's jhonstart_routes NOT dropped (a re-run appends, lookup keeps the first = old render fun; under 665 a second registration is a refusal); rakun's registry.modules not dropped; ?PROPS;
- boot's read-once values: build-id and client manifest read once by RakunSsr.run — every change moves the build id (it hashes every staged source), so static/<buildId>/ URLs go stale after any swap unless RakunSsr.run re-runs;
- closures: funs stored in tables belong to the module version that made them; after a second load the old version is purged → badfun; soft_purge defers (a long-lived connection keeps old code);
- rakun.boot()'s started/stops vars: a reloaded #[rakun.module] is not restarted.
Re-derivation whose order equals start's: drop every registry, erase every {M, Name} key and ETS var table, run the WHOLE init list (580/660 order) and main again — a "soft restart" in a warm VM. Anything narrower is an order start never produces.
commonJS: a re-require leaves importers' bindings and the registry array; only a Worker restart clears them. wasm: nothing survives re-instantiation — the absence of a partial unit is the issue, not residue.

## 3. One invalidation model (no new compiler feature)
1 watcher (cli/dev.bp, target-agnostic): poll fs.stat mtimes over src/, public/, rakun-ssr.json, botopink.json. 2 rebuild = today's build whole (509 (1)); rebuild.bp covers the client half. 3 diff outputs against the previous build (erlang .erl bytes → erlc only those; beam .S/.beam; commonJS .js; wasm one .wasm = always changed) — the compiler's output as the oracle of "what changed". 4 classify a changed module as swappable only if: import shape unchanged, no convention file changed, no effectful module val / var, nothing registered a drop cannot remove; else restart. 5 swap through one seam `Reload { swap(modules) -> Result<void, string>; restart() }`: BEAM = load_dir shape; node = restart only; wasm = restart only.

## 4. Convention files — (b) possible? / (c) forced
body edit, import shape unchanged → BEAM yes with § 2's drops; node/wasm no · an import line → re-walk + swap of every module whose .erl changed · new/removed route file, layout, template, loading, error, not-found → restart on every target (route table generated at build, 403/285; boot copy of the UI table) · .module.css / globals.css → restart (staged modules; stylesheet hash in the build id) · public/ → restart (static root registered at boot, 201) · rakun-ssr.json / botopink.json → restart (config a literal in the generated main) · ANY change moves the build id → stale static URLs unless RakunSsr.run re-runs.
So (c)'s fallback set is "everything except a body edit of a module with no module state", and even that moves the build id. The honest (b) on the BEAM is the soft restart.

## 5. The oracle (67)
(a): by construction. (b) per-module swap: no construction proof; init order differs; a shadow build + request diff costs a full build per edit; "a restart every N swaps" is a knob. (b) as soft restart: equal to start IF the reset is complete — and the reset's completeness is what nothing proves (persistent_term keys, ETS var owner, every registry, ?PROPS, the listener); each missing reset is a bug only in dev. The acceptance gate's "dev and start replies equal over the script" is the one shared oracle: a tautology under (a), the only evidence under (b).

## 6. Cost (no timings run; the code's own comments and counts)
erlang (the one target with a server): (a) = full botopink build of the app (blog 28 modules; dependencies from level A/B) + erlc of EVERY .erl (~4,000, "~80 s in one erlc" / P CPUs → tens of seconds) + erl boot loading all; with 50-c (dependency .beams reused, erlc of the app's .erl only): analysis + a few erlc + boot — the "1–3 s" is an estimate. (b) = the same build + erlc of the changed .erl + load_binary + re-init: saves only the VM boot and module loading. Code: (a) dev.bp (watcher, spawn, forwardSignals) + 50-c; (b) the same + drops for jhonstart_routes and rakun's registry (host cells on both hosts), a reset of persistent_term keys / ETS tables (50-e, a 144 step if emitted), a re-entrant RakunSsr.run, the Reload seam. Risk: (a) none in production; (b) every residue is a dev-only bug.
beam: same once rakun-ssr builds for beam. commonJS/node: no server; if one comes, (a) is the cheapest restart of the four; (b) has no module unit. wasm: no server; (b) ≡ (a).

## 7. Shape, if (b) is done
One dev loop in rakun-ssr (cli/dev.bp): watcher → build → output diff → Reload seam; (a) is this loop with Reload.restart() as the only implementation. Reload on the BEAM lives where the hot load already lives (rakun-data's devtools, in-node, dev profile): what it lacks is rakun-ssr's drops, 50-e's reset, a re-entrant RakunSsr.run. First to land: (a) with 50-c, because it is (b)'s build step too. 144's share: 50-e only if the reset is emitted. rakun-ssr's share: dev.bp, build.bp's erlc narrowing, main.bp's text, conformance/rakun-ssr/docs.md § "What is not wired yet", AGENTS.md.

## 8. Recommendation
(a) now; (b)/(c) later as a decision of its own, on the BEAM only, after (a) with 50-c is measured too slow on the blog. The server exists on one target (rakun erlang-only, 117; no listener on node or wasm): on node and wasm (b) IS (a). On the BEAM the primitive exists, but every swap leaves state start never has, the init order differs from 580/660's, and the restart set is wider than "convention files" because the build id moves on every change; the only (b) equal to start by construction is a soft restart whose reset's completeness nothing proves (67). Most of (a)'s cost is build.bp recompiling 4,000 dependency modules it already has as cached .beams — fixed by 50-c, not by hot loading. (c) refused as a standing form: two paths, the fallback the common case.

## Open points (pending-page shape)
50-c · rakun-ssr build recompiles every dependency's .erl on each build — (a) botopink build materialises the dependencies' cached .beam into <out>/beam/ (509 (4)) and compileBeam compiles only the .erl with no .beam beside it; (b) rakun-ssr diffs .erl bytes; (c) as today. Rec (a). Blocks 50 step 2's time per edit.
50-d · where (b)'s reload would run — (a) devtools' in-node watcher extended; (b) the CLI drives the node (rpc / stdin protocol); (c) none. Rec (a) only if (b) of 50-b is chosen.
50-e · a module's state reset for a warm restart — (a) backends emit `_botopink_reset/0` per module (144 step); (b) the dev tool erases keys by module atom from outside (an internal); (c) a module with an effectful val or a var is never swapped. Rec (c) now; (a) only with a (b) decision.
50-f · rakun-bpp's UI table has no drop and answers the first registration — (a) drop(record)/dropModule host cell on both hosts; (b) last-wins lookup (67 refuses); (c) none — restart. Rec (c) under (a); (a) with (b).
50-g · start.bp's generated onze_main.bp is 665/660/677-stale (not a 50-b choice) — (a) a 150 steps-onze box rewrites serverMainSource to 665's registry read and drops onze_routes's import role, keeping the generated route table; (b) leave until 50 step 2. Rec (a), in the step that writes dev.bp.

Critical files: rakun-ssr/src/cli/build.bp, start.bp, bundler/rebuild.bp; rakun-data/src/sidecars/rakun_devtools.erl; compiler-core/src/codegen/erlang.zig (cachedValueExpr, siblingLoaderForm, memoryVarForms).
