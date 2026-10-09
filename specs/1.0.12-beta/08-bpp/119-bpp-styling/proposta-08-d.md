# Proposta para a `08-d` — o CSS em três camadas e a seção `--- style ---`

**Estado:** proposta, ainda não decidida. Responde à pergunta `08-d` de
[`decisoes-pendentes.md`](../../decisoes-pendentes.md#08-d--quem-faz-o-escopo-do-css): quem faz o
escopo do CSS e onde mora o parser. Quando for aceita, vira uma decisão numerada em
`decisions-taken.md`, e as frentes 116, 119 e `06-emilia/34` são reescritas a partir dela (§ 8).

## 1. A ideia em uma tela

```text
repository/css      (botopink/css)     a base para construir CSS: lê uma folha, Sheet tipado, scope()
        ▲
repository/styled   (botopink/styled)  a base para construir componentes de CSS: styled "…" → @Component<StyledBase, Styled>
        ▲                          ▲
repository/emilia           jhonstart/jhonstart-styled   ← "bpp".style: compila a seção --- style ---
uma série de componentes           ▲
feitos em styled           #[styled(..)] na tag         ← do jhonstart-styled (p4); o jhonstart-emilia sai
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
| `styled`: a base para construir componentes de CSS | `repository/styled` (`botopink/styled`) | `styled "…"` → `@Component<StyledBase, Styled>` (§ 3.2; `Styled` = classe + regras); a folha que junta os componentes por render ou por build, em `@layer`s | `css`, std | emilia · `jhonstart-styled` |
| emilia: uma série de componentes feitos em `styled` | `repository/emilia` | os tokens, o tema, cada família escrita em `styled "…"`; aplicada na tag pelo `#[styled]` do `jhonstart-styled` (p4) | `styled`, std | ninguém em particular: o `Token` implementa o `Styleable` do `styled`, e a aplicação passa tokens ao `#[styled]` |

**Por que dois repositórios próprios.** Pela decisão 326, um pacote compartilhado novo nasce como
repositório (`botopink/<pkg>`, submódulo em `repository/<pkg>`, ao lado de `http`, `log` e
`validation`) e entra como dependência comum (242), sem ir embutido no compilador. O critério das
115–117 continua: um pacote compartilhado precisa de dois consumidores, e há dois, a emilia e o
`jhonstart-styled`. A 113 proíbe que uma biblioteca nomeie outra. Com um pacote compartilhado, os dois
usam o mesmo código sem que o jhonstart importe a emilia, nem o contrário. `css` e `styled` não
conhecem HTML nem framework.

**Quem conhece o `.bpp`: só o `jhonstart-styled`.** `css`, `styled` e emilia não sabem que o
`.bpp` existe. Eles não leem o manifesto, não conhecem a seção `--- style ---` nem o atributo
`data-s`, e não dependem do jhonstart. Cada um conhece só a sua camada: o `css`, texto de CSS e um id
de escopo qualquer; o `styled`, componentes e a folha; a emilia, tokens e tema. Toda a integração
com o `.bpp` mora no `jhonstart-styled`:

- a `pub default fn` que o `"bpp".style` nomeia e que recebe o texto da seção;
- o id de escopo, tirado do caminho do módulo e da linha da seção;
- os buracos de run-time da seção, que viram variáveis CSS no elemento raiz (p1);
- o estilo ativado com `use` no componente (p1), que o `html` lê pelos hooks;
- a ponte `ElementBase` → `StyledBase`;
- o sink que põe a folha no head.

Trocar de framework, ou usar o `styled` fora de qualquer template, não toca nas três camadas.

**O que acaba.** A emilia deixa de ter um modelo de folha só seu (`Rule`, `Sheet`, `renderRule`,
`renderDocument` em `output.bp:44-593`). Ninguém mais monta texto de CSS com `+`.

## 3. A sintaxe `styled "…"`

`styled` é a `pub default fn` do pacote, um template function como o `html`, sobre
`comptime css: @Expr<string>`. O literal contém declarações, blocos aninhados `&…` e at-rules. Os
valores entram por buracos `${…}`, a interpolação que a linguagem já tem, e por isso as chaves
continuam sendo do CSS.

```bp
import styled from "styled";

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
| `@apply p-4 font-bold;` | um buraco do tipo `StyledView`: `${padAll(4)} ${fontBold}` | as declarações do outro componente entram ali; composição tipada, sem nome de classe em string (281) |
| `@utility tab-4 { tab-size: 4; }` | `pub val tab4 = styled "tab-size: 4;";` | o `val` dá o nome; não precisa de `@utility` |
| `@utility tab-* { tab-size: --value(integer); }` | `fn tab(n: i32) -> StyledView { return styled "tab-size: ${n};"; }` | a função é a família; o tipo do parâmetro faz o papel de `--value(integer)` |
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

### 3.2 Um componente de estilo é um `@Component<StyledBase, Styled>`

Um componente `styled` usa o mesmo modelo de componente da linguagem (decisão 128). O `View` do
jhonstart já funciona assim: `@Component<ElementBase, Element>`, em que `Element implement
@Context<ElementBase>` (276). O pacote `styled` declara o par equivalente:

```bp
// styled/src/styled.bp
pub type StyledBase(…);                                  // a base: a folha do render, a camada
pub type Styled(className: string, rules: string) implement @Context<StyledBase>;
pub type StyledView = @Component<StyledBase, Styled>;    // alias, como o View (276)

pub default fn styled(comptime css: @Expr<string>) -> @ExprCustom<StyledView> { … }
```

```bp
// emilia — Tailwind: @utility p-* { padding: --spacing(--value(integer)); }
fn padAll(n: i32) -> @Component<StyledBase, Styled> {
    return styled "padding: --spacing(${n});";
}
```

O que isso dá:

- **Hooks dentro do estilo.** O corpo pode escrever `use`, com os hooks ancorados em `StyledBase`
  (128). A emilia declara os hooks do seu tema nessa base, e um componente lê o breakpoint do tema
  em vez de copiar o valor. Isso responde ao p7.
  ```bp
  fn container() -> @Component<StyledBase, Styled> {
      val md = use breakpoint("md");          // emilia, sobre StyledBase; um breakpoint apagado é erro (300)
      return styled """
        width: 100%;
        @media (width >= ${md}) { max-width: ${md}; }
      """;
  }
  ```
- **Build ou render, pela mesma regra das páginas.** O `@typeInfo(f).hooks` (277) diz o que o
  componente alcança. Um componente sem hook de run-time é calculado no build (classe e regra
  constantes, nada registrado no render), como uma página `#[page]` é pré-renderizada quando não
  alcança um hook `#[serverOnly]` (202). Com um hook de run-time, ele é calculado por render.
- **Composição como entre componentes.** `${btn}` dentro de outro `styled` é um filho renderizado
  sob a mesma base, como um componente dentro do `html`. O `@apply` do Tailwind vira isso.
- **A ponte com o jhonstart.** Quem recebe a seção `--- style ---` é o `jhonstart-styled`, e não o
  `styled`: a função default dele monta, com o `styled`, a folha com escopo da seção, e o componente a
  ativa com `use` (p1). O `jhonstart-styled` também liga `ElementBase` a `StyledBase` (o papel que o `jhonstart-emilia`
  tem hoje, e que acaba com ele): quando o `html` renderiza a página, os componentes de estilo rodam sob a base
  da página e escrevem na folha dela.

**O custo.** No commonJS, todo retorno `@Component` sai como `async function` (120, 128). Um
componente calculado no build não paga nada. Um componente calculado por render vira uma chamada
assíncrona por uso. Isso é o p9.

## 4. A emilia sobre o `styled`

Hoje a escada do `spacing.bp` monta a string `calc(var(--spacing) * n)` (`spacing(n)`,
`spacingHalf`, `spacingNegHalf`), e `padTokenToCss` (`emilia.bp:3360`) cola o resultado com
`oneDecl` e `axisDecl`. Na proposta, a escada é o `--spacing()` do próprio literal, como no Tailwind,
e cada caso da família é um componente:

```bp
// emilia/src/spacing.bp (ou o bloco da família Pad)
import styled, {StyledView} from "styled";

// Tailwind: @utility p-*  { padding: --spacing(--value(integer)); }
fn padAll(n: i32) -> StyledView { return styled "padding: --spacing(${n});"; }
// Tailwind: @utility px-* { padding-inline: --spacing(--value(integer)); }
fn padX(n: i32) -> StyledView { return styled "padding-inline: --spacing(${n});"; }
// o meio passo vira um valor: --spacing(0.5) → calc(var(--spacing) * 0.5)
fn padAllHalf(n: i32) -> StyledView { return styled "padding: --spacing(${n}.5);"; }
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
ao `html`. O valor vira um `val` do módulo que o componente ativa com `use` (p1). O `html` vê esse
`use` nos hooks da função e escreve `data-s="<id>"` em todo elemento que o template escreve.

| Escrito | Significa |
|---|---|
| `--- style ---` | com escopo: cada seletor ganha `[data-s="<id>"]` |
| `--- style #[isGlobal] ---` | vai para a folha como foi escrito, sem escopo (só se o p3 ficar com (a); com (b), o global é `:global(…)`) |
| `:global(sel)` dentro da seção | `sel` fica sem escopo |
| `${props.color}` dentro da seção | buraco: valor fixo vai para a regra; valor de run-time vira `var(--s-<n>)`, e o elemento raiz ganha `style="--s-<n>: …"` (p1; substitui o `#[defineVars]`) |
| `<style #[isInline]>` na marcação | o builder `style`, verbatim (o comportamento de hoje) |
| `<style>` na marcação, sem `#[isInline]` | erro na tag, apontando para a seção |
| seção sem `"bpp".style` no manifesto | erro na linha: `a --- style --- section needs "bpp.style" in botopink.json` |

O id do escopo, sem hash, é o caminho do módulo mais a linha da seção (`components-post-card-12`),
calculado pelo `jhonstart-styled`; o `css` recebe só a string pronta em `scope(id, css)`.
O build o encurta (124).

## 7. Como o jhonstart junta as peças

| Peça | Dono | Faz |
|---|---|---|
| `pub default fn` de `jhonstart-styled` | membro novo do jhonstart | recebe a seção, aplica o escopo pelo `styled` e devolve um `@Component<StyledBase, Styled>` com escopo (id, folha, vars), ativado com `use` (p1) |
| o sink | `jhonstart-styled` | põe a **única** folha do render no head e em cada fill de boundary: as camadas da emilia e depois as seções com escopo |
| o braço no `html.bp` | core do jhonstart | lê nos hooks da função (277) o `use` de um estilo com escopo, escreve `data-s` e recusa `<style>` sem `#[isInline]` |
| `#[styled(..)]` | `jhonstart-styled` (p4) | aceita tudo o que implementa o `Styleable` do `styled`: componentes da aplicação e tokens da emilia; as regras vão para o mesmo sink. O `jhonstart-emilia` sai (p4) |

A ordem da cascata fica: folhas linkadas (`globals.css`), camadas da emilia, seções com escopo.

Todas as linhas desta tabela são do jhonstart. Nenhuma pede nada novo a `css`, `styled` ou emilia,
que continuam sem saber do `.bpp`.

## 8. O que muda se for aceita

| Onde | Mudança |
|---|---|
| decisões 198, 200, 284 | `"bpp": "jhonstart"` vira `"bpp": {"default": "jhonstart", …}` |
| 212 | o arquivo ganha uma terceira parte, a seção de estilo |
| 270 | o prelúdio é o do pacote em `bpp.default` |
| 278 | `#[defineVars]` sai (buracos, p1); `#[isGlobal]` sai pelo p3 (b) ou vai para a linha da seção pelo (a); `<style>` na marcação só com `#[isInline]` |
| 285 | o toolchain passa a conhecer também o pacote de `style` |
| 301 | os tokens viram componentes `styled`; a folha sai pelo `jhonstart-styled`; pelo p4, o `#[styled(..)]` passa do `jhonstart-emilia` para o `jhonstart-styled` e aceita também componentes da aplicação (a escrita no template não muda); o `jhonstart-emilia` sai |
| `08-bpp/119` | é dona de `repository/css`, `repository/styled` e `jhonstart-styled`, e apaga o membro `jhonstart-emilia` (p4); passos: 1 os pacotes, 2 `jhonstart-styled` e o braço do `html`, 3 boundary, 4 `#[styled]`, 5 uma folha só; no gate, `grep -rn "bpp\|jhonstart"` vazio em `repository/css`, `repository/styled` e `repository/emilia/modules` |
| `08-bpp/116` | manifesto em objeto, o desdobramento da seção e o formatter (que não mexe nos bytes da seção) |
| `06-emilia/34` | um passo 5: a emilia sobre o `styled`, com o `e_39b87d03` intacto |
| meta | dois repositórios novos (`botopink/css`, `botopink/styled`), os submódulos em `.gitmodules` e a linha § Layout do `AGENTS.md` (326) |
| emilia, `jhonstart-styled` | `"styled"` em `dependencies` (242) |
| `08-bpp/124` | o scaffold escreve o manifesto em objeto |

## 9. O que ainda precisa ser decidido dentro da proposta

Cada ponto traz o contexto, as opções com exemplo e a recomendação. As recomendações seguem a
decisão 67: uma forma só, a mais restritiva.

### p1 · Como o estilo chega ao `html` — aceito (09/10): `use`, inline ou por `val`

**O que se pergunta.** Um `.bpp` é outro jeito de escrever um `.bp` (198): o toolchain desdobra o
arquivo em código botopink comum. A marcação vira `return html """…""";`. O p1 é qual código a seção
de estilo vira, ou seja, como o `html` fica sabendo que o template tem um estilo com escopo e precisa
escrever `data-s` nos elementos.

- [x] **Resposta: o componente ativa o estilo com `use`.** O estilo é um `@Component<StyledBase,
  Styled>` (§ 3.2, p8), então ativá-lo é o `use` comum da linguagem (128). O `html` vê esse `use` em
  `@typeInfo(f).hooks` (277), como já vê os outros hooks, e escreve `data-s="<id>"` em todo elemento
  do template **dessa função**.
  ```bp
  import html, {View} from "jhonstart";
  import styled from "jhonstart-styled";          // a função default do pacote que "bpp".style nomeia

  val cardStyle = styled """.title { font-size: 2rem; }""";

  pub default fn (props: Props) -> View {
      use cardStyle;
      return html """<h1 class="title">{props.title}</h1>""";
  }
  ```

**O `.bpp` desdobra nisso.** O arquivo

```bpp
---
type Props(title: string)
---
<h1 class="title">{props.title}</h1>
--- style ---
.title { font-size: 2rem; }
```

vira o estilo direto no `use`, a primeira forma abaixo: a seção vira `use <style> """…""";` no
corpo, depois das instruções do cabeçalho e antes do `return`. Não há `val` com nome gerado. A
forma exata é da 116.

**As duas formas valem, porque são a mesma coisa.** `use` ativa qualquer expressão que seja um
`@Component`; escrever o literal no `use` ou passar por um `val` não muda nada. O `val` serve quando
o estilo é compartilhado entre componentes:

```bp
// inline: o que o .bpp desdobra, e o caso comum num .bp
pub default fn (props: Props) -> View {
    use styled """.title { font-size: 2rem; }""";
    return html """<h1 class="title">{props.title}</h1>""";
}

// por val: um estilo usado por mais de um componente
val cardStyle = styled """.title { font-size: 2rem; }""";
pub fn Card(props: Props) -> View { use cardStyle; return html """…"""; }
pub fn CardSmall(props: Props) -> View { use cardStyle; return html """…"""; }
```

**Buracos com valores do corpo substituem o `#[defineVars]`.** Inline, o literal enxerga `props` e os
`val`s do cabeçalho. Um buraco com valor fixo (comptime) é escrito na regra. Um buraco com valor de
run-time vira uma variável CSS: a regra lê `var(--s-<n>)`, e o elemento raiz do template ganha
`style="--s-<n>: …"`, com o valor escapado. É o que o `define:vars` do Astro faz, sem anotação e sem
lista de nomes. A folha continua uma só para todas as instâncias, e só o atributo `style` muda.

```bpp
---
type Props(color: string)
---
<div class="box">…</div>
--- style ---
.box { border: 1px solid ${props.color}; padding: 1rem; }
```
```html
<!-- regra (uma só, no build):  .box[data-s="box-5"]{border:1px solid var(--s-0);padding:1rem} -->
<div class="box" data-s="box-5" style="--s-0: red">…</div>
```

**O que vem junto:**

- **O escopo é da função que faz `use`.** Um filho que escreve o próprio template não ganha o
  atributo desse pai, como no Astro: um componente filho não é estilizado pelo `<style>` do pai.
- **Mais de um estilo:** `use cardStyle; use layoutStyle;`. Cada um tem o seu id, e o template ganha
  os dois atributos.
- **O valor está disponível quando precisa:** `val s = use cardStyle;` dá o `Styled` (`s.className`,
  `s.rules`).
- **Sem custo novo** (p9): o corpo de um `View` já é um `@Component`. Um `cardStyle` com literal fixo
  é calculado no build.
- **Dois `styled` diferentes.** Neste exemplo, `styled` é a função default do `jhonstart-styled`: um
  literal com seletores, que vira uma folha com escopo. O `styled` do pacote `styled` é o de
  componentes, em que declarações viram uma classe. Um `.bp` que use os dois dá alias a um deles (170).
- **A linha da seção fica sem anotação.** O global é `:global(…)` (p3) e as variáveis são buracos.
  Sobra `--- style ---`, sempre igual.

**As alternativas descartadas:** `html(cardStyle) """…"""` (pedia à linguagem um valor antes do
literal) e uma anotação `#[scoped(cardStyle)]` na tag raiz (uma tag carregando algo que vale para o
template inteiro).

### p2 · A forma string `"bpp": "jhonstart"` — aceito (09/10): (a)

- [x] Só o objeto; a string é recusada, e o erro mostra a forma nova. Uma forma só (67).
  ```text
  "bpp": "jhonstart"
  error: "bpp" is an object — write "bpp": {"default": "jhonstart"}      at the key
  ```

### p3 · Quantas seções de estilo por arquivo

**Contexto.** O exemplo `Post` do Astro tem um `<style>` com escopo e outro `is:global` no mesmo
componente.

- [ ] **(a)** No máximo uma seção com escopo e uma `#[isGlobal]`, nessa ordem.
  ```bpp
  <article><h1 class="title">{props.title}</h1></article>
  --- style ---
  .title { font-size: 2rem; }
  --- style #[isGlobal] ---
  h1 { margin: 0; }
  ```
- [ ] **(b)** Uma seção só; o que é global vai com `:global(…)`.
  ```bpp
  --- style ---
  .title { font-size: 2rem; }
  :global(h1) { margin: 0; }
  ```

**Recomendação: (b).** Com o `:global(…)`, uma seção cobre os dois casos, e o arquivo tem um lugar
só de CSS. A (a) só ganha quando a folha global é grande, e aí ela cabe melhor num `globals.css`.
Isso muda a recomendação anterior, que era (a). Com (b), o `#[isGlobal]` deixa de existir; o
`#[defineVars]` já saiu com o p1 (buracos de run-time viram variáveis CSS), e a linha da seção fica
sem anotação.

### p4 · Aplicar um componente `styled` numa tag — aceito (09/10): (a)

- [x] Um `#[styled(…)]` só, que aceita tudo o que implementa o behavior `Styleable`, tanto os
  componentes da aplicação quanto os tokens da emilia.
  ```bp
  <button #[styled(btn, .Pad.All.4, .Text.Bold)]>Salvar</button>
  ```

**Onde cada peça fica:**

| Peça | Hoje (301) | Com o p4 (a) |
|---|---|---|
| a anotação `#[styled(…)]` | `jhonstart-emilia` (a ponte) | `jhonstart-styled`; não vai para o pacote `styled`, que não conhece tag nem HTML |
| `behavior Styleable { fn toStyled(self: Self) -> StyledView; }` | — | pacote `styled` |
| `Token implement Styleable` (cada token → o seu componente `styled`) | — | emilia, que importa o `styled` e continua sem conhecer tag, jhonstart ou `.bpp` |
| `StyledView implement Styleable` | — | pacote `styled` |
| o plugin de flush da folha da emilia (`jhonstart-emilia/src/root.bp:95`) | `jhonstart-emilia` | sai: a folha da emilia é a do `styled`, escrita pelo sink do `jhonstart-styled` |

**O `jhonstart-emilia` deixa de existir** (aceito em 09/10). A anotação vai para o
`jhonstart-styled`, o flush some, e o `class={emilia(tokens)}` já saiu dos templates pela 301. A
aplicação depende do `jhonstart-styled` e da emilia, e a ligação entre os dois é o behavior do
`styled`; nenhum membro do jhonstart nomeia a emilia. Como continua valendo da 301: a escrita no template não muda, a ordem da lista
é a identidade da classe (`contracts.md` § 4), e a lista é comptime (280), com a checagem de
breakpoint da 300.

### p5 · O `#[styled]` numa aplicação sem `"bpp".style` — resolvido (09/10)

- [x] A pergunta partia de uma premissa errada: a emilia não conhece o `.bpp`, então nada nela
  depende do manifesto. Com o p4 (a), a anotação é um import comum do `jhonstart-styled`, e funciona
  com ou sem a chave. `"bpp".style` só diz ao toolchain quem compila a seção `--- style ---`, e é
  exigido só quando o arquivo tem uma.
  ```json
  { "bpp": { "default": "jhonstart" },
    "dependencies": { "jhonstart": {…}, "jhonstart-styled": {…}, "emilia": {…} } }
  ```
  ```bpp
  <h1 #[styled(.Text.Bold)]>Oi</h1>        // compila: a folha sai pelo sink do jhonstart-styled
  --- style ---                            // error: a --- style --- section needs "bpp.style"
  ```

### p6 · `@utility` literal no `styled`

**Contexto.** No Tailwind, `@utility` dá nome a um utilitário, e `--value()` transforma o nome numa
família. No botopink, o nome vem do `val` ou da função, e a família é uma função com parâmetro.

- [ ] **(a)** Recusado; o `val` ou a função faz o papel dele.
  ```bp
  pub val tab4 = styled "tab-size: 4;";
  fn tab(n: i32) -> StyledView { return styled "tab-size: ${n};"; }
  // styled "@utility tab-* { … }"  →  error: name a component with a val or a function   at @utility
  ```
- [ ] **(b)** Aceito: o literal gera uma família tipada a partir do `--value()`.
  ```bp
  pub val tab = styled "@utility tab-* { tab-size: --value(integer); }";   // tab: fn(i32) -> StyledView
  tab(4)
  ```

**Recomendação: (a).** Um jeito só de dar nome, o da linguagem, como o `compose.bp` da emilia já faz.
A (b) faria o tipo de um `val` depender de uma string de CSS.

### p7 · De onde vêm os breakpoints

**Contexto.** O `styled` conhece as pseudo-classes, `dark` e as `@custom-variant` que estão em
escopo. Os breakpoints (`md`, `lg`) estão no tema da emilia (300), que o `styled` não conhece.

- [ ] **(a)** Por hook: a emilia declara `use breakpoint(name)` sobre `StyledBase` (§ 3.2).
  ```bp
  fn container() -> StyledView {
      val md = use breakpoint("md");          // breakpoint apagado no tema: erro de compilação (300)
      return styled "width: 100%; @media (width >= ${md}) { max-width: ${md}; }";
  }
  ```
- [ ] **(b)** A emilia exporta `@custom-variant` geradas do tema, e o literal escreve `@variant md`,
  como no Tailwind.
  ```bp
  import {variants.md} from "emilia";
  pub val container = styled "width: 100%; @variant md { max-width: 48rem; }";
  ```
- [ ] **(c)** O `styled` ganha um tema próprio, separado do da emilia.
  ```bp
  pub val container = styled "width: 100%; @media (width >= --breakpoint(md)) { … }";
  ```

**Recomendação: (a).** O tema continua num lugar só, o mesmo hook lê qualquer valor do tema (cor,
raio, fonte), e o valor é comptime quando o tema é, então o componente ainda sai no build (p9). A (b)
é mais curta, mas cria um segundo canal para o mesmo dado. A (c) duplica o tema.

### p8 e p9 · aceitos em 09/10

- [x] **(p8) Os nomes — aceito (09/10): (a).** `StyledBase`, `Styled`, `StyledView`, no padrão do
  jhonstart (`ElementBase` é o nome do valor seguido de `Base`).
- [x] **(p9) O custo no commonJS — aceito (09/10): (a).** Um componente de estilo calculado por
  render é uma `async function` (120, 128); só paga quem usa hook de run-time. O caso comum, sem
  hook ou só com hooks do tema, é calculado no build.

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
