----- SOURCE
```botopink
val xs = [1, 2, 3];
val y = xs.
           ↑
```

----- COMPLETION at (line 1, char 11)
length  [Field]  detail: val length: i32
at  [Method]  detail: fn at(self: Self, index: i32) -> ?T
push  [Method]  detail: fn push(self: Self, item: T)
pop  [Method]  detail: fn pop(self: Self) -> ?T
contains  [Method]  detail: fn contains(self: Self, item: T) -> bool
slice  [Method]  detail: fn slice(self: Self, start: i32, end: i32) -> Array
join  [Method]  detail: fn join(self: Self, sep: string) -> string
reverse  [Method]  detail: fn reverse(self: Self) -> Array
indexOf  [Method]  detail: fn indexOf(self: Self, item: T) -> i32
forEach  [Method]  detail: fn forEach(self: Self, action: fn(item: T))
map  [Method]  detail: fn map(self: Self, transform: fn(item: T) -> T) -> Array
filter  [Method]  detail: fn filter(self: Self, pred: fn(item: T) -> bool) -> Array
