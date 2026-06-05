```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "isStarFn": false,
        "label": null,
        "name": "html",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "template",
            "typeRef": {
              "expr": {
                "named": "string"
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
          "expr": {
            "named": "string"
          }
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "comptime_": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "exprLiteral": {
                          "body": [
                            {
                              "expr": {
                                "comptime_": {
                                  "loc": {
                                    "line": 2,
                                    "col": 19
                                  },
                                  "kind": {
                                    "splice": {
                                      "identifier": {
                                        "loc": {
                                          "line": 2,
                                          "col": 21
                                        },
                                        "kind": {
                                          "ident": "template"
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              "emptyLinesBefore": 0
                            }
                          ]
                        }
                      }
                    }
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