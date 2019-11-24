--
--------------------------------------------------------------------------------
--         File:  test_tsdp_spec.lua
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

local tsdp = require "dwark.lpeg.tsdp"
local F = string.format

describe("tsdp log format parser", function()

  it("parses a basic log line", function()
    local line = "1573113293 dns.rr 3 0"
    local t = tsdp:match(line)

    assert.truthy(t)
    assert.are.same(1573113293, t.tstamp)
    assert.are.same("dns.rr", t.worker)
    assert.are.same(3, t.start)
    assert.are.same(0, t.stop)

    local n = 0

    assert.are.same("table", type(t.tags))
    for _,_ in pairs(t.tags) do n = n + 1 end
    assert.are.same(0, n, "expected t.tags table to be empty")

    assert.are.same("table", type(t.args))
    for _,_ in pairs(t.args) do n = n + 1 end
    assert.are.same(0, n, "expected t.args table to be empty")

    assert.are.same("table", type(t.data))
    assert.are.same(1, #t.data) -- is always a list of tables
    for _,_ in pairs(t.data[1]) do n = n + 1 end
    assert.are.same(0, n, "expected t.data[1] table to be empty")
  end)

  it("parses a log line with tags", function()
    local line = "1573113293 dns.rr 3 0 rid:42 tip:pro"
    local t = tsdp:match(line)

    assert.truthy(t)
    assert.are.same(1573113293, t.tstamp)
    assert.are.same("dns.rr", t.worker)
    assert.are.same(3, t.start)
    assert.are.same(0, t.stop)

    assert.are.same("table", type(t.tags))
    assert.are.same("42", t.tags.rid)
    assert.are.same("pro", t.tags.tip)

    assert.are.same("table", type(t.args))
    assert.are.same("table", type(t.data))
  end)

  it("parses a log line with args", function()
    local line = "1573113293 dns.rr 3 0 ip=10.10.10.11 type=A host=localhost"
    local t = tsdp:match(line)

    assert.truthy(t)
    assert.are.same(1573113293, t.tstamp)
    assert.are.same("dns.rr", t.worker)
    assert.are.same(3, t.start)
    assert.are.same(0, t.stop)

    assert.are.same("table", type(t.tags))
    local n = 0
    for _,_ in pairs(t.tags) do n = n + 1 end
    assert.are.same(0, n, "expected t.tags table to be empty")

    assert.are.same("table", type(t.args))
    assert.are.same("10.10.10.11", t.args.ip)
    assert.are.same("A", t.args.type)
    assert.are.same("localhost", t.args.host)

    assert.are.same("table", type(t.data))
    assert.are.same(1, #t.data)    -- array of tables
    for _,_ in pairs(t.data[1]) do n = n + 1 end
    assert.are.same(0, n)
  end)

  it("parses a log line with data", function()
    local line = "1573113293 dns.rr 3 0 {\"answer\":42}"
    local t = tsdp:match(line)

    assert.truthy(t)
    assert.are.same(1573113293, t.tstamp)
    assert.are.same("dns.rr", t.worker)
    assert.are.same(3, t.start)
    assert.are.same(0, t.stop)

    assert.are.same("table", type(t.tags))
    local n = 0
    for _,_ in pairs(t.tags) do n = n + 1 end
    assert.are.same(0, n)

    assert.are.same("table", type(t.args))
    for _,_ in pairs(t.args) do n = n + 1 end
    assert.are.same(0, n)

    assert.are.same("table", type(t.data))
    assert.are.same(1, #t.data)    -- array of tables
    assert.are.same(42, t.data[1].answer) -- holds 1 emtpy table
  end)

  it("parses a log line with tags, args & data", function()
    local line = "1573113293 dns.rr 3 0 rid:42 tip:pro ip=10.10.10.11 type=A host=localhost {\"answer\":42}"
    local t = tsdp:match(line)

    assert.truthy(t)
    assert.are.same(1573113293, t.tstamp)
    assert.are.same("dns.rr", t.worker)
    assert.are.same(3, t.start)
    assert.are.same(0, t.stop)

    assert.are.same("table", type(t.tags))
    assert.are.same("42", t.tags.rid)
    assert.are.same("pro", t.tags.tip)

    assert.are.same("table", type(t.args))
    assert.are.same("10.10.10.11", t.args.ip)
    assert.are.same("A", t.args.type)
    assert.are.same("localhost", t.args.host)

    assert.are.same("table", type(t.data))
    assert.are.same(1, #t.data)    -- array of tables
    assert.are.same(42, t.data[1].answer) -- holds 1 emtpy table
  end)

end)
