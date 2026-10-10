# Decisões pendentes — 1.0.12-beta

**Em aberto: 67 perguntas, 6 contradições e 98 escolhas ★ para confirmar.** O que já foi respondido está em `decisions-taken.md` (próximo número livre: **432**). O texto completo de cada pergunta, em inglês, está em `decisions-pending.md` (a fonte) e no `README.md` da trilha que a levantou.

- **Parte 1** — o que trava agora: toda pergunta aberta que trava um passo cujos outros pré-requisitos já estão cumpridos (`status.md` e o "Depends on" do README da frente) — respondida, o passo pode abrir hoje. As perguntas inteiras, no molde **Trava** → **Contexto** → **Hoje** → opções com exemplo → **Recomendação** → **Bloqueia**.
- **Parte 2** — trava, mas o passo ainda espera outra frente: uma linha por pergunta, com o que mais o passo espera.
- **Parte 3** — não trava nada hoje: uma linha por pergunta; no fim, as confirmações ★ que nenhum passo espera.

★ = já implementada: confirmar não muda nada; a alternativa vira trabalho da frente dona. ⏳ = há thread esperando. A recomendação é sempre a leitura mais restritiva, sem configuração que a contorne (decisão 67). Perguntas de método de biblioteca (nome, ordem, assinatura) eu decido pelos seus princípios: ficam marcadas † em `decisions-taken.md`, para você reverter.

---

## Parte 1 — O que trava agora (responder primeiro)

Ordem: quantos passos e frentes a resposta libera, depois o caminho crítico de `fronts.md` § Execution order (102 s3 / 103 s2 → 128 → rakun 04 → 22 → 49 → 53; 118 → 26 → 67 → 127; 118 → 119 → 120 → 126 → 127 → 124). Nenhuma pergunta aberta trava a `00-gate/114`.

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

---

### 396-a · Como uma página renderiza um nó do Markdown com um componente seu (142 passo 3)

**Trava:** a segunda caixa do `03-bundled-libs/142` passo 3 (só o gancho; o mapeamento padrão está construído)

**Contexto.** O passo 3 levou o leitor de Markdown do `onze-content` para a biblioteca `markdown`, que responde uma árvore própria (`MdDoc`, `MdNode`: `Heading`, `Paragraph`, `CodeBlock`, `Link`, `Image`, …). O `onze-content` mapeia a árvore para `Element` (`element.toElement(doc)`). A 396 (3) diz que uma página pode renderizar um nó com um componente seu, mas não fixa a forma.

- [ ] **(a)** Uma função só, `null` mantém o elemento padrão:
  ```bp
  val page = toElementWith(doc, { node, kids -> case node { Heading(depth, id, _) -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo>, _ -> null } });
  ```
- [ ] **(b)** Um record com uma função opcional por tipo de nó:
  ```bp
  val page = toElementWith(doc, Components(heading: { depth, id, kids -> <MeuTitulo nivel={depth} id={id}>{kids}</MeuTitulo> }));
  ```
- [ ] **(c)** Nenhum gancho: a página percorre o `MdDoc` (que é público) e chama `toElement` nos nós que não renderiza.

**Recomendação: (a)** — uma leitura só, sem um campo por tipo de nó para manter em dia com a árvore; a (c) não pede código e já funciona hoje.

---

### 140-d · A grafia de um adaptador de task: `wasi: .Delay` da 393 contra a string única da 238

**Trava:** nada — a 140 passo 4 entrou com a (a) · o `02/97` passo 17 escreve os bindings da std na grafia escolhida

**Contexto.** A 393 escreve `#[@External.Wasm(wasi: .Delay)]`, mas o vocabulário fechado da 238 (e todo
binding da std hoje) é uma string só, e o `builtins.d.bp` declara `Wasm(template: string)`. A thread
seguiu a 238: os adaptadores novos estão na lista única do `host_binding.zig`, conferidos pela forma na
anotação (`run/external_wasm_task_adapter_shape`).

**Hoje:**
```bp
#[@External.Wasm("wasi:delay")]
declare fn delay<T>(millis: i32, value: T) -> @Task<T>;
```

