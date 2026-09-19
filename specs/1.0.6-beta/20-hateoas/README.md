# Front 20 — HATEOAS (Hypermedia)

**Priority:** low — services need hypermedia-driven REST APIs
**Depends on:** F04 (web-middleware)
**Owns:** `modules/rakun-hateoas/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

REST APIs often need hypermedia links (HATEOAS — Hypermedia as the Engine of Application State). Clients discover available actions via links in responses. Spring Boot provides `spring-boot-starter-hateoas` with HAL support.

## Mechanism

Spring Boot HATEOAS:
- `RepresentationModel<T>` → resource with links
- `Link` → hypermedia link (rel, href)
- `linkTo(methodOn(Controller.class))` → build links
- HAL format (`_links`, `_embedded`)

Rakun will implement:
- **Link** type
- **RepresentationModel** type
- **linkTo** helper
- HAL JSON format

## Steps

### Step 1 — Link type

```bp
// hateoas.bp
pub type Link(
    rel: string,
    href: string,
    type: ?string,     // media type
    name: ?string,     // link name
)

pub type Links(
    self: Link,
    others: Array<Link>,
)
```

### Step 2 — RepresentationModel

```bp
pub type RepresentationModel<T>(
    content: T,
    links: Array<Link>,
)

// Usage:
val user = User(id: 1, name: "Alice");
val model = RepresentationModel(
    content: user,
    links: [
        Link(rel: "self", href: "/api/users/1"),
        Link(rel: "orders", href: "/api/users/1/orders"),
    ],
);
```

### Step 3 — HAL JSON format

```json
{
    "id": 1,
    "name": "Alice",
    "_links": {
        "self": { "href": "/api/users/1" },
        "orders": { "href": "/api/users/1/orders" }
    }
}
```

Serialization:
```bp
pub fn toHal<T>(model: RepresentationModel<T>) -> string {
    val contentJson = json.stringify(model.content);
    val linksJson = model.links.fold("{}", { acc, link ->
        acc + "\"" + link.rel + "\": {\"href\": \"" + link.href + "\"},";
    });
    return contentJson.substring(0, contentJson.length - 1) + ", \"_links\": {" + linksJson + "}}";
}
```

### Step 4 — linkTo helper

```bp
pub fn linkTo(controller: type, method: string, params: Array<string>) -> Link {
    // build link from controller route + method mapping
    val route = rkGetRoute(controller, method);
    val href = interpolate(route, params);
    return Link(rel: "self", href: href);
}
```

### Step 5 — CollectionModel

```bp
pub type CollectionModel<T>(
    content: Array<T>,
    links: Array<Link>,
)

// HAL format for collections:
{
    "_embedded": {
        "users": [
            { "id": 1, "name": "Alice", "_links": {...} },
            { "id": 2, "name": "Bob", "_links": {...} }
        ]
    },
    "_links": {
        "self": { "href": "/api/users" }
    }
}
```

### Step 6 — Module structure

```
modules/rakun-hateoas/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── link.bp
│   ├── representation_model.bp
│   ├── collection_model.bp
│   └── hal_serializer.bp
└── test/
    └── hateoas_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] Link type works
- [ ] RepresentationModel serializes to HAL
- [ ] CollectionModel serializes to HAL
- [ ] linkTo helper builds links

## Notes

- HAL format (Hypertext Application Language)
- Other formats: JSON:API, Collection+JSON (later)
- linkTo: needs route introspection (uses runtime registry)
- Affordances: action links with method, content-type (later)
