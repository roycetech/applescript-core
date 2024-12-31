(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-preferences-variables'

	@Created: Tuesday, July 2, 2024 at 11:46:14 AM
	@Last Modified: Tuesday, July 2, 2024 at 11:46:14 AM
	@Change Logs:
*)
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Main
		Manual: Show Variables Preferences
		Manual: Close Preferences Window
		Manual: Search Variable
		Manual: Clear Variable Search
		
		Manual: Get empty variables
		Manual: Delete empty variables
		Manual: Delete a variable
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/keyboard-maestro"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showVariablesPreferences()
		
	else if caseIndex is 3 then
		sut's closePreferences()
		
	else if caseIndex is 4 then
		sut's searchVariable("Unicorn")
		
	else if caseIndex is 5 then
		sut's clearVariablesSearch()
		
	else if caseIndex is 6 then
		set emptyVariables to sut's getEmptyVariables()
		
		if the number of items in emptyVariables is 0 then
			logger's info("There are no empty variables")
		else
			logger's infof("Empty variables count: {}", number of items in emptyVariables)
			repeat with nextVar in emptyVariables
				logger's infof("Next empty: {}", nextVar)
			end repeat
		end if
		
	else if caseIndex is 7 then
		sut's deleteEmptyVariables()
		
	else if caseIndex is 8 then
		logger's infof("Handler result: {}", sut's deleteVariable("Unicorn"))
		logger's infof("Handler result: {}", sut's deleteVariable("spot")) -- Manually create this variable in keybboard maestro.
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	set retry to retryLib's new()
	
	script KeyboardMaestroPreferencesVariablesDecorator
		property parent : mainScript
		
		on showVariablesPreferences()
			if running of application "Keyboard Maestro" is false then return
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is not missing value then return -- Already visible.
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first menu item of menu 1 of menu bar item "Keyboard Maestro" of menu bar 1 whose title starts with "Setting")
				end try
				
				set preferencesWindow to my getPreferencesWindow()
				if preferencesWindow is missing value then return
				
				try
					click button "Variables" of toolbar 1 of preferencesWindow
				end try
			end tell
		end showVariablesPreferences
		
		
		on closePreferences()
			if running of application "Keyboard Maestro" is false then return
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first button of preferencesWindow whose role description is "close button")
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
				
			end tell
		end closePreferences
		
		
		on getPreferencesWindow()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					return first window whose title starts with "Preferences"
				end try
			end tell
			
			missing value
		end getPreferencesWindow
		
		
		on searchVariable(variableKeyword)
			if running of application "Keyboard Maestro" is false then return
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set focused of text field 1 of preferencesWindow to true
				set value of text field 1 of preferencesWindow to variableKeyword
			end tell
		end searchVariable
		
		
		on clearVariablesSearch()
			if running of application "Keyboard Maestro" is false then return
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first button of text field 1 of preferencesWindow whose description is "cancel")
				end try
			end tell
		end clearVariablesSearch
		
		
		(* Retrieves the list of variables whose value is empty. This is probably too use-case specific. *)
		on getEmptyVariables()
			set clearList to {}
			showVariablesPreferences()
			
			if running of application "Keyboard Maestro" is false then return clearList
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return clearList
			
			
			clearVariablesSearch()
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set variableGroups to missing value
				try
					set variableGroups to groups of scroll area 1 of preferencesWindow
				end try
			end tell
			if variableGroups is missing value then return clearList
			logger's debugf("Variables count: {}", number of items in variableGroups)
			
			repeat with nextGroup in variableGroups
				set nextVarName to the name of nextGroup as text
				tell application "Keyboard Maestro Engine"
					set nextValue to getvariable nextVarName
					if nextValue is "" then
						set end of clearList to nextVarName
						-- 					else
						-- 						log nextVarName & " -> " & nextValue
					end if
				end tell
			end repeat
			
			clearList
		end getEmptyVariables
		
		
		on deleteEmptyVariables()
			showVariablesPreferences()
			
			if running of application "Keyboard Maestro" is false then return clearList
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return clearList
			
			logger's info("Retrieving empty variables...")
			set emptyVarsList to getEmptyVariables()
			
			logger's debugf("Empty variables count: {}", number of items in emptyVarsList)
			
			logger's info("Deleting each empty variable...")
			repeat with nextVarName in emptyVarsList
				clearVariablesSearch()
				searchVariable(nextVarName)
				
				script SelectionWaiter
					tell application "System Events" to tell process "Keyboard Maestro"
						exists static text nextVarName of preferencesWindow
					end tell
				end script
				exec of retry on result for 10 by 0.1
				
				clickDeleteVariable()
			end repeat
			clearVariablesSearch()
		end deleteEmptyVariables
		
		
		(*
			@returns true if successful.
		*)
		on deleteVariable(varName)
			showVariablesPreferences()
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return false
			
			script SelectionWaiter
				tell application "System Events" to tell process "Keyboard Maestro"
					exists static text varName of preferencesWindow
				end tell
			end script
			exec of retry on result for 10 by 0.1
			
			if result then
				clickDeleteVariable()
				return true
			end if
			
			false
		end deleteVariable
		
		
		on clickDeleteVariable()
			if running of application "Keyboard Maestro" is false then return
			
			set preferencesWindow to getPreferencesWindow()
			if preferencesWindow is missing value then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first button of preferencesWindow whose description is "Delete Variable")
				end try
			end tell
		end clickDeleteVariable
	end script
end decorate
