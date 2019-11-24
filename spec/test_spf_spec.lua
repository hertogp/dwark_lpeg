--
--------------------------------------------------------------------------------
--         File:  test_spf_spec.lua
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

local spf = require "dwark.lpeg.spf"

describe("spf.dual_cidr", function()
  local dual = spf.dual_cidr * -1

  it("should match /0-32", function()
    for i = 0, 32 do
      local mask = string.format("/%s", i)
      assert.are.same(mask, dual:match(mask))
    end
  end)

  it("should not match bad ip4 lengths", function()
      assert.falsy(dual:match("/33"))
      assert.falsy(dual:match("/128"))
  end)

  it("should match good ip6 lengths", function()
    for i = 0, 128 do
      local mask = string.format("//%s", i)
      assert.are.same(mask, dual:match(mask))
    end
  end)

  it("should not match bad ip6 lengths", function()
      assert.falsy(dual:match("//129"))
      assert.falsy(dual:match("//ff"))
  end)

  it("should match good ip4/ip6 lengths", function()
    for i = 0, 32 do
      for j = 0, 128 do
        local mask = string.format("/%s//%s", i,j)
        assert.are.same(mask, dual:match(mask))
      end
    end
  end)

  it("should not match bad ip4/ip6 lengths", function()
      assert.falsy(dual:match("/33//128"))
      assert.falsy(dual:match("/0//129"))
  end)

end)

describe("spf.delim", function()
  local delims = {".", "-", "+", ",", "/", "_", "="}
  local delim = spf.delim * -1
  it("should match delimeters", function()
    for _, d in ipairs(delims) do
      assert.are.same(d, delim:match(d))
    end
  end)
end)

describe("spf.macro", function()
  local macro = spf.macro_string * -1
  it("should match good macro's", function()
    local macros = {
      "r", "%{ir}", "%{s}", "%{o}", "%{d}", "%{d4}", "%{d3}", "%{d2}",
      "%{d1}", "%{dr}", "%{d2r}", "%{l}", "%{l-}", "%{lr}", "%{lr-}",
      "%{l1r-}", "%{ir}.%{v}",
      "%{ir}.%{v}._spf.%{d2}",
      "%{lr-}.lp._spf.%{d2}",
      "%{lr-}.lp.%{ir}.%{v}._spf.%{d2}",
      "%{ir}.%{v}.%{l1r-}.lp._spf.%{d2}",
      "%{d2}.trusted-domains.example.net.",
      "%{ir}.%{v}._spf.%{d2}",
    }
    for _, m in ipairs(macros) do
      assert.are.same(m, macro:match(m))
    end
  end)
end)

describe("spf.dnsname", function()
  local obj = spf.dnsname * -1
  it("should match good spec's", function()
    local values = {
      "example.",
      "example.com.",
      "example.com",
      "*.example.com",
      "*.example.com.",
      "_ldap._tcp.example.com",
      "_ldap.*.example.com",
      "xn--exmple-kva.com",
    }

    for _, v in ipairs(values) do
      assert.are.same(v, obj:match(v))
    end
  end)
end)

describe("spf.toplabel", function()
  local obj = spf.toplabel * -1
  it("should match good TLD labels", function()
    local values = {
      "example", "1example", "example1", "ex0mple",
      "1-bbb-1", "1-1", "1-1-1", "a-a-a", "aa-a-aa",
      "1--1", "a--1", "1--a", "a--a",
    }

    for _, v in ipairs(values) do
      assert.are.same(v, obj:match(v))
    end
  end)

  it("should not match bad TLD labels", function()
    local values = {
      "example.com",
      "-b", "-b-", "b-", "11"
    }

    for _, v in ipairs(values) do
      assert.falsy(obj:match(v))
    end
  end)
end)

describe("spf.domain_end", function()
  local domain = spf.domain_end * -1
  it("should match good TLD labels", function()
    local domains = {
      ".example", ".1example", ".example1", ".ex0mple",
      ".1-bbb-1", ".1-1", ".1-1-1", ".a-a-a", ".aa-a-aa",
      ".1--1", ".a--1", ".1--a", ".a--a",
      ".example.", ".1example.", ".example1.", ".ex0mple.",
      ".1-bbb-1.", ".1-1.", ".1-1-1.", ".a-a-a.", ".aa-a-aa.",
      ".1--1.", ".a--1.", ".1--a.", ".a--a.",
    }
    for _, x in ipairs(domains) do
      assert.are.same(x, domain:match(x))
    end
  end)
end)

