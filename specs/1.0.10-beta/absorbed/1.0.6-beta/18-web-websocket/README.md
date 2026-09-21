# Front 18 — WebSocket Support

**Priority:** low — services need real-time bidirectional communication
**Depends on:** F04 (web-middleware)
**Owns:** `modules/rakun-web/src/websocket/**`
**Does not touch:** `src/runtime.mjs`, `src/decorators.bp`, `src/http.bp`, `src/bootstrap.bp`, `modules/rakun-web/src/middleware.bp`

---

## Problem

Beyond HTTP request-response, services need real-time bidirectional communication (chat, notifications, live updates). Spring Boot provides WebSocket support via `spring-boot-starter-websocket`.

## Mechanism

Spring Boot WebSocket:
- `@ServerEndpoint` → WebSocket endpoint
- `WebSocketHandler` → handle messages
- STOMP over WebSocket
- SockJS fallback

Rakun will implement:
- **@serverEndpoint** → WebSocket endpoint
- **WebSocketHandler** behavior
- Message routing

## Steps

### Step 1 — WebSocket handler

```bp
// websocket.bp
pub behavior WebSocketHandler {
    fn onOpen(self: Self, session: WebSocketSession);
    fn onMessage(self: Self, session: WebSocketSession, message: string);
    fn onClose(self: Self, session: WebSocketSession, code: i32, reason: string);
    fn onError(self: Self, session: WebSocketSession, error: string);
}

pub type WebSocketSession {
    id: string,
    pub fn send(self: Self, message: string);
    pub fn close(self: Self);
}
```

### Step 2 — @serverEndpoint

```bp
#[serverEndpoint("/ws/chat")]
pub type ChatWebSocketHandler {
    pub fn onOpen(self: Self, session: WebSocketSession) {
        print("Client connected: " + session.id);
    }

    pub fn onMessage(self: Self, session: WebSocketSession, message: string) {
        // broadcast to all connected clients
        session.send("Echo: " + message);
    }

    pub fn onClose(self: Self, session: WebSocketSession, code: i32, reason: string) {
        print("Client disconnected: " + session.id);
    }
}
```

### Step 3 — Erlang implementation

Cowboy WebSocket behavior:
```erlang
-module(chat_ws_handler).
-behaviour(cowboy_websocket).

init(Req, State) ->
    {cowboy_websocket, Req, State}.

websocket_handle({text, Msg}, State) ->
    {reply, {text, "Echo: " ++ Msg}, State};
websocket_handle(_Data, State) ->
    {ok, State}.

websocket_info(_Info, State) ->
    {ok, State}.
```

### Step 4 — Module structure

```
modules/rakun-web/
└── src/
    └── websocket/
        ├── websocket_handler.bp
        └── server_endpoint.bp
```

## Gate

- [ ] `botopink test` green on both targets
- [ ] WebSocket connection established
- [ ] Messages sent/received
- [ ] Connection closed gracefully
- [ ] Multiple clients supported

## Notes

- Cowboy WebSocket (Erlang), `ws` (Node.js)
- STOMP: separate front
- SockJS fallback: separate front
- Broadcasting: use ETS to track sessions (Erlang), Map (Node.js)
