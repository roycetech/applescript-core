(*
	This is built for the standalone version (non-Setapp)

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/marked

	@Migrated: Mon, May 26, 2025 at 08:05:41 AM
	@Last Modified: 2025-10-13 07:32:20
*)

use std : script "core/std"

use fileUtil : script "core/file"

use loggerFactory : script "core/logger-factory"

use configLib : script "core/config"
use markedTabLib : script "core/marked-tab"

use decoratorSettings : script "core/dec-marked-settings"
use decoratorScrolling : script "core/dec-marked-scrolling"
use decoratorSettingsGeneral : script "core/dec-marked-settings-general"
use decoratorSettingsPreview : script "core/dec-marked-settings-preview"
use decoratorSettingsApps : script "core/dec-marked-settings-apps"
use decoratorSettingsAdvanced : script "core/dec-marked-settings-advanced"
use decoratorMenu : script "core/dec-marked-menu"

use decoratorLib : script "core/decorator"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set configSystem to configLib's new("system")

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Open File - Not Running
		Open File - Running
		Open File - Running - No document
		Focus Doc - Manual

		Get Front Tab - Manual (Test Zoomed and non Zoomed)
		Manual: Find Tab With Name
		Manual: Close Tab
		Open File - Free Style 1-2s
		Open File Asynchronous

		Manual: Show Settings
		Manual: Set Preprocess Arguments (Deprecated)
		Dummy
		Dummy
		Dummy

		Dummy
	")

	set examplesPath to configSystem's getValue("AppleScript Core Project Path") & "/apps/3rd-party/Marked"
	set testFile1 to examplesPath & "/example-1.md"
	set testFile2 to examplesPath & "/example-2.md"

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	-- logger's infof("Settings window presence: {}", sut's isSettingsWindowPresent())
	logger's infof("Has tab bar: {}", sut's hasTabBar())
	logger's infof("Integration: Settings window present: {}", sut's isSettingsWindowPresent())

	if caseIndex is 1 then
		set markedTab to sut's getFrontTab()
		if markedTab is missing value then
			logger's info("Front tab was not found")
		else
			logger's info("Front tab was found")
			logger's infof("Document Name: {}", markedTab's getDocumentName())
		end if

	else if caseIndex is 2 then
		tell application "Marked 2" to quit
		delay 1
		set macTab to sut's openFile(testFile1)
		logger's infof("Open file: {}", name of macTab)

	else if caseIndex is 3 then
		tell application "Marked 2" to quit
		delay 2 -- 1s failed.
		activate application "Marked 2"
		delay 1
		tell application "Marked 2" to close every window

		set markedTab1 to sut's openFile(testFile1)
		logger's infof("Open file: {}", markedTab1's getDocumentName())
		set markedTab2 to sut's openFile(testFile2)
		logger's infof("Open file: {}", markedTab2's getDocumentName())

	else if caseIndex is 4 then
		tell application "Marked 2" to quit
		delay 1
		activate application "Marked 2"
		delay 1
		tell application "Marked 2" to close every window

		set markedTab1 to sut's openFile(testFile1)
		logger's infof("Open file: {}", markedTab1's getDocumentName())

	else if caseIndex is 5 then
		tell application "Marked 2" to quit
		delay 1
		activate application "Marked 2"
		delay 1
		tell application "Marked 2" to close every window

		set markedTab1 to sut's openFile(testFile1) -- Safari
		set markedTab2 to sut's openFile(testFile2) -- ST
		markedTab1's focus() -- Manually Switch
		markedTab2's focus()
		logger's infof("Open file: {}", markedTab1's getDocumentName())

	else if caseIndex is 6 then
		set frontTab to sut's getFrontTab()
		if frontTab is missing value then
			logger's info("No window found")

		else
			logger's infof("Open document name: {}", frontTab's getDocumentName())
		end if

	else if caseIndex is 7 then
		set mdTab to sut's findTabWithName("Safari-general.md")
		assertThat of std given condition:mdTab is not missing value, messageOnFail:"Expected found but missing"

		set mdTabMissing to sut's findTabWithName("Safari-general.mdx")
		assertThat of std given condition:(mdTabMissing is missing value), messageOnFail:"Expected missing but present"
		logger's info("Passed.")

	else if caseIndex is 8 then
		set mdTab to sut's findTabWithName("example-2.md")
		if mdTab is not missing value then mdTab's closeTab()

	else if caseIndex is 9 then
		sut's openFile(testFile2)

	else if caseIndex is 10 then
		sut's openFileAsync(testFile2)

	else if caseIndex is 11 then
		sut's showSettings()

	else if caseIndex is 12 then
		set markdownTab to sut's getFrontTab()
		markdownTab's setPreprocessorArguments("1234")


	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)

	script MarkedInstance
		on hasTabBar()
			if running of application "Marked 2" is false then return false

			tell application "System Events" to tell process "Marked 2"
				exists tab group "tab bar" of front window
			end tell
		end hasTabBar

		on startInspection()
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				set frontmost to true
				set htmlContent to UI element 1 of scroll area 1 of group 1 of front window
				perform action 1 of htmlContent
				delay 0.1
				click menu item "Inspect Element" of menu 1 of htmlContent
				delay 0.4 -- 0.2 failed last time.
				click (first button of UI element 1 of scroll area 1 of front window whose description starts with "Start element selection")
			end tell
		end startInspection

		on stopInspection()
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				try
					click (first button of (first window whose title starts with "Web Inspector") whose description is "close button")
				end try
			end tell
		end stopInspection


		(*
			Would it be faster if we use MON?
			@returns true if the operation completes without issues.
		*)
		on openFileAsync(posixFilePath)
			if not fileUtil's posixFilePathExists(posixFilePath) then return missing value

			if running of application "Marked 2" is false then
				activate application "Marked 2"
				delay 0.1
				tell application "Marked 2" to close every window
			end if

			set initialWinCount to _getSysEveWindowCount()
			set isFirstWindow to initialWinCount is 0
			if not isFirstWindow then set frontMarkedTab to getFrontTab()

			tell application "Marked 2"
				ignoring application responses
					open posixFilePath
				end ignoring
			end tell
		end openFileAsync

		(*
			Would it be faster if we use MON?
			@returns true if the operation completes without issues.
		*)
		on openFile(posixFilePath)
			if not fileUtil's posixFilePathExists(posixFilePath) then return missing value

			if running of application "Marked 2" is false then
				activate application "Marked 2"
				delay 0.1
				tell application "Marked 2" to close every window
			end if

			set initialWinCount to _getSysEveWindowCount()
			set isFirstWindow to initialWinCount is 0
			if not isFirstWindow then set frontMarkedTab to getFrontTab()

			tell application "Marked 2"
				open posixFilePath
				delay 0.1
				set tabInstance to markedTabLib's new(front window)
			end tell

			set newWinCount to _getSysEveWindowCount()
			if newWinCount is 2 then
				frontMarkedTab's focus()

				mergeWindows()
			end if
			tabInstance's focus()

			tabInstance
		end openFile


		on getFrontTab()
			if running of application "Marked 2" is false then return missing value
			if _getSysEveWindowCount() is 0 then return missing value

			tell application "Marked 2"
				try
					return markedTabLib's new(front window)
				on error
					missing value
				end try
			end tell
		end getFrontTab


		(*
			@Known Issues:
				Application keeps reference to closed windows, we need to use System Events instead to check actual windows.
		*)
		on findTabWithName(documentName)
			if running of application "Marked 2" is false then return missing value

			tell application "System Events" to tell process "Marked 2"
				-- if (count of (windows whose name contains documentName)) is 0 then return missing value
				if (count of windows) is 0 then return missing value
			end tell

			try
				tell application "Marked 2"
					-- set appWindow to first window whose name is documentName
					set appWindow to first window whose name contains documentName
				end tell
			on error
				return missing value
			end try
			markedTabLib's new(appWindow)
		end findTabWithName


		on showCustomProcessorLog()
			if running of application "Marked 2" is false then return missing value

			tell application "System Events" to tell process "Marked 2"
				set frontmost to true
				try
					click menu item "Show Custom Processor Log" of menu 1 of menu bar item "Help" of menu bar 1
				end try
			end tell
		end showCustomProcessorLog


		(*
			@Requires app focus.
		*)
		on mergeWindows()
			if running of application "Marked 2" is false then return

			tell application "System Events" to tell process "Marked 2"
				set frontmost to true

				repeat
					click menu item "Merge All Windows" of menu 1 of menu bar item "Window" of menu bar 1
					if (count of windows) is 1 then exit repeat
					delay 0.1
				end repeat
			end tell
		end mergeWindows

		-- Private Codes below =======================================================

		on _getSysEveWindowCount()
			tell application "System Events" to tell process "Marked 2"
				count of windows
			end tell
		end _getSysEveWindowCount
	end script

	decoratorSettings's decorate(result)
	decoratorScrolling's decorate(result)
	decoratorSettingsGeneral's decorate(result)
	decoratorSettingsPreview's decorate(result)
	decoratorSettingsApps's decorate(result)
	decoratorSettingsAdvanced's decorate(result)
	decoratorMenu's decorate(result)

	set decorator to decoratorLib's new(result)
	decorator's decorateByName("MarkedInstance")
end new
