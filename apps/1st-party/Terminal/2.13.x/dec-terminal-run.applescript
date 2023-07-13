(*
	@Session:
		
*)

use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"
use textUtil : script "string"

use loggerLib : script "logger"
use retryLib : script "retry"
use plutilLib : script "plutil"
use terminalLib : script "terminal"

use spotScript : script "spot-test"

property logger : loggerLib's new("dec-terminal-run")
property retry : retryLib's new()
property plutil : plutilLib's new()
property terminal : terminalLib's new()

property session : plutil's new("session")

property SESSION_PLIST : missing value

tell application "Finder"
	set my SESSION_PLIST to text 8 thru -1 of (URL of folder "applescript-core" of (path to home folder) as text) & "session.plist"
end tell

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Run Shell
		Manual: Run Shell Void
		Manual: Change Directory
		Manual: Run and Wait
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to terminal's getFrontTab()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		logger's infof("Run echo command result: {}", sut's runShell("echo hello"))
		
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
	script TerminalTabInstance
		property parent : termTabScript
		
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
