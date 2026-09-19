# Specs — 1.0.7-beta (onze13: Next.js em Botopink)

O milestone 1.0.7-beta cria **onze13** — uma nova lib que implementa as funcionalidades do Next.js para o ecossistema botopink, usando **jhonstart** como camada de UI (equivalente ao React), **rakun** como servidor de aplicação (equivalente ao Spring/Node.js server), **emilia** como camada de estilização (equivalente ao Tailwind CSS), e a **std** como fundação de primitivas. onze13 orquestra as três libs existentes + extensões em cada uma para entregar file-system routing, server/client components, streaming, server actions, caching, middleware, metadata, e otimizações — o conjunto completo que torna botopink um framework full-stack comparável ao Next.js.

| Front | Prioridade | Repo | Módulo | Descrição |
|---|---|---|---|---|
| [`01-onze13-stand-up/`](./01-onze13-stand-up/README.md) | **critical** | onze13 (new) | onze13-core | Nova lib: manifest, module tree, tipos base, integration layer |
| [`02-jhonstart-router/`](./02-jhonstart-router/README.md) | **critical** | jhonstart | jhonstart-core | Router real (useRouter, pathname, params, push/replace) — promover router.d.bp → .bp |
| [`03-jhonstart-link/`](./03-jhonstart-link/README.md) | **critical** | jhonstart | jhonstart-core | Link component com prefetch, scroll, client-side navigation |
| [`04-jhonstart-server-components/`](./04-jhonstart-server-components/README.md) | **critical** | jhonstart | jhonstart-core | Server components (#[@future] fn → @Future<Element>), data loading, request() hook |
| [`05-jhonstart-client-directive/`](./05-jhonstart-client-directive/README.md) | **high** | jhonstart | jhonstart-core | 'use client' directive: boundary entre server e client modules |
| [`06-jhonstart-streaming/`](./06-jhonstart-streaming/README.md) | **high** | jhonstart | jhonstart-core | Streaming SSR: Suspense boundary, loading states, progressive render |
| [`07-jhonstart-error-boundaries/`](./07-jhonstart-error-boundaries/README.md) | **high** | jhonstart | jhonstart-core | Error boundaries: error.bp, not-found.bp, global-error.bp |
| [`08-jhonstart-metadata/`](./08-jhonstart-metadata/README.md) | **medium** | jhonstart | jhonstart-core | Metadata API: generateMetadata, OG images, SEO tags |
| [`09-rakun-ssr-pipeline/`](./09-rakun-ssr-pipeline/README.md) | **critical** | rakun | rakun-core | SSR pipeline: render page → HTML, serve via rakun HTTP, RSC payload |
| [`10-rakun-server-actions/`](./10-rakun-server-actions/README.md) | **critical** | rakun | rakun-core | 'use server' directive, form actions, POST dispatch, revalidation |
| [`11-rakun-route-handlers/`](./11-rakun-route-handlers/README.md) | **high** | rakun | rakun-core | Route handlers (API routes): GET/POST/PUT/DELETE em route.bp |
| [`12-rakun-middleware/`](./12-rakun-middleware/README.md) | **high** | rakun | rakun-core | Middleware pipeline: intercept requests, auth, redirects, rewrites |
| [`13-rakun-cache/`](./13-rakun-cache/README.md) | **medium** | rakun | rakun-cache | Cache layer: 'use cache', cacheLife, cacheTag, revalidateTag/Path |
| [`14-rakun-file-routing/`](./14-rakun-file-routing/README.md) | **critical** | rakun | rakun-core | File-system router: app/ convention, [dynamic], (groups), @slots |
| [`15-emilia-attributes/`](./15-emilia-attributes/README.md) | **high** | emilia | emilia-core | Attribute slot: class composition, #[emilia] decorator on builders |
| [`16-emilia-jhonstart-integration/`](./16-emilia-jhonstart-integration/README.md) | **high** | emilia + jhonstart | emilia-core | html DSL integration: [emilia]={expr} attribute, class auto-injection |
| [`17-std-async-primitives/`](./17-std-async-primitives/README.md) | **medium** | std | std-core | Async primitives: Promise.all, Promise.allSettled, async iterators |
| [`18-std-crypto-hash/`](./18-std-crypto-hash/README.md) | **low** | std | std-core | Content hashing: stable hashes for cache keys, ETags |
| [`19-onze13-cli/`](./19-onze13-cli/README.md) | **medium** | onze13 | onze13-cli | CLI: create-onze13-app, dev server, build, start |
| [`20-onze13-image-optimization/`](./20-onze13-image-optimization/README.md) | **low** | onze13 | onze13-core | Image component: lazy loading, resize, format conversion |
| [`21-onze13-font-optimization/`](./21-onze13-font-optimization/README.md) | **low** | onze13 | onze13-core | Font optimization: next/font equivalent, zero layout shift |
| [`22-onze13-example-app/`](./22-onze13-example-app/README.md) | **medium** | onze13 | examples | Full example app: blog with SSR, actions, cache, emilia styling |

## Order

```
Phase 1 (Critical Path — foundation):
  01-onze13-stand-up ──┐
  17-std-async-primitives ──┤
                            └──► 02-jhonstart-router ──┐
                                                        ├──► 03-jhonstart-link
                                                        │
                                                        └──► 04-jhonstart-server-components ──┐
                                                                                                │
  14-rakun-file-routing ────────────────────────────────────────────────────────────────────────┤
  09-rakun-ssr-pipeline ────────────────────────────────────────────────────────────────────────┘
                                                                                                 │
Phase 2 (Core features — parallel after Phase 1):                                                │
  05-jhonstart-client-directive ──┐                                                              │
  06-jhonstart-streaming ─────────┤                                                              │
  07-jhonstart-error-boundaries ──┤                                                              │
  10-rakun-server-actions ────────┤                                                              │
  11-rakun-route-handlers ────────┤                                                              │
  12-rakun-middleware ────────────┤                                                              │
  15-emilia-attributes ───────────┘                                                              │
                                                                                                 │
Phase 3 (Integration + advanced — parallel after Phase 2):                                       │
  08-jhonstart-metadata ──────────┐                                                              │
  13-rakun-cache ─────────────────┤                                                              │
  16-emilia-jhonstart-integration ┤                                                              │
  18-std-crypto-hash ─────────────┤                                                              │
  19-onze13-cli ──────────────────┤                                                              │
  20-onze13-image-optimization ───┤                                                              │
  21-onze13-font-optimization ────┘                                                              │
                                                                                                 │
Phase 4 (Validation):                                                                            │
  22-onze13-example-app ────────────────────────────────────────────────────────────────────────┘
```

**Fase 1 (Critical Path):** `01` + `17` (paralelo) → `02` + `14` (paralelo) → `03` + `04` + `09` (paralelo)

**Fase 2 (Core):** `05` · `06` · `07` · `10` · `11` · `12` · `15` (paralelo após Fase 1)

**Fase 3 (Integration):** `08` · `13` · `16` · `18` · `19` · `20` · `21` (paralelo após Fase 2)

**Fase 4 (Validation):** `22` (app completa valida toda a stack)

**Por que 01-onze13-stand-up é primeiro:** onze13 é a lib nova que orquestra tudo. Sem o manifest, module tree e tipos base, nenhum outro front do onze13 pode compilar. Os fronts de jhonstart/rakun/emilia podem rodar em paralelo (são libs independentes), mas o integration layer do onze13 depende deles.

**Por que 14-rakun-file-routing é crítico:** O file-system router é a fundação do Next.js — sem ele, não há convenção `app/`, não há rotas dinâmicas, não há layout nesting. O SSR pipeline (09) precisa do router para saber qual página renderizar.

## Regras do Milestone

- **Multi-repo:** Os fronts tocam 4 repos (onze13, jhonstart, rakun, emilia) + std. Cada front é dono de arquivos em UM repo apenas (exceto 16 que toca emilia + jhonstart — documentado).
- **Compiler-unaware:** onze13, jhonstart, rakun e emilia são libs puras — o compiler core não conhece nenhuma delas. Tudo é plain botopink + @Decl + comptime + @emit + @External.
- **Dual-target:** Todo front deve funcionar em commonJS E erlang (onde aplicável). onze13 herda o dual-target das libs que compõe.
- **Std lib reuse:** Usar módulos da std (json, http, fs, env, crypto, etc.) quando possível — não re-implementar.
- **Convention over configuration:** File-system routing, decorator-based metadata, emilia tokens — tudo por convenção, não config explícita.
- **No breaking changes:** Nenhum front quebra a API existente de jhonstart, rakun ou emilia. Extensões são aditivas.
- **Test coverage:** Cada front tem testes em commonJS E erlang.

## Arquitetura onze13

```
┌─────────────────────────────────────────────────────────────────┐
│                         onze13 (orchestrator)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  routing  │  │  cache   │  │  image   │  │  font        │   │
│  │  config   │  │  config  │  │  config  │  │  config      │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────┐        ┌─────────────────────────┐    │
│  │    jhonstart (UI)    │        │     rakun (server)       │    │
│  │  ┌───────────────┐  │        │  ┌───────────────────┐  │    │
│  │  │  Element tree  │  │        │  │  IoC container    │  │    │
│  │  │  + hooks       │  │        │  │  + DI             │  │    │
│  │  ├───────────────┤  │        │  ├───────────────────┤  │    │
│  │  │  html DSL      │  │        │  │  HTTP server      │  │    │
│  │  ├───────────────┤  │  ◄───► │  ├───────────────────┤  │    │
│  │  │  Router        │  │  SSR   │  │  File router      │  │    │
│  │  │  + Link        │  │        │  │  + middleware     │  │    │
│  │  ├───────────────┤  │        │  ├───────────────────┤  │    │
│  │  │  Server Comp.  │  │        │  │  Server Actions   │  │    │
│  │  │  + streaming   │  │        │  │  + cache          │  │    │
│  │  ├───────────────┤  │        │  ├───────────────────┤  │    │
│  │  │  Error bounds  │  │        │  │  Route Handlers   │  │    │
│  │  ├───────────────┤  │        │  └───────────────────┘  │    │
│  │  │  Metadata      │  │        │                          │    │
│  │  └───────────────┘  │        │                          │    │
│  └─────────────────────┘        └─────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────┐        ┌─────────────────────────┐    │
│  │   emilia (CSS)       │        │     std (primitives)     │    │
│  │  Token enum          │        │  json, http, fs, env,   │    │
│  │  + class generation  │        │  crypto, dict, sets,    │    │
│  │  + flush()           │        │  time, url, ...         │    │
│  │  + attribute slots   │        │                          │    │
│  └─────────────────────┘        └─────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Mapeamento Next.js → onze13

| Next.js | onze13 | Lib |
|---|---|---|
| React | jhonstart (Element, hooks, html DSL) | jhonstart |
| React Server Components | #[@future] fn → @Future<Element> | jhonstart |
| 'use client' directive | #[client] decorator / convention | jhonstart |
| next/link | Link component | jhonstart |
| next/navigation (useRouter) | useRouter behavior | jhonstart |
| next/image | Image component | onze13 |
| next/font | font optimization | onze13 |
| App Router (file-system) | app/ convention + file router | rakun |
| layout.tsx | layout.bp | rakun (file router) |
| page.tsx | page.bp | rakun (file router) |
| loading.tsx | loading.bp | jhonstart (streaming) |
| error.tsx | error.bp | jhonstart (error boundaries) |
| not-found.tsx | not-found.bp | jhonstart (error boundaries) |
| route.ts (Route Handlers) | route.bp | rakun |
| Server Actions | #[serverAction] + form integration | rakun |
| Middleware | middleware.bp | rakun |
| fetch + cache | 'use cache' + cacheLife + cacheTag | rakun |
| revalidatePath/Tag | revalidate functions | rakun |
| generateMetadata | generateMetadata fn | jhonstart |
| ImageResponse (OG) | OG image generation | jhonstart + onze13 |
| Tailwind CSS | emilia (Token enum) | emilia |
| CSS Modules | emilia (scoped classes) | emilia |
| create-next-app | create-onze13-app | onze13 CLI |
| next dev/build/start | onze13 dev/build/start | onze13 CLI |
| next.config.js | onze13.json | onze13 |

## Estrutura de um projeto onze13

```
my-onze13-app/
├── app/                          # File-system routing (rakun)
│   ├── layout.bp                 # Root layout
│   ├── page.bp                   # Home page (/)
│   ├── loading.bp                # Global loading UI
│   ├── error.bp                  # Global error boundary
│   ├── not-found.bp              # Global 404
│   ├── globals.bp                # Global styles (emilia)
│   ├── blog/
│   │   ├── layout.bp             # Blog layout
│   │   ├── page.bp               # /blog
│   │   ├── loading.bp            # Blog loading
│   │   └── [slug]/
│   │       ├── page.bp           # /blog/:slug
│   │       ├── loading.bp
│   │       ├── not-found.bp
│   │       └── opengraph-image.bp
│   ├── (marketing)/              # Route group
│   │   ├── about/page.bp         # /about
│   │   └── contact/page.bp       # /contact
│   ├── (shop)/                   # Route group
│   │   ├── layout.bp             # Shop layout
│   │   ├── products/page.bp      # /products
│   │   └── cart/page.bp          # /cart
│   └── api/
│       ├── posts/route.bp        # GET/POST /api/posts
│       └── webhooks/route.bp     # POST /api/webhooks
├── components/                   # Shared components (jhonstart)
│   ├── ui/
│   │   ├── button.bp
│   │   └── card.bp
│   └── features/
│       └── post-card.bp
├── lib/                          # Utilities
│   ├── auth.bp
│   ├── db.bp
│   └── actions.bp                # Server actions
├── public/                       # Static assets
├── middleware.bp                  # Middleware (rakun)
├── onze13.json                   # Config
└── botopink.json                 # Dependencies
```

## Exemplos de Código

Veja [`examples-bp.md`](./examples-bp.md) para exemplos completos de como cada frente se traduz em código bp real, do ponto de vista do desenvolvedor que usa o framework. Inclui exemplos para todas as 22 frentes: routing, server/client components, server actions, streaming, error boundaries, metadata, middleware, cache, file routing, emilia integration, image/font optimization, e um exemplo completo de blog app.
