# Front 03 — Context API & Application Events

**Priority:** high — enables programmatic bean resolution, lifecycle hooks, and event-driven architecture
**Depends on:** F01 (erlang-runtime), F02 (config-profiles)
**Owns:** `src/context.bp`, `src/events.bp`, `src/lifecycle.bp`, `src/rakun.d.bp` (update)
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp` (only reads router)

---

## Problem

Rakun's IoC container is implicit — components are auto-wired by constructor injection, but there is no way to:
- Programmatically resolve a bean by type (`ctx.resolve<UserRepository>()`)
- Check if a bean exists (`ctx.has<UserRepository>()`)
- Hook into application lifecycle (startup, shutdown)
- Publish/subscribe to application events

The `Context` behavior exists in `rakun.d.bp` as a declaration-only stub but has no implementation.

## Current state

- `rakun.d.bp` declares `behavior Context { fn resolve<T>() -> ?T; fn has<T>() -> bool; }` — signatures only, no body
- DI is purely constructor-injection — no programmatic access
- No lifecycle hooks (startup/shutdown callbacks)
- No event system
- Singleton cache lives in `runtime.mjs`/`runtime.erl` — not accessible from BP code

## Mechanism

Spring Boot's `ApplicationContext` provides:
- `getBean(Class<T>)` → resolve by type
- `containsBean(String)` → check existence
- `ApplicationListener` → lifecycle events
- `ApplicationEventPublisher` → publish events

Rakun will implement:
- **Context** as a concrete type (not just behavior) that wraps the runtime registries
- **Lifecycle** callbacks via `#[postConstruct]` and `#[preDestroy]` decorators
- **Events** via `ApplicationEvent` type and `@EventListener` decorator

## Steps

### Step 1 — Concrete Context type

Replace declaration-only `Context` with a concrete implementation:

```bp
// context.bp
pub type Context {
    pub fn resolve<T>(self: Self) -> ?T {
        // call rkResolve<T>() runtime fn
    }

    pub fn has<T>(self: Self) -> bool {
        // call rkHas<T>() runtime fn
    }

    pub fn getBeanNames(self: Self) -> Array<string> {
        // call rkScannedNames()
    }
}
```

Runtime side (Node.js):
```js
export function resolve(name) {
    const factory = factories.get(name);
    return factory ? factory() : null;
}
```

Runtime side (Erlang):
```erlang
resolve(Name) ->
    case ets:lookup(?SINGLETON_TABLE, Name) of
        [{_, Value}] -> Value;
        [] ->
            case ets:lookup(?SCAN_TABLE, Name) of
                [{_, _}] ->
                    Factory = erlang:list_to_existing_atom("__rkMake_" ++ Name),
                    Factory();
                [] -> undefined
            end
    end.
```

**Acceptance:**
- [ ] `ctx.resolve<UserRepository>()` returns the singleton instance
- [ ] `ctx.has<UserRepository>()` returns true for registered components
- [ ] `ctx.has<UnregisteredType>()` returns false
- [ ] Works on both commonJS and Erlang

### Step 2 — Context injection

Make `Context` injectable like any other component:

```bp
#[service]
pub type MyService(ctx: Context) {
    pub fn doSomething(self: Self) {
        val repo = self.ctx.resolve<UserRepository>();
        // use repo
    }
}
```

**Acceptance:**
- [ ] `Context` can be a constructor parameter
- [ ] Resolved context can resolve other beans
- [ ] No cycle detection issues (Context is not a regular component)

### Step 3 — Lifecycle decorators

Add `#[postConstruct]` and `#[preDestroy]` decorators:

```bp
#[service]
pub type MyService {
    #[postConstruct]
    pub fn init(self: Self) {
        // called after construction
    }

    #[preDestroy]
    pub fn cleanup(self: Self) {
        // called before shutdown
    }
}
```

Implementation: decorator emits a registration call:
```bp
pub fn postConstruct(comptime decl: @Decl) {
    @emit("val __rkPostConstruct_" + decl.name + " = rkRegisterLifecycle(\"" + decl.name + "\", \"postConstruct\", { instance -> instance." + decl.name + "() });");
    if (decl.kind != DeclKind.Method) decl.fail("#[postConstruct] must annotate a method");
}
```

