local pgvector = {}

function pgvector.serialize(v)
  return "[" .. table.concat(v, ",") .. "]"
end

function pgvector.deserialize(v)
  local res = {}
  for v in string.gmatch(string.sub(value, 2, -2), "[^,]+") do
    table.insert(res, v)
  end
  return res
end

return pgvector
