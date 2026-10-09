# Front 140 — a wasm build binds to its runtime: wasmtime (WASI preview 2) and the browser, together

**Priority:** high — `io/http` and `async` stay refused on wasm until it lands (97-a, 97-b → 334) ·
**State:** partial: steps 1–3 built, step 6 built but for `@Task` through JSPI; 4, 5 wait on `140-a`…`140-c`
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
(`wasi:http`, `wasi:clocks`, `wasi:io/poll`); the **`browser`** profile (JS imports: `fetch`, timers,
`Promise` through JSPI) lands **with it**: a cell bound on one host is bound on the other, and every
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

## Open

### Step 4 — `@Task` on `wasi`

Waits on `140-a` (what a pending Task is on wasm) and `140-b` (an adapter that answers a `@Task`).

- [ ] a `@Task` runs to completion when awaited, blocking on its pollable (the model erlang's eager
      lowering already has, lg2-b); `delay(ms)` waits on the monotonic clock; `race` / `raceOf` answer the
      first pollable ready; `spawnAll` runs each in turn and keeps the order of the answers
- [ ] the `async_block_*` cells gain the wasm column (`.targets` widened)

### Step 5 — the cells

Waits on step 4 and on `02/97` step 17 (`io/http`'s and `async`'s wasm bindings).

- [ ] `run/wasm_host_http` (a request to a local HTTP double, its status and body) and `run/wasm_host_async`
      (`delay`, `race`) under wasmtime; the commonJS and erlang answers equal
- [ ] `05-wasm`'s `wat/AGENTS.md` § Where this backend refuses to answer loses `io/http` and `async`

### Step 6 — the `browser` profile (with 3–5, never after)

- [ ] JS imports for the `browser` host (`fetch`, `setTimeout`) and `@Task` as a `Promise` through JSPI
      (waits on `140-a`, `140-c`); the emitted `.wasm` and its loader are built (§ Done)
- [ ] parity: std's check refuses a cell bound on one host only (std's, `02/97` step 17); `test-libs` runs
      the wasm column on both hosts once `botopink test` runs wasm (335 (3)) — `test-language`'s does (§ Done)

**Gate:** standard (fronts.md § Gate) + `zig build test-language` with wasmtime's component support and
`zig build test-libs` (std's wasm column).
