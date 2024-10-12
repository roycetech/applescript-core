(*
	@Testing:
		Uses Step Two app for testing. Other apps may be used as well like 1Password.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Viscosity/1.10.x/viscosity

	@Last Modified: 2024-10-12 17:33:12
*)

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use processLib : script "core/process"
use configLib : script "core/config"
use stepTwoLib : script "core/step-two"

property logger : missing value
property configBusiness : missing value

property CONFIG_KEY_BUSINESS : "business"
property PLIST_KEY_DOMAIN_KEY : "Domain Key"
property PLIST_KEY_VPN_KEY : "VPN Key"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set retry to retryLib's new()
	set stepTwo to stepTwoLib's new()
	set configBusiness to configLib's new(my CONFIG_KEY_BUSINESS)
	set viscosityProcess to processLib's new("Viscosity")
	viscosityProcess's terminate()

	set domainKey to configBusiness's getValue(my PLIST_KEY_DOMAIN_KEY)
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
	set configBusiness to configLib's new(my CONFIG_KEY_BUSINESS)

	if pOtpRetriever is missing value then
		error "You need to pass a valid OTP retriever"
	end if

	script ViscosityInstance
		property otpRetriever : pOtpRetriever

		on run {}
			if not (running of application "Viscosity") then activate application "Viscosity"

			set vpnKey to configBusiness's getValue(my PLIST_KEY_VPN_KEY)
			logger's debugf("vpnKey: {}", vpnKey)
			tell application "System Events" to tell process "Viscosity"
				if (count of windows) is 0 then
					logger's debug("No window found...")
					tell application "Viscosity"
						if state of first connection is "Connected" then
							logger's info("First connection state is already 'Connected'")
							return true
						end if
						connect vpnKey
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
			logger's info("Supplying Viscosity with OTP")
			tell application "System Events" to tell process "Viscosity"
				set targetWindow to (first window whose name starts with "Viscosity")
				set focused of text field 1 of targetWindow to true

				set value of text field of targetWindow to otp -- Work as of Sat, Oct 12, 2024 at 5:32:22 PM
				click button "OK" of targetWindow
			end tell
		end fillOTP
	end script
end new

