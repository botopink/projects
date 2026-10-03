# Deferred and out of scope — 1.0.12-beta

What the milestone does not cover, so Spring Boot 4 / Next.js / Tailwind CSS parity is checkable.
Every row found by reading the reference docs end to end; every deferred row has one reason: **the
mechanism it needs does not exist on this stack** (not size of work).

- Rule: Erlang/BEAM is the server, JavaScript the client. A JVM- or Node-specific feature with a
  workable BEAM analogue is **specified**, not deferred — OTP releases for fat jars, hot code loading
  for a DevTools restart, `:telemetry` and `observer` for JMX, supervised process pools for thread
  pools and the Edge runtime, sagas and outboxes for JTA, ETS and Mnesia for an in-process Node cache.
- Nothing closed permanently unless the row says so; each row names what must exist first, so a
  later milestone picks it up. No front of this milestone opens any of them.

## Deferred — Spring Boot 4

| Feature | Source | Why BEAM cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| GraalVM native image | `10-otimizacao-producao.md § GraalVM Native Images` | BEAM modules are bytecode inseparable from the VM; no whole-program native compiler (HiPE removed in OTP 24). BEAM already starts in tens of ms | A native BEAM AOT compiler; nearest living work AtomVM (embedded targets, different module set) | AtomVM or a successor runs an OTP application unchanged, or a native path lands in OTP |
| Reflection / resource / proxy / serialization hints | `10 § Spring AOT Processing`, `§ Custom Hints` | Tell a native-image compiler what static analysis cannot see; no such compiler; botopink resolves its bean graph at comptime | The row above | With native images, or never |
| AOT cache (JEP 483) and CDS | `10 § AOT Cache`, `§ CDS`; `08-container-images.md` | Both cache loaded JVM class metadata; BEAM has no class loader, no such per-start cost | Nothing — the cost does not exist | Never. Adjacent win, `-mode embedded` with a preloaded boot script, is front 81's |
| CRaC checkpoint and restore | `10 § Checkpoint e Restore (CRaC)` | Needs JVM + kernel support (CRIU plus a CRaC JDK); BEAM has no heap-image format; per-process heaps, ports, sockets not restorable as a unit | A VM image format for BEAM, which nobody is building | Only if OTP ships one. Redeploy without dropping traffic = release upgrades (front 81) |
| JNDI lookups | `05-data.md § JNDI DataSource`; `06-messaging.md`; `07-io.md` | A Jakarta EE app-server naming service; BEAM's equivalent (a supervised named process) is the DI registry | A Jakarta EE-style container, an explicit non-goal | Never; configuration-based resource definition supersedes it |
| Servlet API surface | `04-web.md § Container Servlet Embutido` | A JVM API contract, not a wire protocol; nothing on BEAM to be compatible with | Nothing; filters are front 07's chain | Never |
| Bytecode agents and instrumentation | `01 § Com Debug Remoto`; `10 § Tracing Agent` | Both attach to the JVM instrumentation interface; BEAM's tracing differs in shape | Nothing — `dbg`, `recon_trace`, `:telemetry`, folded into fronts 80 and 75 | Never as stated; capability covered |

## Deferred — Next.js

| Feature | Source | Why BEAM cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| Deploy to Vercel | `§ 24` | A hosting product with no BEAM target | A BEAM-capable PaaS integration; self-hosting is front 71 | Never, unless a provider ships OTP releases |
| `webpack(config, { isServer })` hook | `§ 28` | Plugin API for a bundler not used here; 68 is a graph walk + concatenation, no loader or plugin model | A stable plugin contract for 68's bundler, wanted by an actual consumer | When an app in `examples/` needs a custom transform — none does |
| `turbopack` config / `--webpack` | `§ 2`, `§ 28`, `§ 29` | Config for two bundlers, neither exists here | As above | As above |
| `transpilePackages` | `§ 28` | Transpiles npm deps published as untranspiled ESM; botopink libraries compile from source | An npm-interop story for client-side botopink libraries | Only if npm interop becomes a goal |
| `serverExternalPackages` | `§ 28` | Keeps Node native modules out of the server bundle; the BEAM server has no npm graph | A Node-side server, which this architecture rejects | Never under this architecture |
| `reactCompiler: true` | `§ 28` | Auto-memoizing compiler pass; library fronts make no compiler changes; `#[@External]` + comptime cannot rewrite call sites | A language-gap row and a compiler milestone | 1.1.x, as a compiler front |
| CSS-in-JS runtime (styled-components) | `§ 15` | JS-runtime style injection + a Babel plugin, npm artefacts with no counterpart | An npm-interop story | Unlikely — `emilia` is the answer; only the server-insertion seam is ported (front 69) |
| SWR / React Query client cache | `§ 9` | Third-party npm libraries; no npm dependency path for the client half | Front 68 plus npm interop for client bundles | A small native client cache is likelier; no front opens it |
| `next telemetry` | `§ 29` | Vendor usage reporting to one company's endpoint | Nothing — a product decision | Never |
| `next upgrade` | `§ 29` | Rewrites `package.json`, runs codemods over an npm tree | Codemod support in `bpmp` over `botopink.json` | A `bpmp` feature, after lg2-v (`02-std-and-packaging`) |
| Partial Prerendering | absent from this doc revision | Prerendered shell whose Suspense holes resume in the same response; 60 and 30 must exist and share a resume protocol | Fronts 60 and 30 landed and stable | A front in the milestone after both are green, not before |

