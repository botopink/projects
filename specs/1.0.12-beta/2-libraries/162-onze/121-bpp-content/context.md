# Front 121 — bpp content: Markdown, frontmatter and collections

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [162-onze](../README.md): s3 → 162 s6 · s4 → 162 s6 · s5 → 162 s6 · s6 → 162 s6 · s7 → 162 s6 · s8 → 162 s6 · s9 → 162 s6 · s10 → 162 s6 · gate → 162 s6. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — the track's largest code that exists in no form; content sites are the
reference's first use case. · **State:** steps 1–2 done (`onze-content`'s `markdown`) · steps 4–5 done
but for the boxes below (`collections`, `feeds`) · step 3 follows 396 (`yaml`, `03-bundled-libs/142` step 2); steps 1–2's reader moves to the `markdown` library (142 step 3)
**Depends on:** `03-bundled-libs/142` step 2 (step 3: the frontmatter reads through the `yaml` library, 396) · `03-bundled-libs/125-validation-zod` steps 0–2 for steps
4–5 (step 12 for step 10: the `#[validated]` type; `Schema<T>` is private, 306) — steps 0–2 merged into botopink-lang `feat` (`libs/validation/src/schemas.bp`); `status.md` still lists
them pending · `118-bpp-components`, `117-bpp-routing` (`page.md`) for step 6 · `07-onze/53` for
step 7. **Steps 1–2 depend on nothing**, open with wave A.
**Owns:** new member `repository/onze/modules/onze-content/**` (`botopink.json`, `src/**`,
`test/**`, `AGENTS.md`) · its line in `onze/botopink.json`'s `workspaces` and `onze/modules.md` ·
`onze/examples/blog/content/**`, `src/lib/db.bp` (step 7, after `07-onze/53`)
**Does not touch:** `onze-cli` (`sync` is 124's), `onze-assets`, `libs/std`, the `yaml` and
`markdown` libraries (`03-bundled-libs/142`, 396), the compiler.

Reference: `astro-docs/14-markdown-content.md`, `15-content-collections.md`,
`10-layouts.md` § Layouts Markdown, `19-images.md` § Imagens em arquivos Markdown.

## Goal

New onze member: CommonMark + GFM to `Element`, frontmatter, collections checked by their
`#[validated]` type at build (306), `.md` pages, RSS — and the blog reads Markdown.

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

Missing: comptime reads a named file only (`@embedFile`, decision 342) — no compile-time `import.meta.glob`; a
collection loads in the build tool and at boot, never in the compiler.

## Mechanism

New member `onze-content`, four public modules, no dependency on the rest of onze:

```
markdown.bp      text → MdNode tree → HTML / Element   (pure, both targets)
frontmatter.bp   "---\n…\n---\n" → Json + body         (pure, both targets)
collections.bp   Collection<T>, loaders, Entry<T>, getCollection / getEntry / render
feeds.bp         rssFeed(…) -> string
```

`markdown` keeps two private modules: `md_text` (code points with constant-time reads on both rows,
character classes, escaping, URL normalisation, character references) and `md_entities` (the HTML5
named references).

**Markdown.** CommonMark 0.31.2 blocks and inlines + GFM tables, strikethrough, task lists,
autolinks + footnotes + the tag filter. Tree `MdNode { Heading(depth, id, kids), Paragraph(kids),
Code(lang, text), List(ordered, start, tight, items), Item(task, kids), Link(href, title, kids),
Image(src, alt, title), Html(text), … }` in `MdDoc(nodes, footnotes)`; `parse(text)` /
`parseWith(text, MarkdownOptions(smartPunctuation, gfm, headingIds))`, all three on by default,
`commonmarkOptions()` CommonMark alone; readers `toElement(doc)`, `toHtml(doc)`,
`headings(doc) -> Array<Heading(depth, slug, text)>`.
Heading ids: GitHub's slug rule, unique per document. Smart punctuation on, off via a
`MarkdownOptions` field. Code block = `<pre><code class="language-x">`, no highlighting. Raw HTML
passes through `raw(…)` (author's own, like a template).

**Frontmatter.** YAML subset: block and flow maps/lists, plain, single- and double-quoted scalars,
`|` and `>` blocks, comments, `null` / `true` / `false`, integers, floats. Anchors, aliases, tags,
multi-document streams, other implicit typing: `Error` naming the line. Result is `Json`, decoded
by the collection's `#[validated]` type (its parse member `T.parse`, 306, 327) with pathed violations.

**Collections.** A value declared in the app:

```bp
pub fn blog() -> Collection<BlogPost> {
    return defineCollection("blog", glob("content/blog", "**/*.md"), schemaOfBlogPost());
}
```

Steps 8 and 10 replace this form (282, 306): the collection is said on its `#[validated]` type —
`#[validated] #[collection(glob("content/blog", "**/*.md"))] pub type BlogPost(…)`, or
`collection(BlogPost)` —, never with a `Schema<T>` value, and the build gathers collections with
`@TypeInfo.all(with: collection)` instead of reading `collections()` by name.

`Entry<T>(id, collection, data: T, body: string, filePath: string)`; id = path under the loader's
base, no extension, slugged; frontmatter `slug` overrides. `getCollection(c)`,
`getCollectionWhere(c, keep)`, `getEntry(c, id)`, `render(entry) -> Rendered(content: Element,
headings: Array<Heading>)`. The app lists collections in `pub fn collections() ->
Array<AnyCollection>` in `src/content.bp`, read by the build (until step 8, 282).

| When | Who | What |
|---|---|---|
| build | `onze sync`, run by `onze build` (124) | loads every collection, decodes every entry; **a violation fails the build** with file path and report; writes `<outDir>/content/<name>.json` and `<outDir>/content/<name>.schema.json` (the type's `jsonSchema` member, 306) |
| run | `getCollection` | reads the build store; under `onze dev` loads from the files |

Cross-collection reference: a marker on a string field, `#[reference("authors")] author: string`;
`sync` checks every id exists after all collections load.

**Markdown page.** `app/about/page.md` is a page (117 step 1). Frontmatter may name a layout by
module path — `layout: "layouts.post"` (no `@/`, decision 218) — a component taking
`(frontmatter: Json, headings: Array<Heading>, children: Node)`; the scan stages a page module that
reads, renders, calls the layout. No `layout`: rendered inside the directory's layout chain.

## Decisions

- `08-f` → 396: Markdown, YAML and JSON are libraries of their own (`03-bundled-libs/142`); step 3's
  frontmatter reads through `yaml`, and steps 1–2's reader moves to `markdown` (a tree of its own,
  onze-content mapping it to `Element`).

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
