# Front 74 — rakun TLS and SSL bundles: client verification and reload, asserted

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../README.md): s1 → 150 s3 · s2 → 150 s3. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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
