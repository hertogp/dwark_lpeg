package = "dwark.lpeg"
version = "scm-0"
source = {
   url = "https://github.com/hertogp/dwark_lpeg.git"
}
description = {
   detailed = [[ Another set of lpeg patterns ]],
   homepage = "https://github.com/hertogp/dwark_lpeg.git",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.3",
   "lpeg"
}
build = {
   type = "builtin",
   modules = {
      ["dwark.lpeg"] = "init.lua",
      ["dwark.lpeg.http"] = "http.lua",
      ["dwark.lpeg.ip"] = "ip.lua",
      ["dwark.lpeg.spf"] = "spf.lua",
      ["dwark.lpeg.tsdp"] = "tsdp.lua"
   }
}
