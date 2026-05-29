# Makefile.test.mk
# Created: Tue, Jul 16, 2024 at 10:27:13 AM
#
# @NOTE:
# 	Make sure scripts for testing are already built.
# 	WARNING: Some applications (Terminal) being tested will be **TERMINATED**
# 	and not re-opened.  (Script Editor will prompt if there are unsaved changes.)
#
# @Change Logs:
# 	Tue, Apr 07, 2026, at 01:17:41 PM - Cleaned up references to apps.


build-test:
	yes | mkdir -p $(SCRIPT_LIBRARY_PATH)/core/test
	yes | ./scripts/build-lib.sh  test/xml-util
.PHONY: build-test


reveal-test-utils:
	open "$(SCRIPT_LIBRARY_PATH)/core/test"

test-all: test-unit
# 	osascript "test/Test Loader.applescript"  # This runs scripts disregarding the context.


test: test-all
.PHONY: test


test-unit:
	osascript "test/libs/Test log4as.applescript"
	osascript "test/core/Test date-time.applescript"
	osascript "test/core/Test decorator.applescript"
	osascript "test/core/Test file.applescript"
	osascript "test/core/Test list.applescript"
	osascript "test/core/Test lov.applescript"
	osascript "test/core/Test map.applescript"
	osascript "test/core/Test plist-buddy.applescript"
	osascript "test/core/Test plutil.applescript"
	osascript "test/core/Test property-list.applescript"
	osascript "test/core/Test regex.applescript"
	osascript "test/core/Test regex-pattern.applescript"
# 	osascript "test/core/Test speech.applescript" # For Review
	osascript "test/core/Test stack.applescript"
	osascript "test/core/Test string.applescript"
	osascript "test/core/Test switch.applescript"
	osascript "test/core/Test string.applescript"
	osascript "test/core/Test timed-cache-plist.applescript"


watch-test: watch-unit

watch-unit: test-unit
	scripts/run-tests_on-change.sh  # This runs test-unit target on change.


spot:  # Test single script here.
# 	osascript "test/core/Test date-time.applescript"
# 	osascript "test/core/Test decorator.applescript"
# 	osascript "test/core/Test file.applescript"
# 	osascript "test/core/Test list.applescript"
# 	osascript "test/libs/Test log4as.applescript"
# 	osascript "test/core/Test plutil.applescript"
# 	osascript "test/core/Test property-list.applescript"
# 	osascript "test/core/Test speech.applescript"
	osascript "test/core/Test string.applescript"
# 	osascript "test/core/Test timed-cache-plist.applescript"

watch-spot: spot
# 	scripts/run-spot_on-change.sh
	scripts/run-spot-test_on-change.sh

