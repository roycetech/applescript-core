# Makefile.test.mk
# Created: Tue, Jul 16, 2024 at 10:27:13 AM
#
# @NOTE:
# 	Make sure scripts for testing are already built.
# 	WARNING: Some applications (Terminal) being tested will be **TERMINATED**
# 	and not re-opened.  (Script Editor will prompt if there are unsaved changes.)
#
# @Change Logs:


build-test:
	yes | mkdir -p $(SCRIPT_LIBRARY_PATH)/core/test
	yes | ./scripts/build-lib.sh  test/terminal-util
	yes | ./scripts/build-lib.sh  test/script-editor-util
	yes | ./scripts/build-lib.sh  test/xml-util
.PHONY: build-test

reveal-test-utils:
	open /Library/Script\ Libraries/core/test


test-all: test-unit test-integration
# 	osascript "test/Test Loader.applescript"  # This runs scripts disregarding the context.


test: test-all
.PHONY: test


test-unit:
	osascript "test/libs/Test cliclick.applescript"
	osascript "test/libs/Test log4as.applescript"
	osascript "test/libs/Test redis.applescript"
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
	osascript "test/core/Test safari-javascript.applescript"
# 	osascript "test/core/Test speech.applescript" # For Review
	osascript "test/core/Test stack.applescript"
	osascript "test/core/Test string.applescript"
	osascript "test/core/Test switch.applescript"
	osascript "test/core/Test string.applescript"
	osascript "test/apps/3rd-party/Test keyboard-maestro.applescript"
	osascript "test/core/Test timed-cache-plist.applescript"


test-integration:
# 	osascript "test/core/Test dec-terminal-path.applescript"

	osascript -e 'quit application "Keyboard Maestro Engine"'

# ifneq ($(OMZ_EXISTS),)
# 	osascript "test/core/Test dec-terminal-prompt-omz.applescript"
# else
# 	osascript "test/core/Test dec-terminal-prompt.applescript"
# endif

	osascript "test/apps/1st-party/Test script-editor.applescript"
	osascript "test/apps/1st-party/Test dec-script-editor-content.applescript"
	open -a "Keyboard Maestro Engine"

watch: watch-unit

watch-unit: test-unit
	scripts/run-tests_on-change.sh  # This runs test-unit target on change.

watch-integration: test-integration
	scripts/run-integration-tests_on-change.sh  # This runs test-unit target on change.

spot:  # Test single script here.
# 	osascript 'apps/3rd-party/Google Chrome/131.0/dec-google-chrome-tab-finder.applescript'
# 	osascript "test/core/Test file.applescript"
# 	osascript "test/libs/Test redis.applescript"
# 	osascript "test/core/Test date-time.applescript"
# 	osascript "test/core/Test dec-terminal-path.applescript"
ifneq ($(OMZ_EXISTS),)
	osascript "test/core/Test dec-terminal-prompt-omz.applescript"
else
	osascript "test/core/Test dec-terminal-prompt.applescript"
endif
# 	osascript "test/core/Test string.applescript"
# 	osascript "test/apps/1st-party/Test script-editor.applescript"
# 	osascript "test/apps/1st-party/Test dec-script-editor-content.applescript"
# 	osascript "test/libs/Test log4as.applescript"
# 	osascript "test/core/Test date-time.applescript"
# 	osascript "test/core/Test speech.applescript"
# 	osascript "test/apps/3rd-party/Test keyboard-maestro.applescript"
# 	osascript "test/core/Test timed-cache-plist.applescript"
# 	osascript "test/apps/1st-party/Test finder.applescript"
# 	osascript "test/core/Test file.applescript"

spot-watch: spot
# 	scripts/run-spot_on-change.sh
	scripts/run-spot-test_on-change.sh

