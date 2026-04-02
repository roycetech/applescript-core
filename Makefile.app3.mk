# Makefile.app3.mk
# Created: Fri, Jul 19, 2024 at 1:27:27 PM
# Contains target for 3rd party apps and libraries.

OMZ_EXISTS := $(wildcard ~/.oh-my-zsh/plugins)
$(info     OMZ_EXISTS: $(OMZ_EXISTS))
$(info )

build-omz:
ifeq ($(OMZ_EXISTS),)
	@echo "Oh My Zsh not found (~/.oh-my-zsh/plugins missing), aborting OMZ build\n"
	exit 1
else
	@echo "Building OMZ scripts..."
	$(call _build-script,libs/zsh/oh-my-zsh)
	$(call _build-script,apps/1st-party/Terminal/2.14.x/dec-terminal-prompt-omz)
	@echo "Build OMZ completed\n"
endif


install-omz: build-omz
	./scripts/factory-insert.sh TerminalTabInstance core/dec-terminal-prompt-omz


# 3rd Party Apps Library ------------------------------------------------------
build-one-password: build-cliclick
	$(call _build-app-scripts-if-exists,1Password,apps/3rd-party/1Password/v6)

install-1password: build-one-password install-cliclick


build-bartender:
	$(call _build-app-scripts-if-exists,Bartender,apps/3rd-party/Bartender/v5)


build-camera-hub:
	$(call _build-app-scripts-if-exists,Camera Hub,apps/3rd-party/Camera Hub/1.10.2)


build-cleanshot-x:
	$(call _build-app-scripts-if-exists,CleanShot X,apps/3rd-party/CleanShot X/4.7.4)


build-cursor: build-base-app
	$(call _build-app-scripts-if-exists,Cursor,apps/3rd-party/Cursor/2.5)
.PHONY: build-cursor

install-cursor: build-cursor
	osascript ./scripts/setup-cursor-cli.applescript


install-eclipse:
	$(call _build-app-scripts-if-exists,Eclipse,apps/3rd-party/Eclipse/v202306)


install-file-zilla:
	$(call _build-app-scripts-if-exists,FileZilla,apps/3rd-party/FileZilla/3.69.x)


install-git-kraken:
	$(call _build-app-scripts-if-exists,GitKraken,apps/3rd-party/GitKraken/v9.8.2)


build-google-chrome:
	@echo "Building Google Chrome scripts..."
	$(call _build-script,apps/3rd-party/Google Chrome/136.0/google-chrome-tab)
	$(call _build-script,apps/3rd-party/Google Chrome/131.0/dec-google-chrome-tab-finder)
	$(call _build-script,apps/3rd-party/Google Chrome/129.0/google-chrome-javascript)
	$(call _build-script,apps/3rd-party/Google Chrome/134.0/dec-google-chrome-inspector)
	$(call _build-script,apps/3rd-party/Google Chrome/139.0/google-chrome)
	@echo "Build Google Chrome completed\n"


build-guitar-pro:
	$(call _build-app-scripts-if-exists,Guitar Pro,apps/3rd-party/Guitar Pro/7.6)


build-microsoft-edge:
	$(call _build-app-scripts-if-exists,Microsoft Edge,apps/3rd-party/Microsoft Edge/140.0)


build-iterm:
	$(call _build-app-scripts-if-exists,iTerm2,apps/3rd-party/iTerm2/3.5.x)


build-intellij:
	$(call _build-app-scripts-if-exists,IntelliJ IDEA,apps/3rd-party/IntelliJ IDEA/v2024.2.4)
.PHONY: build-intellij

install-intellij: build-intellij
	$(SUDO) osascript ./scripts/setup-intellij-cli.applescript


build-keyboard-maestro:
	$(call _build-app-scripts-if-exists,Keyboard Maestro,apps/3rd-party/Keyboard Maestro)


install-last-pass:
	$(call _build-app-scripts-if-exists,LastPass,apps/3rd-party/LastPass/4.4.x)


build-marked:
	$(call _build-app-scripts-if-exists,Marked 2,apps/3rd-party/Marked/2.6.46)


build-mosaic:
	$(call _build-app-scripts-if-exists,Mosaic,apps/3rd-party/Mosaic/v1.3.x)


build-paste: build-base-app
	$(call _build-app-scripts-if-exists,Paste,apps/3rd-party/Paste/4.4.2)


