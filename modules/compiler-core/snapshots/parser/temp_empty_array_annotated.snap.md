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
        "returnType": null,
        "body": [
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "out",
                    "value": {
                      "collection": {
                        "loc": {
                          "line": 2,
                          "col": 27
                        },
                        "kind": {
                          "arrayLit": {
                            "elems": [],
                            "spread": null,
                            "spreadExpr": null,
                            "comments": [],
                            "commentsPerElem": [],
                            "trailingComma": false
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": {
                      "generic": {
                        "name": "Array",
                        "args": [
                          {
                            "named": "i32"
                          }
                        ],
                        "is_builtin": false
                      }
                    }
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 3,
                  "col": 9
                },
                "kind": {
                  "call": {
                    "receiver": {
                      "identifier": {
                        "loc": {
                          "line": 3,
                          "col": 5
                        },
                        "kind": {
                          "ident": "out"
                        }
                      }
                    },
                    "callee": "push",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [
                      {
                        "label": null,
                        "value": {
                          "literal": {
                            "loc": {
                              "line": 3,
                              "col": 14
                            },
                            "kind": {
                              "numberLit": "1"
                            }
                          }
                        },
                        "comments": []
                      }
                    ],
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