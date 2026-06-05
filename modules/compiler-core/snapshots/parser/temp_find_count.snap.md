```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "isStarFn": false,
        "label": null,
        "name": "find",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T"
          }
        ],
        "params": [
          {
            "name": "xs",
            "typeRef": {
              "generic": {
                "name": "Array",
                "args": [
                  {
                    "named": "T"
                  }
                ],
                "is_builtin": false
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          },
          {
            "name": "pred",
            "typeRef": {
              "named": "fn"
            },
            "typeName": "fn",
            "modifier": "none",
            "fnType": {
              "params": [
                {
                  "name": "item",
                  "typeName": "T"
                }
              ],
              "returnType": "bool"
            },
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "optional": {
            "named": "T"
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
                    "call": {
                      "loc": {
                        "line": 2,
                        "col": 28
                      },
                      "kind": {
                        "call": {
                          "receiver": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 15
                              },
                              "kind": {
                                "call": {
                                  "receiver": {
                                    "identifier": {
                                      "loc": {
                                        "line": 2,
                                        "col": 12
                                      },
                                      "kind": {
                                        "ident": "xs"
                                      }
                                    }
                                  },
                                  "callee": "filter",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "identifier": {
                                          "loc": {
                                            "line": 2,
                                            "col": 22
                                          },
                                          "kind": {
                                            "ident": "pred"
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
                          "callee": "at",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": null,
                              "value": {
                                "literal": {
                                  "loc": {
                                    "line": 2,
                                    "col": 31
                                  },
                                  "kind": {
                                    "numberLit": "0"
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
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    },
    {
      "fn": {
        "isPub": true,
        "isStarFn": false,
        "label": null,
        "name": "count",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T"
          }
        ],
        "params": [
          {
            "name": "xs",
            "typeRef": {
              "generic": {
                "name": "Array",
                "args": [
                  {
                    "named": "T"
                  }
                ],
                "is_builtin": false
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          },
          {
            "name": "pred",
            "typeRef": {
              "named": "fn"
            },
            "typeName": "fn",
            "modifier": "none",
            "fnType": {
              "params": [
                {
                  "name": "item",
                  "typeName": "T"
                }
              ],
              "returnType": "bool"
            },
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 5,
                        "col": 12
                      },
                      "kind": {
                        "identAccess": {
                          "receiver": {
                            "call": {
                              "loc": {
                                "line": 5,
                                "col": 15
                              },
                              "kind": {
                                "call": {
                                  "receiver": {
                                    "identifier": {
                                      "loc": {
                                        "line": 5,
                                        "col": 12
                                      },
                                      "kind": {
                                        "ident": "xs"
                                      }
                                    }
                                  },
                                  "callee": "filter",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "identifier": {
                                          "loc": {
                                            "line": 5,
                                            "col": 22
                                          },
                                          "kind": {
                                            "ident": "pred"
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
                          "member": "length",
                          "optional": false
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