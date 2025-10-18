(*

	NOTE: Macro group is sometimes referred to in this script as just "group".

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-editor'

	@Created: Wednesday, August 14, 2024 at 5:53:03 PM
	@Last Modified: Wednesday, August 14, 2024 at 5:53:03 PM
	@Change Logs:
		Tue, Apr 29, 2025 at 12:53:30 PM - Added focusSelectedMacro handler
		Wed, Feb 19, 2025 at 01:34:30 PM - Added Delete/Add Macro Group app.
		Wed, Jan 8, 2025 at 8:33:24 AM - Added #getSelectedMacroName
*)
use retryLib : script "core/retry"
use loggerFactory : script "core/logger-factory"
use kbLib : script "core/keyboard" -- Used to dismiss popup on error

property logger : missing value
property retry : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Set macro name (un/focused)
		Manual: Select macro group by name
		Manual: Delete macro group last app
		Manual: Add macro group app
		
		Manual: Set app availability option
		Manual: Focus Macro
		Manual: Focus Action By Index
		Manual: Focus Search
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
	set sutLib to script "core/keyboard-maestro"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	set currentFocusType to sut's getFocusedType()
	logger's infof("Focused Type: {}", currentFocusType)
	logger's infof("Selected macro group: {}", sut's getSelectedGroupName())
	logger's infof("Selected macro: {}", sut's getSelectedMacroName())
	logger's infof("Selected action index: {}", sut's getSelectedActionIndex())
	
	logger's infof("Editable: {}", sut's isEditable())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setMacroName("Spot Check Macro")
		
	else if caseIndex is 3 then
		set sutMacroGroupName to "Unicorn"
		set sutMacroGroupName to "App: Duolingo Mobile"
		logger's debugf("sutMacroGroupName: {}", sutMacroGroupName)
		
		sut's selectMacroGroup(sutMacroGroupName)
		
	else if caseIndex is 4 then
		sut's deleteLastMacroGroupApp()
		
	else if caseIndex is 5 then
		set sutAppName to "Unicorn"
		logger's debugf("sutAppName: {}", sutAppName)
		sut's addMacroGroupApp(sutAppName)
		
	else if caseIndex is 6 then
		set sutAppAvailabilityOption to "Unicorn"
		set sutAppAvailabilityOption to "Available in these applications:"
		logger's infof("sutAppAvailabilityOption: {}", sutAppAvailabilityOption)
		
		sut's setApplicationAvailabilityOption(sutAppAvailabilityOption)
		
	else if caseIndex is 7 then
		sut's focusSelectedMacro()
		
	else if caseIndex is 8 then
		sut's setSelectedActionByIndex(1)
		
	else if caseIndex is 9 then
		activate application "Keyboard Maestro"
		sut's focusSearch()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set kb to kbLib's new()
	
	script KeyboardMaestroEditorDecorator
		property parent : mainScript
		
		on focusSearch()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set focused of text field 1 of my getEditorWindow() to true
			end tell
		end focusSearch
		
		(*
			@Caveat: Returns last selected action index even if no more action is selected after changing the macro selection.
		*)
		on getSelectedActionIndex()
			if running of application "Keyboard Maestro" is false then return missing value
			
			set selectedIndex to 0
			tell application "System Events" to tell process "Keyboard Maestro"
				set macroActions to groups of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow()
				repeat with nextAction in macroActions
					set selectedIndex to selectedIndex + 1
					if selected of nextAction is true then
						exit repeat
					end if
				end repeat
			end tell
			
			selectedIndex
		end getSelectedActionIndex
		
		
		(* DOES NOT WORK! *)
		on setSelectedActionByIndex(actionIndex)
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set frontmost to true
				set selected of group actionIndex of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() to true
				try
					click group actionIndex of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow()
				end try
			end tell
		end setSelectedActionByIndex
		
		(* 
			NOTE: Menu doesn't immediately reflect reality unless the menu was actually clicked by the user.
			
			@returns "macro group", "macro", or "action" depending on the state of the menus. 
		*)
		on getFocusedType()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					if focused of text field 1 of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() then
						return "action"
					end if
				end try
			end tell
			
			-- Below fails to work from Keyboard Maestro AppleScript
			tell application "Keyboard Maestro"
				set currentSelection to selection
				if (the number of items in currentSelection) is 0 then return "macro group"
				
				first item of currentSelection
				set typeClass to class of result
				if typeClass is action then
					return "action"
				else if typeClass is macro then
					return "macro"
				end if
			end tell
			"macro group"
		end getFocusedType
		
		
		on selectMacro(macroName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (the first group of scroll area 2 of splitter group 1 of group 6 of my getEditorWindow() whose name starts with macroName)
				end try
			end tell
		end selectMacro
		
		(*
			Create a macro via the UI.
		*)
		on createMacro(macroName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (the first button of my getEditorWindow() whose description is "Add Macro")
					delay 0.1
					set value of text field 1 of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() to macroName
				end try
			end tell
		end createMacro
		
		
		on selectMacroGroup(groupName)
			if running of application "Keyboard Maestro Engine" is false then return
			
			activate application "Keyboard Maestro" -- Make the editor window active			
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click group groupName of scroll area 1 of splitter group 1 of group 6 of my getEditorWindow()
				end try
			end tell
		end selectMacroGroup
		
		
		on deleteLastMacroGroupApp()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (last button of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() whose description is "Delete Application")
				end try
			end tell
		end deleteLastMacroGroupApp
		
		
		(*
			NOTE: Using index because there is no available UI identifier.
		*)
		on setApplicationAvailabilityOption(targetOption)
			if running of application "Keyboard Maestro" is false then return
			
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set appAvailabilityPopup to pop up button 3 of scroll area 3 of splitter group 1 of group 6 of editorWindow
				click appAvailabilityPopup
				delay 0.1
				try
					click menu item targetOption of menu 1 of appAvailabilityPopup
					delay 0.1
				on error the errorMessage number the errorNumber
					kb's pressKey("escape")
				end try
			end tell
		end setApplicationAvailabilityOption
		
		on addMacroGroupApp(appNamePrefix)
			if running of application "Keyboard Maestro" is false then return
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return missing value
			
			tell application "System Events"
				set targetScrollArea to scroll area 3 of splitter group 1 of group 6 of editorWindow
			end tell
			
			script AddButtonWaiter
				tell application "System Events"
					if exists (last button of targetScrollArea whose description is "Add Application") then return true
				end tell
			end script
			set waitResult to exec of retry on result for 3
			if waitResult is missing value then return
			
			tell application "System Events"
				try
					click (last button of targetScrollArea whose description is "Add Application")
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
			
			delay 0.1
			script PopupWaiter
				tell application "System Events"
					click (first menu item of menu 1 of targetScrollArea whose title starts with appNamePrefix)
				end tell
				true
			end script
			exec of retry on result for 3
			
		end addMacroGroupApp
		
		
		on getSelectedGroupName()
			if getEditorWindow() is missing value then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				name of first group of scroll area 1 of splitter group 1 of group 6 of my getEditorWindow() whose selected is true
			end tell
		end getSelectedGroupName
		
		
		on getSelectedMacroName()
			tell application "System Events" to tell process "Keyboard Maestro"
				-- name of first group of scroll area 2 of splitter group 1 of group 6 of my getEditorWindow() whose selected is true
				-- Pulsar: Text Expander: Extract and Paste Markdown Link of Keyboard Maestro. kklink
				-- get 
				try
					return value of first text field of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() whose accessibility description is "Macro Name"
				end try
				-- Pulsar: Text Expander: Extract and Paste Markdown Link of Keyboard Maestro
			end tell
			
			missing value
		end getSelectedMacroName
		
		on getSelectedActionID()
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					return value of first text field of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() whose accessibility description is "Macro Name"
				end try
			end tell
			
			missing value
		end getSelectedActionID
		
		
		(*
			Focus the currently selected macro group in the editor so it can be 
			conveniently followed up by a keyboard navigation.
		*)
		on focusSelectedMacroGroup()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set frontmost to true
				
				try
					click menu item "Select Groups Column" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end focusSelectedMacroGroup
		
		
		(*
			Focus the currently selected macro in the editor.
		*)
		on focusSelectedMacro()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set frontmost to true
				
				try
					click menu item "Select Macros Column" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end focusSelectedMacro
		
		
		(* Click on the next macro history button. *)
		on nextEdited()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first button of group 3 of my getEditorWindow() whose description is "go forward")
				end try
			end tell
		end nextEdited
		
		
		(* Click on the back macro history button. *)
		on previouslyEdited()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first button of group 3 of my getEditorWindow() whose description is "go back")
				end try
			end tell
		end previouslyEdited
		
		(*
			Returns the current focused macro or group name in the Keyboard Maestro Editor.
		*)
		on getCurrentItemName()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set editorWindow to missing value
				try
					set editorWindow to the first window whose name does not start with "Preferences: "
				end try
				if editorWindow is missing value then return
				
				set tokens to textUtil's split(name of editorWindow, unic's SEPARATOR)
			end tell
			
			last item of tokens
		end getCurrentItemName
		
		(*  *)
		on focusActionCategory(categoryName)
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					tell application "System Events" to tell process "Keyboard Maestro"
						click group categoryName of scroll area 1 of splitter group 1 of window "New Action"
					end tell
				end try
			end tell
		end focusActionCategory
		
		
		(* @returns "Sort by Name" or "Sort by Trigger" *)
		on getMacroSortMode()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				description of first checkbox of splitter group 1 of group 6 of my getEditorWindow() whose enabled is false
			end tell
			last word of result
		end getMacroSortMode
		
		(*
			@newSortMode - Trigger or Name
		*)
		on setSortMode(newSortMode)
			if running of application "Keyboard Maestro" is false then return
			if getMacroSortMode() is equal to newSortMode then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first checkbox of splitter group 1 of group 6 of my getEditorWindow() whose description contains newSortMode)
				end try
			end tell
		end setSortMode
		
		
		on scrollMacrosPane(zeroToOne)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					set value of value indicator 1 of scroll bar 1 of scroll area 2 of splitter group 1 of group 6 of my getEditorWindow() to zeroToOne
				end try -- Ignore if the scroll bar does not exist.
			end tell
			delay 0.1
		end scrollMacrosPane
		
		
		on getEditorWindow()
			if running of application "Keyboard Maestro" is false then return missing value
			
			try
				with timeout of 1 second
					tell application "System Events" to tell application process "Keyboard Maestro"
						if (count of windows) is 0 then return missing value
					end tell
				end timeout
			on error the errorMessage number the errorNumber
				log errorMessage
				return missing value
			end try
			
			script RetryMainWindow
				tell application "System Events" to tell process "Keyboard Maestro"
					first window whose title starts with "Keyboard Maestro Editor"
				end tell
			end script
			exec of retry on result for 3
		end getEditorWindow
	end script
end decorate
