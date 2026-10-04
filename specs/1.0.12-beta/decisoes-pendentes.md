# Decisões pendentes — 1.0.12-beta (só o que está em aberto, por ordem de importância)

Atualizado em 2026-10-04 (decisões 278–303). Só o que ainda espera resposta sua: o que já foi respondido está em
`specs/1.0.12-beta/decisions-taken.md` (decisões 144–303; próximo número livre: **304**) e saiu daqui.
Respondidas desde 02/10: 225–233 (caches, OTP, CI, `test-web`, std no wasm), 234–236 (injeção do rakun,
`@TypeInfo.all` com lista, decorador de função), 237 (captura do template pelo texto), 238–243
(`@External.Wasm`, `$stringify`, codepoints no wasm, células sem WASI, dependência direta, vírgula final),
244 (default só no fim), 246 (`test-libs` com todas as bibliotecas na chave), 247 (sufixos de literal
minúsculos; a 209 revertida), 248 (um builtin só, `@typeInfo`), 249 (o compilador separado por backend na
chave do cache), 250 (`io.random.bool()` removido), 252 (todo builtin declarado), 253 (`@TypeInfo.all`),
254 (o catálogo responde `unknown`; `is fn() -> T`), 255 (`Tipo<…>.membro` e `comptime <expr>`), 256 (o
registro de beans em comptime no ponto de entrada), 257 (`Schema<T>` na `validation`), 258 (`--lib` múltiplo), 259–263 (`pow` da glibc, `contentHash` por code point, heap do wasm crescendo, `String.fromCodepoint`, `std/math` igual em todo sistema), 264 (estouro de inteiro é erro em todo target), 265 (orçamento do gate frio em 7m30s nesta versão; os 5 min ficam para a próxima), 266 (`comptime` avaliado em compilação em todo lugar, registro içado), 267 (parâmetro variádico `..values: T[]`; `@print` declarado com ele), 268 (tipo builtin `Decorator` no `with:` do `@TypeInfo.all`), 269 (`@getContext(T)` é hook, chamado atrás de `use`), 270 (o prelúdio do `.bpp`: o `src/prelude.bp` do pacote, só imports do próprio pacote, importado só quando usado; o cabeçalho vence), 271 (`ctr-a`: não existe `islandKeyEnv`; a chave da island é sempre `ONZE_KEY`; as chaves da 124 são `trailingSlash`, `redirects`, `markdown`, `islands`), 272 (`08-e2` e `ctr-b`: os modos das props da server island são só `"sealed"`, o padrão, ou `"server"` — nenhum expõe as props), 273 (`ctr-c`: um route handler nunca é exportado no build; `app/rss.xml/route.bp` é servido a cada request — a 222 fica inteira), 274 (`03r-ad` e `ctr-d`: o Pulsar não vira membro — fica em `rakun-messaging/src/pulsar/`; o plano de dados é recusado no boot e adiado), 275 (`bpp-f` e `ctr-e`: o `.bpp` devolve o `R` do `@ExprCustom<R>` que o `html` declara — no jhonstart, sempre `@Component<ElementBase, Element>`, com ou sem `use`/`await`; todo `.bp` que devolve `html """…"""` também passa a declarar esse retorno), 276 (`View`: alias de `@Component<ElementBase, Element>` no `element.bp` do jhonstart — o mesmo tipo com nome curto; o `.bpp` desdobra em `-> View`), 277 (`hooks-a`: o `@Decl` lista todos os nós alcançáveis — cada função com os seus `use` e as suas chamadas —, e cada anotação carrega o seu `Decorator`; o jhonstart decide pré-renderizada/por request e valida `#[client]` comparando com os próprios decorators), 278 (diretivas do Astro viram anotações dentro da tag — `#[clientVisible("200px")]`; `#[clientOnly]` é uma função só, para hook e tag; o `html` age pelo tipo de retorno), 279 → 286 (as duas formas valem, `#[a]` `#[b]` e `#[a, b]`; o formatter mantém como foi escrito), 280 (argumento de decorator tipado e `comptime`, `@Decl<T>`, `Field<T>` e `.campo` com o nome exato), 281 (nenhum identificador de código como string), 282 (o papel de uma função vai no decorator, nunca no nome do export), 283 (segundo modelo: caso a caso, `nat-d1`…`nat-d9`), 284 (JSON: `botopink.json` o mais limpo possível, caso a caso; `"bpp"` obrigatório), 285 (o compilador só conhece o `"bpp"`, o `html` e o prelude; o papel do arquivo é da tabela de rotas do framework; o `bppKinds` sai), 287 (`ctr-aa`: o fallback de uma ilha é argumento da anotação — `#[serverDefer(fallback: …)]`, `#[clientOnly(fallback: …)]` —, fixo em comptime), 288 (`ctr-f`: um `.bpp` é o `pub default fn` do módulo com o nome exato do arquivo, devolvendo `View`; importado `import {components.card};` — a 213 emenda a 198 e a 199), 289 (`ctr-g`, `ctr-t`: a função default pode ser anônima — `pub default fn (…)` — ou marcada depois — `pub default Tree;`; quem importa dá o nome; o `page.bpp` pode importar e escrever `#[page(…)]` sem colidir), 290 (`ctr-x`: sem configuração de segmento — `dynamic` e `fetchCache` saem; `revalidate` e `dynamicParams` são argumentos do `#[page]`), 291 (`ctr-y`: `use request()` para ler e `use response()` para escrever — `res.status(404)`, `res.header(…)` —; header fixo de página S em `#[page(headers: …)]`; sem `isPrerendered()`), 292 (`ctr-z`: `<a #[reload]>`, `<a #[history(.Replace)]>`; os eventos de navegação são hooks — `use onBeforeSwap(…)` —; o `<Script>` tem enum próprio, `strategy={.LazyOnload}`), 293 (`nat-c1`, `nat-c3`, `bpp-g`: a página lê a rota por hook — `use params<BlogParams>()`, `use pageData<Post>()` —, sem parâmetro; o `#[page]` confere os campos contra a pasta), 294 (`nat-c2`: o cookie é declarado uma vez, com tipo — `Cookie<SessionId>("session", httpOnly: true, …)` —, lido com `use cookie(decl)` → `?T` e gravado com `use setCookie`), 295 (`nat-c4`: estado do request como átomos, no estilo do Recoil — `pub val currentUser = Local<User>()`, `use local(currentUser)`, `use setLocal(currentUser)`; middleware, handler e action viram `@Component<RequestBase, Response>`), 296 (`cardume`: lib própria de estado compartilhado, o Recoil do botopink — átomo, selector, família, transação; pontes `rakun-cardume` e `jhonstart-cardume`), 297 (um parâmetro `comptime` aceita valor ou tipo — `Atom<T> | type T` —: `use atomState(currentUser)`, `use atomState<?User>(currentUser)` e `use atomState(User)`, o átomo implícito do tipo), 298 (`nat-c5`: o meta de decorator é um valor tipado indexado pelo tipo — `decl.setMeta(Entity(…))`, lido `@typeInfo(City).meta(Entity)` → `?Entity`; `addMeta` / `metaAll` para o que se repete), 299 (`nat-c6`: a configuração do rakun é um record tipado por prefixo — `#[config("rakun.data")] type DataConfig(…)` —, nome exato do campo, erro no boot com a linha; a 03r-b é revertida), 300 (`nat-c7`: o tema do emilia continua no formato do CSS, mas tipado — `entry(.Breakpoint, "md", Rem(40.0))`, `clear(.Breakpoint, "lg")` — e declarado uma vez com `#[theme] pub val appTheme = comptime extendTheme(…)`; usar um breakpoint apagado é erro de compilação). Com isso a `nat-c` inteira foi respondida (293, 294, 295, 298, 299, 300). 301 (o emilia entra no markup como anotação de tag — `<h1 #[styled(.Text.Bold, …)]>` —, tokens em comptime, classe e regra calculadas no build quando o hash for do std), 302 (anotação de tag e decorator de declaração são a mesma coisa: `fn nome(comptime decl: @Decl, …)`, sem retorno, agindo pelo `decl` — na tag, gravando meta tipado que o `html` lê pelo tipo). 303 (`nat-d1`: a action devolve `@Result<T, ActionError>` dos dois lados — `return v` / `throw e`, lido com `case` — `Ok(…)` / `Error(…)` —; o `ActionOutcome` sai; `Input(fields)` é um caso do `ActionError`; o `{data, error}` fica só no JSON do protocolo). A 245 e a 251 foram registradas cedo demais e retiradas.

> **Numeração.** O prelúdio do `.bpp` tinha sido registrado como 266 no commit `84aa028`, sem saber
> que 266–269 já existiam no seu registro local. Na 1.0.12 ele é a **270**; as 266–269 estão em
> `decisions-taken.md` com o texto completo dos commits `4fb3c5e`, `ec58d33`, `805b2be`, `c4976a6`.

**Ordem:** da decisão que mais destrava para a que menos destrava.
- **Prioridade máxima** — a forma botopink (`nat-d`…`nat-g`; as regras já são as decisões 281–284; a `nat-c` foi toda respondida) (as contradições da varredura já respondidas): o que foi copiado de fora quando a linguagem já tinha o recurso.
- **Parte 0** — `00-gate` e `01-compiler`, por prioridade (o que segura thread rodando primeiro).
- **Parte 1** — contradições entre decisões, achadas na consolidação: cada uma segura um passo.
- **Parte 2** — destravam muitas frentes.
- **Parte 3** — destravam uma frente ou um passo.
- **Parte 4** — não bloqueiam nada hoje.
- **Parte 5** — escolhas que as threads fizeram (★), para confirmar.
- **Parte 6** — escolhas já implementadas na 1.0.10, só para confirmar.

**Estado.** A 1.0.11 foi fechada e consolidada na 1.0.12 (mesmos objetivos, só estado atual; histórico
em `specs/1.0.11-beta/`, com as auditorias em `closure-audit/`). O `00-gate` tem 13 de 14 frentes
fechadas; a 114 segura o resto do gate (CI verde do botopink-lang na `feat`, `budget_cold` 300 contra
os 450 da decisão 265, vscode-extension em OTP 24, nenhum gate frio gravado na ponta atual). No
`01-compiler`, a 129 está pronta e 01, 02, 03, 04, 05, 12, 14, 17, 26, 130 e 134 estão parciais na
`feat`; entraram as decisões 263 e 264 (um `math` em todo sistema; estouro de inteiro aborta — no wasm ainda faltam `u32` e os tipos estreitos), e o 01-checker (decisão 255 e sufixos de literal) e o 130-rakun-di foram mergeados no botopink-lang e no rakun sem gate frio. Das bibliotecas: 104 e 106 (metade do pacote) e 125 passos 0–2 entraram; **102 e 103 só existem
em branches não publicados** e seguram o 128, que abre a trilha do rakun. A trilha `20-snap` (frente
135) reúne os mapas de snapshot, reavaliados caso a caso. Status completo, em cinco linhas de trabalho:
`specs/1.0.12-beta/status.md`.

**O que eu passei a decidir sozinha.** Você autorizou que perguntas de método de biblioteca (nome,
ordem, assinatura, o que a função devolve) eu decida pelos seus princípios, sem contradizer o que
você já disse. Essas não entram mais aqui: ficam em `decisions-taken.md` marcadas com † (hoje,
174–183 e 189), para você reverter se quiser.

★ = opção já implementada. Para confirmar, basta marcar; para reverter, marque a outra.
⏳ = tem thread parada esperando esta resposta.

**Toda pergunta segue o mesmo molde:** **Contexto** (o que existe hoje e por que a pergunta surgiu) →
**Hoje** (um exemplo do comportamento atual) → as **opções** para marcar, cada uma com o seu exemplo →
**Recomendação** → **Bloqueia** (o que fica parado até a resposta). As contradições e as escolhas já
implementadas (★) também viram escolha múltipla com exemplo. A recomendação é a da spec
que levantou a pergunta, e a regra é sempre a mesma: a opção mais restritiva, sem configuração que a
contorne (decisão 67). Onde a spec não registrava nenhuma, a linha diz "desta revisão" ou "da thread".
Os exemplos das opções que ainda não existem são ilustrativos (a forma final é da frente que
implementar). O texto completo de cada pergunta (Measured / Options / Recommendation / Blocks) está em
`specs/1.0.12-beta/decisions-pending.md` (em inglês, a fonte) e no `README.md` da trilha que a levantou.
Ids marcados *(proposta)* foram levantados na consolidação e ainda não tinham id.

Os ids das decisões não mudaram com a renumeração das trilhas: `07-*` são da `03-bundled-libs`,
`03r-*` da `04-rakun`, `05emilia-*` da `06-emilia`.

---

## Prioridade máxima — a forma botopink (`nat-*`) e o que já contradiz decisões

Levantado em 04/10, numa varredura da spec depois da decisão 278. Assim como as diretivas do Astro, que
copiamos quando o botopink **já tinha** a anotação, há cerca de 40 lugares onde um conceito veio do
Astro, Next.js, React, Spring, zod, TypeScript, LINQ ou Tailwind **na forma de fora**, mesmo existindo
o recurso equivalente na linguagem. Eles caem em sete padrões.

**As quatro regras já estão decididas:** 281 (nenhum identificador de código como string), 282 (o papel
vai no decorator), 283 (segundo modelo: caso a caso, `nat-d1`…`nat-d9`) e 284 (JSON: caso a caso,
`nat-f1`…`nat-f4`; a `nat-f1` virou a 285). **Ordem do que falta** (as contradições achadas na varredura já foram respondidas: 287, 290, 291, 292): `nat-d2`…`nat-d9` (a `nat-d1` virou a 303), `nat-e`, `nat-f2`…`nat-f4` e `nat-g`. As do cardume (frente 136) estão na Parte 3: `atm-a`, `atm-c`, `atm-d`.

### nat-d · Um segundo modelo do que a linguagem já tem — caso a caso (decisão 283)

Você decidiu (283) que **não há regra geral**: cada caso é visto separadamente, com calma. Cada um tem
as mesmas três saídas: **(a)** usar o recurso da linguagem; **(b)** os dois, o de fora como camada fina
por cima do nativo; **(c)** como está. Até a resposta, a frente escreve o que tem hoje.

### nat-d2 · Erro lançado nas stores, com uma API `try*` gêmea (rakun 09, 93)

**Contexto.** No Java, o driver lança exceção. O rakun copiou: cada método das stores lança, e existe uma
segunda versão `try*` que devolve `@Result`. São duas APIs para cada operação. Na SOAP, há `throw SoapFault`
dentro de uma função `-> @Result`.

**Hoje:**
```bp
fn get(k: string) -> ?string { … raiseProblem(…) }        // lança
fn tryGet(k: string) -> @Result<?string, StoreError>       // a versão que não lança
```

- [ ] **(a)** Uma API só, com `@Result`.
  ```bp
  fn get(k: string) -> @Result<?string, StoreError>
  ```
- [ ] **(b)** A que lança fica como padrão, e a `try*` continua ao lado.
- [ ] **(c)** Como está.

**Recomendação: (a).**
**Bloqueia:** rakun 09 (todas as stores), 93; lg2-h.

### nat-d3 · Objetos `Schema<T>` ao lado do tipo (125; 257)

**Contexto.** No zod, o schema é um valor montado com funções, porque o TypeScript não tem tipos em
runtime. No botopink, o record tipado já descreve o formato, e o `#[schema]` pode gerar o `parse`. Hoje a
125 tem os dois: o formato fica escrito duas vezes e pode divergir. A 257 decidiu que o `Schema<T>` mora
na `validation`; aqui a pergunta é sobre a **forma**.

**Hoje:**
```bp
pub type Signup(email: string, age: i32)
val signupSchema = schemas.object([#("email", schemas.text().email()), #("age", schemas.int())]);
```

- [ ] **(a)** O tipo é o schema; o `Schema<T>` como valor sai.
  ```bp
  #[schema] pub type Signup(#[email] email: string, age: i32)
  val r = Signup.parse(json);
  ```
- [ ] **(b)** O tipo primeiro; o `Schema<T>` como valor só para o que não é um tipo declarado (uma checagem
  avulsa), e derivável de um `#[schema]` (`Signup.schema`).
  ```bp
  #[schema] pub type Signup(#[email] email: string, age: i32)
  val slug = schemas.text().min(2);           // avulso, sem tipo próprio
  ```
- [ ] **(c)** Como está.

**Recomendação: (b)** — o tipo é a forma principal, e o valor fica para o que não tem tipo. Lê junto com a
07-j e a `ctr-u`.
**Bloqueia:** 125 passos 3–10; 07-j; `ctr-u`.

### nat-d4 · Uma função por aridade: `union2…5`, `tuple2…5` (125)

**Contexto.** O zod em TypeScript precisa de uma função por quantidade de argumentos. O botopink tem tipo
união (`A | B`), tupla (`#(A, B)`) e variádico (267).

**Hoje:**
```bp
schemas.union2(a, b)   schemas.union3(a, b, c)   …   schemas.tuple5(…)
```

- [ ] **(a)** As formas de tipo e, se a forma valor ficar, uma função variádica só.
  ```bp
  type Pet = Cat | Dog | Fish;
  schemas.union(..arms)
  ```
- [ ] **(b)** As famílias ficam.
- [ ] **(c)** Como está.

**Recomendação: (a).**
**Bloqueia:** 125 passo 8.

### nat-d5 · `Partial` / `Pick` / `Omit` do TypeScript ao lado de type alias (125, 134 passo 2)

**Contexto.** Para derivar um tipo de outro, a 125 usa decorators (`#[partial(Recipe)]`) e a 134 tem
builtins (`partial`, `pick`, `omit`, `mergeRecords`). O botopink já tem type alias (110).

**Hoje:**
```bp
#[partial(Recipe)] pub type RecipePatch(…)     // repete os campos, e o decorator confere
```

- [ ] **(a)** Um alias sobre o builtin: um mecanismo só para tipo derivado.
  ```bp
  pub type RecipePatch = partial(Recipe);
  ```
- [ ] **(b)** O decorator num tipo escrito à mão, conferido contra o original.
- [ ] **(c)** Como está.

**Recomendação: (a).**
**Bloqueia:** 125 passo 9; 134 passo 2.

### nat-d6 · `throw "nav:not-found"` ao lado do `noreturn` (53)

**Contexto.** O Next lança um erro especial para `notFound()` e `redirect()`, e o reconhece por um prefixo
de texto. O botopink tem `noreturn` (uma chamada que não volta) e o `routing` já tem o tipo `NavOutcome`.

**Hoje:**
```bp
throw "nav:not-found";
if (isSignal(e)) …                    // compara o começo da string
val _gone = redirect("/login");      // finge devolver string
```

- [ ] **(a)** `noreturn` e o tipo.
  ```bp
  fn notFound() -> noreturn { … }      // a fronteira casa pelo tipo NavOutcome
  redirect("/login");                  // termina o caminho; nada depois executa
  ```
- [ ] **(b)** O sinal em string fica, dentro de um embrulho tipado.
- [ ] **(c)** Como está.

**Recomendação: (a).** Junto com a lg2-l e a lg2-h.
**Bloqueia:** `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a.

### nat-d7 · Anotações de ciclo de vida ao lado de interface (rakun 04)

**Contexto.** O Spring marca os métodos de início e fim com `@PostConstruct` e `@PreDestroy`. O botopink
tem interface com `implement`, que obriga a implementar os dois.

**Hoje:**
```bp
type Pool(…) {
    #[postConstruct] fn init(self) { … }
    #[preDestroy] fn close(self) { … }       // se esquecer, nada avisa
}
```

- [ ] **(a)** Interface.
  ```bp
  type Pool(…) implement Lifecycle {
      fn start(self) { … }
      fn stop(self) { … }
  }
  ```
- [ ] **(b)** Os dois.
- [ ] **(c)** Como está.

**Recomendação: (a).**
**Bloqueia:** rakun 04.

### nat-d8 · Hook chamado `use…` debaixo de `use` (53)

**Contexto.** O React marca hook pelo nome `useX`, porque não tem palavra-chave. O botopink tem `use`
(128). O exemplo da 53 escreve os dois, e a jhonstart-forms já chama o hook de `actionState`.

**Hoje:**
```bp
val s = use useActionState(createPost, initial);
```

- [ ] **(a)** Só `use`; um hook com nome começando por `use` é recusado.
  ```bp
  val s = use actionState(createPost, initial);
  ```
- [ ] **(b)** Os dois nomes valem.
- [ ] **(c)** Como está.

**Recomendação: (a).**
**Bloqueia:** os exemplos da `07-onze/53`.

### nat-d9 · Nomes do LINQ no erika ao lado dos do std (98)

**Contexto.** O erika imita o LINQ do C#: `where`, `select`, `selectMany`, `orderByDescending`, `toList`.
O std já tem `filter`, `map` e `unique` (217) para as mesmas operações. Por outro lado, a identidade do
erika é justamente ser um LINQ.

**Hoje:**
```bp
query.where({ c -> c.active }).select({ c -> c.name }).toList()
```

- [ ] **(a)** Os nomes do std; o erika só acrescenta o que o std não tem (laziness, `groupBy`).
  ```bp
  query.filter({ c -> c.active }).map({ c -> c.name })
  ```
- [ ] **(b)** Os nomes do LINQ: é o propósito do erika.
- [ ] **(c)** Como está.

**Recomendação:** nenhuma desta revisão — depende do que você quer que o erika seja; a (b) é uma leitura
justa.
**Bloqueia:** 98 (erika).

### nat-e · O zoológico de anotações do Spring

**Contexto.** O botopink tem um decorator qualquer mais `@TypeInfo.all(with: …)`; o rakun copiou as
marcas do Spring, várias com o mesmo sentido:
- `#[service]`, `#[repository]`, `#[restController]`, `#[configuration]` + `#[bean]`, `#[managed]`,
  `#[provides]`, às vezes empilhados (rakun 04, 09, 13, 19);
- query derivada do nome do método: `findByNameAndStateAllIgnoringCase` vira SQL (08; R78-1);
- `#[amqpListener]`, `#[kafkaListener]`, `#[redisListener]` com destino em string (15, 91);
- `#[httpExchange]` ligado via `#[configuration]` (13);
- `MockMvc`, `@MockBean`, `UserDetailsService` com os nomes do Spring (19, 79).

**Hoje:**
```bp
#[repository] #[managed] type CityRepo(…)
fn findByNameAndStateAllIgnoringCase(name: string, state: string) -> City[]
#[service] #[listener] #[kafkaListener("orders")] fn onOrder(…)
```

- [ ] **(a)** Um decorator por papel que acrescenta comportamento; query como expressão de comptime;
  transporte vindo da config tipada; nomes do próprio rakun.
  ```bp
  #[component(lazy: true)] type CityRepo(…)
  #[query] fn byState(s: string) -> City[] = City.where(.state == s);
  #[listen(orders)] fn onOrder(o: OrderPlaced) { … }      // orders: Destination
  ```
- [ ] **(b)** Os nomes do Spring ficam como apelidos de (a).
- [ ] **(c)** Como está.

**Recomendação: (a).** Absorve a 130-c.
**Bloqueia:** 130 passo 5; rakun 04, 08, 13, 15, 19, 79, 91, 93; 130-b; 130-c.

### nat-f · Configuração em JSON — caso a caso (decisão 284)

Você decidiu (284) que o `botopink.json` fica **o mais limpo possível**, mas configuração pode ficar nele
quando fizer sentido, decidindo **caso a caso**. O `"bpp": "jhonstart"` continua obrigatório: o app pode
depender de dois pacotes que desdobram `.bpp`, e precisa dizer qual. Cada caso abaixo é uma pergunta.

### nat-f2 · As opções do `onze.json`: `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h)

**Contexto.** Essas chaves repetem opções que o código do onze já tem como tipo (`url_rules`,
`MarkdownOptions`, `app(allowedRedirects:)`). Hoje, um valor errado só aparece quando o servidor sobe.

**Hoje:**
```json
{ "trailingSlash": "nevr" }          // erro de digitação: só aparece no boot
```

- [ ] **(a)** Ficam no `onze.json`, e o build lê para o record tipado: chave ou valor errado é erro **na linha
  do arquivo**, no build.
  ```
  onze.json:1:20 error: "nevr" não é um trailingSlash — always, never, ignore
  ```
- [ ] **(b)** Um record tipado no código do app, sem JSON.
  ```bp
  pub val config = OnzeConfig(trailingSlash: .Never, redirects: [Redirect(from: "/old", to: "/new")]);
  ```
- [ ] **(c)** Como está.

**Recomendação: (a)** — é configuração, pode ficar no JSON (284), e o build confere como conferiria o código.
**Bloqueia:** 124; 08-h; `07-onze/49` e `50`.

### nat-f3 · `files` e `workspaces` no `botopink.json` (98)

**Contexto.** `files` lista o que o pacote publica (como no npm); `workspaces` lista os membros de um
monorepo.

**Hoje:**
```json
{ "files": ["src/client.bp", "src/server.bp"], "workspaces": ["modules/*"] }
```

- [ ] **(a)** Os dois ficam: é empacotamento, não código.
- [ ] **(b)** `files` sai: publica-se o que é `pub`, e um módulo interno se marca no código (`#![internal]`,
  lg2-m); `workspaces` fica.
- [ ] **(c)** Os dois são derivados.

**Recomendação: (a)** — o que vai no pacote é um fato de empacotamento.
**Bloqueia:** 98.

### nat-f4 · O prefixo `ONZE_PUBLIC_` nas variáveis de ambiente (53, `contracts.md`)

**Contexto.** Uma variável só chega ao código do browser se o nome começar com `ONZE_PUBLIC_` (cópia do
`NEXT_PUBLIC_`). É um fato de etapa (186) carregado por uma convenção de nome: se alguém esquecer o
prefixo, nada avisa, e o valor simplesmente não chega.

**Hoje:**
```bp
val api = env("ONZE_PUBLIC_API_URL");
```

- [ ] **(a)** Fica como está.
- [ ] **(b)** A declaração diz que é pública, e o uso num `#[client]` é conferido em comptime (186).
  ```bp
  #[clientVisible] val apiUrl = env("API_URL");
  ```
- [ ] **(c)** Uma lista de variáveis públicas no `onze.json`.
  ```json
  { "publicEnv": ["API_URL"] }
  ```

**Recomendação: (b).**
**Bloqueia:** `07-onze/50` e `53`; `contracts.md`.

### nat-g · Sintaxe estrangeira dentro de anotação

**Contexto.** O botopink rotula argumento com `nome: valor`. Duas anotações usam outra sintaxe:
`#[@BeamMemory.Ets(keyed = true)]` e `inline = true` (o `key = value` do Rust; frente 17);
`#[@External.Erlang("fn:tanBody")]`, `"op:…"` e `"wasi:…"` referenciam uma função por string com
prefixo (238, 263).

**Hoje:**
```bp
#[@BeamMemory.Ets(keyed = true)] var cache: Dict<string, i32>
#[@External.Erlang("fn:tanBody")] fn tan(x: f64) -> f64
```

- [ ] **(a)** Rótulos do botopink e destino tipado.
  ```bp
  #[@BeamMemory.Ets(keyed: true)] var cache: Dict<string, i32>
  #[@External.Erlang(fn: "tanBody")] fn tan(x: f64) -> f64
  ```
- [ ] **(b)** Como está.

**Recomendação: (a).**
**Bloqueia:** 17 (com a 17-b e a 17-c); as células de host dos backends.

---

## Parte 0 — `00-gate` e `01-compiler`, por prioridade

Ordem, do que mais destrava para o que menos:

1. **130-b**, **130-c** — o registro de beans do rakun (qualificador; `#[bean]` de configuração) · seguram o passo 5 da 130, que está rodando ⏳ (Parte 3)
2. **own-a** — quem é dono dos scripts de teste · segura 07-residuals passo 12 e 114 passos 5 e 7 (Parte 2)
3. **134-d** — `@is(…)` escrito à mão · trava a última linha do inventário da 134 (Parte 3)
4. **17-b** — incremento por linha no `keyed` · trava a quarta caixa do passo 1 da 17 (Parte 3)
5. **ctr-i**, **ctr-j** — unidade de string no erlang; faixa do `i64` · seguram células de 02/03/04/05 (Parte 1)
6. **ctr-h**, **ctr-n**, **ctr-o**, **ctr-s** — só registro: decisões antigas que outras já mudaram (Parte 1)
7. **imp-a** — dois tipos com o mesmo nome importados com alias (Parte 3)
8. **17-c** — não trava nada hoje (Parte 3)

---


## Parte 1 — Contradições entre decisões

Pares de regras que não valem juntas, ou uma decisão posterior que mudou outra sem dizer. O texto das
decisões ficou como foi gravado; a escolha é sua. Marque a recomendação ou escreva a sua.

### ctr-h · Decisão 149 × decisões 210 e 211

**Contexto.** A 149 (mais antiga) dizia que `==` em array compara referência e em record é recusado; um
record que quisesse igualdade implementaria `behavior Eq`. A 210, depois, decidiu o contrário: `==` é
estrutural em todo target (records, tuplas, listas e variantes comparam por valor, recursivamente), e a
211 acrescentou que um tipo não define a própria igualdade (`==` nunca chama código do usuário). A 210 não
citou a 149, então o registro ainda tem as duas. O código na `feat` já segue a 210. Só falta o registro.

**Hoje:**
```bp
// tests/language/run/record_structural_equality.bp — passa na feat, nos quatro targets
type Person(name: string, age: i32)
@print(Person(name: "Ana", age: 30) == Person(name: "Ana", age: 30));   // true
@print([1, 2] == [1, 2]);                                               // true (a 149 dizia false)
```

- [ ] **(a)** Registrar a 149 como substituída pela 210, e a cláusula `behavior Eq` pela 211 — nada muda
  no código.
  ```bp
  type Loose(n: i32) {
      pub fn equals(self: Self, other: Self) -> bool { return true; }   // sem papel especial (211)
  }
  @print(Loose(n: 1) == Loose(n: 2));     // false: `==` compara campo a campo
  ```
- [ ] **(b)** Voltar à 149: reverte a 210/211 e o código da `feat`.
  ```bp
  @print([1, 2] == [1, 2]);                                // false: referência
  Person(name: "Ana", age: 30) == Person(…)                // error: `==` on a record; implement behavior Eq
  ```

**Recomendação: (a).** A 210/211 é a decisão mais recente, já está construída e testada nos quatro
targets. **Bloqueia:** nada; só o registro.

### ctr-i · Codepoints (169, 240) × `string:length/1` (197)

**Contexto.** A 169 e a 240 dizem que o índice de string (`length`, `at`, `slice`, `indexOf`) conta
*codepoints* no erlang, no beam e no wasm, para que um índice devolvido por `indexOf` possa voltar ao
`at`. A 197 (1) diz que o erlang responde `string:length/1` do texto antes do achado — e é isso que o
`libs/std/src/primitives.bp` usa (`string:length/1`, `string:slice/3`). Só que essas funções do OTP
contam *grapheme clusters* (o que o leitor vê como um caractere): uma letra mais um acento combinante é
1. Com `"é"` pré-composto (U+00E9) os targets concordam; a diferença aparece com marca combinante.

**Hoje:**
```bp
val s = "e\u{301}";        // "é" escrito como `e` + acento agudo combinante (U+0301)
@print(s.length);          // erlang/beam: 1 (grapheme) · wasm: 2 (codepoints) · commonJS: 2 (UTF-16)
```

- [ ] **(a)** Codepoints: os templates do erlang passam a contar codepoints; uma célula com marca
  combinante fixa os quatro targets.
  ```bp
  @print("e\u{301}".length);     // 2 em todo target — um .out só
  @print("e\u{301}".at(1));      // "\u{301}" em todo target
  ```
- [ ] **(b)** Grapheme clusters: a 169 e a 240 são reescritas; o wasm precisa de um segmentador Unicode
  (tabelas no binário) e o commonJS de `Intl.Segmenter`.
  ```bp
  @print("e\u{301}".length);     // 1 em todo target
  @print("👍🏽".length);           // 1 (emoji + modificador de tom)
  ```

**Recomendação: (a)** — é o que a 169 e a 240 dizem, o que a 260 usa no `contentHash` (code points), e
não exige tabela Unicode em target nenhum. **Bloqueia:** a célula do passo 6 da 02-erlang; o lowering de
string do 05-wasm.

### ctr-j · Decisão 264 × decisão 176 e "o mesmo valor em todo target"

**Contexto.** A 264 tornou estouro de inteiro um erro de programa em todo target (a conta aborta em vez de
dar a volta). Mas ela diz que no commonJS a faixa do `i64` é ±(2^53−1) — o que um número JS (double)
guarda exato —, enquanto no erlang, beam e wasm o `i64` vai até ±2^63. A mesma conta aborta num target e
responde nos outros, contra o princípio da delegação ("o mesmo valor em todo target") e contra a leitura
da 176 (`parseInt` além de ±(2^53−1) é `Error` em todo target). E a 264 diz que "a 247 já recusa um
literal `l` além da faixa" — a 247 só trata de sufixos; quem recusa é o checker
(`refuseBeyondJsSafeInteger`, só no commonJS), citando a 247.

**Hoje:**
```bp
val x: i64 = 9007199254740991l;   // 2^53 − 1
@print(x + 1l);                   // commonJS: aborta "integer overflow: + on i64 at …"
                                  // erlang/beam/wasm: 9007199254740992
val y = 9007199254740993l;        // commonJS: recusado no literal ("past 2^53") · outros: compila
```

- [ ] **(a)** `i64` (e `u64`, `isize`, `usize`) é ±(2^53−1) em todo target (a leitura da 176): a conta
  aborta igual nos quatro, e o literal além da faixa é recusado em todo target.
  ```bp
  @print(x + 1l);                   // aborta em todo target: integer overflow: + on i64
  val y = 9007199254740993l;        // error em todo target: the `i64` literal is past 2^53
  ```
- [ ] **(b)** O commonJS baixa `i64` para `BigInt`: faixa completa ±(2^63−1) em todo target, ao custo de
  aritmética mais lenta e conversão explícita na fronteira com `Number`/JSON.
  ```bp
  @print(x + 1l);                   // 9007199254740992 em todo target
  // commonJS gerado: (x + 1n)   — e checagem contra ±(2n**63n − 1n)
  ```

**Recomendação: (a)**, a mais restritiva; nos dois casos a citação da 247 na 264 é corrigida (a regra do
literal passa a ser da 264). **Bloqueia:** as checagens de faixa de 04-js, 02-erlang, 03-beam; a regra do
literal `l` no checker.

### ctr-k · Decisão 187 × decisão 195

**Contexto.** A 187 (consolidação do rakun) fundiu o `rakun-logging` dentro do core: o core chama o
próprio logger e não existe plugin de relatório de falha. A 195, posterior, criou o pacote bundled `log`
(níveis, `LogRecord`, renderizadores, `errorDigest`, sink injetado) e diz que "o rakun-logging mantém as
células erlang e se instala como o sink" — falando de um membro que a 187 já apagou. A pergunta é só
como ler a 195.

**Hoje:**
```text
187: rakun-logging → dentro do core `rakun`     (25 membros → 16)
195: "o rakun-logging … se instala como o sink do `log`"     ← membro que não existe mais
```

- [ ] **(a)** Ler a 195 como "o logging do core (depois do 128) instala o logger erlang como sink do
  `log` no boot", e registrar assim.
  ```bp
  // core `rakun`, no boot (ilustrativo)
  import {sink.setSink, sink.LogSink} from "log";
  setSink(rakunLoggerSink());          // a partir daqui, todo registro do `log` vira linha do logger do rakun
  ```
- [ ] **(b)** Ler a 195 ao pé da letra: o `rakun-logging` volta a ser membro separado e instala o sink —
  a 187 cede nesse ponto (17 membros).
  ```text
  modules/rakun-logging/   → instala o sink no boot; quem não depende dele fica com o sink padrão
  ```

**Recomendação: (a).** Mantém a consolidação da 187 e o comportamento que a 195 queria (um sink só,
instalado no boot). **Bloqueia:** 04-rakun/17 · 128 · 106.

### ctr-l · A terceira recusa da 186 × decisão 202

**Contexto.** A 186 define em que estágio uma página renderiza (build, servidor, navegador) e os
marcadores de hook `#[serverOnly]`/`#[clientOnly]`, com três recusas em compilação. A terceira — um hook
`#[serverOnly]` numa página "que se declara pré-renderizada" — vinha da época da pergunta `08-g`. Depois a
202 respondeu a `08-g`: nenhuma página declara estágio; não existe `pub val prerender`; uma página que
alcança um hook de servidor simplesmente passa a ser renderizada por request. A terceira recusa não tem
mais como acontecer.

**Hoje:**
```bp
#[page("blog")]
pub fn blog(route: PageContext) -> @Component<ElementBase, Element> {
    val c = use cookies();      // #[serverOnly] → a página é renderizada por request (202), sem erro
    …
}
pub val prerender = true;       // não existe (202): nada para a terceira recusa comparar
```

- [ ] **(a)** Apagar a terceira recusa da 186; ficam as duas (`#[serverOnly]` dentro de `#[client]`;
  `#[clientOnly]` fora de um).
  ```text
  26 passo 8, recusas: 1) #[serverOnly] dentro de #[client]   2) #[clientOnly] fora de #[client]
  ```
- [ ] **(b)** Manter a recusa reintroduzindo uma declaração de pré-renderização (reverte parte da 202).
  ```bp
  pub val prerender = true;
  val c = use cookies();          // error: #[serverOnly] hook in a page that declares itself prerendered
  ```

