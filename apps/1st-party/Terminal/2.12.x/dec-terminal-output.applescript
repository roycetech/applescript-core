(*
	@Build:
		make compile-lib SOURCE=apps/1st-party/Terminal/2.12.x/dec-terminal-prompt-sftp

	@Last Modified: 2023-07-29 10:52:09
*)

use listUtil : script "list"
use textUtil : script "string"
use loggerFactory : script "logger-factory"

use kbLib : script "keyboard"
use retryLib : script "retry"

use spotScript : script "spot-test"

property logger : missing value
property retry : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Recent Output
		Manual: Last Output (With/out lastCommand, Shell, Non-Shell)
		Complete Output
		Wait for Output
		Output Contains

		Clear
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set terminalLib to script "terminal"
	set terminal to terminalLib's new()
	set frontTab to terminal's getFrontTab()

	-- override the existing so we can test the current implementation.
	set frontTab to decorate(frontTab)


	if caseIndex is 1 then
		logger's infof("Recent Output: {}", frontTab's getRecentOutput())

	else if caseIndex is 2 then
		-- set frontTab's lastCommand to "ls"
		logger's infof("Last Output: {}", frontTab's getLastOutput())

	else if caseIndex is 3 then
		log sut's getOutput()

	else if caseIndex is 4 then
		sut's waitForOutput("complete")

	else if caseIndex is 5 then
		log sut's outputContains("complete")

	else if caseIndex is 6 then
		log sut's clear()

	end if

	spot's finish()
	logger's finish()
end spotCheck


on decorate(terminalTabScript)
	set retry to retryLib's new()
	set kb to kbLib's new()

	script TerminalTabInstance
		property parent : terminalTabScript

		(* Used to determine the amount of characters to include in the getRecentOutput handler. *)
		property recentOutputChars : 1024


		(*
			Most recent output trimmed by user-defined amount of characters.
		*)
		on getRecentOutput()
			tell application "Terminal"
				set theText to textUtil's rtrim(contents of selected tab of my appWindow as text)
			end tell

			if length of theText is less than my recentOutputChars then return theText
			return textUtil's substringFrom(theText, (length of theText) - (my recentOutputChars))
		end getRecentOutput


		(*
			Gets last output by finding the last command executed. If lastCommand is missing,
			the last output is based on the text between the prompt text.

			This is bloody war!

			@Test Cases:
				On Git Directory/Non Git Directory
				With/out Lingering Command -
				Shell Prompt/Non-shell prompt (awsume)
				Command did not result into output, e.g. "open ."

			@Known Issues:
				Would not work when new shell process is launched from the last command.
		*)
		on getLastOutput()
			set mainScope to me -- without this, below breaks when ran from a client script
			-- 			script RetryOnce
			tell application "Terminal"
				set theHistory to textUtil's rtrim(contents of selected tab of my appWindow as text)
			end tell

			-- logger's debugf("lastCommand internal: {}", my lastCommand)
			set lastCommand to getLastCommand()
			-- logger's debugf("lastCommand: {}", lastCommand)

			if lastCommand is not missing value and lastCommand is not "" then
				if isShellPrompt() then
					set promptText to getPromptText()
					set textAfterCommand to text 2 thru -1 of textUtil's lastStringAfter(theHistory, lastCommand)

					(* Non-output commands*)
					if promptText is equal to textAfterCommand then return missing value

					return text 1 thru (-(length of promptText) - 2) of textAfterCommand
				end if

				try
					return text 2 thru -1 of textUtil's lastStringAfter(theHistory, lastCommand)
				end try
			end if

			missing value


			(*
				-- logger's debugf("Prompt: [{}]", mainScope's getPrompt())

				set promptText to mainScope's getPromptText()
				logger's debugf("getPromptText: [{}]", promptText)
				set promptTextLines to textUtil's split(promptText, ASCII character 10)
				set promptTextLine1 to item 1 of promptTextLines
				-- logger's debugf("Prompt Text Line 1: [{}]", promptTextLine1)

				set aShellPrompt to isShellPrompt()
				logger's debugf("aShellPrompt: {}", aShellPrompt)
				if isShellPrompt() then
					set outputTokens to textUtil's split(theHistory, mainScope's getPromptText())
					set totalTokens to the number of items in outputTokens
					return item (totalTokens - 1) of outputTokens
				end if

				set outputTokens to textUtil's split(theHistory, promptTextLine1)
				return text 2 thru -1 of last item of outputTokens
*)


			-- 			end script
			-- 			exec of retry on result for 2 by 3
		end getLastOutput


		(* @returns all the output present in the tab. *)
		on getOutput()
			tell application "Terminal"
				textUtil's rtrim(history of selected tab of my appWindow as text)
			end tell
		end getOutput

		(*
			@param targetText text or list of text to wait for.
			@returns missing value on time out, otherwise the target that matched.
		*)
		on waitForOutput(targetText)
			if class of targetText is list then
				set targetList to targetText
			else
				set targetList to {targetText}
			end if

			script OutputWaiter
				repeat with nextTarget in targetList
					if outputContains(nextTarget) then return nextTarget
				end repeat
			end script
			exec of retry on result for my commandRunMax by my commandRetrySleepSeconds
		end waitForOutput

		on outputContains(targetText)
			getRecentOutput() contains targetText
		end outputContains

		(*
			Clears the terminal my sending a Command + K key stroke.
			@Requires focus, make sure to handle refocus on the client code.
		*)
		on clear()
			if isShellPrompt() then return runAndWait("clear && printf '\\e[3J'")

			focus()
			kb's pressCommandKey("k")
		end clear
	end script
end decorate
