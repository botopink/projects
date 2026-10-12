# Decisões pendentes — 1.0.12-beta

**66 perguntas e 6 contradições estão abertas, e 100 escolhas de implementação aguardam confirmação** (contadas das
entradas abaixo: uma pergunta com letra, sendo `nat-d` e `nat-f` títulos de seus casos; `ctr-*` e `119-a` as
contradições; uma linha de uma tabela de escolhas, ou uma entrada `#####` ao lado dela).

- Uma resposta vai para [`decisions-taken.md`](decisions-taken.md) sob o próximo número livre (mantido
  só lá); um id com letra nunca é renumerado nem reutilizado. O próximo número livre é **484**.
- Toda recomendação é a leitura mais restritiva, sem configuração que a contorne (decisão 67).
- Uma frente que encontra uma pergunta que não consegue responder pelo código a acrescenta aqui: id · título · Medido
  (observado, re-executável) · Opções · Recomendação · Bloqueia. *Proposta* = levantada sem id.

- **Parte 1** — o que bloqueia a frente 144 (`repository/botopink-lang`, decisão 433: os passos abertos das antigas trilhas
  `00-gate`, `01-compiler`, `02-std-and-packaging`, `03-bundled-libs`), por antiga trilha, depois as
  escolhas de implementação dessas trilhas que aguardam confirmação.
- **Parte 2** — o resto (trilhas 04–10, 20, propriedade, contradições que não bloqueiam nenhum passo 00–03).
- **Parte 3** — as escolhas de implementação das trilhas 04–09.

A página em português (`decisoes-pendentes.md`) é a tradução direta desta página: o texto em inglês guarda o sentido
(`AGENTS.md` da meta § Conventions). Ids respondidos saem deste arquivo; `decisions-taken.md` guarda as respostas e o próximo
número livre, que é **484**.

---

## Parte 1 — O que bloqueia as trilhas 00–03

### 01-compiler

`00-gate` não tem pergunta aberta: os passos da 114 não esperam nenhuma decisão.

#### s29-a · Como uma anotação de template recebe a declaração anotada, e se ela também é um template de ponto de chamada (311)
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
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(b).** Um tipo de meta é ou único ou repetido numa declaração, nunca os dois: gravado com `setMeta` é lido com `meta(T)` (`?T`); gravado com `addMeta` é lido só com `metaAll(T)` (`T[]`) — `meta(Index)` sobre um tipo adicionado é `typeinfo-meta-repeated` na leitura mesmo com um valor, então acrescentar um segundo decorator nunca quebra um leitor. Um tipo ao mesmo tempo setado e adicionado numa declaração (ou setado duas vezes) continua `decorator-meta-twice` na anotação que o gravou; `metaAll(T)` sobre um tipo setado responde um array de um elemento.
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
- **Regras.** 146: uma função cujo corpo alcança uma função de host sem binding para o alvo "é recusada em sua declaração, chamada ou não". `lem-c` (construído, a confirmar): um método de host sem binding "é recusado onde é CHAMADO" — recusar a declaração era a opção não tomada; a 311 mantém o mesmo na chamada.
- **Recomendação.** Confirmar `lem-c` para uma declaração de host sem corpo (um tipo declarado uma vez ainda compila para um alvo que seu método não tem); declarar que a 146 rege qualquer função com corpo, livre ou método, que alcance uma; `docs.md` diz as duas coisas.
- **Bloqueia.** A confirmação de `lem-c`.

#### 17-c · O que mais nomeia um var `keyed: true`
- **Medido.** Construído: só `counts.at(k)` (`ets:lookup`) e `counts = counts.insert(k, v)` (`ets:insert`); todo o resto (`counts[k]`, `hasKey`, `delete`, `size()`, passá-lo adiante) recusado no identificador; um var keyed nunca é `pub`. A 63 da 1.0.5: um índice responde `V` e falha numa chave ausente; `at` responde `?V` (`null`).
- **Opções.** (a) As duas formas, como construído, e `counts = counts.bump(k, n)` (340). (b) (a) mais `counts[k]` com o significado da 63 (`ets:lookup`, `V`, falha numa linha ausente). (c) (b) mais `hasKey` (`ets:member`) e `delete` (`ets:delete`), cada um uma nova primitiva de `std/beam`.
- **Recomendação.** (a).
- **Bloqueia.** Nada — a superfície construída vale até ser ampliada.

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
  declare fn session() -> @Component<string>;        // #[@External.Node("""Promise.resolve("alice")""")]
  fn Page() -> @Component<Element> { val u = use session(); … }
  // (c): Page sync, `const u = session()` — a Promise where a string is read
  ```
- **Recomendação.** (a): uma marca que nunca é falsa onde o commonJS precisa de um `await`, e verdadeira não mais ampla do que
  os tipos dizem.
- **Bloqueia.** Nada — construído como (a).

#### 04s12-a · Um método, lambda ou `default fn` de `@Component` não tem nó de hooks (375 (2), 04-js passo 12)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(c), e um tipo pode ser um componente — toda forma se comporta e é chamada como um componente `fn`.** (1) Um método, uma lambda ou um `default fn` que responde `@Component<R>` é baixado como um componente de topo: uma lambda sobre o `RenderScope` (388) que responde sua árvore e o scope dos seus filhos, com `use provide` / `use context` / `await` no seu corpo, marcado pelo próprio corpo (s23-j); chamá-lo só cria a lambda e não marca quem chama. (2) Um tipo que implementa `Component<R>` é um componente: seus campos são suas props e seu `render(self) -> R` é seu corpo — `type Menu(items: string[]) implement Component<Element> { fn render(self: Self) -> Element { val t = use context(Theme); return <ul class={t.cls}>…</ul>; } }` — escrito e chamado como `fn Menu(items: string[]) -> @Component<Element>` é: `<Menu items={["a", "b"]}/>`, o mesmo lowering `(props) => (scope) => …`, as mesmas marcas. O scope nunca é um campo (388 (5): nada capturado; o renderer o entrega em cada execução, inclusive um fill de `Suspense`). (3) Cada um tem seu próprio nó de hooks, e o nó de um método ou de um tipo entra no `decl.hooks` (277 amendada: uma chamada de método seguida pelo tipo do receptor), então um decorator vê os hooks de `Menu` como vê os de `fn App`. **(2) em detalhe** (o mantenedor, 2026-10-12): um tipo que implementa `Component<R>` é açúcar para um componente `fn`. Seus campos são os parâmetros — padrões, opcionais, `children`, genéricos como numa `fn`, imutáveis — e seu `fn render(self: Self) -> @Component<R>` é o corpo, `self` lendo os campos e os métodos auxiliares do tipo. `X(campos…)` e `<X …/>` respondem o componente (a lambda `(props) => (scope) => …`), nunca um record, então quem chama não distingue as duas formas. O mesmo lowering em commonJS, erlang, beam e wasm, o mesmo `.d.ts` (`export declare function X(props: {…}): Component<R>`), as mesmas marcas (s23-j: um `render` com `await` é assíncrono), o mesmo `decl.hooks` para decorators (`#[page] type` e `#[page] fn` intercambiáveis), o mesmo comptime (434-b). Hooks só no `render`; um método auxiliar que não responde `@Component` é uma função comum. Recusados, localizados: `implement Component` sem `render`; um `render` de outra assinatura; um campo `RenderScope` (388 (5)); um `use` fora do `render`; `X.render()` chamado direto (`call the component, not its body: <X …/> or X(…)`). **(2) amendada — as props de um componente são um record** (o mantenedor, 2026-10-12): um componente, `fn` ou tipo, recebe suas props como um único parâmetro record, nunca uma lista de parâmetros. `type MenuProps(items: string[], title: string = "Menu");` — então `fn Menu(props: MenuProps) -> @Component<Element> { val t = use context(Theme); return <nav class={t.cls}><h2>{title}</h2><ul>{items.map({ i -> <li>{i}</li> })}</ul></nav>; }`, ou o mesmo componente como tipo: `type Menu(props: MenuProps) implement Component<Element> { fn render(self: Self) -> @Component<Element> { …<h2>{self.title}</h2><ul>{self.items.map({ i -> self.item(i) })}</ul>… } fn item(self: Self, i: string) -> Element { return <li>{i}</li>; } }` (`item` não responde `@Component`: um auxiliar comum). Os campos do record estão em escopo: nus no corpo da `fn` (`title`, `items`), em `self` no `render` e nos auxiliares (`self.title`, `self.items`); `props` nomeia o record inteiro. Padrões, opcionais, `children` e genéricos são do record, escritos uma vez em `MenuProps`. Quem chama nunca constrói o record: os atributos são seus campos — `<Menu items={["a", "b"]}/>` (`title` assumindo seu padrão), `<Menu items={["a", "b"]} title="Principal"/>`, `<Layout view={ { -> <Menu items={xs}/> } }/>` (dentro de uma prop lambda, igual) — e o compilador constrói o `MenuProps` a partir deles, verificado campo a campo como uma construção de record (um campo faltando, um atributo desconhecido, um tipo errado: localizado no atributo). Um componente sem props não recebe parâmetro (`fn App() -> @Component<Element>`). O lowering não muda — `(props) => (scope) => …`, `props` o record — e o `.d.ts` o nomeia: `export declare function Menu(props: MenuProps): Component<Element>`, `MenuProps` exportado ao lado. Recusados, localizados: um componente com mais de um parâmetro, ou cujo único parâmetro não é um tipo record (`a component takes its props as one record: type MenuProps(…); fn Menu(props: MenuProps)`).
- **Medido.** O 04-js passo 12 pede que um método, um lambda e um `default fn` sigam a marca "do mesmo modo", mas os
  nós da 277 são só as funções de nível superior do módulo. Construído: cada um continua uma `async function` / arrow `async` no
  commonJS, e uma chamada de um deles mantém seu `await` (uma chamada que o checker não consegue seguir, s23-j (1)).
