# Use "build" instead of "compile" to make it uniform.

OS := $(shell osascript -e "system version of (system info)" \
| cut -d '.' -f 1 \
| awk '{if ($$1 ~ /^14/) print "sonoma"; else if ($$1 ~ /^13/) print "ventura"; else if ($$1 ~ /^12/) print "monterey"; else print "unknown"}')

help:
	@echo "make install - Create config files, assets, and install essential
	libraries."

	@echo "make install-core - install the core AppleScript libraries in the current user's Library/Script Library folder"
	@echo "make install-automator - install additional config for spot testing"
	@echo "make build-library - compiles a script library.  e.g. make build-lib SOURCE=core/config"
	@echo "make reveal-config - reveals the default AppleScript Core configurations folder in Finder"
	@echo "make reveal-lib - reveals the default AppleScript user libraries deployment folder in Finder"
	@echo "make reveal-apps - reveals the default AppleScript apps deployment folder in Finder"
	@echo "-s option hides the Make invocation command."

# 	The stub prefix is intentional to avoid the warning for Makefile, which
# 	wants to avoid having a similar target.
STUB_LIBS :=  \
	stubs/config \
	stubs/list \
	stubs/logger \
	stubs/logger-factory \
	stubs/plist-buddy \
	stubs/string \
	stubs/string-builder \
	stubs/spot-test \
	stubs/user

# 	config

# Needs to be ordered because the use script will compile dependent scripts.
# Transitive scripts need to be compiled first before it can be referenced by
# another library.
CORE_LIBS :=  \
	logger-factory \
	decorator \
	simple-test \
	unit-test \
	list \
	string \
	regex-pattern \
	map \
	date-time \
	plutil \
	config \
	emoji \
	switch \
	clipboard \
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
	spot-test

APPS_PATH=/Applications/AppleScript

_init:
	mkdir -p ~/Library/Script\ Libraries/core
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
# 	./scripts/build-bundle.sh 'core/Text Utilities'
	plutil -replace 'Project applescript-core' -string "`pwd`" ~/applescript-core/config-system.plist

clean:
	find . -name '*.scpt' ! -name "main.scpt" -delete

install: _init compile
	mkdir -p ~/Library/'Script Libraries'/core/test
	touch ~/applescript-core/logs/applescript-core.log
	osascript scripts/setup-applescript-core-project-path.applescript
	./scripts/setup-switches.sh
	@echo "Installation done"

$(STUB_LIBS): Makefile
	osacompile -o "$(HOME)/Library/Script Libraries/core/$(patsubst stubs/%,%,$@).scpt" "scripts/stub.applescript"

$(CORE_LIBS): Makefile
	./scripts/build-lib.sh core/$@

uninstall:
	# TODO


build-standard:
ifeq ($(OS), ventura)
	./scripts/build-lib.sh macOS-version/13-ventura/std

else ifeq ($(OS), monterey)
	./scripts/build-lib.sh macOS-version/12-monterey/std

else
	./scripts/build-lib.sh macOS-version/12-monterey/std
	@echo "build-core unimplemented macOS version error"
endif

build-core-bundle:
	@echo "Core Bundle compiled."
	./scripts/build-bundle.sh 'core/Text Utilities'


# There are circular dependency issue that needs to be considered. You may need
# to re-order the build of the script depending on which script is needed first.
build: compile

compile: \
	build-stub \
	build-standard \
	build-core-bundle \
	build-core \
	build-control-center \
	build-user

build-extras: \
	build-counter \
	build-redis \
	build-terminal

build-extras: install-timed-cache
	./scripts/build-lib.sh "libs/zsh/oh-my-zsh"


build-all: \
	compile \
	build-extras \
	build-macos-apps

install-all: build-all

build-stub: $(STUB_LIBS)
	@echo "Stubs compiled. This target is meant to help compile other scripts. \
Make sure this is not the last target you run, otherwise the scripts that \
need the real library will fail."

build-core: $(CORE_LIBS)
	@echo "Core libraries compiled."


