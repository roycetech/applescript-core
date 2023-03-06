global std, textUtil, proc
global APP_NAME

(*
	@Prerequisites
		Running of the Step Two app must be managed by the client script.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "step-two-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Filter(Found, Empty)
		Manual: Get OTP (Empty, Non-Empty)
		Manual: Get Front Window
		Manual: OTP Retriever
		Manual: Clear Filter
		
		Manual: Get OTP by Cred Key (Found, Not Found)
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseIndex is 1 then
		-- sut's filter("xxx")
		sut's filter("VPN")
		
	else if caseIndex is 2 then
		set secondsUntilNext to sut's getSecondsRemaining()
		if secondsUntilNext is less than 2 then delay secondsUntilNext
		logger's debugf("OTP: {}", sut's getFirstOTP())
		
	else if caseIndex is 3 then
		set frontWindow to sut's getFrontWindow()
		assertThat of std given condition:frontWindow is not missing value, messageOnFail:"Front Window is missing value"
		logger's info("Passed.")
		
	else if caseIndex is 4 then
		set otpRetriever to sut's newRetriever("VPN")
		assertThat of std given condition:otpRetriever's getOTP() is not missing value, messageOnFail:"Failed spot check"
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
		on getOTP()
			local stepTwo
			set stepTwo to new()
			set secondsUntilNext to stepTwo's getSecondsRemaining()
			if secondsUntilNext is less than 2 then
				logger's infof("{} second/s to expire, waiting for the next...", secondsUntilNext)
				delay secondsUntilNext
			end if
			
			stepTwo's clearFilter()
			stepTwo's getOtpByCredKey(credKey)
		end getOTP
	end script
	
end newRetriever


(*  *)
on new()
	if std's appExists("Step Two") is false then error "Step Two app was not found"
	
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
					
					logger's debugf("nextDesc: {}", nextDesc)
					
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
			30 - (3rd word of time string of (current date) as integer) mod 30
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
			
			set processStepTwo to proc's new("Step Two")
			processStepTwo's terminate()
			activate application "Step Two"
			delay 0.1
			tell application "System Events" to tell process "Step Two"
				return front window
			end tell
		end _getFrontWindow
	end script
end new


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("step-two")
	set textUtil to std's import("string")
	set proc to std's import("process")
	
	set APP_NAME to "Step Two"
end init
