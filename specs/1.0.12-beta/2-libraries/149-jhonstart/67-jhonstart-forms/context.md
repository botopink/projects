# Front 67 — jhonstart forms: the DOM-side boxes and the wire-name literals

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [149-jhonstart](../README.md): s1 → 149 s3 · s2 → 149 s3 · s3 → 149 s3 · s4 → 149 s3 · s5 → 149 s3. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** medium-high — the forms are the write path of onze 53's proof; two open boxes
(`ok: false` in place; optimistic roll-back) are what a user hits first · **State:** not started
**Depends on:** `05-jhonstart/26` (steps 1–3 assert through 26's `fake_dom.mjs`; this front adds a
test file there, stops if a primitive is missing) · `03-bundled-libs/103-actions-id` step 2 (owns
`form.bp:117-121`, `formAction`'s hand id check, replaced by `actions.id.isActionId`; never together
— this one after; step 4 needs only 103) · `67-a` pending — steps 1–3 written for (a), the
recommendation; only the record is missing
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
