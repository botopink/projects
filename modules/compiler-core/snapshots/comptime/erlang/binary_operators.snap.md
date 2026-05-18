----- SOURCE CODE -- main.bp
```botopink
val sum = 1 + 2;
val product = 3.0 * 2.0;
val joined = "a" + "b";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "val",
      "indent": "sum",
      "return_type": "i32"
    },
    {
      "ast": "val",
      "indent": "product",
      "return_type": "f64"
    },
    {
      "ast": "val",
      "indent": "joined",
      "return_type": "string"
    }
  ]
}
```

