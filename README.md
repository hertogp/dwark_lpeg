---
title: dwark.lpeg
topic: matching and parsing
author: git.padh@github.com
...

Another set of lpeg patterns, see:
- [*`lpeg`*](http://www.inf.puc-rio.br/~roberto/lpeg/)
  Parsing Expression Grammars for Lua, version 1.0

- [*`lpeg-parsers`*](https://github.com/spc476/LPeg-Parsers)
  an extensive collection of lpeg parsers, by `spc476`

- [*`lpeg-patterns`*](https://github.com/daurnimator/lpeg_patterns)
  another large collection of lpeg patterns, by `daurnimator`

# dwark.lpeg

The 'core' of the set of lpeg patterns, it:

- pulls in lpeg's [*`locale`*](phttp://www.inf.puc-rio.br/~roberto/lpeg/#basic)
    - `alnum`, `alpha`, `cntrl`, `digit`, `graph`, `lower`,
    - `print`, `punct`, `space`, `upper`, and `xdigit`

- and the lpeg [*`functions`*](http://www.inf.puc-rio.br/~roberto/lpeg/#intro)
    - `P` to match a string of `n`-characters
    - `S` to match a `set` of characters (eg S", ")
    - `R` to match a `range` of characters (eg R"09")
    - `B` to match `behind` current position

- and the lpeg
  [*`captures`*](http://www.inf.puc-rio.br/~roberto/lpeg/#captures)
    - `C(p)` -> the match for `p` and all its captures
    - `Carg(n)` -> the value of the `n`-th argument to p:match()
    - `Cb(name)` -> the values of a previous group capture `name`
    - `Cc(values)` -> the literal values given
    - `Cf(p, func)` -> the `folding` of what `p` captures
    - `Cg(p [, name])` -> 
    - `Cp()`
    - `Cs(p)`
    - `Ct(p)`
    - `Cmt(p, func)`

- provides ABNF patterns
    - `ALPHA`, matches letters
    - `BIT`, matches either 0 or 1
    - `CHAR`, matches any 7bit character except `NULL`
    - `CR`, matches carriage return
    - `LF`, matches a line feed
    - `CRLF`, matches carriage return, line feed OR just line feed
    - `CTRL`, matches control chars 0-31 and 127
    - `DIGIT`, matches 0-9
    - `DQUOTE`, matches '"'
    - `HEXDIG`, matches a hexadecimal character
    - `HTAB`, matches horizontal tab
    - `OCTET`, matches any 8bit character data
    - `SP`, matches a space
    - `VCHAR`, matches visible characters (33-126)
    - `PCHAR`, matches printable characters (32-126, which includes space)
    - `WSP`, matches a single whitespace (space or tab)
    - `LWSP`, matches 1+ linear whitespace (space, tab, cr, lf)

- functions to create patterns
    - `mc(p)`, capture `p`'s match result
    - `mj`, json-decode `p`'s match result
    - `mk`, captures a pattern's result and inserts literal key before
    - `mkv`, insert literal key before `p`'s value
    - `mt`, match and capture key|sep|val patterns into a table
    - `mlist`, same but for key|sep|val|sep? patterns
    - `ts`, split a string on a pattern
    - `split`, same
    - `nocase`, case-insensitive match of some string
    - `endswith`, matches 1+ time pattern p1, as long as it ends with p2


Usage:
```lua
local core = require "dwark.lpeg"
```

## dwark.lpeg.spf

- parse an SPF record
    - `parts`, parses an SPF record into a list of terms
- SPF record syntax check
    - `record`, matches a syntactily correct SPF record
- match parts of an SPF record
    - `version`, matches an SPF version term
    - `mechanism`, matches an SPF mechanism
    - `modifier`, matches an SPF modifier
    - `mtokens`, matches tokens in a macro-string (returns a list)
    - `dnsname`, matches a domain name
    - `dnslabel`, matches a domain name label
    - `toplabel`, matches a top level label with restrictions
- pulls in `dwark.lpeg` as well
    - `core` is namespace for `dwark.lpeg`

## dwark.lpeg.ip

- match and parse ipv4 and ipv6 addresses and networks

The `v{4,6}.{address,length,network}` patterns are used for matching parts of
an spf record and match as many characters as they can while stil producing a
valid address and/or length.  So `v4.address:match("1.1.1.256")` returns `9`
since it matched `1.1.1.25` as a valid address, stopping that the `6`.

The `v{4,6}.parts` patterns however, does not and continues to match until
whitespace is seen, or end-of-string.


```lua
local ip = require "dwark.lpeg.ip"

print(ip.v4.address:match("1.1.1.1"))             --> 8
print(ip.v4.length:match("24"))                   --> 3
print(ip.v4.network:match("1.1.1.1/24"))          --> 11

print(ip.v6.address:match("2000:ab::"))           --> 10
print(ip.v4.length:match("98"))                   --> 3
print(ip.v4.network:match("2000:ab::/98"))        --> 13

print(ip.v6.address:match("2000::1.1.1.1/98"))    --> 17

print(ip.v6.network:match("2000::1.1.1.256/98"))  --> nil

-- gotcha:
print(ip.v6.network:match("2000::1.1.1.1/129"))   --> 17, matches ../12

-- require end-of-string:
print((ip.v6.network * -1):match("2000::1.1.1.1/129")  --> nil

-- parts
print(ip.v4.parts:match("1.1.1.1/24"))  --> "1.1.1.1", 24
print(ip.v4.parts:match("1.1.1.1/33"))  --> nil, nil

print(ip.v6.parts:match("2000::1.1.1.1/124")  --> "2000::1.1.1.1", 124
print(ip.v6.parts:match("2000:ag::1.1.1.1/124")  --> nil, nil
print(ip.v6.parts:match("2000:::1.1.1.1/129")  --> nil, nil

-- either v4 or v6
local addr, mlen, version = ip.parts("1.1.1.1/24")
print(addr,mlen,version) --> "1.1.1.1", 24, 4

addr, mlen, version = ip.parts("2000::1.1.1.1/124")
print(addr,mlen,version) --> "2000::1.1.1.1", 124, 6
```


## dwark.lpeg.tsdp

- parse log lines in a "timestamped data-point"-format:

    `tstamp worker start stop tags args data`

    where
     - `tstamp` is seconds since the epoch
     - `worker` is the name of log entry creator
     - `start`  is relative to tstamp
     - `stop`   is relative to tstamp
     - `tags`   is list of tag:value's for filtering logs (if any)
     - `args`   is list of key=value's the worker used (if any)
     - `data`   json-encoded data of the worker's results (if any)

```lua
local tsdp = require "dwark.lpeg.tsdp"
local line = "123 some.name 0 3 tag:demo key=val {\"answer\": 42}"
local t = tsdp:match(line)

print(t.tstamp)        --> 123
print(t.worker)        --> some.name
print(t.start)         --> 0
print(t.stop)          --> 3
print(t.tags.tag)      --> "demo"
print(t.args.key)      --> "val"
print(t.data[1])       --> table 0x..  : list of table(s)
print(t.data[1].answer --> 42.0        : 42 decoded to a float
```


## dwark.lpeg.http

- parse header and status code



