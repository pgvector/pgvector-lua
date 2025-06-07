local pgvector = {}

-- vector

local vector_mt = {
  pgmoon_serialize = function(v)
    return 0, pgvector.serialize(v)
  end,
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

-- halfvec

local function halfvec_serialize(v)
  for _, v in ipairs(v) do
    assert(type(v) == "number")
  end
  return "[" .. table.concat(v, ",") .. "]"
end

local function halfvec_deserialize(v)
  local vec = {}
  for x in string.gmatch(string.sub(v, 2, -2), "[^,]+") do
    table.insert(vec, tonumber(x))
  end
  -- pgvector.halfvec without copy
  return setmetatable(vec, halfvec_mt)
end

local halfvec_mt = {
  pgmoon_serialize = function(v)
    return 0, halfvec_serialize(v)
  end,
}

function pgvector.halfvec(v)
  local vec = {}
  for _, x in ipairs(v) do
    table.insert(vec, x)
  end
  return setmetatable(vec, halfvec_mt)
end

-- sparsevec

local function sparsevec_serialize(vec)
  local elements = {}
  for i, v in pairs(vec["elements"]) do
    table.insert(elements, tonumber(i) .. ":" .. tonumber(v))
  end
  return "{" .. table.concat(elements, ",") .. "}/" .. tonumber(vec["dim"])
end

local function sparsevec_deserialize(v)
  local m = string.gmatch(v, "[^/]+")
  local elements = {}
  for e in string.gmatch(string.sub(m(), 2, -2), "[^,]+") do
    local mx = string.gmatch(e, "[^:]+")
    local index = tonumber(mx())
    local value = tonumber(mx())
    elements[index] = value
  end
  local vec = {
    elements = elements,
    dim = tonumber(m()),
  }
  return setmetatable(vec, sparsevec_mt)
end

local sparsevec_mt = {
  pgmoon_serialize = function(v)
    return 0, sparsevec_serialize(v)
  end,
}

function pgvector.sparsevec(elements, dim)
  for k, v in pairs(elements) do
    assert(type(k) == "number")
    assert(type(v) == "number")
  end
  assert(type(dim) == "number")

  local vec = {
    elements = elements,
    dim = dim,
  }
  return setmetatable(vec, sparsevec_mt)
end

-- register

function pgvector.setup_vector(pg)
  local row = pg:query(
    "SELECT to_regtype('vector')::oid AS vector_oid, to_regtype('halfvec')::oid AS halfvec_oid, to_regtype('sparsevec')::oid AS sparsevec_oid"
  )[1]
  assert(row["vector_oid"], "vector type not found in the database")
  pg:set_type_deserializer(row["vector_oid"], "vector", function(self, v)
    return pgvector.deserialize(v)
  end)
  if row["halfvec_oid"] then
    pg:set_type_deserializer(row["halfvec_oid"], "halfvec", function(self, v)
      return halfvec_deserialize(v)
    end)
  end
  if row["sparsevec_oid"] then
    pg:set_type_deserializer(row["sparsevec_oid"], "sparsevec", function(self, v)
      return sparsevec_deserialize(v)
    end)
  end
end

return pgvector
