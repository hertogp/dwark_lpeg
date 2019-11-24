# dwark.lpeg

INSTALL=`which install`
LUACHECK=`which luacheck`
BUSTED=`which busted`
LUAVERSION :=$(shell lua -e "print(_VERSION:match('^%S+%s+(%S+)'))")

info:
	@echo "make test       : runs busted on this directory"
	@echo "make check      : runs luacheck on all lua files"
	@echo "make install    : runs luarocks --local to install targets"
	@echo "make uninstall  : runs luarocks --local to remove targets"
	@echo "make info       : shows values of variables, paths etc.."
	@echo "----------------:"
	@echo "install command : ${INSTALL}"
	@echo "lua version     : ${LUAVERSION}"

test:
	@${BUSTED} .

check:
	@${LUACHECK} *.lua

