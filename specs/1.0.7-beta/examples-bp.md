# Exemplos de Código bp por Frente

Este documento mostra exemplos práticos de como cada frente do milestone 1.0.7-beta se traduz em código botopink real.

---

## F01 — onze13 Stand-up

### Configuração do projeto (onze13.json)

```json
{
  "name": "my-app",
  "port": 3000,
  "basePath": "",
  "outDir": ".onze13"
}
```

### Importando onze13

```bp
// app/page.bp
import {Element, div, h1, text} from "jhonstart";
import {emilia, Token} from "emilia";
import {PageProps} from "onze13";

pub fn HomePage() -> Element {
    val titleClass = emilia([.Text.Size.X3xl, .Text.Bold, .Color.Blue700]);
    return div([
        h1([text("Bem-vindo ao onze13!", attrs: [])], attrs: [#("class", titleClass)]),
    ], attrs: []);
}
```

### Usando tipos de integração

```bp
// app/blog/[slug]/page.bp
import {PageProps} from "onze13";
import {Element, div, h1, p, text} from "jhonstart";

#[@future]
pub fn BlogPost(props: PageProps<Dict<string, string>>) -> @Future<Element> {
    val slug = props.params.get("slug");
    val post = await fetchPost(slug);
    return div([
        h1([text(post.title, attrs: [])], attrs: []),
        p([text(post.content, attrs: [])], attrs: []),
    ], attrs: []);
}
```

---

## F02 — Jhonstart Router

### useRouter em um componente

```bp
// components/breadcrumb.bp
#[client]
import {useRouter} from "jhonstart";
import {Element, div, span, text} from "jhonstart";

pub fn Breadcrumb() -> Element {
    val router = use useRouter();
    val path = router.pathname();
    return div([
        span([text("Você está em: " + path, attrs: [])], attrs: []),
    ], attrs: []);
}
```

### Navegação programática

```bp
// components/login-form.bp
#[client]
import {useRouter} from "jhonstart";
import {Element, form, input, button, text} from "jhonstart";

pub fn LoginForm() -> Element {
    val router = use useRouter();
    return form([
        input([attrs: [#("type", "email"), #("name", "email")]]),
        button([text("Entrar", attrs: [])], attrs: [
            #("onClick", "handleLogin"),
        ]),
    ], attrs: [#("action", "/api/login")]);
}
```

### Acessando params da rota

```bp
// app/blog/[slug]/page.bp
import {useRouter} from "jhonstart";
import {Element, div, h1, text} from "jhonstart";

pub fn BlogPost() -> Element {
    val router = use useRouter();
    val slug = router.params().get("slug");
    return div([
        h1([text("Post: " + slug, attrs: [])], attrs: []),
    ], attrs: []);
}
```

---

## F03 — Jhonstart Link

### Link básico

```bp
// app/layout.bp
import {Link} from "jhonstart";
import {Element, nav, text} from "jhonstart";

pub fn NavBar() -> Element {
    return nav([
        Link("/", [text("Home", attrs: [])]),
        Link("/blog", [text("Blog", attrs: [])]),
        Link("/about", [text("Sobre", attrs: [])]),
    ], attrs: []);
}
```

### Link com prefetch desabilitado

```bp
// app/blog/page.bp
import {Link} from "jhonstart";
import {Element, ul, li, text} from "jhonstart";

pub fn BlogList() -> Element {
    val posts = getPosts();
    return ul(
        posts.map({ post ->
            li([
                Link(
                    "/blog/" + post.slug,
                    [text(post.title, attrs: [])],
                    prefetch: false,
                ),
            ], attrs: [])
        }),
        attrs: [],
    );
}
```

### Link com replace

```bp
// app/settings/page.bp
#[client]
import {Link} from "jhonstart";
import {Element, div, text} from "jhonstart";

pub fn SettingsPage() -> Element {
    return div([
        Link("/settings/profile", [text("Perfil", attrs: [])], replace: true),
        Link("/settings/security", [text("Segurança", attrs: [])], replace: true),
    ], attrs: []);
}
```

---

## F04 — Jhonstart Server Components

### Server component com data fetching

