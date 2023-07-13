use script "Core Text Utilities"
use scripting additions

(*
		@Build:
			make compile-lib SOURCE=apps/1st-party/Terminal/2.12.x/dec-terminal-prompt
*)

use listUtil : script "list"
use textUtil : script "string"
use fileUtil : script "file"
use regex : script "regex"
use unic : script "unicodes"
use decTerminalOutput : script "dec-terminal-output"

use loggerFactory : script "logger-factory"

use retryLib : script "retry"
use terminalLib : script "terminal"

use spotScript : script "spot-test"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Is Shell Prompt - zsh, bash, docker with/out command, redis, sftp, EC2 ssh
		Manual: Wait for Prompt
		Manual: Prompt With Command (Git/Non Git, Parens, Lingering Command)
		Manual: Prompt (Git/Non Git, With/out Parens, With/out Lingering Command)
		Manual: Is Git Directory (yes, no)
		
		Manual: Last Command (Git/Non, With/out, Waiting for MFA)
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set terminal to terminalLib's new()
	terminal's getFrontTab()
	set frontTab to decorate(result)
	set sut to decTerminalOutput's decorate(result)
	
	if caseIndex is 1 then
		logger's infof("Is Shell Prompt: {}", frontTab's isShellPrompt())
		logger's infof("Is SSH: {}", frontTab's isSSH())
		logger's infof("Is zsh: {}", frontTab's isZSH())
		logger's infof("Is bash: {}", frontTab's isBash())
		
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
	loggerFactory's injectBasic(me, "dec-terminal-prompt")
	set retry to retryLib's new()
	
	script TerminalTabInstance
		property parent : termTabScript
		
		(*
			@Overridable
			
			The implementation depends on your current bash or zsh theme.
		*)
		on gitPromptPattern()
			set tokens to {unic's OMZ_ARROW, unic's OMZ_GIT_X}
			format {"{}  [0-9a-zA-Z_\\s-]+\\sgit:\\([a-zA-Z0-9/_\\.()-]+\\)(?: {})?\\s?", tokens}
		end gitPromptPattern
		
		
		on ec2SSHPromptPattern()
			"\\[.+\\]\\$$"
		end ec2SSHPromptPattern
		
		(*
			@Overridable
			
			Includes the space suffix.
		*)
		on getNonGitPrefix()
			unic's OMZ_ARROW & "  "
		end getNonGitPrefix
		
		
		(*
			
		*)
		on isGitDirectory()
			-- logger's debug("isGitDirectory...")
			return fileUtil's posixFolderPathExists(getPosixPath() & "/.git")
			
			set subjectLine to getPromptText()
			-- logger's debugf("subjectLine: {}", subjectLine)
			
			if isShellPrompt() is false then
				set subjectLine to first item of textUtil's split(my getPromptText(), ASCII character 10)
			end if
			
			set gitPattern to gitPromptPattern()
			regex's matchesInString(gitPattern, subjectLine)
		end isGitDirectory
		
		
		on isSSH()
			regex's matchesInString(ec2SSHPromptPattern(), getRecentOutput())
		end isSSH
		
		
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
				Zsh on Home Path ~
		*)
		on isShellPrompt()
			-- logger's debugf("isZsh: {}", isZsh())
			
			-- tell application "Terminal"
			-- 	set theText to the history of selected tab of my appWindow
			-- 	set termProcesses to processes of selected tab of my appWindow
			-- end tell
			
			set {history, lastProcess} to _getHistoryAndLastProcess()
			
			-- if last item of termProcesses is "redis-cli" then
			-- 	return regex's matchesInString(redisPromptPattern() & "$", textUtil's rtrim(theText as text))
			-- end if
			
			if isSSH() then
				return true
				
			else if isZSH() then
				-- logger's debug("zsh...")
				set promptText to getPromptText()
				-- logger's debugf("promptText: {}", promptText)
				if promptText is missing value then return false
				
				if promptText is equal to getNonGitPrefix() & "~" then return true
				set promptGit to regex's matchesInString(gitPromptPattern() & "$", promptText)
				-- set promptGit to regex's matchesInString(gitPromptPattern(), promptText)
				-- logger's debugf("promptGit: {}", promptGit)
				set promptNonGit to regex's matchesInString(getNonGitPrefix() & "[a-zA-Z0-9-\\s\\.@]+$", promptText)
				-- logger's debugf("promptNonGit: {}", promptNonGit)
				return promptGit or promptNonGit and promptText ends with getDirectoryName()
			end if
			-- logger's debug("non-zsh...")
			
			
			set rtrimmedHistory to textUtil's rtrim(history as text)
			-- set isSsh to last item of termProcesses is "ssh"
			set localIsSSH to lastProcess is "ssh"
			-- logger's debugf("localIsSSH: {}", localIsSSH)
			-- set isDocker to last item of termProcesses is "com.docker.cli"
			set isDocker to lastProcess is "com.docker.cli"
			-- logger's debugf("isDocker: {}", isDocker)
			-- ssh prompt can be # or $.
			-- logger's debugf("my promptEndChar: {}", my promptEndChar)
			set isSshShell to localIsSSH and ((rtrimmedHistory ends with "#") or (rtrimmedHistory ends with "$"))
			-- logger's debugf("isSshShell: {}", isSshShell)
			isDocker and rtrimmedHistory ends with "#" or isSshShell or rtrimmedHistory ends with my promptEndChar or regex's matchesInString("bash-\\d(?:\\.\\d)?[#\\$]$", rtrimmedHistory)
		end isShellPrompt
		
		
		on getPromptWithCommand()
			getPromptText()
		end getPromptWithCommand
		
		
		(* 
			@returns the prompt text along with any of the lingering commands typed that hasn't executed. 
		*)
		on getPromptText()
			-- logger's debug("getPromptText...")
			if not isZSH() then
				logger's warn("Bash is not yet implemented.")
				return missing value
			end if
			
			set recentBuffer to getRecentOutput()
			
			-- tell application "Terminal"
			-- 	set theText to the history of selected tab of my appWindow
			-- 	set termProcesses to processes of selected tab of my appWindow
			-- end tell
			
			
			
			
			
			set position to textUtil's lastIndexOf(recentBuffer, unic's OMZ_ARROW) -- TODO: Move out.
			-- logger's debugf("position: {}", position)
			if position is not 0 then
				set promptText to text position thru -1 of recentBuffer
				if promptText is equal to getNonGitPrefix() & getDirectoryName() then return promptText
				return promptText
			end if
			
			missing value
		end getPromptText
		
		
		(* @returns the history and last process *)
		on _getHistoryAndLastProcess()
			tell application "Terminal"
				set termProcesses to processes of selected tab of my appWindow
				{the history of selected tab of my appWindow, last item of termProcesses}
			end tell
		end _getHistoryAndLastProcess
		
		
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
			-- logger's debugf("prompt: {}", prompt)
			if prompt is missing value then return missing value
			
			set outputTokens to textUtil's split(recentBuffer, prompt)
			set tokenCount to the count of outputTokens
			
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
			-- logger's debugf("getPrompt(): {}", getPrompt())
			
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
			-- logger's debug("Git Prompt...")
			if isGitDirectory() then
				-- logger's debug("Git Directory...")
				set promptText to getPromptText()
				if promptText is missing value then return missing value -- Can't retrieve if current output is too big.				
				
				set lastCommand to regex's stringByReplacingMatchesInString(gitPromptPattern(), promptText, "")
				-- logger's debugf("lastCommand: {}", lastCommand)
				if lastCommand is not "" then return text 1 thru -2 of textUtil's replace(promptText, lastCommand, "")
				return promptText
			end if
			
			if isShellPrompt() is false then
				-- logger's debug("Non-shell")
				set firstLine to first item of textUtil's split(my getPromptText(), ASCII character 10)
				set directoryName to getDirectoryName()
				-- logger's debugf("firstLine: {}", firstLine)
				set directoryNameLength to the length of directoryName
				set directoryNameOffset to offset of directoryName in firstLine
				return text 1 thru (directoryNameLength + directoryNameOffset - 1) of firstLine
			end if
			
			set lingeringText to getLingeringCommand()
			-- logger's debugf("lingeringText: {}", lingeringText)
			if lingeringText is missing value then return getPromptText()
			
			set promptAndCommand to getPromptText()
			text 1 thru (-(length of lingeringText) - 2) of promptAndCommand
		end getPrompt
	end script
end decorate
