(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/26.3/dec-system-settings_general_about'

	@Created: Wed, Feb 18, 2026 at 11:17:06 AM
	@Last Modified: Wed, Feb 18, 2026 at 11:17:06 AM
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
		Manual: Trigger Subpane about
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
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Storage text: {}", sut's getStorageText())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerSubPaneAbout()
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SystemSettingsGeneralAboutDecorator
		property parent : mainScript
		
		on triggerSubPaneAbout()
			set outlineUi to getRightPaneScrollArea()
			if outlineUi is missing value then
				logger's fatal("Outline UI was not found.")
				return
			end if
			
			tell application "System Events" to tell process "System Settings"
				click of button 1 of group 2 of outlineUi
			end tell
		end triggerSubPaneAbout
		
		
		on getStorageText()
			set outlineUi to getRightPaneScrollArea()
			if outlineUi is missing value then
				logger's fatal("Outline UI was not found.")
				return
			end if
			
			tell application "System Events" to tell process "System Settings"
				try
					return value of static text 2 of group 5 of outlineUi
				end try
			end tell
			
			missing value
		end getStorageText
	end script
end decorate
