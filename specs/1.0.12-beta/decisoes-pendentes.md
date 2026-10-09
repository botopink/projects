# Decisões pendentes — 1.0.12-beta

**Em aberto: 56 perguntas, 8 contradições e 88 escolhas ★ para confirmar.** O que já foi respondido está em `decisions-taken.md` (próximo número livre: **337**). O texto completo de cada pergunta, em inglês, está em `decisions-pending.md` (a fonte) e no `README.md` da trilha que a levantou.

- **Parte 1** — o que trava `00-gate`, `01-compiler`, `02-std-and-packaging` e `03-bundled-libs`: as perguntas inteiras, no molde **Trava** → **Contexto** → **Hoje** → opções com exemplo → **Recomendação** → **Bloqueia**; no fim, as confirmações ★ dessas trilhas.
- **Parte 2** — o resto (trilhas 04–09 e 20), uma linha por pergunta: o detalhe vem quando você pedir.
- **Parte 3** — as confirmações ★ das trilhas 04–09, uma linha cada.

★ = já implementada: confirmar não muda nada; a alternativa vira trabalho da frente dona. ⏳ = há thread esperando. A recomendação é sempre a leitura mais restritiva, sem configuração que a contorne (decisão 67). Perguntas de método de biblioteca (nome, ordem, assinatura) eu decido pelos seus princípios: ficam marcadas † em `decisions-taken.md`, para você reverter.

---

## Parte 1 — O que trava 00-gate, 01-compiler, 02-std e 03-bundled-libs

### O que trava agora (responder primeiro)

O que o mantenedor pediu para responder primeiro e ainda está aberto; ao responder, a thread do passo pode abrir.

### 138-a · O import abreviado alcança os módulos de uma dependência? *(proposta)* ⏳

**Trava:** `03-bundled-libs/138` (o patch do botopink-lang e a célula `modules/shorthand_import_beside_bundled_package`) · ⏳ pronto para integrar ao responder

**Contexto.** A regra da 170, no compilador (`comptime.zig` `outsideShorthandReach`), deixa o import
abreviado (`import {x};`, sem `from`) fora só dos módulos de um pacote **embutido**. Depois da 326 a
std é o único pacote embutido, e os módulos dela já são alcançados de qualquer jeito (com outra
recusa), então essa exclusão não cobre mais nada. A célula
`modules/shorthand_import_beside_bundled_package`, reescrita para declarar um `routing` de fixture por
`path`, passa a responder `ambiguous-import-use` nos quatro targets. Com o `routing` embutido ela
imprimia `own` / `2`.

**Hoje** (`src/config.bp` declara `pub fn splitPath(p: string) -> string[] { return ["own", p]; }`):
```bp
pub mod config;
import {splitPath};
import {splitPath as routeSplit} from "routing";
// error: ambiguous-import-use: `splitPath` is imported from two declarations —
// declared `pub` by `config` and by `routing/match` — and this use does not say which
```

- [ ] **(a)** O abreviado resolve só entre os módulos do próprio pacote — nunca os de uma
  dependência, nunca os da std: o programa imprime `own` e `2`, como enquanto o `routing` era embutido
  (326: "os nomes, exports e fontes de import não mudam"); a exclusão passa a valer para "um módulo de
  outro pacote do build", e não mais "um pacote embutido".
