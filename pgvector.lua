local pgvector = {}

function pgvector.serialize(v)
  return "[" .. table.concat(v, ",") .. "]"
end

function pgvector.deserialize(v)
  local res = {}
  for x in string.gmatch(string.sub(v, 2, -2), "[^,]+") do
    table.insert(res, x)
  end
  return res
end

return pgvector
