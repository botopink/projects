# Front 103 — actions id: `actions` gains `id`

**Priority:** high — the action id is a security boundary derived in one place, re-checked in
another; one grammar only · **State:** steps 1–2 done; the secret's source follows `04-rakun/04` step 7 (299)
**Depends on:** nothing (step 2 edits two library members — `fronts.md` § Order)
**Owns:** `repository/botopink-lang/libs/actions/src/id.bp` (new), `libs/actions/test/id_test.bp`,
`libs/actions/AGENTS.md`, `libs/actions/botopink.json` (`files`), `libs/actions/src/root.bp` (the
module's line) · consumers:
`repository/rakun/modules/rakun-app/src/actions.bp` (`actionId` and its callers `actionIdOf`,
`resolveAction` only), `repository/jhonstart/modules/jhonstart-forms/src/form.bp` (`formAction`'s
`wellFormed` check only)
**Does not touch:** the rest of rakun-app / jhonstart-forms (`04-rakun` 22, `05-jhonstart` 67) ·
`build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`

## Goal

rakun-app `actionId(module, name, buildId)` (`actions.bp`) = `"a_" +
hash.hmacSha256(rkProp("rakun.actions.secret"), module + "." + name + ":" + buildId).slice(0, 24)`
(today; `rkProp` goes with 299 — the secret becomes a field of rakun-app's typed
`#[config("rakun.actions")]` record, injected by type). jhonstart-forms' `formAction` re-checks a
looser shape (`a_` prefix, no `/`, space or quote): a 23-hex id passes jhonstart, never matches
rakun. After: both read one derivation and grammar from `actions.id`.

**Name.** `deriveActionId` — rakun-app exports `actionId` (decision 163). Decision 324: rakun-app's
`actionId` is deleted, not kept as a wrapper; its callers call `deriveActionId` with the secret from the
`#[config("rakun.actions")]` record (299), not `rkProp`. `actionIdOf(name:
string)` — a lookup by the action's name in text — is today's code and goes with 281 (an action is
referred to by its function; `08-bpp/127` step 5); this front only repoints the derivation under it.

## Done

- Step 1 — `libs/actions/src/id.bp`: `deriveActionId(secret, module, name, buildId)` (std
  `hash.hmacSha256`, the secret a parameter) and `isActionId(id)` (`a_` + exactly 24 lowercase hex);
  `test/id_test.bp` (5 tests) — six known-answer ids (HMAC-SHA256 computed outside botopink;
  `(…, "app@posts", "createPost", "build-1")` of `rakun-app/test/actions_test.bp` among them, empty
  texts included), every derived id an `isActionId`, refusals of 23 and 25 digits, uppercase, `a_`,
  `""`, another prefix, a non-hex digit, `a_9f2c1b7e`, `a_1`, `a_<script>`. `botopink test` 24
  passed, 0 failed on erlang and on commonJS (19 before); `format --check` clean;
  `libs/actions/AGENTS.md` names `id`; `botopink.json` `files`, `root.bp` updated

- Step 2 — consumers, one patch per member (decision 188), rakun's first:
  - rakun-app `actions.bp`: `actionId` deleted (324); `actionIdOf` and `resolveAction` call
    `id.deriveActionId(rkProp("rakun.actions.secret"), module, name, buildId())` — derivation and
    `slice` gone from rakun-app; `resolveAction`'s `hash.equalsConstantTime` over every entry
    untouched; `test/actions_test.bp` calls `deriveActionId(testSecret(), …)` (the secret
    `configure()` sets). `botopink test --target erlang` 204 passed, 0 failed (204 before)
  - jhonstart-forms `form.bp`: `formAction` asserts `id.isActionId(actionId)`; the refusal reads
    "an action id is `a_` and 24 lowercase hex digits" (the two asserted ``is not an action id``
    texts kept); `test/form_test.bp`'s `a_9f2c1b7e` / `a_0000aaaa` are now
    `a_9f2c1b7e0d4a6c8e1f3b5d7a` / `a_0000aaaa0000aaaa0000aaaa` (`a_1` stays: `formStatusOf`
    checks nothing); `docs.md`'s example and table row state the grammar. jhonstart-forms 15
    passed, 0 failed on commonJS and on erlang; `examples/forms` 7 passed, 0 failed on both

## Open

- [ ] The secret from rakun-app's typed `#[config("rakun.actions")]` record (299), not `rkProp` —
      measured 9 Oct: no `#[config(…)]` record exists in rakun, so the one read sits at the two
      `deriveActionId` calls; the switch and the `rkProp` removal are `04-rakun/04` step 7's

**Gate:** standard (fronts.md § Gate) + `libs/actions/AGENTS.md` names `id`