```bp
// app/blog/page.bp
import {Element, div, h1, ul, li, p, text} from "jhonstart";

#[@future]
pub fn BlogPage() -> @Future<Element> {
    val posts = await fetch("https://api.example.com/posts").then({ r -> r.json() });
    return div([
        h1([text("Blog", attrs: [])], attrs: []),
        ul(
            posts.map({ post ->
                li([
                    p([text(post.title, attrs: [])], attrs: []),
                ], attrs: [])
            }),
            attrs: [],
        ),
    ], attrs: []);
}
```

### Acessando a request no server component

```bp
// app/search/page.bp
import {Element, div, h1, ul, li, text} from "jhonstart";
import {request} from "jhonstart";

#[@future]
pub fn SearchPage() -> @Future<Element> {
    val req = use request();
    val query = req.query("q");
    val results = await search(query);
    return div([
        h1([text("Resultados para: " + query, attrs: [])], attrs: []),
        ul(
            results.map({ r ->
                li([text(r.title, attrs: [])], attrs: [])
            }),
            attrs: [],
        ),
    ], attrs: []);
}
```

### Server component com banco de dados

```bp
// app/users/page.bp
import {Element, div, table, tr, td, text} from "jhonstart";
import {db} from "@/lib/db";

#[@future]
pub fn UsersPage() -> @Future<Element> {
    val users = await db.user.findAll();
    return div([
        table(
            users.map({ user ->
                tr([
                    td([text(user.name, attrs: [])], attrs: []),
                    td([text(user.email, attrs: [])], attrs: []),
                ], attrs: [])
            }),
            attrs: [],
        ),
    ], attrs: []);
}
```

---

## F05 — Jhonstart Client Directive

### Componente cliente com state

```bp
// components/counter.bp
#[client]
import {Element, div, button, p, text} from "jhonstart";
import {state} from "jhonstart";

pub fn Counter() -> Element {
    val count = use state(0);
    return div([
        p([text("Count: " + count.value.toString(), attrs: [])], attrs: []),
        button([text("+1", attrs: [])], attrs: [
            #("onClick", "increment"),
        ]),
    ], attrs: []);
}
```

### Componente cliente com effect

```bp
// components/timer.bp
#[client]
import {Element, div, p, text} from "jhonstart";
import {state, effect} from "jhonstart";

pub fn Timer() -> Element {
    val seconds = use state(0);
    use effect({ ->
        val interval = setInterval({ ->
            seconds.set(seconds.value + 1);
        }, 1000);
        return { -> clearInterval(interval); };
    }, []);
    return div([
        p([text("Tempo: " + seconds.value.toString() + "s", attrs: [])], attrs: []),
    ], attrs: []);
}
```

### Misturando server e client components

```bp
// app/dashboard/page.bp
import {Element, div, h1} from "jhonstart";
import {Counter} from "@/components/counter";    // client component
import {RecentPosts} from "@/components/posts";   // server component

#[@future]
pub fn DashboardPage() -> @Future<Element> {
    return div([
        h1([text("Dashboard")], attrs: []),
        Counter(),               // hidratado no cliente
        await RecentPosts(),     // renderizado no servidor
    ], attrs: []);
}
```

---

## F06 — Jhonstart Streaming

### Suspense com fallback

```bp
// app/blog/page.bp
import {Element, div, h1, Suspense, text} from "jhonstart";

#[@future]
pub fn BlogPage() -> @Future<Element> {
    return div([
        h1([text("Blog", attrs: [])], attrs: []),
        Suspense(SuspenseProps(
            fallback: div([text("Carregando posts...", attrs: [])], attrs: []),
            children: [await PostList()],
        )),
    ], attrs: []);
}
```

### loading.bp automático

```bp
// app/blog/loading.bp
import {Element, div, text} from "jhonstart";
import {emilia, Token} from "emilia";

pub fn Loading() -> Element {
    val skeletonClass = emilia([.Pad.All.4, .Bg.Gray100, .Border.Rounded.Md]);
    return div([
        div([text("Carregando...", attrs: [])], attrs: [#("class", skeletonClass)]),
    ], attrs: []);
}
```

### Streaming granular

