(*
	@Purpose:
		refactored AppleScript-specific handlers to reduce automator.applescript file size.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Automator/2.10/dec-automator-applescript

	@Created: Monday, July 22, 2024 at 10:55:15 PM
	@Last Modified: 2024-09-28 13:44:42
	@Change Logs:
*)

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"

property logger : missing value
property usr : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/automator"
	set sut to sutLib's new()
	set sut to decorate(sut)

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set usr to usrLib's new()

	script AutomatorAppleScriptDecorator
		property parent : mainScript
		(* Allow override of the domain destination, e.g. Speech works only on user domain. *)
		property domainKeyOverride : missing value

		(*
			RTFC. Dynamically determines the deployment script path.

			@ projectPathKey - this is the key in config-user.plist which points to the path of the project containing the script.
			@resourcePath - the script path name relative to the project.
		*)
		on writeRunScript(appScriptName)
			if running of application "Automator" is false then return

				set domainObjectKey to getDomainKey()
			tell application "System Events" to tell process "Automator"
				-- set the code
				set theCodeTextArea to text area 1 of scroll area 1 of splitter group 1 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)

				-- set appScriptMon to path of (library folder of domainObject) & SUBMON_APP_SCRIPT & appScriptName & ".scpt"
				set appScriptMon to "(path of library folder of (" & domainObjectKey & " domain) & \"Script Libraries:core:app:" & appScriptName & ".scpt\")"
				-- logger's debugf("appScriptMon: {}", appScriptMon)

				set value of theCodeTextArea to "
use scripting additions

on run {input, parameters}
	(* Your script goes here *)
	tell application \"System Events\"
		run script alias " & appScriptMon & "
	end tell
	return input
end run
"
			end tell
		end writeRunScript

		(* @returns "local" or "user" *)
		on getDomainKey()
			if my domainKeyOverride is not missing value then return my domainKeyOverride
			if usr's isLocalDeployment() then return "local"

			"user"
		end getDomainKey


		on compileScript()
			if running of application "Automator" is false then return

			tell application "System Events" to tell process "Automator"
				click button 4 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
			end tell
		end compileScript
	end script
end decorate
