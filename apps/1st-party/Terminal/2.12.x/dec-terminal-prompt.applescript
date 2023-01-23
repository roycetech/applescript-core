global std, retry, textUtil, uni, regex

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dec-terminal-prompt-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Manual: Is Shell Prompt - zsh/bash/docker - manual switch
		Manual: Wait for Prompt
		Manual: Prompt Text
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set extOutput to std's import("dec-terminal-output")
	set termTabMain to std's import("terminal")'s new()
	termTabMain's getFrontTab()
	set frontTab to decorate(result)
	set sut to extOutput's decorate(result)
	
	if caseIndex is 1 then
		logger's infof("Is Shell Prompt: {}", frontTab's isShellPrompt())
		
		
	else if caseIndex is 2 then
		(* Can use "sleep 5" to test. *)
		sut's waitForPrompt()
		
	else if caseIndex is 3 then
		logger's infof("Prompt Text: {}", sut's getPromptText())
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on decorate(termTabScript)
	script TermExtPrompt
		property parent : termTabScript
		
		on waitForPrompt()
			script PromptWaiter
				if isShellPrompt() then return true
			end script
			tell retry to exec on PromptWaiter for 60 by 1
		end waitForPrompt
		
		
		(* Based on default implementation.  Override if you have specific theme. *)
		on isShellPrompt()
			if isZsh() then
				set promptText to getPromptText()
				if promptText is missing value then return false
				
				if promptText is uni's OMZ_ARROW & "  ~" then return true
				
				set tokens to {uni's OMZ_ARROW, uni's OMZ_GIT_X}
				set gitPattern to format {"{}  [a-zA-Z0-9\\s_-]+\\sgit:\\([a-zA-Z0-9/\\$_()-]+\\)(?: {})?$", tokens}
				set promptGit to regex's matchesInString(gitPattern, promptText)
				set promptNonGit to regex's matchesInString(uni's OMZ_ARROW & "  [a-zA-Z0-9-\\s\\.@]+$", promptText)
				return promptGit or promptNonGit
			end if
			
			tell application "Terminal"
				set theText to the history of selected tab of my appWindow
				set termProcesses to processes of selected tab of my appWindow
			end tell
			
			set theText to textUtil's rtrim(theText as text)
			set isSsh to last item of termProcesses is "ssh"
			set isDocker to last item of termProcesses is "com.docker.cli"
			-- ssh prompt can be # or $.
			isDocker or isSsh and ((theText ends with "#") or (theText ends with "$")) or theText ends with my promptEndChar or regex's matchesInString("bash-\\d(?:\\.\\d)?[#\\$]$", theText)
		end isShellPrompt
		
		
		(* @returns the prompt text along with any of the lingering commands typed that hasn't executed. *)
		on getPromptText()
			if not isZsh() then 
				logger's warn("Bash is not yet implemented.")
				return missing value
			end if
				
			set recentBuffer to getRecentOutput()
			
			set position to textUtil's lastIndexOf(recentBuffer, uni's OMZ_ARROW)
			if position is not 0 then
				return text position thru -1 of recentBuffer
			end if
			
			missing value
		end getPromptText
	end script
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-terminal-prompt")
	set retry to std's import("retry")'s new()
	set textUtil to std's import("string")
	set uni to std's import("unicodes")
	set regex to std's import("regex")
end init
