OS := $(shell osascript -e "system version of (system info)" | cut -d '.' -f 1 | awk '{if ($$1 ~ /^13/) print "ventura"; else if ($$1 ~ /^12/) print "monterey"; else print "unknown"}')

help:
	@echo "make install - Create config files, assets, and install essential
	libraries."

	@echo "make install-core - install the core AppleScript libraries in the current user's Library/Script Library folder"
	@echo "make install-automator - install additional config for spot testing"
	@echo "make compile-library - compiles a script library.  e.g. make compile-lib SOURCE=core/config"
	@echo "make reveal-config - reveals the default AppleScript Core configurations folder in Finder"
	@echo "make reveal-lib - reveals the default AppleScript user libraries deployment folder in Finder"
	@echo "make reveal-apps - reveals the default AppleScript apps deployment folder in Finder"
	@echo "-s option hides the Make invocation command."

# 	The stub prefix is intentional to avoid the warning for Makefile that wants
# 	to avoid having a similar target.
STUB_LIBS :=  \
	stubs/config \
	stubs/list \
	stubs/logger \
	stubs/logger-factory \
	stubs/plist-buddy \
	stubs/string \
	stubs/string-builder \
	stubs/notification-center-helper \
	stubs/spot-test \
	stubs/terminal \
	stubs/user

# 	config

# Needs to be ordered because the use script will compile dependent scripts.
# Transitive scripts need to be compiled first before it can be referenced by
# another library.
CORE_LIBS :=  \
	logger-factory \
	overrider \
	unit-test \
	list \
	string \
	regex \
	map \
	plutil \
	config \
	emoji \
	switch \
	clipboard \
	date-time \
	speech \
	dialog \
	file \
	idler \
	keyboard \
	lov \
	plist-buddy \
	process \
	retry \
	string-builder \
	stack \
	system-events \
	ui-util \
	unicodes \
	window \
	logger \
	spot-test \

APPS_PATH=/Applications/AppleScript

_init:
	mkdir -p ~/Library/Script\ Libraries
	mkdir -p ~/applescript-core/sounds/
	mkdir -p ~/applescript-core/logs/
	mkdir -p ~/Applications/AppleScript/Stay\ Open/
	cp -n config-default.template ~/applescript-core/config-default.plist || true
	cp -n config-emoji.template ~/applescript-core/config-emoji.plist || true
	cp -n plist.template ~/applescript-core/config-lib-factory.plist || true
	cp -n plist.template ~/applescript-core/lov.plist || true
	cp -n plist.template ~/applescript-core/config-system.plist || true
	cp -n plist.template ~/applescript-core/session.plist || true
	cp -n plist.template ~/applescript-core/switches.plist || true
	cp -n plist.template ~/applescript-core/config-user.plist || true
	cp -n plist.template ~/applescript-core/config-business.plist || true
	cp -n notification-app-id-name.plist ~/applescript-core/notification-app-id-name.plist || true
	cp -a assets/sounds/. ~/applescript-core/sounds/
	./scripts/compile-bundle.sh 'core/Core Text Utilities'
	plutil -replace 'Project applescript-core' -string "`pwd`" ~/applescript-core/config-system.plist

install: _init compile
	touch ~/applescript-core/logs/applescript-core.log
	osascript scripts/setup-applescript-core-project-path.applescript
	./scripts/setup-switches.sh
	@echo "Installation done"

$(STUB_LIBS): Makefile
	osacompile -o "$(HOME)/Library/Script Libraries/$(patsubst stubs/%,%,$@).scpt" "scripts/stub.applescript"

$(CORE_LIBS): Makefile
	./scripts/compile-lib.sh core/$@

uninstall:
	# TODO


compile-standard:
ifeq ($(OS), ventura)
	./scripts/compile-lib.sh macOS-version/13-ventura/std

else ifeq ($(OS), monterey)
	./scripts/compile-lib.sh macOS-version/12-monterey/std

