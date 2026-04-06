# Makefile.user.mk

USE_SUDO ?= false
APPS_PATH := $(HOME)/Applications
SCRIPT_LIBRARY_PATH := "$(HOME)/Library/Script\ Libraries"

include Makefile.core.mk
include Makefile.test.mk
include Makefile.extra.mk
