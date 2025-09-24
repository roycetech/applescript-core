(* 
	This script focuses on the Keyboard Maestro Editor and fundamental handlers 
		when working with the app.

	NOTE: Do not reference front window directly in this code because other 
		non-editor window may be active. Use the "my getEditorWindow()" instead.

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

use std : script "core/std"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

use decoratorLib : script "core/decorator"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()
if name of current application is "osascript" then unitTest()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Run Macro
		Set/Get Variable
		Placeholder (So toggle action cases are in the same set)
		
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
		Manual: Delete Variable
	")
	
	set spotScript to script "core/spot-test"
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
		
	else if caseIndex is 17 then
		sut's deleteVariable("ActionID")
		
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
			Text Expander concats the shortcut, that's why we are using the starts with to find the macro.
		*)
		on macroWithNameExists(macroName)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					first group of scroll area 2 of splitter group 1 of group 6 of my getEditorWindow() whose title starts with the macroName
					return true
				end try
			end tell
			false
		end macroWithNameExists
		
		
		
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
	end script
	
	set keyboardMaestroPreferenceVariableDecorator to script "core/dec-keyboard-maestro-preferences-variables"
	set keyboardMaestroVariablesDecorator to script "core/dec-keyboard-maestro-variables"
	set keyboardMaestroEditorDecorator to script "core/dec-keyboard-maestro-editor"
	set keyboardMaestroEditorActionsDecorator to script "core/dec-keyboard-maestro-editor-actions"
	
	keyboardMaestroPreferenceVariableDecorator's decorate(KeyboardMaestroInstance)
	keyboardMaestroVariablesDecorator's decorate(result)
	keyboardMaestroEditorDecorator's decorate(result)
	keyboardMaestroEditorActionsDecorator's decorate(result)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("KeyboardMaestroInstance")
end new
