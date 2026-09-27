# Front 79 — OAuth2 and SSO (`rakun-security`'s tail)

**Priority:** high — the LDAP `Unavailable` answer is silently a rejection through 10's Basic path today; SAML's ACS is a decision the maintainer owes
**Carries:** 10 (files only; no open box)
**Depends on:** maintainer 03r-ae (SAML ACS), 03r-w (confirmation; its option 2 is 13's interceptor seam, which this front may adopt for `withClientToken` once 13 lands — not a dependency) · none in this track otherwise
**Owns:** `modules/rakun-security/**` · `repository/rakun/AGENTS.md` § Security, § OAuth2, OIDC, LDAP and SAML
**Does not touch:** `rakun-session` (12's) · `rakun-client` (13's) · `rakun-web` (65's)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/79-rakun-oauth2-sso/README.md`) | Box, as written |
|---|---|---|
| R79-1 | § Step 7 — LDAP directory authentication | "An unreachable directory produces `Unavailable`, and `Unavailable` is not treated as a rejection by front 10's manager — open: `unavailable` is a distinct answer (`ldap_test.bp` …), but front 10's Basic path reads its own user store and no seam lets the directory stand in as its manager" |
| R79-2 | § Step 8 — SAML 2.0 service provider | "An assertion with a valid signature, in-window `Conditions`, matching audience and matching `InResponseTo` authenticates" · "Each of those four checks, failed on its own, rejects — four separate cases, not one" · "An assertion whose signature covers a different document rejects" — all three "open: step 8 is cut; verifying the IdP signature needs Exclusive XML Canonicalization" |
| R79-3 | § Definition of done | "`#[clientCredentials]` attaches a token to a front-13 client with no token mentioned in the service body — open: the token source is `withClientToken(id, call)` (03r-w)" — closes by amendment on 03r-w's confirmation |
| R79-4 | § Definition of done | "`modules/rakun-security/AGENTS.md` documents the front-10 boundary table above — open: rakun keeps one AGENTS.md at the repository root" — closes by amendment |
| RX-1 | closed `status.md` L117 | `test/basic_test.bp:137` and `:174` — `?? UserDetails(…)` replaced by `if (x == null)` narrowing |

## Problem

`ldap_test.bp` proves `Unavailable` is distinct; `basic.bp` (10) authenticates against
`UserDetailsService` only, so an application that wants LDAP as its Basic authority cannot install
it, and if it could, `Unavailable` would read as "no such user". SAML answers 501 at the ACS.

## Current state

`modules/rakun-security`: 13 test files, 73 tests green. `src/`: 10's core (`principal`, `policy`,
`jwt`, `password`, `users`, `users_sql`, `basic`, `csrf`, `method_security`, `security_filter`,
`security`) and 79's (`oauth2/{provider,flow,resource,client_credentials}`, `saml2/saml2`,
`ldap/ldap`, the two hosts); sidecars `rakun_security`, `rakun_oauth2`, `rakun_ldap`. Both fronts'
files are this front's now (10 has no open box), so the seam R79-1 needs is an edit inside the
member.

## Mechanism

- R79-1: `basic.bp` authenticates through an `AuthenticationManager` behavior with one
  implementation over `UserDetailsService`; `ldap.bp` gains a second implementation whose
  `Unavailable` answer becomes a 503 problem detail, never a 401. Installation is by registering
  the manager as the `#[bean]` `basic.bp` resolves — one resolution point, no configuration flag.
- R79-2 (03r-ae (a)): `rakun_saml2.erl` implements exc-c14n over `xmerl`'s tree (namespace
  visibility per the InclusiveNamespaces list, lexicographic attribute order, character
  normalisation) and `xmldsig` verification with `public_key`; fixtures signed by a checked-in
  test key under `test/saml2/fixtures/`.

## Gate stance

No env-gated cell. The identity provider, the directory and the token endpoint are in-process
doubles today (`ldap_test.bp`, `oauth2_test.bp`); SAML's fixtures are checked-in documents.

## Steps

### Step 1 — The manager seam (R79-1)

**Acceptance:**
- [ ] `basic_test.bp`: with the LDAP manager installed, a reachable directory double authenticates a Basic request; an unreachable one answers 503 with a problem detail naming `ldap`, not 401
- [ ] with no manager installed the default over `UserDetailsService` behaves as today (the existing cells)
- [ ] `basic_test.bp:137,174` narrowed with `if (x == null)` (RX-1)

### Step 2 — Amendments (R79-3, R79-4)

**Acceptance:**
- [ ] on 03r-w's confirmation: R79-3 reworded to "`withClientToken(id, call)` attaches a token to a front-13 call with no token mentioned in the service body" and ticked against `oauth2_test.bp`'s existing cell; if 13's interceptor seam has landed, `withClientToken` is re-implemented as one interceptor and the cell re-run
- [ ] R79-4 reworded to "`repository/rakun/AGENTS.md` § OAuth2, OIDC, LDAP and SAML documents the boundary table" and ticked

### Step 3 — SAML ACS (R79-2, 03r-ae)

**Acceptance:**
- [ ] under (a): `test/saml2/acs_test.bp` — a fixture assertion with a valid signature, in-window `Conditions`, matching audience and matching `InResponseTo` authenticates; each of the four checks failed alone rejects (four cells); a signature over a different document rejects; `rakun_saml2.erl`'s canonicaliser reproduces the W3C exc-c14n test vectors checked in under `test/saml2/fixtures/c14n/`
- [ ] under (b): the three boxes are deleted, `saml2.bp` keeps the 501 with a message naming the gap, and one `deferred.md` row holds them

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun-security`
- [ ] `botopink format --check` clean
- [ ] `AGENTS.md` sections updated
- [ ] commit on `fix/79-rakun-oauth2-sso`

## Blast radius

Step 1 introduces a behavior between `basic.bp` and its user store; `rakun-actuator`'s 76 (access
rules) and `rakun-websocket` (the upgrade after security) call `security_filter.bp`, whose
signature does not change. Step 3 (a) adds a sidecar and fixtures only.

## Notes

`examples/` of the closed 79 carry no open marker; nothing is copied.
