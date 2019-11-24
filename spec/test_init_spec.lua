--
--------------------------------------------------------------------------------
--         File:  test_init_spec.lua
--
--        Usage:  busted .
--
--  Description:  test lpeg patterns
--
--      Options:  ---
-- Requirements:  ---
--         Bugs:  ---
--        Notes:  ---
--       Author:  YOUR NAME (), <>
-- Organization:
--      Version:  1.0
--      Created:  17-10-19
--     Revision:  ---
--------------------------------------------------------------------------------
--

-- local lpeg = require "lpeg"
local core = require "dwark.lpeg"
local json = require "cjson"
local F = string.format

describe("dwark.lpeg", function()
  local abnf = core.abnf

  it("matches the basic ABNF character types", function()
    --[[ ABNF ]]
    for i=0, 255 do
      local c = string.char(i)

      --[[ - OCTET ]] -- matches any 8 bit char data
      assert.truthy(abnf.OCTET:match(c),
        F("abnf.OCTET should have matched char %d (%q)", i, c))

      --[[ - CHAR ]] -- matches any 7 bit char data, except NULL
      if i>0 and i<128 then
        assert.truthy(abnf.CHAR:match(c),
          F("abnf.CHAR should have matched char %d, %s", i, c))
      else
        assert.falsy(abnf.CHAR:match(c),
          F("abnf.CHAR should NOT match char %d, %s", i, c))
      end

      --[[ - ALPHA ]] -- matches only letters
      if c:match("[A-Za-z]") then
        assert.truthy(abnf.ALPHA:match(c),
           F("ALPHA char %d (%q) did not match", i, c))
      else
        assert.falsy(abnf.ALPHA:match(c),
           F("ALPHA char %d (%q) should not match", i, c))
      end

      --[[ - CTL ]] -- matches control chars 0-31 and 127
      if i<32 or i==127 then
        assert.truthy(abnf.CTL:match(c),
          F("abnf.CTL should have matched char %d (%s)", i, c))
      else
        assert.falsy(abnf.CTL:match(c),
          F("abnf.CTL should NOT have matched char %d (%s)", i, c))
      end

      --[[ - HEXDIGIT ]]
      if c:match("[0-9A-Fa-f]") then
        assert.truthy(abnf.HEXDIG:match(c),
          F("abnf.HEXDIG should have matched char %d (%s)", i, c))
      else
        assert.falsy(abnf.HEXDIG:match(c),
          F("abnf.HEXDIG should NOT have matched char %d (%s)", i, c))
      end

      --[[ - DIGIT ]]
      if c:match("[0-9]") then
        assert.truthy(abnf.DIGIT:match(c),
          F("abnf.DIGIT should have matched char %d (%s)", i, c))
      else
        assert.falsy(abnf.DIGIT:match(c),
          F("abnf.DIGIT should NOT have matched char %d (%s)", i, c))
      end

      --[[ - WSP ]]
      if c:match("[ \t]") then
        assert.truthy(abnf.WSP:match(c),
          F("abnf.WSP should have matched char %d (%s)", i, c))
      else
        assert.falsy(abnf.WSP:match(c),
          F("abnf.WSP should NOT have matched char %d (%s)", i, c))
      end

      --[[ - VCHAR ]] -- matches visible characters (which excludes whitespace)
      if i>=33 and i<=126 then
        assert.truthy(abnf.VCHAR:match(c),
          F("abnf.VCHAR should have matched char %d (%s)", i, c))
      else
        assert.falsy(abnf.VCHAR:match(c),
          F("abnf.VCHAR should NOT have matched char %d (%s)", i, c))
      end

      --[[ - PCHAR ]] -- matches printable characters (which includes a space)
      if i>=32 and i<=126 then
        assert.truthy(abnf.PCHAR:match(c),
          F("abnf.PCHAR should have matched char %d (%s)", i, c))
      else
        assert.falsy(abnf.PCHAR:match(c),
          F("abnf.PCHAR should NOT have matched char %d (%s)", i, c))
      end

    end --> end of for loop

    --[[ - CRLF ]] -- the \r is optional
    assert.truthy(abnf.CRLF:match("\r\n"), "should've matched '\\r\\n'")
    assert.truthy(abnf.CRLF:match("\n"), "should've matched '\\n'")

    --[[ - LWSP ]]
    -- linear whitespace
    assert.truthy(abnf.LWSP:match(" \t\r\n \t"),
      "should've matched linear whitespace")
    assert.truthy(abnf.LWSP:match(" \r\n \t"),
      "should've matched linear whitespace")
    assert.truthy(abnf.LWSP:match("\r\n \t"),
      "should've matched linear whitespace")
    assert.truthy(abnf.LWSP:match("\n \t"),
      "should've matched linear whitespace")

    -- regular whitespace
    assert.truthy(abnf.LWSP:match(" \t"),
      "should've matched regular whitespace")
    assert.truthy(abnf.LWSP:match("\t"),
      "should've matched regular whitespace")
    assert.truthy(abnf.LWSP:match(" "),
      "should've matched regular whitespace")
    assert.truthy(abnf.LWSP:match("      "),
      "should've matched regular whitespace")
    assert.truthy(abnf.LWSP:match("\t\t\t"),
      "should've matched regular whitespace")
  end)

  --[[ core.mc() ]]
  it("mc() captures lpeg expression", function()
    local s = "%LINEPROTO-5-UPDOWN:"
    local Ct, P, mc = core.Ct, core.P, core.mc
    local p = Ct(  P"%" * mc((1-P"-")^1)
                 * P"-" * mc((1-P"-")^1)
                 * P"-" * mc((1-P":")^1))
    local t = p:match(s)
    assert.are.same("LINEPROTO", t[1])
    assert.are.same("5", t[2])
    assert.are.same("UPDOWN", t[3])
  end)

  --[[ core.mk() ]]
  it("mk() captures and inserts literal key before matched value", function()
    local s = "%SYS-5-CONFIG_I:"
    local Cf, Ct, P, mk = core.Cf, core.Ct, core.P, core.mk
    local p = Cf(Ct("") * P"%" * mk("facility", (1-P"-")^1)
                        * P"-" * mk("severity", (1-P"-")^1)
                        * P"-" * mk("mnemonic", (1-P":")^1), rawset)
    local t = p:match(s)
    assert.are.same("SYS", t.facility)
    assert.are.same("5", t.severity)
    assert.are.same("CONFIG_I", t.mnemonic)

  end)

  --[[ core.mt() ]]
  it("mt() parses key|sep|val-pairs into a table", function()
    local tests = {
      "a=1 b=2 c=3",
      "a = 1 b = 2 c = 3",
      "a= 1 b =2 c = 3"
    }
    local key = core.alpha
    local val = core.digit
    local sep = core.P"="
    for _, test in ipairs(tests) do
      local t = core.mt(key, sep, val):match(test)
      assert.are.same("1", t.a)
      assert.are.same("2", t.b)
      assert.are.same("3", t.c)
    end

  end)

  --[[ core.mlist() ]]
  it("mlist() parses k,v pairs from a k,v-list", function()
    local tests = {
      "from:localhost, to:bounce@example.net, bounced:3 times",
      "from : localhost, to : bounce@example.net, bounced : 3 times",
      "from: localhost, to :bounce@example.net, bounced : 3 times",
    }
    local sep = core.S","
    local key = core.alpha^1
    local val = (1-sep)^1
    local assign = core.P":"
    for _, test in ipairs(tests) do
      local t = core.mlist(key, assign, val, sep):match(test)
      assert.are.same("localhost", t.from)
      assert.are.same("bounce@example.net", t.to)
      assert.are.same("3 times", t.bounced)
    end
  end)

  --[[ core.mj() ]]
  it("mj() json decodes a match result", function()
    local t = { foo = 1, bar = 2, baz = { foo = 3, bar = 4} }
    local s = json.encode(t)          -- table as a string
    local x = core.P(1)^1             -- match all characters
    local m = core.mj(x):match(s)     -- parse into array of tables
    assert.are.same(1, #m)            -- array of tables with 1 element
    assert.are.same(t.foo, m[1].foo)
    assert.are.same(t.bar, m[1].bar)
    assert.are.same(t.baz.foo, m[1].baz.foo)
    assert.are.same(t.baz.bar, m[1].baz.bar)
  end)

  --[[ core.nocase() ]]
  it("nocase() allows for case-insensitive matching", function()
    local m = core.nocase("abc")
    assert.truthy(m:match("abc"))

    assert.truthy(m:match("Abc"))
    assert.truthy(m:match("aBc"))
    assert.truthy(m:match("abC"))

    assert.truthy(m:match("ABc"))
    assert.truthy(m:match("aBC"))
    assert.truthy(m:match("AbC"))

    assert.truthy(m:match("ABC"))
  end)

  --[[ core.split() ]]
  it("split() splits a string on 1 or more chars", function()
    -- split on 1 or more chars, no repeating separators
    local tests = {
      -- separator string -> test string
      [" "]   = "a b c",
      [", "]  = "a, b, c",
      [" , "] = "a , b , c",
    }

    -- split and donot allow repeated separators
    for k,v in pairs(tests) do
      local t = core.split(k):match(v)
      assert.are.same(3, #t)
      assert.are.same("a", t[1])
      assert.are.same("b", t[2])
      assert.are.same("c", t[3])
    end

    -- split and allow for repeated separators
    local t = core.split(" ", true):match("a  b  c")
    assert.are.same(3, #t)
    assert.are.same("a", t[1])
    assert.are.same("b", t[2])
    assert.are.same("c", t[3])

    -- not allowing repeated separators means ""-fields
    t = core.split(" ", false):match("a  b  c")
    assert.are.same(5, #t)
    assert.are.same("a", t[1])
    assert.are.same("",  t[2])
    assert.are.same("b", t[3])
    assert.are.same("",  t[4])
    assert.are.same("c", t[5])

    -- split on a set of characters, allowing repeated separator chars
    local sep = core.S" ,"
    t = core.split(sep, true):match("a,  b  ,  c")
    assert.are.same(3, #t)
    assert.are.same("a", t[1])
    assert.are.same("b", t[2])
    assert.are.same("c", t[3])
  end)

  it("endswith() checks a match for p1^1 endswith p2", function()
    -- repeatedly matches p1 as long as the match ends with p2
    local p1 = core.P(1)     -- just match anything
    local p2 = core.digit^1  -- p1^0 match result must end with p2
    local p3 = core.P","     -- stop matching here (default is end-of-string)

    -- match until end-of-string
    assert.truthy(core.endswith(p1, p2):match("the answer is 42"))

    -- match until ","
    assert.truthy(core.endswith(p1, p2, p3):match("the answer is 42, right?"))

    -- match till end-of-string, but it doesnt end with digits
    assert.falsy(core.endswith(p1, p2):match("the answer is 42, right?"))
  end)

end)
