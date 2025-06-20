local pgmoon = require("pgmoon")
local pgvector = require("./src/pgvector")

local pg = pgmoon.new({
  database = "pgvector_lua_test",
  user = os.getenv("USER")
})

assert(pg:connect())
assert(pg:query("CREATE EXTENSION IF NOT EXISTS vector"))
assert(pg:query("DROP TABLE IF EXISTS items"))

assert(pg:query("CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))"))

local embedding1 = pgvector.new({1, 1, 1})
local embedding2 = pgvector.new({2, 2, 2})
local embedding3 = pgvector.new({1, 1, 2})
assert(pg:query("INSERT INTO items (embedding) VALUES ($1), ($2), ($3)", embedding1, embedding2, embedding3))

-- optional: automatically deserialize vector types
pgvector.setup_vector(pg)

local embedding = pgvector.new({1, 1, 1})
local res = assert(pg:query("SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", embedding))
for i, row in ipairs(res) do
  print(row["id"])
  print(row["embedding"])
end

assert(pg:query("CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)"))
