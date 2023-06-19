global std, textUtil, unic
global GENERIC_RESULT_VAR

(* 
	WARNING: This script is still heavily user customised, TODO: to make it more generic and document required changes to Keyboard Maestro. 
	
	Compile:
		make compile-lib SOURCE="apps/3rd-party/Keyboard Maestro/keyboard-maestro"
		or (from the project root)
		make install-keyboard-maestro
	
*)

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()
if name of current application is "osascript" then unitTest()

on spotCheck()
	init()
	set thisCaseId to "spotCheck-keyboard-maestro"
	logger's start()
	
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Run Unit Tests
		Safari
		Manual: Run Macro
		Set/Get Variable
		Placeholder (So toggle action cases are in the same set)
		
		Manual: Editor: Show Actions
		Manual: Editor: Hide Actions
		Manual: Get Current Item Name
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		unitTest()
		
	else if caseIndex is 2 then
		sut's sendSafariText("KM Test")
		
	else if caseIndex is 3 then
		sut's runMacro("hello")
		
	else if caseIndex is 4 then
		sut's setVariable("from Script Editor Name", "from Script Editor Value 1")
		assertThat of std given condition:sut's getVariable("from Script Editor Name") is equal to "from Script Editor Value 1", messageOnFail:"Failed spot check"
		sut's setVariable("from Script Editor Name", "from Script Editor Value 2")
		assertThat of std given condition:sut's getVariable("from Script Editor Name") is equal to "from Script Editor Value 2", messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	else if caseIndex is 6 then
		sut's showActions()
		
	else if caseIndex is 7 then
		sut's hideActions()
		
	else if caseIndex is 8 then
		logger's infof("Handler result: {}", sut's getCurrentItemName())
		
	end if
	
	activate
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script KeyboardMaestroInstance
	
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
		
		
		(* @Warning - Grabs app focus *)
		on showActions()
			if running of application "Keyboard Maestro" is false then return
			
			activate application "Keyboard Maestro"
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click menu item "Show Actions" of menu 1 of menu bar item "Actions" of menu bar 1
				end try
			end tell
		end showActions
		
		(* @Warning - Grabs app focus *)
		on hideActions()
			if running of application "Keyboard Maestro" is false then return
			
			activate application "Keyboard Maestro"
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click menu item "Hide Actions" of menu 1 of menu bar item "Actions" of menu bar 1
				end try
			end tell
		end hideActions
		
		(*
			TODO: move out.
		*)
		on createTriggerLink(scriptName, params)
			set encodedName to textUtil's encodeUrl(scriptName)
			set encodedParam to textUtil's encodeUrl(params)
			format {"kmtrigger://m={}&value={}", {encodedName, encodedParam}}
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
			@returns true on successful passing of command. 
		*)
		on sendSafariText(theText as text)
			setVariable("TypeText", theText)
			runScript("App Safari Send Text")
		end sendSafariText
		
		
		(*
			Note: Still fails silently, retry mitigates the issue.
			@returns true on successful passing of command.
		*)
		on sendSlackText(theText as text)
			if runScript("App Slack Prepare For Automation") is false then -- reduce the macro to simply check if input box is ready.
				set cq to std's import("command-queue")
				
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
		
		
		on getVariable(varName)
			tell application "Keyboard Maestro Engine" to getvariable varName
		end getVariable
		
		
		on setVariable(varName, newValue)
			tell application "Keyboard Maestro Engine" to setvariable varName to newValue
		end setVariable
	end script
end new

-- Private Codes below =======================================================

on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	set sut to new()
	tell ut
		newMethod("createTriggerLink")
		assertEqual("kmtrigger://m=Open%20in%20QuickNote&value=Hello%20World", sut's createTriggerLink("Open in QuickNote", "hello world"), "With Parameter")
		
		ut's done()
	end tell
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("keyboard-maestro")
	set textUtil to std's import("string")
	set unic to std's import("unicodes")
	
	set GENERIC_RESULT_VAR to "km_result"
end init
