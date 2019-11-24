--
-------------------------------------------------------------------------------
--         File:  tsdp.lua
--
--        Usage:  local tsdp = require"dwark.lpeg.tsdp".tdsp
--                tsdp:match(line) -- from some log.tdsp file
--
--  Description:  parse lines in "timestamped data point"-format
--
--      Options:  ---
-- Requirements:  ---
--         Bugs:  ---
--        Notes:  ---
--       Author:  YOUR NAME (), <>
-- Organization:
--      Version:  1.0
--      Created:  13-10-19
--     Revision:  ---
-------------------------------------------------------------------------------
-- tsdp format: timestamp worker_name start stop [tags args data]
-- where
--  o timestamp is in epoch seconds
--  o worker_name may contain dots
--  o start is relative to timestamp [seconds]
--  o stop is relative to timestamp [seconds], may be last value on the line
--  o tags is list of key:val
--  o args is list of key=val
--  o data is a json-encoded string of some data-point

local core = require "dwark.lpeg"
local P = core.P
local S = core.S
local Cf = core.Cf
local Ct = core.Ct
local mk = core.mk
local mkv = core.mkv
local mt = core.mt
local mj = core.mj
local digit = core.digit
local alpha = core.alpha
local alnum = core.alnum
local space = core.space

--[[ locals ]]

local number = digit^1 -- / tonumber
local name = (alpha + P"_") * (alnum + S"._")^0
local key = (alpha + P"_") * (alnum + P"_")^0
local value = (1 - space)^1
local restofline = (1-S"\r\n")^0

--[[ tsdp pattern ]]

return Cf(  Ct""
          * mkv("tstamp", number/tonumber) * space^1
          * mk("worker",  name)
          * mkv("start",  number/tonumber) * space^1
          * mkv("stop",   number/tonumber) * space^0
          * mkv("tags",   mt(name, P":", value))
          * mkv("args",   mt(key, P"=", value))
          * mkv("data",   mj(restofline))
          , rawset)

