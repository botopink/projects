# Front 10 — Rakun Server Actions

**Referência Next.js:** [Mutating Data](https://nextjs.org/docs/app/getting-started/mutating-data) · [Server Actions](https://nextjs.org/docs/app/guides/server-actions) · ["use server"](https://nextjs.org/docs/app/api-reference/directives/use-server)

**Priority:** critical — server actions enable form submissions and mutations
**Depends on:** F09 (rakun-ssr-pipeline)
**Owns:** `repository/rakun/src/actions.bp`, `repository/rakun/src/actions.mjs`
**Does not touch:** `runtime.bp`, `ssr.bp`, `file_router.bp`, `http.bp`, `bootstrap.bp`

---

## Problem

Forms need to submit data to the server. Next.js uses Server Actions — functions marked with `'use server'` that can be called from forms. Rakun needs an equivalent mechanism.

## Current state

- Rakun has route handlers (API endpoints) but no form-specific action handling
- No `'use server'` directive equivalent
- Forms would need to manually POST to API routes

## Mechanism

Introduce `#[serverAction]` decorator:
- Marks a function as a server action
- The function can be passed to a form's `action` attribute
- On form submission, the action is invoked on the server
- The action can mutate data, revalidate cache, redirect

```bp
// lib/actions.bp
#[serverAction]
#[@future]
pub fn createPost(formData: FormData) -> @Future<void> {
    val title = formData.get("title");
    val content = formData.get("content");
    await db.post.create(title, content);
    revalidatePath("/posts");
}
```

```bp
// app/posts/new/page.bp
import {createPost} from "@/lib/actions";

pub fn NewPostPage() -> Element {
    return form([
        input([attrs: [#("type", "text"), #("name", "title")]]),
        textarea([attrs: [#("name", "content")]]),
        button([text("Create", attrs: [])], attrs: [#("type", "submit")]),
    ], attrs: [#("action", "createPost")]);
}
```

## Exemplos em bp

### Action simples

```bp
#[serverAction]
#[@future]
pub fn createPost(formData: FormData) -> @Future<void> {
    val title = formData.get("title");
    await db.post.create(title: title);
    revalidatePath("/blog");
}
```

### Formulário usando a action

```bp
pub fn NewPostForm() -> Element {
    return form([
        input([attrs: [#("name", "title")]]),
        button([text("Criar")], attrs: [#("type", "submit")]),
    ], attrs: [#("action", "createPost")]);
}
```

## Steps

### Step 1 — #[serverAction] decorator

```bp
// src/actions.bp
pub fn serverAction(comptime decl: @Decl) {
    if (decl.kind != DeclKind.Fn) decl.fail("#[serverAction] must annotate a function");
    // Emit registration: this function is a server action
    @emit("val __rakun_action_" + decl.name + " = rkRegisterAction(\"" + decl.name + "\", " + decl.name + ");");
}
```

**Acceptance:**
- [ ] `#[serverAction]` decorator compiles
- [ ] Can be applied to async functions
- [ ] Emits registration code

### Step 2 — Action registry (host runtime)

```bp
// src/actions.mjs (sidecar)
const actions = new Map();

export function registerAction(name, fn) {
    actions.set(name, fn);
    return 0;
}

export async function invokeAction(name, formData) {
    const fn = actions.get(name);
    if (!fn) throw new Error(`Action '${name}' not found`);
    return await fn(formData);
}
```

```bp
// src/actions.bp
#[@External.Node("rakun/actions", "registerAction")]
#[@External.Erlang("rakun_actions", "register_action")]
declare fn rkRegisterAction(name: string, fn: fn(FormData) -> @Future<void>) -> void;

#[@External.Node("rakun/actions", "invokeAction")]
#[@External.Erlang("rakun_actions", "invoke_action")]
declare fn rkInvokeAction(name: string, formData: FormData) -> @Future<void>;
```

**Acceptance:**
- [ ] Actions can be registered
- [ ] Actions can be invoked by name
- [ ] Host cells declared for both targets

### Step 3 — Form action handling

When a form with `action="createPost"` is submitted:
1. The browser POSTs to the current URL with `action=createPost` in the body
2. The SSR pipeline detects the action and invokes it
3. After the action completes, the page is re-rendered

```bp
// In SSR pipeline (ssr.bp)
#[@future]
pub fn handleFormSubmission(path: string, formData: FormData) -> @Future<void> {
    val actionName = formData.get("_action");
    await rkInvokeAction(actionName, formData);
}
```

**Acceptance:**
- [ ] Form submissions invoke the correct action
- [ ] Page re-renders after action completes

### Step 4 — revalidatePath / revalidateTag

```bp
#[@External.Node("rakun/cache", "revalidatePath")]
#[@External.Erlang("rakun_cache", "revalidate_path")]
declare fn revalidatePath(path: string) -> void;

#[@External.Node("rakun/cache", "revalidateTag")]
#[@External.Erlang("rakun_cache", "revalidate_tag")]
declare fn revalidateTag(tag: string) -> void;
```

**Acceptance:**
- [ ] `revalidatePath` and `revalidateTag` declared
- [ ] Can be called from server actions

### Step 5 — Tests

```bp
test "#[serverAction] decorator can be applied" {
    #[serverAction]
    #[@future]
    fn testAction(formData: FormData) -> @Future<void> {
        // no-op
    }
    assert true;
}
```

**Acceptance:**
- [ ] Tests pass on commonJS + erlang

## Gate

- [ ] `botopink test` green
- [ ] `actions.bp` and `actions.mjs` in place
- [ ] Form submissions work end-to-end
- [ ] AGENTS.md updated
- [ ] Commit on `fix/rakun-server-actions`

## Blast radius

- New files `actions.bp`, `actions.mjs`
- SSR pipeline updated to handle form submissions
- No breaking changes to existing route handlers

## Notes

- Server actions are POST-only (forms use POST).
- The action name is passed as a hidden field (`_action`) in the form.
- Revalidation (cache invalidation) is a separate concern (F13), but actions can trigger it.