- **Opções.** (a) Como construído. (b) O checker marca todo corpo de `@Component` — um método, um `default fn`, um lambda —
  pela regra da 375 (um nó próprio, não listado em `decl.hooks`), o commonJS emite cada um por sua marca:
  ```bp
  type Menu(items: string[]) { fn render(self: Self) -> @Component<Element> { return Element(…); } }
  // (a): `async render(map) {…}`, `await menu.render(map)`; (b): `render(map) {…}`, no `await`
  ```
  (c) (b), e o nó de um método entra em `decl.hooks` (277 emendada: uma chamada de método seguida pelo tipo de seu
  receptor).
- **Recomendação.** (b): a regra é do corpo, onde quer que o corpo seja escrito; (c) muda o que um leitor de `.hooks`
  vê e é pergunta da 277.
- **Bloqueia.** O método, o lambda e o `default fn` da caixa 1 do 04-js passo 12.

#### s23-a · Dois nomes de campo dos records da decisão 277 (contradição com as palavras reservadas)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(a), como construído.** `HookNode(function: Declared<unknown>, uses: HookUse[], calls: HookCall[])` e `HookUse(…, context: ?Declared<unknown>)`, lidos `n.function.name` e `u.context.name` por um decorator no build; o `fn` da 277 é palavra reservada e não é nome de campo.
- **Medido.** A 277 escreve `HookNode(fn: Declared<unknown>, …)`; toda palavra-chave é reservada em toda posição
  (`reserved-word-as-name`: `type N(fn: string)` é recusado no campo). A 354 (4) pede que `Decl.hooks` carregue cada
  `provide` / `context` "com seu objeto" e não nomeia nenhum campo. Construído (`01-checker` passo 23): `HookNode(function:
  Declared<unknown>, uses: HookUse[], calls: HookCall[])` e `HookUse(…, context: ?Declared<unknown>)`, lidos como
  `n.function.name` e `u.context.name` (`run/decl_hooks_context` imprime `App: std/context.provide(main.ThemeContext)`).
- **Opções.** (a) Como construído: `n.function`, `u.context`. (b) `n.decl` / `u.target`: `n.decl.name`, `u.target.name`.
  (c) `n.of` / `u.object`: `n.of.name`, `u.object.name`.
- **Recomendação.** (a): as palavras que as decisões usam para eles, nenhuma exceção às palavras reservadas.
- **Bloqueia.** Nada — construído como (a); um renome toca `builtins.d.bp`, o espelho do `comptime.zig`, `hooks.zig` e as células.

#### s23-c · O que o `Declared` de uma declaração alcançada guarda num corpo de decorator
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

#### s23-g · Onde `Decorator.same` é declarado (o `extend Decorator { … }` da 371 não faz parse)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(a), como construído.** `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }` no `builtins.d.bp`, espelhado no `decl_reflection_src` do `comptime.zig`; o `extend Decorator { … }` anônimo da 371 é lido como este membro, e `a.decorator.same(serverOnly)` não muda.
- **Medido.** A 371 escreve `extend Decorator { pub fn same(self, other: Decorator) -> bool; }` em `builtins.d.bp`. Um
  `extend` é sempre nomeado (`'extend' needs a name`, `parser.zig` `reportAnonImplExtendError`), `builtins.d.bp` é
  lido pelo teste de deriva (`comptime/builtins.zig` `collectTypes`), e esse teste guarda os métodos de instância de um tipo builtin
  dentro de sua declaração. Construído e pousado: um membro do behavior, espelhado em
  `decl_reflection_src` do `comptime.zig` — `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }`;
  `a.decorator.same(serverOnly)` lê igual nos dois casos.
- **Opções.** (a) Como construído: `pub behavior Decorator { fn same(self: Self, other: Decorator) -> bool; }`. (b) Uma
  extensão nomeada: `pub DecoratorIdentity extend Decorator { fn same(self: Self, other: Decorator) -> bool; }`, o teste de
  deriva ensinado a ler os métodos de um `extend` em seu alvo. (c) O parser aceita um `extend Decorator { … }` anônimo
  só em `builtins.d.bp`.
- **Recomendação.** (a): nenhuma exceção ao parser para um arquivo, e o teste de deriva já o guarda.
- **Bloqueia.** Nada — construído como (a).

#### s23-i · Um catálogo de um leitor de `.hooks` lido no próprio módulo do leitor (372)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(d), uma quarta opção: o catálogo é lido só na raiz do pacote.** (1) `@TypeInfo.all` é lido só na raiz do pacote (`main.bp` num binário, `root.bp` numa biblioteca); em qualquer outro módulo é recusado, localizado, nomeando a raiz (``@TypeInfo.all` is read only in the package's root (src/main.bp) — move it there`). (2) Nenhum módulo do pacote importa da sua raiz — recusado, localizado (`src/pages/home.bp imports from the package's root (src/main.bp) — the root imports the package, never the reverse`) — então o resolver analisa a raiz depois de todo módulo que sua árvore de `mod` declara. (3) Na raiz, os catálogos são respondidos depois que os seus próprios leitores de `.hooks` rodaram (um passo 4 depois dos três da 372), então uma declaração decorada na própria raiz também traz sua meta. Nenhum catálogo é respondido antes do que ele lista: toda entrada traz sua meta inteira. Substitui `typeinfo-all-hooks-reader`. Um framework recebe o catálogo da raiz da aplicação como argumento (`jhonstart.serve(@TypeInfo.all(with: page))`), nunca o lê sozinho. **Todo pacote com fontes tem raiz** (o mantenedor, 2026-10-12): um pacote cujo `botopink.json` tem fontes declara `src/root.bp` (uma biblioteca) ou `src/main.bp` (um binário), e o resolver segue a árvore de `mod` a partir dela; o blind scan deprecated sai — um pacote com fontes e sem raiz é recusado, localizado, nomeando o arquivo que falta. Um manifesto sem fontes (o `"workspaces"` de um workspace, o manifesto de dependência de uma fixture) não precisa de raiz. `onze/examples/scaffold` move seu `root.bp` para `src/root.bp` ou seu manifesto nomeia onde fica sua raiz — escolha da frente 162; `json`, `yaml` e `dbcontext` nascem com `src/root.bp`. Medido no `feat` de cada biblioteca: todo outro pacote com fontes já tem uma.
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

