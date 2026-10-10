# Front 79 — OAuth2 and SSO: the authentication-manager seam, two amendments, the SAML ACS

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s6 · s2 → 150 s6 · s3 → 150 s6 · s4 → 150 s6. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — an LDAP `Unavailable` cannot stand in as the Basic authority today; SAML's ACS
answers 501 on a decision the maintainer owes · **State:** not started
**Depends on:** 128 · 03r-ae (step 3) · 03r-w (confirmation; its option 2 is 13's interceptor seam,
which `withClientToken` may adopt once 13 lands — not a dependency)
**Owns:** `modules/rakun-security/**` (10's files included; 10 has no open box) ·
`repository/rakun/AGENTS.md` § Security, § OAuth2, OIDC, LDAP and SAML
**Does not touch:** `rakun-session` (12's) · `rakun-client` (13's) · `rakun-web` (65's)

## Goal

Basic authentication goes through an `AuthenticationManager` an LDAP directory can implement; a down
directory answers 503, never 401; the two closed-by-amendment boxes reworded and ticked; SAML ACS
verifies signatures (03r-ae (a)) or is retired with a `deferred.md` row.

## Mechanism

- **R79-1.** `basic.bp` authenticates against `UserDetailsService` only; `ldap/ldap.bp`'s
  `Unavailable` is a distinct answer (`ldap_test.bp`) with no way in. `basic.bp` gains an
  `AuthenticationManager` behavior, one implementation over `UserDetailsService`; `ldap.bp` a second
  whose `Unavailable` becomes a 503 problem detail. Installed by registering the manager as the
  `#[bean]` `basic.bp` resolves — one resolution point, no flag.
- **R79-2 (03r-ae (a)).** `src/sidecars/rakun_saml2.erl`: exc-c14n over `xmerl`'s tree (namespace
  visibility per the InclusiveNamespaces list, lexicographic attribute order, character
  normalisation) and `xmldsig` verification with `public_key`; fixtures signed by a checked-in test
  key under `test/saml2/fixtures/`. Today `saml2/saml2.bp` answers 501 at `/saml2/acs`.

Identity provider, directory and token endpoint are in-process doubles; SAML fixtures checked-in
documents; nothing env-gated.
