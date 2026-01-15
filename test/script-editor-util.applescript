(*
	Utility for testing Script Editor app scripts.
	CAVEAT: It uses the script-editor.applescript to test itself to keep it simple.

	@Last Modified: 2026-01-15 13:37:09

	@Plists:
		config-user:
			Project applescript-core

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh test/script-editor-util

	@Created: Tue, Jan 06, 2026, at 09:05:20 AM
	@Change Logs:

*)
use scripting additions

use textUtil : script "core/string"

(*
	NOTE: This logger doesn't show logs during test runs. Stick to vanilla log
	when debugging during tests.
*)
use loggerFactory : script "core/logger-factory"

use scriptEditorTabLib : script "core/script-editor-tab"
use systemEventLib : script "core/system-events"
use dockLib : script "core/dock"

property logger : missing value

property scriptEditorTab : missing value
property systemEvent : missing value
property dock : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Launch Test Window
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()

	if caseIndex is 1 then
		set scriptEditorTab to sut's getTestingTab()
		logger's infof("Testing tab presence: {}", scriptEditorTab is not missing value)

	else if caseIndex is 2 then


	else if caseIndex is 3 then


	end if

	spot's finish()
	logger's finish()
end spotCheck



on new()
	loggerFactory's inject(me)
	set systemEvent to systemEventLib's new()
	set dock to dockLib's new()

	script ScriptEditorUtilInstance
		property TEST_TAB_NAME : "unit-test.scpt"

		property autoFocusWindow : false

		(* @returns ScriptEditorTabInstance *)
		on getTestingTab()
			tell application "Script Editor"
				if not (exists document (my TEST_TAB_NAME)) then
					make new document with properties {name:my TEST_TAB_NAME}
				else
					my focusTestTab()
				end if
				id of front window
			end tell

			scriptEditorTabLib's new(result)
		end getTestingTab


		on focusTestTab()
			tell application "System Events" to tell process "Script Editor"
				try
					click menu item (my TEST_TAB_NAME) of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end focusTestTab

		on _focusAsConfigured()
			if autoFocusWindow is true then
				tell application "System Events" to tell process "Script Editor"
					set frontmost to true
				end tell

			else if systemEvent's getFrontAppName() is not "Script Editor" then
				return
			end if
		end _focusAsConfigured


		on clearScript()
			_focusAsConfigured()

			writeScript("")
		end clearScript


		on writeScript(scriptText)
			_focusAsConfigured()

			tell application "Script Editor"
				set contents of document my TEST_TAB_NAME to scriptText
			end tell
		end writeScript


		on killApp()
			try
				do shell script "killall -9 \"Script Editor\""
			end try

			repeat until running of application "Script Editor" is false
				delay 0.5
			end repeat
		end killApp


		on launchAppViaDock()
			if running of application "Script Editor" is false then activate application "Script Editor"
			dock's clickFirstApp("Script Editor")
			set counter to 0
			repeat
				set counter to counter + 1
				if counter is 6 then
					-- let's try again.
					dock's clickFirstApp("Script Editor")
				end if

				delay 0.5
				if running of application "Script Editor" is true then
					tell application "System Events" to tell process "Script Editor"
						try
							if (the count of windows) is not 0 then exit repeat
						end try
					end tell
				end if
			end repeat

			tell application "System Events" to tell process "Script Editor"
				 set frontmost to true
			end tell
		end launchAppViaDock

		on quitApp()
			if running of application "Script Editor" then quit application "Script Editor"

			repeat until running of application "Script Editor" is false
				delay 0.2

				(* Probably better to not auto-delete and have the user take action manually. *)
				-- set saveDialogExists to false
				-- tell application "Script Editor"
				-- 	set saveDialogExists to exists(window "Save Panel Accessory View")
				-- end tell
				-- if saveDialogExists then
				-- 	tell application "System Events" to tell process "Script Editor"
				-- 		try
				-- 			click button "Delete" of splitter group 1 of sheet 1 of front window
				-- 			quit application "Script Editor"
				-- 		end try
				-- 	end tell
				-- end if

			end repeat
		end quitApp


		on quitAppViaDock()
			-- Using dock is a safe way to quit the Terminal app.
			-- Using quit command causes side effect, while pkill is a system level way to terminate a process.

			-- dock's triggerAppMenu("Script Editor", "Quit")

			-- repeat until running of application "Script Editor" is false
			-- 	delay 0.2

			-- 	tell application "System Events" to tell process "Script Editor"
			-- 		if exists button "Terminate" of sheet 1 of front window then
			-- 			click button "Terminate" of sheet 1 of front window
			-- 			delay 1
			-- 			try
			-- 				dock's triggerAppMenu("Script Editor", "Quit")
			-- 			end try
			-- 		end if
			-- 	end tell
			-- end repeat

			dock's triggerAppMenu("Script Editor", "Quit")
			repeat until running of application "Script Editor" is false
				delay 0.2
			end repeat
		end quitApp

		on closeTestingTab()
			-- TODO
			-- set scriptEditorTab to terminal's findTabByWindowNameSubstring(my TEST_TAB_NAME)
			-- if scriptEditorTab is missing value then return

			-- scriptEditorTab's closeTab()
		end closeTestingTab

		on getFrontAppName()
			tell application "System Events"
				set frontApp to first application process whose frontmost is true
				name of frontApp
			end tell
		end getFrontAppName

		on getFrontWindowTitle()
			tell application "System Events"
				set frontApp to first application process whose frontmost is true
				set frontAppName to name of frontApp
				tell process frontAppName
					1st window whose value of attribute "AXMain" is true
				end tell
				title of result
			end tell
		end getFrontWindowTitle

		(*
			@returns true if expected count was met.
		*)
		on waitWindowCount(expectedCount)
			set limit to 200
			set counter to 0
			tell application "Script Editor"
				repeat until (the number of windows) is expectedCount or counter is greater than limit
					set counter to counter + 1
					delay 0.2
				end repeat
			end tell
			counter is less than limit
		end waitWindowCount


		on getTrimmedContent()
			if running of application "Script Editor" is false then return missing value

			tell application "Script Editor"
				contents of document
				textUtil's rtrim(tabContents)
			end tell
		end getTrimmedContent
	end script
end new
