(*
	NOTE:
		Checkboxes with similar title works across tabs is the Profiles settings.
		Implementation is limited to options I personally use.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings

	@Created: Monday, December 23, 2024 at 6:55:56 AM
	@Last Modified: 2024-12-31 19:32:03
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
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Show Settings
		Manual: Close Settings
		Manual: Set new window profile
		Manual: Switch settings tab

		Manual: Switch profiles tab
		Manual: Toggle Dimension Off
		Manual: Toggle Dimension On
		Manual: Toggle Active Process Name Off
		Manual: Toggle Active Process Name On

		Manual: Toggle Working Directory or Document Off
		Manual: Toggle Use Option as Meta key On
		Manual: Toggle Use Option as Meta key Off
		Manual: Set Default Profile
		Manual: Set Selected Profile

		Manual: Iterate Profiles
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/terminal"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Settings dialog present: {}", sut's isSettingsWindowPresent())

	logger's infof("Window dimensions toggled: {}", sut's isDimensionsOn())
	logger's infof("Shared Active process name toggled: {}", sut's isActiveProcessNameOn())
	logger's infof("Shared Working directory or document toggled: {}", sut's isWorkingDirectoryOrDocumentOn())
	logger's infof("Keyboard: Option key is meta key: {}", sut's isUseOptionAsMetaKeyOn())
	logger's infof("Selected Profile: {}", sut's getSelectedProfile())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showSettingsWindow()

	else if caseIndex is 3 then
		sut's closeSettingsWindow()

	else if caseIndex is 4 then
		set profileTitle to "Unicorn"
		set profileTitle to "Pro"

		sut's setNewWindowProfile(profileTitle)

	else if caseIndex is 5 then
		set settingsTitle to "Unicorn"
		set settingsTitle to "General"
		set settingsTitle to "Profiles"

		sut's switchSettingsTab(settingsTitle)

	else if caseIndex is 6 then
		set profileTabTitle to "Unicorn"
		set profileTabTitle to "Window"
		-- 		set profileTabTitle to "Tab"
		-- 		set profileTabTitle to "Keyboard"

		sut's switchProfilesTab(profileTabTitle)

	else if caseIndex is 7 then
		sut's setDimensionsOff()

	else if caseIndex is 8 then
		sut's setDimensionsOn()

	else if caseIndex is 9 then
		sut's setActiveProcessNameOff()

	else if caseIndex is 10 then
		sut's setActiveProcessNameOn()

	else if caseIndex is 11 then
		sut's setWorkingDirectoryOrDocumentOff()

	else if caseIndex is 12 then
		sut's setUseOptionAsMetaKeyOn()

	else if caseIndex is 13 then
		sut's setUseOptionAsMetaKeyOff()

	else if caseIndex is 14 then
		set sutProfile to "Unicorn"
		set sutProfile to "Pro"

		sut's setDefaultProfile(sutProfile)

	else if caseIndex is 15 then
		set sutProfile to "Unicorn"
		set sutProfile to "Basic"
		-- set sutProfile to "Pro"

		sut's setSelectedProfile(sutProfile)
		logger's infof("Handler result: {}", result)

	else if caseIndex is 16 then
		sut's switchSettingsTab("Profiles")
		script ProfileNamePrinter
			on execute(nextRow)
				tell application "System Events"
					logger's infof("Profile name: {}", value of text field 1 of nextRow)
				end tell
			end execute
		end script
		sut's iterateProfiles(result)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set kb to kbLib's new()

	script TerminalSettingsDecorator
		property parent : mainScript

		on showSettingsWindow()
			if running of application "Terminal" is false then return

			tell application "System Events" to tell process "Terminal"
				try
					click (first menu item of menu 1 of menu bar item "Terminal" of menu bar 1 whose title starts with "Setting")
				end try
			end tell
		end showSettingsWindow

		on isSettingsWindowPresent()
			if running of application "Terminal" is false then return false

			tell application "System Events" to tell process "Terminal"
				return exists (first window whose description is "dialog")
			end tell

			false
		end isSettingsWindowPresent

		on closeSettingsWindow()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click (first button of settingsWindow whose role description is "close button")
				on error
					return
				end try
			end tell
		end closeSettingsWindow

		on setNewWindowProfile(profileTitle)
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				set newWindowProfilePopup to pop up button 1 of group 1 of settingsWindow
				click newWindowProfilePopup
				delay 0.1
				try
					click menu item profileTitle of menu 1 of newWindowProfilePopup
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					kb's pressKey("esc")
				end try
			end tell
		end setNewWindowProfile

		on switchSettingsTab(tabTitle)
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				try
					set settingsWindow to first window whose description is "dialog"
				on error
					return
				end try

				try
					click button tabTitle of toolbar 1 of settingsWindow
				end try
			end tell
		end switchSettingsTab

		on switchProfilesTab(profilesTabTitle)
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click radio button profilesTabTitle of tab group 1 of group 1 of window 1
				end try
			end tell
		end switchProfilesTab


		on toggleDimensions()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Dimensions" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleDimensions

		(* Need to have the settings dialog present and the Windows tab active *)
		on isDimensionsOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Dimensions" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell

			false
		end isDimensionsOn

		on setDimensionsOn()
			if not isDimensionsOn() then toggleDimensions()
		end setDimensionsOn

		on setDimensionsOff()
			if isDimensionsOn() then toggleDimensions()
		end setDimensionsOff


		on toggleActiveProcessName()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Active process name" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleActiveProcessName

		(* Need to have the settings dialog present and the Windows tab active *)
		on isActiveProcessNameOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Active process name" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell

			false
		end isActiveProcessNameOn

		on setActiveProcessNameOn()
			if not isActiveProcessNameOn() then toggleActiveProcessName()
		end setActiveProcessNameOn

		on setActiveProcessNameOff()
			if isActiveProcessNameOn() then toggleActiveProcessName()
		end setActiveProcessNameOff


		on toggleWorkingDirectoryOrDocument()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Working directory or document" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleWorkingDirectoryOrDocument

		(* Need to have the settings dialog present and the Windows tab active *)
		on isWorkingDirectoryOrDocumentOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Working directory or document" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell

			false
		end isWorkingDirectoryOrDocumentOn

		on setWorkingDirectoryOrDocumentOn()
			if not isWorkingDirectoryOrDocumentOn() then toggleWorkingDirectoryOrDocument()
		end setWorkingDirectoryOrDocumentOn

		on setWorkingDirectoryOrDocumentOff()
			if isWorkingDirectoryOrDocumentOn() then toggleWorkingDirectoryOrDocument()
		end setWorkingDirectoryOrDocumentOff


		(* Under Profiles > Keyboard Subtab *)
		on isUseOptionAsMetaKeyOn()
			if running of application "Terminal" is false then return false
			if not isSettingsWindowPresent() then return false

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return (value of checkbox "Use Option as Meta key" of tab group 1 of group 1 of settingsWindow) is 1
				end try
			end tell

			false
		end isUseOptionAsMetaKeyOn

		on toggleUseOptionAsMetaKey()
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					click checkbox "Use Option as Meta key" of tab group 1 of group 1 of settingsWindow
				end try
			end tell
		end toggleUseOptionAsMetaKey

		on setUseOptionAsMetaKeyOn()
			if not isUseOptionAsMetaKeyOn() then toggleUseOptionAsMetaKey()
		end setUseOptionAsMetaKeyOn

		on setUseOptionAsMetaKeyOff()
			if isUseOptionAsMetaKeyOn() then toggleUseOptionAsMetaKey()
		end setUseOptionAsMetaKeyOff


		on setDefaultProfile(profileName)
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					set selected of (first row of table 1 of scroll area 1 of group 1 of settingsWindow whose value of text field 1 is profileName) to true
					click button "Default" of group 1 of front window
				end try
			end tell
		end setDefaultProfile


		on getSelectedProfile()
			if running of application "Terminal" is false then return missing value
			if not isSettingsWindowPresent() then return missing value

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					return value of text field 1 of (first row of table 1 of scroll area 1 of group 1 of settingsWindow whose selected is true)
				end try
			end tell

			missing value
		end getSelectedProfile

		(* @return true - if profile was set without error. *)
		on setSelectedProfile(profileName)
			if running of application "Terminal" is false then return missing value
			if not isSettingsWindowPresent() then return missing value

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				try
					set selected of (first row of table 1 of scroll area 1 of group 1 of front window whose value of text field 1 is profileName) to true
					return true
				end try
			end tell

			false
		end setSelectedProfile


		on iterateProfiles(scriptObject)
			if running of application "Terminal" is false then return
			if not isSettingsWindowPresent() then return

			tell application "System Events" to tell process "Terminal"
				set settingsWindow to first window whose description is "dialog"
				repeat with nextRow in rows of table 1 of scroll area 1 of group 1 of settingsWindow
					scriptObject's execute(nextRow)
				end repeat
			end tell
		end iterateProfiles
	end script
end decorate
