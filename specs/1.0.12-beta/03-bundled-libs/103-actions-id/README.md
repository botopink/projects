# Front 103 — actions id: `actions` gains `id`

**Priority:** high — the action id is a security boundary derived in one place, re-checked in
another; one grammar only · **State:** not on feat; step 1 reported done on unpushed branch
`front/103-actions-id` — push it
**Depends on:** the branch pushed and landed (step 1)
**Owns:** `repository/botopink-lang/libs/actions/src/id.bp` (new), `libs/actions/test/id_test.bp`,
`libs/actions/AGENTS.md`, `libs/actions/botopink.json` (`files`) · consumers:
`repository/rakun/modules/rakun-app/src/actions.bp` (`actionId` and its callers `actionIdOf`,
`resolveAction` only), `repository/jhonstart/modules/jhonstart-forms/src/form.bp` (`formAction`'s
`wellFormed` check only)
**Does not touch:** the rest of rakun-app / jhonstart-forms (`04-rakun` 22, `05-jhonstart` 67) ·
`build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`

## Goal

rakun-app `actionId(module, name, buildId)` (`actions.bp`) = `"a_" +
hash.hmacSha256(rkProp("rakun.actions.secret"), module + "." + name + ":" + buildId).slice(0, 24)`.
jhonstart-forms' `formAction` re-checks a looser shape (`a_` prefix, no `/`, space or quote): a
23-hex id passes jhonstart, never matches rakun. After: both read one derivation and grammar from
`actions.id`.

**Name.** `deriveActionId` — rakun-app exports `actionId` (decision 163). rakun-app's `actionId`
(read by its tests, `actionIdOf`, `resolveAction`) keeps its name, calls `deriveActionId` with the
secret it reads.

## Open

### Step 1 — `id.bp`

`deriveActionId(secret, module, name, buildId) -> string` (above, over std `hash.hmacSha256`);
`isActionId(id) -> bool` (`a_` + exactly 24 lowercase hex). Secret is a parameter; the package never
reads `rakun.actions.secret`. `hmacSha256` answers lowercase hex on both targets (Node
`digest('hex')`, Erlang `~2.16.0b`); the test pins it.

- [ ] known-answer: one fixed `(secret, module, name, buildId)` → one fixed id, both rows; lowercase,
      so `isActionId(deriveActionId(…))` holds
- [ ] `isActionId` refuses 23 and 25 digits, uppercase, and the empty suffix

### Step 2 — consumers

- [ ] rakun-app's `actionId` calls `actions.id.deriveActionId` (derivation and `slice` gone from
      rakun-app); `resolveAction`'s constant-time comparison untouched; `actions_test.bp` green unchanged
- [ ] jhonstart-forms' `formAction` calls `isActionId`; its form tests green on both rows

**Gate:** standard (fronts.md § Gate) + `libs/actions/AGENTS.md` names `id`
