# Proposta para a `08-d` — o CSS em três camadas e a seção `--- style ---`

**Estado:** proposta, ainda não decidida. Responde à pergunta `08-d` de
[`decisoes-pendentes.md`](../../decisoes-pendentes.md#08-d--quem-faz-o-escopo-do-css): quem faz o
escopo do CSS e onde mora o parser. Quando for aceita, vira uma decisão numerada em
`decisions-taken.md`, e as frentes 116, 119 e `06-emilia/34` são reescritas a partir dela (§ 8).

## 1. A ideia em uma tela

```text
repository/css      (botopink/css)     a base para construir CSS: lê uma folha, Sheet tipado, scope()
        ▲
repository/styled   (botopink/styled)  a base para construir componentes de CSS: styled "…" → Styled
        ▲                          ▲
repository/emilia           jhonstart/jhonstart-styled   ← "bpp".style: compila a seção --- style ---
uma série de componentes           ▲
feitos em styled           jhonstart-emilia             ← #[styled(..tokens)] na tag (301)
```

```json
{ "bpp": { "default": "jhonstart", "style": "jhonstart-styled" } }
```

```bpp
---
type Props(title: string, children: Node)
---
<article>
  <h1 class="title">{props.title}</h1>
  {props.children}
</article>
--- style ---
.title { font-size: 2rem; }
article :global(p) { line-height: 1.6; }
```

## 2. As três camadas

| Camada | Onde | O que é | Importa | Quem importa |
|---|---|---|---|---|
| `css`: a base para construir CSS | `repository/css` (`botopink/css`) | lê uma folha (regras, at-rules, comentários, strings, `{ }` aninhado) para um `Sheet` tipado; o renderizador; `scope(id, css) -> @Result<string, string>` | std | `styled` |
| `styled`: a base para construir componentes de CSS | `repository/styled` (`botopink/styled`) | `styled "…"` → `Styled` (classe + regras); a folha que junta os componentes por render ou por build, em `@layer`s | `css`, std | emilia · `jhonstart-styled` |
| emilia: uma série de componentes feitos em `styled` | `repository/emilia` | os tokens, o tema, cada família escrita em `styled "…"`; aplicada na tag como anotação (301) | `styled`, std | `jhonstart-emilia` |

**Por que dois repositórios próprios.** Pela decisão 326, um pacote compartilhado novo nasce como
repositório (`botopink/<pkg>`, submódulo em `repository/<pkg>`, ao lado de `http`, `log` e
`validation`) e entra como dependência comum (242), sem ir embutido no compilador. O critério das
115–117 continua: um pacote compartilhado precisa de dois consumidores, e há dois, a emilia e o
`jhonstart-styled`. A 113 proíbe que uma biblioteca nomeie outra. Com um pacote compartilhado, os dois
usam o mesmo código sem que o jhonstart importe a emilia, nem o contrário. `css` e `styled` não
conhecem HTML nem framework.

**O que acaba.** A emilia deixa de ter um modelo de folha só seu (`Rule`, `Sheet`, `renderRule`,
`renderDocument` em `output.bp:44-593`). Ninguém mais monta texto de CSS com `+`.

## 3. A sintaxe `styled "…"`

`styled` é a `pub default fn` do pacote, um template function como o `html`, sobre
`comptime css: @Expr<string>`. O literal contém declarações, blocos aninhados `&…` e at-rules. Os
valores entram por buracos `${…}`, a interpolação que a linguagem já tem, e por isso as chaves
continuam sendo do CSS.

```bp
import styled, {Styled} from "styled";

val wide = 8;

pub val card = styled """
  padding: --spacing(4);
  border-radius: 0.5rem;
  &:hover { box-shadow: 0 1px 3px rgb(0 0 0 / 0.1); }
  @media (width >= 40rem) { padding: --spacing(${wide}); }
""";
// card.className → "s_<hash>"
// card.rules     → ".s_<hash>{padding:calc(var(--spacing) * 4);border-radius:0.5rem}
//                   .s_<hash>:hover{…} @media (width >= 40rem){.s_<hash>{…}}"
```

- A classe sai do `hash.contentHash` da std sobre as regras: as mesmas regras dão a mesma classe.
- Se todos os buracos são comptime, a classe e a regra são calculadas no build e nada é registrado
  no render. É o mesmo caminho que a 301 já prevê para a emilia.
- Recusado: `styled "padding: {wide};"` (`{` abre um bloco de CSS, o valor vai em `${…}`) e
  uma declaração sem `;`.

### 3.1 A sintaxe do Tailwind v4 dentro do `styled "…"`

Desde a v4, o Tailwind se escreve em CSS: `@utility`, `@variant`, `@custom-variant`, `@apply`,
`@theme` e as funções `--spacing()`, `--alpha()` e `--value()`. O próprio Tailwind declara o `p-*`
assim:

```css
@utility p-* { padding: --spacing(--value(integer)); }
```

A proposta é o literal do `styled` aceitar essa sintaxe onde ela é CSS de verdade, e usar o
botopink onde o Tailwind usa uma diretiva só porque o CSS não tem funções. A emilia já fez essa
troca em `compose.bp`: "Tailwind needs directives here because CSS has no functions; botopink has
functions".

| Tailwind v4 | No `styled "…"` | O que sai |
|---|---|---|
| `--spacing(4)` | igual, com buraco: `padding: --spacing(${n});` | `padding:calc(var(--spacing) * 4)` — o `css` expande; `spacing(n)` do `spacing.bp` deixa de ser preciso |
| `--alpha(var(--color-lime-300) / 50%)` | igual | `color-mix(in oklab, var(--color-lime-300) 50%, transparent)` |
| `@variant hover { … }`, `@variant dark { … }` | igual, dentro do componente | a regra sob `&:hover` / sob a variante `dark` |
| `@custom-variant hocus (&:hover, &:focus);` | igual, num `styled` exportado como variante | `@variant hocus { … }` passa a valer onde ele é importado |
| `@apply p-4 font-bold;` | um buraco do tipo `Styled`: `${padAll(4)} ${fontBold}` | as declarações do outro componente entram ali; composição tipada, sem nome de classe em string (281) |
| `@utility tab-4 { tab-size: 4; }` | `pub val tab4 = styled "tab-size: 4;";` | o `val` dá o nome; não precisa de `@utility` |
| `@utility tab-* { tab-size: --value(integer); }` | `fn tab(n: i32) -> Styled { return styled "tab-size: ${n};"; }` | a função é a família; o tipo do parâmetro faz o papel de `--value(integer)` |
| `@layer components { … }` | a camada do `Sheet` em que o componente entra | |
| `@theme { --color-mint-500: …; }` | recusado no `styled` | o tema é o da decisão 300 (`#[theme]`, `entry(…)`), tipado e declarado uma vez |

O mesmo componente, escrito das duas formas:

```css
/* Tailwind v4 */
@utility btn {
  padding: --spacing(2) --spacing(4);
  border-radius: var(--radius-md);
  @variant hover { background: --alpha(var(--color-blue-500) / 80%); }
  @variant dark  { color: var(--color-white); }
}
```

```bp
// styled
pub val btn = styled """
  padding: --spacing(2) --spacing(4);
  border-radius: var(--radius-md);
  @variant hover { background: --alpha(var(--color-blue-500) / 80%); }
  @variant dark  { color: var(--color-white); }
""";

pub val primaryBtn = styled """
  ${btn}
  background: var(--color-blue-500);
""";
```

Ficam abertos (§ 9, p6 e p7): aceitar ou não `@utility … --value()` literalmente, e de onde o
`@variant` tira os breakpoints, que hoje estão no tema da emilia.

## 4. A emilia sobre o `styled`

Hoje a escada do `spacing.bp` monta a string `calc(var(--spacing) * n)` (`spacing(n)`,
`spacingHalf`, `spacingNegHalf`), e `padTokenToCss` (`emilia.bp:3360`) cola o resultado com
`oneDecl` e `axisDecl`. Na proposta, a escada é o `--spacing()` do próprio literal, como no Tailwind,
e cada caso da família é um componente:

```bp
// emilia/src/spacing.bp (ou o bloco da família Pad)
import styled, {Styled} from "styled";

// Tailwind: @utility p-*  { padding: --spacing(--value(integer)); }
fn padAll(n: i32) -> Styled { return styled "padding: --spacing(${n});"; }
// Tailwind: @utility px-* { padding-inline: --spacing(--value(integer)); }
fn padX(n: i32) -> Styled   { return styled "padding-inline: --spacing(${n});"; }
// o meio passo vira um valor: --spacing(0.5) → calc(var(--spacing) * 0.5)
fn padAllHalf(n: i32) -> Styled { return styled "padding: --spacing(${n}.5);"; }
```

- Uma lista de tokens é a composição dos componentes dos seus tokens. A ordem continua sendo a
  identidade da classe (`contracts.md` § 4).
- No template nada muda: `<h1 #[styled(.Text.Size.X3xl, .Text.Bold)]>` (301).
- O fixture do contrato 4, `e_39b87d03`, não pode mudar. Por isso a camada da emilia mantém o
  prefixo `e_`, e o `styled` aceita um prefixo por camada (`s_` por padrão).

## 5. O manifesto

```json
{ "bpp": { "default": "jhonstart", "style": "jhonstart-styled" } }
```

- `default` (obrigatório): o pacote cuja `pub default fn` desdobra a marcação, o `html` do core
  (200).
- `style` (opcional): o pacote cuja `pub default fn` desdobra a seção de estilo, ou seja, o
  `jhonstart-styled`.
- Com isso, o toolchain conhece quatro coisas: os dois pacotes, as duas funções default e o prelúdio
  (emenda a 285). Continua sem nomear nenhuma biblioteca.

## 6. A seção `--- style ---` no `.bpp`

Depois da marcação, uma linha `--- style ---` abre a seção, que vai até o fim do arquivo. Ela é
compilada à parte: o toolchain entrega o texto à função default do `style`, como entrega a marcação
ao `html`. O valor que volta chega ao `html` junto com a marcação, e o `html` escreve
`data-s="<id>"` em todo elemento que o template escreve.

| Escrito | Significa |
|---|---|
| `--- style ---` | com escopo: cada seletor ganha `[data-s="<id>"]` |
| `--- style #[isGlobal] ---` | vai para a folha como foi escrito, sem escopo |
| `:global(sel)` dentro da seção | `sel` fica sem escopo |
| `--- style #[defineVars(a, b)] ---` | cada nome é um valor do escopo do template; o elemento raiz ganha `style="--a: …; --b: …"` |
| `<style #[isInline]>` na marcação | o builder `style`, verbatim (o comportamento de hoje) |
| `<style>` na marcação, sem `#[isInline]` | erro na tag, apontando para a seção |
| seção sem `"bpp".style` no manifesto | erro na linha: `a --- style --- section needs "bpp.style" in botopink.json` |

O id do escopo, sem hash, é o caminho do módulo mais a linha da seção (`components-post-card-12`).
O build o encurta (124).

## 7. Como o jhonstart junta as peças

| Peça | Dono | Faz |
|---|---|---|
| `pub default fn` de `jhonstart-styled` | membro novo do jhonstart | recebe a seção, aplica o escopo pelo `styled` e devolve o `Style` do jhonstart (id, folha, modo, vars) |
| o sink | `jhonstart-styled` | põe a **única** folha do render no head e em cada fill de boundary: as camadas da emilia e depois as seções com escopo |
| `Style` e o braço no `html.bp` | core do jhonstart | recebe o `Style` com a marcação, escreve `data-s` e recusa `<style>` sem `#[isInline]` |
| `#[styled(..tokens)]` | `jhonstart-emilia` | 301; os tokens viram componentes `styled` e as regras vão para o mesmo sink, e o plugin de flush próprio da ponte sai |

A ordem da cascata fica: folhas linkadas (`globals.css`), camadas da emilia, seções com escopo.

## 8. O que muda se for aceita

| Onde | Mudança |
|---|---|
| decisões 198, 200, 284 | `"bpp": "jhonstart"` vira `"bpp": {"default": "jhonstart", …}` |
| 212 | o arquivo ganha uma terceira parte, a seção de estilo |
| 270 | o prelúdio é o do pacote em `bpp.default` |
| 278 | `#[isGlobal]` e `#[defineVars]` passam para a linha da seção; `<style>` na marcação só com `#[isInline]` |
| 285 | o toolchain passa a conhecer também o pacote de `style` |
| 301 | os tokens viram componentes `styled`; a folha sai pelo `jhonstart-styled` |
| `08-bpp/119` | é dona de `repository/css`, `repository/styled`, `jhonstart-styled` e `jhonstart-emilia`; passos: 1 os pacotes, 2 `jhonstart-styled` e o braço do `html`, 3 boundary, 4 `#[styled]`, 5 uma folha só |
| `08-bpp/116` | manifesto em objeto, o desdobramento da seção e o formatter (que não mexe nos bytes da seção) |
| `06-emilia/34` | um passo 5: a emilia sobre o `styled`, com o `e_39b87d03` intacto |
| meta | dois repositórios novos (`botopink/css`, `botopink/styled`), os submódulos em `.gitmodules` e a linha § Layout do `AGENTS.md` (326) |
| emilia, `jhonstart-styled` | `"styled"` em `dependencies` (242) |
| `08-bpp/124` | o scaffold escreve o manifesto em objeto |

## 9. O que ainda precisa ser decidido dentro da proposta

- [ ] **(p1) Como o `Style` chega ao `html` num `.bp`.** É a forma escrita do desdobramento e a que
  um componente `.bp` escreve à mão. (a) `html(style) """…"""`: um template function que recebe um
  valor antes do literal; a 116 mede no passo 0 se a linguagem aceita isso e, se não aceitar, abre
  uma linha no `language-gaps.md`. (b) Um hook, `use scopedStyle(style)`, lido pelo `html` através
  de `@typeInfo(f).hooks` (277). **Recomendo (a)**: é explícito e não depende do contexto do render.
- [ ] **(p2) A forma string `"bpp": "jhonstart"`.** (a) Recusada, apontando para o objeto. (b)
  Aceita como atalho para `{"default": …}`. **Recomendo (a)**: uma forma só (67).
- [ ] **(p3) Quantas seções por arquivo.** (a) No máximo uma com escopo e uma `#[isGlobal]`. (b)
  Uma só. **Recomendo (a)**: o exemplo `Post` do Astro usa as duas.
- [ ] **(p4) O nome `styled` repetido.** O pacote se chama `styled` e a anotação da 301 também
  (`#[styled(..tokens)]`). (a) Os dois ficam; um é pacote, o outro é função da ponte. (b) A anotação
  muda de nome, para `#[emilia(…)]` ou `#[tw(…)]`. **Recomendo (a)**: os dois nunca se encontram no
  mesmo escopo.
- [ ] **(p5) A emilia sem `"bpp".style`.** Uma aplicação que só usa `#[styled]`, sem seção de
  estilo, (a) continua com a folha da emilia porque a ponte registra o sink, ou (b) é obrigada a
  ter `style`. **Recomendo (a)**.
- [ ] **(p6) `@utility` literal.** (a) Recusado no `styled`: o `val` ou a função faz o papel dele,
  como em `compose.bp`. (b) Aceito: `styled "@utility tab-* { tab-size: --value(integer); }"` gera
  uma família tipada `fn(i32) -> Styled`. **Recomendo (a)**: um jeito só de nomear, o do botopink.
- [ ] **(p7) De onde o `@variant` tira os nomes.** O `styled` conhece as pseudo-classes, `dark` e as
  `@custom-variant` importadas. Os breakpoints (`md`, `lg`) estão no tema da emilia (300). (a) A
  emilia exporta as variantes de breakpoint como `@custom-variant` geradas do tema. (b) O `styled`
  ganha um tema próprio. **Recomendo (a)**: o tema continua num lugar só.

## 10. Comparação com as opções que a `08-d` tinha

| Opção | Onde fica o parser | Problema |
|---|---|---|
| (a) `scopeCss` na emilia, pela ponte | emilia | a emilia passa a ter duas entradas (tokens e CSS escrito) e o parser só serve a ela |
| (b) onze-assets no build | onze | sem o onze, não há escopo |
| (c) o `html` do core | jhonstart | um parser de CSS dentro da biblioteca de HTML |
| **(d) esta proposta** | o repositório `css`; os componentes no repositório `styled` | dois repositórios novos (326); muda o formato do manifesto e do `.bpp` |

O que a (d) ganha: um único parser e uma única folha para todo mundo. A emilia vira uma cliente do
`styled` como qualquer outra, e o estilo do componente fica numa seção que o toolchain compila sem
saber de biblioteca nenhuma.
