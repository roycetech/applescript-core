(* 
	This script focuses on the Keyboard Maestro Editor and fundamental handlers 
		when working with the app.

	NOTE: Do not reference front window directly in this code because other 
		non-editor window may be active. Use the "my _getMainWindow()" instead.

	@Project:
		applescript-core
	
	@Build:
		./scripts/build-lib.sh "apps/3rd-party/Keyboard Maestro/keyboard-maestro"

	@Last Modified: November 28, 2023 11:05 PM
	@Change Logs:
		Wednesday, May 29, 2024 at 2:33:10 PM - Macro sorting handlers.
		October 20, 2023 10:27 AM - Added focusSelectedMacroGroup().
*)

use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use decoratorLib : script "core/decorator"

use spotScript : script "core/spot-test"


property logger : missing value
property retry : missing value

property MENU_ALL : "All Actions"


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()
if name of current application is "osascript" then unitTest()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Run Macro
		Set/Get Variable
		Placeholder (So toggle action cases are in the same set)		
		Manual: Editor: Show Actions
		
		Manual: Editor: Hide Actions
		Manual: Get Current Item Name
		Manual: Click New Action Category
		Manual: History Backward
		Manual: History Forward
		
		Manual: Select Macro Group
		Manual: Select Macro
		Manual: Scroll Macros/Actions Pane
		Manual: Focus MacroGroup Pane
		Manual: Sort By Name/Trigger

		Manual: Insert Action
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("Focused Type: {}", sut's getFocusedType())
	logger's infof("Actions Window Present: {}", sut's isActionsWindowPresent())
	logger's infof("Selected Group Name: {}", sut's getSelectedGroupName())
	logger's infof("Macro with name exists (Unicorn): {}", sut's macroWithNameExists("Unicorn"))
	logger's infof("Macro with name exists yes: {}", sut's macroWithNameExists("Script Editor: Text Expander: km's getFocusedType()"))
	logger's infof("Macro sort mode: {}", sut's getMacroSortMode())
	
	if caseIndex is 1 then
		-- sut's sendSafariText("KM Test")
		
	else if caseIndex is 2 then
		sut's runMacro("hello")
		
	else if caseIndex is 3 then
		sut's setVariable("from Script Editor Name", "from Script Editor Value 1")
		assertThat of std given condition:sut's getVariable("from Script Editor Name") is equal to "from Script Editor Value 1", messageOnFail:"Failed spot check"
		sut's setVariable("from Script Editor Name", "from Script Editor Value 2")
		assertThat of std given condition:sut's getVariable("from Script Editor Name") is equal to "from Script Editor Value 2", messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	else if caseIndex is 5 then
		sut's showActions()
		
	else if caseIndex is 6 then
		sut's hideActions()
		
	else if caseIndex is 7 then
		logger's infof("Handler result: {}", sut's getCurrentItemName())
		
	else if caseIndex is 8 then
		sut's focusActionCategory("Favorites")
		
	else if caseIndex is 9 then
		sut's previouslyEdited()
		
	else if caseIndex is 10 then
		sut's nextEdited()
		
	else if caseIndex is 11 then
		sut's selectMacroGroup("App: Script Editor")
		
	else if caseIndex is 12 then
		sut's selectMacro("_Script Editor: Text Expander: Temp Template")
		
	else if caseIndex is 13 then
		set zeroToOne to 0
		sut's scrollMacrosPane(zeroToOne)
		sut's scrollActionsPane(zeroToOne)
		
	else if caseIndex is 14 then
		sut's focusSelectedMacroGroup()
		
	else if caseIndex is 15 then
		-- sut's setSortMode("Unicorn")
		sut's setSortMode("Name")
		-- sut's setSortMode("Trigger")
		
		logger's infof("New macro sort mode: {}", sut's getMacroSortMode())
		
	else if caseIndex is 16 then
		
		-- sut's insertAction("Favorites", "Code Complet")
		sut's insertAction(missing value, "Alert")
		
	end if
	
	activate
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	set retry to retryLib's new()
	
	script KeyboardMaestroInstance
		property variable_update_retry_count : 3
		property delayAfterRun : 0
		
		(*
			Insert a new action via the menu "Edit".
		
			@ middleMenu - missing value defaults to "All Actions" which is slow.
		*)
		on insertAction(middleMenu, menuItemKeyword)
			set actualMiddleMenu to middleMenu
			if actualMiddleMenu is missing value then set actualMiddleMenu to MENU_ALL
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first menu item of menu 1 of menu item actualMiddleMenu of menu 1 of menu item "Insert Action" of menu 1 of menu bar item "Edit" of menu bar 1 whose title contains menuItemKeyword)
				end try
			end tell
		end insertAction
		
		
		(* @returns "Sort by Name" or "Sort by Trigger" *)
		on getMacroSortMode()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				description of first checkbox of splitter group 1 of group 6 of my _getMainWindow() whose enabled is false
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
					click (first checkbox of splitter group 1 of group 6 of my _getMainWindow() whose description contains newSortMode)
				end try
			end tell
		end setSortMode
		
		
		
		on scrollMacrosPane(zeroToOne)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					set value of value indicator 1 of scroll bar 1 of scroll area 2 of splitter group 1 of group 6 of my _getMainWindow() to zeroToOne
				end try -- Ignore if the scroll bar does not exist.
			end tell
			delay 0.1
		end scrollMacrosPane
		
		on scrollActionsPane(zeroToOne)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					set value of value indicator 1 of scroll bar 1 of scroll area 3 of splitter group 1 of group 6 of my _getMainWindow() to zeroToOne
				end try -- Ignore if the scroll bar does not exist.
			end tell
			delay 0.1
		end scrollActionsPane
		
		(*
			Text Expander concats the shortcut, that's why we are using the starts with to find the macro.
		*)
		on macroWithNameExists(macroName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					first group of scroll area 2 of splitter group 1 of group 6 of my _getMainWindow() whose title starts with the macroName
					return true
				end try
			end tell
			false
		end macroWithNameExists
		
		
		on selectMacro(macroName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (the first group of scroll area 2 of splitter group 1 of group 6 of my _getMainWindow() whose name starts with macroName)
				end try
			end tell
		end selectMacro
		
		(*
			Create a macro via the UI.
		*)
		on createMacro(macroName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (the first button of my _getMainWindow() whose description is "Add Macro")
					delay 0.1
					set value of text field 1 of scroll area 3 of splitter group 1 of group 6 of my _getMainWindow() to macroName
				end try
			end tell
		end createMacro
		
		on selectMacroGroup(groupName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click group "App: Script Editor" of scroll area 1 of splitter group 1 of group 6 of my _getMainWindow()
				end try
			end tell
		end selectMacroGroup
		
		on getSelectedGroupName()
			tell application "System Events" to tell process "Keyboard Maestro"
				name of first group of scroll area 1 of splitter group 1 of group 6 of my _getMainWindow() whose selected is true
			end tell
		end getSelectedGroupName
		
		(* 
			NOTE: Menu doesn't immediately reflect reality unless the menu was actually clicked by the user.
			
			@Test Cases:
				1 Enabled Macro Group
				1 Enabled Macro
				1 Enabled Action
				1 Disabled Macro
				1 Disabled Macro Group
				1 Disabled Action
				2 Enabled Macro Group
				2 Enabled Macro
				2 Enabled Action
				2 Disabled Macro
				2 Disabled Macro Group
				2 Disabled Action
		
			@returns "macro group", "macro", or "action" depending on the state of the menus. 
		*)
		on getFocusedType()
			if running of application "Keyboard Maestro" is false then return missing value
			
			
			-- Below fails to work from Keyboard Maestro AppleScript
			tell application "Keyboard Maestro"
				selection
				first item of result
				class of result
				return result as text
			end tell
			
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set viewMenu to menu 1 of menu bar item "View" of menu bar 1
				
				menu items of viewMenu
				
				set disableMenu to missing value
				set enableMenu to missing value
				
				try
					set disableMenu to first menu item of viewMenu whose title starts with "Disable"
				end try
				
				try
					set enableMenu to first menu item of viewMenu whose title starts with "Enable"
				end try
				
				
				
				if disableMenu is not missing value then
					logger's debugf("title: {}", title of disableMenu)
					if title of disableMenu contains "Action" then return "action"
					if title of disableMenu contains "Macro Group" then return "group"
				end if
				
				if enableMenu is not missing value then
					logger's debugf("title: {}", title of enableMenu)
					if title of enableMenu contains "Action" then return "action"
					if title of enableMenu contains "Macro Group" then return "group"
				end if
				
				(*
				if exists (first menu item of viewMenu whose title ends with "able Action") then
					return "action"
					
				else if exists (first menu item of viewMenu whose title ends with "Macro Group") then
					return "group"
					
				end if
*)
				
			end tell
			
			"macro"
		end getFocusedType
		
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
					click (first button of group 3 of my _getMainWindow() whose description is "go forward")
				end try
			end tell
		end nextEdited
		
		
		(* Click on the back macro history button. *)
		on previouslyEdited()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first button of group 3 of my _getMainWindow() whose description is "go back")
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
		
		(* @Warning - Grabs app focus *)
		on showActions()
			if running of application "Keyboard Maestro" is false then return
			tell application "System Events" to tell process "Keyboard Maestro"
				if exists (window "New Action") then return
			end tell
			
			script NewActionWindowWaiter
				tell application "System Events" to tell process "Keyboard Maestro"
					set frontmost to true
					try
						click menu item "Show Actions" of menu 1 of menu bar item "Actions" of menu bar 1
					end try
					if exists (window "New Action") then return true
				end tell
			end script
			exec of retry on result for variable_update_retry_count
		end showActions
		
		(* @Warning - Grabs app focus *)
		on hideActions()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set frontmost to true
				try
					click menu item "Hide Actions" of menu 1 of menu bar item "Actions" of menu bar 1
				end try
			end tell
		end hideActions
		
		on isActionsWindowPresent()
			if running of application "Keyboard Maestro" is false then return false
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					return exists (window "New Action")
				end try
			end tell
			false
		end isActionsWindowPresent
		
		on createTriggerLink(scriptName, params)
			set paramPart to ""
			if params is not missing value then
				set paramPart to "&value=" & textUtil's encodeUrl(params)
			end if
			
			set encodedName to textUtil's encodeUrl(scriptName)
			format {"kmtrigger://m={}{}", {encodedName, paramPart}}
		end createTriggerLink
		
		
		(* Runs a keyboard maestro macro asynchronously and plainly, no extras. *)
		on runMacro(macroName)
			script RunRetry
				tell application "Keyboard Maestro Engine" to do script macroName
				true
			end script
			exec of retry on result for 3
			delay delayAfterRun
		end runMacro
		
		(* 
			Runs a keyboard maestro macro asynchronously and plainly, no extras. *)
		on runMacroWithParameter(macroName, macroParameter)
			script RunRetry
				tell application "Keyboard Maestro Engine"
					do script macroName with parameter macroParameter
					true
				end tell
			end script
			exec of retry on result for 3
			delay delayAfterRun
		end runMacroWithParameter
		
		
		on getVariable(variableName)
			script RetrieveRetry
				tell application "Keyboard Maestro Engine" to getvariable variableName
			end script
			exec of retry on result for variable_update_retry_count
		end getVariable
		
		
		on getLocalVariable(variableName)
			script RetrieveRetry
				set kmInst to system attribute "KMINSTANCE"
				tell application "Keyboard Maestro Engine"
					return getvariable variableName instance kmInst
				end tell
			end script
			exec of retry on result for variable_update_retry_count
		end getLocalVariable
		
		
		on setLocalVariable(localVariableName, textValue)
			script RetrieveRetry
				set kmInst to system attribute "KMINSTANCE"
				tell application "Keyboard Maestro Engine"
					setvariable variableName to textValue instance kmInst
				end tell
			end script
			exec of retry on result for variable_update_retry_count
		end setLocalVariable
		
		
		(* This works only for KM global variables. *)
		on setVariable(variableName, newValue)
			script SetRetry
				tell application "Keyboard Maestro Engine" to setvariable variableName to newValue
				true
			end script
			exec of retry on result for variable_update_retry_count
		end setVariable
		
		on getEditorWindow()
			_getMainWindow()
		end getEditorWindow
		
		on _getMainWindow()
			script RetryMainWindow
				tell application "System Events" to tell process "Keyboard Maestro"
					first window whose title starts with "Keyboard Maestro Editor"
				end tell
			end script
			exec of retry on result for 3
		end _getMainWindow
	end script
	
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