build-lib:
	./scripts/build-lib.sh $(SOURCE)

build-bundle:
	./scripts/build-bundle.sh $(SOURCE)

# Fails to work with accessibility permission error. Export via Script Editor
# fails as well. Use Automator-created apps instead, see "Create Automator App.applescript"
build-app:
	./scripts/build-app.sh $(SOURCE)

# Fails to work when we try to hide the icon in the dock.
build-stay-open:
	./scripts/build-stay-open.sh $(SOURCE)


reveal-config:
	open ~/applescript-core

reveal-deployed-scripts:
	open ~/Library/Script\ Libraries

reveal-apps:
	open $(APPS_PATH)

reveal-stay-open:
	open $(APPS_PATH)/Stay\ Open


test-all:
	osascript "test/Test Loader.applescript"

test-integration:

test: test-all
.PHONY: test

test-unit:
# 	osascript "test/libs/Test cliclick.applescript"
# 	osascript "test/libs/Test jira.applescript"
# 	osascript "test/libs/Test log4as.applescript"
# 	osascript "test/core/Test redis.applescript"
# 	osascript "test/core/Test date-time.applescript"
# 	osascript "test/core/Test decorator.applescript"
	osascript "test/core/Test file.applescript"
# 	osascript "test/core/Test list.applescript"
# 	osascript "test/core/Test lov.applescript"
# 	osascript "test/core/Test map.applescript"
# 	osascript "test/core/Test plist-buddy.applescript"
# 	osascript "test/core/Test plutil.applescript"
# 	osascript "test/core/Test property-list.applescript"
# 	osascript "test/core/Test regex.applescript"
# 	osascript "test/core/Test regex-pattern.applescript"
# 	osascript "test/core/Test safari-javascript.applescript"
# 	osascript "test/core/Test stack.applescript"
# 	osascript "test/core/Test switch.applescript"
# 	osascript "test/core/Test speech.applescript"
# 	osascript "test/core/Test string.applescript"
# 	osascript "test/core/Test timed-cache-plist.applescript"
# 	osascript test/apps/1st-party/script-editorTest.applescript
# 	osascript test/apps/1st-party/dec-script-editor-contentTest.applescript
# 	osascript "test/apps/3rd-party/Test keyboard-maestro.applescript"


watch: test
	scripts/run-tests_on-change.sh


build-macos-apps: \
	build-automator \
	build-calendar \
	build-console \
	install-control-center \
	build-dock \
	build-finder \
	build-notification-center \
	build-preview \
	install-safari \
	build-system-preferences \
	build-terminal


# Extra Libraries ================================
# Suggestion: Install related core libraries so that related updates don't
# require a separate make install.

# 1st Party Apps Library
# build-calendar: build-counter
build-calendar:
	./scripts/build-lib.sh "apps/1st-party/Calendar/11.0/dec-calendar-view"
	./scripts/build-lib.sh "apps/1st-party/Calendar/11.0/calendar-event"
	./scripts/build-lib.sh "apps/1st-party/Calendar/11.0/calendar"

install-calendar: build-calendar
	osascript ./scripts/enter-user-country.applescript

build-console:
ifeq ($(OS), ventura)
	./scripts/build-lib.sh "apps/1st-party/Console/v1.1/console"
else
	@echo "Unsupported"
endif

build-system-preferences:
ifeq ($(OS), sonoma)
	@echo "Sonoma"
	./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"
	./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_passwords"
	./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/macOS Sonoma/dec-system-settings-sonoma"
	./scripts/factory-insert.sh SystemSettingsInstance core/dec-system-settings-sonoma

else ifeq ($(OS), ventura)
	@echo "Ventura"
	./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"
	./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_passwords"

else ifeq ($(OS), monterey)
	./scripts/build-lib.sh "apps/1st-party/System Preferences/15.0/system-preferences"

else
	@echo "Unsupported"
endif


build-system-settings:
	./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"

build-mail:
	./scripts/build-lib.sh apps/1st-party/Mail/16.0/mail


