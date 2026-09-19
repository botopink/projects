# Front 22 — Onze13 Example App

**Referência Next.js:** [Next.js Learn](https://nextjs.org/learn) · [Dashboard App Tutorial](https://nextjs.org/learn/dashboard-app)

**Priority:** medium — example app validates the entire stack
**Depends on:** ALL previous fronts
**Owns:** `repository/onze13/examples/blog/**`
**Does not touch:** `onze13/src/**`, jhonstart, rakun, emilia, std

---

## Problem

We need a complete example app that exercises all onze13 features: file-system routing, server components, server actions, caching, middleware, emilia styling, image optimization, font optimization. This validates the entire stack works together.

## Current state

- No complete onze13 example exists
- Individual features are tested in isolation
- No integration test

## Mechanism

Create a blog app that demonstrates:
- File-system routing (pages, layouts, dynamic segments)
- Server components (data fetching)
- Client components (interactivity)
- Server actions (form submissions)
- Caching (cacheLife, cacheTag, revalidation)
- Middleware (auth, redirects)
- Emilia styling (Token-based CSS)
- Image optimization (Image component)
- Font optimization (googleFont, localFont)
- Error handling (error boundaries, not-found)
- Metadata (SEO, OG images)

## Exemplos em bp

### app/layout.bp

```bp
val inter = googleFont("Inter", subsets: ["latin"]);

#[@future]
pub fn RootLayout(children: Element) -> @Future<Element> {
    val styles = await flush();
    return html([
        head([style([text(inter.css + styles)])]),
        body([
            nav([Link("/", [text("Blog")])]),
            div([children], attrs: [#("class", inter.className)]),
        ]),
    ], attrs: []);
}
```

### app/blog/page.bp

```bp
#[@future]
pub fn BlogPage() -> @Future<Element> {
    cacheLife("hours");
    cacheTag("posts");
    val posts = await db.post.findAll();
    return div([
        h1([text("Blog")]),
        ul(posts.map({ p -> li([PostCard(p)]) })),
    ], attrs: []);
}
```

### middleware.bp

```bp
#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    if (request.path().startsWith("/dashboard") && request.cookie("session") == "") {
        return NextResponse.redirect("/login");
    };
    return NextResponse.next();
}
```

## Steps

### Step 1 — App structure

```
examples/blog/
├── botopink.json
├── onze13.json
├── app/
│   ├── layout.bp              # Root layout (fonts, global styles)
│   ├── page.bp                # Home page
│   ├── loading.bp             # Global loading
│   ├── error.bp               # Global error
│   ├── not-found.bp           # Global 404
│   ├── globals.bp             # Global emilia styles
│   ├── blog/
│   │   ├── layout.bp          # Blog layout
│   │   ├── page.bp            # Blog list (server component)
│   │   ├── loading.bp         # Blog loading
│   │   └── [slug]/
│   │       ├── page.bp        # Blog post (server component)
│   │       ├── loading.bp     # Post loading
│   │       └── not-found.bp   # Post not found
│   ├── about/
│   │   └── page.bp            # About page
│   ├── dashboard/
│   │   ├── layout.bp          # Dashboard layout (auth required)
│   │   ├── page.bp            # Dashboard home
│   │   └── posts/
│   │       └── new/
│   │           └── page.bp    # Create post form (server action)
│   └── api/
│       └── posts/
│           └── route.bp       # API endpoint
├── components/
│   ├── PostCard.bp            # Reusable component
│   └── LikeButton.bp          # Client component
├── lib/
│   ├── auth.bp                # Auth utilities
│   ├── db.bp                  # Database (mock)
│   └── actions.bp             # Server actions
├── middleware.bp               # Auth middleware
└── public/
    └── images/
        └── hero.jpg           # Sample image
```

**Acceptance:**
- [ ] App structure created
- [ ] All files present

### Step 2 — Root layout (fonts + global styles)

```bp
// app/layout.bp
import {googleFont} from "onze13";
import {html} from "jhonstart";
import {emilia, flush} from "emilia";

val inter = googleFont("Inter", subsets: ["latin"]);

pub fn RootLayout(children: Element) -> Element {
    return html """
<html>
  <head>
    <style>${inter.css}</style>
  </head>
  <body class="${inter.className}">
    ${children}
  </body>
</html>
""";
}
```

**Acceptance:**
- [ ] Fonts are loaded
- [ ] Global styles applied

### Step 3 — Server component (data fetching)

```bp
// app/blog/page.bp
import {cacheLife, cacheTag} from "rakun";

#[@future]
pub fn BlogPage() -> @Future<Element> {
    cacheLife("hours");
    cacheTag("posts");
    val posts = await db.post.findAll();
    return div([
        h1([text("Blog", attrs: [])], attrs: []),
        ul(posts.map({ post -> 
            li([PostCard(post)], attrs: [])
        }), attrs: []),
    ], attrs: []);
}
```

**Acceptance:**
- [ ] Data is fetched on server
- [ ] Caching works

### Step 4 — Client component (interactivity)

```bp
// components/LikeButton.bp
#[client]
pub fn LikeButton(postId: string) -> Element {
    val likes = use state(0);
    return button([
        text(likes.value.toString() + " likes", attrs: [])
    ], attrs: [
        #("onClick", "incrementLikes"),
    ]);
}
```

**Acceptance:**
- [ ] Client component renders
- [ ] Interactivity works

### Step 5 — Server action (form submission)

```bp
// lib/actions.bp
#[serverAction]
#[@future]
pub fn createPost(formData: FormData) -> @Future<void> {
    val title = formData.get("title");
    val content = formData.get("content");
    await db.post.create(title, content);
    revalidateTag("posts");
    redirect("/blog");
}
```

**Acceptance:**
- [ ] Form submits to server action
- [ ] Data is created
- [ ] Cache is revalidated
- [ ] Redirect works

### Step 6 — Middleware (auth)

```bp
// middleware.bp
#[@future]
pub fn middleware(request: Request) -> @Future<Response> {
    val token = request.cookie("session");
    if (token == null && request.path().startsWith("/dashboard")) {
        return NextResponse.redirect("/login");
    };
    return NextResponse.next();
}
```

**Acceptance:**
- [ ] Middleware protects routes
- [ ] Redirects work

### Step 7 — Emilia styling

```bp
// components/PostCard.bp
import {emilia} from "emilia";

pub fn PostCard(post: Post) -> Element {
    val cardClass = emilia([.Pad.All.4, .Bg.White, .Border.Rounded.Md]);
    return div([
        h2([text(post.title, attrs: [])], attrs: []),
        p([text(post.excerpt, attrs: [])], attrs: []),
    ], attrs: [#("class", cardClass)]);
}
```

**Acceptance:**
- [ ] Emilia styles applied
- [ ] CSS is generated

### Step 8 — Image optimization

```bp
// app/page.bp
import {Image} from "onze13";

pub fn HomePage() -> Element {
    return div([
        Image(ImageProps(
            src: "/images/hero.jpg",
            alt: "Hero",
            width: 1200,
            height: 600,
            priority: true,
            quality: 80,
            sizes: "",
        )),
        h1([text("Welcome to the Blog", attrs: [])], attrs: []),
    ], attrs: []);
}
```

**Acceptance:**
- [ ] Image is optimized
- [ ] Lazy loading works

### Step 9 — Error handling

```bp
// app/blog/[slug]/not-found.bp
pub fn NotFound() -> Element {
    return div([
        h1([text("Post Not Found", attrs: [])], attrs: []),
        p([text("The post you're looking for doesn't exist.", attrs: [])], attrs: []),
    ], attrs: []);
}
```

**Acceptance:**
- [ ] 404 page renders
- [ ] Error boundaries catch errors

### Step 10 — Metadata (SEO)

```bp
// app/blog/[slug]/page.bp
import {Metadata} from "jhonstart";

#[@future]
pub fn generateMetadata(params: Dict<string, string>) -> @Future<Metadata> {
    val slug = params.get("slug");
    val post = await db.post.findBySlug(slug);
    return Metadata(
        title: post.title,
        description: post.excerpt,
        openGraph: OpenGraph(
            title: post.title,
            description: post.excerpt,
            images: ["/og/" + slug + ".png"],
            url: "/blog/" + slug,
            type: "article",
        ),
        twitter: TwitterCard(card: "summary_large_image", title: post.title, description: post.excerpt, images: []),
        icons: Icons(icon: "/favicon.ico", apple: "/apple-icon.png"),
    );
}
```

**Acceptance:**
- [ ] Metadata is generated
- [ ] SEO tags are in `<head>`

### Step 11 — Run the app

```bash
cd examples/blog
onze13 dev
```

**Acceptance:**
- [ ] App runs without errors
- [ ] All pages render
- [ ] Navigation works
- [ ] Forms submit
- [ ] Images load
- [ ] Fonts render

### Step 12 — Build for production

```bash
onze13 build
onze13 start
```

**Acceptance:**
- [ ] Build succeeds
- [ ] Production server starts
- [ ] App works in production

## Gate

- [ ] App runs in dev mode
- [ ] App builds for production
- [ ] All features work end-to-end
- [ ] AGENTS.md updated
- [ ] Commit on `fix/onze13-example-app`

## Blast radius

- New directory `examples/blog/`
- No changes to existing code
- Validates the entire stack

## Notes

- This is the integration test — if this works, everything works.
- The example uses a mock database (in-memory) for simplicity.
- Future: add authentication, database integration, deployment guide.
