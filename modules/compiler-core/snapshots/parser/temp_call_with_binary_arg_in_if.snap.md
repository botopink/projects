```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "isStarFn": false,
        "label": null,
        "name": "g",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "a",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          },
          {
            "name": "b",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": null,
        "body": [
          {
            "expr": {
              "branch": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "binaryOp": {
                        "loc": {
                          "line": 2,
                          "col": 11
                        },
                        "op": "gt",
                        "lhs": {
                          "identifier": {
                            "loc": {
                              "line": 2,
                              "col": 9
                            },
                            "kind": {
                              "ident": "a"
                            }
                          }
                        },
                        "rhs": {
                          "literal": {
                            "loc": {
                              "line": 2,
                              "col": 13
                            },
                            "kind": {
                              "numberLit": "0"
                            }
                          }
                        }
                      }
                    },
                    "binding": null,
                    "then_": [
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 3,
                              "col": 9
                            },
                            "kind": {
                              "call": {
                                "receiver": null,
                                "callee": "g",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [
                                  {
                                    "label": null,
                                    "value": {
                                      "binaryOp": {
                                        "loc": {
                                          "line": 3,
                                          "col": 13
                                        },
                                        "op": "add",
                                        "lhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 3,
                                              "col": 11
                                            },
                                            "kind": {
                                              "ident": "a"
                                            }
                                          }
                                        },
                                        "rhs": {
                                          "literal": {
                                            "loc": {
                                              "line": 3,
                                              "col": 15
                                            },
                                            "kind": {
                                              "numberLit": "1"
                                            }
                                          }
                                        }
                                      }
                                    },
                                    "comments": []
                                  },
                                  {
                                    "label": null,
                                    "value": {
                                      "identifier": {
                                        "loc": {
                                          "line": 3,
                                          "col": 18
                                        },
                                        "kind": {
                                          "ident": "b"
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
                    ],
                    "else_": null
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