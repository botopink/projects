# Exemplos — argumentos de decorator tipados (decisão 280)

Aprovados pelo mantenedor em 04/10 como os casos de uso da decisão 280; são os alvos do passo 24 do
`01-checker` (cada exemplo vira uma célula `run/` e as suas recusas, células `reject/`). Partes
ilustrativas, que não são da 280: a emissão por função (`decl.addMember("validate", fn…)`) não é
decidida (a `nat-c` fechou em 293–300 sem ela); o meta tipado (`decl.setMeta(Table(…))`) é da 298; `decl.wrapWith` (exemplo 5) é da 316 (`01-checker` passo 30);
`decl.addToCatalogue()` é a forma do catálogo de 216 (4).

Cada exemplo mostra quatro partes:

1. **A lib** — o decorator, com todos os parâmetros `comptime`.
2. **O uso** — o código de quem usa a lib.
3. **O que sobra em runtime** — o que o decorator gera. Os argumentos não existem mais nessa hora:
   eles foram usados em comptime e viraram constantes dentro do código gerado.
4. **O que não compila** — onde cai cada erro.

As regras que os exemplos usam:

- **(0)** Todo parâmetro de decorator é `comptime`, escrito explicitamente.
- **(1)** O argumento é tipado: pode ser função, `type`, `Type.Field<T>` (308), enum ou record.
- **(2)** `@Decl<T>`: o `T` é inferido da declaração anotada; quando a assinatura não usa o `T`, ele é `unknown`.
- **(3)** `Type.Field<T>` (da std, decisão 308) e o atalho `.campo`.
- **(4)** O atalho `.Nome` resolve exatamente o nome declarado (maiúsculas contam): `.Custom`, nunca
  `.custom`; nenhuma saída converte caixa — um nome de outro sistema é string explícita.

> **Sobre a emissão.** Hoje o `decl.addMember` recebe o código como string (216). Nos exemplos ele
> recebe uma **função de verdade**: `decl.addMember("validate", fn(self: T) -> … { … })`. Essa função
> captura os argumentos `comptime`, que entram no código gerado como constantes. Essa forma de
> emitir não é decidida (a `nat-c` fechou em 293–300 sem ela). Onde aparece, está marcada como ilustrativa.

---

## 1. Validação — `#[check]` no tipo e na função (front 125)

### A lib
```bp
// validation/src/check.bp
import {types.Type} from "std";

pub type Code { Custom, Required, TooShort, Mismatch }

pub type Violation(field: string, code: Code, message: string)

// No tipo: T = o tipo anotado.
// Na função: sem `rule`, a própria função anotada é a regra; o T desta chamada é o tipo da função,
// e o tipo validado é o do parâmetro dela.
pub fn check<T>(
    comptime decl: @Decl<T>,
    comptime rule: ?fn(v: T) -> bool = null,
    comptime at: ?Type.Field<T> = null,
    comptime message: string,
    comptime code: Code = .Custom,
) {
    if (rule == null) {
        // forma na função: confere a forma da regra
        if (decl.kind != DeclKind.Fn || decl.returnType != "bool" || decl.params.length != 1)
            decl.fail("#[check] sem `rule` vai numa `fn(x) -> bool`");
        if (at != null) decl.fail("`at` só existe no #[check] escrito no tipo");
        // só vale no módulo que declara o tipo validado (67)
        if (decl.params[0].module != decl.module)
            decl.fail("a regra precisa estar no módulo que declara `${decl.params[0].typeName}`");
        decl.addToCatalogue();                      // o validate do tipo encontra a regra aqui
        return;
    }
    // forma no tipo: acrescenta a regra ao validate de T (ilustrativo)
    decl.addMember("validate", fn(self: T) -> Violation[] {
        if (rule(self)) return [];
        return [Violation(field: at?.name ?? "", code: code, message: message)];
    });
}
```

