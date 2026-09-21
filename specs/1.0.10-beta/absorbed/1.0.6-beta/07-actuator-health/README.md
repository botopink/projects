# Front 07 — Actuator (Health, Metrics, Info)

**Priority:** medium — production services need monitoring and observability
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-actuator/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no built-in monitoring. Services cannot:
- Expose health checks (for Kubernetes, load balancers)
- Expose metrics (for Prometheus, Grafana)
- Expose application info (version, environment)
- Diagnose issues at runtime

Spring Boot provides `spring-boot-starter-actuator` with comprehensive monitoring. Rakun needs equivalent for Erlang/BEAM.

## Current state

- No health endpoints
- No metrics
- No info endpoint
- No way to check if service is healthy
- Example app has no monitoring

## Mechanism

Spring Boot Actuator:
- `/actuator/health` → health check (UP, DOWN, OUT_OF_SERVICE)
- `/actuator/info` → application info
- `/actuator/metrics` → metrics (JVM, HTTP, custom)
- `/actuator/env` → environment properties
- `/actuator/beans` → list of beans

Rakun will implement:
- **Health** → health indicators (DB, disk, custom)
- **Info** → application info (version, build)
- **Metrics** → basic metrics (request count, duration)
- **Env** → environment properties (sanitized)
- **Beans** → list of beans

## Steps

### Step 1 — Health endpoint

```bp
// health.bp
pub type Health(
    status: string,  // UP, DOWN, OUT_OF_SERVICE, UNKNOWN
    details: Dict<string, string>,
)

pub behavior HealthIndicator {
    fn health(self: Self) -> Health;
}

#[restController]
#[route("/actuator")]
pub type HealthController(indicators: Array<HealthIndicator>) {
    #[getMapping("/health")]
    pub fn health(self: Self, req: Request) -> Response {
        val statuses = self.indicators.map({ i -> i.health() });
        val overall = aggregateStatus(statuses);
        return Response.json(stringify(Health(
            status: overall,
            details: mergeDetails(statuses),
        )));
    }
}
```

Built-in indicators:
```bp
#[component]
pub type DiskSpaceHealthIndicator {
    pub fn health(self: Self) -> Health {
        val free = fs.diskFree();
        val threshold = 100 * 1024 * 1024;  // 100 MB
        return if (free < threshold) Health(status: "DOWN", details: {"free": free.toString()})
            else Health(status: "UP", details: {"free": free.toString()});
    }
}
```

**Acceptance:**
- [ ] `/actuator/health` returns health status
- [ ] Health indicators registered
- [ ] Overall status aggregated (DOWN if any DOWN)
- [ ] Disk space indicator works
- [ ] Custom indicators can be added

### Step 2 — Database health indicator

```bp
#[component]
pub type DataSourceHealthIndicator(dataSource: DataSource) {
    pub fn health(self: Self) -> Health {
        val conn = self.dataSource.getConnection();
        return match conn {
            @Ok(c) => {
                c.close();
                Health(status: "UP", details: {"database": "connected"});
            }
            @Err(e) => Health(status: "DOWN", details: {"error": e});
        };
    }
}
```

**Acceptance:**
- [ ] DataSource health indicator checks connection
- [ ] UP when connection succeeds
- [ ] DOWN when connection fails
- [ ] Error message included in details

### Step 3 — Info endpoint

```bp
// info.bp
pub behavior InfoContributor {
    fn contribute(self: Self) -> Dict<string, string>;
}

#[restController]
#[route("/actuator")]
pub type InfoController(contributors: Array<InfoContributor>) {
    #[getMapping("/info")]
    pub fn info(self: Self, req: Request) -> Response {
        val info = contributors.fold(Dict.empty(), { acc, c -> acc.merge(c.contribute()) });
        return Response.json(stringify(info));
    }
}
```

Built-in contributors:
```bp
#[component]
pub type BuildInfoContributor {
    pub fn contribute(self: Self) -> Dict<string, string> {
        return Dict.empty()
            .insert("version", "1.0.0")
            .insert("buildTime", "2026-01-01T00:00:00Z");
    }
}

#[component]
pub type EnvInfoContributor {
    pub fn contribute(self: Self) -> Dict<string, string> {
        return Dict.empty()
            .insert("profile", rkProp("rakun.profiles.active"))
            .insert("java.version", erlang.systemInfo("version"));
    }
}
```

**Acceptance:**
- [ ] `/actuator/info` returns application info
- [ ] Build info included (version, build time)
- [ ] Env info included (profile, runtime version)
- [ ] Custom contributors can be added

### Step 4 — Metrics endpoint

