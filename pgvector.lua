local pgvector = {}

function pgvector.serialize(v)
  return "[" .. table.concat(v, ",") .. "]"
end

return pgvector
