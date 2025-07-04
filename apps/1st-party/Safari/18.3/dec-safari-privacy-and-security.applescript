(*
	@Purpose:
		This decorator provides handlers for responding to the prompt asking for location or camera access.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/18.3/dec-safari-privacy-and-security

	@Created: Monday, February 10, 2025 at 12:52:14 PM
	@Last Modified: 2025-05-18 13:17:40
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use unic : script "core/unicodes"

property logger : missing value

use retryLib : script "core/retry"
use processLib : script "core/process"

property TopLevel : me

property KEYWORD_LOCATION_PROMPT : "use your current location"
property KEYWORD_CAMERA_PROMPT : "to use your camera"
property KEYWORD_PASSWORD_PROMPT : "Save Password"
property KEYWORD_STRONG_PASSWORD_PROMPT : "Many people use this password"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Allow Use Location (bundy website)
		Manual: Deny Use Location (bundy website)
		Manual: Never Use Location (bundy website)
		Manual: Toggle Remember My Location Decision (bundy website)

		Manual: Allow Use Camera (bundy website)
		Manual: Deny Use Camera (bundy website)
		Manual: Never Use Camera (bundy website)

		Manual: Not Now Password (work_a2)
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Is Location Prompt Present: {}", sut's isLocationPromptPresent())
	
	logger's infof("Is Camera Prompt Present: {}", sut's isCameraPromptPresent())
	logger's infof("Save Password Prompt Present: {}", sut's isSavePasswordPromptPresent())
	logger's infof("Strong password prompt present: {}", sut's isStrongPasswordPromptPresent())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's allowLocationAccess()
		
	else if caseIndex is 3 then
		sut's denyLocationAccess()
		
	else if caseIndex is 4 then
		sut's neverAllowLocationAccess()
		
	else if caseIndex is 5 then
		sut's rememberMyLocationDecisionForOneDay()
		
	else if caseIndex is 6 then
		sut's allowCameraAccess()
		
	else if caseIndex is 7 then
		sut's denyCameraAccess()
		
	else if caseIndex is 8 then
		sut's neverAllowCameraAccess()
		
	else if caseIndex is 9 then
		sut's declineSavePassword()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script SafariPrivacyAndDecorator
		property parent : mainScript
		
		on isLocationPromptPresent()
			run TopLevel's newLocationPromptPresenceLambda()
		end isLocationPromptPresent
		
		on allowLocationAccess()
			_respondToAccessRequest(TopLevel's newLocationPromptPresenceLambda(), TopLevel's newAllowButton())
		end allowLocationAccess
		
		on denyLocationAccess()
			_respondToAccessRequest(TopLevel's newLocationPromptPresenceLambda(), TopLevel's newDenyButton())
		end denyLocationAccess
		
		on rememberMyLocationDecisionForOneDay()
			tell application "System Events" to tell process "Safari"
				if the value of checkbox 1 of sheet 1 of front window is not 1 then
					click checkbox 1 of sheet 1 of front window
				end if
			end tell
		end rememberMyLocationDecisionForOneDay
		
		
		on isCameraPromptPresent()
			run TopLevel's newCameraPromptPresenceLambda()
		end isCameraPromptPresent
		
		
		on allowCameraAccess()
			_respondToAccessRequest(TopLevel's newCameraPromptPresenceLambda(), TopLevel's newAllowButton())
		end allowCameraAccess
		
		on denyCameraAccess()
			_respondToAccessRequest(TopLevel's newCameraPromptPresenceLambda(), TopLevel's newDenyButton())
		end denyCameraAccess
		
		
		on neverAllowCameraAccess()
			_respondToAccessRequest(TopLevel's newCameraPromptPresenceLambda(), TopLevel's newNeverButton())
		end neverAllowCameraAccess
		
		
		on isSavePasswordPromptPresent()
			run TopLevel's newSavePasswordPromptPresenceLambda()
		end isSavePasswordPromptPresent
		
		
		on confirmSavePassword()
			_respondToAccessRequest(TopLevel's newSavePasswordPromptPresenceLambda(), TopLevel's newSavePasswordButton())
		end confirmSavePassword
		
		
		on declineSavePassword()
			_respondToAccessRequest(TopLevel's newSavePasswordPromptPresenceLambda(), TopLevel's newNotNowButton())
		end declineSavePassword
		
		
		on isStrongPasswordPromptPresent()
			run TopLevel's newStrongPasswordPromptPresenceLambda()
		end isStrongPasswordPromptPresent
		
		on confirmChangePassword()
			_respondToAccessRequest(TopLevel's newStrongPasswordPromptPresenceLambda(), TopLevel's newChangePasswordButton())
		end confirmChangePassword
		
		on declineChangePassword()
			_respondToAccessRequest(TopLevel's newStrongPasswordPromptPresenceLambda(), TopLevel's newNotNowButton())
		end declineChangePassword
		
		on _respondToAccessRequest(PresenceLambda, UiLambda)
			if running of application "Safari" is false then return
			if not (run PresenceLambda) then return
			
			set safariProcess to processLib's new("Safari")
			safariProcess's focusWindow()
			
			set promptButton to run UiLambda
			if promptButton is missing value then
				return
			end if
			
			script DenyRetrier
				tell application "System Events"
					try
						click promptButton
					end try
				end tell
				if not (run PresenceLambda) then return true
			end script
			set retryResult to exec of retry on result for 3
			
			if retryResult is missing value then
				logger's warnf("{}  failed after retries", name of UiLambda)
			end if
		end _respondToAccessRequest
	end script
