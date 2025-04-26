# Makefile
# Build the decorators before the main script.

OS_NAME := $(shell osascript -e "system version of (system info)" \
| cut -d '.' -f 1 \
| awk '{if ($$1 ~ /^15/) print "sequoia"; else if ($$1 ~ /^14/) print "sonoma"; else if ($$1 ~ /^13/) print "ventura"; else if ($$1 ~ /^12/) print "monterey"; else print "unknown"}')

GET_DEPLOY_SCRIPT := ./scripts/get-deploy-type.sh
DEPLOY_TYPE := $(shell $(GET_DEPLOY_SCRIPT))

list-targets:
	@awk '/^[a-zA-Z][^:]*:$$/' $(MAKEFILE_LIST) | sed 's/:.*//'
.PHONY: list-targets


help:
	@echo "make install - Create config files, assets, and install essential libraries."

$(info     AppleScript Core Build Script)
$(info     OS_NAME: $(OS_NAME))
$(info     DEPLOY_TYPE: $(DEPLOY_TYPE))

ifeq ($(DEPLOY_TYPE),computer)
	# Commands to execute if VARIABLE is equal to "value"
# $(info     computer)
	include Makefile.global

else
# $(info     user)
 	include Makefile.user

endif


# deploy-type:  # Detects configured deployment type
# 	@deploy_type=$$(plutil -extract "[app-core] Deployment Type - LOV Selected" raw ~/applescript-core/session.plist); \
# 	if [ "$$deploy_type" = "computer" ]; then \
# 		echo "computer"; \
# 	else \
# 		echo "user"; \
# 	fi

set-user-deploy-type:
	mkdir ~/applescript-core
	cp -n plist.template ~/applescript-core/session.plist || true
	$$(plutil -replace '[app-core] Deployment Type - LOV Selected' -string 'user' ~/applescript-core/session.plist);
	echo "Deployment type changed to 'user-scope'"


set-computer-deploy-type:
	mkdir ~/applescript-core
	cp -n plist.template ~/applescript-core/session.plist || true
	plutil -replace '[app-core] Deployment Type - LOV Selected' -string 'computer' ~/applescript-core/session.plist
	echo "Deployment type changed to 'computer-scope'"


detect-deploy-type:  # Detects actual deployment type
	./scripts/detect-deployment-type.sh


uninstall:
	./scripts/uninstall.sh