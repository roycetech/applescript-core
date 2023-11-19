(* 
	WARNING: This script is still heavily user customized, 
	TODO: to make it more generic and document required changes to Keyboard Maestro. 
	
	@Project:
		applescript-core
	
	@Build:
		make build-keyboard-maestro
		or (from the project root)
		make build-lib SOURCE="apps/3rd-party/Keyboard Maestro/keyboard-maestro"

	@Last Modified: September 9, 2023 2:43 PM
	@Change Logs:
		October 20, 2023 10:27 AM - Added focusSelectedMacroGroup().
*)

use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"
use retryLib : script "core/retry"

use decoratorLib : script "core/decorator"

use spotScript : script "core/spot-test"

property logger : missing value
property cliclick : missing value

property GENERIC_RESULT_VAR : "km_result"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()
if name of current application is "osascript" then unitTest()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Safari
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
	logger's infof("Selected Group Name: {}", sut's getSelectedGroupName())
	logger's infof("Macro with name exists (Unicorn): {}", sut's macroWithNameExists("Unicorn"))
	logger's infof("Macro with name exists yes: {}", sut's macroWithNameExists("Script Editor: Text Expander: km's getFocusedType()"))
	
	if caseIndex is 1 then
		sut's sendSafariText("KM Test")
		
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
	end if
	
	activate
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	set cliclick to cliclickLib's new()
	
	script KeyboardMaestroInstance
		
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
			@returns "group", "macro", or "action" depending on the state of the menus. 
		*)
		on getFocusedType()
			if running of application "Keyboard Maestro" is false then return missing value
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set viewMenu to menu 1 of menu bar item "View" of menu bar 1
				if exists (first menu item of viewMenu whose title ends with "able Action") then
					return "action"
					
				else if exists (first menu item of viewMenu whose title ends with "Macro Group") then
					return "group"
					
				end if
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
				set selectedGroup to the first group of scroll area 1 of splitter group 1 of group 6 of my _getMainWindow() whose selected is true
			end tell
			
			lclick of cliclick at selectedGroup
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
			
			set retry to retryLib's new()
			script NewActionWindowWaiter
				tell application "System Events" to tell process "Keyboard Maestro"
					set frontmost to true
					try
						click menu item "Show Actions" of menu 1 of menu bar item "Actions" of menu bar 1
					end try
					if exists (window "New Action") then return true
				end tell
			end script
			exec of retry on result for 3
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
		
		on createTriggerLink(scriptName, params)
			set paramPart to ""
			if params is not missing value then
				set paramPart to "&value=" & textUtil's encodeUrl(params)
			end if
			
			set encodedName to textUtil's encodeUrl(scriptName)
			format {"kmtrigger://m={}{}", {encodedName, paramPart}}
		end createTriggerLink
		
		
		(*
			TODO: move out.
		*)
		on createReadableTriggerLink(scriptName, params)
			set plusName to textUtil's replace(scriptName, " ", "+")
			set plusParams to textUtil's replace(params, " ", "+")
			if scriptName contains "Open in QuickNote" then
				return format {"note://{}", {plusParams}}
				
			else if scriptName contains "Open in Sublime Text" then
				return format {"st://{}", {plusParams}}
				
			end if
			format {"kmt://m={}&value={}", {plusName, plusParams}}
		end createReadableTriggerLink
		
		
		(* Runs a keyboard maestro macro plainly, no extras. *)
		on runMacro(macroName)
			tell application "Keyboard Maestro Engine"
				do script macroName
			end tell
		end runMacro
		
		(* Runs a keyboard maestro macro plainly, no extras. *)
		on runMacroWithParameter(macroName, macroParameter)
			tell application "Keyboard Maestro Engine"
				do script macroName with parameter macroParameter
			end tell
		end runMacroWithParameter
		
		
		(* 
			Runs a keyboard maestro macro with result tracking. 

			@returns true on successful run.
		*)
		on runScript(scriptName as text)
			-- logger's debugf("Script Name: [{}]", scriptName)
			tell application "Keyboard Maestro Engine"
				setvariable "km_result" to "false"
				do script scriptName
				set runResult to (getvariable "km_result") is equal to "true"
			end tell
			delay 0.1
			runResult
		end runScript
		
		
		(**)
		on fetchValue(scriptName)
			tell application "Keyboard Maestro Engine"
				setvariable "km_result" to "false"
				do script scriptName
				set run_result to (getvariable "km_result")
			end tell
			delay 0.1
			run_result
		end fetchValue
		
		
		(* 
			WARN: Problematic, sends text to address bar.
			@Deprecated - Do not use. Too usecase-specific.
			@returns true on successful passing of command. 
		*)
		on sendSafariText(theText as text)
			setVariable("TypeText", theText)
			runScript("App Safari Send Text")
		end sendSafariText
		
		(*
		(*
			Note: Still fails silently, retry mitigates the issue.
			@returns true on successful passing of command.
		*)
		on sendSlackText(theText as text)
			if runScript("App Slack Prepare For Automation") is false then -- reduce the macro to simply check if input box is ready.
				set cq to std's importx("command-queue")
				
				logger's info("Slack seems unready, registering command...")
				cq's add("slack-command", theText)
				return false
			end if
			
			setVariable("TypeText", theText)
			if runScript("App Slack Send Text") is false then
				logger's warnf("Failed to send text: '{}', Slack may have a draft message", theText)
				return false
			end if
			
			if runScript("App Slack Click Send") is false then
				logger's debug("Failed to click the Slack send button")
				return false
			end if
			
			return true
			
			tell application "Keyboard Maestro Engine"
				do script "App Slack Prepare For Automation"
				delay 0.1
				if (getvariable "automation_status" as text) is not "ready" then
				end if
				
				setvariable "TypeText" to theText
				do script "App Slack Send Text"
				delay 0.5 -- 0.2 fails intermittently. 0.3 failed on first morning run 0.4 failed TTW meeting.
				set hasEmoji to theText contains ":"
				if hasEmoji then delay 0.4 -- increment by 0.1 until it becomes more reliable.
				
				setvariable "TypeText" to return
				do script "App Slack Send Text"
				delay 0.5 -- Fix attempt.
				logger's debugf("Invoking: '{}'", "App Slack Click Send")
				do script "App Slack Click Send" -- To ensure send in case the above fails. Silently fails.
				
				true
			end tell
		end sendSlackText
		*)
		
		on getVariable(variableName)
			tell application "Keyboard Maestro Engine" to getvariable variableName
		end getVariable
		
		
		on getLocalVariable(variableName)
			set kmInst to system attribute "KMINSTANCE"
			tell application "Keyboard Maestro Engine"
				getvariable variableName instance kmInst
			end tell
		end getLocalVariable
		
		
		(* This works only for KM global variables. *)
		on setVariable(variableName, newValue)
			tell application "Keyboard Maestro Engine" to setvariable variableName to newValue
		end setVariable
		
		
		on _getMainWindow()
			tell application "System Events" to tell process "Keyboard Maestro"
				first window whose title is not "New Action"
			end tell
		end _getMainWindow
		
	end script
	
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new

