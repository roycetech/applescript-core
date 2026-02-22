# Makefile.core.mk
# @Created: Tue, Jul 16, 2024 at 11:43:13 AM
# @Purpose:
# 	Contains the core libraries.

ifeq ($(USE_SUDO),true)
  SUDO := sudo
else
  SUDO :=
endif

# 	config

LEVEL1_LIBS := \
	decorator \
	string \
	logger \
	logger-factory \
	list

APPS_PATH=/Applications/AppleScript

_init:
ifeq ($(DEPLOY_TYPE), user)
	mkdir -p ~/Library/Script\ Libraries/core
	mkdir -p ~/Applications/AppleScript/Stay\ Open/
else
	$(SUDO) mkdir -p /Library/Script\ Libraries/core
	$(SUDO) mkdir -p /Applications/AppleScript/Stay\ Open/
endif
	mkdir -p ~/applescript-core/sounds/
	mkdir -p ~/applescript-core/logs/
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

install: _init build
ifeq ($(DEPLOY_TYPE), user)
	mkdir -p ~/Library/'Script Libraries'/core/test
	mkdir -p ~/Library/'Script Libraries'/core/app
else
	$(SUDO) mkdir -p /Library/'Script Libraries'/core/test
	$(SUDO) mkdir -p /Library/'Script Libraries'/core/app
endif
	touch ~/applescript-core/logs/applescript-core.log
#	osascript scripts/setup-applescript-core-project-path.applescript
# 	./scripts/setup-switches.sh
	@echo "applescript-core installation completed"

$(LEVEL1_LIBS): Makefile
	yes y | ./scripts/build-lib.sh "core/Level_1/$@"


build-standard:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "Unsupported macOS version for standard script"
else
	$(call _build-script,macOS-version/12-monterey/control-center)

# [Begin] nested standard sub level 1
ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_MONTEREY) ] && echo yes),yes)
	$(call _build-script,macOS-version/13-ventura/std)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_VENTURA) ] && echo yes),yes)
	$(call _build-script,macOS-version/14-sonoma/std)
endif

# [End] nested standard sub level 1
endif
	@echo "Build standard completed"


build-core-bundle:
	$(SUDO) ./scripts/build-bundle.sh 'core/Text Utilities'
	@echo "Core bundle built."


build: \
	build-core-bundle \
	build-core \
	build-control-center \
	build-dock \
	build-user


build-extras: \
	build-counter \
	build-redis \
	build-terminal


build-all: \
	build \
	build-extras \
	build-macos-apps

install-all: build-all

build-core: \
	build-level1 \
	build-standard \
	build-level2 \
	build-control-center \
	build-level3 \
	build-level4 \
	build-user \
	build-level5
	@echo "Core libraries compiled."

build-level1: $(LEVEL1_LIBS)
	@echo "Level 1 scripts compiled."


