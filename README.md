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

Or check out some examples:

- [Embeddings](examples/openai/example.lua) with OpenAI
- [Binary embeddings](examples/cohere/example.lua) with Cohere
- [Hybrid search](examples/hybrid/example.lua) with Ollama (Reciprocal Rank Fusion)
- [Sparse search](examples/sparse/example.lua) with Text Embeddings Inference

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
local embedding = pgvector.new({1, 1, 1})
pg:query("INSERT INTO items (embedding) VALUES ($1)", embedding)
```

Get the nearest neighbors

```lua
local embedding = pgvector.new({1, 1, 1})
local res = pg:query("SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", embedding)
for i, row in ipairs(res) do
  print(row["id"])
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

## Reference

### Half Vectors

Create a half vector from a table

```lua
local vec = pgvector.halfvec({1, 2, 3})
```

### Sparse Vectors

Create a sparse vector from a table of non-zero elements

```lua
local elements = {[1] = 1, [3] = 2, [5] = 3}
local vec = pgvector.sparsevec(elements, 6)
```

Get the number of dimensions

```lua
vec["dim"]
```

Get the non-zero elements

```lua
vec["elements"]
```

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
lua test/pgvector.lua
```

To run an example:

```sh
createdb pgvector_example
luarocks install luasec
luarocks install lua-cjson
lua examples/openai/example.lua
```