```bp
// app/dashboard/page.bp
import {Element, div, h1, Suspense, text} from "jhonstart";

#[@future]
pub fn DashboardPage() -> @Future<Element> {
    return div([
        h1([text("Dashboard", attrs: [])], attrs: []),
        div([
            Suspense(SuspenseProps(
                fallback: div([text("Carregando stats...", attrs: [])], attrs: []),
                children: [await StatsPanel()],
            )),
        ], attrs: []),
        div([
            Suspense(SuspenseProps(
                fallback: div([text("Carregando dados...", attrs: [])], attrs: []),
                children: [await DataTable()],
            )),
        ], attrs: []),
    ], attrs: []);
}
```

---

## F07 — Jhonstart Error Boundaries

### error.bp por segmento

```bp
// app/blog/error.bp
#[client]
import {Element, div, h2, p, button, text} from "jhonstart";

pub fn Error(error: string, retry: fn()) -> Element {
    return div([
        h2([text("Algo deu errado!", attrs: [])], attrs: []),
        p([text(error, attrs: [])], attrs: []),
        button([text("Tentar novamente", attrs: [])], attrs: [
            #("onClick", "retry"),
        ]),
    ], attrs: []);
}
```

### not-found.bp

```bp
// app/blog/[slug]/not-found.bp
import {Element, div, h2, p, text} from "jhonstart";
import {Link} from "jhonstart";
import {emilia, Token} from "emilia";

pub fn NotFound() -> Element {
    val containerClass = emilia([.Pad.All.8, .Text.Center]);
    return div([
        h2([text("Post não encontrado", attrs: [])], attrs: []),
        p([text("O post que você procura não existe.", attrs: [])], attrs: []),
        Link("/blog", [text("Voltar ao blog", attrs: [])]),
    ], attrs: [#("class", containerClass)]);
}
```

### notFound() em server component

```bp
// app/blog/[slug]/page.bp
import {Element, div, h1, text} from "jhonstart";
import {notFound} from "jhonstart";

#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val slug = params.get("slug");
    val post = await getPost(slug);
    if (post == null) {
        notFound();
    };
    return div([
        h1([text(post.title, attrs: [])], attrs: []),
    ], attrs: []);
}
```

---

## F08 — Jhonstart Metadata

### Metadata estático

```bp
// app/about/page.bp
import {Element, div, h1, p, text} from "jhonstart";
import {Metadata} from "jhonstart";

pub val metadata: Metadata = Metadata(
    title: "Sobre Nós — Minha Empresa",
    description: "Saiba mais sobre nossa empresa.",
    openGraph: OpenGraph(
        title: "Sobre Nós",
        description: "Nossa missão é transformar o mundo.",
        images: ["/og/about.png"],
        url: "/about",
        type: "website",
    ),
    twitter: TwitterCard(
        card: "summary_large_image",
        title: "Sobre Nós",
        description: "Conheça nossa empresa.",
        images: ["/og/about.png"],
    ),
    icons: Icons(icon: "/favicon.ico", apple: "/apple-icon.png"),
);

pub fn AboutPage() -> Element {
    return div([
        h1([text("Sobre Nós", attrs: [])], attrs: []),
        p([text("Somos uma empresa de tecnologia.", attrs: [])], attrs: []),
    ], attrs: []);
}
```

### Metadata dinâmico

```bp
// app/blog/[slug]/page.bp
import {Element, div, h1, p, text} from "jhonstart";
import {Metadata} from "jhonstart";

#[@future]
pub fn generateMetadata(params: Dict<string, string>) -> @Future<Metadata> {
    val slug = params.get("slug");
    val post = await fetchPost(slug);
    return Metadata(
        title: post.title + " — Blog",
        description: post.excerpt,
        openGraph: OpenGraph(
            title: post.title,
            description: post.excerpt,
            images: ["/og/blog/" + slug + ".png"],
            url: "/blog/" + slug,
            type: "article",
        ),
        twitter: TwitterCard(
            card: "summary_large_image",
            title: post.title,
            description: post.excerpt,
            images: [],
        ),
        icons: Icons(icon: "/favicon.ico", apple: ""),
    );
}

#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val slug = params.get("slug");
    val post = await fetchPost(slug);
    return div([
        h1([text(post.title, attrs: [])], attrs: []),
        p([text(post.content, attrs: [])], attrs: []),
    ], attrs: []);
}
```