end decorate


on newAllowButton()
	script AllowButtonFactory
		property name : "Allow"
		on run {} -- NOTE: This needs to be called explicitly.
			tell application "System Events" to tell process "Safari"
				try
					return button "Allow" of sheet 1 of front window
				end try
			end tell
			missing value
		end run
	end script
end newAllowButton


on newDenyButton()
	script DenyButtonFactory
		property name : "Don't Allow"
		on run {}
			tell application "System Events" to tell process "Safari"
				try
					return first button of sheet 1 of front window whose title starts with "Don" & unic's APOSTROPHE & "t Allow"
					
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
			end tell
			missing value
		end run
	end script
end newDenyButton


on newNeverButton()
	script NeverButtonFactory
		property name : "Never for This Website"
		on run {}
			tell application "System Events" to tell process "Safari"
				try
					return button "Never for This Website" of sheet 1 of front window
				end try
			end tell
			missing value
		end run
	end script
end newNeverButton


on newSavePasswordButton()
	script SavePasswordButtonFactory
		property name : "Save Password"
		on run {} -- NOTE: This needs to be called explicitly.
			tell application "System Events" to tell process "Safari"
				try
					return button (my name) of sheet 1 of front window
				end try
			end tell
			missing value
		end run
	end script
end newSavePasswordButton


on newChangePasswordButton()
	script ChangePasswordButtonFactory
		property name : "Change Password"
		on run {} -- NOTE: This needs to be called explicitly.
			tell application "System Events" to tell process "Safari"
				try
					return button (my name) of sheet 1 of front window
				end try
			end tell
			missing value
		end run
	end script
end newChangePasswordButton


on newNotNowButton()
	script NotNowButtonFactory
		property name : "Not Now"
		on run {} -- NOTE: This needs to be called explicitly.
			tell application "System Events" to tell process "Safari"
				try
					return button (my name) of sheet 1 of front window
				end try
			end tell
			missing value
		end run
	end script
end newNotNowButton


on newLocationPromptPresenceLambda()
	script LocationPromptPresenceLambda
		on run {}
			if running of application "Safari" is false then return false
			
			tell application "System Events" to tell process "Safari"
				try
					return value of static text 1 of sheet 1 of front window contains my KEYWORD_LOCATION_PROMPT
				end try
			end tell
			
			false
		end run
	end script
end newLocationPromptPresenceLambda


on newCameraPromptPresenceLambda()
	script CameraPromptPresenceLambda
		on run {}
			if running of application "Safari" is false then return false
			
			tell application "System Events" to tell process "Safari"
				try
					return value of static text 1 of sheet 1 of front window contains my KEYWORD_CAMERA_PROMPT
				end try
			end tell
			
			false
		end run
	end script
end newCameraPromptPresenceLambda


on newSavePasswordPromptPresenceLambda()
	script SavePasswordPromptPresenceLambda
		on run {}
			if running of application "Safari" is false then return false
			
			tell application "System Events" to tell process "Safari"
				try
					return value of static text 1 of sheet 1 of front window contains my KEYWORD_PASSWORD_PROMPT
				end try
			end tell
			
			false
		end run
	end script
end newSavePasswordPromptPresenceLambda


on newStrongPasswordPromptPresenceLambda()
	script StrongPasswordPromptPresenceLambda
		on run {}
			if running of application "Safari" is false then return false
			
			tell application "System Events" to tell process "Safari"
				try
					return value of static text 1 of sheet 1 of front window contains my KEYWORD_STRONG_PASSWORD_PROMPT
				end try
			end tell
			
			false
		end run
	end script
end newStrongPasswordPromptPresenceLambda
