# Front 06 — Security (Authentication & Authorization)

**Priority:** high — services need authentication and authorization
**Depends on:** F04 (web-middleware)
**Owns:** `modules/rakun-security/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `modules/rakun-web/src/**`

---

## Problem

Rakun has no security layer. Services cannot:
- Authenticate users (JWT, Basic Auth, OAuth2)
- Authorize access (role-based, method-level)
- Protect endpoints
- Manage sessions

Spring Boot provides `spring-boot-starter-security` with comprehensive security. Rakun needs equivalent for Erlang/BEAM.

## Current state

- No authentication
- No authorization
- All endpoints public
- No security filters
- Example app has no security

## Mechanism

Spring Boot Security:
- `SecurityFilterChain` → filter chain with security filters
- `@EnableWebSecurity` → enable security
- `@PreAuthorize`, `@PostAuthorize` → method-level security
- `UserDetailsService` → load user details
- `JwtDecoder` → JWT validation

Rakun will implement:
- **SecurityFilterChain** → filter chain with auth filters
- **@secured**, **@preAuthorize** → method-level security
- **UserDetailsService** → load user details
- **JWT** → token-based auth
- **Basic Auth** → simple auth

## Steps

### Step 1 — Security context

```bp
// security_context.bp
pub type SecurityContext(
    authentication: ?Authentication,
)

pub type Authentication(
    principal: string,        // username
    credentials: string,      // password/token (not stored)
    authorities: Array<string>,  // roles/permissions
    authenticated: bool,
)

pub behavior SecurityContextRepository {
    fn loadContext(self: Self, request: Request) -> SecurityContext;
    fn saveContext(self: Self, request: Request, response: Response, context: SecurityContext);
}
```

**Acceptance:**
- [ ] `SecurityContext` type defined
- [ ] `Authentication` type defined
- [ ] `SecurityContextRepository` behavior defined

### Step 2 — Security filter chain

```bp
#[configuration]
pub type SecurityConfig {
    #[bean]
    pub fn securityFilterChain(self: Self) -> SecurityFilterChain {
        return SecurityFilterChain()
            .addFilter(JwtAuthenticationFilter())
            .addFilter(AuthorizationFilter())
            .authorizeRequests({ requests ->
                requests
                    .antMatchers("/api/public/**").permitAll()
                    .antMatchers("/api/admin/**").hasRole("ADMIN")
                    .anyRequest().authenticated();
            });
    }
}
```

Implementation: security filter runs before other filters:
```bp
#[filter]
#[order(-300)]  // very early
pub type SecurityFilter(chain: SecurityFilterChain) {
    pub fn doFilter(self: Self, request: Request, response: Response, next: FilterChain) -> Response {
        val context = self.chain.loadContext(request);
        if (!self.chain.isAuthorized(request, context)) {
            return Response.status(401).body("Unauthorized");
        }
        return next.doFilter(request);
    }
}
```

**Acceptance:**
- [ ] `SecurityFilterChain` configures auth rules
- [ ] Security filter runs early in chain
- [ ] Unauthorized requests return 401
- [ ] Authorized requests pass through

### Step 3 — JWT authentication

```bp
#[component]
pub type JwtAuthenticationFilter(
    #[value("rakun.security.jwt.secret")] secret: string,
) {
    pub fn authenticate(self: Self, request: Request) -> ?Authentication {
        val token = request.header("Authorization");
        if (!token.startsWith("Bearer ")) return null;
        val jwt = token.substring(7);
        val claims = verifyJwt(jwt, self.secret);
        return Authentication(
            principal: claims.sub,
            credentials: "",
            authorities: claims.roles,
            authenticated: true,
        );
    }
}
```

JWT verification:
```bp
pub fn verifyJwt(token: string, secret: string) -> @Result<JwtClaims, string> {
    val parts = token.split(".");
    if (parts.length != 3) return @Err("Invalid JWT");
    val header = base64Decode(parts[0]);
    val payload = base64Decode(parts[1]);
    val signature = parts[2];
    // verify HMAC-SHA256 signature
    val expectedSig = hmacSha256(header + "." + payload, secret);
    if (signature != expectedSig) return @Err("Invalid signature");
    return @Ok(parseJwtClaims(payload));
}
```

**Acceptance:**
- [ ] JWT token extracted from `Authorization: Bearer <token>`
- [ ] Signature verified with secret
- [ ] Claims extracted (sub, roles, exp)
- [ ] Expired tokens rejected
- [ ] Invalid signatures rejected

### Step 4 — Basic authentication

```bp
#[component]
pub type BasicAuthenticationFilter(
    userDetailsService: UserDetailsService,
) {
    pub fn authenticate(self: Self, request: Request) -> ?Authentication {
        val auth = request.header("Authorization");
        if (!auth.startsWith("Basic ")) return null;
        val encoded = auth.substring(6);
        val decoded = base64Decode(encoded);
        val parts = decoded.split(":");
        val username = parts[0];
        val password = parts[1];
        val user = self.userDetailsService.loadUserByUsername(username);
        if (user == null || !passwordMatches(password, user.password)) return null;
        return Authentication(
            principal: username,
            credentials: "",
            authorities: user.authorities,
            authenticated: true,
        );
    }
}
```

**Acceptance:**
- [ ] Basic auth extracted from `Authorization: Basic <base64>`
- [ ] Username/password decoded
- [ ] User loaded via `UserDetailsService`
- [ ] Password verified (bcrypt)
- [ ] Invalid credentials return 401

### Step 5 — UserDetailsService

```bp
pub behavior UserDetailsService {
    fn loadUserByUsername(self: Self, username: string) -> ?UserDetails;
}

pub type UserDetails(
    username: string,
    password: string,  // hashed
    authorities: Array<string>,
    enabled: bool,
)
```

In-memory implementation:
```bp
#[component]
pub type InMemoryUserDetailsService(
    #[value("rakun.security.users")] usersConfig: string,
) {
    pub fn loadUserByUsername(self: Self, username: string) -> ?UserDetails {
        // parse usersConfig: "user1:pass1:ROLE_USER,user2:pass2:ROLE_ADMIN"
    }
}
```

Database implementation:
```bp
#[service]
pub type JdbcUserDetailsService(template: SqlTemplate) {
    pub fn loadUserByUsername(self: Self, username: string) -> ?UserDetails {
        val rows = self.template.query("SELECT * FROM users WHERE username = $1", [username]);
        return rows.map({ r -> mapRow(r) });
    }
}
```

**Acceptance:**
- [ ] `UserDetailsService` behavior defined
- [ ] In-memory implementation works
- [ ] JDBC implementation works
- [ ] Users loaded from config or database

### Step 6 — Method-level security

```bp
#[service]
pub type AdminService {
    #[secured("ROLE_ADMIN")]
    pub fn adminOnly(self: Self) -> string {
        return "Admin data";
    }

    #[preAuthorize("hasRole('ADMIN') or #userId == authentication.principal")]
    pub fn userSpecific(self: Self, userId: string) -> string {
        return "User data for " + userId;
    }
}
```

Implementation: decorator wraps method with security check:
```bp
pub fn secured(comptime decl: @Decl, role: string) {
    @emit("pub fn " + decl.name + "(self: Self, " + /* params */ ") -> " + /* return type */ " { rkCheckAuthority(\"" + role + "\"); /* original body */ }");
}
```

Runtime:
```js
export function checkAuthority(authority) {
    const context = getCurrentContext();
    if (!context.authentication || !context.authentication.authorities.includes(authority)) {
        throw new AccessDeniedException("Access denied");
    }
}
```

**Acceptance:**
- [ ] `#[secured("ROLE")]` checks role
- [ ] `#[preAuthorize("expression")]` evaluates expression
- [ ] Access denied returns 403
- [ ] Works on both targets

