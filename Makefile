# dwark.lpeg
IMAGINE=~/dev/imagine/pandoc_imagine.py
BUSTED=`which busted`
LUACHECK=`which luacheck`
LUAVERSION :=$(shell lua -e "print(_VERSION:match('^%S+%s+(%S+)'))")

help:
	@echo "make target     : what it does:"
	@echo "----------------:------------------------------------------"
	@echo "make test       : runs busted on this directory"
	@echo "make check      : runs luacheck on all Lua files"
	@echo "make install    : runs luarocks --local to install dwark.lpeg"
	@echo "make uninstall  : runs luarocks --local to remove dwark.lpeg"
	@echo "make help       : shows this message."
	@echo "----------------:------------------------------------------"
	@echo "Lua version     : ${LUAVERSION}"

test:
	@${BUSTED} .

check:
	@${LUACHECK} dwark/lpeg/*.lua

install:
	@luarocks --local make dwark_lpeg-scm-0.rockspec

uninstall:
	@luarocks --local remove dwark.lpeg

readme:
	@pandoc --filter $(IMAGINE) -f markdown -t gfm -o README.md doc/_readme.md
	@pandoc --filter $(IMAGINE) -f gfm -o doc/README.pdf README.md
