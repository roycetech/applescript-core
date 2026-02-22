# Makefile.app1.mk
# @Created: Fri, Jul 19, 2024 at 1:14:29 PM
# Contains targets for 1st party apps.
#
# @NOTE:
#   Versions of scripts indicate the app and OS version when the script was created.
#   New functionalities were only added to the latest version of the script at the time.
#
# @Change Logs:
# - 2026-02-20: Added echo statements to the build targets to make the output more readable.


build-all: \
	build \
	build-extras \
	build-apps-first-party


build-apps-first-party: \
	build-automator \
	build-calendar \
	build-console \
	build-finder \
	build-passwords \
	build-preview \
	install-safari \
	build-system-settings \
	build-terminal


# 1st Party Apps Library ------------------------------------------------------

build-automator:
	@echo "\nBuilding Automator scripts..."
	$(call _build-script, apps/1st-party/Automator/2.10/dec-automator-applescript)
	$(call _build-script, apps/1st-party/Automator/2.10/automator)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SEQUOIA) ] && echo yes),yes)
	@echo "\nBuilding Automator 2.10-Tahoe scripts..."
	$(call _build-script, apps/1st-party/Automator/2.10-Tahoe/automator)
endif
	@echo "Build Automator completed\n"

install-automator: build-automator
	mkdir -p /Applications/AppleScript
	# cp -n plist.template ~/applescript-core/config-system.plist || true
	osascript scripts/setup-apps-applescript-path.applescript

uninstall-automator:
	@echo "TODO"



build-calendar:
	@echo "\nBuilding Calendar scripts..."
	$(call _build-script, apps/1st-party/Calendar/11.0/dec-calendar-view)
	$(call _build-script, apps/1st-party/Calendar/15.0/calendar-event)
	$(call _build-script, apps/1st-party/Calendar/15.0/dec-calendar-meetings)
	$(call _build-script, apps/1st-party/Calendar/15.0/calendar)
	@echo "Build Calendar completed\n"

install-calendar: build-calendar
	osascript ./scripts/enter-user-country.applescript


build-console:
	@echo "\nBuilding Console scripts..."
	$(call _build-script, apps/1st-party/Console/v1.1/console)
	@echo "Build Console completed\n"


build-finder:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "Untested macOS version for Finder. Development started at least on macOS Monterey (v12)."
endif
	$(call _build-script,apps/1st-party/Finder/12.5/finder)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "\nBuilding Finder 15.2 scripts..."
	$(call _build-script,apps/1st-party/Finder/15.2/finder-mini)
	$(call _build-script,apps/1st-party/Finder/15.2/dec-finder-selection)
	$(call _build-script,apps/1st-party/Finder/15.2/finder-tab)
	$(call _build-script,apps/1st-party/Finder/15.2/dec-finder-folders)
	$(call _build-script,apps/1st-party/Finder/15.2/dec-finder-files)
	$(call _build-script,apps/1st-party/Finder/15.2/dec-finder-paths)
	$(call _build-script,apps/1st-party/Finder/15.2/dec-finder-view)
	$(call _build-script,apps/1st-party/Finder/15.2/finder)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SEQUOIA) ] && echo yes),yes)
	@echo "\nBuilding Finder 26.0 scripts..."
	$(call _build-script,apps/1st-party/Finder/26.0/dec-finder-view)
	$(call _build-script,apps/1st-party/Finder/26.1/dec-finder-dialog)
	$(call _build-script,apps/1st-party/Finder/26.1/finder)
endif
	@echo "Build Finder completed\n"


build-home:
	$(call _build-script,apps/1st-party/Home/7.0/home)
	@echo "Build Home completed\n"


build-mail:
	$(call _build-script,apps/1st-party/Mail/16.0/dec-mail-settings)
	$(call _build-script,apps/1st-party/Mail/16.0/dec-mail-selection)
	$(call _build-script,apps/1st-party/Mail/16.0/mail)
	@echo "Build mail scripts completed\n"


build-passwords:
	$(call _build-script,apps/1st-party/Passwords/2.0/passwords)
	@echo "Build Passwords completed\n"


build-preview:
	$(call _build-script,core/decorators/dec-preview-markup)
	$(call _build-script,apps/1st-party/Preview/v11/preview)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SEQUOIA) ] && echo yes),yes)
	$(call _build-script,apps/1st-party/Preview/v11-Tahoe/preview)
endif
	@echo "Build Preview completed\n"


VERSION_SAFARI_MAJOR_MINOR = $(shell osascript -e "tell application \"Safari\" to version" | awk -F. '{print $$1 "." $$2}')
$(info     VERSION_SAFARI_MAJOR_MINOR: $(VERSION_SAFARI_MAJOR_MINOR))