## Deferred — Tailwind CSS

`emilia` **produces** CSS, never **consumes** it: reading a user-written stylesheet or scanning
source for class strings has no path in a comptime library with a closed, typed token set.

| Feature | Source | Why emilia cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| `@source` / `@source not` / source detection of class strings, dynamic class objects, template literals | `§ 3.8`, `§ 3.9`, `§ 20.6` | emilia scans nothing; no class strings, only typed tokens | A build-time source scanner and class extractor in the toolchain | When the toolchain has a build-graph file walker (`io.fs.walk` / `io.process` nearest precursor) |
| `@apply` inside a hand-written `.css` file | `§ 3.9`, `§ 20.5` | Needs parsing and rewriting user CSS. Naming a reusable `Token[]` bundle is **not** deferred: front 59 | A comptime CSS parser and project-file reads during compilation | When a comptime filesystem and parser story exists; 59 covers the common case |
| `@layer` wrapping user-authored CSS | `§ 3.1`, `§ 3.7` | Same file-consumption problem; layering emilia's own output is front 56 | As above | As above |
| `@import "tailwindcss"` and partial imports | `§ 2.1`, `§ 20.1` | Imports real CSS files from an npm package; emilia has no CSS input path, no npm dependency | A comptime CSS import resolver | Only if interop with an existing Tailwind install becomes a goal |
| Reading a CSS-authored `@theme` block, and `--*: initial` against it | `§ 3.5`, `§ 20.2`, `§ 21.7` | Same; a theme defined in botopink is front 54 | A comptime CSS parser | With `@apply` above |
| Third-party Tailwind plugins (JS plugin API) | implied by `§ 2.5` | JS modules executed by Tailwind's build; emilia has no plugin host | A comptime plugin protocol — a language-design question | A milestone defining comptime extension points |
| Editor tooling: class autocomplete, hover previews, sorting | upstream IntelliSense | Not authored in the library; the LSP would need the token enum | LSP work in `botopink-lang`, outside `repository/emilia` | A tooling milestone; the typed enum already gives autocomplete |
| JS dark-mode toggle | `§ 3.4` | Run-time browser code, not comptime CSS | Nothing in emilia; jhonstart / onze own it | Fronts 49 and 53 build the app shell |
| CDN / Play distribution | `§ 2.4` | Distribution concern, no authoring surface | — | Never, as a library feature |
| Cross-module class minification and dedup | implied by `§ 1` | emilia hashes per call site; cross-module dedup needs a whole-program pass | Build-level aggregation over all compiled modules | When `onze build` (front 50) defines a CSS emission stage |
| One static `.css` file per build | `§ 1`, `§ 2.3` | `flush()` is per render by contract; a static file needs a run-once stage | The same `onze build` CSS stage | Front 50 or later |
| Tree-shaking unused theme values | `§ 3.5` | Needs the whole program's token usage | Whole-program aggregation | As above |
| `@custom-variant` bodies using `@slot` | `§ 20.3`, `§ 20.7` | `@slot` is CSS-in-CSS templating; a function over `Token[]` covers the intent, not the syntax | Nothing — recorded so "no `@slot`" is a decision | Closed by front 59's function form |
| Arbitrary values validated against CSS grammar | `§ 3.1` | emilia splices any string, cannot tell a valid `calc()` from a typo | A comptime CSS value parser | Front 57 refuses `}` and `<`; full validation waits on a parser |
| `color-mix()` / P3 fallback chains | not in doc | Correct fallback cascade needs 56's `@supports` hoisting (exists) + an OKLCH→sRGB converter | An OKLCH→sRGB converter | When the converter exists; single-value form is front 33's |
| Automatic vendor prefixing | implied by `§ 2.2` | Tailwind delegates to PostCSS; emilia has no plugin pipeline | A PostCSS-style transform stage | Only if a browser-support matrix is declared; hand-written prefixes cover today |

