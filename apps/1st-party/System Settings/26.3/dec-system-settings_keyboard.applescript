(*
	@Purpose:
		Automating settings customization.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/macOS Tahoe/dec-system-settings_keyboard'

	@Created: Wed, Dec 25, 2024 at 9:13:56 AM
	@Last Modified: 
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use processLib : script "core/process"
use kbLib : script "core/keyboard" -- The keyboard settings doesn't respond to programmatic changes unfortunately.
use Math : script "core/math"

property logger : missing value

property kb : missing value
property retry : missing value

property PANE_ID_KEYBOARD : "com.apple.Keyboard-Settings.extension"

-- Below does not work inside whose clause.
-- property TEXT_REPEAT_RATE : "Key repeat rate"
-- property TEXT_REPEAT_DELAY : "Delay until repeat"

property REPEAT_RATE_OFF : 0
property MIN_REPEAT_RATE : 1
property MAX_REPEAT_RATE : 7

property MIN_REPEAT_DELAY : 6
property MAX_REPEAT_DELAY : 1

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Reveal Keyboard Pane
		Manual: Set key repeat rate
		Manual: Set Delay until repeat
		Manual: Trigger Keyboards Shortcuts
		
		Manual: Select Keyboard Shortcuts Tab
		Manual: Clear all check boxes
		Manual: Keyboard Shortcuts: Trigger Done
		Manual: Trigger Text Input > Edit...
		Manual: Text Input > Edit... > Toggle Add period with double-space

		Manual: Text Input > Edit... > Set Add period with double-space ON
		Manual: Text Input > Edit... > Set Add period with double-space OFF
		Manual: Text Input > Edit... > Trigger Done
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
	
	logger's infof("Key repeat rate: {}", sut's getKeyRepeatRate())
	logger's infof("Delay until repeat: {}", sut's getDelayUntilRepeat())
	logger's infof("Text Input: Add period with double-space: {}", sut's getAddPeriodWithDoubleSpace())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealKeyboard()
		
	else if caseIndex is 3 then
		set newRepeatRate to REPEAT_RATE_OFF
		set newRepeatRate to MIN_REPEAT_RATE
		set newRepeatRate to MIN_REPEAT_RATE + 1
		set newRepeatRate to MAX_REPEAT_RATE
		
		logger's infof("Spot: newRepeatRate: {}", newRepeatRate)
		sut's setKeyRepeatRate(newRepeatRate)
		
	else if caseIndex is 4 then
		set newDelayUntil to MIN_REPEAT_DELAY -- My preferred.
		-- set newDelayUntil to MIN_REPEAT_DELAY - 1 -- a point longer than the shortest
		-- set newDelayUntil to MAX_REPEAT_DELAY
		-- set newDelayUntil to MAX_REPEAT_DELAY + 1 -- a point shorter than the longest
		
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
		
	else if caseIndex is 8 then
		sut's triggerKeyboardShortcutsDone()
		
	else if caseIndex is 9 then
		sut's triggerTextInputEdit()
		
	else if caseIndex is 10 then
		sut's toggleAddPeriodWithDoubleSpace()
		
	else if caseIndex is 11 then
		sut's setAddPeriodWithDoubleSpaceOn()
		
	else if caseIndex is 12 then
		sut's setAddPeriodWithDoubleSpaceOff()
		
	else if caseIndex is 13 then
		sut's triggerTextInputEditDone()
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()
	
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
			
			script KeyboardPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Keyboard") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealKeyboard
		
		
		on getKeyRepeatRate()
			if running of application "System Settings" is false then return missing value
			if getCurrentPanelTitle() is not "Keyboard" then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set repeatKeyRateSlider to first slider of group 1 of scroll area 1 of group 1 of my getRightPaneUI() whose description is equal to "Key repeat rate"
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
				-- description is equal to "Key repeat rate"
				
				value of repeatKeyRateSlider
			end tell
		end getKeyRepeatRate
		
		(* 
			@newRepeatRate - 0-7, 0 is Off 7 is the max.
		*)
		on setKeyRepeatRate(newRepeatRate)
			if running of application "System Settings" is false then return
			if newRepeatRate is less than REPEAT_RATE_OFF or newRepeatRate is greater than MAX_REPEAT_RATE then return
			
			if getCurrentPanelTitle() is not "Keyboard" then revealKeyboard()			
			set currentRepeatRate to getKeyRepeatRate()
			set repeatRateDelta to currentRepeatRate - newRepeatRate
			-- logger's debugf("repeatDelta: {}", repeatDelta)
			
			tell application "System Events" to tell process "System Settings"
				set frontmost to true
				set repeatKeyRateSlider to first slider of group 1 of scroll area 1 of group 1 of my getRightPaneUI() whose description is "Key repeat rate"
				-- set value of attribute "AXAutoInteractable" of repeatKeyRateSlider to true  -- Not useful here.
				set value of repeatKeyRateSlider to newRepeatRate -- DOESN'T WORK.
				set focused of repeatKeyRateSlider to true
			end tell
			
			if repeatRateDelta is greater than 0 then
				repeat repeatRateDelta times
					kb's pressKey("left")
				end repeat
				
			else
				repeat Math's abs(repeatRateDelta) times
					kb's pressKey("right")
				end repeat
				
			end if
		end setKeyRepeatRate
		
		
		on getDelayUntilRepeat()
			if running of application "System Settings" is false then return missing value
			if getCurrentPanelTitle() is not "Keyboard" then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					set delayUntilRepeatSlider to first slider of group 1 of scroll area 1 of group 1 of my getRightPaneUI() whose description is "Delay until repeat"
				end try
				
				value of delayUntilRepeatSlider
			end tell
		end getDelayUntilRepeat
		
		
		(* 
			@newRepeatRate - 1-6, 1 being long and 6 being the shortest.  So it maybe a bit confusing because 1 is long (max), and 6 is short (min).
		*)
		on setDelayUntilRepeat(newRepeatDelay)
			if running of application "System Settings" is false then return
			if newRepeatDelay is less than MAX_REPEAT_DELAY or newRepeatDelay is greater than MIN_REPEAT_DELAY then return
			
			if getCurrentPanelTitle() is not "Keyboard" then revealKeyboard()
			
			set currentRepeatDelay to getDelayUntilRepeat()
			set repeatDelayDelta to currentRepeatDelay - newRepeatDelay
			
			tell application "System Events" to tell process "System Settings"
				set frontmost to true
				try
					set delayUntilRepeatSlider to first slider of group 1 of scroll area 1 of group 1 of my getRightPaneUI() whose description is "Delay until repeat"
					
				end try
				
				set value of delayUntilRepeatSlider to newRepeatDelay -- DOESN'T WORK
				set focused of delayUntilRepeatSlider to true
			end tell
			
			set changeDirection to "left"
			if repeatDelayDelta is less than 0 then set changeDirection to "right"
			
			repeat Math's abs(repeatDelayDelta) times
				kb's pressKey(changeDirection)
				delay 0.02
			end repeat
		end setDelayUntilRepeat
		
		
		on triggerKeyboardShortcuts()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				set frontmost to true
				try
					-- click button 1 of group 2 of scroll area 1 of group 1 of my getRightPaneUI()
					click button 3 of group 2 of scroll area 1 of group 1 of my getRightPaneUI()
				on error the errorMessage number the errorNumber
					log errorMessage
					
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
		
		
		on triggerKeyboardShortcutsDone()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				try
					click button 2 of my getRightPaneUI() -- Indexed, no attribute, label, description a
				end try
			end tell
		end triggerKeyboardShortcutsDone
		
		
		on triggerTextInputEdit()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				try
					click button 1 of group 3 of scroll area 1 of group 1 of my getRightPaneUI()
				end try
			end tell
			
			script SheetWaiter
				tell application "System Events" to tell process "System Settings"
					if exists sheet 1 of window 1 then return true
				end tell
			end script
			exec of retry on result for 3
		end triggerTextInputEdit
		
		
		on triggerTextInputEditDone()
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				try
					click button 1 of group 2 of splitter group 1 of group 1 of sheet 1 of front window
				end try
			end tell
		end triggerTextInputEditDone
		
		
		on getAddPeriodWithDoubleSpace()
			if running of application "System Settings" is false then return false
			
			tell application "System Events" to tell process "System Settings"
				try
					return value of checkbox "Add period with double-space" of group 2 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of front window is 1
				end try
			end tell
			false
		end getAddPeriodWithDoubleSpace
		
		
		on toggleAddPeriodWithDoubleSpace()
			if running of application "System Settings" is false then return false
			
			tell application "System Events" to tell process "System Settings"
				try
					click checkbox "Add period with double-space" of group 2 of scroll area 1 of group 2 of splitter group 1 of group 1 of sheet 1 of front window
				end try
			end tell
		end toggleAddPeriodWithDoubleSpace
		
		
		on setAddPeriodWithDoubleSpaceOn()
			if not getAddPeriodWithDoubleSpace() then toggleAddPeriodWithDoubleSpace()
		end setAddPeriodWithDoubleSpaceOn
		
		
		on setAddPeriodWithDoubleSpaceOff()
			if getAddPeriodWithDoubleSpace() then toggleAddPeriodWithDoubleSpace()
		end setAddPeriodWithDoubleSpaceOff
		
	end script
end decorate