LEVEL2_SCRIPTS = $(wildcard core/Level_2/*.applescript)
build-level2:
	@for file in $(LEVEL2_SCRIPTS); do \
		echo "Building $$file"; \
		no_ext=$${file%.applescript}; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building level 2 scripts"

LEVEL3_SCRIPTS = $(wildcard core/Level_3/*.applescript)
build-level3:
	@for file in $(LEVEL3_SCRIPTS); do \
		echo "Building $$file"; \
		no_ext=$${file%.applescript}; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building level 3 scripts"

LEVEL4_SCRIPTS = $(wildcard core/Level_4/*.applescript)
build-level4:
	@for file in $(LEVEL4_SCRIPTS); do \
		echo "Building $$file"; \
		no_ext=$${file%.applescript}; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building level 4 scripts"

LEVEL5_SCRIPTS = $(wildcard core/Level_5/*.applescript)
build-level5:
	@for file in $(LEVEL5_SCRIPTS); do \
		echo "Building $$file"; \
		no_ext=$${file%.applescript}; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building level 5 scripts"


reveal-scripts:  # Reveal the deployed scripts.
	open ~/Library/Script\ Libraries


# Helper function to build and confirm with yes to the prompt.
_build-script = \
	@echo "Building $(1)"; \
	yes y | ./scripts/build-lib.sh $(1)

# macOS Version-Specific Apps -------------------------------------------------


build-control-center:
	# Supports macOS Monterey and later.
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "Untested macOS version for control-center"
endif

	$(call _build-script,macOS-version/12-monterey/control-center)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "\nBuilding Control Center 13-ventura scripts..."
	$(call _build-script,macOS-version/13-ventura/control-center_network)
	$(call _build-script,macOS-version/13-ventura/control-center_sound)
	$(call _build-script,macOS-version/13-ventura/control-center_focus)
	$(call _build-script,macOS-version/13-ventura/control-center)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_VENTURA) ] && echo yes),yes)
	@echo "\nBuilding Control Center 14-sonoma scripts..."
	$(call _build-script,macOS-version/14-sonoma/control-center_network)
	$(call _build-script,macOS-version/14-sonoma/control-center_sound)
	$(call _build-script,macOS-version/14-sonoma/control-center_focus)
	$(call _build-script,macOS-version/14-sonoma/control-center_bluetooth)
	$(call _build-script,macOS-version/14-sonoma/control-center_wifi)
	$(call _build-script,macOS-version/14-sonoma/control-center)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SONOMA) ] && echo yes),yes)
	# Sonoma scripts are compatible with Sequoia
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SEQUOIA) ] && echo yes),yes)
	@echo "\nBuilding Control Center 26-tahoe scripts..."
	$(call _build-script,macOS-version/26-tahoe/control-center_sound)
	$(call _build-script,macOS-version/26-tahoe/control-center)
endif
	@echo "Build control-center completed\n"

install-control-center: build-control-center


build-dock:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "Untested macOS version for dock. Development started at least on macOS Monterey (v12)."
endif
	$(call _build-script,macOS-version/12-monterey/dock)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_VENTURA) ] && echo yes),yes)
	$(call _build-script,macOS-version/14-sonoma/dock)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SONOMA) ] && echo yes),yes)
	$(call _build-script,macOS-version/15-sequoia/dock)
endif
	@echo "Build dock completed\n"


build-notification-center:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt $(OS_MONTEREY) ] && echo yes),yes)
	@echo "Untested macOS version for notification-center. Please report any issues."
endif

	$(call _build-script,macOS-version/12-monterey/notification-center-helper)
	$(call _build-script,macOS-version/12-monterey/notification-center)

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_MONTEREY) ] && echo yes),yes)
	$(call _build-script,macOS-version/13-ventura/notification-center-helper)
	$(call _build-script,macOS-version/13-ventura/notification-center)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_VENTURA) ] && echo yes),yes)
	$(call _build-script,macOS-version/14-sonoma/notification-center-helper)
	$(call _build-script,macOS-version/14-sonoma/notification-center)
endif

ifeq ($(shell [ $(OS_VERSION_MAJOR) -gt $(OS_SONOMA) ] && echo yes),yes)
	$(call _build-script,macOS-version/15-sequoia/notification-center-helper)
	$(call _build-script,macOS-version/15-sequoia/notification-center)
endif
	@echo "Build notification-center completed\n"


build-user:
	$(call _build-script,libs/user/user)
	@echo "Build user completed"


# Directory containing the decorator scripts
DECORATORS_PATH = ./core/decorators
DECORATORS = $(wildcard $(DECORATORS_PATH)/dec-*.applescript)

build-decorators:
	@for file in $(DECORATORS); do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file"; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building core decorators"


# Library Decorators
install-dvorak:
	$(call _build-script,core/Level_2/keyboard)
	$(call _build-script,core/decorators/dec-keyboard-dvorak-cmd)
	yes y | ./scripts/factory-insert.sh KeyboardInstance core/dec-keyboard-dvorak-cmd
	@echo "Done building Dvorak scripts"


# Deprecated targets ----------------------------------------------------------

build-lib:  # Deprecated on 20260219. Use the ./scripts/build-lib.sh directly.
	$(SUDO) ./scripts/build-lib.sh $(SOURCE)

build-bundle:  # Deprecated on 20260219. Use the ./scripts/build-bundle.sh directly.
	$(SUDO) ./scripts/build-bundle.sh $(SOURCE)
