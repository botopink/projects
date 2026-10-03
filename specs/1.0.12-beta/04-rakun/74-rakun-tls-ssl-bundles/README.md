# Front 74 — rakun TLS and SSL bundles: client verification and reload, asserted

**Priority:** high — 92's TLS transport and 93's client bundle read this registry, and `verify=full`
hostname matching is the check that separates TLS from encryption to anybody · **State:** not
started (two halves already have cells)
**Depends on:** 128. Runs beside 04, 17 and 11 (disjoint files in `modules/rakun`) and 65 (disjoint
files in `modules/rakun-web`)
**Owns:** the four core files `modules/rakun/src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`,
`test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`, and two of `rakun-web`: `src/tls.bp`,
`test/tls_test.bp` · `repository/rakun/AGENTS.md` § SSL bundles
**Does not touch:** every other file of `modules/rakun` (04's) and `modules/rakun-web` (65's) ·
`rakun-client` (13 reads the bundle through the registry's API)

## Goal

A `verify=full` client bundle is asserted to refuse a hostname mismatch over a loopback `ssl`
listener; `verify=none` warns through the core's logger; a reload leaves live connections alone and
`reload-on-update` picks up a rotated certificate within two intervals.

## Mechanism

`rakun_ssl.erl` builds the `ssl:tls_client_option()` list from a bundle; `verify=full` already maps
to `{verify, verify_peer}`, `{server_name_indication, Host}` and `{customize_hostname_check,
[{match_fun, public_key:pkix_verify_hostname_match_fun(https)}]}` — the open box is the loopback
assertion that the list does its job. `verify=none` already resolves with a warning naming the bundle
(`ssl_bundle_test.bp` "verify none resolves with a warning naming the bundle", read through
`sslWarnings()`); the warning must also reach the core's logger, which is in this member after 128
(decision 187 — no seam). Reload swaps the bundle's ETS row (`sslReload`); an established `ssl`
socket holds its own state, so live connections are untouched by construction — the box is the
assertion. Every cell generates its material under `BOTOPINK_TEST_TMPDIR`; nothing is env-gated.

## Open

### Step 1 — Client verification (R74-1, R74-2)

- [ ] `ssl_bundle_test.bp`: a loopback server presenting a certificate for `other.test`, a client bundle with `verify=full` for `localhost`: the connect fails and the failure names the hostname mismatch
- [ ] `verify=full` against a matching certificate connects (the positive control)
- [ ] with `verify=none` the same loopback connect succeeds against both certificates, and resolving the bundle writes one warning through the core's logger naming the bundle (the `sslWarnings()` cell stays)

### Step 2 — Reload (R74-3, R74-4)

- [ ] `tls_listener_test.bp`: a connection opened before `sslReload("b")` still exchanges bytes after it (the existing cell "sslReload after replacing both files makes the next handshake present the new certificate" covers the new-connection half)
- [ ] `reload-on-update=true` with `interval=200ms`: rotating the files on disk is picked up and a new connection presents the new serial within 400 ms, asserted with `io.clock`

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun` and `modules/rakun-web`.

Blast radius: none outside the owned files; 13, 92 and 93 consume the registry API, which does not change.
