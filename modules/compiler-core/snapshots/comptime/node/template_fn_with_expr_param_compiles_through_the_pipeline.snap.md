----- SOURCE CODE -- main.bp
```botopink
pub fn html(comptime template: expr string) -> expr string {
    return template;
}
val c = html """
<p>hello</p>
""";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "html",
      "is_pub": true,
      "params": [
        {
          "name": "template",
          "type": "?",
          "is_comptime": true
        }
      ],
      "return_type": "?",
      "body": [
        {
          "source": "return template;"
        }
      ]
    },
    {
      "ast": "val",
      "indent": "c",
      "return_type": "expr<string>",
      "expr": {
        "ast": "call",
        "params": [
          {
            "value": "string"
          }
        ],
        "return_type": "expr<string>"
      }
    }
  ]
}
```