### O uso
```bp
import {check, Code} from "validation";

#[
    check(passwordsMatch, at: .confirm, message: "As senhas não batem"),
    check(handleFree, at: .handle, message: "Esse nome já é usado", code: .Mismatch),
]
pub type Account(handle: string, password: string, confirm: string)

fn passwordsMatch(a: Account) -> bool { return a.password == a.confirm; }
fn handleFree(a: Account) -> bool { return a.handle != "admin"; }

// a regra pode ficar na própria função (no mesmo módulo de Account)
#[check(message: "A senha não pode conter o nome")]
fn passwordNotHandle(a: Account) -> bool { return !a.password.contains(a.handle); }

test "senhas diferentes" {
    val v = Account(handle: "ana", password: "abc12345", confirm: "abc1234X").validate();
    assert v.length == 1;
    assert v[0].field == "confirm";
    assert v[0].message == "As senhas não batem";
}
```

### O que sobra em runtime
```bp
// Account ganha um membro; os argumentos viraram literais dentro dele
pub fn validate(self: Account) -> Violation[] {
    var out: Violation[] = [];
    if (!passwordsMatch(self))    out = out.append(Violation(field: "confirm", code: .Custom,   message: "As senhas não batem"));
    if (!handleFree(self))        out = out.append(Violation(field: "handle",  code: .Mismatch, message: "Esse nome já é usado"));
    if (!passwordNotHandle(self)) out = out.append(Violation(field: "",        code: .Custom,   message: "A senha não pode conter o nome"));
    return out;
}
```

### O que não compila
```bp
#[check(passwordMatch, message: "…")]                  // ❌ nome `passwordMatch` não existe       — no argumento
#[check(passwordsMatch, at: .confrim, message: "…")]   // ❌ `Account` não tem o campo `confrim`   — no `.confrim`
#[check(orderTotal, message: "…")]                     // ❌ esperado fn(Account) -> bool, recebido fn(Order) -> bool
#[check(passwordsMatch, message: env("MSG"))]          // ❌ `env(...)` não é conhecido em comptime — no argumento
#[check(message: "…")] fn bad(a: Account) -> string    // ❌ #[check] sem `rule` vai numa `fn(x) -> bool`
```

---

## 2. Eventos — `#[on]` sem argumento nenhum (rakun 04)

O tipo do evento sai da assinatura da função, pelo padrão `@Decl<fn(e: E) -> unknown>`.

### A lib
```bp
// rakun/src/events.bp
pub fn on<E>(comptime decl: @Decl<fn(e: E) -> unknown>) {
    decl.addToCatalogue();           // @TypeInfo.all(with: on) acha todos os listeners
}

// publish é genérico; a tabela de quem ouve cada E é montada em comptime
pub fn publish<E>(event: E) {
    val listeners = comptime @TypeInfo.all(with: on).filter({ l -> l.value is fn(e: E) -> unknown });
    for (l in listeners) (l.value as fn(e: E) -> unknown)(event);
}
```

### O uso
```bp
import {on, publish} from "rakun";

pub type OrderPlaced(id: string, total: i64)
pub type OrderCancelled(id: string)

#[on] fn sendReceipt(e: OrderPlaced) { mail.send(e.id, …); }
#[on] fn updateStock(e: OrderPlaced) { … }
#[on] fn refund(e: OrderCancelled) { … }

fn checkout(o: Order) {
    publish(OrderPlaced(id: o.id, total: o.total));   // chama sendReceipt e updateStock
}
```

### O que sobra em runtime
```bp
// publish<OrderPlaced> com a lista resolvida em comptime
fn publish__OrderPlaced(event: OrderPlaced) { sendReceipt(event); updateStock(event); }
```

### O que não compila
```bp
#[on] fn wrong() { … }                   // ❌ #[on] espera fn(e: E) -> …, a função não tem parâmetro
#[eventListener("OrderPlaced")]          // ❌ não existe mais: o evento é o tipo do parâmetro
publish("OrderPlaced")                   // compila, mas nenhum listener recebe `string`
```

---

## 3. Bean condicional — um tipo como argumento (rakun 04, lg2-f)

