# Decisões pendentes — 1.0.12-beta (só o que está em aberto, por ordem de importância)

Atualizado em 2026-10-03. Só o que ainda espera resposta sua: o que já foi respondido está em
`specs/1.0.12-beta/decisions-taken.md` (decisões 144–270; próximo número livre: **271**) e saiu daqui.
Respondidas desde 02/10: 225–233 (caches, OTP, CI, `test-web`, std no wasm), 234–236 (injeção do rakun,
`@TypeInfo.all` com lista, decorador de função), 237 (captura do template pelo texto), 238–243
(`@External.Wasm`, `$stringify`, codepoints no wasm, células sem WASI, dependência direta, vírgula final),
244 (default só no fim), 246 (`test-libs` com todas as bibliotecas na chave), 247 (sufixos de literal
minúsculos; a 209 revertida), 248 (um builtin só, `@typeInfo`), 249 (o compilador separado por backend na
chave do cache), 250 (`io.random.bool()` removido), 252 (todo builtin declarado), 253 (`@TypeInfo.all`),
254 (o catálogo responde `unknown`; `is fn() -> T`), 255 (`Tipo<…>.membro` e `comptime <expr>`), 256 (o
registro de beans em comptime no ponto de entrada), 257 (`Schema<T>` na `validation`), 258 (`--lib` múltiplo), 259–263 (`pow` da glibc, `contentHash` por code point, heap do wasm crescendo, `String.fromCodepoint`, `std/math` igual em todo sistema), 264 (estouro de inteiro é erro em todo target), 265 (orçamento do gate frio em 7m30s nesta versão; os 5 min ficam para a próxima), 266 (`comptime` avaliado em compilação em todo lugar, registro içado), 267 (parâmetro variádico `..values: T[]`; `@print` declarado com ele), 268 (tipo builtin `Decorator` no `with:` do `@TypeInfo.all`), 269 (`@getContext(T)` é hook, chamado atrás de `use`), 270 (o prelúdio do `.bpp`: o `src/prelude.bp` do pacote, só imports do próprio pacote, importado só quando usado; o cabeçalho vence). A 245 e a 251 foram registradas cedo demais e retiradas.

> **Numeração.** O prelúdio do `.bpp` tinha sido registrado como 266 no commit `84aa028`, sem saber
> que 266–269 já existiam no seu registro local. Na 1.0.12 ele é a **270**; as 266–269 estão em
> `decisions-taken.md` com o texto completo dos commits `4fb3c5e`, `ec58d33`, `805b2be`, `c4976a6`.

**Ordem:** da decisão que mais destrava para a que menos destrava.
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

**Toda pergunta traz um exemplo por opção e uma linha "Recomendação".** A recomendação é a da spec
que levantou a pergunta, e a regra é sempre a mesma: a opção mais restritiva, sem configuração que a
contorne (decisão 67). Onde a spec não registrava nenhuma, a linha diz "desta revisão" ou "da thread".
Os exemplos das opções que ainda não existem são ilustrativos (a forma final é da frente que
implementar). O texto completo de cada pergunta (Measured / Options / Recommendation / Blocks) está em
`specs/1.0.12-beta/decisions-pending.md` (em inglês, a fonte) e no `README.md` da trilha que a levantou.
Ids marcados *(proposta)* foram levantados na consolidação e ainda não tinham id.

Os ids das decisões não mudaram com a renumeração das trilhas: `07-*` são da `03-bundled-libs`,
`03r-*` da `04-rakun`, `05emilia-*` da `06-emilia`.

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

### ctr-a · Decisão 224 × a chave `islandKeyEnv` da frente 124
224: a chave é `ONZE_KEY` (ou gerada no build) e o modo vai no `onze.json`. A 124 ainda planeja:
```json
{ "islandKeyEnv": "ASTRO_KEY" }        // "a variável que guarda a chave da island"
```
- [ ] **Recomendação:** a 124 segue a 224 — não existe `islandKeyEnv`; a variável é sempre `ONZE_KEY`
  (renomear seria configuração que afrouxa, decisão 67). As chaves da 124 viram `trailingSlash`,
  `redirects`, `markdown`, `islands`.

**Bloqueia:** 124 passos 1 e 3.

### ctr-b · A configuração da 224 × decisão 67
224: "configurável… o modo vai no `onze.json`". 67: nenhuma configuração que contorne o mais restritivo.
- [ ] **Recomendação:** responder a `08-e2` com (a) (Parte 3) — só modos que mantêm as props secretas.

**Bloqueia:** o mesmo que a `08-e2`.

### ctr-c · Decisão 222 × 117 passo 4
222: um route handler é sempre servidor, nunca pré-renderizado. A caixa da 117 diz:
```
app/rss.xml/route.bp   exporta para   <outDir>/rss.xml       ← pré-renderiza um handler
```
- [ ] **Recomendação:** apagar a caixa, ou reescrevê-la como "`app/rss.xml/route.bp` é servido a cada
  request"; um feed estático seria um arquivo do tipo página.

**Bloqueia:** 117 passo 4.

### ctr-d · A opção (a) da `03r-ad` × decisão 187
A (a) diz que `rakun-pulsar` depende de `rakun-tx` — que a 187 funde no `rakun-data`. E lista
`rakun-security`/`rakun-data` desde já, embora a 91 só os acrescente junto com o plano de dados.
- [ ] **Recomendação:** sob (a), o membro depende de `rakun-data` para transação; o registro diz 17
  membros depois da divisão.

**Bloqueia:** 91; a lista de membros do 128.

### ctr-e · O `-> Element` das 199 e 213 × decisões 113 e 198
199 e 213 escrevem `pub default fn PostCard(props: Props) -> Element`, mas `Element` é nome do jhonstart
e a ferramenta "não nomeia biblioteca nenhuma" (198, 113). E um cabeçalho com `use`/`await` precisa de
`-> @Component<…>`.
- [ ] **Recomendação:** responder a `bpp-f` com (b) (Parte 2); ler o `-> Element` das 199/213 como a
  instância do jhonstart dessa regra.

**Bloqueia:** 116 passo 2.

### ctr-f · Decisões 198 e 199 × decisão 213
199: `card.bpp` é `pub fn card(…)`; 198: `import {components.card.Card};`. A 213 passou a
`pub default fn PostCard(…)` e `import {components.PostCard};` sem citar as duas.
- [ ] **Recomendação:** registrar que a 213 emenda o nome e a visibilidade da 199 e o exemplo de
  import da 198 (`card.bpp` → `pub default fn card`, `import {components.card};`, ou com alias).

**Bloqueia:** os READMEs da 116 e da 118.

### ctr-g · 213 × 221: um nome ligado duas vezes
213: `page.bpp` vira `pub default fn page`. 221: o `bppKinds` aplica o decorador `page` do jhonstart no
mesmo módulo. Dois `page` no mesmo escopo (152/205 recusam), e a 270 recusa um cabeçalho que ligue o
nome da função default.
```bp
pub default fn page(…) { … }       // nome do arquivo (213)
#[page] …                           // decorador do jhonstart, mesmo nome (221)
```
- [ ] **(a)** A ferramenta aplica o decorador do `bppKinds` por referência qualificada, sem ligar nome
  no módulo.
- [ ] **(b)** A função de um arquivo de rota ganha outro nome que não o do arquivo.
- [ ] **(c)** Os decoradores ganham nomes diferentes dos tipos de arquivo.

**Recomendação: (a)** — não muda a superfície de nenhuma biblioteca. **Bloqueia:** 116 passo 2; 117
passo 1; `bpp-g`.

### ctr-h · Decisão 149 × decisões 210 e 211
149: `==` é por referência em array e recusado em record (um record implementa `behavior Eq`). 210:
igualdade estrutural em todo target; 211: um tipo não define a própria igualdade. A 210 não cita a 149.
- [ ] **Recomendação:** registrar a 149 como substituída pela 210, e a cláusula `behavior Eq` pela 211;
  o código na `feat` já segue a 210 (`run/record_structural_equality`).

**Bloqueia:** nada; só o registro.

### ctr-i · Codepoints (169, 240) × `string:length/1` (197)
169 e 240: o índice de string é em codepoints. Mas o erlang usa `string:length/1` e `string:slice/3`,
que contam *grapheme clusters*:
```bp
"é".length     // erlang: 1 · wasm: 2
```
- [ ] **(a)** Codepoints: os templates do erlang passam a contar codepoints; uma célula com marca
  combinante fixa os quatro targets.
- [ ] **(b)** Grapheme clusters: 169/240 reescritas; o wasm precisa de um segmentador.

**Recomendação: (a)** — é o que a 169 e a 240 dizem e o que a 260 usa no hash. **Bloqueia:** a
célula do passo 6 da 02-erlang; o lowering de string do 05-wasm.

### ctr-j · Decisão 264 × decisão 176 e "o mesmo valor em todo target"
264: no commonJS o `i64` vai até ±(2^53−1) e passar disso aborta — mas no erlang, beam e wasm a mesma
conta responde. 176 diz que um inteiro além de ±(2^53−1) é `Error` em todo target. E a 264 cita a 247
para algo que a 247 não diz.
```bp
val x: i64 = 9007199254740991 + 1;   // commonJS: aborta · erlang: 9007199254740992
```
- [ ] **(a)** `i64` é ±(2^53−1) em todo target (a leitura da 176).
- [ ] **(b)** O commonJS baixa `i64` para `BigInt`, faixa completa.

**Recomendação: (a)**, a mais restritiva; nos dois casos a citação da 247 é corrigida. **Bloqueia:**
as checagens de faixa de 04-js, 02-erlang, 03-beam; a regra do literal `l` no checker.

### ctr-k · Decisão 187 × decisão 195
187: o core absorve `rakun-logging`. 195 (posterior): "o rakun-logging … se instala como o sink".
- [ ] **Recomendação:** ler a 195 como "o logging do core (depois do 128) instala o logger erlang como
  sink do `log` no boot", e registrar assim.

**Bloqueia:** 04-rakun/17 · 128 · 106.

### ctr-l · A terceira recusa da 186 × decisão 202
186 recusa "um hook `#[serverOnly]` numa página que se declara pré-renderizada". 202: nenhuma página
se declara pré-renderizada (não existe `prerender`).
- [ ] **Recomendação:** apagar a terceira recusa da 186.

**Bloqueia:** a lista de recusas do passo 8 da 26.

### ctr-m · O argumento da `lg2-s` × decisão 216
A recomendação da `lg2-s` (Parte 4) diz "em linha com a `lg2-k` e a `lg2-m`" — mas a `lg2-k` foi
respondida ao contrário (216 dá reflexão do projeto em comptime).
- [ ] **Recomendação:** reargumentar a `lg2-s` sozinha (os imports de um módulo continuam uma
  varredura textual), ou respondê-la como a 216 fez, com um campo `imports`.

**Bloqueia:** a `lg2-s`.

### ctr-n · O exemplo da 170 × decisão 206
170: `import {x as a} from "m1"; import {x as b} from "m2";`, com `m1` um módulo. 206: `from` só nomeia
pacote — a forma é `import {m1.x as a};`.
- [ ] **Recomendação:** reescrever o exemplo da 170 na forma da 206; responder a `imp-a` (Parte 3).

**Bloqueia:** `imp-a`.

### ctr-o · Decisão 146 × confirmação `lem-c`
146: função cujo corpo alcança função host sem binding é recusada na declaração, chamada ou não.
`lem-c` (Parte 6): método host sem binding é recusado onde é chamado.
- [ ] **Recomendação:** confirmar a `lem-c` para declaração host sem corpo (um tipo declarado uma vez
  compila para um target em que falta um método); a 146 vale para toda função com corpo; o `docs.md`
  diz as duas.

**Bloqueia:** a confirmação da `lem-c`.

### ctr-p · Confirmação `std-a` × confirmação `03r-e`
`std-a`: `querystring` recusa escape que decodifica para caractere de controle. `03r-e`: componente de
cookie/query que decodificaria para caractere de controle "fica como escrito".
- [ ] **Recomendação:** confirmar a `std-a`; a `03r-e` cai quando o rakun ler query pela `querystring` e
  cookie pelo `http`.

**Bloqueia:** os leitores do rakun 04; a varredura de consumidores da 104.

### ctr-q · Decisão 234 ("no boot") × decisão 256 ("em comptime")
234: o contexto é preenchido no boot a partir do `@TypeInfo.all`. 256: o registro é construído em
comptime, no ponto de entrada.
- [ ] **Recomendação:** ler o "no boot" da 234 como "a partir do registro comptime da 256", e registrar.

**Bloqueia:** 130 passo 5.

### ctr-r · Decisão 189 (org-3) × decisão 200
org-3: "a 118 reescreve os atributos fora do próprio `jhonstart-html`". 200: o `jhonstart-html` é
apagado (26 passo 0, antes da 118).
- [ ] **Recomendação:** ler a org-3 contra o `html.bp` do core depois do 26 passo 0.

**Bloqueia:** os recortes da 118.

### ctr-s · Decisão 166 × decisão 243
166: lista sem vírgula final fica numa linha. 243: sem ela, decidem as regras de largura
(`16-a`/`16-b`) — e diz que "estende" a 166.
- [ ] **Recomendação:** registrar a 243 como emenda da metade "sem vírgula" da 166.