build-pulsar:
	$(call _build-app-scripts-if-exists,Pulsar,apps/3rd-party/Pulsar/1.128.x)


build-script-debugger:
	$(call _build-app-scripts-if-exists,Script Debugger,apps/3rd-party/Script Debugger/v8.0.x)


build-sequel-ace:
	$(call _build-app-scripts-if-exists,Sequel Ace,apps/3rd-party/Sequel Ace/4.1.x)


install-sequel-ace: build-sequel-ace


build-sourcetree:
	$(call _build-app-scripts-if-exists,Sourcetree,apps/3rd-party/Sourcetree/4.2.11)


build-step-two:
	$(call _build-app-scripts-if-exists,Step Two,apps/3rd-party/Step Two/3.1)


build-stream-deck:
	# 6.x is the OLDEST version.
	@echo "Building Stream Deck scripts..."
	$(call _build-script,apps/3rd-party/Stream Deck/6.x/dec-spot-stream-deck)
	$(call _build-script,apps/3rd-party/Stream Deck/6.9.1/dec-stream-deck-settings)
	$(call _build-script,apps/3rd-party/Stream Deck/6.9.1/dec-stream-deck-button)
# 	$(call _build-script,apps/3rd-party/Stream Deck/6.9.1/stream-deck)
	$(call _build-script,apps/3rd-party/Stream Deck/7.0/stream-deck)
	@echo "Build Stream Deck completed"


install-stream-deck: build-stream-deck
	yes y | ./scripts/factory-insert.sh StreamDeckInstance core/dec-spot-stream-deck
	@echo "Install Stream Deck completed"


install-sublime-text: build-finder
	osascript ./scripts/setup-sublime-text-cli.applescript
	./scripts/factory-insert.sh SystemEventsInstance core/dec-system-events-with-sublime-text
	$(call _build-script,apps/3rd-party/Sublime Text/4.x/dec-sublime-text-tabs)
	$(call _build-script,apps/3rd-party/Sublime Text/4.x/sublime-text)
	$(call _build-script,apps/3rd-party/Sublime Text/4.x/dec-system-events-with-sublime-text)
	@echo "Build Sublime Text completed"


install-text-mate:
	$(call _build-app-scripts-if-exists,TextMate,apps/3rd-party/TextMate/2.0.x)


build-ui-browser:
	$(call _build-app-scripts-if-exists,UI Browser,apps/3rd-party/UI Browser/3.0.2)


build-viscosity: build-step-two
	$(call _build-app-scripts-if-exists,Viscosity,apps/3rd-party/Viscosity/1.10.x)


build-visual-studio-code:
	$(call _build-app-scripts-if-exists,Visual Studio Code,apps/3rd-party/Visual Studio Code/1.81)


build-vlc:
	$(call _build-app-scripts-if-exists,VLC,apps/3rd-party/VLC/3.0.x)


build-zoom:
	$(call _build-app-scripts-if-exists,Zoom,apps/3rd-party/zoom.us/6.0.x)


install-zoom: build-zoom
	mkdir -p ~/applescript-core/zoom.us/
	cp -n plist.template ~/applescript-core/zoom.us/config.plist || true
	osascript ./apps/3rd-party/zoom.us/setup-zoom-configurations.applescript
# plutil -replace 'UserInstance' -string 'core/dec-user-zoom' ~/applescript-core/config-lib-factory.plist
# ./scripts/plist-insert.sh ~/applescript-core/config-lib-factory.plist "UserInstance" "core/dec-user-zoom"
# plutil -replace 'CalendarEventLibrary' -string 'core/dec-calendar-event-zoom' ~/applescript-core/config-lib-factory.plist
	./scripts/factory-insert.sh UserInstance core/dec-user-zoom
	./scripts/factory-insert.sh CalendarEventLibrary core/dec-calendar-event-zoom
	@echo "Install Zoom completed\n"


# @1 - App name
# @2 - folder to build the scripts from
_build-app-scripts-if-exists = \
	@if [ -d "/Applications/$(1).app" ]; then \
		echo "Building $(1) scripts..."; \
		find "$(2)" -maxdepth 1 -type f -name '*.applescript' -print0 \
		| while IFS= read -r -d '' file; do \
			echo "Building $$file"; \
			no_ext=$${file%.applescript}; \
			yes y | ./scripts/build-lib.sh "$$no_ext"; \
		done; \
		echo "Build $(1) scripts completed\n"; \
	else \
		echo "$(1) not found, skipping build"; \
	fi
