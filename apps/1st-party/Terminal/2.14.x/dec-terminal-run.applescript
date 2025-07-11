(*
	@Purpose:
		This script integrates handlers that encompass the run capabilities of the terminal.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/dec-terminal-run

	@Migrated:
		Sunday, January 28, 2024 at 2:45:58 PM
*)

use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use plutilLib : script "core/plutil"
use finderLib : script "core/finder"

property logger : missing value
property retry : missing value
property plutil : missing value
property terminal : missing value
property finder : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Run Shell
		Manual: Run Shell Void
		Manual: Change Directory
		Manual: Run and Wait
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set terminalLib to script "core/terminal"
	set terminal to terminalLib's new()
	set sut to terminal's getFrontTab()
	set sut to decorate(sut)

	if caseIndex is 1 then
		log sut's runShell("docker ps -qf 'ancestor=roycetech/minecraft-server'")

		-- logger's infof("Run echo command result: {}", sut's runShell("echo hello"))

	else if caseIndex is 2 then
		sut's runShellVoid("echo world")

	else if caseIndex is 3 then
		sut's doCd("~/Desktop")

	else if caseIndex is 4 then
		sut's runAndWait("sleep 5")

	end if

	spot's finish()
	logger's finish()
end spotCheck


on decorate(termTabScript)
	loggerFactory's inject(me)

	set retry to retryLib's new()
	set plutil to plutilLib's new()
	set session to plutil's new("session")
	set finder to finderLib's new()

	tell application "Finder"
		set localSessionPlist to text 8 thru -1 of (URL of folder "applescript-core" of finder's getHomeFolder() as text) & "session.plist"
	end tell

	script TerminalRunDecorator
		property parent : termTabScript
		property SESSION_PLIST : localSessionPlist
		property delayAfterRunShell : 0

		(*
			Runs a bash command waiting for its result.

			@bashCommand bash command that returns a value.
			@propertyName session key name to be used to store the result temporarily.

			@return the result of the bash command.
		*)
		on runShell(shellCommand)
			set lastCommand to shellCommand
			set propertyName to format {"runShell-{}", my getTabName()}
			-- logger's debugf("Using session property: {}", propertyName)
			-- session's removeValue(propertyName)
			session's deleteKey(propertyName)
			-- logger's debugf("Running Command: \"{}\"", bashCommand)

			set calcCommmand to format {"plutil -replace {} -string \"`{}`\" {}", {quoted form of propertyName, shellCommand, SESSION_PLIST}}
			-- logger's debugf("Calculated Command: {}", calcCommmand)
			set NO_RESULT to "_noresult_"
			tell application "Terminal"
				if my refreshPrompt then
					do script "" in appWindow
					delay 0.2
				end if
				do script calcCommmand in my appWindow
				script CommandWaiter
					set commandResult to session's getValue(propertyName)
					if commandResult is not missing value and the length of commandResult is greater than 0 then return commandResult
					set theText to the history of selected tab of appWindow
					set theText to textUtil's rtrim(theText as text)
					if theText ends with " " & promptEndChar then
						logger's debug("Prompt detected and result was not returned.")
						return NO_RESULT
					end if
				end script
			end tell

			set waitResult to exec of retry on CommandWaiter for my commandRunMax by my commandRetrySleepSeconds
			if waitResult is missing value or waitResult is equal to NO_RESULT then
				logger's warn("Bash Script did not communicate OK via session.plist")
				session's deleteKey(propertyName)
				return missing value
			end if

			session's deleteKey(propertyName)
			return waitResult
		end runShell

		(*
			Runs a shell command without waiting for the result

			@Known Issue:
				Beeps when doing a multi-line echo command. Solved, you need
				to avoid indentation using the tab character. You may indent
				using spaces instead.
		*)
		on runShellVoid(shellCommand)
			set lastCommand to shellCommand
			tell application "Terminal"
				if my refreshPrompt then
					do script "" in my appWindow
					delay 0.2
				end if
				do script shellCommand in my appWindow
			end tell

			delay delayAfterRunShell
		end runShellVoid

		on runAndWait(shellCommand)
			runShellVoid(shellCommand)
			delay 0.2 -- experiment from 0.1, SSH to EC2 stack on new install is crappy.
			waitForPrompt()
			_refreshTabName()
			delay 0.2 -- Seems to solve mysterious issues. 0.1 has issues, finding BSS stack reports incorrect result.
		end runAndWait

		on doCd(thePath)
			tell application "Terminal" to do script "cd " & thePath in my appWindow
			waitForPrompt()
			_refreshTabName()
		end doCd
	end script
end decorate
