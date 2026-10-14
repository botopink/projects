# Front 143 — dbcontext: botopink's JPA over erika — entities, the context, repositories (decision 398)

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [150-rakun](../steps-dbcontext.md): s1 → 150 s48 · s2 → 150 s49 · s3 → 150 s50. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

**Priority:** high — rakun-data's repositories (08 step 7) stand on it · **State:** step 0 done
(`botopink/dbcontext` scaffolded, a submodule); steps 1–3 open
**Depends on:** decision 398 · `137` step 2 (erika's `QueryContext`, `QueryTable`, `query`, 397) ·
`01-compiler/01-checker` step 29 (the template annotation `#[query "…"]` and the template method) ·
step 3's rakun commit: `04-rakun/128` landed (decision 339)
**Owns:** `repository/dbcontext/**` (decision 326's rule) · in rakun-data, the code that moves here
(`#[entity]`'s mapping, `#[repository]`, `#[nativeQuery]`, `#[query]`'s checks, the row decoding) and
its deletion there (step 3, one commit, 188)
**Does not touch:** erika (`QueryContext`, `QueryTable`, the grammar are 137's) · rakun-data's drivers,
container registration, `#[transactional]` and `/actuator/sql` (08 step 7's)

## Goal

Decision 398: the persistence layer is a library of its own over erika — erika the query language,
`dbcontext` the entities, the context and the repositories, rakun-data the drivers and the container.

```bp
import {entity, column, repository, query, nativeQuery, DbContext} from "dbcontext";

#[entity("usuarios")]
pub type User(id: i32, nome: string, #[column("ativo")] active: bool)

#[repository]
behavior Users {
    #[query "select * from User where id = ${id} limit 1"]            // erika's grammar
    fn find(self: Self, id: i32) -> @Result<?User, StoreError>;

    #[nativeQuery("select * from usuarios where nome ilike :q")]     // the driver's SQL
    fn search(self: Self, q: string) -> @Result<User[], StoreError>;
}

type Relatorio(db: DbContext) {
    fn ativos(self: Self) -> @Result<User[], StoreError> {
        return self.db.query "select * from User where active = true";        // 397
    }
}
```


## Former front 153 — dbcontext: botopink's JPA over erika (398)

Front 153 (a library front of the high tier, decision 433) was refiled under 150 rakun by 165 s8: its open steps are
`steps-dbcontext.md` beside `150-rakun/README.md` (150 s48 … s51); the package is `rakun-data`
(`rakun/modules/rakun-data/`). Its dependencies were: 145 s1 (137 s2) · 144 B-18 (01-checker s29).