#### 14s8-a · Como um template lê o valor de build de um buraco (355; `01-compiler/14` passo 8 caixa 1)
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(e), uma quinta opção: o buraco é da sublinguagem, não da linguagem.** Um template recebe o texto bruto do seu literal (`@Expr<string>`, `q.text()`) — escrito `css "…"` ou `css """…"""`, ambos iguais, nenhum interpolado pela linguagem dentro de uma chamada de template — faz o parse com sua própria gramática, inclusive a sintaxe dos seus buracos (`{expr}`, como o `html` do jhonstart faz), e responde código botopink por `q.build(code)` / `q.custom(tree, code)`. Um template nunca lê o valor de um buraco: a expressão do buraco é emendada no código gerado (`css "padding: {gap};"` → `"padding: " + cssValue(gap) + ";"`), e o checker a tipa no escopo de quem chama, recusando no buraco do usuário pelo span do `CustomNode` (`cssValue(true)`: `expected Length | string, got bool` em `{true}`). Calcular no build é do compilador, pela 355 / 376: uma chamada de função `Any` com argumentos conhecidos é dobrada no build (`card` vira `"padding: 8px; margin: 1.5rem;"`), senão roda no render (`badge(size)`). `Part.Interp`, `known` e `hole.value` saem da API de template; os templates que leem `q.parts()` hoje (styled, emilia …) fazem o parse do seu texto. `"${x}"` numa string comum continua interpolando.
- **Medido.** A caixa 1 foi escrita como `e.lookup(name)` respondendo o valor de build de um `val`. Um buraco `${…}` não acrescenta palavra à captura (237), então `lookup` não alcança `tab4` em `styled "${tab4} color: red;"`, e os buracos conhecidos no build da 355 incluem um literal e um `comptime`, que não têm nome. Construído e pousado: cada parte `Interp` de `q.parts()` carrega `known` (bool) e `value` (o valor de build como dado, um record seus campos; `null` quando calculado na renderização). `builtins.d.bp` ainda declara `Part.Interp(hole: Expr<string>, span)`; a parte que um corpo lê carrega `code`, `known`, `value` (leituras de campo em `Part` não são checadas hoje), então um valor de forma errada falha o template em tempo de execução: `styled "${whole} margin: 0;"` com `whole = styled "color: red;"` (um `Styled` onde cabe uma declaração) é `{error,{badkey,declarations}}` no literal, onde a chamada calculada o recusava como `type mismatch: expected StyledProperty, got Styled`.
- **Opções.** (a) Como construído: `for (q.parts()) { p -> if (p.kind == "Interp" && p.known) built = built + p.value; }`; `p.value` é `null` para um buraco calculado na renderização. (b) `q.lookup(p.code)` responde `Binding(name, kind, value)` para um buraco que nomeia um `val`: `val b = q.lookup(p.code); if (b?.value != null) …` — um buraco literal ou `comptime` nunca é conhecido. (c) O `@Expr<T>.value` da 364 em cada buraco: `if (p.known) built = built + p.hole.value;`, o `.value` de um buraco não conhecido no build um erro na leitura, localizado — uma grafia com todo outro parâmetro `comptime`, o buraco tipado `@Expr<T>`.
- **Recomendação.** (c) — uma grafia, tipada, uma leitura de valor desconhecido recusada (decisão 67); (a) vale até o `01-checker` s24 construir `@Expr.value`, e de qualquer forma `Part` em `builtins.d.bp` (o da 02) declara o que a parte carrega.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-c · Um buraco conhecido no build cujo valor lança lá
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **(a), pela 14s8-a (e).** A expressão de um buraco é emendada no código gerado; quando o compilador a dobra no build (355 / 376) e ela lança, o build é recusado no buraco do usuário, localizado — nunca adiado para o render.
- **Medido.** Um buraco conhecido no build é avaliado no runtime de comptime como um `comptime` é (331). Construído: um lançamento é recusado no buraco — `pub val boom = raising "x"; pub val read = quote "${boom}";` (`raising` construindo `crash("x")`, que dá `@panic`) é ``this hole is known at build (decision 355) and its value raised there: the comptime block raised: {error,{panic,<<"crash: x">>}}`` em `${boom}` (`reject/hole_known_at_build_raises`).
- **Opções.** (a) Recusado no buraco (como construído). (b) O buraco é calculado na renderização (`known` falso): `read` constrói, e o programa lança quando lê `boom`.
- **Recomendação.** (a) — falhar > avisar, no build e não em tempo de execução.
- **Bloqueia.** Nada — construído como (a).

#### 14s8-d · Um `comptime` que alcança uma função declarada depois dele que contém uma chamada de template
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
#### 434-b · Os caminhos residente-na-renderização e no-build sob um só runtime de comptime wasm (434, 378 (4))
- **Respondida (o mantenedor, 2026-10-11; aguardando seu número em `decisions-taken.md`):** **Toda biblioteca roda no build no runtime de comptime wasm (434), o jhonstart primeiro; uma função que só Erlang ou Node consegue rodar é um erro localizado ali.** (1) Uma célula de host (`@External.Erlang` / `@External.Node`) alcançada no build roda pela sua forma wasm — um corpo botopink (`#[@External.Wasm(fn: …)]`) ou um export do std-wasm (`std:`, 481) — então `comptime renderToString(<Rodape ano={2026} />)` responde uma string para todo alvo. (2) Cada biblioteca dá às suas células puras (escape, formatação, parse — lógica escrita em Erlang ou JS por conveniência) uma forma wasm: o renderer do jhonstart (`jhonstart_render.erl`) primeiro, para o 144 B-17, depois cada frente de biblioteca (145–162) num passo próprio. (3) Uma função sem forma wasm — 100% Erlang ou Node, ou um efeito real de host (rede, banco, fs, processo) — alcançada por um `comptime` é recusada no build, localizada, nomeando a célula: `error: `Rodape` reaches jhonstart_render:escape/1, which has no wasm form — it cannot run at build (give it a botopink body, or remove `comptime`)`. Nenhuma tradução substitui uma forma wasm ausente no build (sem fallback de beam-to-wasm), e nunca a VM do alvo (c). O alvo do build não estreita isso: um `comptime` roda no wasm qualquer que seja o `--target`, então um build erlang que alcança no build uma célula só `@External.Erlang` é recusado como um build commonJS é. A leitura do comptime fora isso não muda (388 (4): `RenderScope.root()`).
- **Medido.** A 84 mandava uma avaliação de comptime para a VM do alvo, então um build erlang renderizava um componente `Build` / `Any` no build no BEAM (o passo erl de `render_resident`) e um build commonJS no wat. A 378 (4) pede que o runtime de comptime rode o lambda de um componente com `RenderScope.root()` (388) — `comptime renderToString(<Rodape ano={2026} />)`; a última caixa do passo 6 da 134 (144 B-17). Sob a 434 o único runtime é o wasm, e o renderizador do jhonstart no BEAM é um sidecar (`jhonstart_render.erl`).
- **Opções.**
  (a) O renderizador roda no build só no wasm: o caminho de renderização do jhonstart alcançado no build é botopink (ou std-wasm), sua célula Erlang traduzida pelo beam-to-wasm onde não tem corpo botopink; a resposta é uma string para todo alvo.
  ```bp
  val footer = comptime renderToString(<Rodape ano={2026} />);   // "<footer>2026</footer>" on the four targets
  ```
  (b) Um componente é renderizado no build só quando toda função que ele alcança tem um corpo botopink ou std-wasm; um que alcança uma célula Erlang é recusado no `comptime`, nomeando a célula.
  ```text
  error: `Rodape` reaches jhonstart_render:escape/1, which has no wasm body — it renders at run time (remove `comptime`)
  ```
  (c) Manter a VM do alvo só para a renderização no build (um passo BEAM dentro da compilação para builds erlang/beam).
- **Recomendação.** (b) agora — nenhuma resposta no build que dependa de uma tradução não provada; (a) quando o beam-to-wasm cobrir as células do renderizador; nunca (c), que a 434 remove.
- **Bloqueia.** 144 B-17 (a caixa da 378 (4) do passo 6 da 134); nada em B-00.

### 02-std-and-packaging

#### 97-s16-a · Onde ficam as tabelas geradas do `unicode`
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
- **Medido.** `files` lista, relativo a `src`, os módulos que um consumidor pode importar; uma biblioteca sem ele não distribui nada (`docs/botopink-json.md:52`). `workspaces` lista membros; um manifesto com ele é um workspace e recusa `src`, `files`, `entry`, `dependencies` (`:159-170`) — os dois nunca dividem um arquivo (`98-packaging-tail/README.md:27`). A 270 depende de `files` (o prelúdio `src/prelude.bp` é listado ali).
- **Opções.** (a) Ambos mantidos — empacotamento, não código. (b) `files` derivado dos módulos `pub` (um módulo interno marcado em código — `#![internal]` não tem grafia desde a 315), 270 reescrita; `workspaces` mantido. (c) Ambos derivados.
- **Recomendação.** (a): o que é distribuído é um fato de empacotamento, e a 270 já depende dele.
- **Bloqueia.** 98.

