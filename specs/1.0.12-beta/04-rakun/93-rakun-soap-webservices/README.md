# Front 93 — SOAP web services: the WSDL generator, the client's bundle, the served hash

**Priority:** low — SOAP appears where an enterprise endpoint exists; nothing builds on it ·
**State:** not started
**Depends on:** 128 (merges the SOAP member into `rakun-client` — decision 187; no rename) · lg2-o (a
comptime body has no filesystem access — the generator is a run-time tool writing checked-in `.bp`)
· 13's client already takes a bundle (R93-2) · 88 writes the CLI command after this
**Owns:** `modules/rakun-client/src/ws/**`, `test/ws/**`, `src/sidecars/rakun_ws.erl` · its
`modules/README.md` row · `repository/rakun/AGENTS.md` § SOAP
**Does not touch:** rest of `rakun-client` (13's — `botopink.json`, `src/root.bp` included; the
generator's lines appended when 13 does not hold them) · `rakun-cli` (88's `ws generate`) · the core

## Goal

A WSDL becomes checked-in botopink records and a test file, deterministically, for the targeted XSD
subset, with a located refusal for every construct outside it; `WsClient` passes its TLS bundle to
`rakun-client`; `<path>?wsdl` serves the source whose hash the generated header names.

## Mechanism

Exists (`src/ws/{root,ws}.bp`, `rakun_ws.erl`, `test/ws/{client,envelope}_test.bp`): SOAP 1.1/1.2
envelopes and faults over `xmerl`, the client over `rakun-client` with WS-Security UsernameToken, a
published endpoint dispatching on the wrapped element and serving the WSDL unmodified. No generator.

- **Generator (step 2).** `src/ws/generate.bp`: `generate(wsdlPath: string, outDir: string) ->
  @Result<string[], string>` reads the WSDL and its local `xsd:import`s through std's `fs` at run
  time (lg2-o); walks the targeted subset (elements, complex types with sequence/all, simple types
  with enumeration and restriction, `minOccurs`/`maxOccurs`, local imports) into records and an
  enum-shaped `type` per enumeration; refuses the closed table's thirteen constructs (choice, any,
  anyAttribute, substitution groups, mixed content, union, list, redefine, network import, recursive
  depth over the limit, xsd:ID/IDREF, attribute groups, abstract types) with a located error; writes
  `<out>/<service>.bp` + `<out>/<service>_test.bp` with header `// generated from <wsdl>
  sha256=<hash>`, sorted by element name, formatted through `botopink format`.
- **R93-3.** The endpoint compares the generated header's hash with the served WSDL's `hash.strongHash`.

Generator runs over fixtures under `test/ws/fixtures/wsdl/`; the generated tree compiles through
`BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`; nothing env-gated.

## Done

- Step 1 — the member rename (`03r-ac`) is not done: superseded by decision 187, 128 step 4 merges the member

## Open

### Step 2 — The generator (R93-1)

- [ ] `test/ws/generate_test.bp`: `fixtures/wsdl/targeted.wsdl` (every targeted construct) generates; the tree compiles with `botopink build --target erlang`, its generated tests pass with no hand edit
- [ ] thirteen fixtures, thirteen cells, each a located error naming the construct and its element
- [ ] `minOccurs="0"` → `?T`, `maxOccurs="unbounded"` → `T[]`, both → `?T[]`; an enumeration → an enum-shaped `type`, an unknown value in a response is an error
- [ ] a recursive type beyond depth 8 refused
- [ ] two runs over an unchanged WSDL byte-identical; header names the WSDL and its hash
- [ ] a network `xsd:import` refused; a local relative one followed

### Step 3 — The client and the endpoint (R93-2, R93-3)

- [ ] `test/ws/client_test.bp`: `WsClient` built with bundle `b` passes it to `rakun-client`; the TLS double sees the bundle's client certificate; a missing bundle name refuses the build
- [ ] `test/ws/client_test.bp`: `<path>?wsdl` serves the source unmodified, its hash equals the generated header's

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` green in `modules/rakun-client`
(`test/ws/` in the run); `botopink format --check` clean, generator output included;
`modules/README.md` updated.

Blast radius: new files under `rakun-client/src/ws/` only. 88 adds `ws generate` and the
`rakun-cli → rakun-client` edge in its own front.

`examples/soap-client-example.bp` kept for its open marker (lg2-o).
