global std, retry, textUtil, uni, regex

use script "Core Text Utilities"
use scripting additions

(*
	@Known Issues:
		
*)

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
		Manual: Is Shell Prompt - zsh/bash/docker with/out command
		Manual: Wait for Prompt
		Manual: Prompt With Command (Git/Non Git, Parens, Lingering Command)
		Manual: Prompt (Git/Non Git, With/out Parens, With/out Lingering Command)
		Manual: Is Git Directory (yes, no)
		
		Manual: Last Command (Git/Non, With/out)
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
		logger's infof("Prompt With Command (if command is present): {}", sut's getPromptText())
		
	else if caseIndex is 4 then
		logger's infof("Prompt: [{}]", sut's getPrompt())
		
	else if caseIndex is 5 then
		logger's infof("Git directory?: [{}]", sut's isGitDirectory())
		
	else if caseIndex is 6 then
		logger's infof("Last Command: [{}]", sut's getLastCommand())
		logger's infof("Prompt: [{}]", sut's getPrompt())
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on decorate(termTabScript)
	script TermExtPrompt
		property parent : termTabScript
		
		(*
			@Overridable
			
			The implementation depends on your current bash or zsh theme.
		*)
		on gitPromptPattern()
			set tokens to {uni's OMZ_ARROW, uni's OMZ_GIT_X}
			format {"{}  [0-9a-zA-Z_\\s-]+\\sgit:\\([a-zA-Z0-9/_\\.()-]+\\)(?: {})?\\s?", tokens}
		end gitPromptPattern
		
		(*
			@Overridable
			
			Includes the space suffix.
		*)
		on getNonGitPrefix()
			uni's OMZ_ARROW & "  "
		end getNonGitPrefix
		
		
		(*
			
		*)
		on isGitDirectory()
			set fileUtil to std's import("file")
			return fileUtil's posixFolderPathExists(getPosixPath() & "/.git")
			
			set subjectLine to getPromptText()
			logger's debugf("subjectLine: {}", subjectLine)
			
			if isShellPrompt() is false then
				log 4
				set subjectLine to first item of textUtil's split(my getPromptText(), ASCII character 10)
			end if
			log 3
			
			set gitPattern to gitPromptPattern()
			regex's matchesInString(gitPattern, subjectLine)
		end isGitDirectory
		
		
		on waitForPrompt()
			script PromptWaiter
				if isShellPrompt() then return true
			end script
			tell retry to exec on PromptWaiter for 60 by 1
		end waitForPrompt
		
		
		(* 
			Based on default implementation.  Override if you have specific theme. 
			
			@Test Cases:
				Zsh
				Bash
				With Lingering Command
				Without Lingering Command
				Non-Shell Prompt
				Non Git
				Git
		*)
		on isShellPrompt()
			-- logger's debugf("isZsh: {}", isZsh())
			if isZsh() then
				set promptText to getPromptText()
				if promptText is missing value then return false
				
				if promptText is equal to getNonGitPrefix() & "~" then return true
				set promptGit to regex's matchesInString(gitPromptPattern() & "$", promptText)
				-- set promptGit to regex's matchesInString(gitPromptPattern(), promptText)
				-- logger's debugf("promptGit: {}", promptGit)
				set promptNonGit to regex's matchesInString(getNonGitPrefix() & "[a-zA-Z0-9-\\s\\.@]+$", promptText)
				-- logger's debugf("promptNonGit: {}", promptNonGit)
				return promptGit or promptNonGit and promptText ends with getDirectoryName()
			end if
			
			tell application "Terminal"
				set theText to the history of selected tab of my appWindow
				set termProcesses to processes of selected tab of my appWindow
			end tell
			
			set theText to textUtil's rtrim(theText as text)
			set isSsh to last item of termProcesses is "ssh"
			-- logger's debugf("isSsh: {}", isSsh)
			set isDocker to last item of termProcesses is "com.docker.cli"
			-- logger's debugf("isDocker: {}", isDocker)
			-- ssh prompt can be # or $.
			-- logger's debugf("my promptEndChar: {}", my promptEndChar)
			set isSshShell to isSsh and ((theText ends with "#") or (theText ends with "$"))
			-- logger's debugf("isSshShell: {}", isSshShell)
			isDocker and theText ends with "#" or isSshShell or theText ends with my promptEndChar or regex's matchesInString("bash-\\d(?:\\.\\d)?[#\\$]$", theText)
		end isShellPrompt
		
		
		on getPromptWithCommand()
			getPromptText()
		end getPromptWithCommand
		
		
		(* @returns the prompt text along with any of the lingering commands typed that hasn't executed. *)
		on getPromptText()
			if not isZsh() then
				logger's warn("Bash is not yet implemented.")
				return missing value
			end if
			
			set recentBuffer to getRecentOutput()
			set position to textUtil's lastIndexOf(recentBuffer, uni's OMZ_ARROW)
			if position is not 0 then
				set promptText to text position thru -1 of recentBuffer
				if promptText is equal to getNonGitPrefix() & getDirectoryName() then return promptText
				return promptText
			end if
			
			missing value
		end getPromptText
		
		
		(*
			How is last command different from the unexecuted command?
				> 
		
			@returns the detected last command after the prompt. 
			This can be the last executed command or an unexecuted command in the buffer. It can also be missing value if only a prompt is in the output.
			
			@Test Cases:
				Lingering command are treated as the last command. (e.g. c:> last command)
				If shell prompt, the previous command is considered. 
					example:
						c:> echo test
						test
						c:>
					# The last command is the "echo test"
				If non-shell prompt, the text after the prompt is considered.
					example:
						c:> start server
							Listening on port 1234...
					# The last command is the "start server"
			
			@Steps:
				1. Split by prompt
				2.a If is shell:
					Get second to the last token
					Get first line
					Get text after the prompt
				2.c else
					Get last token
					Get first line
					Get text after the prompt
			
			NOTE: This is not the same with the internal lastCommand on the original design.
		*)
		on getLastCommand()
			set recentBuffer to getRecentOutput()
			
			set prompt to getPrompt()
			if prompt is missing value then return missing value
			
			set outputTokens to textUtil's split(recentBuffer, getPrompt())
			set tokenCount to the count of outputTokens
			-- log getPrompt()
			
			-- repeat with nextToken in outputTokens
			-- log nextToken
			-- end repeat
			
			set aShellPrompt to isShellPrompt()
			-- logger's debugf("isShellPrompt(): {}", aShellPrompt)
			if isShellPrompt() then
				set subject to item (tokenCount - 1) of outputTokens
				set subjectLines to textUtil's split(subject, ASCII character 10)
				try
					return text 2 thru -1 of first item of subjectLines
				on error -- when only the prompt line is in the output.
					return missing value
				end try
			end if
			
			set recentBuffer to getPromptText()
			set firstLine to first item of textUtil's split(recentBuffer, ASCII character 10)
			-- logger's debugf("firstLine: {}", firstLine)
			-- logger's debugf("recentBuffer: {}", recentBuffer)
			
			set replaceResult to text 2 thru -1 of textUtil's replace(firstLine, getPrompt(), "")
			if replaceResult is "" then return missing value
			
			return replaceResult
			-- end if
			
			missing value
		end getLastCommand
		
		
		(* 
			@returns the prompt without the lingering command text. 
			Trailing space is included when present. 
		*)
		on getPrompt()
			if isGitDirectory() then
				set promptText to getPromptText()
				if promptText is missing value then return missing value -- Can't retrieve if current output is too big.
				
				set lastCommand to regex's stringByReplacingMatchesInString(gitPromptPattern(), promptText, "")
				if lastCommand is not "" then return text 1 thru -2 of textUtil's replace(promptText, lastCommand, "")
				return promptText
			end if
			
			if isShellPrompt() is false then
				set firstLine to first item of textUtil's split(my getPromptText(), ASCII character 10)
				return firstLine
			end if
			
			set lingeringText to getLingeringCommand()
			-- logger's debugf("lingeringText: {}", lingeringText)
			if lingeringText is missing value then return getPromptText()
			
			set promptAndCommand to getPromptText()
			text 1 thru (-(length of lingeringText) - 2) of promptAndCommand
		end getPrompt
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