build-preview:
	./scripts/build-lib.sh apps/1st-party/Preview/v11/preview


build-safari: build-dock
	osacompile -o "$(HOME)/Library/Script Libraries/core/safari.scpt" "scripts/stub.applescript"
	./scripts/build-lib.sh apps/1st-party/Safari/16.0/safari-javascript
	./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/safari-tab
	./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-tab-finder
	./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-ui-noncompact
	./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-ui-compact
	./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-side-bar
	./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-tab-group
	./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-keychain
	./scripts/build-lib.sh apps/1st-party/Safari/16.0/safari


#3rd-party cliclick is required because some Safari actions no longer work without simulated user interactions.
install-safari: install-cliclick build-safari
	osascript ./scripts/allow-apple-events-in-safari.applescript
	plutil -replace 'FIND_RETRY_MAX' -integer 90 ~/applescript-core/config-system.plist
	plutil -replace 'FIND_RETRY_SLEEP' -integer 1 ~/applescript-core/config-system.plist

build-safari-technology-preview:
	osacompile -o "$(HOME)/Library/Script Libraries/core/safari-technology-preview.scpt" "scripts/stub.applescript"
	./scripts/build-lib.sh  apps/1st-party/Safari Technology Preview/r168/dec-safari-technology-preview-javascript
	./scripts/build-lib.sh  apps/1st-party/Safari Technology Preview/r168/safari-technology-preview

install-safari-technology-preview: build-safari-technology-preview
	osascript ./scripts/allow-apple-events-in-safari-technology-preview.applescript


build-script-editor:
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/script-editor"

build-finder:
	./scripts/build-lib.sh apps/1st-party/Finder/12.5/finder

build-automator:
	./scripts/build-lib.sh apps/1st-party/Automator/2.10/automator

install-automator: build-automator
	mkdir -p /Applications/AppleScript
	# cp -n plist.template ~/applescript-core/config-system.plist || true
	osascript scripts/setup-applescript-apps-path.applescript

uninstall-automator:
	@echo "TODO"
	# TODO:


build-home:
	./scripts/build-lib.sh apps/1st-party/Home/7.0/home


build-terminal:
	osacompile -o "$(HOME)/Library/Script Libraries/core/terminal.scpt" "scripts/stub.applescript"

ifeq ($(OS), sonoma)
	./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-output
	./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-path
	./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-prompt
	./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-run
	./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal-tab
	./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal

else ifeq ($(OS), ventura)
	./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-output
	./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-path
	./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-prompt
	./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-run
	./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/terminal

else ifeq ($(OS), monterey)
	./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-output
	./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-path
	./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-prompt
	./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-run
	./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/terminal


else
	@echo "Hello Something Else"
endif

	./scripts/build-lib.sh libs/sftp/dec-terminal-prompt-sftp


# macOS Version-Specific Apps -------------------------------------------------


build-control-center:
ifeq ($(OS), ventura)
	osacompile -o "$(HOME)/Library/Script Libraries/core/control-center.scpt" "scripts/stub.applescript"
	./scripts/build-lib.sh "macOS-version/13-ventura/control-center_network"
	./scripts/build-lib.sh "macOS-version/13-ventura/control-center_sound"
	./scripts/build-lib.sh "macOS-version/13-ventura/control-center_focus"
	./scripts/build-lib.sh "macOS-version/13-ventura/control-center"

else ifeq ($(OS), monterey)
	./scripts/build-lib.sh "macOS-version/12-monterey/control-center"

else
	./scripts/build-lib.sh "macOS-version/12-monterey/control-center"
	@echo "Unsupported macOS version for control-center"
endif

install-control-center: build-control-center


build-dock:
	./scripts/build-lib.sh "macOS-version/12-monterey/dock"


build-notification-center:
	osacompile -o "$(HOME)/Library/Script Libraries/core/notification-center.scpt" "scripts/stub.applescript"

