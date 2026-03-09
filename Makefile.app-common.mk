# Makefile.app-common.mk
# @Created: Mon, Mar 09, 2026, at 08:47:53 AM
# @Description:
# 	Contains the common app scripts for 1st and 3rd party apps.

build-base-app:
	@echo "\nBuilding Base App scripts..."
	$(call _build-script,apps/base-app)
	$(call _build-script,apps/abstract-app-with-file-dialog)
	@echo "Build Base App scripts completed\n"
