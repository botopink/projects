# Decisões pendentes — 1.0.12-beta

**108 perguntas e 6 contradições estão abertas, e 100 escolhas de implementação aguardam confirmação** (contadas das
entradas abaixo: uma pergunta com letra, sendo `nat-d` e `nat-f` títulos de seus casos; `ctr-*` e `119-a` as
contradições; uma linha de uma tabela de escolhas, ou uma entrada `#####` ao lado dela).

- Uma resposta vai para [`decisions-taken.md`](decisions-taken.md) sob o próximo número livre (mantido
  só lá); um id com letra nunca é renumerado nem reutilizado.
- Toda recomendação é a leitura mais restritiva, sem configuração que a contorne (decisão 67).
- Uma frente que encontra uma pergunta que não consegue responder pelo código a acrescenta aqui: id · título · Medido
  (observado, re-executável) · Opções · Recomendação · Bloqueia. *Proposta* = levantada sem id.

- **Bloqueando agora** — prioridade máxima: as perguntas que seguram hoje o trabalho da máquina 2, as que mais bloqueiam primeiro; um índice de entradas mantidas nas suas seções.
- **Bloqueando agora — máquina 1 e frente 165** — o mesmo para os passos da máquina 1 e a frente 165.
- **Máquina 1** — prioridade máxima: as perguntas que a máquina 1 da frente 144 espera, por passo.
- **Máquina 2** — prioridade máxima: as perguntas que a máquina 2 da frente 144 espera, as mais urgentes primeiro. O desenvolvimento novo está centrado na frente 164 wasm-gc (s1 → s4, wasmtime-a, wasmgc-a).
- **Frente 165** — rakun-workspace: um repositório `rakun`, 17 pacotes plug-and-play (mono-a).
- **Parte 1** — o que bloqueia a frente 144 (`repository/botopink-lang`, decisão 433: os passos abertos das antigas trilhas
  `00-gate`, `01-compiler`, `02-std-and-packaging`, `03-bundled-libs`), por antiga trilha, depois as
  escolhas de implementação dessas trilhas que aguardam confirmação.
- **Parte 2** — o resto (trilhas 04–10, 20, propriedade, contradições que não bloqueiam nenhum passo 00–03).
- **Parte 3** — as escolhas de implementação das trilhas 04–09.

A página em português (`decisoes-pendentes.md`) é a tradução direta desta página: o texto em inglês guarda o sentido
(`AGENTS.md` da meta § Conventions). Ids respondidos saem deste arquivo; `decisions-taken.md` guarda as respostas e o próximo
número livre, que é **629**.

## Bloqueando agora — prioridade máxima (máquina 2, 2026-10-15)

As perguntas que seguram hoje o trabalho da máquina 2, as que mais bloqueiam primeiro. Cada uma é explicada aqui em
poucas linhas — o problema, um exemplo, as opções, a recomendação e por quê — e a sua entrada completa (Medido, todas as
opções) fica na § Máquina 2. Marque uma opção por pergunta (`[x]`); o coordenador transforma a resposta marcada numa decisão, e a pergunta sai desta lista.

Nenhuma pergunta segura o trabalho da máquina 2 hoje; as abertas seguram uma linha cada, ou nada construído (§ Máquina 2).

## Bloqueando agora — máquina 1 e frente 165 (2026-10-15)

As perguntas que seguram hoje os passos da máquina 1 e a frente 165, as que mais bloqueiam primeiro. Cada entrada fica na sua seção; esta tabela as indexa e sai quando são respondidas. Com a § Bloqueando agora — máquina 2 acima, estas são as perguntas a responder primeiro.

| # | Pergunta | O que decide | Trava | Recomendação |
|---|---|---|---|---|
| 1 | **50-b** — o que o servidor de dev (`onze dev`, agora rakun-ssr) faz numa mudança (§ Parte 2, 07-onze) | se o servidor de dev reinicia a partir de um build novo a cada mudança ou carrega a quente os módulos mudados | 50 passo 2; 53 passo 6 | (a) `build` e depois `start` a cada mudança |
| 2 | **b140-a** — a linhagem de spread de um tipo derivado quando `compiler.buildType` recebe texto (§ Máquina 1) | se `buildType` recebe `from:` ou se o spread a partir da fonte de um tipo derivado sai | a peça de tipos derivados do B-140 | (a) `from:` em `buildType` |
| 3 | **b140-b** — qual módulo da std declara `DeclAnnotation` (§ Máquina 1) | o ciclo de imports `types.bp` ↔ `compiler.bp` | a primeira peça do B-140 | (a) `types.bp` |
| 4 | **165-d** — código calculado no build sem `@emit` (§ Máquina 1) | se um decorator emenda um valor construído (`compiler.build`) num membro, ou se o `addMember` string fica | a remoção do `addMember` string do B-140; os dez membros calculados do rakun | (a) `compiler.build` no corpo de um decorator |

Abertas e sem travar nada (frente 165): **165-b** (três nomes de pacote), **548-a** (toda biblioteca linka seu código),
**548-b** (os nomes de código que guardam o nome de uma biblioteca antiga), **B-98-a** (um `.bp` e um `.d.bp` de mesmo
stem, construído como recusado), **B-99-c** (a própria raiz de uma dependência chamando um default de catálogo, construído como recusado). **B-99-e** (onde fica um argumento do chamador que quebra um corpo genérico expandido, construído no argumento).

---

## Máquina 1 — prioridade máxima (frente 144, `machine-1/144-checker/`)

As perguntas que os passos da máquina 1 esperam (lane A, B-19, B-22, B-23, B-24, B-25, B-27, B-55, B-60, o grupo do
modelo de módulos), respondidas antes de toda outra parte desta página; na ordem dos passos que travam.

#### B-02-c · `"std:…"` escrito em `@External.Node` / `@External.Erlang`: código de host, ou recusado como os outros prefixos? (decisões 305, 481; 144 B-02)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): recusado em todo target, nomeando a forma rotulada** — o `conformance/docs.md` § Host bindings já diz que as quatro strings com prefixo são recusadas no argumento em todo target; uma string que se lê como cell e roda como código de host é a ambiguidade que a 305 removeu. Muda: `checkExternalCells` recusa `"std:"` fora do wasm também; uma cell.
- **Medido.** `checkExternalCells` recusa `"std:…"` só em `@External.Wasm`; no Node e no Erlang é código de host ("`std:` was only ever a wasm cell").
- **Opções.**
  (a) Recusado em todo lugar.
  ```bp
  #[@External.JavaScript("std:hash.contentHash")]   // refused: a `std:` cell is `@External.Wasm`'s
  ```
  (b) Código de host fora do wasm, o texto corrigido.
  ```bp
  #[@External.JavaScript("std:hash.contentHash")]   // JavaScript source `std:hash.contentHash`
  ```
- **Recomendação.** (a).
- **Trava.** A linha do `std:` do 144 B-02.

#### B-10-b · `Decl.variants`: o que uma entrada carrega, incluindo uma seção? (decisões 268, 298; 144 B-10 G1)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): `Variant(name, fields: Field[], annotations, section: ?string)`** — uma variante com payload lista seus campos como `decl.fields`; uma seção não é entrada, suas variantes carregam o nome da seção. Uma entrada por variante construível.
- **Medido.** `Decl.variants` carrega só nomes, com as seções listadas entre eles.
- **Opções.**
  (a) Entradas tipadas, seções como campo.
  ```bp
  decl.variants[0].fields[0].name   // "amount"
  ```
  (b) Como hoje: nomes.
  ```bp
  decl.variants[0]   // "Paid" — a name, sections among them
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-10.

#### B-10-c · `clock.formatIso8601`: qual texto é a resposta única? (decisão 497; 144 B-10 G1)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): sempre milissegundos, `.sssZ`** — `2026-10-12T20:31:02.000Z` em todo target; uma largura fixa ordena como texto e é lida de volta por uma regra só.
- **Medido.** o commonJS responde sempre `.sssZ` (o `toISOString` do node); o erlang nunca escreve milissegundos.
- **Opções.**
  (a) Sempre `.sssZ`.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02.000Z
  ```
  (b) Milissegundos só quando não são zero.
  ```bp
  clock.formatIso8601(t)   // 2026-10-12T20:31:02Z, .123Z only when nonzero
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-10.

#### B-10-e · Como um alias de tipo de `@Component<Styled>` implementa um behavior? (144 B-10 G2)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(b): não implementa — um alias é o seu alvo**: `Styleable` é implementado por `Styled`, e `@Component<Styled>` chega a ele por `R`; um alias não declara nada (um segundo nome, não um tipo). O marcador do styled é reescrito sobre a implementação de `Styled`.
- **Medido.** `pub val StyledView = @Component<Styled>` não aceita `implement`; não existe grafia.
- **Opções.**
  (a) Um alias com `implement`.
  ```bp
  pub val StyledView = @Component<Styled> implement Styleable;
  ```
  (b) Só o tipo alvo implementa.
  ```bp
  pub type Styled(…) implement Styleable { … }   // StyledView reaches it
  ```
- **Recomendação.** (b).
- **Trava.** A linha do 144 B-10.

#### B-10-f · Como um decorator lê se o `R` de um retorno `@Component<R>` implementa `@Renderable`? (decisões 268, 280; 144 B-10 G3)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): pelo `@typeInfo` do retorno declarado** — `@typeInfo(decl.returnType).implements(@Renderable)`; `@Decl` continua sendo o handle de uma declaração e perguntas de tipo passam por `@typeInfo`, a única reflexão de um tipo. Viável: `decl.returnType` como valor de tipo (hoje um nome) e `TypeInfo.implements(B)`. Muda: dois membros; o marcador do jhonstart em `client.bp` sai.
- **Medido.** Nenhuma reflexão responde: `decl.returnType` é o nome do tipo como texto, e nenhum membro pergunta se um tipo implementa um behavior.
- **Opções.**
  (a) `@typeInfo` do tipo de retorno.
  ```bp
  if (!@typeInfo(decl.returnType).typeArg(0).implements(@Renderable)) decl.fail("…");
  ```
  (b) Um membro de `@Decl`.
  ```bp
  if (!decl.returnImplements(@Renderable)) decl.fail("…");
  ```
- **Recomendação.** (a).
- **Trava.** A linha do `@Renderable` do 144 B-10 G3.

#### B-10-g · Um template declarado `-> @ExprCustom<View>` cujo código construído é um `Element`: a expansão é um `View`? (decisões 275, 276; 144 B-10 G3)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): sim — a expansão é o que o template declara** — o `html` declarado `-> @ExprCustom<View>` responde um `View` (`@Component<Element>`), e um `Element` construído é checado contra ele como corpo de um componente; o `renderNode(html …)` do jhonstart e os seus componentes `-> Element` passam para `View`. O tipo declarado de um template é o tipo da sua chamada (426); manter `Element` na chamada tornaria a declaração decorativa. Viável: a checagem do código construído contra `View` aceita um `Element` como resposta de um componente. Muda: os componentes do jhonstart (um commit de consumidor), uma cell.
- **Medido.** Com `-> @ExprCustom<View>` toda expansão do `html` falha `expected Component, got Element`.
- **Opções.**
  (a) Um `View`.
  ```bp
  fn Card() -> View { html`<div/>` }   // the expansion is a View
  ```
  (b) A chamada mantém `Element`.
  ```bp
  fn Card() -> Element { html`<div/>` }   // the declared View ignored at the call
  ```
- **Recomendação.** (a).
- **Trava.** A linha do `@ExprCustom<View>` do 144 B-10 G3.

#### B-11-a · `decl.wrapWith(f)`: o wrapper é só um lambda escrito na chamada, ou qualquer valor do tipo da chamada? (decisão 316; 144 B-11)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): um lambda escrito na chamada** — `decl.wrapWith({ call -> … })`; qualquer outra expressão é `decorator-wrap-not-lambda`, localizado no argumento. É a regra da 370 (2) para uma função membro que um decorator adiciona: o código que o decorator escreve é checado como o do programa, nunca um valor calculado no build. Viável: como construído. Muda: nada.
- **Medido.** Construído como (a). O tipo da chamada é interno (`__Decl__Call<A, R>`, um por função embrulhada), então um helper que devolve um wrapper (`cachedCall(cache)`) não consegue nomear o tipo do seu parâmetro; (b) precisaria desse tipo nomeável.
- **Opções.**
  (a) Um lambda na chamada.
  ```bp
  decl.wrapWith({ call -> cachedCall(cache, { -> call.run() }) });   // accepted
  decl.wrapWith(cachedCall(cache));                                  // refused: decorator-wrap-not-lambda
  ```
  (b) Qualquer valor de um tipo de chamada nomeável.
  ```bp
  fn cachedCall<A, R>(cache: Cache<R>) -> fn(call: Decl.Call<A, R>) -> R { … }
  decl.wrapWith(cachedCall(cache));                                  // accepted
  ```
- **Recomendação.** (a).
- **Trava.** A linha do wrapper do 144 B-11.

#### B-11-b · `decl.wrapWith` pode embrulhar uma função genérica ou um membro de um tipo genérico? (decisão 316; 144 B-11)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(b): sim, como uma linha do 144** — o wrapper é checado contra a assinatura com seus parâmetros de tipo, e a função embrulhada continua genérica. A 316 não nomeia exceção para genéricos, e um cache ou um retry é tão útil em `fn byId<T>(…)`. Viável: o tipo de chamada gerado recebe os parâmetros de tipo da função. Muda: uma cell; `decorator-wrap-generic` sai.
- **Medido.** Uma função ou dono genérico é recusado hoje, `decorator-wrap-generic`, localizado no decorator.
- **Opções.**
  (a) Recusado, como construído.
  ```bp
  #[counted] fn first<T>(xs: T[]) -> ?T { … }   // refused: decorator-wrap-generic
  ```
  (b) Embrulhado, genérico.
  ```bp
  #[counted] fn first<T>(xs: T[]) -> ?T { … }   // wrapped; first<i32>, first<string> both counted
  ```
- **Recomendação.** (b).
- **Trava.** A linha genérica do 144 B-11.

#### B-14-b · Em que ordem a fonte de um spread e os valores rotulados são avaliados? (decisão 359 (3), (6); 144 B-14)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): na ordem escrita** — todo argumento, a fonte de um spread incluída, é avaliado da esquerda para a direita como escrito, uma vez; os campos então se aplicam da esquerda para a direita, o posterior vencendo (359 (3)). Os argumentos de uma chamada são avaliados na ordem escrita em todo outro lugar; um spread não é exceção. Viável: `infer.inferRecordSpread` liga todo argumento com efeito colateral a um local na ordem escrita, não só a fonte. Mudanças: uma célula cuja fonte e um valor rotulado imprimem.
- **Medido.** Uma fonte que não é um nome é ligada uma vez antes da chamada, então é avaliada antes de todo valor rotulado, mesmo um escrito antes dela: `Pessoa(nome: say("n"), ...make())` imprime `make` e depois `n`.
- **Opções.**
  (a) Ordem escrita.
  ```bp
  val p = Pessoa(nome: say("n"), ...make());   // prints n, then make
  ```
  (b) As fontes primeiro, depois os valores rotulados (como construído).
  ```bp
  val p = Pessoa(nome: say("n"), ...make());   // prints make, then n
  ```
- **Recomendação.** (a).
- **Bloqueia.** A linha de ordem do 144 B-14.

#### B-15-a · Como um corpo de template constrói o `@Decl` de uma tag e roda a sua anotação? (decisão 302; 144 B-15)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): `q.tagDecl(kind, name, attrs)` e `q.annotate(decl, at: Span)`, como construído** — a captura (`q`) constrói o handle e roda a anotação escrita num span do seu próprio texto, resolvida no escopo de quem chama, com os argumentos checados ali; o texto da anotação é lido do span, nunca passado como string (281). Os dois ficam na captura porque só ela conhece o escopo e o texto de quem chama. Viável: como construído (a execução para com `need`, o compilador roda a anotação, o corpo roda de novo com a resposta). Muda: nada.
- **Medido.** Construído como (a); o `html` do `jhonstart` usa (`#[isRaw]` grava `RawBody`).
- **Opções.**
  (a) Na captura.
  ```bp
  val d = q.tagDecl(.Element, "div", attrs);
  q.annotate(d, at: ann.span);
  val names = d.metaAll(ClassName);
  ```
  (b) Funções livres no namespace `template` da std.
  ```bp
  val d = template.tagDecl(q, .Element, "div", attrs);
  template.annotate(q, d, ann.span);
  ```
- **Recomendação.** (a).
- **Trava.** A linha da grafia do 144 B-15.

#### B-15-b · O `Binding` de um corpo de template carrega o seu `Decorator`, para `Decorator.same`? (decisões 268, 302, 371; 144 B-15)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(b): não — a meta é lida pelo tipo** — um corpo de template distingue anotações pela meta que gravam (`d.meta(RawBody)`), como diz a 302; `Binding` não carrega `Decorator`, e a caixa do B-15 que nomeia `Decorator.same` sai. Uma só forma de identificar o que uma anotação fez, pela sua resposta tipada, não por qual função ela era. Viável: como construído. Muda: o texto da caixa.
- **Medido.** `Binding` (um nome procurado num corpo de template) não tem `Decorator`; o `html` lê a meta pelo tipo.
- **Opções.**
  (a) `Binding.decorator`.
  ```bp
  if (b.decorator?.same(isRaw)) { … }
  ```
  (b) Pelo tipo da meta.
  ```bp
  if (d.meta(RawBody) != null) { … }
  ```
- **Recomendação.** (b).
- **Trava.** A linha do `Decorator.same` do 144 B-15.

#### B-15-c · Uma anotação pode ler a meta que uma anotação anterior gravou na mesma declaração ou tag? (decisões 298, 302; 144 B-15)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): não, como construído** — dentro de um decorator, `decl.meta(T)` é recusado; a meta de uma declaração é lida pelo código que a consome (`@typeInfo(X).meta(T)`, um corpo de template sobre `d.meta(T)`), depois de toda anotação rodar. As anotações então não dependem da ordem em que foram escritas. Viável: como construído. Muda: nada.
- **Medido.** `d.meta(T)` no próprio parâmetro `@Decl` de um decorator é recusado.
- **Opções.**
  (a) Recusado dentro de um decorator.
  ```bp
  pub fn raw(comptime decl: @Decl) { decl.meta(ClassName); }   // refused
  ```
  (b) Lido, na ordem das anotações.
  ```bp
  pub fn raw(comptime decl: @Decl) { if (decl.meta(ClassName) != null) decl.fail("…"); }
  ```
- **Recomendação.** (a).
- **Trava.** A linha da leitura de meta do 144 B-15.

#### B-17-a · Um corpo que roda no build chama uma função host com forma de build: permitido? (decisões 376 (4), (5), 341, 434, 451 (3), 452; 144 B-17)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): uma função host com forma de build (cell `std:`, `@External.Wasm` `fn:`) é `Any`; o run-in-build recusa só as outras**, substituindo `comptime-host-cell-unavailable` pela mensagem da 376. A 434/452 tornaram exatamente essas chamáveis no build; a 376, escrita antes delas, desfaria isso.
- **Medido.** `decorator_host_cells`, `comptime_std_host_function`, `comptime_random_seeded`, `decorator_random_seeded_commonjs` chamam funções host com forma wasm no build e passam; a 376 como escrita as recusa.
- **Opções.**
  (a) Uma forma de build faz `Any`.
  ```bp
  comptime { random.seeded(1).next() }   // accepted: random has a std: cell
  ```
  (b) A 376 como escrita.
  ```bp
  comptime { random.seeded(1).next() }   // refused: a Run function at build
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-b · Como se escreve o estágio de uma função? (decisão 376 (4); 144 B-17)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): `#[@Stage.Any]`, como construído** — `pub type Stage { Build, Run, Any }` em `builtins.d.bp`; só `Any` é escrito (Build e Run decorrem dos recursos), então `#[@Stage.Build]` / `#[@Stage.Run]` são recusados como anotações desconhecidas.
- **Medido.** Construído como (a); as funções host do `math` da std o carregam.
- **Opções.**
  (a) `#[@Stage.Any]`.
  ```bp
  #[@Stage.Any] pub declare fn sqrt(x: f64) -> f64;
  ```
  (b) `#[pure]`.
  ```bp
  #[pure] pub declare fn sqrt(x: f64) -> f64;
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-c · O que é o recurso `Build`: a leitura de um parâmetro comptime, ou qualquer `@typeInfo`? (decisões 364, 376 (1); 144 B-17)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): a leitura de um parâmetro comptime `@Decl` / `@Expr`**; `@typeInfo(NamedType)` é uma constante de build, dobrada, não um recurso. Senão todo `main` que lê a meta de um tipo vira `Build` e não roda.
- **Medido.** Construído como (a); `comptime t: type` é recusado (364).
- **Opções.**
  (a) Parâmetro comptime.
  ```bp
  fn main() { @print(@typeInfo(User).fields.length) }   // Any: a constant
  ```
  (b) Qualquer `@typeInfo`.
  ```bp
  fn main() { @print(@typeInfo(User).fields.length) }   // Build: refused at run
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-d · O estágio segue só declarações? (decisão 376 (2); 144 B-17)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): sim** — o estágio de uma chamada é o da declaração chamada; uma chamada de método ou por um valor de função não acrescenta nada (`Any`); um corpo de run que chama uma função comptime-`@Expr` e lê o relógio é `build-and-run`, como a 376 escreve.
- **Medido.** Construído como (a).
- **Opções.**
  (a) Só declarações.
  ```bp
  fn main() { val f = clock.now; f() }   // Any: a function value adds nothing
  ```
  (b) Valores de função também.
  ```bp
  fn main() { val f = clock.now; f() }   // Run: the value's declaration counted
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-e · Um raise ao dobrar uma expressão no build: sempre um erro de build? (decisão 380 (2); 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): sim, como a 380 (2) escreve — depois que as primitivas do runtime de comptime responderem como os targets** (essa linha antes); até lá a dobra fica limitada ao que o runtime responde certo, para nenhuma resposta errada virar erro de build.
- **Medido.** Como construído só erros aritméticos (badarith) são erros de build; qualquer outro raise deixa o hole para renderizar.
- **Opções.**
  (a) Todo raise um erro de build, depois da linha do runtime.
  ```bp
  val h = "${parse("x")}";   // build error: the raise named
  ```
  (b) Só erros aritméticos.
  ```bp
  val h = "${parse("x")}";   // left to run
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-f · Qual função `Any` a 380 dobra no build? (decisões 376, 380; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): como construído** — uma função `Any` que não escreve `@panic` / `@todo` / `throw`, nem `@print`, nem `var` de módulo, nem chamada por valor de função, nem método de tipo declarado; as suas chamadas por outras funções assim também dobram.
- **Medido.** Construído como (a) (`hole_any_call_at_build`, `hole_any_call_raises`).
- **Opções.**
  (a) Como construído.
  ```bp
  fn shout(s: string) -> string { s.toUpper() }   // folded
  ```
  (b) Toda função `Any`.
  ```bp
  fn logShout(s: string) -> string { @print(s); s.toUpper() }   // folded too
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-g · Onde uma leitura de contexto encontra um default declarado num módulo que ela nem importa nem alcança pelo seu tipo? (decisões 378, 379; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): no próprio módulo do tipo ou num módulo já analisado; senão recusada na leitura, nomeando o tipo** — um default é encontrado onde o programa o vê, nunca por uma busca no programa inteiro.
- **Medido.** Não construído; o passo 6 espera por isso.
- **Opções.**
  (a) O módulo do tipo ou um analisado, senão recusada.
  ```bp
  use context<Theme>();   // refused: no default for Theme visible here
  ```
  (b) Qualquer módulo do programa.
  ```bp
  use context<Theme>();   // the default found in any module
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-h · As funções host só-`op:` do math no build: ganham cells `std:`? (decisões 452, 481; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): sim — uma cell de binding `std:` por função no std-wasm** (`floor`, `abs`, `trunc`, `sqrt`, `minF`, `maxF`), para o runtime de comptime as responder e elas dobrarem (380); um opcode não tem forma de host no build de outro jeito.
- **Medido.** São recusadas no build (452) e não são mais tratadas como dobráveis.
- **Opções.**
  (a) Uma cell `std:` cada.
  ```bp
  val r = "${math.sqrt(16.0)}";   // computed at build
  ```
  (b) Só em runtime.
  ```bp
  val r = "${math.sqrt(16.0)}";   // computed at run time
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-i · Confirmar `Context<T>(contextValue)` e um contexto reduzido ao seu valor puro em runtime (decisões 378, 379; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): como construído** — o `Context<T>` da std guarda `contextValue: T`; em runtime um contexto é o seu valor puro, então um contexto `f64` / `i64` cruza o scope do wasm como qualquer valor.
- **Medido.** Construído como (a).
- **Opções.**
  (a) Como construído.
  ```bp
  pub val Theme = createContext(Light);   // at run time: the value Light
  ```
  (b) Um record mantido em runtime.
  ```bp
  pub val Theme = createContext(Light);   // at run time: Context(contextValue: Light)
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-j · Contextos chaveados pelo nome declarado do tipo ou pelo módulo e nome? (decisões 310, 379; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): por módulo e nome** — dois tipos de mesmo nome de dois pacotes são dois tipos (310), então são dois contextos; as chaves do sheet do styled continuam batendo entre pacotes porque nomeiam um tipo só, o do styled.
- **Medido.** Construído chaveado pelo nome declarado: dois tipos de mesmo nome de dois pacotes compartilham uma chave e caem em `context-declared-twice`.
- **Opções.**
  (a) Por módulo e nome.
  ```bp
  import {a.Theme as A}; import {b.Theme as B};   // two contexts
  ```
  (b) Pelo nome declarado, como construído.
  ```bp
  import {a.Theme as A}; import {b.Theme as B};   // refused: context-declared-twice
  ```
- **Recomendação.** (a).
- **Trava.** A linha do 144 B-17.

#### B-17-m · Um tipo que implementa um behavior só por um bloco de extensão: um valor desse behavior? (decisões 379, 416; 144 B-17)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(b): recusado, como construído** — um bloco de extensão (`Sym implement B for T`) acrescenta métodos onde o bloco é visível; não faz de `T` um valor `B` para um parâmetro, um retorno ou um contexto, já que nenhum backend despacha uma chamada de behavior para o bloco. A leitura mais estrita; aceitar significaria despacho de behavior para os métodos do bloco nos quatro targets.
- **Medido.** Recusado em todo lugar (contextos e parâmetros tipados `B`); um teste que o aceitava abortou no commonJS, erlang e beam, e o wasm o recusou.
- **Opções.**
  (a) Aceito, despachado para o bloco.
  ```bp
  Sym implement Shape for Circle { … }
  fn draw(s: Shape) { … }  draw(Circle(r: 1));   // accepted
  ```
  (b) Recusado.
  ```bp
  draw(Circle(r: 1));   // refused: Circle does not implement Shape
  ```
- **Recomendação.** (b).
- **Trava.** A linha do bloco de extensão do 144 B-17.

#### B-18-a · Como um método de template é encontrado: por um nome no escopo de quem chama, ou pelo tipo do receptor? (decisões 397, 415; 144 B-18)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): por um nome no escopo de quem chama, como construído** — `value.method "…"` resolve `method` como um template cujo `self` recebe o receptor, local ou importado; nada alcança o template de uma biblioteca sem import, como todo outro nome. O tipo de um receptor nunca importa código sozinho. Muda: o exemplo do 145 importa `query`.
- **Medido.** Construído como (a); o exemplo do 145 escreve `self.db.query """…"""` sem import de `query`.
- **Opções.**
  (a) Um nome no escopo.
  ```bp
  import {query} from "query";
  self.db.query """select …"""
  ```
  (b) Pelo tipo do receptor.
  ```bp
  self.db.query """select …"""   // erika's query found through Db, no import
  ```
- **Recomendação.** (a).
- **Trava.** A linha do lookup do 144 B-18; o exemplo do 145.

#### B-18-b · Confirmar a superfície do B-18: o texto de `q.note`, `bindings()` como `Decl[]`, `@Decl.module` em todo handle (decisões 415, 426; 144 B-18)
- **Proposto (opus, 2026-10-12; aguardando o mantenedor):** **(a): como construído** — uma nota é acrescentada à linha do mismatch como `— note: …`, então a linha `refused` de uma cell a fixa; `bindings()` responde `Decl[]` e `Binding.ref()` sai com o record `Binding` (um handle só, o `@Decl`); todo `@Decl` carrega `module`, não só um procurado.
- **Medido.** Construído como (a).
- **Opções.**
  (a) Como construído.
  ```bp
  // error: type mismatch: expected User, got Order — note: the query selects from orders
  ```
  (b) Uma nota na sua própria linha, `Binding` mantido ao lado de `Decl`.
  ```bp
  // error: type mismatch: expected User, got Order
  //   note: the query selects from orders
  ```
- **Recomendação.** (a).
- **Trava.** A linha da superfície do 144 B-18.

#### B-27-d · O `botopink format` mantém um nome entre crases que já é um identificador? (decisão 561; 144 B-27)
- **Proposta (opus, 2026-10-15; construída como (a), aguardando o mantenedor):** (a): o formatter escreve `` `count` `` como `count`.
- **Contexto.** A decisão 561 faz de `` `text` `` um identificador, e um nome que é um identificador válido significa o mesmo escrito de qualquer jeito (`` `count` `` é `count`). O formatter imprime o programa de volta; a pergunta é se ele mantém as crases que o autor escreveu em volta de um nome simples.
- **Medido.** O lexer transforma `` `count` `` no identificador simples `count`, então a árvore não sabe mais que as crases foram escritas, e o `botopink format` imprime `count`. Um nome que não é identificador (`` `not-found` ``, `` `fn` ``) mantém as crases.
- **Opções.**
  (a) ★ Como construído: o formatter escreve a grafia simples; as crases ficam só onde o nome precisa delas.
  ```bp
  val `count` = 1;   // botopink format →  val count = 1;
  ```
  (b) Mantidas como escritas: a árvore lembra a grafia.
  ```bp
  val `count` = 1;   // botopink format →  val `count` = 1;
  ```
- **Recomendação.** (a): uma grafia para um nome, como as outras reescritas do formatter.
- **Bloqueia.** Nada.

#### B-27-e · No erlang, `not-found.bpp` e `not_found.bp` viram o mesmo nome de módulo (decisões 561, 109; 144 B-27)
- **Proposta (opus, 2026-10-15; aguardando o mantenedor):** (a): o átomo do módulo erlang é escrito entre aspas a partir do nome do arquivo como escrito, então os dois nunca se encontram.
- **Contexto.** A decisão 561 deixa importar um arquivo cujo nome não é identificador (`not-found.bpp`) e pede que cada backend mapeie um nome sem colisão. No erlang o nome de um módulo passa pela limpeza da decisão 109, que troca os caracteres que um átomo sem aspas não aceita.
- **Medido.** A limpeza da decisão 109 transforma `not-found.bpp` em `…@not_found`, o mesmo módulo que um `not_found.bp` irmão; os dois sobrescreveriam o `.beam` um do outro. Nenhuma célula tem o par hoje.
- **Opções.**
  (a) ★ O átomo do módulo vai entre aspas e mantém o nome do arquivo (`'pages@not-found'`).
  ```erlang
  'app@pages@not-found':render(...)   % not_found.bp stays app@pages@not_found
  ```
  (b) A limpeza da decisão 109 fica, e o par é recusado no segundo arquivo ("`not-found.bpp` and `not_found.bp` are one module on erlang").
  ```text
  error: src/pages/not_found.bp and src/pages/not-found.bpp are one module on erlang (app@pages@not_found) — rename one
  ```
  (c) A limpeza da decisão 109 fica e nada é checado.
- **Recomendação.** (a): a 561 pede nenhuma colisão, e um átomo entre aspas é a forma do próprio erlang para tal nome; (b) se um átomo de módulo entre aspas quebrar alguma ferramenta.
- **Bloqueia.** Nada hoje; um pacote com os dois arquivos.

#### B-27-f · `Name<T>.f()` com um nome de tipo entre crases (decisão 561; 144 B-27)
- **Proposta (opus, 2026-10-15; aguardando o mantenedor):** (a): o parser distingue um tipo pelo que o nome é, não por uma primeira letra maiúscula.
- **Contexto.** Argumentos de tipo explícitos antes de um `.` (`Name<T>.f()`) só são lidos como tipo quando o nome começa com letra maiúscula. Um nome de tipo entre crases (`` `my point` ``) não tem essa letra, então não pode ser escrito ali; uma chamada `Name<T>(…)` já funciona.
- **Medido.** `` `my box`<i32>.make() `` não é lido como um tipo com argumentos de tipo; `` `my box`<i32>(…) `` é.
- **Opções.**
  (a) ★ Estendido: um nome entre crases seguido de `<…>.` é lido como tipo, como um maiúsculo.
  ```bp
  val b = `my box`<i32>.make();
  ```
  (b) Deixado como está: um tipo entre crases recebe seus argumentos de tipo só numa chamada ou numa posição de tipo.
  ```bp
  val b: `my box`<i32> = `my box`.make();
  ```
- **Recomendação.** (a): a 561 diz toda posição que recebe um nome.
- **Bloqueia.** Nada.

#### B-27-g1 · `Signal.Int` no erlang e no beam (decisão 506 (c); 144 B-27 passo 6)
- **Proposta (sonnet, 2026-10-15; construída como (a), aguardando o mantenedor):** (a): `onSignal(.Int, f)` responde `Error(Unsupported)` no erlang e no beam; `forwardSignals` pula `Int` ali.
- **Contexto.** O `io.process` da std deixa um programa tratar `SIGINT`, `SIGTERM`, `SIGHUP` e `SIGWINCH` (506 (c)). A VM Erlang guarda o `SIGINT` para o seu próprio break handler.
- **Medido.** No OTP 28 `os:set_signal(sigint, handle)` é `badarg`; `sigterm`, `sighup` e `sigwinch` funcionam. O Ctrl-C de um terminal ainda chega a um filho iniciado pelo grupo de processos.
- **Opções.**
  (a) ★ Como construído: `Int` fica no enum, responde `Unsupported` no erlang / beam.
  ```bp
  case process.onSignal(process.Signal.Int, h) { Ok(_) -> …; Error(e) -> … }   // erlang: Error(Unsupported)
  ```
  (b) `Int` sai do enum comum; o Node ganha o seu próprio `Interrupt`.
  ```bp
  process.onSignal(process.Signal.Term, h);   // Int not writable; node-only API for Ctrl-C
  ```
  (c) A VM é iniciada de modo a entregar o `SIGINT` (um port program ou uma flag da VM), todos os targets iguais.
  ```text
  erl +B…  # the runner's VM flags change for every program
  ```
- **Recomendação.** (a): a resposta é tipada e honesta, sem mudar o runner.
- **Bloqueia.** O tratamento de Ctrl-C da biblioteca `cli` no erlang.

#### B-27-g2 · `io.terminal.keys()` no erlang e no beam (decisões 506 (c), 553; 144 B-27 passo 6)
- **Proposta (sonnet, 2026-10-15; aguardando o mantenedor):** (b): acrescentar `readKey() -> @Task<?Key>` em todo target.
- **Contexto.** `keys()` responde um stream de teclas para prompts interativos. No erlang e no beam um `@Stream` é gerado de forma ansiosa.
- **Medido.** No erlang / beam `keys()` junta toda a entrada antes de entregar a primeira tecla, então nunca responde num terminal vivo (trava sob um pty); o commonJS entrega preguiçosamente. `stdin.readChunk()` + `terminal.parseKey` funciona nos três targets.
- **Opções.**
  (a) `keys()` como está; um laço interativo no erlang lê `readChunk()` e `parseKey`.
  ```bp
  val chunk = await stdin.readChunk(); val key = terminal.parseKey(chunk);
  ```
  (b) ★ `readKey() -> @Task<?Key>` em todo target, `keys()` mantido.
  ```bp
  val key = await terminal.readKey();   // one key, null at end of input
  ```
  (c) Esperar uma geração preguiçosa de `async iter` no erlang (553), `keys()` a única API.
  ```bp
  for (await terminal.keys()) { k -> … }   // lazy once 553 lands on erlang
  ```
- **Recomendação.** (b), ou (c) quando a 553 gerar preguiçosamente no erlang.
- **Bloqueia.** Prompts guiados por tecla (`cli.prompt`) no erlang.

#### B-27-g3 · O stdio de um filho iniciado no erlang (decisão 506 (c); 144 B-27 passo 6)
- **Proposta (sonnet, 2026-10-15; construída como (a), aguardando o mantenedor):** (a): mantido e documentado.
- **Contexto.** `process.spawn` inicia um programa filho. No Node o filho herda o stdin, o stdout e o stderr do pai; no erlang ele roda atrás de um port.
- **Medido.** No erlang / beam o port dá ao filho um pipe de stdin (não o do pai), e o stderr dele é mesclado ao stdout.
- **Opções.**
  (a) ★ Mantido, a diferença no `libs/std/AGENTS.md` e no doc da função.
  ```bp
  process.spawn("cat", []);   // erlang: reads the port's pipe, not the terminal
  ```
  (b) Um port program que entrega ao filho os descritores do pai, todos os targets iguais.
  ```bp
  process.spawn("cat", []);   // reads the terminal on every target
  ```
