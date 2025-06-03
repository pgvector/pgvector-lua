-- good resources
-- https://opensearch.org/blog/improving-document-retrieval-with-sparse-semantic-encoders/
-- https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1
--
-- run with
-- text-embeddings-router --model-id opensearch-project/opensearch-neural-sparse-encoding-v1 --pooling splade

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
assert(pg:query("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))"))

function sparsevec(elements, dim)
  local e = {}
  for k, v in pairs(elements) do
    table.insert(e, k .. ":" .. v)
  end
  return "{" .. table.concat(e, ",") .. "}/" .. dim
end

function embed(inputs)
  local url = "http://localhost:3000/embed_sparse"
  local data = {
    inputs = inputs,
  }
  local headers = {
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
  for i, item in ipairs(res) do
    local embedding = {}
    for i, v in ipairs(item) do
      embedding[v["index"] + 1] = v["value"]
    end
    embeddings[i] = embedding
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
  assert(pg:query("INSERT INTO documents (content, embedding) VALUES ($1, $2::text::sparsevec)", content, sparsevec(embedding, 30522)))
end

local query = "forest"
local embedding = embed({query})[1]
local res = assert(pg:query("SELECT content FROM documents ORDER BY embedding <#> $1::text::sparsevec LIMIT 5", sparsevec(embedding, 30522)))
for i, row in ipairs(res) do
  print(row["content"])
end
