# Deferred and out of scope — 1.0.10-beta

The fronts a row cites are under `03-rakun/`, `04-jhonstart/`, `05-emilia/`, `06-onze/` (map in
[`unification.md`](./unification.md)).

A milestone that claims to cover three frameworks has to say what it does not cover, or the claim
cannot be checked. This file is that list. Every row here was found by reading the reference
documentation end to end, and every row was deferred for the same reason: **the mechanism it needs
does not exist on this stack**, not that the work is large.

The rule that produced this file: Erlang/BEAM is the server, JavaScript is the client. A feature
that is JVM-specific or Node-specific and has a workable BEAM analogue was **specified**, not
deferred — OTP releases in place of fat jars, hot code loading in place of a DevTools restart,
`:telemetry` and `observer` in place of JMX, supervised process pools in place of thread pools,
sagas and outboxes in place of JTA, ETS and Mnesia in place of an in-process Node cache, a
supervised process pool in place of the Edge runtime. Only where no such analogue exists does a
feature land here.

Nothing in this file is closed permanently unless the row says so. Each names what would have to
exist first, so that a later milestone can pick it up rather than rediscover it.

## Deferred — Spring Boot 4

| Feature | Source | Why BEAM cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| GraalVM native image | `10-otimizacao-producao.md § GraalVM Native Images` | BEAM modules are compiled bytecode inseparable from the VM that runs them; there is no whole-program native compiler, and HiPE was removed in OTP 24. The startup and footprint wins are largely absent anyway — BEAM already starts in tens of milliseconds. | A native BEAM AOT compiler. The nearest living work is AtomVM, for embedded targets with a different module set. | AtomVM or a successor runs an OTP application unchanged, or a native path lands in OTP |
| Reflection / resource / proxy / serialization hints | `10 § Spring AOT Processing`, `§ Custom Hints` | These exist only to tell a native-image compiler what static analysis cannot see. There is no such compiler here, and botopink resolves its bean graph at comptime, so the problem does not arise. | The row above | Arrives with native images, or never |
| AOT cache (JEP 483) and CDS | `10 § AOT Cache`, `§ CDS`; `08-container-images.md` | Both cache loaded JVM class metadata. BEAM has no class loader and no equivalent per-start cost to amortize. | Nothing — the cost being optimized does not exist | Never. The adjacent win, `-mode embedded` with a preloaded boot script, is already inside front 81 |
| CRaC checkpoint and restore | `10 § Checkpoint e Restore (CRaC)` | Snapshotting a process heap needs JVM and kernel support (CRIU plus a CRaC-enabled JDK). BEAM has no heap-image format, and per-process heaps plus ports and sockets are not restorable as a unit. | A VM image format for BEAM, which nobody is building | Only if OTP ships one. The *operational goal* — redeploy without dropping traffic — is served today by release upgrades in front 81, which is why this is deferred rather than designed around |
| JNDI lookups | `05-data.md § JNDI DataSource`; `06-messaging.md`; `07-io.md` | JNDI is a Jakarta EE naming service provided by an application server. BEAM has no container to look resources up from, and the equivalent — a supervised named process — is what the DI registry already is. | A Jakarta EE-style container, an explicit non-goal | Never; configuration-based resource definition supersedes it |
| Servlet API surface | `04-web.md § Container Servlet Embutido` | The Servlet specification is a JVM API contract, not a wire protocol. There is nothing on BEAM to be compatible *with*. | Nothing. The behaviour that matters — filters — is front 07's chain | Never |
| Bytecode agents and instrumentation | `01 § Com Debug Remoto`; `10 § Tracing Agent` | Both attach to the JVM instrumentation interface. BEAM's tracing is richer but entirely different in shape, and no JVM agent runs here. | Nothing — `dbg`, `recon_trace` and `:telemetry` are the replacement, already folded into fronts 80 and 75 | Never as stated; the capability is covered elsewhere |

## Deferred — Next.js