## Deferred — ecosystem

Rows from the package restructure. The mocking surface is not deferred: `testing.mocks` (decisions
71, 106).

| Feature | Source | Why it is not re-homed | What would have to exist first | Revisit |
|---|---|---|---|---|
| The `Request` / `MockMvc` double as a *shared* helper across libraries | 1.0.9's language-gaps "Unowned surface" | Front 19's, rakun-only; jhonstart and onze tests reach the server via `onze-test`, which depends on `rakun-test` ([`02-packaging/README.md`](../1.0.10-beta/02-packaging/README.md)) | Nothing | Never as a shared helper |
| The Redis arm of `rakun-session`'s store suite against a real server | `rakun-session/test/store_test.bp` (its env-gated `RAKUN_TEST_REDIS_URL` cell is gone, decision gate-h) | A cell needing an out-of-process service is not a gate cell; no CI job provides Redis | `rakun-test`'s RESP2 double on a loopback port (`04-rakun/12` § the double, `19-rakun-test-utilities` step 1); the suite then runs its third arm against it | When `04-rakun/19` lands the double; real-driver arm stays out unless a CI job provides the service (gate-h: no `--integration` flag without a job) |
| A WebSocket broadcast across two BEAM nodes (`pg` over `erl` distribution) | `04-rakun/92-rakun-rsocket` step 1; `rakun-websocket/test/broadcast_test.bp` asserts the same-node broadcast only | Gate cells run on one node; `00-gate/99` removed the peer start; a cell that cannot run in the gate is not a gate cell (decision 160) | A CI job running two named nodes with a shared cookie | When such a job exists; until then the same-node `pg` cell is the evidence |

## Out of scope

Not runtime or authoring features; listed so the audit is closed, not silent.

| Feature | Source | Why |
|---|---|---|
| Maven, Gradle, Ant/Ivy integration; the JVM/Gradle/Maven version matrix | Spring `02`, `11`, `01` | JVM build tooling; equivalents are fronts 88 and 81; version requirement is an OTP minimum |
| Kotlin and Java source examples | Spring `01`–`03` | JVM language bindings; botopink is the only source language |
| JAX-RS / Jersey as an alternative web stack | Spring `04` | A second web framework behind the same server; one router is the design |
| `open-in-view` / session-per-request | Spring `05` | Artefact of JPA lazy-loading proxies; with explicit fetches nothing stays open |
| LiveReload | Spring `12` | Deprecated upstream in 4.1.0; browser reload is front 50's dev server |
| Upgrade guides, OpenRewrite recipes, Spring Boot Migrator, support-window policy | Spring `12` | Source-migration tooling and governance; `rakun` needs a deprecation policy, not a front |
| Pages Router: `pages/`, `_app`, `_document`, `getStaticProps`, `getServerSideProps`, `pages/api/*` | Next `§ 1`, `§ 3`, `§ 30` | The legacy router; the App Router is ported, each legacy API has an App Router equivalent in a front |
| TypeScript setup, ESLint/Biome, `typescript.ignoreBuildErrors`, `eslint.ignoreDuringBuilds` | Next `§ 2`, `§ 28`, `§ 29` | Tooling for another language; the last two disable a correctness gate, which this project does not ship |
| Node version and OS matrix; prerequisites | Next `§ 1`, `§ 2` | An OTP requirement in front 49's README; the browser matrix carries over |
| Vite, PostCSS and Tailwind CLI installation; the 19 framework install guides | Tailwind `§ 2.1`–`§ 2.5` | Host toolchain setup |
| "Managing duplication" advice: loops, multi-cursor editing, components | Tailwind `§ 3.1` | Editing practice and host-language features botopink has |
| Documentation aids: summaries, "when to use what", recommended structure | all three | Reader guidance; the recommended structure shapes front 53's example app |
