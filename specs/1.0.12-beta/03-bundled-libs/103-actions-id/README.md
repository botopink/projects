# Front 103 — actions id: `actions` gains `id`

**Priority:** high — the action id is a security boundary derived in one place, re-checked in
another; one grammar only · **State:** step 1 done (the package); step 2 open
**Depends on:** nothing (step 2 edits two library members — `fronts.md` § Order)
**Owns:** `repository/actions/src/id.bp` (new), `repository/actions/test/id_test.bp`,
`repository/actions/AGENTS.md`, `repository/actions/botopink.json` (`files`), `repository/actions/src/root.bp` (the
module's line) · consumers:
`repository/rakun/modules/rakun-app/src/actions.bp` (`actionId` and its callers `actionIdOf`,
`resolveAction` only), `repository/jhonstart/modules/jhonstart-forms/src/form.bp` (`formAction`'s
`wellFormed` check only)
**Does not touch:** the rest of rakun-app / jhonstart-forms (`04-rakun` 22, `05-jhonstart` 67) ·
the compiler (`repository/botopink-lang/**` — `actions` is a repository of its own since 138 (decision 326))

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

- Step 1 — `repository/actions/src/id.bp`: `deriveActionId(secret, module, name, buildId)` (std
  `hash.hmacSha256`, the secret a parameter) and `isActionId(id)` (`a_` + exactly 24 lowercase hex);
  `test/id_test.bp` (5 tests) — six known-answer ids (HMAC-SHA256 computed outside botopink;
  `(…, "app@posts", "createPost", "build-1")` of `rakun-app/test/actions_test.bp` among them, empty
  texts included), every derived id an `isActionId`, refusals of 23 and 25 digits, uppercase, `a_`,
  `""`, another prefix, a non-hex digit, `a_9f2c1b7e`, `a_1`, `a_<script>`. `botopink test` 24
  passed, 0 failed on erlang and on commonJS (19 before); `format --check` clean;
  `repository/actions/AGENTS.md` names `id`; `botopink.json` `files`, `root.bp` updated

## Open

### Step 2 — consumers

| Member | Changes | Imports from `actions` | Needs attention |
|---|---|---|---|
| rakun-app `actions.bp` | `actionId(module, name, buildId)` deleted (324); its callers — the registration at `actions.bp:265`, `resolveAction` at `:274`, `test/actions_test.bp` — call `deriveActionId(<secret>, module, name, buildId)` | `id.deriveActionId` | the tests that named `actionId` rewritten to `deriveActionId` with the test secret |
| jhonstart-forms `form.bp` | `formAction`'s `wellFormed` expression becomes `isActionId(actionId)` | `id.isActionId` | `test/form_test.bp` binds forms to `a_9f2c1b7e`, `a_0000aaaa` and `a_1` (the last in `formStatusOf`, which does not check), and `docs.md` shows `a_9f2c1b7e`: 8 hex digits, refused by the grammar — those fixtures become 24-digit ids; the refusal text of `formAction` ("hold no `/`, space or quote") states the old rule; the two refusals `form_test.bp` asserts (``is not an action id``) keep. `examples/forms` already uses a 24-digit id |

- [ ] rakun-app's `actionId` deleted (324): every caller calls `actions.id.deriveActionId` (derivation and
      `slice` gone from rakun-app), the secret from the `#[config("rakun.actions")]` record once 299 lands
      in rakun-app — until then the one `rkProp` read sits at the call; `resolveAction`'s constant-time
      comparison untouched; `actions_test.bp` green with the calls renamed
- [ ] jhonstart-forms' `formAction` calls `isActionId`; its form tests green on both rows

**Gate:** standard (fronts.md § Gate) + `repository/actions/AGENTS.md` names `id`
