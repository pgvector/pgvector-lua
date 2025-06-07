local pgmoon = require("pgmoon")
local pgvector = require("./src/pgvector")

local pg = pgmoon.new({
  database = "pgvector_lua_test",
  user = os.getenv("USER")
})

assert(pg:connect())
assert(pg:query("CREATE EXTENSION IF NOT EXISTS vector"))
pgvector.setup_vector(pg)

local vec = pg:query("SELECT $1::vector::text", pgvector.new({1, 2, 3}))[1]["text"]
assert(vec == "[1,2,3]")

local vec = pg:query("SELECT '[1,2,3]'::vector")[1]["vector"]
assert(#vec == 3)
assert(vec[1] == 1)
assert(vec[2] == 2)
assert(vec[3] == 3)

local vec = pg:query("SELECT $1::halfvec::text", pgvector.halfvec({1, 2, 3}))[1]["text"]
assert(vec == "[1,2,3]")

local vec = pg:query("SELECT '[1,2,3]'::halfvec")[1]["halfvec"]
assert(#vec == 3)
assert(vec[1] == 1)
assert(vec[2] == 2)
assert(vec[3] == 3)

local vec = pg:query("SELECT $1::sparsevec::text", pgvector.sparsevec({[1] = 1, [3] = 2, [5] = 3}, 6))[1]["text"]
assert(vec == "{1:1,3:2,5:3}/6")

local vec = pg:query("SELECT '{1:1,3:2,5:3}/6'::sparsevec")[1]["sparsevec"]
assert(vec["elements"][1] == 1)
assert(vec["elements"][2] == nil)
assert(vec["elements"][3] == 2)
assert(vec["elements"][4] == nil)
assert(vec["elements"][5] == 3)
assert(vec["elements"][6] == nil)
assert(vec["dim"] == 6)
