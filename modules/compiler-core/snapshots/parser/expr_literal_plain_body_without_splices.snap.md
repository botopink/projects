```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "isStarFn": false,
        "label": null,
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "expr": {
            "named": "i32"
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
                                "binaryOp": {
                                  "loc": {
                                    "line": 2,
                                    "col": 21
                                  },
                                  "op": "add",
                                  "lhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 19
                                      },
                                      "kind": {
                                        "numberLit": "1"
                                      }
                                    }
                                  },
                                  "rhs": {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 23
                                      },
                                      "kind": {
                                        "numberLit": "2"
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