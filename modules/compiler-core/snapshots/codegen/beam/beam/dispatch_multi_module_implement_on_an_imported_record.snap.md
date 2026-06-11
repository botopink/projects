----- SOURCE CODE -- pond.bp
```botopink
pub val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
```

----- BEAM ASSEMBLY -- pond.S
```erlang
{module, pond}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- RUN LOG -----
```logs
```
