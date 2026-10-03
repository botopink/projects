# Deferred and out of scope — 1.0.12-beta

What the milestone does not cover, so the claim of Spring Boot 4, Next.js and Tailwind CSS parity is
checkable. Every row was found by reading the reference documentation end to end, and every
deferred row has one reason: **the mechanism it needs does not exist on this stack**, not that the
work is large.

The rule: Erlang/BEAM is the server, JavaScript the client. A JVM- or Node-specific feature with a
workable BEAM analogue is **specified**, not deferred — OTP releases for fat jars, hot code loading
for a DevTools restart, `:telemetry` and `observer` for JMX, supervised process pools for thread
pools and the Edge runtime, sagas and outboxes for JTA, ETS and Mnesia for an in-process Node cache.
Only where no analogue exists does a feature land here. Nothing is closed permanently unless the row
says so; each row names what would have to exist first, so a later milestone picks it up rather than
rediscovers it. No front of this milestone opens any of them.

## Deferred — Spring Boot 4

| Feature | Source | Why BEAM cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| GraalVM native image | `10-otimizacao-producao.md § GraalVM Native Images` | BEAM modules are bytecode inseparable from the VM; there is no whole-program native compiler (HiPE was removed in OTP 24). BEAM already starts in tens of milliseconds | A native BEAM AOT compiler; the nearest living work is AtomVM, for embedded targets with a different module set | AtomVM or a successor runs an OTP application unchanged, or a native path lands in OTP |
| Reflection / resource / proxy / serialization hints | `10 § Spring AOT Processing`, `§ Custom Hints` | They tell a native-image compiler what static analysis cannot see; there is no such compiler, and botopink resolves its bean graph at comptime | The row above | With native images, or never |
| AOT cache (JEP 483) and CDS | `10 § AOT Cache`, `§ CDS`; `08-container-images.md` | Both cache loaded JVM class metadata; BEAM has no class loader and no such per-start cost | Nothing — the cost does not exist | Never. The adjacent win, `-mode embedded` with a preloaded boot script, is front 81's |
| CRaC checkpoint and restore | `10 § Checkpoint e Restore (CRaC)` | Needs JVM and kernel support (CRIU plus a CRaC JDK); BEAM has no heap-image format, and per-process heaps, ports and sockets are not restorable as a unit | A VM image format for BEAM, which nobody is building | Only if OTP ships one. Redeploy without dropping traffic is served by release upgrades (front 81) |
| JNDI lookups | `05-data.md § JNDI DataSource`; `06-messaging.md`; `07-io.md` | A Jakarta EE naming service of an application server; on BEAM the equivalent — a supervised named process — is what the DI registry is | A Jakarta EE-style container, an explicit non-goal | Never; configuration-based resource definition supersedes it |
| Servlet API surface | `04-web.md § Container Servlet Embutido` | A JVM API contract, not a wire protocol; nothing on BEAM to be compatible with | Nothing; filters are front 07's chain | Never |
| Bytecode agents and instrumentation | `01 § Com Debug Remoto`; `10 § Tracing Agent` | Both attach to the JVM instrumentation interface; BEAM's tracing is different in shape | Nothing — `dbg`, `recon_trace` and `:telemetry`, folded into fronts 80 and 75 | Never as stated; the capability is covered |

## Deferred — Next.js

