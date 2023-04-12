global std, retry, textUtil, sessionPlist
global SESSION_PLIST

(*
	@Session:
		
*)

use script "Core Text Utilities"
use scripting additions

property logger : missing value
property initialized : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "term-ext-run-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Manual: Run Shell
		Manual: Run Shell Void
		Manual: Change Directory
		Manual: Run and Wait
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	set termTabMain to std's import("terminal")'s new()
	set sut to termTabMain's getFrontTab()
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
			-- sessionPlist's removeValue(propertyName)
			sessionPlist's deleteKey(propertyName)
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
					set commandResult to sessionPlist's getValue(propertyName)
					if commandResult is not missing value and the length of commandResult is greater than 0 then return commandResult
					set theText to the history of selected tab of appWindow
					set theText to textUtil's rtrim(theText as text)
					if theText ends with " " & promptEndChar then
						logger's debug("Prompt detected and result was not returned.")
						return NO_RESULT
					end if
				end script
			end tell
			
			set waitResult to exec of retry on CommandWaiter for my commandRunMax by my commandRetrySleepSec
			if waitResult is missing value or waitResult is equal to NO_RESULT then
				logger's warn("Bash Script did not communicate OK via session.plist")
				sessionPlist's deleteKey(propertyName)
				return missing value
			end if
			
			sessionPlist's deleteKey(propertyName)
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


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-terminal-run")
	set retry to std's import("retry")'s new()
	set textUtil to std's import("string")
	set plutil to std's import("plutil")'s new()
	set sessionPlist to plutil's new("session")
	
	tell application "Finder"
		set SESSION_PLIST to text 8 thru -1 of (URL of folder "applescript-core" of (path to home folder) as text) & "session.plist"
	end tell
end init