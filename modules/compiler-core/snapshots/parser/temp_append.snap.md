```json
{
  "decls": [
    {
      "fn": {
        "isPub": true,
        "isStarFn": false,
        "label": null,
        "name": "append",
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
            "name": "ys",
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
          }
        ],
        "returnType": {
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
                          "col": 25
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
                            "named": "T"
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
                  "col": 8
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
                          "ident": "xs"
                        }
                      }
                    },
                    "callee": "forEach",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [
                      {
                        "label": null,
                        "value": {
                          "function": {
                            "loc": {
                              "line": 3,
                              "col": 16
                            },
                            "kind": {
                              "syntax": "lambda",
                              "params": [
                                "x"
                              ],
                              "body": [
                                {
                                  "expr": {
                                    "call": {
                                      "loc": {
                                        "line": 3,
                                        "col": 27
                                      },
                                      "kind": {
                                        "call": {
                                          "receiver": {
                                            "identifier": {
                                              "loc": {
                                                "line": 3,
                                                "col": 23
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
                                                "identifier": {
                                                  "loc": {
                                                    "line": 3,
                                                    "col": 32
                                                  },
                                                  "kind": {
                                                    "ident": "x"
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
                              "isStarFn": false
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
          },
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 4,
                  "col": 8
                },
                "kind": {
                  "call": {
                    "receiver": {
                      "identifier": {
                        "loc": {
                          "line": 4,
                          "col": 5
                        },
                        "kind": {
                          "ident": "ys"
                        }
                      }
                    },
                    "callee": "forEach",
                    "is_builtin": false,
                    "is_tagged": false,
                    "optional": false,
                    "args": [
                      {
                        "label": null,
                        "value": {
                          "function": {
                            "loc": {
                              "line": 4,
                              "col": 16
                            },
                            "kind": {
                              "syntax": "lambda",
                              "params": [
                                "y"
                              ],
                              "body": [
                                {
                                  "expr": {
                                    "call": {
                                      "loc": {
                                        "line": 4,
                                        "col": 27
                                      },
                                      "kind": {
                                        "call": {
                                          "receiver": {
                                            "identifier": {
                                              "loc": {
                                                "line": 4,
                                                "col": 23
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
                                                "identifier": {
                                                  "loc": {
                                                    "line": 4,
                                                    "col": 32
                                                  },
                                                  "kind": {
                                                    "ident": "y"
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
                              "isStarFn": false
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
          },
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
                        "ident": "out"
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