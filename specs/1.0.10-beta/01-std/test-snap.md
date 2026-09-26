# std — the preventive snapshot-test map

The tests std records as snapshots, written in `.bp` with `@src()` and `\\` line-strings, and the
exact `.snap` each one produces. std has no `-test` submodule (`modules.md`), so the helpers here
are `snapshots.assert` and `snapshots.assertAs` called directly, and every test sits inline at the
foot of its own `.bp`. The path rule puts a snapshot beside the file that owns the test, so the
root modules record under `libs/std/src/__snapshots__/` and the harness's own tests under
`libs/std/src/testing/__snapshots__/`.

What is snapshotted and what is not: a snapshot is for a value whose exact text *is* the
contract — a failure message, a rendered path, an escaped string, a digest. A boolean outcome
(`isOk`, a round-trip) is an `asserts` call, not a snapshot. The map keeps the two apart so that
`__snapshots__/` holds evidence and not restatements of `true`.

## `src/testing/asserts.bp` — the messages, pinned

The failure message of every assertion is part of its contract (`asserts-api.md` § *Failure message
format*). Each is recorded once, so a message cannot drift without a `.new` appearing.

The error text is read with `asserts.errorText(r)` — a `pub fn errorText(r: @Result<void, string>)
-> string` this front adds to the module (`asserts-api.md` § *Utility*): a plain `case` over the
`Ok`/`Error` variants, returning a plain `string`, answering `""` for `Ok`. It is the same helper every
`-test` submodule uses to snapshot a failure message.

```bp
test "asserts: message ---- equals" {
    val r = equals("ana", "bob");
    try snapshots.assert(@src(), errorText(r));
}
```

→ `src/testing/__snapshots__/asserts/message_equals.snap`

```
botopink-snap 1
test: asserts: message ---- equals
subject: text

asserts.equals: values differ
```

One such test per function; the table is the full list.

| Test name | File | Body |
|---|---|---|
| `asserts: message ---- isTrue` | `asserts/message_istrue.snap` | `asserts.isTrue: condition was false` |
| `asserts: message ---- isFalse` | `asserts/message_isfalse.snap` | `asserts.isFalse: condition was true` |
| `asserts: message ---- equals` | `asserts/message_equals.snap` | `asserts.equals: values differ` |
| `asserts: message ---- notEquals` | `asserts/message_notequals.snap` | `asserts.notEquals: values match` |
| `asserts: message ---- approxEquals` | `asserts/message_approxequals.snap` | `asserts.approxEquals: values differ by more than tolerance` |
| `asserts: message ---- deepEquals` | `asserts/message_deepequals.snap` | `asserts.deepEquals: values differ structurally` |
| `asserts: message ---- isNil` | `asserts/message_isnil.snap` | `asserts.isNil: value was present` |
| `asserts: message ---- isNotNil` | `asserts/message_isnotnil.snap` | `asserts.isNotNil: value was null` |
| `asserts: message ---- isOk` | `asserts/message_isok.snap` | `asserts.isOk: result was Error` |
| `asserts: message ---- isError` | `asserts/message_iserror.snap` | `asserts.isError: result was Ok` |
| `asserts: message ---- contains` | `asserts/message_contains.snap` | `asserts.contains: needle not in actual` |
| `asserts: message ---- notContains` | `asserts/message_notcontains.snap` | `asserts.notContains: needle found in actual` |
| `asserts: message ---- startsWith` | `asserts/message_startswith.snap` | `asserts.startsWith: prefix does not match` |
| `asserts: message ---- endsWith` | `asserts/message_endswith.snap` | `asserts.endsWith: suffix does not match` |
| `asserts: message ---- matches` | `asserts/message_matches.snap` | `asserts.matches: pattern did not match` |
| `asserts: message ---- isEmpty` | `asserts/message_isempty.snap` | `asserts.isEmpty: array was not empty` |
| `asserts: message ---- isNotEmpty` | `asserts/message_isnotempty.snap` | `asserts.isNotEmpty: array was empty` |
| `asserts: message ---- lengthIs` | `asserts/message_lengthis.snap` | `asserts.lengthIs: length differs` |
| `asserts: message ---- includes` | `asserts/message_includes.snap` | `asserts.includes: element not found` |
| `asserts: message ---- notIncludes` | `asserts/message_notincludes.snap` | `asserts.notIncludes: element found` |
| `asserts: message ---- between` | `asserts/message_between.snap` | `asserts.between: value out of range` |
| `asserts: message ---- greaterThan` | `asserts/message_greaterthan.snap` | `asserts.greaterThan: value not greater` |
| `asserts: message ---- lessThan` | `asserts/message_lessthan.snap` | `asserts.lessThan: value not less` |
| `asserts: message ---- throws` | `asserts/message_throws.snap` | `asserts.throws: body did not raise` |
| `asserts: message ---- throwsWith no raise` | `asserts/message_throwswith_no_raise.snap` | `asserts.throwsWith: body did not raise` |
| `asserts: message ---- throwsWith wrong message` | `asserts/message_throwswith_wrong_message.snap` | `asserts.throwsWith: message does not contain needle` |
| `asserts: message ---- fail` | `asserts/message_fail.snap` | `asserts.fail: this branch is unreachable` |