#### nat-d9 · Os nomes do LINQ no erika ao lado dos do std (98)
- **Medido.** `98-packaging-tail/README.md:47-51`; `erika.bp`: `where`, `select`, `selectMany`, `orderByDescending`, `toList`; o erika é ansioso — todo operador materializa um novo array (`erika.bp:5`); o std tem `filter`, `map`, `flatMap`, `unique` (217).
- **Opções.** (a) Nomes do std (`filter`, `map`), o erika acrescentando só o que o std não tem (`groupBy`, os agregados). (b) Nomes do LINQ — a identidade do erika é o LINQ. (c) Como está.
- **Recomendação.** nenhuma desta revisão: o propósito do erika decide (b) é uma leitura justa.
- **Bloqueia.** 98 (erika).

### 03-bundled-libs

#### ctr-p · Confirmação `std-a` contra a confirmação `03r-e`
- **Regras.** `std-a`: `querystring.parse` / `parseForm` "recusam … um escape que decodifica para um caractere de controle", e o `splitQuery` do rakun passa a usá-los. `03r-e`: um componente de cookie ou de query que decodificaria para um caractere de controle "fica exatamente como escrito". A 196 move os leitores de cookie do rakun para o `http`.
- **Recomendação.** Confirmar `std-a`; `03r-e` caduca quando o rakun lê queries via `querystring` e cookies via `http`.
- **Bloqueia.** Os leitores da rakun 04; a varredura de consumidores da 104.

#### 396-a · onze-content: "um nó renderizado por um componente da própria página onde a página pede"
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
| ck2-a | `@module()` recusado na chamada (`builtin-not-lowered`) até uma regra dizer o que é um valor de módulo | `builtins.d.bp` · `reject/builtin_module_not_lowered` |
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

##### 24-c · `iter for` / `iter while` são um `loop` com prefixo (*implementado como (a)*)
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

##### 24-g · A forma do `std/async` com uma Task que nunca falha (*implementado como (a)*)
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

#### 03-bundled-libs (4)

| Id | Escolha implementada | Onde |
|---|---|---|
| 106-b | `log.consoleSink` escreve uma linha por registro na saída padrão por `@print` em todo alvo (não o `console.error` / `console.warn` do node, não o `logger` do OTP) — o único stream que um programa wasm também escreve; `defaultSink` mantém o logger do host | `repository/log/src/sink.bp` |
| 106-c | `log.fileSink` rotaciona como o `logger_std_h` do OTP faz, escrito uma vez em botopink sobre quatro células: depois que uma escrita deixa o arquivo em `maxBytes` ou mais, o arquivo vira `<path>.0`, cada arquivo morto sobe um, `<path>.<maxFiles - 1>` é apagado, `maxFiles` 0 apaga o arquivo; uma chamada de host que falha lança; o teto de tamanho total do rakun continua do rakun (dobrado em `maxFiles`) | `repository/log/src/logfile.bp` |
| 106-d | Níveis por nome: `Threshold { From(level), Off }`, `Levels(root, names)`, vale o prefixo pontuado mais longo definido; um nome vazio, um segmento vazio e um nome definido duas vezes são recusados (um `Error` quando um sink é construído, um panic quando resolvido); grupos e overrides em tempo de execução são do framework (ele reconstrói os `Levels` e instala um sink de novo) | `repository/log/src/levels.bp` |
| 106-e | `log.captureRuntimeReports()` observa e nunca trata: BEAM um filtro `logger` primário no domínio `otp` que repassa o evento inalterado (o handler do próprio OTP ainda o imprime), node `uncaughtExceptionMonitor` (o node ainda sai; `unhandledRejection` chega como sua origem sob o modo default do node), registros do logger `runtime` com `report.kind` (e a pilha do node sob `error.stack_trace`), wasm um binding no-op | `repository/log/src/reports.bp` |

#### Escolhas feitas pela thread bugs-sweep (4)

| Id | ★ implementado | Onde |
|---|---|---|
| bs-a | Uma fn associada de um tipo é chamada como a fn de um módulo do std é (`planQualifiedCall`): uma chamada curta é preenchida dos defaults declarados, uma rotulada é reordenada, qualquer outra contagem é o erro de aridade. `fn of(x: string, y: string = "d")` — (a) ★ `Bag.of("p")` é `Bag.of("p", "d")`; (b) recusar a chamada curta, `'of' expects 2 argument(s), got 1` (antes, toda contagem exceto a exata caía num fallback que não checava nada e não preenchia nada) | `infer.zig` `associatedCallReturnType` · `run/associated_fn_of_type_default` |
| bs-b | Um tipo sem sinal não aceita literal negado: `val x: u32 = -1;` — (a) ★ recusado no literal, ``the literal `-1` does not fit `u32` (at least 0)``; (b) aceito, e a checagem em tempo de execução da 264 aborta na negação (`-0` é aceito nos dois casos) | `infer.zig` `refuseIntegerOutOfRange` |
| bs-c | Um `erl` que imprimiu o banner de seu break handler (`BREAK: (a)bort …`) é uma execução interrompida mesmo saindo com 0 (SIGINT, depois EOF no stdin para o emulador com status 0): nunca guardado no cache de runtime — o único lugar em que o harness lê a saída, e só para decidir não cachear. (a) ★ o banner a marca como `.interrupted`; (b) iniciar `erl +Bi` (SIGINT ignorado): a execução termina e é genuína, mas uma execução travada então sobrevive ao Ctrl-C até o timeout de 2 minutos | `codegen/runtime.zig` `classifyEnd` |
| bs-d | `scripts/check-docs.sh --lib-root <dir>` substitui as raízes de biblioteca default; o teste do harness nomeia as suas. O gate mantém o default, que faz o hash de todo pacote irmão inteiro — `repository/vscode-extension` carrega um `botopink.json`, então um link simbólico em seu `node_modules` faz toda checagem de docs ficar `never stored` no checkout meta (um custo, nunca um veredito). (a) ★ como está; (b) as raízes default tomam só um pacote com `src` (o manifesto do vscode-extension é `{ "name", "version" }`); (c) o hash da árvore pula `node_modules` | `scripts/check-docs.sh` · `modules/compiler-cli/tests/result_store.sh` |

#### Escolhas de outras trilhas de que um passo 00–03 espera

| Id | Escolha implementada | Onde |
|---|---|---|
| 03r-q | O roteamento de locale vive em `rakun-app/src/i18n.bp`; nenhum membro `rakun-i18n` | 22 |

---

## Parte 2 — O resto

### Prioridade — a forma botopink (`nat-*`)

#### nat-d · Um segundo modelo do que a linguagem tem — caso a caso (decisão 283)
Nenhuma regra geral (283): cada caso abaixo é sua própria pergunta, (a) o da própria linguagem, (b) ambos — o estrangeiro uma camada fina sobre o nativo — ou (c) como está.

#### nat-d6 · `throw "nav:not-found"` ao lado de `noreturn` (53)
- **Medido.** Um sinal é uma string com prefixo `nav:` lançada pelo host (`contracts.md` § 5b); `notFound()` / `redirect()` do jhonstart declaram `-> string`, os do rakun `-> i32` (`jhonstart/src/error_boundary.bp:180-189`, `rakun-app/src/navigation.bp:47-55`); `isSignal` → `isSignalReason` por prefixo; `boundaries-example.bp:89-91` (um `throw` dentro de `-> @Result`, um valor `Error` pela 118, não um raise); `server-action-example.bp:79` `val _gone = redirect(…)`.
- **Regras.** 303: uma action responde `@Result<T, ActionError>` e `throw e` ali é `Error(e)`; `ActionError` tem `NotFound` mas nenhum caso de redirect — a resposta deve dizer também como uma action redireciona.
- **Opções.** (a) `fn notFound() -> noreturn`, boundaries casando o tipo `NavOutcome`. (b) O sinal de string mantido sob um wrapper tipado. (c) Como está.
- **Recomendação.** (a). Com lg2-l e lg2-h.
- **Bloqueia.** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

