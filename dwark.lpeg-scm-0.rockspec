package = "dwark.lpeg"
version = "scm-0"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   detailed = [[ Another set of lpeg patterns ]],
   homepage = "*** please enter a project homepage ***",
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
