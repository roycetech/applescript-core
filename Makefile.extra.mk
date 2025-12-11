# Makefile.extra.mk
# @Created: Fri, Jul 19, 2024 at 5:05:16 PM
# This will contain targets for building optional libraries.



# Other libraries
build-extra: build-counter install-timed-cache


build-counter:
	$(SUDO) ./scripts/build-lib.sh libs/counter-plist/dec-counter-hourly
	$(SUDO) ./scripts/build-lib.sh libs/counter-plist/dec-counter-daily
	$(SUDO) ./scripts/build-lib.sh libs/counter-plist/counter

install-counter: build-counter


build-cliclick:
	@if command -v cliclick >/dev/null 2>&1; then \
		echo "cliclick is installed"; \
		./scripts/build-lib.sh libs/cliclick/cliclick; \
	else \
		echo "Error: cliclick is not installed" >&2; \
		exit 1; \
	fi

install-cliclick-decorators:
	$(SUDO) ./scripts/plist-insert.sh ~/applescript-core/config-lib-factory.plist "SystemSettingsInstance" "core/dec-system-settings-cliclick"

uninstall-cliclick-decorators:
	$(SUDO) ./scripts/plist-remove.sh ~/applescript-core/config-lib-factory.plist "SystemSettingsInstance" "core/dec-system-settings-cliclick"


install-jira:
	$(SUDO) ./scripts/build-lib.sh libs/jira/jira


# Optional with 3rd party app dependency.
build-json:
	$(SUDO) ./scripts/build-lib.sh libs/json/json

install-json: build-json


build-log4as:
	$(SUDO) ./scripts/build-lib.sh libs/log4as/log4as
	$(SUDO) ./scripts/build-lib.sh core/decorators/dec-logger-log4as

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
	@for file in $(PROCESS_SCRIPTS); do \
		no_ext=$${file%.applescript}; \
		echo "Building $$file"; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done
	@echo "Done building process scripts"


# build-process:
# 	# $(SUDO) ./scripts/build-lib.sh libs/process/process
# 	yes y | ./scripts/build-lib.sh libs/process/process

install-process-dock:
	./scripts/factory-insert.sh ProcessInstance core/dec-process-dock

uninstall-process-dock:
	./scripts/factory-remove.sh ProcessInstance core/dec-process-dock


build-redis:
	osascript ./scripts/setup-redis-cli.applescript
	$(SUDO) ./scripts/build-lib.sh libs/redis/redis

build-redis-terminal:
	$(SUDO) ./scripts/build-lib.sh libs/redis/dec-terminal-prompt-redis

install-redis: build-redis


build-security:
	$(SUDO) ./scripts/build-lib.sh libs/security-cli/security-cli


install-timed-cache:
	cp -n plist.template ~/applescript-core/timed-cache.plist || true
	$(SUDO) ./scripts/build-lib.sh libs/timed-cache-plist/timed-cache-plist