#### nat-d7 · Anotações de ciclo de vida ao lado de interfaces (rakun 04)
- **Medido.** `context-lifecycle-example.bp:66,72`: `#[postConstruct]`, `#[preDestroy]`.
- **Opções.** (a) `implement Lifecycle { fn start(self); fn stop(self) }`. (b) Ambos. (c) Como está.
- **Recomendação.** (a).
- **Bloqueia.** rakun 04.

#### nat-d8 · Um nome de hook `use…` sob `use` (53)
- **Medido.** `new-post-form-example.bp:118`: `use useActionState("createPost", actionState(""))` — o jhonstart não exporta nenhum `useActionState`; o hook do jhonstart-forms é `actionState(actionId: string, initial)` (`form.bp:182`).
- **Regras.** A 281 já resolve o argumento: a action é passada como referência (`createPost`), nunca como string — no exemplo e na assinatura de `actionState`. Só o nome do hook está aberto.
- **Opções.** (a) `use actionState(createPost, initial)`; um hook chamado `use…` recusado. (b) Os dois nomes. (c) Como está.
- **Recomendação.** (a).
- **Bloqueia.** Os exemplos da `07-onze/53`.

#### nat-f · Configuração em JSON — caso a caso (decisão 284)
`botopink.json` o mais limpo possível, configuração permitida onde faz sentido (284); `"bpp"` fica, um objeto desde a 338 (`{"default": "<package>", "style": …}`). Cada caso abaixo é sua própria pergunta.

#### nat-f2 · `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` do `onze.json` (124, 08-h)
- **Medido.** O `onze.json` é lido e validado por `loadConfig` sempre que o CLI resolve o projeto, `onze build` incluído (`onze-cli/src/resolve.bp:48-50`); uma chave desconhecida é recusada (49-c) sem linha. Só `allowedRedirects` existe (`onze/src/config.bp:192-193`); `trailingSlash`, `redirects`, `markdown` são as chaves planejadas da 124 (`124-bpp-cli/README.md:67-69`), que a 08-h já escreve; as quatro repetem opções que o código do onze tipa (`url_rules`, `MarkdownOptions`, `app(allowedRedirects:)`). Precedente: 299 (record tipado ligado a partir de um arquivo, erros nomeando arquivo, linha e tipo esperado).
- **Opções.** (a) Mantidas no `onze.json`, lidas no record tipado no build como a 299 faz, uma chave ou valor errado um erro em sua linha no arquivo. (b) Um record tipado no código do app (`pub val config = OnzeConfig(trailingSlash: .Never, …)`), sem JSON. (c) Como está.
- **Recomendação.** (a) — configuração é permitida ali (284); o build a checa como o código checaria, como a 299 faz para o rakun.
- **Bloqueia.** 124; 08-h; `07-onze/49`, `50`.

#### nat-f4 · O prefixo `ONZE_PUBLIC_` nas variáveis de ambiente (53, `contracts.md`)
- **Medido.** Uma variável chega ao código do cliente só quando seu nome começa com `ONZE_PUBLIC_` (o `NEXT_PUBLIC_` do Next). Um prefixo ausente não é silencioso: o bundler recusa no build o `env.read("X")` de um módulo cliente sem ele, nomeando a variável (`env-non-public`, `onze-bundler/src/refusal.bp:13-14`; `contracts.md:440-442`). O que resta é um fato de estágio (186) carregado por uma convenção de nome que o ambiente deve seguir (`client-island-example.bp:41`).
- **Opções.** (a) Mantido. (b) A declaração o diz — `#[publicEnv] val apiUrl = env.read("API_URL")`, seu uso de um componente `#[client]` checado em comptime (186); um marcador próprio, já que `#[clientVisible]` é a anotação de hidratação da 278; o `#[env("…")]` da 299 o precedente num record. (c) Uma lista de variáveis públicas no `onze.json`.
- **Recomendação.** (b).
- **Bloqueia.** `07-onze/50`, `53`; `contracts.md`.

### 01-compiler — a linguagem

#### lg2-b · O que `@Task<T>` significa no BEAM
- **Medido.** No erlang e no beam o corpo de uma Task roda até o fim onde é criada: dois `async.delay(300, …)` criados antes de qualquer um ser aguardado levam ≥ 600 ms (menos de 600 ms no commonJS).
- **Opções.** (1) Uma Task promete o valor, nada sobre quando seu corpo roda; concorrência = o processo explícito do `std/async` por thunk não iniciado, documentado. (2) Um escalonador por trás de `@Task` no BEAM (um processo por Task, `await` um receive). (3) `spawn` / `join` na linguagem.
- **Recomendação.** (1) — a leitura restritiva da 120 da 1.0.10.
- **Bloqueia.** A linha; rakun 02, 23, 25, 28, 30, 60.

#### lg2-d · Um decorator que lê o corpo que anota
- **Medido.** `decl.body` é o `unknown field 'body' on type 'Decl'` do checker, localizado na leitura no corpo do decorator (a linha de corpo de decorator do `01-checker`; era `{error,{badkey,body}}` na anotação); o handle carrega kind, nome, campos, variantes, métodos, tipo de retorno, anotações.
- **Opções.** (1) Nenhum acesso a statements. (2) Uma árvore de statements somente leitura no `@Decl`. (3) Uma API de comptime que percorre corpos.
- **Recomendação.** (1); a saga da rakun 83 continua um valor que pareia cada passo com sua compensação.
- **Bloqueia.** A linha; rakun 83.

#### lg2-h · Lançar e capturar por tipo
- **Medido.** `try load(p) catch { e: NotFound -> … }` não faz parse; o erro de um `@Result<T, E>` é tipado por `E`, lido com `case` no corpo do `catch`; uma exceção de host não é um `E`.
- **Opções.** (1) Um erro é o `E` de um `@Result` (a 121 da 1.0.10): um erro tipado é um enum casado com `case`. (2) Um braço de `catch` por tipo. (3) Exceções de host tipadas.
- **Recomendação.** (1) — a linha vira documentação da 121.
- **Bloqueia.** A linha; rakun 07, 31, 63.

#### lg2-l · Se `noreturn` é um tipo bottom
- **Medido.** `fn notFound() -> noreturn { raise("…"); }` encerra o caminho no commonJS e no erlang, mas `throw notFound();` num corpo `@Result` e `val s: string = notFound();` dão incompatibilidade → `notFound()` / `redirect()` do jhonstart declaram `-> string` (`error_boundary.bp:180-188`); o exemplo da frente 53 escreve `val _gone = redirect(…)` (`server-action-example.bp:79`); o app de blog do onze chama `notFound();` como statement. `@panic` / `@todo` são `noreturn`; um branch que termina numa chamada `noreturn` já estreita — pode ser confirmado de fato.
- **Opções.** (1) `noreturn` não unifica com nada: uma chamada a ele é um statement que encerra seu caminho; os sinais viram `-> noreturn` chamados como statements (numa página: `fn() -> View`, `use params<P>()`). (2) `noreturn` é o tipo bottom, cabe em qualquer posição.
- **Recomendação.** (1).
- **Bloqueia.** A linha; os sinais do jhonstart (63, `31-a`); os testes de navegação do rakun.

#### lg2-n · Um thunk coagido para `Node`
- **Medido.** `show({ -> "x" })` contra `fn show(children: Children)` (`Node` sob a 223) dá incompatibilidade.
- **Opções.** (1) Nenhuma coerção de thunk: um filho adiado é um campo nomeado do boundary. (2) `fn() -> Element` coage para `Node`.
- **Recomendação.** (1): as coerções conhecidas pelo compilador continuam três (array, `Element`, `string`).
- **Bloqueia.** A linha; jhonstart 30.

#### lg2-p · Cancelamento
- **Medido.** O `std/async` não tem handle de cancelamento; um competidor perdedor e um timeout expirado rodam até o fim.
- **Opções.** (1) Nenhum: o trabalho perdedor termina, resultado descartado, documentado. (2) Tokens de cancelamento explícitos. (3) Processos ligados com um caminho de kill no BEAM.
- **Recomendação.** (1), em compasso com `lg2-b` (1).
- **Bloqueia.** A linha; rakun 02.

#### lg2-s · Reflexão do grafo de módulos
- **Medido.** `decl.imports` é o campo desconhecido de `Decl` do checker, na leitura (era `badkey` na anotação); `onze-bundler/src/graph.bp` lê imports com `importsOf`, uma varredura textual.
- **Opções.** (1) Nenhuma: `importsOf` continua uma varredura textual que falha alto. (2) Um campo `imports` num `@Decl` de nível de módulo.
- **Recomendação.** (1); seu argumento antigo ("em compasso com `lg2-k`") caiu com a 216.
- **Bloqueia.** A linha; onze 68 (bundle cliente).