**Bloqueia:** 16-formatter passo 6.

### ctr-t · 213 × 221: arquivo de tipo cujo nome não é nome de função
213: nome de arquivo que não é nome de função válido é erro. 221 mapeia tipos por nome de arquivo — e
`not-found.bpp` é um deles (o scaffold da 124 o tem; a tabela de rotas do onze importa `NotFound`).
- [ ] **Recomendação:** um arquivo listado no `bppKinds` recebe o nome de função do tipo
  (`not-found` → `NotFound`); qualquer outro mantém o erro da 213.

**Bloqueia:** 116 passo 2; o scaffold da 124.

### ctr-u · Decisão 216 × o `#[schema]` da 125
216: um decorador produz membros, meta, tipos associados e reflexão — "o `@emit` solto sai". O
`#[schema]` (na `feat` e no desenho da 125) ainda emite funções soltas:
```bp
#[schema] type Player(…)
val p = try parsePlayer(input);       // hoje: função solta
val p = try Player.parse(input);      // como o #[validated] já faz
```
- [ ] **Recomendação:** as saídas do `#[schema]` viram membros (`Player.parse(input)`); as linhas do
  `surface.md` da 125 acompanham.

**Bloqueia:** 125 passos 3–10.

### ctr-v · Decisão 189 (org-3) × as frentes da emilia abrindo antes da 118
org-3: os recortes da 118 entram antes de a frente dona abrir. A 34 passo 1 e a 33 passo 2 abrem
agora e elas mesmas reescrevem as linhas de comentário `[class]={…}` da emilia.
- [ ] **Recomendação:** registrar que um recorte só de comentário é feito pela frente dona; a 118 fica
  com as linhas de código.

**Bloqueia:** 34 passo 1; 33 passo 2; o Owns da 118.

### ctr-w · O braço Elasticsearch da 09 × decisão 185
185: capacidade opcional passa por um ponto de extensão do core, sem aresta entre membros. O braço
Elasticsearch sobre o `rakun-client` cria uma aresta `rakun-data → rakun-client` que todo consumidor de
dados carrega.
- [ ] **Recomendação:** o braço chega ao HTTP por um ponto de extensão do core (ou pelo `httpc` direto,
  como o relay da 65); responder junto com a `03r-ab`.

**Bloqueia:** 09 passo 3.

- [ ] Confirmo a recomendação em todas desta parte
- [ ] Quero rever: ___

---

## Parte 2 — Destravam muitas frentes

### snap-a · Os mapas de snapshot — aposentados; ficam os snapshots que existem ou que um contrato lê
Substitui as cinco perguntas antigas (`01std-f`, `03r-ag`, `30-h`, `05emilia-m`, `53-b`). Os nove mapas
herdados da 1.0.10 foram reavaliados caso a caso na trilha `20-snap` (frente 135): **473 casos** — 27
obsoletos (renomeados, apagados ou mudados pelas decisões 186, 194, 200, 218, pelo 34 passo 2, pela 50-a,
ou adiados pela `03r-ad`), 418 já verificados hoje por um teste inline ou um `.snap` que existe, e 21
que nada verifica e valem um teste simples. Os literais gravados nos mapas são anteriores ao código
(separador de slug, ordem do `_links`, `normalize`, classes da emilia) e não servem de valor esperado.

Hoje cada caso já é afirmado por um literal inline, nos dois targets:
```bp
test "rounded" { asserts.equals(css([.Rounded.Md]), ".rounded-md{border-radius:0.375rem}"); }
```
- [ ] **(a)** Como proposto: os mapas viram registro fechado; os `.snap` que existem ficam (std 4,
  jhonstart 39, onze 50); um `.snap` novo só onde os bytes exatos são contrato de outro pacote (os
  `text_…` e `dockerfile_…` do onze-release, já em disco, para a `107-release`); helpers só os que um
  consumidor usa — `emilia-test`: `assertClassName` (sob `defaultTheme()`, gravando `e_39b87d03`) e
  `assertCss(loc, tokens, th)`; `rakun-test`: `assertResponse(loc, res)` sobre `MockMvc.perform`; os do
  jhonstart e do onze como estão. Os 21 valores sem verificação viram testes simples:
  ```bp
  asserts.throwsWith({ -> mocks.verify(m, 2) }, "expected 2 calls, got 1");    // std, nos dois targets
  ```
  e 97 passo 7, 26 passo 7, 33 passos 3–4, 50 passo 8, 51 passo 7 fecham com uma linha no `AGENTS.md`.
  Só **3** `.snap` novos (emilia-test 2, rakun-test 1).
- [ ] **(b)** Construir a camada inteira: todos os helpers e `.snap` dos mapas (~2 500 arquivos), com os
  literais recalculados primeiro.
- [ ] **(c)** Manter os mapas abertos por biblioteca: cada uma responde a sua pergunta antiga.

**Recomendação: (a).** Uma regra para todas as bibliotecas, cada valor verificado uma vez. **Bloqueia:**
a frente 135 inteira (`20-snap`), que é dona desses passos.

### 03r-ao · A ordem entre o 130 e o 128 no rakun *(proposta)*
O passo 5 do 130 (decisão 216) ainda planeja editar arquivos que o 128 move ou que as frentes do rakun
possuem (o `decorators.bp` do core, `rakun-web`, `rakun-app`, `rakun-actuator-api` — que o 128 move para
`modules/rakun/src/actuator_api/` — e outros). Nenhuma decisão diz quem vai primeiro.
- [ ] **(a)** O 128 primeiro e sozinho; os pontos do 130 no rakun apontam para os caminhos depois do
  128; depois dele cada um é um commit de consumidor (decisão 188, nunca na mesma onda da frente dona);
  a regra de arquivos congelados abre exceção para a reescrita do `decorators.bp` pelo 130.
- [ ] **(b)** Os pontos do 130 no rakun antes de o 128 abrir.
- [ ] **(c)** O próprio 128 faz a reescrita do 130 nos arquivos que move.

**Recomendação: (a)** — o 128 segura o rakun inteiro, e a (b) seguraria toda frente do rakun esperando
o 130. **Bloqueia:** a abertura do 128; as linhas do rakun no passo 5 do 130.

### own-a · Quem é dono dos scripts de teste *(proposta)*
`scripts/{gate.sh,test-libs.sh,lib/pool.sh}`, `tests/language/run.sh`, `modules/test-shard/**`,
`modules/lib-test-runner/**` e os `scripts/**` do meta eram da 25, 113, 115 e 133 — todas fechadas.
- [ ] **(a)** `01-compiler/07-residuals`, que já tem o passo aberto da 25 (a compilação de dependência
  por célula).
- [ ] **(b)** `00-gate/114`, o resto do gate.
- [ ] **(c)** Ninguém: cada frente declara um recorte por commit.

**Recomendação: (a)** — um dono só, o que já segura o trabalho aberto. **Bloqueia:** 07-residuals passo
12; 114 passos 5 e 7.

### bpp-f · O tipo de retorno da função em que um `.bpp` se desdobra
A reescrita escreve `-> Element`, nome do jhonstart que a ferramenta não pode escrever (113, 198); a 270
traz o nome para o escopo, não a anotação. O pacote de teste do 116 responde o tamanho do literal
(`i32`). E um cabeçalho com `await` ou `use` (199) precisa hoje de `-> @Component<ElementBase, Element>`.
```bpp
---
val post = use loadPost(props.id);     // hook no cabeçalho
---
<article>{post.title}</article>
```
- [ ] **(a)** O retorno é o `R` do `@ExprCustom<R>` declarado pela função default; cabeçalho com `await`
  ou `use` é recusado na linha (estreita a 199).
- [ ] **(b)** Como (a), e o embrulho segue as instruções do cabeçalho pela regra de efeitos por retorno
  (`01-compiler/24`): sem `await`/`use` → `-> R`; com → o embrulho que a regra mandar (o passo 0 do 116 mede).
- [ ] **(c)** O cabeçalho escreve o retorno numa linha `-> T` antes do `---` de fechamento.

**Recomendação: (b)** — mantém os hooks da 199, e todo nome vem da assinatura da função default ou da
linguagem. **Bloqueia:** 116 passo 2.

### bpp-g · Como um `page.bpp` recebe `route: PageContext` e os `params`
A 221 dá o decorador; a reescrita responde `fn <Nome>(props: Props)` ou `fn <Nome>()`; uma página `.bp`
recebe `route: PageContext` e liga os segmentos com `paramsOf(…, route)` (236). O roteador do jhonstart
chama a página com um `PageContext` e não sabe construir o `Props` da aplicação.
```bpp
---
val post = findPost(params.slug);      // de onde vem `params`?
---
<h1>{post.title}</h1>
```
- [ ] **(a)** A entrada do `bppKinds` diz também o parâmetro:
  ```json
  "bppKinds": { "page": { "decorator": "page", "parameter": "route: PageContext" } }
  ```
  a reescrita escreve `pub default fn page(route: PageContext)`, o cabeçalho lê `route`, e o prelúdio
  traz `PageContext` e um helper `params(route)` (ver `ctr-g`).
- [ ] **(b)** O cabeçalho declara `type Props(route: PageContext)`, e o roteador exige essa forma.
- [ ] **(c)** A saída do decorador `#[page]` acrescenta o parâmetro (`01-compiler/130`).

**Recomendação: (a)** — a ferramenta copia o que o manifesto do pacote diz, como a 221 já faz.
**Bloqueia:** 116 passo 6; 117 passo 1.

### 08-j · Como o `local()` do rakun carrega uma marca do jhonstart *(proposta)*
O `local<T>(key)` da 123 lê dado do request, então uma página que o lê renderiza por request (186). Mas
`#[serverOnly]` é marca do jhonstart, e rakun e jhonstart nunca se importam (113).
- [ ] **(a)** As marcas de estágio vão para um pacote que os dois importam (o bundled `routing`, pelo
  teste das duas bibliotecas da 115); os dois marcam com o mesmo `#[serverOnly]`.
- [ ] **(b)** O rakun declara a própria marca; a checagem lê marcas por um nome declarado no manifesto.
- [ ] **(c)** `local` só pode ser lido em middleware, handlers e actions, nunca numa página.

**Recomendação: (a)** — uma marca só, e nenhuma biblioteca nomeia outra. **Bloqueia:** a terceira caixa
do passo 1 da 123; toda leitura de request do rakun que uma página alcança.

---

## Parte 3 — Destravam uma frente ou um passo

Cada uma abre uma frente, um passo ou uma onda.

### 130-b · Dois `#[provides]` do mesmo tipo num registro chaveado pelo nome do tipo (decisões 254, 256)
O trecho da 256 chaveia um provider por `b.returnTypeName`. Dois providers qualificados do mesmo tipo — e um `#[primary]` ao lado de um comum — colidem em `"Dye"`, e o registro os recusa como duplicata. Antes, o `__rkMake_Dye` deixava o sem qualificador (ou o `#[primary]`) ser o injetado e mantinha os outros por `ctx.resolveNamed("Dye", "fast")`.
```bp
#[provides] #[qualifier("fast")] fn fastDye() -> Dye { … }
#[provides] #[qualifier("slow")] fn slowDye() -> Dye { … }     // hoje: duplicata de "Dye"
```
- [ ] **(a)** Provider qualificado é chaveado `Tipo@qualificador`; o nome puro é o sem qualificador ou o `#[primary]`; dois donos do nome puro são a duplicata:
```bp
for (@TypeInfo.all(with: provides)) { b ->
    d = d.insert(rkBeanKey(b), b.value);   // "Dye@fast", "Dye@slow", "Dye" para o primary
}
```
- [ ] **(b)** O registro guarda só o que a injeção por tipo lê; os qualificados ficam na tabela do contexto que o registro em load preenche (`resolveNamed` a lê).
- [ ] **(c)** O trecho como está: dois providers de um tipo são sempre duplicata; qualificador só nomeia bean de tipo com um provider.

**Recomendação: (a)** — um registro, todo bean nele, a regra antiga de dono mantida e duplicata continua erro de build; precisa do `rkBeanKey` chamável no bloco (decisão 266). **Bloqueia:** a migração de `#[provides]` / `#[qualifier]` / `#[primary]` do rakun (130 passo 5).

### 130-c · Os métodos `#[bean]` de um `#[configuration]` no registro (decisão 234)
A 234 preenche o contexto "a partir do `@TypeInfo.all(with: provides)` / dos métodos `#[bean]`", mas o `@TypeInfo.all` responde declarações de topo, e um `#[bean]` é método de um tipo `#[configuration]`: nenhuma consulta o alcança. Hoje o `#[configuration]` emite `__rkMake_<Tipo>()` por `#[bean]` (`autoconfig.bp`, `conditions.bp`, `config.bp`, `settings.bp` do rakun-client, `oauth2/provider.bp` do rakun-security, `examples/rakun`).
- [ ] **(a)** Métodos `#[bean]` viram funções livres `#[provides]` (o record de configuração fica com os campos `#[value]`; o provider os lê por `rkResolve`):
```bp
#[provides]
pub fn dataSource() -> DataSource { return DataSource(url: rkResolve<DbConfig>("DbConfig").url); }
```
- [ ] **(b)** A configuração grava cada bean como meta e ganha um membro `Config.bean(name) -> unknown`; o ponto de entrada faz um terceiro laço sobre `@TypeInfo.all(with: configuration)`.
- [ ] **(c)** O `@TypeInfo.all` ganha `methods: true`:
```bp
for (@TypeInfo.all(with: bean, methods: true)) { b -> d = d.insert(b.returnTypeName, b.value); }
```

