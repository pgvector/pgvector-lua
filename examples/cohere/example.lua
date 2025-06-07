local cjson = require("cjson")
local http = require("socket.http")
local ltn12 = require("ltn12")
local pgmoon = require("pgmoon")

local pg = pgmoon.new({
  database = "pgvector_example",
  user = os.getenv("USER")
})

assert(pg:connect())
assert(pg:query("CREATE EXTENSION IF NOT EXISTS vector"))
assert(pg:query("DROP TABLE IF EXISTS documents"))
assert(pg:query("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding bit(1536))"))

function embed(texts, input_type)
  local api_key = os.getenv("CO_API_KEY")
  assert(api_key, "Set CO_API_KEY")
  local url = "https://api.cohere.com/v2/embed"
  local data = {
    texts = texts,
    model = "embed-v4.0",
    input_type = input_type,
    embedding_types = {"ubinary"}
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
  local res = cjson.decode(table.concat(chunks))

  local embeddings = {}
  for i, object in ipairs(res["embeddings"]["ubinary"]) do
    local bits = {}
    for j, byte in ipairs(object) do
      for k = 1, 8 do
        bits[(j - 1) * 8 + k] = (byte >> (8 - k)) & 1
      end
    end
    embeddings[i] = table.concat(bits)
  end
  return embeddings
end

local documents = {
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
}
local embeddings = embed(documents, "search_document")
for i, content in ipairs(documents) do
  local embedding = embeddings[i]
  assert(pg:query("INSERT INTO documents (content, embedding) VALUES ($1, $2::text::varbit)", content, embedding))
end

local query = "forest"
local embedding = embed({query}, "search_query")[1]
local res = assert(pg:query("SELECT content FROM documents ORDER BY embedding <~> $1::text::varbit LIMIT 5", embedding))
for i, row in ipairs(res) do
  print(row["content"])
end
