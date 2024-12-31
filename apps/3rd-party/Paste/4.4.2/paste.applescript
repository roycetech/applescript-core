(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Paste/4.4.2/paste

	@Created: Tuesday, December 31, 2024 at 12:46:53 PM
	@Last Modified: 2024-12-31 15:47:45
*)
use scripting additions

use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP:
		Manual: Show Settings
		Manual: Switch Tab
		Manual: Set Open at Login On
		Manual: Set Open at Login Off

		Manual: Set iCloud Sync On
		Manual: Set iCloud Sync Off
		Manual: Close Settings
		Manual: Set Destination
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()

	logger's infof("Open at login: {}", sut's getOpenAtLogin())
	logger's infof("iCloud Sync: {}", sut's getIcloudSync())
	logger's infof("Paste destination: {}", sut's getPasteItemsDestination())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showSettings()

	else if caseIndex is 3 then
		set sutTabName to "Unicorn"
		set sutTabName to "Shortcuts"
		set sutTabName to "General"

		sut's switchTab(sutTabName)

	else if caseIndex is 4 then
		sut's setOpenAtLoginOn()

	else if caseIndex is 5 then
		sut's setOpenAtLoginOff()

	else if caseIndex is 6 then
		sut's setIcloudSyncOn()

	else if caseIndex is 7 then
		sut's setIcloudSyncOff()

	else if caseIndex is 8 then
		sut's closeSettings()

	else if caseIndex is 9 then
		set sutDestination to "unicorn"
		set sutDestination to "clipboard"
		set sutDestination to "active app"

		sut's setPasteItemsDestination(sutDestination)

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set retry to retryLib's new()

	script PasteInstance
		on showSettings()
			do shell script "open -a Paste.app"

			tell application "System Events" to tell process "Paste"
				click button 3 of window 1
				delay 0.1
				click (first menu item of menu 1 of button 3 of window 1 whose title starts with "Settings")
			end tell

			script WindowWaiter
				tell application "System Events" to tell process "Paste"
					if exists window 1 then return true
				end tell
			end script
			exec of retry on result for 3
		end showSettings

		on closeSettings()
			tell application "System Events" to tell process "Paste"
				click (first button of window 1 whose description is "close button")
			end tell
		end closeSettings

		on switchTab(vTabName)
			tell application "System Events" to tell process "Paste"
				-- properties of static text 1 of UI element 1 of row 3 of outline 1 of scroll area 1 of group 1 of splitter group 1 of window 1
				try
					first row of outline 1 of scroll area 1 of group 1 of splitter group 1 of window 1 whose name of static text 1 of UI element 1 is vTabName
					set selected of result to true
				end try
			end tell
		end switchTab

		on getOpenAtLogin()
			if running of application "Paste" is false then return false

			tell application "System Events" to tell process "Paste"
				try
					return value of checkbox 1 of group 1 of scroll area 1 of splitter group 1 of window 1 is 1
				end try
			end tell

			false
		end getOpenAtLogin


		on toggleOpenAtLogin()
			if running of application "Paste" is false then return false

			tell application "System Events" to tell process "Paste"
				try
					click checkbox 1 of group 1 of scroll area 1 of splitter group 1 of window 1
				end try
			end tell

			false
		end toggleOpenAtLogin


		on setOpenAtLoginOn()
			if not getOpenAtLogin() then toggleOpenAtLogin()
		end setOpenAtLoginOn


		on setOpenAtLoginOff()
			if getOpenAtLogin() then toggleOpenAtLogin()
		end setOpenAtLoginOff

		on getIcloudSync()
			if running of application "Paste" is false then return false

			tell application "System Events" to tell process "Paste"
				try
					return value of checkbox 2 of group 1 of scroll area 1 of splitter group 1 of window 1 is 1
				end try
			end tell
			false
		end getIcloudSync


		on toggleIcloudSync()
			if running of application "Paste" is false then return false

			tell application "System Events" to tell process "Paste"
				try
					click checkbox 2 of group 1 of scroll area 1 of splitter group 1 of window 1
				end try
			end tell
			false
		end toggleIcloudSync


		on setIcloudSyncOn()
			if not getIcloudSync() then toggleIcloudSync()
		end setIcloudSyncOn


		on setIcloudSyncOff()
			if getIcloudSync() then toggleIcloudSync()
		end setIcloudSyncOff


		on getPasteItemsDestination()
			if running of application "Paste" is false then return missing value

			tell application "System Events" to tell process "Paste"
				if value of radio button 1 of radio group 1 of group 1 of scroll area 1 of splitter group 1 of window 1 is 1 then
					return "active app"
				else if value of radio button 2 of radio group 1 of group 1 of scroll area 1 of splitter group 1 of window 1 is 1 then
					return "clipboard"
				end if
			end tell
			missing value
		end getPasteItemsDestination


		(* @destination - 'active app' or 'clipboard'. *)
		on setPasteItemsDestination(destination)
			tell application "System Events" to tell process "Paste"
				if destination is "active app" then
					click radio button 1 of radio group 1 of group 1 of scroll area 1 of splitter group 1 of window 1

				else if destination is "clipboard" then
					click radio button 2 of radio group 1 of group 1 of scroll area 1 of splitter group 1 of window 1

				end if
			end tell
		end setPasteItemsDestination
	end script
end new
