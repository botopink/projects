# Front 93 — Rakun SOAP Web Services

**Track:** B rakun
**Priority:** low — SOAP appears where a rakun service must integrate with an enterprise endpoint that already exists; nothing new is built on it, and nothing else in the milestone depends on it
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 13 (the HTTP client every call goes out through), 07 (the filter chain a published endpoint is mounted behind), 88 (the CLI step that generates types from a schema), 74 (TLS), 05 (endpoint configuration)
**Owns:** `modules/rakun-ws/src/**`, `modules/rakun-ws/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. `modules/rakun-web/src/websocket/**` is front 20's and is unrelated: `rakun-ws` is *web services*, and the WebSocket module is `rakun-web`. The two names are close and the module README says so on its first line.
**Reference:** `07-io.md § Web Services (SOAP)` (Configuracao, WebServiceTemplate) · https://docs.spring.io/spring-boot/reference/io/webservices.html

---

## Problem

Spring Boot 4 ships a web-services starter: `WebServiceTemplate` for calling a SOAP endpoint,
`spring.webservices.wsdl-locations` for publishing one contract-first
(`07-io.md § Web Services (SOAP)`). rakun has neither, and a service asked to call an existing
billing, logistics or government endpoint — the places SOAP still lives — has no path to it.

The reference is short and the work behind it is not, which is the thing this front has to be honest
about. `WebServiceTemplate.marshalSendAndReceive(req, new SoapActionCallback(...))` hides a JAXB
binding generated from an XSD, an envelope codec, a fault model and a transport. Only the last two
are small. Pretending otherwise would produce a front that is scoped in one paragraph and unfinishable
in practice, so the scope below is written as a subset with an explicit refusal list, and the refusal
list is part of the deliverable rather than an apology.

## Current state

Examples use the pre-118 effect annotations; front 24's codemod rewrites them ([`00 · 24-effects-by-return`](../../00-compiler-carry-over/24-effects-by-return/README.md)).

- `repository/rakun/modules/` holds no `rakun-ws`. The directory this front owns does not exist.
- There is no XML anything in the workspace: no parser, no serializer, no schema reader.
  `libs/std/src/root.bp:13-36` lists twenty-four modules and none of them is XML.
- `repository/rakun/modules/rakun-client/src/root.bp` — a stub; front 13 lands the HTTP client this
  front posts through.
- Ground truth §2.2 — a comptime body sees only a minimal native-JS prelude with no filesystem
  access. A schema-driven `@Expr` template cannot read a `.wsdl` file, and that decides where the
  code generation runs.

## Mechanism

**The subset this front targets.**

| Area | Targeted |
|---|---|
| Envelope | SOAP 1.1 (`http://schemas.xmlsoap.org/soap/envelope/`) and SOAP 1.2 (`http://www.w3.org/2003/05/soap-envelope`) |
| Style | document/literal *wrapped* — the style every modern endpoint publishes |
| Transport | HTTP and HTTPS through front 13, with the `SOAPAction` header |
| Contract | WSDL 1.1 with an inline or imported XSD |
| Schema | `element`, `complexType` with `sequence` and `all`, `simpleType` restrictions over `string`, `int`, `long`, `boolean`, `decimal`, `dateTime` and `base64Binary`, `minOccurs`/`maxOccurs` mapped to optionals and arrays, `nillable`, and enumerations |
| Faults | `soap:Fault` decoded into a typed error, not a string |
| Security | WS-Security UsernameToken (`PasswordText` with `Nonce` and `Created`, over TLS) |

**What this front refuses, in writing.**

RPC/encoded style · `xsd:choice` · substitution groups · `xsd:any` and `anyType` · mixed content ·
recursive type graphs beyond a configured depth · `xsd:import` across the network · MTOM/XOP
attachments · WS-Addressing · WS-ReliableMessaging · WS-Policy · WS-AtomicTransaction ·
signature- and encryption-based WS-Security.

Each refusal is a located error naming the construct, not a silent mis-binding. A generator that
quietly maps `xsd:choice` onto a record with every branch optional produces a client that compiles
and sends invalid documents, and the endpoint's rejection arrives weeks later. Refusing at
generation time is the whole reason the list exists. UsernameToken is the single WS-* inclusion
because most real endpoints demand *something* and it is the cheapest something that works; anything
signature-based needs XML canonicalization, which is a project rather than a step.

**Code generation is a CLI step, not comptime, and the reason is verifiable.** The natural botopink
shape would be `wsdl """…"""` as a comptime template function. It cannot work: a comptime body sees
only a minimal native-JS prelude with no filesystem access (ground truth §2.2), so it cannot read a
`.wsdl` file, and inlining a multi-thousand-line schema into a string literal is not a design. So
`rakun ws generate --wsdl billing.wsdl --out src/billing/` (front 88) emits ordinary `.bp` — record
types, an operation behavior, and one marshaller per type — which is checked into the project and
read like any other source. Three consequences follow and all three are improvements: the generated
code is reviewable in a diff, a schema change is visible as a source change rather than as a silent
rebuild, and the compiler never learns what XML is.

**Marshalling runs over `xmerl` and `erlsom`.** Both ship with or alongside OTP; `xmerl` parses, and
`erlsom`'s schema support is the reference this front's generator follows for the subset above. The
runtime half is small because the generated marshaller knows its own shape: a record in, an element
out, field by field, with escaping applied once at the leaf.

**A fault is an `Error`, not an exception.** A generated operation is a `#[@result] fn` returning
`@Result<Response, SoapFault>`; `throw` inside it produces the `Error` arm, and a caller matches
`case r { Ok(result) -> …; Error(error) -> …; }`. `SoapFault` carries the fault code, the reason, the
actor and the detail element as text. HTTP 500 with a fault body is a fault and not a transport
error — conflating the two is the most common SOAP client bug, and this front tests the distinction.

**Publishing is a route, not a listener.** A contract-first endpoint is mounted on front 07's chain
at its configured path, serves its WSDL at `<path>?wsdl` (mirroring
`spring.webservices.wsdl-locations`), and dispatches on the wrapped element name. The one case that
touches front 15's listener registry is a *one-way* SOAP message delivered over a queue: the envelope
codec is transport-independent, so that case reuses front 90's `#[jmsListener]` arm and adds no
transport here. This front registers no arm of its own with front 15.

**Target.** Calls and endpoints both run while a request is in flight, so both are erlang. Host cells
are `#[@External.Erlang]` over `xmerl` and `erlsom`; the HTTP transport is front 13's. There is no
`@External.Node` cell in this front.

## Steps

### Step 1 — The envelope codec

```bp
pub fn soapEnvelope(version: string, bodyXml: string) -> string
pub fn soapBody(envelopeXml: string) -> string
```

**Acceptance:**
- [ ] A 1.1 envelope carries the `http://schemas.xmlsoap.org/soap/envelope/` namespace and a 1.2 envelope carries `http://www.w3.org/2003/05/soap-envelope`; neither is written into the other's document.
- [ ] `soapBody(soapEnvelope(v, x))` returns `x` for both versions, including when the body contains a nested element named `Body`.
- [ ] `&`, `<`, `>`, `"` and `'` are escaped exactly once at leaf values and never in element names.
- [ ] A document with a prefix other than `soap:` — `s11:`, `env:`, none at all — is read correctly; the prefix is not assumed.

### Step 2 — The schema subset and its refusals

**Acceptance:**
- [ ] Every construct in the *targeted* table generates, asserted by a fixture schema exercising each one.
- [ ] Every construct in the *refused* list produces a located error naming the construct and the element it appeared in — thirteen refusals, thirteen tests.
- [ ] `minOccurs="0"` becomes `?T` and `maxOccurs="unbounded"` becomes `T[]`; both together become `?T[]` with the documented reading.
- [ ] An enumeration becomes an enum-shaped `type`, and an unknown value in a response is an error rather than a silent empty.
- [ ] A recursive type beyond the configured depth is refused, not expanded until the generator runs out of memory.

### Step 3 — The generator

```
rakun ws generate --wsdl billing.wsdl --out src/billing/
```

**Acceptance:**
- [ ] The generated tree compiles with `botopink build --target erlang` and its own generated tests pass, with no hand edits.
- [ ] Re-running the generator over an unchanged WSDL produces byte-identical output — a generator whose output churns cannot be reviewed in a diff.
- [ ] Generated files carry a header naming the source WSDL and its content hash, so a stale generation is visible.
- [ ] A WSDL with an `xsd:import` pointing at a network URL is refused; a local relative import is followed.

### Step 4 — The client

```bp
pub type WsClient(endpoint: string, version: string, timeoutMs: i32)

#[@result]
pub fn wsCall(client: WsClient, action: string, bodyXml: string) -> @Result<string, SoapFault>
```

**Acceptance:**
- [ ] The `SOAPAction` header is sent for 1.1 and folded into the `Content-Type` `action` parameter for 1.2.
- [ ] A 200 with a normal body returns `Ok`; a 500 with a `soap:Fault` body returns `Error` carrying the decoded fault; a 500 with a non-XML body returns `Error` carrying a transport fault, distinguishably.
- [ ] A connection timeout is a transport error and never a fault.
- [ ] TLS material comes from front 74's bundle registry.

### Step 5 — Faults

```bp
pub type SoapFault(
    code: string,
    reason: string,
    actor: string,
    detail: string,
)

pub fn parseFault(bodyXml: string) -> ?SoapFault
```

**Acceptance:**
- [ ] `parseFault` returns `null` for a normal response body and a filled record for a fault, matched as `case f { null { … } fault { … } }`.
- [ ] Both the 1.1 shape (`faultcode`/`faultstring`/`faultactor`) and the 1.2 shape (`Code/Value`, `Reason/Text`, `Role`) decode into the same record.
- [ ] `detail` preserves the raw detail element, so an application can read an endpoint-specific error code the generator never saw.

### Step 6 — Publishing an endpoint

**Acceptance:**
- [ ] A generated endpoint mounts at its configured path through front 07 and dispatches on the wrapped element name.
- [ ] `<path>?wsdl` serves the source WSDL unmodified, and the served document's content hash matches the one in the generated header.
- [ ] A request whose wrapped element matches no operation is answered with a `soap:Fault` — a client sending the wrong document must get a fault, not a 404.
- [ ] A malformed envelope is answered with a client fault and does not crash the handler process.

### Step 7 — WS-Security UsernameToken

**Acceptance:**
- [ ] The outgoing header carries `Username`, `PasswordText`, a fresh `Nonce` and a `Created` timestamp.
- [ ] The nonce differs between two calls, asserted by capturing both.
- [ ] Sending a `PasswordText` token over plain HTTP is refused at boot unless an explicitly named override is set, and the override is named in the README as a development-only setting.
- [ ] An incoming token is verified against the configured credentials on a published endpoint, and a replayed nonce within the configured window is rejected.

## Examples

- [`examples/soap-client-example.bp`](./examples/soap-client-example.bp) — calling a generated
  operation, handling a fault as a `@Result` error, and the envelope and fault decoding asserted
  against real documents.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| **A comptime body has no filesystem access** — it sees only a minimal native-JS prelude (ground truth §2.2). A `wsdl """…"""` template function cannot read a schema, which is why generation is a CLI step and not comptime. | `examples/soap-client-example.bp`, the header comment over the generated types | `rakun ws generate` (front 88) emits checked-in `.bp` source, read like any other module. | A comptime capability for reading a declared build input, sandboxed to the project directory |
| **Declared parameter defaults are never applied** — the row already in [`language-gaps.md`](../../language-gaps.md). A generated operation cannot leave an optional element out of its call. | `examples/soap-client-example.bp`, the request record | Every field is passed; a `minOccurs="0"` element is `?T` and is passed as `null`. | Apply declared defaults at call sites |

## Test plan

`modules/rakun-ws/test/` on the **erlang** target, invoked as
`zig build test-libs -- --target erlang --lib rakun` from `repository/botopink-lang/`, and as
`botopink test --target erlang` from `repository/rakun/`.

| File | Asserts |
|---|---|
| `test/envelope_test.bp` | Both versions, round trip, escaping, arbitrary prefixes |
| `test/schema_test.bp` | Every targeted construct generating, and each of the thirteen refusals failing by name |
| `test/generator_test.bp` | The generated tree compiling and passing its own tests, byte-identical re-generation, the content-hash header |
| `test/client_test.bp` | SOAPAction per version, the three response classes, timeouts, TLS bundles |
| `test/fault_test.bp` | Both fault shapes into one record, `null` for a normal body, raw detail preservation |
| `test/endpoint_test.bp` | Mounting, `?wsdl`, the no-operation fault, the malformed-envelope fault |
| `test/security_test.bp` | Token contents, nonce freshness, the plain-HTTP refusal, replay rejection |

The envelope, schema, fault and security cells are pure and run against documents checked into the
test directory — a SOAP client is testable entirely from fixtures, and this front uses that. The
client and endpoint cells run against a local endpoint this front publishes, so no external service
is needed there either.

There is no commonJS row. This front is server-only by the milestone's target split.

## Definition of done

- `modules/rakun-ws/` exists, is declared from its `root.bp`, holds no `@External.Node` cell, and its README opens by saying it is web services and not WebSocket.
- The targeted subset and the thirteen refusals are in the module README, each refusal with a test behind it.
- `rakun ws generate` is a front 88 subcommand, and generating twice over one WSDL produces identical bytes.
- A fault, a transport error and a timeout are three distinguishable outcomes, proven by three tests.
- No WS-* beyond UsernameToken appears in the source, and the README says why.
- Both language-gap rows appear in [`language-gaps.md`](../../language-gaps.md) — the comptime-filesystem row is new and is filed there by this front.
- `repository/rakun/AGENTS.md` and `modules/README.md` record the module in the same commit.
- The front's tests are green on erlang.

