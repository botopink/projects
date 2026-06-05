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

pub fn to_int(o: Order) -> i32 {
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

----- ERLANG -- std/order.erl
```erlang
-module(order).
-export([lt/0, eq/0, gt/0, to_int/1, reverse/1]).

%%% Gleam-style `order` module (`import {order} from "std";`), inspired by

%%% `gleam/order`. Exports the `Order` enum (type export) plus companion

%%% functions. Construct via the module fns (`order.lt()`) — the bare

%%% variant constructors have no local decl in importing modules.

%% enum Order
%%   Lt
%%   Eq
%%   Gt

lt() ->
    Order_Lt.

eq() ->
    Order_Eq.

gt() ->
    Order_Gt.

to_int(O) ->
    N = case O of
        Lt ->
            (-1);
        Eq ->
            0;
        _ ->
            1
    end,
    N.

reverse(O) ->
    R = case O of
        Lt ->
            Order_Gt;
        Gt ->
            Order_Lt;
        _ ->
            Order_Eq
    end,
    R.
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
    @print(order.to_int(order.lt()));
    @print(describe(order.reverse(order.lt())));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% import order

describe(O) ->
    S = case O of
        Lt ->
            <<"less">>;
        Gt ->
            <<"greater">>;
        _ ->
            <<"equal">>
    end,
    S.

main() ->
    io:format("~p~n", [order:to_int(order:lt())]),
    io:format("~p~n", [describe(order:reverse(order:lt()))]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