#### lg2-u · Um decorator em posição de expressão fora de markup
- **Medido.** `val x = #[deco] 1;` recusado (`loop-annotation-not-generator`). O caso de markup da frente 48 do emilia está respondido: uma anotação de tag é um decorator (278, 302), e o emilia alcança markup como `<h1 #[styled(…)]>` (301). Restante: um decorator numa expressão comum.
- **Opções.** (1) Nenhuma: fora de markup, o trabalho em nível de expressão é uma chamada (`traced(compute())`). (2) Decorators em posição de expressão rodam no script de avaliação (`#[traced] compute()`).
- **Recomendação.** (1).
- **Bloqueia.** A linha (o caso de markup da emilia 48 coberto pela 301).

### 02-std-and-packaging

#### std-e · Hooks de ciclo de vida de teste
- **Medido.** Os testes de biblioteca resetam o estado à mão no topo do corpo: `resetChain()` do rakun-web 77×, `rkAppReset(…)` 20×, `resetTables(…)` 14×, entre outros; `resetSingletons` / `resetContext` do rakun-test só em seu próprio `context_test.bp`; `installDocument(…)` do jhonstart-dom-test 11×.
- **Opções.** (a) Nenhum: um corpo de teste chama seu helper de reset. (b) `#[before]` / `#[after]` numa fn de nível de módulo que o runner chama em volta de todo `test`. (c) Blocos `beforeEach { … }` na gramática.
- **Recomendação.** (a): nada implícito roda em volta de um teste.
- **Bloqueia.** A linha "No test lifecycle hooks" do `language-gaps.md`.

### 03-bundled-libs

#### 07-b · "Uma biblioteca, várias cópias divergentes" também justifica um pacote?
- **Medido.** O rakun tem quatro leitores de `Cookie:` divergentes dentro de si (`request_context.bp`, `csrf.bp`, `rakun-app/i18n.bp`, `session_cookie.bp`; 196, frente 104). As cópias de cookie e q-value já qualificam pelo teste da 115 (o onze também as consome).
- **Opções.** (a) O "duas ou mais bibliotecas" da 115 continua o único teste. (b) Acrescentar o teste de divergência.
- **Recomendação.** (a): uma duplicata de uma biblioteca só vai para o std ou para o core da biblioteca dona.
- **Bloqueia.** Nada; a regra para o próximo candidato (o `http` da frente 104 existe; o rakun o adota em seu passo 5).

#### 07-h · Embutido, ou um repositório compartilhado separado
- **Medido.** Fios que os dois frameworks devem acordar byte a byte seguem com o compilador que os embute; um repositório separado = uma dependência git, restringida pela 242 (só uma dependência direta é importável); um membro de um repositório instala por `subdir` (344).
- **Opções.** (a) Embutido — versionado com o compilador, sem entrada em `dependencies`. (b) Um repositório compartilhado `botopink/common` com cadência própria.
- **Recomendação.** (a).
- **Bloqueia.** Nada espera; a trilha é cortada como (a).


### 04-rakun

#### erk-b · `#[documentQuery]` sob a 313 (*proposta*)
- **Medido.** 09 passo 4: `#[documentQuery("…")]` segue a forma de `#[query]` — um membro do tipo repositório que responde o template literalmente. A 313 apaga essa forma para SQL: um repositório é um `#[repository] behavior`, seus métodos carregando `#[erika "…"]` ou `#[nativeQuery("…")]`. A gramática do erika é a do SQL; o filtro de um document store é JSON (`$in`, `$gt`, …).
- **Opções.** (a) A mesma forma: um repositório de documentos é um `#[repository] behavior` cujos métodos carregam `#[documentQuery("…")]`, uma string comum entregue ao store como `#[nativeQuery]` entrega SQL ao driver (placeholders `:name` casados com os parâmetros, escapados por `bind`). (b) O erika ganha um alvo de documentos — o mesmo `select … where …` baixado para o filtro do store. (c) Como está: um membro do tipo.
- **Recomendação.** (a) agora — uma forma de repositório para todo store; (b) quando uma necessidade medida pedir.
- **Bloqueia.** 09 passo 4.

#### 03r-ab · Os stores de protocolo binário da frente 09
- **Medido.** O store é selecionado por `rakun.nosql.url`. MongoDB, Neo4j, Cassandra, Couchbase são protocolos de bytes (`Bytes` é da 346, ainda não construído) que precisam de drivers OTP que um sidecar não consegue carregar; ETS e Mnesia estão na VM; Redis é RESP sobre `gen_tcp`; Elasticsearch é HTTP + JSON. O README da 09 já está escrito para (a): os antigos passos 4 e 7 são as células de recusa do passo 5 mais uma linha de `deferred.md` cada — só falta o registro.
- **Opções.** (a) A 09 entrega `ets:memory`, `mnesia:local` / `mnesia:cluster`, `redis://`, `https://` com a suíte de behavior contra os quatro no gate; `mongodb://`, `bolt://`, `cassandra://`, `couchbase://` são esquemas reconhecidos cuja recusa no boot nomeia o driver (passo 5). (b) Quatro clientes de protocolo em sidecars Erlang, uma frente cada. (c) Adiar a 09.
- **Recomendação.** (a): nunca um fallback para ETS sob uma URL Mongo; o braço Elasticsearch sem uma aresta `rakun-client` (`ctr-w`; o passo 3 da 09 ainda passa por ela). A frente já segue (a).
- **Bloqueia.** 09 passo 5 (as células de recusa).

#### 03r-ae · ACS do SAML 2.0
- **Medido.** Verificar a assinatura de um IdP precisa de Exclusive XML Canonicalisation, que nem o `xmerl` do OTP nem o std fornecem; `saml2/saml2.bp` responde 501.
- **Opções.** (a) exc-c14n sobre a árvore do `xmerl` em `src/sidecars/rakun_saml2.erl` (~300 linhas), as três caixas fechadas por um fixture assinado com uma chave versionada. (b) Aposentar o SP: as três caixas saem, `saml2/` mantém 501 com uma linha de `deferred.md`. (c) Deixá-las abertas.
- **Recomendação.** (a) se a 79 tiver equipe neste milestone, senão (b); nunca (c).
- **Bloqueia.** 79 passo 3.

#### 03r-af · Os sete projetos de exemplo não construídos
- **Medido.** `examples/` guarda `rakun`, `rakun-container`, `rakun-ssr` (células de gate); `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit` nunca começaram; o contrato de cada membro é afirmado por seus próprios testes.
- **Opções.** (a) Aposentar os sete (a lista de exemplos da 1.0.10 um registro fechado; os três em disco ganham um `README.md` cada). (b) Construí-los, uma frente cada, depois de toda frente de membro. (c) Construir só o `rest-service`.
- **Recomendação.** (a).
- **Bloqueia.** 73 passo 3.

#### 03r-ak · Validação CycloneDX
- **Medido.** A caixa pede validação contra um schema CycloneDX 1.5 versionado, sem rede; o std não tem validador de JSON schema; `release_test.bp:168` afirma campos por nome (`rakun-cli/test/release/` depois da 128).
- **Opções.** (a) `release_test.bp` percorre o SBOM contra os `required`, `type`, `enum` e `$ref`s locais de `test/release/fixtures/bom-1.5.schema.json` (~120 linhas), como o passo 3 da 81 já lê. (b) Emendar a caixa para a lista campo a campo. (c) Um `json.schema` no std.
- **Recomendação.** (a).
- **Bloqueia.** 81 passo 3.

#### 03r-al · Transações de produtor Kafka contra o broker em processo
- **Medido.** `rakun-messaging/src/reliability/transaction.bp:39` provê `withProducerTransaction(prefix, body)` (envios retidos, liberados no commit, descartados num raise; leitor `read_committed` testado em `transaction_test.bp`). O passo 5 da 15 já está escrito para (a): quatro caixas (caminho do outbox por `withProducerTransaction`, nenhuma linha de outbox; nada visível a `read_committed` depois de um aborto; o caminho no log; uma linha de `deferred.md` para um broker real). Só falta o registro.
- **Opções.** (a) O caminho do outbox da 83 publica por `withProducerTransaction` no broker em processo; execução com broker real uma linha de `deferred.md`. (b) Apagar as caixas de broker do passo 5. (c) Deixar o passo 5 aberto até um Kafka real estar no gate.
- **Recomendação.** (a).
- **Bloqueia.** 15 passo 5 (só o registro; a frente segue (a)).

