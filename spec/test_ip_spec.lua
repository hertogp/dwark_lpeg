--
--------------------------------------------------------------------------------
--         File:  test_ip_spec.lua
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

local lpeg = require"lpeg"
local ip = require "dwark.lpeg.ip"

local ipv4_good = {
  "0.0.0.0/0",
  "255.255.255.255/32",
  "10.10.10.10/3",
}

local ipv4_bad = {
  "0/0",
  "10/8",
  "255.255.255.255/33",
  "10.10.10.256/30",
  "10.10.10.10/128",
}

local ipv6_good = {
  "1:2:3:4:5:6:1.2.3.4/128",

  "1:2:3:4:5:6:7:8/128",
  "1:2:3:4:5:6:7::/128",
  "1:2:3:4:5:6::/128",
  "1:2:3:4:5::/128",
  "1:2:3:4::/128",
  "1:2:3::/128",
  "1:2::/128",
  "1::/128",
  "::/128",

  "::1/128",
  "::1:2/128",
  "::1:2:3/128",
  "::1:2:3:4/128",
  "::1:2:3:4:5/128",
  "::1:2:3:4:5:6/128",
  "::1:2:3:4:5:6:7/128",

  "1::2/128",
  "1:2::3:4/128",
  "1:2:3::4:5:6/128",
  "1:2:3::4:5:6:7/128",
  "1:2:3::4:5:1.2.3.4/128",

  "1:2:3:4:5:6:7::/128",
  "1:2:3:4:5:6::7/128",
  "1:2:3:4:5::6:7/128",
  "1:2:3:4::5:6:7/128",
  "1:2:3::4:5:6:7/128",
  "1:2::3:4:5:6:7/128",
  "1::2:3:4:5:6:7/128",
  "::1:2:3:4:5:6:7/128",

  "::dead:beef/32",
  "::255.255.255.255/32",
  "::FFFF:129.144.52.38/128",
}

local ipv6_bad = {
  "::12345/12",
  "a:b:c:d:e:f:g/40",
  "::1.2:3.4/128",
  "a::b::1.2.3.4/128",
  "::1.2.3.256/128",
}


describe("ipv4 networks", function()
  local pfx4 = lpeg.C(ip.v4.network) * -1  -- *-1 to match the entire string

  it("should match good ip4 networks", function()
    for i, pfx in ipairs(ipv4_good) do
      assert.are.same(pfx, pfx4:match(pfx))
    end
  end)

  it("should fail bad ip4 networks", function()
    for i, pfx in ipairs(ipv4_bad) do
      assert.falsy(pfx4:match(pfx))
    end
  end)

  it("should parse ip.v4 networks", function()
    local addr, mlen
    addr, mlen = ip.v4.parts:match("1.1.1.1")
    assert.are.same("1.1.1.1", addr)
    assert.are.same(32, mlen)

    addr, mlen = ip.v4.parts:match("1.1.1.1/24")
    assert.are.same("1.1.1.1", addr)
    assert.are.same(24, mlen)

    addr, mlen = ip.v4.parts:match("1.1.1.1/33")
    assert.are.same(nil, addr)
    assert.are.same(nil, mlen)

    addr, mlen = ip.v4.parts:match("1.256.1.0/24")
    assert.are.same(nil, addr)
    assert.are.same(nil, mlen)
  end)

end)

describe("ipv6 networks", function()
  local pfx6 = lpeg.C(ip.v6.network) * -1

  it("should match good ip6 networks", function()
    for i, pfx in ipairs(ipv6_good) do
      assert.are.same(pfx, pfx6:match(pfx))
    end
  end)

  it("should fail bad ip6 networks", function()
    for i, pfx in ipairs(ipv6_bad) do
      assert.falsy(pfx6:match(pfx))
    end
  end)

  it("should parse ip.v6 networks", function()
    local addr, mlen
    addr, mlen = ip.v6.parts:match("2000::1.1.1.1")
    assert.are.same("2000::1.1.1.1", addr)
    assert.are.same(128, mlen)

    addr, mlen = ip.v6.parts:match("2000::1.1.1.1/124")
    assert.are.same("2000::1.1.1.1", addr)
    assert.are.same(124, mlen)

    addr, mlen = ip.v6.parts:match("2000:ag::/120")
    assert.are.same(nil, addr)
    assert.are.same(nil, mlen)

    addr, mlen = ip.v6.parts:match("2000:ab::/129")
    assert.are.same(nil, addr)
    assert.are.same(nil, mlen)
  end)

  it("should parse both v4,v6 at the same time", function()
    local addr, mlen, version
    addr, mlen, version = ip.parts:match("1.1.1.1/24")
    assert.are.same("1.1.1.1", addr)
    assert.are.same(24, mlen)
    assert.are.same(4, version)

    addr, mlen, version = ip.parts:match("2000::1.1.1.1/124")
    assert.are.same("2000::1.1.1.1", addr)
    assert.are.same(124, mlen)
    assert.are.same(6, version)
  end)

end)
