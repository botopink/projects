# Front 124 — bpp CLI: what the build has to learn

**Priority:** high — last. It adds no feature of its own; it makes the other fronts' features part
of `onze build`. · **State:** not started · blocked by `08-h`
**Depends on:** open: [`08-h`](../README.md#08-h--the-config-file-and-the-commands) (the whole
front) and [`08-e2`](../README.md#08-e2--which-modes-the-islands-props-setting-may-name) (the
islands key, steps 1 and 3) · `07-onze/50-onze-cli` (it owns `onze-cli` and `onze-bundler`, and
`onze dev` is its open box) · `07-onze/71` (static export to disk, ONZ-71-7) · every front of this
track · 116 and `07-onze/53` (step 5). Written against decisions 202 and 224.
**Owns:** in `repository/onze/modules`: `onze-cli/src/{main.bp, build.bp}` — the commands and
build steps named below; new `onze-cli/src/{sync.bp, key.bp}`; `onze/src/config.bp` — every key
of § Mechanism's table but `site`, which 122 adds (decision 189);
`onze-bundler/src/` — new `component_script.bp`, `style_sheet.bp` · `onze/examples/scaffold/**` ·
`onze/docs.md` § Configuration, § CLI
**Does not touch:** `onze dev` (50's); `onze-release` (71's); `repository/botopink-lang/**`.

Reference: `astro-docs/03-install-and-setup.md`, `05-develop-and-build.md`,
`06-configuring-astro.md`, `23-client-side-scripts.md`, `11-styling.md` § Produção.

## Goal

`onze build` runs the other fronts' features: `onze sync` loads and checks content, `onze
create-key` serves the island key, the config keys reach the libraries as plain values, component
`<script>`s and scoped sheets are bundled, and `onze create --example bpp` scaffolds a `.bpp`
project that passes `07-onze/53`'s acceptance script.

## Problem

The reference's CLI is the framework's: `astro dev`, `astro build`, `astro preview`. The
counterpart here is not `botopink` — the compiler's CLI has no framework command
(`compiler-cli/src/main.zig:121-170`: `build check run test format new clean migrate`), and a dev
server there would have to know jhonstart and rakun, which is the leak the lib-agnostic rule
exists to stop. Nor is it a second config file beside `botopink.json` and `onze.json`.

The framework's CLI already exists and is a botopink program:

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

So this front is small: two commands, the config keys, and three build steps the other fronts
need.

## What exists

- `onze.json` keys: `name port basePath appDir publicDir outDir dev actionsBodyLimit
  allowedRedirects lang` (`onze/src/config.bp:192-193`); defaults port 3000, `appDir` `app`,
  `publicDir` `public`, `outDir` `.onze`, `lang` `en` (`:52-64`).
- `onze build` walks the source tree (`build.bp:105`), reads `globals.css` (`:112-114`), stages a
  generated package, and shells out to `botopink` and `erlc` (`:68`, `:222`).
- The bundler plans chunks (`onze-bundler/src/chunk.bp:85`), generates the entry (`entry.bp:310`)
  and refuses server-only imports in the client graph (`refusal.bp:55-138`); every island is in
  one `shared` chunk (`onze-cli/AGENTS.md:24-26`).
- `<Script>` has four strategies (`onze-bundler/src/script.bp:18-21`); a `<script>` element in a
  page is the `script` builder, emitted verbatim.
- `prerenderAll` and `staticExport` exist in rakun-app (`static_gen.bp:478`, `:620`) and are not
  called by the build — ONZ-50-7 and ONZ-71-7.

## Mechanism

**Config keys.** Each is read in `config.bp`, validated there, and handed to the library that
uses it as a plain value — no library reads `onze.json`.

| Key | Astro's | Goes to |
|---|---|---|
| `site` | `site` | jhonstart's `site()` (122), the RSS helper (121), `alternatesFor` |
| `trailingSlash`: `"always"` \| `"never"` \| `"ignore"` | `trailingSlash` | `routing/url_rules` `canonicalize` |
| `redirects`: `{ "/old": "/new" }` | `redirects` | the redirect table of `routing/url_rules` |
| `markdown`: `{ "smartPunctuation": bool }` | `markdown.*` | 121's `MarkdownOptions` |
| `islandKeyEnv`: the environment variable that holds the server-island key | `ASTRO_KEY` | 120's `seal` |

**This row contradicts decision 224** — flagged, not resolved here. 224 fixes the key in
`ONZE_KEY` (or one generated at build, `onze create-key`), with no configurable variable name,
and puts the island props mode in `onze.json` as `"islands": {"props": "sealed"}` (which modes it
may name is `08-e2`). Whether the table keeps `islandKeyEnv`, replaces it by `islands`, or both,
is the maintainer's; `examples/onze-json-example.json` still writes `"islandKeyEnv": "ONZE_KEY"`.

`base` is `basePath`; there is no `output` key and no `prerender` key — `#[page]` decides each
page's stage at comptime (decisions 186, 202); `image.domains` is `07-onze/51`'s.