**Recomendação: (a).** Sob a 202 nenhuma página se declara pré-renderizada; a recusa é letra morta, e a
202 é a mais restritiva (não há como forçar estágio). **Bloqueia:** a lista de recusas do passo 8 da 26
(`05-jhonstart/26`).

### ctr-m · O argumento da `lg2-s` × decisão 216

**Contexto.** A `lg2-s` (Parte 4) pergunta se um `@Decl` de módulo ganha um campo `imports` (reflexão do
grafo de módulos em comptime). Hoje `decl.imports` dá `badkey`, e o `importsOf` do onze-bundler lê os
imports varrendo o texto, falhando alto quando não entende. A recomendação, (1) "não", se apoiava em
"em linha com a `lg2-k` e a `lg2-m`" — mas a `lg2-k` foi respondida ao contrário: a 216 deu reflexão do
projeto em comptime (`@TypeInfo.all`). O argumento caiu; a recomendação precisa de outro, ou muda.

**Hoje:**
```bp
// onze/modules/onze-bundler/src/scan.bp
pub fn importsOf(file: string, source: string) -> @Result<Array<ImportRef>, string>   // varredura textual

// num decorador de módulo
decl.imports        // badkey
```

- [ ] **(a)** Reargumentar a `lg2-s` sozinha e manter (1): os imports de um módulo continuam uma
  varredura textual que falha alto — o bundler lê arquivos que nem sempre compilam juntos.
  ```bp
  val refs = try importsOf("app/page.bp", source);   // como hoje; erro alto em import que não entende
  ```
- [ ] **(b)** Responder como a 216 fez: um campo `imports` no `@Decl` de módulo.
  ```bp
  for (decl.imports) { i -> @print(i.path); }       // "components.card", "log", …
  ```

**Recomendação: (a)** — a recomendação da `lg2-s` fica (1), com o argumento próprio; a 216 abriu reflexão
para registro, não para o grafo de imports. **Bloqueia:** a `lg2-s`.

### ctr-n · O exemplo da 170 × decisão 206

**Contexto.** A 170 diz que dois imports com alias do mesmo nome, de fontes diferentes, são legais num
módulo — e dá o exemplo com `from "m1"`, sendo `m1` um módulo do próprio pacote. A 206 (já implementada,
frente 129) decidiu que `from` nomeia só pacote; um módulo do próprio pacote é importado pelo caminho
entre chaves, e `from "<módulo>"` é `error[module-import-with-from]`. O exemplo da 170 não compila mais. A
metade "tipos" da 170 é a `imp-a` (Parte 3).

**Hoje:**
```bp
import {x as a} from "m1";     // error[module-import-with-from]: m1 é módulo deste pacote
import {x as b} from "m2";
```

- [ ] **(a)** Reescrever o exemplo da 170 na forma da 206 e responder a `imp-a`.
  ```bp
  import {m1.x as a};
  import {m2.x as b};          // legal: cada import nomeia a sua fonte
  ```
- [ ] **(b)** A 206 cede para a 170: `from` volta a aceitar um módulo do próprio pacote quando o import
  tem alias.
  ```bp
  import {x as a} from "m1";   // aceito de novo, só com alias
  ```

**Recomendação: (a).** A 206 já está construída e é a regra única de import; só o exemplo antigo ficou
para trás. **Bloqueia:** `imp-a`.

### ctr-o · Decisão 146 × confirmação `lem-c`

**Contexto.** A 146 diz que uma função cujo corpo alcança uma função host (com `#[@External.<Target>]`)
sem binding para o target em build é recusada na declaração, chamada ou não. A `lem-c` (Parte 6,
implementada na 1.0.10) diz que um **método** host sem binding é recusado onde é **chamado**; o tipo em si
compila — recusar a declaração foi a opção não tomada. As duas se conciliam se a `lem-c` valer para a
declaração host sem corpo e a 146 para toda função com corpo.

**Hoje:**
```bp
// std io.net: `Socket.recv` tem binding Erlang e Node, nenhum Wasm
sock.recv(10, 1000)    // wasm: MissingExternal `Socket.recv`, na chamada; o tipo Socket compila (lem-c)

fn readLine(s: Socket) -> @Result<string, string> {   // 146: corpo alcança `recv` sem binding no wasm
    return s.recv(80, 1000);                          //      → recusada na declaração, mesmo sem chamada
}
```

- [ ] **(a)** Confirmar a `lem-c` para declaração host sem corpo (um tipo declarado uma vez compila para um
  target em que falta um método); a 146 vale para toda função com corpo, livre ou método, que alcance
  uma; o `docs.md` diz as duas.
  ```bp
  pub type Socket(handle: unknown) { pub declare fn recv(self: Self, length: i32, timeoutMillis: i32) -> … }
  // ↑ compila no wasm (lem-c)
  fn readLine(s: Socket) -> @Result<string, string> { return s.recv(80, 1000); }   // wasm: recusada (146)
  ```
- [ ] **(b)** A 146 vale para tudo: o próprio tipo com método host sem binding é recusado no target que
  não o tem (a opção não tomada da `lem-c`).
  ```text
  $ botopink build --target wasm
  error: `Socket.recv` has no #[@External.Wasm] binding (at the declaration of Socket)
  ```
- [ ] **(c)** A `lem-c` vale para tudo: recusa só na chamada, também para função com corpo (a 146 recua
  e volta o `collectHostBound` preguiçoso do wasm).
  ```bp
  fn readLine(s: Socket) -> @Result<string, string> { return s.recv(80, 1000); }   // compila; só a chamada `readLine(s)` é recusada
  ```

**Recomendação: (a).** Mantém o que cada uma já implementa; a (b) impediria um tipo portátil com um método
de um target só, e a (c) desfaria a regra estrita da 146. **Bloqueia:** a confirmação da `lem-c`.

### ctr-p · Confirmação `std-a` × confirmação `03r-e`

**Contexto.** Há dois decodificadores de query/cookie, cada um com uma regra. A `std-a` (Parte 6,
implementada): `querystring.parse`/`parseForm` do std devolvem `Error` para um escape que decodifica em
caractere de controle (como `%0A`), e o `splitQuery` do rakun passa a usá-los. A `03r-e` (implementada no
rakun): um componente de cookie ou query que decodificaria em caractere de controle "fica como escrito".
A 196 leva os leitores de cookie do rakun para o `http`. Quando o rakun ler query pela `querystring` e
cookie pelo `http`, a regra da `03r-e` fica sem onde morar.

**Hoje:**
```bp
querystring.parse("a=%0A")      // std: Error — escape que vira caractere de controle
decodeComponent("%0A")          // rakun: "%0A" — fica como escrito (03r-e)
```

- [ ] **(a)** Confirmar a `std-a`; a `03r-e` cai quando o rakun ler query pela `querystring` e cookie pelo
  `http` — uma regra só, a do std.
  ```bp
  // GET /busca?q=%0A no rakun, depois da troca
  querystring.parse("q=%0A")      // Error: o leitor do rakun recusa o parâmetro
  ```
- [ ] **(b)** Confirmar a `03r-e` e levar a regra dela para o std: o componente fica como escrito.
  ```bp
  querystring.parse("a=%0A")      // Ok([#("a", "%0A")])
  ```

**Recomendação: (a).** Recusar é o mais restritivo (67) e mantém a lógica compartilhada no std; um valor
"como escrito" chega ao código como se fosse válido. **Bloqueia:** os leitores do rakun 04; a varredura de
consumidores da 104.

### ctr-q · Decisão 234 ("no boot") × decisão 256 ("em comptime")

**Contexto.** A 234 (injeção por construtor no rakun) diz que o contexto de beans é preenchido "no boot" a
partir do `@TypeInfo.all`. A 256, posterior, diz que o registro de beans é construído em comptime, no ponto
de entrada do programa, num `Dict` — "o rakun usa esta forma" —, citando a 254 e não a 234. Lida ao pé da
letra, a 234 faria o loop em tempo de execução; a 256, no build.

**Hoje:**
```bp
// 256: no ponto de entrada da aplicação
val beans: Dict<string, unknown> = comptime {
    var d = Dict.empty();
    for (@TypeInfo.all(with: [stereotypes…], member: "make")) { b -> d = d.insert(b.name, b.value); }
    for (@TypeInfo.all(with: provides)) { b -> d = d.insert(b.returnTypeName, b.value); }
    break d;
};
```

- [ ] **(a)** Ler o "no boot" da 234 como "a partir do registro comptime da 256": o boot só consulta
  `beans`; um nome registrado duas vezes falha o build.
  ```bp
  val clock = rkResolve("Clock");       // lê o Dict montado no build
  // dois beans "Clock" → erro de build, com local
  ```
- [ ] **(b)** Ler a 234 ao pé da letra: o boot percorre o `@TypeInfo.all` em tempo de execução (o loop da
  254, que continua legal); o duplicado só aparece ao subir.
  ```text
  $ ./app
  boot failed: bean "Clock" registered twice
  ```

**Recomendação: (a).** É o que a 256 diz que o rakun usa, e um erro no build é mais restritivo que um erro
no boot. **Bloqueia:** 130 passo 5.

### ctr-r · Decisão 189 (org-3) × decisão 200

**Contexto.** A org-3 (decisão 189, †) diz que a frente 118 reescreve os atributos entre colchetes
(`[name]={expr}` → `name={expr}`) **fora do próprio `jhonstart-html`**, em recortes de uma linha
sequenciados com 34, 33, 26 e 119. A 200 apaga o membro `jhonstart-html`: o `html` vira a função default
do core `jhonstart`, no passo 0 da 26 — antes da 118. "Fora do `jhonstart-html`" fica sem referência.

**Hoje:**
```bp
html """<div [class]={card}><p>hi</p></div>"""   // forma antiga; a 118 reescreve para class={card}
// org-3: recortes "fora do jhonstart-html" · 200: jhonstart-html apagado no 26 passo 0
```

- [ ] **(a)** Ler a org-3 contra o `html.bp` do core depois do 26 passo 0: recorte é tudo que está fora de
  `jhonstart/modules/jhonstart/src/html.bp` e dos testes dele.
  ```text
  da 118 (dona):  jhonstart/src/html.bp, html_test.bp, elements_test.bp
  recortes:       jhonstart-emilia/…/bridge_test.bp, examples/document-shell/…/shell_dsl.bp
  ```
- [ ] **(b)** Ler a org-3 ao pé da letra: a 118 roda antes do 26 passo 0, enquanto o `jhonstart-html`
  ainda existe — inverte a ordem da 200.
  ```text
  118 passo 1 → depois 26 passo 0 (fusão do jhonstart-html no core)
  ```

**Recomendação: (a).** Mantém a ordem da 200 e muda só a referência do texto. **Bloqueia:** os recortes
da 118.

### ctr-s · Decisão 166 × decisão 243

**Contexto.** No formatador, a 166 diz que a vírgula final decide: lista escrita com vírgula depois do
último elemento fica um por linha (e mantém a vírgula); lista sem ela fica numa linha só. A 243 estendeu
o alcance da 166 a toda lista delimitada (genéricos, parâmetros, imports, argumentos…), mas diz que, sem a
vírgula, decidem as regras de largura (`16-a`/`16-b`: quebra o que não cabe) — e se apresenta como
"extensão" da 166, embora mude a metade "sem vírgula".

**Hoje:**
```bp
// escrito sem vírgula final, mais largo que a linha:
val p = Person(name: "Ana Maria da Silva", email: "ana@example.com", city: "Belo Horizonte", age: 30);
// 166: fica numa linha · 243: as regras de largura quebram
```

- [ ] **(a)** Registrar a 243 como emenda da metade "sem vírgula" da 166; a confirmação de `16-a`/`16-b`
  (Parte 6) cobre o resto.
  ```bp
  val p = Person(
      name: "Ana Maria da Silva",
      email: "ana@example.com",
      city: "Belo Horizonte",
      age: 30
  );                                   // forma exata da quebra: 16-a/16-b
  ```
- [ ] **(b)** A 166 vale inteira: sem vírgula, uma linha, por mais larga que fique; a 243 só estende o
  alcance.
  ```bp
  val p = Person(name: "Ana Maria da Silva", email: "ana@example.com", city: "Belo Horizonte", age: 30);
  ```

**Recomendação: (a).** É o que o formatador da `feat` faz (16-a/16-b implementadas) e o que a 243 quis;
falta só o texto dizer "emenda". **Bloqueia:** 16-formatter passo 6.

### ctr-u · Decisão 216 × o `#[schema]` da 125

**Contexto.** A 216 diz que um decorador produz membros do tipo, meta de comptime, tipos associados e
reflexão do projeto — "o `@emit` solto sai" da linguagem quando as bibliotecas migrarem. O `#[validated]`
já migrou (`user.validate()`, `constraints()`). O `#[schema]` (biblioteca `validation`, na `feat` e no
desenho da 125, o port do Zod) ainda emite funções soltas `parse<T>`, `parse<T>At`, `decode<T>`,
`schemaOf<T>` (e, mais tarde, `bind<T>`, `encode<T>`, `jsonSchemaOf<T>`); o `surface.md` da 125 ainda
nomeia `constraintsOf<T>`/`validate<T>`.

**Hoje:**
```bp
#[schema]
type Player(name: string, level: i32)

val p = try parsePlayer(doc);        // função solta, emitida pelo @emit
val s = schemaOfPlayer();
```

- [ ] **(a)** As saídas do `#[schema]` viram membros, como as do `#[validated]`; as linhas do `surface.md`
  da 125 acompanham (os nomes exatos são da 125).
  ```bp
  val p = try Player.parse(doc);
  val q = try Player.decode(text);
  val s = Player.schema();
  ```
- [ ] **(b)** O `#[schema]` mantém as funções soltas: o `@emit` de módulo fica na linguagem enquanto a
  `validation` o usar (a 216 espera).
  ```bp
  val p = try parsePlayer(doc);        // como hoje
  ```

**Recomendação: (a).** É o que a 216 manda e o que o `#[validated]` já fez; os nomes gerados
(`parse<T>`, que hoje são contrato entre dois `#[schema]`) deixam de existir. **Bloqueia:** 125 passos
3–10.

### ctr-v · Decisão 189 (org-3) × as frentes da emilia abrindo antes da 118

**Contexto.** A org-3 manda os recortes da 118 (reescrever `[name]={expr}` fora do membro) entrarem antes
de a frente dona do arquivo abrir. Mas a 34 passo 1 e a 33 passo 2 (emilia) abrem agora, e as linhas
`[class]={…}` da emilia são só comentários — as próprias frentes os reescrevem (`attributes.bp:30,32,36`,
`emilia.bp:185,202`, `emilia-card/src/main.bp:5`). O README da 118 já diz que não é dona deles; o registro
(org-3) ainda diz o contrário.

**Hoje:**
```bp
//// THE `[class]={…}` HOLE MAY NOT CONTAIN A SPACE: jhonstart's DSL splits a …   (emilia/src/attributes.bp:30)
// The class name alone — the value a `[class]={…}` hole and a hydrator compare.   (emilia/src/emilia.bp:185)
```

- [ ] **(a)** Registrar que um recorte só de comentário é feito pela frente dona; a 118 fica com as linhas
  de código (os testes dela, o `bridge_test.bp` do `jhonstart-emilia`, o `document-shell`).
  ```text
  34 passo 1: reescreve os comentários de attributes.bp e emilia.bp (sem esperar a 118)
  33 passo 2: reescreve o comentário de emilia-card/src/main.bp:5
  118 passo 1: bridge_test.bp, shell_dsl.bp — linhas de código
  ```
- [ ] **(b)** A org-3 ao pé da letra: a 34 passo 1 e a 33 passo 2 esperam a 118 entrar os recortes,
  comentários inclusive.
  ```text
  34 passo 1, 33 passo 2 → bloqueados até o commit de recortes da 118
  ```

**Recomendação: (a).** Um comentário não muda comportamento; segurar duas frentes da emilia por ele não
protege nada. **Bloqueia:** 34 passo 1; 33 passo 2; o Owns da 118.

### ctr-w · O braço Elasticsearch da 09 × decisão 185

**Contexto.** A frente 09 (rakun-data NoSQL) tem quatro braços; o Elasticsearch é HTTP + JSON, e o plano
era usar o cliente HTTP do `rakun-client` (frente 13). Hoje o `rakun-data` depende só de `rakun` e
`rakun-actuator`; o braço criaria uma aresta `rakun-data → rakun-client` que todo consumidor de dados
carregaria, mesmo quem nunca configura Elasticsearch. A 185 diz que uma capacidade opcional passa por um
ponto de extensão do core, sem aresta entre membros.

**Hoje:**
```json
// rakun/modules/rakun-data/botopink.json
"dependencies": { "rakun": {…}, "rakun-actuator-api": {…}, "rakun-actuator": {…} }
// 09 passo 3: index/get/search/delete "go through rakun-client"  → + "rakun-client": {…}
```

- [ ] **(a)** O braço chega ao HTTP por um ponto de extensão do core (ou pelo `httpc` direto, como o relay
  da 65) — nenhuma aresta nova; responder junto com a lista de braços da `03r-ab`.
  ```text
  RAKUN_DATA_URL=https://es.local:9200
  rakun-data → ponto de extensão HTTP do core (ou httpc:request inline)
  dependências do rakun-data: inalteradas
  ```
- [ ] **(b)** Aceitar a aresta: a 185 cede para este caso, e todo consumidor de dados carrega o
  `rakun-client` (com o filtro SSRF e os timeouts dele de graça).
  ```json
  "dependencies": { "rakun": {…}, "rakun-actuator": {…}, "rakun-client": {"workspace": true} }
  ```
- [ ] **(c)** O braço Elasticsearch vira um membro à parte que depende de `rakun-data` e `rakun-client`,
  carregado só por quem o configura (um membro a mais na conta da 187).
  ```text
  modules/rakun-data-elasticsearch/ → rakun-data, rakun-client
  ```

**Recomendação: (a)** — é o que a 185 manda e não acrescenta membro. **Bloqueia:** 09 passo 3.

- [ ] Confirmo a recomendação em todas desta parte
- [ ] Quero rever: ___

---

---

## Parte 2 — Destravam muitas frentes

### snap-a · Os mapas de snapshot — aposentados; ficam os snapshots que existem ou que um contrato lê

**Contexto.** Substitui as cinco perguntas antigas (`01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b`).
Um "mapa de snapshot" é uma lista, herdada da 1.0.10, dos casos que cada biblioteca deveria gravar como
arquivo `.snap` (a saída esperada guardada em disco). Os nove mapas foram reavaliados caso a caso na
trilha `20-snap` (frente 135): **473 casos** — 27 obsoletos (renomeados, apagados ou mudados pelas
decisões 186, 194, 200, 218, pelo 34 passo 2, pela 50-a, ou adiados pela 274), 418 já verificados
hoje por um teste inline ou por um `.snap` que existe, e 21 que nada verifica e valem um teste simples.
Os literais gravados nos mapas são anteriores ao código (separador de slug, ordem do `_links`,
`normalize`, classes da emilia) e não servem de valor esperado. O contrato 7, a regra 3 do
`snapshots.md` e a checagem (2) da 98 exigem pelo menos um `assert<Assunto>(loc, …)` em cada `<lib>-test`.

**Hoje:**
```bp
// cada caso já é afirmado por um literal inline, nos dois targets:
test "rounded" { asserts.equals(css([.Rounded.Md]), ".rounded-md{border-radius:0.375rem}"); }
// e os .snap que existem: std 4, jhonstart 39, onze 50 (24 deles via snapshots.assertAs)
```

- [ ] **(a)** Como proposto: os mapas viram registro fechado; os `.snap` que existem ficam (std 4,
  jhonstart 39, onze 50) e só mudam junto com o seu teste; um `.snap` novo só onde os bytes exatos são
  contrato de outro pacote (os `text_…` e `dockerfile_…` do onze-release, já em disco, para a
  `107-release`); helpers só os que um consumidor usa — `emilia-test`: `assertClassName` (sob
  `defaultTheme()`, gravando `e_39b87d03`) e `assertCss(loc, tokens, th)`; `rakun-test`:
  `assertResponse(loc, res)` sobre `MockMvc.perform`; os do jhonstart e do onze como estão (o
  `assertAlias` do onze sai com a 218). Os 21 valores sem verificação viram testes simples, e 97 passo 7,
  26 passo 7, 33 passos 3–4, 50 passo 8, 51 passo 7 fecham com uma linha no `AGENTS.md`. Só **3** `.snap`
  novos (emilia-test 2, rakun-test 1).
  ```bp
  asserts.throwsWith({ -> mocks.verify(m, 2) }, "expected 2 calls, got 1");    // std, nos dois targets
  assertClassName(loc, [.Rounded.Md], defaultTheme());                          // emilia-test → e_39b87d03
  // AGENTS.md: "os literais inline e os __snapshots__/ existentes são a evidência"
  ```
- [ ] **(b)** Construir a camada inteira: todos os helpers e `.snap` dos mapas (~2 500 arquivos), com os
  literais recalculados primeiro — muitos arquivos novos para valores que já têm um teste inline.
  ```text
  modules/emilia-test/test/__snapshots__/rounded_md.snap
  modules/emilia-test/test/__snapshots__/rounded_lg.snap
  …                                            # ~2 500 arquivos, cada literal do mapa recalculado
  ```
- [ ] **(c)** Manter os mapas abertos por biblioteca: cada uma responde a sua pergunta antiga e guarda o
  seu mapa até lá — cinco respostas separadas, regras possivelmente diferentes.
  ```text
  05emilia-m (aberta): a emilia grava os casos do seu mapa?   → resposta só para a emilia
  03r-ag     (aberta): o rakun grava os casos do seu mapa?    → resposta só para o rakun
  ```

**Recomendação: (a).** Uma regra para todas as bibliotecas, cada valor verificado uma vez, e só três
`.snap` novos; é a opção mais restritiva que ainda prova tudo. **Bloqueia:** a frente 135 inteira
(`20-snap`, passos 1–5), que é dona de 97 passo 7 · 19 passo 6 · 26 passo 7 · 33 passos 1, 3, 4 · 50
passo 8 · 51 passo 7 · o runner do passo 1 da 53 e o texto dos passos 2–6 · 71 passo 6; a checagem (2)
da 98 fica como está.

### 03r-ao · A ordem entre o 130 e o 128 no rakun *(proposta)*

