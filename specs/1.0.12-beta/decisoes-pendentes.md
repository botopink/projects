# Decisões pendentes — 1.0.12-beta

**Em aberto: 74 perguntas, 8 contradições e 92 escolhas ★ para confirmar.** O que já foi respondido está em `decisions-taken.md` (próximo número livre: **366**). O texto completo de cada pergunta, em inglês, está em `decisions-pending.md` (a fonte) e no `README.md` da trilha que a levantou.

- **Parte 1** — o que trava agora: toda pergunta aberta que trava um passo cujos outros pré-requisitos já estão cumpridos (`status.md` e o "Depends on" do README da frente) — respondida, o passo pode abrir hoje. As perguntas inteiras, no molde **Trava** → **Contexto** → **Hoje** → opções com exemplo → **Recomendação** → **Bloqueia**.
- **Parte 2** — trava, mas o passo ainda espera outra frente: uma linha por pergunta, com o que mais o passo espera.
- **Parte 3** — não trava nada hoje: uma linha por pergunta; no fim, as confirmações ★ que nenhum passo espera.

★ = já implementada: confirmar não muda nada; a alternativa vira trabalho da frente dona. ⏳ = há thread esperando. A recomendação é sempre a leitura mais restritiva, sem configuração que a contorne (decisão 67). Perguntas de método de biblioteca (nome, ordem, assinatura) eu decido pelos seus princípios: ficam marcadas † em `decisions-taken.md`, para você reverter.

---

## Parte 1 — O que trava agora (responder primeiro)

Ordem: quantos passos e frentes a resposta libera, depois o caminho crítico de `fronts.md` § Execution order (102 s3 / 103 s2 → 128 → rakun 04 → 22 → 49 → 53; 118 → 26 → 67 → 127; 118 → 119 → 120 → 126 → 127 → 124). Nenhuma pergunta aberta trava a `00-gate/114`.

### 134-g · Um valor-função `@Component` entregue a código genérico (354 (8))

**Trava:** `01-compiler/134` passo 6, caixa 4 (o caso genérico; os casos nomeado e tipado estão construídos)

**Contexto.** O mapa de contexto oculto (construído, `comptime/context_lower.zig`) é o primeiro
parâmetro de toda função cujo tipo responde `@Component<R>`, e uma chamada o passa quando o checker
tipa a chamada como `@Component<R>`. Código genérico não sabe que segura um:

```text
items.map(Card)    // map<U>(f: fn(T) -> U), U = @Component<Element>; `map` chama f(x) com 1 argumento
erlang/beam: badarity · commonJS: Card recebe `undefined` como mapa e o item no lugar dele
```

- [ ] **(a)** Recusado em compilação: um valor-função `@Component` passado onde o tipo declarado do
  parâmetro não é um `fn(…) -> @Component<…>` escrito.
  ```bp
  val cards = items.map(Card);                       // error[component-value-to-generic] em `Card`
  for (items) { i -> out.push(Card(i)); }            // escrito assim, ou um parâmetro fn(T) -> @Component<Element>
  ```
- [ ] **(b)** O valor é embrulhado onde é passado, fechando sobre o mapa daquele ponto.
  ```bp
  items.map(Card)    // passa { x -> Card(<mapa aqui>, x) }: lê o contexto de onde foi entregue
  ```
- [ ] **(c)** Nada: a chamada é comportamento indefinido.
  ```bp
  items.map(Card)    // compila; badarity no erlang
  ```

**Recomendação: (a)** — recusar > aceitar (decisão 67); (b) muda em silêncio onde o contexto é lido.

### 134-h · `use` como operando direito de `&&` / `||` / `??` (357 (1))

**Trava:** nada — construído como (a)

**Contexto.** A 357 (1) nomeia `if` / `else`, braço de `case`, laço, lambda, `try` / `catch` e retorno
antecipado; não nomeia os operadores de curto-circuito, cujo operando direito roda só em algumas chamadas.

- [ ] **(a)** Recusado (como construído).
  ```bp
  val n = ready && use flag();     // error[use-not-top-level]: `use` inside the right operand of `&&`
  val f = use flag(); val n = ready && f;   // a forma escrita
  ```
- [ ] **(b)** Aceito: só os construtos listados recusam.
  ```bp
  val n = ready && use flag();     // compila; `flag` roda só quando `ready` vale
  ```

**Recomendação: (a)** — a 357 (2): nunca sob uma condição.

### s23-b · `Decorator.is(other)` — `is` é palavra reservada (contradição)

**Trava:** a caixa `run/decorator_is_identity` do passo 23 do `01-checker`; o passo 8 do `05-jhonstart/26`

**Contexto.** A 277 declara `extend Decorator { pub fn is(self, other: Decorator) -> bool; }` e lê
`a.decorator.is(serverOnly)`. `is` é palavra-chave: nem `fn is(self, …)` nem `a.is(b)` passam no parser
(nenhuma palavra-chave serve de nome de método). O passo 23 construiu o campo `decorator` de todo
`DeclAnnotation` (a identidade da declaração, alias e namespace resolvidos); a comparação não.

- [ ] **(a)** `is` admitido como nome de método depois do `.` e na declaração.
  ```bp
  if (a.decorator.is(serverOnly)) decl.fail("…");
  ```
- [ ] **(b)** Um nome que não é palavra-chave.
  ```bp
  extend Decorator { pub fn same(self, other: Decorator) -> bool; }
  if (a.decorator.same(serverOnly)) decl.fail("…");
  ```
- [ ] **(c)** `==` entre dois `Decorator`, sem método.
  ```bp
  if (a.decorator == serverOnly) decl.fail("…");
  ```

**Recomendação: (b)** — uma regra de palavras reservadas, sem exceção.

### 08-f · Onde moram Markdown e YAML

**Trava:** `08-bpp/121` passo 3 (o leitor de frontmatter; os passos 1–2 não esperam nada e abrem já) · uma linha da `02/97` (o `yaml` no std, se for a (b)) · ⏳ pronto para abrir thread ao responder

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

### snap-a · Os mapas de snapshot — aposentados; ficam os snapshots que existem ou que um contrato lê

**Trava:** `03/107` (a caixa dos dois snapshots do `onze-release`); fora de 00–03: a frente 135 inteira (`20-snap`) e, por ela, 97 passo 7, 19 passo 6, 26 passo 7, 33, 50 passo 8, 51 passo 7, 53 e 71 passo 6

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
assert tokenDeclarations(.Border.Rounded.Md) == "border-radius:var(--radius-md)";   // emilia.bp:10615
// e os .snap que existem: std 4, jhonstart 39, onze 51 (24 deles via snapshots.assertAs)
```

- [ ] **(a)** Como proposto: os mapas viram registro fechado; os `.snap` que existem ficam (std 4,
  jhonstart 39, onze 51) e só mudam junto com o seu teste; um `.snap` novo só onde os bytes exatos são
  contrato de outro pacote (os `text_…` e `dockerfile_…` do onze-release, já em disco, para a
  `107-release`); helpers só os que um consumidor usa — `emilia-test`: `assertClassName` (sob
  `defaultTheme()`, gravando `e_39b87d03`) e `assertCss(loc, tokens, th)`; `rakun-test`:
  `assertResponse(loc, res)` sobre `MockMvc.perform`; os do jhonstart e do onze como estão (o
  `assertAlias` do onze sai com a 218). Os 21 valores sem verificação viram testes simples, e 97 passo 7,
  26 passo 7, 33 passos 3–4, 50 passo 8, 51 passo 7 fecham com uma linha no `AGENTS.md`. Só **3** `.snap`
  novos (emilia-test 2, rakun-test 1).
  ```bp
  try asserts.throwsWith({ -> val _v = verify(repo, times(1)).find(eq(7)); 0; },
      "mocks.verify: find - expected exactly 1 matching call(s), got 2");       // std, nos dois targets
  assertClassName(loc, cardTokens(), defaultTheme());                           // emilia-test → e_39b87d03
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

### 05emilia-n · As linhas do Tailwind sem dono

**Trava:** `06-emilia/34` passo 4 (condicional: só as quatro linhas de feature) · ⏳ pronto para abrir thread ao responder

**Contexto.** Quatro linhas não têm dono: as formas nomeadas `:has()` / `:not()` / ARIA / data /
`in-[…]` (hoje só por `arbSel`); grupos e peers nomeados; `@theme inline`; translate negativo
(`TranslateX/Y.Neg` não existe, `tokens.bp:2259-2272`). A quinta — um breakpoint apagado emitindo
`@media (width >= )` — é da decisão 300: "um token que nomeia um breakpoint apagado ou ausente é erro
de compilação onde a lista de tokens é conhecida no comptime" (34 passo 3, incondicional).

**Hoje** (ilustrativo):
```text
:has() / :not() / ARIA / data / in-[…]   → só por arbSel
TranslateX.Neg / TranslateY.Neg          → não existem
```

- [ ] **(a)** Nenhuma: as quatro fora do escopo em `docs.md` § Deviations, escritas com `arbSel`.
  ```text
  docs.md § Deviations: as quatro linhas; quem precisa escreve com arbSel
  ```
- [ ] **(b)** Translate negativo e grupos / peers nomeados.
  ```text
  TranslateX.Neg / TranslateY.Neg   ;   GroupNamed(name, inner) / PeerNamed(name, inner)
  ```
- [ ] **(c)** As quatro, `@theme inline` incluído (um segundo modo de render).
  ```text
  (b) + as formas nomeadas + @theme inline
  ```

**Recomendação: (a); (b)** se você quiser alguma feature. **Bloqueia:** 34 passo 4 (condicional).

### std-d · `io.process`: sinais e leitor de TTY

