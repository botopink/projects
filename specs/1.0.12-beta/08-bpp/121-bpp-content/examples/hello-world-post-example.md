---
# Front 121 — bpp content · examples/hello-world-post-example.md
# App file: content/blog/hello-world.md
#
# One entry of the `blog` collection of `content-collection-example.bp`. The
# block between the fences is YAML and is decoded with the collection's schema
# (`BlogPost`); everything after it is the body, rendered by `render(entry)`.
# This file's path under the loader's base, without its extension, is the
# entry's id: `hello-world`.
title: Hello, world
description: The first post of the blog. It says hello.
pubDate: 2026-01-10T12:00:00Z
author: ana
---

The first post of the blog. It says hello — and unlike the three lines
`parsePost` reads today, it can say it with a **list**, a [link](/about) and a
heading.

## First steps

1. Write a file under `content/blog/`.
2. Run `onze sync` (or `onze build`, which runs it).
3. Read it with `getCollection(blog())`.

```bp
val posts = await getCollection(blog());
```

![The cover](./hello-world-cover.png)
