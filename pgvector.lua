local pgvector = {}

function pgvector.serialize(v)
  return "[" .. table.concat(v, ",") .. "]"
end

function pgvector.deserialize(v)
  local res = {}
  for x in string.gmatch(string.sub(v, 2, -2), "[^,]+") do
    table.insert(res, tonumber(x))
  end
  return res
end

function pgvector.setup_vector(pg)
  local res = table.unpack(pg:query("SELECT oid FROM pg_type WHERE typname = 'vector'"))
  assert(res, "vector oid not found")
  pg:set_type_deserializer(res.oid, "vector", function(self, v) return pgvector.deserialize(v) end)
end

return pgvector
