global std, retry

property initialized : false
property logger : missing value

(*
	@Testing:
		Uses Step Two app for testing. Other apps may be used as well like 1Password.
*)

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "viscosity-spotCheck"
	logger's start()
	
	set stepTwo to std's import("step-two")'s new()
	set configBusiness to std's import("config")'s new("business")
	set viscosityProcess to std's import("process")'s new("Viscosity")
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
					set otp to my OtpRetriever's getOTP()
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
		
		
		on extractOTP()
			tell pwd
				set unlocked to waitToUnlockNext()
				if not unlocked then
					logger's warn("1Password did not unlock :(")
					return missing value
				end if
				
				selectCategory("Logins")
				
				set theOtp to doGetOTP(WORK_CRED_KEY)
				
				quitApp()
			end tell
			
			return theOtp
		end extractOTP
		
		
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


-- Private Codes below =======================================================

(*
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
*)
on unitTest()
	set actual101 to matched("amazing", "maz")
	set case101 to "Case 101: Found"
	std's assert(true, actual101, case101)
end unitTest


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("viscosity")
	set retry to std's import("retry")'s new()
end init
