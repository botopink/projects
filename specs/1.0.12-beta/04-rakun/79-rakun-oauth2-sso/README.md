# Front 79 — OAuth2 and SSO: the authentication-manager seam, two amendments, the SAML ACS

**Priority:** high — an LDAP `Unavailable` cannot stand in as the Basic authority today; SAML's ACS
answers 501 on a decision the maintainer owes · **State:** not started
**Depends on:** 128 · 03r-ae (step 3) · 03r-w (confirmation; its option 2 is 13's interceptor seam,
which `withClientToken` may adopt once 13 lands — not a dependency)
**Owns:** `modules/rakun-security/**` (10's files included; 10 has no open box) ·
`repository/rakun/AGENTS.md` § Security, § OAuth2, OIDC, LDAP and SAML
**Does not touch:** `rakun-session` (12's) · `rakun-client` (13's) · `rakun-web` (65's)

## Goal

Basic authentication goes through an `AuthenticationManager` an LDAP directory can implement, and a
directory that is down answers 503, never 401; the two closed-by-amendment boxes are reworded and
ticked; the SAML ACS either verifies signatures (03r-ae (a)) or is retired with a `deferred.md` row.

## Mechanism

- **R79-1.** `basic.bp` authenticates against `UserDetailsService` only; `ldap/ldap.bp`'s
  `Unavailable` is a distinct answer (`ldap_test.bp`) with no way in. `basic.bp` gains an
  `AuthenticationManager` behavior with one implementation over `UserDetailsService`; `ldap.bp` a
  second whose `Unavailable` becomes a 503 problem detail. Installation is registering the manager
  as the `#[bean]` `basic.bp` resolves — one resolution point, no flag.
- **R79-2 (03r-ae (a)).** `src/sidecars/rakun_saml2.erl` implements exc-c14n over `xmerl`'s tree
  (namespace visibility per the InclusiveNamespaces list, lexicographic attribute order, character
  normalisation) and `xmldsig` verification with `public_key`; fixtures signed by a checked-in test
  key under `test/saml2/fixtures/`. Today `saml2/saml2.bp` answers 501 at `/saml2/acs`.

The identity provider, the directory and the token endpoint are in-process doubles; SAML's fixtures
are checked-in documents; nothing is env-gated.

## Open

### Step 1 — The manager seam (R79-1, RX-1)

- [ ] `basic_test.bp`: with the LDAP manager installed, a reachable directory double authenticates a Basic request; an unreachable one answers 503 with a problem detail naming `ldap`, not 401
- [ ] with no manager installed the default over `UserDetailsService` behaves as today (the existing cells)
- [ ] `basic_test.bp:137,174`'s `?? UserDetails(…)` narrowed with `if (x == null)` (RX-1)

### Step 2 — Amendments (R79-3, R79-4)

- [ ] on 03r-w's confirmation: R79-3 reworded to "`withClientToken(id, call)` attaches a token to a front-13 call with no token mentioned in the service body" and ticked against `oauth2_test.bp`'s existing cell; if 13's interceptor seam has landed, `withClientToken` is one interceptor and the cell re-runs
- [ ] R79-4 reworded to "`repository/rakun/AGENTS.md` § OAuth2, OIDC, LDAP and SAML documents the boundary table" and ticked

### Step 3 — SAML ACS (R79-2, 03r-ae)

- [ ] under (a): `test/saml2/acs_test.bp` — a fixture assertion with a valid signature, in-window `Conditions`, matching audience and matching `InResponseTo` authenticates; each of the four checks failed alone rejects (four cells); a signature over a different document rejects; the canonicaliser reproduces the W3C exc-c14n test vectors checked in under `test/saml2/fixtures/c14n/`
- [ ] under (b): the three boxes are deleted, `saml2.bp` keeps the 501 with a message naming the gap, and one `deferred.md` row holds them

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun-security`.

Blast radius: step 1 puts a behavior between `basic.bp` and its user store; `rakun-actuator`'s access
rules and `rakun-websocket` call `security_filter.bp`, whose signature does not change. Step 3 (a) adds
a sidecar and fixtures only.
