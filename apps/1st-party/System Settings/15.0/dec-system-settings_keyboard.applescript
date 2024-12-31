(*
	@Purpose:
		Automating settings customization.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_keyboard'

	@Created: Wed, Dec 25, 2024 at 9:13:56 AM
	@Last Modified: 
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use processLib : script "core/process"

property logger : missing value
property PANE_ID_KEYBOARD : "com.apple.Keyboard-Settings.extension"

-- Below does not work inside whose clause.
-- property TEXT_REPEAT_RATE : "Key repeat rate"
-- property TEXT_REPEAT_DELAY : "Delay until repeat"

property REPEAT_RATE_OFF : 0
property MIN_REPEAT_DELAY : 1

property MAX_DELAY_UNTIL : 6
property MAX_REPEAT_RATE : 7


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal Keyboard Pane
		Manual: Set key repeat rate (DOESN'T WORK, slider doesn't react to change in value)
		Manual: Set Delay until repeat (DOESN'T WORK, slider doesn't react to change in value)
		Manual: Trigger Keyboards Shortcuts
		
		Manual: Select Keyboard Shortcuts Tab
		Manual: Clear all check boxes
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
	
	logger's infof("Key repeat rate: {}", sut's getKeyRepeatRate())
	logger's infof("Delay until repeat: {}", sut's getDelayUntilRepeat())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealKeyboard()
		
	else if caseIndex is 3 then
		set newRepeatRate to REPEAT_RATE_OFF
		
		logger's infof("newRepeatRate: {}", newRepeatRate)
		sut's setKeyRepeatRate(newRepeatRate)
		
	else if caseIndex is 4 then
		set newDelayUntil to MAX_DELAY_UNTIL
		set newDelayUntil to 5
		
		logger's infof("newDelayUntil: {}", newDelayUntil)
		sut's setDelayUntilRepeat(newDelayUntil)
		
	else if caseIndex is 5 then
		sut's triggerKeyboardShortcuts()
		
	else if caseIndex is 6 then
		set sutTabName to "unicorn"
		set sutTabName to "Services"
		set sutTabName to "Screenshots"
		sut's selectKeyboardShortcutsTab(sutTabName)
		
	else if caseIndex is 7 then
		sut's clearAllShortcuts()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SystemSettingsKeyboardDecorator
		property parent : mainScript
		
		on revealKeyboard()
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Settings"
				reveal pane id PANE_ID_KEYBOARD
			end tell
			
			set retry to retryLib's new()
			script SoundsPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Keyboard") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealKeyboard
		
		
		on getKeyRepeatRate()
			if running of application "System Settings" is false then return false
			
			tell application "System Events" to tell process "System Settings"
				set repeatKeyRateSlider to first slider of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose description is equal to "Key repeat rate"
				-- description is equal to "Key repeat rate"
				
				value of repeatKeyRateSlider
			end tell
		end getKeyRepeatRate
		
		
		on getDelayUntilRepeat()
			if running of application "System Settings" is false then return false
			
			tell application "System Events" to tell process "System Settings"
				set delayUntilRepeatSlider to first slider of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose description is "Delay until repeat"
				
				value of delayUntilRepeatSlider
			end tell
		end getDelayUntilRepeat
		
		
		(* 
			@newRepeatRate - 0-7, 0 is Off 7 is the max.
		*)
		on setKeyRepeatRate(newRepeatRate)
			if running of application "System Settings" is false then return
			if newRepeatRate is less than REPEAT_RATE_OFF or newRepeatRate is greater than MAX_REPEAT_RATE then return
			
			tell application "System Events" to tell process "System Settings"
				set repeatKeyRateSlider to first slider of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose description is "Key repeat rate"
				set value of repeatKeyRateSlider to newRepeatRate -- DOESN'T WORK.
			end tell
		end setKeyRepeatRate
		
		(* 
			@newRepeatRate - 1-6, 1 being long and 6 being the shortest.
		*)
		on setDelayUntilRepeat(newRepeatDelay)
			if running of application "System Settings" is false then return
			if newRepeatDelay is less than MIN_REPEAT_DELAY or newRepeatDelay is greater than MAX_REPEAT_RATE then return
			
			tell application "System Events" to tell process "System Settings"
				set delayUntilRepeatSlider to first slider of group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window whose description is "Delay until repeat"
				
				set value of delayUntilRepeatSlider to newRepeatDelay
			end tell
		end setDelayUntilRepeat
		
		
		on triggerKeyboardShortcuts()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				try
					tell application "System Events" to tell process "System Settings"
						click button 3 of group 2 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window
					end tell
				end try
			end tell
		end triggerKeyboardShortcuts
		
		
		on selectKeyboardShortcutsTab(tabTitle)
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				set rowIndex to -1
				if tabTitle is "Screenshots" then set rowIndex to 6
				if tabTitle is "Services" then set rowIndex to 8
				
				try
					set selected of row rowIndex of outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of sheet 1 of front window to true
				end try
				
			end tell
			
			missing value
		end selectKeyboardShortcutsTab
		
		on clearAllShortcuts()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				set rowElements to rows of outline 1 of scroll area 1 of group 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of front window
				repeat with nextRow in rowElements
					-- set value of checkbox 1 of UI element 1 of nextRow to 1  -- DIDN'T WORK, must be clicked.
					if the value of checkbox 1 of UI element 1 of nextRow is 1 then
						click checkbox 1 of UI element 1 of nextRow
					end if
				end repeat
			end tell
		end clearAllShortcuts
	end script
end decorate