describe("spf.domain_spec", function()
  local domain = spf.domain_spec * -1
  it("should match good domain specs", function()
    local domains = {
      "%{ir}.com",
      "r.com",
      -- macro-expands
      "%{s}", "%{o}", "%{d}", "%{d4}", "%{d3}", "%{d2}",
      "%{d1}", "%{dr}", "%{d2r}", "%{l}", "%{l-}", "%{lr}", "%{lr-}",
      "%{l1r-}", "%{ir}.%{v}",
      -- macro-expand macro-literals macro-expand
      "%{ir}.%{v}._spf.%{d2}", "%{lr-}.lp._spf.%{d2}",
      "%{lr-}.lp.%{ir}.%{v}._spf.%{d2}", "%{ir}.%{v}.%{l1r-}.lp._spf.%{d2}",
      -- macro-expand macro-literals domain-end
      "%{d2}.trusted-domains.example.net.",
      "%{ir}.%{v}._spf.%{d2}",
      -- macro-expand special chars
      "%_.com", "%%.com", "%_.com", "%_.com.%_", "%%%_%-.com"
    }
    for _, x in ipairs(domains) do
      assert.are.same(x, domain:match(x))
    end
  end)
end)

describe("spf syntax", function()
  local obj = spf.record * -1
  it("should match good spf records", function()
    local tests = {
      "v=SPF1",
      "v=spf1 aLl",
      "v=spf1 +all",
      "v=spf1 ?all",
      "v=spf1 ~all",
      "v=spf1 a/24//30",
      "v=spf1 a//30",
      "v=spf1 a/24 a:example.com redirect=_spf.example.com",
      "v=spf1 a/24 a:example.com/24//40 redirect=_spf.example.com",
      "v=spf1 a -all",
      "v=spf1 a:example.org -all",
      "v=spf1 ip4:192.0.2.128/28 ~all",
      "v=spf1 redirect=example.org ?all",
      "v=spf1 -ip4:192.0.2.0/24 +all",
      "v=spf1 a/24//60",
      "v=spf1 ip4:145.50.40.10 include:_spf.iprox.nl -all",
      "v=spf1 ip4:145.50.40.10 exists:_spf.iprox.nl -all",
      "v=spf1 ip4:145.50.40.10 ptr:_spf.iprox.nl -all",
      "v=spf1 ptr:_spf.iprox.nl -all",
      "v=spf1 -ptr +all",
      "v=spf1 ptr -all",
      "v=spf1 mx mx:example.org -all",
      "v=spf1 mx/30 mx:example.org -all",
      "v=spf1 mx/30//68 mx:example.org/30//68 -all",
      "v=spf1 mx -all",
      "v=spF1 mx:%{d}.example.org -all",
      "v=spf1 exists:_h.%{h}._l.%{l}._o.%{o}._i.%{i}._spf.%{d} ?all",
    }
    for _, test in ipairs(tests) do
      assert(obj:match(test))
    end
  end)
end)

describe("spf rfc examples", function()
  local obj = spf.record * -1

  it("should be matched by spf.record", function()
    local tests = {
      "v=spf1 +mx a:colo.example.com/28 -all",
      "v=spf1 a:A.EXAMPLE.COM -all",
      "v=spf1 +mx -all",
      "v=spf1 +mx redirect=_spf.example.com",
      "v=spf1 a mx -all",
      "v=spf1 include:example.com include:example.org -all",
      "v=spf1 redirect=_spf.example.com",
      "v=spf1 mx:example.com -all",
      "v=spf1 exists:_h.%{h}._l.%{l}._o.%{o}._i.%{i}._spf.%{d} ?all",
      "v=spf1 ip4:192.0.2.1 ip4:192.0.2.129 -all",
      "v=spf1 a:authorized-spf.example.com -all",
      "v=spf1 mx:example.com -all",
      "v=spf1 ip4:192.0.2.0/24 mx -all",
      "v=spf1 -all",
      "v=spf1 a -all",
      "v=spf1 +all",
      "v=spf1 a -all",
      "v=spf1 a:example.org -all",
      "v=spf1 mx -all",
      "v=spf1 mx:example.org -all",
      "v=spf1 mx mx:example.org -all",
      "v=spf1 mx/30 mx:example.org/30 -all",
      "v=spf1 ptr -all",
      "v=spf1 ip4:192.0.2.128/28 -all",
      "v=spf1 include:example.com include:example.net -all",
      "v=spf1 redirect=example.org",
      "v=spf1 mx",
      "v=spf1 exists:%{l1r+}.%{d}",
      "v=spf1 exists:%{ir}.%{l1r+}.%{d}",
      "v=spf1 -ip4:192.0.2.0/24 +all",
      "v=spf1 -ptr +all",
      "v=spf1 exists:_h.%{h}._l.%{l}._o.%{o}._i.%{i}._spf.%{d} ?all",
      "v=spf1 mx ?exists:%{ir}.whitelist.example.org -all",
      "v=spf1 mx exists:%{l}._spf_verify.%{d} -all",
      "v=spf1 mx redirect=%{l1r+}._at_.%{o}._spf.%{d}",
      "v=spf1 mx exists:%{ir}._spf_rate.%{d} -all",
      "v=spf1 mx exists:%{ir}.%{l1r-+}._spf.%{d} -all",
      "v=spf1 mx exists:%{ir}.%{L1R+-}._spf.%{d} -all",
    }
    for _, test in ipairs(tests) do
      assert(obj:match(test))
    end
  end)
end)
