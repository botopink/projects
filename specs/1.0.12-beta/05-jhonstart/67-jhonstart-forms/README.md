# Front 67 — jhonstart forms: the DOM-side boxes and the wire-name literals

**Priority:** medium-high — the forms are the write path of onze 53's proof, and two of the open
boxes (`ok: false` in place; optimistic roll-back) are the ones a user hits first ·
**State:** not started
**Depends on:** `05-jhonstart/26` (steps 1–3 assert through `jhonstart-dom-test`'s
`fake_dom.mjs`, which 26 owns — this front adds a test file there and stops if it needs a
primitive the document lacks) · `03-bundled-libs/103-actions-id` step 2 (owns `form.bp:117-121`,
`formAction`'s hand check of the id, which it replaces with `actions.id.isActionId`; the two
fronts never run together — this one after; step 4 needs only 103) · `67-a` answered
(recommendation (a) — the acceptance of steps 1–3 is written for it)
**Owns:** `repository/jhonstart/modules/jhonstart-forms/**` except `src/form.bp:117-121` ·
`examples/forms/src/**`, `examples/forms/test/**` (with its `__snapshots__/`) ·
`modules/jhonstart-dom-test/test/forms_dom_test.bp` (new) · `modules/jhonstart-test/src/assert_form.bp` and `harness.bp`'s new `stubWireNames()` (step 4) ·
this directory
**Does not touch:** `modules/jhonstart/**`, `modules/jhonstart-dom-test/src/fake_dom.mjs` (26) ·
`modules/jhonstart-link/**` (27) · `form.bp:117-121` (`103-actions-id`) · `libs/actions/**`
(the envelope and the `state` grammar; a literal asserted there stays there)

## Goal

1. Five acceptance boxes describe what happens in the browser after `__jhFormState` returns an
   envelope — `fieldError` reads it, an `ok: false` envelope re-renders the form in place with no
   boundary entered and no field value lost, two in-flight forms give each button its own
   `pending` / `actionId`, an arriving envelope drops the recorded optimistic actions so commit and
   roll-back are one path, and a `push` after the envelope records against the next submit.
   `form_test.bp` (15 tests) asserts the server-pass values and the markup; none runs the
   browser half (`form_runtime.mjs`, which holds `__jhFormState`, the submit interception and the
   optimistic queue; `formMount()` is called by onze's generated entry). When this front lands,
   the five run in `jhonstart-dom-test` over `fake_dom.mjs` on commonJS.
2. `"__bp_action"` / `"X-Bp-Action"` are onze's defaults, passed to both sides through
   `setWireNames` (decision 114: "neither library spells them"); a test asserting the literal pins
   a value the library does not own. Today they are spelled in
   `modules/jhonstart-forms/test/form_test.bp` (18 lines), `examples/forms/src/like.bp:23`,
   `examples/forms/src/main.bp:14`, `examples/forms/test/forms_test.bp:16,21,30,36`, and four
   recorded snapshots under `examples/forms/test/__snapshots__/forms/` (`create_post_empty`,
   `create_post_returned_message_beside_the_title`, `like_widget_server_pass_shows_the_server_s_count`,
   `like_widget_optimistic_count_with_a_busy_nested_button`). When this front lands, none is.

## Mechanism

Under `67-a` (a), `fake_dom.mjs` (26's) needs `<form>` / `<input>` elements with `name` /
`value`, `FormData` over them, a `submit` event with `preventDefault`, and the `fetch` double the
runtime posts the RPC body to (a recorded request answering a scripted envelope). The forms'
browser functions are registered under the same registry the render's are, so
`forms_dom_test.bp` calls them by name like `dom_test.bp` does. If a primitive is missing this
front reports it to 26 rather than editing `fake_dom.mjs`. Under `67-a` (b) the five boxes move
whole to `07-onze/53`'s browser script and this front keeps step 4 only. The CSRF `Origin` /
`Host` check and the body limit stay rakun's; onze 53 asserts the 403.

## Open

### Step 1 — `actionState` in the document

- [ ] `forms_dom_test.bp` "forms: fieldError after an envelope": with `fetch` answering
      `writeEnvelope(ok: false, state: writeState("…", [#("title", "Too short")]))`, submitting the
      create-post form leaves `fieldError("title") == "Too short"` in the re-rendered form
- [ ] "forms: ok:false re-renders in place": the same submit keeps the typed `title` value, enters
      no boundary (`data-jh-e` absent from the document after), and the form element's identity is
      unchanged (`===` on the recorded node)

### Step 2 — `formStatus` for two forms

- [ ] "forms: pending is per form": two forms submitted with `fetch` held open — each button's
      `pending` is `true` and its `actionId` is its own form's; resolving one leaves the other
      pending

### Step 3 — `optimistic`

- [ ] "forms: commit and roll-back are one path": a like with `push(+1)` shows `n+1` before the
      envelope; an `ok: true` envelope carrying `n+1` and an `ok: false` one carrying `n` both end
      in `optimistic()` equal to the envelope's value with the recorded actions empty — two tests
      ending in the same assertion
- [ ] "forms: a late push records against the next submit": `push` after the envelope arrives
      leaves the settled value and one recorded action for the next submit

### Step 4 — the wire names are handed in

- [ ] `form_test.bp`, `examples/forms/src/like.bp`, `examples/forms/src/main.bp` and
      `examples/forms/test/forms_test.bp` take the field and header names from a test fixture
      (`stubWireNames()` in `jhonstart-test/harness.bp`, values chosen not to equal onze's
      defaults) through `setWireNames`; the four `examples/forms` snapshots that carry the field
      name re-record (by renaming the `.new` files); `grep -rn "__bp_action\|X-Bp-Action"
      repository/jhonstart` is empty
- [ ] `07-onze/49`'s last box for the jhonstart side is closable on that grep

### Step 5 — the examples

[`examples/create-post-form-example.bp`](./examples/create-post-form-example.bp) and
[`optimistic-like-example.bp`](./examples/optimistic-like-example.bp) are the shapes steps 1–3
assert (`examples/src/**/*.bpp` show the same components as `.bpp` files); they are corrected
here if the surface moves. Neither carries a `// LANGUAGE GAP` marker.

- [ ] `botopink check` over both against `modules/jhonstart-forms` passes

**Gate:** standard (fronts.md § Gate) + `jhonstart-forms` at 15 or above on both rows;
`jhonstart-dom-test` on commonJS with the new file; `examples/forms` green on both rows with its
four re-recorded snapshots
