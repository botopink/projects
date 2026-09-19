# Front 12 — Scheduling

**Priority:** medium — services need periodic tasks
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-scheduling/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no scheduling abstraction. Services that need periodic tasks must implement their own timers. Spring Boot provides `@Scheduled` with cron, fixed-rate, fixed-delay.

## Mechanism

Spring Boot Scheduling:
- `@Scheduled(cron = "...")` → cron expression
- `@Scheduled(fixedRate = 5000)` → fixed rate (ms)
- `@Scheduled(fixedDelay = 5000)` → fixed delay (ms)
- `@EnableScheduling` → enable scheduling

Rakun will implement:
- **@scheduled** decorator
- Cron, fixedRate, fixedDelay
- Task executor (thread pool)

## Steps

### Step 1 — @scheduled decorator

```bp
#[service]
pub type CleanupService {
    #[scheduled(cron: "0 0 * * * *")]  // every hour
    pub fn cleanup(self: Self) {
        print("Cleaning up...");
    }

    #[scheduled(fixedRate: 5000)]  // every 5 seconds
    pub fn heartbeat(self: Self) {
        print("Heartbeat");
    }
}
```

### Step 2 — Task executor

```erlang
% Erlang: use timer:send_interval or gen_server
% Node.js: use setInterval
```

### Step 3 — Cron parser

```bp
pub fn parseCron(expr: string) -> CronExpression {
    // parse "second minute hour day month weekday"
}
```

### Step 4 — Module structure

```
modules/rakun-scheduling/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── scheduled.bp
│   ├── cron.bp
│   └── task_executor.bp
└── test/
    └── scheduling_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] `@scheduled(cron)` runs on schedule
- [ ] `@scheduled(fixedRate)` runs at fixed rate
- [ ] `@scheduled(fixedDelay)` runs with fixed delay

## Notes

- Cron: 6 fields (second minute hour day month weekday)
- Task executor: configurable pool size
- Async: tasks run in separate process/thread