- **Recomendação.** (a) por ora; (b) quando uma biblioteca precisar.
- **Bloqueia.** O `start` do onze que precisa do stdin do filho no erlang.

#### B-27-g4 · Modo raw e tamanho do terminal no erlang fora do Linux (decisão 506 (c); 144 B-27 passo 6)
- **Proposta (sonnet, 2026-10-15; aguardando o mantenedor):** (a): só Linux, a chamada respondendo `Unsupported` nos outros.
- **Contexto.** `terminal.setRaw(on)` e `terminal.size()` precisam do dispositivo do terminal. O Node os tem embutidos; a VM Erlang não.
- **Medido.** No erlang / beam a implementação lê o `/proc/<pid>/fd/{0,1}` do Linux e roda `stty` (para limpar `isig` e ler o tamanho). macOS e Windows não têm `/proc`.
- **Opções.**
  (a) ★ Só Linux: nos outros `setRaw` responde `Error(Unsupported)` e `size()` `null`.
  ```bp
  case terminal.setRaw(true) { Ok(_) -> …; Error(e) -> … }   // macOS on erlang: Error(Unsupported)
  ```
  (b) Um caminho por SO (`/dev/tty` e `stty -f` no macOS; Windows recusado).
  ```bp
  terminal.setRaw(true);   // Linux and macOS on erlang
  ```
- **Recomendação.** (a): nenhum caminho sem teste é entregue.
- **Bloqueia.** Nada no Linux.

#### B-25-a · Confirmar os adaptadores de gate do B-25 no wasm e as cells deixadas sem binding (decisões 334, 335 (3); 144 B-25)
- **Proposto (opus, 2026-10-13; aguardando o mantenedor):** **(a): como construído** — `.GateNew`, `.GateOpen`, `.GateAwait` (um gate é uma task pendente que nenhum host responde; abri-lo descarta o timer de cada espera pendente); as cells só de teste da std (`monoMillis`, `hostTarget`, `newCounter`, `countUp`, `countOf`, `panicOf`) ficam sem binding no wasm até o `botopink test` rodar wasm (335 (3)), então as "doze cells" da 334 são as de uso do `async`.
- **Medido.** Construído como (a); `std_async_on_every_target` verde nos quatro targets e nos dois hosts.
- **Opções.**
  (a) Como construído.
  ```bp
  @External.Wasm(wasi: .GateNew)
  ```
  (b) As cells de teste também com binding, agora.
  ```bp
  @External.Wasm(wasi: .GateNew)   // and countUp, countOf … bound on wasm
  ```
- **Recomendação.** (a).
- **Trava.** A linha dos adaptadores do 144 B-25.

#### 564-a · O `value` de uma entrada tipada do catálogo pode ser lido fora de uma expansão 562? (decisão 564; 144 B-19 passo 7)
- **Proposta (opus, 2026-10-16; construída como (b), aguardando o mantenedor):** (a): toda leitura do `value` de uma entrada `Declared<B>` fora de uma expansão recusada.
- **Contexto.** A decisão 564 faz `@TypeInfo.all(with: d)` responder `Declared<B>[]` e permite chamar as funções de `B` sobre o `value` de uma entrada só dentro de uma expansão 562. Fora dela, uma entrada de tipo não tem valor de tempo de execução: o catálogo a escreve como `null` tipado `B`.
- **Medido.** Só a chamada direta `d.value.start()` é recusada fora de uma expansão; ligá-la antes (`val v = d.value; v.start()`) passa na checagem de tipos e chega a `null` em tempo de execução.
- **Opções.**
  (a) ★ Toda leitura do `value` de uma entrada tipada fora de uma expansão é recusada, localizada.
  ```bp
  for (mods) { d -> val v = d.value; }   // refused: an entry's `value` is read only inside an expansion
  ```
  (b) Como construído: só a chamada sobre `value` é recusada, como a 564 a enuncia.
  ```bp
  for (mods) { d -> d.value.start(); }        // refused
  for (mods) { d -> val v = d.value; v.start(); }   // accepted; null at run time
  ```
- **Recomendação.** (a): a leitura mais estrita; (b) aceita na checagem de tipos um programa que falha em tempo de execução.
- **Bloqueia.** Nada.

#### 564-b · Um catálogo sobre decorators que nomeiam behaviors diferentes (decisão 564; 144 B-19 passo 7)
- **Proposta (opus, 2026-10-16; construída como (a), aguardando o mantenedor):** (a): respondido `Declared<unknown>[]`, sem precisar de `member:`.
- **Contexto.** Decisão 564: uma consulta sobre vários decorators responde os behaviors que eles compartilham, `unknown` quando nenhum. Antes da 564 uma consulta cujos decorators não davam forma comum precisava de `member:` (`typeinfo-all-needs-member`), e o `member:` está saindo.
- **Medido.** `@TypeInfo.all(with: [a, b])`, `a` sobre `@Decl<A>` e `b` sobre `@Decl<B>`: responde `Declared<unknown>[]`, cada `value` `null`. Um decorator de behavior ao lado de um simples ainda precisa de `member:`.
- **Opções.**
  (a) ★ Como construído: `Declared<unknown>[]`.
  ```bp
  val all = @TypeInfo.all(with: [a, b]);   // Declared<unknown>[]
  ```
  (b) Recusado como `typeinfo-all-needs-member`.
  ```bp
  val all = @TypeInfo.all(with: [a, b]);   // refused: the decorators share no behavior
  ```
- **Recomendação.** (a): o que o "`unknown` quando nenhum" da 564 enuncia, e o `member:` está saindo.
- **Bloqueia.** Nada.

#### 564-c · O texto da recusa de uma chamada de behavior fora de uma expansão (decisão 564; 144 B-19 passo 7)
- **Proposta (opus, 2026-10-16; construída, aguardando o mantenedor):** a recusa como construída, com um código de diagnóstico próprio.
- **Contexto.** A decisão 564 recusa chamar a função de um behavior sobre o `value` de uma entrada fora de uma expansão 562, localizada, mas não dá mensagem.
- **Medido.** Construída sem código de diagnóstico e com o texto da thread (`typeinfo_all_behavior_call_outside_expansion`).
- **Opções.**
  (a) ★ Um código próprio, `behavior-call-outside-expansion`, a mensagem nomeando a chamada e a regra da expansão.
  ```text
  error[behavior-call-outside-expansion]: `d.value.start()` calls `Module.start` on a catalogue entry — legal only inside a function expanded at its call site (decision 562)
  ```
  (b) O texto como construído, sem código.
- **Recomendação.** (a): toda recusa do checker tem um código.
- **Bloqueia.** Nada.

#### 564-d · Um módulo pode declarar um nome ao qual o compilador dá regras? (decisão 564; linha da máquina 1 do 144)
- **Proposta (opus, 2026-10-16; construída como (a), aguardando o mantenedor):** (b) para os nomes aos quais o compilador dá regras, (a) para o resto.
- **Contexto.** O `behavior` próprio ou importado de um módulo agora é dono do seu nome em toda posição de tipo, como um `type` de mesmo nome já era (`conformance/docs.md` § behavior). Alguns nomes do prelúdio carregam regras da linguagem: `Result` (`try`, `throw`), `Task`, `Component`, `Iterator`.
- **Medido.** Como construído, `pub behavior Result { fn score(self: Self) -> i32; }` compila e despacha; o `Result` do módulo é o que o nome lê ali, e `try` / `throw` ficam com o da std.
- **Opções.**
  (a) Sim, para todo nome: a declaração do módulo é o que o nome lê (construído).
  ```bp
  pub behavior Result { fn score(self: Self) -> i32; }   // accepted
  ```
  (b) ★ Recusado na declaração para um nome ao qual o compilador dá regras, localizado, nomeando a declaração da std, como `primitive-type-name-taken` faz para os primitivos; (a) para o resto.
  ```bp
  pub behavior Result { … }      // refused: `Result` is std's (builtins.d.bp), the language's rules use it
  pub behavior Component { … }   // accepted
  ```
- **Recomendação.** (b) para os nomes aos quais o compilador dá regras, (a) para o resto: nunca uma sombra silenciosa de um tipo da linguagem.
- **Bloqueia.** Nada.

#### b140-a · De onde vem a linhagem de spread de um tipo derivado quando `compiler.buildType` recebe texto? (decisões 359 (2), 578 (3), 599 (3), 600; 144 B-140)
- **Proposta (fable, 2026-10-17; aguardando o mantenedor):** **(a).**
- **Medido.** `comptime/derived_types.zig` reescreve `val X = Type.<fn>(…)` antes do checker em `pub type X(…)` e define `TypeDecl.derivedFrom` / `derivedPartial`; as regras de spread da 359 (2) e da 600 os leem (`record_spread_derived_partial`, `record_spread_required`, `record_spread_partial`). Pela 599 (3) as cinco funções viram corpos da std que terminam em `compiler.buildType(text)`, e um texto não carrega linhagem.
- **Opções.**
  (a) `compiler.buildType(source: string, from: anytype[] = [])`: os corpos da std passam `[source]` para `pick` / `omit`, `[first, second]` para `merge`, `[]` para `partial` / `required`; o compilador define `derivedFrom` a partir dele (a 578 (3) ganha um parâmetro rotulado).
  ```bp
  pub fn pick<T>(comptime source: type<T>, comptime ..fields: Type.Field<T>[]) -> anytype {
      return compiler.buildType(recordText(kept), from: [source]);
  }
  ```
  (b) O compilador lê a linhagem da chamada do `val` (`Type.pick(X, …)` → `[X]`): um caso chaveado pelos nomes das funções da std.
  (c) Nenhum spread a partir da fonte de um tipo derivado: a fonte de um spread é só o próprio tipo do record; 359 (2) e 600 emendadas, três cells `record_spread_*` mudam.
- **Recomendação.** (a): a std declara a linhagem, o compilador lê um valor, e a 599 (3) se mantém (nenhum nome da std conhecido pelo compilador).
- **Bloqueia.** A peça de tipos derivados do B-140 (os cinco corpos do `types.bp`).

#### b140-c · No B-140, uma biblioteca pode declarar seu próprio construtor de tipo `-> anytype`, ou só as cinco funções da std? (decisões 578, 599 (3); 144 B-140)
- **Proposta (fable, 2026-10-17; aguardando o mantenedor):** **(b).**
- **Medido.** A 578 faz de `compiler.buildType` a única forma de construir um tipo; a 599 (3) nomeia as funções `Type` da std. Hoje um `val` derivado é encontrado só pelo binder `Type` da std; as doze cells `derived_type_*` chamam todas as da std.
- **Opções.**
  (a) Todo `val` de nível de módulo cujo inicializador chama uma função declarada `-> anytype` (da std ou de uma biblioteca) é avaliado no build e vira um tipo; a função chamada resolvida pelo grafo de imports.
  (b) Só as funções `Type` da std no B-140; a forma geral num passo posterior com suas próprias cells.
- **Recomendação.** (b): as doze cells são o oráculo do B-140; (a) acrescenta um caminho de resolução que nenhuma cell segura.
- **Bloqueia.** Nada no B-140 se (b); (a) acrescenta uma peça.

#### b140-d · O que `compiler.text(f.defaultValue!)` responde para um default que não viaja (o default não fechado de um record importado) (decisões 598, s28-a; 144 B-140)
- **Proposta (fable, 2026-10-17; aguardando o mantenedor):** **(a).**
- **Medido.** O default de um campo atravessa um módulo só quando fechado (`travelled` descarta o resto); a 598 diz que `defaultValue` é o default "como escrito". Um tipo derivado construído a partir de um record importado escreve os defaults dos seus campos de volta no texto.
- **Opções.**
  (a) Esse campo chega com `defaultValue: null`, como viaja hoje: o tipo derivado o exige na construção.
  (b) `defaultValue` guarda o texto como escrito, mas o texto do record derivado o omite.
- **Recomendação.** (a): uma regra para um campo onde quer que seja lido.
- **Bloqueia.** Nada (construído como (a) se não respondida).

#### b140-e · Um meta record que guarda um `Type.Field<T>`, lido em runtime, quando a 599 remove o campo de runtime (decisões 298, 308, 575 (4), 599 (1), 606 (3); 144 B-140)
- **Proposta (fable, 2026-10-18, relida contra 606–609; aguardando o mantenedor):** **(a).**
- **Medido.** A cell `meta_field_tuple_and_field_key` (298) grava `Sort<Book>(by: .pages, keys: [.pages])` por `compiler.setMeta`, e `main` o lê em runtime. Pela 606 (3) a leitura se escreve `val o = comptime compiler.typeInfo(Book).meta(Sort);` (codemod do B-139). O valor de uma expressão `comptime` é emendado no corpo de runtime como literal (575 (4)), e um `Type.Field<T>` não tem forma de runtime (599 (1)). Então a falha é a emenda de `Sort(by: .pages, …)`: o `unbound variable 'pages'` num local sintético (`src/main.bp:1000002:31`) quando a primeira caixa do B-140 remove a chave de runtime. A 606 (3) também dá à (b) um precedente no mesmo record: `Type.Field<T>.type: anytype` é um valor de build reduzido ao seu nome (575 (7)).
- **Opções.**
  (a) Recusado na expressão `comptime` cujo valor guarda um `Type.Field<T>`. O erro é localizado no `comptime`, com o código `field-key-at-run-time`, e nomeia o campo do record (`Sort.by`) e a 599. A leitura no build do decorator fica. A cell se divide: a metade da tupla roda, e a metade do campo vira uma cell de recusa.
  (b) O campo é reduzido ao seu nome, como o seu próprio membro `type`: `o?.by` é `"pages"`, e a forma de runtime de `Sort` é `by: string`, `keys: string[]`.
  (c) `compiler.setMeta` recusa um record com um campo `Type.Field<T>`.
- **Recomendação.** (a): recusa onde o valor de build encontra o runtime, um ponto que a 606 (3) agora escreve (`comptime`). A (b) é mais barata, mas dá duas formas a um record.
- **Bloqueia.** A primeira caixa do B-140 (a cell está vermelha na sua branch).

#### 577-a · Como um erro no código construído por um template encontra o seu lugar no texto do template: pela palavra que copia, ou pelas folhas de buraco que a sub-linguagem grava (decisões 577, 578; 144 B-136)
- **Proposta (opus, 2026-10-18; construída como (a), aguardando o mantenedor):** **(a)** agora, **(b)** como passo posterior.
- **Medido.** Uma sub-linguagem analisa os seus próprios buracos `${…}` a partir de `compiler.text(q)` e constrói código com `compiler.build(text)` (577). O texto construído não guarda ligação com a fonte do template, então o compilador precisa mapear um erro nele de volta. O query grava folhas de buraco que cobrem o `${missing}` inteiro, que nunca aparece no código construído. O rakun-style não grava folha nenhuma. Como construído em `infer.zig` `parseCodeTextAt` (`copiedAt`), todo identificador, número ou string que o código construído copia do texto do template é localizado na sua ocorrência ali. Casa palavras inteiras, varre para frente, e nunca olha dentro do trecho de uma folha. Nomes que o próprio módulo do template declara mantêm a sua localização antiga (`dsl_hygiene`). As quatro cells de recusa das bibliotecas e as cells `template_hole_error_at_column`, `_on_later_line` e `_far_in_built_code` seguram isso.
- **Opções.**
  (a) A regra da palavra copiada como construída: nenhum trabalho para uma sub-linguagem. Uma palavra que aparece duas vezes no texto é localizada na primeira ocorrência depois do casamento anterior.
  (b) Uma sub-linguagem grava cada folha de buraco cobrindo a expressão do buraco (não `${…}`), e só folhas são localizadas. Tokens fora de uma folha recebem a localização do literal do template.
  (c) As duas: folhas quando gravadas, a regra da palavra copiada senão.
- **Recomendação.** (a) agora, porque está verde em toda biblioteca e cell. Depois (c) como passo posterior, para que uma sub-linguagem que grava folhas seja exata mesmo onde uma palavra se repete.
- **Bloqueia.** Nada (construída como (a)).

#### 165-f · Onde os nomes dentro de um `compiler.buildType(text)` são resolvidos (decisões 578 (3), 599 (3); frente 165 s10, 144 B-140)
- **Proposta (opus, 2026-10-17; aguardando o mantenedor):** **(a).**
- **Medido.** O rakun constrói os seus tipos gerados (`Name.Tx`, `Name.Sec`, `Name.Http`) com `compiler.buildType(<string calculada>)`, como `entity.bp` e `cached.bp` já fazem. O texto nomeia funções e tipos de runtime. Hoje o texto de uma contribuição é analisado e resolvido no módulo anotado (o host) (`mergeAssocTypes`), então um helper do módulo do decorator precisa ser importado pelo host ou escrito qualificado. Nenhuma decisão fixa isso.
- **Opções.**
  (a) O texto de um tipo construído é resolvido no módulo que chama `buildType` (o módulo do decorator), como a árvore de um executor (581).
  (b) É resolvido no módulo host, como construído hoje. O decorator escreve nomes qualificados.
- **Recomendação.** (a): uma regra para o código que um decorator escreve, qualquer que seja a forma que o carrega.
- **Bloqueia.** Nada hoje (construída como (b) com nomes qualificados).

#### 150-s34-a · `Sheet.add` sobre um `Styleable` cujo `toStyled()` responde `Component<Styled>`: um `add` assíncrono, ou uma função comum desembrulhando um componente (decisões 280, 432; frente 150 s34)
- **Proposta (coordenador, 2026-10-18; aguardando o mantenedor):** **(a).**
- **Medido.** O 150 s34 faz `Sheet.add(layerName, item: Styleable)` receber o `Styled` que `item.toStyled()` responde. `toStyled()` retorna `Component<Styled>`, e `await` numa função comum é recusado (`await-without-async`: precisa de um retorno `Task` / `Stream` / `Component`; `layers.bp` do rakun-stylesheet). Então `add` não consegue desembrulhar o item sem virar assíncrono ele mesmo. Os testes e as cells encadeiam `Sheet.add(…).add(…)`.
- **Opções.**
  (a) `toStyled()` responde `Styled` (um valor estilizado é dado, não um componente renderizado); `add` continua uma função comum e mantém o seu encadeamento.
  (b) `add` retorna `Component<Sheet>` e quem o chama faz `await` a cada passo, o que quebra `.add().add()`.
  (c) Uma função comum pode desembrulhar um `Component<T>` sabidamente já resolvido: uma mudança no compilador, uma linha do 144.
- **Recomendação.** (a): nada em montar uma folha de estilos é assíncrono, e o encadeamento fica. A medir antes: cada corpo de `toStyled()`, conferindo se algum faz `await`.
- **Bloqueia.** O 150 s34, e o marcador "a method's behavior-typed parameter" em `layers.bp`.

#### 165-h · O código de uma dependência declarada que nenhum módulo importa roda os seus executores de init? (decisões 580, 615, 551; frente 165 s5)
- **Proposta (coordenador, 2026-10-18; aguardando o mantenedor):** **(a).**
- **Medido.** O pacote `alpha` declara `#[rakun.module] pub component fn web() -> Component<Service>`, cujo decorator o registra por um executor `compiler.init`. O `main` do programa importa só `rakun` e lista `alpha` como dependência. O executor de `web` nunca roda, então o registro fica vazio. Acrescentar `import {alpha.web} from "alpha";` o faz rodar. O plug-and-play do rakun (165 s5: `rakun.boot()` monta todo módulo de todo pacote declarado) precisa do primeiro caso. `boot_modules` importa um nome de cada pacote para contornar isso.
- **Opções.**
  (a) Todo módulo de toda dependência declarada entra no build, e os seus executores `init` entram na lista de init em ordem de dependência (a regra da 580 entre pacotes), importados ou não.
  (b) Só módulos importados rodam os seus executores. Um pacote que quer os seus registros rodados é importado por nome (o comportamento de hoje), e o plug-and-play escreve um import por pacote.
  (c) Um pacote marca os módulos cujos executores rodam sem import (um campo do `botopink.json`, p. ex. `"init": ["src/web.bp"]`).
- **Recomendação.** (a): uma dependência declarada faz parte do programa, e a 580 já ordena os executores pela posição da declaração. A (c) acrescenta um campo de manifesto para o mesmo efeito.
- **Bloqueia.** A metade "um pacote acrescentado é descoberto" do 165 s5; `boot_modules` mantém os seus imports até a resposta.

## Máquina 2 — prioridade máxima (frente 144, `machine-2/144-backends-tooling/`)

As perguntas que seguram um passo da máquina 2 (backends, runtimes, std, tooling, o gate), respondidas com as da
máquina 1 antes de toda outra parte desta página; cada uma segura uma linha, ou nada construído.

#### 164-s3-m · `bytes.at` fora do intervalo e `bytes.ofWords` sobre uma palavra fora de `0..255` (decisão 585 (k); 164 s3 P2-d)
- **Proposta (sonnet, 2026-10-17; aguardando o mantenedor; construída como (a)):** **(a): `bytes.at` responde `-1` para um índice fora de `0..length-1`, como `text.byteAt` e `String.charCodeAt`; `bytes.ofWords` guarda os oito bits baixos de cada palavra.** A revisão (fable, 2026-10-17) recomenda (b).
- **Medido.** `modules/std-wasm/wat/bytes.wat`: `bytes.at` compara o índice sem sinal com `array.len` e responde `-1` além dele (um índice negativo incluído), o corpo de `text.byteAt` (P1-a) sobre o mesmo layout `$str` (`Bytes` é um array de `i8`, 164 s2, 346); `String.charCodeAt` responde `-1` fora do intervalo nos quatro alvos (`primitives.bp`: Erlang `_ -> -1`, Node `?? -1`, `text.zig`). `bytes.ofWords` escreve cada palavra com `array.set $str`: uma célula `i8` guarda os oito bits baixos, logo `256 + 33` é o byte `33`. Nenhuma operação de botopink constrói um `Bytes` a partir de palavras (`behavior Bytes`: `fromUtf8`, `toUtf8`, `length`, `concat`, `slice`), logo nenhum alvo tem uma resposta para comparar, e a 585 (k) nomeia as três folhas sem as suas respostas. Os codecs para que foram escritas (`base64DecodeBytes`, `hexDecodeBytes`) produzem palavras em `0..255` e leem índices em `0..length-1`: por eles nenhuma das respostas é observável; qualquer célula `std:` de `libs/std` (445) alcança as folhas. O teste unitário `wat: front 164 s3 ---- the Bytes leaves answer in a GC module` (`codegen/tests/wat.zig`) fixa `bytesOfWords([104, 105, 256 + 33])` como três bytes, `bytesAt(b, 2)` como `33`, `bytesAt(b, 3)` e `bytesAt(b, -1)` como `-1`. Sem a verificação, `array.get_u` dá trap fora de `0..length-1` (um abort `crash:`).
- **Opções.** (a) Como construído. (b) Ambas dão trap: `bytes.at` é o `array.get_u` nu (um trap fora de `0..length-1`, um índice negativo lido sem sinal incluído) e `bytes.ofWords` é `unreachable` na primeira palavra fora de `0..255`; os codecs `.bp` guardam os seus próprios limites; as três linhas do teste unitário substituídas. (c) `bytes.at` como `text.byteAt` (`-1`: uma resposta para uma leitura sobre um layout), `bytes.ofWords` dando trap.
- **Recomendação.** (b) — uma folha não responde nada fora do seu domínio e nenhuma palavra é truncada em silêncio; o `-1` de `text.byteAt` fica o do P1-a até o mantenedor estender a resposta a ele.
- **Bloqueia.** Nada construído espera; a metade `.bp` do P2-d (depois do B-139 e do s2 P5) lê a resposta antes de ser escrita.

#### 521-a · Um `f64` que chega ao texto do commonJS só por um `T` genérico perde o `.0` (decisão 521; 144 B-78)
- **Proposto (sonnet, 2026-10-14; aguardando o mantenedor):** **(a): um corpo genérico que escreve um `T` como texto recebe a função de texto do seu argumento de tipo** — o ponto de chamada, que conhece `T`, entrega ao corpo um `show` oculto para ele (como o checker já especializa por chamada); um corpo JS por função mantido.
- **Medido.** Construído como (a) para uma chamada direta no mesmo módulo (144 B-114): uma fn genérica de topo que escreve um `T` como texto recebe um `__bp_ty_<T>` oculto final por parâmetro de tipo, a forma de impressão do tipo ligado; os valores `T` e o `.d.ts` inalterados; um valor fn, outro módulo e um método genérico são o 144 B-115. Desde a 521 o commonJS escreve um `f64` como o std-wasm (`5.0`, `1.0e21`) onde quer que o checker saiba que é um `f64`. Um float que chega só a um parâmetro de tipo — `Box<T>(value: 2.0)` impresso, `fn show<T>(v: T) { "${v}" }` chamado com `3.0` — imprime `2` / `3`: um número JS não distingue `f64` de inteiro, e um corpo JS serve todo `T`. erlang, beam e wasm imprimem `2.0` / `3.0`.
- **Opções.** (a) Uma função de texto oculta por parâmetro de tipo usado como texto, passada na chamada. (b) Um `f64` encaixotado no commonJS (um objeto ou um número marcado), em todo lugar — um custo em todo float. (c) Especializar todo corpo genérico pelos seus argumentos de tipo no commonJS.
- **Recomendação.** (a) — o custo cai só onde um genérico escreve um `T` como texto.
- **Bloqueia.** A linha 04-js (um float por um `T` genérico); um texto para um valor em todo alvo (434 (5)).

#### 529-a · O que `..` como único spread deixa em aberto (decisões 529 (3), 359, 37; 144)
- **Proposto (sonnet, 2026-10-14; aguardando o mantenedor):** **(a) para cada um:** (1) nenhuma ferramenta de migração — nenhuma biblioteca escreve hoje um spread `...` em chamada (o único `{...pairs}` do jhonstart é um spread de tag que o compilador ainda não implementa); (2) a recusa da 37 de uma base que não é nome acabou: 359 (6) permite qualquer expressão de origem, avaliada uma vez (`record_update_base_not_a_name` responde `out 1`); (3) a atualização `..` de uma variante de enum continua recusada como `call-spread` (a linha de variante de enum da 359); (4) o caminho morto de atualização da decisão 37 em `infer.zig` é apagado.
- **Medido.** A 529 (3) pousou: `..src` é o spread de record, `...src` como spread é `spread-dot-dot-dot` nomeando `..`, o formatador imprime `..`, o botopink-lang migrado. Juntar as duas formas de spread moveu três respostas: `record_update_base_not_a_name` (uma recusa sob a 37) agora responde `out 1` sob a 359 (6); `Subject.Animal(..alice)` é `call-spread` (era um type mismatch); dois carets de recusa andaram uma coluna (o `..` mais curto). O parser recusa `...`, então o formatador não consegue ler um spread `...` antigo para migrá-lo.
- **Opções.** Cada ponto (a) como proposto ou (b): (1) o parser continua lendo `...` por uma versão, o formatador o reescrevendo; (2) a restrição da 37 mantida sob a 359; (3) a atualização de uma variante de enum permitida; (4) o caminho antigo mantido.
- **Recomendação.** (a) — a 359 é a regra posterior, nenhuma biblioteca precisa da grafia antiga.
- **Bloqueia.** Nada construído; a resposta de `record_update_base_not_a_name`.

#### 529-b · O que um parâmetro de record `..props: R` deixa em aberto (decisão 529 (2); 144)
- **Proposto (sonnet, 2026-10-14; aguardando o mantenedor):** **(a) para cada um:** (1) um parâmetro de record ao lado de um variádico recusado (`record-param-variadic`) — argumentos variádicos posicionais e campos rotulados colidem; (2) um default no parâmetro de record recusado (`record-param-default`) — os defaults dos próprios campos de `R` são os defaults; (3) as posições contam os outros parâmetros: em `fn f(a, ..p: R, b)`, `f(1, 2, x: 3)` passa `2` para `b`; (4) métodos e funções associadas recebem um parâmetro de record como as funções (um passo posterior o constrói); (5) um `R` genérico (`..p: Props<T>`) é legal, seus campos tipados pela chamada.
- **Medido.** A 529 (2) pousou para chamadas de função comuns: `..props: R` é um parâmetro comum de tipo `R`; o checker reescreve os rótulos de uma chamada que nomeiam campos de `R`, e um spread `..src`, numa única construção `R(…)`; quatro recusas que a 529 nomeia têm células. Construído além da 529 e a confirmar: (1) e (2) acima; (3) é como as posições são lidas hoje; métodos e funções associadas ainda não são reescritos; um `R` genérico é analisado e não foi testado.
- **Opções.** Cada ponto (a) como proposto ou (b) o seu oposto.
- **Recomendação.** (a) — as leituras mais estritas onde a 529 se cala, e a mesma regra para todo chamável.
- **Bloqueia.** Um parâmetro de record num método; nada construído fora isso.

#### 543-a · O que o s1 da front 164 (wasmtime) deixa em aberto (decisão 543)
- **Proposto (opus, 2026-10-14; aguardando o mantenedor):** **(1) Winch com o cache** — uma compilação a frio de 315 ms contra ~1000 ms do Cranelift, uma execução de 37 contra 33 ms; (2) o CLI e o LSP chamam `interrupt()` no SIGINT, para um corpo descontrolado terminar como um erro localizado; (3) o `attempt` no build captura o que captura num programa wasm — uma divisão inteira por zero faz trap lá, então é excluída no build também (uma resposta, 434 (5)); (4) o cache de módulos compilados é limpo pelo `botopink cache` do B-77.
- **Medido.** O s1 pousou no wasmtime v49 com Cranelift e o cache de módulos compilados (quente 48 ms, frio 1,0–1,3 s para 12 builds); o Winch não era uma das duas opções da 543; nenhum handler de SIGINT está instalado (Ctrl-C encerra o processo; `interrupt()` existe, nada o chama); o `attempt` no build também captura uma divisão inteira por zero, que faz trap num programa wasm; o cache não tem limpeza até o B-77.
- **Opções.** Cada ponto (a) como proposto ou (b): (1) manter o Cranelift; (2) nenhum handler; (3) continuar capturando no build; (4) um limite de tamanho já.
- **Recomendação.** (a) para cada um.
- **Bloqueia.** Nada construído.

#### 539-a · `throw` e um `try` que propaga dentro do corpo de um `defer`: recusados ou permitidos? (decisão 539 (5); 144)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(c): recusar um `throw` e um `try` que propaga, localizados (`defer-throw`, `defer-try`); um `try … catch` tratado dentro do corpo continua** — a razão da 539 (5) é "não pode sair do caminho", e um throw sai dele: em `finally` / `after` o erro adiado substitui o erro sendo propagado, mascarando-o silenciosamente. O Zig recusa `try` num `defer`, o Swift recusa lançar.
- **Medido.** A 539 pousou em todos os targets com `return`, `break` / `continue` para fora do corpo, `yield` e `await` recusados; um `throw` ou um `try` que propaga no corpo compila, e seu erro substitui o do próprio bloco no commonJS, no erlang e no beam.
- **Opções.** (a) Recusar as duas formas, `catch` incluído. (b) Permitir: o erro adiado substitui o do bloco (hoje, não documentado). (c) Como proposto.
- **Recomendação.** (c).
- **Bloqueia.** Nada construído; duas células de recusa quando respondida.

#### 537-b · A precedência do `??` contra o parêntese da 537 (decisões 537 (2), 28, 330)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(b): manter o `??` apertado; 537 (2) emendada para "`catch` é o infixo de menor precedência, abaixo do `??`"** — nenhum programa muda de significado, e a regra de parênteses da 330 já cobre o único vizinho ambíguo.
- **Medido.** A 537 dá ao `catch` "a precedência do `??`, abaixo de todo operador aritmético", mas o `??` é o nível binário mais apertado (decisão 28), recusado ao lado de `&&` / `||` (330). A std depende disso: `libs/std/src/hash.bp` (`h.at(2 * i) ?? 0 * 65536.0 + …`), `io/random.bp` (`64 + b.at(6) ?? 0 % 16`). O build fez o `catch` o mais baixo e deixou o `??` como estava.
- **Opções.** (a) O `??` vai para o nível do `catch`, com uma reescrita do formatador colocando parênteses em todo `??` ao lado de um operador aritmético. (b) Como proposto. (c) O `??` no nível do `||` (JS), o `catch` abaixo dele — a mesma migração de (a).
- **Recomendação.** (b).
- **Bloqueia.** Nada construído; só o texto da 537.

#### 541-a · Quando a migração do `;` do lambda sai do formatador (decisão 541)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(a): a reescrita mantida sob um `botopink format --migrate 541` explícito, removida quando todo repositório em `repository/` e todo branch aberto estiverem migrados** — um branch rebaseado além da regra sem a migração recebe o `void` silencioso que a 541 foi escrita para evitar, e o formatador do `feat` não consegue repará-lo.
- **Medido.** A migração viveu em um commit do botopink-lang e saiu no seguinte, que fez a regra valer; as bibliotecas são migradas com um binário construído no primeiro. vscode-extension, cardume, branches abertos e código de usuário não têm migração no compilador do `feat`.
- **Opções.** (a) Como proposto. (b) Como construído: o coordenador roda o binário da migração sobre cada branch no seu rebase, a regra escrita em `fronts.md`. (c) A reescrita readicionada incondicionalmente até as reformatações da 524 pousarem.
- **Recomendação.** (a); (b) aceitável se o binário for mantido e a regra escrita.
- **Bloqueia.** Todo pouso de biblioteca através da regra; as reformatações da 524.

#### 535-a · Uma divisão de float por zero no erlang e no beam: `crash: badarith` ou `panic`? (decisões 535, 527 (3), 492, 444; 144)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(a): o `/` de float no erlang e no beam checado como o de inteiro, `panic: division by zero: / on f64 at <file>:<l>:<c>`** — uma forma para toda divisão por zero; a divergência (444: commonJS e wasm respondem `Infinity`) fica então só no abortar.
- **Medido.** A 535 cita `panic: division by zero`; a 492 lista "uma divisão por zero" sob `panic`; a 527 (3) checa só a de inteiro. As divergências de erlang e beam da `float_nan_infinity_words` agora afirmam `stderr crash: badarith` — a resposta do compilador (um `badarith` sem marca), não uma que uma decisão fixa.
- **Opções.** (a) Como proposto. (b) Manter `crash: badarith` — a 527 (3) é só de inteiro. (c) Literalmente `panic: division by zero`, uma terceira forma de mensagem.
- **Recomendação.** (a).
- **Bloqueia.** Os dois snapshots de divergência ficam provisórios; uma linha da 144 quando respondida.

#### 535-b · Onde vive o texto de abort do commonJS: no guard do runner ou no programa emitido (decisão 535)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(b): o módulo de entrada (o que tem `main`, nunca um módulo de biblioteca — um `process.on` global numa biblioteca é um efeito colateral) emite o handler; o guard do runner mantido para o `.mjs` do browser** — a 535 é sobre o que o programa escreve; uma regeneração mecânica dos snapshots de codegen do commonJS.
- **Medido.** A 535 pousou no commonJS como um guard `node --import` que o `botopink run` e os testes passam ao node; o `main.js` emitido não muda, e um `node main.js` rodado à mão imprime o relatório do próprio node. O guard do erlang também é do runner, mas um build erlang não tem entrada autocontida; um programa commonJS tem uma e é rodado pelo node fora do botopink.
- **Opções.** (a) Só o guard do runner, como pousou. (b) Como proposto. (c) Os dois.
- **Recomendação.** (b).
- **Bloqueia.** Nada; as células `abort_text_*` respondem o mesmo.

#### 532-a · O registro `from <file>:<line>:<col>` estende a 475 (2) (decisões 532, 475)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(a): a 475 (2) emendada com `from`, o cabeçalho inalterado** — células mais antigas não são afetadas: o registro aparece só onde existem frames.
- **Medido.** A 475 (2) lista os registros do `.snap` exaustivamente; o build da 532 adicionou `from` (depois de `at` / `label`, o mais interno primeiro, comparado exatamente) no formato da célula e no `conformance/docs.md`. 13 células têm linhas `from`; o cabeçalho ainda é `botopink-cell 1`.
- **Opções.** (a) Como proposto. (b) `botopink-cell 2`. (c) Os frames dobrados na mensagem.
- **Recomendação.** (a).
- **Bloqueia.** Nada pousado; o texto da 475.

#### 533-a · `comptime-badarith` nomeia a expressão inteira enquanto o caret está no operador (decisões 533, 472)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(b): a mensagem nomeia o fonte da operação que divide (`6 / (3 - 3)`, `a / b`), texto e caret concordando; as linhas `from` dão o `comptime`** — pouco em jogo.
- **Medido.** A 472 diz "a operação e o lugar"; depois da 533 o lugar é o operador mas o texto entre crases é a expressão inteira do `comptime` (`1 + 6 / (3 - 3) * 2`, `ratio(6, 0)`): `comptime_nested_division_by_zero`, `comptime_division_by_zero_in_helper`, `hole_any_call_raises`.
- **Opções.** (a) O texto do `comptime`, como pousou. (b) Como proposto. (c) Sem texto entre crases.
- **Recomendação.** (b).
- **Bloqueia.** Nada.

