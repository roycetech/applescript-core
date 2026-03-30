# Makefile.app-common.mk
# @Created: Mon, Mar 09, 2026, at 08:47:53 AM
# @Description:
# 	Contains the common app scripts for 1st and 3rd party apps.

build-base-app:
	@echo "\nBuilding Base App scripts..."
	$(call _build-script,apps/base-app)
	$(call _build-script,apps/abstract-app-with-file-dialog)
	@echo "Build Base App scripts completed\n"


# @1 - App name
# @2 - folder to build the scripts from
_build-app-scripts = \
	@echo "Building $(1) scripts..."; \
	find "$(2)" -maxdepth 1 -type f -name '*.applescript' -print0 \
	| while IFS= read -r -d '' file; do \
		echo "Building $$file"; \
		no_ext=$${file%.applescript}; \
		yes y | ./scripts/build-lib.sh "$$no_ext"; \
	done; \
	echo "Build $(1) scripts completed\n";
