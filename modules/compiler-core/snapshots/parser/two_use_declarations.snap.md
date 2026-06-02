```json
{
  "decls": [
    {
      "use": {
        "imports": [
          {
            "segments": [
              "a"
            ],
            "activate": false,
            "alias": null
          }
        ],
        "source": {
          "call": {
            "loc": {
              "line": 1,
              "col": 11
            },
            "kind": {
              "call": {
                "receiver": null,
                "callee": "root",
                "is_builtin": true,
                "args": [],
                "trailing": []
              }
            }
          }
        },
        "docComment": null,
        "comment": null,
        "moduleComment": null
      }
    },
    {
      "use": {
        "imports": [
          {
            "segments": [
              "b"
            ],
            "activate": false,
            "alias": null
          },
          {
            "segments": [
              "c"
            ],
            "activate": false,
            "alias": null
          }
        ],
        "source": {
          "call": {
            "loc": {
              "line": 2,
              "col": 14
            },
            "kind": {
              "call": {
                "receiver": null,
                "callee": "module",
                "is_builtin": true,
                "args": [],
                "trailing": []
              }
            }
          }
        },
        "docComment": null,
        "comment": null,
        "moduleComment": null
      }
    }
  ]
}
```