**Trava:** `02/97` passo 6 (condicional); fora de 00–03: onze 50 passos 4 e 7

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
  $ onze start            # faz exec do nó erl (bin/onze da 71): a VM é PID 1 e recebe o SIGTERM direto
  $ onze create           # sem nome e sem --yes:
  error: `onze create` needs <name> (or --yes)    # o nome é posicional; as flags são --example, --port, …
  ```

**Recomendação: (b)**, a mais restritiva. **Bloqueia:** onze 50 passos 4 e 7; 97 passo 6 (condicional).

### 24-g · A forma do `std/async` com uma Task que nunca falha

**Trava:** `02/97` passo 5 (o `RetryPolicy` construído sobre o `std/async`; resíduo) e `01-compiler/24` passo 2 · ⏳ thread da 97 rodando os resíduos

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
**Bloqueia:** nada — o README da `01-std/02-std-async-primitives` (1.0.10) já especifica o `allOf` sobre
Tasks iniciadas.

### 24-a · Os códigos de diagnóstico de efeito que sobraram

**Trava:** `01-compiler/24` passo 2 (as confirmações)

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

**Trava:** `01-compiler/24` passo 2 (as confirmações); a forma de combinadores do `std/async` (`02/97`)

**Contexto.** O invólucro assíncrono antigo do prelúdio tinha `map` / `flatMap` / `await`. A decisão
120 fala em "`.map`, `.then` e afins, sem parâmetro de erro" — uma Task nunca falha, então não há
`mapError`. A implementação ficou com uma grafia por operação. Os dois métodos estão declarados em
`builtins.d.bp`, que pela decisão 252 é o contrato dos builtins: a checagem do 134 (passo 3) já liga as
chamadas `@…` às declarações, mas ainda não percorre os tipos e seus métodos (passo 2 em aberto), então
uma chamada de `map` / `then` ainda não é checada contra a declaração. Nenhum backend os baixa ainda.

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

**Trava:** `01-compiler/24` passo 2 (as confirmações)

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

### 23-b · As quatro funções do `base64` foram aposentadas

**Trava:** `01-compiler/23` passo 2 (as confirmações)

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

### std-c · O namespace de pasta é uma reescrita do programa

**Trava:** `01-compiler/23` passo 2 (as confirmações); uma reversão abre passo no `01-checker`

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

### erk-a · A fonte de uma consulta `erika "…"` no corpo de um método *(proposta)*

**Trava:** `04-rakun/137` passo 2 (a forma no corpo); a célula da forma no corpo do passo 7 da rakun 08 · ⏳ pronto para abrir thread ao responder

**Contexto.** Pela 312, `from User` nomeia o tipo; uma fonte de banco implementa o `QuerySource<T>` do
erika (o `Table<T>` do rakun-data). Num behavior `#[repository]`, o `Users.Sql(db)` gerado é dono da
fonte (313). No corpo de um método, nada na consulta diz qual valor é a fonte. A 137 vive no
repositório do erika e não espera o 128; o passo 5 espera o passo 29 do `01-checker`, o passo 2 só a
forma no corpo.

**Hoje** (ilustrativo):
```bp
type Report(users: Table<User>) {
    fn active(self: Self) -> @Result<User[], StoreError> {
        return erika "select * from User where active = true";   // qual valor é a fonte?
    }
}
```

- [ ] **(a)** A fonte é um buraco; `from User` fica só para a forma em memória e a de anotação.
  ```bp
  return erika "select * from ${self.users} where active = true";   // tipo da linha vindo de Table<User>
  ```
- [ ] **(b)** `from User` em todo lugar; no corpo, a fonte é o único campo de `self` do tipo
  `Table<User>` — nenhum ou dois é erro na consulta (por tipo, como o contêiner do rakun injeta).
  ```bp
  return erika "select * from User where active = true";   // fonte: self.users, o único Table<User>
  ```
- [ ] **(c)** As duas: a (b), e a (a) quando há dois campos do mesmo tipo de tabela.
  ```bp
  return erika "select * from ${self.archived} where active = true";   // dois Table<User>: buraco
  ```

**Recomendação: (b).** Uma grafia só do `from`, em todo lugar; a fonte achada pelo tipo, nunca por
nome. **Bloqueia:** o passo 2 da `04-rakun/137` (a forma no corpo); a célula da forma no corpo do passo
7 da rakun 08.

### 97-s13-a · O `abs()` do mínimo de um tipo inteiro (decisões 264 e 319)

**Trava:** nada no gate; só a metade `abs` do `02/97` passo 13

**Contexto.** O `abs` é uma chamada host (`erlang:abs`, `Math.abs` ou a negação de um `BigInt`), não um
dos operadores da 264, então nenhum teste de faixa roda: o `abs` do mínimo responde um valor fora do
tipo, igual em commonJS, erlang e beam. O `Signed` declara um `abs` só para `I32` e `I64`, então o
template não sabe a largura.

**Hoje:**
```bp
fn lo64() -> i64 { return -9223372036854775807l - 1l; }
@print(lo64().abs());   // 9223372036854775808 — fora do i64 (commonJS, erlang, beam)
```

- [ ] **(a) ★** O `abs` aborta fora do tipo como o `-` unário: sai do `Signed` para `I32` e `I64`, cada um com o seu limite.
  ```bp
  @print(lo64().abs());   // aborta: integer overflow: abs on i64 — nos quatro targets
  ```
- [ ] **(b)** Como está: o valor matemático, mesmo fora do tipo.
  ```bp
  @print(lo64().abs());   // 9223372036854775808, tipado i64
  ```
- [ ] **(c)** O `abs` responde o tipo sem sinal.
  ```bp
  val m: u64 = lo64().abs();   // 9223372036854775808ul
  ```

**Recomendação: (a).** Um valor fora do tipo declarado nunca existe (264); custa duas declarações.
**Bloqueia:** nada no gate; a célula `run/i64_number_methods_past_js_safe` fica longe do mínimo.

### 97-s13-b · O `io/clock` com uma época fora da faixa de tempo do ECMAScript (decisão 319)

**Trava:** os três templates restantes da linha `io/clock` do `02/97` passo 13

**Contexto.** `formatIso8601`, `toCivil` e `offsetMinutes` recebem uma época `i64`, e a forma Node monta
um `Date`, cuja faixa é ±8,64 × 10^15 ms (anos −271821 … 275760). Toda época `BigInt` (além de
2^53 − 1) fica fora dela. A 319 manda o template Node aceitar `number | bigint`, mas não diz o que ele
responde para essas épocas.

**Hoje:**
```bp
@print(clock.toCivil(8640000000000001l).year);   // NaN no commonJS, 275760 no erlang
clock.toCivil(9007199254740993l);                // commonJS: TypeError: Cannot convert a BigInt value to a number
clock.formatIso8601(8640000000000000l);          // "+275760-09-13T00:00:00.000Z" no commonJS; erlang aborta (badarg depois do ano 9999)
```

- [ ] **(a)** Um domínio só em todos os targets, recusado fora dele: as épocas que o RFC 3339 escreve, 0000-01-01 … 9999-12-31.
  ```bp
  clock.toCivil(253402300800000l);   // aborta em todos os targets: clock.toCivil: 253402300800000 is outside 0000-01-01 … 9999-12-31
  ```
- [ ] **(b)** Toda época `i64` responde, igual em todos os targets: um corpo botopink (dias a partir da data civil, algoritmo de Hinnant) no lugar de `Date` e `calendar`.
  ```bp
  @print(clock.toCivil(9007199254740993l).year);   // 287396 em todos os targets
  ```
- [ ] **(c) ★** Como está: a faixa e a resposta de cada host.
  ```bp
  @print(clock.toCivil(8640000000000001l).year);   // NaN no commonJS, 275760 no erlang
  ```

**Recomendação: (a).** Nenhum target responde `NaN` ou uma data que outro recusa, e o RFC 3339 — o texto que `formatIso8601` e `parseIso8601` prometem — tem ano de quatro dígitos.
**Bloqueia:** só os três templates; o resto da linha `io/clock` entrou (as leituras são `number` por construção, `wide` e `largestExactMillis` são botopink).

### 97-s13-c · O limite de 2^53 − 1 do `clock.parseDuration` depois da 319

**Trava:** nada

**Contexto.** O `parseDuration` recusa uma duração além de 2^53 − 1 ms porque "os dois targets não contam
igual" depois dela — verdade antes da 319, falso depois: um `i64` é exato até 2^63 − 1 em todos os targets.

**Hoje:**
```bp
clock.parseDuration("9007199254740992ms");   // Error("clock.parseDuration: \"9007199254740992ms\" is out of range")
```

- [ ] **(a) ★** Manter o limite: uma duração segue como atraso de timer ou número JSON, os dois `f64`, e além de 2^53 deixa de ser exata lá.
  ```bp
  clock.parseDuration("9007199254740992ms");   // Error(… is out of range)
  ```
- [ ] **(b)** O limite é o do `i64`.
  ```bp
  clock.parseDuration("9007199254740992ms");   // Ok(9007199254740992)
  clock.parseDuration("106751991168d");        // Error(… is out of range) — além de 2^63 − 1 ms
  ```

**Recomendação: (a).** A faixa menor recusa mais, e nenhum chamador medido precisa de mais de 285 426 anos.
**Bloqueia:** nada; o comentário de `largestExactMillis` cita a pergunta.

### 97-s13-d · A resolução do `mtime` do `fs.stat`

**Trava:** nada

**Contexto.** A forma Node responde `mtime` em milissegundos inteiros (`mtimeNs` arredondado para baixo), a
erlang em segundos inteiros × 1000 (`file:read_file_info/2` com `{time, posix}` não tem fração de segundo).

**Hoje:**
```bp
fs.stat("five.txt")   // mtime: 1760000000734 no commonJS, 1760000000000 no erlang e no beam
```

- [ ] **(a)** Um valor só em todos os targets: a forma Node também arredonda para segundos inteiros.
  ```bp
  fs.stat("five.txt")   // mtime: 1760000000000 em todos os targets
  ```
- [ ] **(b) ★** Milissegundos onde o host tem (como está).
  ```bp
  fs.stat("five.txt")   // mtime: 1760000000734 no commonJS, 1760000000000 no erlang
  ```
- [ ] **(c)** O campo vira segundos inteiros (`mtimeSeconds: i64`), a unidade que todo host dá.
  ```bp
  fs.stat("five.txt")   // mtimeSeconds: 1760000000 em todos os targets
  ```

**Recomendação: (a).** O mesmo arquivo responde o mesmo valor em todos os targets; a (c) renomeia um campo público pelo mesmo resultado.
**Bloqueia:** nada; `run/std_io_i64_canonical` imprime só `mtime > 2020-01-01`.

### 110-a · O `testing.asserts` no wasm, depois da regra estrita (decisão 146)

**Trava:** `02/97` passo 11 (std no wasm, grupo 3: a pergunta por módulo) e `05-wasm` passo 5 ("std compila no wasm") · ⏳ thread da 97 rodando os passos 11 e 12

