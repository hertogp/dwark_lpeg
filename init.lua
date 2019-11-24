--
-------------------------------------------------------------------------------
--         File:  dwark.lpeg.init.lua
--
--        Usage:  via require
--
--  Description:  core patterns for use by other sets of lpeg patterns
--
--      Options:  ---
-- Requirements:  ---
--         Bugs:  ---
--        Notes:  ---
--       Author:  YOUR NAME (), <>
-- Organization:
--      Version:  1.0
--      Created:  13-10-19
--     Revision:
-------------------------------------------------------------------------------
--

local cjson = require"cjson"
local L = require "lpeg"
L.locale(L) -- load L name space with locales (eg L.space)

--[[ ABNF ]]

local abnf = {                      -- rfc5234 B.1 core rules

  ALPHA  = L.R("AZ","az"),          -- %x41‑5A / %x61‑7A ; A‑Z  /  a‑z
  BIT    = L.R"01",                 -- "0" / "1"
  CHAR   = L.R"\1\127",             -- %x01-7F ; any 7bit CHAR except NULL
  CR     = L.P"\r",                 -- %x0D ; carriage return
  CRLF   = L.P"\r"^-1 * L.P"\n",    -- CR  LF ; Internet standard newline
                                    --> nb: CR is optional
  CTL    = L.R("\0\31","\127\127"), -- %x00‑1F / %x7F ; any US-ASCII ctl char
                                    --> (octets 0-31) & DEL(127) control chars
  DIGIT  = L.R"09",                 -- %x30‑39 ; 0-9
  DQUOTE = L.P'"',                  -- %x22 ; " (Double Quote)
  HEXDIG = L.R("09","AF","af"),     -- DIGIT/ "A" / "B" / "C" / "D" / "E" / "F"
                                    --> Note: according to the 'char-val' rule,
                                    --> letters (A-F) are case insensitive
  HTAB   = L.P"\t",                 -- %x09 ; horizontal tab
  LF     = L.P"\n",                 -- %x0A ; linefeed
  OCTET  = L.P(1),                  -- %x00-FF ; 8bits of DATA
  SP     = L.P" ",                  -- %x20 ; space
  VCHAR  = L.R"\33\126",            -- %x21-7E ; visible (printing) chars
                                    --> same as  R"!~"

  PCHAR  = L.R"\32\126"             -- printable characters (not ABNF term)
                                    --> same as L.R" ~" (includes space)
}

abnf.WSP  = abnf.SP + abnf.HTAB     -- SP /  HTAB ; white space

abnf.LWSP = ( abnf.WSP              -- *( WSP /  CRLF  WSP )
             + abnf.CRLF * abnf.WSP -- ; linear white space (past newline)
             )^0

--[[ DEBUG ]]

-- luacheck: ignore rawset_dbg
local function rawset_dbg(t, k, v)
  -- debug version of rawset
  print(">>", t, k, v)
  t[k] = v
  return t
end

--[[ CORE functions ]]

local function mc(p)
  --- capture of pattern p, allow for surrounding whitespace
  return abnf.WSP^0 * L.C(p) * abnf.WSP^0
end

local function mk(key, p)
  -- capture p's result, prepend literal key and return as group capture
  --> use this if pattern p does not capture itself
  return L.Cg(L.Cc(key) * mc(p))
end

local function mkv(key, val)
  -- prepend literal key to a value and return as group capture
  --> use this one if you have a pattern that already captures itself
  return L.Cg(L.Cc(key) * val)
end

local function decode(s)
  -- json-decode string `s` as an array of tables
  if type(s) ~= "string" or #s < 1 then
    return {{}}
  end
  local t = cjson.decode(s) or {}  -- either a table or array of tables
  return t[1] and t or {t}         -- always return an array of tables
end

local function mj(p)
  -- match p & json decode its match result into an array of tables
  return L.Cf(mc(p) * L.Cc(" "), decode)
end

local function mt(key, assign, val)
  -- capture key|assign|val patterns into a table (eg k1=v1 k2=v2)
  return L.Cf(L.Ct("") * (L.Cg(mc(key) * assign * mc(val)))^0, rawset)
end

local function mlist(key, assign, val, sep)
  -- capture key|assign|val|sep patterns into a table (eg k1=v1, k2=v2)
  return L.Cf(L.Ct("") * (L.Cg(mc(key) * assign * mc(val) * sep^0))^0, rawset)
end

local function splitter(sep, repeated)
  -- if repeated separators are allowed, then it won't produce empty strings
  sep = L.P(sep)
  local elm = L.C((1 - sep)^0)
  if repeated then
    return L.Ct(elm * (sep^1 * elm)^0)
  else
    return L.Ct(elm * (sep * elm)^0)
  end
end

local function nocase(s)
  -- return a case-insensitive pattern for string s
  assert(type(s) == "string")
  if #s == 0 then return L.P"" end
  local p
  for c in s:gmatch"." do
    local l,u = c:lower(), c:upper()
    local pp = u==l and L.P(c) or L.S(l..u)
    p = p and p * pp or pp
  end
  return p
end

local function endswith(p1, p2, sep)
  -- ensure p1^0 matches, while ending with a p2 match
  p1, p2 = L.P(p1), L.P(p2)
  sep = sep and (L.P(sep) + -1) or -1  -- sep defaults to end-of-string
  return (((p1 - p2 * sep)^0) * p2)
end

-- the main part
-- L has lpeg's C, Cc, .. and digit, alnum, etc ...
-- add core patterns and functions

L.abnf = abnf

-- the helpers
L.mc = mc               -- match & capture, allow surrounding whitespace
L.mj = mj               -- match & json decode into an array of tables
L.mk = mk               -- match val & assign to specified key in table
L.mkv = mkv             -- insert literal key, matched-value
L.mt = mt               -- match key|sep|val patterns, capture in a table
L.mlist = mlist         -- parse key|assign|val|sep?-list into table
L.ts = splitter         -- split string into array
L.split = splitter
L.nocase = nocase       -- return pattern to match string case-insensitive
L.endswith = endswith   -- match p1 if input ends with p2

return L