| Feature | Source | Why BEAM cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| Deploy to Vercel | `§ 24` | A hosting product with no BEAM target | A BEAM-capable PaaS integration; self-hosting is front 71 | Never, unless a provider ships OTP releases |
| `webpack(config, { isServer })` hook | `§ 28` | A plugin API for a bundler not used here; front 68 is a graph walk plus concatenation, with no loader or plugin model | A stable plugin contract for 68's bundler, wanted by an actual consumer | When an app in `examples/` needs a custom transform — none does |
| `turbopack` config / `--webpack` | `§ 2`, `§ 28`, `§ 29` | Configuration for two bundlers, neither of which exists here | As above | As above |
| `transpilePackages` | `§ 28` | Transpiles npm dependencies published as untranspiled ESM; botopink libraries compile from source | An npm-interop story for client-side botopink libraries | Only if npm interop becomes a goal |
| `serverExternalPackages` | `§ 28` | Keeps Node native modules out of the server bundle; the BEAM server has no npm graph | A Node-side server, which this architecture rejects | Never under this architecture |
| `reactCompiler: true` | `§ 28` | An auto-memoizing compiler pass; library fronts make no compiler changes, and `#[@External]` plus comptime cannot rewrite call sites | A language-gap row and a compiler milestone | 1.1.x, as a compiler front |
| CSS-in-JS runtime (styled-components) | `§ 15` | A JS-runtime style-injection library plus a Babel plugin, npm artefacts with no counterpart | An npm-interop story | Unlikely — `emilia` is the answer; only the server-insertion seam is ported (front 69) |
| SWR / React Query client cache | `§ 9` | Third-party npm libraries; no npm dependency path for the client half | Front 68 plus npm interop for client bundles | A small native client cache is the likelier path; no front opens it |
| `next telemetry` | `§ 29` | Vendor usage reporting to one company's endpoint | Nothing — a product decision | Never |
| `next upgrade` | `§ 29` | Rewrites `package.json` and runs codemods over an npm tree | Codemod support in `bpmp` over `botopink.json` | A `bpmp` feature, after lg2-v (`02-std-and-packaging`) |
| Partial Prerendering | absent from this doc revision | A prerendered shell whose Suspense holes resume in the same response; fronts 60 and 30 must exist and share a resume protocol | Fronts 60 and 30 landed and stable | A front in the milestone after both are green, not before |

## Deferred — Tailwind CSS

`emilia` **produces** CSS and never **consumes** it: a feature that reads a stylesheet the user wrote,
or scans source files for class strings, has no path in a comptime library whose token set is closed
and typed.

| Feature | Source | Why emilia cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| `@source` / `@source not` / source detection of class strings, dynamic class objects, template literals | `§ 3.8`, `§ 3.9`, `§ 20.6` | emilia scans nothing; there are no class strings, only typed tokens | A build-time source scanner and class extractor in the toolchain | When the toolchain has a build-graph file walker (`io.fs.walk` / `io.process` are the nearest precursor) |
| `@apply` inside a hand-written `.css` file | `§ 3.9`, `§ 20.5` | Needs parsing and rewriting CSS the user authored. Naming a reusable `Token[]` bundle is **not** deferred: front 59 | A comptime CSS parser and project-file reads during compilation | When a comptime filesystem and parser story exists; 59 covers the common case |
| `@layer` wrapping user-authored CSS | `§ 3.1`, `§ 3.7` | The same file-consumption problem; layering emilia's own output is front 56 | As above | As above |
| `@import "tailwindcss"` and partial imports | `§ 2.1`, `§ 20.1` | Imports real CSS files from an npm package; emilia has no CSS input path and no npm dependency | A comptime CSS import resolver | Only if interop with an existing Tailwind install becomes a goal |
| Reading a CSS-authored `@theme` block, and `--*: initial` against it | `§ 3.5`, `§ 20.2`, `§ 21.7` | The same; a theme defined in botopink is front 54 | A comptime CSS parser | With `@apply` above |
| Third-party Tailwind plugins (JS plugin API) | implied by `§ 2.5` | JS modules executed by Tailwind's build; emilia has no plugin host | A comptime plugin protocol — a language-design question | A milestone that defines comptime extension points |
| Editor tooling: class autocomplete, hover previews, sorting | upstream IntelliSense | Not authored in the library; the LSP would need to know the token enum | LSP work in `botopink-lang`, outside `repository/emilia` | A tooling milestone; the typed enum already gives autocomplete |
| JS dark-mode toggle | `§ 3.4` | Run-time browser code, not comptime CSS | Nothing in emilia; jhonstart / onze own it | Fronts 49 and 53 build the app shell |
| CDN / Play distribution | `§ 2.4` | A distribution concern with no authoring surface | — | Never, as a library feature |
| Cross-module class minification and dedup | implied by `§ 1` | emilia hashes per call site; cross-module dedup needs a whole-program pass | Build-level aggregation over all compiled modules | When `onze build` (front 50) defines a CSS emission stage |
| One static `.css` file per build | `§ 1`, `§ 2.3` | `flush()` is per render by contract; a static file needs a stage that runs once | The same `onze build` CSS stage | Front 50 or later |
| Tree-shaking unused theme values | `§ 3.5` | Needs the whole program's token usage | Whole-program aggregation | As above |
| `@custom-variant` bodies using `@slot` | `§ 20.3`, `§ 20.7` | `@slot` is CSS-in-CSS templating; a function over `Token[]` covers the intent, not the syntax | Nothing — recorded so that "no `@slot`" is a decision | Closed by front 59's function form |
| Arbitrary values validated against CSS grammar | `§ 3.1` | emilia splices any string and cannot tell a valid `calc()` from a typo | A comptime CSS value parser | Front 57 refuses `}` and `<`; full validation waits on a parser |
| `color-mix()` / P3 fallback chains | not in doc | A correct fallback cascade needs front 56's `@supports` hoisting (exists) plus an OKLCH→sRGB converter | An OKLCH→sRGB converter | When the converter exists; the single-value form is front 33's |
| Automatic vendor prefixing | implied by `§ 2.2` | Tailwind delegates it to PostCSS; emilia has no plugin pipeline | A PostCSS-style transform stage | Only if a browser-support matrix is declared; hand-written prefixes cover today's needs |

