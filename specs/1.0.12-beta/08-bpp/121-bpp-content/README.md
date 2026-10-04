# Front 121 — bpp content: Markdown, frontmatter and collections

**Priority:** high — the track's largest code that exists in no form; content sites are the
reference's first use case. · **State:** not started · steps 1–2 ready to open
**Depends on:** open: [`08-f`](../README.md#08-f--where-markdown-and-yaml-live) (step 3,
frontmatter reader's home) · `03-bundled-libs/125-validation-zod` steps 0–2 (`Schema<T>`) for steps
4–5 — merged into botopink-lang `feat` (`libs/validation/src/schemas.bp`); `status.md` still lists
them pending · `118-bpp-components`, `117-bpp-routing` (`page.md`) for step 6 · `07-onze/53` for
step 7. **Steps 1–2 depend on nothing**, open with wave A.
**Owns:** new member `repository/onze/modules/onze-content/**` (`botopink.json`, `src/**`,
`test/**`, `AGENTS.md`) · its line in `onze/botopink.json`'s `workspaces` and `onze/modules.md` ·
`onze/examples/blog/content/**`, `src/lib/db.bp` (step 7, after `07-onze/53`)
**Does not touch:** `onze-cli` (`sync` is 124's), `onze-assets`, `libs/std` (`yaml` is
`02-std-and-packaging/97`'s — `08-f`), the compiler.

Reference: `astro-docs/14-markdown-content.md`, `15-content-collections.md`,
`10-layouts.md` § Layouts Markdown, `19-images.md` § Imagens em arquivos Markdown.

## Goal

New onze member: CommonMark + GFM to `Element`, frontmatter, collections checked by `Schema<T>` at
build, `.md` pages, RSS — and the blog reads Markdown.

## Problem

No Markdown in the six repos. The blog's posts are `.md` files that are not Markdown:

```
Hello, world                        ← line 1: the title
2026-01-10                          ← line 2: the date
The first post of the blog. …       ← the rest: the body, rendered as one <p>
```

read by `parsePost` (`onze/examples/blog/src/lib/db.bp:52-59`), splitting on newlines; a second
paragraph, link, heading or list is text. No frontmatter reader (the one YAML-subset parser is
rakun's config, `rakun/modules/rakun/src/config.bp:340`), no collection, schema, heading index, RSS.
remark/rehype plugins have no host here; a Markdown renderer is a library, not a compiler stage.

## What exists

| Need | Where |
|---|---|
| read, list and walk files | `io.fs.readText`, `walk`, `glob` — run time, both targets (`libs/std/src/io/fs.bp:32-122`) |
| an element tree | `Element`, `el`, `raw` (`jhonstart`) |
| escaping | `escape.html`, `escape.attribute` (`libs/std/src/escape.bp`) |
| code points, normalisation | `unicode.codepoints`, `normalize` (`libs/std/src/unicode.bp`) |
| a document to validate | `json.Json` (`libs/std/src/json.bp:113`) |
| a place to run at build | `onze build`, a botopink program walking the source tree and staging a package (`onze-cli/src/build.bp:105`) |

Missing: comptime has no filesystem (`language-gaps.md` lg2-o) — no compile-time `import.meta.glob`; content loads
in the build tool and at boot, never in the compiler.

## Mechanism

New member `onze-content`, four modules, no dependency on the rest of onze:

```
markdown.bp      text → MdNode tree → Element          (pure, both targets)
frontmatter.bp   "---\n…\n---\n" → Json + body         (pure, both targets)
collections.bp   Collection<T>, loaders, Entry<T>, getCollection / getEntry / render
feeds.bp         rssFeed(…) -> string
```

**Markdown.** CommonMark 0.31.2 blocks and inlines + GFM tables, strikethrough, task lists,
autolinks + footnotes. Tree `MdNode { Heading(depth, id, kids), Paragraph(kids), Code(lang, text),
List(ordered, tight, items), Link(href, title, kids), Image(src, alt, title), Html(text), … }`;
readers `toElement(doc)`, `toHtml(doc)`, `headings(doc) -> Array<Heading(depth, slug, text)>`.
Heading ids: GitHub's slug rule, unique per document. Smart punctuation on, off via a
`MarkdownOptions` field. Code block = `<pre><code class="language-x">`, no highlighting. Raw HTML
passes through `raw(…)` (author's own, like a template).

**Frontmatter.** YAML subset: block and flow maps/lists, plain, single- and double-quoted scalars,
`|` and `>` blocks, comments, `null` / `true` / `false`, integers, floats. Anchors, aliases, tags,
multi-document streams, other implicit typing: `Error` naming the line. Result is `Json`, decoded
by a `Schema<T>` with pathed violations.

**Collections.** A value declared in the app:

```bp
pub fn blog() -> Collection<BlogPost> {
    return defineCollection("blog", glob("content/blog", "**/*.md"), schemaOfBlogPost());
}
```

`Entry<T>(id, collection, data: T, body: string, filePath: string)`; id = path under the loader's
base, no extension, slugged; frontmatter `slug` overrides. `getCollection(c)`,
`getCollectionWhere(c, keep)`, `getEntry(c, id)`, `render(entry) -> Rendered(content: Element,
headings: Array<Heading>)`. The app lists collections in `pub fn collections() ->
Array<AnyCollection>` in `src/content.bp`, read by the build.

| When | Who | What |
|---|---|---|
| build | `onze sync`, run by `onze build` (124) | loads every collection, decodes every entry; **a violation fails the build** with file path and report; writes `<outDir>/content/<name>.json` and `<outDir>/content/<name>.schema.json` (`jsonSchemaOf<T>`) |
| run | `getCollection` | reads the build store; under `onze dev` loads from the files |

Cross-collection reference: a marker on a string field, `#[reference("authors")] author: string`;
`sync` checks every id exists after all collections load.

**Markdown page.** `app/about/page.md` is a page (117 step 1). Frontmatter may name a layout by
module path — `layout: "layouts.post"` (no `@/`, decision 218) — a component taking
`(frontmatter: Json, headings: Array<Heading>, children: Node)`; the scan stages a page module that
reads, renders, calls the layout. No `layout`: rendered inside the directory's layout chain.

## Open

### Step 1 — Markdown blocks

Thematic breaks, ATX and setext headings, indented and fenced code, HTML blocks, link reference
definitions, paragraphs, block quotes, list items and lists, with CommonMark's container rules.

- [ ] CommonMark 0.31.2 spec block-section examples as fixtures under `test/commonmark/` — one case
      each, `markdown` in, HTML out, both targets
- [ ] no example skipped: a failing one is a failing test with its number in its name

### Step 2 — Markdown inlines, GFM, heading ids

Code spans, emphasis/strong (delimiter-run algorithm), links and images (inline, reference,
autolink), raw HTML, hard/soft breaks, entities; tables, strikethrough, task lists, extended
autolinks, footnotes; ids; smart punctuation.

- [ ] every remaining CommonMark example; the GFM spec's extension examples
- [ ] `examples/markdown-example.bp` passes on both targets
- [ ] two same-text headings get `conclusion` and `conclusion-1`
- [ ] a 200 kB document renders within a budget step 2 measures and records (code-point walk; BEAM cost unknown)

### Step 3 — Frontmatter (waits on `08-f`)

- [ ] `test/frontmatter_test.bp`: the reference's five frontmatter blocks decode to the meant
      `Json`; an anchor, a tag, a second document each refused with the line
- [ ] no fence → empty object, whole text as body; unclosed fence → `Error`

### Step 4 — Collections

- [ ] `examples/content-collection-example.bp` passes on erlang
- [ ] a schema-violating entry fails `sync` with `<file>: <path>: <message>` per violation, and the build
- [ ] `file("data/dogs.json")` loads an array of objects by `id`; missing or repeated `id` refused
- [ ] a custom loader is `fn() -> @Task<@Result<Array<RawEntry>, string>>`
- [ ] the store is read at run time without touching content files

### Step 5 — References, the editor's schema, RSS

- [ ] `#[reference]` to a missing id fails `sync`, naming both entries
- [ ] `<name>.schema.json` validates the entries it came from (125's JSON Schema test tool)
- [ ] `examples/rss-endpoint-example.bp`: feed well-formed, every text node escaped

### Step 6 — Markdown pages and layouts; images

- [ ] `page.md` with and without `layout:`; the layout receives frontmatter and heading list
- [ ] `![alt](./cover.png)` beside the document becomes `onze-assets`' image element; `/public`
      paths and remote URLs left as written

### Step 7 — The blog reads Markdown

- [ ] `onze/examples/blog/content/posts/*.md` carry frontmatter; `lib/db.bp`'s `parsePost` deleted,
      pages read `getCollection(posts())`
- [ ] blog's existing tests green with a post holding a heading, a list and a link

### Step 8 — a role in the decorator, not in an export's name (decision 282)

- [ ] `pub fn collections()` found in `src/content.bp` by its name → each collection declared by a
      decorator (`#[collection(glob("content/blog", "**/*.md"))]`), gathered with
      `@TypeInfo.all(with: collection)`; the schema's own shape stays `nat-d`'s question

## Decisions

- `08-f` — where Markdown and YAML live: (b) recommended (Markdown in `onze-content`, YAML in
  std); until std's `yaml`, step 3 keeps its own copy. Step 3 (under (c), steps 1–2 too).

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `modules/onze-content`
- [ ] `zig build test-libs`: onze green, the new member's cells among them
- [ ] `onze/modules.md` and the workspace manifest updated in the same commit

## Blast radius

- **Ninth onze member.** `modules.md` gains a row, edges to `jhonstart` (`Element`) and
  `validation`; nothing imports it until step 7.
- **Build time.** `sync` reads and renders every entry inside `onze build`; step 4 measures the blog and a 1 000-entry fixture.
- **CommonMark fixtures ≈ 650 cells per target**, counted by the gate's cold budget; suite sized against it before landing.

## Notes

- **Not added.** remark/rehype plugins — one hook `MarkdownOptions.transform: fn(node: MdNode) ->
  MdNode`. MDX — 118's template is the form. Processor choice. Syntax highlighting. TOML (one
  format). Live collections — an ordinary `@Task` function.
- **`rawContent()`** = `entry.body`; **`compiledContent()`** = `toHtml(parse(entry.body))`;
  **`<Content />`** = `{rendered.content}`; **`getHeadings()`** = `rendered.headings`.
- **`import.meta.glob`** → `glob(base, pattern)`, a loader evaluated at build and boot, not an import.
