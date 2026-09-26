# Front 74 — rakun TLS and SSL Bundles

**Track:** B rakun
**Priority:** high — five subsystems in the reference reach for a named SSL bundle and none owns one; without this front rakun cannot terminate HTTPS, cannot reach a TLS Redis or a TLS broker, cannot present a client certificate, and the `ssl` health indicator has nothing to report on
**Target:** erlang (server)
**Wave:** 2
**Depends on:** 04 · 05
**Owns:** `src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`, `modules/rakun-web/src/tls.bp` · `test/ssl_bundle_test.bp`, `modules/rakun-web/test/tls_test.bp`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs`; `modules/rakun-web/src/middleware.bp`, `cors.bp`, `error.bp`, `filter.bp`, `convention.bp` — front 07's files
**Reference:** `04-web.md § Container Servlet Embutido · Customizando o servidor` · `05-data.md § Redis · SSL`, `§ Couchbase · Autenticacao com Certificado` · `07-io.md § WebClient (Reativo) · SSL` · `09-actuator.md § SSL Diferente para Management`, `§ HealthIndicators Auto-configurados`, `§ InfoContributors Auto-configurados` · <https://docs.spring.io/spring-boot/reference/features/ssl.html>

---

## Problem

Without this front every transport rakun opens is plaintext: front 04's `gen_tcp` listener has no path
to TLS and nowhere to put the
material if it did. The same hole appears on the outbound side: front 13's HTTP clients, front 08's SQL
driver, front 09's Redis connection and front 15's broker connections each need a certificate, a key
and a trust store, and each would have to invent its own three properties for them.

Spring solved this in 3.1 by naming the material instead of the consumer. A bundle is a named group —
`spring.ssl.bundle.pem.mybundle.*` — and every subsystem refers to it by name:
`server.ssl.bundle=mybundle`, `spring.data.redis.ssl.bundle=example` (`05 § Redis · SSL`),
`ssl.fromBundle("mybundle")` for a client (`07 § WebClient · SSL`),
`management.server.ssl.*` for the management listener (`09 § SSL Diferente para Management`). One
registry, five consumers, and rotating a certificate is one edit.

The consequence of not having it is not "rakun cannot do HTTPS" — a reverse proxy can terminate TLS.
It is that rakun cannot be the thing making a TLS *connection*: no mutual TLS to an internal service,
no certificate-authenticated database connection, no `ssl` health indicator warning that a certificate
expires in four days. Those are the cases where a proxy does not help.

## Mechanism

### Why this is plumbing and not cryptography

OTP ships `ssl` and `public_key` in the standard distribution. `ssl:listen/2` and `ssl:connect/4`
already do TLS 1.2 and 1.3, SNI, ALPN, session reuse and peer verification;
`public_key:pkix_decode_cert/2` already reads a certificate's validity window and subject. This front
writes no protocol code. It writes a registry that turns configuration into an option list, and the
glue that hands that option list to five callers.

It is also the reason the front is safe where front 04's cowboy decision was not: `ssl` is part of
`OTP`, so `application:ensure_all_started(ssl)` cannot fail for the reason `cowboy:start_clear/3` would.

### The bundle model

A bundle is a name, some material, and a verification posture.

```
rakun.ssl.bundle.pem.<name>.keystore.certificate     path to the PEM chain we present
rakun.ssl.bundle.pem.<name>.keystore.private-key     path to the PEM key
rakun.ssl.bundle.pem.<name>.keystore.private-key-password
rakun.ssl.bundle.pem.<name>.truststore.certificate   path to the PEM CA bundle we verify against
rakun.ssl.bundle.pem.<name>.protocols                tlsv1.3,tlsv1.2 — the default is both, in that order
rakun.ssl.bundle.pem.<name>.ciphers                  a cipher list; empty means OTP's default
rakun.ssl.bundle.pem.<name>.client-auth              none | want | need  (server side)
rakun.ssl.bundle.pem.<name>.verify                   full | none        (client side)
rakun.ssl.bundle.pem.<name>.reload-on-update         false by default
```

Property names follow Spring's with `spring` replaced by `rakun`, so the reference's own examples
transliterate without a lookup table.

**PEM is the format.** OTP reads PEM and DER natively. PKCS#12 is accepted where the installed OTP's
`public_key` can decode it, and the failure when it cannot names the OTP version and the file. **JKS is
refused**, with a message naming the `keytool` command that converts it: a Java keystore is a JVM
container format, and accepting it would mean shipping a parser for it. That is a deliberate
restriction and there is no property that lifts it.

### The two postures, and why they are separate properties

`client-auth` is what a *server* demands of a connecting client: `none` (ask for nothing), `want`
(ask, accept a connection without one), `need` (refuse a connection without one). It maps to
`{verify, verify_peer}` plus `{fail_if_no_peer_cert, Bool}`.

`verify` is what a *client* demands of the server it reaches: `full` verifies the chain and the
hostname, `none` verifies nothing. `full` is the default and `none` is only ever correct in a test.
The registry logs a warning naming the bundle every time `none` is resolved, because a `verify: none`
that was set for a Tuesday afternoon and never removed is the most common way a TLS deployment is
insecure while looking fine.

### The transport seam

Front 04's listener is a `gen_tcp` acceptor. OTP's `ssl` module exposes the same five functions with
the same shapes — `listen/2`, `transport_accept/1` + `handshake/2`, `send/2`, `recv/3`, `close/1` — so
the acceptor takes the transport *module* as a parameter rather than branching on it, the way
`ranch_tcp` and `ranch_ssl` are interchangeable. `rakun_ssl:listener_opts/1` answers
`{gen_tcp, Opts}` for a listener with no bundle and `{ssl, Opts}` for one with a bundle, and front 04's
acceptor loop is unchanged apart from the module variable.

The one difference that is not symmetric is the handshake: `ssl:handshake/2` must run in the process
that will own the socket, not in the acceptor, or a slow or hostile client blocks every other
connection from being accepted. So the connection process performs the handshake as its first act, with
`rakun.ssl.handshake-timeout` (default 5000 ms) bounding it. That is a real denial-of-service
difference and it is why this is a step rather than a line.

### Reload without a restart

A certificate is rotated far more often than a process is restarted, and on the BEAM there is no
reason for the two to be connected. `rakun_ssl` keeps each bundle's resolved material in ETS keyed by
name. `rkSslReload(name)` re-reads the files and replaces the entry; with `reload-on-update=true` a
`gen_server` polls the files' mtimes on an interval (`rakun.ssl.reload-interval`, default 60000 ms) and
calls the same function.

A reload that fails — file gone, key and certificate do not match, chain does not verify — **keeps the
previous material** and records the failure in the bundle's state, where the health indicator finds it.
Replacing a working certificate with a broken one at 3am because a deploy half-wrote a file is a worse
outcome than serving the old one for another hour.

Existing connections keep the material they handshook with; OTP gives no way to change it underneath
them and there is no reason to want one. New connections use the new material.

### The health indicator and the info contributor

Both are front 11's SPI and this front implements the `ssl` key for each
(`09 § HealthIndicators Auto-configurados`, `§ InfoContributors Auto-configurados`).

- Health: `UP` when every bundle resolves and no certificate expires within
  `rakun.ssl.health.warn-threshold` (default 14 days). `OUT_OF_SERVICE` when a certificate is inside
  the threshold. `DOWN` when a bundle fails to resolve or its last reload failed. Details name the
  bundle, the subject, and the days remaining — a health check that says `DOWN` without naming which
  certificate is a page nobody can act on.
- Info: per bundle, the subject, the issuer, the not-before and not-after instants, and the days
  remaining. No key material, no fingerprint of the private key, nothing that is worse to leak than the
  certificate itself, which is public by construction.

Both are gated by front 76's exposure and sanitization rules like every other endpoint.

### The interface the five consumers use

```bp
pub type SslBundle(
    name: string,
    certificateFile: string,
    privateKeyFile: string,
    trustStoreFile: string,
    protocols: string,
    ciphers: string,
    clientAuth: string,
    verify: string,
)