### A lib
```bp
// rakun/src/conditions.bp
pub fn conditionalOnMissingBean(comptime decl: @Decl, comptime t: type) {
    decl.setMeta(OnMissing(type: t));      // meta tipado (298); o registro em comptime lê isto
}
```

### O uso
```bp
import {provides, conditionalOnMissingBean} from "rakun";

pub behavior MailSender { fn send(self, to: string, body: string); }

#[provides, conditionalOnMissingBean(MailSender)]
fn consoleMail() -> MailSender { return ConsoleMail(); }    // só entra se ninguém mais der um MailSender
```

### O que sobra em runtime
Nada do argumento. Em comptime, o registro de beans (256) decide se `consoleMail` entra. Em runtime
resta só a tabela já resolvida.

### O que não compila
```bp
#[conditionalOnMissingBean(MailSendr)]     // ❌ nome `MailSendr` não existe   (hoje só falha no boot)
#[conditionalOnMissingBean("MailSender")]  // ❌ esperado `type`, recebido `string`
```

---

## 4. Página — caminhos e cabeçalho por função (117, 53 — 282)

> **Forma da página emendada pela 293:** a página não recebe mais `route: PageContext<P, D>`; ela lê
> `use params<P>()` e `use pageData<D>()`, e o `#[page]` confere `paths:` contra esses `use` (via
> `Decl.hooks`). O mecanismo da 280 (argumento função tipado) continua o mesmo.

Os parâmetros da rota (`P`) e os dados (`D`) saem da assinatura da página. `paths` e `head` têm que
concordar com eles.

### A lib
```bp
// jhonstart/src/routes.bp
pub fn page<P, D>(
    comptime decl: @Decl<fn(route: PageContext<P, D>) -> View>,
    comptime seg: string,                                  // a URL pública: continua string
    comptime paths: ?fn() -> @Task<#(P, D)[]> = null,      // as páginas pré-renderizadas
    comptime head: ?fn(p: P, d: D) -> Head = null,
) {
    decl.setMeta(PageMeta(seg: seg));
    // kind S/D pelo Decl.hooks (277); paths, quando houver, é chamado no build
}
```

### O uso
```bp
pub type BlogParams(slug: string)

#[page("blog/[slug]", paths: allPosts, head: postHead)]
pub fn Page(route: PageContext<BlogParams, Post>) -> View {
    return html """<article><h1>{route.data.title}</h1>{route.data.body}</article>""";
}

fn allPosts() -> @Task<#(BlogParams, Post)[]> {
    return (await db.posts()).map({ p -> #(BlogParams(slug: p.slug), p) });
}

fn postHead(p: BlogParams, d: Post) -> Head { return Head(title: d.title); }
```

### O que não compila
```bp
#[page("blog/[slug]", paths: allUsers)]   // ❌ esperado fn() -> @Task<#(BlogParams, Post)[]>, recebido fn() -> @Task<User[]>
#[page("blog/[slug]", head: postHead)]
pub fn Page(route: PageContext<BlogParams, Post>) -> string   // ❌ #[page] espera uma função que devolve View
pub fn staticPaths() -> …                 // não é mais lido: o papel vai no decorator (282)
```

---

## 5. Cache — o tipo devolvido amarrado ao cache (rakun)

### A lib
```bp
// rakun/src/cache.bp
pub type Cache<T>(name: string)              // `name` é o nome no Redis/ETS: continua string

pub fn cacheable<A, T>(
    comptime decl: @Decl<fn(a: A) -> T>,
    comptime cache: Cache<T>,                 // o T do cache tem que ser o T devolvido
) {
    decl.wrapWith(cachedCall(cache))          // embrulhar a função: decisão 316
}
```

### O uso
```bp
import {Cache, cacheable} from "rakun";

val products = Cache<Product[]>("products");

#[cacheable(products)]
fn byCategory(c: string) -> Product[] { return db.query(…); }
```

