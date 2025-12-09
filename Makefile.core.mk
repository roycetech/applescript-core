# Makefile.core.mk
# Created: Tue, Jul 16, 2024 at 11:43:13 AM
# Purpose:
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

$(CORE_LIBS): Makefile
	$(SUDO) ./scripts/build-lib.sh core/$@


build-standard:
ifeq ($(shell [ $(OS_VERSION_MAJOR) -lt 12 ] && echo yes),yes)
$(error macOS version too old! Requires at least macOS Monterey (v12).)

else ifeq ($(shell [ $(OS_VERSION_MAJOR) -eq 12 ] && echo yes),yes)
	$(SUDO) ./scripts/build-lib.sh macOS-version/12-monterey/std

else ifeq ($(shell [ $(OS_VERSION_MAJOR) -eq 13 ] && echo yes),yes)
	$(SUDO) ./scripts/build-lib.sh macOS-version/12-monterey/std

else ifeq ($(shell [ $(OS_VERSION_MAJOR) -eq 13 ] && echo yes),yes)
	$(SUDO) ./scripts/build-lib.sh macOS-version/13-ventura/std
else
	$(SUDO) ./scripts/build-lib.sh macOS-version/14-sonoma/std
endif


build-core-bundle:
	$(SUDO) ./scripts/build-bundle.sh 'core/Text Utilities'
	@echo "Core bundle built."


# There are circular dependency issue that needs to be considered. You may need
# to re-order the build of the script depending on which script is needed first.

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

# build-core: $(CORE_LIBS)
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


build-lib:
	$(SUDO) ./scripts/build-lib.sh $(SOURCE)

build-bundle:
	$(SUDO) ./scripts/build-bundle.sh $(SOURCE)


reveal-scripts:  # Reveal the deployed scripts.
	open ~/Library/Script\ Libraries


build-apps: \
	build-automator \
	build-calendar \
	build-console \
	install-control-center \
	build-dock \
	build-finder \
	build-notification-center \
	build-preview \
	install-safari \
	build-system-settings \
	build-terminal


# macOS Version-Specific Apps -------------------------------------------------


build-control-center:
ifeq ($(OS_NAME), tahoe)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_network"
	$(SUDO) ./scripts/build-lib.sh macOS-version/16-tahoe/control-center_sound
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_focus"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_bluetooth"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_wifi"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center"

else ifeq ($(OS_NAME), sequoia)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_network"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sequoia/control-center_sound"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_focus"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_bluetooth"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_wifi"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center"

else ifeq ($(OS_NAME), sonoma)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_network"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_sound"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_focus"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_bluetooth"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center_wifi"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/control-center"

else ifeq ($(OS_NAME), ventura)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/13-ventura/control-center_network"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/13-ventura/control-center_sound"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/13-ventura/control-center_focus"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/13-ventura/control-center"

else ifeq ($(OS_NAME), monterey)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/12-monterey/control-center"

else
	$(SUDO) ./scripts/build-lib.sh "macOS-version/12-monterey/control-center"
	@echo "Unsupported macOS version for control-center"
endif
	@echo "Build control-center completed"

install-control-center: build-control-center


build-dock:
ifeq ($(OS_NAME), sonoma)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/dock"
# else ifeq ($(OS_NAME), sequoia)  # Works for Tahoe as well.
else
	$(SUDO) ./scripts/build-lib.sh "macOS-version/15-sequoia/dock"
endif
	@echo "Build dock completed"


build-notification-center:
ifeq ($(OS_NAME), sequoia)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/15-sequoia/notification-center-helper"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/15-sequoia/notification-center"

else ifeq ($(OS_NAME), sonoma)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/notification-center-helper"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/14-sonoma/notification-center"

else ifeq ($(OS_NAME), ventura)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/13-ventura/notification-center-helper"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/13-ventura/notification-center"

else ifeq ($(OS_NAME), monterey)
	$(SUDO) ./scripts/build-lib.sh "macOS-version/12-monterey/notification-center-helper"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/12-monterey/notification-center"

else
	$(SUDO) ./scripts/build-lib.sh "macOS-version/12-monterey/notification-center-helper"
	$(SUDO) ./scripts/build-lib.sh "macOS-version/12-monterey/notification-center"
	@echo "Unsupported macOS version for notification-center"
endif


build-user:
	@yes y | ./scripts/build-lib.sh libs/user/user
	@echo "Build user completed"


# Directory containing the files
DECORATORS_PATH = ./core/decorators

# Get all the .txt files in the directory
DECORATORS = $(wildcard $(DECORATORS_PATH)/dec-*.applescript)

build-decorators:
	@for file in $(DECORATORS); do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file"; \
		$(SUDO) ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building core decorators"


# Library Decorators
install-dvorak:
	$(SUDO) ./scripts/build-lib.sh core/decorators/dec-keyboard-dvorak-cmd
	$(SUDO) ./scripts/build-lib.sh core/keyboard
	$(SUDO) ./scripts/factory-insert.sh KeyboardInstance core/dec-keyboard-dvorak-cmd