#### 540-a · Detalhes de `io.fs` que a 540 deixa em aberto: o link pendente, `hash()`, uma linha ruim, as respostas de escrita (decisão 540; 144)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** (1) um link pendente sob `walk` é **`NotFound(<root>/<link>)`** — o que uma leitura através dele responde; o "nomeando o link" da 178 mantido em `path`, e `Other.message` continua sendo o texto do host como a 540 (1) diz; (2) `hash()` faz o hash **do arquivo inteiro**, qualquer que seja a posição de leitura (como construído: é igual a `Asset.hash`); (3) uma linha `InvalidUtf8` **encerra** `lines()` (como construído: um `throw` num corpo `@Stream` o encerra); (4) as funções de escrita e de diretório respondem **`@Result<void, FsError>`**, só `File.write` uma contagem.
- **Medido.** Construído: `Other(root, "fs.walk: dangling link \"x\"")` (células `fs_error_variants`, `std_fs_walk_root_spellings`) — o texto da própria std onde a 540 (1) faz de `Other.message` o do host, e `path` a raiz, que existe; `hash()` do arquivo inteiro enquanto `bytes()` / `text()` leem o resto a partir da posição (`fs_file_handle`); `lines()` termina na linha `InvalidUtf8` (o `BufRead::lines` do Rust entrega o erro e continua; o `Files.lines` do Java termina); `writeBytes`, `writeText`, `appendText`, `mkdir`, `mkdirRecursive`, `rm`, `removeTree` e `copy` respondem `Ok(0)` de `i32`, uma sobra de `@Result<i32, string>` (`fs_whole_file_shortcuts` imprime `0`) — Rust, Java, Erlang e Node não respondem nada aí.
- **Opções.** (1) (a) como construído; (b) `NotFound(<root>/<link>)`; (c) uma variante `DanglingLink(path, link)`. (2) (a) o arquivo inteiro; (b) o resto, como `text()`. (3) (a) encerra; (b) continua, como o Rust. (4) (a) `i32` 0; (b) `void`; (c) `void`, `copy` uma contagem de bytes.
- **Recomendação.** (1b) (2a) (3a) (4b).
- **Bloqueia.** Nada construído; as células fixadas regravadas para (1) e (4) quando respondida.

#### 540-b · `a.open()` exige `import {io.fs}` (decisão 538; 144)
- **Proposto (fable, 2026-10-14; aguardando o mantenedor):** **(a): manter a recusa `embed-open-needs-fs`** — `File` é um tipo da std; um valor cujo tipo o módulo não consegue nomear é a razão do Go para `import "embed"`.
- **Medido.** A 538 escreve `pub fn open(self: Asset) -> File` sem condição de import. O checker reescreve `a.open()` para `<fs>.openAsset(a)` (o alias mais curto de `io/fs`); sem o import é recusado na chamada (`embed_open_without_fs_import`).
- **Opções.** (a) Como construído. (b) Um import implícito de `io/fs` onde `a.open()` é escrito. (c) `File` ambiente em `builtins.d.bp`, `open` um método real de `Asset`.
- **Recomendação.** (a).
- **Bloqueia.** Nada.

#### 164-s3-g · `String.slice` (`text.slice`, `sliceFrom`, `sliceBetween`): com o P1 ou o P2? (164 s3)
- **Proposta (fable, 2026-10-15; aguardando o mantenedor):** **(a): P2, como um corpo em botopink que o `s[a..b]` / `s[i]` do codegen chama pelo prelúdio.**
- **Medido.** Os três são do próprio codegen (ele rebaixa `s[a..b]` e `s[i]` para eles), não métodos de `String` ligados por uma célula.
- **Opções.** (a) P2. (b) P1, como mais uma folha.
- **Recomendação.** (a).
- **Bloqueia.** Nada no P1.

#### B-127-a · A listagem de um trace: rebaixada de novo a cada leitura, ou guardada? (144 B-127)
- **Proposta (opus, 2026-10-16; aguardando o mantenedor; construída como (a)):** **(a): rebaixada de novo a partir do texto Erlang do módulo a cada vez que um snapshot ou o cache de código a lê** — o cache de build do wat guarda o texto Erlang (35 MB no projeto de marcadores recusados da validation) em vez da listagem (128 MB).
- **Medido.** `botopink build` renderiza o trace de cada módulo uma vez, um snapshot uma vez por alvo; o cache de código grava uma listagem como a string que ela renderiza (as suas entradas idênticas byte a byte antes e depois).
- **Opções.** (a) Como construído: memória primeiro, um re-rebaixamento por leitura. (b) A listagem guardada de novo: ~128 MB de volta nesse projeto, sem re-rebaixamento.
- **Recomendação.** (a) — a memória do gate foi o que derrubou a máquina; um re-rebaixamento é a compilação de um módulo.
- **Bloqueia.** Nada construído espera.

#### B-116-k · O que o corpo de uma lambda `component` permite (decisão 574; 144 B-116 (i))
- **Proposta (opus, 2026-10-16; aguardando o mantenedor; construída como listado, a mais restritiva):** (1) um `throw` ou um `try` que propaga numa lambda `component` é recusado — `Component<Result<R, E>>` é do B-116 (iii); (2) os seus `use`s e `await`s não entram em nenhum nó de hook: o builder da função que a envolve é limpo para o corpo dela, então as suas chamadas recebem a leitura assíncrona conservadora da 375; (3) um corpo cuja última expressão termina com `;` é recusado como incompatível quando `R` não é `void`, onde uma `component fn` responderia `rendered(null)`.
- **Medido.** A 574 rebaixa `component { -> … }` como uma `component fn` (o caminho de component-fn, as capturas carregadas); `component_lambda_typed_val` e `component_lambda_typed_param` respondem nos quatro alvos. Os três pontos são casos que a 574 não nomeia.
- **Opções.** Cada ponto como construído, ou (b): (1) um `throw` permitido como numa `component fn` (um `ErrorBoundary` o pega, 414, 504); (2) os hooks da lambda juntados ao builder que a envolve; (3) um corpo terminado em `;` respondendo `rendered(null)` como uma `component fn` faz.
- **Recomendação.** (b) para (1) e (3), uma regra para uma `component fn` e uma lambda `component` como a 574 diz; (2) como construído até uma lambda `component` ter um builder próprio.
- **Bloqueia.** Nada construído espera.

#### B-116-i · As escolhas que o B-116 P1 fez onde nenhuma decisão fala (decisões 553, 147; 144 B-116)
- **Proposta (opus, 2026-10-15; aguardando o mantenedor; construída como listado):** (1) um tipo de retorno esperado que ainda é uma variável de tipo livre aceita qualquer marcador; (2) um tipo esperado que não é tipo de função fica para a unificação comum; (3) um método de `implement` é verificado contra o seu marcador só quando escreve um tipo de retorno; (4) um método marcado de behavior ou de tipo que não faz yield continua uma fábrica no P1 (o codegen lê a regra antiga até o P4); (5) `component { -> … }` é verificado e então recusado no marcador com `component-lambda-not-lowered` até o B-116 (iii).
- **Medido.** Cada um é um caso que o texto da decisão e a 147 deixam em aberto; as células `marker_*` guardam as respostas construídas onde elas são observáveis.
- **Opções.** Cada ponto como construído, ou (b) recusado.
- **Recomendação.** Como construído para (4) e (5) (temporários pelo seu passo); (1)–(3) recusados depois que o codemod rodar (P4), a leitura mais estrita.
- **Bloqueia.** A lista de recusas do B-116 P4.

#### 518-a · Duas recusas de `needs:` que nenhuma decisão afirma (decisão 518 (1); 144 B-07)
- **Proposto (o coordenador, 2026-10-15; aguardando o mantenedor):** **(a): as duas continuam recusas, cada uma com uma célula** — `needs:` em `@External.Node` / `@External.Erlang`, e `needs:` dado como qualquer coisa que não uma lista de valores `WasmNeed`; a leitura mais restritiva (67).
- **Medido.** A 518 (1) afirma uma recusa: um valor de `needs:` fora de `WasmNeed`. O build da 518 (7990b7de) também recusa `needs:` numa forma Node ou Erlang e um `needs:` que não é lista; nenhuma decisão afirma nenhuma das duas, e nenhuma célula as fixa (a análise da Conformance do B-07).
- **Opções.** (a) Como proposto. (b) `needs:` noutra forma aceito e ignorado. (c) Um valor só aceito como lista de um elemento.
- **Recomendação.** (a).
- **Bloqueia.** Nada construído; duas células de recusa uma vez respondida.

## Frente 165 — rakun-workspace (o mantenedor, 2026-10-14)

#### mono-a · Um repositório `rakun`: um workspace de 17 pacotes plug-and-play; erika fora como `query` (decisões 326, 338, 391, 398, 433, 512; frente 165)
- **Respondida (o mantenedor, 2026-10-14; aguardando seu número em `decisions-taken.md`):** rakun, os consumidores do erika, emilia, styled, jhonstart, onze e dbcontext viram um repositório, `botopink/rakun`, um workspace do botopink (512): um diretório por pacote sob `modules/`, o pacote nomeado pelo seu diretório, cada um com o próprio `botopink.json`, `src/`, testes e `AGENTS.md`, as células sob `conformance/<package>/`, uma versão e tag, um gate, hook e CI. Os pacotes, por camada (cada um dependendo só de camadas abaixo, um ciclo recusado): `rakun` (núcleo) · `rakun-data` (dbcontext + rakun-data) · `rakun-restclient` (rakun-client) · `rakun-style` (styled) · `rakun-bpp` (jhonstart, -html, -link, -forms, -test, -dom-test) · `rakun-stylesheet` (emilia, jhonstart-emilia) · `rakun-service` (rakun-web, rakun-actuator) · `rakun-scheduling` · `rakun-session` · `rakun-cache` · `rakun-security` · `rakun-websocket` · `rakun-metrics` · `rakun-messaging` · `rakun-mail` · `rakun-app` · `rakun-ssr` (onze e seus oito). O erika continua um repositório próprio, renomeado `query` (uma DSL pura de consultas tipadas; a frente 145 continua como `query`); `css`, `actions`, `routing`, `validation`, `snap`, `markdown`, `http`, `log`, `json`, `yaml` continuam externos. Os `rakun-starter-*` saem; cada `*-test` vira o módulo `testing/` do seu pacote. **Plug-and-play:** adicionar um pacote ao `botopink.json` é tudo o que um programa faz — um pacote declara sua contribuição na raiz (`#[rakun.module] pub fn … -> Module`), o `rakun.boot()` descobre todo módulo das dependências do programa pelo catálogo, ordena por camada e os inicia com seus defaults e os overrides tipados do programa (`#[rakun.config]`); tudo resolve no build (uma coisa contribuída duas vezes, um pacote exigido ausente: erros de build que os nomeiam), nenhuma descoberta em runtime. Precisa do 144 B-86: `@TypeInfo.all` alcançando as declarações de uma dependência (seu catálogo exportado com a análise, o nível B o guardando). História preservada por `git subtree add`; os seis repositórios arquivados; os passos abertos das seis frentes refilados sob a 150 (frente 165 s8). Emenda a 326 (as bibliotecas como repositórios), 338, 391, 398 (dbcontext como repositório próprio), 433 (uma frente por repositório: a do rakun é a 150, com lanes por camada).
- **Contexto.** Levantada pelo mantenedor, 2026-10-14: sete repositórios para uma plataforma web, 40 pacotes finos e starters para combiná-los; nomes (erika, emilia, jhonstart, onze) que nada dizem do papel.

#### B-86-a · O `query` do gate lib-agnóstico, e o alcance do catálogo entre pacotes (144 B-86, frente 165 s4)
- **Proposta (opus, 2026-10-14; aguardando o mantenedor):** (1) o gate recusa `rakun` em qualquer caixa em qualquer lugar de `compiler-core/src`, e `query` só como pacote — a origem de import `"query"` ou o handle `import query`; (2) `jhonstart` sai da lista do gate, como a caixa diz; (3) a entrada do catálogo de uma dependência tem `module` = `<package>/<module>` (`plugin/root`), e as declarações de uma dependência transitiva também são listadas — construído assim, fixado por `modules/typeinfo_all_dependency_declarations`.
- **Medido.** `grep -riIE 'rakun|query' modules/compiler-core/src` casa cerca de 111 linhas: `query` é a palavra do próprio catálogo (`Query`, "a template body's query"). `@TypeInfo.all` já listava todo módulo do build, as dependências inclusas, e o journal do nível B já guarda `declared` e `meta`: a nova cell é verde no pai, em todo alvo, a frio e a partir do nível B. A referência diz "every module of the build", enquanto a decisão 242 deixa um programa importar só suas dependências diretas. Ordem e colisões seguem a regra existente (caminho do módulo, depois ordem de declaração; a chave é módulo e nome).
- **Opções.** (1)(a) ★ `query` só como pacote: `! grep -rIE '"query"|import query\b'`; (b) a palavra `query` em qualquer lugar, o vocabulário do catálogo renomeado. (2)(a) ★ `jhonstart` fora da lista (a caixa); (b) mantido até o 165 s2 renomeá-lo. (3)(a) ★ `<package>/<module>`, as dependências transitivas listadas; (b) só as dependências diretas listadas (a regra de import da 242).
  ```bp
  #[m] pub fn hello() -> string { "plugin" }   // in package plugin, module root
  // the program: @TypeInfo.all(with: m) lists { module: "plugin/root", name: "hello" }
  ```
- **Recomendação.** (a) para cada: (1) recusa toda grafia de pacote sem renomear a palavra própria da linguagem; (2) é o texto da caixa; (3) é o que `rakun.boot()` precisa — um módulo contribuído por um pacote duas camadas abaixo é descoberto.
- **Trava.** Nada — construído como (a); o 165 s5 lê (3).

#### B-98-a · Um `.bp` e um `.d.bp` de mesmo stem num pacote: recusados, ou um módulo? (144 B-98)
- **Proposta (opus, 2026-10-15; construída, aguardando o mantenedor):** (a) recusados na segunda entrada de `files` — "`"files" lists p.bp and p.d.bp, one module (`p`) written twice — keep one of the two files`" — como `x.bp` ao lado de `x.bpp` e ao lado de `x/mod.bp` já são.
- **Contexto.** O `botopink.json` de um pacote lista seus arquivos-fonte em `"files"`; um arquivo `.bp` guarda código, um arquivo `.d.bp` só declarações (funções de host, marcadores). Os dois se reduzem ao mesmo nome de módulo, então listar `p.bp` e `p.d.bp` fazia um caminho de módulo carregar duas vezes, e todo consumidor do pacote era recusado com uma duplicata que nomeava o mesmo módulo duas vezes. O 144 B-98 construiu uma recusa no manifesto; pede-se ao mantenedor que a confirme em vez de mesclar os dois arquivos num módulo.
- **Medido.** Os dois arquivos se reduzem ao stem `p` e eram carregados como dois módulos de um caminho: o checker guardava um, `crossModule.buildIn` contava os dois, então todo consumidor era recusado "declared `pub` by `p/p` and by `p/p`". O `src/rakun.d.bp` vazio do rakun ao lado de um `rakun.bp` novo disparou isso; nenhum manifesto sob `repository/` lista um par assim hoje.
- **Opções.**
  (a) ★ Recusado (construído).
  ```json
  { "files": ["rakun.bp", "rakun.d.bp"] }   // refused at "rakun.d.bp": "files" lists rakun.bp and rakun.d.bp, one module (`rakun`) written twice — keep one of the two files
  ```
  (b) Mesclado: as declarações do `.d.bp` e as do `.bp` são um módulo, um nome nos dois recusado.
  ```json
  { "files": ["rakun.bp", "rakun.d.bp"] }   // one module `rakun`; a name declared in both files refused
  ```
- **Recomendação.** (a): a leitura mais restritiva, um arquivo por módulo como as regras de gêmeos já dizem.
- **Bloqueia.** Nada — construído como (a); o 165 s5 remove o `rakun.d.bp` vazio do rakun.

#### B-99-c · A própria raiz de uma dependência pode chamar um default de catálogo? (decisão 551; 144 B-99)
- **Proposta (opus, 2026-10-15; construída como (a), aguardando o mantenedor):** (a): só o módulo raiz do pacote raiz pode omitir um default de catálogo; a raiz de uma dependência é recusada `typeinfo-all-default-outside-root` como qualquer outro módulo.
- **Contexto.** A decisão 551 torna uma chamada que omite um default `@TypeInfo.all` legal "só na raiz do pacote". Uma dependência também é um pacote, com raiz própria; a pergunta é se a raiz dela pode escrever tal chamada.
- **Medido.** Como construído, a raiz de uma dependência é recusada: uma chamada ali respondida para o programa faria a análise daquele pacote depender do programa, então ele não poderia ser guardado no nível B, e a 551 faz o nível B guardar o pacote que declara, nunca o que chama.
- **Opções.**
  (a) ★ Como construído: só o módulo raiz do pacote raiz.
  ```bp
  // in dependency `plugin`, src/root.bp
  import {boot} from "frame";
  pub fn start() { boot(); }   // refused: typeinfo-all-default-outside-root
  ```
  (b) A raiz de uma dependência pode chamá-la, e aquele pacote nunca é guardado no nível B.
  ```bp
  // in dependency `plugin`, src/root.bp
  pub fn start() { boot(); }   // answered for the program; `plugin` re-analysed on every build
  ```
- **Recomendação.** (a): a leitura mais restritiva, e segue o "o nível B guarda o pacote que declara, nunca o que chama" da 551.
- **Bloqueia.** Nada.

#### B-99-e · Onde fica um argumento do chamador que quebra um corpo genérico expandido? (decisão 562; 144 B-99)
- **Proposta (opus, 2026-10-16; construída como (a), aguardando o mantenedor):** (a): no argumento do chamador.
- **Contexto.** Uma função expandida no ponto de chamada (562) é copiada para o chamador; uma recusa dentro do código copiado fica no módulo que a declara, com a chamada como seu quadro called-from. Quando o corpo declarado é genérico e o erro de tipo vem do que o chamador passou, o erro poderia apontar para qualquer um dos dois lugares.
- **Medido.** `fn greet<T>(comptime who: @Expr<T>) { var count = who.value; val n: i32 = count + 1; }` numa biblioteca, chamada `greet("ana")`: recusada no argumento do chamador (`src/main.bp:4:11`), já que a cópia do argumento continua sendo nó do chamador.
- **Opções.**
  (a) ★ No argumento do chamador (construído).
  ```bp
  greet("ana");   // refused here: type mismatch, string where i32 is expected
  ```
  (b) No módulo que a declara, com a chamada como quadro called-from.
  ```text
  at greeter/root.bp:3:30   (count + 1)
  from src/main.bp:4:5
  ```
- **Recomendação.** (a): o valor em falta é do chamador, escrito no arquivo do chamador.
- **Bloqueia.** Nada.

#### 548-a · A referência de toda biblioteca linka seu código e checa os links? (decisão 548; 461, 463)
- **Contexto.** A referência de uma biblioteca — o `docs.md` ao lado das suas cells de conformance — mostra código. As decisões 461 e 463 apontam para o código de uma cell com `<!-- example: <cell> -->`; a decisão 548 (2026-10-15) faz a referência do rakun linkar o seu código em vez disso, como `{src/main.bp}`, e checa que todo link nomeia um arquivo que existe. Hoje só o rakun faz isso; as outras bibliotecas e o botopink-lang mantêm a forma antiga, e o runner que elas compartilham não conhece nenhuma das duas. A pergunta é se todo repositório segue o rakun.
- **Medido.** A decisão 548 faz a referência do rakun linkar seu código (`{src/main.bp}`, a base o diretório do `docs.md`) e o rakun checa todo link com seu próprio `scripts/check-doc-links.sh`, rodado pelo seu `repository-stages.sh`. As outras bibliotecas e o botopink-lang mantêm o `<!-- example: <cell> -->` da 461 / 463. O runner compartilhado (`runner-standalone.sh`, um texto entre as bibliotecas, check 4 da CI) não conhece nenhuma das formas.
- **Opções.**
  (a) ★ Toda biblioteca e o botopink-lang passam à forma da 548, a checagem de links no runner compartilhado (e `zig build test-docs` lendo `{path}`), uma frente por repositório.
  ```text
  conformance/<feature>/docs.md, in every repository:  {src/main.bp}   ← a link to a file that does not exist fails the gate
  ```
  (b) Só o rakun; os outros mantêm `<!-- example -->`.
  ```text
  rakun:                          {src/main.bp}
  other libraries, botopink-lang: <!-- example: <cell> -->
  ```
- **Recomendação.** (a): um só jeito de ler uma referência entre os repositórios.
- **Bloqueia.** Nada — o rakun é construído como a 548 diz.

#### 548-b · Os nomes de código que guardam o nome de uma biblioteca antiga (frente 165)
- **Contexto.** Depois da frente 165 os pacotes têm nomes novos — `rakun-stylesheet` para o emilia, `rakun-bpp` para o jhonstart, `rakun-ssr` para o onze (mono-a) — mas as funções, tipos, arquivos, URLs e prefixos de ambiente dentro deles guardam os nomes antigos das bibliotecas, então um usuário de `rakun-stylesheet` ainda chama `emilia()`. A pergunta é se um passo da frente 150 os renomeia para o vocabulário do pacote ou se eles ficam como a API.
- **Medido.** Depois do 165 os nomes de pacote são novos, mas o código guarda os antigos: `emilia()`, `emiliaWith`, `emiliaPlugin`, `emilia.bp`, a recusa `emilia-hash-split`, os sidecars `jhonstart_*.erl`, `OnzeConfig`, `Onze.run`, `ONZE_PUBLIC_`, `/_onze/`, `.onze`, `onze_main.bp`, os diretórios de exemplo `examples/rakun-stylesheet/emilia-*` e `examples/rakun-bpp/jhonstart-*`.
- **Opções.**
  (a) ★ Um passo do 150 os renomeia para o vocabulário do pacote (um codemod, todo consumidor e toda cell no mesmo commit).
  ```bp
  // a 150 step: `emilia()`, `OnzeConfig`, `/_onze/` … get rakun-stylesheet's and rakun-ssr's names; every consumer and cell in one commit
  ```
  (b) Ficam: os nomes são a API, só o nome do pacote mudou.
  ```bp
  // a program depending on `rakun-stylesheet` still calls `emilia()`; one on `rakun-ssr` still writes `OnzeConfig`
  ```
- **Recomendação.** (a): quem lê encontra um nome para uma coisa.
- **Bloqueia.** Nada.

#### 165-a · Onde ficam as linhas do conjunto de versões dos pacotes juntados (decisão 113; frente 165 s2)
- **Medido.** O `version_set.bp` do rakun guarda uma linha por pacote da família rakun; seu teste compara cada manifesto com a tabela. Após o 165 s1 o workspace tem 21 pacotes juntados (erika, emilia, styled, jhonstart, onze e seus `*-test` / subpacotes) sem linha: uma linha que nomeia `onze` no `src` do núcleo do rakun quebra o grep da decisão 113 (o núcleo do rakun não nomeia nenhum consumidor), então o teste lê só os manifestos `rakun*`.
- **Opções.** (a) ★ Nenhuma até o s2: após a renomeação todo pacote é `rakun-*`, as linhas são escritas então, e o filtro sai. (b) Um conjunto de versões fora do núcleo (um arquivo no nível do workspace que o gate lê), todo membro uma linha agora.
- **Recomendação.** (a): o s2 renomeia todo pacote para um nome `rakun-*`, então as linhas não precisam de exceção; uma versão para o workspace (o README) faz da tabela uma linha por pacote no s2.
- **Trava.** Nada antes do s2; o s2 escreve as linhas.

#### 165-b · Três pacotes fora da tabela do 165: `onze-server`, `jhonstart-dom-test`, `rakun-cli` (frente 165 s2)
- **Contexto.** A frente 165 junta sete repositórios num workspace `rakun` e dá a todo pacote um nome `rakun-*` e uma linha na sua tabela (mono-a). Três pacotes não couberam: `onze-server` e `jhonstart-dom-test` se juntariam a um pacote compilado para outro conjunto de alvos, e `rakun-cli` não tem linha. A linguagem define alvos por pacote, não por módulo nem por dependência, então o 165 s2 os deixou como pacotes próprios; a pergunta é como eles se chamam e se a tabela ganha as suas linhas.
- **Medido.** O 165 s2 dobrou todo pacote da tabela menos três. `onze-server` precisa do `rakun` (só erlang) enquanto `rakun-ssr` compila também para commonJS (seu CLI roda no node): dobrado, 21 vermelhos em commonJS (`rkReqLive` has no External for the node backend) — a linguagem não tem alvo por módulo nem dependência por alvo. Os externals de `jhonstart-dom-test` são só node enquanto `rakun-bpp` compila para erlang. `rakun-cli` não está em nenhuma linha da tabela. Construído: os três ficam pacotes próprios (`onze-server` dependendo de `rakun-ssr`, `rakun-app`, `rakun-service`; `jhonstart-dom-test` de `rakun-bpp`).
- **Opções.**
  (a) ★ Três pacotes nomeados na tabela: `rakun-ssr-server` (era `onze-server`), `rakun-bpp-dom-test` (era `jhonstart-dom-test`), `rakun-cli` como está, cada um sua linha com seus alvos.
  ```text
  modules/rakun-ssr-server/     was onze-server, needs rakun (erlang)
  modules/rakun-bpp-dom-test/   was jhonstart-dom-test, node-only externals
  modules/rakun-cli/            as it is
  ```
  (b) Uma feature da linguagem primeiro — o conjunto de alvos de um módulo ou de uma dependência — e os três dobrados em `rakun-ssr`, `rakun-bpp` (um passo do 144).
  ```text
  onze-server folded into rakun-ssr today: 21 commonJS reds — `rkReqLive` has no External for the node backend
  ```
- **Recomendação.** (a): um pacote é hoje a unidade de um conjunto de alvos; três linhas nomeadas mantêm a regra do 165 (todo pacote um nome `rakun-*`, uma linha cada) sem feature nova da linguagem.
- **Trava.** Nada; os nomes mudam na segunda caixa do s5 ou no s7.

## Parte 1 — O que bloqueia as trilhas 00–03

### 01-compiler

`00-gate` não tem pergunta aberta: os passos da 114 não esperam nenhuma decisão.

#### s29-a · Como uma anotação de template recebe a declaração anotada, e se ela também é um template de ponto de chamada (311)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — uma função de template que declara `comptime decl: @Decl` como seu segundo parâmetro é só uma anotação (`#[query "…"]`): chamada como `query "…"` é `template-annotation-only`, e um template sem esse parâmetro nunca é uma anotação (`template-annotation-without-decl`). A assinatura diz qual forma uma função toma, então nenhum ponto de chamada encontra um handle que não pode ter, e a 398 já escreve os dois usos como duas funções (`#[query "…"]` no dbcontext, `self.db.query "…"` no erika) — uma grafia por coisa; o `?@Decl` de (b) e o `q.decl()` de (c) fazem cada um uma função responder duas formas. Viável, construído: `member_fn.zig` `isTemplateAnnotation` / `isTemplateAnnotationParams`, `infer.zig` `checkTemplateAnnotations` e a recusa na chamada, células `template_annotation`, `template_annotation_called`, `template_annotation_without_decl` (comptime em wasm, uma resposta nos quatro alvos). Mudanças: o "uma função é ao mesmo tempo o template e a anotação" da 311 (2) é emendado para "uma função de template é uma coisa ou outra"; sob a 14s8-a (e) os buracos `${…}` da anotação são a gramática própria do template, cada nome emendado no membro construído e resolvido no escopo da declaração anotada (311), então a leitura de `q.parts()` de `template_annotation` é reescrita pelo passo que pousa a 14s8-a (e).
- **Medido.** A 311 deixa a grafia do `@Decl` para o `01-checker` passo 29 e diz "uma função é ao mesmo tempo
  o template e a anotação (`erika "…"` e `#[erika "…"]`)". Uma função de template é chamada só com
  seu literal (`f "…"`), então um parâmetro `@Decl` declarado não tem argumento num ponto de chamada; a 398 desde
  então dividiu os dois usos em duas funções (o `#[query "…"]` do dbcontext, o método de template
  `self.db.query "…"` do erika), então nenhuma biblioteca escreve uma função para ambos. Construído: o handle
  é o segundo parâmetro, `fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string>`
  (`member_fn.isTemplateAnnotation`); essa função é escrita só como anotação — `query "…"`
  é `template-annotation-only` na chamada (`reject/template_annotation_called`) — e um template
  sem o parâmetro em `#[f "…"]` é `template-annotation-without-decl`
  (`reject/template_annotation_without_decl`); o valor que o corpo devolve não é usado.
- **Opções.** (a) ★ O `@Decl` é um segundo parâmetro declarado, e uma função que o declara é
  só de anotação: `fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string> { … }`
  com `#[query "select …"] fn find(…)`, e `val x = query "select 1";` recusado. (b) O mesmo parâmetro
  como `?@Decl`, `null` num ponto de chamada, uma função para ambos:
  `fn erika(comptime q: @Expr<string>, comptime decl: ?@Decl) -> @Expr<Q> { if (decl != null) decl.setMeta(…); return q.build(…); }`.
  (c) Sem parâmetro: o handle é um método de captura, `q.decl()` respondendo `?@Decl`.
  Exemplo de (a):
  ```bp
  fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string> { … }
  #[query "select * from users where id = ${id}"]
  fn find(id: i32) -> string { … }
  val x = query "select 1";      // template-annotation-only
  ```
  Exemplo de (b):
  ```bp
  fn erika(comptime q: @Expr<string>, comptime decl: ?@Decl) -> @Expr<Q> {
      if (decl != null) decl.setMeta(…);
      return q.build(…);
  }
  ```
  Exemplo de (c):
  ```bp
  fn erika(comptime q: @Expr<string>) -> @Expr<Q> { val d = q.decl(); … }
  ```
- **Recomendação.** (a): a assinatura diz qual forma uma função toma, um ponto de chamada nunca encontra um
  handle que não pode ter, e a 398 já escreve as duas formas como duas funções; (b) se uma biblioteca precisar
  servir as duas formas com um só nome.
- **Bloqueia.** Nada — construído como (a) (`01-checker` passo 29).

#### s29-b · Como o decorator de um dono lê o meta tipado de um método (313)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído, lido como a 130-s8-a agora grafa** — o decorator do dono lê `m.meta(Query)` numa entrada de `decl.methods` e recebe `Query[]` (`[]` quando não há); `metaAll` vai embora. A leitura fica onde o dono já percorre seus métodos, tipada pelo record (298), e a leitura única da 130-s8-a (sempre uma lista) substitui o par `?T` / `metaAll`; (b) não é viável hoje (`inferTypeinfoRead` responde só `.name` e o meta de string, e o meta de um método não é publicado no `TypeInfo` — s23-f (b) primeiro); (c) refaz o trabalho do template em todo dono. Viável: `infer.zig` `inferMethodMetaRead` (tipa `?T` hoje), `runtime/prelude.zig` `__bp_methodMeta` / `__bp_methodMetaAll`, o `Method` de `builtins.d.bp`, célula `template_annotation`. Mudanças: a leitura `T[]` é um passo 144 próprio (o da 130-s8-a, antes do B-72, cuja caixa já nomeia `T[]`): `inferMethodMetaRead` e `inferTypedMetaRead` respondem `T[]`, os dois helpers do prelúdio viram um, `metaAll`, `typeinfo-meta-several` e `typeinfo-meta-repeated` saem de `builtins.d.bp`, `typed_meta.zig`, `syntax_param.zig`, `transform.zig` e `typeinfo_all.zig`, os textos das decisões 418 e 298 são emendados do mesmo modo; um defeito a registrar até lá: `m.meta(T)` sobre vários valores acrescentados responde silenciosamente o primeiro (`__bp_methodMeta` pega a cabeça) onde `@typeInfo(X).meta(T)` recusa.
- **Não viável (fable, 2026-10-12):** (b) — `inferTypeinfoRead` responde só `.name` e o meta de string, e o meta de um método não é publicado no `TypeInfo`; precisa primeiro dos métodos no `TypeInfo` da s23-f (b).
- **Medido.** A 313 tem `#[erika "…"]` / `#[query "…"]` e `#[nativeQuery(…)]` registrando "meta tipado do
  método (298)", e `#[repository]` no behavior "lê o meta de cada método"; a célula do passo 29 pede
  "uma anotação de método cujo meta um decorator de nível de tipo lê". Antes: meta tipado num método era
  `decorator-meta-on-member`, os decorators de um dono rodavam antes dos de seus métodos, e uma entrada de `decl.methods`
  carregava só nome, parâmetros, tipo de retorno e anotações. Construído: os decorators dos métodos de um tipo ou de um behavior
  rodam antes dos do dono; o `decl.setMeta(v)` / `decl.addMeta(v)` de um método é guardado para seu
  dono (um valor por tipo e método, `decorator-meta-twice`); o corpo do dono lê
  `m.meta(Query)` (`?Query`) / `m.metaAll(Query)` (`Query[]`) numa entrada de `decl.methods`, com `Query`
  escrito pelo seu nome declarado (`run/template_annotation`). O decorator de um campo ainda não registra meta;
  meta de string (216 (2)) num método continua recusado.
- **Opções.** (a) ★ Como construído: `for (decl.methods) { m -> val q = m.meta(Query); … }` em
  `#[repository]`. (b) O meta do método pela reflexão do dono, no build:
  `@typeInfo(Users).method("find").meta(Query)`, a ordem dos decorators inalterada. (c) Sem meta de método:
  o decorator do dono relê o literal da anotação do método em `m.annotations[i].args[0]` e
  o interpreta ele mesmo.
  Exemplo de (a):
  ```bp
  fn repository(comptime decl: @Decl) {
      for (decl.methods) { m -> val q = m.meta(Query); … }
  }
  ```
  Exemplo de (b):
  ```bp
  val q = @typeInfo(Users).method("find").meta(Query);
  ```
  Exemplo de (c):
  ```bp
  val sql = m.annotations[0].args[0];   // "\"select …\"" — every owner redoes the template's work
  ```
- **Recomendação.** (a): a leitura fica onde o decorator do dono já percorre seus métodos, tipada como
  `@typeInfo(X).meta(T)` é, e os fatos de um membro existem antes de seu dono lê-los; (c) duplica o
  trabalho do template em cada dono.
- **Bloqueia.** Nada — construído como (a); o `#[repository]` da `04-rakun/137` e da `143` o lê.

#### 130-s8-a · Um tipo de record ao mesmo tempo fixado e acrescentado numa declaração; `meta(T)` sobre valores acrescentados (298)
- **Respondida (o mantenedor, 2026-10-12; aguardando seu número em `decisions-taken.md`):** **Uma leitura, sempre uma lista: `meta(T) -> T[]`.** `@typeInfo(X).meta(T)` e o `d.meta(T)` de uma entrada de catálogo respondem todo valor do tipo `T` gravado na declaração, na ordem de gravação — `[]` quando nenhum, um elemento para um tipo setado uma vez (`@typeInfo(Home).meta(Route)` é `[Route("/", "GET")]`), vários para um repetido. `metaAll`, a resposta `?T` de `meta` e as recusas de leitura `typeinfo-meta-several` / `typeinfo-meta-repeated` saem. O lado de gravação mantém seus dois verbos: `setMeta(v)` grava um tipo no máximo uma vez numa declaração (um segundo `setMeta`, ou um `addMeta` ao lado, é `decorator-meta-twice` na anotação que o gravou) e `addMeta(v)` grava um que se repete.
- **Medido.** Construído: um tipo é mantido uma vez (`decl.setMeta(v)`) ou se repete (`decl.addMeta(v)`) numa
  declaração, nunca os dois — um segundo `setMeta` de um tipo, ou um `addMeta` ao lado de um `setMeta` dele, é
  `decorator-meta-twice` na anotação que o registrou (`reject/meta_twice`). `@typeInfo(X).meta(T)`
  responde `null` ou o único valor, e sobre vários é `typeinfo-meta-several` na leitura
  (`reject/meta_several`); `metaAll(T)` responde um valor fixado uma vez como um array de um elemento. A 298 nomeia
  `setMeta` "um valor por tipo" e `addMeta` "o que se repete", não os dois juntos. Numa entrada de
  catálogo `d.meta(T)` responde o primeiro valor (a leitura é código de execução sobre qualquer entrada).
