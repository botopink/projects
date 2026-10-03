# Front 74 — rakun TLS and SSL Bundles

**Priority:** high — 92's TLS transport and 93's client bundle both read this registry, and two of the four open boxes are security behaviour (`verify=full` hostname matching, `verify=none` warning)
**Carries:** —
**Depends on:** `128-rakun-consolidation`, and nothing else. Runs beside 04, 17 and 11 (disjoint files in `modules/rakun`) and 65 (disjoint files in `modules/rakun-web`)
**Owns:** `modules/rakun/src/ssl_bundle.bp`, `modules/rakun/src/sidecars/rakun_ssl.erl`, `modules/rakun/test/ssl_bundle_test.bp`, `modules/rakun/test/tls_listener_test.bp` · `modules/rakun-web/src/tls.bp`, `modules/rakun-web/test/tls_test.bp` · `repository/rakun/AGENTS.md` § SSL bundles
**Does not touch:** every other file of `modules/rakun` (04's) and `modules/rakun-web` (65's) · `rakun-client` (13 reads the bundle through the registry's API only)

---

## Carried from 1.0.10

| Id | From (`specs/1.0.10-beta/03-rakun/74-rakun-tls-ssl-bundles/README.md`) | Box, as written |
|---|---|---|
| R74-1 | § Step 4 — client-side bundles | "`verify=full` refuses a server whose certificate does not match the requested hostname" |
| R74-2 | § Step 4 — client-side bundles | "`verify=none` connects to both, and resolving it logs a warning naming the bundle" |
| R74-3 | § Step 5 — reload | "A connection established before the reload continues with the old material and is not dropped" |
| R74-4 | § Step 5 — reload | "`reload-on-update=true` picks up a rotated certificate within two intervals" |

## Problem

A client bundle with `verify=full` is not asserted to refuse a hostname mismatch — the one check
that separates TLS from encryption to anybody. `verify=none` resolves silently. A reload's effect on
live connections and the rotation interval are documented, not tested.

## Current state

`modules/rakun/test/ssl_bundle_test.bp` and `test/tls_listener_test.bp` are green (part of the
core's 355); `modules/rakun-web/test/tls_test.bp` green (part of rakun-web's 209). The listener arm
terminates TLS over OTP `ssl` with a PEM bundle; the `ssl` health indicator reports expiry. The
tests generate their material under `BOTOPINK_TEST_TMPDIR` (`ssl_bundle_test.bp:228`).

## Mechanism

`rakun_ssl.erl` builds the `ssl:tls_client_option()` list from a bundle; `verify=full` maps to
`{verify, verify_peer}` plus `{server_name_indication, Host}` and the hostname check is OTP's
(`public_key:pkix_verify_hostname/2`) — the box is an assertion that the option list carries both,
proven by a loopback server presenting a certificate for another name. Reload swaps the bundle's
ETS row; an established `ssl` socket holds its own state, so live connections are untouched by
construction — again, the box is the assertion.

## Gate stance

No cell here is env-gated. Every assertion runs a loopback `ssl` listener from generated material.

## Steps

### Step 1 — Client verification (R74-1, R74-2)

**Acceptance:**
- [ ] `ssl_bundle_test.bp`: a loopback server presenting a certificate for `other.test`, a client bundle with `verify=full` for `localhost`: the connect fails and the failure names the hostname mismatch
- [ ] the same with `verify=none`: connects; resolving the bundle logs one warning through the core's logger (in the core after 128 — decision 187; no failure sink exists) naming the bundle
- [ ] `verify=full` against a matching certificate connects (the positive control)

### Step 2 — Reload (R74-3, R74-4)

**Acceptance:**
- [ ] `tls_listener_test.bp`: a connection opened before `reloadBundle("b")` still exchanges bytes after it; a connection opened after presents the new certificate (asserted by the peer certificate's serial)
- [ ] `reload-on-update=true` with `interval=200ms`: rotating the files on disk is picked up and a new connection presents the new serial within 400 ms, asserted with `io.clock`

## Gate

- [ ] `botopink test --target erlang` green in `modules/rakun` and `modules/rakun-web`
- [ ] `botopink format --check` clean in both
- [ ] `AGENTS.md` § SSL bundles updated in the same commit
- [ ] commit on `fix/74-rakun-tls-ssl-bundles`

## Blast radius

None outside the four owned files; 13, 92 and 93 consume the registry API, which does not change.

## Notes

The warning path of R74-2 is the core's logger: 128 puts it in the member this front already
works in, so no seam and no follow-up is needed (decision 187).
