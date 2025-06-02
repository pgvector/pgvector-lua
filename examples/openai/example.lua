local cjson = require("cjson")
local http = require("socket.http")
local ltn12 = require("ltn12")
local pgmoon = require("pgmoon")
local pgvector = require("./src/pgvector")

local pg = pgmoon.new({
  database = "pgvector_example",
  user = os.getenv("USER")
})

assert(pg:connect())
assert(pg:query("CREATE EXTENSION IF NOT EXISTS vector"))
assert(pg:query("DROP TABLE IF EXISTS documents"))
assert(pg:query("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))"))

function embed(input)
  local api_key = os.getenv("OPENAI_API_KEY")
  local url = "https://api.openai.com/v1/embeddings"
  local data = {
    input = input,
    model = "text-embedding-3-small"
  }
  local headers = {
    ["Authorization"] = "Bearer " .. api_key,
    ["Content-Type"] = "application/json"
  }
  local chunks = {}
  local r, c, h = http.request {
    method = "POST",
    url = url,
    headers = headers,
    source = ltn12.source.string(cjson.encode(data)),
    sink = ltn12.sink.table(chunks)
  }
  assert(c == 200)
  local data = cjson.decode(table.concat(chunks))["data"]
  local embeddings = {}
  for i, object in ipairs(data) do
    embeddings[i] = object["embedding"]
  end
  return embeddings
end

local documents = {
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
}
local embeddings = embed(documents)
for i, content in ipairs(documents) do
  local embedding = embeddings[i]
  assert(pg:query("INSERT INTO documents (content, embedding) VALUES ($1, $2)", content, pgvector.new(embedding)))
end

local query = "forest"
local embedding = embed({query})[1]
local res = assert(pg:query("SELECT content FROM documents ORDER BY embedding <=> $1 LIMIT 5", pgvector.new(embedding)))
for i, row in ipairs(res) do
  print(row["content"])
end
