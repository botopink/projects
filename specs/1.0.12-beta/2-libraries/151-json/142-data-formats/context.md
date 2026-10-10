# Front 142 — data formats: `json`, `yaml` and `markdown`, one repository each (decision 396)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../../../1-botopink-lang/144-botopink-lang/README.md): s1 boxes 1, 2 → B-27; [151-json](../README.md): s1 box 3 → 151 s1; [152-yaml](../../152-yaml/README.md): s2 → 152 s1; [158-markdown](../../158-markdown/README.md): s3 → 158 s1. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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
