package = "dwark.lpeg"
version = "scm-0"
source = {
   url = "https://github.com/hertogp/dwark_lpeg"
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
      ["dwark.lpeg"] = "dwark/lpeg/init.lua",
      ["dwark.lpeg.http"] = "dwark/lpeg/http.lua",
      ["dwark.lpeg.ip"] = "dwark/lpeg/ip.lua",
      ["dwark.lpeg.spf"] = "dwark/lpeg/spf.lua",
      ["dwark.lpeg.tsdp"] = "dwark/lpeg/tsdp.lua"
   }
}