ifeq ($(OS), ventura)
	./scripts/build-lib.sh "macOS-version/13-ventura/notification-center-helper"
	./scripts/build-lib.sh "macOS-version/13-ventura/notification-center"

else ifeq ($(OS), monterey)
	./scripts/build-lib.sh "macOS-version/12-monterey/notification-center-helper"
	./scripts/build-lib.sh "macOS-version/12-monterey/notification-center"

else
	./scripts/build-lib.sh "macOS-version/12-monterey/notification-center-helper"
	./scripts/build-lib.sh "macOS-version/12-monterey/notification-center"
	@echo "Unsupported macOS version for notification-center"
endif


# 3rd Party Apps Library ------------------------------------------------------
build-one-password: build-cliclick
	./scripts/build-lib.sh apps/3rd-party/1Password/v6/one-password

install-1password: build-one-password install-cliclick

install-atom:  ## Deprecated
	./scripts/build-lib.sh apps/3rd-party/Atom/1.60.0/atom

install-eclipse:
	./scripts/build-lib.sh apps/3rd-party/Eclipse/v202306/eclipse

install-git-kraken:
	./scripts/build-lib.sh apps/3rd-party/GitKraken/v9.8.2/git-kraken


build-chrome:
	osacompile -o "$(HOME)/Library/Script Libraries/core/chrome.scpt" "scripts/stub.applescript"
	./scripts/build-lib.sh apps/3rd-party/Google Chrome/110.0/chrome-javascript
	./scripts/build-lib.sh apps/3rd-party/Google Chrome/110.0/chrome-tab
	./scripts/build-lib.sh apps/3rd-party/Google Chrome/110.0/chrome

build-ms-edge:
	osacompile -o "$(HOME)/Library/Script Libraries/core/microsoft-edge.scpt" "scripts/stub.applescript"
	./scripts/build-lib.sh apps/3rd-party/Microsoft Edge/120.0/microsoft-edge-javascript
	./scripts/build-lib.sh apps/3rd-party/Microsoft Edge/120.0/microsoft-edge-tab
	./scripts/build-lib.sh apps/3rd-party/Microsoft Edge/120.0/microsoft-edge


build-intellij:
	./scripts/build-lib.sh apps/3rd-party/IntelliJ IDEA/v2023.2.1/intellij-idea

install-intellij: build-intellij
	osascript ./scripts/setup-intellij-cli.applescript

build-pulsar:
	./scripts/build-lib.sh apps/3rd-party/Pulsar/1.102.x/pulsar

install-pulsar: build-pulsar


build-keyboard-maestro: build-cliclick
	./scripts/build-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro
	./scripts/build-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro
	./scripts/build-lib.sh apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro-group

install-last-pass:
	./scripts/build-lib.sh apps/3rd-party/LastPass/4.4.x/last-pass


build-marked:
	./scripts/build-lib.sh apps/3rd-party/Marked/2.6.18/marked

install-marked: build-marked


build-mosaic:
	./scripts/build-lib.sh apps/3rd-party/Mosaic/v1.3.x/mosaic


build-script-debugger:
	./scripts/build-lib.sh 'apps/3rd-party/Script Debugger/v8.0.x/script-debugger'

install-script-debugger: build-script-debugger


install-step-two:
	./scripts/build-lib.sh apps/3rd-party/Step Two/3.1/step-two


build-sequel-ace:
	./scripts/build-lib.sh apps/3rd-party/Sequel Ace/4.0.x/sequel-ace

install-sequel-ace: build-sequel-ace


build-stream-deck:
	./scripts/build-lib.sh apps/3rd-party/Stream Deck/6.x/stream-deck
	./scripts/build-lib.sh apps/3rd-party/Stream Deck/6.x/dec-spot-stream-deck

install-stream-deck: build-stream-deck
	plutil \
		-replace 'SpotTestInstance' \
		-string 'core/dec-spot-stream-deck' \
		~/applescript-core/config-lib-factory.plist


