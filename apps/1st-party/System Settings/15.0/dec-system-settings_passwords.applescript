(*
	Passwords handlers for System Settings.
		
	@Version:
		macOS Sonoma 14.7
		System Settings 15.0
		
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh "apps/1st-party/System Settings/15.0/dec-system-settings_passwords"

	@Usage:
		set systemSettingLib to script "core/system-settings"
		set systemSetting to systemSettingLib's new()
		systemSetting's revealPasswords()
		systemSetting's waitForPasswordsUnlock()

		systemSetting's filterCredentials("zoom")
		systemSetting's clickFirstCredentialInformation()
		systemSetting's getVerificationCode(2)

	@Created: Wednesday, November 8, 2023 at 10:41:03 PM
	@Last Modified: Wednesday, November 8, 2023 at 10:41:03 PM
	@Change Logs:
		Sat, Oct 12, 2024 at 3:09:54 PM - Changes on UI to retrieve OTP.
*)

use scripting additions
use script "core/Text Utilities"

use textUtil : script "core/string"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"
use clipLib : script "core/clipboard"
use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property usr : missing value
property clip : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		NOOP: Info
		Main: Reveal Passwords
		Manual: Filter Credentials
		Manual: Click Credentials Info
		Manual: Get Credentials Info
		
		Manual: Get Verification Code
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
	
	logger's debug("Timing point 1")
	set sut to sutLib's new() -- INVESTIGATE: This statement is too slow at 4s.
	
	logger's debug("Timing point 2")
	set sut to decorate(sut)
	
	set configLib to script "core/config"
	set configUser to configLib's new("user")
	
	logger's infof("Is password locked: {}", sut's isPasswordsLocked())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		-- sut's printPaneIds()
		sut's revealPasswords()
		
	else if caseIndex is 3 then
		sut's filterCredentials("signin.aws.amazon.com")
		
	else if caseIndex is 4 then
		sut's clickFirstCredentialInformation()
		
	else if caseIndex is 5 then
		set secondaryEmail to configUser's getValue("Username 2")
		logger's debugf("secondaryEmail: {}", secondaryEmail)
		sut's clickCredentialInformationWithUsername(secondaryEmail)
		
	else if caseIndex is 6 then
		logger's infof("Username: {}", sut's getUsername())
		log (format {"Password: {}", sut's getPassword()})
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
	set retry to retryLib's new()
	
	script SystemSettingsPasswordsDecorator
		property parent : mainScript
		
		on isPasswordsLocked()
			script WindowWaiter
				tell application "System Events" to tell process "System Settings"
					if exists (text field "Enter password" of group 1 of group 2 of splitter group 1 of group 1 of window "Passwords") then return true
					if exists (text field "Enter password" of group 1 of list 2 of splitter group 1 of list 1 of window "Passwords") then return true
				end tell
				false
			end script
			exec of retry on result for 5 by 0.2
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
			activate application "System Settings"
			delay 1
			
			script PaneChanger
				tell application "System Settings"
					set current pane to pane id "com.apple.Passwords-Settings.extension"
				end tell
				return true
			end script
			exec of retry on result for 3
			
			if my isPasswordsLocked() then
				usr's cueForTouchId()
			else
				script WindowWaiter
					tell application "System Events" to tell process "System Settings"
						return exists (window "Passwords")
					end tell
				end script
				exec of retry on result for 3
			end if
		end revealPasswords
		
		
		on _getCommonGroup()
			script RetryScript
				tell application "System Events" to tell process "System Settings"
					group 3 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window "Passwords"
					
				end tell
			end script
			exec of retry on result for 3
		end _getCommonGroup
		
		
		on filterCredentials(keyword)
			tell application "System Events" to tell process "System Settings"
				set searchGroup to group 1 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of window "Passwords"
				set focused of text field 1 of searchGroup to true
				set value of text field 1 of searchGroup to keyword
				delay 0.1
			end tell
		end filterCredentials
		
		
		on clickFirstCredentialInformation()
			tell application "System Events" to tell process "System Settings"
				try
					click button 1 of UI element 1 of row 1 of table 1 of scroll area 1 of my _getCommonGroup()
				on error -- Changed DOM.
					click button 1 of UI element 1 of row 1 of table 1 of scroll area 1 of group 2 of scroll area 1 of group 1 of list 2 of splitter group 1 of list 1 of front window
				end try
				delay 0.1
			end tell
		end clickFirstCredentialInformation
		
		
		on clickCredentialInformationWithUsername(username)
			set credentialRows to missing value
			tell application "System Events"
				try
					set credentialRows to rows of table 1 of scroll area 1 of my _getCommonGroup()
				end try
				if credentialRows is missing value then return missing value
				
				repeat with nextRow in credentialRows
					if value of static text 2 of UI element 1 of nextRow is equal to the username then
						click button 1 of UI element 1 of nextRow
					end if
				end repeat
				delay 0.1
				
			end tell
		end clickCredentialInformationWithUsername
		
		
		on getUsername()
			if running of application "System Settings" is false then return missing value
			
			if isPasswordsLocked() then
				promptForTouchID()
				waitForPasswordsUnlock()
			end if
			
			tell application "System Events" to tell process "System Settings"
				try
					set commonUI to group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
				on error the errorMessage number the errorNumber
					logger's warn(errorMasse) -- This needs quick attention.
					return missing value
				end try
				
				-- if exists (static text 4 of commonUI) then return value of static text 4 of commonUI
				-- if exists (UI element 3 of commonUI) then return value of UI element 3 of commonUI
				
				(* As of macOS Sonoma v14.7 *)
				value of static texts of commonUI
				repeat with nextItem in result
					if nextItem starts with "User Name" then
						textUtil's split(nextItem, ", ")
						return last item of result
					end if
				end repeat
			end tell
			
			missing value
		end getUsername
		
		(*
			Returns the password. It requires that the credential info pane is already in focus.		
			BROKEN: as of Thu, Sep 19, 2024 at 3:18:55 PM
		*)
		on getPassword()
			if running of application "System Settings" is false then return missing value
			
			logger's warn("Broken ATM, use cliclick to make it work.")
			return missing value
			
			script ExtractPassword
				tell application "System Events" to tell process "System Settings"
					set frontmost to true
					try
						set targetUI to static text 6 of group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
					on error -- Changed DOM.
						set targetUI to UI element 4 of group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
					end try
					
					perform action "AXShowMenu" of targetUI -- Stopped working.
					-- click targetUI
					
					delay 1
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
			if running of application "System Settings" is false then return missing value
			
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
				try
					set commonUI to group 2 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
				on error the errorMessage number the errorNumber
					logger's warn(errorMasse) -- This needs quick attention.
					return missing value
				end try
				
				if exists (static text 3 of commonUI) then return textUtil's replace(value of static text 3 of commonUI, " ", "")
				
				value of static texts of group 2 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
			end tell
			
			repeat with nextItem in result
				if nextItem starts with "Verification Code" then
					textUtil's split(nextItem, ", ")
					return last item of result
					exit repeat
				end if
			end repeat
			
			missing value
		end getVerificationCode
	end script
end decorate