```bp
// metrics.bp
pub type Counter(
    name: string,
    tags: Dict<string, string>,
) {
    pub fn increment(self: Self);
    pub fn count(self: Self) -> i64;
}

pub type Timer(
    name: string,
    tags: Dict<string, string>,
) {
    pub fn record(self: Self, duration: i64);
    pub fn count(self: Self) -> i64;
    pub fn totalTime(self: Self) -> i64;
}

#[service]
pub type MetricRegistry {
    pub fn counter(self: Self, name: string, tags: Dict<string, string>) -> Counter;
    pub fn timer(self: Self, name: string, tags: Dict<string, string>) -> Timer;
    pub fn getMetrics(self: Self) -> Array<Metric>;
}

#[restController]
#[route("/actuator")]
pub type MetricsController(registry: MetricRegistry) {
    #[getMapping("/metrics")]
    pub fn metrics(self: Self, req: Request) -> Response {
        val metrics = self.registry.getMetrics();
        return Response.json(stringify(metrics));
    }
}
```

**Acceptance:**
- [ ] `/actuator/metrics` returns metrics
- [ ] Counter and Timer types defined
- [ ] Metrics can be registered and updated
- [ ] Metrics exposed in JSON format

### Step 5 — HTTP request metrics

Auto-instrument HTTP requests:
```bp
#[filter]
#[order(0)]
pub type MetricsFilter(registry: MetricRegistry) {
    pub fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response {
        val start = time.nowMillis();
        val result = chain.doFilter(request);
        val duration = time.nowMillis() - start;
        self.registry.timer("http.server.requests", Dict.empty()
            .insert("method", request.method)
            .insert("path", request.path)
            .insert("status", response.status.toString()))
            .record(duration);
        return result;
    }
}
```

**Acceptance:**
- [ ] HTTP requests automatically timed
- [ ] Metrics include method, path, status tags
- [ ] Duration recorded in milliseconds
- [ ] Metrics visible in `/actuator/metrics`

### Step 6 — Env endpoint (sanitized)

```bp
#[restController]
#[route("/actuator")]
pub type EnvController {
    #[getMapping("/env")]
    pub fn env(self: Self, req: Request) -> Response {
        val props = rkGetAllProps();
        val sanitized = props.map({ k, v ->
            if (isSensitive(k)) (k, "***") else (k, v);
        });
        return Response.json(stringify(sanitized));
    }
}

fn isSensitive(key: string) -> bool {
    return key.contains("password") || key.contains("secret") || key.contains("token");
}
```

**Acceptance:**
- [ ] `/actuator/env` returns environment properties
- [ ] Sensitive properties masked (***))
- [ ] Non-sensitive properties visible
- [ ] Works on both targets

### Step 7 — Beans endpoint

```bp
#[restController]
#[route("/actuator")]
pub type BeansController(ctx: Context) {
    #[getMapping("/beans")]
    pub fn beans(self: Self, req: Request) -> Response {
        val names = self.ctx.getBeanNames();
        return Response.json(stringify(names));
    }
}
```

**Acceptance:**
- [ ] `/actuator/beans` returns list of bean names
- [ ] All registered components listed
- [ ] Works on both targets

### Step 8 — Module structure

Create `modules/rakun-actuator/`:
```
modules/rakun-actuator/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── health.bp
│   ├── info.bp
│   ├── metrics.bp
│   ├── env.bp
│   └── beans.bp
└── test/
    ├── health_test.bp
    ├── info_test.bp
    └── metrics_test.bp
```

**Acceptance:**
- [ ] `rakun-actuator` module compiles
- [ ] All tests pass on commonJS and Erlang
- [ ] Example app exposes actuator endpoints

## Gate

- [ ] `botopink test --target commonJS` green
- [ ] `botopink test --target erlang` green
- [ ] `/actuator/health` returns health status
- [ ] `/actuator/info` returns application info
- [ ] `/actuator/metrics` returns metrics
- [ ] `/actuator/env` returns sanitized properties
- [ ] `/actuator/beans` returns bean names
- [ ] HTTP requests automatically timed

## Blast radius

- **New module** `rakun-actuator` — no changes to rakun-core
- **Runtime** gains metric registry
- **Filters** gain metrics filter
- **Example app** exposes actuator endpoints

## Notes

- Health: UP, DOWN, OUT_OF_SERVICE, UNKNOWN (Spring Boot convention)
- Metrics: simple counter/timer for now (Micrometer integration later)
- Env: sensitive keys masked (password, secret, token)
- Beans: list only (no details about dependencies)
- Prometheus: separate front (requires specific format)
- Logging: separate front (structured logging)