---

## F09 — Rakun SSR Pipeline

### Página SSR completa

```bp
// app/page.bp
import {Element, html, head, body, div, h1, p, style, text} from "jhonstart";
import {emilia, flush, Token} from "emilia";

#[@future]
pub fn HomePage() -> @Future<Element> {
    val titleClass = emilia([.Text.Size.X4xl, .Text.Bold]);
    val bodyClass = emilia([.Pad.All.8, .Bg.Gray100]);
    val stats = await fetchStats();
    val styles = await flush();
    return html([
        head([
            style([text(styles, attrs: [])], attrs: []),
        ], attrs: []),
        body([
            div([
                h1([text("Minha Aplicação", attrs: [])], attrs: [#("class", titleClass)]),
                p([text("Visitantes: " + stats.visitors.toString(), attrs: [])], attrs: []),
            ], attrs: [#("class", bodyClass)]),
        ], attrs: []),
    ], attrs: []);
}
```

### Layout com SSR

```bp
// app/layout.bp
import {Element, html, head, body, div, text} from "jhonstart";
import {googleFont} from "onze13";

val inter = googleFont("Inter", subsets: ["latin"]);

#[@future]
pub fn RootLayout(children: Element) -> @Future<Element> {
    return html([
        head([text("", attrs: [])], attrs: []),
        body([
            div([children], attrs: [#("class", inter.className)]),
        ], attrs: []),
    ], attrs: [#("lang", "pt-BR")]);
}
```

---

## F10 — Rakun Server Actions

### Action simples

```bp
// lib/actions.bp
import {revalidatePath} from "rakun";

#[serverAction]
#[@future]
pub fn createPost(formData: FormData) -> @Future<void> {
    val title = formData.get("title");
    val content = formData.get("content");
    await db.post.create(title: title, content: content);
    revalidatePath("/blog");
}
```

### Formulário usando a action

```bp
// app/blog/new/page.bp
import {Element, form, input, textarea, button, text} from "jhonstart";
import {createPost} from "@/lib/actions";

pub fn NewPostForm() -> Element {
    return form([
        input([attrs: [#("type", "text"), #("name", "title"), #("placeholder", "Título")]]),
        textarea([attrs: [#("name", "content"), #("placeholder", "Conteúdo")]]),
        button([text("Criar Post", attrs: [])], attrs: [#("type", "submit")]),
    ], attrs: [#("action", "createPost")]);
}
```

### Action com redirect

```bp
// lib/actions.bp
import {revalidatePath, redirect} from "rakun";

#[serverAction]
#[@future]
pub fn login(formData: FormData) -> @Future<void> {
    val email = formData.get("email");
    val password = formData.get("password");
    val user = await auth.verify(email, password);
    if (user == null) {
        return;
    };
    await session.create(user);
    redirect("/dashboard");
}
```

---

## F11 — Rakun Route Handlers

### GET handler

```bp
// app/api/posts/route.bp
import {Request, Response} from "rakun";

#[@future]
pub fn GET(request: Request) -> @Future<Response> {
    val posts = await db.post.findAll();
    return Response.json(json.stringify(posts));
}
```

### POST handler

```bp
// app/api/posts/route.bp
import {Request, Response} from "rakun";

#[@future]
pub fn POST(request: Request) -> @Future<Response> {
    val body = await request.json();
    val post = await db.post.create(body);
    return Response(status: 201, body: json.stringify(post));
}
```

### Dynamic route handler

```bp
// app/api/posts/[id]/route.bp
import {Request, Response} from "rakun";

#[@future]
pub fn GET(request: Request) -> @Future<Response> {
    val id = request.param("id");
    val post = await db.post.findById(id);
    if (post == null) {
        return Response.notFound();
    };
    return Response.json(json.stringify(post));
}

#[@future]
pub fn DELETE(request: Request) -> @Future<Response> {
    val id = request.param("id");
    await db.post.delete(id);
    return Response(status: 204, body: "");
}
```

---