**Contexto.** A decisão 146 diz que uma função cujo corpo alcança uma função host sem versão para o
target é recusada na declaração, chamada ou não. Com isso, um programa wasm que importa
`testing.asserts` é recusado: quatro das 27 funções dele chegam a uma célula host (`canonical`,
`regexMatches`, `tryCatch`) que não tem versão wasm. A thread ficou com (1) porque nada no gate roda
asserções no wasm hoje e as outras saídas mudam API (2) ou exigem trabalho grande no backend wasm (3).
A (1) segue a decisão 230 ("a std module wasm cannot build is a located refusal") e a opção (a) do
passo 11 do `02/97`, que pede esta pergunta por módulo. A última oração da 146 ("`testing.asserts` is
restructured so nothing without a wasm binding is reachable from it on wasm") pedia a (2) ou a (3):
responder (1) emenda essa oração.

**Hoje:**
```bp
import {testing.asserts} from "std";      // --target wasm
// error: `canonical` has no `#[@External.<Target>(…)]` for the wasm backend — in `std/testing/asserts`, which this import links
```
```
deepEquals → canonical        matches → regexMatches        throws, throwsWith → tryCatch
usos nos repositórios: throwsWith ~290 · throws 4 · deepEquals 2 · matches 1 · 140 arquivos importam o módulo
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

### atm-a · Nomes dos hooks de cookie: substantivos, ou os verbos da 294/295 *(proposta)*

**Trava:** `03/104` passo 6 (os hooks de cookie); fora de 00–03: 123, 127, `07-onze/53`

**Contexto.** A regra do jhonstart (no cabeçalho do `hooks.bp`) diz que hook é **substantivo** e que o
`use` é quem ativa: `use state(0)`, `use memo(…)`. Para as locais de request a 296 já decidiu: elas são
átomos do cardume e "each bridge spells the same hooks (`atomValue`, `atomState`, `atomSetter`,
`atomReset` …)" — `use setLocal(currentUser)` vira `use atomSetter(currentUser)`. Resta o cookie: o
`Cookie<T>` fica no `http` (294, 296), e a 294/295 escreveram **verbos** para escrever e limpar.

**Hoje:**
```bp
val session = use cookie(sessionCookie);          // 294: leitura, substantivo
val setSession = use setCookie(sessionCookie);    // 294/295: verbo
val clearSession = use clearCookie(sessionCookie);
```

- [ ] **(a)** Substantivo também no cookie, como no cardume.
  ```bp
  val setSession = use cookieSetter(sessionCookie);
  val clearSession = use cookieClearer(sessionCookie);
  ```
- [ ] **(b)** Manter os verbos da 294/295 no cookie (`use setCookie`, `use clearCookie`); substantivo no
  resto.
- [ ] **(c)** Cada lib com o seu.

**Recomendação: (a)** — uma regra só, que já é a do jhonstart e a do cardume.
**Bloqueia:** 123; 127; 104 passo 6; `07-onze/53` (os sites de cookie).

### s35-a · Como o corpo de um decorator entrega o `@Expr` de um parâmetro ao programa (364 (1))

**Trava:** `01-checker` s35, caixa 3 (as células `run/decorator_expr_rule_called` e `run/decorator_expr_message_runtime`); o `#[check]` da 125 s7 chegar à validação em tempo de execução.

**Contexto.** A 364 (1) diz que o corpo entrega o `@Expr` a uma saída — meta tipado (298), um membro, código emitido — e o programa o avalia em tempo de execução: `rule` é chamada como `passwordsMatch`, `message` pode ser `t("signup.mismatch")`.

**Hoje.** Toda saída recebe string (`@emit(source: string)`, `decl.addMember(source: string)`, `decl.setMeta(key, value)`); o meta tipado (`decl.addMeta`) é da 130 s8 e não existe. Um parâmetro só chega ao corpo como `x.value` (ou `x.fail`); `message.text()` é `expr-param-method`.

- [ ] **(a)** O meta tipado leva o `@Expr`: o registro é montado no programa que o lê, cada expressão no lugar em que foi escrita.
  ```bp
  pub type Check<T>(message: @Expr<string>, rule: @Expr<fn(v: T) -> bool>)
  decl.addMeta(Check(message: message, rule: rule));   // espera a 130 s8
  ```
- [ ] **(b)** O texto da fonte: `.text()` responde o argumento como foi escrito, colado numa saída de string.
  ```bp
  decl.addMember("pub fn rule(self: Self) -> bool { return " + rule.text() + "(self); }");
  ```
- [ ] **(c)** Um membro tipado (a forma ilustrativa do exemplo 1): o fechamento usa o argumento.
  ```bp
  decl.addMember("validate", fn(self: T) -> bool { return rule(self); });
  ```

**Recomendação: (a)**, com (c) como forma de membro — tipado e localizado; (b) cola texto sem tipo.

### s35-b · Saber se um argumento função opcional foi dado (`rule == null`)

**Trava:** nada — implementado como (a).

**Contexto.** `comptime rule: @Expr<?fn(v: T) -> bool> = null`: uma função opcional é função para a 364 (3).

**Hoje.** `rule.value == null` é `expr-value-of-function` na leitura; as células distinguem a forma da função por `decl.kind == DeclKind.Fn`.

- [ ] **(a)** Como está: sem teste de nulo; o corpo lê a declaração, ou a biblioteca separa o decorator.
  ```bp
  if (decl.kind == DeclKind.Fn) { … }   // #[check] numa função
  ```
- [ ] **(b)** Comparar com `null` é permitido (não chama nada); qualquer outra leitura de `rule.value` é recusada.
  ```bp
  if (rule.value == null) { … }
  ```
- [ ] **(c)** O parâmetro em si é opcional.
  ```bp
  fn check<T>(comptime decl: @Decl<T>, comptime rule: ?@Expr<fn(v: T) -> bool> = null) {
      if (rule == null) { … }
  }
  ```

**Recomendação: (a).** Nenhuma leitura do `@Expr` de uma função; (b) se a grafia do exemplo 1 for desejada.

### s35-c · A grafia de um variádico `comptime`

**Trava:** nada — implementado como (a).

**Contexto.** `Type.pick` / `Type.omit` da std e as células recebem os campos como variádico.

**Hoje.** `comptime ..fields: @Expr<Type.Field<T>[]>`: cada argumento é conferido contra `Type.Field<T>`, e `fields.value` é o array.

- [ ] **(a)** Como está, `@Expr<T[]>`.
  ```bp
  fn index<T>(comptime decl: @Decl<T>, comptime ..fields: @Expr<Type.Field<T>[]>) {
      decl.setMeta("columns", fields.value.map({ f -> f.name }).join(","));
  }
  ```
- [ ] **(b)** `@Expr<T>[]`, uma expressão por argumento (cada uma com seu `.fail`).
  ```bp
  fn index<T>(comptime decl: @Decl<T>, comptime ..fields: @Expr<Type.Field<T>>[]) {
      decl.setMeta("columns", fields.map({ f -> f.value.name }).join(","));
  }
  ```

**Recomendação: (a).** O `comptime x: @Expr<T>` da 364 com `T` o tipo declarado do parâmetro.

### s35-d · O argumento de uma função comum que não é conhecido no build

**Trava:** nada — implementado como (a).

**Contexto.** A 364 emenda a 280: um argumento não conhecido no build é recusado só onde `.value` o lê.

**Hoje.** Vale para decorator (um argumento não lido é aceito, `run/decorator_expr_unread_argument`); numa função comum o argumento `comptime` continua conhecido no build (`comptime-arg-not-known`, regra da 297) — o corpo é código de execução e `n.value` é o valor especializado.

- [ ] **(a)** Como está.
  ```bp
  fn tag(comptime n: @Expr<i32>, x: i32) -> i32 { return x; }
  tag(k, 1);   // k local: comptime-arg-not-known
  ```
- [ ] **(b)** A regra do decorator para toda função: `tag(k, 1)` é aceito, porque o corpo não lê `n.value`.

**Recomendação: (a).** O parâmetro `comptime` de uma função de execução é a sua especialização.

### s24-b · O `#[check]` do exemplo 1 põe parâmetros com default antes de `message`

**Trava:** 125 s7 (a assinatura do `#[check]` em `repository/validation`); o texto do arquivo de exemplos.

**Contexto.** O exemplo 1 declara `check<T>(…, comptime rule: ?fn(v: T) -> bool = null, comptime at: ?Type.Field<T> = null, comptime message: string, comptime code: Code = .Custom)`. A decisão 244 recusa no parse um parâmetro com default seguido de um obrigatório, em toda função (`fn-param-default-trailing-only`).

**Hoje.** A declaração do exemplo não compila; as células do passo 24 declaram `message` primeiro.

- [ ] **(a)** A 244 vale: `message` primeiro.
  ```bp
  pub fn check<T>(comptime decl: @Decl<T>, comptime message: string,
      comptime rule: ?fn(v: T) -> bool = null, comptime at: ?Type.Field<T> = null,
      comptime code: Code = .Custom) { … }
  #[check("As senhas não batem", passwordsMatch, at: .confirm)]
  ```
- [ ] **(b)** Um decorator pode ter default antes de um obrigatório, que então vai sempre por rótulo — o exemplo compila como está; emenda a 244 só para decorators.
  ```bp
  #[check(passwordsMatch, at: .confirm, message: "As senhas não batem")]
  ```
- [ ] **(c)** `message` ganha default `""`.
  ```bp
  #[check(passwordsMatch, at: .confirm)]   // uma regra sem texto
  ```

**Recomendação: (a).** Uma regra de parâmetro para toda função (244); o exemplo segue ela.

### lg2-q · Localização no fonte dentro de `@Decl`

**Trava:** `01-compiler/01-checker`: a linha reduzida de `decl.loc`; fora de 00–03: rakun 22

**Contexto.** Um decorator não sabe em que arquivo está a declaração: `decl.loc.file` dá `badkey`. O
roteamento por arquivo (rakun 22, onze 53) queria deduzir a rota do caminho, como o `app/` do
Next.js. As decisões 289 e 290 já escrevem a forma (1): o `page.bpp` de uma rota leva a rota como
argumento do seu decorator (`#[page("blog/[slug]", paths: allPosts)]`, `#[page("blog/[slug]",
revalidate: hours(1))]`), e a página lê os segmentos por hook (293), sem parâmetro, devolvendo `View`
(275, 276). O segmento explícito é gerado e verificado pelo CLI da frente 50. Resta só registrar que
`@Decl` não ganha `loc` — o `decl.name` de um default anônimo já é o nome do arquivo (289), não o
caminho.

**Hoje:**
```bp
fn page(comptime decl: @Decl, comptime route: string) { decl.loc.file }   // badkey
```

