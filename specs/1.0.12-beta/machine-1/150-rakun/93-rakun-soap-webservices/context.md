# Front 93 — SOAP web services: the WSDL generator, the client's bundle, the served hash

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s2 → 150 s8 · s3 → 150 s8 · s4 → 150 s8. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** low — SOAP appears where an enterprise endpoint exists; nothing builds on it ·
**State:** not started
**Depends on:** 128 (merges the SOAP member into `rakun-client` — decision 187; no rename) · decision 342
(`@embedFile` lets a decorator read the WSDL at compile time; this front keeps the run-time generator
writing checked-in `.bp` — moving it into a decorator is a later front's choice)
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
  time; walks the targeted subset (elements, complex types with sequence/all, simple types
  with enumeration and restriction, `minOccurs`/`maxOccurs`, local imports) into records and an
  enum-shaped `type` per enumeration; refuses the closed table's thirteen constructs (choice, any,
  anyAttribute, substitution groups, mixed content, union, list, redefine, network import, recursive
  depth over the limit, xsd:ID/IDREF, attribute groups, abstract types) with a located error; writes
  `<out>/<service>.bp` + `<out>/<service>_test.bp` with header
  `// generated from <wsdl> sha256=<hash>`, sorted by element name, formatted through `botopink format`.
- **R93-3.** The endpoint compares the generated header's hash with the served WSDL's `hash.strongHash`.

Generator runs over fixtures under `test/ws/fixtures/wsdl/`; the generated tree compiles through
`BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`; nothing env-gated.