Every `.snap` above has the header `test: asserts: message ---- <fn>` and `subject: text`; the
file name lowercases the fn (`slugify`), the header keeps the case.

## `src/testing/snapshots.bp` — the engine's own evidence

The engine tests itself against a scratch directory under the host tmpdir, by building a
`SourceLocation` by hand whose `file` points there, so the package tree is untouched and the three
outcomes can be produced deterministically. The path rule, which is pure, is recorded as ordinary
snapshots beside the file.

```bp
test "snapshots: path ---- suite and slug from a test name" {
    val loc = SourceLocation(file: "src/emilia.bp", line: 1, column: 1, fnName: "css: modifiers ---- hover on md breakpoint");
    try snapshots.assert(@src(), path(loc));
}
```

→ `src/testing/__snapshots__/snapshots/path_suite_and_slug_from_a_test_name.snap`

```
botopink-snap 1
test: snapshots: path ---- suite and slug from a test name
subject: text

src/__snapshots__/css/modifiers_hover_on_md_breakpoint.snap
```

```bp
test "snapshots: path ---- named second snapshot" {
    val loc = SourceLocation(file: "test/router_test.bp", line: 1, column: 1, fnName: "route: two tables");
    try snapshots.assert(@src(), pathNamed(loc, "After Merge"));
}
```

→ `src/testing/__snapshots__/snapshots/path_named_second_snapshot.snap`, body
`test/__snapshots__/route/two_tables.after_merge.snap`.

```bp
test "snapshots: slug ---- punctuation collapses to one underscore" {
    val text =
        \\Modifiers ---- Hover, on (md) breakpoint!
    ;
    try snapshots.assert(@src(), slugOf(text));
}
```

→ `src/testing/__snapshots__/snapshots/slug_punctuation_collapses_to_one_underscore.snap`, body
`modifiers_hover_on_md_breakpoint`.

```bp
test "snapshots: path ---- a name without a suite is refused" {
    val loc = SourceLocation(file: "src/a.bp", line: 1, column: 1, fnName: "no suite here");
    val r = assertAs(loc, "text", "x");
    try snapshots.assert(@src(), errorText(r));
}
```

→ `src/testing/__snapshots__/snapshots/path_a_name_without_a_suite_is_refused.snap`, body
`snapshots: test name needs a suite — write "<suite>: <description>"`.

The three filesystem outcomes, each an `asserts` test (no snapshot of a snapshot):

| Test | Sets up | Asserts |
|---|---|---|
| `snapshots: engine ---- missing writes a .new and answers Error` | a `SourceLocation` whose `file` is `<tmpdir>/<random>/t.bp`, nothing on disk | `isError(r)`; `exists(path + ".new")`; `isFalse(exists(path))`; the error text starts with `snapshots: missing ` |
| `snapshots: engine ---- mismatch writes a .new and answers Error` | the same, then a hand-written `<path>` with body `old` | `isError(r)` for `actual = "new"`; `.new` present and its body is `new`; the text contains `(first difference at body line 1)` |
| `snapshots: engine ---- match answers Ok and removes a stale .new` | `<path>` with the right header and body, plus a stale `<path>.new` | `isOk(r)`; `isFalse(exists(path + ".new"))` |
| `snapshots: engine ---- header must match too` | `<path>` with the right body and `subject: css` | `isError(assertAs(loc, "text", body))`; the text contains `(header differs)` |
| `snapshots: engine ---- CRLF in the recorded file still matches` | `<path>` written with `\r\n` line ends | `isOk(r)` |
| `snapshots: engine ---- not a snapshot file` | `<path>` whose first line is `hello` | `isError(r)`; the text starts with `snapshots: not a snapshot file` |
| `snapshots: engine ---- the header keeps the full test name` | a match, then read `<path>` back | `contains(text, "test: css: modifiers ---- hover on md breakpoint")` |

## `src/testing/mocks.bp` — the verify message

The one text the old library produced on failure is worth pinning, because it is the text a person
reads when a mock's count is wrong, and its two templates were "kept in step by hand"
(`onze/AGENTS.md`).

```bp
#[mocks.mock]
behavior Counter {
    fn tick(self: Self, n: i32) -> i32;
}

test "mocks: verify message ---- expected exactly one call" {
    val c = mockCounter();
    val _1 = c.tick(1);
    val _2 = c.tick(1);
    val msg = verifyMessage({ ->
        val _v = verify(c, times(1)).tick(eq(1));
        0;
    });
    try snapshots.assert(@src(), msg);
}
```

`verifyMessage` is a private test helper in `mocks.bp` over the same `tryCatch` shape `asserts`
keeps, answering the caught message or `""`. The Node and Erlang templates must produce the same
bytes, which is exactly what one snapshot recorded on both targets proves:

→ `src/testing/__snapshots__/mocks/verify_message_expected_exactly_one_call.snap`

```
botopink-snap 1
test: mocks: verify message ---- expected exactly one call
subject: text

onze.verify: tick - expected exactly 1 matching call(s), got 2
```

The body is the Erlang template's wording (`onze.bp:43`: `" - expected "`); the Node one says
`" — expected "` and appends `[recorded: …]` (`onze.mjs:83-88`). The lift makes the two identical —
the Erlang form, without the recorded-calls suffix — and the snapshot is what holds them there. The
prefix stays `onze.verify:` for one milestone so that a grep across old test output still finds it;
`mocks.verify:` is a follow-up rename this map will re-record.

## A handful of std modules

Pure, deterministic, cross-target values whose exact text is the point. Each is one snapshot; the
module's other tests stay `asserts` calls.

### `src/escape.bp` (01-std-lib-enablement step 1)

```bp
test "escape: html ---- ampersand is escaped once" {
    val raw =
        \\<a href="x">&
    ;
    try snapshots.assert(@src(), html(raw));
}
```

→ `src/__snapshots__/escape/html_ampersand_is_escaped_once.snap`, body
`&lt;a href="x"&gt;&amp;`.

```bp
test "escape: jsString ---- a script close tag cannot survive" {
    val raw =
        \\</script><script>alert(1)</script>
    ;
    try snapshots.assert(@src(), jsString(raw));
}
```

→ `src/__snapshots__/escape/jsstring_a_script_close_tag_cannot_survive.snap`, body
`\u003c/script>\u003cscript>alert(1)\u003c/script>`.

### `src/hash.bp` — the content-hash half (03-std-content-hash)

```bp
test "hash: etag ---- quoted djb2 of hello" {
    try snapshots.assert(@src(), etag("hello"));
}
```

→ `src/__snapshots__/hash/etag_quoted_djb2_of_hello.snap`, body `"f923099"` (with the
quotes — they are the value).

```bp
test "hash: cacheKey ---- framing keeps two part lists apart" {
    val a = cacheKey(["user:1", "profile"]);
    val b = cacheKey(["user", "1:profile"]);
    try snapshots.assert(@src(), a + "\n" + b);
}
```

→ `src/__snapshots__/hash/cachekey_framing_keeps_two_part_lists_apart.snap`

```
botopink-snap 1
test: hash: cacheKey ---- framing keeps two part lists apart
subject: text

62d9003d
8aac687d
```

(`62d9003d` = djb2 of `6:user:1|7:profile`, `8aac687d` = djb2 of `4:user|9:1:profile`; the two
lines differing is the front's reason to exist, and the snapshot pins the values on both targets.)

```bp
test "hash: fingerprint ---- extension stays last" {
    try snapshots.assert(@src(), fingerprint("app.js", "console.log(1)"));
}
```

→ `src/__snapshots__/hash/fingerprint_extension_stays_last.snap`, body `app.45ac5e8a.js`.

### `src/encoding.bp` (01-std-lib-enablement step 3)

```bp
test "encoding: percentEncode ---- reserved characters" {
    try snapshots.assert(@src(), percentEncode("a b&c=d"));
}
```

→ `src/__snapshots__/encoding/percentencode_reserved_characters.snap`, body `a%20b%26c%3Dd`.

### `src/hash.bp` — the hmac half (01-std-lib-enablement step 4)

```bp
test "hash: sha256Base64Url ---- of the empty string" {
    try snapshots.assert(@src(), sha256Base64Url(""));
}
```

→ `src/__snapshots__/hash/sha256base64url_of_the_empty_string.snap`, body
`47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU`.

### `src/path.bp`

```bp
test "path: normalize ---- dot and dotdot segments" {
    try snapshots.assert(@src(), normalize("/app/./blog/../page.bp"));
}
```

→ `src/__snapshots__/path/normalize_dot_and_dotdot_segments.snap`, body `/app/page.bp`.

## What is not snapshotted, and why

| Module | Not snapshotted | Because |
|---|---|---|
| `io/clock`, `io/random` | any value | wall clock and randomness — `asserts` on shape and ordering only (01 § *Test plan*) |
| `io/net`, `io/process`, `io/fs` | host output | a `.snap` of `ls /` is a `.snap` of the runner's machine |
| `async` | timings | elapsed-time budgets are `lessThan`, never a literal |
| `regex` captures | arrays | `deepEquals` against a literal array says the same thing without a file |

## Directory after this front

```
libs/std/src/testing/__snapshots__/
├── asserts/            27 files — the messages
├── snapshots/           4 files — the path rule
└── mocks/               1 file

libs/std/src/__snapshots__/
├── escape/              2 files
├── hash/                4 files — 3 content hashes, 1 hmac
├── encoding/            1 file
└── path/                1 file
```

Forty files, every one committed, none with a `.new` beside it on a green run. No `io/` module
records a snapshot, so there is no `src/io/__snapshots__/`.