**Recomendação: (a)** — um jeito só de fornecer bean, já no laço do registro, sem reflexão nova; o `@Bean` do Spring é o que o `#[provides]` já é numa linguagem com funções livres. **Bloqueia:** a migração do `#[configuration]` do rakun e todo `__rkMake_` que um `#[bean]` define.

### 134-d · `@is(…)` escrito à mão
`x is T` é lido como a chamada builtin `is` levando o tipo testado; o lexer também faz de `@is(1)` essa chamada, sem tipo testado — tipa como `bool` e não baixa nada com sentido. É alcançável e não declarado:
```bp
val b = @is(1);   // hoje compila
```
- [ ] **(a)** Recusar `@is(…)` como chamada (`unknown-builtin`, apontando `x is T`):
```bp
val b = @is(1);   // error[unknown-builtin]: `@is` não é builtin — escreva `x is T`
```
- [ ] **(b)** Declará-lo (`is(value: unknown) -> bool`) e manter a chamada:
```bp
pub declare fn is(value: unknown) -> bool;
```

**Recomendação: (a).** `is` é um operador; uma forma de chamada que ninguém escreve e que não testa nada é a leitura mais frouxa. **Bloqueia:** a última linha de chamada builtin não declarada do passo 1 da 134.

### 17-b · O incremento por linha de um `Dict` com `keyed = true`
A frente 17 implementou o `keyed = true` (decisões 168 e 174): `counts.at(k)` lê uma linha (`ets:lookup`) e `counts = counts.insert(k, v)` escreve uma linha (`ets:insert`); dois processos escrevendo cada um a sua chave 20 000 vezes terminam em `20000 20000`. O que falta é um `+=` numa linha virar `ets:update_counter`. O `??` agora existe, então a forma abaixo **tipa** — mas continua recusada, porque recalcula a linha a partir do próprio var (a regra 5(b) da decisão 40):
```bp
#[@BeamMemory.Ets(keyed = true)]
var counts: Dict<string, i32> = Dict.empty();

counts = counts.insert(k, (counts.at(k) ?? 0) + 1);   // tipa; recusado: … can lose one of two concurrent runs
```
- [ ] **(a)** Nenhum: uma linha keyed se escreve inteira; um contador que vários processos incrementam é um `#[@BeamMemory.Ets] var n: i32` próprio (o incremento da decisão 40):
```bp
#[@BeamMemory.Ets] var hitsA: i32 = 0;
hitsA += 1;                                  // ets:update_counter
```
- [ ] **(b)** Um método da std `Dict.bump(key, by)` (valor inteiro; chave ausente conta de 0), comum num `Dict` normal e, sob `keyed = true`, `ets:update_counter(T, K, By, {K, 0})`:
```bp
counts = counts.bump(k, 1);
```
- [ ] **(c)** Atribuição por índice na gramática, com o mesmo lowering:
```bp
counts[k] += 1;
```
- [ ] **(d)** *(nova, agora que `??` existe)* Reconhecer exatamente a forma `counts.insert(k, (counts.at(k) ?? 0) + n)` e baixá-la para `ets:update_counter`, sem método nem gramática nova.

**Recomendação: (a).** Nenhum método ou gramática nova por causa de uma anotação; (b) põe no `Dict` um método cuja atomicidade só existe sob `keyed = true`, (c) cria um alvo de atribuição que a linguagem não tem, (d) faz uma forma escrita mudar de significado conforme o padrão. **Bloqueia:** a quarta caixa do passo 1 da 17.

### 17-c · O que mais pode nomear um var `keyed = true`
Hoje o var só aparece como `counts.at(k)` e `counts = counts.insert(k, v)`; todo o resto é recusado no identificador, e um var keyed nunca é `pub` (quem importasse leria o valor inteiro, que não existe):
```bp
@print(counts.size());     // error: `counts` is a `keyed = true` var: it is read one row at a time, as `counts.at(key)`
@print(counts["a"]);       // a mesma recusa — embora a decisão 63 diga que `d[k]` É `d.at(k)`
```
- [ ] **(a)** Só as duas formas, como está.
- [ ] **(b)** (a) mais `counts[k]`, lido como o `counts.at(k)` que a decisão 63 diz que ele é:
```bp
@print(counts["a"]);       // ets:lookup, como counts.at("a")
```
- [ ] **(c)** (b) mais `hasKey` (`ets:member`) e `delete` (`ets:delete`) como operações de linha, cada uma um primitivo novo no `std/beam`:
```bp
if (counts.hasKey("a")) counts = counts.delete("a");
```

**Recomendação: (a).** Uma grafia por operação de linha; (b) custa pouco, mas é uma segunda grafia da leitura; (c) aumenta a superfície que o checker e os dois emissores precisam manter iguais. **Bloqueia:** nada — o que está construído vale até ser ampliado.

### imp-a · Dois tipos com o mesmo nome importados com alias *(proposta)*
A decisão 170 torna legal importar dois nomes iguais com alias. O checker recusa isso para **tipos** (`import-name-collision`, célula `modules/import_two_types_one_name`), porque os backends não distinguem tipos por módulo:
```bp
import {m1.T as A};
import {m2.T as B};       // hoje: import-name-collision
```
- [ ] **(a)** Tipos continuam recusados: o alias da 170 vale só para valores.
- [ ] **(b)** Os backends qualificam tipos pelo módulo; a forma passa a valer.

**Recomendação: (b).** A 170 é regra sua; a recusa é limite de backend, guardado numa linha do `language-gaps.md` até ser construído. **Bloqueia:** nada aberto; uma linha da 01-checker.

### pkg-b · Um pacote importando a si mesmo pelo nome (`from "log"` dentro do próprio `log`)
A decisão 206 já está implementada (frente 129): `from` nomeia só pacote, e um módulo do próprio pacote vem pelo caminho entre chaves. Sobra um caso: os testes de um pacote importando o próprio pacote pelo nome. Hoje são 12 arquivos (log 1, routing 1, validation 2, std 8):
```bp
// libs/log/test/digest_test.bp
import {errorDigest} from "log";          // o próprio pacote log
```
- [ ] **(a)** Vale: é um pacote, e `from` nomeia pacote.
- [ ] **(b)** Recusa: dentro do pacote, é `import {digest.errorDigest};`, como qualquer outro módulo dele.

**Recomendação: (a).** O teste lê o pacote como um usuário de fora o lê — pela superfície pública —, que é o que um teste de pacote deve exercitar; (b) faria o teste ver também o que não é exportado. **Bloqueia:** nada (o caso está como item do passo 8 da `01-compiler/26`).

### 08-e2 · Quais modos a configuração das props da server island pode escolher
Você respondeu (decisão 224): configurável, com o mais seguro por padrão — **seladas** (`?p=<AES-256-GCM>`, ninguém lê nem altera). Falta dizer o que mais a chave `"islands": {"props": …}` do `onze.json` aceita. Isso esbarra na sua regra de sempre (decisão 67): nenhuma configuração que afrouxe uma regra (ver `ctr-b`).
```json
{ "islands": { "props": "sealed" } }     // padrão
```
- [ ] **(a)** `"sealed"` ou `"server"`: as duas mantêm as props secretas. `"server"` não põe nada na URL (`?id=9f3a…`, as props ficam guardadas no servidor), ao custo de o shell não ser cacheável entre instâncias. `"signed"` não existe.
- [ ] **(b)** `"sealed"`, `"server"` ou `"signed"`: com `"signed"` o visitante lê as props (base64 do JSON), mas não altera.
- [ ] **(c)** Só `"sealed"`: a chave existe para o futuro, mas hoje só aceita o padrão.

**Recomendação: (a).** Dá a escolha real (cache entre instâncias × nada na URL) sem nenhum modo que exponha as props; um `"signed"` é exatamente a configuração que afrouxa a regra. **Bloqueia:** 120 passo 4; 124 passos 1 e 3.

### 08-d · Quem faz o escopo do CSS
```
<style> h1 { color: red; } </style>        // dentro de um componente .bpp
```
- [ ] **(a)** A emilia: `scopeCss("c1a2", css)` → `h1[data-s-c1a2]{color:red}`, alcançada pela ponte `jhonstart-emilia`.
- [ ] **(b)** O onze-assets, no build: uma aplicação jhonstart sem onze fica sem estilos com escopo.
- [ ] **(c)** O jhonstart-html: um parser de CSS dentro da lib de HTML.

**Recomendação: (a).** **Bloqueia:** 119 inteira.

### 08-f · Onde moram Markdown e YAML
```
---
title: Hello
---
# Post
```
- [ ] **(a)** Os dois no novo membro `onze-content`.
- [ ] **(b)** Markdown no `onze-content`; YAML no std: `import {yaml} from "std";` e o leitor de config do rakun é apagado.
- [ ] **(c)** Um bundled `markdown`: `import {markdown} from "markdown";`.

**Recomendação: (b).** **Bloqueia:** 121 passo 3; uma linha para a 97.

### 08-h · Arquivo de config e comandos
- [ ] **(a)** `onze.json` e `onze dev | build | start | create`.
- [ ] **(b)** Um `bpp.json` e `botopink dev` / `botopink preview` no CLI do compilador.

**Recomendação: (a).** **Bloqueia:** 124.

### props-d · Os atributos de uma tag nativa *(proposta)*
A 192 cobre só tags de componente. Uma tag nativa hoje é `fn <tag>(children: Children, attrs: Array<#(string, string)> = [])`:
```bp
<a href={url} tabindex="x">…</a>
```
- [ ] **(a)** Os atributos de uma tag nativa são os campos de um tipo de props que o jhonstart declara por elemento (atributo desconhecido ou de tipo errado é recusado, como na 192).
- [ ] **(b)** Qualquer nome de atributo, valor `string` ou um buraco da 191.
- [ ] **(c)** Um conjunto global de atributos mais listas por tag, valores `string`.

**Recomendação: (a)** — uma regra para toda tag, a mais restritiva. **Bloqueia:** 118 passos 1 e 4.

### props-e · Slot nomeado *(proposta)*
A 193 nomeia só o campo `children`. O Astro escreve `<p slot="footer">` / `<slot name="footer">`.
- [ ] **(a)** Um slot nomeado é um campo de props do tipo `Node`, escrito como atributo:
```bp
<Card footer={<p>rodapé</p>}>corpo</Card>      // `slot="…"` recusado
```
- [ ] **(b)** `slot="footer"` num filho o encaminha para o campo `footer`.
- [ ] **(c)** Sem slots nomeados.

**Recomendação: (a)** — a 192 já cobre, sem um segundo mecanismo de encaminhamento. **Bloqueia:** as caixas de slot da 118 (passos 1 e 4).

### props-f · Spread num componente *(proposta)*
A 118 passo 1 recusa `{...expr}` num componente por um motivo que a 192 removeu (os atributos agora são campos de um único record).
```bp
<Card {...p} featured />
```
- [ ] **(a)** Continua recusado: os atributos são a forma.
- [ ] **(b)** `{...p}` com `p` do tipo de props, atributos explícitos sobrescrevendo.

**Recomendação: (a).** **Bloqueia:** 118 passo 1.

