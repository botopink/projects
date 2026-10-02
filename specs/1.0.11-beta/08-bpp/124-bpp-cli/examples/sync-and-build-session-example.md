# Front 124 — bpp CLI · examples/sync-and-build-session-example.md

What the commands print. Each block is the expected transcript of a shell test under
`onze/modules/onze-cli/test/`; the text is the contract — a message that changes fails the test.

The config these sessions run against is [`onze-json-example.json`](./onze-json-example.json),
whose first seven keys exist today (`onze/src/config.bp:192-193`) and whose last five are this
front's.

Upstream: `astro-docs/05-develop-and-build.md` · `astro-docs/15-content-collections.md` ·
`astro-docs/22-server-islands.md` § Reutilizando a chave de criptografia.

## `onze sync` — content is checked before anything is compiled

```console
$ onze sync
content  blog      3 entries   .onze/content/blog.json
content  authors   2 entries   .onze/content/authors.json
schema   blog      .onze/content/blog.schema.json
schema   authors   .onze/content/authors.schema.json
$ echo $?
0
```

One violating file — a title left empty and a date that is not a date:

```console
$ onze sync
content/blog/broken.md: title: must have at least 1 character
content/blog/broken.md: pubDate: must be an ISO 8601 datetime
content/blog/orphan.md: author: no entry "nobody" in collection "authors"
onze sync: 3 problems in 2 files
$ echo $?
1
```

## `onze build` — sync, then the build that exists

```console
$ onze build
sync       2 collections, 5 entries
scan       src/app   9 routes (6 page.bpp, 1 page.md, 2 route.bp)
compile    erlang    ok
bundle     2 islands, 1 component script
styles     4 scoped sheets, 1.8 kB
prerender  7 routes  .onze/prerender/
$ ls .onze
content  prerender  server  static
```

A content problem stops it at the first line:

```console
$ onze build
content/blog/broken.md: title: must have at least 1 character
onze build: stopped at sync — nothing was compiled
$ echo $?
1
```

A redirect that shadows a page is refused, naming both:

```console
$ onze build
onze.json: redirects["/about"] and src/app/about/page.bpp both answer /about
$ echo $?
1
```

## `onze create-key` — one key for every instance

```console
$ onze create-key
ONZE_KEY=3q2+7wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
$ ONZE_KEY=3q2+7w… onze build
…
```

Without the variable the build generates a key and says where the consequence is:

```console
$ onze build
…
islands    key generated for this build — set ONZE_KEY to share it between instances
```

## `onze start` — the reference's `preview`

```console
$ onze start
onze  notes  http://localhost:3000
$ curl -sI localhost:3000/about/ | head -2
HTTP/1.1 308 Permanent Redirect
location: /about
```
