(*
	Passwords handlers for System Settings.
	
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_passwords"

	@Created: Wednesday, November 8, 2023 at 10:41:03 PM
	@Last Modified: Wednesday, November 8, 2023 at 10:41:03 PM
	@Change Logs:
*)

use scripting additions

use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"
use usrLib : script "core/user"
use clipLib : script "core/clipboard"
use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property usr : missing value
property clip : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Main: Reveal Passwords
		Manual: Filter Credentials
		Manual: Click Credentials Info
		Manual: Get Credentials Info
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		-- sut's printPaneIds()
		sut's revealPasswords()
		
	else if caseIndex is 2 then
		sut's filterCredentials("zoom")
		
	else if caseIndex is 3 then
		sut's clickCredentialInformation()
		
	else if caseIndex is 4 then
		logger's infof("Username: {}", sut's getUsername())
		-- logger's infof("Password: {}", sut's getPassword())
		logger's infof("Verification Code: {}", sut's getVerificationCode(2))
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set usr to usrLib's new()
	set clip to clipLib's new()
	
	script SystemSettingsPasswordsDecorator
		property parent : mainScript
		
		on isPasswordsLocked()
			tell application "System Events" to tell process "System Settings"
				exists (text field "Enter password" of group 1 of group 2 of splitter group 1 of group 1 of window "Passwords")
			end tell
		end isPasswordsLocked
		
		
		on promptForTouchID()
			tell application "System Events" to tell process "System Settings"
				set frontmost to true
			end tell
			
			usr's cueForTouchId()
		end promptForTouchID
		
		on waitForPasswordsUnlock()
			set retry to retryLib's new()
			script PasswordUnlocker
				if not isPasswordsLocked() then return true
			end script
			exec of retry on result for 30 by 1
		end waitForPasswordsUnlock
		
		
		on revealPasswords()
			tell application "System Settings"
				activate
				delay 0.1  -- Intermittent failure without this.
				set current pane to pane id "com.apple.Passwords-Settings.extension"
				delay 1
				usr's cueForTouchId()
			end tell
		end revealPasswords
		
		
		on filterCredentials(keyword)
			tell application "System Events" to tell process "System Settings"
				set value of text field 1 of group 3 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Passwords" to keyword
				delay 0.1
			end tell
			
		end filterCredentials
		
		
		on clickCredentialInformation()
			tell application "System Events" to tell process "System Settings"
				click button 1 of UI element 1 of row 1 of table 1 of scroll area 1 of group 3 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Passwords"
				delay 0.1
			end tell
		end clickCredentialInformation
		
		
		on getUsername()
			if isPasswordsLocked() then
				promptForTouchID()
				waitForPasswordsUnlock()
			end if
			
			tell application "System Events" to tell process "System Settings"
				value of static text 4 of group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
			end tell
		end getUsername
		
		(*
			Returns the password. It requires that the credential info pane is already in focus.		
		*)
		on getPassword()
			script ExtractPassword
				tell application "System Events" to tell process "System Settings"
					set frontmost to true
					set targetUI to static text 6 of group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
					perform action "AXShowMenu" of targetUI
					delay 0.1
					click menu item "Copy Password" of menu 1 of group 1 of sheet 1 of window "Passwords"
				end tell
			end script
			clip's extract(result)
		end getPassword
		
		
		(* 
			Returns the OTP. It requires that the credential info pane is already in focus.
			
			@timeoutAtLeast - The minimum amount of time in seconds allowed for the code. If the current code is less than this, it will wait for the next one. 
		*)
		on getVerificationCode(timeoutAtLeast)
			if isPasswordsLocked() then
				promptForTouchID()
				waitForPasswordsUnlock()
			end if
			
			set remainingTime to 30 - (seconds of (current date)) mod 30
			logger's debugf("remainingTime: {}", remainingTime)
			if remainingTime is less than or equal to timeoutAtLeast then
				delay remainingTime
			end if
			
			tell application "System Events" to tell process "System Settings"
				get value of static text 3 of group 2 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
			end tell
		end getVerificationCode
	end script
end decorate

