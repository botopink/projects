# Front 93 — SOAP Web Services

**Priority:** low — SOAP appears where an enterprise endpoint already exists; nothing builds on it. The generator is the front's unwritten half and the rename is a day
**Carries:** —
**Depends on:** maintainer 03r-ac (the rename) · none in this track (88 writes the CLI command after this lands; 13's client already takes a bundle for R93-2) · compiler lg2-o (a comptime body has no filesystem access — the generator is a run-time tool that writes checked-in `.bp`, the closed front's own reading)
**Owns:** `modules/rakun-ws/**` → `modules/rakun-soap/**` · `modules/README.md` row · `repository/rakun/AGENTS.md` § SOAP
**Does not touch:** `rakun-cli` (88's — the `ws generate` command) · `rakun-client` · the core

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/93-rakun-soap-webservices/README.md`) | Box, as written |
|---|---|---|
| R93-1 | § Step 2 — The schema subset and its refusals | "Every construct in the *targeted* table generates, asserted by a fixture schema exercising each one." · "Every construct in the *refused* list produces a located error naming the construct and the element it appeared in — thirteen refusals, thirteen tests." · "`minOccurs="0"` becomes `?T` and `maxOccurs="unbounded"` becomes `T[]`; both together become `?T[]` with the documented reading." · "An enumeration becomes an enum-shaped `type`, and an unknown value in a response is an error rather than a silent empty." · "A recursive type beyond the configured depth is refused, not expanded until the generator runs out of memory." — all "open: the WSDL/XSD generator (the schema subset, its refusals, `rakun ws generate`) is not written" |
| R93-1 | § Step 3 — The generator | "The generated tree compiles with `botopink build --target erlang` and its own generated tests pass, with no hand edits." · "Re-running the generator over an unchanged WSDL produces byte-identical output" · "Generated files carry a header naming the source WSDL and its content hash, so a stale generation is visible." · "A WSDL with an `xsd:import` pointing at a network URL is refused; a local relative import is followed." |
| R93-2 | § Step 4 — The client | "TLS material comes from front 74's bundle registry. — open: front 13's client takes a bundle, but `WsClient` passes none yet" |
| R93-3 | § Step 6 — Publishing an endpoint | "`<path>?wsdl` serves the source WSDL unmodified, and the served document's content hash matches the one in the generated header. — open: … there is no generated header to compare the hash with" |
| rename | closed `modules.md` § Verdicts | `rakun-ws` → `rakun-soap` (03r-ac) |

## Problem

A rakun service integrating with a SOAP endpoint hand-writes the request and response records
from the WSDL. `WsClient` ignores TLS bundles. The member is named like a WebSocket library.

## Current state

`modules/rakun-ws`: `src/{root,ws}.bp`, `rakun_ws.erl`; `test/{client,envelope}_test.bp` green
(SOAP 1.1/1.2 envelopes and faults over `xmerl`, the client over `rakun-client` with WS-Security
UsernameToken, a published endpoint dispatching on the wrapped element and serving the WSDL
unmodified). Manifest: `rakun`, `rakun-client`. No `generate.bp`.

## Mechanism

- **Rename (step 1).** Directory, manifest `name`, sidecar `rakun_soap.erl` and its
  `#[@External.Erlang]` references, the two test imports, `modules/README.md`, `AGENTS.md`. No
  consumer; no ledger line (03r-ah).
- **Generator (step 2).** `src/generate.bp`: `generate(wsdlPath: string, outDir: string) ->
  @Result<string[], string>` — reads the WSDL and its local `xsd:import`s through std's `fs`
  (run time, lg2-o), walks the targeted XSD subset (elements, complex types with sequence/all,
  simple types with enumeration and restriction, `minOccurs`/`maxOccurs`, local imports) into
  records and an enum-shaped `type` per enumeration, refuses the thirteen constructs of the closed
  table (choice, any, anyAttribute, substitution groups, mixed content, union, list, redefine,
  network import, recursive depth over the limit, xsd:ID/IDREF, attribute groups, abstract types)
  with a located error, writes `<out>/<service>.bp` + `<out>/<service>_test.bp` with a header
  `// generated from <wsdl> sha256=<hash>`, deterministically (sorted by element name, fixed
  formatting through `botopink format`).
- R93-3: the endpoint reads the generated header's hash and compares it to the served WSDL's
  `hash.strongHash`.

## Gate stance

No env-gated cell. The generator runs over fixtures under `test/fixtures/wsdl/`; the generated
tree compiles through `BOTOPINK_BIN` under `BOTOPINK_TEST_TMPDIR`.

## Steps

### Step 1 — The rename (03r-ac)

**Acceptance:**
- [ ] `modules/rakun-soap/` exists and `modules/rakun-ws/` does not; `grep -rn '"rakun-ws"\|rakun_ws' repository/rakun` answers nothing; both suites green under the new name; `test-libs` lists `rakun-soap · erlang`

### Step 2 — The generator (R93-1)

**Acceptance:**
- [ ] `test/generate_test.bp`: `fixtures/wsdl/targeted.wsdl` exercising every targeted construct generates; the tree compiles with `botopink build --target erlang` and its generated tests pass, no hand edit
- [ ] thirteen fixtures, thirteen cells, each a located error naming the construct and the element
- [ ] `minOccurs="0"` → `?T`, `maxOccurs="unbounded"` → `T[]`, both → `?T[]`; an enumeration → an enum-shaped `type` and an unknown value in a response is an error
- [ ] a recursive type beyond depth 8 is refused
- [ ] two runs over an unchanged WSDL are byte-identical; the header names the WSDL and its hash
- [ ] a network `xsd:import` is refused; a local relative one is followed

### Step 3 — The client and the endpoint (R93-2, R93-3)

**Acceptance:**
- [ ] `client_test.bp`: `WsClient` built with bundle `b` passes it to `rakun-client`; the TLS double sees the bundle's client certificate; a missing bundle name refuses the build
- [ ] `client_test.bp`: `<path>?wsdl` serves the source unmodified and its hash equals the generated header's

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-soap`
- [ ] `botopink format --check` clean (the generator's output included)
- [ ] `AGENTS.md` § SOAP and `modules/README.md` updated
- [ ] commit on `fix/93-rakun-soap-webservices`

## Blast radius

The rename touches the member only. 88 adds the `ws generate` command and the `rakun-soap` edge
in its own front.

## Notes

`examples/soap-client-example.bp` is copied here for its open marker (lg2-o).
