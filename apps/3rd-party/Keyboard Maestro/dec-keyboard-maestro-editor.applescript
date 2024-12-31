(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-editor'

	@Created: Wednesday, August 14, 2024 at 5:53:03 PM
	@Last Modified: Wednesday, August 14, 2024 at 5:53:03 PM
	@Change Logs:
*)
use retryLib : script "core/retry"
use loggerFactory : script "core/logger-factory"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Set macro name (un/focused)
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
	
	logger's infof("Focused Type: {}", sut's getFocusedType())
	logger's infof("Editable: {}", sut's isEditable())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setMacroName("Spot Check Macro")
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script KeyboardMaestroEditorDecorator
		property parent : mainScript
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
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click group "App: Script Editor" of scroll area 1 of splitter group 1 of group 6 of my getEditorWindow()
				end try
			end tell
		end selectMacroGroup
		
		
		on getSelectedGroupName()
			tell application "System Events" to tell process "Keyboard Maestro"
				name of first group of scroll area 1 of splitter group 1 of group 6 of my getEditorWindow() whose selected is true
			end tell
		end getSelectedGroupName
		
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
			script RetryMainWindow
				tell application "System Events" to tell process "Keyboard Maestro"
					first window whose title starts with "Keyboard Maestro Editor"
				end tell
			end script
			exec of retry on result for 3
		end getEditorWindow
	end script
end decorate