| Feature | Source | Why BEAM cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| Deploy to Vercel | `§ 24` | A hosting product, not a runtime capability; there is no BEAM target on it | A BEAM-capable PaaS integration, or nothing — self-hosting is front 71 | Never, unless a provider ships OTP releases |
| `webpack(config, { isServer })` hook | `§ 28` | A plugin API for a JavaScript bundler this milestone does not use; front 68 is a graph walk plus concatenation, with no loader or plugin model | A stable plugin contract for front 68's bundler, wanted by an actual consumer | 1.0.11+, only if apps need custom transforms |
| `turbopack` config / `--webpack` | `§ 2`, `§ 28`, `§ 29` | Configuration for two bundlers, neither of which exists here | As above | As above |
| `transpilePackages` | `§ 28` | Transpiles npm dependencies published as untranspiled ESM; botopink libraries are compiled from source already | An npm-interop story for client-side botopink libraries | 1.0.11+ if npm interop becomes a goal |
| `serverExternalPackages` | `§ 28` | Marks Node native modules to keep out of the server bundle. The BEAM server has no npm graph to exclude from. | A Node-side server, which this architecture rejects | Never under this architecture |
| `reactCompiler: true` | `§ 28` | An auto-memoizing compiler pass. This milestone forbids compiler changes, and `#[@external]` plus comptime cannot rewrite call sites. | A language-gap spec and a compiler milestone | 1.1.x, as a compiler front — not a library front |
| CSS-in-JS runtime (styled-components) | `§ 15` | A JS-runtime style-injection library plus a Babel plugin; both are npm artefacts with no botopink counterpart | An npm-interop story | Unlikely — `emilia` is the answer. Only the server-insertion seam is ported, as front 69 |
| SWR / React Query client cache | `§ 9` | Third-party npm libraries; nothing here provides an npm dependency path for the client half | Front 68 plus npm interop for client bundles | 1.0.11+, or replaced by a small native client cache |
| `next telemetry` | `§ 29` | Vendor usage reporting to one company's endpoint | Nothing — a product decision, not a technical one | Never |
| `next upgrade` | `§ 29` | Rewrites `package.json` and runs codemods over an npm dependency tree | Codemod support in `bpmp` over `botopink.json` | 1.0.11+, as a `bpmp` feature |
| Partial Prerendering | absent from this doc revision | Needs a prerendered shell whose Suspense holes resume in the same response; fronts 60 and 30 must both exist and share a resume protocol first | Fronts 60 and 30 landed and stable | **Still deferred in 1.0.10-beta** — 60 and 30 are open here; it gets a front in the milestone after both are green, not before |

## Deferred — Tailwind CSS

Every row here has the same shape: `emilia` **produces** CSS and never **consumes** it. Features that
require reading a stylesheet the user wrote, or scanning source files for class strings, have no
path in a comptime library whose token set is closed and typed.

| Feature | Source | Why emilia cannot carry it | What would have to exist first | Revisit |
|---|---|---|---|---|
| `@source` / `@source not` / source detection of class strings, dynamic class objects, template literals | `§ 3.8`, `§ 3.9`, `§ 20.6` | emilia scans nothing. There are no class strings to detect, only typed tokens — the problem the scanner solves does not arise | A build-time source scanner and class extractor in the toolchain | When the toolchain has a build-graph file walker; front 01's `io.fs.walk` / `io.process` work is the nearest precursor |
| `@apply` inside a hand-written `.css` file | `§ 3.9`, `§ 20.5` | Requires parsing and rewriting CSS the user authored. The composition half — naming a reusable `Token[]` bundle — is **not** deferred; it is front 59 | A comptime CSS parser and project-file reads during compilation | When a comptime filesystem and parser story exists; front 59 covers the common case meanwhile |
| `@layer` wrapping user-authored CSS | `§ 3.1`, `§ 3.7` | Same file-consumption problem. Emitting emilia's *own* output into layers is front 56 | As above | As above |
| `@import "tailwindcss"` and partial imports | `§ 2.1`, `§ 20.1` | These import real CSS files from an npm package; emilia has no CSS input path and no npm dependency | A CSS import resolver at comptime | Only if interop with an existing Tailwind install becomes a goal; parity does not need it |
| Reading a CSS-authored `@theme` block, and `--*: initial` against it | `§ 3.5`, `§ 20.2`, `§ 21.7` | Same. Defining a theme *in botopink* is front 54 | A comptime CSS parser | With `@apply` above |
| Third-party Tailwind plugins (JS plugin API) | implied by `§ 2.5` | Plugins are JS modules executed by Tailwind's own build; emilia has no plugin host | A comptime plugin protocol — a language-design question, not a library one | A milestone that defines comptime extension points generally |
| Editor tooling: class autocomplete, hover previews, sorting | upstream IntelliSense | Not authored in the library; the LSP would need to know the token enum | LSP work in `botopink-lang`, outside `repository/emilia` | A tooling milestone — note the typed enum already gives autocomplete for free, so the need is much smaller |
| JS dark-mode toggle | `§ 3.4` | Runtime browser code, not comptime CSS | Nothing in emilia; `jhonstart`/`onze` own it | Fronts 49 and 53 build the app shell |
| CDN / Play distribution | `§ 2.4` | A distribution concern with no authoring surface | — | Never, as a library feature |
| Cross-module class minification and dedup | implied by `§ 1` | emilia hashes per call site; cross-module dedup needs a whole-program pass | Build-level aggregation over all compiled modules | When `onze build` (front 50) defines a CSS emission stage |
| One static `.css` file per build | `§ 1`, `§ 2.3` | `flush()` is per-render by contract; a static file needs a stage that runs once | The same `onze build` CSS stage | Front 50 or later |
| Tree-shaking unused theme values | `§ 3.5` | Requires knowing the whole program's token usage | Whole-program aggregation, as above | As above |
| `@custom-variant` bodies using `@slot` | `§ 20.3`, `§ 20.7` | `@slot` is CSS-in-CSS templating; the botopink equivalent — a function over `Token[]` — covers the intent but not the literal syntax | Nothing. Recorded so that "we did not implement `@slot`" is a decision rather than an oversight | Closed by front 59's function form |
| Arbitrary values validated against CSS grammar | `§ 3.1` | emilia can splice any string but cannot tell a valid `calc()` from a typo | A comptime CSS value parser | Front 57 ships refuse-on-`}`/`<` safety now; full validation waits on a parser |
| `color-mix()` / P3 fallback chains | not in doc | Emitting the colours is easy; a correct fallback cascade needs front 56's `@supports` hoisting plus an OKLCH→sRGB converter | Front 56, plus the converter | After 56 lands. The single-value form is already a fold-in to front 33 |
| Automatic vendor prefixing | implied by `§ 2.2` | Tailwind delegates this to PostCSS; emilia has no plugin pipeline | A PostCSS-style transform stage | Only if a browser-support matrix is ever declared; hand-written prefixes cover today's needs |