- [ ] **(a) ★ como está** — a string da 238, nomes em snake_case da lista (`wasi:delay`, `wasi:race`, `wasi:race_of`, `wasi:spawn_all`).
  ```bp
  #[@External.Wasm("wasi:race_of")]
  declare fn raceOf<T>(tasks: Array<fn() -> @Task<T>>) -> @Task<T>;
  ```
- [ ] **(b)** A grafia da 393: argumento rotulado com enum, ao lado das formas em string — duas grafias para o mesmo binding.
  ```bp
  #[@External.Wasm(wasi: .Delay)]
  declare fn delay<T>(millis: i32, value: T) -> @Task<T>;
  ```

**Recomendação: (a)** — uma grafia só; o exemplo da 393 se lê `"wasi:delay"`. **Bloqueia:** nada.

### 140-e · Um `await` de task dentro de um corpo `@Component` no wasm (392 (2) contra 375 (3))

**Trava:** a caixa 1 da 140 passo 4 para corpos `@Component` · nada mais

**Contexto.** A 392 (2) diz que uma função que a 375 marca assíncrona vira máquina de estados no wasm. A
thread fez isso para `-> @Task`, método que responde `@Task` e `async { }`; o corpo `@Component` ficou
ansioso, porque um valor componente tem uma representação só para todo chamador: a 375 (3) mantém `await`
legal num componente síncrono, e um componente chamado por valor de função (`slot.view(c)`) é aguardado
sem o chamador saber qual é — no wasm o endereço de uma task e um `Element` são a mesma palavra `i32`.

**Hoje:**
```bp
fn page(n: i32) -> @Component<i32> {
    val v = await answer(n);   // answer -> @Task<i32>: roda as tasks prontas até ela assentar
    return v;                  // uma task esperando o host aqui: trap nos dois hosts
}
```

- [ ] **(a)** Todo `@Component` no wasm vira máquina de estados que responde uma task; um síncrono assenta ao ser criado.
  ```bp
  val page = await Page(slot);   // sempre lê uma task — como o commonJS fazia antes da 375
  ```
- [ ] **(b)** Só os que a 375 marca; uma chamada por valor de função é assíncrona (a resposta conservadora), então um componente síncrono passado como valor é embrulhado numa task já assentada.
  ```bp
  val wrapped = await view(Title());   // view: valor de função — sempre uma task
  ```
- [ ] **(c)** Como está: componentes ansiosos; `await` de task presa no host dentro deles dá trap.
  ```bp
  fn Widget() -> @Component<i32> { return await delay(5, 1); }   // trap nos dois hosts
  ```

**Recomendação: (a)** — uma representação de `@Component<R>` no wasm, sem trap; a marca da 375 fica
otimização do commonJS. Não implementada (muda a descida de toda célula de componente no wasm; thread
seguinte). **Bloqueia:** só a caixa 1 da 140 passo 4 para componentes.

### 140-f · Uma chamada antes de um `await` no mesmo statement, no wasm (392 (2))

**Trava:** nada — a 140 passo 4 entrou com a (a)

**Contexto.** A máquina de estados retoma um `await` entrando de novo no seu statement: o que passou
(condições, sujeito de `case`, início de laço) é lido do frame e os statements anteriores são pulados, mas
um operando avaliado antes do `await` no próprio statement roda outra vez. Uma chamada ali rodaria duas
vezes — a thread recusa no `await`.

**Hoje:**
```bp
@print(pair(label("x"), await answer(21)));
// wasm: error: the wasm backend resumes an `await` by entering its statement again, and a call
//       evaluated before it in that statement would run twice … --> src/main.bp:21:29
```

- [ ] **(a) ★ como está** — recusado onde está escrito; ligando a chamada a um `val` antes, roda em todo target.
  ```bp
  val l = label("x");
  @print(pair(l, await answer(21)));
  ```
- [ ] **(b)** O backend guarda cada operando avaliado antes de um `await` num local do frame (forma A-normal), e o statement roda como escrito.
  ```bp
  @print(pair(label("x"), await answer(21)));   // wasm: label("x") guardado, depois o await
  ```

**Recomendação: (a) agora** — nunca uma chamada rodando duas vezes, recusa localizada; a (b) quando um
programa precisar. **Bloqueia:** nada.

---

---

---

---

---

---

---

## Parte 3 — Não trava nada hoje