### Step 7 — CSRF protection

```bp
#[component]
pub type CsrfFilter {
    pub fn doFilter(self: Self, request: Request, response: Response, chain: FilterChain) -> Response {
        if (request.method == "POST" || request.method == "PUT" || request.method == "DELETE") {
            val token = request.header("X-CSRF-TOKEN");
            if (!validateCsrfToken(token)) {
                return Response.status(403).body("CSRF token invalid");
            }
        }
        val newToken = generateCsrfToken();
        response = response.withHeader("X-CSRF-TOKEN", newToken);
        return chain.doFilter(request);
    }
}
```

**Acceptance:**
- [ ] CSRF token generated for state-changing requests
- [ ] Token validated on POST/PUT/DELETE
- [ ] Invalid token returns 403
- [ ] Token sent in response header

### Step 8 — Module structure

Create `modules/rakun-security/`:
```
modules/rakun-security/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── security_context.bp
│   ├── jwt_filter.bp
│   ├── basic_auth_filter.bp
│   ├── user_details_service.bp
│   ├── method_security.bp
│   └── csrf_filter.bp
└── test/
    ├── jwt_test.bp
    ├── basic_auth_test.bp
    └── method_security_test.bp
```

**Acceptance:**
- [ ] `rakun-security` module compiles
- [ ] All tests pass on commonJS and Erlang
- [ ] Example app uses JWT authentication

## Gate

- [ ] `botopink test --target commonJS` green
- [ ] `botopink test --target erlang` green
- [ ] JWT authentication works
- [ ] Basic authentication works
- [ ] Method-level security works
- [ ] CSRF protection works
- [ ] Unauthorized requests return 401
- [ ] Forbidden requests return 403

## Blast radius

- **New module** `rakun-security` — no changes to rakun-core
- **Dependencies** — `jose` (JWT), `bcrypt` (password hashing)
- **Runtime** gains security context management
- **Decorators** gain `#[secured]`, `#[preAuthorize]`
- **Example app** can use JWT/Basic auth

## Notes

- JWT: HS256 (HMAC-SHA256) for simplicity; RS256 later
- Password hashing: bcrypt (standard for passwords)
- CSRF: stateless (token in header, not session)
- Method security: SpEL-like expressions (simplified for now)
- OAuth2: separate front (complex, requires external provider integration)
- Session-based auth: separate front (requires `rakun-session`)
