(*
	See Stop BSS Server for the latest example usage.

	Usage:
		initMainActionsFromString("
			one,
			two
		")

	TODO:
		Sub actions.

	NOTE: Progress don't work on the Script Menu, so don't bother.
	Note: Menu cog wheel does not reflect the correct progress.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/progress

	@Migrated: Thu, Jul 31, 2025 at 10:46:46 AM
*)
use scripting additions

use script "core/Text Utilities"


use loggerFactory : script "core/logger-factory"

use listUtil : script "core/list"
use plutilLib : script "core/plutil"
use speechLib : script "core/speech"
use switchLib : script "core/switch"

property logger : missing value
property session : missing value
property speech : missing value

property SWITCH_SPEAK_PROGRESS : "app-core: Speak Progress"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		NOOP
		Main Actions
		Step
		Step with Token
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
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's initMainActionsFromString("
			one
			two
		")
		log sut's mainActions

	else if caseIndex is 3 then
		set speakStep of sut to true
		sut's initMainActionsFromString("
			one
			two
		")
		sut's step()
		sut's step()

	else if caseIndex is 4 then
		set speakStep of sut to true
		sut's initMainActions({"Hello '{}'"})

		step of sut given token:"World"
	end if

	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's inject(me)
	set plutil to plutilLib's new()
	set session to plutil's new("session")
	set speech to speechLib's new()

	script ProgressInstance
		property currentStep : 0
		property totalStep : 0
		property mainActions : missing value
		property speakStep : false
		property logging : true

		on initProgress(theTotal, theDesc, theSubDesc)
			set my totalStep to theTotal
			set progress total steps to theTotal
			set progress completed steps to 0
			set progress description to theDesc
			set progress additional description to theSubDesc
		end initProgress


		on initMainActionsFromString(actions)
			initMainActions(listUtil's splitByLine(actions))
		end initMainActionsFromString


		on initMainActions(actions)
			set my mainActions to actions
			set my totalStep to count of actions
			set my currentStep to 0

			set progress total steps to count of actions
			set progress completed steps to 0
			set progress description to "Initializing..."
			-- set progress additional description to theSubDesc
		end initMainActions

		on step given token:theToken : ""
			try
				theToken
			on error
				set theToken to ""
			end try

			set currentStep to currentStep + 1
			set progress completed steps to currentStep
			if currentStep is greater than the (count of mainActions) then
				logger's warn("You are stepping more than the number of actions that you defined. " & currentStep)
				return
			end if
			set currentAction to format {item currentStep of mainActions, theToken}

			set progress description to the currentAction

			if speakStep is true then tell speech to speakWithVolume(currentAction, 0.3)
			if logging is true then logger's info("(" & currentStep & "/" & (count of mainActions) & ") " & currentAction)
		end step


		on finish()
			set currentStep to (count of mainActions) - 1
			step()
		end finish


		(* Complicated, do not to use! *)
		on stepWithSkip(skipPrevious as boolean)
			if skipPrevious then
				set currentStep to currentStep + 1
				logger's info("(" & currentStep & "/" & (count of mainActions) & ") SKIPPED: " & item currentStep of mainActions)
			end if
			step()
		end stepWithSkip


		on nextProgress(theSubDetail)
			set currentStep to currentStep + 1
			set progress completed steps to currentStep

			set progress additional description to theSubDetail & " " & currentStep & " of " & totalStep
		end nextProgress


		on resetProgress()
			-- Reset the progress information
			set progress total steps to 0
			set progress completed steps to 0
			set progress description to ""
			set progress additional description to ""
			set currentStep to 0
		end resetProgress
	end script
end new


