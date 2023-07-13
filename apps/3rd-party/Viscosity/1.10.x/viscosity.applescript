(*
	@Testing:
		Uses Step Two app for testing. Other apps may be used as well like 1Password.

	@Last Modified
*)

use loggerFactory : script "logger-factory"

use retryLib : script "retry"
use processLib : script "process"
use configLib : script "config"
use stepTwoLib : script "step-two"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set retry to retryLib's new()
	set stepTwo to stepTwoLib's new()
	set configBusiness to configLib's new("business")
	set viscosityProcess to processLib's new("Viscosity")
	viscosityProcess's terminate()
	
	set domainKey to configBusiness's getValue("Domain Key")
	logger's debugf("domainKey: {}", domainKey)
	script OtpRetrieverInstance
		on getOTP()
			set OTP_APP_NAME to "Step Two"
			if running of application OTP_APP_NAME is false then
				activate application OTP_APP_NAME
				delay 1
			end if
			stepTwo's filter(domainKey)
			return stepTwo's getFirstOTP()
		end getOTP
	end script
	
	set sut to new(OtpRetrieverInstance)
	exec of retry on sut by 1 for 100
	-- Takes about 9s to re-connect (otp-less).
	
	logger's finish()
end spotCheck


(*
 	@pOtpRetriever - a script object that will perform the OTP retrieval.
*)
on new(pOtpRetriever)
	loggerFactory's inject(me)

	if pOtpRetriever is missing value then
		error "You need to pass a valid OTP retriever"
	end if
	
	script ViscosityInstance
		property otpRetriever : pOtpRetriever
		
		on run {}
			if not (running of application "Viscosity") then activate application "Viscosity"
			
			tell application "System Events" to tell process "Viscosity"
				if (count of windows) is 0 then
					tell application "Viscosity"
						if state of first connection is "Connected" then return true
						connect WORK_NAME
					end tell
				end if
				
				if exists (button "OK" of window "") then click button "OK" of window ""
				
				if exists (window "Preferences") then click first button of window "Preferences"
				if exists (window "Details") then click first button of window "Details"
				
				if exists (button "OK" of (first window whose name starts with "Viscosity")) then
					logger's info("Getting OTP...")
					set otp to my otpRetriever's getOTP()
					logger's debugf("otp: {}", otp)
					if otp is not missing value then
						my fillOTP(otp)
						-- let's assume its going to be alright and return early
						return true
					end if
				end if
			end tell
			
			missing value -- Keep this so we don't inadvertently exit the loop
			-- when one of the instructions above returns a value implicitly.
		end run
		
		
		on fillOTP(otp)
			logger's info("Filling Viscosity with OTP")
			tell application "System Events" to tell process "Viscosity"
				set targetWindow to (first window whose name starts with "Viscosity")
				set value of text field 2 of targetWindow to otp
				click button "OK" of targetWindow
			end tell
		end fillOTP
	end script
end new