- [ ] **(b)** O abreviado alcança todo módulo carregado, do pacote ou não: `import {splitPath};` é
  `ambiguous-import-use`, e o programa escreve `import {config.splitPath};` (170: "um nome nu que
  alcança duas declarações é recusado"); a célula vira uma recusa e o `outsideShorthandReach` é apagado.
  ```bp
  import {config.splitPath};   // a única forma aceita
  ```

**Recomendação: (b)** — a mais restritiva (decisão 67: recusar > aceitar), sem código guardado para um
tipo de pacote que não existe mais; quem cair no caso escreve o caminho do módulo uma vez.
**Bloqueia:** a célula acima (vermelha até a resposta) e, com ela, o patch do botopink-lang da 138; em
(b), também qualquer membro consumidor cujo abreviado alcançasse um nome de pacote movido (nenhum medido
no `zig build test-libs`).

### O resto, por trilha

### Trilha `00-gate`

Nenhuma pergunta aberta trava a `00-gate/114`: os passos 3, 5, 6, 7 e 8 não esperam decisão
(`status.md` L1). As escolhas ★ das frentes do gate da 1.0.11 (`110-b`, `111-b`, `112-a`, `113-a`,
`113-b`) não travam nada e estão na tabela de confirmações no fim desta parte; a `own-a` (dono dos scripts de teste) está na Parte 2.

### Trilha `01-compiler`

20 itens.

### 03r-ao · A ordem entre o 130 e o 128 no rakun *(proposta)*

**Trava:** `01-compiler/130` passo 5 (as linhas do rakun) e a abertura da `04-rakun/128` — só o registro; as frentes já seguem a (a)

**Contexto.** A frente 128 reorganiza o rakun (a decisão 187 funde membros: 25 viram 16) e move
arquivos — por exemplo `rakun-actuator-api` para `modules/rakun/src/actuator_api/`. O passo 5 da
`01-compiler/130` (decisão 216: decoradores produzem membros e meta em vez de `@emit` solto) ainda
edita arquivos que o 128 move ou que as frentes do rakun possuem: o `decorators.bp`, `autoconfig.bp`,
`config.bp`, `context.bp`, `lifecycle.bp` e `conditions.bp` do core, `rakun-web/src/convention.bp`,
`rakun-app`, `rakun-scheduling`, `rakun-messaging`, `rakun-cli`, `rakun-data`, `rakun-security`,
`rakun-websocket`, `rakun-client` e o `actuator_api`. As frentes já seguem a (a) como regra provisória:
o 130 já escreve os caminhos de depois do 128 e não faz commit no rakun com o 128 aberto
(`130-decorator-outputs/README.md` § Step 5), e o `04-rakun` já dá ao 130 a escrita do `decorators.bp`
congelado (`04-rakun/README.md` § Order e § Rules, "to confirm"). Os sites já migrados (`#[entity]`,
`#[entityRepository]`, `#[belongsTo]`, `#[query]`, `#[cached]`, `#[halResource]` e as fábricas
`T.make()` do `front/130-rakun-di`) estão na `feat` e se movem com os arquivos. Falta só registrar a regra.

**Hoje:**
```text
130 passo 5 escreve:     modules/rakun/src/actuator_api/**   (hoje rakun-actuator-api, movido pelo 128 passo 1)
130 passo 5 diz:         nenhum commit do 130 no rakun enquanto o 128 estiver aberto (03r-ao (a))
04-rakun § Rules:        src/decorators.bp congelado; único escritor: a reescrita do 130 (a confirmar)
nenhuma decisão registra a regra
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
o 130. **Bloqueia:** só o registro — o 130 e o `04-rakun` já seguem a (a); a abertura do 128 e as
linhas do rakun no passo 5 do 130 andam pela regra provisória até a confirmação.

### 17-b · O incremento por linha de um `Dict` com `keyed: true`

**Trava:** `01-compiler/17` passo 1, quarta caixa

**Contexto.** A frente 17 implementou o `keyed: true` (decisões 168 e 174; a grafia `label: value` é da
305): um `var` global anotado `#[@BeamMemory.Ets(keyed: true)]` vira uma tabela ETS em que cada chave é
uma linha. `counts.at(k)` lê uma linha (`ets:lookup`) e `counts = counts.insert(k, v)` escreve uma linha
(`ets:insert`); dois processos escrevendo cada um a sua chave 20 000 vezes terminam em `20000 20000`. O
que falta é um `+=` numa linha virar `ets:update_counter` (atômico). O `??` agora existe, então a forma
abaixo **tipa** — mas continua recusada, porque recalcula a linha a partir do próprio var e pode perder
um de dois incrementos simultâneos (a regra 5(b) da decisão 40). `counts.at(k) += 1` e `counts[k] += 1`
não são alvos de atribuição.

**Hoje:**
```bp
#[@BeamMemory.Ets(keyed: true)]
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
  `Dict` normal e, sob `keyed: true`, `ets:update_counter(T, K, By, {K, 0})`.
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
método cuja atomicidade só existe sob `keyed: true`, (c) cria um alvo de atribuição que a linguagem não
tem, (d) faz uma forma escrita mudar de significado conforme o padrão. **Bloqueia:** a quarta caixa do
passo 1 da 17.

### lg2-w · Função host chamada do corpo de um decorator

**Trava:** `01-compiler/14` passo 6 (as linhas que esperam decisão: lg2-j, lg2-o, lg2-w); fora de 00–03: rakun 16 (`#[scheduled]`) e todo decorator que reusaria o std

**Contexto.** Um decorator roda num runtime comptime (BEAM ou wat). Só funções com corpo viajam para
o módulo do decorator; uma função host (`declare fn` com célula Erlang/JS), do std ou do próprio
projeto, não viaja, e a chamada falha com `call to undefined function quote/1` nos dois runtimes. Na
prática, o `#[scheduled]` da frente 16 repete as regras de cron inline em vez de reusar o std. (O
`@emit` de módulo sai da linguagem pela 216; os exemplos usam meta tipado, 298.)

**Hoje:**
```bp
fn route(comptime decl: @Decl, comptime path: string) { decl.setMeta(Route(path: json.quote(path))); }
// undefined function quote/1
```

- [ ] **(1)** Corpo comptime só chama funções com corpo; a chamada host é recusada, localizada, nomeando a função, em todo target.
  ```bp
  fn route(comptime decl: @Decl, comptime path: string) { decl.setMeta(Route(path: json.quote(path))); }
  // error: `json.quote` is a host function — a decorator body calls bodied functions only
  fn quote(s: string) -> string { … }     // a forma aceita: uma fn com corpo no projeto ou num pacote
  ```
- [ ] **(2)** A célula Erlang viaja para o módulo do decorator no runtime BEAM; no runtime wat a chamada é recusada.
  ```bp
  decl.setMeta(Route(path: json.quote(path)));   // runtime BEAM: compila · runtime wat: error
  ```
- [ ] **(3)** Decorator que alcança célula host sempre roda no runtime BEAM, qualquer que seja o target.
  ```bp
  decl.setMeta(Route(path: json.quote(path)));   // --target wasm: o decorator roda no BEAM e compila
  ```

**Recomendação: (1).** A resposta de um decorator nunca depende de qual runtime o target escolheu
(decisão 84). **Bloqueia:** a linha; frente 16 (`#[scheduled]`); todo decorator que reusaria o std.

### lg2-o · Acesso a arquivos no comptime

**Trava:** `01-compiler/14` passo 6; fora de 00–03: rakun 88, 93

**Contexto.** Um corpo comptime (decorator, template) só vê o prelude do seu runtime: `fs.readText`
lá dentro é recusado na anotação. Por isso o rakun gera o `.bp` de um WSDL com um comando
(`rakun ws generate`) e versiona o resultado. Com (2), o build passaria a ler arquivos além dos
fontes, e esses arquivos entrariam na chave do cache.

**Hoje:**
```bp
fn wsdl(comptime decl: @Decl, comptime path: string) { val xml = fs.readText(path); … }   // recusado na anotação
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

### lg2-j · Estado comptime entre invocações de decorator

**Trava:** `01-compiler/14` passo 6; fora de 00–03: rakun 05

**Contexto.** Cada invocação de decorator é uma chamada de módulo independente: um `var` de módulo
escrito pelo corpo do decorator é recusado na anotação. A pergunta veio do rakun 05, que queria
acumular um catálogo de chaves enquanto as anotações são visitadas. Hoje um catálogo é o registro de
entrada da decisão 256, lido com `@TypeInfo.all` (decisões 253/256) — sem `member: "make"` nem chave
pelo nome do tipo, que a 281 tirou da 256 (a chave por tipo e rótulo é da 321).

**Hoje:**
```bp
var seen: Array<string> = [];
fn register(comptime decl: @Decl) { seen.push(decl.name); }   // erro na anotação
```

- [ ] **(1)** Cada invocação é independente; a lista de registros vem de `@TypeInfo.all`.
  ```bp
  val beans = comptime {
      var d: unknown[] = [];
      for (@TypeInfo.all(with: [service, configuration])) { b -> d = d.append([b.value]); }
      break d;
  };                                      // lido no ponto de entrada; a ordem é a do catálogo, não a da visita
  ```
- [ ] **(2)** Estado mutável comptime por compilação: `seen` acumula, e a ordem de visita passa a importar.
  ```bp
  var seen: Array<string> = [];
  fn register(comptime decl: @Decl) { seen.push(decl.name); }   // compila; seen depende da ordem dos arquivos
  ```

**Recomendação: (1).** A resposta de um decorator depende só da declaração dele, então a ordem em que
o compilador visita as declarações nunca muda um build. **Bloqueia:** a linha; rakun 05.

### lg2-v · Subdiretório numa dependência git

**Trava:** `01-compiler/26` passo 6 (a metade do resolver) e `02/98` passo 4 (o campo `subdir`); fora de 00–03: rakun 73; o argumento da `07-h`

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

### 16-a · A lista de argumentos quebra junto com o que a envolve

**Trava:** `01-compiler/16` passos 4 e 6 (o reformat das cinco bibliotecas)

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

### ctr-s · Decisão 166 × decisão 243

**Trava:** `01-compiler/16` passo 6

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
  (confirmações ★, no fim desta parte) cobre o resto.
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
falta só o texto dizer "emenda". A 286 já aplica essa leitura às listas de anotações ("without one
the width rules decide (166, 243)"). **Bloqueia:** 16-formatter passo 6.

### 16-b · Array aberto: um elemento por linha

**Trava:** `01-compiler/16` passo 4

**Contexto.** Antes, elementos escritos numa linha do fonte ficavam numa linha da saída. Quando a lista
passa a medir largura, isso não é idempotente (a linha junta passa de 80, uma chamada dentro dela
quebra, e o passe seguinte lê outro layout: 3 arquivos do corpus mudaram num segundo passe), e faz a
saída depender de como o fonte estava quebrado — o que a decisão 65 parte 2 proíbe. A decisão 166
(escopo na 243) vem antes desta regra: uma lista escrita com vírgula depois do último elemento sai
aberta, um por linha, mesmo que caiba — a única marca do fonte que conta. Esta escolha decide só a lista
escrita sem essa vírgula.

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
  val xs = [1, 2, 3];      // sem vírgula final e cabe: fica fechado numa linha
  ```
- [ ] **(b)** `fill` de Wadler na lista sem vírgula final: quantos couberem por linha — o resultado
  passa a depender de como o fonte estava quebrado.
  ```bp
  val xs = [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
      21, 22, 23,
  ];
  ```

**Recomendação: (a).** É idempotente e não depende da entrada; o custo é que uma lista longa de
números curtos ocupa uma linha por número. **Bloqueia:** nada.

### lg2-a · Tipo byte

**Trava:** `01-compiler/01-checker`: a linha da lg2-a vira passo quando respondida; `03/104` (os parsers de fio e os corpos de compressão esperam a lg2-a); fora de 00–03: rakun 01, 13, 15, 24, 25, 70, 71; `03r-ab`

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

### lg2-e · O dono num `@Decl` de método

**Trava:** `01-compiler/01-checker`: a linha do dono (`owner`) do `@Decl` de método, ao lado do passo 24; fora de 00–03: rakun 06–10, 29; o marcador da `08-bpp/127`

**Contexto.** A decisão 280 já respondeu os parâmetros: o `@Decl<T>` de uma função ou método tem `T`
= o tipo da função (`@Decl<fn(e: E) -> unknown>` liga `E`), e os exemplos aprovados da 280 (exemplo
1, alvo do `01-checker` passo 24) leem `decl.params`, `decl.params[0].module` e `decl.module` num
`@Decl` de fn. Resta o dono: num decorator aplicado a um método, `decl.owner` dá `badkey`, e só o
`@Decl` do tipo enxerga o tipo inteiro com seus métodos (`decl.methods[i]`). Por isso o rakun faz o
decorator do tipo (`#[restController]`) ler os marcadores dos métodos (`#[getMapping]`). A pergunta é
se o decorator de método deve enxergar o tipo que o declara.

**Hoje:**
```bp
type UserController { #[get("/u/:id")] fn show(self: Self, id: i32) … }
fn get(comptime decl: @Decl, comptime path: string) { decl.owner }     // badkey
```

- [ ] **(1)** O marcador de método só vê o próprio método (parâmetros pela 280); quem vê o tipo é o decorator do tipo.
  ```bp
  #[controller] type UserController { #[get("/u/:id")] fn show(self: Self, id: i32) … }
  fn controller(comptime decl: @Decl) {
      for (decl.methods) { m -> … }       // m.annotations tem `get`; m.params tem `id: i32`
  }
  ```
- [ ] **(2)** `decl.owner` existe no método.
  ```bp
  fn get(comptime decl: @Decl, comptime path: string) {
      decl.owner.name;                    // "UserController"
      decl.owner.methods.length;          // os irmãos do método
  }
  ```

**Recomendação: (1).** Um decorator de método responde pelo método; o que depende do tipo inteiro é
do decorator do tipo, que já vê todos os métodos. **Bloqueia:** a linha (o marcador em
`typed-action-example.bp` do `08-bpp/127`, que fecha com o passo 24 do `01-checker` quanto aos
parâmetros); rakun 06–10, 29.

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

### ctr-o · Decisão 146 × confirmação `lem-c`

**Trava:** a confirmação da `lem-c` (confirmações ★, no fim desta parte): qual regra do checker vale para a declaração host sem corpo — só o registro na `01-compiler`

**Contexto.** A 146 diz que uma função cujo corpo alcança uma função host (com `#[@External.<Target>]`)
sem binding para o target em build é recusada na declaração, chamada ou não. A `lem-c` (confirmações ★,
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

### ctr-h · Decisão 149 × decisões 210 e 211

**Trava:** nada — só o registro (o `==` estrutural das 210/211 já está na `feat`); estava na antiga Parte 0

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

### 17-c · O que mais pode nomear um var `keyed: true`

**Trava:** nada hoje — o passo 1 da `01-compiler/17` vale como está; estava na antiga Parte 0

**Contexto.** Um var `keyed: true` não tem "valor inteiro" na memória: é uma tabela lida linha a linha.
Por isso hoje ele só aparece como `counts.at(k)` (`ets:lookup`) e `counts = counts.insert(k, v)`
(`ets:insert`); todo o resto (`counts[k]`, `hasKey`, `delete`, `size()`, passá-lo adiante) é recusado no
identificador, e um var keyed nunca é `pub` (quem importasse leria o valor inteiro, que não existe). A
decisão 63 (1.0.5) dá ao índice outra resposta que a do `at`: `d[k]` responde o tipo do valor, `V`, e
**falha** quando a chave falta; `d.at(k)` responde `?V` (`null` na ausência).

**Hoje:**
```bp
@print(counts.size());     // error: `counts` is a `keyed = true` var: it is read one row at a time, as `counts.at(key)`
@print(counts["a"]);       // a mesma recusa; pela 63, counts["a"] responderia i32 e falharia sem a linha
```

- [ ] **(a)** Só as duas formas, como está.
  ```bp
  val a = counts.at("a") ?? 0;          // ets:lookup
  counts = counts.insert("b", 10);      // ets:insert
  @print(counts["a"]);                  // error: … read one row at a time, as `counts.at(key)`
  ```
- [ ] **(b)** (a) mais `counts[k]`, com o sentido da 63: responde `V` e falha quando a linha falta.
  ```bp
  @print(counts["a"]);       // ets:lookup; sem a linha "a", falha (63)
  ```
- [ ] **(c)** (b) mais `hasKey` (`ets:member`) e `delete` (`ets:delete`) como operações de linha, cada uma
  um primitivo novo no `std/beam`.
  ```bp
  if (counts.hasKey("a")) counts = counts.delete("a");
  ```

**Recomendação: (a).** Uma grafia por operação de linha; (b) custa pouco, mas é uma segunda leitura de
linha, com outra resposta na ausência; (c) aumenta a superfície que o checker e os dois emissores
precisam manter iguais. **Bloqueia:** nada — o que está construído vale até ser ampliado.

### Trilha `02-std-and-packaging`

7 itens.

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

### 08-f · Onde moram Markdown e YAML

**Trava:** `02/97`: uma linha (o `yaml` no std, se for a (b)); fora de 00–03: `08-bpp/121` passo 3

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

### 95-f · A tomada do onze aconteceu sem o branch órfão e sem arquivar nada

**Trava:** `02/98` passo 3 (a frente 95 fechada como confirmação)

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
reescrever o remoto custa um reclone em todo lugar sem ganho. **Bloqueia:** o passo 3 do `02/98`
("front 95 closed as a confirmation"), escrito sob a (1), fecha com ela.

### nat-f3 · `files` e `workspaces` no `botopink.json` (98)

**Trava:** `02/98` (o que vai no pacote; a 270 conta com `files`)

**Contexto.** `files` lista, relativo a `src`, os módulos que um consumidor pode importar (como no npm).
Um pacote-biblioteca sem `files` não publica nada (`docs/botopink-json.md:52`). `workspaces` lista os
membros de um monorepo. Um manifesto com `workspaces` é workspace e recusa `src`, `files`, `entry` e
`dependencies` (`:159-170`), então os dois nunca estão no mesmo arquivo. A 270 já conta com `files`: o
prelude do pacote do `"bpp"` é `src/prelude.bp`, listado em `files`.

**Hoje:**
```json
{ "name": "acme-web", "src": "src/", "files": ["root.bp", "router.bp"] }
```
```json
{ "name": "rakun", "workspaces": ["modules/*", "examples/*"] }
```

- [ ] **(a)** Os dois ficam: é empacotamento, não código.
- [ ] **(b)** `files` sai: publica-se o que é `pub`, e um módulo interno se marca no código (`#![internal]`
  não tem grafia desde a 315); `workspaces` fica. A 270 deixa de citar `files`.
- [ ] **(c)** Os dois são derivados.

**Recomendação: (a)** — o que vai no pacote é um fato de empacotamento, e a 270 já conta com ele.
**Bloqueia:** 98.

### nat-d9 · Nomes do LINQ no erika ao lado dos do std (98)

**Trava:** `02/98` (o primeiro helper do `erika-test` e o README do `erika-linq`)

**Contexto.** O erika imita o LINQ do C#: `where`, `select`, `selectMany`, `orderByDescending`, `toList`.
O std já tem `filter`, `map`, `flatMap` e `unique` (217) para as mesmas operações. O erika é eager: cada
operador materializa um array novo (`erika/src/erika.bp:5`). Por outro lado, a identidade do erika é
justamente ser um LINQ.

**Hoje:**
```bp
query.where({ c -> c.active }).select({ c -> c.name }).toList()
```

- [ ] **(a)** Os nomes do std; o erika só acrescenta o que o std não tem (`groupBy`, as agregações).
  ```bp
  query.filter({ c -> c.active }).map({ c -> c.name })
  ```
- [ ] **(b)** Os nomes do LINQ: é o propósito do erika.
- [ ] **(c)** Como está.

**Recomendação:** nenhuma desta revisão — depende do que você quer que o erika seja; a (b) é uma leitura
justa.
**Bloqueia:** 98 (erika).

### Trilha `03-bundled-libs`

6 itens.

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

### ctr-p · Confirmação `std-a` × confirmação `03r-e`

**Trava:** `03/104` passo 5 (a varredura de consumidores); fora de 00–03: os leitores do rakun 04

**Contexto.** Há dois decodificadores de query/cookie, cada um com uma regra. A `std-a` (confirmações ★,
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
"como escrito" chega ao código como se fosse válido. A 294 já vai nessa direção para cookie: `use
cookie(decl)` dá `null` quando o valor não decodifica. **Bloqueia:** os leitores do rakun 04; a
varredura de consumidores da 104.

### ctr-k · Decisão 187 × decisão 195

**Trava:** `03/106` passo 2 e a abertura da `04-rakun/128` — só o registro; as frentes já seguem a (a)

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
instalado no boot). As frentes já seguem a (a) (`04-rakun/17`: "the logger installs itself as `log`'s
sink at boot"; `03-bundled-libs/106-log`); falta só o registro da 195. **Bloqueia:** nada nas frentes;
só o registro.

### 03r-q ★ · Roteamento por locale mora no `rakun-app`

**Trava:** `03/105` inteira (o `i18n` bundled abre com ela confirmada)

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

### 07-g · Renderização de release OTP

**Trava:** `03/107` inteira (frente condicional: responder ou adiar a 107)

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

---

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

---

## Parte 2 — O resto, uma linha por pergunta (trilhas 04–09 e 20)

### A forma botopink (`nat-*`, decisões 281–284)

| Id | Assunto | Recomendação | Trava |
|---|---|---|---|
| `nat-d6` | `throw "nav:not-found"` ao lado do `noreturn` (53) | (a). Junto com a lg2-l e a lg2-h. | `05-jhonstart/26`, `07-onze/53`; lg2-l, lg2-h, 31-a. |
| `nat-d7` | Anotações de ciclo de vida ao lado de interface (rakun 04) | (a). | rakun 04. |
| `nat-d8` | Hook chamado `use…` debaixo de `use` (53) | (a). | os exemplos da `07-onze/53`. |
| `nat-f2` | As opções do `onze.json`: `trailingSlash`, `redirects`, `markdown`, `allowedRedirects` (124, 08-h) | (a) — é configuração, pode ficar no JSON (284), e o build confere como conferiria o código, do jeito que a 299 faz com a do rakun. | 124; 08-h; `07-onze/49` e `50`. |
| `nat-f4` | O prefixo `ONZE_PUBLIC_` nas variáveis de ambiente (53, `contracts.md`) | (b). | `07-onze/50` e `53`; `contracts.md`. |

### Contradições entre decisões

| Id | Assunto | Recomendação | Trava |
|---|---|---|---|
| `ctr-l` | A terceira recusa da 186 × decisão 202 | (a). Sob a 202 nenhuma página se declara pré-renderizada; a recusa é letra morta, e a 202 é a mais restritiva (não há como forçar estágio). | nada nas frentes; só o registro. |
| `ctr-v` | Decisão 189 (org-3) × as frentes da emilia abrindo antes da 118 | (a). Um comentário não muda comportamento; segurar duas frentes da emilia por ele não protege nada. | nada nas frentes; só o registro. |
| `ctr-w` | O braço Elasticsearch da 09 × decisão 185 | (a) — é o que a 185 manda e não acrescenta membro. | 09 passo 3. |

### Destravam uma frente ou um passo

| Id | Assunto | Recomendação | Trava |
|---|---|---|---|
| `erk-a` | A fonte de uma consulta `erika "…"` no corpo de um método | (b). Uma grafia só do `from`, em todo lugar; a fonte achada pelo tipo, nunca por nome. | `04-rakun/137` passo 2 (a forma no corpo) · a célula da forma no corpo do passo 7 da rakun 08 |
| `erk-b` | O `#[documentQuery]` depois da 313 | (a) agora — uma forma só de repositório para todo store; (b) quando uma necessidade medida pedir. | `04-rakun/09` passo 4 |
| `08-d` | Quem faz o escopo do CSS | (a). A (c) põe um parser de CSS na biblioteca de HTML; a (b) deixa o estilo com escopo indisponível sem o onze. | 119 inteira — na cadeia crítica 118 → 119 → 120 → 126 → 127 → 124. |
| `props-d` | Os atributos de uma tag nativa | (a) — uma regra para toda tag, a mais restritiva. | 118 passos 1 e 4. |
| `props-e` | Slot nomeado | (a) — a 192 já cobre, sem um segundo mecanismo de encaminhamento, e é o caminho que a 287 tomou para o fallback. | as caixas de slot da 118 (passos 1 e 4). |
| `props-f` | Spread num componente | (a). Uma grafia só para passar props, cada atributo visível onde a tag é escrita. | 118 passo 1. |
| `03r-ab` | Front 09: stores de protocolo binário | (a) — nunca cair para ETS debaixo de uma URL do Mongo; o braço Elasticsearch sem aresta para o `rakun-client` (ver `ctr-w`; o passo 3 da 09 ainda passa por ele). A frente já segue a (a); falta só o registro. | 09 passo 5 (as células de recusa). |
| `03r-ae` | SAML 2.0 ACS | (a) — a 79 está no grupo A do rakun, então está escalada neste milestone; **(b)** só se ela sair dele. Nunca a (c). | 79 passo 3. |
| `03r-af` | Os sete projetos de exemplo nunca construídos | (a). O contrato de cada membro já é afirmado pelos testes do próprio membro; sete frentes de exemplo não provariam nada novo. | 73 passo 3. |
| `03r-ak` | Validar o SBOM contra o schema CycloneDX 1.5 | (a). Valida contra o schema de verdade, sem rede, sem afrouxar a caixa e sem pôr no std um validador genérico por causa de um consumidor só. | 81 passo 3. |
| `03r-al` | Transações de produtor Kafka | (a); o broker real vira linha em `deferred.md`. | 15 passo 5 (só o |
| `03r-am` | Onde moram os dublês de broker e scheduler | (a), com a forma (c) em qualquer caso. | 19 passos 3 e 4. |
| `03r-an` | O transporte WebSocket do RSocket depois da 187 | (b). | a primeira e a terceira caixas do passo 2 da 92. |
| `50-b` | O que o `onze dev` faz numa mudança | (a), a mais restritiva: um caminho de código só, os mesmos bytes que o `start` serve; (b) depois, se (a) medir lento demais no blog. | 50 passo 2; 53 passo 6 ("`dev` serve toda |
| `67-a` | Onde as caixas de forms do lado do DOM são afirmadas | (a). As caixas rodam no gate da biblioteca dona, onde quebram primeiro, sem dependência nova; o navegador do onze 53 confere de novo. | a forma dos passos 1–3 da 67 (escritos para a (a)); o caminho de |
| `05emilia-n` | As linhas do Tailwind sem dono | (a); (b) se você quiser alguma feature. | 34 passo 4 (condicional). |
| `atm-c` | O `T` de um átomo entre servidor e browser | (b) — restritivo onde importa (o que atravessa) e livre no resto. | 136 passo 6. |
| `atm-d` | Quais efeitos de átomo entram | (a) — primeiro a store; efeitos num passo próprio quando houver uso medido. | 136 passo 8. |

### Não bloqueiam nada hoje

| Id | Assunto | Recomendação | Trava |
|---|---|---|---|
| `own-a` | Quem é dono dos scripts de teste | (a) — um dono só, a frente que já herdou o passo aberto da 25. | nada |
| `07-b` | "Uma lib, várias cópias divergentes" também justifica pacote? | (a). Pacote bundled novo continua exigindo dois consumidores; a cópia de uma lib só se resolve dentro dela, sem abrir pacote (decisão 67: a regra mais restritiva). |  |
| `07-h` | Bundled, ou um repositório compartilhado à parte? | (a). Fios que dois frameworks precisam concordar byte a byte saem com o compilador que os embute; a (b) depende de abrir a `lg2-v`, que fica fechada. | nada hoje — a trilha |
| `std-e` | Hooks de ciclo de vida de teste | (a). Nada implícito roda em volta de um teste; o que ele precisa está escrito nele. | só a linha "No test lifecycle hooks" do `language-gaps.md`, que fica como está. |
| `07-i (revisão)` | A proibição de nomes repetidos em pacotes bundled continua depois do alias? | (desta revisão): (a). Um pacote novo escolher um nome livre não custa nada, e o alias fica para o caso em que o nome natural é do std (decisão 170). Vale também para o 103: o pacote usa `deriveActionId`, porque o `rakun-app` já … | nada; as frentes |
| `lg2-b` | O que `@Task<T>` significa no BEAM | (1). O tipo promete o valor, nada sobre sobreposição; a única forma concorrente continua sendo a explícita (a leitura restritiva da decisão 120 da 1.0.10). | a linha |
| `lg2-d` | Decorator que lê o corpo | (1). Um decorator lê assinaturas, não corpos; a saga do rakun 83 continua um valor. | a linha; rakun 83. |
| `lg2-h` | Raise e catch por tipo | (1). É a decisão 121 como escrita: o erro é o `E` do `@Result`. | a |
| `lg2-l` | `noreturn` é tipo-fundo? | (1). Um sinal nunca é um valor. | a linha; os sinais do jhonstart (63, |
| `lg2-n` | Thunk convertido em `Node` | (1). As coerções que o compilador conhece continuam três (array, `Element`, `string`). | a linha; jhonstart 30. |
| `lg2-p` | Cancelamento | (1). Em linha com a `lg2-b` (1). | a linha; rakun 02. |
| `lg2-s` | Reflexão do grafo de módulos | (1) — por conta própria: os imports de um módulo são texto que o bundler já lê e recusa alto quando não entende; o argumento antigo ("em linha com a `lg2-k`") caiu com a 216. | a linha; onze 68 (o bundler de cliente). |
| `lg2-u` | Decorator em posição de expressão | (1). Um decorator anota uma declaração ou uma tag; trabalho numa expressão comum é uma chamada. | a linha (o caso da marcação da frente 48 do emilia já está coberto pela 301). |

---

## Parte 3 — Confirmações ★ das trilhas 04–09

### libs-external-methods

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `lem-a` | Um método host é um método de verdade | (a) Um lowering só: método real cujo corpo é a binding, nunca colado no site da chamada (custa um quadro de pilha a mais por chamada). | (a). Um caminho só; (b) é uma otimização com um segundo caminho para manter em quatro backends. |
| `lem-c` | Método sem binding é recusado onde é CHAMADO | (a) Recusa na chamada; o tipo compila para qualquer backend. | (a) — e registrar que a decisão 146 vale para função COM corpo, livre ou método, que alcança uma dessas (ver `ctr-o`). A assimetria do wasm se resolve no dia em que o wasm tiver host. |
| `lem-d` | Os nomes depois do colapso | (a) Um nome por operação em todo tipo: `Listener.port/accept/close`, `Socket.recv/send/close/peer`, `TlsListener.port/accept`, `TlsSocket.recv/send/close`, `Regex.matches`. | (a). O prefixo repetia o que o receptor já diz. |
| `lem-e` | O que ficou função livre mesmo recebendo um tipo | (a) Auxiliares privados ficam livres. | (a). Privado continua privado. |
| `lem-f` | O commonJS adota um registro construído pelo host | (a) O commonJS adota a resposta na classe (`run/external_method_on_host_record`). | (a). Cumpre o que o `docs.md` prometia sem amarrar o template ao nome de uma classe gerada. |

### rakun

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

### jhonstart

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `26-a (jhonstart) ★` | Toda célula do roteador tem os dois targets | (a) manter — célula nos dois targets, um teste para as duas linhas | (a). |
| `27-a ★` | Célula de browser num membro de dois targets | (a) manter — gêmeo erlang que responde o vazio do servidor | (a). Um hook que o render do servidor chama tem de existir no servidor. |
| `29-a ★` | A tabela de starters de island: o que resta é o loader por rota | (a) manter — `globals.starters` + `registerRouteStarters`; nenhum `__` escrito à mão; um loader por rota | (a). A divisão segue a unidade do manifest (a rota) e a entrada não declara global nenhum. |
| `30-b ★` | `RenderPlugin` é um registro de funções | (a) manter — registro de funções; a lista de plugins tipa hoje | (a). Os quatro momentos e a ordem são os do README; só muda onde `chunk` roda. |
| `30-c ★` | `compose` recebe a página como thunk | (a) manter — dois módulos (`render.bp`, `streaming.bp`); página como thunk | (a). |
| `30-d ★` | `Suspense` registra a fronteira no render | (a) manter — a página só devolve a árvore | (a). |
| `30-e ★` | O registro de segmento se chama `UiSegment` | (a) manter — `UiSegment` | (a). |
| `30-f ★` | `app(…, lang:)` | (a) manter — uma língua por app, `"en"` por padrão | (a) agora; `PageInput.lang` por request é aditivo quando o `i18n` (105) entrar. |
| `30-g ★` | A metade de browser é afirmada num membro só-commonJS | (a) manter — as três caixas afirmadas hoje sobre o markup que o render produz | (a). O onze 53 ainda prova as mesmas caixas num browser. |
| `31-a ★` | `notFound()` / `redirect(url)` levantam | (a) manter — a mesma instrução serve em página, layout, template e thunk | (a) até a nat-d6 e a lg2-l serem respondidas; se a nat-d6 for (a), este item vira (c). |

### emilia

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `05emilia-a ★` | O leitor de filtro é uma cadeia inline | (a) manter — `blur-sm brightness-50` compõem na mesma classe, como o upstream | (a). |
| `05emilia-b ★` | A seção de backdrop é `BackdropFilter` | (a) manter — nenhuma frente pronta muda | (a). |
| `05emilia-c ★` | `drop-shadow-none` segue o upstream | (a) manter — CSS válido, igual ao upstream | (a). |
| `05emilia-d ★` | A rigidez do snap é um fallback, não uma entrada do tema | (a) manter — fallback inline | (a). |
| `05emilia-e ★` | `fullTheme()` vai no `fullOptions()` — e qual é a base do `#[theme]` (300) | (a) manter — `fullOptions()` em `emilia.bp`; a base e o fallback da 300 são o `fullTheme()` | (a). Não mexe em cinco frentes e só troca o nome da base na 300. |
| `05emilia-f ★` | As entradas `--inset-shadow-*` não levam o `inset` | (a) manter — o utilitário escreve o `inset`; a entrada do tema não | (a). Não mexe numa frente já entregue. |
| `05emilia-g ★` | `space-*` / `divide-*` como o upstream | (a) manter — `Space.XReverse` passa a ter efeito | (a). |
| `05emilia-i ★` | As variáveis `--tw-*` de transform são blocos `@property` | (a) manter — saída do upstream, sem tipo de saída novo | (a). `scale-*` já segue a mesma forma (`--tw-scale-*` com `@property`, `emilia.bp:13900-13969,14204`). |
| `05emilia-j ★` | Modificador de lista de seletores | (a) manter — a regra de um `&` da frente 56 fica intacta | (a). |
| `05emilia-k ★` | O meio passo negativo | (a) manter — sinal no nome | (a). |
| `05emilia-l ★` | Confirmar uma coluna move a família inteira para a forma do upstream | (a) manter — família inteira na forma do upstream | (a). |

### onze

| Id | Assunto | Implementado (★) | Recomendação |
|---|---|---|---|
| `49-a ★` | As suítes do core renderizam pelo `describe*` do próprio core | (a) manter — uma renderização só; o core testa só com std | (a). |
| `49-c ★` | `onze.json` recusa chave desconhecida | (a) manter — erro nomeando a chave | (a) (decisão 67: um `"prot"` errado não pode deixar a porta 3000 em silêncio). |
| `49-e ★` | A metade rakun do boot é um membro próprio | (a) manter — a CLI nunca carrega rakun; o release que serve carrega `onze-server` | (a). |
| `50-a ★ (emendada)` | `onze build` gera um main de servidor; `onze start` o roda | (a) manter — até o `bin/onze` da frente 71 existir; aí o `start` chama esse script | (a) até o `bin/onze` da frente 71 existir; aí o `start` chama esse script, e o comando de hoje é o que o script roda. |
| `52-a ★` | A tabela de métricas de fonte é transcrita | (a) manter — cinco famílias funcionam com `adjustFontFallback: true` | (a), com as linhas re-derivadas pelo gerador antes de um release. |
| `53-a ★` | Os fontes do blog ficam sob `src/` | (a) manter — o exemplo cobre o layout `src/`; o roteiro de aceitação lê `src/<caminho>` | (a). Os dois layouts compilam. |
| `68-a ★` | Um campo do manifest escapa quatro caracteres | (a) manter — legível; só `%`, `\|`, LF e CR viram `%25`, `%7C`, `%0A`, `%0D` | (a). |
| `68-d ★` | O styleMap é avaliado por uma sonda compilada nos dois pacotes | (a) manter — a classe é a da própria função do emilia, nos dois compiladores | (a) até o passo 1 da frente 34 e o passo 4 da 119 aterrissarem; aí a sonda sai. |
| `69-a ★` | `onze-assets` mantém o seu `AssetRoot` | (a) manter — o build continua em node | (a). |
