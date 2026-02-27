# Makefile.app3.mk
# Created: Fri, Jul 19, 2024 at 1:27:27 PM
# Contains target for 3rd party apps and libraries.

OMZ_EXISTS := $(wildcard ~/.oh-my-zsh/plugins)
$(info     OMZ_EXISTS: $(OMZ_EXISTS))

build-omz:
	$(call _build-script,libs/zsh/oh-my-zsh)
	$(call _build-script,apps/1st-party/Terminal/2.14.x/dec-terminal-prompt-omz)
	@echo "Build OMZ completed"

install-omz: build-omz
	$(call _build-script,apps/1st-party/Terminal/2.14.x/dec-terminal-prompt-omz)
	$(SUDO) ./scripts/factory-insert.sh TerminalTabInstance core/dec-terminal-prompt-omz


# 3rd Party Apps Library ------------------------------------------------------
build-one-password: build-cliclick
	$(call _build-script,apps/3rd-party/1Password/v6/one-password)
	@echo "Build 1Password completed"

install-1password: build-one-password install-cliclick


install-atom:  ## Deprecated
	$(call _build-script,apps/3rd-party/Atom/1.60.0/atom)


build-bartender:
	$(call _build-script,apps/3rd-party/Bartender/v5/bartender)
	@echo "Build Bartender completed"

build-camera-hub:
	$(call _build-script,apps/3rd-party/Camera Hub/1.10.2/camera-hub)
	@echo "Build Camera Hub completed"


build-cleanshot-x:
	$(call _build-script,apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-general)
	$(call _build-script,apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-shortcuts)
	$(call _build-script,apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-quick-access)
	$(call _build-script,apps/3rd-party/CleanShot X/4.7.4/cleanshot-x)
	@echo "Build CleanShot X completed"


build-cursor:
	$(call _build-script,apps/3rd-party/Cursor/2.5/dec-cursor-current-file)
	$(call _build-script,apps/3rd-party/Cursor/2.5/dec-cursor-layout)
	$(call _build-script,apps/3rd-party/Cursor/2.5/cursor)
	@echo "Build Cursor completed"
.PHONY: build-cursor


install-eclipse:
	$(call _build-script,apps/3rd-party/Eclipse/v202306/eclipse)
	@echo "Build Eclipse completed"


install-file-zilla:
	$(call _build-script,apps/3rd-party/FileZilla/3.69.x/file-zilla)
	@echo "Build FileZilla completed"


install-git-kraken:
	$(call _build-script,apps/3rd-party/GitKraken/v9.8.2/git-kraken)
	@echo "Build GitKraken completed"


build-google-chrome:
	$(call _build-script,apps/3rd-party/Google Chrome/136.0/google-chrome-tab)
	$(call _build-script,apps/3rd-party/Google Chrome/131.0/dec-google-chrome-tab-finder)
	$(call _build-script,apps/3rd-party/Google Chrome/129.0/google-chrome-javascript)
	$(call _build-script,apps/3rd-party/Google Chrome/134.0/dec-google-chrome-inspector)
	$(call _build-script,apps/3rd-party/Google Chrome/139.0/google-chrome)
	@echo "Build Google Chrome completed"


build-guitar-pro:
	$(call _build-script,apps/3rd-party/Guitar Pro/7.6/dec-guitar-pro-note)
	$(call _build-script,apps/3rd-party/Guitar Pro/7.6/guitar-pro)
	@echo "Build Guitar Pro completed"


build-microsoft-edge:
	$(call _build-script,apps/3rd-party/Microsoft Edge/140.0/microsoft-edge-javascript)
	$(call _build-script,apps/3rd-party/Microsoft Edge/140.0/microsoft-edge-tab)
	$(call _build-script,apps/3rd-party/Microsoft Edge/140.0/dec-microsoft-edge-tab-finder)
	$(call _build-script,apps/3rd-party/Microsoft Edge/140.0/microsoft-edge)
	@echo "Build Microsoft Edge completed"


build-opera:
	$(call _build-script,apps/3rd-party/Opera/110.0/dec-opera-tab-finder)
	$(call _build-script,apps/3rd-party/Opera/110.0/opera-javascript)
	$(call _build-script,apps/3rd-party/Opera/110.0/opera-tab)
	$(call _build-script,apps/3rd-party/Opera/110.0/opera)
	@echo "Build Opera completed"


build-iterm:
	$(call _build-script,apps/3rd-party/iTerm2/3.5.x/iterm2)
	@echo "Build iTerm2 completed"


build-intellij:
	$(call _build-script,apps/3rd-party/IntelliJ IDEA/v2023.2.1/intellij-idea)
	@echo "Build IntelliJ IDEA completed"


install-intellij: build-intellij
	$(SUDO) osascript ./scripts/setup-intellij-cli.applescript

build-pulsar:
	$(call _build-script,apps/3rd-party/Pulsar/1.102.x/pulsar)

install-pulsar: build-pulsar
	@echo "Build Pulsar completed"


build-keyboard-maestro:
	$(call _build-script,apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-variables)
	$(call _build-script,apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-preferences-variables)
	$(call _build-script,apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-editor)
	$(call _build-script,apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-editor-actions)
	$(call _build-script,apps/3rd-party/Keyboard Maestro/keyboard-maestro)
	$(call _build-script,apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro)
	$(call _build-script,apps/3rd-party/Keyboard Maestro/keyboard-maestro-macro-group)
	@echo "Build Keyboard Maestro completed"


install-last-pass:
	$(call _build-script,apps/3rd-party/LastPass/4.4.x/last-pass)
	@echo "Build LastPass completed"

