# The `./gleam_stdlib.mjs` declarations

`libs/std/src/primitives.bp` names `./gleam_stdlib.mjs` 22 times. The file exists in no repository,
in no commit, and no build step copies it. What that costs is narrower — and sharper — than
"22 broken primitives": 18 are inert, 4 break, and the 4 that break replace a working native method
with one that throws.

Row C1 of the codegen-hardening spec is the same finding counted from the commonJS side: it closes
**9** fixtures. Removing the dependency is a `libs/std` edit and needs no compiler change, which is
why the row belongs to this front and not to a backend row; the helper mechanism the removal leans
on where no native method matches is a commonJS-emitter change, routed to
[`../08-js-bridges/`](../08-js-bridges/README.md). `external_import_binds_symbol` names a second
phantom companion, `./stdlib.mjs`; that one is a fixture, not std source.

---

## The decision: the dependency is removed, not satisfied

**`gleam_stdlib.mjs` is the Gleam language's runtime, not ours.** The 22 annotations name a file from
another language's standard library — `string_length`, `starts_with`, `trim_start` are Gleam symbols
— and `libs/std/src/order.bp:1` says outright that the module is "inspired by `gleam/order`". The
reference is a leftover from that borrowing, so **shipping the file is not on the table**: vendoring
another language's runtime to satisfy our own primitives would make botopink depend on Gleam's ABI
for `slice`.

Two consequences follow, and the second is the one that decides the shape of the work.

### 1 — Native JS where the semantics already match

The annotation almost always names the native method it wants (`slice`, `split`, `startsWith`,
`trim`, `indexOf`, `join`, `map`, `filter`, `push`, `pop`). Where the native method's semantics are
already the ones the signature promises, the declaration becomes an inline `@External.Node`
template: zero runtime, zero load, nothing shipped. The 18 inert declarations already behave this
way *by accident* (see [Mechanism](#mechanism) — the emitter skips them and the native method of the
same name carries the call), so for them this is also the smallest possible change: it makes the
annotation say what the backend already does.

### 2 — A compiler-owned helper, emitted on demand, where no native method matches

Not every primitive has a native JS method with the right semantics, so "just use the native method"
does not cover the whole surface. We will need JavaScript helper code of our own.

**It must not be a module that always loads.** `require("./botopink_stdlib.mjs")` would pull the
whole file in at the first call no matter how little of it is used — the same coupling as the Gleam
companion, with our name on it. The rule is: **only the function actually used is emitted.** The
emitter writes *that one helper function* into the generated module when a call site asks for it; no
file is shipped, no `require` appears, and nothing is loaded that is not used.

### The precedent is already in the tree

This project has solved the same problem three times, on the other three backends:

| Backend | Mechanism | Property worth copying |
|---|---|---|
| wasm | `codegen/wat/wat_prelude.zig`, `Builder.helper` | Asking for a helper **and** marking it for emission is a *single operation*, so "called" and "defined" cannot diverge — it replaced nine `uses_*` booleans |
| beam | `codegen/beam_asm.zig` — `ensureStringifyHelper`, `ensureIndexOfHelper`, `ensureAtHelper` | Synthesised on first use, cached on the emitter |
| erlang | `codegen/erlang.zig` — `comptime_helper_forms` (`__bp_add`, `__bp_len`, `__bp_text`, `__bp_json`) | A fixed helper set carried by the module that needs it |

commonJS is the only backend **without** that mechanism, which is exactly why it reached for someone
else's runtime file. The fix is not a new idea; it is the third instance of an existing one.

Take the `wat_prelude.zig` shape — request-and-mark as one call — because the failure it prevents is
the one this row is about: a helper that is referenced and not defined is precisely
`Cannot find module './gleam_stdlib.mjs'` in a different costume.

### Where the helper source lives

One helper set per backend, in that backend's emitter directory (`codegen/js/` for commonJS,
mirroring `codegen/wat/wat_prelude.zig`) — **not** one cross-backend source, because the bodies are
in four different languages and cannot be shared. What must not be duplicated is the *identity* of a
helper: `primitives.bp` names it once per declaration, and each backend's prelude answers that name.
That is what keeps `String.charAt` meaning the same thing on node and on beam, and it is already how
the other 21 declarations carry their `@External.Erlang` (and 5 their `@External.Beam`) beside the
node form.

### What the helper set contains

