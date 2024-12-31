(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_desktop-and-dock'

	@Created: Sun, Dec 22, 2024 at 2:00:54 PM
	@Last Modified: 
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use processLib : script "core/process"
use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

property PANE_ID_DESKTOP_AND_DOCK : "com.apple.Desktop-Settings.extension"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal Desktop and Dock
		Manual: Set Prefer Tabs When Opening Documents
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
		sut's revealDesktopAndDock()
		
	else if caseIndex is 3 then
		set sutPreference to "unicorn"
		set sutPreference to "Never"
		set sutPreference to "Always"
		-- set sutPreference to "In Full Screen"
		
		sut's setPreferTabsWhenOpeningDocuments(sutPreference)
	else if caseIndex is 4 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script SystemSettingsDesktopAndDockDecorator
		property parent : mainScript
		
		on revealDesktopAndDock()
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Settings"
				reveal pane id PANE_ID_DESKTOP_AND_DOCK
			end tell
			
			return
			set retry to retryLib's new()
			script DisplaysWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Displays") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealDesktopAndDock
		
		
		(*
			Desktop and Dock pane must already be active.
		
			@preferenceType - Always, Never, In Full Screen
		*)
		on setPreferTabsWhenOpeningDocuments(preferenceType)
			tell application "System Events" to tell process "System Settings"
				set frontmost to true
				delay 0.1
				set sutPopup to pop up button 1 of group 8 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window
				click sutPopup
				delay 0.1
				try
					click menu item preferenceType of menu 1 of sutPopup
				on error the errorMessage number the errorNumber
					log errorMessage
					kb's pressKey("escape")
				end try
			end tell
		end setPreferTabsWhenOpeningDocuments
	end script
end decorate
