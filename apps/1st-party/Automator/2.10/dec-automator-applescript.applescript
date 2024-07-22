(*
	@Purpose:
		refactored AppleScript-specific handlers to reduce automator.applescript file size.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Automator/2.10/dec-automator-applescript

	@Created: Monday, July 22, 2024 at 10:55:15 PM
	@Last Modified: 2024-07-22 23:09:41
	@Change Logs:
*)
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"

property logger : missing value
property usr : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

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

		(*
			@ projectPathKey - this is the key in config-user.plist which points to the path of the project containing the script.
			@resourcePath - the script path name relative to the project.
		*)
		on writeRunScript(appScriptName)
			if running of application "Automator" is false then return


			tell application "System Events" to tell process "Automator"
				-- set the code
				set theCodeTextArea to text area 1 of scroll area 1 of splitter group 1 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
				set deploymentType to usr's getDeploymentType()

				tell application "System Events"
					if deploymentType is "computer" then
						set domainObjectKey to "local"
					else
						set domainObjectKey to "user"
					end if
				end tell

				-- set appScriptMon to path of (library folder of domainObject) & SUBMON_APP_SCRIPT & appScriptName & ".scpt"
				set appScriptMon to "(path of library folder of (" & domainObjectKey & " domain) & \"Script Libraries:core:app:" & appScriptName & ".scpt\")"
				logger's debugf("appScriptMon: {}", appScriptMon)

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


		on compileScript()
			if running of application "Automator" is false then return

			tell application "System Events" to tell process "Automator"
				click button 4 of group 1 of list 1 of scroll area 1 of splitter group 1 of splitter group 1 of window (my newWindowName)
			end tell
		end compileScript
	end script
end decorate