**Contexto.** A frente 128 reorganiza o rakun (a decisão 187 funde membros: 25 viram 16) e move
arquivos — por exemplo `rakun-actuator-api` para `modules/rakun/src/actuator_api/`. O passo 5 da
`01-compiler/130` (decisão 216: decoradores produzem membros e meta em vez de `@emit` solto) ainda planeja
editar arquivos que o 128 move ou que as frentes do rakun possuem: o `decorators.bp`, `autoconfig.bp`,
`config.bp`, `context.bp`, `lifecycle.bp` e `conditions.bp` do core, `rakun-web/src/convention.bp`,
`rakun-app`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun-data`, `rakun-security`,
`rakun-websocket`, `rakun-client` e `rakun-actuator-api`. Nenhuma decisão diz quem vai primeiro, e as
duas mexendo nos mesmos arquivos ao mesmo tempo é conflito garantido.

**Hoje:**
```text
130 passo 5 planeja editar:  modules/rakun-actuator-api/src/…        (caminho de antes do 128)
128 move:                    modules/rakun-actuator-api/ → modules/rakun/src/actuator_api/
nenhuma decisão ordena os dois
```

- [ ] **(a)** O 128 primeiro e sozinho; os pontos do 130 no rakun apontam para os caminhos depois do
  128; depois dele cada um é um commit de consumidor (decisão 188, nunca na mesma onda da frente dona);
  a regra de arquivos congelados abre exceção para a reescrita do `decorators.bp` pelo 130.
  ```text
  onda 1: 128 sozinho                 → rakun com 16 membros, caminhos novos
  onda 2: commit de consumidor do 130 → modules/rakun/src/actuator_api/…  (fora da onda da frente dona)
          exceção ao congelamento     → modules/rakun/src/decorators.bp reescrito pelo 130
  ```
- [ ] **(b)** Os pontos do 130 no rakun antes de o 128 abrir — toda frente do rakun espera o 130.
  ```text
  onda 1: 130 passo 5 edita modules/rakun-actuator-api/…, modules/rakun-web/src/convention.bp, …
  onda 2: só então o 128 abre (e move os arquivos que o 130 acabou de editar)
  ```
- [ ] **(c)** O próprio 128 faz a reescrita do 130 nos arquivos que move — o 128 fica maior e mistura
  mudança de lugar com mudança de forma.
  ```text
  128: git mv modules/rakun-actuator-api/src → modules/rakun/src/actuator_api
       + reescreve os #[…] desses arquivos no formato da 216, no mesmo commit
  ```

**Recomendação: (a)** — o 128 segura o rakun inteiro, e a (b) seguraria toda frente do rakun esperando
o 130. **Bloqueia:** a abertura do 128; as linhas do rakun no passo 5 do 130.

### own-a · Quem é dono dos scripts de teste *(proposta)*

**Contexto.** Toda frente declara os arquivos que é dona; mexer em arquivo de outra frente pede um
recorte combinado. Os scripts que rodam os testes — `scripts/{gate.sh,test-libs.sh,lib/pool.sh}` (além
das linhas de orçamento da 114), `tests/language/run.sh` (além do relatório da 12),
`modules/test-shard/**`, `modules/lib-test-runner/**` e os `scripts/**` do meta — eram da 25, 113, 115
e 133, todas fechadas. Hoje são órfãos (`fronts.md` § Ownership, item em aberto), e quem precisar
editá-los não tem a quem pedir.

**Hoje:**
```text
arquivo                                         dono anterior            estado
scripts/{gate.sh,test-libs.sh,lib/pool.sh}      25-gate-perf/113/115/133 fechadas
tests/language/run.sh                           (idem)                   fechadas
modules/test-shard/**, modules/lib-test-runner/** (idem)                 fechadas
→ 07-residuals passo 12 e 114 passos 5 e 7 querem editar e não têm dono a quem pedir
```

- [ ] **(a)** `01-compiler/07-residuals`, que já tem o passo aberto da 25 (a compilação de dependência
  por célula) — um dono só para o trabalho de runner que já está aberto.
  ```text
  fronts.md § Ownership:  scripts/gate.sh, scripts/test-libs.sh, … → 01-compiler/07-residuals
  114 passo 5 edita scripts/gate.sh → recorte pedido à 07-residuals
  ```
- [ ] **(b)** `00-gate/114`, o resto do gate — o dono é a frente do gate, mas o trabalho de runner
  aberto (passo 12 da 07-residuals) passa a pedir recorte.
  ```text
  fronts.md § Ownership:  scripts/gate.sh, scripts/test-libs.sh, … → 00-gate/114
  07-residuals passo 12 edita scripts/test-libs.sh → recorte pedido à 114
  ```
- [ ] **(c)** Ninguém: cada frente declara um recorte por commit.
  ```text
  commit 114: "recorte: scripts/gate.sh (114 passo 5)"
  commit 07-residuals: "recorte: scripts/test-libs.sh (07-residuals passo 12)"
  ```

**Recomendação: (a)** — um dono só, o que já segura o trabalho aberto. **Bloqueia:** 07-residuals passo
12; 114 passos 5 e 7.

### 08-j · Como o `local()` do rakun carrega uma marca do jhonstart *(proposta)*

**Contexto.** O `local<T>(key)` da 123 lê um dado do request (o que um middleware guardou), então uma
página que o lê precisa renderizar por request, nunca pré-renderizada (186). A checagem da 186 reconhece
isso pela marca `#[serverOnly]` — mas `#[serverOnly]` é marca do jhonstart, e rakun e jhonstart nunca se
importam (113). A terceira caixa do passo 1 da 123 está escrita para a ponte (`ChunkWriter.markDynamic`,
`dynamicReason()` dizendo `locals`), que a 186 apaga quando a checagem do compilador chegar.

**Hoje:**
```bp
// rakun: um middleware guarda o usuário; a página lê
val user = local<User>("user");      // leitura de request → a página tem de renderizar por request (186)
// mas `local` não pode levar #[serverOnly]: a marca é do jhonstart, e o rakun não importa o jhonstart (113)
```

- [ ] **(a)** As marcas de estágio vão para um pacote que os dois importam (o bundled `routing`, pelo
  teste das duas bibliotecas da 115); os dois marcam com o mesmo `#[serverOnly]`.
  ```bp
  import {serverOnly} from "routing";
  #[serverOnly] pub fn local<T>(key: string) -> ?T { … }     // rakun
  #[serverOnly] pub fn cookies() -> Cookies { … }            // jhonstart, a mesma marca
  ```
- [ ] **(b)** O rakun declara a própria marca; a checagem lê marcas por um nome declarado no manifesto.
  ```json
  { "name": "rakun", "stageMarkers": { "serverOnly": ["rkRequestScoped"] } }
  ```
  ```bp
  #[rkRequestScoped] pub fn local<T>(key: string) -> ?T { … }
  ```
- [ ] **(c)** `local` só pode ser lido em middleware, handlers e actions, nunca numa página.
  ```bp
  // app/profile/page.bp
  val user = local<User>("user");   // error: `local` só pode ser lido em middleware, handler ou action
  ```

**Recomendação: (a)** — uma marca só, e nenhuma biblioteca nomeia outra. **Bloqueia:** a terceira caixa
do passo 1 da 123; toda leitura de request do rakun que uma página alcança.

---

## Parte 3 — Destravam uma frente ou um passo

Cada uma abre uma frente, um passo ou uma onda.

### 130-b · Dois `#[provides]` do mesmo tipo num registro chaveado pelo nome do tipo (decisões 254, 256)

**Contexto.** A 256 monta o registro de beans do rakun em comptime, no ponto de entrada, com um laço
sobre `@TypeInfo.all(with: provides)`, e o trecho dela chaveia cada provider por `b.returnTypeName`.
Dois providers qualificados do mesmo tipo — e um `#[primary]` ao lado de um comum — colidem em `"Dye"`,
e o registro os recusa como duplicata. Antes, o `__rkMake_Dye` deixava o sem qualificador (ou o
`#[primary]`) ser o injetado e mantinha os outros por `ctx.resolveNamed("Dye", "fast")`
(`rakun/test/context_test.bp`, `examples/rakun-container`) — a regra do Spring.

**Hoje:**
```bp
#[provides] #[qualifier("fast")] fn fastDye() -> Dye { … }
#[provides] #[qualifier("slow")] fn slowDye() -> Dye { … }     // hoje: duplicata de "Dye"
```

- [ ] **(a)** Provider qualificado é chaveado `Tipo@qualificador` (o decorador grava
  `setMeta("qualifier", …)`); o nome puro é o sem qualificador ou o `#[primary]`; dois donos do nome puro
  são a duplicata.
  ```bp
  for (@TypeInfo.all(with: provides)) { b ->
      d = d.insert(rkBeanKey(b), b.value);   // "Dye@fast", "Dye@slow", "Dye" para o primary
  }
  ctx.resolveNamed("Dye", "fast")            // lê "Dye@fast" do mesmo registro
  ```
- [ ] **(b)** O registro guarda só o que a injeção por tipo lê; os qualificados ficam na tabela do
  contexto que o registro em load preenche (`resolveNamed` a lê) — dois lugares para bean.
  ```bp
  // registro em comptime: só "Dye" (o sem qualificador ou o #[primary])
  // fastDye e slowDye: registrados em load na tabela do contexto
  ctx.resolveNamed("Dye", "fast")            // lê a tabela, não o registro
  ```
- [ ] **(c)** O trecho como está: dois providers de um tipo são sempre duplicata; qualificador só nomeia
  bean de tipo com um provider.
  ```bp
  #[provides] #[qualifier("fast")] fn fastDye() -> Dye { … }
  #[provides] #[qualifier("slow")] fn slowDye() -> Dye { … }
  // error: duplicate bean "Dye" (fastDye, slowDye)
  ```
- [ ] **(d)** *(nova, pela 281)* O qualificador é um tipo distinto; o registro é chaveado só pelo tipo, e
  `#[qualifier("…")]` e `resolveNamed` saem.
  ```bp
  type FastDye(dye: Dye)
  type SlowDye(dye: Dye)
  #[provides] fn fastDye() -> FastDye { … }
  #[provides] fn slowDye() -> SlowDye { … }
  val d = use bean(FastDye);              // em vez de ctx.resolveNamed("Dye", "fast")
  ```

**Recomendação: (d)**, pela decisão 281 — a (a) guarda uma string (`Dye@fast`) ao lado do tipo. A (a)
continua possível se você quiser um rótulo em texto mesmo assim. **Bloqueia:** a migração
de `#[provides]` / `#[qualifier]` / `#[primary]` do rakun (130 passo 5: `context.bp`, o teste dele,
rakun-container).

### 130-c · Os métodos `#[bean]` de um `#[configuration]` no registro (decisão 234)

**Contexto.** A 234 preenche o contexto de injeção "a partir do `@TypeInfo.all(with: provides)` / dos
métodos `#[bean]`", mas o `@TypeInfo.all` responde só declarações de topo, e um `#[bean]` é método de um
tipo `#[configuration]`: nenhuma consulta o alcança. Hoje o `#[configuration]` emite `__rkMake_<Tipo>()`
por `#[bean]` (`autoconfig.bp`, `conditions.bp`, `config.bp`, `settings.bp` do rakun-client,
`oauth2/provider.bp` do rakun-security, `examples/rakun`). Sem resposta, esses beans ficam fora do
registro novo.

**Hoje:**
```bp
// examples/rakun/src/config.bp
#[configuration]
pub type AppConfig(
    #[value("app.timezone")] timezone: string,
) {
    #[bean]
    pub fn clock(self: Self) -> Clock { return Clock(zone: self.timezone); }   // emite __rkMake_Clock()
}
```

- [ ] **(a)** Métodos `#[bean]` viram funções livres `#[provides]` (o record de configuração fica com os
  campos `#[value]`; o provider os lê por `rkResolve`).
  ```bp
  #[configuration]
  pub type AppConfig(#[value("app.timezone")] timezone: string);

  #[provides]
  pub fn clock() -> Clock { return Clock(zone: rkResolve<AppConfig>("AppConfig").timezone); }
  ```
- [ ] **(b)** A configuração grava cada bean como meta e ganha um membro `Config.bean(name) -> unknown`;
  o ponto de entrada faz um terceiro laço sobre `@TypeInfo.all(with: configuration)`.
  ```bp
  for (@TypeInfo.all(with: configuration)) { c ->
      // c.meta("beans") == ["clock"]
      d = d.insert("Clock", c.value.bean("clock"));     // unknown
  }
  ```
- [ ] **(c)** O `@TypeInfo.all` ganha `methods: true` — reflexão nova, que alcança métodos.
  ```bp
  for (@TypeInfo.all(with: bean, methods: true)) { b -> d = d.insert(b.returnTypeName, b.value); }
  ```

**Recomendação: (a)** — um jeito só de fornecer bean, já no laço do registro, sem reflexão nova; o
`@Bean` do Spring é o que o `#[provides]` já é numa linguagem com funções livres. **Bloqueia:** a
migração do `#[configuration]` do rakun e todo `__rkMake_` que um `#[bean]` define (130 passo 5).

### 134-d · `@is(…)` escrito à mão

**Contexto.** `x is T` é lido como a chamada builtin `is` levando o tipo testado. O lexer também faz de
`@is(1)` essa mesma chamada, só que sem tipo testado — tipa como `bool` e não baixa nada com sentido. É
alcançável e não está declarado, e a 252 diz que todo builtin é declarado; esta é a última chamada
builtin não declarada do passo 1 da 134.

**Hoje:**
```bp
val b = @is(1);   // hoje compila: bool, sem testar nada
```

- [ ] **(a)** Recusar `@is(…)` como chamada (`unknown-builtin`, apontando `x is T`).
  ```bp
  val b = @is(1);   // error[unknown-builtin]: `@is` não é builtin — escreva `x is T`
  ```
- [ ] **(b)** Declará-lo (`is(value: unknown) -> bool`) e manter a chamada.
  ```bp
  pub declare fn is(value: unknown) -> bool;
  val b = @is(1);   // compila, declarado — e continua sem testar tipo nenhum
  ```

**Recomendação: (a).** `is` é um operador; uma forma de chamada que ninguém escreve e que não testa nada
é a leitura mais frouxa. **Bloqueia:** a última linha de chamada builtin não declarada do passo 1 da 134.

### 17-b · O incremento por linha de um `Dict` com `keyed = true`

**Contexto.** A frente 17 implementou o `keyed = true` (decisões 168 e 174): um `var` global anotado
`#[@BeamMemory.Ets(keyed = true)]` vira uma tabela ETS em que cada chave é uma linha. `counts.at(k)` lê
uma linha (`ets:lookup`) e `counts = counts.insert(k, v)` escreve uma linha (`ets:insert`); dois
processos escrevendo cada um a sua chave 20 000 vezes terminam em `20000 20000`. O que falta é um `+=`
numa linha virar `ets:update_counter` (atômico). O `??` agora existe, então a forma abaixo **tipa** — mas
continua recusada, porque recalcula a linha a partir do próprio var e pode perder um de dois incrementos
simultâneos (a regra 5(b) da decisão 40). `counts.at(k) += 1` e `counts[k] += 1` não são alvos de
atribuição.

**Hoje:**
```bp
#[@BeamMemory.Ets(keyed = true)]
var counts: Dict<string, i32> = Dict.empty();

counts = counts.insert(k, (counts.at(k) ?? 0) + 1);   // tipa; recusado: … can lose one of two concurrent runs
```

- [ ] **(a)** Nenhum: uma linha keyed se escreve inteira; um contador que vários processos incrementam é
  um `#[@BeamMemory.Ets] var n: i32` próprio (o incremento da decisão 40).
  ```bp
  #[@BeamMemory.Ets] var hitsA: i32 = 0;
  hitsA += 1;                                  // ets:update_counter
  ```
- [ ] **(b)** Um método da std `Dict.bump(key, by)` (valor inteiro; chave ausente conta de 0), comum num
  `Dict` normal e, sob `keyed = true`, `ets:update_counter(T, K, By, {K, 0})`.
  ```bp
  counts = counts.bump(k, 1);
  ```
- [ ] **(c)** Atribuição por índice na gramática, com o mesmo lowering.
  ```bp
  counts[k] += 1;
  ```
- [ ] **(d)** *(nova, agora que `??` existe)* Reconhecer exatamente a forma
  `counts.insert(k, (counts.at(k) ?? 0) + n)` e baixá-la para `ets:update_counter`, sem método nem
  gramática nova.
  ```bp
  counts = counts.insert(k, (counts.at(k) ?? 0) + 1);   // reconhecida → ets:update_counter(T, k, 1, {k, 0})
  counts = counts.insert(k, (counts.at(k) ?? 0) * 2);   // outra forma: continua recusada
  ```

**Recomendação: (a).** Nenhum método ou gramática nova por causa de uma anotação; (b) põe no `Dict` um
método cuja atomicidade só existe sob `keyed = true`, (c) cria um alvo de atribuição que a linguagem não
tem, (d) faz uma forma escrita mudar de significado conforme o padrão. **Bloqueia:** a quarta caixa do
passo 1 da 17.

### 17-c · O que mais pode nomear um var `keyed = true`

**Contexto.** Um var `keyed = true` não tem "valor inteiro" na memória: é uma tabela lida linha a linha.
Por isso hoje ele só aparece como `counts.at(k)` (`ets:lookup`) e `counts = counts.insert(k, v)`
(`ets:insert`); todo o resto (`counts[k]`, `hasKey`, `delete`, `size()`, passá-lo adiante) é recusado no
identificador, e um var keyed nunca é `pub` (quem importasse leria o valor inteiro, que não existe). A
decisão 63, porém, diz que `d[k]` É `d.at(k)` — e a forma com índice é recusada.

**Hoje:**
```bp
@print(counts.size());     // error: `counts` is a `keyed = true` var: it is read one row at a time, as `counts.at(key)`
@print(counts["a"]);       // a mesma recusa — embora a decisão 63 diga que `d[k]` É `d.at(k)`
```

- [ ] **(a)** Só as duas formas, como está.
  ```bp
  val a = counts.at("a") ?? 0;          // ets:lookup
  counts = counts.insert("b", 10);      // ets:insert
  @print(counts["a"]);                  // error: … read one row at a time, as `counts.at(key)`
  ```
- [ ] **(b)** (a) mais `counts[k]`, lido como o `counts.at(k)` que a decisão 63 diz que ele é.
  ```bp
  @print(counts["a"]);       // ets:lookup, como counts.at("a")
  ```
- [ ] **(c)** (b) mais `hasKey` (`ets:member`) e `delete` (`ets:delete`) como operações de linha, cada uma
  um primitivo novo no `std/beam`.
  ```bp
  if (counts.hasKey("a")) counts = counts.delete("a");
  ```

**Recomendação: (a).** Uma grafia por operação de linha; (b) custa pouco, mas é uma segunda grafia da
leitura; (c) aumenta a superfície que o checker e os dois emissores precisam manter iguais.
**Bloqueia:** nada — o que está construído vale até ser ampliado.

### imp-a · Dois tipos com o mesmo nome importados com alias *(proposta)*

**Contexto.** A decisão 170 torna legal importar dois nomes iguais de módulos diferentes, desde que com
alias. O checker recusa isso para **tipos** (`import-name-collision`, célula
`modules/import_two_types_one_name`), porque os backends não distinguem tipos por módulo — dois `T`
viram o mesmo nome no código gerado. Para valores (funções, constantes) o alias já funciona.

**Hoje:**
```bp
import {m1.f as f1};
import {m2.f as f2};      // ok: valores
import {m1.T as A};
import {m2.T as B};       // hoje: import-name-collision
```

- [ ] **(a)** Tipos continuam recusados: o alias da 170 vale só para valores.
  ```bp
  import {m1.T as A};
  import {m2.T as B};     // error[import-name-collision]: dois tipos `T`; o alias vale só para valores
  ```
- [ ] **(b)** Os backends qualificam tipos pelo módulo; a forma passa a valer.
  ```bp
  import {m1.T as A};
  import {m2.T as B};
  val a: A = A(…);        // ok: o backend distingue m1.T de m2.T
  val b: B = B(…);
  ```

**Recomendação: (b).** A 170 é regra sua; a recusa é limite de backend, guardado numa linha do
`language-gaps.md` até ser construído. **Bloqueia:** nada aberto; uma linha da 01-checker.

### pkg-b · Um pacote importando a si mesmo pelo nome (`from "log"` dentro do próprio `log`)

**Contexto.** A decisão 206 já está implementada (frente 129): `from` nomeia só pacote, e um módulo do
próprio pacote vem pelo caminho entre chaves. Sobra um caso: os testes de um pacote importando o próprio
pacote pelo nome. Hoje são 12 arquivos (log 1, routing 1, validation 2, std 8). A diferença prática é
o que o teste enxerga: pelo nome do pacote, só o que é exportado; pelo caminho, também o interno.

**Hoje:**
```bp
// libs/log/test/digest_test.bp
import {errorDigest} from "log";          // o próprio pacote log — compila
```

- [ ] **(a)** Vale: é um pacote, e `from` nomeia pacote.
  ```bp
  // libs/log/test/digest_test.bp
  import {errorDigest} from "log";        // ok: só a superfície pública do log
  ```
- [ ] **(b)** Recusa: dentro do pacote, é `import {digest.errorDigest};`, como qualquer outro módulo dele.
  ```bp
  import {errorDigest} from "log";        // error: dentro do pacote `log`, importe pelo módulo
  import {digest.errorDigest};            // ok: vê também o que não é exportado
  ```

**Recomendação: (a).** O teste lê o pacote como um usuário de fora o lê — pela superfície pública —, que
é o que um teste de pacote deve exercitar; (b) faria o teste ver também o que não é exportado.
**Bloqueia:** nada (o caso está como item do passo 8 da `01-compiler/26`).

### 08-d · Quem faz o escopo do CSS

**Contexto.** Um `<style>` dentro de um componente `.bpp` deve valer só para aquele componente (como no
Astro): alguém precisa reescrever os seletores com um atributo único. Hoje ninguém faz isso: a emilia
compila tokens (`Token[]`) e "não é um processador de CSS"; o onze-assets só renomeia as classes de
`*.module.css` (`style_module.bp`); e a decisão 113 proíbe uma biblioteca nomear outra, então o caminho
precisa passar por uma ponte. A resposta decide onde mora o parser de CSS.

**Hoje:**
```text
<style> h1 { color: red; } </style>        // dentro de um componente .bpp — ninguém dá escopo ainda
styles.module.css  .title{…}  → .title_<hash>   // o onze-assets só renomeia classes de *.module.css
```

- [ ] **(a)** A emilia ganha `scopeCss(scope, css)`, alcançada pela ponte `jhonstart-emilia`.
  ```bp
  scopeCss("c1a2", "h1 { color: red; }")     // → "h1[data-s-c1a2]{color:red}"
  ```
- [ ] **(b)** O onze-assets, no build, ao lado do renomeador de módulos: uma aplicação jhonstart sem onze
  fica sem estilos com escopo.
  ```text
  $ onze build      → dist/…/card.css: h1[data-s-c1a2]{color:red}
  jhonstart sem onze: <style> h1{color:red} </style> sai sem escopo e vale para a página inteira
  ```
- [ ] **(c)** O jhonstart-html: um parser de CSS dentro da lib de HTML.
  ```bp
  // jhonstart, junto do html.bp: scopeStyle("c1a2", "h1 { color: red; }") → "h1[data-s-c1a2]{color:red}"
  ```

**Recomendação: (a).** A (c) põe um parser de CSS na biblioteca de HTML; a (b) deixa o estilo com escopo
indisponível sem o onze. **Bloqueia:** 119 inteira — na cadeia crítica 118 → 119 → 120 → 126 → 127 → 124.

### 08-f · Onde moram Markdown e YAML

**Contexto.** Páginas de conteúdo (posts de blog) são Markdown com um cabeçalho YAML ("frontmatter").
Hoje não existe código de Markdown em lugar nenhum, e há um único leitor de um subconjunto de YAML, no
`config.bp` do rakun. A regra do `03-bundled-libs` (115) manda um leitor de config para o std "quando
aparecer um segundo consumidor" — e o frontmatter é esse segundo consumidor do YAML; o Markdown tem um
só.

**Hoje:**
```text
---
title: Hello
---
# Post
→ ninguém lê isto ainda; o único leitor de YAML é o de rakun/src/config.bp (subconjunto, privado)
```

- [ ] **(a)** Os dois no novo membro `onze-content` — o rakun fica com a sua cópia de YAML.
  ```bp
  import {markdown, frontmatter} from "onze-content";
  ```
- [ ] **(b)** Markdown no `onze-content`; YAML no std, e o leitor de config do rakun é apagado pela frente
  do rakun. Até o `yaml` do std chegar, o passo 3 da 121 lê o frontmatter com cópia própria e a apaga
  depois.
  ```bp
  import {yaml} from "std";
  import {markdown} from "onze-content";
  ```
- [ ] **(c)** Um bundled `markdown`.
  ```bp
  import {markdown} from "markdown";
  ```

**Recomendação: (b).** O frontmatter é o segundo consumidor do YAML; o Markdown tem um só (115).
**Bloqueia:** 121 passo 3; uma linha para a 97.

### 08-h · Arquivo de config e comandos

**Contexto.** O onze já tem um arquivo de config e um CLI próprios: o `onze.json` existe e recusa chave
desconhecida (`49-c`); `onze create | info | build | start` existem e `dev` é só um stub. O `botopink`
(CLI do compilador) não tem nenhum comando de framework. A pergunta é se o `.bpp` continua nesse
caminho ou abre um segundo arquivo e comandos no CLI do compilador.

**Hoje:**
```text
$ onze dev
onze dev: not available yet - it serves the build `onze start` serves and reloads the changed modules … (front 50 step 6)
$ botopink dev            # o botopink não tem comando de framework
```

- [ ] **(a)** `onze.json` e `onze dev | build | start | create`.
  ```text
  onze.json: { "trailingSlash": "never", "islands": { "props": "sealed" } }
  $ onze dev
  $ onze build && onze start
  ```
- [ ] **(b)** Um `bpp.json` e `botopink dev` / `botopink preview` no CLI do compilador.
  ```text
  bpp.json: { "trailingSlash": "never" }
  $ botopink dev
  $ botopink preview
  ```

**Recomendação: (a).** O CLI do compilador não é o de um framework. **Bloqueia:** 124.

### props-d · Os atributos de uma tag nativa *(proposta)*

**Contexto.** A 192 fez dos atributos de uma tag de componente os campos de um record de props, checados
pelo tipo. Ela cobre só tags de componente. Uma tag nativa (`<a>`, `<div>`) hoje é uma função do
jhonstart `fn <tag>(children: Children, attrs: Array<#(string, string)> = [])` — qualquer nome, qualquer
string, nenhum erro.

**Hoje:**
```bp
<a href={url} tabindex="x">…</a>     // compila: todo atributo é um par (string, string)
```

- [ ] **(a)** Os atributos de uma tag nativa são os campos de um tipo de props que o jhonstart declara por
  elemento (atributo desconhecido ou de tipo errado é recusado, como na 192).
  ```bp
  <a href={url} tabindex="x">…</a>    // error: `tabindex` espera i32, recebeu string
  <a hreff={url}>…</a>                // error: `<a>` não tem o atributo `hreff`
  ```
- [ ] **(b)** Qualquer nome de atributo, valor `string` ou um buraco da 191.
  ```bp
  <a href={url} tabindex="x" hreff="y">…</a>    // compila
  ```
- [ ] **(c)** Um conjunto global de atributos mais listas por tag, valores `string`.
  ```bp
  <a href={url} tabindex="x">…</a>    // compila: tabindex é global, valor string
  <a colspan="2">…</a>                // error: `colspan` não é atributo de `<a>`
  ```

**Recomendação: (a)** — uma regra para toda tag, a mais restritiva. **Bloqueia:** 118 passos 1 e 4.

### props-e · Slot nomeado *(proposta)*

**Contexto.** A 193 nomeia só o campo `children` (o conteúdo entre as tags). O Astro tem slots nomeados:
`<p slot="footer">` no uso e `<slot name="footer">` no componente. Como a 192 já faz dos atributos campos
de um record, um campo do tipo `Node` já pode carregar marcação; a pergunta é se existe um segundo
mecanismo.

**Hoje:**
```bp
<Card>corpo</Card>                              // o conteúdo vai para `children` (193)
<Card>corpo<p slot="footer">rodapé</p></Card>   // `slot` é só mais um atributo do <p>; nada o encaminha
```

- [ ] **(a)** Um slot nomeado é um campo de props do tipo `Node`, escrito como atributo.
  ```bp
  type Props(children: Children, footer: Node)
  <Card footer={<p>rodapé</p>}>corpo</Card>      // `slot="…"` recusado
  ```
- [ ] **(b)** `slot="footer"` num filho o encaminha para o campo `footer`.
  ```bp
  <Card>corpo<p slot="footer">rodapé</p></Card>  // o <p> vai para props.footer
  ```
- [ ] **(c)** Sem slots nomeados — só `children`.
  ```bp
  <Card>corpo<p>rodapé</p></Card>                // o rodapé é parte de children
  ```

**Recomendação: (a)** — a 192 já cobre, sem um segundo mecanismo de encaminhamento. **Bloqueia:** as
caixas de slot da 118 (passos 1 e 4).

### props-f · Spread num componente *(proposta)*

**Contexto.** O passo 1 da 118 recusa `{...expr}` num componente por um motivo que a 192 removeu: os
atributos agora são campos de um único record, então espalhar um record de props seria tecnicamente
simples. A 118 § Notes ainda lista o spread de props em "O que não entra".

**Hoje:**
```bp
<Card {...p} featured />     // error: spread recusado num componente (118 passo 1)
```

- [ ] **(a)** Continua recusado: os atributos são a forma.
  ```bp
  <Card title={p.title} date={p.date} featured />
  ```
- [ ] **(b)** `{...p}` com `p` do tipo de props, atributos explícitos sobrescrevendo.
  ```bp
  <Card {...p} featured />     // ok: os campos de p; `featured` sobrescreve p.featured
  ```

**Recomendação: (a).** Uma grafia só para passar props, cada atributo visível onde a tag é escrita.
**Bloqueia:** 118 passo 1.

### 03r-ab · Front 09: stores de protocolo binário

**Contexto.** A frente 09 dá ao `rakun-data` os stores escolhidos pela URL (`RAKUN_DATA_URL`). ETS e
Mnesia estão dentro da VM; Redis é RESP sobre `gen_tcp`; Elasticsearch é HTTP + JSON. MongoDB, Neo4j
(`bolt://`), Cassandra e Couchbase são protocolos binários: precisam de um tipo byte (`lg2-a`) e de
drivers OTP que um sidecar não carrega. Os passos 4 e 7 têm 12 caixas para esses quatro.

**Hoje:**
```text
RAKUN_DATA_URL=mongodb://localhost/app
# 09 passos 4 e 7: 12 caixas abertas para mongodb://, bolt://, cassandra://, couchbase://
# nenhum cliente binário existe, nem tipo byte na linguagem (lg2-a)
```

- [ ] **(a)** Quatro braços no gate (`ets:memory`, `mnesia:local`/`mnesia:cluster`, `redis://`,
  Elasticsearch por HTTP), com a suíte de comportamento contra os quatro; os binários são esquemas
  reconhecidos que recusam o boot, e as 12 caixas viram as células de recusa mais uma linha de
  `deferred.md` cada.
  ```text
  RAKUN_DATA_URL=mongodb://localhost/app
  boot refused: `mongodb://` needs a byte type (lg2-a) and the mongodb driver
  ```
- [ ] **(b)** Escrever Mongo, Bolt, Cassandra e Couchbase em sidecars Erlang — quatro clientes de
  protocolo, uma frente cada.
  ```text
  src/sidecars/rakun_mongo.erl  rakun_bolt.erl  rakun_cassandra.erl  rakun_couchbase.erl
  RAKUN_DATA_URL=mongodb://localhost/app   → conecta
  ```
- [ ] **(c)** Adiar o 09 inteiro.
  ```text
  deferred.md: | 04-rakun/09 | stores do rakun-data (ETS, Mnesia, Redis, Elasticsearch, binários) | adiada |
  ```

**Recomendação: (a)** — nunca cair para ETS debaixo de uma URL do Mongo; o braço Elasticsearch sem aresta
para o `rakun-client` (ver `ctr-w`). **Bloqueia:** 09 passos 4 e 7.

### 03r-ae · SAML 2.0 ACS

**Contexto.** O ACS é o endpoint do service provider SAML que recebe a assertion assinada do provedor de
identidade. Verificar essa assinatura exige Exclusive XML Canonicalisation (exc-c14n), que nem o `xmerl`
do OTP nem o std têm. Por isso o `saml2/saml2.bp` responde 501, e as três caixas do passo 3 da 79 seguem
abertas.

**Hoje:**
```bp
// modules/rakun-security/src/saml2/saml2.bp
return rkRegisterRoute("POST", "/saml2/acs", { req -> Response.withStatus(501, acsNotImplemented()) });
```

- [ ] **(a)** Implementar Exclusive C14N no sidecar (`rakun_saml2.erl`, ~300 linhas, sobre a árvore do
  `xmerl`) e fechar as três caixas com uma assertion assinada por uma chave versionada.
  ```text
  src/sidecars/rakun_saml2.erl      exc_c14n/1 sobre a árvore do xmerl
  test: POST /saml2/acs  (assertion de fixture assinada pela chave versionada) → 302, sessão criada
        a mesma assertion com um byte trocado                                  → 401
  ```
- [ ] **(b)** Aposentar o SP: `POST /saml2/acs` continua respondendo 501, com linha em `deferred.md`.
  ```text
  POST /saml2/acs → 501 (acsNotImplemented)
  deferred.md: | 04-rakun/79 | SAML 2.0 ACS: exc-c14n | adiado |
  ```
- [ ] **(c)** Deixar as três caixas abertas — não recomendado.
  ```text
  79 passo 3: [ ] [ ] [ ]   # sem prazo, sem linha em deferred.md
  ```

**Recomendação: (a)** — a 79 está no grupo A do rakun, então está escalada neste milestone; **(b)** só
se ela sair dele. Nunca a (c). **Bloqueia:** 79 passo 3.

### 03r-af · Os sete projetos de exemplo nunca construídos

**Contexto.** A lista de exemplos da 1.0.10 tinha dez projetos; só três existem em `examples/`
(`rakun`, `rakun-container`, `rakun-ssr`), e são células do gate. Os outros sete nunca começaram, e o
contrato de cada membro já é afirmado pelos testes do próprio membro — os exemplos não provariam nada
novo.

**Hoje:**
```text
$ ls examples/
rakun  rakun-container  rakun-ssr
# rest-service, secured-api, blog-server, order-pipeline, observed-service, realtime-gateway, release-kit: nunca começados
```

- [ ] **(a)** Aposentar `rest-service`, `secured-api`, `blog-server`, `order-pipeline`,
  `observed-service`, `realtime-gateway`, `release-kit` (a lista da 1.0.10 vira registro fechado); os três
  em disco ganham `README.md`.
  ```text
  examples/rakun/README.md  examples/rakun-container/README.md  examples/rakun-ssr/README.md
  ```
- [ ] **(b)** Construir os sete, uma frente cada, depois de todas as frentes de membro.
  ```text
  examples/rest-service/  examples/secured-api/  …  examples/release-kit/   # 7 frentes novas
  ```
- [ ] **(c)** Construir só o `rest-service`, como passeio no estilo Spring.
  ```text
  examples/rest-service/src/main.bp     # controller, service, repository, testes com MockMvc
  ```

**Recomendação: (a).** O contrato de cada membro já é afirmado pelos testes do próprio membro; sete frentes
de exemplo não provariam nada novo. **Bloqueia:** 73 passo 3.

### 03r-ak · Validar o SBOM contra o schema CycloneDX 1.5

**Contexto.** O release do rakun gera um SBOM (lista de componentes) em CycloneDX. A caixa do passo 3 da
81 pede validá-lo contra o schema CycloneDX 1.5 versionado no repositório, sem rede. O std não tem
validador de JSON Schema, então hoje o teste afirma alguns campos pelo nome.

**Hoje:**
```bp
// modules/rakun-release/test/release_test.bp
assert empty.contains("\"bomFormat\":\"CycloneDX\"") && empty.contains("\"specVersion\":\"1.5\"") && empty.contains("\"components\":[]"), empty;
```

- [ ] **(a)** Validador no teste: percorre o SBOM contra os `required` e os `type` do
  `bom-1.5.schema.json` versionado (só definições locais, ~120 linhas).
  ```bp
  val schema = try json.decode(fs.readText("bom-1.5.schema.json"));
  asserts.equals(validateRequiredAndTypes(schema, sbom), []);     // ~120 linhas: `required` e `type`
  ```
- [ ] **(b)** Trocar a caixa por uma lista de campos afirmados pelo nome.
  ```text
  81 passo 3: "o SBOM tem bomFormat, specVersion, metadata.component, components[].{name,version,purl}"
  ```
- [ ] **(c)** Um `json.schema` no std.
  ```bp
  import {schema} from "std";
  asserts.equals(schema.validate(try json.decode(fs.readText("bom-1.5.schema.json")), sbom), []);
  ```

**Recomendação: (a).** Valida contra o schema de verdade, sem rede, sem afrouxar a caixa e sem pôr no
std um validador genérico por causa de um consumidor só. **Bloqueia:** 81 passo 3.

### 03r-al · Transações de produtor Kafka

**Contexto.** O passo 5 da 15 pede o outbox publicando dentro de uma transação de produtor Kafka, lida
por um consumidor `read_committed`. A pergunta original supunha que o broker em processo não tinha
transação.

> **Medido na consolidação:** o broker em processo **já tem** transação de produtor com `read_committed`
> (e o termo de nomes de listener). A premissa da pergunta ("o broker não tem transação") está
> errada; o que sobra é amarrar o outbox ao `withProducerTransaction` (passo 5 da 15).

**Hoje:**
```text
modules/rakun-messaging/src/reliability/transaction.bp   withProducerTransaction — read_committed segura e descarta, testado
15 passo 5, duas caixas abertas: "with a Kafka broker", "a consumer in read_committed mode"
```

- [ ] **(a)** Usar a transação que o broker em processo já tem; as caixas passam a dizer "o dublê de
  broker".
  ```bp
  val tx = broker.beginTx(); broker.publish(tx, "orders", msg);
  asserts.equals(consumer.poll(), []);       // read_committed: nada antes do commit
  broker.commitTx(tx);
  ```
- [ ] **(b)** Apagar as duas caixas.
  ```text
  15 passo 5: - [ ] with a Kafka broker                     ← removida
              - [ ] a consumer in read_committed mode       ← removida
  ```
- [ ] **(c)** Deixá-las abertas até haver um broker real — não recomendado.
  ```text
  15 passo 5: [ ] [ ]   # esperando um Kafka de verdade no gate
  ```

**Recomendação: (a)**; o broker real vira linha em `deferred.md`. **Bloqueia:** 15 passo 5.

### 03r-am · Onde moram os dublês de broker e scheduler

**Contexto.** Os testes precisam de dublês (implementações falsas) do broker de mensagens e do
scheduler. O `rakun-test` depende só do `rakun`, e os testes do `rakun-messaging` importam o
`rakun-test`; pôr os dublês no `rakun-test` cria a aresta `rakun-test → rakun-messaging`, que é um ciclo
de pacotes — a não ser que o loader trate `<lib>-test` como escopo de teste, o que não foi verificado.

**Hoje:**
```json
// modules/rakun-test/botopink.json
"dependencies": { "rakun": { "workspace": true } }
// e modules/rakun-messaging/test/*.bp importam rakun-test
```

- [ ] **(a)** Medir primeiro: acrescentar a aresta; se o `botopink test` recusar o ciclo, os dublês
  ficam ao lado do módulo que dublam e o `rakun-test` os documenta.
  ```text
  rakun-test/botopink.json  + "rakun-messaging"
  $ botopink test            # em modules/rakun-messaging
  ciclo recusado → os dublês ficam em rakun-messaging/src/broker_double.bp e rakun-scheduling/src/task_double.bp
  ```
- [ ] **(b)** Acrescentar a aresta supondo que o loader já trata `<lib>-test` como escopo de teste.
  ```json
  "dependencies": { "rakun": { "workspace": true }, "rakun-messaging": { "workspace": true } }
  ```
- [ ] **(c)** Dublês no `rakun-test` alcançando os registries só por hooks do core (`rkOnReset`, o termo
  de nomes de listener), sem importar o messaging.
  ```bp
  // modules/rakun-test/src/broker_double.bp
  rkOnReset({ -> brokerDoubleClear() });
  ```

**Recomendação: (a)**, com a forma (c) em qualquer caso. **Bloqueia:** 19 passos 3 e 4.

### 03r-an · O transporte WebSocket do RSocket depois da 187 *(proposta)*

**Contexto.** O transporte WebSocket do RSocket monta pelo `#[wsEndpoint]` do `rakun-websocket`. Depois
da 187 o RSocket mora no `rakun-messaging`, então a aresta `rakun-messaging → rakun-websocket` carregaria
a árvore do `rakun-websocket` (security, data) para todo consumidor de messaging. Hoje o transporte
WebSocket é recusado no boot (só TCP).

**Hoje:**
```text
rakun.rsocket.server.transport=websocket
rakun rsocket: rakun.rsocket.server.transport=websocket needs front 20's mount at the mapping path, which is not wired - use tcp
```

- [ ] **(a)** Aceitar a aresta `rakun-messaging → rakun-websocket`.
  ```json
  // modules/rakun-messaging/botopink.json
  "dependencies": { …, "rakun-websocket": { "workspace": true } }   // security e data vêm junto
  ```
- [ ] **(b)** O core define um ponto de extensão de transporte, em que o `rakun-websocket` se pluga (a
  regra da 185: capacidade opcional pelo core, nenhuma aresta entre membros).
  ```bp
  // rakun-websocket, no boot:
  rkRegisterTransport("websocket", { path, handler -> wsMount(path, handler) });
  // rakun-messaging só pede rkTransport("websocket"); sem o rakun-websocket, a recusa de hoje
  ```
- [ ] **(c)** Manter a recusa; transporte WebSocket vira linha em `deferred.md`.
  ```text
  deferred.md: | 04-rakun/92 | RSocket sobre WebSocket | adiado |
  ```

**Recomendação: (b).** **Bloqueia:** a primeira caixa do passo 2 da 92.

### 50-b · O que o `onze dev` faz numa mudança

**Contexto.** O `onze build` compila o servidor para BEAM (`server/beam/`) e o `onze start` roda
`erl -noshell -pa <outDir>/server/beam -eval …` (50-a). O `onze-bundler/src/rebuild.bp` já calcula os
módulos invalidados, e a BEAM sabe `code:load_file/1`; o registro de UI e a tabela de rotas se preenchem
no load do módulo (decisão 140), então uma página recarregada se registra de novo, mas um arquivo de
rota novo exige regenerar o `onze_routes.bp`. O estado das islands no navegador se perde em qualquer
opção (Fast Refresh não é objetivo).

**Hoje:**
```text
$ onze dev        # e você salva app/blog/page.bp
onze dev: not available yet - it serves the build `onze start` serves and reloads the changed modules into the running node, and the reload is not written (front 50 step 6)
```

- [ ] **(a)** Reinicia o nó: `build` + `start` em laço sobre um observador de arquivos, 1–3 s por edição;
  serve os mesmos bytes que o `start`.
  ```text
  $ onze dev
  app/blog/page.bp mudou → onze build (1.6 s) → nó reiniciado → http://localhost:3000
  ```
- [ ] **(b)** Hot-load: `code:load_file` do módulo mudado, sem reiniciar; um arquivo de rota novo exige
  regenerar o `onze_routes`.
  ```text
  app/blog/page.bp mudou   → code:load_file(app_blog_page)          (~100 ms)
  app/about/page.bp criado → onze_routes.bp regenerado e recarregado
  ```
- [ ] **(c)** (b), caindo para (a) quando muda um arquivo de convenção (`page`, `layout`, `route`).
  ```text
  src/lib/format.bp mudou → code:load_file(format)
  app/blog/page.bp mudou  → reinicia o nó (como a)
  ```

**Recomendação: (a)**, a mais restritiva: um caminho de código só, os mesmos bytes que o `start` serve;
(b) depois, se (a) medir lento demais no blog. **Bloqueia:** 50 passo 2; 53 passo 6 ("`dev` serve toda
rota" — a spec inglesa ainda diz passo 5).

### std-d · `io.process`: sinais e leitor de TTY

**Contexto.** O `io/process.bp` do std não registra nem repassa sinal, e o std não tem leitor de linha
do terminal. Consequência no onze: o `onze start` espera o `process.run`, então um `SIGTERM` mata o
`bin/onze` e deixa o nó rodando; e o `onze create` sem `--yes` não tem prompt para onde cair. A pergunta
é se o std ganha essas três funções host (em dois targets) ou se o onze contorna.

**Hoje:**
```text
$ onze start &  ;  kill -TERM %1
# o bin/onze sai; o nó erl continua rodando
$ onze create
# sem --yes: não há leitor de TTY para perguntar o nome do projeto
```

- [ ] **(a)** O std ganha as três células: `process.onSignal(name, fn)`, `process.forwardSignals(child)`,
  `io.stdin.readLine()`.
  ```bp
  process.forwardSignals(child);
  val name = io.stdin.readLine();           // `onze create` pergunta o nome do projeto
  ```
- [ ] **(b)** Nada no std.
  ```text
  $ onze start            # faz exec do node: o bin/onze é PID 1 e recebe o SIGTERM direto
  $ onze create           # sem --yes:
  error: `onze create` needs --name and --template (or --yes)
  ```

**Recomendação: (b)**, a mais restritiva. **Bloqueia:** onze 50 passos 4 e 7; 97 passo 6 (condicional).

### 67-a · Onde as caixas de forms do lado do DOM são afirmadas

**Contexto.** Cinco caixas de forms do jhonstart (as 3a, 3b, 4, 5 da 1.0.10: `fieldError` depois do
`__jhFormState`, re-render no lugar com `ok: false`, o `pending` de dois forms, commit / rollback
otimista) leem `document` e `FormData`. O `botopink test` não tem DOM; o `jhonstart-dom-test`
(`fake_dom.mjs`, só commonJS) já serve a metade de navegador do render.

**Hoje:**
```text
modules/jhonstart-dom-test/src/fake_dom.mjs   # documento falso: sem <form>, <input>, FormData, submit
67 passos 1–3: cinco caixas de forms sem lugar para rodar
```

- [ ] **(a)** No gate do próprio jhonstart, com o documento falso estendido (`<form>`, `<input>`,
  `FormData`, `submit`). E de novo no browser do onze 53.
  ```bp
  // jhonstart-dom-test/test/forms_dom_test.bp
  val form = dom.form("signup"); form.submit();
  asserts.equals(dom.text("#email-error"), "invalid email");
  ```
- [ ] **(b)** Só no browser do onze 53: o gate do jhonstart nunca roda essas cinco caixas.
  ```text
  onze 53 (E2E no navegador): submit em /signup → "#email-error" == "invalid email"
  $ botopink test   # no jhonstart: nenhuma das cinco roda
  ```
- [ ] **(c)** Uma lib de DOM real como dependência de dev.
  ```json
  // jhonstart-dom-test/package.json
  "devDependencies": { "jsdom": "…" }
  ```

**Recomendação: (a).** As caixas rodam no gate da biblioteca dona, onde quebram primeiro, sem dependência
nova; o navegador do onze 53 confere de novo. **Bloqueia:** a forma dos passos 1–3 da 67 (escritos para a (a)); o caminho de
escrita do onze 53.

### 05emilia-n · As linhas do Tailwind sem dono

**Contexto.** Cinco linhas da referência do Tailwind não têm dono: formas nomeadas de `:has()` / `:not()`
/ ARIA / data / `in-[…]` (hoje só via `arbSel`); grupos e peers nomeados; `@theme inline`; translate
negativo (`TranslateX/Y.Neg` não existe); e um buraco — um `--breakpoint-*` limpo no tema emite
`@media (width >= )` em vez de recusar, como a 58 já recusa um tamanho de container esvaziado.

**Hoje:**
```text
theme: --breakpoint-md limpo   → hoje emite `@media (width >= )`
```

- [ ] **(a)** Só a recusa: `panic: breakpoint "md" was cleared`; as quatro features ficam fora (em
  `docs.md` § Deviations) e se escrevem com `arbSel("…")`.
  ```bp
  [.Md.Flex]                         // com --breakpoint-md limpo: panic: breakpoint "md" was cleared
  arbSel(":has(> img)", [.Flex])     // a forma nomeada fica fora; escreve-se pelo seletor arbitrário
  ```
- [ ] **(b)** (a) + translate negativo e grupos/peers nomeados.
  ```bp
  [.TranslateY.Neg.2]            // -translate-y-2
  [.Group.Named("item").Hover]   // group-hover/item
  ```
- [ ] **(c)** As cinco, inclusive `@theme inline` (um segundo modo de render em todo site de `var()`).
  ```text
  @theme inline { --color-brand: var(--acme-pink); }
  → .bg-brand{background-color:var(--acme-pink)}   (em vez de var(--color-brand))
  ```

**Recomendação: (a)**; (b) se você quiser alguma feature. A recusa em si não é opcional (decisão 67).
**Bloqueia:** 34 passo 4 (condicional); o passo 3 (a recusa) não é condicional.

### 07-g · Renderização de release OTP

**Contexto.** Hoje `rakun-release/release.bp` (depois do 128, `rakun-cli/src/release/`) e
`onze-release/otp.bp` escrevem o mesmo `.rel` / `vm.args` / `sys.config` / script de boot / Dockerfile,
cada um com o seu código. O onze não pode reusar o do rakun (o rakun é só erlang; o onze-release também
compila para commonJS). Uma correção no formato hoje precisa ser feita duas vezes.

**Hoje:**
```bp
// rakun/modules/rakun-release/src/release.bp
pub fn renderRel(r: Release) -> string
pub fn renderVmArgs(r: Release) -> string
// onze/modules/onze-release/src/otp.bp
pub fn relFileText(spec: ReleaseSpec) -> string
pub fn vmArgsText(spec: ReleaseSpec) -> string
```

- [ ] **(a)** Um bundled `release` de renderizadores puros.
  ```bp
  import {rel, vmArgs, sysConfig} from "release";
  fs.writeText(path.join([out, "onze.rel"]), rel(spec));
  ```
- [ ] **(b)** Feature do CLI: `botopink release --out dist/`.
  ```text
  $ botopink release --out dist/
  dist/releases/0.1.0/onze.rel  dist/releases/0.1.0/vm.args  dist/releases/0.1.0/sys.config
  ```
- [ ] **(c)** Deixar os dois como estão.
  ```text
  rakun: renderRel(r)       onze: relFileText(spec)     # duas cópias, cada correção feita duas vezes
  ```

**Recomendação: (a)** — uma cópia só, que serve aos dois frameworks nos dois targets; o CLI pode adotar o
pacote depois. **Bloqueia:** 107-release (frente condicional:
responder ou adiar a 107).

### 07-j · Quanto do Zod entra na 125

**Contexto.** A frente 125 traz para a `validation` a superfície do Zod (validação por schema).
`125-validation-zod/surface.md` tem 205 linhas de referência — 27 já são a linguagem ou a biblioteca, 151
dá para construir com o decorador e a reflexão que existem, 7 precisam de uma linha do compilador, 18 não
fazem sentido aqui. Os passos 0–2 (`Schema<T>`, `#[schema]`, `parse<T>`) já estão na `feat`; a pergunta
é o tamanho do resto (passos 3–10).

**Hoje:**
```bp
#[schema] type Signup(email: string, password: string)
val s = try parse<Signup>(json);           // passos 0–2, já na feat
```

- [ ] **(a)** Só os marcadores (passo 3).
  ```bp
  type Signup(#[email] email: string, #[min(8)] password: string)
  ```
- [ ] **(b)** Marcadores + `parse<T>` de records planos (passos 0–3).
  ```bp
  #[schema] type Signup(#[email] email: string, #[min(8)] password: string)
  val s = try parse<Signup>(json);
  ```
- [ ] **(c)** Tudo: uniões, tuplas, mapas, coerção, transforms, codecs, `jsonSchemaOf<T>`.
  ```bp
  val form = try bind<Signup>(pairs);            // de pares de formulário
  val schema = jsonSchemaOf<Signup>();
  ```

**Recomendação: (c)**, na ordem dos passos (e com as saídas como membros, ver `ctr-u`:
`Signup.parse(input)`). **Bloqueia:** o tamanho da 125 (passos 3–10).

- [ ] Confirmo a recomendação em todas desta parte
- [ ] Quero rever: ___

---

---

### cardume (frente 136)

### atm-a · Nomes dos hooks: substantivos, ou os verbos da 295 *(proposta)*

**Contexto.** A regra do jhonstart (no cabeçalho do `hooks.bp`) diz que hook é **substantivo** e que o
`use` é quem ativa: `use state(0)`, `use memo(…)`. O rascunho do cardume segue isso (`atomValue`,
`atomSetter`). Mas a 295 escreveu **verbos**: `use setLocal(atom)`, `use setCookie(decl)`.

**Hoje:**
```bp
val setUser = use setLocal(currentUser);       // 295: verbo
val setItems = use atomSetter(cartItems);      // cardume: substantivo
```

- [ ] **(a)** Substantivo em tudo; os nomes da 295 acompanham.
  ```bp
  val setUser = use atomSetter(currentUser);      // ou por tipo (297): use atomSetter(User)
  val setSession = use cookieSetter(sessionCookie);
  ```
- [ ] **(b)** Verbo para quem escreve, substantivo para quem lê: `use setAtom(a)`, `use setCookie(c)`,
  `use atomValue(a)`.
- [ ] **(c)** Cada lib com o seu.

**Recomendação: (a)** — uma regra só, que já é a do jhonstart.
**Bloqueia:** 136 passos 1 e 7; 123; 127; `07-onze/53`.

### atm-c · O `T` de um átomo entre servidor e browser *(proposta)*

**Contexto.** O servidor manda para cada ilha os valores dos átomos que ela leu, para o browser começar
igual (136 passo 6). Para atravessar, o valor precisa ser serializável (`encode<T>`, 125). Mas há estado
que só existe no browser, como uma referência a um elemento ou uma função.

**Hoje:**
```bp
pub val cartItems = atom<Item[]>([]);            // serializável: atravessa
pub val mapHandle = atom<?MapInstance>(null);    // só existe no browser
```

- [ ] **(a)** Todo átomo precisa ter `T` serializável, conferido na declaração.
- [ ] **(b)** Qualquer `T`; no build, confere-se o que cada ilha lê: um átomo não serializável lido por
  uma ilha precisa ser declarado só para o browser.
  ```bp
  pub val mapHandle = clientAtom<?MapInstance>(null);   // nunca atravessa; o servidor lê o padrão
  ```
- [ ] **(c)** Qualquer `T`, recusado só em runtime.

**Recomendação: (b)** — restritivo onde importa (o que atravessa) e livre no resto.
**Bloqueia:** 136 passo 6.

### atm-d · Quais efeitos de átomo entram *(proposta)*

**Contexto.** No Recoil, um átomo pode ter "efeitos": salvar no `localStorage`, sincronizar com a URL,
receber atualização do servidor. Aqui ainda não existe nenhum.

**Hoje:** nenhum.

- [ ] **(a)** Nenhum na primeira versão.
- [ ] **(b)** Só salvar no browser.
  ```bp
  pub val cartItems = atom<Item[]>([], effects: [persistLocal("cart")]);
  ```
- [ ] **(c)** Salvar no browser e sincronizar com a URL (`syncSearchParam("tab")`).

**Recomendação: (a)** — primeiro a store; efeitos num passo próprio quando houver uso medido.
**Bloqueia:** 136 passo 8.

## Parte 4 — Não bloqueiam nada hoje

Regras para o próximo caso, confirmações e recursos de linguagem que ficam de fora por padrão.

### 07-b · "Uma lib, três cópias divergentes" também justifica pacote?

**Contexto.** A decisão 115 diz quando um código vira pacote *bundled* (distribuído junto com o
compilador, importado sem nenhuma linha em `dependencies`): quando duas ou mais bibliotecas carregam
cópias dele. No rakun existem três leitores do cabeçalho `Cookie:` que divergem entre si, todos
dentro do próprio rakun. A pergunta é se "três cópias divergentes numa lib só" também abre um pacote.
No caso do cookie (e do q-value) nada muda: o onze também consome essas cópias, então elas já passam
no teste da 115 — a resposta vale para o próximo candidato.

**Hoje:**
```bp
// rakun: request_context.bp · csrf.bp · session_cookie.bp
// três leitores de `Cookie:`, só dentro do rakun, cada um com seu jeito de tratar `;` e aspas
import {cookie} from "http";      // o pacote `http` da decisão 104 já existe (o onze também usa)
```

- [ ] **(a)** Não: vale só "duas ou mais libs" (decisão 115) — a duplicata numa lib só vai para o core dela (ou para o std).
  ```bp
  // as três cópias viram um módulo do core do rakun
  import {cookie} from "rakun";
  ```
- [ ] **(b)** Sim: três cópias divergentes numa lib só já abrem um pacote bundled, mesmo com um único consumidor.
  ```bp
  import {cookie} from "http";      // pacote novo do compilador, mesmo que só o rakun o use
  ```

**Recomendação: (a).** Pacote bundled novo continua exigindo dois consumidores; a cópia de uma lib
só se resolve dentro dela, sem abrir pacote (decisão 67: a regra mais restritiva). **Bloqueia:**
nada — é a regra para o próximo candidato (o `http` da 104 já existe e o rakun passa a usá-lo no
passo 5 dela).

### 07-h · Bundled, ou um repositório compartilhado à parte?

**Contexto.** Os formatos de fio que o rakun e o onze precisam concordar byte a byte (cookie,
cabeçalhos HTTP) podem morar num pacote *bundled* — que viaja com o compilador e tem a versão dele —
ou num repositório separado, com cadência própria. Um repositório separado é uma dependência git, e
hoje isso esbarra em duas regras: a `lg2-v` (dependência git não tem `subdir`) e a decisão 242 (só
uma dependência direta é importável — cada app teria de listá-lo). A trilha já foi cortada como (a).

**Hoje:**
```bp
// botopink.json do app: nenhuma linha para "http"
import {cookie} from "http";      // resolve para o pacote bundled; versão = a do compilador
```

- [ ] **(a)** Bundled — versionado com o compilador, sem entrada em `dependencies`.
  ```bp
  import {cookie} from "http";      // nada a instalar; atualiza quando o compilador atualiza
  ```
- [ ] **(b)** Repositório compartilhado `botopink/common`, com cadência própria — cada app lista a dependência (decisão 242).
  ```json
  "dependencies": {
    "http": { "git": "git@github.com:botopink/common.git", "subdir": "http" }   // precisa do lg2-v (2)
  }
  ```

**Recomendação: (a).** Fios que dois frameworks precisam concordar byte a byte saem com o compilador
que os embute; a (b) depende de abrir a `lg2-v`, que fica fechada. **Bloqueia:** nada hoje — a trilha
já está cortada como (a); escolher (b) reabriria a forma da trilha.

### std-e · Hooks de ciclo de vida de teste

**Contexto.** O `rakun-test` tem `resetSingletons` / `resetContext`, chamados à mão em mais de 40
corpos de teste; o `jhonstart-dom-test` instala o documento do mesmo jeito. A pergunta é se o runner
deve chamar algo automaticamente antes/depois de cada `test`. Na prática: com hooks, um teste deixa
de mostrar no próprio corpo o estado de que parte.

**Hoje:**
```bp
test "a" { resetSingletons(); … }
test "b" { resetSingletons(); … }      // esquecer a linha = estado vazado do teste anterior
```

- [ ] **(a)** Sem hooks (hoje): o corpo do teste chama o helper de reset.
  ```bp
  test "a" { resetSingletons(); … }
  test "b" { resetSingletons(); … }
  ```
- [ ] **(b)** Decorators `#[before]` / `#[after]` numa fn de módulo, que o runner chama em volta de todo `test`.
  ```bp
  #[before] fn setup() { resetSingletons(); }
  #[after]  fn teardown() { resetContext(); }
  test "a" { … }
  ```
- [ ] **(c)** Bloco na gramática.
  ```bp
  beforeEach { resetSingletons(); }
  afterEach  { resetContext(); }
  test "a" { … }
  ```

**Recomendação: (a).** Nada implícito roda em volta de um teste; o que ele precisa está escrito nele.
**Bloqueia:** só a linha "No test lifecycle hooks" do `language-gaps.md`, que fica como está.

### 95-f · A tomada do onze aconteceu sem o branch órfão e sem arquivar nada

**Contexto.** A decisão 79 previa que o nome `onze` passasse da antiga biblioteca de mocking para o
orquestrador por meio de um branch órfão, arquivando o histórico antigo. O que aconteceu:
`repository/onze` é o workspace do orquestrador, construído em cima da tag `mocking-lib-final`, no
mesmo histórico e no mesmo remoto; nada foi arquivado nem renomeado, e o nome já resolve só para os
membros do orquestrador. A thread ficou com (1) porque o resultado prático é o mesmo e reescrever o
remoto obrigaria todo checkout a reclonar. Responder (1) gera uma decisão nova que emenda a 79.

**Hoje:**
```
$ git -C repository/onze tag            → mocking-lib-final     # a lib antiga vive como histórico tagueado
$ git -C repository/onze log --oneline  → o orquestrador em cima dessa tag, mesmo remoto
```

- [ ] **(1) ★** Confirmar a árvore como está — uma decisão nova emenda a 79: a lib antiga é o histórico tagueado do mesmo repositório.
  ```
  $ git -C repository/onze checkout mocking-lib-final   # quem precisar da lib antiga, lê a tag
  $ git -C repository/onze pull                         # nenhum checkout precisa reclonar
  ```
- [ ] **(2)** Reescrever o remoto para o branch órfão e arquivar o histórico antigo, como a 79 escreveu.
  ```
  $ git -C repository/onze checkout --orphan main && git commit …
  $ git -C repository/onze push --force origin main      # todo checkout de repository/onze reclona
  ```

**Recomendação: (1).** O nome já é só do orquestrador e a lib antiga continua recuperável pela tag;
reescrever o remoto custa um reclone em todo lugar sem ganho. **Bloqueia:** as caixas de registro do
`02/98` (as quatro do passo 5 do 01-std e as duas primeiras do passo 2 do 95) fecham com (1).

### 07-i (revisão) · A proibição de nomes repetidos em pacotes bundled continua depois do alias?

**Contexto.** A decisão 163 proíbe um pacote bundled de exportar um nome que o std ou um framework já
exporta "até a linha do toolchain fechar". A decisão 170 (import que diz o módulo nunca é ambíguo;
alias quando o módulo precisa dos dois) é o que fecha essa linha. A pergunta é se, com o alias
disponível, a proibição ainda faz sentido. Na prática, nenhum pacote existente muda: os pacotes das
frentes 102 e 103 já escolheram nomes livres.

**Hoje:**
```bp
import {cookie} from "http";            // 102: o pacote se chama `cookie`, não `cookies` (o rakun exporta `cookies`)
import {deriveActionId} from "actions"; // 103: não `actionId`, que o `rakun-app` já exporta
```

- [ ] **(a)** Continua proibido: pacote bundled novo escolhe nome que não colide.
  ```bp
  import {cookie} from "http";          // o pacote se chama `cookie`, nunca `cookies`
  ```
- [ ] **(b)** Cai a proibição: o pacote usa o nome natural e quem importa os dois usa alias.
  ```bp
  import {cookies as httpCookies} from "http";
  import {cookies as rkCookies} from "rakun";
  ```

**Recomendação (desta revisão): (a).** Um pacote novo escolher um nome livre não custa nada, e o
alias fica para o caso em que o nome natural é do std (decisão 170). Vale também para o 103: o pacote
usa `deriveActionId`, porque o `rakun-app` já exporta `actionId`. **Bloqueia:** nada; as frentes 102
e 103 já escolheram nomes livres.

### 110-a · O `testing.asserts` no wasm, depois da regra estrita (decisão 146)

**Contexto.** A decisão 146 diz que uma função cujo corpo alcança uma função host sem versão para o
target é recusada na declaração, chamada ou não. Com isso, um programa wasm que importa
`testing.asserts` é recusado: quatro das 27 funções dele chegam a uma célula host (`canonical`,
`regexMatches`, `tryCatch`) que não tem versão wasm. A thread ficou com (1) porque nada no gate roda
asserções no wasm hoje e as outras saídas mudam API (2) ou exigem trabalho grande no backend wasm (3).

**Hoje:**
```bp
import {testing.asserts} from "std";      // --target wasm
// error: `canonical` has no `#[@External.<Target>(…)]` for the wasm backend — in `std/testing/asserts`, which this import links
```
```
deepEquals → canonical        matches → regexMatches        throws, throwsWith → tryCatch
usos nos repositórios: throwsWith 280 · throws 4 · deepEquals 2 · matches 1 · 133 arquivos importam o módulo
```

- [ ] **(1) ★ como está** — o `asserts` não é importável no wasm; duas células de linguagem viraram recusa fixada no wasm.
  ```bp
  // --target wasm: o import é recusado (erro acima); um programa wasm checa à mão
  if (soma(1, 2) != 3) @panic("soma(1, 2) != 3");
  ```
- [ ] **(2)** As quatro funções com célula host vão para um módulo próprio; as outras 23 voltam a importar no wasm. Muda a API do `asserts` (decisão 74) e o import de cada arquivo que usa as quatro.
  ```bp
  import {testing.asserts} from "std";            // equals, isTrue, contains… — importa no wasm
  import {testing.asserts_host} from "std";       // deepEquals, matches, throws, throwsWith — nome ilustrativo
  ```
- [ ] **(3)** As três células ganham versão wasm. Precisa de um leitor de `@External.Wasm` no backend (a decisão 238 já existe), de um motor de regex no prelude wasm para `regexMatches`, e de `@panic` capturável para `tryCatch` (hoje é `unreachable`).
  ```bp
  import {testing.asserts} from "std";            // --target wasm: compila
  try asserts.matches("abc", "a.c");              // regex do prelude wasm
  try asserts.throwsWith({ -> parse("x") }, "bad");  // @panic capturável no wasm
  ```

**Recomendação (da thread): (1) agora**; a (2) se o wasm precisar rodar asserções — é a única que
não espera a 05-wasm. **Bloqueia:** nada no gate; só o "std compila no wasm" do 05-wasm passo 5 / 97
passo 11.

### lg2-a … lg2-w · Recursos que as bibliotecas pediram e a linguagem não tem

Cada `lg2-*` é uma linha do [`language-gaps.md`](./language-gaps.md): um recurso que alguma
biblioteca pediu e que a linguagem não tem. A recomendação em todas é a **(1)**: o recurso fica de
fora e a forma mais próxima que já existe é o desenho. Nenhuma frente abre sobre uma delas até ser
respondida; a frente dona lista a linha em *Depends on* e segue com a forma mais próxima, marcada
`// LANGUAGE GAP:`. A **lg2-k** (reflexão comptime sobre o projeto) saiu daqui: foi respondida pelas
decisões 216 e 253 (`@TypeInfo.all`).

### lg2-a · Tipo byte

**Contexto.** Nenhum primitivo, tipo do std ou literal guarda bytes, e toda célula host (o código
Erlang/JS por trás de uma função `declare`) passa dados como `string`. Por isso `Socket.recv` devolve
UTF-8 quebrado num fluxo binário e não dá para escrever upload, download ou endpoint de imagem.
Custa: uploads, downloads, imagens; Mongo/Bolt/Cassandra/Couchbase e o plano de dados do Pulsar no
rakun.

**Hoje:**
```bp
val b: Bytes = "a";                       // type mismatch em todo target
val chunk = sock.recv();                  // string: bytes que não são UTF-8 chegam corrompidos
```

- [ ] **(1)** Sem tipo byte: um payload binário é recusado onde entra; nada lê bytes como texto.
  ```
  POST /upload   Content-Type: multipart/form-data
  → 415 Unsupported Media Type            // a frente 25 recusa na borda
  ```
- [ ] **(2)** `Bytes` com fronteira explícita: toda conversão é uma chamada que pode falhar, nenhuma implícita.
  ```bp
  val b = Bytes.fromUtf8("a");
  val s = try b.toUtf8();                 // toUtf8 -> @Result: bytes inválidos viram Error, não lixo
  ```
- [ ] **(3)** `string` também carrega bytes crus, como hoje.
  ```bp
  val frame: string = sock.recv();        // bytes crus dentro de uma string
  val n = frame.length();                 // conta caracteres, não bytes; UTF-8 quebrado passa calado
  ```

**Recomendação: (1).** Um payload binário é recusado onde entra, nunca lido com perda. Se você
escolher a (2): nenhuma conversão sem uma chamada que pode falhar; a (3) continua recusada.
**Bloqueia:** a linha "No byte or binary type"; rakun 01, 13, 15, 24, 25, 70, 71; `03r-ab`,
o plano de dados do Pulsar (adiado pela 274) (todos seguem com `string` + recusa 415 até a resposta).

### lg2-b · O que `@Task<T>` significa no BEAM

**Contexto.** No erlang e no beam, o corpo de uma Task roda até o fim no ponto em que ela é criada:
duas `async.delay(300, …)` criadas antes de qualquer `await` levam ≥ 600 ms (no commonJS, ~300 ms).
Concorrência no servidor existe hoje só pelo `std/async`, explícita: `async.runAll` recebe thunks
ainda não iniciados e roda um processo BEAM por thunk. A pergunta é se `@Task` deve prometer
sobreposição.

**Hoje:**
```bp
val a = async.delay(300, 1); val b = async.delay(300, 2);
await a; await b;                         // erlang/beam: ≥ 600 ms · commonJS: ~300 ms
```

- [ ] **(1)** Task é só "valor que ainda não chegou"; concorrência é o `async.runAll` explícito. O exemplo de cima continua 600 ms no BEAM, documentado.
  ```bp
  val r = await async.runAll([{ -> async.delay(300, 1) }, { -> async.delay(300, 2) }]);   // ~300 ms em todo target
  ```
- [ ] **(2)** Um escalonador por trás de `@Task` no BEAM (um processo por Task, `await` vira `receive`).
  ```bp
  val a = async.delay(300, 1); val b = async.delay(300, 2);
  await a; await b;                       // beam: passa a levar ~300 ms
  ```
- [ ] **(3)** `spawn` / `join` na linguagem.
  ```bp
  val h = spawn work();
  val v = join h;
  ```

**Recomendação: (1).** O tipo promete o valor, nada sobre sobreposição; a única forma concorrente
continua sendo a explícita (a leitura restritiva da decisão 120 da 1.0.10). **Bloqueia:** a linha
"`@Task<T>` lowers eagerly on erlang"; rakun 02, 23, 25, 28, 30, 60.

### lg2-c · Decorator que reescreve ou embrulha o corpo

**Contexto.** Um decorator lê a declaração como dado (`@Decl`) e só responde com as saídas da
decisão 216: membros, meta, tipos associados, entradas de catálogo. Nenhuma forma devolve um corpo
substituto — é a lacuna principal da trilha B do rakun, onde o Spring embrulharia o método
(`@Cacheable`, `@Transactional`, `@Retryable`). Hoje o rakun emite tipos proxy (`<Type>Tx`,
`<Type>Sec`) injetados pelo nome, e o `'use cache'` de uma fn vira o combinador
`cacheThrough(policy, keys, load)`.

**Hoje:**
```bp
#[cached] fn load(id: i32) -> User { … }
load(1);                                  // roda o corpo como escrito; o decorator não o embrulha
```

- [ ] **(1)** Não: o decorator emite um proxy ao lado e `load` continua fazendo o que está escrito.
  ```bp
  #[cached] fn load(id: i32) -> User { … }
  val u = loadCached(1);                  // proxy emitido ao lado: passa pelo cache
  val v = load(1);                        // continua indo direto ao corpo
  ```
- [ ] **(2)** O decorator recebe o corpo e devolve o que o substitui.
  ```bp
  fn cached(comptime decl: @Decl) { @replaceBody("return cacheThrough(policy, keys, { -> " + decl.body + " });"); }  // ilustrativo
  load(1);                                // passa pelo cache
  ```
- [ ] **(3)** Ganchos fixos (antes / depois / em volta), compostos pelo compilador.
  ```bp
  fn cacheHook(call: fn() -> User) -> User { return cacheThrough(policy, keys, call); }
  #[around(cacheHook)] fn load(id: i32) -> User { … }
  ```

**Recomendação: (1).** Ler uma declaração nunca muda o que ela faz; os tipos proxy que o rakun
entrega são o desenho. **Bloqueia:** a linha; rakun 06, 07, 08, 10, 12, 16, 83.

### lg2-d · Decorator que lê o corpo

**Contexto.** O handle `@Decl` traz kind, name, fields, variants, methods, returnType e annotations,
mas nenhum statement: `decl.body` dá `badkey` na anotação. A pergunta veio da saga do rakun 83, que
queria ler os passos (e suas compensações) do corpo da função. Sem isso, a saga é um valor montado à
mão.

**Hoje:**
```bp
fn saga(comptime decl: @Decl) { decl.body }      // {error,{badkey,body}}
```

- [ ] **(1)** Só assinaturas: a saga é um valor que pareia cada passo com sua compensação.
  ```bp
  val checkout = saga([step(charge, refund), step(ship, cancel)]);
  ```
- [ ] **(2)** `decl.body` como árvore de statements somente-leitura.
  ```bp
  fn saga(comptime decl: @Decl) { for (decl.body.statements) { s -> … } }
  ```
- [ ] **(3)** Uma API comptime de percorrer o corpo.
  ```bp
  fn saga(comptime decl: @Decl) { decl.walk({ stmt -> if (stmt.isCall("charge")) … }); }
  ```

**Recomendação: (1).** Um decorator lê assinaturas, não corpos; a saga do rakun 83 continua um valor.
**Bloqueia:** a linha; rakun 83.

### lg2-e · Dono e parâmetros num `@Decl` de método

**Contexto.** Num decorator aplicado a um método, `decl.owner` e `decl.params` dão `badkey`; só o
`@Decl` de um tipo lista os métodos com seus parâmetros (`decl.methods[i].params`). Por isso o rakun
faz o decorator do tipo (`#[restController]`) ler os marcadores dos métodos (`#[getMapping]`). A
pergunta é se o decorator de método deve enxergar o dono e os parâmetros diretamente.

**Hoje:**
```bp
type UserController { #[get("/u/:id")] fn show(self, id: i32) … }
fn get(comptime decl: @Decl, path: string) { decl.owner; decl.params }     // badkey
```

- [ ] **(1)** Marcador de método só marca; quem lê os parâmetros é o decorator do tipo.
  ```bp
  #[controller] type UserController { #[get("/u/:id")] fn show(self, id: i32) … }
  fn controller(comptime decl: @Decl) {
      for (decl.methods) { m -> … }       // m.annotations tem `get`; m.params tem `id: i32`
  }
  ```
- [ ] **(2)** `decl.owner` e `decl.params` existem no método.
  ```bp
  fn get(comptime decl: @Decl, path: string) {
      decl.owner.name;                    // "UserController"
      decl.params[0].typeName;            // "i32"
  }
  ```

**Recomendação: (1).** Nada novo chega a um decorator de método; o decorator do tipo já vê todos os
parâmetros. **Bloqueia:** a linha (o marcador em `typed-action-example.bp` do `08-bpp/127`); rakun
06–10, 29.

### lg2-g · `@typeName<T>()`

**Contexto.** Não existe intrínseco que transforme um tipo no seu nome: `@typeName<User>()` não
parseia. Argumentos de tipo explícitos já parseiam em toda chamada (decisão 8 §1.3 da 1.0.10, 255) —
só falta o intrínseco. Sem ele, o registro do rakun (`rkResolve<T>(name)`, decisão 254) recebe a
chave como string ao lado de `T`, e nada checa que as duas batem.

**Hoje:**
```bp
val u = rkResolve<User>("User");          // compila; a string não é checada contra T
val n = @typeName<User>();                // não parseia
```

- [ ] **(1)** Sem intrínseco: a chave viaja como string ao lado de `T`.
  ```bp
  val u = rkResolve<User>("User");
  val w = rkResolve<User>("Usr");         // compila; falha só ao resolver, em runtime
  ```
- [ ] **(2)** `@typeName<T>()` comptime responde o nome declarado.
  ```bp
  pub fn rkResolve<T>() -> T { val name = @typeName<T>(); … }   // dentro: "User"
  val u = rkResolve<User>();
  ```

**Recomendação: (1).** A chave do registro continua uma string ao lado de `T`. **Bloqueia:** a
linha; rakun 06.

### lg2-h · Raise e catch por tipo

**Contexto.** Um erro em botopink é o `E` de um `@Result<T, E>`, lido com `case` dentro do `catch`
(decisão 121 da 1.0.10). Não existe braço de `catch` por tipo (`catch { e: NotFound -> … }` não
parseia), e uma exceção host (do Erlang, do JS) não é um `E`. Com (1), a linha do `language-gaps.md`
vira documentação da 121.

**Hoje:**
```bp
fn load(p: string) -> @Result<User, LoadError> { … }
val u = try load(p) catch { e: NotFound -> defaultUser() };   // não parseia
```

- [ ] **(1)** O erro é o `E` do `@Result`, lido com `case`.
  ```bp
  val u = try load(p) catch { e -> case e { .NotFound -> defaultUser(); _ -> throw e; } };
  ```
- [ ] **(2)** Um braço de `catch` por tipo.
  ```bp
  val u = try load(p) catch { e: NotFound -> defaultUser(); e: Timeout -> retry(p) };
  ```
- [ ] **(3)** Exceções host tipadas: um erro do Erlang chega como um `E`.
  ```bp
  val s = try sock.connect(host) catch { e -> case e { .Econnrefused -> fallback(); _ -> throw e; } };
  ```

**Recomendação: (1).** É a decisão 121 como escrita: o erro é o `E` do `@Result`. **Bloqueia:** a
linha; rakun 07, 31, 63.

### lg2-j · Estado comptime entre invocações de decorator

**Contexto.** Cada invocação de decorator é uma chamada de módulo independente: um `var` de módulo
escrito pelo corpo do decorator é recusado na anotação. A pergunta veio do rakun 05, que queria
acumular um catálogo de chaves enquanto as anotações são visitadas. Hoje um catálogo é o registro de
entrada da decisão 256, lido com `@TypeInfo.all` (decisões 253/256).

**Hoje:**
```bp
var seen: Array<string> = [];
fn register(comptime decl: @Decl) { seen.push(decl.name); }   // erro na anotação
```

- [ ] **(1)** Cada invocação é independente; a lista de registros vem de `@TypeInfo.all`.
  ```bp
  val d = comptime {
      var d: Dict<string, unknown> = Dict.empty();
      for (@TypeInfo.all(with: [service, configuration], member: "make")) { b -> d = rkAddBean(d, b.name, b.value); }
      break d;
  };
  ```
- [ ] **(2)** Estado mutável comptime por compilação: `seen` acumula, e a ordem de visita passa a importar.
  ```bp
  var seen: Array<string> = [];
  fn register(comptime decl: @Decl) { seen.push(decl.name); }   // compila; seen depende da ordem dos arquivos
  ```

**Recomendação: (1).** A resposta de um decorator depende só da declaração dele, então a ordem em que
o compilador visita as declarações nunca muda um build. **Bloqueia:** a linha; rakun 05.

### lg2-l · `noreturn` é tipo-fundo?

**Contexto.** Uma função `-> noreturn` encerra o caminho no commonJS e no erlang, mas não cabe em
nenhuma posição de valor: `throw notFound();` num corpo `@Result` e `val s: string = notFound();` dão
mismatch. Por isso os sinais de navegação do jhonstart (`notFound()` / `redirect()`) declaram
`-> string` e o onze escreve `val _gone = notFound();`. `@panic` / `@todo` já são `noreturn` e um
ramo que termina numa chamada `noreturn` já estreita — talvez a (1) já esteja respondida de fato.

**Hoje:**
```bp
pub fn notFound() -> noreturn { raise("…"); }
notFound();                               // ok: encerra o caminho
val s: string = notFound();               // error: expected string, got noreturn
```

- [ ] **(1)** Não unifica com nada: `notFound();` é um statement que encerra o caminho; `throw notFound();` e `val s: string = notFound();` são erro. Os sinais passam a `-> noreturn`, chamados como statement.
  ```bp
  pub fn notFound() -> noreturn { raise("…"); }
  fn page(slug: string) -> Element {
      val post = posts.find(slug);
      if (post == null) notFound();       // statement; daqui em diante `post` não é nulo
      return render(post);
  }
  ```
- [ ] **(2)** É o tipo-fundo: cabe em qualquer posição.
  ```bp
  val s: string = notFound();             // checa
  val f = { -> notFound() };              // checa como fn() -> qualquer coisa
  ```

**Recomendação: (1).** Um sinal nunca é um valor. **Bloqueia:** a linha; os sinais do jhonstart (63,
`31-a`) e os testes de navegação do rakun.

### lg2-m · Anotação de módulo

**Contexto.** O `'use cache'` no topo de um arquivo do Next.js não tem grafia em botopink: `#![…]` no
topo de um módulo dá "this token cannot appear here". O `rakun-cache` hoje liga a política padrão do
módulo uma vez num `val` e cada chamada usa esse `val`. A pergunta é se a linguagem ganha atributo de
módulo.

**Hoje:**
```bp
#![useCache]                              // error: this token cannot appear here
```

- [ ] **(1)** Não: a política do módulo é um `val` de módulo.
  ```bp
  val cached = cacheWith(cachePolicy(…));                                  // rakun-cache/src/cache.bp
  pub fn posts() -> string { return cached(["posts"], { -> loadPosts() }); }
  ```
- [ ] **(2)** Atributo interno no topo do arquivo, que um decorator recebe com o `@Decl` do módulo.
  ```bp
  #![useCache(ttl: 60)]
  pub fn posts() -> string { return loadPosts(); }                         // toda fn do módulo passa pelo cache
  ```

**Recomendação: (1).** A política de um módulo é um `val` de módulo. **Bloqueia:** a linha; rakun 12.

### lg2-n · Thunk convertido em `Node`

**Contexto.** O tipo de nó da UI (`Children` hoje, `Node` pela decisão 223) aceita conversão
automática de três coisas: array, `Element` e `string`. Uma função sem argumentos (thunk) não
converte, então `show({ -> "x" })` não compila. A pergunta veio do jhonstart 30 (Suspense), que
queria passar o filho adiado como filho comum.

**Hoje:**
```bp
show({ -> "x" })                          // expected Node, got function
```

- [ ] **(1)** Não: o filho adiado é um campo nomeado da fronteira.
  ```bp
  Suspense(fallback: spinner(), content: { -> posts() })
  ```
- [ ] **(2)** `fn() -> Element` converte em `Node`.
  ```bp
  show({ -> "x" })                        // compila
  Suspense(fallback: spinner()) { -> posts() }
  ```

**Recomendação: (1).** As coerções que o compilador conhece continuam três (array, `Element`,
`string`). **Bloqueia:** a linha; jhonstart 30.

### lg2-o · Acesso a arquivos no comptime

**Contexto.** Um corpo comptime (decorator, template) só vê o prelude do seu runtime: `fs.readText`
lá dentro é recusado na anotação. Por isso o rakun gera o `.bp` de um WSDL com um comando
(`rakun ws generate`) e versiona o resultado. Com (2), o build passaria a ler arquivos além dos
fontes, e esses arquivos entrariam na chave do cache.

**Hoje:**
```bp
fn wsdl(comptime decl: @Decl, path: string) { val xml = fs.readText(path); … }   // recusado na anotação
```

- [ ] **(1)** Não: o `.bp` gerado é versionado.
  ```
  $ rakun ws generate schema.wsdl         → src/ws/billing.bp   # roda antes; o resultado entra no repositório
  ```
- [ ] **(2)** Leitura isolada de entradas declaradas, que entram na chave do cache do build.
  ```bp
  #[wsdl("schema.wsdl")] type Billing {}  // lê o arquivo durante a compilação
  ```

**Recomendação: (1).** Um build lê só os seus fontes. **Bloqueia:** a linha; rakun 88, 93.

### lg2-p · Cancelamento

**Contexto.** O `std/async` não tem como cancelar trabalho: o perdedor de um `raceOf` e a task de um
`timeout` que estourou continuam rodando até o fim; o chamador só para de esperar. Isso está
documentado no próprio `async.bp` ("NO CANCELLATION"). A pergunta é se a linguagem ganha
cancelamento.

**Hoje:**
```bp
val r = await async.raceOf([{ -> slow() }, { -> fast() }]);   // fast() vence; slow() roda até o fim
val t = await async.timeout({ -> slow() }, 100);              // Error("timeout"); slow() continua
```

- [ ] **(1)** Nenhum: o trabalho perdedor termina e o resultado é descartado, documentado.
  ```bp
  val r = await async.raceOf([{ -> slow() }, { -> fast() }]);   // igual a hoje; o doc diz que slow() completa
  ```
- [ ] **(2)** Tokens explícitos.
  ```bp
  fn slow(token: CancelToken) -> @Task<i32> { while (!token.cancelled()) { … } … }
  val r = await async.raceOf([{ -> slow(tok) }, { -> fast() }]);   // o perdedor vê o token e para
  ```
- [ ] **(3)** Processos ligados no BEAM: o perdedor é morto.
  ```bp
  val r = await async.raceOf([{ -> slow() }, { -> fast() }]);   // beam: o processo de slow() recebe exit(kill)
  ```

**Recomendação: (1).** Em linha com a `lg2-b` (1). **Bloqueia:** a linha; rakun 02.

### lg2-q · Localização no fonte dentro de `@Decl`

**Contexto.** Um decorator não sabe em que arquivo está a declaração: `decl.loc.file` dá `badkey`. O
roteamento por arquivo (rakun 22, onze 53) queria deduzir a rota do caminho, como o `app/` do
Next.js. Hoje o segmento é um argumento explícito, gerado e verificado pelo CLI da frente 50.

**Hoje:**
```bp
fn page(comptime decl: @Decl) { decl.loc.file }   // badkey
```

- [ ] **(1)** Não: o segmento é argumento explícito.
  ```bp
  // app/blog/[slug]/page.bp
  #[page("blog/[slug]")] pub fn BlogPost(slug: string) -> Element { … }
  ```
- [ ] **(2)** `decl.loc` (o `SourceLocation` do `@src()`): `#[page]` deduz a rota do caminho do arquivo.
  ```bp
  // app/blog/[slug]/page.bp
  #[page] pub fn BlogPost(slug: string) -> Element { … }   // rota "blog/[slug]" lida de decl.loc.file
  ```

**Recomendação: (1).** A saída de um decorator nunca depende de onde o arquivo está. **Bloqueia:** a
linha; rakun 22.

### lg2-r · Corpo fornecido por um decorator para um método declarado

**Contexto.** Um método sem corpo (`declare fn`) num `type` é só a forma de método host: sem
`#[@External.<Target>]`, ele é recusado em toda chamada, em todo target
(`run/bodyless_method_without_binding`). Nenhum decorator pode fornecer o corpo — o rakun-data queria
isso para `#[query]`, como os repositórios do Spring Data. Hoje o decorator emite um helper e o
método chama o helper.

**Hoje:**
```bp
type Users { #[query("select * from users where id = $1")] declare fn find(id: i32) -> ?User; }
users.find(1);                            // error: run/bodyless_method_without_binding, na chamada
```

- [ ] **(1)** Método sem corpo é só binding host; o decorator emite um helper e o método tem corpo.
  ```bp
  type Users {
      #[query("select * from users where id = $1")]
      fn find(id: i32) -> ?User { return findQuery(self, id); }   // findQuery emitido pelo #[query]
  }
  ```
- [ ] **(2)** O decorator fornece o corpo: a declaração basta.
  ```bp
  type Users { #[query("select * from users where id = $1")] declare fn find(id: i32) -> ?User; }
  users.find(1);                          // compila; o corpo veio do #[query]
  ```

**Recomendação: (1).** É o que a recusa de hoje já impõe (`run/bodyless_method_without_binding`).
**Bloqueia:** a linha; rakun 08, 09, 78.

### lg2-s · Reflexão do grafo de módulos

**Contexto.** O `@Decl` expõe declarações, não os imports de um módulo: `decl.imports` dá `badkey`.
O `onze-bundler` lê os imports com `importsOf`, uma varredura textual que falha alto numa linha que
não entende. A recomendação (1) antes se apoiava em "em linha com a `lg2-k`", mas a `lg2-k` foi
respondida ao contrário (decisão 216 abriu reflexão comptime sobre o projeto); a `ctr-m` pede que esta
seja reargumentada por conta própria.

**Hoje:**
```bp
val refs = try importsOf(f.path, f.source);    // onze-bundler/src/graph.bp: varredura textual
fn graph(comptime decl: @Decl) { decl.imports } // badkey
```

- [ ] **(1)** Não: o `importsOf` do onze-bundler continua uma varredura textual que falha alto.
  ```bp
  val refs = try importsOf(f.path, f.source);    // Error(…) numa linha de import que não parseia
  ```
- [ ] **(2)** `decl.imports` num `@Decl` de módulo (como a 216 fez com `@TypeInfo.all`).
  ```bp
  fn graph(comptime decl: @Decl) { for (decl.imports) { i -> i.module } }
  ```

**Recomendação: (1)** — por conta própria: os imports de um módulo são texto que o bundler já lê e
recusa alto quando não entende; o argumento antigo ("em linha com a `lg2-k`") caiu, ver `ctr-m`.
**Bloqueia:** a linha; rakun 68; a `ctr-m` fecha com a resposta.

### lg2-t · Folha de enum numérica negativa

**Contexto.** Folhas numéricas de enum são dígitos puros, então `-rotate-12` e `-translate-y-2` do
Tailwind não têm grafia: `Rotate { 12, -12 }` é recusado no `-`. O emilia usa a convenção de uma
sub-seção `Neg { … }` (frentes 35, 40, 45), lida como "rotate, negativo, doze". Em posição de
expressão uma folha numérica se escreve `.__12`.

**Hoje:**
```bp
type Tok { Rotate { 12, -12 } }           // erro no `-`
```

- [ ] **(1)** Não: sub-seção `Neg`.
  ```bp
  type Tok { Rotate { 12, Neg { 12 } } }
  val t = .Rotate.Neg.__12;
  ```
- [ ] **(2)** Folha com sinal.
  ```bp
  type Tok { Rotate { 12, -12 } }
  val t = .Rotate.__N12;                  // grafia em posição de expressão
  ```
- [ ] **(3)** `-` unário num caminho de enum.
  ```bp
  val t = -(.Rotate.__12);
  ```

**Recomendação: (1).** O nome de uma folha continua um nome. **Bloqueia:** a linha; emilia 35, 36, 45.

### lg2-u · Decorator em posição de expressão

**Contexto.** Decorators só anotam declarações: `val x = #[deco] 1;` é recusado
(`loop-annotation-not-generator`). A frente 48 queria escrever `#[emilia([.Pad.All.4])] div(…)`
direto numa expressão. Hoje o trabalho em expressão é uma chamada de função comum.

**Hoje:**
```bp
val x = #[deco] 1;                        // recusado: loop-annotation-not-generator
```

- [ ] **(1)** Não: trabalho em expressão é uma chamada.
  ```bp
  val x = traced(compute());
  val d = emilia([.Pad.All.4], div(…));
  ```
- [ ] **(2)** Decorator em posição de expressão, rodado no script de eval.
  ```bp
  val x = #[traced] compute();
  val d = #[emilia([.Pad.All.4])] div(…);
  ```

**Recomendação: (1).** Um decorator anota uma declaração; trabalho em expressão é uma chamada.
**Bloqueia:** a linha; frente 48.

### lg2-v · Subdiretório numa dependência git

**Contexto.** Uma dependência no `botopink.json` é `{git, path, ref, workspace}`
(`modules/manifest/src/root.zig`): não há como apontar para uma pasta dentro de um repositório git.
Como todo módulo `rakun-*` é uma pasta do repositório do rakun, quem está fora do checkout meta não
instala um starter por git. Custa: segura o `07-h` (b) e o 98 passo 4.

**Hoje:**
```json
"rakun-web": { "git": "git@github.com:botopink/rakun.git" }      // instala a raiz do repositório, não o módulo
```

- [ ] **(1)** Não: dependência git é a raiz de um repositório; membro de monorepo só por `path`.
  ```json
  "rakun-web": { "path": "../rakun/modules/rakun-web" }
  ```
- [ ] **(2)** Campo `subdir`, resolvido pelo `bpmp`.
  ```json
  "rakun-web": { "git": "git@github.com:botopink/rakun.git", "subdir": "modules/rakun-web" }
  ```

**Recomendação: (1).** Se você escolher a (2): `subdir` só vale junto com `git`, e um que escape do
checkout (`..`) é recusado. **Bloqueia:** a linha; rakun 73; `02/98` passo 4 (condicional); o
argumento do `07-h`.

### lg2-w · Função host chamada do corpo de um decorator

**Contexto.** Um decorator roda num runtime comptime (BEAM ou wat). Só funções com corpo viajam para
o módulo do decorator; uma função host (`declare fn` com célula Erlang/JS), do std ou do próprio
projeto, não viaja, e a chamada falha com `call to undefined function quote/1` nos dois runtimes. Na
prática, o `#[scheduled]` da frente 16 repete as regras de cron inline em vez de reusar o std.

**Hoje:**
```bp
fn route(comptime decl: @Decl, path: string) { @emit("…" + json.quote(path)); }
// undefined function quote/1
```

- [ ] **(1)** Corpo comptime só chama funções com corpo; a chamada host é recusada, localizada, nomeando a função, em todo target.
  ```bp
  fn route(comptime decl: @Decl, path: string) { @emit("…" + json.quote(path)); }
  // error: `json.quote` is a host function — a decorator body calls bodied functions only
  fn quote(s: string) -> string { … }     // a forma aceita: uma fn com corpo no projeto ou num pacote
  ```
- [ ] **(2)** A célula Erlang viaja para o módulo do decorator no runtime BEAM; no runtime wat a chamada é recusada.
  ```bp
  @emit("…" + json.quote(path));          // runtime BEAM: compila · runtime wat: error
  ```
- [ ] **(3)** Decorator que alcança célula host sempre roda no runtime BEAM, qualquer que seja o target.
  ```bp
  @emit("…" + json.quote(path));          // --target wasm: o decorator roda no BEAM e compila
  ```

**Recomendação: (1).** A resposta de um decorator nunca depende de qual runtime o target escolheu
(decisão 84). **Bloqueia:** a linha; frente 16 (`#[scheduled]`); todo decorator que reusaria o std.

- [ ] Confirmo a recomendação em todas desta parte
- [ ] Quero rever: ___

---

---

## Parte 5 — Escolhas que as threads fizeram (★), para confirmar

Cada uma já está no código da `feat` (as frentes 110–113 entraram e fecharam na 1.0.11). Confirmar não
muda nada; marcar a alternativa vira trabalho para a frente dona (hoje, a `00-gate/114` ou a dona do
arquivo). Exceção: a 103-a (da consolidação) ainda não está na `feat` — está na branch
`front/103-actions-id`, ainda não enviada ao remoto.

### 111-b ★ · O carregador de sidecars no beam só é emitido quando o build liga uma função host

**Contexto.** Um "sidecar" é o arquivo `.erl` escrito à mão que acompanha uma função declarada com
`#[@External.Erlang("host", …)]`: o build copia `host.erl` para `out/beam/`, ao lado do `.beam` gerado.
Para o programa achar esse módulo ao rodar, a entrada do programa (`'_botopink_main'/0`) chama primeiro
`'__bp_load_siblings'/0`, que compila e carrega todo `.erl` da pasta. A thread da 111 decidiu emitir
esse carregador só quando algum módulo do build tem `#[@External.Erlang]` / `#[@External.Beam]` num
`declare fn`, num `type` ou num método de `type` (`buildBindsBeamHost` em
`codegen/beam_asm.zig`); por isso só 13 snapshots de beam mudaram (e seus 13 gêmeos em `wat/beam/`).
Na prática: um programa sem binding host gera o mesmo assembly de antes.

**Hoje:**
```bp
// programa sem binding host
fn main() { @print("oi"); }
// main.S: '_botopink_main'/0 chama io:setopts e main/0 — sem '__bp_load_siblings'

// programa com binding host (snapshot external_global_math)
#[@External.Erlang("math", "floor"), @External.Node("Math", "floor")]
pub declare fn floor(n: f64) -> f64;
// main.S: '_botopink_main'/0 faz {call, 0, {f, 9}} → {function, '__bp_load_siblings', 0, 9}
```

- [ ] **(a) ★** Um programa sem `#[@External.Erlang]` / `#[@External.Beam]` não ganha a chamada ao carregador; 13 snapshots mudaram.
  ```bp
  '_botopink_main'/0:   (sem __bp_load_siblings)      # programa sem binding host
  '_botopink_main'/0:   call '__bp_load_siblings'/0   # programa com #[@External.Erlang(…)]
  ```
- [ ] **(b)** Todo módulo de entrada chama o carregador, haja sidecar ou não: uma forma só de emissão, e 219 snapshots de beam regravados (×2 runtimes).
  ```bp
  {function, '_botopink_main', 0, 5}.
    …
    {call, 0, {f, 9}}.                 % sempre, mesmo em fn main() { @print("oi"); }
  {function, '__bp_load_siblings', 0, 9}.   % varre out/beam/*.erl e não acha nada
  ```

**Recomendação: (a) ★.** O programa que não tem sidecar não paga por um carregador. **Bloqueia:** nada.

### 111-c ★ · `botopink build --target beam` dispara um `erl`, como o build erlang

**Contexto.** O build erlang já rodava uma sondagem com o `erl` instalado para conferir que cada
módulo host citado num `#[@External.Erlang("host", …)]` existe (copiado como sidecar ou no code path do
OTP); um módulo que falta vira uma recusa com arquivo e linha, não um `undef` ao rodar. A 111 fez o
build beam copiar os mesmos sidecars para `out/beam/` e, com isso, passar pela mesma sondagem
(`build.zig`: `if ((target == .erlang or target == .beam) and !try otp.check(…)) return 1`). O custo é
~0,25 s de `erl` por build e a exigência de OTP instalado; o ganho é que `botopink run --target beam`
passou a de fato executar o programa, e um sidecar quebrado é recusado antes de rodar.

**Hoje:**
```bp
$ botopink build --target beam      # com um erl que falha primeiro no PATH
(exit 1)                            # a sondagem de módulo host não consegue rodar
$ botopink run --target beam        # sidecar ok
hello, sidecar                      (exit 0)
```

- [ ] **(a) ★** O build beam roda a mesma sondagem de módulo host que o build erlang (~0,25 s) e sai com 1 se o `erl` falhar; `botopink run --target beam` passou a executar o programa.
  ```bp
  $ botopink build --target beam      # sidecar que não compila
  error: … does not compile - refusing to run            (exit 1)
  ```
- [ ] **(b)** O build beam não chama o `erl`: termina mesmo sem OTP instalado, e um sidecar quebrado só aparece ao rodar.
  ```bp
  $ botopink build --target beam      # sem OTP, sidecar quebrado
  (exit 0)                            # escreve out/beam/main.S e out/beam/lt_greeter.erl
  $ botopink run --target beam
  error: …/out/beam/lt_greeter.erl does not compile - refusing to run   (exit 1)
  ```

**Recomendação: (a) ★.** Falhar no build é mais restritivo do que falhar ao rodar (decisão 67).
**Bloqueia:** nada.

### 113-a ★ · Pedir um target que o `botopink test` não roda falha o `test-libs`

**Contexto.** `zig build test-libs` roda os testes de cada biblioteca em cada target, pelo script
`scripts/test-libs.sh`. Hoje o `botopink test` só sabe rodar commonJS e erlang; beam e wasm não
rodam. Antes da 113, pedir um desses alvos pelo nome dava `skipped` (amarelo, `~`) e o comando saía
com 0 — ou seja, "nada rodou" parecia sucesso. A thread aplicou a regra de `fronts.md` (uma célula que
reporta "skipped" é vermelha): o par vira `NOT RUNNABLE` e o comando falha. Isso só acontece quando
alguém pede beam ou wasm explicitamente; a execução padrão não pede.

**Hoje:**
```bp
$ zig build test-libs -- --target wasm        # botopink test só roda commonJS e erlang
── hostbound · wasm: NOT RUNNABLE — `botopink test` cannot run this target; nothing ran
test-libs: 0 passed, 0 failed, 0 without tests, 0 restrictions audited, 1 not runnable by botopink test
(exit 1)
```

- [ ] **(a) ★** `NOT RUNNABLE`, e o comando sai com erro. É a regra de `fronts.md`: uma célula que reporta "skipped" é vermelha.
  ```bp
  $ zig build test-libs -- --target beam
  ── hostbound · beam: NOT RUNNABLE — `botopink test` cannot run this target; nothing ran
  (exit 1)
  ```
- [ ] **(b)** Reportar `skipped` e sair com 0, como era antes da 113.
  ```bp
  $ zig build test-libs -- --target beam
  ── hostbound · beam: skipped (~)
  test-libs: 0 passed, 0 failed, … 1 skipped
  (exit 0)
  ```

**Recomendação: (a) ★.** Falhar é mais restritivo do que pular: um par que não rodou nunca conta
como aprovado. **Bloqueia:** nada.

### 113-b ★ · A auditoria de restrições reconhece a recusa pelo texto, porque ela não tem id

**Contexto.** Uma biblioteca pode limitar seus targets no manifesto (`"targets": ["erlang"]`). A regra
da decisão 156 aceita uma exclusão só quando o build do target excluído é recusado por falta de binding
host — a biblioteca estruturalmente não pode rodar ali. Essa recusa do compilador
(`MissingExternal.diagnostic`, `codegen/moduleOutput.zig`) não tem id de erro, então a auditoria
(`lib-test-runner/src/runner.zig`, `HOST_BINDING_MARK`) compara o texto fixo
``has no `#[@External.<Target>(…)]` for the <backend> backend``. O risco é que alguém reescreva a
frase no compilador; nesse caso a auditoria passa a recusar tudo (falha alta), nunca a aceitar algo
errado. `compiler-cli/tests/test_tooling.sh` amarra os dois com um build real.

**Hoje:**
```bp
$ botopink build --target node      # biblioteca com "targets": ["erlang"]
error: `callGlobal` has no `#[@External.<Target>(…)]` for the node backend
  --> src/main.bp:4:5
# a auditoria procura "has no `#[@External.<Target>(…)]` for the " + " backend" → exclusão estrutural (·)
```

- [ ] **(a) ★** Comparar pelo texto. Se o compilador mudar a frase, toda auditoria vira "não estrutural" e o `test-libs` falha — o erro aparece, não passa em silêncio.
  ```bp
  # compilador reescreve para "lacks a host binding for node":
  ── hostbound · commonJS: NOT STRUCTURAL — error: `callGlobal` lacks a host binding for node
  (exit 1)
  ```
- [ ] **(b)** A recusa ganha um id (por exemplo `error[external-missing]`) no compilador, e a auditoria compara o id. É trabalho da `01-compiler`.
  ```bp
  $ botopink build --target node
  error[external-missing]: `callGlobal` has no `#[@External.<Target>(…)]` for the node backend
  # a auditoria compara só "error[external-missing]"; a frase pode mudar livremente
  ```

**Recomendação (desta revisão): (b)**, como linha da `01-compiler/07-residuals`; a (a) fica valendo até
lá. Um id é um contrato explícito; o texto é um acordo implícito entre dois módulos. **Bloqueia:** nada
— a (a) funciona até a linha da 07-residuals entrar.

### 110-b ★ · O histórico de contagens saiu do `tests/language/AGENTS.md`

**Contexto.** O arquivo `tests/language/expected-failures.txt` listava células de teste que podiam
falhar; a decisão 154 o eliminou, e o texto `expected-failures` tinha de sumir de todo o repositório.
Ele ainda aparecia no `tests/language/AGENTS.md`, numa seção "registro das frentes anteriores" com
cerca de 480 linhas de contagens antigas (quantos testes passavam em cada frente). Para cumprir a 154,
a thread apagou a seção inteira. O que se perde é a leitura rápida dessas contagens; elas continuam no
histórico do git.

**Hoje:**
```bp
$ grep -rn "expected-failures" tests/language/AGENTS.md
(nada)
$ grep -n "^## " tests/language/AGENTS.md
18:## Layout
1006:## The targets
1128:## Running
1234:## Status and the gate        # estado atual dos quatro targets, sem registro histórico
```

- [ ] **(a) ★** Apagado. O arquivo diz o estado atual dos quatro targets.
  ```bp
  ## Status and the gate
  `run.sh --target all` → language tests: <N> passed, 0 failed   # só o número de hoje
  ```
- [ ] **(b)** Recuperar esse histórico do git para um arquivo à parte (por exemplo `tests/language/HISTORY.md`).
  ```bp
  $ git show <commit-anterior-à-110>:tests/language/AGENTS.md > /tmp/old.md
  # copiar a seção para tests/language/HISTORY.md, reescrevendo cada
  # "expected-failures" para não violar a decisão 154
  ```

**Recomendação: (a) ★.** A convenção das specs é estado atual, sem narrativa; o histórico continua no
git. **Bloqueia:** nada.

### 112-a ★ · O que o `format-check` percorre

**Contexto.** `scripts/format-check.sh` roda `botopink format --check` sobre uma lista de pastas
(`TREES`) e é a etapa 3 do `scripts/gate.sh` e um passo do CI: um `.bp` fora do formato canônico deixa
o gate vermelho. Antes, a lista nomeava quatro pastas de exemplo uma a uma, então `examples/hello.bp`
e qualquer exemplo novo ficavam de fora sem ninguém notar; `modules/manifest/tests` também não estava.
A thread trocou por `examples` inteiro e acrescentou `modules/manifest/tests`. Na medição da 112, todo
`.bp` rastreado ficou coberto ou isento por estrutura (pastas ocultas, `node_modules`, `reject/<n>.bp`
ao lado do seu `.expect`, e o `pattern.bp` que de propósito não lexa): 508 + 173 `reject/` + 1 = 682.

**Hoje:**
```bp
TREES=(
    examples
    libs/std
    libs/routing
    libs/actions
    libs/validation
    libs/log
    libs/http
    modules/compiler-cli/tests
    modules/manifest/tests
    tests/language
)
```

- [ ] **(a) ★** `TREES` tem `examples` como uma entrada só (pega `examples/hello.bp` e qualquer exemplo novo) e ganhou `modules/manifest/tests`; todo `.bp` rastreado está coberto ou isento por estrutura (508 + 173 `reject/` + 1 = 682).
  ```bp
  $ mkdir -p examples/novo/src && echo 'fn main(){@print("x")}' > examples/novo/src/main.bp
  $ scripts/format-check.sh
    ✗ examples (run: zig-out/bin/botopink format examples)     # exit 1
  ```
- [ ] **(b)** Voltar às quatro pastas de exemplo nomeadas, mais `examples/hello.bp` numa linha própria.
  ```bp
  TREES=(
      examples/generic-loader-binding
      examples/modules
      examples/stdlib-tour
      examples/yamlconf
      examples/hello.bp
      …
  )
  # examples/novo/ não é verificado até alguém lembrar de acrescentá-lo
  ```

**Recomendação: (a) ★.** Um exemplo novo já nasce verificado, sem lista para manter (decisão 67).
**Bloqueia:** nada.

### 103-a ★ · O nome da função do pacote `actions.id` *(da consolidação)*

**Contexto.** Hoje o `rakun-app` calcula o id de uma action em `actions.bp`
(`actionId(module, name, buildId)`, um HMAC-SHA256 com o segredo `rakun.actions.secret`, prefixo `a_`
+ 24 hex), e o `jhonstart-forms` confere um formato mais frouxo. A frente 103 cria o pacote
`actions.id` com uma derivação e uma gramática únicas para os dois lerem. A thread chamou a função do
pacote de `deriveActionId` (recebe o segredo como parâmetro; o pacote nunca lê a configuração) e
manteve o `actionId` do `rakun-app`, que já é lido pelos testes, por `actionIdOf` e por
`resolveAction`, passando a apenas envolvê-la. Isso está na branch `front/103-actions-id`, ainda não
na `feat`.

**Hoje:**
```bp
// rakun/modules/rakun-app/src/actions.bp
pub fn actionId(module: string, name: string, buildId: string) -> string {
    val mac = hash.hmacSha256(
        rkProp("rakun.actions.secret"),
        module + "." + name + ":" + buildId,
    );
    return "a_" + mac.slice(0, 24);
}
```

- [ ] **(a) ★** `deriveActionId(secret, module, name, buildId)` no pacote; o `actionId` do `rakun-app` continua e passa a envolvê-lo.
  ```bp
  // libs/actions — id.bp
  pub fn deriveActionId(secret: string, module: string, name: string, buildId: string) -> string { … }
  pub fn isActionId(id: string) -> bool { … }

  // rakun-app/src/actions.bp
  pub fn actionId(module: string, name: string, buildId: string) -> string {
      return deriveActionId(rkProp("rakun.actions.secret"), module, name, buildId);
  }
  ```
- [ ] **(b)** O pacote se chama `actionId` e o `actionId` do `rakun-app` é apagado no passo 2 da 103.
  ```bp
  // libs/actions — id.bp
  pub fn actionId(secret: string, module: string, name: string, buildId: string) -> string { … }

  // rakun-app: actionIdOf, resolveAction e actions_test.bp passam a chamar
  actionId(rkProp("rakun.actions.secret"), module, name, buildId);
  ```

**Recomendação: (a) ★** — nome livre (decisão 163 / 07-i): o `rakun-app` já exporta `actionId`, e
reaproveitar o nome no pacote com outra assinatura obrigaria a mexer em todos os seus chamadores.
**Bloqueia:** nada com (a); com (b), o passo 2 da 103 (consumidores) muda antes do envio da branch.

- [ ] Confirmo as sete como estão
- [ ] Quero rever: ___

---

---

## Parte 6 — Escolhas já implementadas na 1.0.10, ainda sem confirmação

Cada item abaixo já está no código com a opção ★. O exemplo mostra o que você escreve e o que
acontece hoje; a linha "Alternativa" é o que mudaria se você revertesse. O texto medido de cada uma
está em `specs/1.0.10-beta/decisions-pending.md` (procure pelo id); a 1.0.12 já traz cada uma numa
linha em `decisions-pending.md` § Implementation choices. Saíram daqui por já estarem resolvidas:
**23-a** e **01std-d** (a alternativa delas entrou no código) e **26-b** (respondida pela decisão 186).

### As duas em que recomendo a alternativa

### lem-b · `inline = true` num método de tipo

**Contexto.** `inline = true` num `#[@External.Erlang(…)]` / `#[@External.Beam(…)]` existe para os
métodos de um behavior PRIMITIVO: tira o método da tabela de despacho para que uma forma escrita à mão
continue sendo emitida. Um `type` do usuário não tem nem a tabela nem a forma à mão, então a flag não
tem o que fazer ali. A thread `libs-external-methods` aceitou a flag e baixou o método do mesmo jeito
(fixado pelo `times` de `run/external_method_local`), porque recusá-la é uma regra do checker e cabe
ao `01-checker` acrescentar. A leitura da decisão 67 (já aplicada ao F9 da frente 20) é que uma chave
que ninguém lê é recusada.

**Hoje:**
```bp
pub type Meter(base: i32) {
    #[@External.Erlang("""(element(2, $0) * $1)""", inline = true)]
    pub declare fn times(self: Self, n: i32) -> i32;
}
m.times(2)      // compila; o método é emitido igualzinho a um sem `inline`
```

- [ ] **(a) ★** Aceita e ignora — compila, o método não é inlinado; as regras do `refuseUnreadInline`
  continuam valendo.
  ```bp
  #[@External.Erlang("""(element(2, $0) * $1)""", inline = true)]   // aceito, sem efeito
  pub declare fn times(self: Self, n: i32) -> i32;
  ```
- [ ] **(b)** O checker recusa a flag num método de tipo — quem a escreveu apaga o `inline = true`.
  ```bp
  #[@External.Erlang("""(element(2, $0) * $1)""", inline = true)]
  // error: inline is not available on a type method
  pub declare fn times(self: Self, n: i32) -> i32;
  ```

**Recomendação: (b).** É a leitura mais restritiva (decisão 67): uma chave que não muda nada é uma
promessa falsa para quem lê o código. **Bloqueia:** nada — a recusa é do `01-checker`; até lá vale (a).

### 03r-b · `rkPropInt("12abc")`

> **Revertida pela 299:** um número malformado na configuração para o boot, apontando a linha.

**Contexto.** O rakun lê uma propriedade inteira da configuração com `rkPropInt` (em
`rakun_runtime.erl`), que segue o `parseInt(v, 10)`: pega os dígitos do começo e, se não houver
nenhum, devolve zero. O `toI32` da frente 05 declara a mesma regra para todo leitor tipado, para que
`#[value]` e um record ligado à configuração nunca discordem. A caixa do passo 3 da frente 04 dizia
`0`; a auditoria da trilha manteve `12` e emendou a caixa. Recusar o texto que sobra é a leitura mais
estrita, e muda as frentes 04 e 05 ao mesmo tempo (uma função em cada).

**Hoje:**
```text
# application.properties
server.port=8080x
```
```bp
rkPropInt("12abc")      // 12  — "propInt is parseInt, and unparsable is zero"
rkPropInt("abc")        // 0
```

- [ ] **(a) ★** `rkPropInt` pega os dígitos do começo — o servidor sobe na porta 8080, e o `x` some
  em silêncio.
  ```text
  server.port=8080x      →  porta 8080, boot normal
  ```
- [ ] **(b)** Texto sobrando é erro de configuração — o boot é recusado e o erro diz qual chave.
  ```text
  server.port=8080x
  error: server.port: "8080x" is not an integer      (o boot para aqui)
  ```

**Recomendação: (b).** É a mais restritiva: um erro de digitação na configuração não deve virar um
valor válido sem ninguém ver. **Bloqueia:** nada — é uma função no `rakun_runtime.erl` (frente 04) e o
`toI32` (frente 05).

### Compilador

### 24-a · Os códigos de diagnóstico de efeito que sobraram

**Contexto.** Desde a frente 24 (decisão 118), uma função ganha um efeito escrevendo o invólucro no
tipo de retorno (`-> @Result<…>`, `-> @Task<…>`) e mais nada; não há mais anotação de efeito. Os
códigos que falavam da anotação (`effect-missing-annotation`, `effect-missing-wrapper`,
`effect-duplicate-annotation`, `effect-on-declare-forbidden`, `effect-on-behavior-method-forbidden`)
ficaram sem assunto, e `for-over-fallible-generator` aplicava uma regra que a decisão 122 apaga. O
guia já escrevia a recusa de um `throw` com o código do `try`, e a implementação seguiu o guia. Os
sobreviventes estão em `comptime/diagnostics.zig`.

**Hoje:**
```bp
fn f() { try g(); }       // error[effect-try-without-fallible-channel]
fn h() { throw "x"; }     // error[effect-try-without-fallible-channel] — o do `throw` foi fundido nele
for (s) { x -> … }        // sobre um @Stream: error[for-over-stream] (era for-over-future-generator)
```

- [ ] **(a) ★** Um código só para "não há camada `@Result` no retorno", seja `try` ou `throw`;
  `effect-wrapper-mismatch` fica só para o componente cujo `T` implementa `@Context<B>` com um `B`
  diferente do `C` escrito; `for-over-stream` / `for-await-expects-stream` são os nomes novos.
  ```bp
  fn h() { throw "x"; }     // error[effect-try-without-fallible-channel]
  ```
- [ ] **(b)** Um código separado para o `throw`.
  ```bp
  fn h() { throw "x"; }     // error[effect-throw-without-fallible-channel]
  ```

**Recomendação: (a).** As duas recusas têm a mesma causa e a mesma correção (pôr `@Result` no
retorno); o guia já escreve assim, e reverter é renomear constantes. **Bloqueia:** nada.

### 24-b · Os métodos de `@Task`

**Contexto.** O invólucro assíncrono antigo do prelúdio tinha `map` / `flatMap` / `await`. A decisão
120 fala em "`.map`, `.then` e afins, sem parâmetro de erro" — uma Task nunca falha, então não há
`mapError`. A implementação ficou com uma grafia por operação. Os dois métodos estão declarados em
`builtins.d.bp` (que é documentação), nenhum backend os baixa ainda, e uma chamada não é checada
contra a declaração até o registro de métodos de behavior ler os invólucros.

**Hoje:**
```bp
// builtins.d.bp
pub behavior Task<T> {
    fn map<R>(self: Self<T>, transform: fn(value: T) -> R) -> Task<R>;
    fn then<R>(self: Self<T>, next: fn(value: T) -> Task<R>) -> Task<R>;
}
```

- [ ] **(a) ★** `map` e `then` (o bind, com o nome que o guia usa); nenhum apelido.
  ```bp
  val t: @Task<i32> = load();
  t.map({ n -> n + 1 })           // existe
  t.then({ n -> loadMore(n) })    // existe (é o bind)
  t.flatMap({ n -> loadMore(n) }) // não existe: uma grafia por operação
  ```
- [ ] **(b)** `flatMap` como apelido de `then`.
  ```bp
  t.flatMap({ n -> loadMore(n) }) // o mesmo que t.then(…)
  ```

**Recomendação: (a).** Uma grafia por operação (decisão 67). **Bloqueia:** o `std/async`, se ele
quiser uma forma de combinadores.

### 24-c · `iter for` / `iter while` são um `loop` com prefixo

**Contexto.** O README da frente pedia um nó novo `GenLoop { kind, loop }`; mas cada um dos quatro
backends já baixa uma forma de laço anotado (o `loop` da 22-loops), e a própria decisão 125 diz que
`iter for (xs) { … }` significa `iter loop { for (xs) { … }; break; }`. O parser então lê assim e
guarda a palavra escrita em `LoopExpr.prefixedKeyword`, para o formatador devolvê-la. O label fica
onde a decisão 105 o escreve, depois da palavra do laço.

**Hoje:**
```bp
iter for (xs) { x -> yield x * 2; }      // lido como: iter loop { for (xs) { x -> yield x * 2; }; break; }
iter loop :l { yield :l 1; }             // o label nomeia o gerador
iter for :l (xs) { x -> break :l; }      // o label nomeia o `for` escrito
iter for :l (xs) { x -> yield :l x; }    // error[yield-label-not-generator]
```

- [ ] **(a) ★** Açúcar sintático sobre o `loop` prefixado; o label de `iter for :l` nomeia o `for`
  (então `break :l` / `continue :l` mantêm o sentido de sempre).
  ```bp
  iter for :l (xs) { x -> if (x < 0) { continue :l; }; yield x; }   // continue do `for`
  ```
- [ ] **(b)** Um nó novo `GenLoop`, com um lowering próprio em cada um dos quatro backends — o mesmo
  código-fonte, mais quatro caminhos para manter em acordo.
  ```bp
  iter for (xs) { x -> yield x * 2; }      // vira GenLoop { kind: For, loop: … } até o backend
  ```
- [ ] **(c)** Como (a), mas o label de um `for` prefixado nomeia também o gerador — o parser só move o
  label para o nó de fora.
  ```bp
  iter for :l (xs) { x -> yield :l x; }    // compila: `:l` é o escopo do gerador
  ```

**Recomendação: (a).** É a equivalência que a decisão 125 já escreve, sem nenhum backend novo.
**Bloqueia:** nada.

### 24-g · A forma do `std/async` com uma Task que nunca falha

**Contexto.** Antes da frente 24, o `std/async` tinha uma superfície de thunks (`allOf`, `settleOf`,
`raceOf`, `timeout`) e uma de Tasks já iniciadas (`all`, `allSettled`, `race`), as duas construídas
sobre "Task rejeitada = falha". Agora uma Task nunca falha (decisões 120 e 121): o erro vai DENTRO,
`@Task<@Result<T, E>>`. O guia escreve `try await async.allOf([fetchUser(1), fetchUser(2)])` — Tasks
já iniciadas cujo valor é `@Result` — e a suíte `front/24-cells` segue o guia; já as células
`beam_memory_*` precisam de thunks não iniciados, porque no erlang uma Task ansiosa já rodou quando o
combinador a recebe. A implementação deu o nome `allOf` à forma do guia e outros nomes aos thunks.

**Hoje:**
```bp
val users = try await async.allOf([fetchUser(1), fetchUser(2)]);   // Tasks já iniciadas de @Result: para no primeiro Error
val xs = await async.runAll([{ -> work(1) }, { -> work(2) }]);     // thunks: é aqui que há concorrência
val r = await async.timeout({ -> slow() }, 100);                   // estourou → Error("timeout"), uma string
```

- [ ] **(a) ★** Iniciadas: `allOf`, `all`, `race`; não iniciadas: `runAll`, `raceOf`, `timeout`;
  `failed(message)` responde `Error(message)`; `allSettled`, `settleOf`, `unwrapAll` e `attempt` foram
  removidos (não há rejeição para "settle"). Um crash dentro de uma task é relançado.
  ```bp
  val users = try await async.allOf([fetchUser(1), fetchUser(2)]);
  async.allSettled([…])          // não existe mais
  ```
- [ ] **(b)** `allOf` sobre thunks, como o README da `01-std/02` escreveu — o exemplo do guia passa a
  ser escrito com thunks.
  ```bp
  val users = try await async.allOf([{ -> fetchUser(1) }, { -> fetchUser(2) }]);
  ```
- [ ] **(c)** Um `allOf` sobrecarregado para as duas formas de elemento — exige sobrecarga por tipo,
  que a linguagem não tem.
  ```bp
  async.allOf([fetchUser(1)])            // iniciadas
  async.allOf([{ -> fetchUser(1) }])     // thunks — mesmo nome, outra assinatura
  ```

**Recomendação: (a).** Segue o guia e a suíte da frente 24, e cada forma tem um nome só.
**Bloqueia:** `01-std/02-std-async-primitives`, cujo README ainda especifica o `allOf` sobre thunks.

### 01c-a · O átomo de um módulo comptime

**Contexto.** Um módulo gerado em comptime (por exemplo, o de um template de `html` do jhonstart)
vira um módulo com um átomo no erlang. O README da 13 escreveu o átomo no namespace do pacote dono
(`jhonstart@html__tpl__html__<hash>`) antes de a decisão 109 fazer todo átomo começar pelo seu pacote
e antes de o nó comptime passar a ser compartilhado por todos os pacotes do build. O caminho do dono
chega ao avaliador (`Env.comptimeOwners`); o PACOTE do dono não chega a `comptime/**` (o
`crossModule.Packages` é posto pelo driver só na config do codegen).

**Hoje:**
```text
bp@comptime@html__tpl__html__<hash>     decodifica como pacote `bp`, caminho `comptime/html`
```

- [ ] **(a) ★** O pacote reservado `bp`, com o caminho do dono — nenhum átomo de usuário colide (o
  `manifest` recusa um pacote chamado `bp`) e o hash continua endereçando o conteúdo.
  ```text
  bp@comptime@<caminho do dono>__tpl__<decl>__<hash>
  ```
- [ ] **(b)** No namespace do pacote dono — exige passar `Packages` para a inferência, e põe código
  rascunho endereçado por conteúdo no mesmo namespace dos módulos que o pacote publica.
  ```text
  jhonstart@html__tpl__html__<hash>
  ```

**Recomendação: (a).** Nada de usuário pode encontrá-lo, o arquivo de origem continua nomeado e não há
fio novo no compilador. **Bloqueia:** nada.

### 01c-b · Folha de seção com o atalho de ponto

**Contexto.** Um enum pode ter seções (o `Token` da emilia tem `Token.Text`, `Token.Layout.Break`…),
cada uma com suas folhas. Para uma variante de topo, o atalho `.Circle(…)` já é decidido pelo tipo
esperado da posição (frente 15). Para uma folha de seção, `.Zeta` contra `Token.Layout.Break` dava
`unbound variable 'Zeta'`, embora a aceitação do passo 4 (d) já escrevesse
`val t: Token.Text = .Bold;` como válido. A implementação usou a mesma regra: o tipo da posição diz a
seção.

**Hoje:**
```bp
val t: Token.Text = .Bold;      // compila: a posição diz qual é a seção
val u = .Bold;                  // recusado, nomeando a seção (não há tipo esperado)
val v: Token.Text = Token.Text.Bold;   // o caminho completo continua valendo (é o que a emilia escreve)
```

- [ ] **(a) ★** Atalho de ponto também para folha de seção, pela regra da posição; sem tipo esperado,
  recusa nomeando a seção.
  ```bp
  val b: Token.Layout.Break = .After;   // compila
  ```
- [ ] **(b)** Nenhum atalho para folha de seção — sempre o caminho completo, com uma recusa nomeada.
  ```bp
  val t: Token.Text = .Bold;            // recusado: escreva Token.Text.Bold
  ```

**Recomendação: (a).** Uma regra só para todo ponto inicial, e recusa onde a regra não tem resposta —
nada é escolhido por adivinhação. **Bloqueia:** nada; a emilia escreve o caminho completo e continua
compilando.

### ck2-a · `@module()` é recusado até um target o baixar

**Contexto.** `builtins.d.bp` declara `pub declare fn module() -> module;`, mas não existe tipo
`module` e nenhum backend baixava a chamada: o commonJS emitia `@module()` cru (`SyntaxError` ao
carregar) e o erlang chamava um `module/0` que não existe; o checker tipava como `void`. Ninguém
especificou o que é "o valor de um módulo".

**Hoje:**
```bp
val m = @module();      // error[builtin-not-lowered] no `@`   (reject/builtin_module_not_lowered)
```

- [ ] **(a) ★** Recusar no `@` até uma regra dizer o que é o valor de módulo.
  ```bp
  val m = @module();    // error[builtin-not-lowered]
  ```
- [ ] **(b)** Apagar a declaração de `builtins.d.bp` — o nome deixa de existir.
  ```bp
  val m = @module();    // error[unknown-builtin]
  ```
- [ ] **(c)** Especificar o valor de módulo e baixá-lo nos quatro backends.
  ```bp
  val m = @module();    // compila: m.name == "app/main" (ilustrativo)
  ```

**Recomendação: (a) agora;** (b) se nenhuma frente precisar do valor — um nome declarado sem
significado é uma promessa que o compilador não cumpre. **Bloqueia:** nada.

### ck2-b · Um membro de seção pode ter o nome de uma variante de topo do mesmo enum

**Contexto.** O `Token` da emilia declara `After(inner: Token[])` no topo e também
`Layout.Break { After }` numa seção. O checker resolve cada posição pelo caminho ou pelo tipo esperado,
e commonJS, erlang e beam rodam isso (`modules/enum_section_leaf_beside_variant`); o defeito era a
tabela plana do checker (corrigida) e continua no `case` do wasm (listado). Recusar o nome na
declaração foi implementado e medido: a emilia tem onze pares assim, todos nomes do Tailwind upstream
(`Sm`/`Md`/`Lg`/`Xl`/`X2xl` ao lado de `Text.Size.*`, `Alpha` ao lado de `Mask.Mode.Alpha`, `Empty`,
`First`, `Last`, `Dark`, `Transform`).

**Hoje:**
```bp
// Token declara `After(inner: Token[])` e também `Layout.Break { After }`
Token.After([…])                         // a variante com payload
val b: Token.Layout.Break = .After;      // a folha da seção
```

- [ ] **(a) ★** Legal: o caminho e o tipo da posição separam os dois (`docs.md` § Sections of an enum
  diz isso). Uma variante declarada duas vezes NO MESMO nível continua recusada.
  ```bp
  enum E { A, A }                          // error[enum-variant-duplicate]
  ```
- [ ] **(b)** Recusar na declaração — a emilia renomeia onze membros.
  ```bp
  Layout.Break { After }                   // error[enum-section-member-shadows-variant]
  ```

**Recomendação: (a).** Nada é ambíguo na linguagem: toda posição que nomeia o membro nomeia o seu
nível. **Bloqueia:** a emilia, se for (b).

### ck2-d · Label na chamada de um valor-função

**Contexto.** Um tipo de função (`fn(i32, string) -> string`) não carrega nomes de parâmetro. Antes,
uma chamada com labels num valor desses era checada e casada por posição: os labels eram ignorados, e
`f(s: "x", n: 1)` queria dizer `f("x", 1)` em silêncio.

**Hoje:**
```bp
fn apply(f: fn(i32, string) -> string) -> string {
    return f(n: 1, s: "x");      // error[label-on-function-value]   (reject/label_on_function_value)
}
```

- [ ] **(a) ★** Label na chamada de um valor-função é recusado, no argumento rotulado.
  ```bp
  return f(1, "x");              // a única forma aceita
  ```
- [ ] **(b)** Labels ignorados (a leitura antiga, silenciosa).
  ```bp
  return f(s: "x", n: 1);        // compila e vira f("x", 1)
  ```
- [ ] **(c)** Tipos de função carregam nomes, e o label tem de bater com um deles.
  ```bp
  fn apply(f: fn(n: i32, s: string) -> string) -> string {
      return f(s: "x", n: 1);    // compila: reordenado para f(1, "x")
  }
  ```

**Recomendação: (a).** É a mais restritiva; (c) é uma mudança grande de superfície para uma forma que
ninguém escreve. **Bloqueia:** nada.

### ck2-e · Um decorator do std é alcançado pelo módulo

**Contexto.** Um decorator como `#[mocks.mock]` gerava código (`@emit`) colado no módulo de quem usa,
onde o runtime de `mocks.bp` só é alcançável pelo handle que esse módulo importou (`mocks`, ou um
alias). Com um import folha (`import {testing.mocks.mock}`), o código emitido ficaria sem handle. A
implementação registra os decorators de um módulo importado como `#[<handle>.<fn>]` e recusa o import
folha. A metade "emite pelo handle da anotação" caduca com a remoção do `@emit` pela decisão 216; a
metade de alcance continua.

**Hoje:**
```bp
import {testing.mocks} from "std";
#[mocks.mock]                               // compila
#[mocks.helper]                             // error[unknown-annotation] — não é decorator
import {testing.mocks.mock} from "std";     // error[std-decorator-leaf-import]
```

- [ ] **(a) ★** Decorator do std só pelo handle do módulo; import folha recusado.
  ```bp
  import {testing.mocks as m} from "std";
  #[m.mock]                                 // compila, pelo alias
  ```
- [ ] **(b)** Permitir o import folha, com os nomes gerados resolvidos no módulo do decorator (a
  higiene da decisão 112 estendida).
  ```bp
  import {testing.mocks.mock} from "std";
  #[mock]                                   // compila
  ```

**Recomendação: (a) agora.** A alternativa é a resposta geral para o decorator de qualquer lib, e
precisa que a decisão 112 diga que cobre o que o decorator gera. **Bloqueia:** nada.

### rc3-b · `unknown` é a grafia do vocabulário host depois que `any` saiu

**Contexto.** A decisão 31 apagou `any`, e a correção dela disse que a remoção devia uma grafia nova às
declarações host: 51 do `std/erlang`, 10 do `std/beam`, os handles de `io.net` e `regex`, o
`getContext` de `builtins.d.bp`, o `deps: any[]` do jhonstart e três handles do rakun. `any` era um
tipo fechado: `erlang.element(1, t)` recusava um `i32`. A linguagem já tem `unknown` (decisão 8 §2),
que aceita qualquer valor e exige `is` antes do uso.

**Hoje:**
```bp
val v = erlang.element(1, t);       // o parâmetro é `unknown`: aceita o i32 (com `any` era recusado)
if (v is string) { @print(v); }     // e o resultado é testado com `is` antes de usar
pub type Socket(handle: unknown)    // io.net: o handle host
```

- [ ] **(a) ★** `unknown` (`run/host_unknown_parameter`).
  ```bp
  val v = erlang.element(1, t);     // v: unknown
  ```
- [ ] **(b)** Um tipo opaco `HostTerm`, que não aceita nenhum valor botopink — o fechamento do `any`
  com outro nome.
  ```bp
  val v: HostTerm = erlang.element(1, t);   // e passar um i32 onde se espera HostTerm é recusado
  ```
- [ ] **(c)** Um tipo botopink por declaração.
  ```bp
  pub declare fn abs(n: i64) -> i64;
  pub declare fn element(n: i32, t: unknown) -> unknown;
  ```

**Recomendação: (a).** A linguagem já tem o tipo que guarda qualquer valor; (c) é o refinamento em que
o vocabulário host pode crescer, uma declaração de cada vez. **Bloqueia:** nada.

### rc3-c · Atribuir a um `var` estreitado

**Contexto.** Depois de `if (x != null)`, um `var x: ?Node` é estreitado para `Node` dentro do bloco.
Antes, uma atribuição ali era checada contra o tipo estreitado: `x = x.next` dava
`expected Node, got ?Node` — e por isso o corpo de um `while (x != null)` nunca era estreitado. A
implementação checa contra o tipo declarado e encerra o estreitamento.

**Hoje:**
```bp
var x: ?Node = head;
while (x != null) { x = x.next; }         // compila: a atribuição checa contra `?Node`…
if (x != null) { x = x.next; x.value; }   // …e encerra o estreitamento: `x.value` é recusado
```

- [ ] **(a) ★** Atribuição checada contra o tipo declarado; o nome volta a esse tipo pelo resto do
  escopo (`reject/narrow_ends_at_assignment`).
  ```bp
  if (x != null) { x = x.next; if (x != null) { x.value; } }   // é preciso testar de novo
  ```
- [ ] **(b)** Flow typing: o nome fica com o tipo do valor atribuído.
  ```bp
  if (x != null) { x = Node(value: 1, next: null); x.value; }  // compila: continua Node
  ```
- [ ] **(c)** Proibir a atribuição dentro do escopo estreitado — recusa o percurso de lista ligada.
  ```bp
  while (x != null) { x = x.next; }       // recusado
  ```

**Recomendação: (a).** É correta sem análise de fluxo; (b) é o refinamento, (c) recusa o percurso de
lista que toda biblioteca escreve. **Bloqueia:** nada.

### 16-a · A lista de argumentos quebra junto com o que a envolve

**Contexto.** O formatador (C-12) só quebra uma construção quando ela não cabe em 80 colunas, e o
grupo de fora decide primeiro (decisão 65: tudo-ou-nada). Habilitada sozinha (o
`argument-list.patch` estacionado), a lista de argumentos abria ~1 480 de ~2 770 listas por causa do
que vinha DEPOIS delas (`) != -1;`, `) + "…"`), porque a expressão binária em volta estava fixada — o
"meio errado" da decisão 65. Por isso a implementação habilitou junto, cada uma com seu
`groupMeasured`: corrida binária, `if` sem chaves, lista de argumentos e literais de array, tupla e
behavior. Custo medido: 142 arquivos; linhas acima de 80 colunas 5 973 → 1 840; um segundo passe não
move nada.

**Hoje:**
```bp
assert doc.indexOf("…um argumento comprido…")
    != -1;                 // o binário quebra primeiro; a lista é medida na própria linha
```

- [ ] **(a) ★** A lista habilitada junto com as construções que a envolvem, a de fora decidindo
  primeiro.
  ```bp
  if (absDiff > tolerance)
      throw "…";           // o `if` sem chaves põe o ramo na linha seguinte, sem quebrar a condição
  ```
- [ ] **(b)** A lista habilitada sozinha (ou em commits separados — cada passo intermediário é um meio
  errado próprio, e as seis árvores seriam reformatadas duas vezes).
  ```bp
  assert doc.indexOf(
      "…um argumento comprido…",
  ) != -1;
  ```
- [ ] **(c)** Manter a lista fixada (nunca quebra).
  ```bp
  assert doc.indexOf("…um argumento comprido…") != -1;   // passa de 80 colunas
  ```

**Recomendação: (a).** É a única que não reformata nada duas vezes e não abre lista pelo que vem
depois; cobre também a metade "sem vírgula" da 166 (ver `ctr-s`). **Bloqueia:** o reformat das cinco
bibliotecas (09) e o passo 6 da 16-formatter.

### 16-b · Array aberto: um elemento por linha

**Contexto.** Antes, elementos escritos numa linha do fonte ficavam numa linha da saída. Quando a lista
passa a medir largura, isso não é idempotente (a linha junta passa de 80, uma chamada dentro dela
quebra, e o passe seguinte lê outro layout: 3 arquivos do corpus mudaram num segundo passe), e faz a
saída depender de como o fonte estava quebrado — o que a decisão 65 parte 2 proíbe.

**Hoje:**
```bp
val xs = [
    1,
    2,
    3,
];
```

- [ ] **(a) ★** Na forma aberta, um elemento por linha (tudo-ou-nada, decisão 65 parte 1).
  ```bp
  val xs = [1, 2, 3];      // cabe: fica fechado numa linha
  ```
- [ ] **(b)** `fill` de Wadler: quantos couberem por linha — o resultado passa a depender de como o
  fonte estava quebrado.
  ```bp
  val xs = [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
      21, 22, 23,
  ];
  ```

**Recomendação: (a).** É idempotente e não depende da entrada; o custo é que uma lista longa de
números curtos ocupa uma linha por número. **Bloqueia:** nada.

### 23-b · As quatro funções do `base64` foram aposentadas

**Contexto.** `base64.decode` devolvia uma `string`; o substituto `encoding.base64Decode` devolve
`@Result<string, string>` porque a frente 01 valida a entrada antes de o `Buffer.from` truncá-la
(idem `decodeUrlSafe` → `base64UrlDecode`). Nenhuma biblioteca importava `base64`. O `base64.bp` foi
apagado e seus quatro testes foram reescritos com os nomes do `encoding` (o std continua com 417
testes). A decisão 106 e `01-std/modules.md` já nomeiam os substitutos.

**Hoje:**
```bp
val s = try encoding.base64Decode(text);     // @Result<string, string>: valida antes de decodificar
base64.decode(text)                          // não existe mais
```

- [ ] **(a) ★** Aposentar as quatro (`encode` / `decode` / `encodeUrlSafe` / `decodeUrlSafe`).
  ```bp
  val raw = try encoding.base64UrlDecode(token);
  ```
- [ ] **(b)** Manter as quatro no `encoding` como apelidos que devolvem `string` (escondem a recusa).
  ```bp
  val s = encoding.decode("não é base64!");   // devolve uma string truncada, sem erro
  ```

**Recomendação: (a).** Duas grafias de um mesmo codec, uma delas escondendo a recusa, é o que a frente
01 removeu. **Bloqueia:** nada.

### 23-c · `botopink test` num projeto com módulos em pasta

**Contexto.** Quando o std passou a ter módulos em pasta (`io/random`, `io/net`), o `botopink test`
quebrou de dois jeitos: no commonJS, todo módulo `a/b` era lido como pertencente à dependência `a`
(`shipMjsSidecars`), e no erlang doze testes morriam com `{error,undef}` porque o `test_cmd` gravava as
unidades de tipo (`std@io@net@@Socket`) na raiz da execução, onde o runner de `io/net` não procura. Um
projeto de dois módulos (`src/top.bp`, `src/io/rec.bp`) reproduz o segundo em qualquer lugar.

**Hoje:**
```text
src/top.bp   src/io/rec.bp
$ botopink test --target erlang       # passa (antes: testes morriam com {error,undef})
$ botopink test --target commonJS     # passa (antes: module 'io/random' requires "./sidecars/random.mjs",
                                      #   but its library 'io' resolves to no package directory)
```

- [ ] **(a) ★** Duas correções gerais na CLI: um módulo cujo fonte está no `src` do próprio projeto é
  do projeto; as unidades de tipo são gravadas ao lado do módulo que as declara.
  ```text
  libs/std/src/io/net.bp   →   unidades de `Socket` gravadas junto de io/net, não na raiz
  ```
- [ ] **(b)** Manter o std plano no disco e aninhar só as chaves do registro.
  ```text
  libs/std/src/io_net.bp   (arquivo plano)  →  registrado como "io/net"
  ```

**Recomendação: (a).** As regras são gerais — qualquer biblioteca com módulo em pasta tinha os dois
defeitos — e nenhuma toca o compiler-core nem um snapshot. **Bloqueia:** nada.

### 0405-b · O vazio imprime `null` no commonJS

**Contexto.** Pela decisão 47, a ausência de valor imprime como `null`. O wasm já imprime todo `?T`
vazio como `null`, e o `Array.at` do commonJS responde `null`; mas duas formas do commonJS ainda
produziam o outro "vazio" do JavaScript — o `?.` nativo e um `if` sem `else` usado como valor — e
imprimiam `undefined`. A implementação corrigiu no impressor (`__bp_show`), que é onde a grafia é
decidida, e deixou o `== null` (já frouxo neste backend) intacto. Custo: 196 snapshots commonJS por
árvore ganharam uma linha de prelúdio. Erlang e beam são do C-18.

**Hoje:**
```bp
val r = if (n > 0) { "positive"; };
@print(r);                        // n = 0 → null   (antes: undefined)
@print(choose(false)?.kind);      // null
```

- [ ] **(a) ★** `__bp_show` imprime `undefined` como `null` — um ramo no impressor.
  ```bp
  @print(choose(false)?.kind);    // null   (o valor em JS continua `undefined`; só a impressão muda)
  ```
- [ ] **(b)** Baixar o `?.` e o `if` sem `else` para produzirem `null` de fato — move todo site de `?.`.
  ```js
  // commonJS emitido para choose(false)?.kind
  (__t = choose(false)) == null ? null : __t.kind
  ```

**Recomendação: (a).** O impressor é o lugar da grafia, e a mudança é um ramo só. **Bloqueia:** nada —
commonJS e wasm já imprimem a ausência como `null`.

### onze F7 · A regra da divisão inteira

**Contexto.** O `docs.md` não dizia o que `/` faz com dois inteiros. O achado F7 do onze mostrou que o
commonJS dividia todo `/` como float e imprimia `3.5`, enquanto o erlang usava `div`. A correção fez
`/` entre inteiros truncar em direção a zero e devolver inteiro em todos os backends
(`run/integer_division_truncates.bp`); a `status.md` da 1.0.10 registra que a regra espera sua
confirmação.

**Hoje:**
```bp
7 / 2        // 3
-7 / 2       // -3      trunca em direção a zero, nos quatro targets
7.0 / 2.0    // 3.5     divisão de float continua float
```

- [ ] **(a) ★** Inteiro / inteiro trunca em direção a zero e é inteiro (o `div` do erlang).
  ```bp
  fn half(n: i32) -> i32 { return n / 2; }
  @print(half(-7));      // -3
  ```
- [ ] **(b)** Divisão inteira arredondando para baixo (piso, como o `//` do Python).
  ```bp
  @print(-7 / 2);        // -4
  ```
- [ ] **(c)** `/` sempre devolve float; divisão inteira teria uma função própria.
  ```bp
  @print(7 / 2);         // 3.5
  @print(7.div(2));      // 3   (ilustrativo)
  ```

**Recomendação: (a).** É o que os quatro targets já fazem e o que o host erlang dá de graça; muda só o
`docs.md`, que passa a dizer a regra. **Bloqueia:** nada.

### libs-external-methods

### lem-a · Um método host é um método de verdade

**Contexto.** Um `declare fn` com `#[@External.*]` dentro do corpo de um `type` era aceito pelo parser
e pelo checker, mas nenhum backend o emitia (erlang `undef`, commonJS `… is not a function`, o beam
entrava em pânico em `lowerIdentAccess`, o wasm gerava um módulo inválido). Na binding, `$0` é o
receptor e `$1…` os argumentos depois dele. A implementação (`codegen/hostMethods.zig`) emite o método
como função do tipo — membro de classe no commonJS, função exportada do módulo do tipo no erlang —
cujo corpo é a binding: o mesmo invólucro que uma `pub declare fn` de módulo já ganha. Um método de um
tipo importado é respondido pelo dono (decisão 21), sem caminho novo no site da chamada.

**Hoje:**
```bp
pub type Socket(handle: unknown) {
    #[@External.Erlang("""… gen_tcp:recv(element(2, $0), $1, $2) …""")]
    pub declare fn recv(self: Self, length: i32, timeoutMillis: i32) -> @Result<string, string>;
}
sock.recv(10, 5000)      // chamada de método comum: o backend emite `recv` como função do tipo
```

- [ ] **(a) ★** Um lowering só: método real cujo corpo é a binding, nunca colado no site da chamada
  (custa um quadro de pilha a mais por chamada).
  ```bp
  val data = try sock.recv(10, 5000);   // chama a função `recv` do tipo Socket
  ```
- [ ] **(b)** Além disso, colar a binding no site da chamada dentro do módulo dono, como um template de
  módulo é — um segundo caminho a manter em acordo nos quatro backends.
  ```erlang
  %% erlang emitido no módulo dono, sem passar pela função do tipo (ilustrativo)
  case gen_tcp:recv(element(2, Sock), 10, 5000) of …
  ```

**Recomendação: (a).** Um caminho só; (b) é uma otimização com um segundo caminho para manter em quatro
backends. **Bloqueia:** nada.

### lem-c · Método sem binding é recusado onde é CHAMADO

**Contexto.** Uma função host de módulo sem binding para o target é recusada no site da chamada (06
C13). Um tipo, porém, é declarado uma vez e pode ser compilado para um backend em que um dos seus
métodos não tem binding. A implementação não emite o método e recusa a chamada feita por um receptor
de tipo inferido, com `MissingExternal` nomeando `Tipo.método` (`hostMethods.missingAt`). O wasm, sem
host, recusa toda chamada de método host — até com binding `External.Wasm` (no nível de módulo ela vira
`unreachable`). O índice é por NOME de tipo (dois módulos declarando o mesmo `Tipo.método` ficam com o
primeiro percorrido), e um receptor sem tipo inferido não é recusado: falha em tempo de execução, como
qualquer método desconhecido.

**Hoje:**
```bp
pub type Sock(handle: unknown) {
    #[@External.Erlang("""…""")]          // nenhuma binding Node
    pub declare fn recv(self: Self, length: i32) -> string;
}
sock.recv(10)        // no commonJS: error MissingExternal `Sock.recv`, na chamada
                     // o tipo em si compila
```

- [ ] **(a) ★** Recusa na chamada; o tipo compila para qualquer backend.
  ```bp
  val s = Sock(handle: h);   // compila no commonJS — só chamar `recv` é recusado
  ```
- [ ] **(b)** Recusar a declaração do tipo inteiro nesse backend.
  ```bp
  pub type Sock(handle: unknown) { … }   // commonJS: error MissingExternal `Sock.recv`, na declaração
  ```

**Recomendação: (a)** — e registrar que a decisão 146 vale para função COM corpo, livre ou método, que
alcança uma dessas (ver `ctr-o`). A assimetria do wasm se resolve no dia em que o wasm tiver host.
**Bloqueia:** a resolução de `ctr-o`.

### lem-d · Os nomes depois do colapso

**Contexto.** O `io.net` tinha uma função livre por tipo e operação (`listenerPort`, …) e o `regex`
tinha `runCompiled(r, input)` porque `matches(pattern, input)` já ocupava o nome. Com os métodos, o
receptor passa a dizer o dono, que era o que os prefixos faziam. Os construtores continuam funções de
módulo.

**Hoje:**
```bp
listener.accept(t)   sock.recv(n, t)   sock.close()   r.matches(s)
val l = try net.listen(8080);     // construtores: `listen`, `connect`, `tlsListen`, `tlsConnect`, `regex.compile`
```

- [ ] **(a) ★** Um nome por operação em todo tipo: `Listener.port/accept/close`,
  `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`,
  `Regex.matches`.
  ```bp
  l.port()     tls.accept(t)     r.matches(s)
  ```
- [ ] **(b)** Manter os nomes antigos como métodos.
  ```bp
  l.listenerPort()     r.runCompiled(s)
  ```

**Recomendação: (a).** O prefixo repetia o que o receptor já diz. **Bloqueia:** nada.

### lem-e · O que ficou função livre mesmo recebendo um tipo

**Contexto.** Depois do colapso, algumas funções que recebem um tipo do std continuaram livres:
`tlsEchoOnce(listener, length)` (instrumento de teste privado do `io.net`) e, no `validation`,
`rkvPush(v: Violation)`, `putMessageSource(source)` e `messageSourceOr(fallback)` (um armazenamento
global de processo, não uma operação sobre o valor). No erlang e no beam, um método é exportado pelo
módulo do seu tipo — então um auxiliar privado que virasse método entraria na superfície pública do
tipo.

**Hoje:**
```bp
fn rkvPush(v: Violation)                  // privado do `validation`: continua livre
fn tlsEchoOnce(listener, length)          // instrumento de teste do `io.net`: continua livre
```

- [ ] **(a) ★** Auxiliares privados ficam livres.
  ```bp
  rkvPush(v);                             // chamada de função, visível só no módulo
  ```
- [ ] **(b)** Virar método — e entrar na superfície pública do tipo no erlang e no beam.
  ```bp
  v.rkvPush();                            // exportado pelo módulo de `Violation`
  ```

**Recomendação: (a).** Privado continua privado. **Bloqueia:** nada.

### lem-f · O commonJS adota um registro construído pelo host

**Contexto.** Uma resposta do host declarada como record ficava um objeto JS cru no commonJS: os
campos liam, os métodos não existiam, e a impressão saía como `%O`. O erlang já adota mapas desde a
decisão 21 (`adoptHostResult`), e o `docs.md` prometia a adoção em todo backend. A implementação
(`__bp_adopt(v, C, path)`) dá à resposta o protótipo da classe — direto, através de `?T`, de um array e
do lado ok de um `@Result` — no site da chamada do dono, no invólucro exportado e no corpo de um método
host. Não olha dentro de `@Task`, e um alias `(module, symbol)` importado por outro módulo passa por
fora. O beam ainda não adota mapa host (linha do `03-beam`).

**Hoje:**
```bp
regex.compile(p).map({ r -> r.matches(s) })     // funciona (antes: "r.matches is not a function")
```

- [ ] **(a) ★** O commonJS adota a resposta na classe (`run/external_method_on_host_record`).
  ```bp
  val r = try regex.compile("a+");
  r.matches("aaa")                              // true — `r` é um Regex de verdade
  ```
- [ ] **(b)** O template tem de construir a classe — um template passa a nomear uma classe emitida.
  ```bp
  #[@External.Node("""new Regex(new RegExp($0))""")]   // o autor do template escreve o `new`
  pub declare fn compile(pattern: string) -> @Result<Regex, string>;
  ```

**Recomendação: (a).** Cumpre o que o `docs.md` prometia sem amarrar o template ao nome de uma classe
gerada. **Bloqueia:** nada.

### std e packaging

### 01std-a · Onde uma lib bundled é carregada

**Contexto.** Libs bundled (`routing`, `actions`, `validation`) vêm embutidas no binário, como o
`std`. A tabela da frente pedia generalizar o `expandStdImports` e trocar cada checagem de `"std"` no
core e nos codegens por uma busca; mas o caminho do `std` no core é específico de ponta a ponta, e uma
dependência declarada já chega aos codegens como módulos comuns `<dep>/<stem>` (decisão 109). A
implementação: o `build.zig` gera `comptime.bundled_packages`; a CLI (`appendBundled`) e o LSP
(`ProjectGraph.appendBundled`) acrescentam os módulos embutidos de cada lib bundled importada. O core
só conhece `std`; nenhum arquivo de codegen mudou.

**Hoje:**
```bp
import {pattern} from "routing";      // sem nenhuma linha em "dependencies"
```
```json
{ "dependencies": { "routing": { "path": "…" } } }     // recusado: `routing` é bundled
```

- [ ] **(a) ★** CLI e LSP carregam a lib bundled; para o core ela é código comum (como a decisão 115
  diz do `routing`).
  ```text
  botopink build   →  routing/pattern.bp entra como módulo `routing/pattern`, átomo routing@pattern
  ```
- [ ] **(b)** Generalizar o caminho do `std` dentro do core — mexe nos quatro codegens e no checker,
  sem diferença observável hoje.
  ```text
  expandStdImports(["std", "routing", "actions", "validation"])   (ilustrativo)
  ```

**Recomendação: (a).** O contrato observável vale igual, com menos código mexido. **Bloqueia:** nada;
o passo 3 da `00 · 23-std-purity` deve manter o `std` fora de `bundledPkgFiles`.

### 01std-c · O padrão vazio do `routing.pattern`

**Contexto.** No rakun-web, `matcherMatches("", path)` era verdadeiro para todo caminho — o padrão do
Next para um middleware sem `#[matcher]`; já o `routeMatches` não tinha essa regra. Uma gramática
compartilhada com o jhonstart não deveria carregar o padrão de um consumidor só.

**Hoje:**
```bp
parsePattern("")       // zero segmentos: casa só com "/"
matcherAdmits("", "/qualquer")   // rakun-web: true — a regra do middleware fica no site de chamada dele
```

- [ ] **(a) ★** O padrão vazio da lib casa só com `/`; o rakun-web mantém "matcher vazio roda em todo
  lugar" (`matcherAdmits`).
  ```bp
  routeMatches(try parsePattern(""), "/users")   // false
  ```
- [ ] **(b)** O padrão vazio da lib casa com tudo.
  ```bp
  routeMatches(try parsePattern(""), "/users")   // true — também para o jhonstart
  ```

**Recomendação: (a).** A regra de um consumidor fica no consumidor. **Bloqueia:** nada.

### 01std-e · `actions.readEnvelope` recusa um envelope incoerente

**Contexto.** O envelope de uma server action é um JSON
`{"v":1,"ok":…,"state":…,"revalidated":[…],"redirect":"…","n":"…","payload":"…"}`. O `n` é o sinal de
navegação (`"R|307|/login"` para um redirect) e o `writeEnvelope` DERIVA o `redirect` dele — não há
parâmetro, então o único escritor nunca produz um par que discorda. Um envelope que chega discordando
não foi escrito por ele.

**Hoje:**
```bp
readEnvelope("{\"v\":1,\"redirect\":\"/admin\",\"n\":\"R|307|/login\",…}")
// Error("actions.readEnvelope: `redirect` disagrees with the signal in `n`")
```

- [ ] **(a) ★** Recusar o envelope incoerente (decisão 67).
  ```bp
  val e = try readEnvelope(text);   // propaga o Error acima
  ```
- [ ] **(b)** Ler o `n` e ignorar o `redirect`.
  ```bp
  readEnvelope(text)                // Ok: redireciona para /login; o "/admin" é descartado
  ```

**Recomendação: (a).** É a mais restritiva: o que o escritor não produz, o leitor não aceita.
**Bloqueia:** nada.

### std-a · `querystring` recusa por `Error`, nos dois sentidos

**Contexto.** A `03r-e` do rakun mantém um componente malformado ou que decodifica para caractere de
controle *como escrito* (`decodeComponent("%0A") == "%0A"`). O `querystring` do std faz o contrário:
`parse` / `parseForm` devolvem `@Result` e recusam `%` sem dois dígitos hex, escape que não é UTF-8 e
caractere de controle cru ou decodificado; `stringify` recusa caractere de controle, para que todo
texto que ele escreve seja lido de volta pelo `parse`. Há dois leitores: `parse` é a query do RFC 3986,
`parseForm` o sabor de formulário. Igual em commonJS, erlang e beam (os catorze testes de
`libs/std/src/querystring.bp`).

**Hoje:**
```bp
querystring.parse("?a=1+2")              // Ok([#("a", "1+2")])    RFC 3986: `+` fica `+`, o `?` sai
querystring.parseForm("a=1+2")           // Ok([#("a", "1 2")])    formulário: `+` é espaço
querystring.parse("a=%zz")               // Error("a `%` not followed by two hex digits")
querystring.stringify([#("a", "\n")])    // Error: caractere de controle
```

- [ ] **(a) ★** Como está: recusa nos dois sentidos, dois leitores.
  ```bp
  val pairs = try querystring.parse(url.query);   // um componente ilegível não é lido
  ```
- [ ] **(b)** O "mantém como escrito" da `03r-e` no `parse`, e `stringify` infalível.
  ```bp
  querystring.parse("a=%zz")               // Ok([#("a", "%zz")])
  querystring.stringify([#("a", "\n")])    // "a=%0A"
  ```
- [ ] **(c)** Um `parse` só, com o sabor como parâmetro.
  ```bp
  querystring.parse("a=1+2", form = true)  // Ok([#("a", "1 2")])
  ```

**Recomendação: (a)** — a leitura restritiva (decisão 67): o que não pode ser lido não é lido, e o que
o próprio leitor recusaria não é escrito. A `03r-e` cai junto (ver `ctr-p`). **Bloqueia:** a mudança do
`splitQuery` / `encodeQuery` do rakun para o `querystring` (frente do rakun).

### std-b · `fs.exists` segue link simbólico

**Contexto.** `fs.exists` agora é um `stat` nos dois targets (`existsSync` / `file:read_file_info`):
`/`, `/dev/null`, um arquivo e um diretório dão `true` no commonJS e no erlang. Um link cujo alvo
sumiu dá `false` — a mesma resposta que uma leitura por ele daria.

**Hoje:**
```bp
fs.exists("/dev/null")          // true
fs.exists("link-quebrado")      // false — a mesma resposta que uma leitura daria
```

- [ ] **(a) ★** Segue o link (`stat`).
  ```bp
  if (fs.exists(path)) { val text = try fs.readText(path); }   // se existe, a leitura acha algo
  ```
- [ ] **(b)** `lstat` — um link pendurado existe como link.
  ```bp
  fs.exists("link-quebrado")      // true, e a leitura logo depois falha
  ```

**Recomendação: (a).** A pergunta de quem chama antes de ler é se a leitura vai achar alguma coisa.
**Bloqueia:** nada.

### std-c · O namespace de pasta é uma reescrita do programa

**Contexto.** A decisão 110 permite `import {io} from "std"` e depois `io.fs.readText(…)`. A
implementação (`comptime/std_namespace.zig`) reescreve o programa já lido para as formas folha que o
checker e os quatro backends já baixam: `io.fs.f()` vira o namespace de `io/fs` (o item
`io.fs as __bp_ns_io_fs` é acrescentado), e `collections.Dict` vira `Dict`. Só os módulos alcançados
são importados. Limites: um membro inexistente é `unbound variable 'io'`; um módulo que declara seu
próprio `Dict` de topo mantém `collections.Dict` sem reescrever (recusado do mesmo jeito); um local com
o nome da pasta (`fn f(io: …)`) não é distinguido dela. (Foi por aqui que a alternativa da 23-a entrou.)

**Hoje:**
```bp
import {io} from "std";
io.fs.readText(path)       // reescrito para o import folha `io.fs`; só os módulos alcançados são importados
io.nope.f()                // unbound variable 'io'
```

- [ ] **(a) ★** A reescrita: um arquivo, nenhum backend mexido.
  ```bp
  import {collections} from "std";
  val d = collections.Dict.empty();   // roda nos quatro targets
  ```
- [ ] **(b)** Um tipo-namespace no checker e um lowering de `a.b.f()` nos quatro backends, para o
  diagnóstico nomear a pasta.
  ```bp
  io.nope.f()                // error: std folder `io` has no module `nope`
  ```

**Recomendação: (a).** (b) só se o diagnóstico nomeando a pasta for desejado. **Bloqueia:** nada.

### 95-a · Os cortes de realocação `jhonstart-link` e `rakun-app`

**Contexto.** O `modules.md` do jhonstart põe o `link.bp` / `reconcile.bp` da frente 27 em
`jhonstart-link`, e o do rakun põe as frentes 22 e 23 (o app router) em `rakun-app`; as duas frentes já
tinham entrado no core. Nada nos cores importa os módulos movidos, então cada movimento é só os
arquivos mais as linhas de import: jhonstart 120 → 85 + 35 testes, rakun 369 → 310 + 59 no commonJS; o
`examples/rakun-ssr` imprime um documento idêntico byte a byte.

**Hoje:**
```bp
import {…} from "jhonstart-link";     // link.bp / reconcile.bp saíram do core do jhonstart
import {…} from "rakun-app";          // o app router (frentes 22 e 23) saiu do core do rakun
```

- [ ] **(a) ★** Realocar já, como movimento sem comportamento.
  ```text
  repository/rakun/modules/rakun-app/src/…   (59 testes, todos passando)
  ```
- [ ] **(b)** Deixar no core até as frentes donas (27 passo 4, 22/24) mexerem de novo.
  ```bp
  import {…} from "rakun";              // o app router continua no core
  ```

**Recomendação: (a).** Senão as frentes donas fariam o movimento no meio de uma mudança de
comportamento, que é o diff mais difícil de revisar. **Bloqueia:** nada.

### 95-b · `rakun-app` herda os `targets` do workspace (emendada)

**Contexto.** O core de onde o `rakun-app` saiu declarava `["commonJS"]`, e o `modules.md` do rakun diz
que todo membro é `["erlang"]`, corrigido pela frente de número mais baixo de cada módulo. Na época, as
alternativas eram copiar `["commonJS"]` do core ou fixar `["erlang"]`; a implementação não escreveu
`targets` e o membro seguiu o workspace. A emenda: depois que o rakun 04 mudou a raiz do workspace,
herdar dá `["erlang"]`.

**Hoje:**
```json
{ "name": "rakun-app" }        // sem "targets": segue o workspace, que hoje é ["erlang"]
```

- [ ] **(a) ★** Sem `targets` no membro: segue o workspace sem edição.
  ```json
  { "name": "rakun-app" }
  ```
- [ ] **(b)** Declarar `targets` no próprio membro — uma cópia que precisa ser editada quando o
  workspace mudar.
  ```json
  { "name": "rakun-app", "targets": ["erlang"] }
  ```

**Recomendação: (a).** Uma fonte só para os targets. **Bloqueia:** nada.

### 95-c · `erika-test` existe

**Contexto.** O `02-packaging/README.md` § 2 torna obrigatório um `modules/<lib>-test/` para toda
biblioteca. A erika é workspace desde o passo 2 do `02-packaging`, e o `AGENTS.md` dela dizia que o
membro esperava os passos 2–3 do `01-std`, que já entraram. A tabela da frente 95 não listava a erika.

**Hoje:**
```text
repository/erika/modules/erika-test/      # um teste inline, 1/1 nos dois targets
```

- [ ] **(a) ★** Criar o membro agora, com um teste.
  ```text
  $ botopink test     # erika-test: 1/1 commonJS, 1/1 erlang
  ```
- [ ] **(b)** Esperar uma frente da erika — até lá a regra do § 2 fica sem cumprir na erika.
  ```text
  repository/erika/modules/       # sem erika-test
  ```

**Recomendação: (a).** Cumpre a regra do packaging sem custo. **Bloqueia:** nada.

### 95-e · Import qualificado do contexto de request

**Contexto.** Ao mover o app router para `rakun-app`, o `ssr.bp` passou a importar do pacote `rakun`, e
o compilador recusou: `percentDecode` é `pub` tanto em `std/encoding` quanto em
`rakun/request_context`, e o import não diz qual. Dentro do core, o mesmo import já nomeava o módulo.
A decisão 116 leva o codec do rakun para o `encoding` do std, o que aposentaria o duplicado.

**Hoje:**
```bp
import {request_context.percentDecode} from "rakun";     // forma da decisão 206
import {percentDecode} from "rakun";                     // recusado: `pub` em std/encoding e em rakun/request_context
```

- [ ] **(a) ★** Manter o import que nomeia o módulo.
  ```bp
  import {request_context.percentDecode} from "rakun";
  ```
- [ ] **(b)** Renomear um dos dois `percentDecode`.
  ```bp
  import {percentDecode} from "rakun";      // compila: o do rakun virou outro nome (ilustrativo)
  ```

**Recomendação: (a) agora;** renomear é o trabalho da decisão 116 (o codec do rakun vai para o
`encoding` do std), depois do qual a linha pode voltar a `from "rakun"`. **Bloqueia:** nada.

### rakun

### 03r-a ★ · Todo manifest do rakun é `["erlang"]`

**Contexto.** A decisão 117 (regra 9) põe todo membro do rakun só no target erlang, e a 113 apaga o
`runtime.mjs` (o gêmeo node do runtime). Quando a thread mudou os manifests (rakun `99b8049`), os
três exemplos compilavam mas não rodavam: um programa erlang construído não levava os seus `.erl`
de sidecar (`undef rakun_runtime:serve/2`). O compilador fechou essa metade: `botopink build
--target erlang` copia os `.erl` do pacote para `out/erl/` e o `botopink run` os compila no code
path; a metade do ledger (`restricted-targets.txt`) ficou sem efeito com a decisão 153. A thread
escolheu (a) porque (b) mantém vivo o segundo runtime que a 113 aposentou.

**Hoje:**
```json
// repository/rakun/modules/rakun/botopink.json (e todo outro membro, starters e exemplos)
{ "name": "rakun", "target": "erlang", "targets": ["erlang"] }
```

- [ ] **(a)** ★ manter — um só runtime (BEAM); os exemplos rodam pelos sidecars que o build copia
  ```sh
  $ cd examples/rakun && botopink build --target erlang   # copia os 5 .erl para out/erl/
  $ botopink run                                          # compila os .erl e sobe o servidor
  ```
- [ ] **(b)** exemplos em commonJS, com um gêmeo node mantido só para eles — dois runtimes de novo
  ```json
  { "name": "rakun-example", "targets": ["commonJS"] }   // + src/runtime.mjs de volta, só para os exemplos
  ```
- [ ] **(c)** esperar o compilador antes de mudar — os manifests ficam com os dois targets até lá
  ```json
  { "name": "rakun", "targets": ["erlang", "commonJS"] }   // e o runtime.mjs sobrevive por um marco
  ```

**Recomendação: (a).** O compilador já entrega o que faltava, e (b)/(c) devolvem o runtime node
que a 113 retirou. **Bloqueia:** nada.

### 03r-c ★ · Os leitores de config ficam em botopink

**Contexto.** A definição de pronto da frente 05 pedia um sidecar `src/sidecars/rakun_config.erl`.
A frente escreveu os leitores (`.properties`, `.yaml`, `.json`, perfis) em botopink sobre o `fs` e
o `env` do std, e o `.json` passou a ser lido pelo `json.decode` do std (rakun `b742a4c`). Um
leitor em botopink não tem metade host para manter em sincronia com o resto.

**Hoje:**
```bp
val cfg = try json.decode(text);     // o `.json` de config é lido pelo `json.decode` do std; não existe `rakun_config.erl`
```

- [ ] **(a)** ★ manter — sem sidecar; a caixa da frente 05 é emendada
  ```bp
  // modules/rakun/src/profiles.bp
  import {json.decode, fs, env} from "std";
  val text = try fs.readText(dir + "/application.json");
  val cfg = try json.decode(text);
  ```
- [ ] **(b)** portar os leitores para Erlang — uma metade host a manter
  ```bp
  #[@External.Erlang("rakun_config", "read_json")]
  declare fn __rkReadJson(path: string) -> @Result<Json, string>;   // + src/sidecars/rakun_config.erl
  ```

**Recomendação: (a).** Menos código host, o mesmo comportamento nos dois lados do std.
**Bloqueia:** nada.

### 03r-d ★ · A checagem de configuração roda no boot

**Contexto.** Um registro marcado `#[configurationProperties]` + `#[validated]` é validado contra o
que está no arquivo de config. O `Rakun.run` (`bootstrap.bp`) está congelado; quem constrói os
componentes é o `bootSequenceFor` da frente 06. rakun `c8f185c` registra uma checagem por registro
no load do módulo e roda todas depois do evento 3, antes da passada eager — inclusive com
`lazy-initialization`, que trata de *quando construir*, não de *validar*.

**Hoje:**
```bp
#[validated]
#[configurationProperties("my.service")]
type MyService(enabled: bool, remoteAddress: string, retries: i32)
// application.properties:  my.service.retries=abc
```

- [ ] **(a)** ★ manter — o boot é recusado, mesmo com `lazy-initialization=true`
  ```text
  $ botopink run
  rakun: boot refused: my.service.retries: "abc" is not an integer   (em bootSequenceFor)
  ```
- [ ] **(b)** só falhar no primeiro request que injeta o registro — o servidor sobe com config inválida
  ```text
  servidor no ar na porta 8080
  GET /status  →  500  (my.service.retries: "abc" is not an integer)
  ```

**Recomendação: (a).** Configuração inválida não pode esperar o primeiro request (decisão 67: a
opção mais restritiva). **Bloqueia:** nada.

### 03r-e ★ · Componente de cookie/query nunca decodifica para caractere de controle

**Contexto.** O `encoding.percentDecode("%0A")` do std devolve uma quebra de linha; o decoder da
frente 62 mantinha `%0A` como escrito, porque um decoder que produz quebra de linha é o caminho por
onde uma quebra de linha chega num header. rakun `98a5090` lê pelo `decodeComponent`
(`request_context.bp`): a decodificação do std, mas uma entrada que o std recusa (`%zz`, `100%`) ou
que decodificaria para caractere de controle fica exatamente como escrita. A contradição `ctr-p`
(Parte 1) diz que isto cai quando o rakun ler query pela `querystring` e cookie pelo `http` (196).

**Hoje:**
```bp
decodeComponent("%0A")      // "%0A" — fica como escrito
decodeComponent("%zz")      // "%zz"
decodeComponent("a%20b")    // "a b"
```

- [ ] **(a)** ★ manter — sem caractere de controle saindo de cookie ou query
  ```text
  Cookie: lang=pt%0ASet-Cookie:%20x=1   →  lang = "pt%0ASet-Cookie: x=1"   (o %0A não vira quebra de linha)
  ```
- [ ] **(b)** o decode do std ao pé da letra — `%0A` vira quebra de linha
  ```bp
  encoding.percentDecode("pt%0Ax")    // Ok("pt\nx") — chega assim ao handler
  ```

**Recomendação: (a) até o rakun passar a ler pela `querystring` e pelo `http`** — aí ela cai, e a
recusa da `querystring` (std-a) assume o papel (ver `ctr-p`). **Bloqueia:** nada.

### 03r-f ★ · Chave de cache por `hash.strongCacheKey`

**Contexto.** O README escrevia a chave como `namespace + ":" + contentHash(parts.join("\u{1f}"))`.
Juntar com separador deixa `["a\u{1f}b"]` igual a `["a", "b"]`, e o `contentHash` do std é um
djb2 fácil de colidir de propósito — e a chave carrega entrada do request e, no escopo privado, o
id de sessão. O `hash.strongCacheKey(parts)` do std prefixa cada parte com o tamanho e usa SHA-256
(32 hex).

**Hoje:**
```bp
// modules/rakun-cache/src/cache.bp
pub fn cacheKey(namespace: string, parts: Array<string>) -> string {
    return namespace + ":" + hash.strongCacheKey(parts);
}
```

- [ ] **(a)** ★ manter — chaves que não colidem
  ```bp
  cacheKey("products", ["a\u{1f}b"])     // diferente de…
  cacheKey("products", ["a", "b"])       // …esta: cada parte leva o tamanho, SHA-256
  ```
- [ ] **(b)** `contentHash(parts.join("\u{1f}"))` — as duas chaves colidem
  ```bp
  "products:" + hash.contentHash(["a\u{1f}b"].join("\u{1f}"))   // == "products:" + hash.contentHash(["a", "b"].join("\u{1f}"))
  ```

**Recomendação: (a).** Um cache que colide através da fronteira de usuário serve a página de um
usuário para outro. **Bloqueia:** nada.

### 03r-g ★ · Leitura de escopo privado sem sessão

**Contexto.** `CacheScope.Private` usa o id da sessão como chave; um request pode não ter sessão,
e o README não dizia o que acontece. O rakun-cache lê `optionalSession()` (frente 18) e, sem
sessão, não usa cache nenhum (`key_test.bp`).

**Hoje:**
```bp
#[cacheable("cart", scope: CacheScope.Private)]
fn cartSummary() -> string { … }
// request anônimo, sem cookie de sessão
```

- [ ] **(a)** ★ manter — roda o loader e não guarda nada
  ```text
  GET /cart (sem sessão)  →  cartSummary() roda, resposta 200, nenhuma linha gravada, nenhum Set-Cookie
  ```
- [ ] **(b)** criar uma sessão para servir de chave — ler cache passa a criar sessão e cookie
  ```text
  GET /cart (sem sessão)  →  200  +  Set-Cookie: RAKUNSESSION=…   (uma sessão por visitante anônimo)
  ```
- [ ] **(c)** levantar erro — a página anônima falha por causa de uma anotação de cache
  ```text
  GET /cart (sem sessão)  →  500  rakun-cache: private scope read without a session
  ```

**Recomendação: (a).** Não cria estado nem quebra a página; só perde o cache onde não há dono.
**Bloqueia:** nada.

### 03r-h ★ · A chave do gêmeo e o `#[cacheEvict(name, false)]`

**Contexto.** O README lê `cacheKey("products", ["productJson", id])` no `peekCachedProduct`, então
uma linha de `#[cacheable]` é chaveada por nome do método + argumentos. Aí "a chave construída com
os argumentos do método" de um `#[cacheEvict(name, false)]` não casaria com nada, a menos que seja
construída sob o nome de um leitor. A thread fez o evict remover `[m, args…]` para todo leitor `m`
daquele cache (fixture `twin`).

**Hoje:**
```bp
#[cacheable("products")]            fn productJson(id: i32) …     // chave ["productJson", id]
#[cacheable("products")]            fn productHtml(id: i32) …     // chave ["productHtml", id]
#[cacheEvict("products", false)]    fn rename(id: i32) …
```

- [ ] **(a)** ★ manter — `rename(7)` remove `["productJson", 7]` e `["productHtml", 7]`, e só essas
  ```text
  rename(7)  →  apaga products:[productJson,7] e products:[productHtml,7]; products:[productJson,8] fica
  ```
- [ ] **(b)** chave só pelos argumentos (o padrão do Spring) — dois leitores do mesmo cache dividem linhas
  ```text
  productJson(7) grava products:[7] = "{…}"
  productHtml(7) lê products:[7] e devolve o JSON no lugar do HTML
  ```

**Recomendação: (a).** Cada leitor tem a sua linha, e o evict acerta todas as de um argumento.
**Bloqueia:** nada.

### 03r-i ★ · O provider Redis do cache

**Contexto.** O README apontava o cliente da frente 13 (`rakun-client`) como transporte Redis, mas
ele só fala HTTP; o rakun-session já tem um wire RESP (`rkSessRedis`). O Redis expira linhas
sozinho e não tem o estado "servir uma vez o antigo e atualizar". A thread reaproveitou o wire do
rakun-session; a aresta para `rakun-client` em `modules.md` não foi usada.

**Hoje:**
```properties
rakun.cache.type=redis
rakun.cache.redis.url=redis://localhost:6379
```

- [ ] **(a)** ★ manter — wire do rakun-session; sem janela stale; Redis fora do ar = sem cache
  ```text
  Redis fora do ar  →  a leitura roda o loader sem cache e o health reporta DOWN
  revalidateTag     →  apaga as linhas (o Redis não tem "servir uma vez e atualizar")
  ```
- [ ] **(b)** um cliente RESP no `rakun-client` — um segundo wire Redis no projeto
  ```bp
  import {redisClient} from "rakun-client";
  val r = redisClient("redis://localhost:6379");   // novo, ao lado do rkSessRedis
  ```
- [ ] **(c)** um marcador stale num hash do Redis — `revalidateTag` marca em vez de apagar
  ```text
  HSET rakun:stale products:… 1   →  próxima leitura serve o antigo e atualiza em background
  ```

**Recomendação: (a).** Um wire RESP só, e nada de estado stale inventado por cima do Redis.
**Bloqueia:** nada.

### 03r-j ★ · Fora de request; e `none` vence o tipo por cache

**Contexto.** A tabela de legalidade das revalidações tem três colunas (action, handler, render),
mas um job agendado ou um hook de boot roda sem request. Separado disso, `rakun.cache.type=none`
junto com `rakun.cache.<nome>.type=ets` não estava resolvido. A thread leu "sem request" como fase
`none` e fez o `none` global desligar tudo, como o `spring.cache.type=none` do Spring
(`revalidate_test.bp`, `store_test.bp`).

**Hoje:**
```properties
rakun.cache.type=none
rakun.cache.products.type=ets
```

- [ ] **(a)** ★ manter — revalidar é legal fora de request, `updateTag` não; `none` é chave geral
  ```text
  job agendado:   revalidateTag("users")  legal   ·   updateTag("users")  levanta erro
  rakun.cache.type=none  +  rakun.cache.products.type=ets   →  tudo desligado
  ```
- [ ] **(b)** recusar os três fora de request; o tipo por cache vence o `none` global
  ```text
  job agendado:   revalidateTag("users")  levanta erro
  rakun.cache.type=none  +  rakun.cache.products.type=ets   →  só "products" continua em ETS
  ```

**Recomendação: (a).** `updateTag` (ler a própria escrita) não tem sentido sem request, e a chave
geral não pode ser derrubada por uma linha de config (decisão 67). **Bloqueia:** nada.

### 03r-k ★ · Todo braço de messaging roda no broker em processo

**Contexto.** Os drivers do README — `amqp_client`, `brod`, `rabbitmq_stream_client` — são
aplicações OTP, e um sidecar só carrega os `.erl` ao lado do módulo emitido (linha de
`language-gaps.md` sobre aplicações OTP externas). Escrever AMQP 0-9-1, Kafka ou Streams sobre
`gen_tcp` é uma frente por protocolo. A thread pôs os quatro braços num broker em processo e
recusa o boot quando a config aponta um broker real.

**Hoje:**
```properties
rakun.messaging.amqp.transport=memory
```

- [ ] **(a)** ★ manter — broker em processo explícito; endereço real sem `memory` recusa o boot
  ```text
  rakun.messaging.amqp.host=rabbit.local   (sem transport=memory)
  →  boot recusado: rakun-messaging: rakun.messaging.amqp.host needs amqp_client, which is not available
  ```
- [ ] **(b)** cair no broker em processo em silêncio — a aplicação acha que fala com o RabbitMQ
  ```text
  rakun.messaging.amqp.host=rabbit.local  →  boot ok; as mensagens nunca saem do nó
  ```
- [ ] **(c)** escrever os protocolos agora — uma frente por protocolo
  ```text
  modules/rakun-messaging/src/sidecars/rakun_amqp091.erl, rakun_kafka_wire.erl, rakun_streams.erl
  ```

**Recomendação: (a).** (b) engana em produção; (c) é trabalho de várias frentes. As células de
integração esperam (c) ou o fim da lacuna de sidecars. **Bloqueia:** nada.

### 03r-l ★ · O container tem o nome do destino; Redis é ack-mode none

**Contexto.** Os marcadores de listener não levam nome de container; os exemplos do README
configuravam `listener.orders.*` para a fila `orders` mas `listener.audit.*` para o stream
`audit-stream`. O ack-mode padrão era `auto` em todo braço, e o Redis só aceita `none`. A thread
fez o container ter o nome do destino e o Redis começar em `none`; o exemplo de stream passou a
ler `listener.audit-stream.*`.

**Hoje:**
```bp
#[rabbitListener("orders")]            fn onOrder(m: Message) …
#[streamListener("audit-stream")]      fn onAudit(m: Message) …
```

- [ ] **(a)** ★ manter — sem argumento extra; Redis sem config de ack
  ```text
  fila `orders`           →  rakun.messaging.listener.orders.*
  stream `audit-stream`   →  rakun.messaging.listener.audit-stream.*
  Redis                   →  ack-mode padrão `none`; `auto` ou `manual` explícito recusa o boot
  ```
- [ ] **(b)** um argumento de container em todo marcador
  ```bp
  #[streamListener("audit-stream", container: "audit")]   fn onAudit(m: Message) …   // lê listener.audit.*
  ```
- [ ] **(c)** `auto` como padrão do Redis — todo listener Redis precisa de uma linha para subir
  ```properties
  rakun.messaging.listener.notifications.ack-mode=none   # sem isto, boot recusado
  ```

**Recomendação: (a).** Nada a escrever a mais, e o Redis sobe com o único modo que ele aceita.
**Bloqueia:** nada.

### 03r-m ★ · Dentro de uma server action, revalidar expira na hora

**Contexto.** Na frente 12, `revalidateTag` / `revalidatePath` marcam linhas como stale: a próxima
leitura serve o valor antigo uma vez e atualiza em background. A frente 24 exige que o re-render da
própria action seja feito "a partir do cache invalidado e preenchido", e afirma o valor novo no
documento. A thread fez as duas expirarem na hora na fase `action` (como o `updateTag`), que é o
comportamento do Next.

**Hoje:**
```bp
#[serverAction]
fn publish(form: FormData) -> ActionResult {
    savePost(form);
    revalidateTag("posts");
    return ok();
}
```

- [ ] **(a)** ★ manter — dentro da action expira; fora, stale-then-fresh
  ```bp
  revalidateTag("posts");     // numa action: expira já — o re-render da própria action mostra o valor novo
                              // fora de action: marca stale (serve o antigo uma vez, atualiza em background)
  ```
- [ ] **(b)** a frente 24 chama `updateTag` para cada caminho registrado
  ```bp
  for (recordedPaths()) { p -> updateTag(p); }   // feito pelo runtime das actions, não pelo cache
  ```
- [ ] **(c)** o re-render espera as atualizações em background
  ```text
  POST /publish  →  re-render bloqueia até o refresh de "posts" terminar  →  documento com o valor novo
  ```

**Recomendação: (a).** É a regra do Next, num lugar só (o rakun-cache). **Bloqueia:** nada.

### 03r-n ★ · Argumento de JSON-RPC é uma lista de campos form-encoded

**Contexto.** O corpo RPC de uma server action é `{"v":1,"id":…,"args":["…"]}`, a action recebe
um `FormData`, e o passo 6 exige que a chamada RPC e "o POST de formulário equivalente" deem o mesmo
estado. Nada dizia como strings posicionais viram campos com nome. A thread lê cada argumento como
uma lista `nome=valor` form-encoded, em ordem, num formulário só; a frente 67 pode escrever
`args: [formStringify(fields)]`.

**Hoje:**
```json
{"v":1,"id":"…","args":["title=Hello&draft=true"]}
```

- [ ] **(a)** ★ manter — mesmos nomes de campo do formulário
  ```text
  args: ["title=Hello&draft=true"]   ≡   POST  title=Hello&draft=true   →  form.get("title") == "Hello"
  ```
- [ ] **(b)** o argumento `i` é o campo chamado `i`
  ```text
  args: ["Hello", "true"]   →  form.get("0") == "Hello", form.get("1") == "true"
  ```
- [ ] **(c)** o primeiro argumento é o corpo inteiro
  ```text
  args: ["title=Hello&draft=true", "ignorado"]   →  só o primeiro é lido
  ```

**Recomendação: (a).** É a única que dá exatamente o estado do POST de formulário. **Bloqueia:** nada.

### 03r-o ★ · Campo de segment config igual ao default conta como não declarado

> **Sem objeto desde a 290:** a configuração de segmento foi apagada (`revalidate` e `dynamicParams` são
> argumentos do `#[page]`), então não há mais herança de layout para página. Nada a confirmar.

**Contexto.** O `configFor` tem de sobrescrever o config do ancestral "campo a campo, não inteiro":
um segmento que só define `revalidate` mantém o `dynamic` do ancestral. Mas `SegmentConfig` é um
registro — todo campo está sempre preenchido, e os defaults de parâmetro não são aplicados, então
um registro escreve os quatro campos. A thread trata um campo igual ao de `defaultSegmentConfig()`
como herdado.

**Hoje:**
```text
layout:  `dynamic` fora do default
page:    só `revalidate = 60`        →  a página mantém o `dynamic` do layout
```

- [ ] **(a)** ★ manter — igual ao default = herda; diferente = sobrescreve
  ```bp
  // layout: dynamic = "force-dynamic"; page: SegmentConfig(..defaultSegmentConfig(), revalidate: 60)
  configFor(page).dynamic     // "force-dynamic" — o que não dá: "volte este campo ao default" abaixo do layout
  ```
- [ ] **(b)** um segundo registro só de campos opcionais, para o registro de segmento
  ```bp
  SegmentConfigPatch(revalidate: 60)            // dynamic ausente = herda; dynamic: "auto" = volta ao default
  ```
- [ ] **(c)** substituição por inteiro
  ```text
  page com só `revalidate = 60`  →  dynamic volta a "auto" (o do layout se perde)
  ```

**Recomendação: (a)** agora; (b) é o formato certo quando existirem campos opcionais em registro.
**Bloqueia:** nada.

### 03r-p ★ · O slot é do layout mais próximo acima; só um slot conflita consigo mesmo

**Contexto.** Rotas paralelas: uma pasta `@slot` renderiza ao lado da página no mesmo layout. O
registro da frente 22 descarta o segmento `@slot` (`dashboard/@team/settings` vira
`P|/dashboard/settings|team`), então o registro não diz sob qual layout o slot fica. E o passo 2
recusava "dois slots na mesma URL sob um layout" — mas o próprio dashboard do `§ 21` tem
`@analytics` e `@team` em `/dashboard`, que é o recurso.

**Hoje:**
```text
app/dashboard/@analytics/page.bp
app/dashboard/@team/page.bp             →  os dois renderizam em /dashboard (é o recurso)
app/dashboard/@team/(a)/page.bp + (b)/page.bp   →  conflito: duas páginas de UM slot na mesma URL
```

- [ ] **(a)** ★ manter — dono = o `L` mais próximo no/acima do caminho mais curto do slot
  ```text
  $ botopink run
  rakun-app: slot @team has two pages at /dashboard: (a)/page.bp, (b)/page.bp
  ```
- [ ] **(b)** guardar a profundidade do slot no registro da frente 22 — muda o contrato 1
  ```text
  P|/dashboard/settings|team|2     (novo campo: profundidade do @team)
  ```
- [ ] **(c)** ler o conflito como escrito — recusa o exemplo do próprio `§ 21`
  ```text
  app/dashboard/@analytics + @team  →  recusado: two slots claim /dashboard
  ```

**Recomendação: (a).** (b) mexe no contrato que a frente 22 possui; (c) proíbe o recurso.
**Bloqueia:** nada.

### 03r-q ★ · Roteamento por locale mora no `rakun-app`

**Contexto.** O README da frente 64 reservava `modules/rakun-i18n/**`, mas `modules.md` § The cut
põe "negociação de i18n" no `rakun-app`, e o módulo precisa dos vizinhos dele de qualquer forma (a
cadeia de layouts, o cache, a navegação da frente 63). Os exemplos importam de `"rakun-app"`.

**Hoje:**
```bp
import {…} from "rakun-app";       // src/i18n.bp
```

- [ ] **(a)** ★ manter — `rakun-app/src/i18n.bp`
  ```bp
  import {localeOf, htmlLang} from "rakun-app";
  ```
- [ ] **(b)** um membro novo `rakun-i18n`
  ```bp
  import {localeOf, htmlLang} from "rakun-i18n";   // modules/rakun-i18n/botopink.json, depende de rakun-app
  ```

**Recomendação: (a)** (a 105 extrai o que for comum para o bundled `i18n`; mover um arquivo é
barato se um serviço sem app router precisar de locale). **Bloqueia:** nada.

### 03r-r ★ · Starters nomeiam os irmãos com `workspace: true`

**Contexto.** O passo 1 da frente 73 escrevia `"rakun-web": { "path": "../../modules/rakun-web" }`.
Com `starters/*` nos `workspaces` do rakun, o loader recusa essa entrada ("path points at the
sibling member … — use { "workspace": true }"); fora do workspace os starters não seriam células
do `test-libs`. O resolvedor de runtime (`resolvedModuleListIn`) segue as duas formas, então um
consumidor que aponta `path` para um starter ainda alcança todo módulo. O `onze` está fora do
repositório e continua `path`.

**Hoje:**
```json
{ "rakun-web": { "workspace": true } }
{ "rakun-web": { "path": "../../modules/rakun-web" } }     // recusado dentro do workspace
```

- [ ] **(a)** ★ manter — starters são membros do workspace e testados pelo `test-libs`
  ```json
  // starters/web/botopink.json
  { "dependencies": { "rakun": { "workspace": true }, "rakun-web": { "workspace": true } } }
  ```
- [ ] **(b)** tirar `starters/` do `workspaces` — escrevem `path`, deixam de ser células do `test-libs`
  ```json
  // botopink.json da raiz:  "workspaces": ["modules/*"]
  { "dependencies": { "rakun-web": { "path": "../../modules/rakun-web" } } }
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 03r-s ★ · OTLP é enviado como HTTP/JSON

**Contexto.** A frente 75 dizia "push HTTP/protobuf". Nem o OTP nem o std têm encoder protobuf, e
escrever um para as mensagens de métricas e traces do OTLP é muita superfície. O OTLP/HTTP aceita
`application/json` com as mesmas mensagens nos mesmos caminhos, e todo coletor que aceita protobuf
aceita JSON. O `rakun_metrics.erl` monta o JSON com `json:encode`.

**Hoje:**
```text
POST /v1/metrics     Content-Type: application/json
POST /v1/traces      Content-Type: application/json
```

- [ ] **(a)** ★ manter — HTTP/JSON, sem encoder novo
  ```text
  POST http://collector:4318/v1/metrics   Content-Type: application/json   {"resourceMetrics":[…]}
  ```
- [ ] **(b)** um encoder protobuf no sidecar
  ```text
  POST http://collector:4318/v1/metrics   Content-Type: application/x-protobuf   <bytes>
  ```

**Recomendação: (a).** (b) entra ao lado do JSON se algum coletor só aceitar protobuf.
**Bloqueia:** nada.

### 03r-t ★ · As chaves da frente 76 ficam sob `rakun.management.*`

**Contexto.** A frente 76 escrevia `rakun.endpoints.web.exposure.include`,
`rakun.endpoint.<id>.access`, `rakun.endpoints.access.max-permitted` e seis arquivos. A frente 11 já
lê `rakun.management.endpoints.web.base-path`, `…path-mapping.<id>`, `…cors.*` — o prefixo
`management.` do Spring. A thread pôs tudo sob `rakun.management.` num `management.bp` mais o
sidecar `rakun_probes`.

**Hoje:**
```properties
rakun.management.endpoints.web.base-path=/actuator        # frente 11
rakun.management.endpoints.web.exposure.include=health,info
```

- [ ] **(a)** ★ manter — um prefixo só para todo o actuator, como o upstream
  ```properties
  rakun.management.endpoints.web.exposure.include=health,info
  rakun.management.endpoint.health.access=read-only
  rakun.management.endpoints.access.max-permitted=read-only
  ```
- [ ] **(b)** as grafias da spec, ao lado das da frente 11 — dois prefixos no mesmo actuator
  ```properties
  rakun.management.endpoints.web.base-path=/actuator
  rakun.endpoints.web.exposure.include=health,info
  rakun.endpoint.health.access=read-only
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 03r-u ★ · O grupo liveness só aceita indicadores locais

**Contexto.** A regra é "nenhum indicador que alcança um socket entra no grupo liveness" (o probe
de liveness não pode cair porque o banco caiu, senão o orquestrador reinicia o pod à toa). Mas um
indicador não declara se alcança socket. A thread usou uma lista fixa de indicadores locais.

**Hoje:**
```properties
rakun.management.endpoint.health.group.liveness.include=livenessState,ping,db
```

- [ ] **(a)** ★ manter — lista fechada
  ```text
  liveness com `livenessState`, `ping`, `diskSpace`     →  ok
  liveness com `db` (ou qualquer outro)                →  boot recusado
  ```
- [ ] **(b)** o indicador se declara local no registro — um campo novo no rakun-actuator-api
  ```bp
  registerIndicator(HealthIndicator(name: "cacheWarm", local: true, check: …))   // pode entrar no liveness
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 03r-v ★ · O operador do builder tipado é um enum

**Contexto.** A frente 78 escrevia `.where(CityCol.state, "=", "CA")` e pedia que "um operador
fora do conjunto aceito seja erro de compilação, não string emendada" — mas um argumento string
nunca é erro de compilação. A thread criou `Op` (`Eq | Ne | Lt | Gt | Le | Ge | Like`, em
`rakun-data/src/orm/query.bp`).

**Hoje:**
```bp
queryOf(CityMeta()).where(CityCol().state, Op.Eq, "CA")
```

- [ ] **(a)** ★ manter — operador desconhecido é variante desconhecida, erro de compilação
  ```text
  .where(CityCol().state, Op.Equals, "CA")   →  error: `Op` has no variant `Equals`
  ```
- [ ] **(b)** string checada em runtime
  ```bp
  .where(CityCol.state, "==", "CA")   // compila; falha só quando a query roda: unknown operator "=="
  ```

**Recomendação: (a).** É a única que cumpre o "erro de compilação" que a frente pede.
**Bloqueia:** nada.

### 03r-w ★ · OAuth2: endpoints são campos do provider; client credentials é uma função

**Contexto.** O `OAuth2Provider` da frente 79 não tinha campo para "os quatro endpoints definidos
à mão" de um provedor que não é OIDC; e um `#[clientCredentials("id")]` num campo de cliente teria
de embrulhar cada chamada desse cliente — um decorador não reescreve corpo que não é dele. A thread
pôs os endpoints no provider (`oidcProvider(...)` os deixa vazios) e fez de client credentials uma
função (`client_credentials.bp`).

**Hoje:**
```bp
OAuth2Provider(authorizationUri: …, tokenUri: …, userinfoUri: …, jwksUri: …)
withClientToken("github", { token -> client.get("/user").bearer(token).retrieve() })   // tenta de novo uma vez no 401
```

- [ ] **(a)** ★ manter — campos no provider; `withClientToken(id, call)` busca o token, chama, e no
  401 descarta o token e tenta mais uma vez
  ```bp
  val r = withClientToken("github", { token -> fetchUser(token) });   // 401 → novo token → segunda chamada
  ```
- [ ] **(b)** um `ProviderEndpoints` à parte e um interceptor de request no `rakun-client`
  ```bp
  OAuth2Provider(name: "legacy", endpoints: ProviderEndpoints(authorization: …, token: …, userinfo: …, jwks: …))
  client.withInterceptor(clientCredentials("github"))    // gancho novo no rakun-client
  ```

**Recomendação: (a).** (b) exige um gancho de interceptor que o rakun-client não tem.
**Bloqueia:** nada.

### 03r-x ★ · O relay reivindica por UPDATE condicional

**Contexto.** Outbox, sagas e 2PC (frentes 83 e 84). O braço `ets:memory` do rakun-data — o
datasource em que os testes rodam — não tem `FOR UPDATE SKIP LOCKED`, e um módulo botopink não
declara um `gen_statem`. A thread fez cada reivindicação por `UPDATE` condicional (um vencedor por
linha em todo driver), devolvendo reivindicações de um relay que caiu por `reclaimStale`; sagas e
2PC gravam cada transição e são retomados no boot. O job store reivindica gatilho e assume lease
vencido do mesmo jeito.

**Hoje:**
```sql
UPDATE outbox SET status = 'claimed' WHERE id = :id AND status = 'pending'     -- um vencedor por linha, em todo driver
```

- [ ] **(a)** ★ manter — o estado durável é o que a recuperação lê
  ```text
  boot  →  resumeSagas()  →  saga "order-42" retomada no passo 3 (gravado antes da queda)
  boot  →  recover2pc()   →  transação "tx-9" em prepared → commit
  ```
- [ ] **(b)** `FOR UPDATE SKIP LOCKED` por driver e sidecars `gen_statem` supervisionados
  ```sql
  SELECT * FROM outbox WHERE status = 'pending' FOR UPDATE SKIP LOCKED LIMIT 10   -- só no Postgres
  ```

**Recomendação: (a).** (b) é otimização para o braço Postgres; recuperar depende do estado
gravado, não do processo. **Bloqueia:** nada.

### jhonstart

### 26-a (jhonstart) ★ · Toda célula do roteador tem os dois targets

**Contexto.** (O id `26-a` do compilador é outra pergunta, já respondida pela decisão 242.) Uma
"célula" é uma função `declare fn` com corpo no host (`.mjs` no node, `.erl` no erlang). O core do
jhonstart compila nos dois targets, e uma célula só-erlang chamada quebra a compilação commonJS no
ponto da chamada. Por isso as cinco leituras, `fill`, `navigate` e `lastNavigation` do roteador
ganharam um gêmeo `router_runtime.mjs`, e um só conjunto de asserções roda nas duas linhas.

**Hoje:**
```bp
#[@External.Erlang(…), @External.Node("./router_runtime.mjs", …)]
declare fn __jhRoutePath() -> string;
```

- [ ] **(a)** ★ manter — célula nos dois targets, um teste para as duas linhas
  ```text
  botopink test (commonJS)  ✓ router · botopink test (erlang)  ✓ router
  ```
- [ ] **(b)** o roteador num membro só-erlang, importado pelo render através de uma divisão de target
  ```text
  modules/jhonstart-router  targets ["erlang"]
  error: `__jhRoutePath` has no `#[@External.<Target>(…)]` for the node backend   (no core, que é dos dois)
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 27-a ★ · Célula de browser num membro de dois targets

**Contexto.** O mesmo problema do outro lado: uma célula só-node chamada quebra a compilação
erlang. `jhonstart-link` e o core declaram os dois targets, e `linkStatus()` / `propsFor()` chamam
as suas. A thread deu a cada célula de browser um gêmeo erlang (`sidecars/jhonstart_link.erl`,
`sidecars/jhonstart_island.erl`) que responde o que é verdade num servidor: nenhum link em voo,
nada pré-carregado, nada hidratado, nenhuma prop.

**Hoje:**
```bp
linkStatus()       // no erlang responde a verdade do servidor: nenhum link em voo, nada pré-carregado
```

- [ ] **(a)** ★ manter — gêmeo erlang que responde o vazio do servidor
  ```text
  render no servidor: linkStatus() == LinkStatus(pending: false, prefetched: [])
  ```
- [ ] **(b)** um membro só-commonJS para as células — divide o `link.bp` em dois
  ```text
  modules/jhonstart-link          targets ["commonJS","erlang"]   link.bp (sem células)
  modules/jhonstart-link-browser  targets ["commonJS"]            link_cells.bp
  ```

**Recomendação: (a).** Um hook que o render do servidor chama tem de existir no servidor.
**Bloqueia:** nada.

### 29-a ★ · A tabela de starters de island

**Contexto.** Island é um componente `#[client]` que hidrata no browser; o "starter" é a função que
o inicia. O `hydrate()` lia `globalThis.__jhIslandStarters`, um nome que a entrada gerada pelo onze
escrevia à mão por uma célula própria, e a entrada importava todo componente cliente — o bundle não
se dividia por rota. A thread fez a tabela ser o quarto global do registro (`globals.starters`),
preenchida por duas funções; o `hydrate()` chama o loader do padrão `r` do payload uma vez.

**Hoje:**
```bp
registerStarter("Counter", startCounter);
registerRouteStarters("/blog/[slug]", loadBlogChunk);     // o chunk da rota só carrega quando a rota casa
```

- [ ] **(a)** ★ manter — duas funções; nenhum `__` escrito à mão; um starter por nome
  ```text
  registerStarter("Counter", outro)  →  jhonstart: a starter for `Counter` is already registered
  ```
- [ ] **(b)** só a entrada do registro — a entrada do onze mantém a sua célula sobre `globals.starters`
  ```bp
  // onze_entry.bp (gerado)
  #[@External.Node("./entry.mjs", "setStarters")] declare fn __onzeSetStarters(name: string, t: Json) -> i32;
  __onzeSetStarters(globals.starters, allStarters());
  ```
- [ ] **(c)** starters preguiçosos por componente, em vez de loader por rota
  ```bp
  registerLazyStarter("Counter", { -> import("./counter.chunk.js") });
  ```

**Recomendação: (a).** A divisão segue a unidade do manifest (a rota) e a entrada não declara
global nenhum. **Bloqueia:** nada (o onze 68 adota).

### 30-b ★ · `RenderPlugin` é um registro de funções

**Contexto.** Um plugin de render (o do emilia, por exemplo) injeta CSS no `<head>` e em cada
pedaço do streaming. Um `Array<RenderPlugin>` com dois tipos diferentes que implementam uma
`behavior` não tipa (`type mismatch: expected Rec, got Quiet`). E no erlang cada fronteira de
streaming resolve no seu próprio processo, e a folha de estilo do emilia é por processo — então
`chunk(id)` precisa rodar no processo da fronteira. `payload` devolve `Array<#(key, json)>` (`[]`
para "nada").

**Hoje:**
```bp
RenderPlugin(name: …, head: …, chunk: …, close: …, payload: …)     // `chunk(id)` roda no processo da própria fronteira
```

- [ ] **(a)** ★ manter — registro de funções; a lista de plugins tipa hoje
  ```bp
  app([emiliaPlugin(), RenderPlugin(name: "quiet", head: { -> "" }, …)])
  ```
- [ ] **(b)** uma `behavior RenderPlugin` — quando um array de tipos diferentes que a implementam tipar
  ```bp
  pub behavior RenderPlugin { fn head(self) -> @Task<string>; fn chunk(self, id: string) -> @Task<string>; … }
  app([Rec(), Quiet()])   // hoje: type mismatch: expected Rec, got Quiet
  ```

**Recomendação: (a).** Os quatro momentos e a ordem são os do README; só muda onde `chunk` roda.
**Bloqueia:** nada.

### 30-c ★ · `compose` recebe a página como thunk

**Contexto.** `resolve` precisa do walker de `render.bp`, e as entradas precisam de `resolve` — os
dois arquivos se importariam. Por isso `render` / `renderStream` / `App` foram para `streaming.bp`.
E um layout tem de rodar antes da página para valer "um redirect num layout e a página nunca é
chamada", então `compose` não pode receber a página já renderizada. A superfície plana
`from "jhonstart"` não muda; `PageInput` ganhou `metadata` / `viewports`.

**Hoje:**
```bp
compose(chain, route, { -> Page() })     // os layouts rodam antes: redirect num layout e a página nunca é chamada
```

- [ ] **(a)** ★ manter — dois módulos (`render.bp`, `streaming.bp`); página como thunk
  ```bp
  // layout chama redirect("/login")  →  Page() nunca roda; resposta 307 /login
  ```
- [ ] **(b)** um módulo só, maior, com `render.bp` e `streaming.bp` juntos
  ```text
  modules/jhonstart/src/render.bp   (walker + compose + resolve + render + renderStream + App)
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 30-d ★ · `Suspense` registra a fronteira no render

**Contexto.** `Suspense` marca um pedaço da página que chega depois, por streaming. Um `Element`
não tem campo que carregue o thunk, então o render não acharia uma fronteira escrita à mão na
árvore que compôs. A thread fez `Suspense(b)` guardar `b` no estado por render (`render.mjs` /
`jhonstart_render`) ao escrever o buraco — uma célula host.

**Hoje:**
```bp
Suspense(b)        // escreve o buraco e guarda `b` no estado do render
```

- [ ] **(a)** ★ manter — a página só devolve a árvore
  ```bp
  fn Page() -> Element { return div([h1("Posts"), Suspense(Boundary(id: "list", fallback: spinner(), body: postList))]); }
  ```
- [ ] **(b)** a página devolve as fronteiras ao lado da árvore
  ```bp
  fn Page() -> #(Element, Array<Boundary>) { val b = Boundary(…); return #(div([h1("Posts"), hole(b)]), [b]); }
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 30-e ★ · O registro de segmento se chama `UiSegment`

**Contexto.** O bundled `routing` também exporta `Segment` (o módulo `segment`); um consumidor que
escreve `import {Segment} from "jhonstart"` seria recusado por ambiguidade. A thread chamou o
registro de `UiSegment`, com `segment(pattern)`, os `with*` e `segmentFor`.

**Hoje:**
```bp
import {UiSegment} from "jhonstart";      // compila
import {Segment} from "jhonstart";        // seria ambíguo com o `Segment` do `routing`
```

- [ ] **(a)** ★ manter — `UiSegment`
  ```bp
  val s: UiSegment = segment("/blog/[slug]").withLayout(BlogLayout);
  ```
- [ ] **(b)** manter `Segment` e exigir que o consumidor nomeie o módulo
  ```bp
  import {Segment} from "jhonstart/routes";   // a forma plana `from "jhonstart"` deixa de servir
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 30-f ★ · `app(…, lang:)`

**Contexto.** O `--lang` do onze 50 é "o atributo `lang`, escrito uma vez no elemento do
documento", e o layout raiz não alcança o `<html>`: quem o escreve é o render. O `documentStart`
tinha o literal `<html lang="pt-BR">`; o `htmlLang()` por request do rakun 64 ainda não existia.
A thread pôs `lang` no `App`, com `"en"` por padrão e um formato checado.

**Hoje:**
```bp
app(plugins, lang: "pt-BR")       // <html lang="pt-BR"> em todo documento; sem o argumento, "en"
app(plugins, lang: "pt_BR")       // recusado: só letras, dígitos e `-`, começando por letra
```

- [ ] **(a)** ★ manter — uma língua por app, `"en"` por padrão
  ```text
  jhonstart: app(lang: "pt_BR") is not a language tag - letters, digits and '-', starting with a letter
  ```
- [ ] **(b)** `PageInput.lang` por request (o `htmlLang()` da frente 64)
  ```bp
  render(app, PageInput(…, lang: htmlLang()))   // /en/… → lang="en", /pt/… → lang="pt"
  ```
- [ ] **(c)** nenhum padrão — `lang` obrigatório
  ```bp
  app(plugins)   // error: missing argument `lang`
  ```

**Recomendação: (a) agora;** `PageInput.lang` por request é aditivo quando o `i18n` (105) entrar.
**Bloqueia:** nada.

### 30-g ★ · A metade de browser é afirmada num membro só-commonJS

**Contexto.** As funções de browser do render (`registerFill`, `registerSignal`, `payloadText`)
leem `document`, `history` e `location`. O `botopink test` roda em node e no BEAM, nenhum tem DOM,
e o core roda toda suíte nas duas linhas (um DOM falso só-node ficaria vermelho ou passaria vazio
no erlang). Nenhum browser estava ao alcance antes do onze 53. A thread criou um membro só-commonJS
com um DOM mínimo, sem dependência.

**Hoje:**
```text
modules/jhonstart-dom-test      targets ["commonJS"]      fake_dom.mjs + dom_test.bp
```

- [ ] **(a)** ★ manter — as três caixas afirmadas hoje sobre o markup que o render produz
  ```text
  $ botopink test modules/jhonstart-dom-test
  ✓ fill substitui o buraco pelo template · ✓ payload lido · ✓ signal navega (history.pushState gravado)
  ```
- [ ] **(b)** deixar para o browser do onze 53 — as caixas ficam abertas até lá
  ```text
  frente 30, passo 7: [ ] fill no DOM   (espera onze 53)
  ```
- [ ] **(c)** uma lib de DOM real como dependência
  ```json
  { "dependencies": { "jsdom": "^24" } }
  ```

**Recomendação: (a).** O onze 53 ainda prova as mesmas caixas num browser. **Bloqueia:** nada.

### 31-a ★ · `notFound()` / `redirect(url)` levantam

**Contexto.** Página, layout e template são corpos `-> @Component<…>` e não podem `throw` (decisão
121), então a forma de instrução `notFound();` do README exige que a chamada em si levante; e
`throw notFound();` dentro de um thunk `@Result` tem de continuar funcionando. O `try … catch` do
botopink só desembrulha `@Result`, então nenhum código `.bp` observa um raise. A thread levanta pelo
`__jhRaise` e a fronteira captura pelo `__jhCapture`, que transforma o raise em `Error(reason)`.

**Hoje:**
```bp
if (post == null) { notFound(); }       // a chamada em si levanta; a fronteira captura por uma célula host
val reason = notFoundReason();          // o motivo como valor, sem levantar
```

- [ ] **(a)** ★ manter — a mesma instrução serve em página, layout, template e thunk
  ```text
  GET /blog/inexistente  →  404 com o not-found.bp mais próximo; um componente que quebra é capturado igual
  ```
- [ ] **(b)** as funções devolvem o motivo e o componente devolve uma "árvore sinalizadora"
  ```bp
  if (post == null) return signal(notFoundReason());   // o render inspeciona a árvore
  ```
- [ ] **(c)** um tipo `never` (a lacuna de linguagem que a frente 63 registra)
  ```bp
  pub fn notFound() -> never { … }   // o checker sabe que nada depois roda
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### pub val globals ★ · O registro global do jhonstart (decisão 140)

**Contexto.** O jhonstart tem quatro "globais de browser" que dois builds precisam concordar sem
trocar nada: o payload, a função de fill, a de signal e a tabela de starters (29-a). Cada uma
recebe um alias `__bp<N>` pela ordem do registro. A decisão 140 fez um `pub val` de módulo cruzar
módulos em todo backend, avaliado uma vez no load; o jhonstart usa um registro só para não sombrear
o `fill` da frente 26 num import plano.

**Hoje:**
```bp
// modules/jhonstart/src/globals.bp
pub val globals = Globals(payload: alias("payload"), fill: alias("fill"), signal: alias("signal"), starters: alias("starters"));
// globals.starters == "__bp3"
```

- [ ] **(a)** ★ manter — um `pub val`, importado como qualquer nome
  ```bp
  import {globals} from "jhonstart";
  val name = globals.starters;    // "__bp3"
  ```
- [ ] **(b)** a função `globals()` (a forma anterior à 140)
  ```bp
  import {globals} from "jhonstart";
  val name = globals().starters;  // recalculado a cada chamada
  ```

**Recomendação: (a).** É o que a decisão 140 escolheu. **Bloqueia:** nada.

### emilia

### 05emilia-a ★ · O leitor de filtro é uma cadeia inline

**Contexto.** O emilia gera CSS no estilo Tailwind v4. A spec pedia `filter:var(--tw-filter)`, mas
`--tw-filter` precisaria estar definido em algum lugar: o `extendTheme` recusa nomes `--tw-` e,
mesmo como regra em `:root`, não compõe — os `var()` de uma custom property são resolvidos no
elemento que a declara, então todo elemento herdaria o resultado vazio de `:root`. O upstream
escreve a cadeia inteira em cada utilitário (`filterChain()` / `backdropFilterChain()`).

**Hoje:**
```css
.blur-sm { --tw-blur: blur(var(--blur-sm)); filter: var(--tw-blur,) var(--tw-brightness,) … var(--tw-drop-shadow,) }
```

- [ ] **(a)** ★ manter — `blur-sm brightness-50` compõem na mesma classe, como o upstream
  ```css
  filter: var(--tw-blur,) var(--tw-brightness,) … var(--tw-drop-shadow,)     /* em todo utilitário */
  ```
- [ ] **(b)** `filter: var(--tw-filter)` com `--tw-filter` no tema — não compõe
  ```css
  :root { --tw-filter: var(--tw-blur) var(--tw-brightness) }   /* resolvido em :root: vazio */
  .blur-sm { --tw-blur: blur(4px); filter: var(--tw-filter) }   /* nenhum blur aparece */
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-b ★ · A seção de backdrop é `BackdropFilter`

