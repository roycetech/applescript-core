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
CORE_LIBS := std logger config plutil string-builder string map speech regex \
unicodes switch unit-test spot-test list date-time idler retry keyboard file \
process syseve clipboard emoji window stack dialog

APPS_PATH=/Applications/AppleScript

_init:
	mkdir -p ~/Library/Script\ Libraries
	mkdir -p ~/applescript-core/sounds/
	mkdir -p ~/applescript-core/logs/
	mkdir -p "/Applications/AppleScript/Stay Open/"
	./scripts/compile-bundle.sh 'core/Core Text Utilities'
	plutil -replace 'Project applescript-core' -string "`pwd`" ~/applescript-core/config-system.plist

install: _init compile-core
	cp -n config-default.template ~/applescript-core/config-default.plist || true
	cp -n config-emoji.template ~/applescript-core/config-emoji.plist || true
	cp -n plist.template ~/applescript-core/config-system.plist || true
	cp -n plist.template ~/applescript-core/session.plist || true
	cp -n plist.template ~/applescript-core/switches.plist || true

	cp -n plist.template ~/applescript-core/config-user.plist || true
	cp -a assets/sounds/. ~/applescript-core/sounds/
	touch ~/applescript-core/logs/applescript-core.log
	osascript scripts/register-project.applescript
	./scripts/setup-switches.sh
	@echo "Installation done"

$(CORE_LIBS): Makefile
	./scripts/compile-lib.sh core/$@

uninstall:
	# TODO


compile-core: $(CORE_LIBS)

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
# Suggestion: Install related core libraries so that related updates don't
# require a separate make install.

# 1st Party Apps Library
install-calendar:
	./scripts/compile-lib.sh "apps/1st-party/Calendar/11.0/calendar"
	./scripts/compile-lib.sh "apps/1st-party/Calendar/11.0/calendar-event"
	./scripts/compile-lib.sh "apps/1st-party/Calendar/11.0/dec-calendar-view"

install-system-preferences:
	./scripts/compile-lib.sh "apps/1st-party/System Preferences/15.0/system-preferences"

install-safari:
	./scripts/compile-lib.sh apps/1st-party/Safari/16.0/safari
	./scripts/compile-lib.sh apps/1st-party/Safari/16.0/safari-javascript

install-script-editor:
	make compile-lib SOURCE="apps/1st-party/Script Editor/2.11/script-editor"

install-finder:
	./scripts/compile-lib.sh apps/1st-party/Finder/12.5/finder

compile-automator:
	./scripts/compile-lib.sh apps/1st-party/Automator/2.10/automator

install-automator: compile-automator
	mkdir -p /Applications/AppleScript
	# cp -n plist.template ~/applescript-core/config-system.plist || true
	osascript scripts/setup-applescript-apps-path.applescript

uninstall-automator:
	# TODO:


# 3rd Party Apps Library
install-marked:
	./scripts/compile-lib.sh apps/3rd-party/Marked/2.6.x/marked

install-atom:
	./scripts/compile-lib.sh apps/3rd-party/Atom/1.60.0/atom

install-step-two:
	./scripts/compile-lib.sh apps/3rd-party/Step Two/3.1/step-two

install-keyboard-maestro:
	./scripts/compile-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro
	./scripts/compile-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro

install-text-mate:
	./scripts/compile-lib.sh apps/3rd-party/TextMate/2.0.x/text-mate

install-sequel-ace:
	./scripts/compile-lib.sh apps/3rd-party/Sequel Ace/4.0.x/sequel-ace


# Library Decorators
install-dvorak:
	./scripts/compile-lib.sh core/decorators/dec-keyboard-dvorak-cmd
	./scripts/compile-lib.sh core/keyboard
	plutil -replace 'KeyboardInstance' -string 'dec-keyboard-dvorak-cmd' ~/applescript-core/config-lib-factory.plist


install-cliclick:
	./scripts/compile-lib.sh libs/cliclick/cliclick
	osascript libs/cliclick/setup-cliclick-cli.applescript


# Optional with 3rd party app dependency.
install-json:
	./scripts/compile-lib.sh core/json.applescript

