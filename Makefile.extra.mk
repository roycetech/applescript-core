# Makefile.extra.mk
# @Created: Fri, Jul 19, 2024 at 5:05:16 PM
# This will contain targets for building optional libraries.


# Other libraries
build-extra: build-counter install-timed-cache


build-counter:
	@echo "Building counter scripts..."
	$(call _build-script,libs/counter-plist/dec-counter-hourly)
	$(call _build-script,libs/counter-plist/dec-counter-daily)
	$(call _build-script,libs/counter-plist/counter)
	@echo "Build counter scripts completed\n"

install-counter: build-counter


build-cliclick:
	@echo "Building cliclick scripts..."
	@if command -v cliclick >/dev/null 2>&1; then \
		osascript libs/cliclick/setup-cliclick-cli.applescript; \
		./scripts/build-lib.sh libs/cliclick/cliclick; \
		echo "Done installing cliclick"; \
	else \
		echo "Error: cliclick is not installed. Please check https://github.com/BlueM/cliclick" >&2; \
		exit 1; \
	fi
	@echo "Build cliclick scripts completed\n"

install-cliclick-decorators:
	@echo "Installing cliclick decorators..."
	$(SUDO) ./scripts/plist-insert.sh ~/applescript-core/config-lib-factory.plist "SystemSettingsInstance" "core/dec-system-settings-cliclick"
	@echo "Install cliclick decorators completed\n"

uninstall-cliclick-decorators:
	$(SUDO) ./scripts/plist-remove.sh ~/applescript-core/config-lib-factory.plist "SystemSettingsInstance" "core/dec-system-settings-cliclick"


build-jira:
	@echo "Building jira scripts..."
	$(call _build-script,libs/jira/jira)
	@echo "Build jira scripts completed\n"


# Optional with 3rd party app dependency.
build-json:
	@echo "Building json scripts..."
	$(call _build-script,libs/json/json)
	@echo "Build json scripts completed\n"

install-json: build-json


build-log4as:
	@echo "Building log4as scripts..."
	$(call _build-script,libs/log4as/log4as)
	$(call _build-script,core/decorators/dec-logger-log4as)
	@echo "Build log4as scripts completed\n"

install-log4as: build-log4as
# 	plutil -replace 'LoggerSpeechAndTrackingInstance' -string 'dec-logger-log4as' ~/applescript-core/config-lib-factory.plist
	plutil -replace 'LoggerOverridableInstance' -string 'core/dec-logger-log4as' ~/applescript-core/config-lib-factory.plist
	cp -n libs/log4as/log4as.plist.template ~/applescript-core/log4as.plist || true
	plutil -replace 'defaultLevel' -string 'DEBUG' ~/applescript-core/log4as.plist
	plutil -replace 'printToConsole' -bool true ~/applescript-core/log4as.plist
	plutil -replace 'writeToFile' -bool true ~/applescript-core/log4as.plist
	plutil -insert categories -xml "<dict></dict>" ~/applescript-core/log4as.plist || true


PROCESS_SCRIPTS = $(wildcard libs/process/*.applescript)
build-process:
	@echo "Building process scripts..."
	@for file in $(PROCESS_SCRIPTS); do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file"; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Build process scripts completed\n"


# build-process:
# 	# $(SUDO) ./scripts/build-lib.sh libs/process/process
# 	yes y | ./scripts/build-lib.sh libs/process/process

install-process-dock:
	./scripts/factory-insert.sh ProcessInstance core/dec-process-dock

uninstall-process-dock:
	./scripts/factory-remove.sh ProcessInstance core/dec-process-dock


build-redis:
	@echo "Building Redis scripts..."
	osascript ./scripts/setup-redis-cli.applescript
	$(call _build-script,libs/redis/redis)
	@echo "Build redis scripts completed\n"

build-redis-terminal:
	@echo "Building Redis terminal scripts..."
	$(call _build-script,libs/redis/dec-terminal-prompt-redis)
	@echo "Build redis terminal scripts completed\n"

install-redis: build-redis


build-security-cli:
	@echo "Building Security CLI scripts..."
	$(call _build-script,libs/security-cli/security-cli)
	@echo "Build Security CLI scripts completed\n"


install-timed-cache:
	cp -n plist.template ~/applescript-core/timed-cache.plist || true
	$(call _build-script,libs/timed-cache-plist/timed-cache-plist)
	@echo "Build timed cache scripts completed\n"
