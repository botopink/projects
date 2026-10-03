# Front 121 — bpp content: Markdown, frontmatter and collections

**Priority:** high — it is the largest piece of code in the track that does not exist in any form,
and a content site is the reference's first use case. · **State:** not started · steps 1–2 ready
to open
**Depends on:** open: [`08-f`](../README.md#08-f--where-markdown-and-yaml-live) (step 3, the
frontmatter reader's home) · `03-bundled-libs/125-validation-zod` steps 0–2 (`Schema<T>`) for
steps 4–5 — merged into botopink-lang `feat` (`libs/validation/src/schemas.bp`); `status.md` still
lists them as pending · `118-bpp-components` and `117-bpp-routing` (`page.md`) for step 6 ·
`07-onze/53` for step 7. **Steps 1–2 depend on nothing** and open with wave A.
**Owns:** the new member `repository/onze/modules/onze-content/**` (`botopink.json`, `src/**`,
`test/**`, `AGENTS.md`) · its line in `onze/botopink.json`'s `workspaces` and in
`onze/modules.md` · `onze/examples/blog/content/**` and `src/lib/db.bp` (step 7, after
`07-onze/53`)
**Does not touch:** `onze-cli` (the `sync` command is 124's), `onze-assets`, `libs/std` (a `yaml`
module is `02-std-and-packaging/97`'s — see `08-f`), the compiler.

Reference: `astro-docs/14-markdown-content.md`, `15-content-collections.md`,
`10-layouts.md` § Layouts Markdown, `19-images.md` § Imagens em arquivos Markdown.

## Goal

A new onze member renders CommonMark + GFM to `Element`, reads frontmatter, loads collections
checked by a `Schema<T>` at build, serves `.md` pages and RSS — and the blog reads Markdown.

## Problem

There is no Markdown in the six repositories. The blog — the stack's proof app — keeps its posts
in `.md` files that are not Markdown:

```
Hello, world                        ← line 1: the title
2026-01-10                          ← line 2: the date
The first post of the blog. …       ← the rest: the body, rendered as one <p>
```

read by `parsePost` (`onze/examples/blog/src/lib/db.bp:52-59`), which splits on newlines. A
second paragraph, a link, a heading or a list in a post is text. There is no frontmatter reader
(the one YAML-subset parser is rakun's config reader, `rakun/modules/rakun/src/config.bp:340`), no
collection, no schema over content, no heading index, no RSS.

Two things the reference leans on have no place here: remark and rehype plugins are a JavaScript
ecosystem with no host on this stack, and a Markdown renderer is a library, not a compiler stage.

## What exists

No Markdown implementation in any repository. What a content layer stands on:

| Need | Where |
|---|---|
| read, list and walk files | `io.fs.readText`, `walk`, `glob` — run time, both targets (`libs/std/src/io/fs.bp:32-122`) |
| an element tree | `Element`, `el`, `raw` (`jhonstart`) |
| escaping | `escape.html`, `escape.attribute` (`libs/std/src/escape.bp`) |
| code points, normalisation | `unicode.codepoints`, `normalize` (`libs/std/src/unicode.bp`) |
| a document to validate | `json.Json` (`libs/std/src/json.bp:113`) |
| a place to run at build | `onze build` is a botopink program that walks the source tree and stages a package (`onze-cli/src/build.bp:105`) |

and what it cannot stand on: a comptime body has no filesystem (`language-gaps.md` lg2-o), so
`import.meta.glob`'s compile-time form has no spelling — content is loaded by the build tool and
at boot, never by the compiler.

## Mechanism

A new member, `onze-content`, with four modules and no dependency on the rest of onze:

```
markdown.bp      text → MdNode tree → Element          (pure, both targets)
frontmatter.bp   "---\n…\n---\n" → Json + body         (pure, both targets)
collections.bp   Collection<T>, loaders, Entry<T>, getCollection / getEntry / render
feeds.bp         rssFeed(…) -> string
```

**Markdown.** CommonMark 0.31.2 blocks and inlines, plus the four GFM extensions (tables,
strikethrough, task lists, autolinks) and footnotes. The parser answers a tree —
`MdNode { Heading(depth, id, kids), Paragraph(kids), Code(lang, text), List(ordered, tight, items),
Link(href, title, kids), Image(src, alt, title), Html(text), … }` — and three functions read it:
`toElement(doc)`, `toHtml(doc)` and `headings(doc) -> Array<Heading(depth, slug, text)>`. Heading
ids follow GitHub's slug rule and are unique within a document. Smart punctuation is on, as in the
reference, and off by a field of `MarkdownOptions`.

A code block is `<pre><code class="language-x">`; highlighting is not done. Raw HTML in a document
passes through `raw(…)` — a document is the author's own, like a template.

**Frontmatter.** A YAML subset, defined by what it refuses: block and flow maps and lists, plain,
single- and double-quoted scalars, `|` and `>` blocks, comments, `null` / `true` / `false`,
integers and floats. Anchors, aliases, tags, multi-document streams and implicit typing beyond
those five are an `Error` naming the line. The result is a `Json`, so a `Schema<T>` decodes it and
its violations carry paths like any other document.

**Collections.** A collection is a value, declared in the application:

```bp
pub fn blog() -> Collection<BlogPost> {
    return defineCollection("blog", glob("content/blog", "**/*.md"), schemaOfBlogPost());
}
```

`Entry<T>(id, collection, data: T, body: string, filePath: string)`. The id is the file's path
under the loader's base, without extension, slugged; a `slug` key in the frontmatter overrides it.
`getCollection(c)`, `getCollectionWhere(c, keep)`, `getEntry(c, id)`, and
`render(entry) -> Rendered(content: Element, headings: Array<Heading>)`. The application lists its
collections in one exported function, `pub fn collections() -> Array<AnyCollection>` in
`src/content.bp`, which is what the build reads.

Loading has two moments and one implementation:

| When | Who | What |
|---|---|---|
| build | `onze sync`, run by `onze build` (124) | loads every collection, decodes every entry; **a violation fails the build** with the file's path and the report; writes `<outDir>/content/<name>.json` and `<outDir>/content/<name>.schema.json` (`jsonSchemaOf<T>`) |
| run | `getCollection` | reads the store written at build; under `onze dev` it loads from the files |

A reference between collections is a marker on a string field — `#[reference("authors")] author:
string` — and `sync` checks that every id exists, after every collection has loaded.

**A Markdown page.** `app/about/page.md` is a page (117 step 1). Its frontmatter may name a
layout by module path — `layout: "layouts.post"` (no `@/`, decision 218) — a component taking
`(frontmatter: Json, headings: Array<Heading>, children: Node)`; the scan stages a page
module that reads the file, renders it and calls the layout. With no `layout`, the document is
rendered inside the directory's layout chain like any page.

## Open

### Step 1 — Markdown blocks

Thematic breaks, ATX and setext headings, indented and fenced code, HTML blocks, link reference
definitions, paragraphs, block quotes, list items and lists, with CommonMark's container rules.

- [ ] the block sections of the CommonMark 0.31.2 specification's examples, as fixtures under
      `test/commonmark/` — each example one case, `markdown` in, HTML out, both targets
- [ ] no example is skipped: one that does not pass is a failing test with its number in its name

### Step 2 — Markdown inlines, GFM, heading ids

Code spans, emphasis and strong emphasis (the delimiter-run algorithm), links and images (inline,
reference, autolink), raw HTML, hard and soft breaks, entities; tables, strikethrough, task lists,
extended autolinks, footnotes; ids; smart punctuation.

- [ ] every remaining CommonMark example; the GFM specification's extension examples
- [ ] `examples/markdown-example.bp` passes on both targets
- [ ] two headings with the same text get `conclusion` and `conclusion-1`
- [ ] a 200 kB document renders within a budget step 2 measures and writes down — the parser is
      a code-point walk, and its cost on the BEAM is not known

### Step 3 — Frontmatter (waits on `08-f`)

- [ ] `test/frontmatter_test.bp`: the reference's five frontmatter blocks decode to the `Json`
      they mean; an anchor, a tag and a second document are each refused with the line
- [ ] a file with no fence has an empty object and the whole text as body; a fence that is not
      closed is an `Error`

### Step 4 — Collections

- [ ] `examples/content-collection-example.bp` passes on erlang
- [ ] an entry that violates the schema fails `sync` with `<file>: <path>: <message>` per
      violation, and the build with it
- [ ] `file("data/dogs.json")` loads an array of objects by their `id`; a missing or repeated `id`
      is refused
- [ ] a custom loader is a function `fn() -> @Task<@Result<Array<RawEntry>, string>>`
- [ ] the store is read at run time without touching the content files

### Step 5 — References, the editor's schema, RSS

- [ ] a `#[reference]` to an id that does not exist fails `sync`, naming both entries
- [ ] `<name>.schema.json` validates the entries it was generated from (125's JSON Schema test
      tool)
- [ ] `examples/rss-endpoint-example.bp`: the feed is well-formed and every text node is escaped

### Step 6 — Markdown pages and layouts; images

- [ ] `page.md` with and without `layout:`; the layout receives the frontmatter and the heading
      list
- [ ] `![alt](./cover.png)` beside the document becomes `onze-assets`' image element; a `/public`
      path and a remote URL are left as written

### Step 7 — The blog reads Markdown

- [ ] `onze/examples/blog/content/posts/*.md` carry frontmatter; `lib/db.bp`'s `parsePost` is
      deleted and the pages read `getCollection(posts())`
- [ ] the blog's existing tests are green with a post that has a heading, a list and a link

## Decisions

- `08-f` — where Markdown and YAML live: (b) Markdown in `onze-content`, YAML in std recommended;
  until std's `yaml` lands, step 3 keeps its own copy. Step 3 (under (c), steps 1–2 too).

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/onze-content`
- [ ] `zig build test-libs`: onze green, the new member's cells among them
- [ ] `onze/modules.md` and the workspace manifest updated in the same commit

## Blast radius

- **A ninth member of onze.** `modules.md` gains a row and an edge to `jhonstart` (for `Element`)
  and to `validation`; nothing imports it until step 7.
- **Build time.** `sync` reads and renders every entry; it runs inside `onze build`. Step 4
  measures the blog and a 1 000-entry fixture.
- **The CommonMark fixtures are ~650 test cells per target.** The gate's cold budget counts
  them; the member's suite is sized against it before it lands.

## Notes

- **Not added.** Remark and rehype plugins — no plugin host; `MarkdownOptions.transform:
  fn(node: MdNode) -> MdNode` is the one hook. MDX — Markdown with components is a template, and
  118 is the form. A processor choice. Syntax highlighting. TOML frontmatter — one format. Live
  collections — a function that fetches at request time is an ordinary `@Task` function.
- **`rawContent()`** is `entry.body`; **`compiledContent()`** is `toHtml(parse(entry.body))`;
  **`<Content />`** is `{rendered.content}` in a template; **`getHeadings()`** is
  `rendered.headings`.
- **`import.meta.glob`.** `glob(base, pattern)` is a loader, evaluated at build and at boot, not
  an import.