### 03r-ab · Front 09: stores de protocolo binário
```
RAKUN_DATA_URL=mongodb://localhost/app
```
- [ ] **(a)** Quatro braços no gate (`ets:memory`, `mnesia:`, `redis://`, Elasticsearch por HTTP); os binários recusam o boot.
  ```
  boot refused: `mongodb://` needs a byte type (lg2-a) and the mongodb driver
  ```
- [ ] **(b)** Escrever Mongo, Bolt, Cassandra e Couchbase em sidecars Erlang — quatro clientes de protocolo, uma frente cada.
- [ ] **(c)** Adiar o 09 inteiro.

**Recomendação: (a)**; o braço Elasticsearch sem aresta para o `rakun-client` (ver `ctr-w`). **Bloqueia:** 09 passos 4 e 7.

### 03r-ad · Pulsar: divisão do membro e o plano de dados
- [ ] **(a)** Dividir agora e adiar o plano de dados.
  ```
  modules/rakun-pulsar/                  # nomes de tópico, admin, checagens, codec CRC32C
  boot refused: a `pulsar://` listener needs the data plane (deferred)
  ```
  Dependências: `rakun`, `rakun-messaging`, `rakun-client` — e `rakun-data` (não `rakun-tx`, que a 187 funde; ver `ctr-d`). Separar o Pulsar tira só a aresta direta para o `rakun-client`; ela continua transitiva pelo `rakun-metrics`.
- [ ] **(b)** Dividir e escrever o plano de dados contra `rakun_pulsar_fixture.erl` (CONNECT, LOOKUP, produtores, consumidores, transações — semanas, protocolo escrito sem broker para comparar).
- [ ] **(c)** Deixar dentro do `rakun-messaging`.

**Recomendação: (a).** **Bloqueia:** 91 inteira.

### 03r-ae · SAML 2.0 ACS
- [ ] **(a)** Implementar Exclusive C14N no sidecar (`rakun_saml2.erl`, ~300 linhas) e fechar as três caixas com uma assertion assinada por uma chave versionada.
- [ ] **(b)** Aposentar o SP: `POST /saml2/acs` continua respondendo 501, com linha em `deferred.md`.

**Recomendação: (a)** — a 79 está no grupo A do rakun, então está escalada neste milestone; **(b)** só se ela sair dele. Nunca deixar a caixa aberta. **Bloqueia:** 79 passo 3.

### 03r-af · Os sete projetos de exemplo nunca construídos
- [ ] **(a)** Aposentar `rest-service`, `secured-api`, `blog-server`, `order-pipeline`, `observed-service`, `realtime-gateway`, `release-kit`; os três em disco (`rakun`, `rakun-container`, `rakun-ssr`) ganham `README.md`.
- [ ] **(b)** Construir os sete, uma frente cada.
- [ ] **(c)** Construir só o `rakun-rest-service`, como passeio no estilo Spring.

**Recomendação: (a).** **Bloqueia:** 73 passo 3.

### 03r-ak · Validar o SBOM contra o schema CycloneDX 1.5
- [ ] **(a)** Validador no teste.
  ```bp
  val schema = try json.decode(fs.readText("bom-1.5.schema.json"));
  asserts.equals(validateRequiredAndTypes(schema, sbom), []);     // ~120 linhas: `required` e `type`
  ```
- [ ] **(b)** Trocar a caixa por uma lista de campos afirmados pelo nome.
- [ ] **(c)** Um `json.schema` no std.

**Recomendação: (a).** **Bloqueia:** 81 passo 3.

### 03r-al · Transações de produtor Kafka
> **Medido na consolidação:** o broker em processo **já tem** transação de produtor com `read_committed`
> (e o termo de nomes de listener). A premissa da pergunta ("o broker não tem transação") está
> errada; o que sobra é amarrar o outbox ao `withProducerTransaction` (passo 5 da 15).
- [ ] **(a)** Usar a transação que o broker em processo já tem.
  ```bp
  val tx = broker.beginTx(); broker.publish(tx, "orders", msg);
  asserts.equals(consumer.poll(), []);       // read_committed: nada antes do commit
  broker.commitTx(tx);
  ```
- [ ] **(b)** Apagar as duas caixas.

**Recomendação: (a)**; o broker real vira linha em `deferred.md`. **Bloqueia:** 15 passo 5.

### 03r-am · Onde moram os dublês de broker e scheduler
- [ ] **(a)** Medir primeiro.
  ```
  rakun-test/botopink.json  + "rakun-messaging"
  $ botopink test            # em modules/rakun-messaging
  ciclo recusado → os dublês ficam em rakun-messaging/src/broker_double.bp e rakun-scheduling/src/task_double.bp
  ```
- [ ] **(b)** Acrescentar a aresta supondo que o loader já trata `<lib>-test` como escopo de teste.
- [ ] **(c)** Dublês no `rakun-test` alcançando os registries só por hooks do core (`rkOnReset`).

**Recomendação: (a)**, com a forma (c) em qualquer caso. **Bloqueia:** 19 passos 3 e 4.

### 03r-an · O transporte WebSocket do RSocket depois da 187 *(proposta)*
O transporte monta pelo `#[wsEndpoint]` do `rakun-websocket`; depois da 187 o RSocket mora no
`rakun-messaging`, então a aresta carregaria a árvore do `rakun-websocket` (security, data) para todo
consumidor de messaging. Hoje o transporte WebSocket é recusado no boot (só TCP).
- [ ] **(a)** Aceitar a aresta `rakun-messaging → rakun-websocket`.
- [ ] **(b)** O core define um ponto de extensão de transporte, em que o `rakun-websocket` se pluga (a regra da 185).
- [ ] **(c)** Manter a recusa; transporte WebSocket vira linha em `deferred.md`.

**Recomendação: (b).** **Bloqueia:** a primeira caixa do passo 2 da 92.

### 50-b · O que o `onze dev` faz numa mudança
```
$ onze dev        # e você salva app/blog/page.bp
```
- [ ] **(a)** Reinicia o nó: `build` + `start` em laço, 1–3 s por edição; serve os mesmos bytes que o `start`.
- [ ] **(b)** Hot-load: `code:load_file` do módulo mudado, sem reiniciar; um arquivo de rota novo exige regenerar o `onze_routes`.
- [ ] **(c)** (b), caindo para (a) quando muda um arquivo de convenção (`page`, `layout`, `route`).

**Recomendação: (a)**, a mais restritiva. **Bloqueia:** 50 passo 2; 53 passo 6 ("`dev` serve toda rota" — a spec inglesa ainda diz passo 5).

### std-d · `io.process`: sinais e leitor de TTY
- [ ] **(a)** O std ganha as três células.
  ```bp
  process.forwardSignals(child);
  val name = io.stdin.readLine();           // `onze create` pergunta o nome do projeto
  ```
- [ ] **(b)** Nada no std.
  ```
  $ onze start            # faz exec do node: o bin/onze é PID 1 e recebe o SIGTERM direto
  $ onze create           # sem --yes:
  error: `onze create` needs --name and --template (or --yes)
  ```

**Recomendação: (b)**, a mais restritiva. **Bloqueia:** onze 50; 97 passo 6.

### 67-a · Onde as caixas de forms do lado do DOM são afirmadas
- [ ] **(a)** No gate do próprio jhonstart, com o documento falso.
  ```bp
  // jhonstart-dom-test/test/forms_dom_test.bp
  val form = dom.form("signup"); form.submit();
  asserts.equals(dom.text("#email-error"), "invalid email");
  ```
  E de novo no browser do onze 53.
- [ ] **(b)** Só no browser do onze 53: o gate do jhonstart nunca roda essas cinco caixas.
- [ ] **(c)** Uma lib de DOM real como dependência de dev.

**Recomendação: (a).** **Bloqueia:** a forma dos passos 1–3 da 67.

### 05emilia-n · As linhas do Tailwind sem dono
```
theme: --breakpoint-md limpo   → hoje emite `@media (width >= )`
```
- [ ] **(a)** Só a recusa: `panic: breakpoint "md" was cleared`; as quatro features ficam fora e se escrevem com `arbSel("…")`.
- [ ] **(b)** (a) + translate negativo e grupos/peers nomeados.
  ```bp
  [.TranslateY.Neg.2]            // -translate-y-2
  [.Group.Named("item").Hover]   // group-hover/item
  ```
- [ ] **(c)** As cinco, inclusive `@theme inline` (um segundo modo de render em todo site de `var()`).

**Recomendação: (a)**; (b) se você quiser alguma feature. A recusa em si não é opcional (decisão 67). **Bloqueia:** 34 passo 4.

### 07-g · Renderização de release OTP
Hoje `rakun-release/release.bp` (depois do 128, `rakun-cli/src/release/`) e `onze-release/otp.bp` escrevem o mesmo `.rel` / `vm.args` / `sys.config`.
- [ ] **(a)** Um bundled `release` de renderizadores puros.
  ```bp
  import {rel, vmArgs, sysConfig} from "release";
  fs.writeText(path.join([out, "onze.rel"]), rel(spec));
  ```
- [ ] **(b)** Feature do CLI: `botopink release --out dist/`.
- [ ] **(c)** Deixar os dois como estão.

**Recomendação: (a).** **Bloqueia:** 107-release.

### 07-j · Quanto do Zod entra na 125
Os passos 0–2 (`Schema<T>`, `#[schema]`, `parse<T>`) já estão na `feat`.
- [ ] **(a)** Só os marcadores.
  ```bp
  type Signup(#[email] email: string, #[min(8)] password: string)
  ```
- [ ] **(b)** Marcadores + `parse<T>` de records planos.
  ```bp
  #[schema] type Signup(…)
  val s = try parse<Signup>(json);
  ```
- [ ] **(c)** Tudo: uniões, tuplas, mapas, coerção, transforms, codecs, `jsonSchemaOf<T>`.
  ```bp
  val form = try bind<Signup>(pairs);            // de pares de formulário
  val schema = jsonSchemaOf<Signup>();
  ```

**Recomendação: (c)**, na ordem dos passos (e com as saídas como membros, ver `ctr-u`). **Bloqueia:** o tamanho da 125 (passos 3–10).

- [ ] Confirmo a recomendação em todas desta parte
- [ ] Quero rever: ___

---

## Parte 4 — Não bloqueiam nada hoje

Regras para o próximo caso, confirmações e recursos de linguagem que ficam de fora por padrão.

### 07-b · "Uma lib, três cópias divergentes" também justifica pacote?
```
rakun:  request_context.bp · csrf.bp · session_cookie.bp     três leitores de `Cookie:`, só dentro do rakun
```
- [ ] **(a)** Não: vale só "duas ou mais libs" (decisão 115). As três cópias viram um módulo do core do rakun (ou do std): `import {cookie} from "rakun";`.
- [ ] **(b)** Sim: três cópias divergentes numa lib só já abrem um pacote bundled: `import {cookie} from "http";`, mesmo com um único consumidor.

**Recomendação: (a).** Não bloqueia nada hoje (o `http` da 104 já existe e o rakun passa a usá-lo no passo 5 dela).

### 07-h · Bundled, ou um repositório compartilhado à parte?
- [ ] **(a)** Bundled: `import {cookie} from "http";` sem nenhuma linha em `dependencies`; versão = a do compilador.
- [ ] **(b)** Repositório `botopink/common`:
  ```json
  "http": { "git": "git@github.com:botopink/common.git", "subdir": "http" }      // precisa do lg2-v (2)
  ```

**Recomendação: (a).** **Bloqueia:** a forma da trilha.

### std-e · Hooks de ciclo de vida de teste
- [ ] **(a)** Sem hooks (hoje).
  ```bp
  test "a" { resetSingletons(); … }
  test "b" { resetSingletons(); … }
  ```
- [ ] **(b)** Decorators.
  ```bp
  #[before] fn setup() { resetSingletons(); }
  test "a" { … }
  ```
- [ ] **(c)** Bloco na gramática.
  ```bp
  beforeEach { resetSingletons(); }
  ```

**Recomendação: (a).**

### 95-f · A tomada do onze aconteceu sem o branch órfão e sem arquivar nada
- [ ] **(1) ★** Confirmar a árvore como está.
  ```
  $ git -C repository/onze tag            → mocking-lib-final     # a lib antiga vive como histórico tagueado
  $ git -C repository/onze log --oneline  → o orquestrador em cima dessa tag, mesmo remoto
  ```
- [ ] **(2)** Reescrever o remoto para o branch órfão e arquivar o histórico antigo (`git push --force`; todo checkout de `repository/onze` reclona).

**Recomendação: (1).**

### 07-i (revisão) · A proibição de nomes repetidos em pacotes bundled continua depois do alias?
A decisão 163 proíbe um pacote bundled de exportar um nome que o std ou um framework já exporta "até
a linha do toolchain fechar". A decisão 170 (import que diz o módulo nunca é ambíguo; alias quando o
módulo precisa dos dois) é o que fecha essa linha.
- [ ] **(a)** Continua proibido: pacote bundled novo escolhe nome que não colide.
  ```bp
  import {cookie} from "http";          // o pacote se chama `cookie`, nunca `cookies`
  ```
- [ ] **(b)** Cai a proibição: o pacote usa o nome natural e quem importa os dois usa alias.
  ```bp
  import {cookies as httpCookies} from "http";
  import {cookies as rkCookies} from "rakun";
  ```

**Recomendação (desta revisão): (a).** Um pacote novo escolher um nome livre não custa nada, e o alias fica para o caso em que o nome natural é do std (decisão 170). Vale também para o 103: o pacote usa `deriveActionId`, porque o `rakun-app` já exporta `actionId`.
**Bloqueia:** nada; as frentes 102 e 103 já escolheram nomes livres.