**`onze sync`.** Loads the application's `collections()` (121), decodes every entry, checks
references, and writes `<outDir>/content/<name>.json` and `<name>.schema.json`. A violation prints
`<file>: <path>: <message>` and exits 1. `onze build` runs it first; `onze dev` runs it on a
content file's change (50's watcher).

**`onze create-key`.** Prints a fresh 256-bit key, base64, for `ONZE_KEY` (decision 224; the
`islandKeyEnv` row above names the variable otherwise). Without the variable, `onze build`
generates a key and writes it into the server bundle; with several instances behind one cache the
key must be the same on all of them, which is what the command is for.

**Component scripts.** A `<script>` in a template with no attribute but `src` is a module script:
the build collects it, bundles each distinct script once per page that renders its component, and
emits one `<script type="module">`. `<script is:inline>` and a `<script>` with any other attribute
are emitted where written, as today. The collected script is JavaScript — it is not compiled from
botopink; typed client code is an island (120).

**Styles at build.** The scoped sheets of 119 are gathered per route, their long scope ids
replaced by a counter in declaration order (the same in the markup the build prerenders), and
minified; a route's sheet under a threshold is inlined, otherwise linked.

## Open

### Step 1 — The config keys (the islands key waits on `08-e2` and the row above)

- [ ] the keys of § Mechanism read and validated; an unknown key still refused; `docs.md`'s table generated
      from the one source `--help` and `create` read (ONZ-50-DoD's "defaults table from one
      source")
- [ ] `trailingSlash: "always"` redirects `/about` to `/about/` with 308; `"never"` the reverse
- [ ] `redirects` to an absolute URL and to a path; a redirect whose source is also a page fails
      the build, naming both (the reference's rule 7, as a refusal)

### Step 2 — `onze sync`

- [ ] `examples/sync-and-build-session-example.md` — the session it shows is a `compiler-cli`-style
      shell test under `onze-cli/test/`
- [ ] `onze build` fails on a content violation before it compiles anything

### Step 3 — `onze create-key` and the key in the build

- [ ] two builds with the same `ONZE_KEY` unseal each other's island URLs; two builds without it
      do not

### Step 4 — Component scripts and the style sheet

- [ ] a component used three times on a page contributes its script once
- [ ] a route with no island and no component script loads no JavaScript at all — asserted on the
      prerendered file
- [ ] scoped ids are rewritten identically in the sheet and in the prerendered markup; the test
      fails if one side is left long

### Step 5 — The scaffold, and the second blog

- [ ] `onze create --example bpp` (50's `--example` tail) writes a project whose pages are `.bpp`
      and whose posts are a collection — `examples/scaffold/`: the manifest carries
      `"bpp": "jhonstart"` (116), and `app/` holds `layout.bpp`, `page.bpp` and `not-found.bpp`;
      `onze build && onze start` serves it
- [ ] `07-onze/53`'s acceptance script runs against it — the same routes, the same assertions, as
      against `examples/blog`

## Decisions

- `08-h` — the config file and the commands: (a) `onze.json` and `onze <command>` recommended.
  The whole front.
- `08-e2` — which modes `"islands": {"props": …}` may name. Steps 1 and 3.
- `islandKeyEnv` against decision 224 (§ Mechanism) — no id; the maintainer's to settle.

**Gate:** standard (fronts.md § Gate), plus:
- [ ] `botopink test` green on both targets in `onze-cli`, `onze-bundler`, `onze`
- [ ] `zig build test-libs`: onze green; `examples/blog` builds unchanged
- [ ] `onze/docs.md` § Configuration, § CLI

## Blast radius

- **`onze build` gains a first step that can fail** (`sync`). A project with no `content.bp`
  skips it.
- **The build output gains `content/`** beside `server/` and `prerender/`; `onze-release`'s
  tarball (71) must carry it — reported to 71, not edited here.
- **A page's JavaScript may shrink to nothing.** Today every page loads the shared entry; after
  step 4 a page with no island does not. `linkMount` and `formMount` are in that entry, so a page
  with a `Link` or an action form still gets it — step 4 lists which pages lose it.

## Notes

- **Not added.** `botopink dev` / `preview` / `new`-for-a-framework; `bpp.json`; port 4321 (onze's
  is 3000); `astro add`; the dev toolbar; adapters.
- **`onze dev`** is `07-onze/50`'s, by decision 50-b's restart loop; this front adds content files
  and `.bpp` files to what its watcher watches, in 50's file, after 50 lands.
