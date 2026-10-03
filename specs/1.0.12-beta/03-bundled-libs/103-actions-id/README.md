# Front 103 — actions id: `actions` gains `id`

**Priority:** high — the action id is a security boundary derived in one place and re-checked in
another; two grammars for it is one too many · **State:** not on feat; step 1 reported done on an
unpushed branch `front/103-actions-id` — push it
**Depends on:** the branch pushed and landed (step 1)
**Owns:** `repository/botopink-lang/libs/actions/src/id.bp` (new), `libs/actions/test/id_test.bp`,
`libs/actions/AGENTS.md`, `libs/actions/botopink.json` (`files`) · consumers:
`repository/rakun/modules/rakun-app/src/actions.bp` (`actionId` and its callers `actionIdOf`,
`resolveAction` only), `repository/jhonstart/modules/jhonstart-forms/src/form.bp` (the `wellFormed`
check of `formAction` only)
**Does not touch:** anything else in rakun-app or jhonstart-forms (`04-rakun` 22 and `05-jhonstart`
67 own the rest) · `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`

## Goal

rakun-app's `actionId(module, name, buildId)` (`actions.bp`) computes `"a_" +
hash.hmacSha256(rkProp("rakun.actions.secret"), module + "." + name + ":" + buildId).slice(0, 24)`.
jhonstart-forms' `formAction` re-checks the shape independently — `a_` prefix, no `/`, space or
quote — which is looser than the derivation: a 23-hex id passes jhonstart and can never match
rakun. When the front lands, both read one derivation and one grammar from `actions.id`.

**Name.** The package function is `deriveActionId`: rakun-app already exports `actionId`, and
decision 163 forbids a bundled package exporting a name a framework exports. rakun-app's own
`actionId` (read by its tests and by `actionIdOf` / `resolveAction`) keeps its name and becomes a
call of `deriveActionId` with the secret it reads.

## Open

### Step 1 — `id.bp`

`deriveActionId(secret, module, name, buildId) -> string` (the derivation above, over std
`hash.hmacSha256`), `isActionId(id) -> bool` (`a_` followed by exactly 24 lowercase hex digits).
The secret is a parameter; the package never reads `rakun.actions.secret`. std's `hmacSha256`
answers lowercase hex on both targets (Node `digest('hex')`, Erlang `~2.16.0b`); the test pins it.

- [ ] known-answer test: one fixed `(secret, module, name, buildId)` → one fixed id, on both rows;
      the id is lowercase, so `isActionId(deriveActionId(…))` holds
- [ ] `isActionId` refuses 23 and 25 digits, uppercase, and the empty suffix

### Step 2 — consumers

- [ ] rakun-app's `actionId` calls `actions.id.deriveActionId` (the derivation and its `slice` gone
      from rakun-app); `resolveAction`'s constant-time comparison is untouched; rakun-app's
      `actions_test.bp` green unchanged
- [ ] jhonstart-forms' `formAction` calls `isActionId`; its form tests green on both rows

**Gate:** standard (fronts.md § Gate) + `libs/actions/AGENTS.md` names `id`