### 110-a · O `testing.asserts` no wasm, depois da regra estrita (decisão 146)
Com a regra estrita, um programa wasm que importa `testing.asserts` é recusado: quatro das 27 funções
dele chegam a uma célula host que não tem versão wasm.
```bp
import {testing.asserts} from "std";      // --target wasm
// error: `canonical` has no `#[@External.<Target>(…)]` for the wasm backend — in `std/testing/asserts`, which this import links
```
```
deepEquals → canonical        matches → regexMatches        throws, throwsWith → tryCatch
usos nos repositórios: throwsWith 280 · throws 4 · deepEquals 2 · matches 1 · 133 arquivos importam o módulo
```
- [ ] **(1) ★ como está** O `asserts` não é importável no wasm. Duas células de linguagem viraram recusa fixada no wasm.
- [ ] **(2)** As quatro funções com célula host vão para um módulo próprio; as outras 23 voltam a importar no wasm.
  ```bp
  import {testing.asserts} from "std";            // equals, isTrue, contains… — importa no wasm
  import {testing.asserts_host} from "std";       // deepEquals, matches, throws, throwsWith — nome ilustrativo
  ```
  Muda a API do `asserts` (decisão 74) e o import de cada um dos arquivos que usam as quatro.
- [ ] **(3)** As três células ganham versão wasm. Precisa de um leitor de `@External.Wasm` no backend (decisão 238 já existe), de um motor de regex no prelude wasm para `regexMatches`, e de `@panic` capturável para `tryCatch` (hoje é `unreachable`).

**Recomendação (da thread): (1) agora**; a (2) se o wasm precisar rodar asserções — é a única que não espera a 05-wasm.
**Bloqueia:** nada no gate; só o "std compila no wasm" do 05-wasm passo 5 / 97 passo 11.

### lg2-a … lg2-w · Recursos que as bibliotecas pediram e a linguagem não tem
A recomendação em todas é a **(1)**: o recurso fica de fora e a forma mais próxima que já existe
é o desenho. Nenhuma frente abre sobre uma delas até ser respondida. A **lg2-k** (reflexão comptime
sobre o projeto) saiu daqui: foi respondida pelas decisões 216 e 253 (`@TypeInfo.all`).

**lg2-a · Tipo byte**
```bp
val b: Bytes = "a";                       // hoje: type mismatch em todo target
```
- [ ] **(1)** Sem tipo byte: `POST /upload` com corpo binário → 415 na borda; nada lê bytes como texto.
- [ ] **(2)** `Bytes` com fronteira explícita: `val b = Bytes.fromUtf8("a"); val s = try b.toUtf8();` — nenhuma conversão implícita.
- [ ] **(3)** `string` carrega bytes crus: `sock.recv()` devolve UTF-8 quebrado, como hoje.

Custa: uploads, downloads, imagens; Mongo/Bolt/Cassandra/Couchbase e o plano de dados do Pulsar no rakun.

**Recomendação: (1).** Um payload binário é recusado onde entra, nunca lido com perda. Se você escolher a (2): nenhuma conversão sem uma chamada que pode falhar; a (3) continua recusada.

**lg2-b · O que `@Task<T>` significa no BEAM**
```bp
val a = async.delay(300, 1); val b = async.delay(300, 2);
await a; await b;                         // erlang/beam: ≥ 600 ms · commonJS: ~300 ms
```
- [ ] **(1)** Task é só "valor que ainda não chegou"; concorrência é o `async.runAll([{ -> … }, { -> … }])` explícito. O exemplo continua 600 ms no BEAM, documentado.
- [ ] **(2)** Um processo por Task no BEAM: o exemplo passa a levar ~300 ms.
- [ ] **(3)** `spawn` / `join` na linguagem: `val h = spawn work(); join h;`

**Recomendação: (1).** O tipo promete o valor, nada sobre sobreposição; a única forma concorrente continua sendo a explícita.

**lg2-c · Decorator que reescreve ou embrulha o corpo**
```bp
#[cached] fn load(id: i32) -> User { … }
```
- [ ] **(1)** Não: o decorator emite um proxy ao lado (`loadCached`) e `load` continua fazendo o que está escrito.
- [ ] **(2)** O decorator recebe o corpo e devolve o que o substitui: chamar `load(1)` passa pelo cache.
- [ ] **(3)** Ganchos fixos: `#[around(cacheHook)]`, compostos pelo compilador.

**Recomendação: (1).** Ler uma declaração nunca muda o que ela faz; os tipos proxy que o rakun entrega são o desenho.

**lg2-d · Decorator que lê o corpo**
```bp
fn saga(comptime decl: @Decl) { decl.body }      // hoje: {error,{badkey,body}}
```
- [ ] **(1)** Só assinaturas: a saga é um valor `[step(charge, refund), step(ship, cancel)]`.
- [ ] **(2)** `decl.body` como árvore de statements somente-leitura.
- [ ] **(3)** Uma API comptime de percorrer corpo: `decl.walk({ stmt -> … })`.

**Recomendação: (1).** Um decorator lê assinaturas, não corpos.

**lg2-e · Dono e parâmetros num `@Decl` de método**
```bp
type UserController { #[get("/u/:id")] fn show(self, id: i32) … }
fn get(comptime decl: @Decl, path: string) { decl.owner; decl.params }     // hoje: badkey
```
- [ ] **(1)** Marcador de método só marca; quem lê os parâmetros é o decorator do tipo (`#[controller] type UserController`).
- [ ] **(2)** `decl.owner` e `decl.params` existem no método.

**Recomendação: (1).** Nada novo chega a um decorator de método; o decorator do tipo já vê todos os parâmetros.

**lg2-f · Argumento de decorator que nomeia um tipo**
- [ ] **(1)** Pelo nome em string: `#[onMissing("MailSender")]`.
- [ ] **(2)** Parâmetro do tipo `type`: `#[onMissing(MailSender)]`, checado na anotação.

**Recomendação: (1).** Nenhum tipo-de-tipo entra na linguagem por causa de uma família de anotações.

**lg2-g · `@typeName<T>()`**
- [ ] **(1)** Sem intrínseco: `resolve<User>("User")` — a chave viaja como string ao lado de `T`.
- [ ] **(2)** `resolve<User>()` e, dentro, `@typeName<T>()` responde `"User"`.

**Recomendação: (1).** A chave do registro continua uma string ao lado de `T`.

**lg2-h · Raise e catch por tipo**
- [ ] **(1)** O erro é o `E` do `@Result`, lido com `case`:
  ```bp
  val u = try load(p) catch { e -> case e { .NotFound -> defaultUser(); _ -> throw e; } };
  ```
- [ ] **(2)** Um braço de `catch` por tipo: `try load(p) catch { e: NotFound -> … }`.
- [ ] **(3)** Exceções host tipadas: um erro do Erlang chega como um `E`.

**Recomendação: (1).** É a decisão 121 como escrita: o erro é o `E` do `@Result`.

**lg2-i · Argumento de decorator é lexema cru**
```bp
fn grid(comptime decl: @Decl, sizes: Array<i32> = [1, 2])     // hoje: sizes.length == 6 (é o texto "[1, 2]")
```
- [ ] **(1)** Recusar na declaração todo parâmetro de decorator que não seja `string`, número ou `bool`.
- [ ] **(2)** Argumentos tipados: `sizes.length == 2`.

**Recomendação: (1).** O caminho do lexema continua exato para os três tipos que trata, e nenhum outro finge ser tipado.

**lg2-j · Estado comptime entre invocações de decorator**
```bp
var seen: Array<string> = [];
fn register(comptime decl: @Decl) { seen.push(decl.name); }   // hoje: erro na anotação
```
- [ ] **(1)** Cada invocação é independente; a lista de registros vem de `@TypeInfo.all` (decisões 253/256).
- [ ] **(2)** Estado mutável comptime por compilação: `seen` acumula (a ordem de visita passa a importar).

**Recomendação: (1).** A resposta de um decorator depende só da declaração dele, então a ordem em que o compilador visita as declarações nunca muda um build.

**lg2-l · `noreturn` é tipo-fundo?** (talvez já respondida de fato: `@panic` / `@todo` estreitam)
```bp
pub fn notFound() -> noreturn { raise("…"); }
```
- [ ] **(1)** Não unifica com nada: `notFound();` é um statement que encerra o caminho; `throw notFound();` e `val s: string = notFound();` são erro.
- [ ] **(2)** É o tipo-fundo: `val s: string = notFound();` e `{ -> notFound() }` checam.

**Recomendação: (1).** Um sinal nunca é um valor. **Bloqueia:** os sinais do jhonstart e os testes de navegação do rakun.

**lg2-m · Anotação de módulo**
- [ ] **(1)** Não: a política do módulo é um `pub val useCache = true;`.
- [ ] **(2)** Atributo interno no topo do arquivo: `#![useCache]`.

**Recomendação: (1).** A política de um módulo é um `val` de módulo.

**lg2-n · Thunk convertido em `Node`** (o `Children` virou `Node` pela decisão 223)
```bp
show({ -> "x" })          // hoje: expected Node, got function
```
- [ ] **(1)** Não: o filho adiado é um campo nomeado da fronteira, `Suspense(fallback: …, content: { -> … })`.
- [ ] **(2)** `fn() -> Element` converte em `Node`: a linha acima compila.

**Recomendação: (1).** As coerções que o compilador conhece continuam três (array, `Element`, `string`).

**lg2-o · Acesso a arquivos no comptime**
- [ ] **(1)** Não: o `.bp` gerado é versionado (`rakun ws generate` roda antes e o resultado entra no repositório).
- [ ] **(2)** Leitura isolada de entradas declaradas: `#[wsdl("schema.wsdl")]` lê o arquivo durante a compilação, e ele entra na chave do cache.

**Recomendação: (1).** Um build lê só os seus fontes. **Bloqueia:** frentes 88, 93.

**lg2-p · Cancelamento**
```bp
val r = await async.race([slow(), fast()]);     // hoje: slow() roda até o fim
```
- [ ] **(1)** Nenhum: o trabalho perdedor termina e o resultado é descartado, documentado.
- [ ] **(2)** Tokens explícitos: `slow(token)` consulta `token.cancelled()`.
- [ ] **(3)** Processos ligados no BEAM: o perdedor é morto.

**Recomendação: (1).** Em linha com a `lg2-b` (1).

**lg2-q · Localização no fonte dentro de `@Decl`**
- [ ] **(1)** Não: o segmento é argumento explícito, `#[page("blog/[slug]")]`.
- [ ] **(2)** `decl.loc.file`: `#[page]` deduz a rota do caminho do arquivo.

**Recomendação: (1).** A saída de um decorator nunca depende de onde o arquivo está.

**lg2-r · Corpo fornecido por um decorator para um método declarado**
```bp
type Users { #[query("select * from users where id = $1")] declare fn find(id: i32) -> ?User; }
```
- [ ] **(1)** Método sem corpo é só binding host; o decorator emite um helper e o método tem corpo: `fn find(id: i32) -> ?User { return findQuery(self, id); }`.
- [ ] **(2)** O decorator fornece o corpo: a declaração acima basta.

**Recomendação: (1).** É o que a recusa de hoje já impõe (`run/bodyless_method_without_binding`).

**lg2-s · Reflexão do grafo de módulos**
- [ ] **(1)** Não: o `importsOf` do onze-bundler continua uma varredura textual que falha alto.
- [ ] **(2)** `decl.imports` num `@Decl` de módulo.

**Recomendação: (1)** — mas o argumento antigo ("em linha com a `lg2-k`") caiu, porque a `lg2-k` foi respondida ao contrário; ver `ctr-m`.

**lg2-t · Folha de enum numérica negativa**
```bp
type Tok { Rotate { 12, -12 } }          // hoje: erro no `-`
```
- [ ] **(1)** Não: `Rotate { 12, Neg { 12 } }`, escrito `.Rotate.Neg.12`.
- [ ] **(2)** Folha com sinal: `.Rotate.-12`.
- [ ] **(3)** `-` unário num caminho de enum: `-(.Rotate.12)`.

**Recomendação: (1).** O nome de uma folha continua um nome.

**lg2-u · Decorator em posição de expressão**
- [ ] **(1)** Não: trabalho em expressão é uma chamada, `val x = traced(compute());`.
- [ ] **(2)** `val x = #[traced] compute();`.

**Recomendação: (1).** Um decorator anota uma declaração; trabalho em expressão é uma chamada.

**lg2-v · Subdiretório numa dependência git**
- [ ] **(1)** Não: dependência git é a raiz de um repositório; membro de monorepo só por `path`.
  ```json
  "rakun-web": { "path": "../rakun/modules/rakun-web" }
  ```
- [ ] **(2)** Campo `subdir`:
  ```json
  "rakun-web": { "git": "git@github.com:botopink/rakun.git", "subdir": "modules/rakun-web" }
  ```
Custa: nenhum starter `rakun-*` instala por git fora do checkout meta; segura o `07-h` e o 98 passo 4.

**Recomendação: (1).** Se você escolher a (2): `subdir` só vale junto com `git`, e um que escape do checkout (`..`) é recusado.

**lg2-w · Função host chamada do corpo de um decorator**
```bp
fn route(comptime decl: @Decl, path: string) { @emit("…" + json.quote(path)); }     // hoje: undefined function quote/1
```
- [ ] **(1)** Corpo comptime só chama funções com corpo; a chamada host é recusada, localizada, em todo target.
- [ ] **(2)** A célula Erlang viaja para o módulo do decorator no runtime BEAM; no runtime wat a chamada é recusada.
- [ ] **(3)** Decorator que alcança célula host sempre roda no runtime BEAM, qualquer que seja o target.

**Recomendação: (1).** A resposta de um decorator nunca depende de qual runtime o target escolheu (decisão 84). **Bloqueia:** frente 16 (`#[scheduled]`).

- [ ] Confirmo a recomendação em todas desta parte
- [ ] Quero rever: ___

---

## Parte 5 — Escolhas que as threads fizeram (★), para confirmar

Cada uma já está no código da `feat` (as frentes 110–113 entraram e fecharam na 1.0.11). Confirmar não
muda nada; marcar a alternativa vira trabalho para a frente dona (hoje, a `00-gate/114` ou a dona do
arquivo).

### 111-b ★ · O carregador de sidecars no beam só é emitido quando o build liga uma função host
- [ ] **(a) ★** Um programa sem `#[@External.Erlang]` / `#[@External.Beam]` não ganha a chamada ao carregador; 13 snapshots mudaram.
  ```
  '_botopink_main'/0:   (sem __bp_load_siblings)      # programa sem binding host
  ```
- [ ] **(b)** Todo módulo de entrada chama o carregador, haja sidecar ou não: uma forma só de emissão, e 219 snapshots de beam regravados (×2 runtimes).

**Recomendação: (a) ★.** O programa que não tem sidecar não paga por um carregador.

