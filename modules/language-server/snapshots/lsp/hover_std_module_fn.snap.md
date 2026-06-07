----- SOURCE
```botopink
import {list} from "std";
val xs = list.map([1], { x -> x });
              ↑
```

----- HOVER at (line 1, char 14)
kind: markdown

```botopink
pub fn map<T, U>(xs: Array<T>, transform: fn(item: T) -> U) -> Array<U>
```

*from `std/list`*
