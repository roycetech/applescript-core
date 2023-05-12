global std, speech, listUtil

use script "Core Text Utilities"
use scripting additions

property logger : missing value
property initialized : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dialog-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set cases to listUtil's splitByLine("
		Show 2 Choices
		Manual: Show 2 Choices with Timeout (Timeout/Non-Timeout)
		Manual: Show Warning with Timeout
		Manual: Confirm Warning
		Manual: Show 3 Choices

		Manual: Confirm with Timeout (Yes, No, Timeout)
		Manual: Show 2 Choices with default
		Manual: Show choices from a list (Options: missing value, empty, happy, mismatch-default)
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to new()
	if caseIndex is 1 then
		logger's infof("You chose: {}", sut's showChoices("Multiple Choices", "Pick which?", {"Me", "You"}))
		
	else if caseIndex is 2 then
		logger's infof("You chose: {}", sut's showChoicesWithTimeout("Multiple Choices", "Pick which?", {"Me", "You"}, "Me", 5))
		
	else if caseIndex is 3 then
		set speechOn of sut to true
		sut's showWarningWithTimeout("Test recommended", "Test Subject changed, re-run test", 5)
		
	else if caseIndex is 4 then
		log sut's confirmWarning("Spot Check Title", "Spot Check Description")
		
	else if caseIndex is 5 then
		log sut's showChoices("Multiple Choices", "Pick which?", {"Client ID", "Phone ID", "Cancel"})
		
	else if caseIndex is 6 then
		logger's infof("Result: {}", sut's confirmWarningWithTimeout("Auto Join is off", "Join?", 8))
		
	else if caseIndex is 7 then
		logger's infof("Result: {}", sut's showChoicesWithDefault("Choices with default", "Choose", {"Yes", "No"}, "No"))
		
	else if caseIndex is 8 then
		set utLib to std's import("unit-test")
		set ut to utLib's new()
		
		set optionsList to {"Option 1", "Option 2", "Option 3"}
		try
			logger's infof("Result: {}", sut's showChoicesFromList("Options from list", "Choose", missing value, missing value))
			ut's fail("Expected error was not encountered")
		on error the errorMessage number the errorNumber
			if errorMessage starts with "Assertion" then
				error errorMessage
			end if
		end try
		
		try
			logger's infof("Result: {}", sut's showChoicesFromList("Options from list", "Choose", {}, missing value))
			ut's fail("Expected error was not encountered")
		on error the errorMessage number the errorNumber
			if errorMessage starts with "Assertion" then
				error errorMessage
			end if
		end try
		
		logger's infof("Result: {}", sut's showChoicesFromList("Options from list", "Choose", optionsList, "Option 2"))
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script DialogInstance
		property speechOn : false
		
		on showChoicesFromList(title, message, optionsList, defaultChoice)
			assertThat of std given condition:optionsList is not missing value, messageOnFail:"optionsList must be a valid list " & optionsList
			
			if defaultChoice is missing value or listUtil's listContains(optionsList, defaultChoice) is false then
				set chosenOption to choose from list optionsList with prompt "Please choose an option:" without multiple selections allowed and empty selection allowed
			else
				set chosenOption to choose from list optionsList with prompt "Please choose an option:" default items defaultChoice without multiple selections allowed and empty selection allowed
			end if
			
			if chosenOption is false then return missing value
			
			item 1 of chosenOption
		end showChoicesFromList
		
		
		on showOkDialog(theTitle, message)
			if speech is true then
				set synchronous of speech to false
				tell speech to speakAndLog(message)
			end if
			
			display dialog message with title theTitle with icon 1 buttons {"OK"}
			-- giving up after 10
		end showOkDialog
		
		
		on showWarningWithTimeout(theTitle, message, timeoutSec)
			if speech is true then
				set synchronous of speech to false
				tell speech to speakAndLog(message)
			end if
			
			set titleWithTimeout to format {"{} (autoclose in {}s)", {theTitle, timeoutSec}}
			display dialog message with title titleWithTimeout with icon 2 buttons {"OK"} giving up after timeoutSec
		end showWarningWithTimeout
		
		
		(* @choices up to 3 choices to be shown as buttons for quick response. *)
		on showChoices(theTitle, message, choices as list)
			if (count of choices) is greater than 3 then tell me to error "You can only have up to 3 choices"
			
			if speech is true then
				set synchronous of speech to false
				tell speech to speakAndLog(message)
			end if
			
			display dialog message with title theTitle with icon 1 buttons choices
			button returned of result
		end showChoices
		
		
		(* @choices up to 3 choices to be shown as buttons for quick response. *)
		on showChoicesWithDefault(theTitle, message, choices as list, defaultButton)
			if (count of choices) is greater than 3 then tell me to error "You can only have up to 3 choices"
			
			if speech is true then
				set synchronous of speech to false
				tell speech to speakAndLog(message)
			end if
			
			display dialog message with title theTitle with icon 1 buttons choices default button defaultButton
			button returned of result
		end showChoicesWithDefault
		
		
		(* @choices up to 3 choices to be shown as buttons for quick response. *)
		on showChoicesWithTimeout(theTitle, message, choices as list, defaultChoice, timeoutSec)
			if (count of choices) is greater than 3 then tell me to error "You can only have up to 3 choices"
			
			if speech is true then
				set synchronous of speech to false
				tell speech to speakAndLog(message)
			end if
			
			display dialog message with title theTitle with icon 1 buttons choices default button defaultChoice giving up after timeoutSec
			set response to button returned of result
			if response is "" then return defaultChoice
			
			response
		end showChoicesWithTimeout
		
		
		
		(* @return boolean *)
		on confirmWarning(theTitle as text, yourMessage as text)
			display alert theTitle message yourMessage as critical buttons {"Yes", "No"} default button "no"
			button returned of result is equal to "Yes"
		end confirmWarning
		
		
		(* 
			@return boolean or missing value on timeout.
		*)
		on confirmWarningWithTimeout(theTitle as text, yourMessage as text, timeoutSec)
			display alert theTitle message yourMessage as critical buttons {"Yes", "No"} default button "no" giving up after timeoutSec
			if gave up of result then 
				missing value
			else
			button returned of result is equal to "Yes"
			end if
		end confirmWarningWithTimeout
		
		
		on showWarningDialog(theTitle, message)
			if speech is true then
				set synchronous of speech to false
				tell speech to speakAndLog(message)
			end if
			
			display dialog message with title theTitle with icon 2 buttons {"OK"}
		end showWarningDialog
	end script
end new



-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dialog")
	set speech to std's import("speech")'s new()
	set listUtil to std's import("list")
end init