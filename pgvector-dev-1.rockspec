package = "pgvector"
version = "dev-1"
source = {
   url = "git+https://github.com/pgvector/pgvector-lua.git"
}
description = {
   summary = "pgvector support for Lua",
   detailed = "pgvector support for Lua",
   homepage = "https://github.com/pgvector/pgvector-lua",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      pgvector = "src/pgvector.lua"
   }
}