install-sublime-text:
	osascript ./scripts/setup-sublime-text-cli.applescript
	plutil \
		-replace 'SystemEventsInstance' \
		-string 'core/dec-system-events-with-sublime-text' \
		~/applescript-core/config-lib-factory.plist
	./scripts/build-lib.sh apps/3rd-party/Sublime Text/4.x/sublime-text
	./scripts/build-lib.sh apps/3rd-party/Sublime Text/4.x/dec-system-events-with-sublime-text

install-text-mate:
	./scripts/build-lib.sh apps/3rd-party/TextMate/2.0.x/text-mate

install-viscosity:
	./scripts/build-lib.sh apps/3rd-party/Viscosity/1.10.x/viscosity

build-zoom:
	osacompile -o "$(HOME)/Library/Script Libraries/core/zoom.scpt" "scripts/stub.applescript"
	./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/dec-user-zoom
	./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/zoom-window
	./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/zoom-actions
	./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/zoom-participants
	./scripts/build-lib.sh apps/3rd-party/zoom.us/dec-calendar-event-zoom
	./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/zoom

install-zoom: build-zoom
	mkdir -p ~/applescript-core/zoom.us/
	cp -n plist.template ~/applescript-core/zoom.us/config.plist || true
	osascript ./apps/3rd-party/zoom.us/setup-configurations.applescript
	plutil -replace 'UserInstance' -string 'core/dec-user-zoom' ~/applescript-core/config-lib-factory.plist
	plutil -replace 'CalendarEventLibrary' -string 'core/dec-calendar-event-zoom' ~/applescript-core/config-lib-factory.plist

# Other libraries
build-counter:
	./scripts/build-lib.sh libs/counter-plist/counter

install-counter: build-counter

build-user:
	./scripts/build-lib.sh libs/user/user


# Library Decorators
install-dvorak:
	./scripts/build-lib.sh core/decorators/dec-keyboard-dvorak-cmd
	./scripts/build-lib.sh core/keyboard
	plutil -replace 'KeyboardInstance' -string 'dec-keyboard-dvorak-cmd' ~/applescript-core/config-lib-factory.plist

build-cliclick:
	./scripts/build-lib.sh libs/cliclick/cliclick

install-cliclick: build-cliclick
	osascript libs/cliclick/setup-cliclick-cli.applescript

install-jira:
	./scripts/build-lib.sh libs/jira/jira


# Optional with 3rd party app dependency.
build-json:
	./scripts/build-lib.sh libs/json/json

install-json: build-json


build-logger:
	./scripts/build-lib.sh core/logger


build-log4as:
	./scripts/build-lib.sh libs/log4as/log4as
	./scripts/build-lib.sh core/decorators/dec-logger-log4as

install-log4as: build-log4as
# 	plutil -replace 'LoggerSpeechAndTrackingInstance' -string 'dec-logger-log4as' ~/applescript-core/config-lib-factory.plist
	plutil -replace 'LoggerOverridableInstance' -string 'core/dec-logger-log4as' ~/applescript-core/config-lib-factory.plist
	cp -n libs/log4as/log4as.plist.template ~/applescript-core/log4as.plist || true
	plutil -replace 'defaultLevel' -string 'DEBUG' ~/applescript-core/log4as.plist
	plutil -replace 'printToConsole' -bool true ~/applescript-core/log4as.plist
	plutil -replace 'writeToFile' -bool true ~/applescript-core/log4as.plist
	plutil -insert categories -xml "<dict></dict>" ~/applescript-core/log4as.plist || true

build-redis:
	osascript ./scripts/setup-redis-cli.applescript
	./scripts/build-lib.sh libs/redis/redis

build-redis-terminal:
	./scripts/build-lib.sh libs/redis/dec-terminal-prompt-redis

install-redis: build-redis

install-timed-cache:
	cp -n plist.template ~/applescript-core/timed-cache.plist || true
	./scripts/build-lib.sh libs/timed-cache-plist/timed-cache-plist

# 	osacompile -o ~/Library/Script\ Libraries/redis.scpt redis.applescript

