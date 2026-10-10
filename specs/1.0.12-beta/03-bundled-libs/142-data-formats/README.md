# Front 142 — data formats: `json`, `yaml` and `markdown`, one repository each (decision 396)

**Priority:** medium — `08-bpp/121` step 3 (frontmatter) waits on `yaml`; every other consumer works
today against std's `json` · **State:** step 0 done (the three repositories scaffolded, submodules); steps 1–3 open
**Depends on:** decision 396 · step 2's rakun commit: `04-rakun/128`
landed (rakun rows target post-128 paths, decision 339)
**Owns:** `repository/{json,yaml,markdown}/**` (new repositories, decision 326's rule), their
`.gitmodules` entries, `AGENTS.md` § Layout row and CI check 4's list in the commit that adds each ·
the removal of `libs/std/src/json.bp` and `pub mod json;` from std's `root.bp` (a carve-out of
`02/97`, named in the commit) · the consumers' `botopink.json` `dependencies` lines and import lines
(rakun, validation, onze, jhonstart, actions, log — one commit per library, 188) · rakun's
`config.bp` YAML subset (deleted, step 2) · onze-content's Markdown reader (moved, step 3) and its
tree-to-`Element` mapping
**Does not touch:** the consumers' code beyond the import and the dependency (the API moves byte for
byte, `json.parse` stays `json.parse`) · onze-content's collections and feeds (121) · the compiler
(its JSON is Zig's `std.json`, unrelated)

## Goal

Decision 396: std knows nothing of JSON; three data-format libraries — `json` (the `Json` value
type and its codec), `yaml` (one YAML subset into `Json`), `markdown` (a tree of its own) — each a
repository of its own, every consumer declaring the dependency (242).

```bp
import {json, json.Json} from "json";
import {yaml} from "yaml";
import {markdown} from "markdown";

val config: Json = yaml.parse(text)?;               // the YAML subset, into json's Json
val post = BlogPost.parse(config)?;                 // #[validated] (306) reads Json as before
val doc = markdown.parse(body);                     // Heading, Paragraph, Link, … — no Element
```

## Open

### Step 0 — the three repositories

- [x] `botopink/json`, `botopink/yaml`, `botopink/markdown` scaffolded on `feat`, its default branch (the shared hooks
      byte-identical, `.gitignore` naming `*.snap.new` / `*.snap.md.new`, `AGENTS.md` naming
      `core.hooksPath`), each a submodule with its `.gitmodules` entry, `AGENTS.md` § Layout row and CI
      check 4's list in the commit that adds it (CI checks 1, 2, 4)

### Step 1 — `json` leaves std

- [ ] `libs/std/src/json.bp` moves whole to `repository/json` (history kept as 138 did): the `Json` type
      and its methods, `parse`, `decode`, `stringify`, `quote`, `unquote`, `array`, `object`, the host
      cells and their tests; std's `root.bp` loses `pub mod json;`; `grep -rn "json" libs/std/src` names
      no module (comments aside)
- [ ] `import {json} from "std"` is an unknown-module error naming the `json` library
- [ ] the consumers declare `{ "json": { "git": "https://github.com/botopink/json.git", "branch": "feat" } }`
      and import `from "json"`, one commit per library (188): validation, actions, log, jhonstart, onze,
      rakun (after `04-rakun/128`); each library's suite green unchanged

### Step 2 — `yaml`

- [ ] `repository/yaml` reads one YAML subset into `json`'s `Json`: block and flow mappings and
      sequences, plain / quoted / block scalars, comments; an anchor, an alias, a tag and a second
      document each `Error` naming the line (67), never read as something else
- [ ] rakun's `config.bp` reads `.yaml` / `.yml` through it and deletes its own subset (after
      `04-rakun/128`); its config tests unchanged
- [ ] `08-bpp/121` step 3's frontmatter reads through it (no copy in onze-content)

### Step 3 — `markdown`

- [ ] onze-content's Markdown reader moves to `repository/markdown`, answering a tree of its own
      (`Heading`, `Paragraph`, `Emphasis`, `Strong`, `Code`, `CodeBlock`, `Link`, `Image`, `List`,
      `Quote`, …); it names no framework (113)
- [ ] onze-content maps the tree to jhonstart's `Element` (a node rendered by a component of the page's
      own where the page asks); onze-content's 714 tests green on both rows
- [ ] `markdown`'s one consumer is the maintainer's exception to 115, stated in its `AGENTS.md` (396 (4))

**Gate:** standard (fronts.md § Gate) + every consumer's suite green on both rows after its import
commit · `grep -rn "pub mod json" repository/botopink-lang/libs/std/src/root.bp` empty
