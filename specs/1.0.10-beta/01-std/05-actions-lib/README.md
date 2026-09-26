# Front 05 (std track) — the bundled `actions` library

The directory number is this front's index inside `01-std`, beside `04-routing-lib`; it is not a
milestone front number — rakun's front 05 is `03-rakun/05-rakun-config-profiles`. Everywhere else it
is named `01-std/05-actions-lib`.

**Track:** A std
**Priority:** high — a server action is written by rakun on erlang and read by jhonstart in the
browser; until this library exists the two sides can only agree by pinning the same literal twice,
and rakun front 24 and jhonstart front 67 have nothing to import
**Target:** both — erlang and commonJS, every module. The library keeps no state and ships `.bp`
files only (decision 117 rule 8); it reads JSON with std's `json.decode` and declares no
`#[@External]` cell
**Wave:** 0 — the library beside `01-std`'s steps, after `01-std-lib-enablement` Step 3
(`encoding`), `01-std-lib-enablement` Steps 11 and 13 (`json.quote`, the writers and `json.decode`) and `04-routing-lib`
Step 7 (`navigation`); before rakun 24 and jhonstart 67 (waves 6–7)
**Depends on:** `01-std` step 2 (`testing.asserts`) · `01-std/01-std-lib-enablement` Step 3
(`encoding.percentEncode` / `percentDecode` / `formParse` / `formStringify`) ·
`01-std/01-std-lib-enablement` Steps 11 and 13 (`json.quote`, `json.array`, `json.object`,
`json.decode`) · `01-std/04-routing-lib`
Step 7 (`navigation.signalToWire` / `signalFromWire`) and Step 2 (the bundled-package registry this
front adds one name to, which opens after `00 · 23-std-purity`). Steps 1–5 do not wait on Step 2 of
`04-routing-lib`: the library is compiled and tested from its own directory until Step 6 bundles it
**Owns:** `repository/botopink-lang/libs/actions/**` (`botopink.json`, `AGENTS.md`, `src/root.bp`,
`src/state.bp`, `src/envelope.bp`, `src/rpc.bp`, `src/refresh.bp`, `test/**`) · the `actions` row
of `repository/botopink-lang/libs/AGENTS.md` · the name `actions` in the bundled-package list
`04-routing-lib` Step 2 introduces in `build.zig` (one entry, by the same carve-out)
**Does not touch:** `libs/std/**`, `libs/routing/**`; `repository/rakun/**` — rakun front 24 writes
the envelope and reads the RPC body with this library; `repository/jhonstart/**` — front 67 reads
the envelope and writes the RPC body, front 26 sends `refreshValue()`; `repository/onze/**` — onze
still passes `actionField` / `actionHeader` to both sides (decision 114 item 7)
**Reference:** [decision 116](../../decisions-taken.md#116-code-two-libraries-both-run-is-neutral-routing-gains-navigation-and-param-actions-and-validation-are-bundled-libraries-std-writes-json)
rule 2 (the library, its modules, no wire name built in) · decision 115 (a bundled library is neutral
and resolves like `from "std"`) · decision 78 (`parseActionState(envelope)`) · decision 114 item 7
(the wire names are onze's) · `contracts.md § 3` (the action id and the envelope) · rakun front
[24](../../03-rakun/24-rakun-server-actions/README.md) (*The result envelope*, Steps 5–6) · jhonstart
front [67](../../04-jhonstart/67-jhonstart-forms/README.md) (*The envelope, and who owns which half*,
Step 1)

---

## Problem

A server action crosses the stack twice. The browser sends a form body or a JSON-RPC body; the
server answers with a JSON envelope whose `state` field is itself a querystring with its own grammar
(`message`, `f.<name>`), and whose `n` field is the navigation signal's wire form. rakun writes every
one of those texts on erlang and jhonstart reads them in the browser (and writes the RPC body back).
Decision 113 forbids either framework to import the other, so the specs had settled for two
implementations and "the golden fixture, written here and asserted by a test on each side of the
boundary … rather than sharing a parser between two targets that cannot share code" (front 67). The
two targets *can* share code — `routing` does (decision 115) — and a literal pinned in two test files
catches a drift only after both sides have written it. Decision 116 gives the protocol a library
neutral like `routing`, bundled with the compiler, which both import by name.

It names no field and no header. The hidden field and the header that name an action are onze's
values (decision 114 item 7), passed to both sides as before; this library holds the texts whose
shape is fixed, not the names a deployment chooses.

## Current state

**Landed 2026-09-26** (Steps 1–7): `libs/actions/` — `state`, `envelope`, `rpc`, `refresh`, pure
`.bp`, importing std (`json`, `encoding`) and the bundled `routing` (`navigation`); 19 tests in four
`test/*_test.bp` files, 19 / 0 on erlang and on commonJS, format-clean, in `TREES`. JSON is written
with `json.quote` / `array` / `object` and read with `json.decode`; bundled after `routing` in
`build.zig`'s `bundled_packages`. Open: Step 8 — rakun 24 and jhonstart 67 are not written, so no
consumer imports it yet. The table below is the state this front started from.

Measured 2026-09-25 on `repository/botopink-lang` `52843fd5`, `repository/rakun` `a8ba8bd`,
`repository/jhonstart` `8e8dbe2`.

| Piece | State | Evidence |
|---|---|---|
| The envelope writer | specified, not written | rakun front 24 *The result envelope*; `modules/rakun/src/actions.bp` does not exist |
| The envelope reader and `ActionState` | specified, not written | jhonstart front 67 Step 1 (`form_state.bp`); no `form*.bp` under `modules/jhonstart/src/` |
| The `state` grammar | specified in front 67, encoded by 24, pinned by a literal in both | 67 *The envelope …* (`message`, `f.<name>`; the fixture `message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short`) |
| The JSON-RPC body | specified by 24 (reader), no writer anywhere | 24 *Two dispatch paths* and Step 6; no front says who writes it in the browser |
| The `refresh` header value | specified by 24, sent by 26 | 24 *`router.refresh()`*; jhonstart front 26 `refresh()` |
| JSON reading in botopink | none yet — `std/json` validates and re-stringifies; `json.decode` is `01-std-lib-enablement` Step 13 | `libs/std/src/json.bp:36` (`parse -> @Result<string, string>`), `:45` (`stringify`) |
| JSON writing | four private copies in rakun, none escaping every control character | `modules/rakun/src/ssr.bp:641-676` (`jsonString`, `jsonStrings`, `jsonPairs`, `jsonTriples`); std's replacement is `01-std-lib-enablement` Step 11 |
| Form encoding | escape-naive in std today | `libs/std/src/querystring.bp:35,48` (`parse`, `stringify` — no percent codec); `encoding` is `01-std-lib-enablement` Step 3 |
| The `n` codec | specified in rakun 63, moving to `routing` | `04-routing-lib` Step 7 |
| Bundled packages | `std`, and `routing` once `04-routing-lib` Step 2 lands | `04-routing-lib` *Mechanism* — the list is one constant in `build.zig` |

## Mechanism

**The four texts and their one reader-writer pair each:**

| Text | Written by | Read by | Module |
|---|---|---|---|
| `state` querystring | rakun 24 (from the action's result) | jhonstart 67 (`ActionState`) | `state` |
| the v1 envelope, JSON | rakun 24 | jhonstart 67 | `envelope` |
| the JSON-RPC body | jhonstart 67 (a scripted call from an event handler) | rakun 24 | `rpc` |
| the `refresh` header value | jhonstart 26 (`refresh()`) | rakun 24 | `refresh` |

```bp
// state
pub type ActionState(ok: bool, message: string, redirectTo: string,
                     fields: Array<#(string, string)>) {
    pub fn fieldError(self: Self, name: string) -> string    // "" when absent
    pub fn hasError(self: Self) -> bool
}
pub fn newActionState(message: string) -> ActionState
pub fn writeState(message: string, fields: Array<#(string, string)>) -> string
pub fn parseState(state: string) -> #(string, Array<#(string, string)>)   // (message, fields)

// envelope
pub type ActionEnvelope(ok: bool, state: string, revalidated: Array<string>,
                        n: string, payload: string)
pub fn writeEnvelope(e: ActionEnvelope) -> string          // JSON, `v` first, `redirect` from `n`
pub fn readEnvelope(json: string) -> @Result<ActionEnvelope, string>
pub fn parseActionState(envelope: string) -> ActionState    // decision 78's name, over the JSON

// rpc
pub type RpcCall(id: string, args: Array<string>)
pub fn writeRpcBody(call: RpcCall) -> string               // {"v":1,"id":…,"args":[…]}
pub fn parseRpcBody(body: string) -> @Result<RpcCall, string>

// refresh
pub fn refreshValue() -> string                             // "refresh"
```

**Writing JSON** is std's (`json.quote`, `json.array`, `json.object`, `01-std-lib-enablement`
Step 11), so the envelope escapes every control character. **Reading JSON** is std's too:
`readEnvelope` and `parseRpcBody` read the text with `json.decode` (`01-std-lib-enablement` Step 13,
decision 117 rule 7) and walk the `Json` it answers — the same botopink code on both targets, with
no per-target template. A missing key reads as its empty value and an unknown key is ignored; `v`
other than `1`, text that is not JSON, and a known key of the wrong JSON kind are an `Error` (decision
67 — a version the reader does not know is refused, not guessed).

`redirect` is derived from `n` inside `writeEnvelope` (`signalFromWire(n).location` for a redirect,
`""` otherwise) and is never a parameter, so the envelope cannot carry a `redirect` that disagrees
with its signal — `contracts.md § 3`'s rule, now enforced by the only writer.

**Where it sits:** `libs/actions/` beside `libs/routing/`, `"name": "actions"`, `"targets":
["erlang", "commonJS"]`, imports `std` and `routing` and nothing else. Consumers write
`import {envelope.writeEnvelope, state.writeState} from "actions";`. Module atoms follow decision
109: `actions@envelope`, `actions@envelope@@ActionEnvelope`.

```
libs/actions/
├── botopink.json     "name": "actions", "target": "erlang", "targets": ["erlang", "commonJS"],
│                     "src": "src/", "entry": "root.bp", "files": [the five modules]
├── AGENTS.md
├── src/root.bp       pub mod state; pub mod envelope; pub mod rpc; pub mod refresh;
├── src/state.bp      ActionState, newActionState, writeState, parseState
├── src/envelope.bp   ActionEnvelope, writeEnvelope, readEnvelope, parseActionState
├── src/rpc.bp        RpcCall, writeRpcBody, parseRpcBody
├── src/refresh.bp    refreshValue
└── test/             state_test.bp · envelope_test.bp · rpc_test.bp
```

## Steps

### Step 1 — Scaffold `libs/actions`

`botopink.json`, `AGENTS.md`, `src/root.bp` declaring the four modules, and the `actions` row of
`libs/AGENTS.md` (*Provides*: the server-action protocol; *Embedded in compiler?*: yes, from Step 6).

**Acceptance:**
- [x] `libs/actions/botopink.json` reads `"name": "actions"`, `"targets": ["erlang", "commonJS"]`
      with erlang first, and lists every `src/*.bp` in `files`
- [x] `grep -rn "rakun\|jhonstart\|onze\|emilia\|__bp_action\|X-Bp-Action" libs/actions/src` is
      empty — no library name and no wire name
- [x] no file under `libs/actions/` is a sidecar (`*.erl`, `*.mjs`), and no `src/*.bp` declares an
      `#[@External]` cell — the library reads and writes JSON through std (decision 117 rules 7
      and 8)

### Step 2 — `state`: the `state` grammar and `ActionState`

jhonstart front 67 Step 1's record and decoder, and the encoder rakun front 24 needed, in one file.
The grammar: `message` is the form-level message; `f.<name>` is one field's message; any other key
is ignored; values are percent-encoded with `encoding.formStringify`.

**Acceptance:**
- [x] `writeState("Title must be at least 3 characters", [#("title", "Too short")])` answers
      `message=Title%20must%20be%20at%20least%203%20characters&f.title=Too%20short` — the literal
      front 67 pinned, now asserted once, here, on both targets
- [x] `parseState` of that literal answers the same message and fields; `parseState("")` answers
      `#("", [])`
- [x] a key that is neither `message` nor `f.`-prefixed is ignored; a value containing `&`, `=`, `%`
      and a space round-trips — `a%26b%3Dc%25d%20e`
- [x] `fieldError` of an absent name is `""`; `newActionState("")` has `ok: true` and no fields

### Step 3 — `envelope`: the v1 envelope

```json
{"v":1,"ok":true,"state":"message=","revalidated":["/blog"],"redirect":"","n":"","payload":""}
```

**Acceptance:**
- [x] `writeEnvelope` answers the literal above for `ActionEnvelope(ok: true, state: "message=",
      revalidated: ["/blog"], n: "", payload: "")`, with `v` first and the keys in that order, on
      both targets
- [x] with `n: "R|307|/login"` the envelope carries `"redirect":"/login"`; with `n: "N"` it carries
      `"redirect":""` — `redirect` has no parameter of its own
- [x] a `state` or `payload` containing `"`, `\`, a newline and U+0001 produces JSON that std's
      `json.decode` accepts — the control-character case the private copies got wrong
- [x] `readEnvelope(writeEnvelope(e))` is `Ok(e)` field by field, for an `ok: false`
      envelope, one with each `n` form, and one whose `revalidated` holds three entries — seven envelopes, `R|307|/a|b` included; `readEnvelope` also refuses a `redirect` that disagrees with `n` (decision 67 — the only writer never produces one)
- [x] `readEnvelope` of `{"v":2,…}`, of text that is not JSON and of `{"v":1,"ok":"yes",…}` answer
      an `Error`
- [x] `parseActionState(writeEnvelope(e))` fills `ok` and `redirectTo` from the envelope's own keys,
      never from `state` — a `state` carrying an `ok` key is ignored

### Step 4 — `rpc`: the JSON-RPC body

**Acceptance:**
- [x] `writeRpcBody(RpcCall(id: "a_9f2c1b7e", args: ["x", "y"]))` answers
      `{"v":1,"id":"a_9f2c1b7e","args":["x","y"]}` on both targets
- [x] `parseRpcBody(writeRpcBody(c))` equals `c`, including an argument with `"` and a newline
- [x] `parseRpcBody` of `{"v":2,…}`, of a body without `id`, of `args` that is not an array of
      strings, and of text that is not JSON each answer an `Error` naming what was wrong — rakun
      front 24 turns it into a 400

### Step 5 — `refresh`

**Acceptance:**
- [ ] `refreshValue()` answers `refresh`; rakun 24's and jhonstart 26's tests import it rather than
      spelling it — **open:** `refreshValue()` answers `refresh` on both targets; rakun 24 and jhonstart 26 are not written yet, so nothing imports it

### Step 6 — Bundle it

`actions` joins the bundled-package list `04-routing-lib` Step 2 made (`std`, `routing`, `actions`,
`validation`); nothing else in the mechanism changes. Opens after `04-routing-lib` Step 2.

**Acceptance:**
- [x] a scratch project with no `dependencies` builds `import {envelope.writeEnvelope} from
      "actions";` on `--target erlang` and `--target commonJS`, and both print the Step 3 literal — both print the Step 3 literal (`$HOME/.cache/bp-01std/actions-probe`)
- [x] the erlang output names `actions@envelope`; the commonJS output requires `./actions/envelope.js`
- [x] a manifest listing `actions` in `dependencies` is refused with a located error — the same generic refusal the routing box measured
- [x] `grep -rn '"actions' modules/compiler-core/src` is empty; the compiler's `snapshots/codegen/**`
      are byte-identical

### Step 7 — Both targets, in the gate

**Acceptance:**
- [x] `botopink test --target erlang` and `--target commonJS` from `libs/actions/` are green, and
      `zig build test-libs` reads `actions · erlang: pass` and `actions · commonJS: pass` — 19 / 0 on each
- [x] every expected text in the tests is a literal
- [x] `libs/actions` is in `scripts/format-check.sh`'s `TREES`, green

### Step 8 — rakun and jhonstart import it

Each consumer switches in its own front; this front is not done until both have:

| Consumer | Front | What it imports |
|---|---|---|
| rakun action dispatcher | 24 | `envelope.writeEnvelope`, `state.writeState`, `rpc.parseRpcBody`, `refresh.refreshValue` |
| jhonstart forms | 67 | `state.ActionState`, `envelope.parseActionState`, `rpc.writeRpcBody` (the scripted call) |
| jhonstart router | 26 | `refresh.refreshValue` (`refresh()`) |

**Acceptance:**
- [x] `grep -rn "fn parseActionState\|fn writeEnvelope\|fn writeRpcBody\|fn parseRpcBody"
      --include=*.bp repository/` finds only `repository/botopink-lang/libs/actions/src/` — measured 2026-09-26 (rakun 24 and jhonstart 67 have not written their halves yet)
- [x] the fixture `message=Title%20must…&f.title=Too%20short` appears in no test under
      `repository/rakun/` or `repository/jhonstart/` — the literal lives once — measured 2026-09-26 (rakun 24 and jhonstart 67 have not written their halves yet)
- [x] no `botopink.json` under `repository/` lists `actions` in `dependencies` — measured 2026-09-26 (rakun 24 and jhonstart 67 have not written their halves yet)

## Test plan

`libs/actions/test/*.bp`, suite `actions:`, run by `botopink test --target erlang` and `--target
commonJS` from `libs/actions/` and by `zig build test-libs`. Deterministic — no clock, no network.
The tests assert the `state` grammar and its literal, the envelope literal and its key order,
`redirect` derived from `n`, the control-character case, the envelope round trip, the refusals of an
unknown `v` and of text that is not JSON, and the RPC body both ways. The bundling (Step 6) is tested
in the compiler's own suite beside `04-routing-lib`'s bundled-package test.

## Gate

- [x] `zig build test-libs` green — `actions` on both targets; `routing` and std unchanged — `zig build test-libs` 58 passed / 0 failed (19 restricted as pinned), emilia and erika included, run from an rsync copy of the worktree
- [ ] the Step 6 compiler test green from a cold cache; `snapshots/codegen/**` byte-identical — **open:** `zig build test` green warm, `snapshots/codegen/**` byte-identical; not re-run cold
- [x] `libs/AGENTS.md` and `libs/actions/AGENTS.md` describe the library in the same commit

## Blast radius

- **Compiler:** one more name in the bundled list; a program that does not import `actions` is
  byte-identical.
- **rakun:** front 24's envelope and RPC reading are imports, not code; `actions.bp` keeps the id,
  the checks, dispatch and revalidation.
- **jhonstart:** front 67's `form_state.bp` shrinks to the hooks' glue; `ActionState` is imported.
  `__jhFormSubmit` returns the response body as it arrived, and `parseActionState` reads it.
- **onze:** unchanged — it still passes the two wire names.

## Notes

- **Why a library of its own and not a `routing` module.** The maintainer chose `libs/actions`
  (decision 116 rule 2). Its consumers are a different pair of fronts (24 and 67, not 22 and 26), it
  depends on `routing` and not the reverse, and it changes when the action protocol changes.
- **Why the JSON readers are std's `json.decode`.** [decision 117](../../decisions-taken.md#117-navigation-signals-are-jhonstarts-end-to-end-pages-and-layouts-are-components-std-reads-json-bundled-libraries-are-bp-only) rules 7 and 8: a
  bundled library ships `.bp` files only and keeps target-native code to inline templates, and std's
  structured reader keeps member order and refuses a duplicate key identically on both targets,
  which `JSON.parse` and OTP's `json:decode` do not. If something this library needs cannot be
  expressed in `.bp` or an inline template, the front stops and raises it in
  `decisions-pending.md` rather than adding a sidecar.