**Contexto.** `Backdrop(inner: Token[])` já é o modificador `::backdrop` da frente 34, uma variante
de primeiro nível; uma seção com o mesmo nome é a colisão que o `AGENTS.md` do emilia registra
como quebrando em silêncio a projeção do payload. A seção nova usa o nome da propriedade no
upstream; `BackdropRaw` mantém o nome da spec.

**Hoje:**
```text
BackdropFilter …              a seção nova (nome da propriedade no upstream)
Backdrop(inner: Token[])      continua sendo o modificador `::backdrop`
```

- [ ] **(a)** ★ manter — nenhuma frente pronta muda
  ```bp
  emilia([BackdropFilter.Blur.Md, Backdrop([Bg.Black])])
  ```
- [ ] **(b)** renomear o modificador da frente 34
  ```bp
  emilia([Backdrop.Blur.Md, BackdropPseudo([Bg.Black])])   // muda a saída fixada da frente 34
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-c ★ · `drop-shadow-none` segue o upstream

**Contexto.** O `TAILWIND_CSS_DOCS.md § 13.1` imprime `filter: drop-shadow(none)`, que não é CSS
válido (`drop-shadow()` exige uma sombra). O upstream (`staticUtility('drop-shadow-none')`)
escreve `--tw-drop-shadow: ` e o leitor. O teste afirma a ausência da forma da referência;
`blur-none` mantém o `filter:none` da referência, que é válido.

**Hoje:**
```css
.drop-shadow-none { --tw-drop-shadow: ; filter: var(--tw-blur,) … var(--tw-drop-shadow,) }
```

- [ ] **(a)** ★ manter — CSS válido, igual ao upstream
  ```css
  --tw-drop-shadow: ;  /* + o leitor */
  ```
- [ ] **(b)** a string da referência — o browser descarta a declaração
  ```css
  filter: drop-shadow(none)   /* inválido: a regra é ignorada */
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-d ★ · A rigidez do snap é um fallback, não uma entrada do tema

