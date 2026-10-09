# Front 74 — rakun TLS and SSL bundles: client verification and reload, asserted

**Priority:** high — 92's TLS transport and 93's client bundle read this registry; `verify=full`
hostname matching separates TLS from encryption to anybody · **State:** not started (two halves
already have cells)
**Depends on:** 128. Runs beside 04, 17, 11 (disjoint files in `modules/rakun`) and 65 (disjoint
files in `modules/rakun-web`)
**Owns:** the four core files `modules/rakun/src/ssl_bundle.bp`, `src/sidecars/rakun_ssl.erl`,
`test/ssl_bundle_test.bp`, `test/tls_listener_test.bp`, and two of `rakun-web`: `src/tls.bp`,
`test/tls_test.bp` · `repository/rakun/AGENTS.md` § SSL bundles
**Does not touch:** every other file of `modules/rakun` (04's) and `modules/rakun-web` (65's) ·
`rakun-client` (13 reads the bundle through the registry's API)

## Goal

A `verify=full` client bundle asserted to refuse a hostname mismatch over a loopback `ssl`
listener; `verify=none` warns through the core's logger; a reload leaves live connections alone,
`reloadOnUpdate` (299: the key is the field's name; `reload-on-update` today) picks up a rotated certificate within two intervals.

## Mechanism

- `rakun_ssl.erl` builds the `ssl:tls_client_option()` list from a bundle; `verify=full` already
  maps to `{verify, verify_peer}`, `{server_name_indication, Host}`, `{customize_hostname_check,
  [{match_fun, public_key:pkix_verify_hostname_match_fun(https)}]}` — open box: the loopback
  assertion that it works.
- `verify=none` already resolves with a warning naming the bundle (`ssl_bundle_test.bp` "verify none
  resolves with a warning naming the bundle", via `sslWarnings()`); it must also reach the core's
  logger, in this member after 128 (decision 187 — no seam).
- Reload swaps the bundle's ETS row (`sslReload`); an established `ssl` socket holds its own state,
  so live connections are untouched by construction — the box asserts it.
- Cells generate material under `BOTOPINK_TEST_TMPDIR`; nothing env-gated.

## Open

### Step 1 — Client verification (R74-1, R74-2)

- [ ] `ssl_bundle_test.bp`: a loopback server presenting a certificate for `other.test`, a `verify=full` client bundle for `localhost`: connect fails, the failure names the hostname mismatch
- [ ] `verify=full` against a matching certificate connects (positive control)
- [ ] with `verify=none` the same connect succeeds against both certificates; resolving the bundle writes one warning through the core's logger naming the bundle (the `sslWarnings()` cell stays)

### Step 2 — Reload (R74-3, R74-4)

- [ ] `tls_listener_test.bp`: a connection opened before `sslReload("b")` still exchanges bytes after it (existing cell "sslReload after replacing both files makes the next handshake present the new certificate" covers the new-connection half)
- [ ] `reloadOnUpdate: true`, `interval: 200ms` (299): rotated files on disk picked up, a new connection presents the new serial within 400 ms (`io.clock`)

**Gate:** standard (fronts.md § Gate) + `botopink test --target erlang` and `botopink format --check`
green in `modules/rakun` and `modules/rakun-web`.

Blast radius: none outside the owned files; 13, 92, 93 consume the unchanged registry API.
