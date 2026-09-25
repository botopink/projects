# Front 07 (std track) — std writes JSON: `json.quote`, the writers, `escape.scriptJson`

The directory number is this front's index inside `01-std`; it is not a milestone front number —
rakun's front 07 is `03-rakun/07-rakun-middleware`. Everywhere else it is named
`01-std/07-std-json-writers`.

**Track:** A std
**Priority:** high — four private JSON writers in rakun can emit invalid JSON today, and the action
envelope (`05-actions-lib`), the payload (jhonstart front 30), `RenderPlugin.payload` (decision 114)
and the violation report (`06-validation-lib`) all need a correct one
**Target:** both — every function, erlang and commonJS (and the pure ones on every backend)
**Wave:** 0 — Step 1 beside `01-std`'s own steps; Step 2 after `01-std-lib-enablement` Step 1 has
created `escape.bp`. Both land either **before** `00 · 23-std-purity` opens or **after** it lands,
never while it holds `libs/std/src/**`; `json.bp` and `escape.bp` stay at the root of decision 106's
tree, so their path is the same on both sides of the move
**Depends on:** `01-std` step 2 (`testing.asserts`) · `01-std/01-std-lib-enablement` Step 1 (for
Step 2 only — it creates `escape.bp`)
**Owns:** the four new functions at the foot of `repository/botopink-lang/libs/std/src/json.bp`
(`quote`, `unquote`, `array`, `object`) and their inline tests · the one new function
`scriptJson` appended to `libs/std/src/escape.bp` below `01-std-lib-enablement`'s four, and its
inline tests · the `json` and `escape` rows of `libs/std/AGENTS.md` (the added names only)
**Does not touch:** `json.bp`'s `parse` and `stringify`; `escape.bp`'s `html`, `attribute`,
`unescapeHtml`, `jsString`; `libs/std/src/root.bp` (both modules are already exported, `escape` by
`01-std-lib-enablement` Step 10); every consumer — rakun fronts 05, 07 and 23, `05-actions-lib`,
`06-validation-lib` and jhonstart front 30 switch to these functions in their own fronts
**Reference:** [decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rules 3 and 8 · [RFC 8259 § 7](https://www.rfc-editor.org/rfc/rfc8259#section-7) (a JSON string
must escape `"`, `\` and U+0000–U+001F) · [HTML § 4.12.1.3](https://html.spec.whatwg.org/multipage/scripting.html#restrictions-for-contents-of-script-elements)
(what may not appear inside `<script>`)

**Why a front of its own, not steps in `01-std-lib-enablement`.** That front lists `json.bp` under
*Does not touch*, and its branch is being worked on in parallel; putting `quote` there would rewrite
its ownership lines rather than append to them. This front owns four functions in `json.bp`, which no
other std front writes, and appends one function to `escape.bp` after 01 lands — one sequenced
append, recorded in `fronts.md` § *Conflict rules*.

---

## Problem

std reads JSON only to validate it (`json.parse` and `json.stringify` both answer a re-serialised
`string`, `libs/std/src/json.bp:36,45`) and writes none. Every library that answers JSON therefore
wrote its own string escaper, and none escapes what RFC 8259 requires:

| Copy | Escapes | Evidence |
|---|---|---|
| rakun `jsonString` (+ `jsonStrings`, `jsonPairs`, `jsonTriples`) | `\` `"` `\n` `\r` `\t` | `modules/rakun/src/ssr.bp:641-676` |
| rakun-validation `jsonEscape` | `\` `"` `\n` `\r` `\t` | `modules/rakun-validation/src/report.bp:80` |
| rakun-web `jsonEscape` | `"` `\` `\n` `\r` `\t` | `modules/rakun-web/src/error.bp:131` |
| rakun config's string reader (the inverse) | reads `\n` `\t` `\r`, any other escaped char as itself — `\b`, `\f`, `A` misread | `modules/rakun/src/config.bp:394-433` |

A U+0001 in a user's input, echoed into any of those bodies, produces text a JSON parser rejects.
And a JSON value placed inside `<script>` needs one more escape none of them has: `</script>` ends
the element, and U+2028 / U+2029 end a JavaScript line in older engines — neither `escape.html`
(entities, wrong inside a script) nor `escape.jsString` (a JS string literal, not JSON text) is it.

## Current state

Measured 2026-09-25 on `repository/botopink-lang` `52843fd5` and `repository/rakun` `a8ba8bd`.

| Piece | State | Evidence |
|---|---|---|
| `json` | `parse`, `stringify` — validation only | `libs/std/src/json.bp:33-45` |
| `escape` | absent; specified with `html`, `attribute`, `unescapeHtml`, `jsString` | `01-std-lib-enablement` Step 1 |
| The copies | four, above | — |
| Their consumers | the payload writer (moving to jhonstart front 30), the problem-detail body (rakun-web front 07), the violation report and constraint table (moving to `libs/validation`), the JSON configuration reader (front 05) | decision 113 item 1; decision 116 rules 3 and 5 |

## Mechanism

```bp
// json — added
pub fn quote(s: string) -> string                          // a JSON string literal, quotes included
#[@result] pub fn unquote(literal: string) -> @Result<string, string>   // its inverse
pub fn array(items: Array<string>) -> string               // items already encoded
pub fn object(fields: Array<#(string, string)>) -> string  // keys quoted here, values already encoded

// escape — added
pub fn scriptJson(json: string) -> string                  // JSON text, safe inside <script>
```

`quote` escapes `"` as `\"`, `\` as `\\`, U+0008 / U+000C / U+000A / U+000D / U+0009 as `\b` `\f`
`\n` `\r` `\t`, every other code point below U+0020 as `\u00xx` (lowercase hex), and nothing else —
non-ASCII text passes through as UTF-8, as RFC 8259 allows. The front may implement it in botopink or
as an inline template per target (`JSON.stringify` on node, `json:encode` on erlang, OTP 28); either
way the acceptance literals below are the same on both targets, and a template whose output differs
from them on one target is replaced, not documented. `unquote` reads one string literal and refuses
anything else (a bare word, a number, a missing quote) with an `Error`.

`array` and `object` do no escaping of values: a value is the output of `quote`, a number's text,
`true` / `false` / `null`, or another writer's output. `object` quotes its keys with `quote` and keeps
the given order — the envelope's `v` first (contract 3) and the payload's key order (contract 2) are
the caller's order.

`scriptJson` takes JSON text and replaces `&` with `&`, `<` with `<`, `>` with `>`,
U+2028 with ` ` and U+2029 with ` `. In JSON those characters can only occur inside a
string, where each `\u` form is a valid escape, so the output is the same JSON value — `JSON.parse`
of it equals `JSON.parse` of the input — and it contains no `</script`, no `<!--` and no line
terminator a script parser would see.

## Steps

### Step 1 — `json.quote`, `json.unquote`, `json.array`, `json.object`

**Acceptance:**
- [ ] `json.quote("a\"b\\c")` answers `"a\"b\\c"` (as text: quote, `a`, `\"`, `b`, `\\`, `c`, quote)
- [ ] `json.quote` of a string holding U+0001, U+0008, U+000C, U+001F, a newline and a tab answers
      `"\u0001\b\f\u001f\n\t"`, identical on erlang and commonJS
- [ ] `json.quote("ação")` answers `"ação"` — non-ASCII is not escaped
- [ ] for every string `s` in the test table, `json.parse(json.quote(s))` is `Ok` and
      `json.unquote(json.quote(s))` is `Ok(s)`
- [ ] `json.unquote("abc")`, `json.unquote("\"abc")` and `json.unquote("1")` answer an `Error`
- [ ] `json.array([json.quote("a"), "1", "true"])` answers `["a",1,true]`; `json.array([])` answers `[]`
- [ ] `json.object([#("v", "1"), #("ok", "true"), #("s", json.quote("x"))])` answers
      `{"v":1,"ok":true,"s":"x"}` — order kept, keys quoted; `json.object([])` answers `{}`
- [ ] a key containing `"` is quoted by `object`: `json.object([#("a\"b", "1")])` parses

### Step 2 — `escape.scriptJson`

After `01-std-lib-enablement` Step 1 has created `escape.bp`; one function and its tests appended
below that front's four.

**Acceptance:**
- [ ] `escape.scriptJson(json.object([#("h", json.quote("</script><!--&"))]))` contains no `<`, `>`
      or `&`, and `json.parse` of it equals `json.parse` of the input
- [ ] U+2028 and U+2029 inside a string come out as ` ` and ` `
- [ ] JSON text with none of the five characters comes out unchanged
- [ ] the function declares no `#[@External]` cell

### Step 3 — The copies are deletable

This front deletes nothing outside std; it is done when each consumer front can. Each switch is that
front's step:

| Copy | Replaced by | Front |
|---|---|---|
| `ssr.bp:641-676` (`jsonString` …) | `json.quote`, `json.array`, `json.object` — in jhonstart's payload writer | jhonstart 30 (the writer leaves rakun, decision 113) |
| jhonstart's `payloadEscape` | `escape.scriptJson` | jhonstart 30 |
| `rakun-validation/src/report.bp:80` | `json.quote` | `06-validation-lib` |
| `rakun-web/src/error.bp:131` | `json.quote`, `json.object` | rakun 07 |
| `config.bp:394-433` (the string reader) | `json.parse` to check the document, `json.unquote` for each string token | rakun 05 |
| the action envelope and RPC body | `json.quote`, `json.array`, `json.object` | `05-actions-lib` |

**Acceptance:**
- [ ] `grep -rn "fn jsonString\|fn jsonEscape\|fn jsonStrings\|fn jsonPairs\|fn jsonTriples\|fn payloadEscape" --include=*.bp repository/`
      is empty once the fronts in the table have landed — asserted in this milestone's exit gate,
      not by this front

## Test plan

Inline `test` blocks at the foot of `json.bp` and `escape.bp`, as every std test (`fronts.md` § *std
tests are inline*), run by `botopink test` and `botopink test --target erlang` in `libs/std`. Every
expected text is a literal; the round-trip table covers the empty string, every code point below
U+0020, `"`, `\`, `/`, U+2028, U+2029 and a four-byte UTF-8 character.

## Gate

- [ ] `botopink test` green in `libs/std` on commonJS and erlang
- [ ] `libs/std/AGENTS.md`'s `json` and `escape` rows list the added functions
- [ ] no `root.bp` line changed

## Blast radius

Additive: four functions in `json.bp`, one in `escape.bp`. No existing function changes. The
consumers' switches — and the invalid JSON they stop emitting — are their fronts'.
