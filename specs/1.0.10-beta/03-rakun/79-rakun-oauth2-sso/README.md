# Front 79 — rakun OAuth2 and SSO

**Track:** B rakun
**Priority:** high — front 10 validates a token somebody else issued; it cannot log a user in against an identity provider, which is how essentially every real application authenticates
**Target:** erlang (server)
**Wave:** 5
**Depends on:** 01 (`crypto`, `random`, `base64`, `regex`), 05 (provider configuration), 10 (the security context, the authority list, JWT signature verification), 13 (token and JWKS fetch), 18 (the session the flow's state lives in), 74 (the TLS bundle every provider connection uses), 11 (registers the `ldap` health indicator)
**Owns:** `modules/rakun-security/src/oauth2/**`, `modules/rakun-security/src/oidc/**`, `modules/rakun-security/src/ldap/**`, `modules/rakun-security/src/saml2/**` · `modules/rakun-security/test/oauth2/**`, `test/oidc/**`, `test/ldap/**`, `test/saml2/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen for the milestone. Also `modules/rakun-security/src/*.bp` at the top level, which is front 10's
**Reference:** `04-web.md § OAuth2` · `04-web.md § SAML 2.0` · `05-data.md § LDAP` · `06-messaging.md § Apache Pulsar · Autenticacao OAuth2` · <https://docs.spring.io/spring-boot/reference/web/spring-security.html> · <https://docs.spring.io/spring-boot/reference/data/nosql.html#data.nosql.ldap>
**Replaces:** new — proposed by the Spring Boot 4 coverage audit, § 2 `NN-rakun-oauth2-sso`, plus the fold-in rows *SAML 2.0* and *LDAP / directory authentication*

---

## Problem

A rakun application can be told who a caller claims to be, and cannot find out who they are. Front 10
delivers authentication, authorization, JWT verification and method security — all of which start
from a credential that already exists. Nothing in the milestone produces one. There is no way to send
a browser to an identity provider, no way to exchange an authorization code for a token, no way to
discover a provider's endpoints, no way to fetch the keys the provider signs with, and no way to
authenticate a username and password against a directory.

The consequence is concrete. An application that wants "log in with the company identity provider" —
the default for every internal service written in the last decade — has to hand-write the
authorization-code flow: build the redirect, generate and store a PKCE verifier, survive the
round trip, POST the code to the token endpoint, verify the ID token against a key set it also has
to fetch and rotate, and turn the result into whatever value front 10's security context holds. That
is several hundred lines of protocol per application, written once per application, wrong in a
different place each time. It is exactly the work a framework exists to do once.

The same is true one layer down. A service that calls another service has no way to get a token of
its own; the client-credentials grant is four lines of protocol and nobody has written them, so
service-to-service calls end up carrying a static shared secret in a header. And an application on a
corporate network that wants to authenticate against LDAP has OTP's `eldap` sitting in the release
already, with nothing in botopink that reaches it.

## Current state

| Piece | Where it is today |
|---|---|
| `modules/rakun-security/` | `botopink.json` plus `src/root.bp`, whose entire body is the comment *"Module contents will be added by the respective fronts."* |
| Anything OAuth2, OIDC, SAML or LDAP | does not exist, in rakun or in std |
| `crypto` | `sha256`, `sha512`, `md5`, `hmacSha256`, `randomBytes` — `libs/std/src/crypto.bp`. Enough for PKCE and state; **not** enough for RSA/ECDSA signature verification |
| `base64` | `encode`, `decode`, `encodeUrlSafe`, `decodeUrlSafe` — `libs/std/src/base64.bp`. JWT segments are url-safe base64, so this is the right primitive already |
| `json` | `parse`/`stringify`, both `string -> @Result<string, string>`; **no structured walker** (`libs/std/src/json.bp:9-16`). Reading a claim out of an ID token needs one |
| `http.fetch` | `pub declare fn fetch(url: string) -> @Future<Response>` — `libs/std/src/http.bp:55`. GET only, no POST, no form body. Front 13 is the real client |
| An HTTP request's inputs | `req.header(name)`, `req.query(name)`, `req.param(name)`, `req.body()` — all plain `string`, `""` when absent (`src/http.bp:30-43`) |
| A response's headers | there is no header field on `Response` and no builder for one. Front 04 adds `rkSetReplyHeader/2`; the redirect in step 3 depends on it |

Two absences decide the shape of this front. There is no structured JSON reader, so every claim and
every discovery-document field is read through a small accessor this front owns rather than by
walking a value. And there is no public-key cryptography in std, so RSA and ECDSA verification is a
host cell over OTP's `public_key` — which front 10 already needs for JWT and therefore already owns.

## Mechanism

### The boundary with front 10

Front 10 owns *what a credential means*: the security context, the principal, the authority list,
method security, and the JWT verifier itself. This front owns *where a credential comes from*: the
protocol that produces one and the key material that validates it.

| Concern | Front |
|---|---|
| Parse a JWT, check its signature against a supplied key, check `exp`/`nbf` | 10 |
| Decide *which* key — fetch the JWKS, cache it, select by `kid`, re-fetch on rotation | **79** |
| Issuer, audience and nonce policy | **79** |
| Map `scope` and `roles` claims to authorities | **79** produces the list, **10** enforces it |
| `#[secured]` / `#[preAuthorize]` | 10 |
| Authorization-code, PKCE, refresh, client-credentials | **79** |
| Username/password against a directory | **79** (provider) registered into **10**'s authentication manager |

A front-79 login therefore ends by handing front 10 a `Principal` and an authority list, and
everything downstream — `#[secured]`, the filter chain, the session — is unchanged.

### The flow, and where each half runs

Everything in this front is server-side and compiles to BEAM. The browser's only participation is
following two redirects, which is what makes the authorization-code flow safe to run from a server in
the first place: the client secret, the PKCE verifier and the token never reach the browser.

```
GET /oauth2/authorization/keycloak
  ├─ generate verifier (43+ chars, base64url of 32 random bytes)
  ├─ challenge = base64url(sha256(verifier))            crypto + base64, front 01
  ├─ state, nonce = base64url(16 random bytes) each
  ├─ store {verifier, nonce, returnTo} under `state`     session, front 18
  └─ 302 to <authorization_endpoint>?…&code_challenge_method=S256

GET /login/oauth2/code/keycloak?code=…&state=…
  ├─ look up `state`; absent or already used  → 400, nothing else happens
  ├─ POST code + verifier to <token_endpoint>            client, front 13
  ├─ verify the ID token: kid → JWKS → front 10's verifier
  ├─ check iss, aud, nonce, exp with a configured skew
  ├─ Principal + authorities → front 10's security context
  └─ 302 to the stored returnTo
```

Both handlers are registered by this front at boot, through `rkRegisterRoute` — the same table every
`#[getMapping]` lands in. They are not decorators the application writes; the application writes a
provider record and gets the two endpoints.

### Where the comptime work is

Very little of this front is comptime, and saying so is part of the design. The flow is protocol, and
protocol is run-time code. Three things are comptime:

- `#[oauth2Provider]` on a `#[bean]` method: checks at compile time that the method returns an
  `OAuth2Provider`, that its `id` is a literal, and `@emit`s the registration call into the module —
  the same `@emit`ted-wiring shape `#[bean]` already uses (`src/decorators.bp:49`).
- `#[clientCredentials("registration-id")]` on a front-13 client field: `@emit`s the interceptor that
  attaches a bearer token, so the service body never mentions a token at all.
- `#[ldapAuthentication]` on a `#[configuration]` record: registers the directory provider with front
  10's authentication manager.

Everything else — discovery, exchange, verification, refresh, bind-and-search — is ordinary botopink
calling host cells.

### Host cells this front adds

All Erlang-only, all in `modules/rakun-security/src/oauth2/` and `src/ldap/` with their `.erl`
sidecars. None carries a Node form: this is a server front.

| Cell | OTP behind it | Why it cannot be botopink |
|---|---|---|
| `rkJwkToPem(jwkJson) -> string` | `public_key` | Converts a JWKS entry's modulus/exponent into a key term. Bignum arithmetic on base64url digits |
| `rkVerifyRs256(signingInput, sig, pem) -> bool` | `public_key:verify/5` | Front 10 owns the JWT shape; this is the key-material half it calls |
| `rkJsonField(json, path) -> string` | `jsx`-free hand-rolled scan, or `json` in OTP 27+ | std's `json` has no walker. `""` when absent, so no optional crosses the boundary |
| `rkLdapOpen(urlsCsv, timeoutMs) -> i32` | `eldap:open/2` | Returns a handle id into an ETS table; `eldap` handles are pids |
| `rkLdapBind(handle, dn, password) -> i32` | `eldap:simple_bind/3` | |
| `rkLdapSearch(handle, base, filter, attrsCsv) -> string` | `eldap:search/2` | Returns one `key=value` line per attribute; the bp side splits |
| `rkLdapClose(handle) -> i32` | `eldap:close/1` | |
| `rkDeflate(s) -> string` / `rkInflate(s) -> string` | `zlib` | SAML's HTTP-Redirect binding is deflate + base64 |

`eldap` and `public_key` both ship with OTP. Nothing here adds a dependency to the release, which is
the reason the audit chose them.

### The JWKS cache

A key set is fetched once per issuer and held in ETS with the issuer as the key. A token whose `kid`
is absent from the cached set triggers exactly one re-fetch, rate-limited to one per configured
interval (default 30s) so a token with a garbage `kid` cannot be used to hammer the provider. A
fetch failure does not evict the cached set: an identity provider being briefly unreachable must not
log every user out.

### SAML, and why it is last

SAML 2.0 is in the doc set (`04-web.md § SAML 2.0`) and it is a protocol, not a JVM mechanism, so the
audit does not defer it. It is nonetheless the last deliverable here and the first thing to cut,
because verifying an assertion means XML canonicalization (`xml-exc-c14n`) followed by signature
verification, and OTP ships `xmerl` but not c14n. Writing canonicalization is a week on its own and
getting it subtly wrong is a silent authentication bypass, which is the worst failure mode in this
document.

The rule for cutting it: if step 8 does not land, the front ships the SP metadata endpoint and the
`AuthnRequest` builder and **refuses** the assertion-consumer path with a 501 naming the missing
verifier. It does not ship an assertion path that skips or weakens signature checking. A front that
half-verifies a SAML assertion is worse than a front that has no SAML at all.

## Steps

### Step 1 — Provider registry and discovery

An `OAuth2Provider` is a record built by the application, usually from configuration, and registered
by a `#[bean]` method. `issuerUri` is enough on its own: the OIDC discovery document supplies the
authorization, token, userinfo and JWKS endpoints. An application against a non-OIDC OAuth2 server
sets the four endpoints explicitly instead, and discovery is skipped.

```bp
pub type OAuth2Provider(
    id: string,
    clientId: string,
    clientSecret: string,
    issuerUri: string,
    scopes: string[],
    pkce: bool,
    redirectPath: string,
)

pub type ProviderEndpoints(
    authorization: string,
    token: string,
    userinfo: string,
    jwks: string,
    issuer: string,
)

pub fn discover(p: OAuth2Provider) -> ProviderEndpoints
pub fn registerProvider(p: OAuth2Provider) -> i32
```

**Acceptance:**
- [ ] `discover` fetches `<issuerUri>/.well-known/openid-configuration` exactly once per issuer per boot and caches the result
- [ ] A discovery document whose `issuer` field disagrees with the configured `issuerUri` is rejected at boot with a message naming both values — not at first login
- [ ] A provider with all four endpoints set and an empty `issuerUri` registers without any network call
- [ ] Two providers with the same `id` fail the boot, naming the id
- [ ] A provider whose `clientSecret` is empty and whose `pkce` is `false` fails the boot: that combination is a public client with no proof of possession

### Step 2 — PKCE, state and nonce

`authorizationRequest` builds the redirect URL and the three secrets that go with it. The verifier is
43–128 characters of base64url per RFC 7636; the challenge is `S256` only — `plain` is not
implemented and a provider that advertises only `plain` is refused.

```bp
pub type AuthorizationRequest(
    url: string,
    state: string,
    nonce: string,
    verifier: string,
)

pub fn authorizationRequest(p: OAuth2Provider, returnTo: string) -> AuthorizationRequest
```

**Acceptance:**
- [ ] The URL carries `response_type=code`, `client_id`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge` and `code_challenge_method=S256`
- [ ] `verifier.length() >= 43` and every character is in the unreserved set
- [ ] `challenge == base64.encodeUrlSafe(crypto.sha256(verifier))` with no `=` padding
- [ ] Two calls a millisecond apart produce different `state`, `nonce` and `verifier`
- [ ] `returnTo` is stored server-side and never appears in the redirect URL, so an open-redirect parameter cannot be forged
- [ ] A `returnTo` that is not a path on this application is replaced by `/`

### Step 3 — The two endpoints

`/oauth2/authorization/{id}` and `/login/oauth2/code/{id}`, registered into the route table at boot.
The callback is single-use: the state entry is deleted before the token exchange starts, so a
replayed callback finds nothing.

**Acceptance:**
- [ ] `GET /oauth2/authorization/keycloak` answers 302 with a `Location` built by step 2 and sets the session cookie if there is none
- [ ] `GET /oauth2/authorization/unknown` answers 404
- [ ] A callback with no `state`, an unknown `state`, or a `state` already consumed answers 400 and performs no token exchange
- [ ] A callback carrying `error=access_denied` answers 403 with the provider's `error_description`, and does not exchange
- [ ] A successful callback answers 302 to the stored `returnTo`
- [ ] Neither endpoint ever puts the code, the verifier or the token in a response body or a log line

### Step 4 — Token exchange, ID-token verification, refresh

The exchange is a form POST through front 13's client. The ID token is verified with front 10's JWT
verifier, keyed by this front's JWKS cache, and then checked for `iss`, `aud`, `nonce` and `exp`
against a configured clock skew (default 60s). Refresh happens on demand: `accessToken` returns the
cached token when it has more than a configured margin left, and refreshes otherwise.

```bp
pub type TokenSet(
    accessToken: string,
    refreshToken: string,
    idToken: string,
    expiresAt: i32,
    scopes: string[],
)
```

**Acceptance:**
- [ ] A token response missing `id_token` for an `openid`-scoped request fails the login; it does not produce an anonymous session
- [ ] An ID token whose `nonce` differs from the stored one fails, and the failure names `nonce` rather than "invalid token"
- [ ] An ID token signed with a key absent from the cached JWKS triggers exactly one re-fetch; a second token with the same unknown `kid` within the rate-limit window does not re-fetch
- [ ] `exp` in the past by less than the skew passes; by more than the skew fails
- [ ] `aud` that is an array containing the client id passes; one that does not contain it fails
- [ ] A refresh that fails with `invalid_grant` clears the session rather than retrying
- [ ] A JWKS fetch failure leaves the previously cached key set in place

### Step 5 — Resource server

A filter in front 07's chain reads `Authorization: Bearer …`, verifies it the same way step 4 verifies
an ID token, maps `scope` (space-delimited) and `roles` claims to authorities, and installs the
principal. A request with no bearer token is left anonymous — this filter authenticates, it does not
authorize; `#[secured]` from front 10 does that.

**Acceptance:**
- [ ] `scope: "orders:read orders:write"` produces authorities `SCOPE_orders:read` and `SCOPE_orders:write`
- [ ] A `roles` claim that is an array of strings produces `ROLE_<name>` for each
- [ ] A malformed bearer token answers 401 with `WWW-Authenticate: Bearer error="invalid_token"`, through front 04's `rkSetReplyHeader`
- [ ] A request with no `Authorization` header reaches the handler as anonymous and a `#[secured]` handler answers 401, not 500
- [ ] Token validation does not hit the network when the key set is cached and the `kid` is present

### Step 6 — Client credentials for service-to-service calls

A registration with `grantType: ClientCredentials` produces a token source. `#[clientCredentials("id")]`
on a front-13 client field emits the interceptor that attaches it, refreshing on the same margin rule
as step 4. Tokens are cached per registration, not per call.

**Acceptance:**
- [ ] N concurrent calls through a cold token source perform one token request, not N
- [ ] A 401 from the downstream service invalidates the cached token and retries exactly once
- [ ] The token never appears in an exception message or a log line
- [ ] A registration used by no client is never fetched

### Step 7 — LDAP directory authentication

Bind-and-search over `eldap`: bind as the service account, search for the user by filter, then bind as
the found DN with the supplied password. A `userDnPattern` short-circuits the search when the
directory's DNs are formulaic. Group membership from `memberOf` or a group search becomes authorities.
The `ldap` health indicator from `09-actuator.md § HealthIndicators Auto-configurados` is registered
with front 11 here, because this front owns the connection.

**Acceptance:**
- [ ] A correct username and password produce `Authenticated(principal)` with the DN as `subject`
- [ ] A wrong password produces `Rejected`, and the reason does not distinguish "no such user" from "bad password"
- [ ] An unreachable directory produces `Unavailable`, and `Unavailable` is not treated as a rejection by front 10's manager
- [ ] A user whose entry has three `memberOf` values produces three authorities
- [ ] The `ldap` health indicator is `DOWN` when a bind against the service account fails, and carries no credentials in its detail map
- [ ] Every `eldap` handle opened is closed, including on the failure paths — asserted by a handle count before and after

### Step 8 — SAML 2.0 service provider (last; cut first)

SP metadata endpoint, `AuthnRequest` over the HTTP-Redirect binding (deflate + base64 + query
signature), and an assertion consumer service that verifies the IdP's signature, the `Conditions`
window, the audience restriction and the `InResponseTo` correlation.

**Acceptance:**
- [ ] `/saml2/metadata` serves SP metadata whose `entityID` and ACS URL match the configuration
- [ ] An `AuthnRequest` round-trips through deflate/base64 to the same XML
- [ ] An assertion with a valid signature, in-window `Conditions`, matching audience and matching `InResponseTo` authenticates
- [ ] Each of those four checks, failed on its own, rejects — four separate cases, not one
- [ ] An assertion whose signature covers a different document rejects
- [ ] **If this step is cut:** the ACS path answers 501 with a body naming the missing canonicalization, and the front's tests assert that 501 rather than skipping

## Examples

- [`examples/oidc-login-example.bp`](./examples/oidc-login-example.bp) — an application that logs users
  in against Keycloak: the provider bean, the protected controller, and what the principal looks like
  when it arrives. This is all the code an application writes for OIDC login.
- [`examples/service-token-and-ldap-example.bp`](./examples/service-token-and-ldap-example.bp) — the two
  non-browser halves: a service calling another service with a client-credentials token it never
  names, and LDAP bind-and-search wired into front 10's authentication manager.

## Language gaps

| Gap | Where | Nearest valid form today | Proposed surface |
|---|---|---|---|
| A `fn` cannot forward a `@Result` it received. `-> @Result<…>` requires `#[@result]`, and inside such a fn `return v` wraps `v` again, so a token exchange that calls a fetch which already returns `@Result` double-wraps. | `examples/service-token-and-ldap-example.bp`, `tokenFor` — written as a total fn returning `""` on failure instead | `.map` / `.flatMap` / `.unwrapOr`, or unwrap and `throw` | A forwarding return (`return! r;`), or an implicit forward when the returned expression is already `@Result<D, E>`. Already recorded by front 04 |
| Declared parameter defaults are never applied, so an API with optional arguments has to be a record constructor or force every caller to write every argument. | `examples/oidc-login-example.bp`, `OAuth2Provider(...)` — seven named fields where four would do | Record construction with every field written | Apply declared defaults at the call site, which would let `OAuth2Provider` default `pkce`, `scopes` and `redirectPath` |

## Test plan

`modules/rakun-security/test/oauth2/`, `test/oidc/`, `test/ldap/` and `test/saml2/`, run with
`botopink test --target erlang` from `modules/rakun-security/`, and in the gate as
`zig build test-libs -- --target erlang --lib rakun`.

The protocol halves are tested against a **fixture provider** this front ships in
`test/oauth2/fixture_provider.bp`: a set of routes registered on the same in-process router that
answer a discovery document, a JWKS, and a token endpoint, with a key pair generated at test start.
That is what makes "an ID token signed with an unknown `kid` triggers exactly one re-fetch" a
falsifiable assertion rather than a comment — the fixture counts its own requests. No test in this
front reaches the network.

LDAP is tested against `eldap`'s own loopback: an `eldap` client pointed at a directory that is not
listening exercises the `Unavailable` path, and the bind-and-search paths run against a fixture
directory when one is available and are skipped with a named reason when it is not. A skipped LDAP
row is reported, never silently passed.

This front is erlang-only. It has no commonJS row and must not acquire one: the client secret, the
PKCE verifier and every token are server state, and a JS build of this module would be a mistake that
compiles.

## Definition of done

- [ ] `OAuth2Provider`, discovery, the two endpoints, exchange, verification and refresh all land, and a login against the fixture provider produces a principal front 10 accepts
- [ ] The JWKS cache re-fetches on an unknown `kid`, at most once per rate-limit window, and survives a provider outage
- [ ] The resource-server filter maps scopes and roles into front 10's authority list
- [ ] `#[clientCredentials]` attaches a token to a front-13 client with no token mentioned in the service body
- [ ] LDAP bind-and-search authenticates, and its health indicator is registered with front 11
- [ ] SAML either lands complete or answers 501 with a named reason — never a weakened verification path
- [ ] No cell in this module carries a Node form
- [ ] `modules/rakun-security/AGENTS.md` documents the front-10 boundary table above
- [ ] The front's tests are green on its assigned target
