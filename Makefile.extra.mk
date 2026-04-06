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


build-security-cli:
	@echo "Building Security CLI scripts..."
	$(call _build-script,libs/security-cli/security-cli)
	@echo "Build Security CLI scripts completed\n"


install-timed-cache:
	cp -n plist.template ~/applescript-core/timed-cache.plist || true
	$(call _build-script,libs/timed-cache-plist/timed-cache-plist)
	@echo "Build timed cache scripts completed\n"