pub fn sslBundle(name: string) -> ?SslBundle;
pub fn sslBundleNames() -> string[];
pub fn sslExpiryDays(name: string) -> i32;
pub fn sslReload(name: string) -> bool;
```

and the host seams, `#[@External.Erlang("rakun_ssl", …)]` only:

| Cell | Shape | Consumer |
|---|---|---|
| `rkSslListenerOpts` | `(bundle: string) -> string` | front 04's acceptor, front 76's management listener |
| `rkSslClientOpts` | `(bundle: string, host: string) -> string` | fronts 08, 09, 13, 15 |
| `rkSslReload` | `(bundle: string) -> bool` | this front's watcher, and an operator through front 11 |
| `rkSslExpiryDays` | `(bundle: string) -> i32` | the health indicator and the info contributor |
| `rkSslSubject` | `(bundle: string) -> string` | the info contributor |
| `rkSslLastError` | `(bundle: string) -> string` | the health indicator; `""` when the last resolve succeeded |

The option cells answer an encoded option list rather than an Erlang term because a `declare fn` has to
have a botopink return type, and there is no term type. The encoding is the same line-oriented blob the
rest of the milestone uses (`key|value` per record, `;` between records), decoded by `rakun_ssl` itself
before it reaches `ssl:listen/2`. A consumer never parses it — it passes it back.