#### 03r-am · Onde vivem os doubles de broker e scheduler
- **Medido.** `rakun-test` depende só de `rakun`; nenhum `rakun-messaging/test/*.bp` importa `rakun-test` hoje, mas o passo 3 da 19 faz `container_test.bp` rodar pelo double — com o double no `rakun-test` isso é `rakun-test → rakun-messaging` ao lado de `rakun-messaging (tests) → rakun-test`, um ciclo de pacotes a menos que o loader respeite o escopo de teste (não verificado). `rkOnReset(name, reset)` (`rakun/src/runtime.bp:215`).
- **Opções.** (a) Medir: acrescentar a aresta e o import de `container_test.bp`; se `botopink test` recusar o ciclo, os doubles vivem ao lado do módulo que duplicam (`rakun-messaging/src/broker_double.bp` + `rakun_messaging_fixture.erl`, `rakun-scheduling/src/task_double.bp`) e o `rakun-test` os documenta. (b) Tomar a aresta, supondo que a regra pousou. (c) Os doubles no `rakun-test`, alcançando os registros só por hooks do core (`rkOnReset("broker-double", …)`, o termo de nomes de listeners).
- **Recomendação.** (a), com a forma de (c) de qualquer jeito.
- **Bloqueia.** 19 passos 3 e 4.

#### 03r-an · O transporte WebSocket do RSocket depois da decisão 187 (*proposta*, levantada como R92-1)
- **Medido.** R92-1 monta o transporte pelo `#[wsEndpoint]` do `rakun-websocket`; depois da 187 o RSocket vive no `rakun-messaging` → a aresta carregaria a árvore do `rakun-websocket` (security, data) para todo consumidor de messaging; hoje o transporte WebSocket é recusado no boot (`rakun-rsocket/src/rsocket.bp:69`, só TCP).
- **Opções.** (a) Tomar a aresta `rakun-messaging → rakun-websocket`. (b) O core define um ponto de extensão de transporte em que o `rakun-websocket` se pluga (regra da 185), chaveado pela variante do enum de transporte (`rkRegisterTransport(.WebSocket, …)` — a 299 tipa a config, a 281 nenhuma string). (c) Aposentar o transporte WebSocket: as duas caixas da R92-1 e os braços `ws://` / `wss://` da R92-7 apagados, só TCP e TLS, uma linha de `deferred.md`.
- **Recomendação.** (b).
- **Bloqueia.** A primeira e a terceira caixas do passo 2 da 92.

#### 04-a · O tempo de vida, o tipo e a tag vazia da época de tag (*implementado como (a), aguarda confirmação*)
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
- **Medido.** `fieldError` depois de `__jhFormState`, re-renderização no lugar em `ok: false`, `pending` de dois formulários, commit / rollback otimista leem `document` e `FormData`; `botopink test` não tem DOM; `jhonstart-dom-test` (`fake_dom.mjs`, só commonJS) já serve a metade de navegador da renderização. O cabeçalho da frente 67 diz "`67-a` respondida", mas nenhuma decisão a registra — ainda aberta.
- **Opções.** (a) Estender `fake_dom.mjs` com `<form>`, `<input>`, `FormData`, `submit`; afirmar as cinco caixas (3a, 3b, 4, 5 da 1.0.10) em `jhonstart-dom-test/test/forms_dom_test.bp` agora, e de novo no navegador da onze 53. (b) Só no navegador da onze 53. (c) Uma biblioteca DOM real como dependência de dev.
- **Recomendação.** (a).
- **Bloqueia.** 67 passos 1–3 (escritos para (a)); o caminho de escrita da onze 53.

### 06-emilia

### 07-onze

#### 50-b · O que `onze dev` faz numa mudança
- **Medido.** `onze build` compila o servidor para BEAM (`server/beam/`), `onze start` roda `erl -noshell -pa <outDir>/server/beam -eval …` (50-a); `onze-bundler/src/rebuild.bp` calcula os módulos invalidados; o BEAM pode fazer `code:load_file/1`; o registro de UI e a tabela de rotas se preenchem no carregamento do módulo (decisão 140): uma página recarregada se re-registra, um novo arquivo de rota precisa de `onze_routes.bp` regenerado e da tabela reconstruída.
- **Opções.** (a) Reiniciar o nó a cada mudança (`build` + `start` em loop sobre um observador de arquivos — os mesmos bytes de `start`, 1–3 s por edição). (b) Carregar a quente os módulos alterados; regenerar e recarregar `onze_routes` quando a árvore do app mudar. (c) (b), recaindo em (a) quando um arquivo de convenção mudou. Estado de ilha do navegador perdido de qualquer jeito (Fast Refresh um não-objetivo, `07-onze/reference-holes.md` § 29).
- **Recomendação.** (a): um caminho de código, os mesmos bytes que `start` serve; (b) depois, se (a) medir lento demais no blog.
- **Bloqueia.** 50 passo 2; 53 passo 6.

#### 49-g · `isString` — do próprio onze, ou o `Json` do std
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

#### 116-a · O `import {bpp} from "std"` do próprio módulo de prelúdio (decisão 361 × 270) (*proposta*)
- **Respondida (o mantenedor, 2026-10-12; aguardando seu número em `decisions-taken.md`):** **(f), uma sexta opção: o prelude são os itens marcados `#[bpp.htmlPrelude]` onde são declarados, um a um.** Um `pub val` / `pub fn` / `pub type` marcado de um módulo que a raiz do pacote (s23-i) alcança só por `pub mod` — inclusive a própria raiz — está no prelude: um `.bpp` o vê pelo nome simples sem importar (`#[bpp.htmlPrelude] pub fn Card(…)` em `src/components.bp`, `pub mod components;` na raiz, `<Card/>` num `.bpp`). A raiz não reexporta nada para isso. Um item `pub` sem o marcador é API da biblioteca, não prelude. Imports são privados — inclusive o `import {bpp} from "std";` de que cada módulo marcado precisa — então nenhum chega a um `.bpp`. Nenhum nome é sombreado: dois itens marcados de um nome, ou um `.bpp` que declara ou importa um nome que o prelude já dá, é recusado, localizado, nomeando os dois lugares (`` `Card` is already in the prelude (src/components.bp:4) — rename one ``). Recusados, localizados: o marcador num item sem `pub`, num `mod`, num módulo alcançado por um `mod` privado (`` `X` is marked for the prelude but `internal` is a private mod — make it `pub mod` or drop the mark ``), ou num item que reexporta um item de outro pacote (242). `src/prelude.bp` e seu `pub val prelude = bpp.Prelude()` saem. A frente 116 lista o prelude de um pacote — cada item, seu nome e onde é declarado — por `botopink prelude` e no language server (a origem de um nome de `.bpp` no hover). Amenda a 361 e a 270.
- **Medido** (frente 116 passo 1). A 361 põe o marcador do prelúdio no módulo
  de prelúdio — `#[bpp.htmlPrelude] pub val prelude = bpp.Prelude();` — então o módulo deve importar o
  `bpp` do std (o `src/prelude.bp` do jhonstart agora termina em `import {bpp} from "std"; #[bpp.htmlPrelude] pub val
  prelude = bpp.Prelude();`). A 270 diz "os imports daquele módulo são o prelúdio" e recusa, na
  linha, "um item de outro pacote (242)". Lidas juntas, o import do próprio marcador é ao mesmo tempo um item do
  prelúdio (todo arquivo `.bpp` resolveria `bpp` por ele) e uma linha recusada. O passo 1 checa só que
  o módulo contém imports e seu marcador; o escopo do prelúdio e suas recusas são do passo 2.
