----- SOURCE CODE -- main.bp
```botopink
use { foo, bar } = @root()
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- RUN LOG -----
```logs
```
