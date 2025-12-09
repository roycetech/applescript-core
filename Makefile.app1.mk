# Makefile.app1.mk
# @Created: Fri, Jul 19, 2024 at 1:14:29 PM


build-all: \
	build \
	build-extras \
	build-apps-first-party


build-apps-first-party: \
	build-automator \
	build-calendar \
	build-console \
# 	build-control-center \  # Moved to core.
	build-dock \
	build-finder \
	build-notification-center \
	build-passwords \
	build-preview \
	install-safari \
	build-system-settings \
	build-terminal


# 1st Party Apps Library

build-automator:
ifeq ($(OS_NAME), tahoe)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Automator/2.10-Tahoe/automator
else
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Automator/2.10/automator
endif
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Automator/2.10/dec-automator-applescript

install-automator: build-automator
	mkdir -p /Applications/AppleScript
	# cp -n plist.template ~/applescript-core/config-system.plist || true
	osascript scripts/setup-apps-applescript-path.applescript

uninstall-automator:
	@echo "TODO"
	# TODO:


build-calendar:
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/Calendar/11.0/dec-calendar-view"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/Calendar/15.0/calendar-event"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/Calendar/15.0/dec-calendar-meetings"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/Calendar/15.0/calendar"

install-calendar: build-calendar
	osascript ./scripts/enter-user-country.applescript


build-console:
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/Console/v1.1/console"

# build-control-center:
# 	# TODO:
# 	$(SUDO) ./scripts/build-lib.sh macOS-version/16-tahoe/control-center_sound

build-finder:
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder-mini
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-selection
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder-tab
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-folders
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-files
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-paths
ifeq ($(OS_NAME), tahoe)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/26.0/dec-finder-view
else
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-view
endif
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder


build-home:
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Home/7.0/home


build-mail:
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Mail/16.0/mail

build-passwords:
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Passwords/2.0/passwords

build-preview:
	$(SUDO) ./scripts/build-lib.sh core/decorators/dec-preview-markup
ifeq ($(OS_NAME), tahoe)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Preview/v11-Tahoe/preview
else
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Preview/v11/preview
endif


build-safari: build-dock build-process
	yes y | ./scripts/build-lib.sh core/Level_5/javascript
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/16.0/safari-javascript
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/safari-tab
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/17.5/dec-safari-tab-finder
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/26.0/dec-safari-tab-finder2
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-ui-noncompact
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-ui-compact
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-side-bar
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.6/dec-safari-tab-group
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/17.4.1/dec-safari-keychain
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-inspector
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/17.5/dec-safari-preferences
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-general
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-tabs
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-extensions
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/dec-safari-settings-advanced
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-profile
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-privacy-and-security
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/18.5/safari

install-safari: build-safari
	osascript ./scripts/allow-apple-events-in-safari.applescript
	plutil -replace 'FIND_RETRY_MAX' -integer 90 ~/applescript-core/config-system.plist
	plutil -replace 'FIND_RETRY_SLEEP' -integer 1 ~/applescript-core/config-system.plist


build-safari-technology-preview:  # Broken
	./scripts/build-lib.sh  apps/1st-party/Safari Technology Preview/r168/dec-safari-technology-preview-javascript
	./scripts/build-lib.sh  apps/1st-party/Safari Technology Preview/r168/safari-technology-preview

install-safari-technology-preview: build-safari-technology-preview
	osascript ./scripts/allow-apple-events-in-safari-technology-preview.applescript


build-script-editor:
	$(SUDO) ./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/script-editor-tab'
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-dialog"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-tabs"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-window"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-content"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-cursor"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-settings"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-settings-general"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/dec-script-editor-settings-editing"
	make build-lib SOURCE="apps/1st-party/Script Editor/2.11/script-editor"


build-system-settings:
	./scripts/factory-insert.sh SystemSettingsInstance core/dec-system-settings-sonoma
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/macOS Sonoma/dec-system-settings-sonoma"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control_voice-commands"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_passwords"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_displays"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_sound"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_desktop-and-dock"
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"

ifeq ($(OS_NAME), sequoia)
	$(SUDO) ./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/macOS Sequoia/dec-system-settings-siri'
	$(SUDO) ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"
endif


build-terminal:
ifeq ($(OS_NAME), sequoia)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-output
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-path
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-prompt
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-run
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal-tab
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-general
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile-window
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile-keyboard
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal_tab-finder
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal

else ifeq ($(OS_NAME), sonoma)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-output
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-path
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-prompt
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-run
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal-tab
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal

else ifeq ($(OS_NAME), ventura)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-output
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-path
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-prompt
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/dec-terminal-run
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.13.x/terminal

else ifeq ($(OS_NAME), monterey)
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-output
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-path
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-prompt
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/dec-terminal-run
	$(SUDO) ./scripts/build-lib.sh apps/1st-party/Terminal/2.12.x/terminal
endif
	$(SUDO) ./scripts/build-lib.sh libs/sftp/dec-terminal-prompt-sftp


build-xcode:
	$(SUDO) ./scripts/build-lib.sh apps/3rd-party/Xcode/15.4/xcode