# dir — build when VERSION_SAFARI_MAJOR_MINOR >= dir (subfolders of Safari/, excluding 16.0)
SAFARI_VERSION_BUILDS := $(filter-out 16.0,$(patsubst apps/1st-party/Safari/%/,%,$(wildcard apps/1st-party/Safari/*/)))

build-safari: build-dock build-process
	# Older versions of scripts are built first and overwritten by newer versions.
	$(call _build-script,core/Level_5/javascript)

	@echo "Building Safari 16.0 scripts"
	@for file in $(wildcard apps/1st-party/Safari/16.0/*.applescript); do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file"; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done

	@for dir in $(SAFARI_VERSION_BUILDS); do \
		dir_mm=$$(echo "$$dir" | awk -F. '{print $$1 "." $$2}'); \
		if echo "$(VERSION_SAFARI_MAJOR_MINOR) $$dir_mm" | awk '{exit !($$1 >= $$2)}'; then \
			echo "\nBuilding Safari $$dir scripts..."; \
			for file in apps/1st-party/Safari/$$dir/*.applescript; do \
				[ -e "$$file" ] || continue; \
				no_ext=$${file%.applescript}; \
				echo "Building $$file"; \
				yes y | ./scripts/build-lib.sh "$$no_ext"; \
			done; \
		fi; \
	done
	osascript apps/1st-party/Safari/26.1/allow-javascript-from-apple-events.applescript
	@echo "Build Safari completed\n"

install-safari: build-safari
	osascript ./scripts/allow-apple-events-in-safari.applescript
	plutil -replace 'FIND_RETRY_MAX' -integer 90 ~/applescript-core/config-system.plist
	plutil -replace 'FIND_RETRY_SLEEP' -integer 1 ~/applescript-core/config-system.plist


build-safari-technology-preview:  # Broken
	$(call _build-script,apps/1st-party/Safari Technology Preview/r168/dec-safari-technology-preview-javascript)
	$(call _build-script,apps/1st-party/Safari Technology Preview/r168/safari-technology-preview)

install-safari-technology-preview: build-safari-technology-preview
	osascript ./scripts/allow-apple-events-in-safari-technology-preview.applescript


build-script-editor:
	$(call _build-script,apps/1st-party/Script Editor/2.11/script-editor-tab)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-dialog)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-tabs)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-window)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-content)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-cursor)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-settings)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-settings-general)
	$(call _build-script,apps/1st-party/Script Editor/2.11/dec-script-editor-settings-editing)
	$(call _build-script,apps/1st-party/Script Editor/2.11/script-editor)
	@echo "Build Script Editor completed"


OS_VERSION_MAJOR = $(OS_TAHOE) # Debugging only.
$(info     DEBUG: OS_VERSION_MAJOR: $(OS_VERSION_MAJOR))

build-system-settings:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "WARNING:Untested macOS version for system settings. Development started at least on macOS Monterey (v12)."
endif
	./scripts/factory-remove.sh SystemSettingsInstance core/dec-system-settings-sonoma
	@echo "\nBuilding initial System Settings 15.0 scripts..."
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control_voice-commands)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_accessibility_voice-control)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_desktop-and-dock)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_displays)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_internet-accounts)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_keyboard)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_lock-screen)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_network)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_passwords)
	$(call _build-script,apps/1st-party/System Settings/15.0/dec-system-settings_sound)
	$(call _build-script,apps/1st-party/System Settings/15.0/system-settings)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_VENTURA) ] && echo yes),yes)
	@echo "\nBuilding System Settings 15.0 macOS Sonoma scripts..."
	$(call _build-script,apps/1st-party/System Settings/15.0/macOS Sonoma/dec-system-settings-sonoma)
	./scripts/factory-insert.sh SystemSettingsInstance core/dec-system-settings-sonoma
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SONOMA) ] && echo yes),yes)
	@echo "\nBuilding System Settings 15.0 macOS Sequoia scripts..."
	$(call _build-script,apps/1st-party/System Settings/15.0/macOS Sequoia/dec-system-settings_apple-intelligence-and-siri)
	$(call _build-script,apps/1st-party/System Settings/15.0/macOS Sequoia/system-settings)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SEQUOIA) ] && echo yes),yes)
	@echo "\nBuilding System Settings for macOS Tahoe scripts..."
	$(call _build-script,apps/1st-party/System Settings/26.3/dec-system-settings_keyboard)
	$(call _build-script,apps/1st-party/System Settings/26.3/dec-system-settings_general_about)
	$(call _build-script,apps/1st-party/System Settings/26.3/dec-system-settings_general)
	$(call _build-script,apps/1st-party/System Settings/26.3/dec-system-settings_keyboard)
	$(call _build-script,apps/1st-party/System Settings/26.3/system-settings)
endif

	@echo "Build System Settings completed"


build-terminal:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "Untested macOS version for terminal. Development started at least on macOS Monterey (v12)."
endif

	@echo "\nBuilding Terminal 2.12.x scripts..."
	$(call _build-script, apps/1st-party/Terminal/2.12.x/dec-terminal-output)
	$(call _build-script, apps/1st-party/Terminal/2.12.x/dec-terminal-path)
	$(call _build-script, apps/1st-party/Terminal/2.12.x/dec-terminal-prompt)
	$(call _build-script, apps/1st-party/Terminal/2.12.x/dec-terminal-run)
	$(call _build-script, apps/1st-party/Terminal/2.12.x/terminal)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "\nBuilding Terminal 2.13.x scripts..."
	$(call _build-script, apps/1st-party/Terminal/2.13.x/dec-terminal-output)
	$(call _build-script, apps/1st-party/Terminal/2.13.x/dec-terminal-path)
	$(call _build-script, apps/1st-party/Terminal/2.13.x/dec-terminal-prompt)
	$(call _build-script, apps/1st-party/Terminal/2.13.x/dec-terminal-run)
	$(call _build-script, apps/1st-party/Terminal/2.13.x/terminal)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_VENTURA) ] && echo yes),yes)
	@echo "\nBuilding Terminal 2.14.x scripts..."
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-output)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-path)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-prompt)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-run)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/terminal-tab)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/terminal)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SONOMA) ] && echo yes),yes)
	@echo "\nBuilding > macOS Sonoma Terminal 2.14.x scripts..."
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-settings)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-settings-general)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile-window)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile-keyboard)
	$(call _build-script, apps/1st-party/Terminal/2.14.x/dec-terminal_tab-finder)
endif

	$(call _build-script, libs/sftp/dec-terminal-prompt-sftp)
	@echo "Build Terminal completed"


build-xcode:
	$(call _build-script, apps/3rd-party/Xcode/15.4/dec-xcode-debugging)
	$(call _build-script, apps/3rd-party/Xcode/15.4/xcode)
	@echo "Build Xcode completed"
