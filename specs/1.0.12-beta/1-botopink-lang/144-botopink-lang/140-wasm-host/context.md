# Front 140 — a wasm build binds to its runtime: wasmtime (WASI preview 2) and the browser, together

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s4 → B-25 · s5 → B-25 · s6 → B-25. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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
