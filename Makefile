# Makefile

OS_NAME := $(shell osascript -e "system version of (system info)" \
| cut -d '.' -f 1 \
| awk '{if ($$1 ~ /^14/) print "sonoma"; else if ($$1 ~ /^13/) print "ventura"; else if ($$1 ~ /^12/) print "monterey"; else print "unknown"}')

GET_DEPLOY_SCRIPT := ./scripts/get-deploy-type.sh
DEPLOY_TYPE := $(shell $(GET_DEPLOY_SCRIPT))

list-targets:
	@awk '/^[a-zA-Z][^:]*:$$/' $(MAKEFILE_LIST) | sed 's/:.*//'
.PHONY: list-targets


help:
	@echo "make install - Create config files, assets, and install essential libraries."

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
