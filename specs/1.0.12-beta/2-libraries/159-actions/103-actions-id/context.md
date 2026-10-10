# Front 103 — actions id: `actions` gains `id`

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../../150-rakun/README.md): open → 150 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — the action id is a security boundary derived in one place, re-checked in
another; one grammar only · **State:** steps 1–2 done; the secret's source follows `04-rakun/04` step 7 (299)
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