| Id | Assunto | Recomendação | Trava |
|---|---|---|---|
| `s23-j ★` | O que a marca da 375 conta como "não dá para seguir", e um host `@Component` | (a) construída: chamada por valor-função ou método conta só quando o tipo resolve para `@Component<R>` (ou fica aberto); `use`/chamada de host `@Component` conta como host `@Task` (`Component` estende `Task`); `await` dentro de lambda do corpo conta; (b) toda chamada por valor ou método marca assíncrono (`xs.length()` incluso); (c) host `@Component` é síncrono | nada — (a) está construída |
| `04s12-a ★` | Método, lambda e `default fn` `@Component` não têm nó (375 (2), 04-js passo 12) | (b) — o checker marca todo corpo `@Component` pela regra da 375 e o commonJS emite cada um pela marca; hoje (a) ★: continuam `async` e a chamada mantém o `await`; (c) (b) e o nó do método entra no `decl.hooks` | a caixa 1 do 04-js passo 12 (método, lambda, `default fn`) |
| `s23-a ★` | Dois nomes de campo da 277 (`fn` é reservada; o objeto do contexto da 354 (4) não tinha nome) | (a) ★ — `HookNode(function: …)` e `HookUse(…, context: ?Declared<unknown>)`, lidos `n.function.name` / `u.context.name`; (b) `n.decl` / `u.target`; (c) `n.of` / `u.object` | nada — (a) está construída |
| `s23-c ★` | O que um `Declared` alcançado guarda no corpo de um decorator | (b) — ler `h.value` num corpo de decorator é recusado (`decl-hooks-value`), como num corpo de template; hoje (a) ★: `h.value == null` é `true` e `h.meta` lista `route.path` (toda entrada, chave `<decorator>.<key>`); (c) (b) e `meta` só do decorator que lê | nada — (a) está construída |
| `s23-f ★` | O `TypeInfo` de um argumento de tipo num `HookUse` | (b) — as anotações de cada campo e os métodos do tipo, como `decl.fields` / `decl.methods`; hoje (a) ★: nome, módulo e campos `Field(name, typeName, annotations: [])`, `methods: []` (`params<main.BlogParams(slug: string, id: i32)>`) | nada para a 293 |
| `ctr-o` | Decisão 146 × confirmação `lem-c` | (a). Mantém o que cada uma já implementa. | a confirmação da `lem-c` — nenhum passo. |
| `17-c` | O que mais pode nomear um var `keyed: true` | (a): `at`, `insert` e o `bump` da 340. Uma grafia por operação de linha. | nada — o que está construído vale até ser ampliado. |
| `ctr-l` | A terceira recusa da 186 × decisão 202 | (a). Sob a 202 nenhuma página se declara pré-renderizada; a recusa é letra morta, e a 202 é a mais restritiva (não há como forçar estágio). | nada nas frentes; só o registro. |
| `ctr-v` | Decisão 189 (org-3) × as frentes da emilia abrindo antes da 118 | (a). Um comentário não muda comportamento; segurar duas frentes da emilia por ele não protege nada. | nada nas frentes; só o registro. |
| `141-a` | Como uma decisão que aposenta uma grafia impede as specs de ficarem para trás | (a) — o commit que escreve a decisão reescreve as linhas das specs vigentes que ainda usam a forma antiga e acrescenta a linha dela no `inventory.md` da 141; (b) um check 6 no CI com lista de grafias e arquivos permitidos; (c) nada, a varredura da 141 roda de novo em cada fechamento. Exemplo, a 379 aposentando `Context<T>()`: em (a) o mesmo commit troca `pub val StyledContext = Context<StyledSheet>();` no README da 119 por `comptime createContext(StyledSheet.missing())`; em (b) o check 6 fica vermelho nessa linha até alguém reescrevê-la; em (c) a linha fica com a forma antiga até o fechamento | o passo 6 da 141 |
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
| `cep-a` | Caminho de seção numa função declarada depois do `comptime` | (a) O `comptime` é recusado nomeando o caminho, o `linha:coluna` e a função — `comptime label(later())` com `fn later() -> Tok { return .Pad.All.8; }` abaixo dá "declare `later` before the `comptime` in this module" —, como o passo 8 da 14 recusa uma chamada de template ali. (b) inferiria a função antes do `comptime`, de dentro do corpo que está sendo inferido. | (a). Recusa com o remédio escrito, e a mesma regra do template. |
| `cep-b` | Função local de um decorator que escreve um caminho de seção | (a) Inferida antes do decorator rodar, uma vez, como a 371 faz com quem escreve `same`, e levada já reescrita (`fn fallback() -> Tok { return .Pad.All.8; }` alcançada por `#[mark(…)]`). (b) recusaria o decorator na anotação, nomeando o caminho. | (a). Em (b) o único remédio seria mudar a função de módulo. |
| `cep-c` | O teste de registro no runtime comptime | (a) Um registro é o mapa sem tag do módulo comptime: `v is Rule` testa as chaves declaradas (`is_map(V) andalso is_map_key(selector, V) …`), e um registro de outro tipo com as mesmas chaves responde `true`. (b) Levar o tipo no mapa (`#{'__bp_type' => 'Rule', …}`) — muda todo termo que os avaliadores leem e respondem. (c) Recusar o `is` / o braço de registro no runtime comptime quando dois registros levados têm as mesmas chaves. | (c), a mais restritiva; (a) implementada, nenhuma célula tem dois registros assim. |
| `388-b ★` | O que `c.run(scope)` devolve, e o `RenderScope` opaco | (a) `c.run(scope)` devolve `@Task<Rendered<R>>` para todo componente (a marca da 375 não está no tipo), declarado no `Component<R>` do `builtins.d.bp`; o `context` da std declara `Rendered<R>(value: R, scope: RenderScope)` e `RenderScope(frames: unknown)`, cuja construção fora da std é recusada (`render-scope-construction`), já que a linguagem não tem construtor privado. | (a) ★. É a grafia que a 388 (2) deixa para a frente, e um escopo feito à mão é recusado no build. |
| `388-c ★` | `await c` fora de todo corpo | (a) O "fora de todo corpo um valor roda com `c.run(RenderScope.root())`" da 388 (4) lido como o que `await c` significa ali: num `main`, num teste, numa função comum, o `await` roda o componente com `RenderScope.root()`. (b) Recusaria o `await`, pedindo `c.run(RenderScope.root())` — todo teste e todo `main` que aguarda um componente seria reescrito. | (a) ★. É o texto da 388 (4), e a raiz é o único escopo que existe fora de uma renderização. |
| `388-d ★` | O wasm recusa a baixa do escopo | (a) O wasm recusa o módulo que a baixa alcançou, no primeiro componente (`the wasm backend does not lower a component yet`), até a baixa da 05: toda célula de componente ganhou `.wasm.expect` (32 células; as `run/decl_hooks_*`, que rodavam no wasm com o mapa da 354, entre elas). | (a) ★. Recusar no build, localizado, em vez de rodar com outra semântica; a baixa é da `05-wasm`. |
| `388-e ★` | Um `try` solto no corpo de um componente | (a) O corpo que guarda um `try` solto roda o que vem depois do último `use provide` numa closure interna, cuja resposta (o valor, ou o erro que o `try` devolve antes) é o resultado; os demais corpos respondem `rendered(v, kids)` em cada `return`. | (a) ★. O `try` continua com o significado que os backends já dão, e nada antes do último provide pode sair cedo (357). |
| `389-a ★` | O que o código genérico responde | (a) Uma função declarada cujo retorno não é `@Component`, mas que devolve um pelos argumentos de tipo (`first<T>(cards)`), é o "o que o código genérico responde" da 389: uma aresta com `callee: null`, o nó assíncrono, sem marca de síncrono na chamada. | (a) ★. O lado seguro que a 389 pede, sem seguir o tipo de quem chama. |
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
| `04-a ★` | A época por tag do núcleo (185): vida, tipo e tag vazia | (a) manter — a época só cresce (`rkResetContext` não a zera), é `i64`, e `rkBumpTag("")` / `rkTagEpoch("")` recusam (`rakun: a tag is a non-empty string (rkBumpTag)`). (b) `rkResetContext` zera: `rkBumpTag("t")` volta a dar `1` e uma resposta guardada na época 1 antes do reset é servida velha. (c) a vida da (a), `i32` como os outros contadores, e `""` uma tag comum (`rkBumpTag("") == 1`) | (a). Um contador de versão nunca volta, então nenhuma época guardada casa com um estado posterior; `i64` não tem borda alcançável; tag vazia é bug de quem chama, recusada (decisão 67). |

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
