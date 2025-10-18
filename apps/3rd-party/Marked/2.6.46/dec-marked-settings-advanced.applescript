(*
	@Purpose:


	@Conventions:
		If reading values, the tab must already be focused, else it will return the default null value.
		When writing values, like for checkboxes, tab switching will be performed automatically, but settings window must already be present.


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-settings-advanced

	@Created: Mon, May 26, 2025 at 10:56:22 AM
	@Last Modified: 2025-10-11 09:03:04
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Switch Settings:Advanced: Processor
		Manual: Switch Settings:Advanced: Enable Custom Preprocessor: ON
		Manual: Switch Settings:Advanced: Enable Custom Preprocessor: OFF
		Manual: Switch Settings:Advanced: Preprocessor: Set Path

		Manual: Switch Settings:Advanced: Preprocessor: Set Args
		Manual: Switch Settings:Advanced: Enable Custom Preprocessor: ON
		Manual: Switch Settings:Advanced: Enable Custom Preprocessor: OFF
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/marked"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Advanced: Selected Processor: {}", sut's getAdvancedSelectedProcessor())
	logger's infof("Advanced: Preprocessor: Path: {}", sut's getPreprocessorPath())
	logger's infof("Advanced: Preprocessor: Cache hosted images: {}", sut's isCacheHostedImages())
	logger's infof("Advanced: Enable Custom Preprocessor: {}", sut's isEnableCustomPreprocessor())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		set sutProcessor to "Unicorn"
		set sutProcessor to "Preprocessor"
		-- set sutProcessor to "Custom Processor"
		logger's infof("sutProcessor: {}", sutProcessor)

		sut's switchSettingsAdvancedProcessor(sutProcessor)

	else if caseIndex is 3 then
		sut's setEnableCustomPreprocessorOn()

	else if caseIndex is 4 then
		sut's setEnableCustomPreprocessorOff()

	else if caseIndex is 5 then
		set configLib to script "core/config"
		set configUser to configLib's new("user")
		set CONFIG_KEY_DOCS_PATH to "iCloud Documents Path"
		set documentsPath to configUser's getValue(CONFIG_KEY_DOCS_PATH)
		set fileUtil to script "core/file"
		set documentsFullPath to fileUtil's expandTildePath(documentsPath)
		logger's debugf("documentsFullPath: {}", documentsFullPath)

		set sutPath to "Unicorn"
		set sutPath to documentsFullPath & "/scripts/bash/run_docker_preprocessor.sh"
		logger's debugf("sutPath: {}", sutPath)

		sut's setPreprocessorPath(sutPath)

	else if caseIndex is 6 then
		set sutArgs to "Unicorn"
		set sutArgs to "MAC21,6.21.1"
		logger's debugf("sutArgs: {}", sutArgs)

		sut's setPreprocessorArgs(sutArgs)

	else if caseIndex is 7 then
		sut's setCacheHostedImagesOn()

	else if caseIndex is 8 then
		sut's setCacheHostedImagesOff()

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()

	script MarkedSettingsAdvancedDecorator
		property parent : mainScript

		(*
			@returns "Custom Processor","Preprocessor", or missing value when Advanced tab is not focused.
		*)
		on getAdvancedSelectedProcessor()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value
			if getSettingsSelectedTabName() is not equal to "Advanced" then return missing value

			tell application "System Events" to tell process "Marked 2"
				try
					return title of first radio button of tab group 1 of settingsWindow whose value is 1
				end try
			end tell

			missing value
		end getAdvancedSelectedProcessor


		on switchSettingsAdvancedProcessor(tabName)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			if getSettingsSelectedTabName() is not equal to "Advanced" then
				switchSettingsTab("Advanced")
			end if

			tell application "System Events" to tell process "Marked 2"
				try
					click (first radio button of tab group 1 of settingsWindow whose title is tabName)
				end try
			end tell
		end switchSettingsAdvancedProcessor


		on isEnableCustomPreprocessor()
			_isSettingsTabbedCheckboxChecked("Advanced", "Enable Custom Preprocessor")
		end isEnableCustomPreprocessor

		on setEnableCustomPreprocessorOn()
			if not isEnableCustomPreprocessor() then _toggleSettingsTabbedCheckbox("Advanced", "Enable Custom Preprocessor")
		end setEnableCustomPreprocessorOn

		on setEnableCustomPreprocessorOff()
			if isEnableCustomPreprocessor() then _toggleSettingsTabbedCheckbox("Advanced", "Enable Custom Preprocessor")
		end setEnableCustomPreprocessorOff


		on getPreprocessorPath()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			if getSettingsSelectedTabName() is not equal to "Advanced" then return missing value
			if getAdvancedSelectedProcessor() is not equal to "Preprocessor" then return missing value

			tell application "System Events" to tell process "Marked 2"
				try
					return value of first text field of tab group 1 of window "Advanced" whose help contains "path"
				end try
			end tell

			missing value
		end getPreprocessorPath



		on setPreprocessorPath(newPath)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			if getSettingsSelectedTabName() is not equal to "Advanced" then
				switchSettingsTab("Advanced")
			end if
			if getAdvancedSelectedProcessor() is not equal to "Preprocessor" then
				switchSettingsAdvancedProcessor("Preprocessor")
			end if

			tell application "System Events" to tell process "Marked 2"
				set pathTextField to the first text field of tab group 1 of window "Advanced" whose help contains "path"
				try
					set focused of pathTextField to true
					set value of pathTextField to newPath
					set frontmost to true
					kb's pressKey(return)
				end try
			end tell

			missing value
		end setPreprocessorPath


		on setPreprocessorArgs(newPath)
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			if getSettingsSelectedTabName() is not equal to "Advanced" then
				switchSettingsTab("Advanced")
			end if
			if getAdvancedSelectedProcessor() is not equal to "Preprocessor" then
				switchSettingsAdvancedProcessor("Preprocessor")
			end if

			tell application "System Events" to tell process "Marked 2"
				set pathTextField to the first text field of tab group 1 of window "Advanced" whose help contains "Additional arguments"
				try
					set focused of pathTextField to true
					set value of pathTextField to newPath
				end try
			end tell

			missing value
		end setPreprocessorArgs


		on isCacheHostedImages()
			_isSettingsCheckboxChecked("Advanced", "Cache hosted images")
		end isCacheHostedImages

		on setCacheHostedImagesOn()
			if not isCacheHostedImages() then _toggleSettingsCheckbox("Advanced", "Cache hosted images")
		end setCacheHostedImagesOn

		on setCacheHostedImagesOff()
			if isCacheHostedImages() then _toggleSettingsCheckbox("Advanced", "Cache hosted images")
		end setCacheHostedImagesOff


		on triggerRefresh()
			set settingsWindow to getSettingsWindow()
			if settingsWindow is missing value then return missing value

			tell application "System Events" to tell process "Marked 2"
				click button "Refresh" of settingsWindow
			end tell
		end triggerRefresh

	end script
end decorate