**Contexto.** O passo 6 da frente 46 queria `--tw-scroll-snap-strictness` no tema da frente 54,
mas o `extendTheme` recusa nomes `--tw-` (ver 05emilia-a). O upstream registra a variável com
`@property` e valor inicial `proximity`. A thread usou o `cssVarOr` da frente 39: um
`Snap.Type.X` sozinho faz snap por proximidade, e um `Snap.Strictness` na mesma classe sobrescreve.

**Hoje:**
```css
scroll-snap-type: x var(--tw-scroll-snap-strictness, proximity)
```

- [ ] **(a)** ★ manter — fallback inline
  ```css
  .snap-x.snap-mandatory { --tw-scroll-snap-strictness: mandatory; scroll-snap-type: x var(--tw-scroll-snap-strictness, proximity) }
  ```
- [ ] **(b)** um namespace `Tw` no tema
  ```css
  :root { --tw-scroll-snap-strictness: proximity }
  .snap-x { scroll-snap-type: x var(--tw-scroll-snap-strictness) }
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-e ★ · `fullTheme()` vai no `fullOptions()`

**Contexto.** A decisão 80 dizia que `defaultOptions()` carrega o `fullTheme()`. Mas
`defaultOptions()` está em `output.bp`, o `fullTheme()` compõe funções que vivem em `emilia.bp`, e
`emilia.bp` importa `output.bp` — o contrário seria um ciclo de módulos. Um teste falha em qualquer
`var(--…)` indefinido num documento do `flush()`, com `defaultTheme()` como controle.

**Hoje:**
```bp
flush()                 // renderiza com fullOptions() = withTheme(defaultOptions(), fullTheme())
defaultOptions()        // continua a base sem paleta
```

- [ ] **(a)** ★ manter — `fullOptions()` em `emilia.bp`
  ```bp
  pub fn fullOptions() -> Options { return withTheme(defaultOptions(), fullTheme()); }
  ```
- [ ] **(b)** mover as entradas de cinco frentes para o `theme.bp`
  ```bp
  // theme.bp passa a ter colorEntries(), effectEntries(), … de cinco frentes
  pub fn defaultOptions() -> Options { return Options(theme: fullTheme(), …); }
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-f ★ · As entradas `--inset-shadow-*` não levam o `inset`

