# Makefile.global.mk

USE_SUDO ?= true
APPS_PATH := /Applications
SCRIPT_LIBRARY_PATH := "/Library/Script\ Libraries"

include Makefile.core.mk
include Makefile.app1.mk
include Makefile.app3.mk
include Makefile.test.mk
include Makefile.extra.mk
