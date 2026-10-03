# Front 67 — jhonstart forms: the DOM-side boxes and the wire-name literals

**Priority:** medium-high — the forms are the write path of onze 53's proof; two open boxes
(`ok: false` in place; optimistic roll-back) are what a user hits first · **State:** not started
**Depends on:** `05-jhonstart/26` (steps 1–3 assert through 26's `fake_dom.mjs`; this front adds a
test file there, stops if a primitive is missing) · `03-bundled-libs/103-actions-id` step 2 (owns
`form.bp:117-121`, `formAction`'s hand id check, replaced by `actions.id.isActionId`; never together
— this one after; step 4 needs only 103) · `67-a` answered (recommendation (a); steps 1–3's
acceptance written for it)
**Owns:** `repository/jhonstart/modules/jhonstart-forms/**` except `src/form.bp:117-121` ·
`examples/forms/src/**`, `examples/forms/test/**` (with its `__snapshots__/`) ·
`modules/jhonstart-dom-test/test/forms_dom_test.bp` (new) · `modules/jhonstart-test/src/assert_form.bp`
and `harness.bp`'s new `stubWireNames()` (step 4) · this directory
**Does not touch:** `modules/jhonstart/**`, `modules/jhonstart-dom-test/src/fake_dom.mjs` (26) ·
`modules/jhonstart-link/**` (27) · `form.bp:117-121` (`103-actions-id`) · `libs/actions/**`
(envelope and `state` grammar; a literal asserted there stays)

## Goal

1. Five boxes on the browser after `__jhFormState` returns an envelope: `fieldError` reads it; an
   `ok: false` envelope re-renders the form in place, no boundary entered, no field value lost; two
   in-flight forms give each button its own `pending` / `actionId`; an arriving envelope drops the
   recorded optimistic actions (commit and roll-back one path); a `push` after the envelope records
   against the next submit. `form_test.bp` (15 tests) asserts server-pass values and markup; none
   runs the browser half (`form_runtime.mjs`: `__jhFormState`, submit interception, optimistic
   queue; `formMount()` called by onze's generated entry). After: the five run in
   `jhonstart-dom-test` over `fake_dom.mjs` on commonJS.
2. `"__bp_action"` / `"X-Bp-Action"` are onze's defaults, passed to both sides via `setWireNames`
   (decision 114: "neither library spells them"); asserting the literal pins a value the library
   does not own. Spelled today in `modules/jhonstart-forms/test/form_test.bp` (18 lines),
   `examples/forms/src/like.bp:23`, `examples/forms/src/main.bp:14`,
   `examples/forms/test/forms_test.bp:16,21,30,36`, four snapshots under
   `examples/forms/test/__snapshots__/forms/` (`create_post_empty`,
   `create_post_returned_message_beside_the_title`, `like_widget_server_pass_shows_the_server_s_count`,
   `like_widget_optimistic_count_with_a_busy_nested_button`). After: none.

## Mechanism

- Under `67-a` (a), `fake_dom.mjs` (26's) needs `<form>` / `<input>` with `name` / `value`,
  `FormData` over them, a `submit` event with `preventDefault`, and the `fetch` double the runtime
  posts the RPC body to (recorded request, scripted envelope). Forms' browser functions share the
  render's registry, so `forms_dom_test.bp` calls them by name like `dom_test.bp`. A missing
  primitive is reported to 26, not edited.
- Under (b) the five boxes move whole to `07-onze/53`'s browser script; this front keeps step 4.
- CSRF `Origin` / `Host` check and body limit stay rakun's; onze 53 asserts the 403.

## Open

### Step 1 — `actionState` in the document

- [ ] `forms_dom_test.bp` "forms: fieldError after an envelope": with `fetch` answering
      `writeEnvelope(ok: false, state: writeState("…", [#("title", "Too short")]))`, submitting the
      create-post form leaves `fieldError("title") == "Too short"` in the re-rendered form
- [ ] "forms: ok:false re-renders in place": same submit keeps the typed `title`, enters no boundary
      (`data-jh-e` absent after), form element identity unchanged (`===` on the recorded node)

### Step 2 — `formStatus` for two forms

- [ ] "forms: pending is per form": two forms submitted with `fetch` held open — each button's
      `pending` is `true`, its `actionId` its own form's; resolving one leaves the other pending

### Step 3 — `optimistic`

- [ ] "forms: commit and roll-back are one path": a like with `push(+1)` shows `n+1` before the
      envelope; an `ok: true` envelope carrying `n+1` and an `ok: false` one carrying `n` both end in
      `optimistic()` equal to the envelope's value, recorded actions empty — two tests, same final
      assertion
- [ ] "forms: a late push records against the next submit": `push` after the envelope leaves the
      settled value and one recorded action for the next submit

### Step 4 — the wire names are handed in

- [ ] `form_test.bp`, `examples/forms/src/like.bp`, `examples/forms/src/main.bp`,
      `examples/forms/test/forms_test.bp` take field and header names from a fixture
      (`stubWireNames()` in `jhonstart-test/harness.bp`, values unequal to onze's defaults) through
      `setWireNames`; the four `examples/forms` snapshots carrying the field name re-record
      (renaming the `.new` files); `grep -rn "__bp_action\|X-Bp-Action" repository/jhonstart` is empty
- [ ] `07-onze/49`'s last box for the jhonstart side is closable on that grep

### Step 5 — the examples

[`examples/create-post-form-example.bp`](./examples/create-post-form-example.bp) and
[`optimistic-like-example.bp`](./examples/optimistic-like-example.bp) are the shapes steps 1–3
assert (`examples/src/**/*.bpp` show them as `.bpp`); corrected here if the surface moves. Neither
carries a `// LANGUAGE GAP` marker.

- [ ] `botopink check` over both against `modules/jhonstart-forms` passes

**Gate:** standard (fronts.md § Gate) + `jhonstart-forms` at 15 or above on both rows;
`jhonstart-dom-test` on commonJS with the new file; `examples/forms` green on both rows with its
four re-recorded snapshots
