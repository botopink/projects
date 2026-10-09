# Front 140 — a wasm build binds to its runtime: wasmtime and WASI preview 2 first

**Priority:** high — `io/http` and `async` stay refused on wasm until it lands (97-a, 97-b → 334) ·
**State:** not started
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
offers. The first and default profile is **`wasi`** — wasmtime and the runtimes that follow WASI
preview 2 (`wasi:http`, `wasi:clocks`, `wasi:io/poll`); the **`browser`** profile (JS imports:
`fetch`, timers, `Promise` through JSPI) is decided and comes after.

```jsonc
// botopink.json of a wasm program
{ "name": "app", "target": "wasm", "wasm": { "host": "wasi" } }   // "wasi" is the default
```

```bp
// std/io/http.bp — the cell bound per host
#[@External.Wasm(host: .Wasi, wasi: .HttpOutgoing)]
declare fn fetch(req: Request) -> @Task<@Result<Response, HttpError>>;
```

## Open

### Step 1 — the profile in the manifest

- [ ] `"wasm": { "host": "wasi" | "browser" }` read by `modules/manifest`; absent means `"wasi"`; an
      unknown host is a located manifest error; `docs/botopink-json.md` documents it (284: packaging)

### Step 2 — `@External.Wasm(host: …)`

- [ ] the binding takes `host: .Wasi | .Browser` beside `op:`, `fn:`, `wasi:`, `module:` (238, 333); a
      binding with no `host:` serves every profile (`op:`, `fn:`); a cell with no binding for the build's
      host is the located `std-unsupported-on-target` naming the host, as today

### Step 3 — WASI preview 2 for the `wasi` profile

- [ ] the emitted module is wrapped as a WASI preview 2 component (the preview 1 adapter for the existing
      `wasi:` cells, `wasi:http/outgoing-handler`, `wasi:clocks/monotonic-clock`, `wasi:io/poll` imported);
      `wasmtime run` (with `-S http`) runs it; the adapters' list in `docs.md` § External grows
- [ ] every existing wasm cell still green under the component (`zig build test-language`, wasm column)

### Step 4 — `@Task` on `wasi`

- [ ] a `@Task` runs to completion when awaited, blocking on its pollable (the model erlang's eager
      lowering already has, lg2-b); `delay(ms)` waits on the monotonic clock; `race` / `raceOf` answer the
      first pollable ready; `spawnAll` runs each in turn and keeps the order of the answers
- [ ] the `async_block_*` cells gain the wasm column (`.targets` widened)

### Step 5 — the cells

- [ ] `run/wasm_host_http` (a request to a local HTTP double, its status and body) and `run/wasm_host_async`
      (`delay`, `race`) under wasmtime; the commonJS and erlang answers equal
- [ ] `05-wasm`'s `wat/AGENTS.md` § Where this backend refuses to answer loses `io/http` and `async`

### Step 6 — the `browser` profile (after 1–5)

- [ ] JS imports for the `browser` host (`fetch`, `setTimeout`) and `@Task` as a `Promise` through JSPI;
      the emitted `.wasm` and a small loader `.js`; a cell run under node with JSPI enabled

**Gate:** standard (fronts.md § Gate) + `zig build test-language` with wasmtime's component support and
`zig build test-libs` (std's wasm column).
