# Front 10 — Bean Validation

**Priority:** medium — services need input validation
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-validation/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no validation abstraction. Controllers must manually validate request data. Spring Boot provides `spring-boot-starter-validation` with `@NotNull`, `@Size`, `@Email`, etc.

## Mechanism

Spring Boot Validation:
- `@NotNull`, `@NotEmpty`, `@NotBlank`
- `@Size(min, max)`, `@Min`, `@Max`
- `@Email`, `@Pattern`
- `@Valid` on method parameters
- Auto-validation in controllers

Rakun will implement:
- Constraint decorators
- `@valid` on controller method parameters
- Auto-validation with error collection

## Steps

### Step 1 — Constraint decorators

```bp
// validation.bp
pub fn notNull(comptime decl: @Decl) {
    // register constraint
}

pub fn size(comptime decl: @Decl, min: i32, max: i32) {
    // register constraint
}

pub fn email(comptime decl: @Decl) {
    // register constraint
}

pub fn pattern(comptime decl: @Decl, regex: string) {
    // register constraint
}
```

### Step 2 — Usage on types

```bp
pub type CreateUserRequest(
    #[notNull]
    #[size(min: 2, max: 50)]
    name: string,

    #[notNull]
    #[email]
    email: string,

    #[min(18)]
    age: i32,
)
```

### Step 3 — Validator

```bp
#[service]
pub type Validator {
    pub fn validate<T>(self: Self, obj: T) -> @Result<void, Array<Violation>>;
}

pub type Violation(
    field: string,
    message: string,
    value: string,
)
```

### Step 4 — @valid on controller methods

```bp
#[restController]
pub type UserController {
    #[postMapping("/users")]
    pub fn create(self: Self, #[valid] req: CreateUserRequest) -> Response {
        // req is already validated
        return Response.created("created");
    }
}
```

If validation fails, returns 400 with violations:
```json
{
    "errors": [
        {"field": "name", "message": "must not be null"},
        {"field": "email", "message": "must be a valid email"}
    ]
}
```

### Step 5 — Module structure

```
modules/rakun-validation/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── constraints.bp
│   └── validator.bp
└── test/
    └── validation_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] `@notNull`, `@size`, `@email`, `@min`, `@max`, `@pattern` work
- [ ] `@valid` triggers validation
- [ ] Violations returned as 400

## Notes

- Validation runs before controller method
- Multiple violations collected (not fail-fast)
- Custom validators: later front