**Contexto.** A frente 41 emite `box-shadow:inset var(--inset-shadow-xs)` (da referência); os
valores do `theme.css` do upstream já começam com `inset`, então juntar os dois daria
`inset inset …` — CSS inválido. A thread tirou o `inset` das entradas (`effectEntries()`); a
sombra renderizada é igual à do upstream.

**Hoje:**
```css
:root { --inset-shadow-xs: 0 1px 1px rgb(0 0 0 / 0.05) }
.inset-shadow-xs { box-shadow: inset var(--inset-shadow-xs) }
```

- [ ] **(a)** ★ manter — o utilitário escreve o `inset`; a entrada do tema não
  ```css
  box-shadow: inset var(--inset-shadow-xs)
  ```
- [ ] **(b)** os valores do upstream (que já começam com `inset`) e a frente 41 muda a saída fixada
  ```css
  :root { --inset-shadow-xs: inset 0 1px 1px rgb(0 0 0 / 0.05) }
  .inset-shadow-xs { box-shadow: var(--inset-shadow-xs) }
  ```

**Recomendação: (a).** Não mexe numa frente já entregue. **Bloqueia:** nada.

### 05emilia-g ★ · `space-*` / `divide-*` como o upstream

**Contexto.** O upstream escreve `space-x-*` como `:where(& > :not(:last-child))` com
`--tw-space-x-reverse:0` e as duas margens lógicas lidas por ele; o emilia escrevia
`& > :not(:last-child)` (especificidade maior) e só a margem final, então `Space.XReverse`
definia uma variável que ninguém lia. `divide-*` usa o mesmo `siblingSelector()`. A thread alinhou
as duas frentes, as saídas fixadas e os dois exemplos de uma vez.

