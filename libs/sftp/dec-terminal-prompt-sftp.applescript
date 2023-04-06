global std, regex, textUtil

(*
	@Plists:
		config-user.plist
			Terminal Tab Decorators - This decorator must be appended to this 
				array to be active.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dec-terminal-prompt-sftp-spotCheck"
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
		Manual: Prompt Text - Non SFTP
		Manual: Prompt Text - SFTP
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
	
	(*
	log frontTab's sftpPromptPattern()
	log frontTab's isBash()
	log frontTab's isZsh()
*)
	
	logger's infof("Is SFTP: {}", frontTab's isSFTP())
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
		
		on getPrompt()
			if isSFTP() then
				return sftpPromptPattern()
			end if
			
			continue getPrompt()
		end getPrompt
		
		
		(* *)
		on getPromptText()
			set {_history, lastProcess} to _getHistoryAndLastProcess()
			-- logger's debugf("lastProcess: {}", lastProcess)
			if lastProcess is "ssh" then
				set recentBuffer to getRecentOutput()
				set promptOnly to regex's firstMatchInString(my sftpPromptPattern(), recentBuffer)
				-- logger's debugf("promptOnly: {}", promptOnly)
				set prompts to textUtil's split(recentBuffer, promptOnly)
				return promptOnly & last item of prompts
			end if
			
			continue getPromptText()
		end getPromptText
		
		
		on isSFTP()
			if getPromptText() contains sftpPromptPattern() then return true
			
			set {_history, lastProcess} to _getHistoryAndLastProcess()
			
			lastProcess is "sftp"
		end isSFTP
		
		
		on getLastOutput()
			if isShellPRompt() is false then return missing value
			
			continue getLastOutput()
		end
		
		(*
			@Override
		*)
		on isShellPrompt()
			set {_history, lastProcess} to _getHistoryAndLastProcess()
			-- logger's debugf("lastProcess: {}", lastProcess)
			
			if lastProcess is "ssh" then
				return regex's matchesInString(my sftpPromptPattern() & "$", textUtil's rtrim(_history))
			end if
			
			continue isShellPrompt()
		end isShellPrompt
		
		
		(* SFTP prompt looks like this currently: "sftp>" *)
		on sftpPromptPattern()
			"sftp>"
		end sftpPromptPattern
		
	end script
end decorate


-- Private Codes below =======================================================



(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-terminal-prompt-sftp")
	set regex to std's import("regex")
	set textUtil to std's import("string")
end init
