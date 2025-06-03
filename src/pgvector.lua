local pgvector = {}

local vector_mt = {
  pgmoon_serialize = function(v)
    return 0, pgvector.serialize(v)
  end
}

function pgvector.new(v)
  local vec = {}
  for _, x in ipairs(v) do
    table.insert(vec, x)
  end
  return setmetatable(vec, vector_mt)
end

function pgvector.serialize(v)
  for _, v in ipairs(v) do
    assert(type(v) == "number")
  end
  return "[" .. table.concat(v, ",") .. "]"
end

function pgvector.deserialize(v)
  local vec = {}
  for x in string.gmatch(string.sub(v, 2, -2), "[^,]+") do
    table.insert(vec, tonumber(x))
  end
  -- pgvector.new without copy
  return setmetatable(vec, vector_mt)
end

function pgvector.setup_vector(pg)
  local row = pg:query("SELECT to_regtype('vector')::oid AS vector_oid")[1]
  assert(row["vector_oid"], "vector type not found in the database")
  pg:set_type_deserializer(row["vector_oid"], "vector", function(self, v) return pgvector.deserialize(v) end)
end

return pgvector
