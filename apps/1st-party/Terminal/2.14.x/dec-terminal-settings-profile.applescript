(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-settings-profile

	@Created: Mon, Jun 02, 2025 at 06:32:28 AM
	@Last Modified: Mon, Jun 02, 2025 at 06:32:28 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Switch profiles tab
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
	set sutLib to script "core/terminal"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script TerminalSettingsProfileDecorator
		property parent : mainScript

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