- **Opções.** (a) Como construído: `decl.setMeta(Entity(…)); decl.addMeta(Entity(…));` é `decorator-meta-twice`
  no segundo; `meta(Index)` sobre dois `Index` é `typeinfo-meta-several`. (b) Um tipo registrado com
  `addMeta` é lido só com `metaAll` — `meta(Index)` recusado mesmo sobre um único `Index`
  (`typeinfo-meta-repeated`). (c) Os dois se misturam: `setMeta` mantém um valor entre os acrescentados, e
  `meta(T)` responde o fixado.
  Exemplo de (a):
  ```bp
  decl.setMeta(Entity(table: "a"));
  decl.addMeta(Entity(table: "b"));            // decorator-meta-twice
  @typeInfo(City).meta(Index)                  // typeinfo-meta-several with two Index
  ```
  Exemplo de (b):
  ```bp
  @typeInfo(City).meta(Index)                  // typeinfo-meta-repeated, even with one Index
  ```
  Exemplo de (c):
  ```bp
  decl.setMeta(Entity(table: "a")); decl.addMeta(Entity(table: "b"));   // meta(Entity) == "a"
  ```
- **Recomendação.** (a): uma chave com dois significados ao mesmo tempo é recusada onde é escrita; (b) se um
  leitor não deve depender de quantos decorators acrescentaram um tipo.
- **Bloqueia.** Nada — construído como (a).

#### 130-s8-c · Uma leitura de meta tipado de uma declaração que um leitor de `.hooks` deste módulo anota (298, 372)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(b′), provisória até o 144 B-55: um passo 4 em todo módulo.** Uma leitura de meta tipada `@typeInfo(X).meta(T)` é tipada onde está (`T[]`, 130-s8-a) e responde a meta inteira. Em outro módulo o import de `X` garante isso: o resolver termina o módulo de `X`, inclusive seus leitores de `.hooks` (372), antes de quem o importa. No próprio módulo de `X` a leitura é um valor pendente preenchido num passo 4, depois dos leitores de `.hooks` do módulo — o passo da raiz da s23-i, agora de todo módulo. Só uma leitura cujo valor é necessário no build antes desse passo (um `comptime`, o argumento de um decorator do mesmo módulo, a expansão de um template) é recusada, localizada, nomeando o decorator e pedindo a leitura a partir de um módulo que importa `X`. Substitui `typeinfo-meta-hooks-pending`. Se a análise do pacote inteiro do B-55 for adotada, isto vira sua regra geral sob demanda. **Sob a B-55-a (e)** (2026-10-12): o passo 4 é por bloco de módulos que se importam.
- **Medido.** Construído: a decisão 372 roda um decorator que lê `.hooks` depois dos corpos do módulo, e
  responde depois uma leitura de meta de string de sua declaração no módulo (`answerDeferredMetaReads`). Uma
  leitura tipada é uma expressão tipada onde está (seus construtores, campos `@Expr`), então é recusada
  nesse módulo antes de o leitor rodar: `typeinfo-meta-hooks-pending` na leitura; outro módulo a lê
  depois de o módulo inteiro rodar.
- **Opções.** (a) Como construído: `@typeInfo(Page).meta(Route)` no módulo da `Page`, com `#[route]` lendo
  `.hooks`, é `typeinfo-meta-hooks-pending`. (b) Adiada como a leitura de string: tipada como `?Route` na
  leitura, o valor escrito e tipado quando o leitor rodou — um erro de tipo num campo `@Expr` então localizado
  na segunda fase.
  Exemplo de (a):
  ```bp
  // #[route] reads .hooks
  @typeInfo(Page).meta(Route)   // typeinfo-meta-hooks-pending in Page's module
  ```
  Exemplo de (b):
  ```bp
  @typeInfo(Page).meta(Route)   // answered after #[route]
  ```
- **Recomendação.** (a).
- **Bloqueia.** Nada — construído como (a); o `#[page]` da `05-jhonstart/26` lê seu meta a partir do ponto de entrada.

#### 130-s8-d · Um record de meta genérico lido por uma entrada de catálogo (298)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Já respondida: decisão 420** ((a), como construído). Fechar removendo a entrada; quando o `T[]` da 130-s8-a pousar, o `metaAll(Check)` da 420 lê `meta(Check)` — a regra (um record genérico é lido por `@typeInfo(X)`, nunca por uma entrada de catálogo) não muda.
- **Medido.** Construído: `d.metaAll(T)` numa entrada de `@TypeInfo.all` chama uma função do módulo leitor
  tipada para `T` (`declared__metaAll__<T>`, `typed_meta.withMetaHelper`); uma genérica não pode ser escrita
  sem aplicação (`Check` de `Check<T>`), e um leitor genérico perde o `T` no wasm. `d.metaAll(Check)` é
  `typeinfo-meta-type` no argumento (`reject/meta_catalogue_generic`); `@typeInfo(X).metaAll(Check)`
  o lê (`run/meta_expr_field`). As entradas de um catálogo podem conter `Check<Signup>` e
  `Check<Login>`.
- **Opções.** (a) Como construído. (b) A leitura escreve os argumentos, `d.metaAll(Check<Signup>)`, e responde
  os valores registrados com exatamente esses. (c) A leitura responde `Check<unknown>[]`, seus campos tipados
  por `unknown`.
  Exemplo de (a):
  ```bp
  for (@TypeInfo.all(with: mark)) { d -> d.metaAll(Check) }   // typeinfo-meta-type
  ```
  Exemplo de (b):
  ```bp
  d.metaAll(Check<Signup>)
  ```
  Exemplo de (c):
  ```bp
  d.metaAll(Check)              // Check<unknown>[]
  ```
- **Recomendação.** (a).
- **Bloqueia.** Nada — construído como (a).

#### s28-a · O default de um campo de uma fonte importada que nomeia um binding de seu módulo (307)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Já respondida: decisão 421** ((a), como construído). Fechar removendo a entrada.
- **Medido.** Construído: `Type.omit(Link, .href)` sobre um `Link(…, rel: string = defaultRel())` importado
  copia o campo sem seu default — a regra que `registerExports` aplica ao parâmetro de uma função importada
  (`infer.isClosedDefault`): um literal, `true` / `false`, `null`, um sinal, um array ou tupla desses
  viaja, qualquer outra coisa não — então `NoHref(target: null)` é a recusa de campo ausente na
  chamada (copiá-lo fez o erlc falhar: `function defaultRel/0 undefined`). Um default de enum (`= .Blank`) também não é
  fechado.
- **Opções.** (a) Como construído: o default não viaja, o campo é fornecido em toda construção.
  (b) A derivação é recusada na chamada nomeando o campo (`derived-type-default-not-closed`).
  (c) O default viaja, o módulo derivador chamando a função do módulo de origem (um import implícito).
  Exemplo de (a):
  ```bp
  val NoHref = Type.omit(Link, .href);
  val n = NoHref(target: null);           // error at the call: `rel` is missing
  ```
  Exemplo de (b):
  ```bp
  val NoHref = Type.omit(Link, .href);    // derived-type-default-not-closed: `rel`
  ```
- **Recomendação.** (a): nenhum import implícito, nenhum valor silencioso; (b) se um tipo derivado precisar manter todo default.
- **Bloqueia.** Nada — construído como (a).

#### s28-b · `Type.required` sobre um campo com default `null` (307)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Já respondida: decisão 422** ((a), como construído). Fechar removendo a entrada.
- **Medido.** Construído: `required` tira o `?` de cada campo e descarta junto um default `null`
  (`description: ?string = null` → `description: string`, fornecido em toda construção); qualquer outro
  default permanece.
- **Opções.** (a) Como construído. (b) Recusado na chamada, nomeando o campo. (c) O default `null` permanece e
  o campo é recusado no construtor quando omitido.
  Exemplo de (a):
  ```bp
  val Full = Type.required(Recipe);   // description: string, without a default
  ```
- **Recomendação.** (a): "todo `?` sai" (types.bp), um `null` não pode tipar um campo não opcional.
- **Bloqueia.** Nada — construído como (a).

#### s28-c · O que um tipo derivado leva além dos campos (307)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Já respondida: decisão 423** ((a), como construído). Fechar removendo a entrada.
- **Medido.** Construído: o record derivado contém só os campos — os métodos, as cláusulas `implement`
  e as anotações de nível de tipo da fonte não vêm (`Type.pick(Recipe, .title)` não tem método de `Recipe`);
  as anotações do próprio `val` vão no tipo. A decisão 307 nomeia só "os marcadores dos campos da fonte".
- **Opções.** (a) Como construído: campos e suas anotações. (b) Os métodos cujos corpos leem só campos
  mantidos vêm também. (c) As cláusulas `implement` vêm, recusadas quando um membro de que precisam sumiu.
  Exemplo de (a):
  ```bp
  val T = Type.pick(Recipe, .title);   // T(title: string), without Recipe's methods
  ```
- **Recomendação.** (a): um tipo derivado é dado; o comportamento é escrito sobre ele.
- **Bloqueia.** Nada — construído como (a).

#### s28-d · Um record genérico ou um alias importado como fonte (307)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Já respondida: decisão 424** ((a), como construído). Fechar removendo a entrada.
- **Medido.** Construído: recusado no argumento (`derived-type-source-not-record`): um record com parâmetros
  de tipo (`Type.pick(Box, .item)` — `T` sem vínculo), e um alias de tipo importado (seu alvo é nomeado no
  escopo de seu próprio módulo). Um alias local de um record é esse record.
- **Opções.** (a) Como construído. (b) Uma aplicação de tipo como fonte, `Type.pick(Box<i32>, .item)`, os
  campos substituídos. (c) Um alias importado seguido através de seu módulo.
  Exemplo de (a):
  ```bp
  val P = Type.pick(Box, .item);        // Box<T>: refused
  ```
  Exemplo de (b):
  ```bp
  val P = Type.pick(Box<i32>, .item);   // P(item: i32)
  ```
- **Recomendação.** (a) até uma frente precisar de (b) ou (c).
- **Bloqueia.** Nada — construído como (a).

#### ctr-o · Decisão 146 contra a confirmação `lem-c`
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Confirmar `lem-c`, e ler a 146 junto com ela como uma só regra** — uma célula de host sem binding para o alvo (um `declare fn` livre ou um `declare fn` de um tipo) pode ser declarada; toda função com corpo, livre ou método, cujo corpo a alcança é recusada para esse alvo na expressão de chamada dentro desse corpo, chame-se ou não essa função. Os dois textos nomeiam um só comportamento: o "na sua declaração, chamada ou não" da 146 é a função recusada pelo próprio corpo, o "onde é chamada" da `lem-c` é onde fica o cursor; recusar a declaração do tipo proibiria um tipo declarado uma vez para vários alvos, e nada roda em silêncio de um jeito ou de outro (67). Viável, construído: `codegen/hostMethods.zig` `missingAt`, chamado na chamada em `commonJS.zig`, `erlang.zig`, `beam_asm.zig` e `wat.zig`; toda função com corpo é emitida, então a chamada falha chamada ou não; células `bodyless_method_without_binding`, `external_method_erlang_only`, `external_wrapper_keeps_refusal`, `std_asserts_host_cell_on_wasm`; `conformance/docs.md` já afirma as duas. Mudanças: a linha da 146 e a `lem-c` reescritas como a regra única acima (sem código); duas linhas 144 a registrar: em wasm um método de behavior com parâmetros de tipo é emitido só quando alcançado (`wat.zig`), então a 146 não vale ali; `hostMethods.binds(.wasm)` é `false` fixo, então um método de tipo que carrega uma célula `@External.Wasm(fn:` / `std:)` é recusado em wasm contra o `docs.md`.
- **Regras.** 146: uma função cujo corpo alcança uma função de host sem binding para o alvo "é recusada em sua declaração, chamada ou não". `lem-c` (construído, a confirmar): um método de host sem binding "é recusado onde é CHAMADO" — recusar a declaração era a opção não tomada; a 311 mantém o mesmo na chamada.
- **Recomendação.** Confirmar `lem-c` para uma declaração de host sem corpo (um tipo declarado uma vez ainda compila para um alvo que seu método não tem); declarar que a 146 rege qualquer função com corpo, livre ou método, que alcance uma; `docs.md` diz as duas coisas.
- **Bloqueia.** A confirmação de `lem-c`.

#### s23-j · O que a marca da 375 conta como "não consegue seguir", e um `@Component` de host
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **Um componente nunca é assíncrono por causa dos seus filhos.** Um componente é uma função que responde sua árvore (um array de nós, 388); compor outro componente — inclusive um valor recebido — só põe sua lambda na árvore. A marca `async` da 375 conta só o próprio corpo do componente: `await`, `async { }`, um hook assíncrono, uma chamada ao host que responde `@Task` / `@Component` (itens 2–5 como construídos). Um componente marcado responde uma Promise da sua árvore (uma máquina de estados no wasm, 140-e (d)); todo outro responde sua árvore direto. **A raiz é sempre assíncrona:** o render de um `#[page]` (e `renderToString`) percorre a árvore e faz await só nas lambdas marcadas. A marca transitiva (`subtreeAsync`: um componente que usa, direta ou indiretamente, um marcado; um componente recebido como valor contado a partir do argumento em cada uso, um valor desconhecido contado assíncrono) é calculada no build só como otimização, legível por decorators: falsa, um `#[page]` renderiza sem streaming e um `Suspense` emite seu filho direto, sem fallback; sem ela o renderer descobre ao descer, com a mesma resposta. O item 1 como construído (uma chamada por valor de função ou método que responde `@Component` marca o nó) sai. Amenda a 504 (140-e): seu renderer lê essa `subtreeAsync` de build onde ela é conhecida, e descobre ao descer só para um valor desconhecido.
- **Medido.** Construído e pousado (`infer.zig` `noteAsyncCall`, `finishHookNode`,
  `markHookAsync`): (1) uma chamada de um valor de função ou de um método torna o nó assíncrono só quando o
  tipo da chamada resolve para `@Component<R>` ou permanece uma variável de tipo aberta — `xs.length()`, um construtor de record e um
  método que responde `string` não tornam (da s23-d, respondida pela 389: "um `@Component` chamado por um valor de função ou um método");
  (2) um `use` de um hook de host e uma chamada de uma função de host que responde `@Component` contam como um host que responde
  `@Task` (`Component<R> extends Task`) — a `Page` de `run/decl_hooks_direct` (`use session()`, `declare fn
  session() -> @Component<string>`) é `async`; (3) uma chamada de uma função botopink que responde `@Task` sem
  `await` escrito não conta (`val t = loadComments();` mantém um valor Task); (4) um `await` ou `async { … }`
  escrito dentro de um lambda no corpo conta para o nó (o nó contém seus lambdas, 277); (5) um alvo sem
  nó publicado (uma declaração que a sessão não publicou) é assíncrono.
- **Opções.** (a) Como construído. (b) Qualquer chamada de um valor de função ou de um método torna o nó assíncrono, seja
  o que ela responder:
  ```bp
  fn Card(xs: string[]) -> @Component<Element> { val n = xs.length(); return Element(text: n.toString()); }
  // (a): Card sync, `function Card(map, xs)`; (b): Card async — every component reading a method is async
  ```
  (c) Um host que responde `@Component` é síncrono (só um host que responde `@Task` é nomeado):
  ```bp
  declare fn session() -> @Component<string>;        // #[@External.JavaScript("""Promise.resolve("alice")""")]
  fn Page() -> @Component<Element> { val u = use session(); … }
  // (c): Page sync, `const u = session()` — a Promise where a string is read
  ```
- **Recomendação.** (a): uma marca que nunca é falsa onde o commonJS precisa de um `await`, e verdadeira não mais ampla do que
  os tipos dizem.
- **Bloqueia.** Nada — construído como (a).

#### s23-c · O que o `Declared` de uma declaração alcançada guarda num corpo de decorator
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b), e a leitura de meta tipada** — num corpo de decorator o `value` de uma declaração alcançada (`h.hook.value`, `c.callee.value`, `n.function.value`) é recusado na leitura, localizado (`decl-hooks-value: a reached function is no value at build`), como o `value` de catálogo de um corpo de template é (`typeinfo-all-template-value`); seu meta é lido tipado — `h.hook.meta(Route)` → `Route[]` (298, 130-s8-a), respondido no build quando `Route` é dado e recusado nomeando o campo de run-time caso contrário (415 (3), 380) — nunca a lista de strings `<decorator>.<key>`. Recusar antes de aceitar (67): um `null` tipado como a função esconde que não há nada ali, e a 364 (3) já diz que uma função não tem valor no build; strings carregando os fatos de um decorator são o legado da 216 (2), que o próprio `builtins.d.bp` marca como de saída. Viável: a recusa de corpo de template em `infer.zig` (guardada por `env.inTemplateFn`) ampliada para um corpo de decorator, um id em `diagnostics.zig`; `hooks.zig` `declaredTerm` constrói o termo (escreve `value` como `undefined` e o `meta` de string, e não escreve a chave `typedMeta` hoje, então uma leitura direta de `typedMeta` provavelmente falha em run time — uma linha 144); a leitura tipada segue a regra de `meta_read_at_build` para dados. Mudanças: `Declared.meta: DeclaredMeta[]` sai com o meta de string; o comentário sobre `Declared` em `builtins.d.bp`; uma célula de recusa.
- **Medido.** `HookUse.hook`, `HookCall.callee` e `HookNode.function` são `Declared<unknown>`. Construído: `value` é
  `null` (nenhuma função do programa roda enquanto ele compila, 364 (3)), e `meta` é toda entrada que os decorators da
  declaração definiram até então, com chave `<decorator>.<key>` (`DeclaredMeta(key: "route.path", value: "/about")`). A leitura de `value`
  de uma entrada de catálogo no corpo de um template é recusada (`typeinfo-all-template-value`).
- **Opções.** (a) Como construído: `h.value == null` é `true`; `h.meta` lista `route.path`. (b) `h.value` recusado na leitura
  num corpo de decorator, como num corpo de template (`decl-hooks-value: a reached function is no value at build`); `meta` como
  (a). (c) (b), e `meta` guarda só as entradas do decorator que lê a lista (`path`), como uma entrada de catálogo
  guarda as de `d`.
- **Recomendação.** (b): recusar > aceitar; um `null` que passa na checagem de tipos como a função esconde que não há nada ali.
- **Bloqueia.** Nada — construído como (a).

#### s23-f · O `TypeInfo` de um argumento de tipo num `HookUse`
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(b), tipada.** Um `TypeInfo` traz as annotations de cada campo e os métodos do tipo, como `decl.fields` / `decl.methods` os dão (`t.fields[0].annotations` lista `#[validated]`); a sessão de build publica as declarações de tipo de cada módulo, então nenhuma lista vazia significa "não carregado". O tipo de um campo, de um parâmetro e de um retorno deixa de ser `typeName: string` / `returnType: string` e é um `TypeInfo<unknown>`, com `kind: TypeKind` (`Record`, `Enum`, `Primitive`, `Array`, `Optional`, `Tuple`, `Fn`, `Task` …) e `args: TypeInfo<unknown>[]` (`Array<string>` → `[string]`, `?i32` → `[i32]`), todos declarados no std (`builtins.d.bp`, espelhados no `type_info_src` do `comptime.zig`): `Field(name, type, annotations)`, `Param(name, type)`, `Method(name, params, returnType: ?TypeInfo<unknown>, annotations)`. Os argumentos de uma annotation continuam lidos pela meta tipada (s29-b).
- **Medido.** Construído: `typeArgs` dá o nome do tipo, seu módulo declarante (`""` para um primitivo ou do std), e os
  campos de um record como `Field(name, typeName, annotations: [])` — `params<main.BlogParams(slug: string, id: i32)>`;
  `methods` é `[]` e as anotações de um campo não são carregadas (o checker de um módulo importador guarda a forma
  do tipo, não sua declaração). A 293 lê os nomes e tipos dos campos.
- **Opções.** (a) Como construído. (b) As anotações de cada campo e os métodos do tipo, como `decl.fields` / `decl.methods`
  os dão — `t.fields[0].annotations` lista `#[validated]` — a sessão publicando as declarações de tipo de cada módulo.
- **Recomendação.** (b): o record é do `TypeInfo`, e uma lista vazia que significa "não carregado" é uma mentira.
- **Bloqueia.** Nada para a 293.

#### s23-i · Um catálogo de um leitor de `.hooks` lido no próprio módulo do leitor (372)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(d), uma quarta opção: o catálogo é lido só na raiz do pacote.** (1) `@TypeInfo.all` é lido só na raiz do pacote (`main.bp` num binário, `root.bp` numa biblioteca); em qualquer outro módulo é recusado, localizado, nomeando a raiz (``@TypeInfo.all` is read only in the package's root (src/main.bp) — move it there`). (2) Nenhum módulo do pacote importa da sua raiz — recusado, localizado (`src/pages/home.bp imports from the package's root (src/main.bp) — the root imports the package, never the reverse`) — então o resolver analisa a raiz depois de todo módulo que sua árvore de `mod` declara. (3) Na raiz, os catálogos são respondidos depois que os seus próprios leitores de `.hooks` rodaram (um passo 4 depois dos três da 372), então uma declaração decorada na própria raiz também traz sua meta. Nenhum catálogo é respondido antes do que ele lista: toda entrada traz sua meta inteira. Substitui `typeinfo-all-hooks-reader`. Um framework recebe o catálogo da raiz da aplicação como argumento (`jhonstart.serve(@TypeInfo.all(with: page))`), nunca o lê sozinho. **Todo pacote com fontes tem raiz** (o mantenedor, 2026-10-12): um pacote cujo `botopink.json` tem fontes declara `src/root.bp` (uma biblioteca) ou `src/main.bp` (um binário), e o resolver segue a árvore de `mod` a partir dela; o blind scan deprecated sai — um pacote com fontes e sem raiz é recusado, localizado, nomeando o arquivo que falta. Um manifesto sem fontes (o `"workspaces"` de um workspace, o manifesto de dependência de uma fixture) não precisa de raiz. `onze/examples/scaffold` move seu `root.bp` para `src/root.bp` ou seu manifesto nomeia onde fica sua raiz — escolha da frente 150 (a seção do onze, 150 s59 … s71); `json`, `yaml` e `dbcontext` nascem com `src/root.bp`. Medido no `feat` de cada biblioteca: todo outro pacote com fontes já tem uma. **`root.bp` declara a árvore, `main.bp` é a entrada** (o mantenedor, 2026-10-12; amenda a regra da raiz desta resposta): `mod` / `pub mod` são declarados só em `src/root.bp` e no `mod.bp` de uma pasta — nunca em `src/main.bp` nem em outro módulo (recusado, localizado: `declare the module tree in src/root.bp`). `src/root.bp` não é obrigatório: um pacote sem módulo além da sua entrada (um programa de um arquivo) tem só `src/main.bp`; um pacote com módulos tem `src/root.bp`; uma biblioteca tem `src/root.bp` e nenhum `main.bp`. `src/main.bp` contém `pub fn main()`, não é declarado por nenhum `mod`, importa o pacote como um consumidor, não é importado por nenhum módulo, e é analisado depois de toda a árvore e do `root.bp`. Nenhum módulo da árvore importa o `root.bp`. `@TypeInfo.all` é lido no `root.bp` ou no `main.bp` e recusado, localizado, em qualquer outro módulo. O prelude (116-a) é alcançado a partir do `root.bp`. **`src/lib.bp`, como o `lib.rs` do Rust** (o mantenedor, 2026-10-12; amenda as duas regras acima): a raiz do pacote se chama `src/lib.bp` — `root.bp` é renomeado em todo lugar (o do std, o de cada biblioteca, o do resolver, o da documentação — pelo passo que o entrega, à mão ou por um script avulso); `botopink migrate` é removido (o comando, `cli/migrate.zig`, seus testes e docs; 144 B-56) — e `src/main.bp` pode declarar `mod` / `pub mod` quando o pacote não tem `lib.bp`, como o `main.rs` do Rust: um pacote só com `main.bp` tem sua árvore ali; com `lib.bp`, o `lib.bp` guarda a árvore e o `main.bp` não declara `mod` (recusado, localizado: `declare the module tree in src/lib.bp`) e usa o pacote como um consumidor. Toda regra acima que nomeia a raiz lê `lib.bp`, ou `main.bp` quando não há `lib.bp` (o catálogo, o prelude da 116-a, nenhum módulo da árvore a importar). A análise do pacote inteiro permitindo que dois módulos se importem mutuamente é o estudo do B-55 da frente 144; até ele entrar, nenhum ciclo de import entre módulos. **Substituída pela B-55-a (e)** (o mantenedor, 2026-10-12): um arquivo é um módulo, sem `lib.bp` e sem `mod`; o catálogo é lido em qualquer módulo; o que fica aqui é a entrada `src/main.bp` de um executável.
- **Medido.** A 372 roda um leitor de `.hooks` depois dos corpos do módulo. `@TypeInfo.all(with: graph)` escrito no
  módulo de `#[graph] pub fn Page` é respondido quando o módulo é re-analisado, a partir do meta definido até então: o binário
  pai imprimia `Page 1` (`d.meta.length`), e com os leitores movidos para depois dos corpos a resposta imprimiria
  `Page 0` — o meta silenciosamente ausente. Construído: recusado, `typeinfo-all-hooks-reader` em `graph` em `with:`
  (`reject/typeinfo_all_hooks_reader`). Um catálogo em outro módulo (um ponto de entrada — os leitores de `@TypeInfo.all` são
  analisados depois de todos os outros módulos) carrega o meta do leitor; `@typeInfo(Page).meta.graph.count` no mesmo módulo
  é respondido depois de o leitor rodar.
- **Opções.** (a) Como construído: a consulta no mesmo módulo recusada no nome do decorator. (b) O meta da resposta de um leitor
  do mesmo módulo preenchido depois de o leitor rodar, como uma leitura de `@typeInfo(X).meta` é — `@TypeInfo.all(with: graph)`
  imprime `Page 1` no módulo da `Page`. (c) O meta de um leitor de `.hooks` nunca aparece numa entrada de catálogo (`meta: []`
  em todo lugar), lido só por `@typeInfo(X).meta`.