## Deferred — ecosystem

Rows produced by the package restructure itself, not by a reference document. The mocking surface
is not deferred: it is `std/mocks` (decision 71; `testing.mocks` under decision 106).

| Feature | Source | Why it is not re-homed now | What would have to exist first | Revisit |
|---|---|---|---|---|
| The `Request`/`MockMvc` double as a *shared* helper across libraries | 1.0.9 `language-gaps.md` § Unowned surface | Closed as front 19's, rakun-only; jhonstart and onze tests reach the server through `onze-test`, which depends on `rakun-test` (dependency direction in [`02-packaging/README.md`](./02-packaging/README.md)) | Nothing | Never as a shared helper |

## Out of scope

Not runtime or authoring features at all. Listed so the audit is closed rather than silent.

| Feature | Source | Why |
|---|---|---|
| Maven, Gradle, Ant/Ivy integration; the JVM/Gradle/Maven version matrix | Spring `02`, `11`, `01` | JVM build tooling. The equivalent commands are fronts 88 and 81; the version requirement becomes an OTP minimum |
| Kotlin and Java source examples | Spring `01`–`03` | JVM language bindings; botopink is the only source language here |
| JAX-RS / Jersey as an alternative web stack | Spring `04` | A second web framework behind the same server. One router is the design |
| `open-in-view` / session-per-request | Spring `05` | An artefact of JPA lazy-loading proxies. With explicit fetches there is nothing to keep open |
| LiveReload | Spring `12` | Deprecated upstream in 4.1.0. Browser reload belongs to front 50's dev server |
| Upgrade guides, OpenRewrite recipes, Spring Boot Migrator, support-window policy | Spring `12` | Source-migration tooling and project governance. `rakun` needs a deprecation policy, not a front |
| Pages Router: `pages/`, `_app`, `_document`, `getStaticProps`, `getServerSideProps`, `pages/api/*` | Next `§ 1`, `§ 3`, `§ 30` | Legacy router kept alive upstream for migration. This milestone ports the App Router; each legacy API has an App Router equivalent already in a front |
| TypeScript setup, ESLint/Biome, `typescript.ignoreBuildErrors`, `eslint.ignoreDuringBuilds` | Next `§ 2`, `§ 28`, `§ 29` | Tooling for another language. The last two are escape hatches that disable a correctness gate, which this project does not ship |
| Node version and OS matrix; prerequisites | Next `§ 1`, `§ 2` | Replaced by an OTP requirement in front 49's README; the browser matrix carries over unchanged |
| Vite, PostCSS and Tailwind CLI installation; the 19 framework install guides | Tailwind `§ 2.1`–`§ 2.5` | Host toolchain setup |
| "Managing duplication" advice: loops, multi-cursor editing, components | Tailwind `§ 3.1` | Editing practice, and host-language features botopink already has |
| Documentation aids: summaries, "when to use what", recommended structure | all three | Reader guidance. The recommended structure shapes front 53's example app but is not a feature |

## What this file is for

Two things.

First, so that "we did not do X" is a recorded decision with a reason, rather than something a
reader has to infer from absence. An audit that finds 152 gaps and reports 22 fronts owes an account
of the other 130.

Second, so that the exit gate in [`fronts.md`](./fronts.md) can be honest. A milestone claiming
Spring Boot 4, Next.js and Tailwind CSS parity is making a checkable claim only if the exceptions
are written down. These are the exceptions.