## F12 — Rakun Middleware

### Middleware de autenticação

```bp
// middleware.bp
import {Request, Response, NextResponse} from "rakun";

#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    val token = request.header("Authorization");
    val path = request.path();

    if (path.startsWith("/dashboard") && token == "") {
        return NextResponse.redirect("/login");
    };

    if (path.startsWith("/api/") && token == "") {
        return Response(status: 401, body: "{\"error\":\"Unauthorized\"}");
    };

    return NextResponse.next();
}

pub val config = MiddlewareConfig(
    matcher: ["/dashboard/*", "/api/*"],
);
```

### Middleware de logging

```bp
// middleware.bp
import {Request, Response, NextResponse} from "rakun";

#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    val start = nowMillis();
    val response = NextResponse.next();
    val duration = nowMillis() - start;
    print(request.method() + " " + request.path() + " — " + duration.toString() + "ms");
    return response;
}
```

---

## F13 — Rakun Cache

### Cache com cacheLife

```bp
// lib/data.bp
import {cacheLife, cacheTag} from "rakun";

#[cache]
#[@future]
pub fn getProducts() -> @Future<Product[]> {
    cacheLife("hours");
    cacheTag("products");
    return await db.product.findAll();
}
```

### Cache com revalidação on-demand

```bp
// lib/actions.bp
import {revalidateTag} from "rakun";

#[serverAction]
#[@future]
pub fn updateProduct(formData: FormData) -> @Future<void> {
    val id = formData.get("id");
    val name = formData.get("name");
    await db.product.update(id, name: name);
    revalidateTag("products");
}
```

---

## F14 — Rakun File Routing

### Estrutura de arquivos

```
app/
├── layout.bp                 → Root layout
├── page.bp                   → / (Home)
├── blog/
│   ├── layout.bp             → Layout do blog
│   ├── page.bp               → /blog
│   └── [slug]/
│       └── page.bp           → /blog/:slug
├── (marketing)/              → Route group
│   └── about/page.bp         → /about
└── api/
    └── posts/route.bp        → /api/posts
```

### Layout aninhado

```bp
// app/blog/layout.bp
import {Element, div, nav, text} from "jhonstart";
import {Link} from "jhonstart";

pub fn BlogLayout(children: Element) -> Element {
    return div([
        nav([
            Link("/blog", [text("Todos os Posts", attrs: [])]),
            Link("/blog/tags", [text("Tags", attrs: [])]),
        ], attrs: []),
        div([children], attrs: []),
    ], attrs: []);
}
```

### Dynamic segment

```bp
// app/blog/[slug]/page.bp
import {Element, div, h1, p, text} from "jhonstart";

#[@future]
pub fn BlogPost(params: Dict<string, string>) -> @Future<Element> {
    val slug = params.get("slug");
    val post = await fetchPost(slug);
    return div([
        h1([text(post.title, attrs: [])], attrs: []),
        p([text(post.content, attrs: [])], attrs: []),
    ], attrs: []);
}
```

---

## F15 — Emilia Attributes

### Decorator #[emilia] em builders

```bp
import {Element, div, h1, p, text} from "jhonstart";
import {emilia, Token} from "emilia";

pub fn Card() -> Element {
    val cardClass = emilia([.Pad.All.4, .Bg.White, .Border.Rounded.Lg, .Effect.Shadow.Md]);
    return div([
        h1([text("Título do Card", attrs: [])], attrs: [
            #("class", emilia([.Text.Size.X2xl, .Text.Bold])),
        ]),
        p([text("Descrição do card aqui.", attrs: [])], attrs: [
            #("class", emilia([.Text.Size.Base, .Color.Gray500])),
        ]),
    ], attrs: [#("class", cardClass)]);
}
```

### Modifiers (hover, responsive)

```bp
import {emilia, Token} from "emilia";

val buttonClass = emilia([
    .Pad.X.4, .Pad.Y.2,
    .Bg.Blue500,
    .Color.White,
    .Border.Rounded.Md,
    .Hover([.Bg.Blue700]),
    .Md([.Pad.X.8, .Pad.Y.4]),
]);
```

---

## F16 — Emilia-Jhonstart Integration

