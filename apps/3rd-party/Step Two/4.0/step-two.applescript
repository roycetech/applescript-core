(*
	@Prerequisites
		Running of the Step Two app must be managed by the client script.

	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Step Two/4.0/step-two'

	@Usage:
		if running of application "Step Two" is false then 
			activate application "Step Two"
		else
			dock's clickApp("Step Two")
		end if

		set OtpRetriever of otpUser to stepTwo's newRetriever("credKeyHere")
		otpUser's executeExample()
*)
use scripting additions
use std : script "core/std"

use listUtil : script "core/list"
use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

use processLib : script "core/process"
use dateTimeLib : script "core/date-time"
use spotScript : script "core/spot-test"

property logger : missing value
property dateTime : missing value

property APP_NAME : "Step Two"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Filter(Found, Empty)
		Manual: Get OTP (Empty, Non-Empty)
		Manual: Get Front Window
		Manual: OTP Retriever
		Manual: Clear Filter
		
		Manual: Get OTP by Cred Key (Found, Not Found)
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set plutilLib to script "core/plutil"
	set plutil to plutilLib's new()
	set session to plutil's new("session")
	set spotUsername to session's getValue("AWS_USER_NAME")
	logger's debugf("spotUsername: {}", spotUsername)
	
	set sut to new()
	if caseIndex is 1 then
		sut's clearFilter()
		-- sut's filter("xxx")
		sut's filter("VPN")
		-- sut's filter(spotUsername)
		
	else if caseIndex is 2 then
		set secondsUntilNext to sut's getSecondsRemaining()
		if secondsUntilNext is less than 2 then delay secondsUntilNext
		logger's debugf("OTP: {}", sut's getFirstOTP())
		
	else if caseIndex is 3 then
		set frontWindow to sut's getFrontWindow()
		assertThat of std given condition:frontWindow is not missing value, messageOnFail:"Front Window is missing value"
		logger's info("Passed.")
		
	else if caseIndex is 4 then
		set otpRetriever to sut's newRetriever(spotUsername)
		set otp to otpRetriever's getOTP()
		logger's debugf("otp: {}", otp)
		assertThat of std given condition:otp is not missing value, messageOnFail:"Failed spot check"
		logger's info("Passed.")
		
	else if caseIndex is 5 then
		sut's clearFilter()
		
	else if caseIndex is 6 then
		set secondsUntilNext to sut's getSecondsRemaining()
		if secondsUntilNext is less than 2 then delay secondsUntilNext
		logger's debugf("OTP: {}", sut's getOtpByCredKey("VPN"))
		
	end if
	
	spot's finish()
	
	logger's finish()
end spotCheck


on newRetriever(credKey)
	script OtpRetrieverInstance
		
		(*
			@returns a OTP with more than 2 seconds time remaining, and 
			minimizing the Step Two app window before returning the otp.
		*)
		on getOTP()
			if running of application "Step Two" is false then
				activate application "Step Two"
			else
				tell application "System Events" to tell process "Dock"
					perform action "AXPress" of UI element "Step Two" of list 1
				end tell
			end if
			
			local stepTwo
			set stepTwo to new()
			set secondsUntilNext to stepTwo's getSecondsRemaining()
			if secondsUntilNext is less than 2 then
				logger's infof("{} second/s to expire, waiting for the next...", secondsUntilNext)
				delay secondsUntilNext
			end if
			
			stepTwo's clearFilter()
			set otp to stepTwo's getOtpByCredKey(credKey)
			
			-- Below fails to work on actual script.
			set stepTwoProc to processLib's new("Step Two")
			-- stepTwoProc's minimize()
			stepTwoProc's terminate()
			
			otp
		end getOTP
	end script
	
end newRetriever


(*  *)
on new()
	if std's appExists("Step Two") is false then error "Step Two app was not found"
	
	loggerFactory's inject(me)
	set dateTime to dateTimeLib's new()
	
	script StepTwoInstance
		(* 
			@Deprecated
			Unreliable, setting the field with a text does not trigger a filter. 
		*)
		on filter(filterKey)
			set frontWindow to _getFrontWindow()
			if running of application APP_NAME is false then return
			
			tell application "System Events" to tell process "Step Two"
				set value of text field 1 of frontWindow to filterKey
			end tell
		end filter
		
		
		on clearFilter()
			tell application "System Events" to tell process "Step Two"
				try
					click button 2 of text field 1 of front window
				end try -- Ignore error when search field is blank and clear button is absent.
			end tell
		end clearFilter
		
		
		on getOtpByCredKey(credKey)
			tell application "System Events" to tell process "Step Two"
				set accountGroups to groups of list 1 of list 1 of scroll area 1 of front window
			end tell
			try
				repeat with nextGroup in accountGroups
					tell application "System Events" to tell process "Step Two"
						set nextDesc to description of UI element 1 of nextGroup
					end tell
					
					-- logger's debugf("nextDesc: {}", nextDesc)
					
					if nextDesc contains credKey then
						set tokens to textUtil's split(nextDesc, ",")
						return textUtil's replace(last item of tokens, " ", "")
					end if
				end repeat
			on error the errorMessage number the errorNumber
				logger's warn(errorMessage)
			end try
			
			missing value
		end getOtpByCredKey
		
		on getFirstOTP()
			if running of application APP_NAME is false then return missing value
			
			tell application "System Events" to tell process "Step Two"
				try
					first UI element of group 1 of list 1 of list 1 of scroll area 1 of my _getFrontWindow()
					set tokens to textUtil's split(description of result as text, ",")
				on error
					return missing value
				end try
			end tell
			
			textUtil's replace(last item of tokens, " ", "")
		end getFirstOTP
		
		
		on getSecondsRemaining()
			30 - (3rd word of dateTime's cleanTimeString(time string of (current date)) as integer) mod 30
		end getSecondsRemaining
		
		
		(* This handler is to address an error through re-launch when the app becomes inaccessible after some time. *)
		on _getFrontWindow()
			if running of application "Step Two" is false then
				activate application "Step Two"
				delay 0.1
			end if
			try
				tell application "System Events" to tell process "Step Two"
					return front window
				end tell
			end try
			
			set processStepTwo to processLib's new("Step Two")
			processStepTwo's terminate()
			activate application "Step Two"
			delay 0.1
			tell application "System Events" to tell process "Step Two"
				return front window
			end tell
		end _getFrontWindow
	end script
end new
