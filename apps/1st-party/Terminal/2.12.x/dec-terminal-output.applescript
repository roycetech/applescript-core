global std, retry, textUtil, kb

(*
		
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dec-terminal-output-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Manual: Recent Output
		Manual: Last Output
		Complete Output
		Wait for Output
		Output Contains

		Clear
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	set termTabMain to std's import("terminal")'s new()
	set frontTab to termTabMain's getFrontTab()
	
	-- override the existing so we can test the current implementation.	
	set frontTab to decorate(frontTab)
	
	
	if caseIndex is 1 then
		logger's infof("Recent Output: {}", frontTab's getRecentOutput())
		
	else if caseIndex is 2 then
		set frontTab's lastCommand to "ls"
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


on decorate(termTabScript)
	script TermExtOutput
		property parent : termTabScript
		
		(* Used to determine the amount of characters to include in the getRecentOutput handler. *)
		property recentOutputChars : 300
		
		
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
			Gets last output by finding the last command executed. The amount of result is limited to the user defined limit on the number of characters for the recent output.
			
			@Known Issues:
				Would not work when new shell process is launched from the last command.
		*)
		on getLastOutput()
			script RetryOnce
				tell application "Terminal"
					set theHistory to textUtil's rtrim(contents of selected tab of my appWindow as text)
				end tell
				logger's debugf("lastCommand: {}", my lastCommand)
				logger's debugf("Prompt Text: {}", my getPromptText())
				
				set commandIdx to textUtil's lastIndexOf(theHistory, my lastCommand)
				set promptIdx to (textUtil's lastIndexOf(theHistory, my getPromptText())) - (length of my getPromptText())
				
				if commandIdx > 0 then
					return textUtil's substring(theHistory, commandIdx + 2, promptIdx - 1)
				end if
				
				return theHistory
			end script
			exec of retry on result for 2 by 3
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
			exec of retry on result for my commandRunMax by my commandRetrySleepSec
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


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-terminal-output")
	set retry to std's import("retry")'s new()
	set textUtil to std's import("string")
	set kb to std's import("keyboard")'s new()
end init
