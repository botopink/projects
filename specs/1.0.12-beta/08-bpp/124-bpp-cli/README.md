# Front 124 — bpp CLI: what the build has to learn

**Priority:** high — last; no feature of its own, makes the others part of `onze build`. ·
**State:** not started · blocked by `08-h`
**Depends on:** open: [`08-h`](../README.md#08-h--the-config-file-and-the-commands) (whole front) · `07-onze/50-onze-cli` (owns `onze-cli`, `onze-bundler`; `onze dev` its open box) ·
`07-onze/71` (static export to disk, ONZ-71-7) · every track front · 116 and `07-onze/53` (step 5).
Written against decisions 202, 224.
**Owns:** in `repository/onze/modules`: `onze-cli/src/{main.bp, build.bp}` (commands, build
steps below); new `onze-cli/src/{sync.bp, key.bp}`; `onze/src/config.bp` — every § Mechanism key
but `site` (122's, 189); `onze-bundler/src/` — new `component_script.bp`, `style_sheet.bp` ·
`onze/examples/scaffold/**` · `onze/docs.md` § Configuration, § CLI
**Does not touch:** `onze dev` (50's); `onze-release` (71's); `repository/botopink-lang/**`.

Reference: `astro-docs/03-install-and-setup.md`, `05-develop-and-build.md`,
`06-configuring-astro.md`, `23-client-side-scripts.md`, `11-styling.md` § Produção.

## Goal

`onze build` runs the other fronts' features: `onze sync` loads and checks content, `onze
create-key` serves the island key, config keys reach libraries as plain values, component
`<script>`s and scoped sheets are bundled, `onze create --example bpp` scaffolds a `.bpp` project
passing `07-onze/53`'s acceptance script.

## Problem

Not `botopink` — no framework command (`compiler-cli/src/main.zig:121-170`: `build check run test
format new clean migrate`), and a dev server there would know jhonstart and rakun (lib-agnostic
rule; 08-h). Not a second config file. The framework CLI exists, in botopink:

| Astro | onze | State |
|---|---|---|
| `create astro` | `onze create` | real (`onze-cli/src/main.bp:19-104`) |
| `astro dev` | `onze dev` | answers code 2, "not available yet" (`main.bp:101`) — `07-onze/50`, decision 50-b |
| `astro build` | `onze build` | real: scans, stages, compiles, bundles |
| `astro preview` | `onze start` | real: runs what `build` produced (50-a) |
| `astro check` | `botopink check` | real |
| `astro sync` | — | not found |
| `astro create-key` | — | not found |
| `astro add` | — | n/a — a dependency is a line of `botopink.json` |
| `astro.config.mjs` | `onze.json` | real; refuses an unknown key (49-c) |

Work: two commands, the config keys, three build steps.

## What exists

- `onze.json` keys `name port basePath appDir publicDir outDir dev actionsBodyLimit
  allowedRedirects lang` (`onze/src/config.bp:192-193`); defaults port 3000, `appDir` `app`,
  `publicDir` `public`, `outDir` `.onze`, `lang` `en` (`:52-64`).
- `onze build` walks the source tree (`build.bp:105`), reads `globals.css` (`:112-114`), stages a
  generated package, shells out to `botopink` and `erlc` (`:68`, `:222`).
- Bundler plans chunks (`onze-bundler/src/chunk.bp:85`), generates the entry (`entry.bp:310`),
  refuses server-only client imports (`refusal.bp:55-138`); all islands in one `shared` chunk
  (`onze-cli/AGENTS.md:24-26`).
- `<Script>` has four strategies (`onze-bundler/src/script.bp:18-21`); a page `<script>` is the
  `script` builder, verbatim.
- `prerenderAll`, `staticExport` in rakun-app (`static_gen.bp:478`, `:620`), not called by the
  build — ONZ-50-7, ONZ-71-7.

## Mechanism

**Config keys**: read and validated in `config.bp`, handed to the using library as plain values;
no library reads `onze.json`.

| Key | Astro's | Goes to |
|---|---|---|
| `site` | `site` | jhonstart's `site()` (122), the RSS helper (121), `alternatesFor` |
| `trailingSlash`: `"always"` \| `"never"` \| `"ignore"` | `trailingSlash` | `routing/url_rules` `canonicalize` |
| `redirects`: `{ "/old": "/new" }` | `redirects` | the redirect table of `routing/url_rules` |
| `markdown`: `{ "smartPunctuation": bool }` | `markdown.*` | 121's `MarkdownOptions` |
| `islands`: `{ "props": "sealed" }` — the server-island props mode (224; `"sealed"` default or `"server"`, decision 272) | `ASTRO_KEY` (here fixed: `ONZE_KEY`) | 120's `seal` |

The key is always the environment variable `ONZE_KEY` (decision 271): no key names it otherwise.

`base` is `basePath`; no `output`, no `prerender` key — `#[page]` decides each stage at comptime (186, 202); `image.domains` is `07-onze/51`'s.

**`onze sync`.** Loads `collections()` (121), decodes entries, checks references, writes
`<outDir>/content/<name>.json` and `<name>.schema.json`. Violation: prints `<file>: <path>:
<message>`, exits 1. Run first by `onze build`; by `onze dev` on a content change (50's watcher).

**`onze create-key`.** Prints a fresh 256-bit base64 key for `ONZE_KEY` (224, 271). Unset: `onze build` generates one into the server bundle; several
instances behind one cache need the same key — the command's purpose.

**Component scripts.** A template `<script>` with no attribute but `src` is a module script:
collected, each distinct one bundled once per page rendering its component, emitted as one
`<script type="module">`. `<script #[isInline]>` (Astro's `is:inline`, 278) or any other attribute: emitted in place. Collected
script is JavaScript, not compiled botopink; typed client code is an island (120).

**Styles at build.** 119's scoped sheets gathered per route, long scope ids → declaration-order
counter (same in prerendered markup), minified; under a threshold inlined, else linked.

## Open

### Step 1 — The config keys

- [ ] § Mechanism keys read and validated; unknown key still refused; `docs.md`'s table generated
      from the one source `--help` and `create` read (ONZ-50-DoD's "defaults table from one source")
- [ ] `trailingSlash: "always"` redirects `/about` to `/about/` with 308; `"never"` the reverse
- [ ] `redirects` to an absolute URL and to a path; a redirect whose source is also a page fails the
      build, naming both (the reference's rule 7, as a refusal)

### Step 2 — `onze sync`

- [ ] `examples/sync-and-build-session-example.md` — its session is a `compiler-cli`-style shell test under `onze-cli/test/`
- [ ] `onze build` fails on a content violation before compiling anything

### Step 3 — `onze create-key` and the key in the build

- [ ] two builds with the same `ONZE_KEY` unseal each other's island URLs; two without it do not

### Step 4 — Component scripts and the style sheet

- [ ] a component used three times on a page contributes its script once
- [ ] a route with no island and no component script loads no JavaScript — asserted on the prerendered file
- [ ] scoped ids rewritten identically in sheet and prerendered markup; test fails if one side stays long

### Step 5 — The scaffold, and the second blog

- [ ] `onze create --example bpp` (50's `--example` tail) writes a project with `.bpp` pages and a
      posts collection — `examples/scaffold/`: manifest carries `"bpp": "jhonstart"` (116), `app/`
      holds `layout.bpp`, `page.bpp`, `not-found.bpp`; `onze build && onze start` serves it
- [ ] `07-onze/53`'s acceptance script runs against it — same routes, same assertions as `examples/blog`

## Decisions

- `08-h` — config file and commands: (a) `onze.json` + `onze <command>` recommended. Whole front.

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `onze-cli`, `onze-bundler`, `onze`
- [ ] `zig build test-libs`: onze green; `examples/blog` builds unchanged
- [ ] `onze/docs.md` § Configuration, § CLI

## Blast radius

- **`onze build` gains a failable first step** (`sync`); skipped without `content.bp`.
- **Build output gains `content/`** beside `server/`, `prerender/`; `onze-release`'s tarball (71)
  must carry it — reported to 71, not edited here.
- **Page JavaScript may shrink to nothing**: after step 4 a page with no island skips the shared
  entry; `linkMount`, `formMount` live there, so `Link` / action-form pages still get it — step 4
  lists which pages lose it.

## Notes

- **Not added.** `botopink dev` / `preview` / framework `new`; `bpp.json`; port 4321 (onze's is
  3000); `astro add`; dev toolbar; adapters.
- **`onze dev`** is `07-onze/50`'s (50-b's restart loop); this front adds content and `.bpp` files
  to its watcher, in 50's file, after 50 lands.
