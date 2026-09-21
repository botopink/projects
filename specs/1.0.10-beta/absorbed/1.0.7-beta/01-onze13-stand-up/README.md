# Front 01 — onze13 Stand-up

**Referência Next.js:** [Getting Started](https://nextjs.org/docs/app/getting-started)

**Priority:** critical — without the new lib, nothing else in onze13 can compile
**Depends on:** none
**Owns:** `repository/onze13/` (entire new repo)
**Does not touch:** jhonstart, rakun, emilia, std (other fronts own those)

---

## Problem

onze13 não existe. É preciso criar a nova lib do zero — manifest, module tree, tipos base, integration layer — para que os fronts subsequentes (CLI, image, font, example app) tenham onde trabalhar.

## Current state

- O diretório `repository/onze13/` não existe
- Nenhuma lib orquestra jhonstart + rakun + emilia como um framework full-stack
- O ecossistema tem as peças (jhonstart = UI, rakun = server, emilia = CSS, std = primitives) mas falta a cola

## Mechanism

onze13 é uma lib botopink como jhonstart/rakun/emilia — escrita em `.bp`, alcançada via `from "onze13"`, opt-in por projeto. O compiler core não conhece onze13. Ela:

1. **Re-exporta** tipos e funções de jhonstart, rakun e emilia (convenience imports)
2. **Adiciona** a camada de orquestração: config (`onze13.json`), routing integration, image/font optimization
3. **Define** os tipos de integração: `PageProps`, `LayoutProps`, `RouteContext`, `ActionResponse`

## Exemplos de Uso na Linguagem bp

### Configuração do projeto (onze13.json)

```json
{
  "name": "my-app",
  "port": 3000,
  "basePath": "",
  "outDir": ".onze13"
}
```

### Importando onze13 em uma página

```bp
// app/page.bp
import {Element, div, h1, text} from "jhonstart";
import {emilia, Token} from "emilia";

pub fn HomePage() -> Element {
    val titleClass = emilia([.Text.Size.X3xl, .Text.Bold, .Color.Blue700]);
    return div([
        h1([text("Bem-vindo ao onze13!", attrs: [])], attrs: [#("class", titleClass)]),
    ], attrs: []);
}
```

### Usando tipos de integração

```bp
// app/blog/[slug]/page.bp
import {PageProps} from "onze13";
import {Element, div, h1, p, text} from "jhonstart";

#[@future]
pub fn BlogPost(props: PageProps<Dict<string, string>>) -> @Future<Element> {
    val slug = props.params.get("slug");
    val post = await fetchPost(slug);
    return div([
        h1([text(post.title, attrs: [])], attrs: []),
        p([text(post.content, attrs: [])], attrs: []),
    ], attrs: []);
}
```

## Exemplos em bp

### Configuração do projeto

```json
// onze13.json
{
  "name": "my-app",
  "port": 3000,
  "basePath": ""
}
```

### Usando onze13 em uma página

```bp
// app/page.bp
import {Element, div, h1, text} from "jhonstart";
import {emilia, Token} from "emilia";
import {PageProps} from "onze13";

pub fn HomePage() -> Element {
    val titleClass = emilia([.Text.Size.X3xl, .Text.Bold]);
    return div([
        h1([text("Bem-vindo!", attrs: [])], attrs: [#("class", titleClass)]),
    ], attrs: []);
}
```

## Steps

### Step 1 — Criar repositório e manifest

```
repository/onze13/
├── AGENTS.md
├── botopink.json
├── docs.md
├── README.md
├── src/
│   ├── root.bp
│   ├── config.bp
│   ├── types.bp
│   └── reexports.bp
├── test/
│   └── config_test.bp
└── examples/
    └── blog/
```

```json
{
  "name": "onze13",
  "version": "0.0.1",
  "description": "Next.js-style full-stack framework for botopink — orchestrates jhonstart (UI), rakun (server), emilia (CSS), and std (primitives)",
  "src": "src/",
  "targets": ["commonJS", "erlang"],
  "files": [
    "root.bp",
    "config.bp",
    "types.bp",
    "reexports.bp"
  ],
  "requires": {
    "jhonstart": "feat",
    "rakun": "feat",
    "emilia": "feat"
  }
}
```

**Acceptance:**
- [ ] `repository/onze13/` criado com estrutura acima
- [ ] `botopink check` passa no manifest
- [ ] Dependências declaradas: jhonstart, rakun, emilia

### Step 2 — Module tree (root.bp)

```bp
// src/root.bp
pub mod config;
pub mod types;
pub mod reexports;
```

**Acceptance:**
- [ ] `root.bp` declara os 3 módulos
- [ ] Compila sem erros

### Step 3 — Config types (config.bp)

```bp
// src/config.bp
// onze13.json — configuration for a onze13 application.
// Analogous to next.config.js.

pub type BpnextConfig(
    port: i32,
    basePath: string,
    outDir: string,
    dev: bool,
)

pub fn defaultConfig() -> BpnextConfig {
    return BpnextConfig(
        port: 3000,
        basePath: "",
        outDir: ".onze13",
        dev: false,
    );
}
```

**Acceptance:**
- [ ] `BpnextConfig` type definido
- [ ] `defaultConfig()` retorna valores padrão
- [ ] Test: config defaults são corretos

### Step 4 — Integration types (types.bp)

```bp
// src/types.bp
// Types shared between onze13's integration layer and consumer apps.

import {Element} from "jhonstart";

// Props passed to page components (analogous to Next.js PageProps)
pub type PageProps<P>(
    params: P,
    searchParams: Dict<string, string>,
)

// Props passed to layout components
pub type LayoutProps(
    children: Element,
)

// The result of a server action
pub type ActionResponse<S>(
    state: S,
    success: bool,
    message: string,
)

// Route segment config (analogous to Next.js route segment config)
pub type RouteSegmentConfig(
    dynamic: string,     // "auto" | "force-dynamic" | "error" | "force-static"
    revalidate: i32,     // seconds, 0 = never cache, false = infinite
)
```

**Acceptance:**
- [ ] `PageProps`, `LayoutProps`, `ActionResponse`, `RouteSegmentConfig` definidos
- [ ] Compila com import de jhonstart

### Step 5 — Re-exports (reexports.bp)

```bp
// src/reexports.bp
// Convenience re-exports so consumers can `from "onze13"` for common items.
// The actual implementations live in jhonstart/rakun/emilia.

// From jhonstart:
//   Element, text, div, span, p, h1, ul, li, fragment
//   renderToString, html
//   state, effect, memo, ref, reducer
//   useRouter, Link (once F02/F03 land)

// From rakun:
//   Response, Request, App
//   #[service], #[restController], #[getMapping], etc.

// From emilia:
//   emilia, flush, Token

// Re-exports are documented here; actual wiring happens when consumer
// apps import from "onze13" and the resolver follows the dependency chain.
```

**Acceptance:**
- [ ] Documentação de re-exports clara
- [ ] Consumer apps podem `from "onze13"` (após fronts de jhonstart/rakun/emilia)

### Step 6 — AGENTS.md e docs.md

Documentar convenções, module tree, CI, local gate.

**Acceptance:**
- [ ] AGENTS.md segue padrão dos sibling repos
- [ ] docs.md documenta a API pública
- [ ] README.md com quickstart

### Step 7 — CI setup

`.github/workflows/test.yml` para onze13.

**Acceptance:**
- [ ] CI roda `botopink test --target commonJS` e `--target erlang`
- [ ] CI checka que jhonstart/rakun/emilia estão disponíveis como deps

## Gate

- [ ] `botopink test` green (commonJS + erlang)
- [ ] `botopink check` green no manifest
- [ ] AGENTS.md, docs.md, README.md escritos
- [ ] CI configurado
- [ ] Commit em `fix/onze13-stand-up`; no push

## Blast radius

- **Novo repo** `repository/onze13/` — sem impacto em libs existentes
- **bpmp registry** precisa reconhecer onze13 como lib válida
- **Nenhum compiler change** — onze13 é uma lib pura

## Notes

- onze13 é opt-in: um projeto botopink não precisa usar onze13
- O nome "onze13" é placeholder — pode ser renomeado antes do merge
- A lib começa mínima (config + types) e cresce com os fronts subsequentes