else
	./scripts/compile-lib.sh macOS-version/12-monterey/std
	@echo "compile-core unimplemented macOS version error"
endif

compile-core-bundle:
	@echo "Core Bundle compiled."
	./scripts/compile-bundle.sh 'core/Core Text Utilities'



# There are circular dependency issue that needs to be considered. You may need
# to re-order the build of the script depending on which script is needed first.
build: compile

compile: compile-stub compile-standard compile-core-bundle compile-core compile-control-center compile-user

compile-stub: $(STUB_LIBS)
	@echo "Stubs compiled. This target is meant to help compile other scripts. \
Make sure this is not the last target you run, otherwise the scripts that \
need the real library will fail."

compile-core: $(CORE_LIBS)
	@echo "Core libraries compiled."


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

test-all:
	osascript "test/Test Loader.applescript"

test-integration:

test:
# 	osascript test/core/Test regex.applescript
# 	osascript test/apps/1st-party/dec-script-editor-contentTest.applescript
# 	osascript test/core/fileTest.applescript
	osascript "test/core/Test plutil.applescript"
# 	osascript "test/core/Test plistBuddy.applescript"
# 	osascript test/apps/1st-party/script-editorTest.applescript
.PHONY: test

watch: test
	scripts/run-tests_on-change.sh

#
#

# Extra Libraries ================================
# Suggestion: Install related core libraries so that related updates don't
# require a separate make install.

# 1st Party Apps Library
compile-calendar: compile-counter
	./scripts/compile-lib.sh "apps/1st-party/Calendar/11.0/dec-calendar-view"
	./scripts/compile-lib.sh "apps/1st-party/Calendar/11.0/calendar-event"
	./scripts/compile-lib.sh "apps/1st-party/Calendar/11.0/calendar"

install-calendar: compile-calendar
	osascript ./scripts/enter-user-country.applescript

install-system-preferences:
	./scripts/compile-lib.sh "apps/1st-party/System Preferences/15.0/system-preferences"

install-system-settings:
	./scripts/compile-lib.sh "apps/1st-party/System Settings/15.0/system-settings"


compile-chrome:
	./scripts/compile-lib.sh  apps/1st-party/Chrome/110.0/chrome.applescript

install-chrome:
	osascript scripts/allow-apple-events-in-chrome.applescript


compile-safari: compile-dock
	osacompile -o "$(HOME)/Library/Script Libraries/safari.scpt" "scripts/stub.applescript"
	./scripts/compile-lib.sh apps/1st-party/Safari/16.0/safari-javascript
	./scripts/compile-lib.sh apps/1st-party/Safari/16.0/safari

install-safari: compile-safari
	osascript ./scripts/allow-apple-events-in-safari.applescript
	plutil -replace 'FIND_RETRY_MAX' -integer 90 ~/applescript-core/config-system.plist
	plutil -replace 'FIND_RETRY_SLEEP' -integer 1 ~/applescript-core/config-system.plist

compile-safari-technology-preview:
	osacompile -o "$(HOME)/Library/Script Libraries/safari-technology-preview.scpt" "scripts/stub.applescript"
	./scripts/compile-lib.sh  apps/1st-party/Safari Technology Preview/r168/dec-safari-technology-preview-javascript
	./scripts/compile-lib.sh  apps/1st-party/Safari Technology Preview/r168/safari-technology-preview

install-safari-technology-preview: compile-safari-technology-preview
	osascript ./scripts/allow-apple-events-in-safari-technology-preview.applescript


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
	osacompile -o "$(HOME)/Library/Script Libraries/terminal.scpt" "scripts/stub.applescript"
ifeq ($(OS), ventura)
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-output
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-path
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-prompt
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-run
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.13.x/terminal

else ifeq ($(OS), monterey)
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-output
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-path
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-prompt
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-run
	./scripts/compile-lib.sh apps/1st-party/Terminal/2.12.x/terminal

else
	@echo "Hello Something Else"
endif

	./scripts/compile-lib.sh libs/sftp/dec-terminal-prompt-sftp

