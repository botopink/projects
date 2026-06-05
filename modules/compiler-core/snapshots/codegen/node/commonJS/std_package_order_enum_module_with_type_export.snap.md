----- SOURCE CODE -- std/order.bp
```botopink
//// Gleam-style `order` module (`import {order} from "std";`), inspired by
//// `gleam/order`. Exports the `Order` enum (type export) plus companion
//// functions. Construct via the module fns (`order.lt()`) — the bare
//// variant constructors have no local decl in importing modules.

pub enum Order {
    Lt,
    Eq,
    Gt,
}

pub fn lt() -> Order {
    return Order.Lt;
}

pub fn eq() -> Order {
    return Order.Eq;
}

pub fn gt() -> Order {
    return Order.Gt;
}

pub fn toInt(o: Order) -> i32 {
    val n = case o {
        Lt -> -1;
        Eq -> 0;
        _ -> 1;
    };
    return n;
}

pub fn reverse(o: Order) -> Order {
    val r = case o {
        Lt -> Order.Gt;
        Gt -> Order.Lt;
        _ -> Order.Eq;
    };
    return r;
}

```

----- JAVASCRIPT -- std/order.js
```javascript
//// Gleam-style `order` module (`import {order} from "std";`), inspired by

//// `gleam/order`. Exports the `Order` enum (type export) plus companion

//// functions. Construct via the module fns (`order.lt()`) — the bare

//// variant constructors have no local decl in importing modules.

const Order = Object.freeze({
    Lt: "Lt",
    Eq: "Eq",
    Gt: "Gt",
});

function lt() {
    return Order.Lt;
}
exports.lt = lt;

function eq() {
    return Order.Eq;
}
exports.eq = eq;

function gt() {
    return Order.Gt;
}
exports.gt = gt;

function toInt(o) {
    const n = (() => {
        const _s = o;
        if (_s === "Lt") return (-1);
        if (_s === "Eq") return 0;
        return 1;
    })();
    return n;
}
exports.toInt = toInt;

function reverse(o) {
    const r = (() => {
        const _s = o;
        if (_s === "Lt") return Order.Gt;
        if (_s === "Gt") return Order.Lt;
        return Order.Eq;
    })();
    return r;
}
exports.reverse = reverse;
```

----- TYPESCRIPT TYPEDEF -- std/order.d.ts
```typescript
export declare enum Order {
    Lt = "Lt",
    Eq = "Eq",
    Gt = "Gt",
}


export declare function lt(): Order;


export declare function eq(): Order;


export declare function gt(): Order;


export declare function toInt(o: ): i32;


export declare function reverse(o: ): Order;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {order} from "std";

fn describe(o: Order) -> string {
    val s = case o {
        Lt -> "less";
        Gt -> "greater";
        _ -> "equal";
    };
    return s;
}

fn main() {
    @print(order.toInt(order.lt()));
    @print(describe(order.reverse(order.lt())));
}
```

----- JAVASCRIPT -- main.js
```javascript
const order = require("./std/order.js");

function describe(o) {
    const s = (() => {
        const _s = o;
        if (_s === "Lt") return "less";
        if (_s === "Gt") return "greater";
        return "equal";
    })();
    return s;
}

function main() {
    console.log(order.toInt(order.lt()));
    console.log(describe(order.reverse(order.lt())));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
-1
greater
```
