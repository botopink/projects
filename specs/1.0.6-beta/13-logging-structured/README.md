# Front 13 — Structured Logging

**Priority:** low — services need structured logging for observability
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-logging/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun uses `print()` for logging. Services need structured logging (JSON), log levels, and log groups for production observability.

## Mechanism

Spring Boot Logging:
- Log levels: TRACE, DEBUG, INFO, WARN, ERROR
- Structured logging: ECS, GELF, Logstash
- Log groups: configure multiple loggers together
- Logback/Log4j2 integration

Rakun will implement:
- **Logger** type with levels
- **Structured logging** (JSON)
- **Log configuration** via properties

## Steps

### Step 1 — Logger type

```bp
// logging.bp
pub type Logger {
    name: string,
}

pub fn getLogger(name: string) -> Logger {
    return Logger(name: name);
}

pub fn trace(self: Self, message: string);
pub fn debug(self: Self, message: string);
pub fn info(self: Self, message: string);
pub fn warn(self: Self, message: string);
pub fn error(self: Self, message: string);
```

### Step 2 — Structured logging

```yaml
logging:
  structured:
    format:
      console: ecs  # or gelf, logstash
```

Output:
```json
{"@timestamp":"2026-01-01T00:00:00Z","log.level":"INFO","message":"Starting application","service.name":"myapp"}
```

### Step 3 — Log levels via config

```yaml
logging:
  level:
    root: INFO
    rakun: DEBUG
    myapp: TRACE
```

### Step 4 — Module structure

```
modules/rakun-logging/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── logger.bp
│   └── structured.bp
└── test/
    └── logging_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] Logger with levels works
- [ ] Structured logging (JSON) works
- [ ] Log levels configurable via properties

## Notes

- Formats: ECS, GELF, Logstash
- Console + file output
- MDC (mapped diagnostic context) for request tracing
