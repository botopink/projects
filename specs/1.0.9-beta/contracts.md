# Cross-front contracts — 1.0.9-beta

Ninety-three fronts stay coherent only where they agree on a format. This file is the list of those
agreements. Each one is owned by a single front, consumed by several, and checkable by a test that
asserts a literal — not by a paragraph asking everyone to be careful.

The rule for every contract here: **the same literal is asserted on both sides.** A contract that
only one side tests is a contract that drifts.

## 1 · Route table — owned by front 22

Line-oriented, not JSON, and deliberately so: `std/json` has no structured value and the parser has
to run on BEAM.

```
kind|pattern|slot|verb
```

`kind` is one of `L` layout · `T` template · `P` page · `D` default · `R` route handler ·
`S` loading · `E` error · `N` not-found. The pattern keeps the bracket spelling — `/blog/[slug]`,
`/shop/[...slug]`, `/docs/[[...slug]]` — and groups and slots never appear in it. `|` and newline
are illegal inside a segment name. Match precedence is static > dynamic > catch-all > optional
catch-all.

`parseTable`, `writeTable` and `matchPath` are **one botopink implementation compiled twice**. The
server matches with it; front 26's client router prefetches with it. Neither writes a second parser.

## 2 · Payload envelope — owned by front 23

One `<script id="__onze" type="application/json">`, placed last in `<body>`, before the bundle.

| Key | Meaning |
|---|---|
| `v` | 1 |
| `b` | build id |
| `p` | pathname |
| `r` | matched pattern |
| `m` | params, querystring-encoded |
| `q` | search params |
| `t` | the route-table blob |
| `i` | islands, `[id, component, props]` |
| `a` | actions, `[name, id]` |
| `s` | emilia class names already present in the server-emitted `<style>` |
| `h` | open streaming holes |
| `d` | dynamic flag |

Escaping inside that script: `<`, `>` and `&` become `<`, `>`, `&`, plus U+2028 and
U+2029. `</script` is therefore **unrepresentable by construction** rather than filtered.

Markers: an island is `<div data-onze-i="i0">`. A streaming hole is
`<div data-onze-h="h1">fallback</div>`, filled later by
`<template data-onze-f="h1">…</template><script>__onzeFill("h1")</script>`.

Consumed by fronts 26, 28, 29, 30, 68.

## 3 · Action id and envelope — owned by front 24

```
id = "a_" + crypto.hmacSha256(buildSecret, module + "." + name + ":" + buildId).slice(0, 24)
```

Computed only on the server, echoed by the client, never derived in the browser.

Form binding: `<form method="post" action="<pathname>" data-onze-a="<id>">` plus a hidden
`__onze_action` field. Scripted invocation: the same POST carrying `X-Onze-Action`, or a JSON-RPC
body `{"v":1,"id":…,"args":[…]}` — the same auth path, not a second door.

Response envelope:

```json
{"v":1,"ok":…,"state":"<querystring>","revalidated":[…],"redirect":"…","payload":"…"}
```

`state` is querystring-encoded rather than JSON because `std/json` has no walker.

**Front 24 admits no configuration key that weakens the CSRF `Origin`/`Host` check**, and asserts
the absence of one in a test. Nothing downstream may add one.

Consumed by fronts 67, 31, 68.

## 4 · Class-name scheme — owned by front 48

```
class = "e_" + djb2hex(tokensToCss(tokens))
```

Lowercase hex, seed 5381, multiplier 33, masked to 32 bits, folded over the composed rule body, with
`tokens` in author order. Nothing else enters the hash — no counter, no salt, no request id. With a
static class present, the attribute value is `<static> + " " + <emilia class>`.

This is emilia's existing scheme pinned as a contract rather than a new invention. Five clauses,
each of them a test:

1. A pure function of the token list.
2. **Token order is class identity**, so both halves must build the same list from one shared function.
3. ASCII-only rule bodies — the JS cell folds UTF-16 units and the erlang cell folds codepoints, and
   they diverge above U+10000. Front 48 gates payload leaves on this.
4. Merge order is static-first, one ASCII space, no sorting and no de-duplication, with one
   implementation (`mergeClass` in `emilia/src/attributes.bp`) and nowhere else.
5. Attribute array order is fixed, because `renderToString` writes attrs in array order.

**The shared fixture:** `emilia/test/integration_test.bp` asserts the class for a fixed token list as
a **literal hex string**, on both commonJS and erlang. Front 23's SSR test asserts the same literal
for the same list, and front 68's bundle test asserts the client produces it too. If the three ever
differ, hydration is broken and a test is red before a user sees it.

The `s` key in the payload envelope is what makes this checkable at runtime as well as at test time.

## 5 · Request context — owned by front 62

Consumed by fronts 23, 25, 12, 18, 60 and the auth pattern. Reading it outside a request is a hard
failure, not a silent default. *(Filled in when front 62 lands.)*

## 6 · Client bundle — owned by front 68

Consumed by fronts 26, 27, 29, 31, 67, and by front 50's `build`. *(Filled in when front 68 lands.)*