### O que não compila
```bp
val users = Cache<User[]>("users");
#[cacheable(users)] fn byCategory(c: string) -> Product[]   // ❌ esperado Cache<Product[]>, recebido Cache<User[]>
#[cacheable("products")]                                     // ❌ esperado Cache<…>, recebido string
```

---

## 6. Entidade — campos como argumento (rakun 08)

### A lib
```bp
// rakun-data-sql/src/entity.bp
import {types.Type} from "std";

pub fn entity<T>(comptime decl: @Decl<T>, comptime table: string) {        // nome SQL: string
    decl.setMeta(Table(name: table));
}
pub fn index<T>(comptime decl: @Decl<T>, comptime ..fields: Type.Field<T>[]) {   // variádico (267)
    decl.setMeta(Index(columns: fields.map({ f -> f.name })));
}
pub fn unique<T>(comptime decl: @Decl<T>, comptime field: Type.Field<T>) {
    decl.setMeta(Unique(column: field.name));
}
pub fn column<T>(comptime decl: @Decl<T>, comptime name: string) {          // num campo: T = tipo do campo
    decl.setMeta(Column(name: name));
}
```

### O uso
```bp
#[entity("cities"), index(.state, .name), unique(.code)]
pub type City(
    code: string,
    name: string,
    #[column("state_name")] state: string,
)
```

### O que sobra em runtime
```sql
-- a migração gerada no build
CREATE TABLE cities (code TEXT, name TEXT, state_name TEXT);
CREATE INDEX cities_state_name ON cities (state_name, name);
CREATE UNIQUE INDEX cities_code ON cities (code);
```

### O que não compila
```bp
#[index(.state, .nmae)]       // ❌ `City` não tem o campo `nmae`
#[unique(.code, .name)]       // ❌ `unique` recebe um campo; para vários, `index`
```
Renomear `state` → `uf` deixa vermelhos todos os `.state`. Com string, o erro só aparecia no SQL.

---

## 7. Anotação de tag — handler como função (278 + 280)

Na tag, o `@Decl` é o do componente (278). O handler é uma função do próprio componente.

### A lib
```bp
// jhonstart/src/events.bp
// 302: anotação de tag = decorator — não devolve nada, grava meta no `decl` da tag
pub fn onClick(comptime decl: @Decl, comptime handler: fn() -> unknown) {
    decl.addMeta(EventBinding(event: .Click, handler: handler));   // o html gera o registro na ilha
}
```

### O uso
```bp
#[client]
pub fn LikeButton(props: LikeButtonProps) -> View {
    val count = use state(props.likes);
    fn like() { count.set(count.value + 1); }
    return html """<button #[onClick(like)]>{count.value.toString()} likes</button>""";
}
```

### O que sobra em runtime
```html
<!-- servidor: o mesmo HTML; no browser a ilha liga o handler -->
<button data-jh-h="0">3 likes</button>
```
```js
// starter da ilha (gerado): handlers por posição, não por nome
bind(root, 0, "click", like);
```

### O que não compila
```bpp
<button #[onClick(lik)]>                   <!-- ❌ nome `lik` não existe -->
<button #[onClick(props.likes)]>           <!-- ❌ esperado fn() -> …, recebido i32 -->
<button data-jh-on-click="LikeButton:like"> <!-- ❌ não existe mais: use #[onClick(like)] -->
```

---

## O que continua string — nomes que pertencem a outro sistema

| Exemplo | Por quê |
|---|---|
| `entity("cities")`, `column("state_name")` | nomes do banco |
| `page("blog/[slug]")` | URL pública |
| `Cache<Product[]>("products")` | nome do cache no Redis/ETS |
| `@External.Erlang("string:slice($0, 0, 1)")` | código do host (a string sem rótulo); `fn: tanBody` é referência à função botopink (305) |
| `config("rakun.data")` | caminho no arquivo de configuração |
| `message: "As senhas não batem"` | texto para o usuário |

**A regra:** se o nome aponta para **código botopink** (função, tipo, campo, variante, evento, hook,
ação), ele é referência tipada. Se aponta para fora, é string.
