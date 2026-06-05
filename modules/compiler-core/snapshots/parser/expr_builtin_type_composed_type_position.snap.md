```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "isStarFn": false,
        "label": null,
        "name": "collect",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "first",
            "typeRef": {
              "optional": {
                "generic": {
                  "name": "Expr",
                  "args": [
                    {
                      "named": "Element"
                    }
                  ],
                  "is_builtin": true
                }
              }
            },
            "typeName": "",
            "modifier": "comptime",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "generic": {
            "name": "Expr",
            "args": [],
            "is_builtin": true
          }
        },
        "body": [
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "todo",
                    "is_builtin": true,
                    "is_tagged": false,
                    "args": [],
                    "trailing": []
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```