----- SOURCE CODE
val cfg = (record { port: 8080 });
val x = cfg.prot;

----- ERROR
error: unknown field
  ┌─ :2:9
  │
2 │ val x = cfg.prot;
  │         ^

  'record' has no field 'prot'