- **Opções.**
  (a) O import do `bpp` do std (ou de uma folha dele) é do marcador, não do prelúdio: deixado de fora da
  lista de itens entregue ao `compiler-core`, e isento da recusa da 242 — todo outro item `from "std"`
  num prelúdio continua recusado:
  ```bp
  // src/prelude.bp
  import {element.Element};          // a prelude item
  import {bpp} from "std";           // the marker's import — not a prelude item, not refused
  #[bpp.htmlPrelude]
  pub val prelude = bpp.Prelude();
  // Card.bpp: `bpp.Prelude()` in its header is `unbound variable 'bpp'`
  ```
  (b) O import do marcador é um item de prelúdio como qualquer outro: um arquivo `.bpp` resolve `bpp` sem
  importá-lo, e a recusa da 242 isenta o std:
  ```bp
  // Card.bpp header: `val p = bpp.Prelude();` compiles through the prelude
  ```
  (c) A 242 vale para o prelúdio: um módulo de prelúdio não pode importar nada de outro pacote, então o
  marcador é escrito por um caminho que a linguagem não tem hoje (uma anotação qualificada sem
  import, `#[std.bpp.htmlPrelude]`), uma mudança de parser e checker:
  ```bp
  #[std.bpp.htmlPrelude]
  pub val prelude = Prelude();   // `Prelude` unbound: (c) needs a qualified constructor too
  ```
- **Recomendação.** (a): o prelúdio continua os módulos do próprio pacote (242), e o único import de que o
  marcador precisa não alcança nenhum arquivo `.bpp`.
- **Bloqueia.** A caixa de prelúdio do passo 2 da 116 (a lista de itens e suas recusas); nada no passo 1.

#### 116-b · Os papéis são checados num projeto sem arquivo `.bpp`? (*proposta* ★)
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
- **Medido.** O servidor semeia os valores que uma ilha leu em seu payload (136 passo 6); um valor que cruza deve ser codificável — depois da 306, o membro `encode` de um tipo `#[validated]` (`T.encode(v)`, 327; outra biblioteca aceita `T` só com `@typeInfo(T).meta(Validated)`), ou um dos `T`s que a 294 aceita para um cookie (string, número, `bool`, enum, record de um campo); algum estado é só do navegador por natureza (um handle de DOM, uma função).
- **Opções.** (a) O `T` de todo átomo codificável, checado onde o átomo é declarado. (b) Qualquer `T`; o conjunto de leitura de uma ilha checado no build — um átomo não codificável que uma ilha lê deve ser declarado só-cliente (`clientAtom(…)`, ou o `#[clientOnly]` da 278 estendido a declarações, 282). (c) Qualquer `T`, recusado só em tempo de execução.
- **Recomendação.** (b): restritivo onde importa (o que cruza), livre no resto.
- **Bloqueia.** 136 passo 6.

#### atm-d · Quais efeitos de átomo são entregues (*proposta*)
- **Medido.** Os efeitos de átomo do Recoil persistem ou sincronizam um átomo (localStorage, URL, um push do servidor); nenhum existe aqui.
- **Opções.** (a) Nenhum no primeiro corte. (b) Só `persistLocal("cart")`. (c) `persistLocal` e uma sincronização de search-param (`syncSearchParam("tab")`).
- **Recomendação.** (a): pousar o store primeiro; efeitos como um passo próprio depois de uma necessidade medida.
- **Bloqueia.** 136 passo 8.

### 10-specs

#### 141-a · Como uma decisão que aposenta uma grafia impede os specs de derivar (*proposta*)
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
- **Medido.** A 163 proíbe um pacote embutido de exportar um nome que o std ou um framework exporta "até a linha do toolchain fechar"; a 170 (um import que nomeia seu módulo nunca é ambíguo; alias quando os dois são necessários) a fecha.
- **Opções.** (a) Ainda proibido: um novo pacote embutido escolhe um nome que não colide (o módulo `cookie` do `http`, o `id.deriveActionId` do `actions`). (b) Proibição suspensa: nomes naturais, os importadores usam alias.
- **Recomendação.** (a).
- **Bloqueia.** Nada; 102, 103 e 104 já escolheram nomes livres.

### 20-snap

### Propriedade

#### own-a · Quem é dono dos test runners (*proposta*)
- **Medido.** `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (além das linhas de orçamento da 114), `tests/language/run.sh` (além do relatório da 12), `modules/test-shard/**`, `modules/lib-test-runner/**`, os `scripts/**` do meta eram de `25-gate-perf`, 113, 115, 133, todas fechadas (`fronts.md` § Ownership, item aberto). Regra provisória ali (`fronts.md:55-59`) = opção (c): uma frente que edita nomeia a exceção em seu commit; duas frentes abertas não editam o mesmo arquivo. Nenhum passo aberto edita um runner: o passo 12 da 07-residuals "não edita nenhum runner", as linhas de orçamento do passo 5 da 114 já são da 114, o passo 7 da 114 só roda o gate.
- **Opções.** (a) `01-compiler/07-residuals`, que já guarda o passo aberto da 25 (a compilação de dependência por célula). (b) `00-gate/114`, o resíduo do gate. (c) nenhuma: cada frente nomeia uma exceção por commit (a regra provisória de hoje, mantida).
- **Recomendação.** (a): um dono, a frente que herdou o passo aberto da 25.
- **Bloqueia.** Nada hoje; a regra provisória (c) vale até ser respondida.

### Contradições que não bloqueiam nenhum passo 00–03

#### ctr-l · A terceira recusa da decisão 186 contra a decisão 202
- **Regras.** A 186 recusa "um hook `#[serverOnly]` numa página que se declara pré-renderizada (`08-g`)". A 202: "Nenhuma declaração … nenhum `pub val prerender` … nenhum jeito de forçar". Uma página é `pub fn blog() -> View` lendo `use cookie(sessionCookie)` (293, 294): renderizada por requisição, sem erro.
- **Recomendação.** Descartar a terceira recusa da 186: sob a 202 nenhuma página se declara pré-renderizada. O `05-jhonstart/26` passo 8 já lista só as duas recusas (`README.md:58-59,182-183`); só a linha da 186 está pendente.
- **Bloqueia.** Nada nas frentes; o registro.

#### ctr-v · A decisão 189 (org-3) contra as frentes do emilia abrindo antes da 118
- **Regras.** org-3: as exceções da 118 pousam antes de a frente dona abrir. `06-emilia/34` passo 1 e `33` passo 2 abrem agora; as linhas `[class]={…}` do emilia (`attributes.bp:30,32,36`, `emilia.bp:185,202`) e o `[emilia]={…}` de `emilia-card/src/main.bp:5` são só comentários, reescritos por essas frentes.
- **Recomendação.** Registrar que uma exceção só de comentários é tomada pela frente dona; a 118 mantém as linhas de código (seus próprios testes, o teste de ponte do `jhonstart-emilia`, `document-shell`). As frentes já a seguem (118 § Does not touch, 34 passo 1, `fronts.md:49`); só a linha da org-3 está pendente.
- **Bloqueia.** Nada nas frentes; o registro.

#### ctr-w · O braço Elasticsearch da frente 09 contra a decisão 185
- **Regras.** 185: uma capacidade opcional passa por um ponto de extensão do core, "nenhuma aresta de membro para membro". `04-rakun/09` § Open point: o braço Elasticsearch sobre `rakun-client` acrescenta uma aresta `rakun-data → rakun-client` que todo consumidor de data carrega.
- **Recomendação.** O braço alcança HTTP por um ponto de extensão do core (ou `httpc` diretamente, como o relay da 65), não por uma aresta `rakun-client`; respondida com a lista de braços da `03r-ab`.
- **Bloqueia.** 09 passo 3.


#### 119-a · A caixa de grep do passo 1 contra o hook byte-idêntico da checagem 4 do CI
- **Regras.** 119 passo 1 e seu gate: `grep -rn "bpp\|jhonstart\|emilia" repository/css repository/styled` vazio (338). Checagem 4 do CI (meta `AGENTS.md` § CI): `scripts/git-hooks/lib/runner-standalone.sh` byte-idêntico em todo repositório de biblioteca — e sua linha 31 lê `# one-at-a-time gate printed. Front 115 of 1.0.11-beta measured emilia's`, então o grep o encontra em `repository/css` (e encontrará em `repository/styled`). `src/`, `test/`, `AGENTS.md` e o manifesto não guardam nenhum dos três nomes.
- **Opções.** (a) A caixa faz grep no texto do próprio pacote: `grep -rn "bpp\|jhonstart\|emilia" repository/css/{src,test,botopink.json} repository/styled/{src,test,botopink.json}` — vazio hoje para `css`. (b) O comentário do hook compartilhado perde o nome, em todo repositório de biblioteca de uma vez (checagem 4), uma mudança que nenhum dos repositórios da 119 possui.
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
