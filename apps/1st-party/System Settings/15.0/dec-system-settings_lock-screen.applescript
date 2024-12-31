(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_lock-screen'

	@Created: Fri, Dec 27, 2024 at 11:20:08 AM
	@Last Modified: 
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use processLib : script "core/process"

property logger : missing value
property PANE_ID_LOCK_SCREEN : "com.apple.Lock-Screen-Settings.extension"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal Lock Screen Pane
		Manual: Set Start Sreen Saver when inactive
		Manual: Turn display off on battery when inactive
		Manual: Turn display off on power adapter when inactive
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
	
	logger's infof("Start Screen Saver when inactive: {}", sut's getStartScreenSaverWhenInactive())
	logger's infof("Turn display off on battery when inactive: {}", sut's getTurnDisplayOffOnBatteryWhenInactive())
	logger's infof("Turn display off on power adapter when inactive: {}", sut's getTurnDisplayOffOnPowerAdapterWhenInactive())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealLockScreen()
		
	else if caseIndex is 3 then
		set sutMenuTitle to "Never"
		set sutMenuTitle to "For 2 minutes"
		
		sut's setStartScreenSaverWhenInactive(sutMenuTitle)
		logger's infof("Handler result: {}", result)
		
	else if caseIndex is 4 then
		set sutMenuTitle to "Never"
		set sutMenuTitle to "For 5 minutes"
		
		sut's setTurnDisplayOffOnBatteryWhenInactive(sutMenuTitle)
		logger's infof("Handler result: {}", result)
		
	else if caseIndex is 5 then
		set sutMenuTitle to "Never"
		set sutMenuTitle to "For 10 minutes"
		
		sut's setTurnDisplayOffOnPowerAdapterWhenInactive(sutMenuTitle)
		logger's infof("Handler result: {}", result)
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SystemSettingsLockScreenDecorator
		property parent : mainScript
		
		on revealLockScreen()
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Settings"
				reveal pane id PANE_ID_LOCK_SCREEN
			end tell
			
			set retry to retryLib's new()
			script LockScreenPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Sound") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealLockScreen
		
		
		on getStartScreenSaverWhenInactive()
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set popupButton to first pop up button of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose name is "Start Screen Saver when inactive"
					return value of popupButton
				end try
			end tell
			
			missing value
		end getStartScreenSaverWhenInactive
		
		
		(* 
			@newValue - one of the popup dropdowns e.g. For 1 minute 
			@returns - true if no error was encountered.
		*)
		on setStartScreenSaverWhenInactive(newValue)
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set popupButton to first pop up button of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose name is "Start Screen Saver when inactive"
					click popupButton
					delay 0.1
					click (first menu item of menu 1 of popupButton whose title is newValue)
					return true
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
			end tell
			false
		end setStartScreenSaverWhenInactive
		
		
		on getTurnDisplayOffOnBatteryWhenInactive()
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set popupButton to first pop up button of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose name is "Turn display off on battery when inactive"
					return value of popupButton
				end try
			end tell
			
			missing value
		end getTurnDisplayOffOnBatteryWhenInactive
		
		
		(* 
			@newValue - one of the popup dropdowns e.g. For 1 minute 
			@returns - true if no error was encountered.
		*)
		on setTurnDisplayOffOnBatteryWhenInactive(newValue)
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set popupButton to first pop up button of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose name is "Turn display off on battery when inactive"
					click popupButton
					delay 0.1
					click (first menu item of menu 1 of popupButton whose title is newValue)
					return true
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
			end tell
			false
		end setTurnDisplayOffOnBatteryWhenInactive
		
		
		on getTurnDisplayOffOnPowerAdapterWhenInactive()
			tell application "System Events" to tell process "System Settings"
				try
					set popupButton to first pop up button of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose name is "Turn display off on power adapter when inactive"
					return value of popupButton
					
					
					properties of popupButton
				end try
			end tell
			
		end getTurnDisplayOffOnPowerAdapterWhenInactive
		
		(* 
			@newValue - one of the popup dropdowns e.g. For 1 minute 
			@returns - true if no error was encountered.
		*)
		on setTurnDisplayOffOnPowerAdapterWhenInactive(newValue)
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set popupButton to first pop up button of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose name is "Turn display off on power adapter when inactive"
					click popupButton
					delay 0.1
					click (first menu item of menu 1 of popupButton whose title is newValue)
					return true
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
			end tell
			false
		end setTurnDisplayOffOnPowerAdapterWhenInactive
	end script
end decorate