**Hoje:**
```css
.space-x-4 { :where(& > :not(:last-child)) { --tw-space-x-reverse: 0; margin-inline-start: …; margin-inline-end: … } }
```

- [ ] **(a)** ★ manter — `Space.XReverse` passa a ter efeito
  ```css
  :where(& > :not(:last-child))     /* com --tw-space-x-reverse */
  ```
- [ ] **(b)** a forma antiga, documentada — especificidade maior, o reverse não faz nada
  ```css
  & > :not(:last-child) { margin-inline-end: calc(var(--spacing) * 4) }
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-h ★ · Módulos irmãos nunca importam `from "emilia"`

**Contexto.** Um módulo irmão que importa `from "emilia"` (o módulo padrão `emilia.bp`) passa no
`botopink test` dentro de `modules/emilia/` e falha em todo consumidor (`unbound variable
'flushWith'` em `emilia/preflight.bp` quando `examples/emilia-cascade` compila o emilia como
dependência). A thread fez os irmãos importarem só `tokens` / `theme` / `output` / uns aos outros, e
pôs `named()` e a célula `lookupRule` em `emilia.bp`. A decisão 206 transformou isso em regra
(`module-import-with-from`).

**Hoje:**
```bp
// modules/emilia/src/preflight.bp
import {flushWith} from "emilia";      // dentro do próprio pacote: `module-import-with-from` (decisão 206)
```

- [ ] **(a)** ★ manter — irmãos importam pelo caminho; `named()` mora no `emilia.bp`
  ```bp
  // modules/emilia/src/preflight.bp
  import {Options} from "output";
  import {Theme} from "theme";
  ```
- [ ] **(b)** consertar o resolver primeiro (mudança no compilador) e permitir `from "emilia"` de dentro
  ```bp
  import {flushWith} from "emilia";   // passaria a resolver também no consumidor
  ```

**Recomendação: (a)** (a decisão 206 já transformou isso em regra). **Bloqueia:** nada.

### 05emilia-i ★ · As variáveis `--tw-*` de transform são blocos `@property`

**Contexto.** `translate-*` e `skew-*` não compunham (duas classes na mesma tag não somavam). O
Tailwind 4.3.2 compilado escreve `--tw-translate-x` e lê `translate: var(--tw-translate-x)
var(--tw-translate-y)`, com `@property` (valor inicial `0`) e uma camada `@layer properties` com
fallback `@supports`. O `Block` do emilia já é cabeçalho + corpo, deduplicado por cabeçalho no
flush — a forma de uma regra `@property`. Um documento sem transform não muda.

**Hoje:**
```css
@layer properties;
@property --tw-translate-x { syntax: "*"; inherits: false; initial-value: 0 }
.translate-x-4 { --tw-translate-x: calc(var(--spacing) * 4); translate: var(--tw-translate-x) var(--tw-translate-y) }
```

- [ ] **(a)** ★ manter — saída do upstream, sem tipo de saída novo
  ```css
  /* translate-x-4 translate-y-2 na mesma tag → translate: 1rem 0.5rem */
  ```
- [ ] **(b)** o fallback inline e skews que não compõem
  ```css
  .translate-x-4 { translate: calc(var(--spacing) * 4) var(--tw-translate-y, 0) }
  .skew-x-3 { transform: skewX(3deg) }   /* skew-y-3 na mesma tag apaga o skew-x */
  ```
- [ ] **(c)** um tipo de saída novo no modelo da frente 56 para `@property`
  ```bp
  OutputKind.Property(name: "--tw-translate-x", initial: "0")
  ```

**Recomendação: (a).** `scale-*` ainda escreve `scale:` direto (registrado em `status.md`).
**Bloqueia:** nada.

### 05emilia-j ★ · Modificador de lista de seletores

**Contexto.** O Tailwind 4.3.2 compila `marker:flex` em quatro regras e `selection:` em duas: "o
elemento e seus descendentes" não cabe num seletor com um só `&` (pseudo-elemento não entra em
`:is()`), e o `checkVariantSelector` da frente 56 recusa dois `&`. A thread fez desses dois
modificadores uma *lista* de variantes de um `&` cada (`markerVariants()`, `selectionVariants()`).

**Hoje:**
```text
marker:flex  →  & *::marker · &::marker · & *::-webkit-details-marker · &::-webkit-details-marker     (4 regras, como o upstream)
```

- [ ] **(a)** ★ manter — a regra de um `&` da frente 56 fica intacta
  ```css
  .marker\:flex *::marker, … { display: flex }   /* 4 regras, na ordem do upstream */
  ```
- [ ] **(b)** `& ::marker` (só descendentes, como a referência)
  ```css
  .marker\:flex ::marker { display: flex }   /* o próprio <li> fica de fora */
  ```
- [ ] **(c)** `Variant` carregando uma lista de seletores
  ```bp
  Variant(name: "marker", selectors: ["& *::marker", "&::marker", …])   // muda o tipo da frente 56
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-k ★ · O meio passo negativo

