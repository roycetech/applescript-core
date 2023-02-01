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
CORE_LIBS :=  clipboard config date-time dialog emoji file idler keyboard list \
logger map plutil process regex retry spot-test std string string-builder \
speech stack switch  syseve ui-util unicodes unit-test window

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
	cp -n plist.template ~/applescript-core/config-business.plist || true
	cp -a assets/sounds/. ~/applescript-core/sounds/
	touch ~/applescript-core/logs/applescript-core.log
	osascript scripts/setup-applescript-core-project-path.applescript
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


compile-safari:
	./scripts/compile-lib.sh apps/1st-party/Safari/16.0/safari
	./scripts/compile-lib.sh apps/1st-party/Safari/16.0/safari-javascript

install-safari: compile-safari
	osascript ./scripts/allow-apple-events-in-safari.applescript
	plutil -replace 'FIND_RETRY_MAX' -integer 90 ~/applescript-core/config-system.plist
	plutil -replace 'FIND_RETRY_SLEEP' -integer 1 ~/applescript-core/config-system.plist

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
	@echo "TODO"
	# TODO:

compile-terminal:
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/terminal
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-output
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-path
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-prompt
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-run

install-terminal: compile-terminal


# macOS Version-Specific Apps
install-control-center:
	./scripts/compile-lib.sh "macOS-version/12-monterey/control-center"

# 3rd Party Apps Library
install-1password:
	./scripts/compile-lib.sh apps/3rd-party/1Password/v6/1password

install-atom:
	./scripts/compile-lib.sh apps/3rd-party/Atom/1.60.0/atom

install-keyboard-maestro:
	./scripts/compile-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro
	./scripts/compile-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro

install-marked:
	./scripts/compile-lib.sh apps/3rd-party/Marked/2.6.18/marked

install-step-two:
	./scripts/compile-lib.sh apps/3rd-party/Step Two/3.1/step-two

install-sequel-ace:
	./scripts/compile-lib.sh apps/3rd-party/Sequel Ace/4.0.x/sequel-ace

install-sublime-text:
	./scripts/compile-lib.sh apps/3rd-party/Sublime Text/4.x/sublime-text

install-text-mate:
	./scripts/compile-lib.sh apps/3rd-party/TextMate/2.0.x/text-mate

install-viscosity:
	./scripts/compile-lib.sh apps/3rd-party/Viscosity/1.10.x/viscosity

compile-zoom:
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/dec-user-zoom
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom-window
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom-actions
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom-participants
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/dec-calendar-event-zoom

install-zoom: compile-zoom
	mkdir -p ~/applescript-core/zoom.us/
	cp -n plist.template ~/applescript-core/zoom.us/config.plist || true
	osascript ./apps/3rd-party/zoom.us/setup-configurations.applescript
	plutil -replace 'UserInstance' -string 'dec-user-zoom' ~/applescript-core/config-lib-factory.plist
	plutil -replace 'CalendarEventLibrary' -string 'dec-calendar-event-zoom' ~/applescript-core/config-lib-factory.plist

# Other libraries
install-user:
	./scripts/compile-lib.sh libs/user/user


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
	./scripts/compile-lib.sh libs/json/json


compile-redis:
	./scripts/compile-lib.sh libs/redis/redis

install-redis: compile-redis
	osascript ./scripts/setup-redis-cli.applescript
# 	osacompile -o ~/Library/Script\ Libraries/redis.scpt redis.applescript