## Steps

### Step 1 — the registry: configuration to resolved material

`sslBundles()` walks front 05's property table for `rakun.ssl.bundle.pem.*`, groups by the `<name>`
segment, reads each file once through `io.fs`, and stores the resolved material in ETS. A bundle with
a certificate and no key, or a key and no certificate, is a startup failure naming the bundle and the
missing half.

**Acceptance:**
- [ ] Two bundles configured independently resolve independently, and one failing does not prevent the other from resolving
- [ ] A bundle naming a file that does not exist fails at startup, naming the bundle, the property and the absolute path searched
- [ ] A certificate and a key that do not correspond fail at startup, naming the bundle — not at first handshake
- [ ] A JKS file is refused with a message naming `keytool -importkeystore -deststoretype PKCS12`, and there is no property that accepts it anyway
- [ ] `sslBundleNames()` lists every configured bundle in property order
- [ ] `sslBundle("absent")` answers the empty optional; reading it with `if (b) { … }` is the documented form

### Step 2 — the server listener

`rkSslListenerOpts/1` produces the `ssl:listen/2` option list; front 04's acceptor takes the transport
module from the same call. `rakun.server.ssl.bundle` names the listener's bundle; absent, the listener
is plaintext and nothing in this front runs.

**Acceptance:**
- [ ] With no bundle named, the listener is `gen_tcp` and byte-for-byte the same behaviour front 04 tests
- [ ] With a bundle named, a TLS 1.3 client completes a handshake and receives the handler's body
- [ ] `protocols=tlsv1.2` refuses a TLS 1.3-only client, and the refusal is logged with the bundle name
- [ ] The handshake runs in the connection process: a client that opens a socket and sends nothing does not delay the acceptance of a second connection
- [ ] `rakun.ssl.handshake-timeout=200` closes such a connection within 500 ms
- [ ] A handshake failure is logged once, with the peer address and the reason, and does not crash the acceptor

### Step 3 — mutual TLS

`client-auth=need` sets `{verify, verify_peer}` and `{fail_if_no_peer_cert, true}` against the bundle's
trust store. The peer's subject is made available to the handler through the request, so front 10 can
authenticate on it.

**Acceptance:**
- [ ] `client-auth=none` accepts a client presenting no certificate and one presenting an untrusted certificate
- [ ] `client-auth=want` accepts a client presenting none, and rejects one presenting a certificate the trust store does not verify
- [ ] `client-auth=need` rejects a client presenting none
- [ ] A handler can read the verified peer subject, and reads `""` when there was none
- [ ] The peer subject is never read from an unverified certificate — `want` with an unverified peer is a rejected connection, not an empty subject

### Step 4 — client-side bundles

`rkSslClientOpts/2` produces the `ssl:connect/4` option list, including `{server_name_indication, Host}`
and hostname verification for `verify=full`. Fronts 08, 09, 13 and 15 call it with the bundle their own
configuration names.