Start from the four that break today, then add whichever of the other 18 the audit finds:

| Helper | Why it cannot be the native method |
|---|---|
| `stringSlice0` / `stringSlice1` (`primitives.bp:231`, `:235`) | Behind `default fn slice` (`:165-171`); today the prototype patch replaces `String.prototype.slice` with a throwing body |
| `arraySlice0` / `arraySlice1` (`:828`, `:832`) | Behind `default fn slice` (`:572-578`); same patch on `Array.prototype.slice` |
| `String.charAt` (`:174`) | **Known mismatch**: JS returns `""` where the signature says `?string`. Either a helper, or the signature changes |

Audit the rest before choosing per declaration — the checks that matter are the ones where JS is
lenient and the signature is not: negative indices (`slice`, `at`, `charAt`), an empty separator
(`split("")`), which code points `trim`/`trimStart`/`trimEnd` strip, `startsWith`/`endsWith` with an
empty needle or an offset, and `indexOf` returning `-1` where the signature says `?i32`. Each
mismatch found is a helper; each match is an inline template. Record the verdict per row in the
table below so the next reader does not re-derive it.

Two shapes are therefore **rejected**, and the reasons are recorded so they are not re-proposed:

| Rejected | Why |
|---|---|
| Write and ship `libs/std/src/sidecars/gleam_stdlib.mjs` (12 exports, through `shipMjsSidecars` in `cli/libs.zig`, which already probes `<lib>/src/sidecars/<base>`) | A new file to maintain, a `require` on every `.slice` call, and it keeps another language's name on our runtime. The other 18 stay inert either way |
| Keep the annotations as documentation and fix only the four `declare fn` | Leaves a live trap: any future `declare fn` with a relative companion breaks silently |

---

## Mechanism

A 3-arg `@External.Node("<module>", "<symbol>")` on an *interface method* is skipped by both the
emitter and inference when `<module>` is a relative companion: `commonJS.zig:1431`
(`if (!isJsGlobalNamespace(ref.module)) continue;` — no prototype patch) and `infer.zig:6675-6677`
("left to the permissive path (native JS handles them)"). The call-site rename map is fed only by
the **2-arg** form (`commonJS.zig:734-742, 786-788`), so no rename is recorded either. The call
therefore emits verbatim — `xs.at(0)`, `path.split(sep)` — and resolves against the real JS
prototype.

A 3-arg annotation on a **`declare fn`** has no receiver to fall back to, so it emits
`require("./gleam_stdlib.mjs").<symbol>(…)` and throws at require time.

Measured over the whole of `libs/std` compiled to `commonJS`: the only gleam symbols that reach
emitted JavaScript are `slice` (12 call sites) and `string_slice` (4).

## The 22 declarations

| # | Declaration | `primitives.bp` | gleam symbol | Emitted JS | Status |
|---|---|---|---|---|---|
| 1 | `String.length` | `:118` | `string_length` | none — `.length` is only ever read as a property | inert |
| 2 | `String.split` | `:122` | `split` | `s.split(sep)` | inert · native |
| 3 | `String.startsWith` | `:140` | `starts_with` | `s.startsWith(p)` | inert · native |
| 4 | `String.endsWith` | `:145` | `ends_with` | `s.endsWith(x)` | inert · native |
| 5 | `String.trim` | `:150` | `trim` | `s.trim()` | inert · native |
| 6 | `String.trimStart` | `:154` | `trim_start` | `s.trimStart()` | inert · native |
| 7 | `String.trimEnd` | `:158` | `trim_end` | `s.trimEnd()` | inert · native |
| 8 | `String.replace` | `:162` | `replace` | `s.replace(a, b)` | inert · native |
| 9 | `String.charAt` | `:174` | `string_char_at` | `s.charAt(i)` | inert · native, **semantics differ**: JS returns `""` where the signature says `?string` |
| 10 | `String.indexOf` | `:178` | `index_of` | `s.indexOf(sub)` | inert · native |
| 11 | `stringSlice0` | `:231` | `string_slice` | `require("./gleam_stdlib.mjs").string_slice(self, start)` | **broken** |
| 12 | `stringSlice1` | `:235` | `string_slice` | `require("./gleam_stdlib.mjs").string_slice(self, start, end)` | **broken** |
| 13 | `Array.at` | `:561` | `index` | `xs.at(i)` | inert · native (ES2022) |
| 14 | `Array.push` | `:565` | `push` | `xs.push(x)` | inert · native |
| 15 | `Array.pop` | `:569` | `pop` | `xs.pop()` | inert · native |
| 16 | `Array.join` | `:581` | `join` | `xs.join(sep)` | inert · native |
| 17 | `Array.indexOf` | `:590` | `index_of` | `xs.indexOf(x)` | inert · native |
| 18 | `Array.forEach` | `:594` | `for_each` | `xs.forEach(f)` | inert · native |
| 19 | `Array.map` | `:598` | `map` | `xs.map(f)` | inert · native |
| 20 | `Array.filter` | `:602` | `filter` | `xs.filter(p)` | inert · native |
| 21 | `arraySlice0` | `:828` | `slice` | `require("./gleam_stdlib.mjs").slice(this, start)` | **broken** |
| 22 | `arraySlice1` | `:832` | `slice` | `require("./gleam_stdlib.mjs").slice(this, start, end)` | **broken** |

