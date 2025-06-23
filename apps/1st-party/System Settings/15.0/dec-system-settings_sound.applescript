(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/System Settings/15.0/dec-system-settings_sound'

	@Created: Tue, Dec 24, 2024 at 8:06:45 PM
	@Last Modified: 
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use processLib : script "core/process"

property logger : missing value
property PANE_ID_SOUND : "com.apple.Sound-Settings.extension"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Reveal Sounds Pane
		Manual: Toggle Play Feedback when Volume is Changed
		Manual: Set Play Feedback when Volume is Changed -> On
		Manual: Set Play Feedback when Volume is Changed -> Off		
		
		Manual: Switch Output & Input tab
		Manual: Switch Microphone by Name
		Manual: Switch Microphone by Type
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
	
	logger's infof("isPlayFeedbackWhenSoundIsChanged: {}", sut's isPlayFeedbackWhenSoundIsChanged())
	logger's infof("Output & Input: {}", sut's getOutputAndInput())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's revealSounds()
		
	else if caseIndex is 3 then
		sut's togglePlayFeedbackWhenSoundIsChanged()
		
	else if caseIndex is 4 then
		sut's setPlayFeedbackWhenSoundIsChangedOn()
		
	else if caseIndex is 5 then
		sut's setPlayFeedbackWhenSoundIsChangedOff()
		
	else if caseIndex is 6 then
		set sutOutputInputTab to "Unicorn"
		set sutOutputInputTab to "Input"
		-- set sutOutputInputTab to "Output"
		logger's debugf("sutOutputInputTab: {}", sutOutputInputTab)
		
		sut's switchOutputInputTab(sutOutputInputTab)
		
	else if caseIndex is 7 then
		set sutInputName to "Unicorn"
		set sutInputName to "WH-1000XM4"
		set sutInputName to "MacBook Pro Microphone"
		logger's debugf("sutInputName: {}", sutInputName)
		
		sut's switchInputByName(sutInputName)
		
	else if caseIndex is 8 then
		set sutInputType to "Unicorn"
		set sutInputType to "Built-in"
		-- set sutInputType to "Bluetooth"
		logger's debugf("sutInputType: {}", sutInputType)
		
		sut's switchInputByType(sutInputType)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SystemSettingsSoundsDecorator
		property parent : mainScript
		
		(* @returns "Output" or "Input" *)
		on getOutputAndInput()
			if running of application "System Settings" is false then return missing value
			
			tell application "System Events" to tell process "System Settings"
				try
					return description of first radio button of tab group 1 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window whose value is 1
				end try
			end tell
			missing value
		end getOutputAndInput
		
		on switchOutputInputTab(tabDescription)
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				try
					click (the first radio button of tab group 1 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of front window whose description is tabDescription)
				end try
			end tell
			
		end switchOutputInputTab
		
		on switchInputByName(inputDescription)
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				set selected of first row of outline 1 of scroll area 1 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Sound" whose value of first static text of group 1 of UI element 1 is inputDescription to true
			end tell
		end switchInputByName
		
		on switchInputByType(inputType)
			if running of application "System Settings" is false then return
			
			tell application "System Events" to tell process "System Settings"
				set selected of first row of outline 1 of scroll area 1 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Sound" whose value of first static text of group 1 of UI element 2 is inputType to true
			end tell
		end switchInputByType
		
		on revealSounds()
			if running of application "System Settings" is false then
				set systemSettingsProcess to processLib's new("System Settings")
				systemSettingsProcess's waitActivate()
			end if
			
			tell application "System Settings"
				reveal pane id PANE_ID_SOUND
			end tell
			
			set retry to retryLib's new()
			script SoundsPaneWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (window "Sound") then return true
				end tell
			end script
			exec of retry on result for 3
		end revealSounds
		
		
		on isPlayFeedbackWhenSoundIsChanged()
			if running of application "System Settings" is false then return false
			
			tell application "System Events" to tell process "System Settings"
				value of checkbox "Play feedback when volume is changed" of group 1 of scroll area 1 of group 1 of my getRightPaneUI() is 1
			end tell
		end isPlayFeedbackWhenSoundIsChanged
		
		on togglePlayFeedbackWhenSoundIsChanged()
			if running of application "System Settings" is false then return false
			
			tell application "System Events" to tell process "System Settings"
				click checkbox "Play feedback when volume is changed" of group 1 of scroll area 1 of group 1 of my getRightPaneUI()
			end tell
		end togglePlayFeedbackWhenSoundIsChanged
		
		on setPlayFeedbackWhenSoundIsChangedOff()
			if not isPlayFeedbackWhenSoundIsChanged() then return
			
			togglePlayFeedbackWhenSoundIsChanged()
		end setPlayFeedbackWhenSoundIsChangedOff
		
		on setPlayFeedbackWhenSoundIsChangedOn()
			if isPlayFeedbackWhenSoundIsChanged() then return
			
			togglePlayFeedbackWhenSoundIsChanged()
		end setPlayFeedbackWhenSoundIsChangedOn
		
		
	end script
end decorate
