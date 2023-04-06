global std, regex, textUtil

(*
	Update the following quite obvious if you read through the template code.:
	spotCheck()
		thisCaseId
		base library instantiation

	init()
		logger constructor parameter inside init handler

	decorate()
		instance name
		handler name

*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dec-terminal-prompt-redis-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Regular Shell Prompt - Yes
		Manual: Regular Shell Prompt - No
		Manual: Redis Shell Prompt - Yes
		Manual: Redis Shell Prompt - Yes With Lingering Command
		Manual: Prompt Text - Non Redis
		Manual: Prompt Text - Redis
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sut to std's import("terminal")'s new()
	set frontTab to sut's getFrontTab()
	set frontTab to decorate(frontTab)
	
	logger's infof("Is Shell Prompt: {}", frontTab's isShellPrompt())
	logger's infof("Prompt with text: {}", frontTab's getPromptText())
	logger's infof("Prompt: {}", frontTab's getPrompt())
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
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


-- Private Codes below =======================================================

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("replaceFirst")
		-- expected, actual, description
		assertEqual("three two  one", my replaceFirst("three one plus one", "one", "two"), "Happy Case")
		assertEqual("one", my replaceFirst("one", "{}", "found"), "Not Found")
		assertEqual("one", my replaceFirst("one", "three", "dummy"), "Substring is longer")
		
		ut's done()
	end tell
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-terminal-prompt-redis")
	set regex to std's import("regex")
	set textUtil to std's import("string")
end init
