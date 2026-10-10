# Front 140 — a wasm build binds to its runtime: wasmtime (WASI preview 2) and the browser, together

**Priority:** high — `io/http` and `async` stay refused on wasm until it lands (97-a, 97-b → 334) ·
**State:** partial: steps 1–3 built; step 4 built but for `@Component` bodies (140-e) and `fetch`'s
records (with `io/http`); step 5's `run/wasm_host_async` and step 6's adapter list built; `run/wasm_host_http`,
`async_block_all_of`'s wasm column and std's bindings wait on `02/97` step 17 ·
**Depends on:** decision 334 · `05-wasm` step 5 (std on wasm, groups 1–2) · front 18 (the binary
emitter, for the component wrapping) · `02-std-and-packaging/98` (the manifest model, for the
`"wasm"` key)
**Owns:** the WASI preview 2 half of `codegen/wat.zig` + `codegen/wat/**` (a named carve-out of
05-wasm, after its open steps) · the component wrapping in front 18's binary emitter (carve-out) ·
`@External.Wasm`'s `host:` argument in the checker (a carve-out of `01-checker`, one commit with its
cells) · the `"wasm": { "host": … }` key in `modules/manifest/**` (with 98) · the wasm runner of
`compiler-cli` and `lib-test-runner` (`wasmtime` invocation) · its cells under `tests/language/`
**Does not touch:** std's bindings (handed to `02/97` step 17) · `unicode.normalize` (333 (A): std's
botopink body, no host) · the WAT comptime runtime (`wasm3`, front 18), which keeps the core-module
subset — comptime asks no network and no timer

Paths relative to `repository/botopink-lang/modules/compiler-core/src/` unless they start `modules/`.

## Goal

Decision 334: a wasm build names the runtime it runs on, and std binds a cell to what that runtime
offers. The default profile is **`wasi`** — wasmtime and the runtimes that follow WASI preview 2
(`wasi:http`, `wasi:clocks`, `wasi:io/poll`); the **`browser`** profile (JS imports: `fetch`, timers;
the same task state machines driven by the JS event loop, decisions 392–394) lands **with it**: a cell bound on one host is bound on the other, and every
wasm cell runs on both.

```jsonc
// botopink.json of a wasm program
{ "name": "app", "target": "wasm", "wasm": { "host": "wasi" } }   // "wasi" is the default
```

```bp
// std/io/http.bp — the cell bound per host
#[@External.Wasm(host: .Wasi, wasi: .HttpOutgoing)]
declare fn fetch(req: Request) -> @Task<@Result<Response, HttpError>>;
```

## Done

- Step 1 — `"wasm": { "host": "wasi" | "browser" }` in `modules/manifest` (`WasmHost`, `parseWasm`: a
  non-object, no `host`, another field, a host neither — located; refused on a workspace); the CLI reads
  it (`ProjectConfig.wasmHost`); `docs/botopink-json.md` documents the field and its five refusals.