- **Recomendação.** (a) até uma frente precisar do catálogo no mesmo módulo; (b) é a resposta completa.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-c · Um buraco conhecido no build cujo valor lança lá
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(a), pela 14s8-a (e).** A expressão de um buraco é emendada no código gerado; quando o compilador a dobra no build (355 / 376) e ela lança, o build é recusado no buraco do usuário, localizado — nunca adiado para o render.
- **Medido.** Um buraco conhecido no build é avaliado no runtime de comptime como um `comptime` é (331). Construído: um lançamento é recusado no buraco — `pub val boom = raising "x"; pub val read = quote "${boom}";` (`raising` construindo `crash("x")`, que dá `@panic`) é ``this hole is known at build (decision 355) and its value raised there: the comptime block raised: {error,{panic,<<"crash: x">>}}`` em `${boom}` (`reject/hole_known_at_build_raises`).
- **Opções.** (a) Recusado no buraco (como construído). (b) O buraco é calculado na renderização (`known` falso): `read` constrói, e o programa lança quando lê `boom`.
- **Recomendação.** (a) — falhar > avisar, no build e não em tempo de execução.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-d · Um `comptime` que alcança uma função declarada depois dele que contém uma chamada de template
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a) até o 144 B-72, depois obsoleta pela B-55-a (e)** — a recusa fica como construída; a B-55-a (e) (5) analisa todo corpo de um bloco antes de seus decorators e de seus valores `comptime`, então uma função declarada depois do `comptime` já está expandida quando o `comptime` roda, e a recusa vai embora com a da 419 (caixa do B-72). O "inferir os corpos alcançados primeiro" de (b) é o que o modelo de blocos dá em geral; uma versão de um módulo só (o precedente de `sameLoweredFn` em `infer.zig`) seria o mesmo passo feito duas vezes. Viável: `block_eval.zig` `expandedFn` / `unexpandedTemplateCall`, célula `comptime_template_call_declared_after`; o B-72 os remove. Mudanças: nenhuma agora; `cep-a` (o gêmeo do caminho de seção, `comptime_section_path_declared_after`) vai na mesma caixa do B-72, que nomeia só a 14s8-d e deveria nomear as duas.
- **Medido.** As chamadas de template de uma função são expandidas quando seu corpo é inferido; um `comptime` carrega as expansões (`block_eval.zig` `expandedFn`). Uma função declarada depois do `comptime` ainda não tem nenhuma. Construído: recusado no `comptime` — `pub val early = comptime late();` acima de `fn late() -> string { return tag "b"; }` é ``the comptime reaches the template call `tag` at 14:12 in `late`, which is not expanded where the comptime runs — declare `late` before the `comptime` in this module`` (`reject/comptime_template_call_declared_after`).
- **Opções.** (a) Recusado, nomeando a chamada e o remédio (como construído). (b) O checker infere o corpo de toda função que um `comptime` alcança antes de o `comptime` ser avaliado, então a ordem das declarações não importa.
- **Recomendação.** (a) até (b) ser construída pelo `01-checker`; (b) não recusa nada de que um programa precise.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-e · Um `comptime` que alcança um componente que lê um contexto (`comptime padAll(2)`)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **`use` existe só no corpo de um `@Component`, e um hook é um `@Component<R>` — então um `comptime` ou um buraco nunca alcança um.** (1) Um hook é um componente que responde um valor: `pub fn usePad(n: i32) -> @Component<StyledProperty> { val cfg = use context(StyleConfig); return padAll(n, cfg); }`, lido num componente com `val p = use usePad(2);` (`use` o executa com o scope do corpo e responde `R`). (2) `use` escrito numa função que não responde `@Component<R>` é recusado no `use`, localizado (`use` is allowed only in a component's body — `padAll` answers `StyledProperty`). (3) Chamar um componente ou um hook sem `use` só cria sua lambda (504), então uma expressão solta nunca executa um `use`; só o renderer executa — no build também, com `RenderScope.root()`, onde `use context` lê o padrão declarado (388 (4)). (4) Um contexto é declarado e lido como a 354 (2) o escreve — `pub val styleContext = comptime createContext(StyleConfig(unit: 4));`, lido pelo tipo do seu valor `use context(StyleConfig)`, fornecido por `use provide(createContext(StyleConfig(unit: 5)))` — e seu valor é imutável (nenhum campo `var`; um que tenha é recusado, localizado), então ler seu padrão no build é seguro. (5) O styled mantém suas funções puras, a config um parâmetro (`padAll(n, cfg: StyleConfig = StyleConfig(unit: 4))`), calculadas no build num buraco ou num `comptime`; um componente lê `StyleConfig` com `use context(StyleConfig)` ou usa o hook `use usePad(2)`. O `use context(StyleConfig); sheet.add(…)` de hoje sai: as regras viajam como dado (`StyledProperty(className, rule)`), coletadas onde são usadas (355 / 377).
- **Medido.** A caixa do passo 8 lia `comptime padAll(2).rules` como recusado em `.contentHash(…)`; com
  `contentHash` carregado (passo 6, 341) a execução agora alcança o `styledPropertyComputed` do styled, cujo corpo
  é `val sheet = use context(StyledContext); … sheet.add(sheet.layer, …)` — um `comptime` não tem árvore
  de renderização (354 (3)), então nada provê `StyledContext`, e a execução parou em ``the comptime block calls
  `.add(…)` with 2 argument(s) at 144:11, which no primitive type … provides`` (botopink-lang, styled `feat`). A 376 (3) faz `context` ser `Any`, e a 355 / 376 (5) calculam
  `styled "${padAll(2)}"` no build — mas no build não há provedor para ler.
- **Opções.** (a) ★ Um `comptime` (ou um buraco calculado no build) que alcança um `use` numa função que
  carrega é recusado no `comptime`, nomeando o `use` e sua função: ``the comptime reaches `use
  context.context(…)` at 139:17 in `__bp_tpl_styled_styled__propertyComputed`, and a `comptime` runs with
  no render tree: nothing provides what the `use` reads (decision 354 (3))`` (`reject/comptime_reaches_use`); `padAll(2)` fica na renderização até o styled não ler
  contexto nesse caminho. (b) O build provê o default declarado de cada contexto (o do `StyledContext`), então
  `comptime padAll(2)` calcula com a folha default e seu registro é descartado:
  `val p = comptime padAll(2);` responde `StyledProperty(className: "s_…", …)` e nenhuma folha guarda a
  regra. (c) Um buraco que nomeia uma chamada que alcança um `use` nunca é conhecido no build (o `Any` da 376 exclui uma
  função que alcança um `use context`): `styled "${padAll(2)}"` é calculado na renderização, como hoje.
- **Recomendação.** (a) — recusar em vez de responder com um provedor que ninguém escreveu (67); (c) é o que o estágio do
  passo 36 do 01-checker dá quando pousar, e concorda com (a).
- **Bloqueia.** Nada — construído como (a) (`block_eval.useReached`); a caixa da chamada `Any` do passo 8 o lê.

#### 414-a · Uma chamada de componente num corpo: renderizada (128) ou o lambda (o exemplo da 414)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Respondida pela 504 e pela resposta da s23-j: uma chamada num corpo faz o lambda** — `val inner = notFoundLevel(chain, i, route, page);` num corpo de componente é o `@Component<Element>` não executado, posto na árvore (`ErrorBoundaryNode(child: inner)`) e executado pelo renderizador com o escopo que seu pai respondeu; só um `await c` escrito executa `c` no corpo (388 (4)); uma leitura de campo num valor sem `await` continua a recusa do checker. 504: "chamar um componente só faz seu lambda, só o renderizador o executa", "`<main>{view()}</main>` guarda o lambda de `view()`"; s23-j: "compor outro componente só põe seu lambda na árvore"; o "renderiza onde lido como `R`" de (b) é mais fraco e infere intenção do uso. Viável: `infer.zig` `inferComponentCall` (o splice de `await` por `env.indexRewrites`) e seu ponto de chamada saem, `noteAsyncCall` e `context_lower.zig` seguem; o renderizador do jhonstart na feat já escreve toda execução como `await` e guarda seus filhos como thunks (`ErrorBoundaryNode.child: fn() -> @Component<Element>`, que vira `child: @Component<Element>` sob a 504 e a lg2-n); commonJS, erlang e beam hoje, wasm com o 144 B-25 passo 4 (cuja caixa ainda lê a recomendação pré-504). Mudanças: a caixa de hooks do 144 B-17 toma a remoção do splice e reescreve as duas células que codificam o renderizar-na-chamada da 128 (`component_call_renders`, `component_call_awaited`; `component_is_lambda` fica); a entrada fecha como (b) na redação da 504.
- **Medido.** A cadeia da 128, mantida pela 388 (4) ("dentro de um corpo de componente `await c` roda `c` com o escopo
  de filhos do corpo"), renderiza uma chamada de componente escrita num corpo de componente: o checker insere `await` em volta
  dela (`inferComponentCall`), então `val inner = notFoundLevel(chain, i, route, page);` RODA `notFoundLevel` com
  o escopo dos filhos e `inner` é seu `Element`. O exemplo da 414 escreve a mesma linha com o comentário "o
  lambda, não rodado". Construído e pousado: a inserção vale; um corpo obtém um valor de componente não rodado
  nomeando a função (`itens.map(Card)`) ou por um lambda — o `ErrorBoundaryNode` / `NotFoundBoundaryNode` do jhonstart
  guardam `child: fn() -> @Component<Element>` (`{ -> notFoundLevel(…) }`), como o
  `suspense.Boundary` já fazia.
- **Opções.** (a) Como construído: uma chamada num corpo renderiza; um valor é um nome ou um lambda:
  ```bp
  fn caughtBelow(…) -> @Component<Element> {
      return nodePlaceholder(TreeNode.Errors(ErrorBoundaryNode(id: …, child: { -> notFoundLevel(chain, i, route, page) }, …)));
  }
  ```
  (b) Uma chamada num corpo faz o lambda onde seu valor não é lido como `R`, e renderiza só onde o
  checker o lê como `R` (uma leitura de campo, um argumento tipado `R`) — `val inner = notFoundLevel(…);` um lambda,
  `inner.tag` recusado sem `await`:
  ```bp
  val inner = notFoundLevel(chain, i, route, page);          // @Component<Element>, not run
  return ErrorBoundaryNode(id: …, child: inner, …);
  ```
- **Recomendação.** (a): uma regra para uma chamada num corpo (128, inalterada pela 388), sem inferir intenção a partir do
  uso; (b) muda o que o `val x = Card(…)` de todo corpo significa.
### 02-std-and-packaging

#### 97-s16-a · Onde ficam as tabelas geradas do `unicode`
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a) agora; sob a B-55-a (e) o arquivo é `libs/std/src/internal/unicode_tables.bp`** — até o 144 B-75 o irmão plano privado fica como pousado; quando o modelo de módulos pousar (B-69: um arquivo é um módulo nomeado por seu caminho, `mod` vai embora, `src/internal/` é privado a seu pacote) as tabelas geradas vão para `src/internal/`, `unicode.bp` escreve `import {internal.unicode_tables as tables};`, e o residual 11 fecha estruturalmente — um import do `internal/` do std a partir de outro pacote é recusado, localizado. (b) é obsoleta sob a (e) (sem `mod`, sem filhos de pasta a declarar); a privacidade que um `mod` não conseguia dar a pasta dá (67: estrutural, sem lista). Viável: a resolução de `mod` do `resolver.zig` e `collectStdModules` do `build.zig` hoje; a caixa de `internal/` do B-69 e a mudança do std no B-75 (`collectStdModules` percorre a árvore em vez de ler linhas `mod`; o gerador `libs/std/tools/unicode-gen` escreve o novo caminho). Mudanças: nenhuma agora; um defeito a registrar até o B-69: `import {unicode_tables} from "std"` compila (`resolver.zig` checa visibilidade só dentro do pacote que importa).
- **Não viável (fable, 2026-10-12):** (b) — obsoleta sob a B-55-a (e): não há `mod` nem filho de pasta a declarar quando um arquivo é um módulo nomeado por seu caminho.
- **Medido.** O `02/97` passo 16 nomeia `libs/std/src/unicode/tables.bp`. A árvore de módulos resolve um `mod Name;` só para `Name.bp` ou `Name/mod.bp` no diretório do arquivo declarante (`compiler-cli/src/cli/resolver.zig`, `build.zig` `collectStdModules`), então um módulo de arquivo `unicode.bp` não tem filhos: `unicode/tables.bp` é inalcançável a menos que `unicode` vire uma pasta, e um índice de pasta guarda só linhas `mod` e faz de `unicode` um namespace (`unicode.normalize` viraria `unicode.<sub>.normalize`, decisão 110). Pousado: um irmão plano `libs/std/src/unicode_tables.bp`, `mod unicode_tables;` (privado) em `root.bp`, `import {unicode_tables as tables};` em `unicode.bp`. O registro não respeita a privacidade do `mod`: o `import {unicode_tables} from "std"` de um consumidor resolve (resíduo 11 da 97 do compilador).
- **Opções.** (a) ★ Como pousado — um irmão plano privado:
  ```bp
  // root.bp
  pub mod unicode;
  mod unicode_tables;
  // unicode.bp
  import {unicode_tables as tables};
  ```
  (b) Um módulo de arquivo pode declarar filhos na pasta do seu próprio nome (o `unicode.rs` + `unicode/tables.rs` do Rust 2018) — uma mudança no resolver e no `build.zig`, `01-compiler/26`:
  ```bp
  // unicode.bp
  mod tables;            // → libs/std/src/unicode/tables.bp
  import {unicode.tables};
  ```
  (b) na forma `unicode/mod.bp`:
  ```bp
  // libs/std/src/unicode/mod.bp
  mod tables;
  pub fn normalize(s: string, form: Form) -> string { … tables.ccc(cp) … }
  ```
- **Recomendação.** (a): nenhuma mudança no compilador, um módulo a mais no registro; o resíduo 11 torna a privacidade real seja qual for a escolhida.
- **Bloqueia.** Nada (uma mudança de um arquivo gerado e do caminho de saída do gerador sob (b)).

#### nat-f3 · `files` e `workspaces` em `botopink.json` (98)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **`files` vai embora com o B-69 / B-75; `workspaces` fica (512)** — o que um consumidor pode importar é derivado da árvore: todo módulo sob `src/` fora de `src/internal/` (B-55-a (e) (8)); um manifesto que escreve `files` é recusado, localizado, nomeando `src/internal/` como o único jeito de manter um módulo privado; `workspaces` continua listando os membros de um workspace (512 (1)–(5): dependências e alvos compartilhados, um workspace de células por `conformance/modules/`). Duas grafias do que é distribuído (uma lista e a árvore) seriam dois jeitos de dizer uma coisa, e uma lista que esquece um módulo distribui uma biblioteca silenciosamente incompleta (67); a dependência da 270 em `files` já se foi com a 116-a (f) e a (e) (9) (o prelúdio é qualquer item `pub` marcado fora de `internal/`); o `#![internal]` de (b) não tem grafia (315) — a pasta é sua grafia. Viável depois do B-69: `compiler-cli/src/cli/libs.zig` carrega uma dependência a partir de `manifest.files` hoje e `shipsNothing` de `manifest/src/root.zig` recusa uma biblioteca sem ele, então os dois leem a árvore no lugar; `code_cache.zig` já chaveia o fechamento pelos arquivos da árvore (509 (3)); os três arquivos ambientes do std (`primitives.bp`, `builtins.d.bp`, `builtins_fns.d.bp`), listados no `files` do std hoje, são do próprio compilador e mantêm um lugar fixo em `libs/std`, não uma chave de manifesto. Mudanças: até o B-69 (a) fica como construído; as citações de `docs/botopink-json.md` da entrada estão defasadas (o manifesto está documentado em `modules/manifest/AGENTS.md`), e "um workspace recusa `dependencies`" é revertido pela 512 (2).
- **Não viável (fable, 2026-10-12):** (c) — `workspaces` é uma lista de membros (`modules/*`, `examples/*`, `*`) que nenhum código consegue derivar.
- **Medido.** `files` lista, relativo a `src`, os módulos que um consumidor pode importar; uma biblioteca sem ele não distribui nada (`docs/botopink-json.md:52`). `workspaces` lista membros; um manifesto com ele é um workspace e recusa `src`, `files`, `entry`, `dependencies` (`:159-170`) — os dois nunca dividem um arquivo (`98-packaging-tail/README.md:27`). A 270 depende de `files` (o prelúdio `src/prelude.bp` é listado ali).
- **Opções.** (a) Ambos mantidos — empacotamento, não código. (b) `files` derivado dos módulos `pub` (um módulo interno marcado em código — `#![internal]` não tem grafia desde a 315), 270 reescrita; `workspaces` mantido. (c) Ambos derivados.
- **Recomendação.** (a): o que é distribuído é um fato de empacotamento, e a 270 já depende dele.
- **Bloqueia.** 98.

#### nat-d9 · Os nomes do LINQ no erika ao lado dos do std (98)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), lida com a 312: a gramática é a única grafia pública do erika sobre um array, os métodos do std a outra; o `Query<T>` fluente com nomes do LINQ vira o alvo privado de lowering do erika** — `erika "select name from xs where active order by name"` (312: uma gramática, dois alvos) e `xs.filter(…)`, `map`, `flatMap`, `unique` do std são os dois jeitos de computar sobre um array; os 35 métodos públicos de `Query<T>` (`where`, `select`, `selectMany`, `orderByDescending`, `toList`, …) saem da API pública, mantidos privados como aquilo em que o template constrói; o erika não acrescenta operador fluente ao lado dos do std (o contexto da 137 já diz isso). Um só jeito de escrever cada coisa: hoje `xs.filter(p)`, `erika.of(xs).where(p)` e `erika "select * from xs where …"` são três grafias de uma leitura, duas delas nomes do LINQ para métodos do std (170: o std toma o nome natural, a cópia de uma biblioteca vai embora). Viável hoje, só erika: `erika/modules/erika/src/erika.bp` (os métodos de `Query<T>` viram `fn`s privadas, o lowering do pipeline do template continua a chamá-las), `erika-test` e `examples/erika-linq` reescritos para a gramática. Mudanças: um passo da 145 (uma renomeação e um passe de visibilidade, sem mudança no compilador); (b) e (c) mantêm dois modelos públicos de uma coisa contra a leitura caso a caso da 283.
- **Medido.** `98-packaging-tail/README.md:47-51`; `erika.bp`: `where`, `select`, `selectMany`, `orderByDescending`, `toList`; o erika é ansioso — todo operador materializa um novo array (`erika.bp:5`); o std tem `filter`, `map`, `flatMap`, `unique` (217).
- **Opções.** (a) Nomes do std (`filter`, `map`), o erika acrescentando só o que o std não tem (`groupBy`, os agregados). (b) Nomes do LINQ — a identidade do erika é o LINQ. (c) Como está.
- **Recomendação.** nenhuma desta revisão: o propósito do erika decide (b) é uma leitura justa.
- **Bloqueia.** 98 (erika).

### 03-bundled-libs

#### ctr-p · Confirmação `std-a` contra a confirmação `03r-e`
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Confirmar `std-a`; `03r-e` caduca, e os leitores próprios do rakun vão embora com ela** — um componente de query ou um pedaço de cookie cujo escape é malformado ou decodifica para um caractere de controle é recusado: `querystring.parse` / `parseForm` respondem `Error` (std, já é assim), `http.cookie.parse` / `get` respondem o pedaço como ausente enquanto o pedaço recusado ainda reivindica seu nome (196, 181); nada é mantido "como escrito". Recusar antes de aceitar (67), um leitor por header (196): o `queryDict` do rakun-app já lê queries por `querystring.parse` com `try`, então a metade de query da `03r-e` está morta; sua metade de cookie vive só nos cinco leitores do rakun (`request_context.bp` `decodeComponent`, `csrf.bp` `cookieValue`, `session_cookie.bp` `cookieFromHeader`, `i18n.bp` `cookieFrom`, `exchanges.bp` `sessionIdOf`), que a 196 apaga. Viável: `libs/std/src/querystring.bp` e `repository/http/src/cookie.bp` existem e recusam como dito; o rakun ainda não declara dependência de `http` — a adoção é o passo "consumir http" da 150 (rakun 04 passo 5). Mudanças: a linha `03r-e` da Parte 3 é revertida por esta confirmação; duas linhas 150 a registrar: `cookieFromHeader` pega a última duplicata contra 181 / 348 (a primeira vence), e os cinco leitores discordam sobre um mesmo header.
- **Regras.** `std-a`: `querystring.parse` / `parseForm` "recusam … um escape que decodifica para um caractere de controle", e o `splitQuery` do rakun passa a usá-los. `03r-e`: um componente de cookie ou de query que decodificaria para um caractere de controle "fica exatamente como escrito". A 196 move os leitores de cookie do rakun para o `http`.
- **Recomendação.** Confirmar `std-a`; `03r-e` caduca quando o rakun lê queries via `querystring` e cookies via `http`.
- **Bloqueia.** Os leitores da rakun 04; a varredura de consumidores da 104.

#### 396-a · onze-content: "um nó renderizado por um componente da própria página onde a página pede"
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), no onze-content, tipada pela árvore da 504** — `toElementWith(doc: MdDoc, render: fn(node: MdNode, kids: Node) -> ?Node) -> Element` ao lado de `toElement`: a função da página vê cada nó com seus filhos já renderizados e responde o nó a colocar — uma tag, um valor de componente (`<MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>` é o lambda não executado que o renderizador executa, 504) ou `null` para o elemento default; `Item`, `Row` e `Cell` também são nós, oferecidos por seus pais, e os parágrafos de uma lista compacta mantêm sua renderização `tight` quando o hook responde `null`. Uma função, um `case` tipado sobre os tipos de `MdNode` (281: o tipo é a variante, nunca uma string), nada por tipo a manter em dia com a árvore (o record de 21 campos de (b)); (c) continua disponível mas reproduz a contabilidade do mapeamento default em toda página. Viável hoje: `onze/modules/onze-content/src/element.bp` (`toElement`, `blockElement`, `inlineElement`, `itemElement`, `tableElement`, `rowElement` passam o hook adiante; o `MdNode` de `markdown/src/markdown.bp` é público); o `Node` do jhonstart é a união que um buraco aceita (223, 191) e um valor de componente nela é o da 504. Mudanças: a segunda caixa do passo 3 da 142; o "`toElement` do markdown" da entrada é do onze-content (396 (3): o markdown não nomeia framework).
- **Medido.** O passo 3 da 142 construiu `element.toElement(doc: MdDoc) -> Element` (todo `MdNode` para um elemento fixo, como o antigo `toElement`); a 396 (3) e a caixa do passo dizem que uma página pode renderizar um nó com um componente seu, e não fixam forma. Componentes são funções de um record de props (192/193), `Element`s são valores.
- **Opções.** (a) `toElementWith(doc, render: fn(node: MdNode, kids: Array<Element>) -> ?Element)` — uma função, `null` mantém o elemento default, a página casa os kinds de nó que quer (`Heading`, `Link`, `CodeBlock`, …). (b) Um record de funções opcionais por kind, `Components(heading: ?fn(depth, id, kids) -> Element, link: ?fn(href, title, kids) -> Element, …)`, um campo por kind de nó. (c) Percorrer o `MdDoc` na página e chamar `toElement` para os nós que ela não renderiza (sem hook; a árvore é pública).
  Exemplo de (a):
  ```bp
  val page = toElementWith(doc, { node, kids -> case node { Heading(depth, id, _) -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>, _ -> null } });
  ```
  Exemplo de (b):
  ```bp
  val page = toElementWith(doc, Components(heading: { depth, id, kids -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo> }));
  ```
- **Recomendação.** (a): uma leitura, nenhum campo por kind para manter em compasso com a árvore; (c) não precisa de código e está disponível hoje.
- **Bloqueia.** A segunda caixa do passo 3 da `142` (só o hook; o mapeamento default está construído).

#### 07-g · Renderização de release OTP
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como um repositório `botopink/release`** — uma biblioteca de renderizadores puros (`.rel`, `vm.args`, `sys.config`, o boot script, o Dockerfile e a unit do systemd) escrita em botopink para todo alvo, importada por `rakun-cli` e `onze-release` (242); cada um mantém só o que é seu (os caminhos de actuator e o env de cookie do rakun, a execução de processo `assembleRelease` do onze). Dois consumidores satisfazem o teste da 115, e a 326 faz de um novo pacote compartilhado um repositório, nunca um embutido no compilador; (b) não serve ao onze-release (sem alvo erlang); (c) mantém dois renderizadores cujos bytes já diferem (as versões de `kernel` / `stdlib` do `.rel`, as flags do `vm.args`), duas respostas para um release. Viável: `rakun/modules/rakun-cli/src/release/release.bp` (`renderRel`, `renderVmArgs`, `bootScript`, `renderDockerfile`, `renderSystemdUnit` são texto puro; `renderSysConfig` chama o host Erlang `rkRelTerm` e precisa do escritor de termos `.bp` que a primeira caixa do s1 da 107 pede) e `onze/modules/onze-release/src/otp.bp`; o `.gitmodules` da meta, o § Layout e a checagem 4 do CI carregam o repositório como carregam `json` / `yaml`. Mudanças: a 107 abre como escrita (seu s1 reproduz as duas linhas byte a byte a partir de um renderizador); o `rakun-release` da entrada é `rakun-cli` desde a 187.
- **Não viável (fable, 2026-10-12):** (b) — uma funcionalidade do CLI não serve ao onze-release, que não tem alvo erlang.
- **Medido.** `rakun-release/release.bp` (para dentro do `rakun-cli` sob a 187) e `onze-release/otp.bp` renderizam o mesmo `.rel` / `vm.args` / `sys.config` / script de boot / Dockerfile; o onze não pode reutilizar o do rakun (rakun só erlang, onze-release também commonJS).
- **Opções.** (a) Um `release` embutido de renderizadores puros. (b) Um recurso do CLI `botopink` (02). (c) Deixar os dois.
- **Recomendação.** (a); o CLI pode adotar o pacote depois.
- **Bloqueia.** `107-release` (uma frente condicional: respondê-la ou adiar a 107).

### Escolhas de implementação das trilhas 00–03

Cada uma implementada com sua opção recomendada; o mantenedor confirma ou reverte (uma reversão é uma
mudança local no lugar nomeado). Texto completo da 1.0.10 sob o mesmo id em
[`../1.0.10-beta/decisions-pending.md`](../1.0.10-beta/decisions-pending.md).

#### 01-compiler (28)