install-terminal: compile-terminal

install-terminal-sftp: ## Add support to basic SFTP prompt
	echo TODO

install-terminal-ec2-ssh: ## Add support to basic ec2 SSH
	echo TODO

# macOS Version-Specific Apps
install-macos-monterey: install-control-center install-dock install-notification-center
	#TODO

compile-control-center:
ifeq ($(OS), ventura)
	./scripts/compile-lib.sh "macOS-version/13-ventura/control-center"
	./scripts/compile-lib.sh "macOS-version/13-ventura/control-center_focus"
	./scripts/compile-lib.sh "macOS-version/13-ventura/control-center_sound"
	./scripts/compile-lib.sh "macOS-version/13-ventura/control-center_network"

else ifeq ($(OS), monterey)
	./scripts/compile-lib.sh "macOS-version/12-monterey/control-center"

else
	./scripts/compile-lib.sh "macOS-version/12-monterey/control-center"
	@echo "Unsupported macOS version for control-center"
endif

install-control-center: compile-control-center


compile-dock:
	./scripts/compile-lib.sh "macOS-version/12-monterey/dock"

install-dock: compile-dock

install-notification-center:
	osacompile -o "$(HOME)/Library/Script Libraries/notification-center.scpt" "scripts/stub.applescript"

ifeq ($(OS), ventura)
	./scripts/compile-lib.sh "macOS-version/13-ventura/notification-center-helper"
	./scripts/compile-lib.sh "macOS-version/13-ventura/notification-center"

else ifeq ($(OS), monterey)
	./scripts/compile-lib.sh "macOS-version/12-monterey/notification-center-helper"
	./scripts/compile-lib.sh "macOS-version/12-monterey/notification-center"

else
	./scripts/compile-lib.sh "macOS-version/12-monterey/notification-center-helper"
	./scripts/compile-lib.sh "macOS-version/12-monterey/notification-center"
	@echo "Unsupported macOS version for notification-center"
endif

# 3rd Party Apps Library
compile-one-password: compile-cliclick
	./scripts/compile-lib.sh apps/3rd-party/1Password/v6/one-password

install-1password: compile-one-password install-cliclick

install-atom:  ## Deprecated
	./scripts/compile-lib.sh apps/3rd-party/Atom/1.60.0/atom


compile-pulsar:
	./scripts/compile-lib.sh apps/3rd-party/Pulsar/1.102.x/pulsar

install-pulsar: compile-pulsar


install-keyboard-maestro:
	./scripts/compile-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro
	./scripts/compile-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro

install-last-pass:
	./scripts/compile-lib.sh apps/3rd-party/LastPass/4.4.x/last-pass


compile-marked:
	./scripts/compile-lib.sh apps/3rd-party/Marked/2.6.18/marked

install-marked: compile-marked


compile-mosaic:
	./scripts/compile-lib.sh apps/3rd-party/Mosaic/v1.3.x/mosaic


compile-script-debugger:
	./scripts/compile-lib.sh 'apps/3rd-party/Script Debugger/v8.0.x/script-debugger'

install-script-debugger: compile-script-debugger


install-step-two:
	./scripts/compile-lib.sh apps/3rd-party/Step Two/3.1/step-two


compile-sequel-ace:
	./scripts/compile-lib.sh apps/3rd-party/Sequel Ace/4.0.x/sequel-ace

install-sequel-ace: compile-sequel-ace


compile-stream-deck:
	./scripts/compile-lib.sh apps/3rd-party/Stream Deck/6.x/stream-deck
	./scripts/compile-lib.sh apps/3rd-party/Stream Deck/6.x/dec-spot-stream-deck

install-stream-deck: compile-stream-deck
	plutil \
		-replace 'SpotTestInstance' \
		-string 'dec-spot-stream-deck' \
		~/applescript-core/config-lib-factory.plist


