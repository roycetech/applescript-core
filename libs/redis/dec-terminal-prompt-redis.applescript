(*
	Update the following quite obvious if you read through the template code.:
	spotCheck()
		thisCaseId
		base library instantiation

		logger constructor parameter inside init handler

	decorate()
		instance name
		handler name

	@Last Modified: 2023-07-26 15:26:41
*)

use listUtil : script "list"
use textUtil : script "string"
use regex : script "regex"

use loggerFactory : script "logger-factory"
use terminalLib : script "terminal"

use spotScript : script "spot-test"

use testLib : script "test"

property logger : missing value
property terminal : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then
	spotCheck()
end if

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Regular Shell Prompt - Yes
		Manual: Regular Shell Prompt - No
		Manual: Redis Shell Prompt - Yes
		Manual: Redis Shell Prompt - Yes With Lingering Command
		Manual: Prompt Text - Non Redis

		Manual: Prompt Text - Redis
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if


	-- activate application ""
	log name of terminal
	log name of logger of terminalLib
	set frontTab to terminal's getFrontTab()
	log frontTab
	set frontTab to decorate(frontTab)

	logger's infof("Is Shell Prompt: {}", frontTab's isShellPrompt())
	logger's infof("Prompt with text: {}", frontTab's getPromptText())
	logger's infof("Prompt: {}", frontTab's getPrompt())

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's injectBasic(me)
	set terminal to terminalLib's new()

	script TerminalTabInstance -- shadow the original
		property parent : mainScript

		(* *)
		on getPromptText()
			set {_history, lastProcess} to _getHistoryAndLastProcess()
			-- logger's debugf("lastProcess: {}", lastProcess)
			if lastProcess is "redis-cli" then
				set recentBuffer to getRecentOutput()
				set promptOnly to regex's firstMatchInString(my redisPromptPattern(), recentBuffer)
				-- logger's debugf("promptOnly: {}", promptOnly)
				set prompts to textUtil's split(recentBuffer, promptOnly)
				return promptOnly & last item of prompts
			end if

			continue getPromptText()
		end getPromptText

		(*
			@Override
		*)
		on isShellPrompt()
			set {_history, lastProcess} to _getHistoryAndLastProcess()
			if lastProcess is "redis-cli" then
				return regex's matchesInString(my redisPromptPattern() & "$", textUtil's rtrim(_history))
			end if

			continue isShellPrompt()
		end isShellPrompt


		(* Redis prompt looks like this currently: "127.0.0.1:6379>" *)
		on redisPromptPattern()
			"\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}.\\d{1,3}:\\d+>"
		end redisPromptPattern

	end script
end decorate


(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
on unitTest()
	set test to testLib's new()
	set ut to test's new()
	tell ut
		newMethod("replaceFirst")
		-- expected, actual, description
		assertEqual("three two  one", my replaceFirst("three one plus one", "one", "two"), "Happy Case")
		assertEqual("one", my replaceFirst("one", "{}", "found"), "Not Found")
		assertEqual("one", my replaceFirst("one", "three", "dummy"), "Substring is longer")

		done()
	end tell
end unitTest