- [ ] **(1)** Não: o segmento é argumento explícito (a forma da 289/290).
  ```bp
  // app/blog/[slug]/page.bp
  #[page("blog/[slug]")] pub fn BlogPost() -> View { val p = use params<BlogParams>(); … }
  ```
- [ ] **(2)** `decl.loc` (o `SourceLocation` do `@src()`): `#[page]` deduz a rota do caminho do arquivo.
  ```bp
  // app/blog/[slug]/page.bp
  #[page] pub fn BlogPost() -> View { … }   // rota "blog/[slug]" lida de decl.loc.file
  ```

**Recomendação: (1).** A saída de um decorator nunca depende de onde o arquivo está; as 289/290 já
foram escritas assim. **Bloqueia:** a linha; rakun 22 (os exemplos com `#[page("…")]` já seguem a (1)).

---

### 97-s16-a · Onde ficam as tabelas geradas do `unicode` *(proposta)*

**Trava:** nada hoje — a 97 s16 entra com a forma (b) · confirmar ou mudar o arquivo

**Contexto.** O README da 97 s16 pede as tabelas em `libs/std/src/unicode/tables.bp`, mas o sistema de
módulos não alcança esse caminho: um `mod` resolve só `<nome>.bp` ou `<nome>/mod.bp` ao lado do arquivo
que o declara, então um módulo de arquivo `unicode.bp` não pode ter filhos. Transformar `unicode` numa
pasta mudaria a API dele para um namespace.

**Hoje** (como a thread fez):
```bp
// libs/std/src/root.bp
mod unicode_tables;          // privado, gerado por `zig build gen-unicode`
// libs/std/src/unicode.bp
import {unicode_tables as tables};
```

- [ ] **(a)** `unicode` vira pasta: `libs/std/src/unicode/mod.bp` com `mod tables;` — o caminho do README;
  `unicode.normalize(…)` continua igual para quem usa.
  ```bp
  // libs/std/src/unicode/mod.bp
  mod tables;
  pub fn normalize(s: string, form: Form) -> string { … tables.ccc(cp) … }
  ```
- [ ] **(b)** Fica como a thread fez: um irmão privado `unicode_tables.bp` na raiz da std.

**Recomendação (da thread): (b)** — nenhuma mudança de API, um arquivo gerado e privado. **Bloqueia:** nada.

### 125-a · Como os documentos JSON Schema são conferidos contra o meta-schema 2020-12 *(proposta)* ⏳

**Trava:** `03-bundled-libs/125` passo 9, caixa 3 · ⏳ pronto para abrir thread ao responder

**Contexto.** A terceira caixa do passo 9 pede "um script node em `test/tools/`, rodado por
`test/json_schema_test.bp` no commonJS, sem pular nada". Conferir contra o meta-schema 2020-12 exige um
validador (Ajv 2020 ou outro), e nenhum é alcançável pela suíte do `repository/validation`: o
repositório só tem `.bp`, não tem `package.json`, e um teste não pode instalar da rede (CI e gate frio).
Os documentos já estão fixados como literais contra o § 8 do ZOD_DOCUMENTATION.md (dezesseis documentos
e nós em `test/json_schema_test.bp`).

**Hoje:**
```bp
// test/json_schema_test.bp compara o documento gerado com um literal; nenhum validador roda
```

- [ ] **(a)** Trazer um validador para `test/tools/` (o build standalone do Ajv 2020, ~120 kB de JS, MIT)
  e rodá-lo pelo `test/json_schema_test.bp` com `io.process.run("node", …)` no commonJS:
  ```bp
  // node test/tools/check-schema.js '<documento>'  → "ok" ou a lista de erros
  ```
- [ ] **(b)** Uma checagem estrutural escrita à mão das palavras-chave que a biblioteca escreve (`type`,
  `properties`, `required`, `items`, `prefixItems`, `$ref`, `$defs`, `anyOf`, `format`, …) contra o
  vocabulário do meta-schema, em botopink — sem dependência, mas não é "validar contra o meta-schema".
- [ ] **(c)** Tirar a caixa: os literais contra o § 8 são a evidência.

**Recomendação: (a)** — a leitura mais restritiva da caixa, um validador de verdade, sem rede; versão e
hash do arquivo trazido registrados no `AGENTS.md` do `repository/validation`. **Bloqueia:** 125 passo 9,
caixa 3.

### 140-a · O que é uma `@Task` pendente no wasm (frente 140, passo 4)

**Trava:** `01-compiler/140` passos 4 e 5 (`run/wasm_host_async`) e a metade JSPI do 6; `02/97` passo 17

**Contexto.** No wasm `@Task<T>` é `T`: `await` é identidade e `async { … }` roda onde está escrito. A 334 (4) pede que a Task no `wasi` rode "até o fim quando aguardada, bloqueando no seu pollable", e `race` responda "o primeiro pollable pronto"; sem pollable não há o que esperar, e `delay` bloquearia onde é chamado. A 335 (2) faz do resultado o contrato. Um corpo que aguarda por dentro não pode ser suspenso num host de uma thread que roda até o fim.

**Hoje:**
```bp
val t = async.delay(30, "a");   // bloqueia 30 ms aqui; `await t` é identidade
```

- [ ] **(1)** Task feita pelo host (`delay`, `fetch`) vira caixa `{pollable, valor}`; o resto continua ansioso.
  ```bp
  await async.race([async.delay(30, "a"), async.delay(10, "b")])          // "b" nos quatro targets
  await async.raceOf([{ -> async { await async.delay(30, ()); "a" } }, { -> async.delay(10, "b") }])
  // "a" no wasm (o primeiro thunk bloqueia 30 ms), "b" no node
  ```
- [ ] **(2)** Toda Task é preguiçosa (thunk + pollable opcional), roda no `await`; mesma divergência para um corpo que aguarda por dentro.
- [ ] **(3)** (1), e no wasm `race`/`raceOf` aceitam só Tasks feitas pelo host: um operando que roda código botopink antes é `std-unsupported-on-target … on host 'wasi'` na chamada.
  ```bp
  await async.race([async.delay(30, "a"), async.delay(10, "b")])   // compila
  await async.raceOf([…])                                            // recusado no wasm
  ```

**Recomendação: (3).** Um programa cuja resposta pode diferir entre hosts não compila (335 (2), decisão 67).

### 140-b · Como a std liga uma função de host que devolve Task no wasm

**Trava:** `01-compiler/140` passos 4–5; `02/97` passo 17

**Contexto.** Os adaptadores `wasi:` da 238 só têm slots numéricos (`i32`, `i64`, `f32`, `f64`, `bool`); `delay<T>(millis: i32, value: T) -> @Task<T>` e `fetch(req: Request) -> @Task<@Result<Response, HttpError>>` têm tipos genéricos e records.

**Hoje:**
```bp
#[@External.Wasm("wasi:random_f64")] pub declare fn float() -> f64;   // só formas numéricas
```

- [ ] **(1)** Só adaptadores numéricos; a std escreve `delay`/`fetch` como corpos `fn:` sobre eles (corpo ansioso: a caixa da 140-a (1) não sai da std).
  ```bp
  #[@External.Wasm(fn: delayBody)] pub declare fn delay<T>(millis: i32, value: T) -> @Task<T>;
  fn delayBody<T>(millis: i32, value: T) -> @Task<T> { sleepMillis(millis); return value; }
  ```
- [ ] **(2)** A assinatura de um adaptador pode nomear `@Task<T>` e um `T` genérico, conferida pela forma; o compilador monta a caixa.
  ```bp
  #[@External.Wasm(wasi: .Delay)] pub declare fn delay<T>(millis: i32, value: T) -> @Task<T>;
  ```
- [ ] **(3)** Records cruzam no layout do compilador (`Request`, `Response` lidos pelo adaptador) — o `fetch` precisa disso também sob (2).

**Recomendação: (2), com (3) só para o `fetch`.** Cada assinatura na lista do docs.md; qualquer outra forma recusada na anotação.

### 140-c · O que uma ligação do host `browser` nomeia

**Trava:** `01-compiler/140` passo 6 (`fetch`, `setTimeout` no `browser`); `02/97` passo 17

**Contexto.** A 334 (3) dá `host: .Browser`; a 238/305 têm três formas (`op:`, `fn:`, `wasi:`), nenhuma é import JavaScript. Já feito (passo 6): o loader do `browser` serve em JavaScript os dois imports preview 1 do módulo (`fd_write`, `random_get`), então um adaptador `wasi:` sem `host:` já roda nos dois hosts.

**Hoje:**
```bp
#[@External.Wasm("wasi:random_f64")] pub declare fn float() -> f64;   // wasmtime e node, iguais
```

- [ ] **(1)** Quarta forma `js: .Adaptador` para `host: .Browser`, uma segunda lista, o loader com o JavaScript de cada um.
  ```bp
  #[@External.Wasm(js: .Fetch, host: .Browser)]
  #[@External.Wasm(wasi: .HttpOutgoing, host: .Wasi)]
  pub declare fn fetch(req: Request) -> @Task<@Result<Response, HttpError>>;
  ```
- [ ] **(2)** Uma lista só para os dois hosts: cada adaptador `wasi:` tem implementação preview 2 (o componente) e JavaScript (o loader); `host:` só onde os hosts diferem de fato.
  ```bp
  #[@External.Wasm(wasi: .HttpOutgoing)]
  pub declare fn fetch(req: Request) -> @Task<@Result<Response, HttpError>>;
  ```
- [ ] **(3)** Texto JavaScript sem rótulo numa ligação `.Browser` (código de host, como no `@External.Node`).

**Recomendação: (2).** Uma lista fechada, paridade por construção ("ligado nos dois hosts ou em nenhum").

## Parte 2 — Trava, mas o passo ainda espera outra frente

