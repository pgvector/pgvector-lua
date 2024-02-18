# pgvector-lua

[pgvector](https://github.com/pgvector/pgvector) support for Lua

Supports [pgmoon](https://github.com/leafo/pgmoon)

[![Build Status](https://github.com/pgvector/pgvector-lua/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-lua/actions)

## Getting Started

Run:

```sh
luarocks install pgvector
```

And follow the instructions for your database library:

- [pgmoon](#pgmoon)

## pgmoon

Require the library

```lua
local pgvector = require("pgvector")
```

Enable the extension

```lua
pg:query("CREATE EXTENSION IF NOT EXISTS vector")
```

Create a table

```lua
pg:query("CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")
```

Insert a vector

```lua
embedding = pgvector.new({1, 1, 1})
pg:query("INSERT INTO items (embedding) VALUES ($1)", embedding)
```

Get the nearest neighbors

```lua
embedding = pgvector.new({1, 1, 1})
local res = pg:query("SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", embedding)
for i, row in ipairs(res) do
  for k, v in pairs(row) do
    print(k, v)
  end
end
```

Add an approximate index

```lua
pg:query("CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
-- or
pg:query("CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](test/example.lua)

## History

View the [changelog](https://github.com/pgvector/pgvector-lua/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-lua/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-lua/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-lua.git
cd pgvector-lua
createdb pgvector_lua_test
luarocks install pgmoon
luarocks install luasocket
lua test/example.lua
```
