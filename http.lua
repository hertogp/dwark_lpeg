--
------------------------------------------------------------------------------
--         File:  dwark.lpeg.http.lua
--
--        Usage:  Used by worker to match http headers
--
--  Description:
--
--      Options:  ---
-- Requirements:  ---
--         Bugs:  ---
--        Notes:  ---
--       Author:  YOUR NAME (), <>
-- Organization:
--      Version:  1.0
--      Created:  15-10-19
--     Revision:  ---
------------------------------------------------------------------------------
--

local core = require "dwark.lpeg"
local abnf = core.abnf
local Ct = core.Ct
local Cg = core.Cg
local P = core.P

local number = abnf.DIGIT^1
local dotnr = number * P"." * number
local version = P"HTTP/" * dotnr
local explain = abnf.PCHAR^0 -- all printable chars (visible + space)

local key = (1-P":")^1
local val = (1-abnf.CRLF)^1

--[[ http patterns ]]

local status = Ct(
               Cg(version, "version") * abnf.WSP
             * Cg(number,  "code") * abnf.WSP
             * Cg(explain, "status")
           )

local header = Ct(
               Cg(key, "k") * P":" * abnf.WSP^0
             * Cg(val, "v"))

return {
  status = status,
  header = header
}