**18 of 22 are inert** — the annotation documents an intent the backend never acts on, and the
native JS method of the same name carries the call. No other backend is affected: each of the 22
also carries `@External.Erlang` (and 5 carry `@External.Beam`), which is what erlang and beam use.

## The four that break, and why they break more than themselves

`stringSlice0/1` and `arraySlice0/1` are the arity-dispatch helpers behind `default fn slice`
(`primitives.bp:165-171` for `String`, `:572-578` for `Array`). Because `slice` is a `default fn`,
the emitter *does* patch the prototype — `String.prototype.slice` and `Array.prototype.slice` appear
in the emitted std — so the patch **replaces the working native `slice` with one that throws**:

```javascript
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
     if (end) { return require("./gleam_stdlib.mjs").string_slice(self, start, end); } else { … };
};
```

(`snapshots/codegen/commonJS/string_methods_map_to_native_js_names.snap.md:39-42`; the array twin is
`array_slice_2_arg_lowers_byte_identically_across_backends.snap.md:57`.)

This is also the reason the prototype patch is the right place for the helper mechanism: the body is
already synthesised per declaration, so "emit the helper the body calls" is the same code path, one
step further.

## Who else it breaks

Every one of the 18 `botopink test` failures in `libs/std` is this, and nothing else:

| Module | Failing tests | Reached through |
|---|---|---|
| `url` | 8 | `.slice` in `parse`/`serialize` |
| `path` | 5 (`dirname`, `relative` ×2, `resolve` ×2) | `.slice` |
| `queue` | 4 | `.slice` |
| `querystring` | 1 | `query.slice(1, query.length)` |

Plus, outside std: 2 of erika's 18 fluent tests, and the jhonstart/onze paths recorded in
[`../01-comptime-dispatch/README.md`](../01-comptime-dispatch/README.md).

Five committed commonJS snapshots pin the broken `require` as the expected output
(`string_methods_map_to_native_js_names`, `string_slice_copies_bytes_into_a_new_buffer`,
`array_slice_2_arg_lowers_byte_identically_across_backends`, `array_instance_default_fn_methods`,
`option_method_on_tuple_element`, `array_zip_via_external_node_template`), four of them with an
empty RUN LOG. The row inside the method body is why the damage is bounded: the `require` sits
**inside** the method, so only a fixture that actually calls the method dies
(`Error: Cannot find module './gleam_stdlib.mjs'`), which is how 11 snapshots can emit it while only
9 fixtures show it.

## Acceptance

- [ ] No declaration in `libs/std` names a file that is not shipped, and no emitted module contains
      `require("./gleam_stdlib.mjs")`
- [ ] Every one of the 22 declarations is either an inline native template or a named helper, with
      the verdict recorded per row in the table above
- [ ] **A program that calls one helper emits one helper and no `require`** — asserted by a codegen
      test that greps the emitted module for the helpers it did *not* call
- [ ] Requesting a helper and marking it for emission is a single operation, as in
      `codegen/wat/wat_prelude.zig` — no separate "used" flag a caller can forget
- [ ] `libs/std`'s 18 `./gleam_stdlib.mjs` test failures are green, and the six commonJS snapshots
      that pin the `require` are re-recorded with a non-empty RUN LOG
- [ ] `libs/std/AGENTS.md` states what a 3-arg `@External.Node` with a relative module does on an
      interface method versus on a `declare fn`, and that a relative companion module is not a
      supported form
