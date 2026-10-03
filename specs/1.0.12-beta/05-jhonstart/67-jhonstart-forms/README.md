# Front 67 — jhonstart forms: the DOM-side boxes and the wire-name literals

**Priority:** medium-high — the forms are the write path of onze 53's proof, and two of the four
open boxes (`ok: false` in place; optimistic roll-back) are the ones a user hits first
**Depends on:** `05-jhonstart/26` (steps 1–3 assert through `jhonstart-dom-test`'s `fake_dom.mjs`,
which 26 owns — this front adds a test file there and stops if it needs a primitive the document
lacks) · `03-bundled-libs/103-actions-id` (owns `form.bp:117-121`; the two fronts never run
together — this one after) · maintainer answer to `67-a` (recommendation (a) — the acceptance below
is written for it) · nothing from `02-std-and-packaging`
**Owns:** `repository/jhonstart/modules/jhonstart-forms/**` except `src/form.bp:117-121` ·
`examples/forms/src/**`, `examples/forms/test/**` · `modules/jhonstart-dom-test/test/forms_dom_test.bp`
(new) · `modules/jhonstart-test/src/assert_form.bp` · this directory
**Does not touch:** `modules/jhonstart/**`, `modules/jhonstart-dom-test/src/fake_dom.mjs` (26) ·
`modules/jhonstart-link/**` (27) · `form.bp:117-121` (`103-actions-id`) · `libs/actions/**`
(the envelope and the `state` grammar; a literal asserted there stays there)
**Carried from 1.0.10:** `04-jhonstart/67-jhonstart-forms/README.md` § Step 3 (two boxes), § Step 4
(two), § Step 5 (two) · `06-onze/49-onze-stand-up/README.md` § Step 4 last box (the literals under
`repository/jhonstart/`) · `examples/{create-post-form,optimistic-like}-example.bp` (copied)

---

## Problem

1. Six acceptance boxes of front 67 describe what happens in the browser after `__jhFormState`
   returns an envelope — `fieldError` reads it, an `ok: false` envelope re-renders the form in
   place with no boundary entered and no field value lost, two in-flight forms give each button
   its own `pending` / `actionId`, an arriving envelope drops the recorded optimistic actions so
   commit and roll-back are one path, and a `push` after the envelope records against the next
   submit. `form_test.bp` asserts the server-pass values (a hook called without `use`) and the
   markup; none of the six runs the browser half (`form_runtime.mjs`).
2. `modules/jhonstart-forms/test/form_test.bp` and `examples/forms/src/like.bp:23` spell
   `"__bp_action"` / `"X-Bp-Action"`. Those are onze's defaults, passed to both sides through
   `setWireNames` (decision 114: "neither library spells them"); a test asserting the literal
   pins a value the library does not own.

## Current state

`jhonstart-forms` green on both rows (the 1.0.10 count); `jhonstart-dom-test` runs `render.mjs`'s
functions over `fake_dom.mjs` on commonJS (30-g). `formMount()` is called by onze's generated
entry; `form_runtime.mjs` holds `__jhFormState`, the submit interception and the optimistic
queue. `form.bp:117-121` re-checks the action id's shape — `103-actions-id` replaces it with
`actions.id.isActionId`.

## Mechanism

Under `67-a` (a), `fake_dom.mjs` (26's) needs `<form>` / `<input>` elements with `name` /
`value`, `FormData` over them, a `submit` event with `preventDefault`, and the `fetch` double the
runtime posts the RPC body to (a recorded request answering a scripted envelope). The forms'
browser functions are registered under the same registry the render's are, so
`forms_dom_test.bp` calls them by name like `dom_test.bp` does. If a primitive is missing this
front reports it to 26 rather than editing `fake_dom.mjs`.

## Steps

### Step 1 — `actionState` in the document

**Acceptance:**
- [ ] `forms_dom_test.bp` "forms: fieldError after an envelope": with `fetch` answering
      `writeEnvelope(ok: false, state: writeState("…", [#("title", "Too short")]))`, submitting the
      create-post form leaves `fieldError("title") == "Too short"` in the re-rendered form
- [ ] "forms: ok:false re-renders in place": the same submit keeps the typed `title` value, enters
      no boundary (`data-jh-e` absent from the document after), and the form element's identity is
      unchanged (`===` on the recorded node)

### Step 2 — `formStatus` for two forms

**Acceptance:**
- [ ] "forms: pending is per form": two forms submitted with `fetch` held open — each button's
      `pending` is `true` and its `actionId` is its own form's; resolving one leaves the other
      pending

### Step 3 — `optimistic`

**Acceptance:**
- [ ] "forms: commit and roll-back are one path": a like with `push(+1)` shows `n+1` before the
      envelope; an `ok: true` envelope carrying `n+1` and an `ok: false` one carrying `n` both end
      in `optimistic()` equal to the envelope's value with the recorded actions empty — two tests
      ending in the same assertion
- [ ] "forms: a late push records against the next submit": `push` after the envelope arrives
      leaves the settled value and one recorded action for the next submit

### Step 4 — the wire names are handed in

**Acceptance:**
- [ ] `form_test.bp` and `examples/forms/src/like.bp` take the field and header names from a test
      fixture (`stubWireNames()` in `jhonstart-test/harness.bp`, values chosen not to equal onze's
      defaults) through `setWireNames`; `grep -rn "__bp_action\|X-Bp-Action" repository/jhonstart`
      is empty
- [ ] `07-onze/49`'s last box for the jhonstart side is closable on that grep

### Step 5 — the examples

[`examples/create-post-form-example.bp`](./examples/create-post-form-example.bp) and
[`optimistic-like-example.bp`](./examples/optimistic-like-example.bp) are the shapes steps 1–3
assert; they are corrected here if the surface moves (none of them carries a `// LANGUAGE GAP`
marker).

**Acceptance:**
- [ ] `botopink check` over both against `modules/jhonstart-forms` passes

## Gate

- [ ] `zig build test-libs` — `jhonstart-forms` at its count or above on both rows;
      `jhonstart-dom-test` on commonJS with the new file; `examples/forms` green on both rows
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/67-jhonstart-forms`; no push, no merge — landing is the maintainer's step

## Blast radius

None on the surface: every box tests behaviour that exists. Step 4 changes two test files and one
example line. Sequenced after `103-actions-id` so `form.bp` has one editor at a time.

## Notes

- Under `67-a` (b) the six boxes move whole to `07-onze/53`'s browser script and this front
  keeps step 4 only.
- The CSRF `Origin` / `Host` check and the body limit stay rakun front 24's; onze 53 asserts the
  403.