### 111-c ★ · `botopink build --target beam` dispara um `erl`, como o build erlang
- [ ] **(a) ★** O build beam roda a mesma sondagem de módulo host que o build erlang (~0,25 s) e sai com 1 se o `erl` falhar; `botopink run --target beam` passou a executar o programa.
  ```
  $ botopink build --target beam      # sidecar que não compila
  error: … does not compile - refusing to run            (exit 1)
  ```
- [ ] **(b)** O build beam não chama o `erl`: termina mesmo sem OTP instalado, e um sidecar quebrado só aparece ao rodar.

**Recomendação: (a) ★.** Falhar no build é mais restritivo do que falhar ao rodar.

### 113-a ★ · Pedir um target que o `botopink test` não roda falha o `test-libs`
```
$ zig build test-libs -- --target wasm        # botopink test só roda commonJS e erlang
```
- [ ] **(a) ★** `NOT RUNNABLE`, e o comando sai com erro. É a regra de `fronts.md`: uma célula que reporta "skipped" é vermelha.
- [ ] **(b)** Reportar `skipped` e sair com 0, como era antes da 113.

**Recomendação: (a) ★.** Falhar é mais restritivo do que pular.

### 113-b ★ · A auditoria de restrições reconhece a recusa pelo texto, porque ela não tem id
A regra da decisão 156 aceita uma exclusão só quando o build do target excluído é recusado por falta
de binding host. Essa recusa do compilador não tem id de erro, então a auditoria compara o texto fixo
``has no `#[@External.<Target>(…)]` for the <backend> backend``.
- [ ] **(a) ★** Comparar pelo texto. Se o compilador mudar a frase, toda auditoria vira "não estrutural" e o `test-libs` falha — o erro aparece, não passa em silêncio.
- [ ] **(b)** A recusa ganha um id (por exemplo `error[external-missing]`) no compilador, e a auditoria compara o id. É trabalho da `01-compiler`.

**Recomendação (desta revisão): (b)**, como linha da `01-compiler/07-residuals`; a (a) fica valendo até lá.

### 110-b ★ · O histórico de contagens saiu do `tests/language/AGENTS.md`
Para o texto `expected-failures` sumir de todo o repositório (decisão 154), a thread apagou a seção
"registro das frentes anteriores": cerca de 480 linhas de contagens antigas.
- [ ] **(a) ★** Apagado. O arquivo diz o estado atual dos quatro targets.
- [ ] **(b)** Recuperar esse histórico do git para um arquivo à parte (por exemplo `tests/language/HISTORY.md`).

**Recomendação: (a) ★.** A convenção das specs é estado atual, sem narrativa; o histórico continua no git.

### 112-a ★ · O que o `format-check` percorre
- [ ] **(a) ★** `TREES` tem `examples` como uma entrada só (pega `examples/hello.bp` e qualquer exemplo novo) e ganhou `modules/manifest/tests`; todo `.bp` rastreado está coberto ou isento por estrutura (508 + 173 `reject/` + 1 = 682).
- [ ] **(b)** Voltar às quatro pastas de exemplo nomeadas, mais `examples/hello.bp` numa linha própria.

**Recomendação: (a) ★.** Um exemplo novo já nasce verificado.

### 103-a ★ · O nome da função do pacote `actions.id` *(da consolidação)*
- [ ] **(a) ★** `deriveActionId(secret, module, name, buildId)` no pacote; o `actionId` do `rakun-app` continua e passa a envolvê-lo.
- [ ] **(b)** O pacote se chama `actionId` e o `actionId` do `rakun-app` é apagado no passo 2 da 103.

**Recomendação: (a) ★** — nome livre (decisão 163 / 07-i).

- [ ] Confirmo as sete como estão
- [ ] Quero rever: ___

---

## Parte 6 — Escolhas já implementadas na 1.0.10, ainda sem confirmação

Cada item abaixo já está no código com a opção ★. O exemplo mostra o que você escreve e o que
acontece hoje; a linha "Alternativa" é o que mudaria se você revertesse. O texto medido de cada uma
está em `specs/1.0.10-beta/decisions-pending.md` (procure pelo id); a 1.0.12 já traz cada uma numa
linha em `decisions-pending.md` § Implementation choices. Saíram daqui por já estarem resolvidas:
**23-a** e **01std-d** (a alternativa delas entrou no código) e **26-b** (respondida pela decisão 186).

### As duas em que recomendo a alternativa

**lem-b · `inline = true` num método de tipo**
```bp
type Sock { #[@External.Erlang("gen_tcp:recv($self, 0)", inline = true)] declare fn recv(self) -> string; }
```
- [ ] **(a) ★** Aceito e ignorado: compila, e o método não é inlinado.
- [ ] **(b)** O checker recusa: `error: inline is not available on a type method`.

**Recomendação: (b)**, a mais restritiva.

**03r-b · `rkPropInt("12abc")`**
```
server.port=8080x
```
- [ ] **(a) ★** `rkPropInt` devolve `8080` (pega os dígitos do começo); o servidor sobe.
- [ ] **(b)** Erro de config: `server.port: "8080x" is not an integer`; o boot é recusado.

**Recomendação: (b).**

### Compilador

**24-a ★ · Os códigos de diagnóstico de efeito que sobraram**
```bp
fn f() { try g(); }       // error[effect-try-without-fallible-channel]
fn h() { throw "x"; }     // o mesmo código: o do `throw` foi fundido nele
```
`effect-missing-annotation` e os outros códigos de anotação foram apagados;
`for-over-future-generator` virou `for-over-stream`.
Alternativa: um código separado para o `throw` (`effect-throw-without-fallible-channel`).

**Recomendação: manter ★.**

**24-b ★ · Os métodos de `@Task`**
```bp
val t: @Task<i32> = load();
t.map({ n -> n + 1 })           // existe
t.then({ n -> loadMore(n) })    // existe (é o bind)
t.flatMap({ n -> loadMore(n) }) // não existe: uma grafia por operação
```
Os dois estão declarados; nenhum backend os baixa ainda.
Alternativa: `flatMap` como apelido de `then`.

**Recomendação: manter ★.**

**24-c ★ · `iter for` / `iter while` são um `loop` com prefixo**
```bp
iter for (xs) { x -> yield x * 2; }      // lido como: iter loop { for (xs) { x -> yield x * 2; }; break; }
iter loop :l { yield :l 1; }             // o label nomeia o gerador
iter for :l (xs) { x -> break :l; }      // o label nomeia o `for` escrito; `yield :l` aqui é yield-label-not-generator
```
Alternativa: um nó novo `GenLoop`, com um lowering próprio em cada um dos quatro backends.

**Recomendação: manter ★.**

**24-g ★ · A forma do `std/async` com uma Task que nunca falha**
```bp
val users = try await async.allOf([fetchUser(1), fetchUser(2)]);   // Tasks já iniciadas de @Result: para no primeiro Error
val xs = await async.runAll([{ -> work(1) }, { -> work(2) }]);     // thunks: é aqui que há concorrência
val r = await async.timeout({ -> slow() }, 100);                   // estourou → Error("timeout"), uma string
```
`allSettled`, `settleOf`, `unwrapAll` e `attempt` foram removidos.
Alternativa: `allOf` sobre thunks (`async.allOf([{ -> fetchUser(1) }])`), como a 01-std/02 escreveu.

**Recomendação: manter ★.**

**01c-a ★ · O átomo de um módulo comptime**
```
bp@comptime@<caminho do dono>__tpl__<decl>__<hash>     ★ pacote reservado `bp`; nenhum átomo de usuário colide
jhonstart@html__tpl__html__<hash>                      alternativa: no namespace do pacote dono
```

**Recomendação: manter ★.**

**01c-b ★ · Folha de seção com o atalho de ponto**
```bp
val t: Token.Text = .Bold;      // compila: a posição diz qual é a seção
val u = .Bold;                  // recusado, nomeando a seção (não há tipo esperado)
```
Alternativa: nenhum atalho para folha de seção — sempre `Token.Text.Bold`.

**Recomendação: manter ★.**

**ck2-a ★ · `@module()` é recusado até um target o baixar**
```bp
val m = @module();      // error[builtin-not-lowered] no `@`
```
Antes: o commonJS emitia `@module()` cru (`SyntaxError` ao carregar) e o erlang chamava um `module/0` que não existe.
Alternativa: apagar a declaração de `builtins.d.bp` (vira `unknown-builtin`); ou especificar o valor e baixá-lo.

**Recomendação: manter ★ agora;** apagar a declaração de `builtins.d.bp` se nenhuma frente precisar do valor — um nome declarado sem significado é uma promessa que o compilador não cumpre.

**ck2-b ★ · Um membro de seção pode ter o nome de uma variante de topo do mesmo enum**
```bp
// Token declara `After(inner: Token[])` e também `Layout.Break { After }`
Token.After([…])                         // a variante com payload
val b: Token.Layout.Break = .After;      // a folha da seção
```
Alternativa: recusar na declaração (`enum-section-member-shadows-variant`) — a emilia renomeia onze membros (`Sm`, `Md`, `Lg`, `Xl`, `X2xl`, `Alpha`, …).

**Recomendação: manter ★.**

**ck2-d ★ · Label na chamada de um valor-função**
```bp
fn apply(f: fn(i32, string) -> string) -> string {
    return f(n: 1, s: "x");      // error[label-on-function-value]
}
```
Antes: os labels eram ignorados e `f(s: "x", n: 1)` queria dizer `f("x", 1)`, em silêncio.
Alternativa: tipos de função carregam nomes (`fn(n: i32, s: string)`) e o label tem de bater.

**Recomendação: manter ★.**

**ck2-e ★ · Um decorator do std é alcançado pelo módulo**
```bp
import {testing.mocks} from "std";
#[mocks.mock]                               // compila: o código emitido usa o handle `mocks`
import {testing.mocks.mock} from "std";     // error[std-decorator-leaf-import]
```
Alternativa: permitir o import folha (`#[mock]`), com os nomes emitidos resolvidos no módulo do decorator.

**Recomendação: manter ★ agora.** A alternativa é a resposta geral para o decorator de qualquer lib, e precisa que a decisão 112 diga que cobre `@emit`.

**rc3-b ★ · `unknown` é a grafia do vocabulário host depois que `any` saiu**
```bp
val v = erlang.element(1, t);       // o parâmetro é `unknown`: aceita o i32 (com `any` era recusado)
if (v is string) { @print(v); }     // e o resultado é testado com `is` antes de usar
```
Alternativa: um tipo opaco `HostTerm`; ou um tipo botopink por declaração (`abs(n: i64) -> i64`).

**Recomendação: manter ★.** Um tipo botopink por declaração é o refinamento em que o vocabulário host pode crescer, uma declaração de cada vez.

**rc3-c ★ · Atribuir a um `var` estreitado**
```bp
var x: ?Node = head;
while (x != null) { x = x.next; }     // compila: a atribuição checa contra `?Node`…
if (x != null) { x = x.next; x.value; }   // …e encerra o estreitamento: `x.value` é recusado
```
Alternativa: flow typing (o nome fica com o tipo do valor atribuído); ou proibir a atribuição dentro do escopo estreitado (recusa o percurso de lista ligada).

**Recomendação: manter ★.**

**16-a ★ · A lista de argumentos quebra junto com o que a envolve**
```bp
assert doc.indexOf("…um argumento comprido…")
    != -1;                 // o binário quebra primeiro; a lista é medida na própria linha
```
Alternativa (lista habilitada sozinha): ~1 480 de ~2 770 listas abriam pelo que vinha depois delas:
```bp
assert doc.indexOf(
    "…um argumento comprido…",
) != -1;
```

**Recomendação: manter ★** (cobre também a metade "sem vírgula" da 166, ver `ctr-s`).

**16-b ★ · Array aberto: um elemento por linha**
```bp
val xs = [
    1,
    2,
    3,
];
```
Alternativa: `fill` (quantos couberem por linha) — o resultado passa a depender de como o fonte estava quebrado.

**Recomendação: manter ★.**

**23-b ★ · As quatro funções do `base64` foram aposentadas**
```bp
val s = try encoding.base64Decode(text);     // @Result<string, string>: valida antes de decodificar
base64.decode(text)                          // não existe mais
```
Alternativa: manter `decode` / `encode` no `encoding` como apelidos que devolvem `string` (escondem a recusa).

**Recomendação: manter ★.**

**23-c ★ · `botopink test` num projeto com módulos em pasta**
```
src/top.bp   src/io/rec.bp
$ botopink test --target erlang       # passa (antes: testes morriam com {error,undef}; no commonJS o módulo de pasta era recusado)
```
Alternativa: manter o std plano no disco e aninhar só as chaves do registro.

**Recomendação: manter ★.**

**0405-b ★ · O vazio imprime `null` no commonJS**
```bp
val r = if (n > 0) { "positive"; };
@print(r);                        // n = 0 → null   (antes: undefined)
@print(choose(false)?.kind);      // null
```
Alternativa: baixar o `?.` e o `if` sem `else` para produzirem `null` (move todo site de `?.`).

**Recomendação: manter ★.**

**A regra da divisão inteira ★**
```bp
7 / 2        // 3
-7 / 2       // -3      trunca em direção a zero, nos quatro targets
7.0 / 2.0    // 3.5     divisão de float continua float
```