**Acceptance:**
- [ ] `verify=full` refuses a server whose certificate does not match the requested hostname
- [ ] `verify=full` refuses a server whose chain does not verify against the bundle's trust store
- [ ] `verify=none` connects to both, and resolving it logs a warning naming the bundle
- [ ] A bundle with only a trust store — no client certificate — is valid and produces a verify-only option list
- [ ] The same bundle name is usable by a listener and by a client without conflict

### Step 5 — reload

`sslReload(name)` and the mtime watcher. A failed reload keeps the previous material and is recorded.

**Acceptance:**
- [ ] `sslReload` after replacing both files on disk makes the next handshake present the new certificate
- [ ] A connection established before the reload continues with the old material and is not dropped
- [ ] A reload whose certificate and key do not match keeps the old material and returns false
- [ ] `rkSslLastError` names the reason for the last failed reload and is `""` after a successful one
- [ ] `reload-on-update=false` does not poll — with the property off, no filesystem call happens on the interval
- [ ] `reload-on-update=true` picks up a rotated certificate within two intervals

### Step 6 — health and info

Implement the `ssl` key for front 11's two SPIs.

**Acceptance:**
- [ ] A certificate expiring in 30 days with a 14-day threshold reports `UP`
- [ ] A certificate expiring in 3 days reports `OUT_OF_SERVICE` and names the bundle and the days remaining
- [ ] An already-expired certificate reports `DOWN`
- [ ] A bundle whose last reload failed reports `DOWN` with the reload error as the detail
- [ ] The info contribution carries subject, issuer, not-before, not-after and days remaining per bundle, and no key material
- [ ] With no bundles configured, the `ssl` indicator reports `UP` with an empty detail rather than being absent — "no TLS configured" and "TLS broken" must not look the same

## Examples

- [`examples/https-listener-example.bp`](./examples/https-listener-example.bp) — configuring a PEM
  bundle, pointing the listener at it, and reading the expiry back. This is the file an operator's
  change lands in.
- [`examples/mutual-tls-client-example.bp`](./examples/mutual-tls-client-example.bp) — a service that
  presents a client certificate to an internal API and demands one from its own callers, with the
  management listener on a second bundle.

## Language gaps

None — every construct in the examples parses today.

Two near misses are worth recording so the next reader does not rediscover them. A host cell must have
a botopink return type and there is no Erlang-term type, which is why the option cells answer an encoded
string; that is a design consequence of `declare fn`, not a gap, and the alternative — one cell per
option — would be worse. And `sslBundle` returns `?SslBundle`, read with `if (b) { bundle -> … }`,
because a `case` arm that is a bare lower-case name is a located error (`use _ {`); that is the
documented idiom, not a limitation this front hit.

## Test plan

`test/ssl_bundle_test.bp` and `modules/rakun-web/test/tls_test.bp`, run with
`botopink test --target erlang` from `repository/rakun/` and in the gate as
`zig build test-libs -- --target erlang --lib rakun`.

The tests need certificates. They are generated at test setup by `rakun_ssl:selftest_material/1`, which
calls `public_key` to produce a CA, a server certificate, a matching client certificate and a
deliberately-mismatched key into a temporary directory — no fixture files are committed, because a
committed certificate expires and turns a whole front red on a date nobody chose. The expiry tests
generate certificates with explicit validity windows for the same reason.

This front is erlang-only and the reason is unusually clean: `ssl` and `public_key` are OTP
applications and there is no Node form of any cell here. A commonJS run compiles the `.bp` and fails at
the first call, which is the target split working.

The sidecar module atom is `rakun_ssl`, not `ssl` and not `ssl_bundle`. `ssl` would shadow OTP's own
module; `ssl_bundle` is the basename of this front's emitted module and would be skipped by the sidecar
shipper for the reason front 04 documented.

## Definition of done

- A named bundle resolves from configuration, is stored once, and is reachable by name from five
  subsystems
- The listener terminates TLS, with the handshake in the connection process and a bounded timeout
- Mutual TLS works in all three postures and a handler can read a verified peer subject
- A rotated certificate is picked up without a restart, and a broken rotation does not take the service
  down
- The `ssl` health indicator distinguishes "no TLS configured", "expiring", "expired" and "broken"
- JKS is refused with an actionable message and no property accepts it
- The front's tests are green on its assigned target

