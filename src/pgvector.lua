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
  local res = {}
  for x in string.gmatch(string.sub(v, 2, -2), "[^,]+") do
    table.insert(res, tonumber(x))
  end
  -- pgvector.new without copy
  return setmetatable(vec, vector_mt)
end

function pgvector.setup_vector(pg)
  local res = table.unpack(pg:query("SELECT oid FROM pg_type WHERE typname = 'vector'"))
  assert(res, "vector oid not found")
  pg:set_type_deserializer(res.oid, "vector", function(self, v) return pgvector.deserialize(v) end)
end

return pgvector
