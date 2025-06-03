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
assert(pg:query("CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(768))"))
assert(pg:query("CREATE INDEX ON documents USING GIN (to_tsvector('english', content))"))

function embed(input, task_type)
  -- nomic-embed-text uses a task prefix
  -- https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
  local task_input = {}
  for i, v in ipairs(input) do
    task_input[i] = task_type .. ": " .. v
  end

  local url = "http://localhost:11434/api/embed"
  local data = {
    input = task_input,
    model = "nomic-embed-text"
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

  return res["embeddings"]
end

local documents = {
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
}
local embeddings = embed(documents, "search_document")
for i, content in ipairs(documents) do
  local embedding = embeddings[i]
  assert(pg:query("INSERT INTO documents (content, embedding) VALUES ($1, $2)", content, pgvector.new(embedding)))
end

local sql = [[
WITH semantic_search AS (
    SELECT id, RANK () OVER (ORDER BY embedding <=> $2) AS rank
    FROM documents
    ORDER BY embedding <=> $2
    LIMIT 20
),
keyword_search AS (
    SELECT id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC)
    FROM documents, plainto_tsquery('english', $1) query
    WHERE to_tsvector('english', content) @@ query
    ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC
    LIMIT 20
)
SELECT
    COALESCE(semantic_search.id, keyword_search.id) AS id,
    COALESCE(1.0 / ($3 + semantic_search.rank), 0.0) +
    COALESCE(1.0 / ($3 + keyword_search.rank), 0.0) AS score
FROM semantic_search
FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
ORDER BY score DESC
LIMIT 5
]]
local query = "growling bear"
local embedding = embed({query}, "search_query")[1]
local k = 60
local res = assert(pg:query(sql, query, pgvector.new(embedding), k))
for i, row in ipairs(res) do
  print("document: " .. row["id"] .. ", RRF score: " .. row["score"])
end
