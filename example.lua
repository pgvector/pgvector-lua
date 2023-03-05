local pgmoon = require("pgmoon")
local pg = pgmoon.new({
  database = "pgvector_lua_test",
  user = os.getenv("USER")
})

assert(pg:connect())
assert(pg:query("CREATE EXTENSION IF NOT EXISTS vector"))
assert(pg:query("DROP TABLE IF EXISTS items"))

assert(pg:query("CREATE TABLE items (embedding vector(3))"))

local pgvector = {}
function pgvector.serialize(v)
  return "[" .. table.concat(v, ",") .. "]"
end

embedding1 = pgvector.serialize({1, 1, 1})
embedding2 = pgvector.serialize({2, 2, 2})
embedding3 = pgvector.serialize({1, 1, 2})
assert(pg:query("INSERT INTO items (embedding) VALUES ($1::vector), ($2::vector), ($3::vector)", embedding1, embedding2, embedding3))

embedding = pgvector.serialize({1, 1, 1})
local res = assert(pg:query("SELECT * FROM items ORDER BY embedding <-> $1::vector LIMIT 5", embedding))
for i, row in ipairs(res) do
  for k, v in pairs(row) do
    print(k, v)
  end
end

assert(pg:query("CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)"))
