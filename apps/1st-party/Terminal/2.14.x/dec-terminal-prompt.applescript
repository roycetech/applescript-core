(*
	@Purpose:
		This script incorporates handlers that encompass the terminal's prompt.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-prompt

	@Migrated:
		September 25, 2023 12:19 PM
*)

use scripting additions

use script "core/Text Utilities"

use std : script "core/std"
use listUtil : script "core/list"
use textUtil : script "core/string"
use regex : script "core/regex"
use unic : script "core/unicodes"
use extOutput : script "core/dec-terminal-output"
use fileUtil : script "core/file"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use terminalLib : script "core/terminal"

use spotScript : script "core/spot-test"

property logger : missing value
property retry : missing value
property terminal : missing value

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
	terminal's getFrontTab()
	decorate(result)
	set sut to extOutput's decorate(result)

	----------------------------------------------------------------------------
	-- Check: zsh, bash, docker with/out command, redis, sftp, EC2 ssh
	logger's infof("Is Shell Prompt: {}", sut's isShellPrompt())

	----------------------------------------------------------------------------
	-- Check (Git/Non Git, With/out Parens, With/out Lingering Command)
	logger's infof("Prompt: [{}]", sut's getPrompt())
	logger's infof("Prompt With Command (if command is present): {}", sut's getPromptText())


	logger's infof("Is SSH: {}", sut's isSSH())
	logger's infof("Is zsh: {}", sut's isZsh())
	logger's infof("Is bash: {}", sut's isBash())

	logger's infof("Git directory?: [{}]", sut's isGitDirectory())

	logger's infof("Last Command: [{}]", sut's getLastCommand())

	if caseIndex is 2 then
		(* Can use "sleep 5" to test. *)
		sut's waitForPrompt()

	end if

	spot's finish()
	logger's finish()
end spotCheck


on decorate(termTabScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set terminal to terminalLib's new()

	set computedDefaultPrompt to short user name of (system info) & "@" & textUtil's stringBefore(host name of (system info), ".local")
	-- logger's debugf("computedDefaultPrompt: {}", computedDefaultPrompt)

	script TerminalPromptDecorator
		property parent : termTabScript
		property defaultPrompt : computedDefaultPrompt


		on ec2SSHPromptPattern()
			"\\[.+\\]\\$$"
		end ec2SSHPromptPattern


		(*

		*)
		on isGitDirectory()
			fileUtil's posixFolderPathExists(getPosixPath() & "/.git")
		end isGitDirectory


		on isSSH()
			-- regex's matchesInString(ec2SSHPromptPattern(), getRecentOutput())

			tell application "Terminal"
				set termProcesses to processes of selected tab of front window
				last item of termProcesses is "ssh"
			end tell
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
			-- logger's info("isShellPrompt...")
			set {history, lastProcess} to _getHistoryAndLastProcess()

			if isSSH() then return true

			if isZsh() then
				-- logger's debug("zsh...")
				set promptText to getPromptText()
				-- logger's debugf("promptText: {}", promptText)

				if promptText is missing value then return false

				-- logger's debugf("defaultPrompt: {}", defaultPrompt)

				set atHomePath to getPosixPath() is equal to "/Users/" & std's getUsername()
				-- logger's debugf("atHomePath: {}", atHomePath)

				if atHomePath and promptText is equal to defaultPrompt & " ~ %" then return true

				return promptText is equal to defaultPrompt & " " & getDirectoryName() & " %"
			end if

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
			-- logger's debugf("recentBuffer: {}", recentBuffer)

			set position to textUtil's lastIndexOf(recentBuffer, my defaultPrompt)
			-- logger's debugf("position: {}", position)

			if position is not 0 then
				set promptText to (text position thru -1 of recentBuffer)
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

			@returns the detected last command after the prompt.
			This can be the last executed command or an unexecuted command in the buffer. It can also be missing value if only a prompt is in the output.
		*)
		on getLastCommand()
			set recentBuffer to getRecentOutput()

			set prompt to getPrompt()
			-- logger's debugf("prompt: {}", prompt)
			if prompt is missing value then return missing value
			-- logger's debugf("defaultPrompt: {}", defaultPrompt)

			set rawList to textUtil's split(recentBuffer, defaultPrompt)
			set outputTokens to _removeDirectory(rawList)
			set tokenCount to the count of outputTokens

			-- repeat with nextToken in outputTokens
			-- log nextToken
			-- end repeat

			set aShellPrompt to isShellPrompt()
			-- logger's debugf("isShellPrompt(): {}", aShellPrompt)
			if aShellPrompt then
				set subject to item (tokenCount - 1) of outputTokens
				-- logger's debugf("subject: {}", subject)

				set subjectLines to textUtil's split(subject, ASCII character 10)
				try
					-- return text 2 thru -1 of first item of subjectLines
					return first item of subjectLines
				on error -- when only the prompt line is in the output.
					return missing value
				end try
			end if

			set recentBuffer to getPromptText()
			set firstLine to first item of textUtil's split(recentBuffer, ASCII character 10)
			-- logger's debugf("firstLine: {}", firstLine)
			-- logger's debugf("recentBuffer: {}", recentBuffer)
			-- logger's debugf("getPrompt(): {}", getPrompt())

			set promptLess to textUtil's replace(firstLine, getPrompt(), "")
			-- logger's debugf("promptLess: {}", promptLess)

			if promptLess is "" then return missing value

			set replaceResult to text 2 thru -1 of promptLess
			if replaceResult is "" then return missing value

			return replaceResult
		end getLastCommand

		on _removeDirectory(theList)
			set cleanList to {}
			repeat with nextElement in theList
				-- logger's debugf("nextElement: {}", nextElement)
				if nextElement contains "%" then
					set cleanELement to textUtil's stringAfter(nextElement, "% ")
					if cleanELement is missing value then set cleanELement to ""
				else
					set cleanELement to the nextElement
				end if

				set cleanELement to textUtil's rtrim(cleanELement)
				set end of cleanList to the cleanELement
			end repeat

			cleanList
		end _removeDirectory

		(*
			@Test Cases
				Git directory (with/out command)
				Non-git directory (with/out command)
				Directory name with space (with/out command)
				User home directory (with/out command)

			@returns the prompt without the lingering command text.

			Trailing space is included when present.
		*)
		on getPrompt()
			if not isShellPrompt() then
				-- logger's debug("Non-shell")
				if getPromptText() is missing value then return missing value

				set firstLine to first item of textUtil's split(my getPromptText(), ASCII character 10)
				-- logger's debugf("firstLine: {}", firstLine)

				set directoryName to getDirectoryName()
				-- logger's debugf("directoryName: {}", directoryName)

				if getPosixPath() is equal to "/Users/" & std's getUsername() then
					return text 1 thru ((offset of "~" in firstLine) + 2) of firstLine
				end if

				set directoryNameLength to the length of directoryName
				set directoryNameOffset to offset of directoryName in firstLine
				return text 1 thru (directoryNameLength + directoryNameOffset + 1) of firstLine
			end if

			set lingeringText to getLingeringCommand()
			-- logger's debugf("lingeringText: {}", lingeringText)

			if lingeringText is missing value then return getPromptText()

			set promptAndCommand to getPromptText()
			text 1 thru (-(length of lingeringText) - 2) of promptAndCommand
		end getPrompt
	end script
end decorate
