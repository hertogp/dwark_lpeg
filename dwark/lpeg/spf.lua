--
------------------------------------------------------------------------------
--         File:  dwark.lpeg.spf.lua
--
--        Usage:  local spfp = require "dwark.lpeg.spf"
--
--  Description:  Match and parse spf records
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
-- SPF  - https://tools.ietf.org/html/rfc7208
-- ABNF - https://tools.iejktf.org/html/rfc7208#section-12

local core = require "dwark.lpeg"
local ip = require "dwark.lpeg.ip"

local abnf = core.abnf
local alnum = core.alnum
local digit = core.digit
local alpha = core.alpha
local B = core.B
local C = core.C
local Cc = core.Cc
local Cp = core.Cp
local Ct = core.Ct
local I = core.nocase
local P = core.P
local R = core.R
local S = core.S
local endswith = core.endswith

--[[ helpers ]]

local function swap(t)
  -- swap 1st and 2nd entry in array (swaps qualifier w/ mechanism 1st word)
  if t and #t>1 then
    t[1], t[2] = t[2], t[1]
  end
  return t
end

--[[ generic ]]

local sep = P(1 - abnf.SP)

--[[ DNS ]] -- dns names, ignoring the TLD restrictions
local idnastart = I"xn--"
local dnslabel = P(1-S". ")^1
local dnsname = P(
  idnastart^-1
  * (dnslabel * P"."^-1)^1
)

--[[ MACRO ]] -- macro string

local mdelim = S".-+,/_="
local mtrans = abnf.DIGIT^0 * I"r"^-1
local mletter = S"slodiphcrtvSLODIPHCRTV"
local mliteral = R"\33\36" + R"\38\126"
local mexpand = P"%{" * mletter * mtrans * mdelim^0 * P"}" + P"%" * S"%_-"
local mstrelm = (mexpand + mliteral)     -- macro string elements
local mstring = (mexpand + mliteral)^0   -- entire macro string

local mexpant= Ct(P"%{" * C(mletter)
                        * C(abnf.DIGIT^0)
                        * C(I"r"^-1)
                        * C(mdelim^0)
                        * P"}"
                   + C(P"%" * S"%_-"))

--[[ DOMAINSPEC ]] -- LDH-label (letters, digits, hyphen) w/ TLD restrictions

local ldhlabel = P(
  (alpha + digit^1 * (alpha + "-"))
  * (alnum + P"-")^1
  * #B(alnum))
local domain_end = P"." * ldhlabel * P"."^-1 + mexpand
local domain_spec = endswith(mstrelm, domain_end, abnf.SP + P"/")

--[[ mechanism ]]
local dual_cidr = C((P"/" * ip.v4.length)^-1) * C((P"//" * ip.v6.length)^-1)
local all = C(I"all")

local a =   C(I"a")   * (P":" * C(domain_spec) + Cc"") * dual_cidr
local mx =  C(I"mx")  * (P":" * C(domain_spec) + Cc"") * dual_cidr
local ptr = C(I"ptr") * (P":" * C(domain_spec) + Cc"")

local ip4 = C(I"ip4") * P":" * C(ip.v4.network + ip.v4.address)
local ip6 = C(I"ip6") * P":" * C(ip.v6.network + ip.v6.address)
local include = C(I"include") * P":" * C(domain_spec)
local exists = C(I"exists")  * P":" * C(domain_spec)

--[[ directive ]]
local mechanism = all + a + mx + ip4 + ip6 + include + ptr + exists
local qualifier = C(S"+?~-") + Cc"+"
local directive = Ct(qualifier * mechanism)/swap

--[[ modifier ]]
local redirect = C(I"redirect") * P"=" * C((1-abnf.SP)^1)
local explanation = C(I"exp") * P"=" * C((1-abnf.SP)^1)
local unknown = C((1-sep)^1) * P"=" * C((1-abnf.SP^1))
local modifier = Ct(redirect + explanation + unknown)

--[[ record ]]
local version = Ct(C(I"v") * P"=" * C(I"spf") * C(digit^1))
local record = Ct(version * (abnf.SP^1 * (directive + modifier))^0) * Cp()
local parts = core.ts(abnf.SP) -- simple split on space
--> empty string means (illegal) repeated SP ..

--[[ return ]]

return {
  parts = parts,                 -- split version, terms on whitespace
  record = record,               -- true syntax check

  version = version,
  mechanism = mechanism,
  modifier = modifier,

  -- for testing individual expressions
  dual_cidr = C(dual_cidr),
  delim = C(mdelim),
  macro_string = C(mstring),

  dnslabel = C(dnslabel),
  dnsname = C(dnsname),
  toplabel = C(ldhlabel),
  domain_end = C(domain_end),
  domain_spec = C(domain_spec),
  mtokens = Ct((mexpant + C(mliteral^1))^1),  -- tokens in a macrostring

  -- present core as well
  core = core
}