## Deferred — ecosystem

Rows from the package restructure itself. The mocking surface is not deferred: it is
`testing.mocks` (decisions 71, 106).

| Feature | Source | Why it is not re-homed | What would have to exist first | Revisit |
|---|---|---|---|---|
| The `Request` / `MockMvc` double as a *shared* helper across libraries | 1.0.9's language-gaps "Unowned surface" | Front 19's, rakun-only; jhonstart and onze tests reach the server through `onze-test`, which depends on `rakun-test` ([`02-packaging/README.md`](../1.0.10-beta/02-packaging/README.md)) | Nothing | Never as a shared helper |
| The Redis arm of `rakun-session`'s store suite against a real server | `rakun-session/test/store_test.bp` (its env-gated `RAKUN_TEST_REDIS_URL` cell is gone, decision gate-h) | A cell needing a service outside the process is not a gate cell, and no CI job provides Redis | `rakun-test`'s RESP2 double on a loopback port (`04-rakun/12` § the double, `19-rakun-test-utilities` step 1); the suite then runs its third arm against it | When `04-rakun/19` lands the double; the real-driver arm stays out unless a CI job provides the service (gate-h: no `--integration` flag without a job) |

## Out of scope

Not runtime or authoring features. Listed so the audit is closed rather than silent.

| Feature | Source | Why |
|---|---|---|
| Maven, Gradle, Ant/Ivy integration; the JVM/Gradle/Maven version matrix | Spring `02`, `11`, `01` | JVM build tooling; the equivalents are fronts 88 and 81, and the version requirement is an OTP minimum |
| Kotlin and Java source examples | Spring `01`–`03` | JVM language bindings; botopink is the only source language |
| JAX-RS / Jersey as an alternative web stack | Spring `04` | A second web framework behind the same server; one router is the design |
| `open-in-view` / session-per-request | Spring `05` | An artefact of JPA lazy-loading proxies; with explicit fetches nothing stays open |
| LiveReload | Spring `12` | Deprecated upstream in 4.1.0; browser reload is front 50's dev server |
| Upgrade guides, OpenRewrite recipes, Spring Boot Migrator, support-window policy | Spring `12` | Source-migration tooling and governance; `rakun` needs a deprecation policy, not a front |
| Pages Router: `pages/`, `_app`, `_document`, `getStaticProps`, `getServerSideProps`, `pages/api/*` | Next `§ 1`, `§ 3`, `§ 30` | The legacy router; the App Router is ported, and each legacy API has an App Router equivalent in a front |
| TypeScript setup, ESLint/Biome, `typescript.ignoreBuildErrors`, `eslint.ignoreDuringBuilds` | Next `§ 2`, `§ 28`, `§ 29` | Tooling for another language; the last two disable a correctness gate, which this project does not ship |
| Node version and OS matrix; prerequisites | Next `§ 1`, `§ 2` | An OTP requirement in front 49's README; the browser matrix carries over |
| Vite, PostCSS and Tailwind CLI installation; the 19 framework install guides | Tailwind `§ 2.1`–`§ 2.5` | Host toolchain setup |
| "Managing duplication" advice: loops, multi-cursor editing, components | Tailwind `§ 3.1` | Editing practice and host-language features botopink has |
| Documentation aids: summaries, "when to use what", recommended structure | all three | Reader guidance; the recommended structure shapes front 53's example app |
