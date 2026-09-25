# Front 10 — Authentication, Authorization and Method Security

**Track:** B rakun
**Priority:** high — every endpoint rakun serves today is public, and there is no mechanism by which it could be anything else
**Target:** erlang (server)
**Wave:** 4
**Depends on:** 01 · 07 · 08
**Owns:** `modules/rakun-security/src/**` · `modules/rakun-security/test/**`
**Does not touch:** `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `src/runtime.mjs` — frozen · `modules/rakun-web/src/**`, which is front 07's (this front registers into its chain) · `modules/rakun-security/src/oauth2/**`, `oidc/**`, `saml2/**`, `ldap/**`, which are front 79's
**Reference:** `04-web.md § Spring Security` · `09-actuator.md § Seguranca` · <https://docs.spring.io/spring-boot/reference/web/spring-security.html> · <https://www.rfc-editor.org/rfc/rfc7519> (JWT) · <https://www.rfc-editor.org/rfc/rfc7617> (Basic)

---

## Problem

Every route rakun registers is reachable by anyone who can reach the port. There is no authentication,
no authorization, no security context, and — until front 07 — no place to put any of them: the
dispatcher matched a route and called the handler (`runtime.mjs:188-196`), with nothing in between.

The shape of the missing thing matters more than the list. Authorization that lives in each handler is
authorization that is missing from the handler someone added last week. What is needed is a single
point every request passes, a policy stated once, and a way for a service method to refuse a call it
should not have received even when the caller is another part of the same application. Spring's answer
is a filter chain plus method security; front 07 built the chain, and this front is what registers
into it.

There is a second problem that only appears when you try to write it in botopink: **there is nothing
to hash a password with**. bcrypt, scrypt and Argon2 are all NIFs, and a sidecar `.erl` is compiled at
run time with no code path beyond the output directory (`codegen/erlang.zig:1655-1668`). What OTP does
ship is `crypto:pbkdf2_hmac/5`, and that decides the default encoder — see *Passwords*.

## Current state

| Piece | Where | State |
|---|---|---|
| Authentication | — | none |
| Authorization | — | none |
| Request header access | `src/http.bp:39-42` — `header(name) -> string`, `""` when absent | available |
| The chain to register into | front 07, order band −300 reserved for security | available once 07 lands |
| Per-request state | front 06's `Request` scope, front 04's process dictionary | available |
| Reply headers (`WWW-Authenticate`) | front 04's `rkSetReplyHeader` | available |
| HMAC, base64url, constant-time compare | front 01's `hmac` and `encoding` modules | front 01's deliverable |
| `crypto:pbkdf2_hmac/5`, `crypto:hash/2`, `crypto:strong_rand_bytes/1` | OTP `crypto` | available, no dependency |
| bcrypt / scrypt / Argon2 | — | NIFs; not loadable from a run-time-compiled sidecar |
| `modules/rakun-security/` | — | does not exist |

## Mechanism

### One filter, one policy, one context

The security entry registers at order −300, which puts it after the request id and before everything
else that could leak information — CORS, versioning, the error boundary and the application's own
filters all run *after* the decision.

```bp
pub type Principal(
    name: string,
    authorities: string[],
)

pub type Authentication(
    principal: Principal,
    method: string,          // "jwt" | "basic" | "anonymous"
    authenticated: bool,
)
```

There is no `credentials` field. A password or a raw token is read once, verified, and dropped; it
never enters the context, so it cannot reach a log line, an actuator endpoint or an error body by
accident.

The context lives in front 06's `Request` scope — on the BEAM that is the connection process's own
state, so there is no thread-local to leak across requests and no need to clear it. Reading it outside
a request is a hard failure, per [`contracts.md`](../../contracts.md) §5, not an anonymous default.

### The policy

```bp
pub type PathRule(pattern: string, requirement: string)   // "permitAll" | "authenticated" | "hasRole:ADMIN"

pub type SecurityPolicy(
    rules: PathRule[],
    defaultRequirement: string,
)
```

A policy is a `#[provides]`-ed value (front 06), so it is configuration code rather than a decorator
DSL, and rules are matched **in declaration order, first match wins** — the same rule Spring's
`authorizeHttpRequests` uses and the one that makes `/api/public/**` before `/api/**` behave the way
anyone reading it expects.

`defaultRequirement` is `"authenticated"` and there is no way to make it `permitAll`. A path nobody
wrote a rule for is protected; the most restrictive default, with no knob to weaken it. Making a path
public is an explicit `permitAll` rule that a reviewer can see in a diff.

The pattern grammar is **front 65's**, the same matcher front 07's `#[matcher]` uses. This front
compiles no patterns of its own.

### JWT

HS256 only, over front 01's `hmac`:

1. Split on `.`; exactly three parts or reject.
2. Recompute `HMAC-SHA256(header + "." + payload, secret)`, base64url-encode it, and compare to the
   third part **in constant time** — front 01's `hmac.equals`, never `==`. A short-circuiting compare
   on a signature is a timing oracle.
3. Decode the header and check `alg` is `HS256`. An `alg` of `none`, or an `alg` the token chose that
   the configuration did not, is rejected before the signature is even considered — the
   algorithm-confusion attack, refused by construction.
4. Check `exp`, `nbf` and `iat` against `clock.nowMillis()` with a configurable skew (`rakun.security.jwt.clock-skew`,
   default 30 s), and `iss` and `aud` against the configured values when they are configured.
5. Map a claim to authorities: `rakun.security.jwt.authorities-claim` (default `roles`), with an
   optional prefix (`ROLE_`).

RS256, JWKS fetch, rotation and issuer discovery are **front 79's** — they need `public_key`, a TLS
bundle and an HTTP client, and half of that story is worse than none.

### Basic authentication and passwords

`Authorization: Basic <base64>` decoded through front 01's `encoding`, split on the **first** `:` only
(a colon is legal in a password), and the username looked up through `UserDetailsService`.

```bp
pub behavior PasswordEncoder {
    fn id(self: Self) -> string;
    fn encode(self: Self, raw: string) -> string;
    fn matches(self: Self, raw: string, stored: string) -> bool;
}
```

Stored hashes carry their algorithm in a prefix — `{pbkdf2}<iterations>$<salt>$<hash>` — which is
Spring's `DelegatingPasswordEncoder` idea and the reason a later front can add bcrypt without a
migration: an old hash is verified by whichever encoder its prefix names, and re-encoded with the
current default on the next successful login.

**The default and only encoder this front ships is PBKDF2-HMAC-SHA256**, over `crypto:pbkdf2_hmac/5`,
310 000 iterations, a 16-byte random salt from `crypto:strong_rand_bytes/1`. Not because it is the
best choice — Argon2id is — but because it is the best choice that is *available*, and the README says
exactly that rather than listing bcrypt and hoping. A configuration naming `bcrypt` fails at boot with
a message saying a NIF would be required.

`matches` is constant-time. A user that does not exist still runs a dummy encode before answering, so
a missing account and a wrong password take the same time.

### `UserDetailsService`

```bp
pub type UserDetails(
    username: string,
    passwordHash: string,
    authorities: string[],
    enabled: bool,
)

pub behavior UserDetailsService {
    fn loadByUsername(self: Self, username: string) -> ?UserDetails;
}
```

Two arms. The in-memory one reads `rakun.security.users` — but only under a non-production profile;
configuring users in a property file with a production profile active is a boot failure, because a
password in a configuration file is a password in a repository. The SQL one uses front 08's
`SqlTemplate` with a `#[query]` statement, which is also the first real demonstration that front 08's
repository shape composes with another module.

### Method security, and why it is a proxy

A decorator cannot rewrite the body it annotates ([`language-gaps.md`](../../language-gaps.md)), so
`#[secured("ROLE_ADMIN")]` on a method cannot insert a check into that method. The same answer front
08 reached for `#[transactional]` applies here, and it is what Spring itself does at run time — a
proxy:

```bp
#[service]
#[methodSecurity]
#[managed]
pub type AdminService(repo: AuditRepository) {
    #[secured("ROLE_ADMIN")]
    pub fn purge(self: Self, olderThanDays: i32) -> i32 { … }

    #[permitAll]
    pub fn status(self: Self) -> string { … }
}
```

`#[methodSecurity]` is type-level, so it sees `decl.methods` with each method's `params`, `returnType`
and own annotations, and emits `AdminServiceSec` — one method per public method, each wrapping the
call in `rkRequireAuthority("ROLE_ADMIN")`. A caller injects `AdminServiceSec`; injecting
`AdminService` gets the unchecked object, which is visible in the field declaration rather than
hidden behind a proxy the container swapped in.

A method with neither `#[secured]` nor `#[permitAll]` on a `#[methodSecurity]` type inherits the
type's requirement, and a type with no requirement defaults to `authenticated`. Again: the unmarked
case is the protected case.

`#[preAuthorize("hasRole('ADMIN') or #userId == authentication.principal")]` is **not ported**. It
needs an expression language, botopink has none, and inventing one inside a security front is how
authorization bugs are written. The supported forms are `#[secured("ROLE")]`, `#[secured("ROLE_A,ROLE_B")]`
(any of), and `#[permitAll]`. An application that needs a subject check writes it in the method, where
it is ordinary code a reviewer can read.

### CSRF

A double-submit token: a random value in a `Set-Cookie` and the same value required in `X-CSRF-Token`
on every `POST`, `PUT`, `PATCH` and `DELETE` that carries a session cookie. Compared in constant time.
A request authenticated only by a bearer token is exempt, because a bearer token is not sent
automatically by a browser and CSRF protection on it buys nothing.

The `Origin`/`Host` check on **server actions** is front 24's, per the audit, and this front does not
duplicate it. The **action-id HMAC** is front 01's primitive, used by front 24.

### What failure looks like

| Condition | Status | Body |
|---|---|---|
| No credentials, rule requires authentication | 401 | RFC 9457 problem detail, `WWW-Authenticate` set |
| Credentials present and invalid | 401 | the same problem detail — **never** "unknown user" vs "bad password" |
| Authenticated, authority missing | 403 | problem detail naming the required authority, not the user's |
| CSRF token missing or wrong | 403 | problem detail |

The bodies go through front 07's problem-detail entry, so security failures have the same shape as
every other failure and nothing about the account is disclosed by the difference between two
responses.

## Steps

### Step 1 — The module, the context and the chain entry

**Acceptance:**
- [ ] `modules/rakun-security/` compiles with `"target": "erlang"` and its tests run
- [ ] The security entry registers at order −300 and runs before CORS and the error boundary
- [ ] With no policy configured, every path requires authentication
- [ ] The context is readable inside a request and a hard failure outside one
- [ ] Two concurrent requests never observe each other's context

### Step 2 — The policy

**Acceptance:**
- [ ] Rules match in declaration order and the first match wins
- [ ] `/api/public/**` before `/api/**` makes only the public subtree public
- [ ] A path with no rule requires authentication
- [ ] `defaultRequirement` cannot be set to `permitAll`; a configuration that tries fails at boot
- [ ] Patterns are compiled by front 65's matcher, not by this front

### Step 3 — JWT

**Acceptance:**
- [ ] A valid HS256 token authenticates and its claims become the principal and authorities
- [ ] A tampered payload is rejected
- [ ] `alg: none` is rejected before signature verification
- [ ] An `alg` the configuration does not name is rejected even when the signature would verify
- [ ] An expired token is rejected; one expiring within the skew window is accepted
- [ ] A `nbf` in the future is rejected
- [ ] A wrong `iss` or `aud` is rejected when either is configured
- [ ] Signature comparison uses front 01's constant-time compare — asserted by reading the call, and by a test that a one-byte-different signature and a wholly different one both fail
- [ ] A malformed token (one part, four parts, non-base64) is rejected without raising

### Step 4 — Basic authentication and passwords

**Acceptance:**
- [ ] `Authorization: Basic` authenticates a known user with the right password
- [ ] A password containing `:` round-trips — the split takes the first colon only
- [ ] A wrong password and an unknown user produce the identical response and comparable timing
- [ ] `encode` produces `{pbkdf2}310000$<salt>$<hash>` with a fresh salt each time
- [ ] Two encodes of one password differ; both `matches`
- [ ] A stored hash with an unknown prefix fails naming the prefix rather than answering `false`
- [ ] Configuring `bcrypt` fails at boot naming the missing NIF
- [ ] `rakun.security.users` with a production profile active fails at boot

### Step 5 — `UserDetailsService`

**Acceptance:**
- [ ] The in-memory arm parses the configured user list
- [ ] The SQL arm loads a user through a front 08 `#[query]` statement
- [ ] A disabled user is rejected with the same 401 as a wrong password
- [ ] An application can `#[provides]` its own implementation and it wins

### Step 6 — Method security

**Acceptance:**
- [ ] `#[methodSecurity]` emits `<Type>Sec` with one method per public method
- [ ] `#[secured("ROLE_ADMIN")]` refuses a caller without the authority, with 403
- [ ] `#[secured("ROLE_A,ROLE_B")]` admits a caller holding either
- [ ] `#[permitAll]` admits an anonymous caller
- [ ] A method with no marker inherits the type's requirement, and an unmarked type requires authentication
- [ ] Calling a secured method outside a request is a hard failure, not an implicit allow
- [ ] `#[preAuthorize]` fails at comptime with a message saying expression security is not ported and naming the supported forms
- [ ] `#[methodSecurity]` on an enum-shaped `type` fails at comptime

### Step 7 — CSRF

**Acceptance:**
- [ ] A `POST` with a session cookie and no `X-CSRF-Token` answers 403
- [ ] A `POST` with a matching token succeeds
- [ ] A `POST` authenticated by a bearer token and no cookie is exempt
- [ ] The token is compared in constant time
- [ ] `GET` and `HEAD` are never challenged

### Step 8 — Failure shape

**Acceptance:**
- [ ] 401 sets `WWW-Authenticate` and returns a problem detail
- [ ] An unknown user and a wrong password produce byte-identical bodies
- [ ] A 403 names the required authority and not the caller's authorities
- [ ] No response, log line or actuator endpoint ever contains a password or a raw token

## Examples

- [`examples/jwt-and-method-security-example.bp`](./examples/jwt-and-method-security-example.bp) — a
  developer declaring a policy, reading the authenticated principal in a handler, and putting an
  admin-only method behind `#[methodSecurity]` + `#[secured]`.

## Language gaps

None new. Three already in [`language-gaps.md`](../../language-gaps.md) shape this front, and the
example marks them:

- **A decorator cannot rewrite the body it annotates** — decides that method security is a proxy type
  rather than an in-place check, exactly as it decides front 08's `#[transactional]`.
- **A method-level `@Decl` carries no owner or parameter list** — decides that `#[secured]` is a
  placement marker and `#[methodSecurity]` does the wiring.
- **No byte or binary type** — every hash, salt and signature is marshalled through `string`, so the
  encoder's stored form is text (base64 inside a prefixed string) rather than binary. This is
  workable for PBKDF2 and is the reason the stored format is specified as text in this README.

## Test plan

`modules/rakun-security/test/` — `policy_test.bp`, `jwt_test.bp`, `basic_test.bp`,
`password_test.bp`, `method_security_test.bp`, `csrf_test.bp` — run with
`botopink test --target erlang` and in the gate through `zig build test-libs -- --target erlang`. The
manifest declares `"target": "erlang"`, so the commonJS cell reports *skipped*.

`jwt_test.bp` carries a fixture table of **negative** tokens — expired, not-yet-valid, `alg: none`,
`alg: RS256` with an HS256 signature, wrong issuer, wrong audience, one-byte-mutated signature, two
parts, four parts, non-base64 payload — and asserts each is rejected with the same status and the same
body. The positive case is one test; the negative table is the front.

`password_test.bp` asserts the timing property in the only way a unit test honestly can: that the
unknown-user path performs a dummy encode, observed by counting encoder invocations rather than by
measuring a clock. A timing assertion in a test suite is a flake; the invocation count is the
falsifiable version of the same claim.

Erlang-only. There is no client half: front 29's `'use client'` boundary carries no credentials, and
the validation constraints that mirror to the client ([`contracts.md`](../../contracts.md)) are front
14's, not this front's.

## Adjacent fronts

- **79-rakun-oauth2-sso** owns OAuth2, OIDC, RS256/JWKS, SAML 2.0 and LDAP. Front 10 validates a token
  someone else issued and knows nothing about identity providers.
- **24-rakun-server-actions** owns the `Origin`/`Host` check on server actions; **01** owns the
  action-id HMAC primitive. Front 10 duplicates neither.
- **07-rakun-middleware** owns the chain this front registers into, and the problem-detail shape every
  failure here uses.
- **76-rakun-actuator-security-probes** owns actuator endpoint access control and uses this front's
  authorities; front 10 ships no actuator-specific rule.
- **18-rakun-session** owns session storage; this front reads the session cookie and does not store one.
- **74-rakun-tls-ssl-bundles** owns transport security. Front 10 is about who the caller is, not
  whether the pipe is encrypted.
- **08-rakun-data-sql** supplies the SQL `UserDetailsService` arm.

## Contradictions with fronts.md

1. `modules/rakun-security/src/**` is allocated to F10 as a whole, and front 79 later owns
   `src/oauth2/**`, `src/oidc/**`, `src/saml2/**` and `src/ldap/**` inside it. The two rows overlap as
   written; F10's row should be narrowed to `src/*.bp` plus `src/sidecars/**`, the same sub-directory
   carve-out F07 and F20 use.
2. The row names no sidecar. PBKDF2, `strong_rand_bytes` and the constant-time compare live in
   `modules/rakun-security/src/sidecars/rakun_security.erl` unless front 01's `hmac` and `encoding`
   cover all three — which should be settled with front 01 before this front starts, since the whole
   point of front 01 is that a front does not grow a private copy.

## Definition of done

- [ ] `modules/rakun-security/` exists with the policy, the chain entry, both authentication arms,
      the encoder and method security
- [ ] A path with no rule is protected, and the default cannot be weakened
- [ ] The JWT negative table is green and every rejection is byte-identical
- [ ] The only password encoder is PBKDF2-HMAC-SHA256, stored with its algorithm prefix; `bcrypt`
      fails at boot rather than silently downgrading
- [ ] `#[methodSecurity]` emits a proxy; `#[preAuthorize]` fails at comptime naming what is supported
- [ ] No password or raw token appears in any response, log or endpoint
- [ ] `repository/rakun/AGENTS.md` documents the policy order rule and the stored-hash format
- [ ] The front's tests are green on its assigned target
