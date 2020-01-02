# dwark.lpeg
IMAGINE=~/dev/imagine/pandoc_imagine.py
BUSTED=`which busted`
LUACHECK=`which luacheck`
LUAVERSION :=$(shell lua -e "print(_VERSION:match('^%S+%s+(%S+)'))")

help:
	@echo "make targets:"
	@echo "- test       : runs busted on this directory"
	@echo "- check      : runs luacheck on all Lua files"
	@echo "- install    : runs luarocks --local to install dwark.lpegs"
	@echo "- uninstall  : runs luarocks --local to remove dwark.lpegs"
	@echo "- help       : shows this message."
	@echo "- readme     : convert doc/_readme.md to README.md
	@echo "----------------:------------------------------------------"
	@echo "Lua version     : ${LUAVERSION}"

test:
	@${BUSTED} .

check:
	@${LUACHECK} dwark/lpeg/*.lua

install:
	@luarocks --local make dwark-lpegs-scm-0.rockspec

uninstall:
	@luarocks --local remove dwark.lpegs

readme:
	@pandoc --filter $(IMAGINE) -f markdown -t gfm -o README.md doc/_readme.md
	@pandoc --filter $(IMAGINE) -f gfm -o doc/README.pdf README.md