build-marked:
	$(call _build-script,apps/3rd-party/Marked/2.6.46/marked-tab)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-scrolling)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-settings)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-settings-general)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-settings-preview)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-settings-apps)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-settings-advanced)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/dec-marked-menu)
	$(call _build-script,apps/3rd-party/Marked/2.6.46/marked)
	@echo "Build Marked completed"

install-marked: build-marked


build-mosaic:
	$(call _build-script,apps/3rd-party/Mosaic/v1.3.x/mosaic)
	@echo "Build Mosaic completed"


build-paste:
	$(call _build-script,apps/3rd-party/Paste/4.4.2/paste)
	@echo "Build Paste completed"


build-script-debugger:
	$(call _build-script,'apps/3rd-party/Script Debugger/v8.0.x/script-debugger')
	@echo "Build Script Debugger completed"

install-script-debugger: build-script-debugger


build-sequel-ace:
	$(call _build-script,apps/3rd-party/Sequel Ace/4.1.x/sequel-ace-tab)
	$(call _build-script,apps/3rd-party/Sequel Ace/4.1.x/sequel-ace)
	@echo "Build Sequel Ace completed"

install-sequel-ace: build-sequel-ace


build-sourcetree:
	$(call _build-script,apps/3rd-party/Sourcetree/4.2.11/dec-sourcetree-settings)
	$(call _build-script,apps/3rd-party/Sourcetree/4.2.11/sourcetree)
	@echo "Build Sourcetree completed"


build-step-two:
	$(call _build-script,apps/3rd-party/Step Two/3.1/step-two)
	@echo "Build Step Two completed"


build-stream-deck:
	# 6.x is the OLDEST version.
	$(call _build-script,apps/3rd-party/Stream Deck/6.x/dec-spot-stream-deck)
	$(call _build-script,apps/3rd-party/Stream Deck/6.9.1/dec-stream-deck-settings)
	$(call _build-script,apps/3rd-party/Stream Deck/6.9.1/dec-stream-deck-button)
# 	$(call _build-script,apps/3rd-party/Stream Deck/6.9.1/stream-deck)
	$(call _build-script,apps/3rd-party/Stream Deck/7.0/stream-deck)
	@echo "Build Stream Deck completed"


install-stream-deck: build-stream-deck
# 	plutil \
# 		-replace 'SpotTestInstance' \
# 		-string 'core/dec-spot-stream-deck' \
# 		~/applescript-core/config-lib-factory.plist
	yes y | ./scripts/factory-insert.sh StreamDeckInstance core/dec-spot-stream-deck
	@echo "Install Stream Deck completed"


install-sublime-text: build-finder
	osascript ./scripts/setup-sublime-text-cli.applescript
	plutil \
		-replace 'SystemEventsInstance' \
		-string 'core/dec-system-events-with-sublime-text' \
		~/applescript-core/config-lib-factory.plist
	$(call _build-script,apps/3rd-party/Sublime Text/4.x/dec-sublime-text-tabs)
	$(call _build-script,apps/3rd-party/Sublime Text/4.x/sublime-text)
	$(call _build-script,apps/3rd-party/Sublime Text/4.x/dec-system-events-with-sublime-text)
	@echo "Build Sublime Text completed"


install-text-mate:
	$(call _build-script,apps/3rd-party/TextMate/2.0.x/text-mate)
	@echo "Build TextMate completed"


build-talon:
	$(call _build-script,apps/3rd-party/Talon/0.4/talon)
	@echo "Build Talon completed"


build-ui-browser:
	$(call _build-script,'apps/3rd-party/UI Browser/3.0.2/ui-browser')
	@echo "Build UI Browser completed"


build-viscosity: build-step-two
	$(call _build-script,apps/3rd-party/Viscosity/1.10.x/viscosity)
	@echo "Build Viscosity completed"


build-visual-studio-code:
	$(call _build-script,apps/3rd-party/Visual Studio Code/1.81/visual-studio-code)
	@echo "Build Visual Studio Code completed"


build-vlc:
	$(call _build-script,apps/3rd-party/VLC/3.0.x/vlc)
	@echo "Build VLC completed"


build-zoom:
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/dec-zoom-authentication)
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting)
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions)
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions-audio)
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions-video)
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/dec-zoom-meeting-actions-sharing)
	$(call _build-script,apps/3rd-party/zoom.us/6.0.x/zoom)
#	$(call _build-script,apps/3rd-party/zoom.us/5.x/dec-user-zoom)
#	$(call _build-script,apps/3rd-party/zoom.us/5.x/zoom-window)
#	$(call _build-script,apps/3rd-party/zoom.us/5.x/zoom-actions)
#	$(call _build-script,apps/3rd-party/zoom.us/5.x/zoom-participants)
#	$(call _build-script,apps/3rd-party/zoom.us/dec-calendar-event-zoom)
#	$(call _build-script,apps/3rd-party/zoom.us/5.x/zoom)
	@echo "Build Zoom completed"

install-zoom: build-zoom
	mkdir -p ~/applescript-core/zoom.us/
	cp -n plist.template ~/applescript-core/zoom.us/config.plist || true
	osascript ./apps/3rd-party/zoom.us/setup-zoom-configurations.applescript
	# plutil -replace 'UserInstance' -string 'core/dec-user-zoom' ~/applescript-core/config-lib-factory.plist
	./scripts/plist-insert.sh ~/applescript-core/config-lib-factory.plist "UserInstance" "core/dec-user-zoom"
	plutil -replace 'CalendarEventLibrary' -string 'core/dec-calendar-event-zoom' ~/applescript-core/config-lib-factory.plist
	@echo "Install Zoom completed"
