----- SOURCE CODE -- main.bp
```botopink
val x = 42;
val y = 3.14;
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "x",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "y",
      "return_type": "f64"
    }
  ]
}
```