| Id | Escolha implementada | Onde |
|---|---|---|
| 01c-a | O átomo de um módulo comptime é `bp@comptime@<owner path>__tpl__<decl>__<hash>` | comptime |
| 01c-b | Uma folha de seção aceita a forma abreviada de ponto inicial onde o tipo da posição é essa seção; sem expectativa, é recusada nomeando sua seção | checker |
| ck2-b | Um membro de seção pode dividir nome com uma variante de nível superior do mesmo enum (o caminho e o tipo da posição os distinguem); uma variante declarada duas vezes num nível é `enum-variant-duplicate` | `modules/enum_section_leaf_beside_variant` |
| ck2-d | Um rótulo numa chamada de um valor de função é `label-on-function-value` | `reject/label_on_function_value` |
| ck2-e | Um decorator do std é alcançado pelo seu handle de módulo (`#[<handle>.<fn>]`); um import folha de um é `std-decorator-leaf-import`; `#[<handle>.<not a decorator>]` é `unknown-annotation`; o handle ainda é necessário depois da 216 (o texto `addType` / `addMember` de `mocks.mock` nomeia `mocks.invoke`, `testing/mocks.bp:212-220`), enquanto 282/289 já importam como folha decorators de outras bibliotecas | checker |
| rc3-b | `unknown` é a grafia do vocabulário do host onde havia `any` (testado com `is` antes do uso) | `run/host_unknown_parameter` |
| rc3-c | Atribuir a um `var` estreitado checa contra seu tipo declarado e encerra o estreitamento | `reject/narrow_ends_at_assignment` |
| 0405-b | O `__bp_show` do commonJS imprime `undefined` como `null` | prelúdio do commonJS |
| onze F7 | Inteiro `/` inteiro trunca em direção a zero e é um inteiro em todo alvo (`7.0 / 2.0` continua `3.5`); `docs.md:961-963` já o declara | `run/integer_division_truncates` |
| lem-a | Um método de host é um método real de seu tipo cujo corpo é o binding, nunca inlinado no ponto de chamada | `codegen/hostMethods.zig` |
| lem-b | `inline: true` (grafia da 305; o código ainda escreve `inline = true` até o 01-checker passo 27) no `External.Erlang` / `Beam` de um método de tipo é aceito, não muda nada (recusá-lo cabe ao 01-checker acrescentar; recomendado: recusar) | `run/external_method_local` |
| lem-c | Um método de host sem binding para o alvo é recusado onde é chamado (`MissingExternal` nomeando `Type.method`); o wasm recusa todo método de host; um receptor sem tipo falha em tempo de execução (`ctr-o`) | `hostMethods.missingAt` |
| lem-d | Um nome por operação em todo tipo (`Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`); construtores continuam funções de módulo | `io.net` · `regex` |
| lem-e | Helpers privados que recebem um tipo continuam livres (`tlsEchoOnce`, `rkvPush`, `putMessageSource`, `messageSourceOr`) | std · `validation` |
| lem-f | O commonJS adota um record construído pelo host em sua classe (`__bp_adopt`) diretamente e por `?T`, arrays e o lado ok de um `@Result`, não por `@Task` | `run/external_method_on_host_record` |
| cep-a | Um caminho de seção (`.Pad.All.8`) numa função deste módulo declarada depois do `comptime` que a alcança ainda não tem reescrita (o corpo é inferido depois), então (a) o `comptime` é recusado nomeando o caminho, seu `line:col` e a função — "declare `later` before the `comptime` in this module" — como o passo 8 da 14 recusa uma chamada de template ali; (b) inferiria tal função antes do `comptime`, dentro do corpo sendo inferido. Recomendado: (a) | `block_eval.unresolvedSectionPath` · `reject/comptime_section_path_declared_after` |
| cep-b | A função de um decorator local que escreve um caminho de seção (`fn fallback() -> Tok { return .Pad.All.8; }`) é inferida antes da execução, uma vez, como a 371 infere uma que escreve `same` (`infer.sameLoweredFn`), e carregada reescrita; (b) recusaria o decorator na anotação nomeando o caminho. Recomendado: (a) — não existe remédio para (b) além de mover a função para outro módulo | `infer.sameLoweredFn` · `run/comptime_decorator_section_value` |
| cep-c | O record de um módulo comptime é seu mapa sem tag, então (a) `v is Rule` e um braço que nomeia um record testam suas chaves declaradas — `is_map(V) andalso is_map_key(selector, V) andalso is_map_key(decl, V)` — e um record de outro tipo com essas chaves responde `true`; (b) carregar o tipo no mapa (`#{'__bp_type' => 'Rule', selector => …}`), uma mudança de todo termo comptime que os avaliadores leem e respondem; (c) recusar `is` / um braço de record no runtime de comptime onde dois records carregados dividem suas chaves. Recomendado: (c), o mais estrito; (a) implementado, nenhuma célula tem dois desses records | `codegen/erlang.zig` `untypedRecordTest` · `run/comptime_record_pattern` |
| 388-b | `c.run(scope)` responde `@Task<Rendered<R>>` para todo componente (a marca da 375 não está no tipo), declarado no `Component<R>` de `builtins.d.bp`; o `context` do std declara `pub type Rendered<R>(value: R, scope: RenderScope)` e `pub type RenderScope(frames: unknown)`, sua construção recusada fora do std (`render-scope-construction`) já que o botopink não tem construtor privado | `infer.inferComponentRun` · `context` do std · `run/component_run_root`, `reject/render_scope_construction` |
| 388-c | O "fora de todo corpo um valor roda com `c.run(RenderScope.root())`" da 388 (4) lido como o que `await c` significa ali: um `await` de um valor de componente numa função simples, `main`, um teste ou um lambda o roda com `RenderScope.root()`; (b) o recusaria, nomeando `c.run(RenderScope.root())` — todo teste e `main` que aguarda um componente seria reescrito | `context_lower.zig` · `run/component_run_root` |
| 139-b | A superfície do `bigint` é o `behavior BigInt` de `primitives.bp`, ao lado dos métodos de todo outro primitivo, e não um `type bigint` em `builtins.d.bp` como o README da frente disse primeiro: o parser recusa um método `self` num `type` sem campos (`namespace-type-self`), e um `declare fn` estático ali é uma linha de builtin `@` de `builtins.zig`. `bigint.of(n)` / `bigint.parse(text)` são primitivos de host associados da forma da decisão 262 (a de `String.fromCodepoint`), escritos pelo nome do próprio tipo (o checker renomeia o receptor `BigInt`); `BigInt.of(n)` também tipa, como `String.fromCodepoint` faz. (b) ensinaria ao parser e ao teste de deriva um `type` primitivo com métodos | `primitives.bp` · `infer.inferPrimitiveStaticCall` |
| 388-d | O backend wasm recusa um módulo que o lowering de escopo alcançou, em seu primeiro componente (`the wasm backend does not lower a component yet`), até o lowering da 05: toda célula de componente é um `.wasm.expect` (32 células; `run/decl_hooks_*` entre elas, que rodavam no wasm sob o mapa da 354) | `wat.zig` `refuseScopeLowering` · `language-gaps.md` 354-wasm |
| 388-e | Um corpo que mantém um `try` solto roda os statements depois de seu último `use provide` como um closure interno, cuja resposta (o valor, ou o erro que o `try` devolve cedo) é o resultado; todo outro corpo responde `rendered(v, kids)` em cada `return` | `context_lower.zig` `lowerComponentBody` · `run/component_try_in_body` |
| 389-a | Uma função declarada cujo próprio retorno não é um `@Component` que responde um por seus argumentos de tipo (`first<T>(cards)`) é o "o que o código genérico responde" da 389: uma aresta com `callee: null`, o nó assíncrono, nenhuma marca síncrona na chamada | `infer.noteHookCall` · `run/decl_hooks_dynamic_call` |
| s29-c | As saídas de uma anotação de template nomeiam um buraco por sua expressão como escrita (o placeholder `__bp_hole_q_0` do `code` da parte vira `id` num meta registrado ou fonte de membro); `q.fail` / `q.failAt` / `decl.fail` e um `lookup` de um nome que não está no texto são reportados na anotação (o literal não tem mapa de spans ali); seu `DeclAnnotation.args` é o literal como escrito; `decl.params` lista `self` | `infer.unplaceholderContributions` · `decorator_eval.annotationPlans` · `run/template_annotation` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01c-a:** confirmar só como nome e chave de cache: o esquema (`__tpl__`, e `__dec__` para um decorator) vive em `template_eval.zig` `ownerId` e `decorator_eval.zig`, lido por `crossModule.erlDeclAtom` / `decodeAtom`; o módulo comptime ainda é escrito como texto Erlang que `runtime/wat/erl_parse.zig` e `lower.zig` abaixam para wasm (434) — o "comptime" do Onde é esse caminho, nenhum runtime BEAM.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01c-b:** confirmar (a leitura da 369 e da 382 de um caminho de ponto inicial sob um tipo de seção esperado; não remedido).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — ck2-b:** confirmar (célula `enum_section_leaf_beside_variant`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — ck2-d:** confirmar (célula `label_on_function_value`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — ck2-e:** reverter para uma só regra para todo pacote (386): um decorator do std é importado como o de uma biblioteca é — por folha (`import {testing.mocks.mock} from "std"`, escrito `#[mock]`) ou pelo seu namespace (`#[mocks.mock]`) — e `std-decorator-leaf-import` vai embora; `#[<handle>.<não decorator>]` continua `unknown-annotation`. Duas regras de import para um mesmo tipo de coisa é o que a 386 removeu para as bibliotecas; o texto de `#[mocks.mock]` nomeando `mocks.invoke` é uma mensagem a corrigir, não uma razão. Viável: `infer.zig` `registerStdDecorators`; células `std_decorator_leaf_import` (vira célula de execução), `std_decorator_unknown_through_handle`, `std_decorator_through_namespace`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — rc3-b:** confirmar (célula `host_unknown_parameter`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — rc3-c:** confirmar a regra; a célula `narrow_ends_at_assignment` agora fixa uma recusa de leitura de opcional (`v is read off an optional ?Node — write ?.v`), não uma atribuição encerrando um estreitamento — uma linha 144: a célula é remedida e reescrita para sua afirmação (458 (2)).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 0405-b:** confirmar (`codegen/js/js_prelude.zig` `__bp_show`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — onze F7:** confirmar (célula `integer_division_truncates`; o texto está em `conformance/docs.md` § operadores agora).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-a:** confirmar (`codegen/hostMethods.zig`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-b:** reverter para a recomendação: `inline: true` no `@External.Erlang` de um método de tipo é recusado na anotação, localizado — uma flag aceita que não muda nada é uma mentira (67); o checker já recusa um `inline` não lido em `Node` / `Wasm` / `Typescript` (`infer.zig` `refuseUnreadInline`) e `hasExternalInline` é lido só pelo dispatch de primitivas, então a recusa é mais um braço ali; o passo 27 do 144 B-02 a toma, a célula `external_method_local` reescrita de `inline = true` para uma célula de recusa.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-c:** confirmar, como a regra única da `ctr-o` (`hostMethods.missingAt`); o braço wasm `binds(.wasm)` fixo em `false` é a linha 144 da `ctr-o`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-d:** confirmar (`libs/std/src/io/net.bp`; `regex.bp` `Regex.matches`); uma linha 144 de std a pesar: o `regex.matches(pattern, input)` livre ao lado de `Regex.matches` é uma segunda grafia de um mesmo teste.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-e:** confirmar; emendar o Onde: `tlsEchoOnce` é do std (`io/net.bp`), `rkvPush`, `putMessageSource` e `messageSourceOr` são do `validation` (`src/binding.bp`, `src/messages.bp`) desde a 326.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — lem-f:** confirmar (`js_prelude.zig` `__bp_adopt`; célula `external_method_on_host_record`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — cep-a:** confirmar até o 144 B-72, que a remove com a recusa da 14s8-d (uma caixa para as duas; `block_eval.unresolvedSectionPath`, célula `comptime_section_path_declared_after`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — cep-b:** confirmar (`infer.sameLoweredFn`; célula `comptime_decorator_section_value`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — cep-c:** (c), a recomendação, como uma linha 144: no runtime de comptime um record ainda é um mapa sem tag (o módulo comptime é texto Erlang abaixado para wasm; `erlang.zig` `untypedRecordTest`, `is_map_key` servido pela biblioteca de termos do std-wasm) e `v is Rule` testa chaves, então dois records de comptime que compartilham suas chaves respondem `true` um pelo outro — uma resposta silenciosamente errada (67). Proposta: `is` e um braço de record sobre um valor de comptime são recusados, localizados, onde dois records carregados para esse módulo comptime compartilham um mesmo conjunto de chaves, até o comptime carregar o tipo ((b), a resposta completa, sob necessidade medida); a checagem fica onde o módulo é emitido (`erlang.zig` `emitComptimeModule` conhece os records que carrega). Viável hoje; uma célula de recusa ao lado de `comptime_record_pattern`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-b:** confirmar (`infer.inferComponentRun`; `context.bp` do std `RenderScope` / `Rendered`; células `render_scope_construction`, `component_run_root`); sob a resposta da s23-j um componente não marcado responde sua árvore diretamente em run time e `await` sobre ele é no-op (375 (3)) — o tipo `@Task<Rendered<R>>` continua são porque `await` é sempre legal.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-c:** confirmar (`context_lower.zig` `bpScopeRoot__`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 139-b:** confirmar (501; `primitives.bp` `behavior BigInt`, `infer.inferPrimitiveStaticCall`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-d:** confirmar até o 144 B-25 passo 4 (504: composição por dados em wasm); emendar a contagem: 38 células carregam uma partida `snapshot/targets/wasm/main.snap` "does not lower a component" (a forma `.wasm.expect` saiu com a 457), todas saindo com o B-25 (458: uma partida nunca registra um defeito — essas são a linha 354-wasm do `language-gaps.md`, que o B-25 fecha).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 388-e:** confirmar (`context_lower.zig` `lowerComponentBody`; célula `component_try_in_body`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 389-a:** confirmar (`infer.noteHookCall`; célula `decl_hooks_dynamic_call`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — s29-c:** confirmar (`infer.unplaceholderContributions`, `decorator_eval.annotationPlans`; célula `template_annotation`); o placeholder `__bp_hole_q_0` é reescrito pelo passo que pousa a 14s8-a (e) (s29-a).

##### 24-c · `iter for` / `iter while` são um `loop` com prefixo (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — açúcar sobre o `loop` com prefixo, o rótulo nomeando o `for` escrito (`LoopExprOf.prefixedKeyword`, `yield-label-not-generator`; células `iter_loop_and_for`, `yield_label_loop`): a equivalência que a 125 escreve, nenhum nó novo de backend (quatro lowerings a manter de acordo seriam o custo de (b) por nada). Viável, construído; sem mudança.
- **Medido.** O README da frente pediu um novo nó `GenLoop { kind, loop }`; mas cada um dos quatro backends já baixa uma forma de laço anotado (o `loop` da 22-loops), e a própria decisão 125 diz que `iter for (xs) { … }` significa `iter loop { for (xs) { … }; break; }`. O parser o lê assim e guarda a palavra-chave escrita em `LoopExpr.prefixedKeyword`, para o formatador devolvê-la. O rótulo fica onde a decisão 105 o escreve, depois da palavra do laço.
  Hoje:
  ```bp
  iter for (xs) { x -> yield x * 2; }      // read as: iter loop { for (xs) { x -> yield x * 2; }; break; }
  iter loop :l { yield :l 1; }             // the label names the generator
  iter for :l (xs) { x -> break :l; }      // the label names the written `for`
  iter for :l (xs) { x -> yield :l x; }    // error[yield-label-not-generator]
  ```
- **Opções.** (a) ★ Açúcar sintático sobre o `loop` com prefixo; o rótulo de `iter for :l` nomeia o `for` (então `break :l` / `continue :l` mantêm seu significado de sempre).
  ```bp
  iter for :l (xs) { x -> if (x < 0) { continue :l; }; yield x; }   // continue of the `for`
  ```
  (b) Um novo nó `GenLoop`, com um lowering próprio em cada um dos quatro backends — o mesmo fonte, mais quatro caminhos para manter em acordo.
  ```bp
  iter for (xs) { x -> yield x * 2; }      // becomes GenLoop { kind: For, loop: … } down to the backend
  ```
  (c) Como (a), mas o rótulo de um `for` com prefixo nomeia também o gerador — o parser só move o rótulo para o nó de fora.
  ```bp
  iter for :l (xs) { x -> yield :l x; }    // compiles: `:l` is the generator's scope
  ```
- **Recomendação.** (a). É a equivalência que a decisão 125 já escreve, sem nenhum backend novo.
- **Bloqueia.** Nada (as confirmações do passo 2 da `01-compiler/24`).

##### 23-b · As quatro funções do `base64` aposentadas, não aliasadas (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — as quatro aposentadas; `encoding.base64Decode` / `base64UrlDecode` respondem `@Result` (`libs/std/src/encoding.bp`, `base64.bp` removido): nenhum alias escondendo uma recusa (67). Viável, construído; sem mudança.
- **Medido.** `base64.decode` respondia uma `string`; seu substituto `encoding.base64Decode` responde `@Result<string, string>` porque a frente 01 valida a entrada antes de o `Buffer.from` truncá-la (idem `decodeUrlSafe` → `base64UrlDecode`). Nenhuma biblioteca importava `base64`. O `base64.bp` foi apagado e seus quatro testes reescritos com os nomes do `encoding` (o std mantém 417 testes). A decisão 106 e `01-std/modules.md` já nomeiam os substitutos.
  Hoje:
  ```bp
  val s = try encoding.base64Decode(text);     // @Result<string, string>: validates before decoding
  base64.decode(text)                          // no longer exists
  ```
- **Opções.** (a) ★ Aposentar as quatro (`encode` / `decode` / `encodeUrlSafe` / `decodeUrlSafe`).
  ```bp
  val raw = try encoding.base64UrlDecode(token);
  ```
  (b) Manter as quatro no `encoding` como aliases que respondem `string` (escondem a recusa).
  ```bp
  val s = encoding.decode("not base64!");   // answers a truncated string, no error
  ```
- **Recomendação.** (a). Duas grafias de um mesmo codec, uma delas escondendo a recusa, é o que a frente 01 removeu.
- **Bloqueia.** Nada (as confirmações do passo 2 da `01-compiler/23`).

#### 02-std-and-packaging (10)

| Id | Escolha implementada | Onde |
|---|---|---|
| 01std-a | Uma biblioteca embutida carregada pelo CLI e pelo LSP (`appendBundled`), não por `expandStdImports`; o compiler-core não nomeia nenhum pacote além de `std` | `build.zig` `bundled_packages` |
| 01std-c | O padrão vazio de `routing.pattern` casa só com `/`; o rakun-web mantém "vazio roda em todo lugar" em seu ponto de chamada (`matcherAdmits`) | `routing` |
| 01std-e | `actions.readEnvelope` recusa um `redirect` que discorda de `n` | `actions` |
| std-a | `querystring.parse` / `parseForm` respondem `@Result`, recusam um escape malformado, não-UTF-8 e um caractere de controle cru ou decodificado; `stringify` recusa um caractere de controle; `parse` é RFC 3986 (`+` permanece), `parseForm` o sabor de formulário (`ctr-p`) | `libs/std/src/querystring.bp` |
| std-b | `fs.exists` segue um link simbólico (link pendente é `false`) | `io/fs.bp` |
| 95-a | A frente 95 realocou `jhonstart-link` e `rakun-app` como movimentos sem comportamento | jhonstart · rakun |
| 95-b | `rakun-app` declara seu próprio `"targets": ["erlang"]`, como todos os 36 manifestos do rakun fazem (opção (b); o "herda o workspace" da 1.0.10 não é o que o código faz) | manifesto do `rakun-app` |
| 95-c | `erika-test` existe | erika |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01std-a:** confirmar a regra (o compiler-core não nomeia pacote além de `std`: `comptime.zig` `bundledPackage`); emendar a linha: o conjunto embutido é só `std` desde a 326 (`build.zig` `bundled_packages`), e `appendBundled` não existe mais (sobrevive só em `compiler-cli/src/cli/AGENTS.md` e `language-server/AGENTS.md`, duas linhas defasadas para o 144).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01std-c:** confirmar (`routing/src/pattern.bp`; `rakun-web/src/middleware.bp` `matcherAdmits`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 01std-e:** confirmar (`actions/src/envelope.bp` `readEnvelope`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — std-a:** confirmar (`libs/std/src/querystring.bp`); sua contraparte de cookie é a da `ctr-p`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — std-b:** confirmar (`libs/std/src/io/fs.bp` `exists`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 95-a:** confirmar (os dois membros existem).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 95-b:** reverter sob a 512 (3): `targets` é herdado do workspace e um membro o escreve só para estreitar; as 31 listas `["erlang"]` idênticas do rakun (o "36" está defasado) vão embora na varredura de manifestos da 150, o manifesto do workspace mantendo a única declaração — um lugar para um fato.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 95-c:** confirmar (`erika/modules/erika-test`).

##### 24-g · A forma do `std/async` com uma Task que nunca falha (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído** — `allOf` / `all` / `race` sobre tasks iniciadas, `runAll` / `raceOf` / `timeout` sobre thunks, `failed(message)`; cada forma tem um nome (67), e o guia e a suíte da 24 já o escrevem; a 432 depois fez um `@Task<@Result<T, E>>` rejeitar, o que não muda nome algum aqui. Viável, construído: `libs/std/src/async.bp` (o módulo desde então ganhou `Gate`, `delay`, `RetryPolicy`, `retry`). Mudanças: nenhuma; a nota dos `beam_memory_*` (uma task erlang roda eagerly) é o defeito da lg2-b, não desta escolha.
- **Medido.** Antes da frente 24, o `std/async` tinha uma superfície de thunks (`allOf`, `settleOf`, `raceOf`, `timeout`) e uma de Tasks já iniciadas (`all`, `allSettled`, `race`), as duas construídas sobre "Task rejeitada = falha". Agora uma Task nunca falha (decisões 120 e 121): o erro vai DENTRO, `@Task<@Result<T, E>>`. O guia escreve `try await async.allOf([fetchUser(1), fetchUser(2)])` — Tasks já iniciadas cujo valor é um `@Result` — e a suíte da frente 24 segue o guia; as células `beam_memory_*`, porém, precisam de thunks não iniciados, porque no erlang uma Task ansiosa já rodou quando o combinador a recebe. A implementação deu à forma do guia o nome `allOf` e aos thunks outros nomes.
  Hoje:
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);   // started Tasks of @Result: stops at the first Error
  val xs = await async.runAll([{ -> work(1) }, { -> work(2) }]);     // thunks: this is where the concurrency is
  val r = await async.timeout({ -> slow() }, 100);                   // timed out → Error("timeout"), a string
  ```
- **Opções.** (a) ★ Iniciadas: `allOf`, `all`, `race`; não iniciadas: `runAll`, `raceOf`, `timeout`; `failed(message)` responde `Error(message)`; `allSettled`, `settleOf`, `unwrapAll` e `attempt` foram removidos (não há rejeição para "settle"). Um crash dentro de uma task é relançado.
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);
  async.allSettled([…])          // no longer exists
  ```
  (b) `allOf` sobre thunks, como o README da `01-std/02` o escreveu — o exemplo do guia é reescrito com thunks.
  ```bp
  val users = try await async.allOf([{ -> fetchUser(1) }, { -> fetchUser(2) }]);
  ```
  (c) Um `allOf` sobrecarregado para as duas formas de elemento — exige sobrecarga por tipo, que a linguagem não tem.
  ```bp
  async.allOf([fetchUser(1)])            // started
  async.allOf([{ -> fetchUser(1) }])     // thunks — same name, another signature
  ```
- **Recomendação.** (a). Segue o guia e a suíte da frente 24, e cada forma tem um nome.
- **Bloqueia.** Nada — o README da `01-std/02-std-async-primitives` (1.0.10) já especifica `allOf` sobre Tasks iniciadas (`02/97` passo 5 — o `RetryPolicy` construído sobre o `std/async`, um resíduo — e `01-compiler/24` passo 2).

##### std-c · O namespace de pasta da decisão 110 é uma reescrita do programa lido (*implementado como (a)*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a) até o B-69, que decide o destino da pasta** — a reescrita fica (`comptime/std_namespace.zig`); sob a B-55-a (e) (1) um módulo é nomeado por seu caminho e nada diz que uma pasta é um valor, então o B-69 declara uma regra para `import {io} from "std"`: proposta, a forma folha `import {io.fs} from "std"` é o único jeito e uma pasta não é importável (uma grafia, e nenhuma reescrita que possa perder um membro — `io.nope.f()` hoje é `unbound variable 'io'`, um diagnóstico que não nomeia nada); o tipo de namespace de (b) não é necessário então. Viável: o B-69 (a nomeação de módulos do resolver) e a remoção de `std_namespace.zig`. Mudanças: uma caixa no B-69; o namespace de pasta da decisão 110 emendado por ela.
- **Medido.** A decisão 110 permite `import {io} from "std"` e depois `io.fs.readText(…)`. A implementação (`comptime/std_namespace.zig`) reescreve o programa já lido para as formas folha que o checker e os quatro backends já baixam: `io.fs.f()` vira o namespace de `io/fs` (o item `io.fs as __bp_ns_io_fs` é acrescentado), e `collections.Dict` vira `Dict`. Só os módulos alcançados são importados. Limites: um membro ausente é `unbound variable 'io'`; um módulo que declara seu próprio `Dict` de nível superior mantém `collections.Dict` sem reescrever (recusado do mesmo jeito); um local com o nome da pasta (`fn f(io: …)`) não é distinguido dela. (A alternativa da 23-a entrou por aqui.)
  Hoje:
  ```bp
  import {io} from "std";
  io.fs.readText(path)       // rewritten to the leaf import `io.fs`; only the modules reached are imported
  io.nope.f()                // unbound variable 'io'
  ```
- **Opções.** (a) ★ A reescrita: um arquivo, nenhum backend tocado.
  ```bp
  import {collections} from "std";
  val d = collections.Dict.empty();   // runs on the four targets
  ```
  (b) Um tipo de namespace no checker e um lowering de `a.b.f()` nos quatro backends, para o diagnóstico nomear a pasta.
  ```bp
  io.nope.f()                // error: std folder `io` has no module `nope`
  ```
- **Recomendação.** (a). (b) só se o diagnóstico que nomeia a pasta for desejado.
- **Bloqueia.** Nada (as confirmações do passo 2 da `01-compiler/23`); uma reversão abre um passo no `01-checker`.

#### Escolhas feitas pelas threads do 00-gate e pela consolidação (5)

| Id | ★ implementado | Onde |
|---|---|---|
| 111-b | o carregador sidecar do beam é emitido só quando o build liga uma função de host (13 snapshots mudaram); o backend erlang segue a mesma regra (`buildBindsErlangHost`) | botopink-lang `codegen/beam_asm.zig` |
| 113-a | um alvo que o `botopink test` não consegue rodar (wasm hoje — ele roda commonJS, erlang e beam) é `NOT RUNNABLE` e falha o `test-libs`, como o item 3 de `fronts.md` § Gate exige | `scripts/test-libs.sh` |
| 113-b | a auditoria de restrições casa a recusa por seu texto (alternativa, recomendada: dar um id à recusa — 07-residuals) | `lib-test-runner` |
| 110-b | o histórico de contagens saiu de `tests/language/AGENTS.md` | `tests/language/AGENTS.md` |
| 112-a | o `TREES` do `format-check` guarda `examples` como uma entrada mais `modules/manifest/tests` | `scripts/format-check.sh` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 111-b:** confirmar; emendar o nome: o lado erlang é `codegen/crossModule.zig` `bindsErlangHost` (o lado beam `beam_asm.zig` `bindsBeamHost` / `buildBindsBeamHost`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 113-a:** confirmar como construído (`scripts/test-libs.sh` conta `skipped_unsupported` como NOT RUNNABLE e falha; `test_cmd.zig` recusa só `.wasm`); duas linhas defasadas para o 144: a legenda do script ainda diz "(beam, wasm)", e a coluna wasm do `botopink test` é do B-25 / 97 s11.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 113-b:** reverter para a alternativa: a recusa ganha um id (`host-binding-missing`, ao lado do `std-unsupported-on-target` da 334 (3)) e a auditoria casa o id, nunca o texto (`lib-test-runner/src/runner.zig` `HOST_BINDING_MARK`) — uma mensagem reescrita passaria em silêncio pela auditoria (67). A 510 não a toca (a auditoria dispara um build, sem store).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 110-b:** obsoleta: `tests/language/` saiu com a 466 (conformance na árvore); o arquivo não existe.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 112-a:** confirmar como está agora: `TREES=(examples libs/std modules/compiler-cli/tests modules/manifest/tests conformance)` — `examples` uma entrada; emendar a linha.

#### 03-bundled-libs (4)

| Id | Escolha implementada | Onde |
|---|---|---|
| 106-b | `log.consoleSink` escreve uma linha por registro na saída padrão por `@print` em todo alvo (não o `console.error` / `console.warn` do node, não o `logger` do OTP) — o único stream que um programa wasm também escreve; `defaultSink` mantém o logger do host | `repository/log/src/sink.bp` |
| 106-c | `log.fileSink` rotaciona como o `logger_std_h` do OTP faz, escrito uma vez em botopink sobre quatro células: depois que uma escrita deixa o arquivo em `maxBytes` ou mais, o arquivo vira `<path>.0`, cada arquivo morto sobe um, `<path>.<maxFiles - 1>` é apagado, `maxFiles` 0 apaga o arquivo; uma chamada de host que falha lança; o teto de tamanho total do rakun continua do rakun (dobrado em `maxFiles`) | `repository/log/src/logfile.bp` |
| 106-d | Níveis por nome: `Threshold { From(level), Off }`, `Levels(root, names)`, vale o prefixo pontuado mais longo definido; um nome vazio, um segmento vazio e um nome definido duas vezes são recusados (um `Error` quando um sink é construído, um panic quando resolvido); grupos e overrides em tempo de execução são do framework (ele reconstrói os `Levels` e instala um sink de novo) | `repository/log/src/levels.bp` |
| 106-e | `log.captureRuntimeReports()` observa e nunca trata: BEAM um filtro `logger` primário no domínio `otp` que repassa o evento inalterado (o handler do próprio OTP ainda o imprime), node `uncaughtExceptionMonitor` (o node ainda sai; `unhandledRejection` chega como sua origem sob o modo default do node), registros do logger `runtime` com `report.kind` (e a pilha do node sob `error.stack_trace`), wasm um binding no-op | `repository/log/src/reports.bp` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-b:** confirmar (`log/src/sink.bp` `consoleSink`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-c:** confirmar a rotação; emendar "uma chamada de host que falha lança": sob 431 / 486 / 495 as quatro células de arquivo (`appendLine`, `fileBytes`, `moveFile`, `removeFile`) carregam `result: true` e `fileSink` / `appendRotating` respondem `Error` do enum de erro próprio do `log`, nunca um raise — a auditoria do 144 B-08 nomeia as células, a 156 toma a mudança do consumidor.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-d:** confirmar (`log/src/levels.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 106-e:** confirmar (`log/src/reports.bp`; sua célula wasm já é `fn: captureNothing`, 481).

#### Escolhas feitas pela thread bugs-sweep (4)

| Id | ★ implementado | Onde |
|---|---|---|
| bs-a | Uma fn associada de um tipo é chamada como a fn de um módulo do std é (`planQualifiedCall`): uma chamada curta é preenchida dos defaults declarados, uma rotulada é reordenada, qualquer outra contagem é o erro de aridade. `fn of(x: string, y: string = "d")` — (a) ★ `Bag.of("p")` é `Bag.of("p", "d")`; (b) recusar a chamada curta, `'of' expects 2 argument(s), got 1` (antes, toda contagem exceto a exata caía num fallback que não checava nada e não preenchia nada) | `infer.zig` `associatedCallReturnType` · `run/associated_fn_of_type_default` |
| bs-b | Um tipo sem sinal não aceita literal negado: `val x: u32 = -1;` — (a) ★ recusado no literal, ``the literal `-1` does not fit `u32` (at least 0)``; (b) aceito, e a checagem em tempo de execução da 264 aborta na negação (`-0` é aceito nos dois casos) | `infer.zig` `refuseIntegerOutOfRange` |
| bs-c | Um `erl` que imprimiu o banner de seu break handler (`BREAK: (a)bort …`) é uma execução interrompida mesmo saindo com 0 (SIGINT, depois EOF no stdin para o emulador com status 0): nunca guardado no cache de runtime — o único lugar em que o harness lê a saída, e só para decidir não cachear. (a) ★ o banner a marca como `.interrupted`; (b) iniciar `erl +Bi` (SIGINT ignorado): a execução termina e é genuína, mas uma execução travada então sobrevive ao Ctrl-C até o timeout de 2 minutos | `codegen/runtime.zig` `classifyEnd` |
| bs-d | `scripts/check-docs.sh --lib-root <dir>` substitui as raízes de biblioteca default; o teste do harness nomeia as suas. O gate mantém o default, que faz o hash de todo pacote irmão inteiro — `repository/vscode-extension` carrega um `botopink.json`, então um link simbólico em seu `node_modules` faz toda checagem de docs ficar `never stored` no checkout meta (um custo, nunca um veredito). (a) ★ como está; (b) as raízes default tomam só um pacote com `src` (o manifesto do vscode-extension é `{ "name", "version" }`); (c) o hash da árvore pula `node_modules` | `scripts/check-docs.sh` · `modules/compiler-cli/tests/result_store.sh` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-a:** confirmar (`infer.zig` `planQualifiedCall` / `associatedCallReturnType`; a célula é `associated_fn_of_type_default`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-b:** confirmar (`infer.zig` `refuseIntegerOutOfRange`; a mensagem agora cita a 319).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-c:** confirmar a classificação (`codegen/runtime.zig` `classifyEnd`); o cache que ela guarda — o cache de saída de runtime chaveado por conteúdo do harness dos testes de snapshot do compiler-core, que pula uma execução de `erl` / `node` num acerto — é o que a 510 proíbe lida ao pé da letra ("todo teste roda em toda checagem"): proposta, esse cache vai embora (uma linha 144), sujeito ao mantenedor confirmar que a 510 alcança os testes do próprio compiler-core; a bs-c então não tem objeto.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — bs-d:** obsoleta: `check-docs.sh` não aceita `--lib-root` (suas opções são `--doc`, `--list`, `--self-test`; ele checa que as referências `<!-- example: … -->` nomeiam células existentes, 461), e o result store e `result_store.sh` saíram com a 510.

#### Escolhas de outras trilhas de que um passo 00–03 espera

| Id | Escolha implementada | Onde |
|---|---|---|
| 03r-q | O roteamento de locale vive em `rakun-app/src/i18n.bp`; nenhum membro `rakun-i18n` | 22 |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-q:** confirmar (`rakun-app/src/i18n.bp`; nenhum membro `rakun-i18n`).

---

## Parte 2 — O resto

### Prioridade — a forma botopink (`nat-*`)

#### nat-d · Um segundo modelo do que a linguagem tem — caso a caso (decisão 283)
Nenhuma regra geral (283): cada caso abaixo é sua própria pergunta, (a) o da própria linguagem, (b) ambos — o estrangeiro uma camada fina sobre o nativo — ou (c) como está.

#### nat-d6 · `throw "nav:not-found"` ao lado de `noreturn` (53)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), tipada: `notFound() -> noreturn`, `redirect(url) -> noreturn`, o sinal um valor `NavOutcome`, capturado por tipo, nunca por um prefixo `nav:`** — os dois sinais do jhonstart lançam `NavOutcome` (`NotFound`, `Redirect(url)`) pela sua única célula de host (`__jhRaise` carregando o valor: um `Error` que o guarda em commonJS, `error({jhonstart_nav, Outcome})` em erlang) e respondem `noreturn`, então `throw notFound();`, um `notFound();` solto e `val s: string = if (c) "a" else notFound();` todos checam (lg2-l: o código já tem `noreturn` como tipo bottom); um boundary lê o valor capturado com `case` sobre `NavOutcome` (`renderNotFound` captura só `NotFound`, `renderErrorBoundary` relança qualquer `NavOutcome`, 414 (2)); uma action redireciona pelo seu `@Result` — `ActionError` ganha `Redirect(url: string)` (303 emendada; 303 See Other no wire), sem raise. 281 (um fato de código nunca viaja como string), 67 (o boundary casa um tipo, um prefixo mal escrito não escapa), e o teste de string de `isSignalReason` vai embora; (b) mantém a string sob um invólucro; (c) mantém `-> string` para um valor nunca produzido. Viável agora: `jhonstart/modules/jhonstart/src/error_boundary.bp` (`__jhRaise`, `notFound`, `redirect`, `__jhCapture`), `signal_runtime.mjs` / `jhonstart_signal.erl`, o `navigation.bp` do rakun-app (`rkNavSignal`, `-> i32`), o `ActionError` do `actions`; medido na feat que uma célula de host `declare fn raise(reason) -> noreturn` checa e roda em commonJS e erlang. Mudanças: a linha "navigation signals do not return `noreturn`" do `language-gaps.md` fecha (seu texto está defasado: `throw notFound();` já checa); `31-a` (Parte 3) vira `-> noreturn`; wasm segue a forma wasm das células (B-25); quando `attempt` pousar (B-07) o try de host dos boundaries é o da 431, o `NavOutcome` ainda lido por tipo.
- **Medido.** Um sinal é uma string com prefixo `nav:` lançada pelo host (`contracts.md` § 5b); `notFound()` / `redirect()` do jhonstart declaram `-> string`, os do rakun `-> i32` (`jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` por prefixo; `boundaries-example.bp:89-91` (um `throw` dentro de `-> @Result`, um valor `Error` pela 118, não um raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Regras.** 303: uma action responde `@Result<T, ActionError>` e `throw e` ali é `Error(e)`; `ActionError` tem `NotFound` mas nenhum caso de redirect — a resposta deve dizer também como uma action redireciona.
- **Opções.** (a) `fn notFound() -> noreturn`, boundaries casando o tipo `NavOutcome`. (b) O sinal de string mantido sob um wrapper tipado. (c) Como está.
- **Recomendação.** (a). Com lg2-l e lg2-h.
- **Bloqueia.** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

#### nat-d7 · Anotações de ciclo de vida ao lado de interfaces (rakun 04)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), sobre um `Decl.implements` que o compilador deve** — `type Cache(…) implement Lifecycle { fn start(self: Self) { … } fn stop(self: Self) { … } }`, `pub behavior Lifecycle { fn start(self: Self); fn stop(self: Self); }` declarado pelo core do rakun; `#[component]` lê as cláusulas `implement` do tipo a partir de seu `@Decl` e registra as duas chamadas; `#[postConstruct]` / `#[preDestroy]` vão embora (318 (8): o rakun fala botopink, nenhum nome do Spring). Um behavior é a forma própria da linguagem para um contrato (311 (1)), tipado e checado na declaração (um `stop` ausente é erro do checker, não um marcador que ninguém leu), e um só jeito de dizer. Não viável hoje: `Decl` (`builtins.d.bp` `behavior Decl<T>`) expõe `kind`, `name`, `fields`, `variants`, `methods`, `returnType`, `annotations`, `hooks`, `params` e nenhum `implements` — uma linha 144: `Decl.implements: TypeInfo<unknown>[]` (a forma tipada da s23-f), espelhado no `decl_reflection_src` de `comptime.zig`; o rakun 04 pausa nela e mantém os marcadores de (c) (`rakun/src/lifecycle.bp`, `rkRegisterLifecycle` de `context.bp` sobre `decl.methods`) como sua forma mais próxima, marcada como lacuna de linguagem. Mudanças: a linha 144, depois o passo do rakun 04.
- **Não viável (fable, 2026-10-12):** (a) e (b) hoje — `Decl` não expõe `implements`; as duas esperam a linha `Decl.implements` acima (até lá (c) é a forma mais próxima, uma lacuna de linguagem).
- **Medido.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`.
- **Opções.** (a) `implement Lifecycle { fn start(self); fn stop(self) }`. (b) Ambos. (c) Como está.
- **Recomendação.** (a).
- **Bloqueia.** rakun 04.

#### nat-d8 · Um nome de hook `use…` sob `use` (53)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): `use actionState(createPost, initial)`; um hook cujo nome começa com `use` é recusado na sua declaração** — um hook é uma função que responde `@Component<R>` e é lido com `use h(…)` (354 (1)), então `use useX(…)` escreve o verbo duas vezes; o checker recusa uma declaração que responde `@Component` nomeada `use<Maiúscula…>`, localizada (`hook-name-use-prefix: a hook is read with use — name it actionState`). Uma grafia (67), e a 281 já fixa o argumento (a action por referência). Viável: o `actionState(actionId: string, initial)` do jhonstart-forms existe (`form.bp`; seu primeiro parâmetro vira a referência da action sob a 281 — um passo da seção do jhonstart da 150, 150 s36 … s47); a recusa vai junto com os diagnósticos de `use` em `comptime/diagnostics.zig` e os braços `.useHook` de `infer.zig` (hoje `use useThing(2)` passa no `check`), uma célula de recusa. Mudanças: o exemplo da 53 reescreve `use useActionState(…)` para `use actionState(…)`; uma linha 144 para a recusa.
- **Medido.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — o jhonstart não exporta nenhum `useActionState`; o hook do jhonstart-forms é `actionState(actionId: string, initial)` (`form.bp:182`).
- **Regras.** A 281 já resolve o argumento: a action é passada como referência (`createPost`), nunca como string — no exemplo e na assinatura de `actionState`. Só o nome do hook está aberto.
- **Opções.** (a) `use actionState(createPost, initial)`; um hook chamado `use…` recusado. (b) Os dois nomes. (c) Como está.
- **Recomendação.** (a).
- **Bloqueia.** Os exemplos da `07-onze/53`.

#### nat-f · Configuração em JSON — caso a caso (decisão 284)
`botopink.json` o mais limpo possível, configuração permitida onde faz sentido (284); `"bpp"` fica, um objeto desde a 338 (`{"default": "<package>", "style": …}`). Cada caso abaixo é sua própria pergunta.

#### nat-f2 · `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` do `onze.json` (124, 08-h)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como um só record tipado** — `onze.json` mantém suas chaves (284; a 271 fixa `trailingSlash`, `redirects`, `markdown`, `islands`, `site`), lidas no build para um record `OnzeConfig` cujos campos são as opções tipadas que o código do onze já tem (`UrlRules`, `MarkdownOptions`, `IslandProps`, `allowedRedirects: string[]`): uma chave desconhecida, um tipo errado, uma variante desconhecida ou um valor ruim é um erro nomeando o arquivo, o caminho da chave e o tipo esperado (as recusas da 49-c, tipadas), o precedente da 299 no leitor próprio do onze. Configuração é permitida ali (284) e o build a checa como checaria código; (b) moveria o que 271 / 272 / 224 puseram em `onze.json` e deixaria duas casas para um fato. Viável hoje: `onze/modules/onze/src/config.bp` `loadConfig` / `applyKey` / `configKeys` (escrito à mão, tipado; `allowedRedirects` existe, as outras quatro são acrescentadas ali); o binder `#[config]` da 299 não está construído no rakun, então nada é copiado; a linha no arquivo fica "sujeita a" o `decode` da biblioteca `json` expor a posição de um caminho — até lá o erro nomeia o caminho da chave. Mudanças: o passo 1 da 124 (as quatro chaves) e 50 / 53 leem `OnzeConfig`; `islands` entra em `configKeys` (a 224 a nomeia, o código não a tem).
- **Não viável (fable, 2026-10-12):** (a) pelo binder `#[config]` da 299 — não está construído no rakun; a proposta usa o leitor tipado próprio do onze no lugar.
- **Medido.** O `onze.json` é lido e validado por `loadConfig` sempre que o CLI resolve o projeto, `onze build` incluído (`onze-cli/src/resolve.bp:48-50`); uma chave desconhecida é recusada (49-c) sem linha. Só `allowedRedirects` existe (`onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` são as chaves planejadas da 124 (`124-bpp-cli/README.md:67-69`), que a 08-h já escreve; as quatro repetem opções que o código do onze tipa (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedente: 299 (record tipado ligado a partir de um arquivo, erros nomeando arquivo, linha e tipo esperado).
- **Opções.** (a) Mantidas no `onze.json`, lidas no record tipado no build como a 299 faz, uma chave ou valor errado um erro em sua linha no arquivo. (b) Um record tipado no código do app (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), sem JSON. (c) Como está.
- **Recomendação.** (a) — configuração é permitida ali (284); o build a checa como o código checaria, como a 299 faz para o rakun.
- **Bloqueia.** 124; 08-h; `07-onze/49`, `50`.

#### nat-f4 · O prefixo `ONZE_PUBLIC_` nas variáveis de ambiente (53, `contracts.md`)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b): a declaração diz — `#[publicEnv] pub val apiUrl = env.read("API_URL");` — e o prefixo `ONZE_PUBLIC_` vai embora** — um valor que o navegador pode ver é declarado uma vez, tipado, marcado onde é lido; o bundler inlina o valor do build de um `val` marcado no bundle do cliente e recusa, localizado, qualquer `env.read` alcançado de um componente `#[client]` que não seja tal `val` (`env-non-public` mantido, sua mensagem nomeando o marcador). Um fato carregado por uma convenção de nomes do ambiente é uma regra de string que o código nunca declara (o espírito da 281; 67: um prefixo esquecido é um erro localizado de qualquer modo, mas o marcador é checado onde o autor o escreveu, não onde o operador nomeou uma variável); a lista de (c) em `onze.json` é uma segunda casa para um fato de código. Viável: `onze/modules/onze-bundler/src/refusal.bp` (`env-non-public`, `env-dynamic`, `env-vars`, `env-write`) e `scan.bp` já acham o `env.read` de um módulo de cliente; `isPublicEnvName` / `publicEnvPrefix` de `config.bp` vão embora; `publicEnv` é um decorator num `val` (356: ele roda e o `val` é catalogado) registrando o meta tipado `PublicEnv(name)`, que o bundler lê do scan (ele escaneia fonte hoje) ou de `@TypeInfo.all(with: publicEnv)` na raiz do app. Mudanças: 50 / 53 e `contracts.md` § env; os nomes `ONZE_PUBLIC_*` dos exemplos viram nomes simples sob o marcador.
- **Medido.** Uma variável chega ao código do cliente só quando seu nome começa com `ONZE_PUBLIC_` (o `NEXT_PUBLIC_` do Next). Um prefixo ausente não é silencioso: o bundler recusa no build o `env.read("X")` de um módulo cliente sem ele, nomeando a variável (`env-non-public`, `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). O que resta é um fato de estágio (186) carregado por uma convenção de nome que o ambiente deve seguir (`client-island-example.bp:41`).
- **Opções.** (a) Mantido. (b) A declaração o diz — `#[publicEnv] val apiUrl = env.read("API_URL")`, seu uso de um componente `#[client]` checado em comptime (186); um marcador próprio, já que `#[clientVisible]` é a anotação de hidratação da 278; o `#[env("…")]` da 299 o precedente num record. (c) Uma lista de variáveis públicas no `onze.json`.
- **Recomendação.** (b).
- **Bloqueia.** `07-onze/50`, `53`; `contracts.md`.

### 01-compiler — a linguagem

#### lg2-b · O que `@Task<T>` significa no BEAM
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Respondida pela 392: um `@Task<T>` começa quando é feito e roda até seu primeiro `await` em todo alvo — em erlang e beam um processo por task; o lowering eager é um defeito** — dois `async.delay(300, …)` feitos antes de qualquer `await` levam ~300 ms, como em commonJS (392 (1): "a Promise do node, o processo por task do erlang, e wasm igualmente"; a 432 já termina "o processo da task" com `{error, E}`). Remedido na feat: commonJS 301 ms, erlang 603 ms, beam 603 ms — `codegen/erlang.zig` ("@Task — eager lowering") e `beam_asm.zig` ainda rodam o corpo onde é feito, e o cabeçalho de `async.bp` ainda diz isso. (1) contradiz o texto da 392, (3) acrescenta um segundo mecanismo ao lado de `@Task`. Viável: um processo por corpo `-> @Task` em erlang / beam (`spawn` + uma caixa de mensagens de que o `await` recebe, como `runAll` / `raceOf` já fazem por thunk em `async.bp`), o caminho rápido eager mantido só onde o checker prova que nenhum `await` observa a diferença — um passo 144 com a reprodução acima como sua célula. Mudanças: a linha "`@Task<T>` lowers eagerly on erlang" do `language-gaps.md` e o cabeçalho de `async.bp` fecham com ele; as linhas do rakun que citam a lg2-b leem a 392.
- **Medido.** No erlang e no beam o corpo de uma Task roda até o fim onde é criada: dois `async.delay(300, …)` criados antes de qualquer um ser aguardado levam ≥ 600 ms (menos de 600 ms no commonJS).
- **Opções.** (1) Uma Task promete o valor, nada sobre quando seu corpo roda; concorrência = o processo explícito do `std/async` por thunk não iniciado, documentado. (2) Um escalonador por trás de `@Task` no BEAM (um processo por Task, `await` um receive). (3) `spawn` / `join` na linguagem.
- **Recomendação.** (1) — a leitura restritiva da 120 da 1.0.10.
- **Bloqueia.** A linha; rakun 02, 23, 25, 28, 30, 60.

#### lg2-d · Um decorator que lê o corpo que anota
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(1), já a regra pela 316 e pela 403** — um decorator nunca lê o corpo que anota (316: "um decorator nunca lê o corpo (lg2-d) nem escreve um como string"); o que ele pode fazer a um corpo é `decl.wrapWith(f)`, tipado (316, 144 B-11); a saga do rakun 83 continua um valor que emparelha cada passo com sua compensação. Recusar antes de uma API de statements que ninguém checa; (2) e (3) fariam a saída de um decorator depender de como um corpo é escrito. Viável: nada a construir — `Decl` não tem `body` (`builtins.d.bp`), a leitura é `unknown field 'body' on type 'Decl'` na leitura (medido na feat). Mudanças: a entrada fecha como documentação da 316; a linha do `language-gaps.md` vira by design.
- **Medido.** `decl.body` é o `unknown field 'body' on type 'Decl'` do checker, localizado na leitura no corpo do decorator (a linha de corpo de decorator do `01-checker`; era `{error,{badkey,body}}` na anotação); o handle carrega kind, nome, campos, variantes, métodos, tipo de retorno, anotações.
- **Opções.** (1) Nenhum acesso a statements. (2) Uma árvore de statements somente leitura no `@Decl`. (3) Uma API de comptime que percorre corpos.
- **Recomendação.** (1); a saga da rakun 83 continua um valor que pareia cada passo com sua compensação.
- **Bloqueia.** A linha; rakun 83.

#### lg2-h · Lançar e capturar por tipo
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(1), já a regra por 431 / 486 / 489 / 490** — um erro é o `E` de um `@Result`: um erro tipado é um enum casado com `case` no corpo do `catch` (`try load(p) catch { e -> case e { NotFound(path) -> …; … } }`), uma falha de host chega como `HostError` sob `result: true` e um módulo do std a mapeia em seu próprio enum (486); nenhum braço de `catch` por tipo, nenhuma exceção de host tipada. Medido na feat: `catch { e: NotFound -> … }` não faz parse, a forma `case` checa e roda em commonJS e erlang. Viável: nada a construir. Mudanças: a entrada fecha como documentação da 431; a linha "No typed raise and no catch by type" do `language-gaps.md` vira by design; rakun 07 / 31 / 63 escrevem `case`.
- **Medido.** `try load(p) catch { e: NotFound -> … }` não faz parse; o erro de um `@Result<T, E>` é tipado por `E`, lido com `case` no corpo do `catch`; uma exceção de host não é um `E`.
- **Opções.** (1) Um erro é o `E` de um `@Result` (a 121 da 1.0.10): um erro tipado é um enum casado com `case`. (2) Um braço de `catch` por tipo. (3) Exceções de host tipadas.
- **Recomendação.** (1) — a linha vira documentação da 121.
- **Bloqueia.** A linha; rakun 07, 31, 63.

#### lg2-l · Se `noreturn` é um tipo bottom
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(2), como o código já tem: `noreturn` é o tipo bottom, e um corpo `noreturn` não pode cair pelo fim** — uma chamada `noreturn` cabe em qualquer posição (`val s: string = notFound();`, `throw notFound();`, um ramo de `if`), encerra seu caminho (`stmtsAlwaysExit` / `callNeverReturns` estreitam depois dela), e uma função declarada `-> noreturn` cujo corpo pode completar é recusada na declaração, localizada. Medido na feat: `unify.zig` ("`noreturn` é o tipo bottom de mão única"), as células `builtin_noreturn_any_position` e `try_catch_null_and_noreturn_narrowing` fixam (2) nos quatro alvos; (1) quebraria as duas células sem ganho — uma posição de valor que um `noreturn` preenche nunca é produzida, então nada fica silenciosamente errado, e é o que deixa os sinais serem `-> noreturn` (nat-d6). Viável: construído; a checagem de queda pelo fim é mais um uso de `stmtsAlwaysExit` num corpo `-> noreturn` (`infer.zig`). Mudanças: uma linha 144 para o defeito (`fn bad(c: bool) -> noreturn { if (c) { @panic("x"); } }` compila e retorna); o Medido da entrada e as duas linhas de `noreturn` do `language-gaps.md` estão defasados.
- **Medido.** `fn notFound() -> noreturn { raise("…"); }` encerra o caminho no commonJS e no erlang, mas `throw notFound();` num corpo `@Result` e `val s: string = notFound();` dão incompatibilidade → `notFound()` / `redirect()` do jhonstart declaram `-> string` (`error_boundary.bp:180-188`); o exemplo da frente 53 escreve `val _gone = redirect(…)` (`server-action-example.bp:79`); o app de blog do onze chama `notFound();` como statement. `@panic` / `@todo` são `noreturn`; um branch que termina numa chamada `noreturn` já estreita — pode ser confirmado de fato.
- **Opções.** (1) `noreturn` não unifica com nada: uma chamada a ele é um statement que encerra seu caminho; os sinais viram `-> noreturn` chamados como statements (numa página: `fn() -> View`, `use params<P>()`). (2) `noreturn` é o tipo bottom, cabe em qualquer posição.
- **Recomendação.** (1).
- **Bloqueia.** A linha; os sinais do jhonstart (63, `31-a`); os testes de navegação do rakun.

#### lg2-n · Um thunk coagido para `Node`
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(1): nenhuma coerção de thunk — um filho adiado é um valor de componente, nunca um `fn() -> Element`** — `Node` aceita um array, um `Element`, uma `string` e um valor de componente (191, 223, 504: a árvore guarda o lambda não executado que `view()` faz); o filho adiado de um boundary é tipado `child: @Component<Element>` (os nós da 414), não `fn() -> @Component<Element>` como o jhonstart escreve hoje. Três coerções que o compilador conhece e nada inferido da forma de um lambda (67); sob a 388 um componente já é a forma adiada, então um thunk é uma segunda grafia dela. Viável: `infer.zig` `childrenCoercion` (`Children`, array, `string`, `@Renderable`) fica; medido na feat `show({ -> "x" })` é `expected Children, got function`. Mudanças: os campos `child` de `ErrorBoundaryNode` / `NotFoundBoundaryNode` / `suspense.Boundary` do jhonstart largam o thunk com o pouso da 414-a (B-17, 149).
- **Medido.** `show({ -> "x" })` contra `fn show(children: Children)` (`Node` sob a 223) dá incompatibilidade.
- **Opções.** (1) Nenhuma coerção de thunk: um filho adiado é um campo nomeado do boundary. (2) `fn() -> Element` coage para `Node`.
- **Recomendação.** (1): as coerções conhecidas pelo compilador continuam três (array, `Element`, `string`).
- **Bloqueia.** A linha; jhonstart 30.

#### lg2-p · Cancelamento
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(1): sem cancelamento; um corredor perdedor e um timeout expirado rodam até o fim e seus resultados são descartados** — o contrato é o resultado e a ordem das respostas (335 (2)), nunca o entrelaçamento; `raceOf` / `timeout` o documentam. Nada a construir, nada a errar (67); (2) tokens e (3) um caminho de kill acrescentam um mecanismo de que nenhuma frente mediu necessidade, e um caminho de kill em erlang (`spawn` sem link em `async.bp`) precisaria de seu gêmeo commonJS (`AbortController`) para manter uma resposta. Viável: como construído (`libs/std/src/async.bp`; medido na feat: o perdedor imprime depois do vencedor em commonJS, erlang e beam). Mudanças: nenhuma; revisitada sob necessidade medida (um handle respondido por `raceOf`, uma grafia em todo alvo).
- **Medido.** O `std/async` não tem handle de cancelamento; um competidor perdedor e um timeout expirado rodam até o fim.
- **Opções.** (1) Nenhum: o trabalho perdedor termina, resultado descartado, documentado. (2) Tokens de cancelamento explícitos. (3) Processos ligados com um caminho de kill no BEAM.
- **Recomendação.** (1), em compasso com `lg2-b` (1).
- **Bloqueia.** A linha; rakun 02.

#### lg2-s · Reflexão do grafo de módulos
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(1): sem reflexão do grafo de módulos; o onze-bundler mantém `importsOf`, um scan que falha alto** — `Decl` não tem `imports`, e (2) não é viável: não há `@Decl` de nível de módulo para carregar um (315: nenhuma anotação de nível de módulo). O bundler lê o que o compilador já resolve quando uma frente precisar — uma saída do CLI `botopink` com o grafo de módulos (o resolver do B-69 nomeia todo módulo por caminho), nunca uma reflexão de comptime sobre módulos (o catálogo da 216 (4) responde declarações, não módulos). Viável: `onze/modules/onze-bundler/src/scan.bp` `importsOf`, `graph.bp` `loadModules`; medido na feat `decl.imports` é `unknown field 'imports' on type 'Decl'`. Mudanças: o `status.md` lista `ctr-m (= lg2-s)` como fechada em 9 de outubro e a lg2-s como aberta na mesma seção — uma das duas linhas vai embora com esta resposta.
- **Não viável (fable, 2026-10-12):** (2) — não há `@Decl` de nível de módulo para carregar um campo `imports` (315: nenhuma anotação de nível de módulo).
- **Medido.** `decl.imports` é o campo desconhecido de `Decl` do checker, na leitura (era `badkey` na anotação); `onze-bundler/src/graph.bp` lê imports com `importsOf`, uma varredura textual.
- **Opções.** (1) Nenhuma: `importsOf` continua uma varredura textual que falha alto. (2) Um campo `imports` num `@Decl` de nível de módulo.
- **Recomendação.** (1); seu argumento antigo ("em compasso com `lg2-k`") caiu com a 216.
- **Bloqueia.** A linha; onze 68 (bundle cliente).

#### lg2-u · Um decorator em posição de expressão fora de markup
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(1): fora de markup, trabalho em nível de expressão é uma chamada** — `traced(compute())`; a anotação de uma tag é o único decorator em posição de expressão (278, 302, 369), e um registro `#[theme]` é um decorator num `val` (356, a espera da 300 pela lg2-u acabou). Um decorator sem um `@Decl` sobre o qual agir não tem lugar de saída (216); (2) rodaria código do usuário no script de avaliação por um valor, dois jeitos de escrever uma chamada. Viável: como construído (`val x = #[deco] 1;` é recusado); uma linha 144 para a mensagem: o parser reporta `loop-annotation-not-generator` com a dica `iter` / `stream` para uma expressão comum (`parser/exprs.zig` `parseAnnotatedLoopExpr`) — uma recusa própria, nomeando a forma de chamada.
- **Medido.** `val x = #[deco] 1;` recusado (`loop-annotation-not-generator`). O caso de markup da frente 48 do emilia está respondido: uma anotação de tag é um decorator (278, 302), e o emilia alcança markup como `<h1 #[styled(…)]>` (301). Restante: um decorator numa expressão comum.
- **Opções.** (1) Nenhuma: fora de markup, o trabalho em nível de expressão é uma chamada (`traced(compute())`). (2) Decorators em posição de expressão rodam no script de avaliação (`#[traced] compute()`).
- **Recomendação.** (1).
- **Bloqueia.** A linha (o caso de markup da emilia 48 coberto pela 301).

### 02-std-and-packaging

#### std-e · Hooks de ciclo de vida de teste
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): nenhum hook de ciclo de vida; o corpo de um teste chama seu helper de reset** — nada implícito roda em volta de um `test` (67), todo bloco `test` se lê inteiro, e a unidade de teste da 513 guarda só blocos `test`. (b) roda uma função de módulo que o teste nunca nomeia e (c) acrescenta gramática para o que uma chamada já diz. Viável: como construído (nenhum `#[before]` / `beforeEach` no std, no `lib-test-runner` ou nas bibliotecas); as contagens da entrada estão defasadas — `resetChain()` é chamado 77 vezes no rakun todo (31 no rakun-web), `rkAppReset` 20, `resetTables` 13, `installDocument` 19. Mudanças: a linha "No test lifecycle hooks" do `language-gaps.md` vira by design.
- **Medido.** Os testes de biblioteca resetam o estado à mão no topo do corpo: `resetChain()` do rakun-web 77×, `rkAppReset(…)` 20×, `resetTables(…)` 14×, entre outros; `resetSingletons` / `resetContext` do rakun-test só em seu próprio `context_test.bp`; `installDocument(…)` do jhonstart-dom-test 11×.
- **Opções.** (a) Nenhum: um corpo de teste chama seu helper de reset. (b) `#[before]` / `#[after]` numa fn de nível de módulo que o runner chama em volta de todo `test`. (c) Blocos `beforeEach { … }` na gramática.
- **Recomendação.** (a): nada implícito roda em volta de um teste.
- **Bloqueia.** A linha "No test lifecycle hooks" do `language-gaps.md`.

### 03-bundled-libs

#### 07-b · "Uma biblioteca, várias cópias divergentes" também justifica um pacote?
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): o "duas ou mais bibliotecas" da 115 continua o único teste** — uma duplicata dentro de uma biblioteca vai para o std quando genérica, senão para o core dessa biblioteca; os cinco leitores de cookie do rakun já são o caso da 196 (`http.cookie`, consumido por rakun e onze-server). Um segundo teste admitiria um pacote para um consumidor contando suas cópias (a exceção da 115 é do mantenedor, declarada caso a caso: 396 (4), 398 (3)). Viável: `repository/http/src/cookie.bp` existe; a adoção pelo rakun é um passo da 150 (nenhum manifesto do rakun depende de `http` ainda). Mudanças: nenhuma.
- **Medido.** O rakun tem quatro leitores de `Cookie:` divergentes dentro de si (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, frente 104). As cópias de cookie e q-value já qualificam pelo teste da 115 (o onze também as consome).
- **Opções.** (a) O "duas ou mais bibliotecas" da 115 continua o único teste. (b) Acrescentar o teste de divergência.
- **Recomendação.** (a): uma duplicata de uma biblioteca só vai para o std ou para o core da biblioteca dona.
- **Bloqueia.** Nada; a regra para o próximo candidato (o `http` da frente 104 existe; o rakun o adota em seu passo 5).

#### 07-h · Embutido, ou um repositório compartilhado separado
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Já respondida: decisão 326** — as bibliotecas compartilhadas são repositórios próprios (`botopink/<pkg>`, um submódulo em `repository/<pkg>`), dependências comuns declaradas em `botopink.json` (242; uma dependência git pode nomear um `subdir`, 344), o compilador embutindo só o std (`build.zig` `bundled_packages`); o "versionado com o compilador, sem entrada em `dependencies`" de (a) é o estado que a 326 encerrou. Medido na feat: `routing`, `actions`, `validation` são dependências git de membros do rakun, jhonstart e onze; `http` e `log` ainda não têm dependente. Fechar removendo a entrada.
- **Medido.** Fios que os dois frameworks devem acordar byte a byte seguem com o compilador que os embute; um repositório separado = uma dependência git, restringida pela 242 (só uma dependência direta é importável); um membro de um repositório instala por `subdir` (344).
- **Opções.** (a) Embutido — versionado com o compilador, sem entrada em `dependencies`. (b) Um repositório compartilhado `botopink/common` com cadência própria.
- **Recomendação.** (a).
- **Bloqueia.** Nada espera; a trilha é cortada como (a).

### 04-rakun

#### erk-b · `#[documentQuery]` sob a 313 (*proposta*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), com gerador próprio: o `#[documentRepository]` do rakun-data-nosql sobre um `behavior` cujos métodos carregam `#[documentQuery("…")]`** — a mesma forma da 313 (um `behavior`, uma anotação por método registrando meta tipado, um gerador produzindo a implementação e o registro por tipo), o filtro uma string comum entregue ao store textualmente como `#[nativeQuery]` entrega SQL (placeholders `:name` casados por nome com os parâmetros, um erro na anotação quando um fica sem par); não o `#[repository]` do dbcontext, cujo gerador emite runners de SQL e recusa um método que não conhece (313: "um método sem nenhuma das anotações é um erro"). Uma forma de repositório para todo store, nenhum segundo modelo (283); (b) um alvo de documentos do erika espera uma necessidade medida; (c) é a forma que a 313 apagou. Viável como decorator de biblioteca (216, 311 (1): um gerador sobre um behavior, como `#[mocks.mock]`): um novo módulo `rakun-data/src/nosql/` (o `pub mod nosql;` de `root.bp` até o B-75) — nada da 09 existe na feat (nenhum `DocumentStore`, nenhum `nosql.url`; `documentQuery` é um comentário em `sql/query.bp`), e o dbcontext é um esqueleto vazio, então o passo 4 da 09 abre depois de a 143 pousar a forma a copiar. Mudanças: o README da 09 nomeia `#[documentRepository]`; o "09 passo 4" da entrada é `machine-1/150-rakun/09-rakun-data-nosql`.
- **Não viável (fable, 2026-10-12):** (a) pelo `#[repository]` do dbcontext — seu gerador emite runners de SQL e recusa um método que não conhece (313); o dbcontext é um esqueleto vazio na feat; (b) — nenhum alvo de documentos do erika existe.
- **Medido.** 09 passo 4: `#[documentQuery("…")]` segue a forma de `#[query]` — um membro do tipo repositório que responde o template literalmente. A 313 apaga essa forma para SQL: um repositório é um `#[repository] behavior`, seus métodos carregando `#[erika "…"]` ou `#[nativeQuery("…")]`. A gramática do erika é a do SQL; o filtro de um document store é JSON (`$in`, `$gt`, …).
- **Opções.** (a) A mesma forma: um repositório de documentos é um `#[repository] behavior` cujos métodos carregam `#[documentQuery("…")]`, uma string comum entregue ao store como `#[nativeQuery]` entrega SQL ao driver (placeholders `:name` casados com os parâmetros, escapados por `bind`). (b) O erika ganha um alvo de documentos — o mesmo `select … where …` baixado para o filtro do store. (c) Como está: um membro do tipo.
- **Recomendação.** (a) agora — uma forma de repositório para todo store; (b) quando uma necessidade medida pedir.
- **Bloqueia.** 09 passo 4.

#### 03r-ab · Os stores de protocolo binário da frente 09
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), confirmar — só o registro** — a 09 entrega `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://` e `https://` com a suíte do behavior contra os quatro no gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` são esquemas reconhecidos cuja recusa de boot nomeia o driver (passo 5; 160: um double em processo ou uma linha de `deferred.md`, nunca um fallback para ETS). Recusar antes de um substituto silencioso (67); o braço Elasticsearch alcança HTTP por um ponto de extensão do core, nunca por uma aresta `rakun-data → rakun-client` (`ctr-w`, 185). Viável: nada da 09 está na feat (`rakun.nosql.url` não existe; o único store escolhido por URL é `rakun.datasource.url` em `rakun-data/src/datasource.bp`, cuja recusa de esquema desconhecido — "whose scheme no arm serves — accepted: …" — e `sql_datasource_test.bp` são o padrão que as células do passo 5 copiam). Mudanças: nenhuma; a 09 segue (a) como escrita.
- **Medido.** O store é selecionado por `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase são protocolos de bytes (`Bytes` é da 346, ainda não construído) que precisam de drivers OTP que um sidecar não consegue carregar; ETS e Mnesia estão na VM; Redis é RESP sobre `gen_tcp`; Elasticsearch é HTTP + JSON. O README da 09 já está escrito para (a): os antigos passos 4 e 7 são as células de recusa do passo 5 mais uma linha de `deferred.md` cada — só falta o registro.
- **Opções.** (a) A 09 entrega `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` com a suíte de behavior contra os quatro no gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` são esquemas reconhecidos cuja recusa no boot nomeia o driver (passo 5). (b) Quatro clientes de protocolo em sidecars Erlang, uma frente cada. (c) Adiar a 09.
- **Recomendação.** (a): nunca um fallback para ETS sob uma URL Mongo; o braço Elasticsearch sem uma aresta `rakun-client` (`ctr-w`; o passo 3 da 09 ainda passa por ela). A frente já segue (a).
- **Bloqueia.** 09 passo 5 (as células de recusa).

#### 03r-ae · ACS do SAML 2.0
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b) agora: as três caixas do ACS vão embora e `saml2/` mantém o 501 sob uma linha de `deferred.md`; (a) quando uma frente medir necessidade** — uma funcionalidade que responde 501 está ausente, não meio construída, e nada é marcado como passado sem rodar (67, 160); nunca (c). As ~300 linhas de exc-c14n sobre `xmerl` de (a) num novo `rakun-security/src/sidecars/rakun_saml2.erl` (como `rakun_ws.erl` usa `xmerl_scan`) são viáveis, só erlang (03r-a), quando a 79 for ocupada; a 150 está parcial com a 79 não aberta, então o registro honesto é o adiamento. Viável: `rakun-security/src/saml2/saml2.bp` responde 501 hoje (`oauth2_test.bp` o afirma); nenhum `rakun_saml2.erl` existe. Mudanças: as três caixas do passo 3 da 79 viram uma linha de `deferred.md`.
- **Medido.** Verificar a assinatura de um IdP precisa de Exclusive XML Canonicalisation, que nem o `xmerl` do OTP nem o std fornecem; `saml2/saml2.bp` responde 501.
- **Opções.** (a) exc-c14n sobre a árvore do `xmerl` em `src/sidecars/rakun_saml2.erl` (~300 linhas), as três caixas fechadas por um fixture assinado com uma chave versionada. (b) Aposentar o SP: as três caixas saem, `saml2/` mantém 501 com uma linha de `deferred.md`. (c) Deixá-las abertas.
- **Recomendação.** (a) se a 79 tiver equipe neste milestone, senão (b); nunca (c).
- **Bloqueia.** 79 passo 3.

#### 03r-af · Os sete projetos de exemplo não construídos
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): aposentar os sete; os três em disco ganham um `README.md` cada** — `examples/` contém `rakun`, `rakun-container`, `rakun-ssr` (nenhum com README), e o contrato de todo membro é afirmado por seus próprios testes (390 (5): um valor que nada verifica vira um teste comum, não um exemplo). Um exemplo que nunca rodou é uma promessa que o gate não pode cumprir (67); (b) são sete frentes para nenhum leitor medido. Viável: três arquivos; o manifesto do workspace já lista `examples/*`. Mudanças: o passo 3 da 73; a lista da 1.0.10 é um registro fechado.
- **Medido.** `examples/` guarda `rakun`, `rakun-container`, `rakun-ssr` (células de gate); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` nunca começaram; o contrato de cada membro é afirmado por seus próprios testes.
- **Opções.** (a) Aposentar os sete (a lista de exemplos da 1.0.10 um registro fechado; os três em disco ganham um `README.md` cada). (b) Construí-los, uma frente cada, depois de toda frente de membro. (c) Construir só o `rest-service`.
- **Recomendação.** (a).
- **Bloqueia.** 73 passo 3.

#### 03r-ak · Validação CycloneDX
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a′): validar o SBOM contra o schema CycloneDX 1.5 versionado com o validador vendorizado que a 399 já fixou, só no teste — não um caminhador escrito à mão** — `release_test.bp` roda `process.run("node", ["test/tools/check-schema.js", <documento>])` sobre `test/release/fixtures/bom-1.5.schema.json`, como `repository/validation/test/json_schema_test.bp` faz com o build standalone 2020 do Ajv (399: vendorizado sob `test/tools/`, versão e hash no `AGENTS.md`, nunca distribuído); `ok` ou a lista de erros do validador reprova o teste; sem rede. Um validador no ecossistema, não um segundo de ~120 linhas implementando um subconjunto do JSON Schema (67: um subconjunto que aprova um documento que o schema real recusaria é uma aprovação silenciosa); (b) enfraquece a caixa, (c) é uma funcionalidade de std de que ninguém mais precisa. Viável: `rakun-cli/test/release/release_test.bp` (o teste do SBOM afirma `bomFormat`, `specVersion`, `components` por nome hoje; nenhum `fixtures/` ainda), o `io.process.run` do std (o CLI do rakun já o chama); node nas linhas de CI do rakun como nas do validation. Mudanças: a caixa do passo 3 da 81 nomeia a ferramenta da 399; o `release_test.bp:168` da entrada está defasado.
- **Não viável (fable, 2026-10-12):** (c) — o std não tem validador de JSON Schema, e a 399 fixou o vendorizado para testes.
- **Medido.** A caixa pede validação contra um schema CycloneDX 1.5 versionado, sem rede; o std não tem validador de JSON schema; `release_test.bp:168` afirma campos por nome (`rakun-cli/test/release/` depois da 128).
- **Opções.** (a) `release_test.bp` percorre o SBOM contra os `required`, `type`, `enum` e `$ref`s locais de `test/release/fixtures/bom-1.5.schema.json` (~120 linhas), como o passo 3 da 81 já lê. (b) Emendar a caixa para a lista campo a campo. (c) Um `json.schema` no std.
- **Recomendação.** (a).
- **Bloqueia.** 81 passo 3.

#### 03r-al · Transações de produtor Kafka contra o broker em processo
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): confirmar — o registro, e a fiação** — o relay de outbox da 83 publica por `withProducerTransaction` no broker em processo (envios retidos, liberados no commit, descartados num raise; `read_committed` não vê nada depois de um abort); a execução com broker real é uma linha de `deferred.md` (160). Viável: `rakun-messaging/src/reliability/transaction.bp` `withProducerTransaction` (testado em `transaction_test.bp`); o outbox (`rakun-data/src/tx/outbox.bp` `publishAfterCommit`, `relayTick(ds, publisher)`) recebe uma função publicadora e ainda não passa por ele — a aresta `rakun-messaging → rakun-data` existe, então a cola é o publicador do rakun-messaging entregue a `relayTick`, a primeira caixa do passo 5 da 15. Mudanças: nenhuma no plano; o `transaction.bp:39` da entrada é `:54`.
- **Medido.** `rakun-messaging/src/reliability/transaction.bp:39` provê `withProducerTransaction(prefix, body)` (envios retidos, liberados no commit, descartados num raise; leitor `read_committed` testado em `transaction_test.bp`). O passo 5 da 15 já está escrito para (a): quatro caixas (caminho do outbox por `withProducerTransaction`, nenhuma linha de outbox; nada visível a `read_committed` depois de um aborto; o caminho no log; uma linha de `deferred.md` para um broker real). Só falta o registro.
- **Opções.** (a) O caminho do outbox da 83 publica por `withProducerTransaction` no broker em processo; execução com broker real uma linha de `deferred.md`. (b) Apagar as caixas de broker do passo 5. (c) Deixar o passo 5 aberto até um Kafka real estar no gate.
- **Recomendação.** (a).
- **Bloqueia.** 15 passo 5 (só o registro; a frente segue (a)).

#### 03r-am · Onde vivem os doubles de broker e scheduler
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(c): os doubles vivem em `rakun-test`, alcançando os registros só pelos hooks do core — nenhuma aresta para o rakun-messaging, nada a medir** — `rkOnReset("broker-double", …)` (`rakun/src/runtime.bp`) e um termo de nomes de listeners que o core possui são a costura; `rakun-test` continua dependendo só de `rakun` e os testes do `rakun-messaging` dependem de `rakun-test` (sem ciclo: o manifesto não tem escopo só de teste — nenhum existe em `modules/manifest` — então a medição de (a) só encontraria o ciclo). A regra da 185 (o core define o ponto de extensão); o passo 3 da 19 então roda `container_test.bp` pelo double. Viável: `rkOnReset` existe; nenhum `broker_double` / `task_double` existe no rakun (o manifesto do `rakun-test` já descreve "o double de broker" que não contém). Mudanças: os passos 3–4 da 19 escritos para (c); o `runtime.bp:215` da entrada é `:232`.
- **Medido.** `rakun-test` depende só de `rakun`; nenhum `rakun-messaging/test/*.bp` importa `rakun-test` hoje, mas o passo 3 da 19 faz `container_test.bp` rodar pelo double — com o double no `rakun-test` isso é `rakun-test → rakun-messaging` ao lado de `rakun-messaging (tests) → rakun-test`, um ciclo de pacotes a menos que o loader respeite o escopo de teste (não verificado). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:215`).
- **Opções.** (a) Medir: acrescentar a aresta e o import de `container_test.bp`; se `botopink test` recusar o ciclo, os doubles vivem ao lado do módulo que duplicam (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) e o `rakun-test` os documenta. (b) Tomar a aresta, supondo que a regra pousou. (c) Os doubles no `rakun-test`, alcançando os registros só por hooks do core (`rkOnReset("broker-double", …)`, o termo de nomes de listeners).
- **Recomendação.** (a), com a forma de (c) de qualquer jeito.
- **Bloqueia.** 19 passos 3 e 4.

#### 03r-an · O transporte WebSocket do RSocket depois da decisão 187 (*proposta*, levantada como R92-1)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b): um ponto de extensão do core chaveado por um enum de transporte — `rkRegisterTransport(.WebSocket, mount)`; o `rakun-websocket` se encaixa** — o core declara `enum Transport { Tcp, Tls, WebSocket }` e um registro em `rakun/src/runtime.bp`; o RSocket no `rakun-messaging` pede ao registro o transporte configurado e recusa o boot nomeando o membro a acrescentar quando nenhum o registrou; `rakun.rsocket.server.transport` é lido no enum pela config tipada da 299. 185 (nenhuma aresta membro-a-membro para o que é opcional; o `rakun-messaging` não depende do `rakun-websocket` hoje e (a) carregaria sua árvore para todo consumidor de messaging); 281 / 299: o transporte é uma variante, não a string que o código compara. Viável: `rakun-messaging/src/rsocket/rsocket.bp` recusa `transport == "websocket"` e fala só `tcp://`; nenhum registro ou enum existe — a primeira e a terceira caixas do passo 2 da 92 os constroem (o padrão de registro de `rkOnReset`). Mudanças: o `rakun-rsocket/src/rsocket.bp:69` da entrada é `rakun-messaging/src/rsocket/rsocket.bp` (187).
- **Não viável (fable, 2026-10-12):** (a) — uma aresta `rakun-messaging → rakun-websocket` carrega a árvore de websocket para todo consumidor de messaging, o que a 185 proíbe para o que é opcional.
- **Medido.** R92-1 monta o transporte pelo `#[wsEndpoint]` do `rakun-websocket`; depois da 187 o RSocket vive no `rakun-messaging` → a aresta carregaria a árvore do `rakun-websocket` (security, data) para todo consumidor de messaging; hoje o transporte WebSocket é recusado no boot (`rakun-rsocket/src/rsocket.bp:69`, só TCP).
- **Opções.** (a) Tomar a aresta `rakun-messaging → rakun-websocket`. (b) O core define um ponto de extensão de transporte em que o `rakun-websocket` se pluga (regra da 185), chaveado pela variante do enum de transporte (`rkRegisterTransport(.WebSocket, …)` — a 299 tipa a config, a 281 nenhuma string). (c) Aposentar o transporte WebSocket: as duas caixas da R92-1 e os braços `ws://` / `wss://` da R92-7 apagados, só TCP e TLS, uma linha de `deferred.md`.
- **Recomendação.** (b).
- **Bloqueia.** A primeira e a terceira caixas do passo 2 da 92.

#### 04-a · O tempo de vida, o tipo e a tag vazia da época de tag (*implementado como (a), aguarda confirmação*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído — confirmar** — uma época só cresce (`rkResetContext` deixa a tabela de tags), `i64`, e `""` é recusada em `rkBumpTag` / `rkTagEpoch` (`rakun: a tag is a non-empty string (rkBumpTag)`). Um contador de versão nunca volta, então nenhuma época guardada encontra um estado posterior; `i64` não tem borda alcançável; uma tag vazia é bug de quem chama, recusada (67). Viável, construído: `rakun/src/runtime.bp` (`rkTagEpoch` / `rkBumpTag -> i64`), `rakun_runtime.erl` (`tag_epoch/1`, `bump_tag/1` sobre `ets:update_counter`, `check_tag`, `reset_context/0` deixando `?TAGS`). Mudanças: nenhuma.
- **Medido.** A 185 põe a época por tag no core (04 passo 1): `rkBumpTag(tag)` a incrementa, `rkTagEpoch(tag)` a lê, o `rakun-client` guarda as épocas das tags de uma resposta ao lado dela e trata uma alterada como miss (13 passo 1), os três verbos do `rakun-cache` incrementam (12 passo 3). A 185 não diz se `rkResetContext` (o seam de teste que descarta registros e roda todo hook `rkOnReset`) limpa as épocas, de que tipo inteiro elas são, nem o que é uma tag vazia. Todo outro contador em `src/runtime.bp` é `i32` (`rkBuildCount`, `rkScannedCount`); um contador do BEAM não dá a volta, então um `i32` além de `2^31 - 1` seria um valor fora de seu tipo.
- **Opções.** (a) Uma época só cresce: `rkResetContext` deixa a tabela; `i64`; `""` recusado nas duas células (`rakun: a tag is a non-empty string (rkBumpTag)`), localizado pelo raise:
  ```bp
  val _b = rkBumpTag("t");        // 1
  val _r = rkResetContext();
  assert rkTagEpoch("t") == 1;    // a response stored at epoch 1 before the reset stays stale after the next bump (2)
  val _x = rkBumpTag("");         // raises: rakun: a tag is a non-empty string (rkBumpTag)
  ```
  (b) `rkResetContext` limpa as épocas (um teste começa em 0 para toda tag); um cache de cliente que sobrevive ao reset pode reencontrar sua época guardada — um hit obsoleto:
  ```bp
  // stored beside a response: epoch 1
  val _r = rkResetContext();      // epochs back to 0
  val _b = rkBumpTag("t");        // 1 again — the stored 1 matches, the stale response is served
  ```
  (c) O tempo de vida de (a), `i32` como os outros contadores, e `""` uma tag comum:
  ```bp
  val e: i32 = rkBumpTag("");     // 1 — the empty tag is a tag
  ```
- **Recomendação.** (a): um contador de versão nunca volta, então nenhuma época guardada pode casar com um estado posterior; `i64` não tem borda alcançável; uma tag vazia é um bug do chamador, recusada (decisão 67).
- **Bloqueia.** nada — construído como (a); (b) ou (c) seriam algumas linhas em `rakun_runtime.erl` e `runtime.bp` antes de a 13 e a 12 o consumirem.

### 05-jhonstart

#### 27-b · As entradas do driver: de onde vem o markup, e quem define `data-jh-pending` (*proposta* ★)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído — confirmar** — seis funções, o driver assíncrono, `replaceDepth(nav) = nav.shared - 1`; `markPending` põe e limpa `data-jh-pending` (363 (4): o roteador do cliente o define, o CSS o estiliza); um markup que falha limpa a marca, não substitui nada e responde o erro. Toda caixa do README afirmada sem DOM, sobre um `DomOps` que grava; (b) e (c) movem uma caixa para o navegador do onze 53 ou fazem a entrada buscar. Viável, construído: `jhonstart/modules/jhonstart-link/src/reconcile.bp` (`DomOps` com `markup`, `replaceSubtree`, `startIslands`, `mountCount`, `scrollTo`, `markPending`; `applyTransition(current, target, dom) -> @Task<@Result<Navigation, string>>`). Mudanças: nenhuma; o passo 6 do `07-onze/50` fornece as seis (seu `onze dev` ainda recusa).
- **Medido** (frente 27 passo 1 caixa 1 e passo 2 caixa 3). O README fixa
  `applyTransition(current, target, dom: DomOps) -> Navigation` e `DomOps` como quatro funções
  (`replaceSubtree(depth, html)`, `startIslands(depth)`, `mountCount(name)`, `scrollTo`). Duas de suas
  próprias caixas não cabem nessa forma: `replaceSubtree` recebe o `html` do alvo, e nem
  `RouterState` nem as quatro funções fornecem um (o driver é puro, não consegue buscar); e o passo 2
  pede que "o router do cliente defina `data-jh-pending` no link ativo e o limpe quando a
  transição termina", afirmado "sobre um `DomOps` gravador" — nenhuma das quatro funções consegue defini-lo.
  `scrollTo` não tem argumento declarado. Duas leituras da profundidade também eram possíveis: `sharedDepth`
  responde 2 para `/blog` → `/blog/[slug]` (as chaves `/`, `/blog` concordam), enquanto a caixa do README
  espera `replaceSubtree(1, …)`.
- **Opções.**
  (a) ★ Seis funções, o driver assíncrono; a profundidade é o segmento compartilhado mais fundo, cujos
  FILHOS são substituídos (construído, `jhonstart-link` 46 / 0 nas duas linhas):
  ```bp
  pub type DomOps(
      markup: fn(href: string) -> @Task<@Result<string, string>>,   // route cache or fetch
      replaceSubtree: fn(depth: i32, html: string) -> void,
      startIslands: fn(depth: i32) -> void,
      mountCount: fn(name: string) -> i32,
      scrollTo: fn(depth: i32) -> void,
      markPending: fn(href: string, pending: bool) -> void,          // data-jh-pending
  )
  pub fn applyTransition(current: RouterState, target: RouterState, dom: DomOps)
      -> @Task<@Result<Navigation, string>>
  // /blog → /blog/x: pending /blog/x on | markup /blog/x | replace 1 … | start 1 | scroll 1 | pending /blog/x off
  // replaceDepth(nav) = nav.shared - 1 — never below 0, so the root layout is never replaced
  ```
  (b) As quatro funções do README, o markup um parâmetro, a marca de pendente do runtime
  (`link_runtime.mjs` a define no clique, a limpa no `popstate`) — a caixa do passo 2 então é afirmada só
  no navegador da onze 53, não sobre um `DomOps` gravador:
  ```bp
  pub fn applyTransition(current: RouterState, target: RouterState, html: string, dom: DomOps) -> Navigation
  ```
  (c) As quatro funções do README com `replaceSubtree(depth, href)` — a entrada busca o markup
  ela mesma — e a marca de pendente dentro do `replaceSubtree` da entrada; o driver continua síncrono:
  ```bp
  dom.replaceSubtree(1, "/blog/x");   // the entry: fetch, mark, replace, clear
  ```
- **Recomendação.** (a): toda caixa do README é afirmada sem DOM, um markup que falhou é um
  erro localizado que limpa a marca e não substitui nada, e a entrada (`07-onze/50` passo 6)
  fornece funções simples.
- **Bloqueia.** Nada — (a) está construída; o `07-onze/50` passo 6 fornece as seis funções.

#### 67-a · Onde as caixas de formulários do lado DOM são afirmadas
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): `fake_dom.mjs` ganha `<form>`, `<input>`, `FormData` e `submit`; as cinco caixas são afirmadas em `jhonstart-dom-test/test/forms_dom_test.bp` agora, e de novo no navegador do onze 53** — uma caixa afirmada só numa execução de navegador que nenhum gate segura é não afirmada (160, 67); (c) acrescenta uma dependência para o que algumas centenas de linhas de fake dão. Viável: `jhonstart/modules/jhonstart-dom-test/src/fake_dom.mjs` (sem form, sem `FormData`, sem `submit` hoje), `test/dom_test.bp` o padrão; org-6: a 67 é dona do arquivo que acrescenta, `fake_dom.mjs` editado por uma frente de cada vez. Mudanças: os passos 1–3 da 67 como escritos; uma linha de decisão o registra (o cabeçalho da frente reivindica uma resposta que nenhuma decisão tem).
- **Medido.** `fieldError` depois de `__jhFormState`, re-renderização no lugar em `ok: false`, `pending` de dois formulários, commit / rollback otimista leem `document` e `FormData`; `botopink test` não tem DOM; `jhonstart-dom-test` (`fake_dom.mjs`, só commonJS) já serve a metade de navegador da renderização. O cabeçalho da frente 67 diz "`67-a` respondida", mas nenhuma decisão a registra — ainda aberta.
- **Opções.** (a) Estender `fake_dom.mjs` com `<form>`, `<input>`, `FormData`, `submit`; afirmar as cinco caixas (3a, 3b, 4, 5 da 1.0.10) em `jhonstart-dom-test/test/forms_dom_test.bp` agora, e de novo no navegador da onze 53. (b) Só no navegador da onze 53. (c) Uma biblioteca DOM real como dependência de dev.
- **Recomendação.** (a).
- **Bloqueia.** 67 passos 1–3 (escritos para (a)); o caminho de escrita da onze 53.

### 06-emilia

### 07-onze

#### 50-b · O que `onze dev` faz numa mudança
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): `onze dev` é `build` e depois `start`, em loop sobre um observador de arquivos — um caminho de código, os bytes que o `start` serve** — uma mudança reconstrói e reinicia o nó (1–3 s por edição); o estado das ilhas se perde de qualquer modo (Fast Refresh não é meta). O hot load de (b) e o fallback de (c) acrescentam um segundo caminho cuja equivalência com o `start` nada prova (67); (b) volta quando (a) medir lento demais no blog. Viável: `onze-cli/src/start.bp` (`erl -noshell -pa … -eval …`), `onze-bundler/src/rebuild.bp` (a invalidação, mantida para a metade do cliente); `onze dev` responde 2 hoje (`main.bp`) e nenhum observador existe — o observador é o `fs` do std em commonJS / erlang com o `io.process.spawn` / `forwardSignals` da 506 para o filho; o passo 2 da 50 o constrói. Mudanças: o "recarrega os módulos mudados" do passo 6 da 50 vira um reinício; o passo 6 da 53.
- **Não viável (fable, 2026-10-12):** (b) e (c) — o caminho de hot load não está escrito, e nada prova sua equivalência com os bytes que o `start` serve.
- **Contexto.** `onze dev` é o comando de desenvolvimento da renderização no servidor do onze (o onze agora é o pacote `rakun-ssr`, mono-a): enquanto o app roda, ele deveria pegar o que o usuário acabou de editar. Hoje ele responde 2 e não faz nada; `onze build` compila o servidor para BEAM e `onze start` o roda. A escolha é se uma mudança reinicia o servidor a partir de um build novo ou carrega os módulos mudados no que está rodando, e ela precisa ser feita antes que o passo 2 da 50 construa o observador (decisões 67, 140, 506).
- **Medido.** `onze build` compila o servidor para BEAM (`server/beam/`), `onze start` roda `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` calcula os módulos invalidados; o BEAM pode fazer `code:load_file/1`; o registro de UI e a tabela de rotas se preenchem no carregamento do módulo (decisão 140): uma página recarregada se re-registra, um novo arquivo de rota precisa de `onze_routes.bp` regenerado e da tabela reconstruída.
- **Opções.**
  (a) Reiniciar o nó a cada mudança (`build` + `start` em loop sobre um observador de arquivos — os mesmos bytes de `start`, 1–3 s por edição).
  ```text
  $ onze dev
  # src/app/page.bp saved → build, then start again: the node restarts (1–3 s) and serves what `onze start` would
  ```
  (b) Carregar a quente os módulos alterados; regenerar e recarregar `onze_routes` quando a árvore do app mudar.
  ```text
  # src/app/page.bp saved → each invalidated module reloaded with code:load_file/1 in the running node
  # a new route file → onze_routes.bp regenerated, the route table rebuilt
  ```
  (c) (b), recaindo em (a) quando um arquivo de convenção mudou.
  ```text
  # page.bp saved → hot-loaded as (b); a convention file saved → restarted as (a)
  ```
  Estado de ilha do navegador perdido de qualquer jeito (Fast Refresh um não-objetivo, `07-onze/reference-holes.md` § 29).
- **Recomendação.** (a): um caminho de código, os mesmos bytes que `start` serve; (b) depois, se (a) medir lento demais no blog.
- **Bloqueia.** 50 passo 2; 53 passo 6.

#### 49-g · `isString` — do próprio onze, ou o `Json` do std
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b), no `json`: `Json.isString()` ao lado de `isObject`; o onze apaga o seu** — um leitor por pergunta, na biblioteca dona do `Json` (396: a biblioteca `json` toma o `json.bp` do std inteiro; na feat o tipo ainda é do std porque o passo 1 da 142 não o moveu, então o método pousa no std sob a 97 e viaja com a mudança). (c) é um texto de diagnóstico como teste de tipo, nunca. Viável: `libs/std/src/json.bp` (o `case` de `isObject` é a forma), depois o `isString` de `onze/modules/onze/src/config.bp` e o import de `types.bp` vão embora. Mudanças: uma continuação de uma linha no onze depois que a linha do std pousar.
- **Medido.** O passo 1 da 49 moveu `onze/src/config.bp` e `types.bp` para os métodos do `Json` do std
  (`members`, `field`, `str`, `items`, `isObject`, `kindName`); o std não tem teste de string, então
  `config.bp` mantém um `pub fn isString(v: Json) -> bool` (um `case` sobre `Str`), importado por
  `types.bp`. O grep do passo (`membersOf`, `strOf`, `isObject`, `kindName`) está vazio; sua
  linha de Mechanism também nomeia `isString`.
- **Opções.** (a) Manter o `isString` do onze — `if (isString(v) == false) throw wrongKind(…)`.
  (b) O std acrescenta `pub fn isString(self: Self) -> bool` ao `Json` (superfície da 97), o onze apaga o
  seu — `if (v.isString() == false) throw wrongKind(…)`. (c) Ler por `kindName` —
  `if (v.kindName() != "a string") throw …` (um texto de diagnóstico como teste de tipo).
- **Recomendação.** (b): um leitor por pergunta, no std, ao lado de `isObject`; (c) nunca.
- **Bloqueia.** nada; sob (b), um acompanhamento de uma linha em `config.bp` / `types.bp` depois da 97.

#### 51-a · Um inteiro malformado num sidecar de métricas ou num ângulo de gradiente
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b): recusar — `parseMetrics(…) -> @Result<FontMetrics, string>` responde `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, e `gradientOf` responde seu valor "not a two-stop linear gradient" para um ângulo não inteiro** — uma entrada malformada é recusada, nunca lida como zero (67; o precedente da 299: `rkPropInt("12abc") == 12` foi revertido). Viável: `onze-og/src/metrics.bp` (`Error(_) -> 0` em três pontos de `parseInt`) e `svg.bp` `gradientOf`; os pontos de chamada e `og_test.bp`. Mudanças: as caixas de `og_test.bp` da 51.
- **Medido.** O passo 1 da 51 substituiu as duas células `intOf` do `onze-og` pelo `string.parseInt()` do std;
  as células antigas respondiam `0` para texto que não é inteiro, e os pontos de chamada agora também
  (`case t.parseInt() { Ok(n) -> n.toI32(); Error(_) -> 0; }` — `metrics.bp` `parseMetrics`,
  `svg.bp` `gradientOf`). Uma linha de sidecar `ascent 9x0` lê-se como `ascent 0`;
  `linear-gradient(9.5deg,#a,#b)` desenha a 0°. Um inteiro além de `i32` agora aborta (`toI32`).
- **Opções.** (a) Manter `0`. (b) Recusar: `parseMetrics(…) -> @Result<FontMetrics, string>`
  responde `Error("<family> <weight>: line 3: \"9x0\" is not an integer")`, e `gradientOf`
  responde seu valor "not a two-stop linear gradient" (`#(-1, "", "")`) para um ângulo que não é
  inteiro.
- **Recomendação.** (b) — decisão 67: uma entrada malformada é recusada, nunca lida como zero.
- **Bloqueia.** nada hoje; (b) é uma mudança em `og_test.bp` dona da 51.

### 08-bpp

#### 116-b · Os papéis são checados num projeto sem arquivo `.bpp`? (*proposta* ★)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído — confirmar** — os papéis são checados sempre que a chave está presente; uma chave que não pode ser honrada é recusada onde é escrita, antes de um arquivo depender dela (67, 361 (4)). Viável, construído: `compiler-cli/src/cli/libs.zig` (`if (project.bpp) checkBppRoles`), `bpp.zig` `checkPackage`, célula `bpp_html_missing` (sem arquivo `.bpp`, recusada na chave). Mudanças: nenhuma; uma linha de decisão.
- **Medido** (frente 116 passo 1). 361 (4): "a chave num projeto sem `.bpp` aceita". Implementado:
  a chave é aceita, e os papéis do pacote que ela nomeia ainda são checados em todo
  `build` / `check` / `run` / `test` (`compiler-cli/src/cli/bpp.zig`, chamado de
  `libs.loadDependencies`) — `tests/language/modules/bpp_html_missing` não tem arquivo `.bpp` e é
  recusado na chave. Hoje `"bpp": "jhonstart"` é a recusa de tal projeto até o
  `05-jhonstart/26` passo 0 mover o `html` (e seu `#[bpp.html]`) do `jhonstart-html` para o core.
- **Opções.**
  (a) ★ Os papéis são checados sempre que a chave está presente:
  ```text
  { "bpp": "jhonstart" }, no .bpp file, the core marks no #[bpp.html]
  error: "bpp" names "jhonstart", and no declaration of it carries #[bpp.html] — …   (at the key)
  ```
  (b) Os papéis são checados só quando o projeto tem um arquivo `.bpp`; a chave sozinha nunca é recusada
  além do `manifest.parse` (uma dependência, uma string):
  ```text
  { "bpp": "jhonstart" }, no .bpp file → builds; the first Card.bpp added → the error above
  ```
- **Recomendação.** (a): uma chave que não pode ser honrada é recusada onde é escrita, antes de um arquivo
  depender dela (decisão 67).
- **Bloqueia.** Nada — (a) está construída; (b) removeria uma chamada.

#### 116-c · Um decorator num `var` de módulo (a decisão 356 nomeia um `val`) (*proposta* ★)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a), como construído — confirmar** — um decorator do usuário num `var` de módulo é recusado na anotação; recusar não perde nada de que uma biblioteca precise, e (b) / (c) podem ser acrescentadas sem quebrar um programa (a 356 nomeia um `val`: um `var` não tem valor de build). Viável, construído: `infer.zig` (a recusa), célula `val_decorator_on_var`. Mudanças: o `docs.md` da célula ainda diz "question 116-c open"; uma linha de decisão.
- **Medido** (01-compiler/130 passo 10 caixa 1). Antes da 356 todo decorator de usuário
  num binding de módulo era descartado em silêncio. A 356 faz um num `val` rodar (`DeclKind.Val`). Um `var`
  de módulo é o mesmo nó de AST (`ValDecl.mutable`); construído: um decorator de usuário num `var` é recusado na
  anotação, `` `#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on
  a `var` `` (`tests/language/reject/val_decorator_on_var`); `#[@BeamMemory.…]` não é tocado.
- **Opções.**
  (a) ★ Recusado na anotação (construído):
  ```bp
  #[mark]
  var count = 1;   // error at `mark`: … a decorator runs on a `val`, never on a `var`
  ```
  (b) Roda como o de um `val`, kind `DeclKind.Val`, e o `var` é catalogado:
  ```bp
  #[mark]
  var count = 1;   // mark runs; @TypeInfo.all(with: mark) answers `count`
  ```
  (c) Roda com seu próprio kind, `DeclKind.Var`, para um decorator poder distinguir os dois:
  ```bp
  fn mark(comptime decl: @Decl) { if (decl.kind == DeclKind.Var) decl.fail("…"); }
  ```
- **Recomendação.** (a) até um uso ser medido: recusar não perde nada de que uma biblioteca precise hoje, e
  (b) ou (c) podem ser acrescentados sem quebrar um programa.
- **Bloqueia.** Nada.

### 09-cardume

#### atm-c · O `T` de um átomo através da costura servidor/navegador (*proposta*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(b), com `#[clientOnly]` na declaração do átomo como a única grafia** — qualquer `T` pode ser um átomo; o conjunto de leituras de uma ilha é checado no build sobre seus hooks (277: arestas `use atomValue(x)`), e um átomo que uma ilha lê cujo `T` não é codificável (o `encode` do `#[validated]`, 327, ou um tipo que a 294 aceita) deve ser declarado `#[clientOnly] pub val draft = atom(…);` — a única função com um só significado da 278, numa declaração como a 186 a põe num hook — senão um erro no `use` da ilha nomeando o átomo e `T`; nenhum `clientAtom(…)`. Restritiva onde cruza, livre no resto (a 354 (6) declara a costura para contextos e deixa os átomos a esta pergunta); (a) proíbe um handle de DOM em qualquer átomo, (c) descobre em run time. Viável só com o cardume: `repository/cardume` não existe (296, passo 0 da 136) e rakun / jhonstart ainda não têm átomos de requisição; a checagem precisa que `HookUse` carregue o argumento de declaração do `use` (o `val` do átomo) — sujeito ao `HookUse` da 277 ganhá-lo (uma linha 144 se o B-17 não o fizer), senão o conjunto de leituras da ilha é incognoscível no build. Mudanças: o passo 6 da 136 escrito para (b); a 282 lê `#[clientOnly]` num `val`.
- **Não viável (fable, 2026-10-12):** toda opção hoje — `repository/cardume` não existe (passo 0 da 136); a proposta vincula o passo 6 da 136 quando abrir.
- **Medido.** O servidor semeia os valores que uma ilha leu em seu payload (136 passo 6); um valor que cruza deve ser codificável — depois da 306, o membro `encode` de um tipo `#[validated]` (`T.encode(v)`, 327; outra biblioteca aceita `T` só com `@typeInfo(T).meta(Validated)`), ou um dos `T`s que a 294 aceita para um cookie (string, número, `bool`, enum, record de um campo); algum estado é só do navegador por natureza (um handle de DOM, uma função).
- **Opções.** (a) O `T` de todo átomo codificável, checado onde o átomo é declarado. (b) Qualquer `T`; o conjunto de leitura de uma ilha checado no build — um átomo não codificável que uma ilha lê deve ser declarado só-cliente (`clientAtom(…)`, ou o `#[clientOnly]` da 278 estendido a declarações, 282). (c) Qualquer `T`, recusado só em tempo de execução.
- **Recomendação.** (b): restritivo onde importa (o que cruza), livre no resto.
- **Bloqueia.** 136 passo 6.

#### atm-d · Quais efeitos de átomo são entregues (*proposta*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): nenhum efeito de átomo no primeiro corte** — o store pousa primeiro; `persistLocal` / `syncSearchParam` são um passo próprio depois de uma necessidade medida, uma função por preocupação (281: uma chave é a declaração, nunca uma string). Viável: nada a construir; o cardume ainda não tem código (136). Mudanças: o passo 8 da 136 adiado.
- **Não viável (fable, 2026-10-12):** (b) e (c) hoje — o cardume não tem código; a proposta é (a), nada a construir.
- **Medido.** Os efeitos de átomo do Recoil persistem ou sincronizam um átomo (localStorage, URL, um push do servidor); nenhum existe aqui.
- **Opções.** (a) Nenhum no primeiro corte. (b) Só `persistLocal("cart")`. (c) `persistLocal` e uma sincronização de search-param (`syncSearchParam("tab")`).
- **Recomendação.** (a): pousar o store primeiro; efeitos como um passo próprio depois de uma necessidade medida.
- **Bloqueia.** 136 passo 8.

### 10-specs

#### 141-a · Como uma decisão que aposenta uma grafia impede os specs de derivar (*proposta*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): o commit da decisão reescreve a grafia aposentada em `specs/<current>/**` e acrescenta sua linha ao `inventory.md` da 141; o `land-check.py` (484 (4), 163 s12) acrescenta uma checagem — uma linha de decisão que emenda ou substitui N fica vermelha enquanto uma grafia que N aposenta ainda está escrita fora de um milestone fechado e das tabelas de alias** — a deriva nasce no commit da decisão, então é fechada ali; a lista de permissão de (b) escusa linhas (67) e não distingue uma frase que declara uma regra de uma que nomeia o que remove; (c) deixa uma frente ler a forma aposentada por um milestone. Viável: nenhuma ferramenta para (a); a checagem são algumas linhas em `scripts/land-check.py` (ainda não escrito — o 163 s12 está aberto), lendo as palavras da própria linha pela grafia que aposenta (a linha nomeia as duas formas, o inventário da 141 os arquivos). Mudanças: o passo 6 da 141 e a caixa do 163 s12.
- **Medido.** A 354 aposentou `@Component<C, R>`; o compilador a recusa e o codemod da 134 reescreveu as bibliotecas (`01-compiler/134` passo 6 caixas 1, 6), mas cerca de 280 linhas de spec em 71 arquivos ainda escrevem grafias aposentadas (`10-specs/141-specs-sweep/inventory.md`, nove famílias), e 25 linhas de `decisions-taken.md` ainda declaram o texto que uma emenda substituiu. Nada liga uma decisão às linhas de spec que ela aposenta.
- **Opções.** (a) O commit que escreve tal decisão também reescreve as linhas de classe S de `specs/<current>/**` que escrevem a forma antiga, e acrescenta sua linha ao `inventory.md` da 141 — um dever de quem escreve a decisão, sem ferramenta. (b) Uma checagem 6 de CI meta: uma lista de grafias aposentadas e dos arquivos autorizados a nomeá-las, vermelha em qualquer outro acerto — uma lista que desculpa linhas, o que o espírito da decisão 67 recusa, e uma checagem que não distingue uma linha S de uma linha R. (c) Nada: a varredura da 141 re-roda em cada fechamento de milestone.
- **Exemplos.** Uma decisão que aposenta `Context<T>()` por `createContext(value)` (379): (a) seu commit também reescreve o `pub val StyledContext = Context<StyledSheet>();` de `08-bpp/119/README.md` para `comptime createContext(StyledSheet.missing())` e acrescenta uma linha F1 ao `inventory.md` — `grep -rn 'Context<StyledSheet>()' specs/1.0.12-beta` fica vazio quando pousa; (b) `scripts/retired-spellings.txt` ganha `Context<[A-Z][A-Za-z]*>\(\)` com `01-compiler/134/README.md` autorizado, e a checagem 6 fica vermelha na linha da 119 até alguém reescrevê-la — e fica verde numa caixa que nomeia a forma como o que ela remove só porque esse arquivo está na lista; (c) a linha da 119 mantém `Context<StyledSheet>()` até o milestone fechar, e uma frente que abre a 119 nesse meio-tempo lê a forma aposentada.
- **Recomendação.** (a): a deriva nasce no commit da decisão, então é fechada ali; (b) só se (a) for medida falhando.
- **Bloqueia.** 141 passo 6.

#### Superadas por uma decisão posterior (frente 141 passo 5)

Listadas para o mantenedor, não fechadas aqui; cada uma mantém sua própria entrada e id.

| Id | Superada por | Fechamento recomendado |
|---|---|---|

### Do registro em português do mantenedor (`decisoes-pendentes.md`)

#### 07-i (revision) · Se a proibição da 163 de nomes repetidos em pacotes embutidos sobrevive ao alias da 170
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): continua proibido — um novo pacote embutido escolhe um nome que o std e os frameworks não exportam** — o alias da 170 serve às colisões próprias de um programa, não à nomeação do ecossistema; um nome para uma coisa entre pacotes se lê igual em todo módulo (67), e o `cookie` do `http`, o `id.deriveActionId` do `actions` já escolheram nomes livres. Viável: nada a construir. Mudanças: o "até a linha do toolchain fechar" da 163 vira regra permanente; nenhuma no código.
- **Medido.** A 163 proíbe um pacote embutido de exportar um nome que o std ou um framework exporta "até a linha do toolchain fechar"; a 170 (um import que nomeia seu módulo nunca é ambíguo; alias quando os dois são necessários) a fecha.
- **Opções.** (a) Ainda proibido: um novo pacote embutido escolhe um nome que não colide (o módulo `cookie` do `http`, o `id.deriveActionId` do `actions`). (b) Proibição suspensa: nomes naturais, os importadores usam alias.
- **Recomendação.** (a).
- **Bloqueia.** Nada; 102, 103 e 104 já escolheram nomes livres.

### 20-snap

### Propriedade

#### own-a · Quem é dono dos test runners (*proposta*)
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a) como a 433 já corta: os runners do botopink-lang são da 144, os `scripts/**` da meta da 163** — o § Ownership do `fronts.md` o declara ("144 holds them; the meta `scripts/**` are 163's"); um passo que edita um runner o nomeia em seu commit; a 114 de (b) e a 07-residuals de (a) estão dentro da 144 desde a 433 (1). Viável: a regra está em vigor; o item aberto do `fronts.md` ainda lista `tests/language/run.sh`, que saiu com a 466. Mudanças: o item aberto fecha; o `fronts.md:55-59` da entrada é o § Ownership.
- **Medido.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (além das linhas de orçamento da 114), `tests/language/run.sh` (além do relatório da 12), `modules/test-shard/**`, `modules/lib-test-runner/**`, os `scripts/**` do meta eram de `25-gate-perf`, 113, 115, 133, todas fechadas (`fronts.md` § Ownership, item aberto). Regra provisória ali (`fronts.md:55-59`) = opção (c): uma frente que edita nomeia a exceção em seu commit; duas frentes abertas não editam o mesmo arquivo. Nenhum passo aberto edita um runner: o passo 12 da 07-residuals "não edita nenhum runner", as linhas de orçamento do passo 5 da 114 já são da 114, o passo 7 da 114 só roda o gate.
- **Opções.** (a) `01-compiler/07-residuals`, que já guarda o passo aberto da 25 (a compilação de dependência por célula). (b) `00-gate/114`, o resíduo do gate. (c) nenhuma: cada frente nomeia uma exceção por commit (a regra provisória de hoje, mantida).
- **Recomendação.** (a): um dono, a frente que herdou o passo aberto da 25.
- **Bloqueia.** Nada hoje; a regra provisória (c) vale até ser respondida.

### Contradições que não bloqueiam nenhum passo 00–03

#### ctr-l · A terceira recusa da decisão 186 contra a decisão 202
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Retirar a terceira recusa da 186** — sob a 202 nenhuma página se declara pré-renderizada, então "um hook `#[serverOnly]` numa página que se declara pré-renderizada" não tem caso: o `#[page]` recusa um hook `#[serverOnly]` dentro de um componente `#[client]` e um hook `#[clientOnly]` fora de um, e renderiza por requisição uma página cujos hooks alcançam `#[serverOnly]` (186, 202, 277). Viável: o contexto da 26 já lista só as duas recusas (`machine-1/150-rakun/26-jhonstart-router/context.md`). Mudanças: a linha da 186 perde sua terceira recusa; o `README.md:58-59,182-183` da entrada é esse arquivo de contexto.
- **Regras.** A 186 recusa "um hook `#[serverOnly]` numa página que se declara pré-renderizada (`08-g`)". A 202: "Nenhuma declaração … nenhum `pub val prerender` … nenhum jeito de forçar". Uma página é `pub fn blog() -> View` lendo `use cookie(sessionCookie)` (293, 294): renderizada por requisição, sem erro.
- **Recomendação.** Descartar a terceira recusa da 186: sob a 202 nenhuma página se declara pré-renderizada. O `05-jhonstart/26` passo 8 já lista só as duas recusas (`README.md:58-59,182-183`); só a linha da 186 está pendente.
- **Bloqueia.** Nada nas frentes; o registro.

#### ctr-v · A decisão 189 (org-3) contra as frentes do emilia abrindo antes da 118
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **Registrar: um carve-out só de comentários é tomado pela frente dona; a 118 mantém as linhas de código** — a org-3 sequencia carve-outs de código, e as linhas de colchetes do emilia são comentários (hoje só em `emilia/AGENTS.md`, `README.md`, `conformance/docs.md` e no comentário de uma célula: `attributes.bp` / `emilia.bp` não têm nenhuma, e `emilia-card` não existe mais). Viável: nada a construir. Mudanças: a linha org-3 da 189 ganha a frase; as linhas de arquivo da entrada estão defasadas.
- **Regras.** org-3: as exceções da 118 pousam antes de a frente dona abrir. `06-emilia/34` passo 1 e `33` passo 2 abrem agora; as linhas `[class]={…}` do emilia (`attributes.bp:30,32,36`, `emilia.bp:185,202`) e o `[emilia]={…}` de `emilia-card/src/main.bp:5` são só comentários, reescritos por essas frentes.
- **Recomendação.** Registrar que uma exceção só de comentários é tomada pela frente dona; a 118 mantém as linhas de código (seus próprios testes, o teste de ponte do `jhonstart-emilia`, `document-shell`). As frentes já a seguem (118 § Does not touch, 34 passo 1, `fronts.md:49`); só a linha da org-3 está pendente.
- **Bloqueia.** Nada nas frentes; o registro.

#### ctr-w · O braço Elasticsearch da frente 09 contra a decisão 185
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **O braço Elasticsearch alcança HTTP por um ponto de extensão do core (185), nunca por uma aresta `rakun-data → rakun-client`; respondida com a lista de braços da `03r-ab`** — o `rakun-data` depende só de `rakun` e `rakun-actuator` hoje e nenhum braço existe, então nada é desfeito. Viável: o padrão de registro do core (`rkOnReset`; o registro de transporte da `03r-an`), ou o `io/http` do std diretamente, como o relay da 65 faz. Mudanças: o passo 3 da 09 escrito contra ela.
- **Regras.** 185: uma capacidade opcional passa por um ponto de extensão do core, "nenhuma aresta de membro para membro". `04-rakun/09` § Open point: o braço Elasticsearch sobre `rakun-client` acrescenta uma aresta `rakun-data → rakun-client` que todo consumidor de data carrega.
- **Recomendação.** O braço alcança HTTP por um ponto de extensão do core (ou `httpc` diretamente, como o relay da 65), não por uma aresta `rakun-client`; respondida com a lista de braços da `03r-ab`.
- **Bloqueia.** 09 passo 3.

#### 119-a · A caixa de grep do passo 1 contra o hook byte-idêntico da checagem 4 do CI
- **Proposta (fable, 2026-10-12; aguardando o mantenedor):** **(a): a caixa faz grep no texto próprio do pacote — `{src,test,botopink.json}` de `css` e `styled`** — o hook é um só texto de que o gate é dono (checagem 4 do CI), `AGENTS.md` e `decisions-taken.md` nomeiam os vizinhos por design (as camadas da 338), e o `{src,test,botopink.json}` do `css` está vazio hoje; o do `styled` não (`src/styled.bp` e `test/styled_example_test.bp` nomeiam o `flush()` do emilia e o render do jhonstart em comentários) — a 150 s32 reescreve esses dois comentários (338 (2): `styled` não nomeia jhonstart nem emilia). Viável: um grep. Mudanças: a caixa do passo 1 da 119; a "linha 31" da entrada é `runner-standalone.sh:45`, e `css/AGENTS.md` contém `emilia` (por design).
- **Regras.** 119 passo 1 e seu gate: `grep -rn "bpp\|jhonstart\|emilia" repository/css repository/rakun/modules/rakun-style` vazio (338). Checagem 4 do CI (meta `AGENTS.md` § CI): `scripts/git-hooks/lib/runner-standalone.sh` byte-idêntico em todo repositório de biblioteca — e sua linha 31 lê `# one-at-a-time gate printed. Front 115 of 1.0.11-beta measured emilia's`, então o grep o encontra em `repository/css` (e encontrará em `repository/rakun/modules/rakun-style`). `src/`, `test/`, `AGENTS.md` e o manifesto não guardam nenhum dos três nomes.
- **Opções.** (a) A caixa faz grep no texto do próprio pacote: `grep -rn "bpp\|jhonstart\|emilia" repository/css/{src,test,botopink.json} repository/rakun/modules/rakun-style/{src,test,botopink.json}` — vazio hoje para `css`. (b) O comentário do hook compartilhado perde o nome, em todo repositório de biblioteca de uma vez (checagem 4), uma mudança que nenhum dos repositórios da 119 possui.
- **Recomendação.** (a): a caixa mede o que o pacote sabe; o hook é um texto dono do gate.
- **Bloqueia.** Só marcar a caixa de grep do passo 1 da 119.

---

## Parte 3 — Escolhas de implementação das trilhas 04–09

### 04-rakun (21)

| Id | Escolha implementada | Onde |
|---|---|---|
| 03r-a | Todo manifesto do rakun é `["erlang"]`; um programa erlang construído distribui e carrega seus sidecars `.erl` (a metade do ledger perde o sentido sob a 153) | todo membro |
| 03r-c | Os leitores da frente 05 continuam botopink (`config.bp`); nenhum `rakun_config.erl`; sob a 299 alimentam os records `#[config]` | 04 |
| 03r-e | Um componente de cookie ou query que o std recusa, ou que decodificaria para um caractere de controle, fica como escrito (`decodeComponent`) (`ctr-p`) | 04 |
| 03r-f | Uma chave de cache é `namespace + ":" + hash.strongCacheKey(parts)` | 12 |
| 03r-g | Uma leitura de escopo privado sem sessão roda o loader, não guarda nada | 12 |
| 03r-h | A chave de um gêmeo é `[method, args…]`; `#[cacheEvict(name, false)]` o expulsa sob todo leitor `#[cacheable(name)]` | 12 |
| 03r-i | O provedor de cache Redis reutiliza o wire RESP do rakun-session (`rkSessRedis`); `revalidateTag` apaga; um Redis inalcançável roda o loader sem cache (health DOWN) | 12 |
| 03r-j | Fora de uma requisição `revalidateTag` / `revalidatePath` são legais, `updateTag` lança; o global `rakun.cache.type=none` desativa todo cache seja qual for seu próprio tipo | 12 |
| 03r-k | Todo braço de messaging roda no broker em processo (`transport=memory`); um endereço real sem ele recusa o boot nomeando o driver | 15 |
| 03r-l | Um container de listener recebe o nome de seu destino (`#[amqpListener("orders")]` → `rakun.messaging.listener.orders.*`, `#[streamListener("audit-stream", "@next")]` → `listener.audit-stream.*`); o Redis tem por default o ack-mode `none` (`auto` / `manual` explícito no Redis recusa o boot). As grafias das chaves seguem a 299 (`ackMode` ou `#[key("ack-mode")]`) | 15 · `markers.bp:90,103` · `container.bp:125` |
| 03r-m | Dentro de uma server action `revalidatePath` / `revalidateTag` expiram de uma vez; fora, obsoleto-depois-fresco | 12 · 22 |
| 03r-n | Um argumento JSON-RPC é uma lista de campos codificados como formulário, lida em ordem num só formulário | 22 |
| 03r-p | Um slot pertence ao layout mais próximo na altura de sua entrada mais curta ou acima dela; um conflito são duas páginas de um slot numa URL | 22 |
| 03r-r | Os starters nomeiam membros irmãos como `{ "workspace": true }` | 73 |
| 03r-s | OTLP empurrado como HTTP/JSON (`json:encode` em `rakun_metrics.erl`) | 17 |
| 03r-t | As chaves da frente 76 sob `rakun.management.*`, num só `management.bp` mais o sidecar `rakun_probes` | 11 |
| 03r-u | O grupo de liveness admite só `livenessState`, `ping`, `diskSpace`; qualquer outro nome recusa o boot | 11 |
| 03r-v | O operador do construtor de queries tipado é o enum `Op` (`Eq`, `Ne`, `Lt`, `Gt`, `Le`, `Ge`, `Like`): `queryOf(City.entityMeta()).where(City.columns().state, Op.Eq, "CA")`; a coluna como `Type.Field<City>` (308) é uma pergunta separada | 08 · `orm/query.bp:84-115` |
| 03r-w | Os endpoints explícitos do OAuth2 são campos de `OAuth2Provider` (`authorizationUri`, `tokenUri`, `userinfoUri`, `jwksUri`); as credenciais de cliente são `withClientToken(id, call)`, tentando uma vez de novo em 401 | 79 · 13 |
| 03r-x | O relay do outbox reivindica por `UPDATE` condicional (as reivindicações de um relay que caiu voltam por `reclaimStale`); os coordenadores de saga e 2PC persistem toda transição e retomam no boot (`resumeSagas`, `recover2pc`); o job store reivindica triggers e assume leases do mesmo modo | 15 |
| 04-a | A época de tag do core só cresce (`rkResetContext` a deixa), é `i64`, e a tag vazia é recusada em `rkBumpTag` / `rkTagEpoch` | 04 passo 1 · `rakun/src/runtime.bp`, `rakun_runtime.erl` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-a:** confirmar a regra só-erlang; sob a 512 (3) os 27 manifestos de membros, 8 de starters e 3 de exemplos que repetem `"targets": ["erlang"]` o largam (o workspace o declara uma vez) — com a `95-b`, a varredura de manifestos da 150.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-c:** confirmar (`rakun/src/config.bp`, nenhum `rakun_config.erl`); os records `#[config]` da 299 ainda não estão construídos (`#[configurationProperties]` e `rkProp*` permanecem) — rakun 04 s7.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-e:** revertida pela `ctr-p`: nada fica "como escrito"; `decodeComponent` vai embora com os leitores que a 196 apaga.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-f:** confirmar (`rakun-cache/src/cache.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-g:** confirmar (`cache.bp`: uma linha privada sem sessão roda o loader, não guarda nada).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-h:** confirmar (`cache.bp` `cacheMethod`, `cacheEvictAll`, `cacheEvictKeys`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-i:** confirmar; o wire Redis ainda é o `rkSessRedis` do `rakun-session` importado pelo `rakun-cache` — uma aresta membro-a-membro que a 185 move para o core quando uma frente a tocar.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-j:** confirmar (`cache.bp`: `rakun.cache.type=none` vence todo cache; `updateTag` fora de uma action entra em pânico).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-k:** confirmar (`rakun-messaging/src/container.bp` aceita só `memory`, recusa nomeando o driver).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-l:** emendar sob a 318 (5): um listener, `#[listen(orders)]` num método de um `#[component]`, o destino declarado uma vez e tipado (`pub val orders = Destination<OrderPlaced>("order-events")`), o container nomeado por esse destino (`rakun.messaging.listener.<destination>.*`), o modo de ack `none` do Redis imposto, as chaves lidas pela config tipada da 299 (`ackMode` / `#[key("ack-mode")]`); na feat `markers.bp` ainda declara `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]`, `#[streamListener]`, `#[listener]` e lê `rkProp(listenerKey(…))` — o passo da 15 para a 318.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-m:** confirmar (o texto de fase de action do `cache.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-n:** confirmar (`rakun-app/src/actions.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-p:** confirmar (`rakun-app/src/file_router.bp`, `slotOf`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-r:** confirmar (`starters/rakun-starter/botopink.json` `"workspace": true`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-s:** confirmar (`rakun_metrics.erl` `otlp_*_json`, `json:encode`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-t:** confirmar (`rakun-actuator/src/management.bp`, `rakun_probes.erl`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-u:** confirmar (`management.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-v:** confirmar como o estado na feat (`rakun-data/src/orm/query.bp` `Op`, `queryOf`, `City.columns()`); superada em direção por 312 / 397 / 398: o builder tipado sai do rakun-data quando o `self.db.query "…"` do erika e o dbcontext pousarem (137, 143), uma linguagem de consulta — a pergunta da coluna como `Type.Field<City>` (308) fica sem objeto então.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-w:** confirmar (`rakun-security/src/oauth2/provider.bp`; `client_credentials.bp` `withClientToken`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 03r-x:** confirmar (`tx/outbox.bp` `reclaimStale`, `saga.bp` `resumeSagas`, `twopc.bp` `recover2pc`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 04-a:** confirmar (a entrada acima).

### 05-jhonstart (9)

| Id | Escolha implementada | Onde |
|---|---|---|
| 26-a (jhonstart) | Toda célula do router de alvo duplo (um gêmeo `router_runtime.mjs`). Id compartilhado com o `26-a` do 01-compiler, decisão 242 | core |
| 29-a | O que a 281 deixa: a tabela de starters de ilhas é o `globals.starters` do registro, preenchida por rota por `registerRouteStarters(pattern, load)` (um padrão de rota é uma URL, uma string sob a 281); um segundo loader para uma rota falha. O `registerStarter(name, start)` por nome sai — a 281 constrói a tabela de starters em comptime (`@TypeInfo.all(with: client)`, 120 passo 6, 53 passo 7) | core · 26 passo 5 (sua linha de `docs.md` ainda nomeia `registerStarter`) |
| 30-b | `RenderPlugin` é um record de funções async; `payload` responde `Array<#(key, json)>`; `chunk(id)` roda no próprio processo do boundary | `streaming.bp` |
| 30-c | `render` / `renderStream` / `App` em `streaming.bp`; `compose` recebe a página como um thunk, roda os layouts primeiro — `compose(chain, { -> Page() })`; o parâmetro `route: PageContext` de hoje sai com a 293, a página é `fn() -> View` (276) | `streaming.bp` · `render.bp:341` |
| 30-d | `Suspense(Boundary(id, fallback, child))` registra seu boundary na renderização por uma célula de host; a página devolve só a árvore (`-> View`) | `suspense.bp:19-34` |
| 30-e | O record de segmento é `UiSegment` | core |
| 30-f | `app(…, lang = "en")`: uma língua checada por app. A checagem vira o subconjunto BCP 47 da decisão 180 quando a 105 substituir `isLangTag` por `i18n.wellFormedTag`; um `PageInput.lang` por requisição do `htmlLang()` existente do rakun-app continua aditivo | core · `streaming.bp:197-204` · 105 |
| 30-g | Metade de navegador afirmada no membro só-commonJS `jhonstart-dom-test` sobre `fake_dom.mjs` | `jhonstart-dom-test` |
| 31-a | `notFound()` / `redirect(url)` lançam por uma célula de host (`__jhRaise`); um boundary captura por `__jhCapture`; `notFoundReason()` / `redirectReason(url)` respondem a razão sem lançar. Declaram `-> string` até `noreturn` caber numa posição de valor — espera nat-d6 e lg2-l (se nat-d6 for (a), viram `-> noreturn`) | core · `error_boundary.bp:118-187` |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 26-a (jhonstart):** confirmar (`router_runtime.mjs` ao lado de `router.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 29-a:** confirmar a escolha reduzida (`registerRouteStarters` + `globals.starters`); o `registerStarter` por nome ainda está declarado em `client.bp` — vai embora com a tabela de starters em comptime da 281 (26 passo 5, 120 passo 6), uma linha 149.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-b:** confirmar (`plugin.bp` `RenderPlugin`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-c:** confirmar o thunk (`render.bp` `compose(chain, route: PageContext, page: fn() -> @Component<Element>)`); o parâmetro `route: PageContext` ainda está lá — sai com a 293 (26 passo 11), quando a assinatura vira `compose(chain, { -> Page() })`.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-d:** confirmar (`suspense.bp` `Boundary`, `__jhPushBoundary`); seu `child: fn() -> @Component<Element>` vira `@Component<Element>` sob 504 / lg2-n.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-e:** confirmar (`routes.bp` `UiSegment`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-f:** confirmar (`streaming.bp` `app(…, lang = "en")`, `isLangTag`; o repositório `i18n` da 105 ainda não existe).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 30-g:** confirmar (`jhonstart-dom-test`, `fake_dom.mjs`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 31-a:** emendar sob a `nat-d6` (a) e a `lg2-l`: `notFound()` / `redirect(url)` viram `-> noreturn`, lançando um `NavOutcome` tipado; `notFoundReason()` / `redirectReason(url)` ficam; `isSignalReason` vai embora.

### 06-emilia (9)

| Id | Escolha implementada | Onde |
|---|---|---|
| 05emilia-a | O leitor de filter é a cadeia inline do upstream (`filterChain()`, `backdropFilterChain()`), não `var(--tw-filter)` | 42 |
| 05emilia-b | A seção de backdrop é `BackdropFilter` | 42 |
| 05emilia-c | `drop-shadow-none` segue o upstream (`--tw-drop-shadow: ` e o leitor) | 42 |
| 05emilia-d | A rigidez do snap é o fallback `var(--tw-scroll-snap-strictness, proximity)` | 46 |
| 05emilia-f | As entradas `--inset-shadow-*` descartam o `inset` inicial do upstream | 41 |
| 05emilia-g | `space-*` / `divide-*` seguem o seletor do upstream e margens cientes de reverso | 35 · 40 |
| 05emilia-i | As variáveis de transform `--tw-*` são blocos `@property` com a camada `properties` do upstream — `translate-*`, `skew-*` e `scale-*` (`--tw-scale-*`) igualmente | 45 · 54 · 56 |
| 05emilia-j | Um modificador de lista de seletores (`marker:`, `selection:`) é uma lista de variantes de um `&` | 34 · 56 |
| 05emilia-k | O meio passo negativo é `spacingNegHalf(n)`; `spacingHalf` recusa um `n` negativo | 54 |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-a:** confirmar (`emilia.bp` `filterChain`, `backdropFilterChain`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-b:** confirmar (`BackdropFilter` em `emilia.bp`, `tokens.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-c:** confirmar (`emilia.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-d:** confirmar (`tokens.bp` / `emilia.bp` `--tw-scroll-snap-strictness`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-f:** confirmar (`theme.bp` `--inset-shadow-*`; o detalhe do `inset` inicial não reverificado).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-g:** confirmar (`emilia.bp` `space-*` / `divide-*`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-i:** confirmar (blocos `@property` em `emilia.bp`, `tokens.bp`, `output.bp`; o nome da camada não relido).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-j:** confirmar (`emilia.bp` `selectionVariants`, `tokens.bp` `Selection`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 05emilia-k:** confirmar (`spacing.bp` `spacingNegHalf`; `spacingHalf` recusa um `n` negativo).

### 07-onze (9)

| Id | Escolha implementada | Onde |
|---|---|---|
| 49-a | As suítes do core renderizam por seus próprios `describe*` sobre `snapshots.assertAs`; os helpers do `onze-test` são wrappers finos | core do onze |
| 49-c | `onze.json` recusa uma chave desconhecida, uma duplicada, um tipo errado, uma porta fora de `1..65535`, uma entrada não-string de `allowedRedirects` | `config.bp` |
| 49-e | A metade rakun do boot é o membro erlang `onze-server` | 49 passo 2 |
| 50-a | `onze build` prepara um main de servidor, compila para BEAM; `onze start` o roda com `erl` — como emendado: `start` chama o `bin/onze` da frente 71 assim que existir | 50 · 71 passo 2 |
| 52-a | A tabela de métricas de fonte tem cinco linhas transcritas; seu gerador é devido | 51 passo 4 |
| 53-a | Os fontes do blog sob `src/` (`appDir: "src/app"`) | 53 |
| 68-a | Um campo do manifesto de cliente escapa só `%`, `\|`, LF e CR | bundler |
| 68-d | O styleMap é avaliado por uma sonda compilada em ambos os pacotes (`emilia-hash-split`, `emilia-unevaluated`) — sem sentido quando o passo 1 da 34 e o passo 4 da 119 pousarem (301: os tokens `#[styled]` são comptime, a classe e a regra calculadas no build sobre o `contentHash` do std); vale até lá | bundler |
| 69-a | O onze-assets mantém `AssetRoot`; o onze-server o converte para o `StaticRoot` do rakun-web | assets · server |

- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 49-a:** confirmar os `describe*` próprios; emendar o motor: as suítes escrevem pelo `assertAs` do `snap` (391; `import {assertAs} from "snap"`, uma dependência git em `onze/botopink.json`), não pelo `snapshots` do std.
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 49-c:** confirmar (`onze/src/config.bp`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 49-e:** confirmar (`onze-server`, erlang).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 50-a:** confirmar (`onze-cli/src/start.bp` roda `erl -noshell …`; `bin/onze` espera a 71).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 52-a:** confirmar (`onze-assets/src/font_metrics.bp`, cinco linhas; o gerador devido).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 53-a:** confirmar (`examples/blog/onze.json` `appDir: "src/app"`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 68-a:** confirmar (`onze-bundler/src/manifest.bp` `escapeField`).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 68-d:** confirmar até 34 s1 / 119 s4 pousarem (a sonda e seu snapshot ainda existem).
- **Proposta (fable, 2026-10-12; aguardando o mantenedor) — 69-a:** confirmar (`onze-assets/src/assets.bp` `AssetRoot`; `onze-server/src/server.bp` `staticRootOf`).
