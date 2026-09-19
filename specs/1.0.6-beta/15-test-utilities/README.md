# Front 15 — Test Utilities

**Priority:** low — services need testing support
**Depends on:** F03 (context-api)
**Owns:** `modules/rakun-test/src/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`

---

## Problem

Rakun has no test utilities. Testing controllers requires starting a real server. Spring Boot provides `@SpringBootTest`, `MockMvc`, `@WebMvcTest`, test slices.

## Mechanism

Spring Boot Test:
- `@SpringBootTest` → full integration test
- `MockMvc` → test controllers without server
- `@WebMvcTest` → controller slice test
- `@MockBean` → mock dependencies

Rakun will implement:
- **MockMvc** → test controllers in-process
- **@mockBean** → mock dependencies
- Test context management

## Steps

### Step 1 — MockMvc

```bp
// mock_mvc.bp
pub type MockMvc {
    pub fn perform(self: Self, request: MockRequest) -> MockResult;
}

pub type MockRequest(
    method: string,
    path: string,
    headers: Dict<string, string>,
    body: string,
)

pub type MockResult(
    status: i32,
    headers: Dict<string, string>,
    body: string,
)
```

Usage:
```bp
test "GET /users returns 200" {
    val mockMvc = MockMvc.builder()
        .controller(UserController)
        .build();

    val result = mockMvc.perform(MockRequest(
        method: "GET",
        path: "/api/users",
        headers: Dict.empty(),
        body: "",
    ));

    assert result.status == 200;
    assert result.body.contains("alice");
}
```

### Step 2 — @mockBean

```bp
test "UserController with mocked UserService" {
    val mockService = @mockBean(UserService);
    mockService.when("list").thenReturn(["alice", "bob"]);

    val mockMvc = MockMvc.builder()
        .controller(UserController(mockService))
        .build();

    val result = mockMvc.perform(MockRequest(method: "GET", path: "/api/users"));
    assert result.status == 200;
}
```

### Step 3 — Module structure

```
modules/rakun-test/
├── botopink.json
├── src/
│   ├── root.bp
│   ├── mock_mvc.bp
│   └── mock_bean.bp
└── test/
    └── mock_mvc_test.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] MockMvc tests controllers without server
- [ ] @mockBean mocks dependencies
- [ ] Request/response assertions work

## Notes

- MockMvc: in-process dispatch (no socket)
- @mockBean: comptime mock generation
- Test slices: later (WebMvcTest, DataJpaTest)
