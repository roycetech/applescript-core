(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_displays'

	@Created: Saturday, September 21, 2024 at 11:47:11 AM
	@Last Modified: Saturday, September 21, 2024 at 11:47:11 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal Displays
		Manual: Switch display resolution
		Reset: Display resolution
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealDisplays()
		
	else if caseIndex is 3 then
		sut's switchDisplayResolution(5)
		
	else if caseIndex is 4 then
		sut's resetDisplayResolution()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SystemSettingsDisplaysDecorator
		property parent : mainScript
		
		on revealDisplays()
			if running of application "System Settings" is false then
				activate application "System Settings"
				delay 1
			end if
			
			tell application "System Settings"
				reveal pane id "com.apple.Displays-Settings.extension"
			end tell
			
			set retry to retryLib's new()
			script DisplaysWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Displays") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealDisplays
		
		
		on switchDisplayResolution(buttonIndex)
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				click button buttonIndex of UI element 1 of group 1 of scroll area 2 of group 1 of list 2 of splitter group 1 of list 1 of front window
			end tell
		end switchDisplayResolution
		
		
		on resetDisplayResolution()
			switchDisplayResolution(4)
		end resetDisplayResolution
	end script
end decorate