**Recomendação: manter ★.**

### libs-external-methods

**lem-a ★ · Um método host é um método de verdade**
```bp
type Sock { #[@External.Erlang("gen_tcp:recv($self, $0)")] declare fn recv(self, n: i32) -> string; }
sock.recv(10)        // chamada de método comum: o backend emite `recv` como função do tipo
```
Antes: nenhum backend emitia (erlang `undef`, commonJS `… is not a function`).
Alternativa: além disso, colar o binding no site da chamada dentro do módulo dono (um segundo caminho em quatro backends).

**Recomendação: manter ★.**

**lem-c ★ · Método sem binding é recusado onde é CHAMADO**
```bp
sock.recv(10)        // num target sem binding para `recv`: MissingExternal `Sock.recv`, na chamada
```
O tipo em si compila; o wasm recusa toda chamada de método host.
Alternativa: recusar a declaração do tipo inteiro nesse backend.

**Recomendação: manter ★** — e registrar que a 146 vale para função com corpo (ver `ctr-o`).

**lem-d ★ · Os nomes depois do colapso**
```bp
listener.accept()   socket.recv(n)   socket.close()   r.matches(s)      // ★ um nome por operação
l.listenerPort()    r.runCompiled(s)                                    // alternativa: os nomes antigos como métodos
```
Os construtores (`listen`, `connect`, `regex.compile`) continuam funções de módulo.

**Recomendação: manter ★.**

**lem-e ★ · O que ficou função livre mesmo recebendo um tipo**
```bp
fn rkvPush(v: Violation)                  // privado do `validation`: continua livre
fn tlsEchoOnce(listener, length)          // instrumento de teste do `io.net`: continua livre
```
Alternativa: virar método — e entrar na superfície pública do tipo no erlang e no beam.

**Recomendação: manter ★.**

**lem-f ★ · O commonJS adota um registro construído pelo host**
```bp
regex.compile(p).map({ r -> r.matches(s) })     // funciona (antes: "r.matches is not a function")
```
Alternativa: o template tem de construir a classe (`new Regex(…)`).

**Recomendação: manter ★.**

### std e packaging

**01std-a ★ · Onde uma lib bundled é carregada**
```bp
import {pattern} from "routing";      // sem nenhuma linha em "dependencies"
```
```json
{ "dependencies": { "routing": { "path": "…" } } }     // recusado: `routing` é bundled
```
Quem acrescenta os módulos embutidos é a CLI e o LSP; o core só conhece `std`.
Alternativa: generalizar o caminho do `std` dentro do core (mexe nos quatro codegens, sem diferença observável).

**Recomendação: manter ★.**

**01std-c ★ · O padrão vazio do `routing.pattern`**
```bp
parsePattern("")       // zero segmentos: casa só com "/"
```
O rakun-web mantém "matcher vazio roda em todo lugar" no site de chamada dele (`matcherAdmits`).
Alternativa: o padrão vazio da lib casa com tudo.

**Recomendação: manter ★.**

**01std-e ★ · `actions.readEnvelope` recusa um envelope incoerente**
```bp
readEnvelope(text)      // `redirect` que discorda do `n` → Error (o único escritor nunca produz esse par)
```
Alternativa: ler o `n` e ignorar o `redirect`.

**Recomendação: manter ★.**

**std-a ★ · `querystring` recusa por `Error`, nos dois sentidos**
```bp
querystring.parse("?a=1+2")              // Ok([#("a", "1+2")])    RFC 3986: `+` fica `+`, o `?` sai
querystring.parseForm("a=1+2")           // Ok([#("a", "1 2")])    formulário: `+` é espaço
querystring.parse("a=%zz")               // Error("a `%` not followed by two hex digits")
querystring.stringify([#("a", "\n")])    // Error: caractere de controle
```
Alternativa: manter o componente malformado como escrito (`"%zz"`) e o `stringify` infalível; ou um `parse` só, com o sabor como parâmetro.

**Recomendação: manter ★** (a `03r-e` cai junto, ver `ctr-p`).

**std-b ★ · `fs.exists` segue link simbólico**
```bp
fs.exists("/dev/null")          // true
fs.exists("link-quebrado")      // false — a mesma resposta que uma leitura daria
```
Alternativa: `lstat` — um link pendurado existe como link (`true`).

**Recomendação: manter ★.**

**std-c ★ · O namespace de pasta é uma reescrita do programa**
```bp
import {io} from "std";
io.fs.readText(path)       // reescrito para o import folha `io.fs`; só os módulos alcançados são importados
io.nope.f()                // unbound variable 'io'
```
Alternativa: um tipo-namespace no checker e nos quatro backends, para o diagnóstico dizer "std folder `io` has no module `nope`".

**Recomendação: manter ★.**

**95-a ★ · Os cortes de realocação `jhonstart-link` e `rakun-app`**
```bp
import {…} from "jhonstart-link";     // link.bp / reconcile.bp saíram do core do jhonstart
import {…} from "rakun-app";          // o app router (frentes 22 e 23) saiu do core do rakun
```
Alternativa: deixar no core até as frentes donas mexerem de novo.

**Recomendação: manter ★.**

**95-b ★ (emendada) · `rakun-app` herda os `targets` do workspace**
```json
{ "name": "rakun-app" }        // sem "targets": segue o workspace, que hoje é ["erlang"]
```

**Recomendação: manter ★.**

**95-c ★ · `erika-test` existe**
```
repository/erika/modules/erika-test/      # um teste inline, 1/1 nos dois targets
```
Alternativa: esperar uma frente da erika.

**Recomendação: manter ★.**

**95-e ★ · Import qualificado do contexto de request**
```bp
import {request_context.percentDecode} from "rakun";     // forma da decisão 206
import {percentDecode} from "rakun";                     // recusado: `pub` em std/encoding e em rakun/request_context
```
Alternativa: renomear um dos dois `percentDecode`.

**Recomendação: manter ★ agora;** renomear é o trabalho da decisão 116 (o codec do rakun vai para o `encoding` do std), depois do qual a linha pode voltar a `from "rakun"`.

### rakun

**03r-a ★ · Todo manifest do rakun é `["erlang"]`**
```json
{ "name": "rakun", "targets": ["erlang"] }
```
Alternativa: manter os exemplos em commonJS com um gêmeo node só para eles; ou esperar o compilador.

**Recomendação: manter ★.**

**03r-c ★ · Os leitores de config ficam em botopink**
```bp
val cfg = try json.decode(text);     // o `.json` de config é lido pelo `json.decode` do std; não existe `rakun_config.erl`
```
Alternativa: portar os leitores para Erlang.

**Recomendação: manter ★.**

**03r-d ★ · A checagem de configuração roda no boot**
```
um registro #[configurationProperties] + #[validated] com valor inválido
→ o boot é recusado em `bootSequenceFor`, mesmo com lazy-initialization
```
Alternativa: só falhar no request que injeta o registro pela primeira vez.

**Recomendação: manter ★.**

**03r-e ★ · Componente de cookie/query nunca decodifica para caractere de controle**
```bp
decodeComponent("%0A")      // "%0A" — fica como escrito
decodeComponent("%zz")      // "%zz"
```
Alternativa: o decode do std ao pé da letra (`"%0A"` → quebra de linha).

**Recomendação: manter ★ até o rakun passar a ler pela `querystring` e pelo `http`** — aí ela cai (ver `ctr-p`).

**03r-f ★ · Chave de cache por `hash.strongCacheKey`**
```bp
cacheKey("products", ["a\u{1f}b"])     // diferente de…
cacheKey("products", ["a", "b"])       // …esta: cada parte leva o tamanho, SHA-256
```
Alternativa: `contentHash(parts.join("\u{1f}"))` — as duas chaves acima colidem.

**Recomendação: manter ★.**

**03r-g ★ · Leitura de escopo privado sem sessão**
```
request sem sessão lê um cache `Private`  →  roda o loader e não guarda nada
```
Alternativa: criar uma sessão para servir de chave; ou levantar erro.

**Recomendação: manter ★.**

**03r-h ★ · A chave do gêmeo e o `#[cacheEvict(name, false)]`**
```bp
#[cacheable("products")]            fn productJson(id: i32) …     // chave ["productJson", id]
#[cacheEvict("products", false)]    fn rename(id: i32) …          // remove [m, id] de todo leitor `m` de "products"
```
Alternativa: chave só pelos argumentos (dois leitores do mesmo cache passam a dividir linhas).

**Recomendação: manter ★.**

**03r-i ★ · O provider Redis do cache**
```
Redis fora do ar  →  a leitura roda o loader sem cache e o health reporta DOWN
revalidateTag     →  apaga as linhas (o Redis não tem "servir uma vez e atualizar")
```
Usa o wire RESP do rakun-session. Alternativa: um cliente RESP no `rakun-client`; ou um marcador stale num hash do Redis.

**Recomendação: manter ★.**

**03r-j ★ · Fora de request; e `none` vence o tipo por cache**
```
job agendado:   revalidateTag("users")  legal   ·   updateTag("users")  levanta erro
rakun.cache.type=none  +  rakun.cache.products.type=ets   →  tudo desligado
```
Alternativa: recusar os três fora de request; o tipo por cache vence o `none` global.

**Recomendação: manter ★.**

**03r-k ★ · Todo braço de messaging roda no broker em processo**
```
transport=memory                          →  RabbitMQ, Kafka, Streams e Redis no broker em processo
chave de endereço de broker, sem isso     →  boot recusado, nomeando o driver
```
Alternativa: cair no broker em processo em silêncio (a aplicação acha que fala com o RabbitMQ); ou escrever os protocolos agora.

**Recomendação: manter ★.**

**03r-l ★ · O container tem o nome do destino; Redis é ack-mode none**
```
fila `orders`           →  rakun.messaging.listener.orders.*
stream `audit-stream`   →  rakun.messaging.listener.audit-stream.*
Redis                   →  ack-mode padrão `none`; `auto` ou `manual` explícito recusa o boot
```
Alternativa: um argumento de container em todo marcador; ou `auto` como padrão do Redis.

**Recomendação: manter ★.**

**03r-m ★ · Dentro de uma server action, revalidar expira na hora**
```bp
revalidateTag("posts");     // numa action: expira já — o re-render da própria action mostra o valor novo
                            // fora de action: marca stale (serve o antigo uma vez, atualiza em background)
```
Alternativa: a frente 24 chama `updateTag` para cada caminho; ou o re-render espera as atualizações.

**Recomendação: manter ★.**

**03r-n ★ · Argumento de JSON-RPC é uma lista de campos form-encoded**
```json
{"v":1,"id":"…","args":["title=Hello&draft=true"]}
```
Dá o mesmo estado que o POST do formulário equivalente.
Alternativa: o argumento `i` é o campo chamado `i`; ou o primeiro argumento é o corpo inteiro.

**Recomendação: manter ★.**

**03r-o ★ · Campo de segment config igual ao default conta como não declarado**
```
layout:  `dynamic` fora do default
page:    só `revalidate = 60`        →  a página mantém o `dynamic` do layout
```
O que não dá para dizer: "volte este campo ao default" abaixo de um ancestral que o mudou.
Alternativa: um segundo registro só de campos opcionais; ou substituição por inteiro.

**Recomendação: manter ★.**

**03r-p ★ · O slot é do layout mais próximo acima; só um slot conflita consigo mesmo**
```
app/dashboard/@analytics/page.bp
app/dashboard/@team/page.bp             →  os dois renderizam em /dashboard (é o recurso)
app/dashboard/@team/(a)/page.bp + (b)/page.bp   →  conflito: duas páginas de UM slot na mesma URL
```
Alternativa: guardar a profundidade do slot no registro da frente 22.

**Recomendação: manter ★.**

**03r-q ★ · Roteamento por locale mora no `rakun-app`**
```bp
import {…} from "rakun-app";       // src/i18n.bp
```
Alternativa: um membro novo `rakun-i18n`.

**Recomendação: manter ★** (a 105 extrai o que for comum para o bundled `i18n`).

**03r-r ★ · Starters nomeiam os irmãos com `workspace: true`**
```json
{ "rakun-web": { "workspace": true } }
{ "rakun-web": { "path": "../../modules/rakun-web" } }     // recusado dentro do workspace
```
Alternativa: tirar `starters/` do `workspaces` (deixam de ser células do `test-libs`).

**Recomendação: manter ★.**

**03r-s ★ · OTLP é enviado como HTTP/JSON**
```
POST /v1/metrics     Content-Type: application/json
```
Alternativa: um encoder protobuf no sidecar.

**Recomendação: manter ★.**

**03r-t ★ · As chaves da frente 76 ficam sob `rakun.management.*`**
```
rakun.management.endpoints.web.exposure.include=health,info
rakun.management.endpoint.health.access=…
```
Alternativa: as grafias da spec (`rakun.endpoints.web.exposure.include`), ao lado das da frente 11.

**Recomendação: manter ★.**

**03r-u ★ · O grupo liveness só aceita indicadores locais**
```
liveness com `livenessState`, `ping`, `diskSpace`     →  ok
liveness com qualquer outro indicador                 →  boot recusado
```
Alternativa: o indicador se declara local no registro.

**Recomendação: manter ★.**