| Id | Assunto | Recomendação | Trava | Espera também |
|---|---|---|---|---|
| `67-a` | Onde as caixas de forms do lado do DOM são afirmadas | (a). As caixas rodam no gate da biblioteca dona, onde quebram primeiro, sem dependência nova; o navegador do onze 53 confere de novo. | a forma dos passos 1–3 da 67 (escritos para a (a)); o caminho de | 26; 103 s2 |
| `03r-ab` | Front 09: stores de protocolo binário | (a) — nunca cair para ETS debaixo de uma URL do Mongo; o braço Elasticsearch sem aresta para o `rakun-client` (ver `ctr-w`; o passo 3 da 09 ainda passa por ele). A frente já segue a (a); falta só o registro. | 09 passo 5 (as células de recusa). | 09: 19 s1, 13 (grupo B, depois do 128) |
| `ctr-p` | Confirmação `std-a` × confirmação `03r-e` | (a). Recusar é o mais restritivo (67) e mantém a lógica compartilhada no std. | os leitores do rakun 04; a varredura de consumidores da 104 (passo 5) | rakun 04: o 128; 104 s5: os donos dos arquivos consumidores (04, 65, 79, 12, 19, 22, 123, 49, 51) |
| `03r-q` | Roteamento por locale mora no `rakun-app` (★) | (a) — a 105 extrai o que for comum para o bundled `i18n`. | `03/105` inteira (o `i18n` abre com ela confirmada) | 105: 104 s5, 22, 26 |
| `07-g` | Renderização de release OTP | (a) — uma cópia só, que serve aos dois frameworks nos dois targets. | `03/107` inteira (frente condicional) | 107: 71, 81 |
| `95-f` | A tomada do onze sem o branch órfão e sem arquivar nada | (1) — confirmar a árvore; uma decisão nova emenda a 79. | `02/98` passo 3 | 98 (W11): os passos `-test` e README de cada trilha de biblioteca |
| `nat-f3` | `files` e `workspaces` no `botopink.json` (98) | (a) — fato de empacotamento; a 270 já conta com `files`. | 98 | 98 (W11): idem |
| `nat-d9` | Nomes do LINQ no erika ao lado dos do std (98) | nenhuma desta revisão — depende do que você quer que o erika seja; a (b) é uma leitura justa. | 98 (erika) | 98 (W11): idem |
| `nat-d6` | `throw "nav:not-found"` ao lado do `noreturn` (53) | (a). Junto com a lg2-l e a lg2-h. | `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a. | 26 (depois da 118); 53 (49, 50, 51, 71, 26, 27, 67, 22, 12, 65) |
| `nat-d7` | Anotações de ciclo de vida ao lado de interface (rakun 04) | (a). | rakun 04. | rakun 04: o 128 |
| `nat-d8` | Hook chamado `use…` debaixo de `use` (53) | (a). | os exemplos da `07-onze/53`. | 53: idem |
| `nat-f2` | As opções do `onze.json`: `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h) | (a) — é configuração, pode ficar no JSON (284), e o build confere como conferiria o código, do jeito que a 299 faz com a do rakun. | 124; 08-h; `07-onze/49` e `50`. | 124: toda outra frente da 08; 49, 50: 102 s3 |
| `nat-f4` | O prefixo `ONZE_PUBLIC_` nas variáveis de ambiente (53, `contracts.md`) | (b). | `07-onze/50` e `53`; `contracts.md`. | 50: 102 s3; 53 |
| `50-b` | O que o `onze dev` faz numa mudança | (a), a mais restritiva: um caminho de código só, os mesmos bytes que o `start` serve; (b) depois, se (a) medir lento demais no blog. | 50 passo 2; 53 passo 6 ("`dev` serve toda | 50: 102 s3; 53 |
| `49-e ★` | A metade rakun do boot é um membro próprio — (a) manter — a CLI nunca carrega rakun; o release que serve carrega `onze-server` | (a). | 49 passo 2 | 49 s2: 102 s3 |
| `52-a ★` | A tabela de métricas de fonte é transcrita — (a) manter — cinco famílias funcionam com `adjustFontFallback: true` | (a), com as linhas re-derivadas pelo gerador antes de um release. | 51 passo 4 | 51 s2–6: 22 |
| `29-a ★` | A tabela de starters de island: o que resta é o loader por rota — (a) manter — `globals.starters` + `registerRouteStarters`; nenhum `__` escrito à mão; um loader por rota | (a). A divisão segue a unidade do manifest (a rota) e a entrada não declara global nenhum. | 26 passo 5 (reduzida: `registerRouteStarters` + `globals.starters`) | 26: 118 |
| `erk-b` | O `#[documentQuery]` depois da 313 | (a) agora — uma forma só de repositório para todo store; (b) quando uma necessidade medida pedir. | `04-rakun/09` passo 4 | 09: 19 s1, 13 (depois do 128) |
| `ctr-w` | O braço Elasticsearch da 09 × decisão 185 | (a) — é o que a 185 manda e não acrescenta membro. | 09 passo 3. | 09: 19 s1, 13 (depois do 128) |
| `119-a` | A caixa do grep da 119 passo 1 × o hook byte-idêntico da checagem 4 do CI (`runner-standalone.sh` cita `emilia`) | (a) — o grep mede o texto do próprio pacote (`src`, `test`, `botopink.json`); o hook é um texto só, do gate. | Só marcar a caixa do grep da 119 passo 1. | 119 s1 |
| `03r-ae` | SAML 2.0 ACS | (a) — a 79 está no grupo A do rakun, então está escalada neste milestone; **(b)** só se ela sair dele. Nunca a (c). | 79 passo 3. | 79: grupo A, depois do 128 |
| `03r-af` | Os sete projetos de exemplo nunca construídos | (a). O contrato de cada membro já é afirmado pelos testes do próprio membro; sete frentes de exemplo não provariam nada novo. | 73 passo 3. | 73: grupo A, depois do 128 |
| `03r-ak` | Validar o SBOM contra o schema CycloneDX 1.5 | (a). Valida contra o schema de verdade, sem rede, sem afrouxar a caixa e sem pôr no std um validador genérico por causa de um consumidor só. | 81 passo 3. | 81: grupo A, depois do 128 |
| `03r-al` | Transações de produtor Kafka | (a); o broker real vira linha em `deferred.md`. | 15 passo 5 (só o | 15: grupo A, depois do 128 |
| `03r-am` | Onde moram os dublês de broker e scheduler | (a), com a forma (c) em qualquer caso. | 19 passos 3 e 4. | 19 s1 (grupo A, depois do 128); s3–4 depois |
| `03r-an` | O transporte WebSocket do RSocket depois da 187 | (b). | a primeira e a terceira caixas do passo 2 da 92. | 92: o 128 (RSocket no `rakun-messaging` depois dele), 74, 15 |
| `atm-c` | O `T` de um átomo entre servidor e browser | (b) — restritivo onde importa (o que atravessa) e livre no resto. | 136 passo 6. | 136: 26, 120, 125 |
| `atm-d` | Quais efeitos de átomo entram | (a) — primeiro a store; efeitos num passo próprio quando houver uso medido. | 136 passo 8. | 136: 26, 120, 125 |
| `116-a` | O `import {bpp} from "std"` do próprio módulo de prelúdio (361 × 270) | (a) — o import do `bpp` é do marcador, não do prelúdio: fica fora da lista de itens e isento da recusa da 242; todo outro item `from "std"` num prelúdio segue recusado. Com (a): `bpp.Prelude()` no cabeçalho de um `Card.bpp` é `unbound variable 'bpp'`; (b) o import vira item do prelúdio e o `.bpp` resolve `bpp` sem importar; (c) nenhum import, `#[std.bpp.htmlPrelude]` — sintaxe que não existe hoje | a caixa do prelúdio da 116 passo 2 (a lista de itens e as recusas) | 116 passo 2 |
| `106-a` | O que o `log.fileSink` é no wasm (texto completo abaixo) | (a) — uma API só, e no wasm o `fileSink` devolve um `Error` nomeado; nada é escrito nem perdido em silêncio. | a coluna wasm da caixa 1 do passo 3 da 106 e a caixa 3 | 140 (uma ligação wasm que guarde um valor); `02/97` passo 15 (`json` no wasm) e o `io/clock` do std no wasm |


### 106-a · O que o `log.fileSink` é no wasm *(proposta)*

**Trava:** `03-bundled-libs/106` passo 3 — a coluna wasm da caixa 1 e a caixa 3 · espera também a 140 e o `02/97` passo 15

**Contexto.** A decisão 349 pede os sinks do `log` — console, arquivo com rotação, níveis por nome — com uma API só em todo target, cada célula `@External` ligada no erlang/beam, commonJS e wasm. O sink de console não precisa de célula (`@print` existe nos quatro); o de arquivo precisa de quatro (`appendLine`, `fileBytes`, `moveFile`, `removeFile`), ligadas no erlang/beam e no node, e nenhuma ligação wasm alcança arquivo (linha **A wasm binding cannot reach the file system** do `language-gaps.md`): o WASI preview 2 tem `wasi:filesystem`, mas o host `browser` da 334 não tem sistema de arquivos, e a 140 liga uma célula nos dois hosts ou em nenhum.

**Hoje** (medido no `56d4bc29`):
```text
error: `fileBytes` has no `#[@External.<Target>(…)]` for the wasm backend
```
toda função que alcança uma das quatro células é recusada no wasm (146); o `log` não compila lá.

- [ ] **(a)** Uma API só, recusa localizada no wasm: as quatro células ganham ligação `fn:`, e o `fileSink` devolve `Error` no wasm, nos dois hosts.
  ```bp
  val sink = try fileSink(LogFile(path: "app.log", maxBytes: 10485760l, maxFiles: 7), Format.Ecs, levels);
  // no wasm → Error("log.fileSink: a wasm program has no file system - use consoleSink")
  ```
- [ ] **(b)** Arquivo de verdade no host `wasi` por um adaptador `wasi:filesystem` (140), o `Error` da (a) só no `browser` — uma célula que se comporta diferente nos dois hosts.
  ```bp
  #[@External.Wasm(wasi: .FileAppend, host: .Wasi)]
  #[@External.Wasm("fn:noFileAppend", host: .Browser)]
  declare fn appendLine(path: string, line: string) -> i32;
  ```
- [ ] **(c)** O sink de arquivo sai do `log` para um pacote próprio (`log-file`), declarado só para erlang, beam e commonJS; o `log` passa a importar em todo target.
  ```bp
  import {logfile.fileSink} from "log-file";   // um build wasm recusa o import, no import
  ```

**Recomendação: (a)** — a API única da 349, com a recusa localizada na única chamada que não pode ser atendida; a (c) recusa mais cedo, mas tira do `log` um sink que a 349 diz que é dele; a (b) só quando a 140 tiver `wasi:filesystem` e houver motivo para dar arquivo a um programa wasm.

---

## Parte 3 — Não trava nada hoje

| Id | Assunto | Recomendação | Trava |
|---|---|---|---|
| `s23-a ★` | Dois nomes de campo da 277 (`fn` é reservada; o objeto do contexto da 354 (4) não tinha nome) | (a) ★ — `HookNode(function: …)` e `HookUse(…, context: ?Declared<unknown>)`, lidos `n.function.name` / `u.context.name`; (b) `n.decl` / `u.target`; (c) `n.of` / `u.object` | nada — (a) está construída |
| `s23-c ★` | O que um `Declared` alcançado guarda no corpo de um decorator | (b) — ler `h.value` num corpo de decorator é recusado (`decl-hooks-value`), como num corpo de template; hoje (a) ★: `h.value == null` é `true` e `h.meta` lista `route.path` (toda entrada, chave `<decorator>.<key>`); (c) (b) e `meta` só do decorator que lê | nada — (a) está construída |
| `s23-d ★` | Um `@Component` chamado por valor-função ou por método | (b) — `HookCall(callee: ?Declared<unknown>, at)`, a chamada entra com `callee: null` (`fn Page(render: fn() -> @Component<Element>) { val r = render(); }` → `calls: [HookCall(callee: null, at: "main:3:13")]`); hoje (a) ★: não entra (`calls: []`); (c) recusada no build (`hooks-dynamic-call`) | nada — (a) está construída |
| `s23-e ★` | Uma função cuja lista um decorator lê é checada antes das saídas dos decorators do módulo existirem | (b) — o decorator que lê `.hooks` roda depois dos corpos (uma análise a mais no `comptime.zig`); hoje (a) ★: `#[graph] fn Page() { return generatedTitle(); }` ao lado de um `#[gen]` que emite `generatedTitle` falha em `unbound variable 'generatedTitle'`; (c) um decorator que lê `.hooks` só pode `setMeta` / `fail` | nada nas células; o `05-jhonstart/26` passo 8 se o `#[page]` emitir o que a página nomeia |
| `s23-f ★` | O `TypeInfo` de um argumento de tipo num `HookUse` | (b) — as anotações de cada campo e os métodos do tipo, como `decl.fields` / `decl.methods`; hoje (a) ★: nome, módulo e campos `Field(name, typeName, annotations: [])`, `methods: []` (`params<main.BlogParams(slug: string, id: i32)>`) | nada para a 293 |
| `ctr-o` | Decisão 146 × confirmação `lem-c` | (a). Mantém o que cada uma já implementa. | a confirmação da `lem-c` — nenhum passo. |
| `17-c` | O que mais pode nomear um var `keyed: true` | (a): `at`, `insert` e o `bump` da 340. Uma grafia por operação de linha. | nada — o que está construído vale até ser ampliado. |
| `ctr-l` | A terceira recusa da 186 × decisão 202 | (a). Sob a 202 nenhuma página se declara pré-renderizada; a recusa é letra morta, e a 202 é a mais restritiva (não há como forçar estágio). | nada nas frentes; só o registro. |
| `ctr-v` | Decisão 189 (org-3) × as frentes da emilia abrindo antes da 118 | (a). Um comentário não muda comportamento; segurar duas frentes da emilia por ele não protege nada. | nada nas frentes; só o registro. |
| `own-a` | Quem é dono dos scripts de teste | (a) — um dono só, a frente que já herdou o passo aberto da 25. | nada |
| `07-b` | "Uma lib, várias cópias divergentes" também justifica pacote? | (a). Pacote bundled novo continua exigindo dois consumidores; a cópia de uma lib só se resolve dentro dela, sem abrir pacote (decisão 67: a regra mais restritiva). |  |
| `07-h` | Bundled, ou um repositório compartilhado à parte? | (a). Fios que dois frameworks precisam concordar byte a byte saem com o compilador que os embute; um membro de repositório já se instala por `subdir` (344). | nada hoje — a trilha |
| `std-e` | Hooks de ciclo de vida de teste | (a). Nada implícito roda em volta de um teste; o que ele precisa está escrito nele. | só a linha "No test lifecycle hooks" do `language-gaps.md`, que fica como está. |
| `07-i (revisão)` | A proibição de nomes repetidos em pacotes bundled continua depois do alias? | (desta revisão): (a). Um pacote novo escolher um nome livre não custa nada, e o alias fica para o caso em que o nome natural é do std (decisão 170). Vale também para o 103: o pacote usa `deriveActionId`, porque o `rakun-app` já … | nada; as frentes |
| `lg2-b` | O que `@Task<T>` significa no BEAM | (1). O tipo promete o valor, nada sobre sobreposição; a única forma concorrente continua sendo a explícita (a leitura restritiva da decisão 120 da 1.0.10). | a linha |
| `lg2-d` | Decorator que lê o corpo | (1). Um decorator lê assinaturas, não corpos; a saga do rakun 83 continua um valor. | a linha; rakun 83. |
| `lg2-h` | Raise e catch por tipo | (1). É a decisão 121 como escrita: o erro é o `E` do `@Result`. | a |
| `lg2-l` | `noreturn` é tipo-fundo? | (1). Um sinal nunca é um valor. | a linha; os sinais do jhonstart (63, |
| `lg2-n` | Thunk convertido em `Node` | (1). As coerções que o compilador conhece continuam três (array, `Element`, `string`). | a linha; jhonstart 30. |
| `lg2-p` | Cancelamento | (1). Em linha com a `lg2-b` (1). | a linha; rakun 02. |
| `lg2-s` | Reflexão do grafo de módulos | (1) — por conta própria: os imports de um módulo são texto que o bundler já lê e recusa alto quando não entende; o argumento antigo ("em linha com a `lg2-k`") caiu com a 216. | a linha; onze 68 (o bundler de cliente). |
| `49-g` | `isString`: do onze, ou do `Json` do std | (b) — o std ganha `Json.isString()` (superfície da 97) ao lado do `isObject`; o onze apaga o seu. Hoje: `if (isString(v) == false) throw …`; com (b): `if (v.isString() == false) throw …`; nunca (c), `v.kindName() != "a string"`. | nada; com (b), uma linha em `config.bp` / `types.bp` depois da 97. |
| `51-a` | Inteiro malformado num sidecar de métricas ou num ângulo de gradiente | (b) — recusar (decisão 67): `parseMetrics` responde `Error("… line 3: \"9x0\" is not an integer")`; `gradientOf` responde `#(-1, "", "")`. Hoje (a): `ascent 9x0` vira `ascent 0`, `9.5deg` vira 0°. | nada hoje; (b) muda o `og_test.bp` (da 51). |
| `lg2-u` | Decorator em posição de expressão | (1). Um decorator anota uma declaração ou uma tag; trabalho numa expressão comum é uma chamada. | a linha (o caso da marcação da frente 48 do emilia já está coberto pela 301). |
| `14s8-a ★` | Como um template lê o valor de build de um buraco (355; caixa 1 do passo 8 da 14) | (c) — `p.hole.value`, o `.value` da 364 em cada buraco, recusado onde o valor não é conhecido no build; até o `01-checker` s24 construí-lo, (a) ★ como construído: `if (p.kind == "Interp" && p.known) built = built + p.value;` (`p.value` é `null` num buraco computado no render); nunca (b) `q.lookup(p.code)`, que não alcança um literal nem um `comptime`. | nada — construído como (a). |
| `14s8-b ★` | Quais buracos são conhecidos no build | (a) ★ — literal de string, número, `true`/`false`, `null`; um `comptime`; um `val` não-`var` do módulo cujo inicializador é conhecido; uma chamada de template já expandida com todo argumento conhecido. `${[a, b]}`, `${Point(x: 1, y: 2)}`, `${tab4.rules}` e um `val` importado ficam no render (o CSS é o mesmo); (b) aceitaria arrays e construtores de argumentos conhecidos; nunca (c), rodar qualquer função no build (364 (3)). | nada — construído como (a). |
| `14s8-c ★` | Um buraco conhecido no build cujo valor estoura no build | (a) ★ — recusado no buraco: `quote "${boom}"` é `this hole is known at build (decision 355) and its value raised there: …`; (b) cairia para o render e o programa estouraria ao rodar. | nada — construído como (a). |
| `14s8-d ★` | Um `comptime` que alcança uma função declarada depois dele com uma chamada de template | (a) ★ — recusado no `comptime`, nomeando a chamada e o remédio (`declare `late` before the `comptime``); (b) o checker inferiria antes o corpo de toda função que o `comptime` alcança. | nada — construído como (a). |
| `116-b ★` | Os papéis são conferidos num projeto sem nenhum `.bpp`? | (a) ★ — com a chave presente, sempre: `{ "bpp": "jhonstart" }` sem `.bpp` e sem `#[bpp.html]` no núcleo é `error: "bpp" names "jhonstart", and no declaration of it carries #[bpp.html]` na chave; (b) só quando o projeto tem um `.bpp` — a chave sozinha compila até o primeiro `Card.bpp` | nada — (a) está construída |
| `116-c ★` | Decorator num `var` de módulo (a 356 fala de `val`) | (a) ★ — recusado na anotação: `#[mark] var count = 1;` é `` `#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on a `var` ``; (b) roda como o de um `val` (`DeclKind.Val`) e o `var` entra no catálogo; (c) roda com `DeclKind.Var` próprio | nada |
| `27-b ★` | As entradas do driver da transição: de onde vem o markup e quem marca `data-jh-pending` | (a) ★ — seis funções no `DomOps` (`markup` → `@Task<@Result<string, string>>`, `replaceSubtree`, `startIslands`, `mountCount`, `scrollTo(depth)`, `markPending(href, on)`), `applyTransition` assíncrono → `@Task<@Result<Navigation, string>>`, profundidade `shared - 1` (os FILHOS do segmento compartilhado mais fundo; `/blog` → `/blog/x` troca 1); (b) as quatro do README, o markup como parâmetro e a marca no runtime (`link_runtime.mjs`) — a caixa do passo 2 só no browser do onze 53; (c) as quatro, `replaceSubtree(depth, href)` e a marca dentro dela | nada — (a) está construída |

### Confirmações ★ das trilhas 00–03

Já implementadas; marque "confirmo" ou a alternativa (a pergunta inteira em `decisions-pending.md` Part 1 § Implementation choices of tracks 00–03).

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `111-b ★` | O carregador de sidecars no beam só é emitido quando o build liga uma função host | (a) Um programa sem `#[@External.Erlang]` / `#[@External.Beam]` não ganha a chamada ao carregador; 13 snapshots mudaram. | (a) ★. O programa que não tem sidecar não paga por um carregador. |
| `113-a ★` | Pedir um target que o `botopink test` não roda falha o `test-libs` | (a) `NOT RUNNABLE`, e o comando sai com erro. É a regra de `fronts.md` § Gate: uma célula que reporta "skipped" é vermelha. | (a) ★. Falhar é mais restritivo do que pular: um par que não rodou nunca conta como aprovado, e é o que o § Gate de `fronts.md` já exige. |
| `113-b ★` | A auditoria de restrições reconhece a recusa pelo texto, porque ela não tem id | (a) Comparar pelo texto. Se o compilador mudar a frase, toda auditoria vira "não estrutural" e o `test-libs` falha — o erro aparece, não passa em silêncio. | (desta revisão): (b), como linha da `01-compiler/07-residuals`; a (a) fica valendo até lá. Um id é um contrato explícito; o texto é um acordo implícito entre dois módulos. |
| `110-b ★` | O histórico de contagens saiu do `tests/language/AGENTS.md` | (a) Apagado. O arquivo diz o estado atual dos quatro targets. | (a) ★. A convenção das specs é estado atual, sem narrativa; o histórico continua no git. |
| `112-a ★` | O que o `format-check` percorre | (a) `TREES` tem `examples` como uma entrada só (pega `examples/hello.bp` e qualquer exemplo novo) e ganhou `modules/manifest/tests`; todo `.bp` rastreado está coberto ou isento por estrutura. | (a) ★. Um exemplo novo já nasce verificado, sem lista para manter (decisão 67). |
| `lem-b` | `inline: true` num método de tipo | (a) Aceita e ignora — compila, o método não é inlinado; as regras do `refuseUnreadInline` continuam valendo. | (b). É a leitura mais restritiva (decisão 67): uma chave que não muda nada é uma promessa falsa para quem lê o código. |
| `01c-a` | O átomo de um módulo comptime | (a) O pacote reservado `bp`, com o caminho do dono — nenhum átomo de usuário colide (o `manifest` recusa um pacote chamado `bp`) e o hash continua endereçando o conteúdo. | (a). Nada de usuário pode encontrá-lo, o arquivo de origem continua nomeado e não há fio novo no compilador. |
| `01c-b` | Folha de seção com o atalho de ponto | (a) Atalho de ponto também para folha de seção, pela regra da posição; sem tipo esperado, recusa nomeando a seção. | (a). Uma regra só para todo ponto inicial, e recusa onde a regra não tem resposta — nada é escolhido por adivinhação. |
| `ck2-a` | `@module()` é recusado até um target o baixar | (a) Recusar no `@` até uma regra dizer o que é o valor de módulo. | (a) agora; (b) se nenhuma frente precisar do valor — um nome declarado sem significado é uma promessa que o compilador não cumpre. |
| `ck2-b` | Um membro de seção pode ter o nome de uma variante de topo do mesmo enum | (a) Legal: o caminho e o tipo da posição separam os dois (`docs.md` § Sections of an enum diz isso). Uma variante declarada duas vezes NO MESMO nível continua recusada. | (a). Nada é ambíguo na linguagem: toda posição que nomeia o membro nomeia o seu nível. |
| `ck2-d` | Label na chamada de um valor-função | (a) Label na chamada de um valor-função é recusado, no argumento rotulado. | (a). É a mais restritiva; (c) faz os nomes, hoje só escritos, contarem na chamada — uma mudança no checker para uma forma que ninguém escreve. |
| `ck2-e` | Um decorator do std é alcançado pelo módulo | (a) Decorator do std só pelo handle do módulo; import folha recusado. | (a) agora. O código que o `mock` gera ainda precisa do handle. (b) é a forma que as decisões 282 e 289 já escrevem para as outras bibliotecas, e precisa que a decisão 112 diga que cobre o texto que um decorator gera. |
| `rc3-b` | `unknown` é a grafia do vocabulário host depois que `any` saiu | (a) `unknown` (`run/host_unknown_parameter`). | (a). A linguagem já tem o tipo que guarda qualquer valor; (c) é o refinamento em que o vocabulário host pode crescer, uma declaração de cada vez. |
| `rc3-c` | Atribuir a um `var` estreitado | (a) Atribuição checada contra o tipo declarado; o nome volta a esse tipo pelo resto do escopo (`reject/narrow_ends_at_assignment`). | (a). É correta sem análise de fluxo; (b) é o refinamento, (c) recusa o percurso de lista que toda biblioteca escreve. |
| `0405-b` | O vazio imprime `null` no commonJS | (a) `__bp_show` imprime `undefined` como `null` — um ramo no impressor. | (a). O impressor é o lugar da grafia, e a mudança é um ramo só. |
| `onze F7` | A regra da divisão inteira | (a) Inteiro / inteiro trunca em direção a zero e é inteiro (o `div` do erlang). | (a). É o que os quatro targets já fazem e o que o host erlang dá de graça; o `docs.md` já escreve a regra, falta só o registro. |
| `01std-a` | Onde uma lib bundled é carregada | (a) CLI e LSP carregam a lib bundled; para o core ela é código comum (como a decisão 115 diz do `routing`). | (a). O contrato observável vale igual, com menos código mexido. |
| `01std-c` | O padrão vazio do `routing.pattern` | (a) O padrão vazio da lib casa só com `/`; o rakun-web mantém "matcher vazio roda em todo lugar" (`matcherAdmits`). | (a). A regra de um consumidor fica no consumidor. |
| `01std-e` | `actions.readEnvelope` recusa um envelope incoerente | (a) Recusar o envelope incoerente (decisão 67). | (a). É a mais restritiva: o que o escritor não produz, o leitor não aceita. |
| `std-a` | `querystring` recusa por `Error`, nos dois sentidos | (a) Como está: recusa nos dois sentidos, dois leitores. | (a) — a leitura restritiva (decisão 67): o que não pode ser lido não é lido, e o que o próprio leitor recusaria não é escrito. A `03r-e` cai junto (ver `ctr-p`). |
| `std-b` | `fs.exists` segue link simbólico | (a) Segue o link (`stat`). | (a). A pergunta de quem chama antes de ler é se a leitura vai achar alguma coisa. |
| `95-a` | Os cortes de realocação `jhonstart-link` e `rakun-app` | (a) Realocar já, como movimento sem comportamento. | (a). Senão as frentes donas fariam o movimento no meio de uma mudança de comportamento, que é o diff mais difícil de revisar. |
| `95-b` | `targets` do `rakun-app`: herdar do workspace ou declarar | (b) Declarar `targets` no próprio membro, como todo outro membro — uma cópia que precisa ser editada quando o workspace mudar. | (b). É o que o código faz, igual nos 36 manifests, e cada um diz por si onde roda (decisão 153). |
| `95-c` | `erika-test` existe | (a) Criar o membro agora, com um teste. | (a). Cumpre a regra do packaging sem custo. |
| `106-b ★` | O `consoleSink` do `log` escreve na saída padrão | (a) Uma linha por registro na saída padrão, por `@print`, em todo target — não o `console.error` / `console.warn` do node nem o `logger` do OTP; o `defaultSink` continua no logger do host. | (a) ★. É o único fluxo que um programa wasm também escreve: um comportamento só. |
| `106-c ★` | A rotação do `fileSink` | (a) A do `logger_std_h` do OTP, escrita uma vez em botopink: depois de uma escrita que deixa o arquivo com `maxBytes` ou mais, ele vira `<path>.0`, cada arquivo sobe um, o `<path>.<maxFiles - 1>` é apagado; `maxFiles` 0 apaga o arquivo; uma chamada de host que falha levanta erro; o teto total do rakun continua do rakun. | (a) ★. A mesma rotação em todo target, e um log que para de escrever em silêncio é um log perdido. |
| `106-d ★` | Níveis por nome | (a) `Threshold { From(level), Off }`, `Levels(root, names)`, vence o prefixo pontuado mais longo; nome vazio, segmento vazio e nome repetido são recusados (`Error` ao construir um sink, pânico ao resolver); grupos e overrides em tempo de execução são do framework, que reconstrói o `Levels` e instala o sink de novo. | (a) ★. Nada é resolvido adivinhando qual entrada vale. |
| `106-e ★` | O `captureRuntimeReports()` observa, nunca trata | (a) BEAM: um filtro primário do `logger` no domínio `otp`, que passa o evento adiante intacto (o handler do OTP continua imprimindo); node: `uncaughtExceptionMonitor` (o node continua saindo; o `unhandledRejection` chega como origem no modo padrão); registros do logger `runtime` com `report.kind`; wasm: ligação que não faz nada. | (a) ★. Capturar não muda o que o runtime faz com a falha. |

### Confirmações ★ — bugs-sweep

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `bs-a` | Função associada de um tipo chamada com menos argumentos | (a) Preenche pelos defaults declarados e reordena por rótulo, como a função de um módulo do std: com `fn of(x: string, y: string = "d")`, `Bag.of("p")` é `Bag.of("p", "d")`; qualquer outra contagem é o erro de aridade. (b) Recusar a chamada curta: `'of' expects 2 argument(s), got 1`. | (a). É a regra que toda outra chamada já segue; antes, toda contagem diferente da exata caía num caminho que não checava nem preenchia nada. |
| `bs-b` | Tipo sem sinal recebe literal negado | (a) Recusa no literal: `val x: u32 = -1;` → ``the literal `-1` does not fit `u32` (at least 0)``. (b) Aceitar e deixar a checagem de execução da 264 abortar na negação. (`-0` passa nos dois.) | (a) — a mais restritiva: o tipo não tem esse valor, e o checker diz isso onde ele está escrito. |
| `bs-c` | `erl` interrompido sai com status 0 | (a) A saída com o banner do break handler (`BREAK: (a)bort …`) marca a execução como interrompida: nunca vai para o cache. (b) Rodar `erl +Bi` (ignora SIGINT): a execução termina e é genuína, mas um programa travado sobrevive ao Ctrl-C até o timeout de 2 minutos. | (a). É o único lugar em que o harness lê a saída, e só para não guardar. |
| `bs-d` | Raízes de biblioteca do `check-docs.sh` | (a) `--lib-root <dir>` substitui as raízes padrão; o teste do harness passa a sua; o gate mantém o padrão, que faz hash de todo pacote irmão — o `vscode-extension` tem `botopink.json`, então um link simbólico no `node_modules` dele deixa toda checagem dos docs `never stored` no checkout meta (custo, nunca veredito). (b) As raízes padrão só aceitam pacote com `src`. (c) O hash da árvore pula `node_modules`. | (a) agora; (b) se o custo no gate importar — o manifesto do vscode-extension não é de biblioteca. |

### Confirmações ★ — libs-external-methods

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `lem-a` | Um método host é um método de verdade | (a) Um lowering só: método real cujo corpo é a binding, nunca colado no site da chamada (custa um quadro de pilha a mais por chamada). | (a). Um caminho só; (b) é uma otimização com um segundo caminho para manter em quatro backends. |
| `lem-c` | Método sem binding é recusado onde é CHAMADO | (a) Recusa na chamada; o tipo compila para qualquer backend. | (a) — e registrar que a decisão 146 vale para função COM corpo, livre ou método, que alcança uma dessas (ver `ctr-o`). A assimetria do wasm se resolve no dia em que o wasm tiver host. |
| `lem-d` | Os nomes depois do colapso | (a) Um nome por operação em todo tipo: `Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`. | (a). O prefixo repetia o que o receptor já diz. |
| `lem-e` | O que ficou função livre mesmo recebendo um tipo | (a) Auxiliares privados ficam livres. | (a). Privado continua privado. |
| `lem-f` | O commonJS adota um registro construído pelo host | (a) O commonJS adota a resposta na classe (`run/external_method_on_host_record`). | (a). Cumpre o que o `docs.md` prometia sem amarrar o template ao nome de uma classe gerada. |

### Confirmações ★ — rakun

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `03r-a ★` | Todo manifest do rakun é `["erlang"]` | (a) manter — um só runtime (BEAM); os exemplos rodam pelos sidecars que o build copia | (a). O compilador já entrega o que faltava, e (b)/(c) devolvem o runtime node que a 113 retirou. |
| `03r-c ★` | Os leitores de config ficam em botopink | (a) manter — sem sidecar; a caixa da frente 05 é emendada | (a). Menos código host, o mesmo comportamento nos dois lados do std. |
| `03r-e ★` | Componente de cookie/query nunca decodifica para caractere de controle | (a) manter — sem caractere de controle saindo de cookie ou query | (a) até o rakun passar a ler pela `querystring` e pelo `http` — aí ela cai, e a recusa da `querystring` (std-a) assume o papel (ver `ctr-p`). |
| `03r-f ★` | Chave de cache por `hash.strongCacheKey` | (a) manter — chaves que não colidem | (a). Um cache que colide através da fronteira de usuário serve a página de um usuário para outro. |
| `03r-g ★` | Leitura de escopo privado sem sessão | (a) manter — roda o loader e não guarda nada | (a). Não cria estado nem quebra a página; só perde o cache onde não há dono. |
| `03r-h ★` | A chave do gêmeo e o `#[cacheEvict(name, false)]` | (a) manter — `rename(7)` remove `["productJson", 7]` e `["productHtml", 7]`, e só essas | (a). Cada leitor tem a sua linha, e o evict acerta todas as de um argumento. |
| `03r-i ★` | O provider Redis do cache | (a) manter — wire do rakun-session; sem janela stale; Redis fora do ar = sem cache | (a). Um wire RESP só, e nada de estado stale inventado por cima do Redis. |
| `03r-j ★` | Fora de request; e `none` vence o tipo por cache | (a) manter — revalidar é legal fora de request, `updateTag` não; `none` é chave geral | (a). `updateTag` (ler a própria escrita) não tem sentido sem request, e a chave geral não pode ser derrubada por uma linha de config (decisão 67). |
| `03r-k ★` | Todo braço de messaging roda no broker em processo | (a) manter — broker em processo explícito; endereço real sem `memory` recusa o boot | (a). (b) engana em produção; (c) é trabalho de várias frentes. As células de integração esperam (c) ou o fim da lacuna de sidecars. |
| `03r-l ★` | O container tem o nome do destino; Redis é ack-mode none | (a) manter — sem argumento extra; Redis sem config de ack | (a). Nada a escrever a mais, e o Redis sobe com o único modo que ele aceita. |
| `03r-m ★` | Dentro de uma server action, revalidar expira na hora | (a) manter — dentro da action expira; fora, stale-then-fresh | (a). É a regra do Next, num lugar só (o rakun-cache). |
| `03r-n ★` | Argumento de JSON-RPC é uma lista de campos form-encoded | (a) manter — mesmos nomes de campo do formulário | (a). É a única que dá exatamente o estado do POST de formulário. |
| `03r-p ★` | O slot é do layout mais próximo acima; só um slot conflita consigo mesmo | (a) manter — dono = o `L` mais próximo no/acima do caminho mais curto do slot | (a). (b) mexe no contrato que a frente 22 possui; (c) proíbe o recurso. |
| `03r-r ★` | Starters nomeiam os irmãos com `workspace: true` | (a) manter — starters são membros do workspace e testados pelo `test-libs` | (a). |
| `03r-s ★` | OTLP é enviado como HTTP/JSON | (a) manter — HTTP/JSON, sem encoder novo | (a). (b) entra ao lado do JSON se algum coletor só aceitar protobuf. |
| `03r-t ★` | As chaves da frente 76 ficam sob `rakun.management.*` | (a) manter — um prefixo só para todo o actuator, como o upstream | (a). |
| `03r-u ★` | O grupo liveness só aceita indicadores locais | (a) manter — lista fechada | (a). |
| `03r-v ★` | O operador do builder tipado é um enum | (a) manter — operador desconhecido é variante desconhecida, erro de compilação | (a). É a única que cumpre o "erro de compilação" que a frente pede. (A coluna como `Type.Field<City>` — decisão 308 — é outra pergunta; o argumento hoje é a string da coluna SQL.) |
| `03r-w ★` | OAuth2: endpoints são campos do provider; client credentials é uma função | (a) manter — campos no provider; `withClientToken(id, call)` busca o token, chama, e no 401 descarta o token e tenta mais uma vez | (a). (b) exige um gancho de interceptor que o rakun-client não tem. |
| `03r-x ★` | O relay reivindica por UPDATE condicional | (a) manter — o estado durável é o que a recuperação lê | (a). (b) é otimização para o braço Postgres; recuperar depende do estado gravado, não do processo. |

### Confirmações ★ — jhonstart

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `26-a (jhonstart) ★` | Toda célula do roteador tem os dois targets | (a) manter — célula nos dois targets, um teste para as duas linhas | (a). |
| `30-b ★` | `RenderPlugin` é um registro de funções | (a) manter — registro de funções; a lista de plugins tipa hoje | (a). Os quatro momentos e a ordem são os do README; só muda onde `chunk` roda. |
| `30-c ★` | `compose` recebe a página como thunk | (a) manter — dois módulos (`render.bp`, `streaming.bp`); página como thunk | (a). |
| `30-d ★` | `Suspense` registra a fronteira no render | (a) manter — a página só devolve a árvore | (a). |
| `30-e ★` | O registro de segmento se chama `UiSegment` | (a) manter — `UiSegment` | (a). |
| `30-f ★` | `app(…, lang:)` | (a) manter — uma língua por app, `"en"` por padrão | (a) agora; `PageInput.lang` por request é aditivo quando o `i18n` (105) entrar. |
| `30-g ★` | A metade de browser é afirmada num membro só-commonJS | (a) manter — as três caixas afirmadas hoje sobre o markup que o render produz | (a). O onze 53 ainda prova as mesmas caixas num browser. |
| `31-a ★` | `notFound()` / `redirect(url)` levantam | (a) manter — a mesma instrução serve em página, layout, template e thunk | (a) até a nat-d6 e a lg2-l serem respondidas; se a nat-d6 for (a), este item vira (c). |

### Confirmações ★ — emilia

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `05emilia-a ★` | O leitor de filtro é uma cadeia inline | (a) manter — `blur-sm brightness-50` compõem na mesma classe, como o upstream | (a). |
| `05emilia-b ★` | A seção de backdrop é `BackdropFilter` | (a) manter — nenhuma frente pronta muda | (a). |
| `05emilia-c ★` | `drop-shadow-none` segue o upstream | (a) manter — CSS válido, igual ao upstream | (a). |
| `05emilia-d ★` | A rigidez do snap é um fallback, não uma entrada do tema | (a) manter — fallback inline | (a). |
| `05emilia-f ★` | As entradas `--inset-shadow-*` não levam o `inset` | (a) manter — o utilitário escreve o `inset`; a entrada do tema não | (a). Não mexe numa frente já entregue. |
| `05emilia-g ★` | `space-*` / `divide-*` como o upstream | (a) manter — `Space.XReverse` passa a ter efeito | (a). |
| `05emilia-i ★` | As variáveis `--tw-*` de transform são blocos `@property` | (a) manter — saída do upstream, sem tipo de saída novo | (a). `scale-*` já segue a mesma forma (`--tw-scale-*` com `@property`, `emilia.bp:13900-13969,14204`). |
| `05emilia-j ★` | Modificador de lista de seletores | (a) manter — a regra de um `&` da frente 56 fica intacta | (a). |
| `05emilia-k ★` | O meio passo negativo | (a) manter — sinal no nome | (a). |

### Confirmações ★ — onze

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `49-a ★` | As suítes do core renderizam pelo `describe*` do próprio core | (a) manter — uma renderização só; o core testa só com std | (a). |
| `49-c ★` | `onze.json` recusa chave desconhecida | (a) manter — erro nomeando a chave | (a) (decisão 67: um `"prot"` errado não pode deixar a porta 3000 em silêncio). |
| `50-a ★ (emendada)` | `onze build` gera um main de servidor; `onze start` o roda | (a) manter — até o `bin/onze` da frente 71 existir; aí o `start` chama esse script | (a) até o `bin/onze` da frente 71 existir; aí o `start` chama esse script, e o comando de hoje é o que o script roda. |
| `53-a ★` | Os fontes do blog ficam sob `src/` | (a) manter — o exemplo cobre o layout `src/`; o roteiro de aceitação lê `src/<caminho>` | (a). Os dois layouts compilam. |
| `68-a ★` | Um campo do manifest escapa quatro caracteres | (a) manter — legível; só `%`, `\|`, LF e CR viram `%25`, `%7C`, `%0A`, `%0D` | (a). |
| `68-d ★` | O styleMap é avaliado por uma sonda compilada nos dois pacotes | (a) manter — a classe é a da própria função do emilia, nos dois compiladores | (a) até o passo 1 da frente 34 e o passo 4 da 119 aterrissarem; aí a sonda sai. |
| `69-a ★` | `onze-assets` mantém o seu `AssetRoot` | (a) manter — o build continua em node | (a). |
