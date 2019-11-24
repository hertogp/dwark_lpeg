--
------------------------------------------------------------------------------
--         File:  dwark.lpeg.ip.lua
--
--        Usage:  ipm = require "dwark.lpeg.ip"
--                ipm.v4.network:match("1.1.1.1/32")
--
--  Description:   Match ipv4/6 addresses, masks and networks
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
-- see https://tools.ietf.org/html/rfc3986#section-3.2.2 (URI-syntax)
--

local core = require "dwark.lpeg"
local Cg = core.Cg
local Cc = core.Cc
local C = core.C
local P = core.P
local R = core.R

local function m(n, p)
  -- match pattern p exactly n times
  local pp = p
  for _ = 1, n-1 do pp = pp * p end
  return pp
end

local eos = core.abnf.WSP + -1                        -- end of string

--[[ IPv4 ]]

local quad = P"1" * R"09" * R"09"                     -- 100-199
           + P"2" * R"04" * R"09"                     -- 200-249
           + P"25" * R"05"                            -- 250-255
           + R"19" * R"09"                            -- 10-99
           + R"09"                                    -- 0-9

-- IPv4address = dec-octet "." dec-octet "." dec-octet "." dec-octet

local ipv4 = m(3, quad * P".")
           * quad

local pfx4 = P"3" * R"02"                             -- 30-32
           + R"12" * R"09"                            -- 10-29
           + R"09"                                    -- 0-9

local net4 = ipv4 * P"/" * pfx4

local amv4 = Cg( C(ipv4)                              -- address, mask v4
                 * ((P"/" * (pfx4/tonumber)) + Cc(32))
                 ) * eos

--[[ IPv6 ]]

local h16 = core.abnf.HEXDIG * core.abnf.HEXDIG^-3    -- 1-4 hexadecimals
local h16c = h16 * P":" * #(1-P":")                   -- end with single colon
local ls32 = (h16c * h16) + ipv4                      -- 32 lsb's (bits)

local pfx6 = P"12" * R"08"                            -- 120-128
           + P"1" * R"01" * R"09"                     -- 100-119
           + R"19" * R"09"                            -- 10-99
           + R"09"                                    -- 1-9


-- IPv6address =                        6( h16 ":" ) ls32
--         /                       "::" 5( h16 ":" ) ls32
--         / [               h16 ] "::" 4( h16 ":" ) ls32
--         / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
--         / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
--         / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
--         / [ *4( h16 ":" ) h16 ] "::"              ls32
--         / [ *5( h16 ":" ) h16 ] "::"              h16
--         / [ *6( h16 ":" ) h16 ] "::"

local ipv6 =                              m(6, h16c) * ls32
           +                      P"::" * m(5, h16c) * ls32
           + (          h16)^-1 * P"::" * m(4, h16c) * ls32
           + (h16c^-1 * h16)^-1 * P"::" * m(3, h16c) * ls32
           + (h16c^-2 * h16)^-1 * P"::" * m(2, h16c) * ls32
           + (h16c^-3 * h16)^-1 * P"::" *      h16c  * ls32
           + (h16c^-4 * h16)^-1 * P"::" *              ls32
           + (h16c^-5 * h16)^-1 * P"::" *              h16
           + (h16c^-6 * h16)^-1 * P"::"

local net6 = ipv6
           * P"/"
           * pfx6

return {

  v4 = {
    address = ipv4,
    length = pfx4,
    network = net4,
    parts = Cg( C(ipv4) * ((P"/" * (pfx4/tonumber)) + Cc(32))) * eos
  },

  v6 = {
    address = ipv6,
    length = pfx6,
    network = net6,
    parts = Cg( C(ipv6) * ((P"/" * (pfx6/tonumber)) + Cc(128))) * eos
  },

  parts = Cg( C(ipv4) * ((P"/" * (pfx4/tonumber)) + Cc(32)) * Cc(4)) * eos
        + Cg( C(ipv6) * ((P"/" * (pfx6/tonumber)) + Cc(128)) * Cc(6)) * eos

}

