help:
	@echo "make install - Create config files, assets, and install essential
	libraries."

	@echo "make install_core - install the core AppleScript libraries in the current user's Library/Script Library folder"
	@echo "make compile_library - compiles a script library.  e.g. make compile_lib SOURCE=src/std"
	@echo "-s option hides the Make invocation command."

# Simplify to pick all files inside core folder.
# CORE_LIBS := std config logger plutil string
CORE_LIBS := std logger config plutil string-builder string map

_init:
	mkdir -p ~/Library/Script\ Libraries
	mkdir -p ~/applescript-core/sounds/
	mkdir -p ~/applescript-core/logs/
	./scripts/compile-bundle.sh 'core/Core Text Utilities'

install: _init $(CORE_LIBS)
	cp plist.template ~/applescript-core/config-default.plist
	cp plist.template ~/applescript-core/session.plist
	cp -a assets/sounds/. ~/applescript-core/sounds/
	touch ~/applescript-core/logs/applescript-core.log

$(CORE_LIBS): Makefile
	./scripts/compile-lib.sh core/$@


compile-lib:
	./scripts/compile-lib.sh $(SOURCE)

compile-bundle:
	./scripts/compile-bundle.sh $(SOURCE)

compile-app:
	./scripts/compile-lib.sh $(SOURCE) # TODO: Not Implemented

compile-stay-open:
	./scripts/compile-lib.sh $(SOURCE) # TODO: Not Implemented


reveal-config:
	open ~/applescript-core

reveal-lib:
	open ~/Library/Script\ Libraries