### Atributo [emilia] no html DSL

```bp
import {html, renderToString} from "jhonstart";

val page = html """
<div [emilia]={[.Pad.All.8, .Bg.Gray100]}>
  <h1 [emilia]={[.Text.Size.X3xl, .Text.Bold]}>Título</h1>
  <p [emilia]={[.Text.Size.Base, .Color.Gray500]}>Descrição</p>
  <button [emilia]={[.Pad.X.4, .Pad.Y.2, .Bg.Blue500, .Hover([.Bg.Blue700])]}>
    Clique aqui
  </button>
</div>
""";
```

### Responsivo com modifiers

```bp
val card = html """
<div [emilia]={[.Pad.All.4, .Md([.Pad.All.8]), .Lg([.Pad.All.16])]}>
  <h2 [emilia]={[.Text.Size.Xl, .Md([.Text.Size.X2xl]), .Lg([.Text.Size.X3xl])]}>
    Responsivo
  </h2>
</div>
""";
```

---

## F17 — Std Async Primitives

### Parallel data fetching

```bp
import {async} from "std";

#[@future]
pub fn DashboardPage() -> @Future<Element> {
    val [users, posts, stats] = await async.all([
        fetchUsers(),
        fetchPosts(),
        fetchStats(),
    ]);
    return div([
        renderUsers(users),
        renderPosts(posts),
        renderStats(stats),
    ], attrs: []);
}
```

### allSettled (não falha rápido)

```bp
import {async} from "std";

#[@future]
pub fn AggregatedPage() -> @Future<Element> {
    val results = await async.allSettled([
        fetchFromServiceA(),
        fetchFromServiceB(),
        fetchFromServiceC(),
    ]);
    val validResults = results.filter({ r -> r.isOk() }).map({ r -> r.unwrap() });
    return div([
        // renderiza apenas os que succeeded
    ], attrs: []);
}
```

---

## F18 — Std Content Hash

### Cache key generation

```bp
import {contentHash} from "std";

val key = contentHash("user:123:profile");
// → "a1b2c3d4"
```

### ETag generation

```bp
import {contentHash} from "std";

#[@future]
pub fn GET(request: Request) -> @Future<Response> {
    val data = await fetchData();
    val etag = contentHash(json.stringify(data));
    return Response.json(json.stringify(data)).withHeader("ETag", "\"" + etag + "\"");
}
```

---

## F19 — Onze13 CLI

### Criando um novo projeto

```bash
onze13 create my-app
cd my-app
onze13 dev
```

### layout.bp gerado

```bp
// app/layout.bp
import {Element, html, head, body, text} from "jhonstart";
import {googleFont} from "onze13";

val inter = googleFont("Inter", subsets: ["latin"]);

pub fn RootLayout(children: Element) -> Element {
    return html([
        head([text("", attrs: [])], attrs: []),
        body([children], attrs: [#("class", inter.className)]),
    ], attrs: [#("lang", "pt-BR")]);
}
```

### page.bp gerado

```bp
// app/page.bp
import {Element, div, h1, p, text} from "jhonstart";
import {emilia, Token} from "emilia";

pub fn HomePage() -> Element {
    return div([
        h1([text("Bem-vindo ao onze13!", attrs: [])], attrs: [
            #("class", emilia([.Text.Size.X4xl, .Text.Bold])),
        ]),
        p([text("Edite app/page.bp para começar.", attrs: [])], attrs: [
            #("class", emilia([.Text.Size.Lg, .Color.Gray500])),
        ]),
    ], attrs: [#("class", emilia([.Pad.All.8]))]);
}
```

---

## F20 — Onze13 Image Optimization

### Componente Image

```bp
import {Image} from "onze13";
import {Element, div} from "jhonstart";

pub fn HeroSection() -> Element {
    return div([
        Image(ImageProps(
            src: "/images/hero.jpg",
            alt: "Hero banner",
            width: 1200,
            height: 600,
            priority: true,
            quality: 80,
            sizes: "(max-width: 768px) 100vw, 50vw",
        )),
    ], attrs: []);
}
```

---

## F21 — Onze13 Font Optimization

### Google Fonts

