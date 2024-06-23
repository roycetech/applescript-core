(*
	@Purpose:
		Handles the default oh-my-zsh.  https://ohmyz.sh

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-prompt-omz

	@Refactored Out:
		Wednesday, May 15, 2024 at 10:53:05 PM
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use listUtil : script "core/list"
use textUtil : script "core/string"
use regex : script "core/regex"
use fileUtil : script "core/file"
use omz : script "core/oh-my-zsh"
use extOutput : script "core/dec-terminal-output"
use extPrompt : script "core/dec-terminal-prompt"
use extPath : script "core/dec-terminal-path"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use terminalLib : script "core/terminal"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value
property terminal : missing value

property TERMINAL_START_TEXT : "Last Login:"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: INFO
		Manual: Wait for Shell Prompt
	")

	(*
		Manual: Wait for Prompt
		Manual: Prompt With Command (Git/Non Git, Parens, Lingering Command)
		Manual: Is Git Directory (yes, no)

		Manual: Last Command (Git/Non, With/out, Waiting for MFA)
	*)

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set terminal to terminalLib's new()
	set terminalTab to terminal's getFrontTab()

	if terminalTab is missing value then
		activate application "Terminal"
		delay 1
		set terminalTab to terminal's getFrontTab()

	end if

	assertThat of std given condition:terminalTab is not missing value, messageOnFail:"terminalTab is missing value!"

	extOutput's decorate(terminalTab)
	extPrompt's decorate(result)
	extPath's decorate(result)
	set frontTab to decorate(result)

	-- Check (Git/Non Git, With/out Parens, With/out Lingering Command)
	logger's infof("Prompt: [{}]", frontTab's getPrompt())
	logger's infof("Prompt With Command (if command is present): {}", frontTab's getPromptText())

	-- Check: zsh, bash, docker with/out command, redis, sftp, EC2 ssh
	logger's infof("Is Shell Prompt: {}", frontTab's isShellPrompt())

	logger's infof("Is SSH: {}", frontTab's isSSH())
	logger's infof("Is zsh: {}", frontTab's isZsh())
	logger's infof("Is bash: {}", frontTab's isBash())

	-- logger's infof("Git directory?: [{}]", sut's isGitDirectory())

	logger's infof("Lingering Command: [{}]", frontTab's getLingeringCommand())
	logger's infof("Last Command: [{}]", frontTab's getLastCommand())

	if caseIndex is 2 then
		(* Can use "sleep 5" to test. *)
		frontTab's waitForPrompt()

	end if

	spot's finish()
	logger's finish()
end spotCheck