**03r-v ★ · O operador do builder tipado é um enum**
```bp
queryOf(CityMeta()).where(CityCol().state, Op.Eq, "CA")     // operador desconhecido = variante desconhecida, erro de compilação
```
Alternativa: `.where(CityCol.state, "=", "CA")`, com a string checada em runtime.

**Recomendação: manter ★.**

**03r-w ★ · OAuth2: endpoints são campos do provider; client credentials é uma função**
```bp
OAuth2Provider(authorizationUri: …, tokenUri: …, userinfoUri: …, jwksUri: …)
withClientToken("github", { -> client.get("/user").retrieve() })      // tenta de novo uma vez no 401
```
Alternativa: um `ProviderEndpoints` à parte e um interceptor de request no `rakun-client`.

**Recomendação: manter ★.**

**03r-x ★ · O relay reivindica por UPDATE condicional**
```sql
UPDATE … SET status = 'claimed' WHERE id = :id AND status = 'pending'     -- um vencedor por linha, em todo driver
```
Sagas e 2PC persistem cada transição e são retomados no boot (`resumeSagas`, `recover2pc`).
Alternativa: `FOR UPDATE SKIP LOCKED` por driver e sidecars `gen_statem` supervisionados.

**Recomendação: manter ★.**

### jhonstart

**26-a (jhonstart) ★ · Toda célula do roteador tem os dois targets**
(o id `26-a` do compilador é outra pergunta, já respondida pela decisão 242)
```bp
#[@External.Erlang(…), @External.Node("./router_runtime.mjs", …)]
declare fn __jhRoutePath() -> string;
```
Alternativa: o roteador num membro só-erlang, importado pelo render através de uma divisão de target.

**Recomendação: manter ★.**

**27-a ★ · Célula de browser num membro de dois targets**
```bp
linkStatus()       // no erlang responde a verdade do servidor: nenhum link em voo, nada pré-carregado
```
Alternativa: um membro só-commonJS para as células (divide o `link.bp` em dois).

**Recomendação: manter ★.**

**29-a ★ · A tabela de starters de island**
```bp
registerStarter("Counter", startCounter);
registerRouteStarters("/blog/[slug]", loadBlogChunk);     // o chunk da rota só carrega quando a rota casa
```
Um segundo starter para o mesmo componente falha nomeando-o. Antes o onze escrevia `globalThis.__jhIslandStarters` à mão.
Alternativa: só a entrada do registro; ou starters preguiçosos por componente.

**Recomendação: manter ★.**

**30-b ★ · `RenderPlugin` é um registro de funções**
```bp
RenderPlugin(name: …, head: …, chunk: …, close: …, payload: …)     // `chunk(id)` roda no processo da própria fronteira
```
Alternativa: uma `behavior RenderPlugin` (quando um array de tipos diferentes que a implementam tipar).

**Recomendação: manter ★.**

**30-c ★ · `compose` recebe a página como thunk**
```bp
compose(chain, route, { -> Page() })     // os layouts rodam antes: redirect num layout e a página nunca é chamada
```
Alternativa: um módulo só, maior, com `render.bp` e `streaming.bp` juntos.

**Recomendação: manter ★.**

**30-d ★ · `Suspense` registra a fronteira no render**
```bp
Suspense(b)        // escreve o buraco e guarda `b` no estado do render
```
Alternativa: a página devolve as fronteiras ao lado da árvore.

**Recomendação: manter ★.**

**30-e ★ · O registro de segmento se chama `UiSegment`**
```bp
import {UiSegment} from "jhonstart";      // compila
import {Segment} from "jhonstart";        // seria ambíguo com o `Segment` do `routing`
```

**Recomendação: manter ★.**

**30-f ★ · `app(…, lang:)`**
```bp
app(plugins, lang: "pt-BR")       // <html lang="pt-BR"> em todo documento; sem o argumento, "en"
app(plugins, lang: "pt_BR")       // recusado: só letras, dígitos e `-`, começando por letra
```
Alternativa: `PageInput.lang` por request; ou nenhum padrão.

**Recomendação: manter ★ agora;** `PageInput.lang` por request é aditivo quando o `i18n` (105) entrar.

**30-g ★ · A metade de browser é afirmada num membro só-commonJS**
```
modules/jhonstart-dom-test      targets ["commonJS"]      fake_dom.mjs + dom_test.bp
```
Alternativa: deixar para o browser do onze 53; ou uma lib de DOM real como dependência.

**Recomendação: manter ★.**

**31-a ★ · `notFound()` / `redirect(url)` levantam**
```bp
if (post == null) { notFound(); }       // a chamada em si levanta; a fronteira captura por uma célula host
val reason = notFoundReason();          // o motivo como valor, sem levantar
```
Alternativa: as funções devolvem o motivo e o componente devolve uma "árvore sinalizadora"; ou um tipo `never`.

**Recomendação: manter ★.**

**`pub val globals` ★ (decisão 140)** — o registro global do jhonstart é um `pub val` de módulo
(`globals.starters` é a tabela da 29-a), avaliado uma vez e importado como qualquer nome.

**Recomendação: manter ★.**

### emilia

**05emilia-a ★ · O leitor de filtro é uma cadeia inline**
```css
filter: var(--tw-blur,) var(--tw-brightness,) … var(--tw-drop-shadow,)     /* em todo utilitário, como o upstream */
```
Alternativa: `filter: var(--tw-filter)` com `--tw-filter` no tema — não compõe.

**Recomendação: manter ★.**

**05emilia-b ★ · A seção de backdrop é `BackdropFilter`**
```
BackdropFilter …              a seção nova (nome da propriedade no upstream)
Backdrop(inner: Token[])      continua sendo o modificador `::backdrop`
```
Alternativa: renomear o modificador da frente 34.

**Recomendação: manter ★.**

**05emilia-c ★ · `drop-shadow-none` segue o upstream**
```css
--tw-drop-shadow: ;  /* + o leitor */      /* ★ */
filter: drop-shadow(none)                  /* alternativa: a string da referência, que não é CSS válido */
```

**Recomendação: manter ★.**

**05emilia-d ★ · A rigidez do snap é um fallback, não uma entrada do tema**
```css
scroll-snap-type: x var(--tw-scroll-snap-strictness, proximity)
```
Alternativa: um namespace `Tw` no tema.

**Recomendação: manter ★.**

**05emilia-e ★ · `fullTheme()` vai no `fullOptions()`**
```bp
flush()                 // renderiza com fullOptions() = withTheme(defaultOptions(), fullTheme())
defaultOptions()        // continua a base sem paleta
```
Alternativa: mover as entradas de cinco frentes para o `theme.bp`.

**Recomendação: manter ★.**

**05emilia-f ★ · As entradas `--inset-shadow-*` não levam o `inset`**
```css
box-shadow: inset var(--inset-shadow-xs)      /* o utilitário escreve o `inset`; a entrada do tema não */
```
Alternativa: os valores do upstream (que já começam com `inset`) e a frente 41 muda a saída fixada.

**Recomendação: manter ★.**

**05emilia-g ★ · `space-*` / `divide-*` como o upstream**
```css
:where(& > :not(:last-child))     /* ★ com --tw-space-x-reverse: `Space.XReverse` passa a ter efeito */
& > :not(:last-child)             /* alternativa: a forma antiga (especificidade maior, o reverse não faz nada) */
```

**Recomendação: manter ★.**

**05emilia-h ★ · Módulos irmãos nunca importam `from "emilia"`**
```bp
// modules/emilia/src/preflight.bp
import {flushWith} from "emilia";      // dentro do próprio pacote: `module-import-with-from` (decisão 206)
```
Irmãos importam `tokens` / `theme` / `output` pelo caminho; `named()` mora no `emilia.bp`.
Alternativa: consertar o resolver primeiro (mudança no compilador).

**Recomendação: manter ★** (a decisão 206 já transformou isso em regra).

**05emilia-i ★ · As variáveis `--tw-*` de transform são blocos `@property`**
```css
@layer properties;
@property --tw-translate-x { … initial-value: 0 }
.translate-x-4 { --tw-translate-x: …; translate: var(--tw-translate-x) var(--tw-translate-y) }
```
Alternativa: o fallback inline `var(--tw-translate-y, 0)` e skews que não compõem.

**Recomendação: manter ★.**

**05emilia-j ★ · Modificador de lista de seletores**
```
marker:flex  →  & *::marker · &::marker · & *::-webkit-details-marker · &::-webkit-details-marker     (4 regras, como o upstream)
```
Alternativa: `& ::marker` (só descendentes); ou `Variant` carregando uma lista de seletores.

**Recomendação: manter ★.**

**05emilia-k ★ · O meio passo negativo**
```bp
spacingNegHalf(0)       // -0.5  →  margin-top: calc(var(--spacing) * -0.5)
spacingHalf(-1)         // aborta
```
Alternativa: `spacingHalf(n, negative: true)`; ou um passo em string (`"-0.5"`).

**Recomendação: manter ★.**

**05emilia-l ★ · Confirmar uma coluna move a família inteira para a forma do upstream**
```css
w-1/2        →  width: calc(1 / 2 * 100%)
opacity-60   →  opacity: 60%
-rotate-12   →  rotate: calc(12deg * -1)
```
Alternativa: mudar só as linhas não confirmadas; ou manter as grafias da referência e documentar.

**Recomendação: manter ★.**

### onze

**49-a ★ · As suítes do core renderizam pelo `describe*` do próprio core**
```bp
describeConfig(cfg)       // o mesmo texto que o `onze info` imprime; o teste do core o afirma com `snapshots.assertAs`
```
Alternativa: mover as suítes para o `onze-test` (o core não pode importá-lo: o `onze-test` depende do `onze`).

**Recomendação: manter ★.**

**49-c ★ · `onze.json` recusa chave desconhecida**
```json
{ "prot": 4000 }
```
→ `Error` nomeando `prot`. Alternativa: ignorar — a porta fica 3000 em silêncio.

**Recomendação: manter ★.**

**49-d ★ · `chainFor` recebe os padrões ancestrais**
```bp
chainFor(patterns)        // os padrões vêm da cadeia de layouts do rakun; o onze não importa nada de `routing`
```
Alternativa: `import {ancestorPatterns} from "routing"`. **A 102 passo 3 desfaz esta escolha** — precisa da sua confirmação.

**Recomendação (desta revisão): confirmar como emendada pela 102.** O `chainFor(patterns)` fica; cai só a metade "o onze não importa nada de `routing`" — a 102 existe para apagar a re-derivação da gramática de segmentos, e o `types.bp` do onze é um dos sete lugares que a refazem à mão.

**49-e ★ · A metade rakun do boot é um membro próprio**
```
modules/onze-server/      targets ["erlang"]      Onze.run, requestData, responseFor
```
Alternativa: o core vira só-erlang (a CLI e o bundler deixam de depender dele); ou esperar um membro do rakun nos dois targets.

**Recomendação: manter ★.**

**50-a ★ (emendada) · `onze build` gera um main de servidor; `onze start` o roda**
```
$ onze build      # gera onze_main.bp e compila o pacote para BEAM
$ onze start      # erl -noshell -pa <outDir>/server/beam -eval '<pacote>@onze_main':main()
```
Alternativa: `start` roda o script de boot do release (frente 71).

**Recomendação: manter ★** até o `bin/onze` da frente 71 existir; aí o `start` chama esse script, e o comando de hoje é o que o script roda.

**52-a ★ · A tabela de métricas de fonte é transcrita**
```
Arial · Times New Roman · Inter · Roboto · Merriweather     (cinco linhas; o gerador fica devendo)
```
Alternativa: nenhuma tabela — toda família Google com `adjustFontFallback: true` é recusada.

**Recomendação: manter ★,** com as linhas re-derivadas pelo gerador antes de um release.

**53-a ★ · Os fontes do blog ficam sob `src/`**
```
src/app/   src/components/   src/lib/        onze.json: "appDir": "src/app"
```
Alternativa: o layout na raiz (`app/`, `components/`, `lib/`).

**Recomendação: manter ★.**

**68-a ★ · Um campo do manifest escapa quatro caracteres**
```
/_onze/static/app.js          ★ só `%`, `|`, LF e CR são escapados
%2F_onze%2Fstatic%2Fapp.js    alternativa: `percentEncode` no valor inteiro (ilegível)
```

**Recomendação: manter ★.**

**68-c ★ · Os starters decodificam as props a partir do fonte**
```bp
#[client] pub fn Counter(props: CounterProps) …      // o gerador lê os campos de `CounterProps` e gera startCounter(raw, commit)
```
Alternativa: o jhonstart ganha um decoder construído por decorator.

**Recomendação: manter ★.**

**68-d ★ · O styleMap é avaliado por uma sonda compilada nos dois pacotes**
```
$ onze build
error[emilia-hash-split]      a classe ou o hash difere entre node e erl
error[emilia-unevaluated]     um dos dois backends não respondeu
```
Alternativa: um interpretador de tokens no bundler; ou só a regra estática.

**Recomendação: manter ★.**

**69-a ★ · `onze-assets` mantém o seu `AssetRoot`**
```bp
AssetRoot(pattern, directory, immutable, cacheSeconds)     // nos dois targets; o onze-server converte para o `StaticRoot` do rakun-web
```
Alternativa: `onze-assets` só-erlang.

**Recomendação: manter ★.**

- [ ] Confirmo todas como estão, com lem-b (b) e 03r-b (b)
- [ ] Quero rever: ___
