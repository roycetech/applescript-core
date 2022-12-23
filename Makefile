help:
	@echo "make install - Create config files, assets, and install essential
	libraries."

	@echo "make install-core - install the core AppleScript libraries in the current user's Library/Script Library folder"
	@echo "make install-automator - install additional config for spot testing"
	@echo "make compile-library - compiles a script library.  e.g. make compile-lib SOURCE=src/std"
	@echo "make reveal-config - reveals the default AppleScript Core configurations folder in Finder"
	@echo "make reveal-lib - reveals the default AppleScript user libraries deployment folder in Finder"
	@echo "make reveal-apps - reveals the default AppleScript apps deployment folder in Finder"
	@echo "-s option hides the Make invocation command."

# Simplify to pick all files inside core folder.
# CORE_LIBS := std config logger plutil string
CORE_LIBS := std logger config plutil string-builder string map pots regex \
unicodes switch unit-test spot list datetime idler retry keyboard file process \
syseve clipboard emoji

APPS_PATH=/Applications/AppleScript

_init:
	mkdir -p ~/Library/Script\ Libraries
	mkdir -p ~/applescript-core/sounds/
	mkdir -p ~/applescript-core/logs/
	mkdir -p "/Applications/AppleScript/Stay Open/"
	./scripts/compile-bundle.sh 'core/Core Text Utilities'

install: _init $(CORE_LIBS)
	cp -n config-default.template ~/applescript-core/config-default.plist || true
	cp -n config-emoji.template ~/applescript-core/config-emoji.plist || true
	cp -n plist.template ~/applescript-core/config-system.plist || true
	cp -n plist.template ~/applescript-core/session.plist || true
	cp -n plist.template ~/applescript-core/switches.plist || true
	cp -a assets/sounds/. ~/applescript-core/sounds/
	touch ~/applescript-core/logs/applescript-core.log

$(CORE_LIBS): Makefile
	./scripts/compile-lib.sh core/$@


compile-lib:
	./scripts/compile-lib.sh $(SOURCE)

compile-bundle:
	./scripts/compile-bundle.sh $(SOURCE)

# Fails to work with accessibility permission error. Export via Script Editor
# fails as well. Use Automator-created apps instead, see "Create Automator App.applescript"
compile-app:
	./scripts/compile-app.sh $(SOURCE)

# Fails to work when we try to hide the icon in the dock.
compile-stay-open:
	./scripts/compile-stay-open.sh $(SOURCE)


reveal-config:
	open ~/applescript-core

reveal-lib:
	open ~/Library/Script\ Libraries

reveal-apps:
	open $(APPS_PATH)

reveal-stay-open:
	open $(APPS_PATH)/Stay\ Open


# Extra Libraries ================================

install-dvorak:
	compile-lib SOURCE=core/decorators/dec-keyboard-dvorak-cmd
	plutil -replace 'KeyboardInstance' -string 'dec-keyboard-dvorak-cmd' ~/applescript-core/config-lib-factory.plist

install-script-editor:
	make compile-lib SOURCE="apps/1st-party/Script Editor/2.11/script-editor"

install-finder:
	./scripts/compile-lib.sh apps/1st-party/Finder/12.5/finder

install-automator:
	mkdir -p /Applications/AppleScript
	./scripts/compile-lib.sh apps/1st-party/Automator/2.10/automator
	cp -n plist.template ~/applescript-core/config-system.plist || true
	osascript scripts/setup-applescript-apps-path.applescript

# Optional with 3rd party app dependency.
install-json:
	./scripts/compile-lib.sh core/json.applescript