**Contexto.** `spacingHalf(n: i32)` recebe a parte inteira; `-0` é `0`, então `-mt-0.5` não tinha
token. No upstream, `-mt-0.5` é `margin-top: calc(var(--spacing) * -0.5)`. A thread pôs o sinal no
nome (`spacingNegHalf(n)`, `n` = parte inteira do módulo) e fez `spacingHalf` abortar com `n`
negativo, para cada degrau ter uma só grafia; todo `*.Neg.Half` ganhou o `0`.

**Hoje:**
```bp
spacingNegHalf(0)       // -0.5  →  margin-top: calc(var(--spacing) * -0.5)
spacingHalf(-1)         // aborta
```

- [ ] **(a)** ★ manter — sinal no nome
  ```bp
  Mt.Neg.Half(0)    // -mt-0.5
  ```
- [ ] **(b)** `spacingHalf(n, negative: true)`
  ```bp
  spacingHalf(0, negative: true)   // -0.5;  spacingHalf(-1) e spacingHalf(1, negative: true) seriam duas grafias de -1.5
  ```
- [ ] **(c)** um passo em string
  ```bp
  spacing("-0.5")   // erro só em runtime para "-0.7"
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 05emilia-l ★ · Confirmar uma coluna move a família inteira para a forma do upstream

**Contexto.** Algumas grafias da referência divergiam do Tailwind 4.3.2 compilado: fração vira
`calc(1 / 2 * 100%)` em `w-*`, `inset-*`, `basis-*`, `translate-*`; `opacity-60` vira `60%`;
`-rotate-12` vira `calc(12deg * -1)`. A thread moveu cada família inteira, com um helper por forma
(`fraction(n, d)`), para a biblioteca ter uma convenção só. Restam divergências registradas em
`status.md` (`rawTransitionProperty`, `backdrop-opacity`, `border-spacing`,
`-webkit-backdrop-filter`).

**Hoje:**
```css
w-1/2        →  width: calc(1 / 2 * 100%)
opacity-60   →  opacity: 60%
-rotate-12   →  rotate: calc(12deg * -1)
```

- [ ] **(a)** ★ manter — família inteira na forma do upstream
  ```css
  .w-1\/2 { width: calc(1 / 2 * 100%) }   .basis-1\/3 { flex-basis: calc(1 / 3 * 100%) }
  ```
- [ ] **(b)** mudar só as linhas não confirmadas — duas convenções na mesma família
  ```css
  .w-1\/2 { width: calc(1 / 2 * 100%) }   .basis-1\/3 { flex-basis: 33.333333% }
  ```
- [ ] **(c)** manter as grafias da referência e documentar a divergência
  ```css
  .w-1\/2 { width: 50% }   .opacity-60 { opacity: 0.6 }   .-rotate-12 { rotate: -12deg }
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### onze

### 49-a ★ · As suítes do core renderizam pelo `describe*` do próprio core

**Contexto.** O `test-snap.md` escrevia as suítes do core como `import {assertConfig, …} from
"onze-test"`, mas o `onze-test` depende do `onze`, e um manifest não tem dev-dependencies — o core
não pode importá-lo. A thread pôs `describeConfig` / `describeAliases` / `describeAppFiles` /
`describePublicEnv` no core (o mesmo texto que o `onze info` imprime); as suítes do core usam o
`snapshots.assertAs` do std, e os `assert<Assunto>` do `onze-test` são embrulhos finos. Os slugs
de snapshot são os do std (`_`), não os `-` do `test-snap.md`.

**Hoje:**
```bp
describeConfig(cfg)       // o mesmo texto que o `onze info` imprime; o teste do core o afirma com `snapshots.assertAs`
```

- [ ] **(a)** ★ manter — uma renderização só; o core testa só com std
  ```bp
  // onze/test/config_test.bp
  snapshots.assertAs("config default", describeConfig(defaultConfig()));
  ```
- [ ] **(b)** mover as suítes para o `onze-test` (o core não pode importá-lo)
  ```text
  modules/onze-test/test/config_test.bp   import {assertConfig} from "onze-test"
  modules/onze/test/                       sem snapshot nenhum
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 49-c ★ · `onze.json` recusa chave desconhecida

**Contexto.** O README listava os campos, mas não dizia o que acontece com uma chave fora deles. A
thread recusa chave desconhecida, duplicada, de tipo errado, porta fracionária ou fora de
`1..65535` e entrada não-string em `allowedRedirects`, cada uma com um `Error` nomeando a chave. O
`describeConfig` imprime também `actionsBodyLimit` e `allowedRedirects`.

**Hoje:**
```json
{ "prot": 4000 }
```

- [ ] **(a)** ★ manter — erro nomeando a chave
  ```text
  $ onze dev
  onze.json: unknown key "prot"
  ```
- [ ] **(b)** ignorar — a porta fica 3000 em silêncio
  ```text
  $ onze dev
  ready on http://localhost:3000
  ```

**Recomendação: (a)** (decisão 67: um `"prot"` errado não pode deixar a porta 3000 em silêncio).
**Bloqueia:** nada.

### 49-d ★ · `chainFor` recebe os padrões ancestrais

**Contexto.** O jhonstart monta a cadeia de layouts do cliente com o `ancestorPatterns` do
`routing`; o passo 4 dizia que o boot do onze não importa nada de `routing`. A thread fez
`chainFor(patterns)` mapear `segmentFor` sobre os padrões que a cadeia de layouts do rakun já
nomeia para a rota casada. Mas a 102 (`routing.conventions`) existe para apagar a re-derivação da
gramática de segmentos, e o `types.bp` do onze (`appFileKinds`, `classifyAppFile`) é um dos sete
lugares que a refazem à mão — o passo 3 da 102 desfaz a metade "não importa nada de `routing`".

**Hoje:**
```bp
chainFor(patterns)        // os padrões vêm da cadeia de layouts do rakun; o onze não importa nada de `routing`
```

- [ ] **(a)** ★ manter como está — `chainFor(patterns)` e nenhum import de `routing` no onze
  ```bp
  // onze/src/types.bp continua com appFileKinds() e classifyAppFile() próprios
  ```
- [ ] **(b)** importar `ancestorPatterns` — o onze deriva a cadeia de novo
  ```bp
  import {ancestorPatterns} from "routing";
  chainFor(ancestorPatterns(route.pattern))
  ```
- [ ] **(c)** confirmar como emendada pela 102 — `chainFor(patterns)` fica; o onze consome `routing.conventions`
  ```bp
  import {conventions.classify, conventions.fileKinds} from "routing";   // substitui classifyAppFile / appFileKinds
  chainFor(patterns)                                                      // inalterado
  ```

**Recomendação: (c).** A cadeia continua vindo do rakun, e a classificação de arquivos deixa de
ser refeita à mão no onze. **Bloqueia:** o passo 3 da 102 (troca nos consumidores, incluindo o
`types.bp` do onze), e por ele a 128 e o grupo A do rakun.

### 49-e ★ · A metade rakun do boot é um membro próprio

**Contexto.** Todo membro do rakun é `["erlang"]` (decisão 117), e um pacote nos dois targets que
importa rakun não compila para commonJS. O core do onze está nos dois targets, e o `onze-cli`
(commonJS) e o `onze-bundler` dependem dele. A thread criou `onze-server` (só erlang) com
`Onze.run`, `requestData`, `responseFor` e o registro de páginas e raízes; o core fica com a metade
jhonstart e entrega ao `onze-server` o render como valor (`SiteRender`). Nenhum arquivo importa
mais jhonstart, rakun e a ponte juntos.

**Hoje:**
```text
modules/onze-server/      targets ["erlang"]      Onze.run, requestData, responseFor
```

- [ ] **(a)** ★ manter — a CLI nunca carrega rakun; o release que serve carrega `onze-server`
  ```json
  // modules/onze-server/botopink.json
  { "name": "onze-server", "targets": ["erlang"], "dependencies": { "onze": { "workspace": true }, "rakun-app": { … } } }
  ```
- [ ] **(b)** o core vira só-erlang — a CLI e o bundler deixam de depender dele
  ```json
  { "name": "onze", "targets": ["erlang"] }   // onze-cli e onze-bundler copiam o vocabulário do config
  ```
- [ ] **(c)** esperar um membro do rakun nos dois targets
  ```text
  Onze.run fica no core; o build commonJS do core segue recusado até lá
  ```

**Recomendação: (a).** **Bloqueia:** a redação da terceira caixa do passo 4 da frente 49 (ela
nomeia um arquivo só, que não existe mais).

### 50-a ★ (emendada) · `onze build` gera um main de servidor; `onze start` o roda

**Contexto.** O pacote de servidor gerado é uma biblioteca; o compilador emite `.erl` e nenhum
comando de execução mantém um servidor vivo (`botopink run` termina com `halt()`). A thread fez o
`build` gerar `onze_main.bp` (o `OnzeConfig` resolvido como literal, `PORT` sobre a porta,
`Onze.run`), compilar para BEAM com `erlc`, e o `start` rodar `erl`. Porta: `-p` vence `PORT`, que
vence o `onze.json`; a saída vai para `<outDir>/server.log`.

**Hoje:**
```sh
$ onze build      # gera onze_main.bp e compila o pacote para BEAM
$ onze start      # erl -noshell -pa <outDir>/server/beam -eval '<pacote>@onze_main':main()
```

- [ ] **(a)** ★ manter — até o `bin/onze` da frente 71 existir; aí o `start` chama esse script
  ```sh
  $ onze start -p 4000    # hoje: erl … ; depois da 71: .onze/rel/bin/onze foreground (que roda o mesmo comando)
  ```
- [ ] **(b)** `start` roda o script de boot do release (frente 71) já
  ```sh
  $ onze start   # error: release not built — run `onze build --release` (o script ainda não existe)
  ```

**Recomendação: (a)** até o `bin/onze` da frente 71 existir; aí o `start` chama esse script, e o
comando de hoje é o que o script roda. **Bloqueia:** nada.

### 52-a ★ · A tabela de métricas de fonte é transcrita

**Contexto.** O `onze/font` ajusta a fonte de fallback (`adjustFontFallback`) para não haver salto
de layout, e para isso precisa das métricas de cada família. Gerar a tabela exige baixar as fontes
e um leitor binário (`fontTools`), que a thread não tinha. Ela transcreveu cinco linhas, com a
procedência no cabeçalho do arquivo; os testes de fórmula fixam a aritmética independente das
linhas.

**Hoje:**
```text
Arial · Times New Roman · Inter · Roboto · Merriweather     (cinco linhas; o gerador fica devendo)
```

- [ ] **(a)** ★ manter — cinco famílias funcionam com `adjustFontFallback: true`
  ```bp
  googleFont("Inter", adjustFontFallback: true)        // ok, size-adjust calculado
  googleFont("Lato", adjustFontFallback: true)         // recusado: sem métricas para "Lato"
  ```
- [ ] **(b)** nenhuma tabela — toda família Google com `adjustFontFallback: true` é recusada
  ```bp
  googleFont("Inter", adjustFontFallback: true)        // recusado: no font metrics table
  ```

**Recomendação: (a),** com as linhas re-derivadas pelo gerador antes de um release.
**Bloqueia:** a caixa "o script que a gerou" (passo 2 da frente 52).

### 53-a ★ · Os fontes do blog ficam sob `src/`

**Contexto.** O blog de exemplo foi escrito sob `src/` quando um pacote com `"src": "."` não
alcançava módulo aninhado (o F5 da frente 49). O F5 está fechado: `onze create` escreve o layout
na raiz por padrão e o de `src/` com `--src-dir`, e o `botopink check` aceita os dois. É o layout
`src/` do próprio Next, e o `onze build` o prepara como o outro.

**Hoje:**
```text
src/app/   src/components/   src/lib/        onze.json: "appDir": "src/app"
```

- [ ] **(a)** ★ manter — o exemplo cobre o layout `src/`; o roteiro de aceitação lê `src/<caminho>`
  ```json
  { "appDir": "src/app" }
  ```
- [ ] **(b)** o layout na raiz (`app/`, `components/`, `lib/`) — o mesmo que `onze create` gera por padrão
  ```json
  { "appDir": "app" }
  ```

**Recomendação: (a).** Os dois layouts compilam. **Bloqueia:** nada.

### 68-a ★ · Um campo do manifest escapa quatro caracteres

**Contexto.** O manifest do cliente é texto com campos separados por `|`, uma linha por registro.
O `encoding.percentEncode` do std escapa `/`, `:` e `[`, então toda URL e padrão de rota ficava
ilegível, enquanto o próprio exemplo do README mantém as URLs cruas. A regra que o formato precisa
é "nenhum `|` e nenhuma quebra de linha dentro de um campo"; a thread escapa só `%`, `|`, LF e CR,
lê de volta com `percentDecode`, ida-e-volta afirmada nos dois targets.

**Hoje:**
```text
R|/blog/[slug]|/_onze/static/blog-slug.js
```

- [ ] **(a)** ★ manter — legível; só `%`, `|`, LF e CR viram `%25`, `%7C`, `%0A`, `%0D`
  ```text
  /_onze/static/app.js
  ```
- [ ] **(b)** `percentEncode` no valor inteiro — ilegível
  ```text
  %2F_onze%2Fstatic%2Fapp.js
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 68-c ★ · Os starters decodificam as props a partir do fonte

**Contexto.** As props de uma island viajam codificadas no HTML e precisam ser decodificadas no
browser. `@Decl` não tem parâmetros, então nenhum decorador consegue construir um decoder de
props; o `registerStarter(name, start)` do jhonstart (29-a) recebe um `start(raw, commit)`. A
thread fez o gerador ler `#[client] pub fn Nome(props: T)` e os campos de `T` no fonte, gerar
`startNome(raw, commit)` para os quatro tipos permitidos, e registrá-lo.

**Hoje:**
```bp
#[client] pub fn Counter(props: CounterProps) …      // o gerador lê os campos de `CounterProps` e gera startCounter(raw, commit)
```

- [ ] **(a)** ★ manter — código gerado no build, nada novo no jhonstart
  ```bp
  // onze_entry.bp (gerado)
  registerStarter("Counter", startCounter);
  ```
- [ ] **(b)** o jhonstart ganha um decoder construído por decorator — precisa de `@Decl` com parâmetros
  ```bp
  #[clientProps] pub type CounterProps(start: i32, label: string)   // geraria decodeCounterProps(raw)
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 68-d ★ · O styleMap é avaliado por uma sonda compilada nos dois pacotes

**Contexto.** O bundler lê uma lista literal de tokens do emilia como texto; o `styleRule(tokens,
th)` precisa dela como valor `Token[]`, e a regra de paridade de hash exige o mesmo `contentHash`
no node e no erlang. O build já compila um pacote cliente (commonJS) e um servidor (erlang/BEAM).
A thread gera `onze_styles.bp` com uma `probe(site, <tokens>)` por entrada, compila nos dois, roda
em node e em erl, e compara. Um build que chama `emilia(…)` precisa de `node` e `erl` no `PATH`.

**Hoje:**
```sh
$ onze build
error[emilia-hash-split]      a classe ou o hash difere entre node e erl
error[emilia-unevaluated]     um dos dois backends não respondeu
```

- [ ] **(a)** ★ manter — a classe é a da própria função do emilia, nos dois compiladores
  ```text
  contrato 4: [Flex, Gap.N(4)]  →  e_39b87d03   (node == erl)
  ```
- [ ] **(b)** um interpretador de tokens no bundler — uma segunda implementação do emilia
  ```bp
  // onze-bundler/src/style_eval.bp
  fn evalTokens(text: string) -> string { … }   // reimplementa styleRule sobre o texto
  ```
- [ ] **(c)** só a regra estática — sem checar paridade de hash
  ```text
  $ onze build   →  ok (só a recusa de não-ASCII; uma divergência node/erl aparece em produção)
  ```

**Recomendação: (a).** **Bloqueia:** nada.

### 69-a ★ · `onze-assets` mantém o seu `AssetRoot`

**Contexto.** O `rakun-web` (frente 82) tem `StaticRoot(pattern, directory, indexFile,
cacheSeconds, immutable, useLastModified, precompressed)`, e todo membro do rakun é `["erlang"]`.
O `onze-assets` roda nos dois targets (a metade de build roda sob a CLI, em node), e um build
commonJS que carrega `rakun-web` é recusado. A thread manteve `AssetRoot` no `onze-assets` e o
`onze-server` converte (`staticRootOf`) com `indexFile: ""`, `useLastModified: false`,
`precompressed: false`.

**Hoje:**
```bp
AssetRoot(pattern, directory, immutable, cacheSeconds)     // nos dois targets; o onze-server converte para o `StaticRoot` do rakun-web
```

- [ ] **(a)** ★ manter — o build continua em node
  ```bp
  // onze-server/src/server.bp
  pub fn staticRootOf(r: AssetRoot) -> StaticRoot { … }
  ```
- [ ] **(b)** `onze-assets` só-erlang — a CLI (node) deixa de poder usá-lo
  ```json
  { "name": "onze-assets", "targets": ["erlang"] }   // onze-cli: error: onze-assets has no commonJS target
  ```

**Recomendação: (a).** **Bloqueia:** nada.

- [ ] Confirmo todas como estão, com lem-b (b) e 03r-b (b)
- [ ] Quero rever: ___