**Acceptance:**
- [ ] `#[postConstruct]` method called after singleton construction
- [ ] `#[preDestroy]` method called on shutdown
- [ ] Lifecycle methods can access injected dependencies
- [ ] Works on both targets

### Step 4 — Application events

Define event types and publisher:

```bp
// events.bp
pub type ApplicationEvent(
    source: string,
    timestamp: i64,
)

pub type ApplicationStartedEvent(source: string, timestamp: i64)
pub type ApplicationReadyEvent(source: string, timestamp: i64)
pub type ContextRefreshedEvent(source: string, timestamp: i64)

pub behavior ApplicationEventPublisher {
    fn publishEvent(self: Self, event: ApplicationEvent);
}
```

**Acceptance:**
- [ ] Event types defined
- [ ] `ApplicationEventPublisher` behavior declared
- [ ] Events can be published and received

### Step 5 — @EventListener decorator

```bp
#[service]
pub type MyListener {
    #[eventListener]
    pub fn onStarted(self: Self, event: ApplicationStartedEvent) {
        // handle event
    }
}
```

Implementation: decorator scans for `#[eventListener]` methods and registers them:

```bp
pub fn eventListener(comptime decl: @Decl) {
    val eventType = decl.parameters[0].typeName;
    @emit("val __rkEventListener_" + decl.name + " = rkRegisterEventListener(\"" + eventType + "\", { event -> __rkMake_" + /* owner type */ "()." + decl.name + "(event) });");
    if (decl.kind != DeclKind.Method) decl.fail("#[eventListener] must annotate a method");
}
```

**Acceptance:**
- [ ] `#[eventListener]` method called when matching event published
- [ ] Multiple listeners for same event type all called
- [ ] Event type matching is exact (no inheritance yet)

### Step 6 — Bootstrap event publishing

`Rakun.run()` publishes lifecycle events:

```bp
pub fn run(app: App) {
    rkLoadConfig();
    rkPublishEvent(ApplicationStartedEvent(...));
    val _port = rkServe(app.port, ...);
    rkPublishEvent(ApplicationReadyEvent(...));
}
```

**Acceptance:**
- [ ] `ApplicationStartedEvent` published before server starts
- [ ] `ApplicationReadyEvent` published after server is listening
- [ ] Listeners receive events in registration order

### Step 7 — Graceful shutdown

On SIGTERM/SIGINT, call `#[preDestroy]` methods and publish shutdown event:

```bp
// runtime.mjs
process.on('SIGTERM', () => {
    invokePreDestroy();
    publishEvent(new ApplicationStoppedEvent());
    server.close();
});
```

```erlang
% runtime.erl
application:set_env(rakun, shutdown_hook, fun() ->
    invoke_pre_destroy(),
    publish_event(application_stopped),
    cowboy:stop_listener(rakun_http)
end).
```

**Acceptance:**
- [ ] SIGTERM triggers `#[preDestroy]` methods
- [ ] Shutdown completes gracefully (in-flight requests finish)
- [ ] Works on both targets

## Gate

- [ ] `botopink test --target commonJS` green
- [ ] `botopink test --target erlang` green
- [ ] `ctx.resolve<T>()` works for all registered components
- [ ] `#[postConstruct]` and `#[preDestroy]` called at correct times
- [ ] `#[eventListener]` receives published events
- [ ] Graceful shutdown on SIGTERM

## Blast radius

- **rakun-core** gains `context.bp`, `events.bp`, `lifecycle.bp` — new files
- **`rakun.d.bp`** updated: `Context` moves from declaration-only to concrete
- **Decorators** gain `#[postConstruct]`, `#[preDestroy]`, `#[eventListener]`
- **Runtime** gains lifecycle registry and event bus
- **Bootstrap** publishes lifecycle events

## Notes

- `Context` is a special component — not subject to cycle detection (it's a meta-component)
- Events are synchronous for now (async events later)
- No event inheritance matching yet (exact type match only)
- Lifecycle order: `@postConstruct` in dependency order, `@preDestroy` in reverse
- SIGTERM handling: Node.js `process.on`, Erlang `application:set_env` + trap_exit