on decorate(termTabScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	-- set terminal to terminalLib's new()

	set computedDefaultPrompt to omz's OMZ_ARROW & "  "
	-- logger's debugf("computedDefaultPrompt: {}", computedDefaultPrompt)
	script TerminalPromptOmzDecorator
		property parent : termTabScript

		property defaultPrompt : computedDefaultPrompt
		property promptMarker : omz's OMZ_ARROW & "  "


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
			set isShell to isShellPrompt()
			-- logger's debugf("isShell: {}", isShell)

			set prompt to getPrompt()
			-- logger's debugf("prompt: {}", prompt)
			if prompt is missing value then return missing value

			set recentBuffer to getRecentOutput()
			set outputTokens to textUtil's split(recentBuffer, promptMarker)
			if the number of items in outputTokens is less than 2 then return missing value

			set currentPromptLine to item -1 of outputTokens
			-- logger's debugf("currentPromptLine: {}", currentPromptLine)

			set isGit to isGitDirectory()
			-- logger's debugf("isGit: {}", isGit)

			set currentDirectory to getDirectoryName()
			-- logger's debugf("currentDirectory: {}", currentDirectory)

			set lingeringCommand to getLingeringCommand()
			-- logger's debugf("lingeringCommand: {}", lingeringCommand)

			if lingeringCommand is not missing value then
				-- log "Case 4: Shell, non-git, with lingering command"
				return lingeringCommand
			end if

			if not isShell and isGit and currentPromptLine does not end with omz's GIT_X then
				-- log "Case 1: Non-shell, git directory, with command"
				return textUtil's stringAfter(currentPromptLine, omz's GIT_X & " ")
			end if

			if not isShell and currentPromptLine does not end with currentDirectory then
				-- log "Case 2: Non-shell, non-git directory, with command"
				return textUtil's stringAfter(currentPromptLine, currentDirectory & " ")
			end if

			if not isShell and not isGit then
				-- log "Case 3: Non-shell, non-git, process running"
				return textUtil's stringAfter(currentPromptLine, currentDirectory & " ")

			end if

			set previousLine to item -2 of outputTokens
			-- logger's debugf("previousLine: {}", previousLine)

			if previousLine is "" then return missing value

			set isCd to previousLine contains " cd "
			if isCd then
				-- log "Case 5: cd command"
				return "cd " & textUtil's rtrim(textUtil's stringAfter(previousLine, " cd "))
			end if

			if isGit then
				-- log "Case 6: Non-Shell, Git"
				set previousLines to textUtil's split(previousLine, ASCII character 10)
				return textUtil's stringAfter(item 1 of previousLines, omz's GIT_X & " ")
			else
				-- log "Case 5: Non-Shell, Non-Git"

				set isCd to previousLine contains " cd "
				if isCd then
					-- log "Case 5.a: cd command"
					return "cd " & textUtil's rtrim(textUtil's stringAfter(previousLine, " cd "))
				end if

				-- log "Case 7: non-cd command"
				set markerLessPrompt to textUtil's stringAfter(prompt, promptMarker)
				-- logger's debugf("markerLessPrompt: {}", markerLessPrompt) --

				set previousLines to textUtil's split(previousLine, ASCII character 10)
				return textUtil's stringAfter(item 1 of previousLines, markerLessPrompt & " ")
			end if
		end getLastCommand


		on _lastCommandShell()

		end _lastCommandShell


		on _lastCommandNonShell()

		end _lastCommandNonShell


		on hasLingeringCommand()
			getLingeringCommand() is not missing value
		end hasLingeringCommand


		on getLingeringCommand()
			if isShellPrompt() then return missing value

			set recentBuffer to getPromptText()
			if recentBuffer is missing value then return missing value

			if isBash() then
				if recentBuffer does not contain promptEndChar then return missing value
				if recentBuffer ends with my promptEndChar then return missing value
				return textUtil's substringFrom(recentBuffer, (textUtil's lastIndexOf(recentBuffer, my promptEndChar)) + 2)
			end if

			-- zsh
			set tokens to {omz's OMZ_ARROW, omz's OMZ_GIT_X}
			set gitPromptPattern to format {"{}  [0-9a-zA-Z_\\s-\\.]+\\sgit:\\([a-zA-Z0-9/_\\.()-]+\\)(?: {})?\\s?", tokens}
			set gitPattern to gitPromptPattern & ".+$" -- with a typed command

			set promptGit to regex's matchesInString(gitPattern, recentBuffer)

			-- logger's debugf("gitPromptPattern: {}", gitPromptPattern)
			-- logger's debugf("gitPattern: {}", gitPattern)
			-- logger's debugf("promptGit: {}", promptGit)
			-- logger's debugf("recentBuffer: {}", recentBuffer)

			if regex's matchesInString(gitPattern, recentBuffer) then
				set lingeringCommand to regex's stringByReplacingMatchesInString(gitPromptPattern, recentBuffer, "")
				if lingeringCommand is "" then set lingeringCommand to missing value
				return lingeringCommand
			end if

			set dirName to getDirectoryName()
			-- logger's debugf("dirName: {}", dirName)

			if dirName is equal to std's getUsername() then set dirName to "~"
			-- logger's debugf("dirName: {}", dirName)

			ignoring case
				if recentBuffer ends with dirName then return missing value
			end ignoring

			regex's firstMatchInStringNoCase("(?<=" & dirName & "\\s)[\\w\\s-]+$", recentBuffer)
		end getLingeringCommand

		(*
			@Overridable

			The implementation depends on your current bash or zsh theme.
		*)
		on gitPromptPattern()
			set tokens to {omz's OMZ_ARROW, omz's OMZ_GIT_X}
			format {"{}  [0-9a-zA-Z_\\s-\\.]+\\sgit:\\([a-zA-Z0-9/_\\.()-]+\\)(?: {})?\\s?", tokens}
		end gitPromptPattern


		on ec2SSHPromptPattern()
			"\\[.+\\]\\$$"
		end ec2SSHPromptPattern

		(*
			@Overridable

			Includes the space suffix.
		*)
		on getNonGitPrefix()
			omz's OMZ_ARROW & "  "
		end getNonGitPrefix


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

			tell application "Terminal"
				if busy of tab 1 of my appWindow then return false
			end tell

			set {history, lastProcess} to _getHistoryAndLastProcess()

			-- if last item of termProcesses is "redis-cli" then
			-- 	return regex's matchesInString(redisPromptPattern() & "$", textUtil's rtrim(theText as text))
			-- end if

			if isSSH() then
				return true

			else if isZsh() then
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
			-- logger's debugf("localIsSsh: {}", localIsSsh)
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
			if not isZsh() then
				logger's warn("Bash is not yet implemented.")
				return missing value
			end if

			set recentBuffer to getRecentOutput()

			set position to textUtil's lastIndexOf(recentBuffer, omz's OMZ_ARROW) -- TODO: Move out.
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


		on _removeDirectoryAndGit(theList)
			set cleanList to {}
			set currentDirectoryName to getDirectoryName()
			log currentDirectoryName
			repeat with nextElement in theList
				logger's debugf("nextElement: {}", nextElement)
				if nextElement contains omz's OMZ_GIT_X then
					set cleanELement to textUtil's stringAfter(nextElement, omz's OMZ_GIT_X & " ")
					if cleanELement is missing value then set cleanELement to ""
				else
					set cleanELement to the nextElement
				end if
				logger's debugf("cleanElement: {}", cleanELement)

				if cleanELement contains "~" then set cleanELement to text 3 thru -1 of cleanELement
				set cleanELement to textUtil's replace(cleanELement, currentDirectoryName & " ", "")

				set cleanELement to textUtil's rtrim(cleanELement)
				if cleanELement is not "" then set end of cleanList to the cleanELement
			end repeat

			cleanList
		end _removeDirectoryAndGit

		(*
			@returns the prompt without the lingering command text.
			Trailing space is included when present.
		*)
		on getPrompt()
			-- logger's debug("getPrompt...")
			if isGitDirectory() then
				-- logger's debug("Git Directory...")
				set promptText to getPromptText()
				-- logger's debugf("promptText: {}", promptText)
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
				return text 1 thru (directoryNameLength + directoryNameOffset + 1) of firstLine
			end if

			set lingeringText to getLingeringCommand()
			-- logger's debugf("lingeringText: {}", lingeringText)
			if lingeringText is missing value then
				return getPromptText()
			end if

			set promptAndCommand to getPromptText()
			text 1 thru (-(length of lingeringText) - 2) of promptAndCommand
		end getPrompt
	end script
end decorate