```bp
// app/layout.bp
import {googleFont} from "onze13";
import {Element, html, head, body, style, text} from "jhonstart";

val inter = googleFont("Inter", subsets: ["latin"]);
val firaCode = googleFont("Fira Code", subsets: ["latin"]);

pub fn RootLayout(children: Element) -> Element {
    return html([
        head([
            style([text(inter.css + firaCode.css, attrs: [])], attrs: []),
        ], attrs: []),
        body([
            div([children], attrs: [#("class", inter.className)]),
        ], attrs: []),
    ], attrs: [#("lang", "pt-BR")]);
}
```

### Local Font

```bp
import {localFont} from "onze13";

val myBrandFont = localFont(LocalFontOptions(
    src: "./fonts/BrandFont.woff2",
    weight: "400",
    style: "normal",
    display: "swap",
));
```

---

## F22 — Onze13 Example App (Blog Completo)

### app/layout.bp

```bp
import {Element, html, head, body, div, style, text} from "jhonstart";
import {googleFont} from "onze13";
import {flush} from "emilia";
import {Link} from "jhonstart";
import {emilia, Token} from "emilia";

val inter = googleFont("Inter", subsets: ["latin"]);

#[@future]
pub fn RootLayout(children: Element) -> @Future<Element> {
    val styles = await flush();
    val navClass = emilia([.Layout.Flex, .Flex.Row, .Flex.Justify.Between, .Pad.X.8, .Pad.Y.4]);
    return html([
        head([
            style([text(inter.css + styles, attrs: [])], attrs: []),
        ], attrs: []),
        body([
            nav([
                Link("/", [text("Meu Blog", attrs: [])]),
                div([
                    Link("/blog", [text("Posts", attrs: [])]),
                    Link("/about", [text("Sobre", attrs: [])]),
                ], attrs: [#("class", emilia([.Layout.Flex, .Flex.Row, .Flex.Gap.4]))]),
            ], attrs: [#("class", navClass)]),
            div([children], attrs: [#("class", emilia([.Pad.All.8]))]),
        ], attrs: [#("class", inter.className)]),
    ], attrs: [#("lang", "pt-BR")]);
}
```

### app/blog/page.bp

```bp
import {Element, div, h1, ul, li, text} from "jhonstart";
import {cacheLife, cacheTag} from "rakun";
import {emilia, Token} from "emilia";
import {PostCard} from "@/components/post-card";

#[@future]
pub fn BlogPage() -> @Future<Element> {
    cacheLife("hours");
    cacheTag("posts");
    val posts = await db.post.findAll();
    return div([
        h1([text("Blog", attrs: [])], attrs: [
            #("class", emilia([.Text.Size.X3xl, .Text.Bold])),
        ]),
        ul(
            posts.map({ post ->
                li([PostCard(post)], attrs: [#("class", emilia([.Pad.Y.4]))])
            }),
            attrs: [],
        ),
    ], attrs: []);
}
```

### components/post-card.bp

```bp
import {Element, div, h2, p, text} from "jhonstart";
import {Link} from "jhonstart";
import {emilia, Token} from "emilia";

pub fn PostCard(post: Post) -> Element {
    val cardClass = emilia([
        .Pad.All.4, .Bg.White,
        .Border.Rounded.Lg, .Border.W.1, .Border.Color.Gray100,
        .Hover([.Effect.Shadow.Md]),
    ]);
    return Link("/blog/" + post.slug, div([
        h2([text(post.title, attrs: [])], attrs: [
            #("class", emilia([.Text.Size.Xl, .Text.Bold])),
        ]),
        p([text(post.excerpt, attrs: [])], attrs: [
            #("class", emilia([.Color.Gray500, .Pad.Y.2])),
        ]),
    ], attrs: [#("class", cardClass)]));
}
```

### middleware.bp

```bp
import {Request, Response, NextResponse} from "rakun";

#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    val path = request.path();
    val sessionCookie = request.cookie("session");

    if (path.startsWith("/dashboard") && sessionCookie == "") {
        return NextResponse.redirect("/login");
    };

    return NextResponse.next();
}

pub val config = MiddlewareConfig(
    matcher: ["/dashboard/*"],
);
```