- Step 2 — `@External.Wasm(…, host: .Wasi | .Browser)`: the build's lookup carries its host (`wasm` /
  `wasm.browser`, `ast.ExternalLookup`), `externalFor` reads the binding serving it, `checkHostBindings`
  checks every binding whatever its host; the checker refuses `host:` off `Wasm`, a value other than the two,
  and two bindings for one host (`refuseHostArg`, `refuseWasmHostTwice`); `std-unsupported-on-target`
  names the host (`… for target 'wasm' on host 'wasi'`). Cells: four `reject/external_*host*`,
  `run/external_wasm_host_binding`, `modules/wasm_host_from_manifest`. Hand-off: `builtins.d.bp`'s
  `External.Wasm(template: string)` does not declare `host` (std's file; the checker reads it).
- Step 3 — a `wasi` build is a WASI preview 2 component in text (`wat_emitter.renderComponent`): the module
  as `$main` (its start exported `__bp_init`), a preview 1 adapter the compiler writes (`fd_write` on
  `wasi:cli/stdout`/`stderr` + `wasi:io/streams`, `random_get` on `wasi:random/random`), the
  `wasi:cli/run` export; `botopink run` is `wasmtime run -S http`; the wasm column green under it (372/372).
  `wasi:http`, `wasi:clocks`, `wasi:io/poll` join the frame with their users (steps 4–5); the binary
  emitter encodes no component (wasmtime runs the text).
- Step 6, box 1 without `@Task` — a `browser` build writes `<module>.wasm` and the loader `<module>.mjs`
  (`browser_loader.zig`: `fd_write` on the console / `fs.writeSync`, `random_get` on
  `crypto.getRandomValues`); `botopink run` is `node <module>.mjs`; `tests/language/run.sh` runs every
  wasm cell on both hosts, one `.out`, a disagreement failing the cell (372/372 agree);
  `modules/wasm_host_browser_runs`.

- Step 4 (decisions 392, 393) — `@Task<T>` on wasm is a task record (`wat_prelude.zig` § decision 392's
  scheduler) and a `-> @Task<T>` fn, each specialisation, a method answering one and an `async { }` block
  are resumable state machines (`wat.zig` § decision 392: `$f` makes the task and runs it to its first
  `await`, `$f__body` re-entered at the frame's resume index with every local restored, `$f__step` settles
  it; statements, `if` conditions, `case` subjects and loop starts guarded on re-entry, so loops, `try`,
  `try … catch` and `if` arms resume in place; `return t` of a task adopts it); a synchronous function is
  unchanged. The scheduler: a ready queue, settle-once wake-ups, `_start` draining it and waiting on the
  host's pollables (`wasi:io/poll` through the component's `bp_host` adapter, `component_host_*`).
  Adapters answering `@Task<T>` over a generic `T`, checked by shape at the annotation (393; 140-d: the
  string spelling ★): `wasi:delay` (`(i32, T) -> @Task<T>`, `subscribe-duration` on the monotonic
  clock), `wasi:race`, `wasi:race_of`, `wasi:spawn_all`; a float or `i64` `T` refused at the call; each a
  row of `docs.md` § Host bindings. A call evaluated before an `await` in its statement is refused on wasm
  (140-f ★). Cells: `run/task_starts_when_made`, `run/task_resumes_in_place`,
  `run/task_await_after_call_refused_on_wasm`, `run/external_wasm_task_adapter_shape`; every async cell
  green on commonJS, erlang, beam and both wasm hosts.
- Step 4 — the cost, measured (wasmtime 45, precompiled component; node 25 for `browser`): 200 000 rounds
  of two `@Task` calls that never suspend (`mid` awaiting `leaf`) take 0.019 s eager (botopink-lang
  `856bbc69`) and 0.040 s as state machines on `wasi` (0.05 s / 0.07 s on `browser`) — about 50 ns and
  one frame (8 + 8 bytes per local) plus a 40-byte task per asynchronous call, nothing for a
  synchronous one. 2 000 sequential `await delay(0, i)` take 0.012 s on `wasi` and 2.4 s on `browser`,
  the same as commonJS (node's `setTimeout` floor of about 1 ms).
- Step 5, `run/wasm_host_async` — `delay`, `race`, `raceOf` (`"b"`: the block awaiting 30 ms loses to the
  10 ms delay) and `spawnAll` (input order) declared in the cell with std's Node / BEAM templates and the
  `wasi:` adapters; one `.out` on commonJS, erlang, beam, wasmtime and node.
- Step 6, box 1 — one adapter list for both hosts (394): the `browser` loader implements `bp_host.delay`
  with `setTimeout` (re-armed against `performance.now()`) and, after `_start`, waits on the event loop and
  hands each answer to the module's `__bp_ready(id)` — the same state machines, no JSPI.

## Open

### Step 4 — `@Task` on `wasi`

- [ ] `@Component` bodies (375's mark) as state machines — 140-e (recommended: every `@Component` a
      state machine on wasm); today they stay eager and an `await` of a task there runs the ready tasks,
      trapping on both hosts when the task still waits on the host
- [ ] `fetch`'s `Request` / `Response` in the compiler's layout (393), with `wasi:http` (`io/http`, `02/97`
      step 17)
- [ ] `async_block_all_of` gains the wasm column (`.targets` widened) — waits on std's `async` bindings
      (`02/97` step 17: `std/async` is refused on wasm for want of `delay`, `race`, `raceOf`)

### Step 5 — the cells

Waits on `02/97` step 17 (`io/http`'s and `async`'s wasm bindings).

- [ ] `run/wasm_host_http` (a request to a local HTTP double, its status and body) under wasmtime; the
      commonJS and erlang answers equal
- [ ] `05-wasm`'s `wat/AGENTS.md` § Where this backend refuses to answer loses `io/http` and `async`

### Step 6 — the `browser` profile (with 3–5, never after)

- [ ] `fetch`'s JavaScript implementation in the loader (394), with `io/http`
- [ ] parity: std's check refuses a cell bound on one host only (std's, `02/97` step 17); `test-libs` runs
      the wasm column on both hosts once `botopink test` runs wasm (335 (3)) — `test-language`'s does (§ Done)

**Gate:** standard (fronts.md § Gate) + `zig build test-language` with wasmtime's component support and
`zig build test-libs` (std's wasm column).
