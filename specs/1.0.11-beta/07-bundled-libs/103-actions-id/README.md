# Front 103 — `actions` gains `id`

**Priority:** high — the action id is a security boundary derived in one place and re-checked in
another; two grammars for it is one too many.
**Depends on:** `00-gate` green · `07-i`.
**Owns:** `repository/botopink-lang/libs/actions/src/id.bp` (new), `libs/actions/test/id_test.bp`,
`libs/actions/AGENTS.md`, `libs/actions/botopink.json` (`files`) · consumers:
`repository/rakun/modules/rakun-app/src/actions.bp` (lines 199-203 only),
`repository/jhonstart/modules/jhonstart-forms/src/form.bp` (lines 117-121 only).
**Does not touch:** anything else in rakun-app or jhonstart-forms (`03-rakun` 24 and `04-jhonstart`
67 own the rest) · `build.zig`, `libs/AGENTS.md`, `scripts/format-check.sh`.

---

## Problem

rakun-app computes `"a_" + hmacSha256(secret, module + "." + name + ":" + buildId).slice(0, 24)`
(`actions.bp:199-203`). jhonstart-forms independently re-checks the shape — `a_` prefix, no `/`,
space or quote (`form.bp:117-121`). The check is looser than the derivation: a 23-hex id passes
jhonstart and can never match rakun.

## Steps

### Step 1 — `id.bp`

`actionId(secret, module, name, buildId) -> string` (the exact derivation above, over std
`hash.hmacSha256`), `isActionId(id) -> bool` (`a_` followed by exactly 24 lowercase hex digits).
The secret is a parameter; the package never reads `rakun.actions.secret`.

**Acceptance:**
- [ ] known-answer test: one fixed `(secret, module, name, buildId)` → one fixed id, on both rows
- [ ] `isActionId` refuses 23 and 25 digits, uppercase, and the empty suffix

### Step 2 — consumers

- [ ] rakun-app `resolveAction` calls `actionId`; its constant-time comparison is untouched
- [ ] jhonstart-forms calls `isActionId`; its form tests green on both rows

## Gate

- [ ] `zig build test` cold, green; `zig build test-libs` green
- [ ] `libs/actions/AGENTS.md` updated in the same commit
- [ ] Commit on `front/103-actions-id`

## Blast radius

Two files outside `libs/`. No snapshot.
