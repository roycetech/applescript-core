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


define build_finder
	yes y | ./scripts/build-lib.sh $(1)
endef

build-finder:
# ifeq ($(shell [ $(OS_VERSION_MAJOR) -eq 12 ] && echo yes),yes)
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/12.5/finder

# else ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt 12 ] && echo yes),yes)
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder-mini
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-selection
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder-tab
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-folders
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-files
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-paths
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-view
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/15.2/finder
# endif

# ifeq ($(shell [ $(OS_VERSION_MAJOR) -ge 26 ] && echo yes),yes)
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/26.0/dec-finder-view
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/26.1/dec-finder-dialog
# 	yes y | ./scripts/build-lib.sh apps/1st-party/Finder/26.1/finder
# endif
# 	@echo "Build Finder completed"

# Overwrites older version if a newer version is present.
ifeq ($(IS_12),1)
	$(call build_finder,apps/1st-party/Finder/12.5/finder)
endif

ifeq ($(GT_12),1)
	$(call build_finder,apps/1st-party/Finder/15.2/finder-mini)
	$(call build_finder,apps/1st-party/Finder/15.2/dec-finder-selection)
	$(call build_finder,apps/1st-party/Finder/15.2/finder-tab)
	$(call build_finder,apps/1st-party/Finder/15.2/dec-finder-folders)
	$(call build_finder,apps/1st-party/Finder/15.2/dec-finder-files)
	$(call build_finder,apps/1st-party/Finder/15.2/dec-finder-paths)
	$(call build_finder,apps/1st-party/Finder/15.2/dec-finder-view)
	$(call build_finder,apps/1st-party/Finder/15.2/finder)
endif

ifeq ($(GE_26),1)
	$(call build_finder,apps/1st-party/Finder/26.0/dec-finder-view)
	$(call build_finder,apps/1st-party/Finder/26.1/dec-finder-dialog)
	$(call build_finder,apps/1st-party/Finder/26.1/finder)
endif
	@echo "Build Finder completed"


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
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-sidebar
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
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/26.1/safari
# ifeq ($(shell [ $(OS_VERSION) -eq 26.2 ] && echo yes),yes)
ifeq ($(OS_VERSION),26.2)
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/26.2/dec-safari-tab-group
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/26.2/dec-safari-sidebar
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/26.2/dec-safari-tabs
	yes y | ./scripts/build-lib.sh apps/1st-party/Safari/26.2/safari
endif
	osascript apps/1st-party/Safari/26.1/allow-javascript-from-apple-events.applescript
	@echo "Build Safari completed"

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
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-dialog"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-tabs"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-window"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-content"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-cursor"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-settings"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-settings-general"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/dec-script-editor-settings-editing"
	./scripts/build-lib.sh "apps/1st-party/Script Editor/2.11/script-editor"
	@echo "Build Script Editor completed"


build-system-settings:
	./scripts/factory-insert.sh SystemSettingsInstance core/dec-system-settings-sonoma
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/macOS Sonoma/dec-system-settings-sonoma"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control_voice-commands"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_passwords"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_displays"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_sound"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_desktop-and-dock"
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"
# ifeq ($(OS_NAME), sequoia)
ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt 15 ] && echo yes),yes)
	yes y | ./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/macOS Sequoia/dec-system-settings_apple-intelligence-and-siri'
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/system-settings"
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -ge 26 ] && echo yes),yes)
	yes y | ./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/macOS Tahoe/system-settings"
endif

	@echo "Build System Settings completed"


build-terminal:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt 12 ] && echo yes),yes)
$(error macOS version too old! Requires at least macOS Monterey (v12).)
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
# ifeq ($(OS_NAME), sequoia)
else  # Sequoia or higher
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
endif
	$(SUDO) ./scripts/build-lib.sh libs/sftp/dec-terminal-prompt-sftp
	@echo "Build Terminal completed"

build-xcode:
	$(SUDO) ./scripts/build-lib.sh apps/3rd-party/Xcode/15.4/xcode