compile-sublime-text:
	./scripts/compile-lib.sh apps/3rd-party/Sublime Text/4.x/sublime-text
	./scripts/compile-lib.sh apps/3rd-party/Sublime Text/4.x/dec-syseve-with-sublime-text

install-sublime-text: compile-sublime-text
	osascript ./scripts/setup-sublime-text-cli.applescript
	plutil \
		-replace 'SysEveInstance' \
		-string 'dec-syseve-with-sublime-text' \
		~/applescript-core/config-lib-factory.plist

install-text-mate:
	./scripts/compile-lib.sh apps/3rd-party/TextMate/2.0.x/text-mate

install-viscosity:
	./scripts/compile-lib.sh apps/3rd-party/Viscosity/1.10.x/viscosity

compile-zoom:
	osacompile -o "$(HOME)/Library/Script Libraries/zoom.scpt" "scripts/stub.applescript"
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/dec-user-zoom
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom-window
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom-actions
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom-participants
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/dec-calendar-event-zoom
	./scripts/compile-lib.sh apps/3rd-party/zoom.us/5.x/zoom

install-zoom: compile-zoom
	mkdir -p ~/applescript-core/zoom.us/
	cp -n plist.template ~/applescript-core/zoom.us/config.plist || true
	osascript ./apps/3rd-party/zoom.us/setup-configurations.applescript
	plutil -replace 'UserInstance' -string 'dec-user-zoom' ~/applescript-core/config-lib-factory.plist
	plutil -replace 'CalendarEventLibrary' -string 'dec-calendar-event-zoom' ~/applescript-core/config-lib-factory.plist

# Other libraries
compile-counter:
	./scripts/compile-lib.sh libs/counter-plist/counter

install-counter: compile-counter

compile-user:
	./scripts/compile-lib.sh libs/user/user


# Library Decorators
install-dvorak:
	./scripts/compile-lib.sh core/decorators/dec-keyboard-dvorak-cmd
	./scripts/compile-lib.sh core/keyboard
	plutil -replace 'KeyboardInstance' -string 'dec-keyboard-dvorak-cmd' ~/applescript-core/config-lib-factory.plist

compile-cliclick:
	./scripts/compile-lib.sh libs/cliclick/cliclick

install-cliclick: compile-cliclick
	osascript libs/cliclick/setup-cliclick-cli.applescript

install-jira:
	./scripts/compile-lib.sh libs/jira/jira


# Optional with 3rd party app dependency.
compile-json:
	./scripts/compile-lib.sh libs/json/json

install-json: compile-json


compile-logger:
	./scripts/compile-lib.sh core/logger


compile-log4as:
	./scripts/compile-lib.sh libs/log4as/log4as
	./scripts/compile-lib.sh core/decorators/dec-logger-log4as

install-log4as: compile-log4as
# 	plutil -replace 'LoggerSpeechAndTrackingInstance' -string 'dec-logger-log4as' ~/applescript-core/config-lib-factory.plist
	plutil -replace 'LoggerInstance' -string 'dec-logger-log4as' ~/applescript-core/config-lib-factory.plist
	cp -n libs/log4as/log4as.plist.template ~/applescript-core/log4as.plist || true
	plutil -replace 'defaultLevel' -string 'DEBUG' ~/applescript-core/log4as.plist
	plutil -replace 'printToConsole' -bool true ~/applescript-core/log4as.plist
	plutil -replace 'writeToFile' -bool true ~/applescript-core/log4as.plist
	plutil -insert categories -xml "<dict></dict>" ~/applescript-core/log4as.plist || true

compile-redis:
	./scripts/compile-lib.sh libs/redis/redis
	./scripts/compile-lib.sh libs/redis/dec-terminal-prompt-redis

install-redis: compile-redis
	osascript ./scripts/setup-redis-cli.applescript

install-timed-cache:
	cp -n plist.template ~/applescript-core/timed-cache.plist || true
	./scripts/compile-lib.sh libs/timed-cache-plist/timed-cache-plist

# 	osacompile -o ~/Library/Script\ Libraries/redis.scpt redis.applescript


