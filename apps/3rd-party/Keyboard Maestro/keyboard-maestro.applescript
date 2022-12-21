global std, textUtil
global GENERIC_RESULT_VAR

(* 
	WARNING: This script is still heavily user customised, TODO: to make it more generic and document required changes to Keyboard Maestro. 
	
	Compile:
		make compile-lib SOURCE="apps/3rd-party/Keyboard Maestro/keyboard-maestro"
	
*)

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck() -- IMPORTANT: Comment out on deploy

on spotCheck()
	init()
	set thisCaseId to "spotCheck-keyboard-maestro"
	logger's start()
	
	set listUtil to std's import("list")
	set counter to std's import("counter")
	set runCount to counter's totalToday("Running: [" & thisCaseId & "]")
	set cases to listUtil's splitByLine("
		Run Unit Tests
		Safari		
		Manual: Run Macro
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		unitTest()
		
	else if caseIndex is 4 then
		sendSafariText("KM Test")
		
	else if caseIndex is 5 then
		runMacro("hello")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on createTriggerLink(scriptName, params)
	set encodedName to textUtil's encodeUrl(scriptName)
	set encodedParam to textUtil's encodeUrl(params)
	format {"kmtrigger://m={}&value={}", {encodedName, encodedParam}}
end createTriggerLink


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


-- Private Codes below =======================================================

on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("createTriggerLink")
		assertEqual("kmtrigger://m=Open%20in%20QuickNote&value=Hello%20World", my createTriggerLink("Open in QuickNote", "hello world"), "With Parameter")
		
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
	
	set GENERIC_RESULT_VAR to "km_result"
end init
