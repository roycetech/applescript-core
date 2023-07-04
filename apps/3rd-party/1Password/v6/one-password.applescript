(*
	Usage:
		Use the Text Expander: "ppwd"

	TODO: 12/4/21 10:05:40> F Error encountered: System Events got an error: Can?t get scroll area 1 of splitter group 1 of window "1Password" of process "1Password 6". Invalid index.
*)

use scripting additions

use textUtil : script "string"
use listUtil : script "list"
use cliclick : script "cliclick"

use loggerLib : script "logger"
use retryLib : script "retry"
use clipLib : script "clipboard"
use kbLib : script "keyboard"

use spotScript : script "spot-test"

property logger : loggerLib's new("1password")
property clip : clipLib's new()
property retry : retryLib's new()
property kb : kbLib's new()

property initCategory : false
property waitOtpThreshold : 3 -- 2 is too short, failed January 6, 2021

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "1password-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Unlocked (yes, no)
		Manual: Retrieve a password
		Retrieve a password via mini - Manual (Takes 1s vs 3s for the standard.)
		Retrieve an OTP via mini
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	
	set sut to new()
	set spotCredKey to "AppleScript Core"
	
	if caseIndex is 1 then
		(*
		tell application "System Events" to tell process "1Password mini"
			key code 42 using {option down, command down} -- \
			delay 0.1
		end tell
		*)
		
		logger's infof("Unlocked: {}", sut's isUnlocked())
		
	else if caseIndex is 2 then
		set unlocked to sut's waitToUnlock()
		if unlocked then
			sut's selectCategory("Logins")
			logger's infof("U: {}, P: {}", sut's doGetUsernameAndPassword(spotCredKey))
			
		else
			logger's warn("1Password did not unlock :(")
		end if
		sut's quitApp()
		
	else if caseIndex is 3 then
		logger's infof("P: {}", sut's getPasswordViaMini(spotCredKey))
		
	else if caseIndex is 4 then
		logger's infof("OTP: {}", sut's getOtpViaMini(spotCredKey))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	
	script _1PasswordInstance
		(* Sample Usage assumes client code. This handler is not meant to be run on this script.*)
		on sampleUsage()
			set unlocked to pwd's waitToUnlockNext()
			if unlocked then
				pwd's selectCategory("Logins")
				set credKey to "your-unique-key"
				set credKey to "" -- << TEST YOUR CRED HERE, DO NOT COMMIT.
				
				-- set thePassword to pwd's doGetPassword(credKey)
				-- set thePassword to pwd's doGetOTP(credKey)
				set {theUsername, thePassword} to doGetUsernameAndPassword(credKey)
				log "Username: " & theUsername
				log "Password: " & thePassword -- do not user logger because that would log to a file.
				-- set { thePassword, theOtp } to doGetPasswordAndOtp(credKey)
			else
				logger's warn("1Password did not unlock :(")
			end if
			
			pwd's quitApp()
		end sampleUsage
		
		-- End of spot check code ==============================================
		
		
		on getPasswordViaMini(credKey)
			kb's pressCommandOptionKey("\\")
			set unlocked to waitToUnlockMini()
			if unlocked is false then return
			
			script RetrievePassword
				tell application "System Events" to tell process "1Password mini"
					perform action 2 of group 1 of UI element 1 of row 1 of table 1 of scroll area 1 of window 1
					delay 0.2
					repeat with nextRow in rows of table 1 of scroll area 1 of window 1
						kb's pressKey("down")
						if credKey is equal to the name of UI element 1 of nextRow then
							set found to true
							exit repeat
						end if
					end repeat
					kb's pressKey("right")
					kb's pressKey("return")
				end tell
			end script
			clip's extract(RetrievePassword)
		end getPasswordViaMini
		
		(* Does not check if expiring soon, but should be okay because this is faster. May fail if the UI elementis not ready in time.*)
		on getOtpViaMini(credKey)
			kb's pressCommandOptionKey("\\")
			
			set unlocked to waitToUnlockMini()
			if unlocked is false then return
			
			script RetrievePassword
				tell application "System Events" to tell process "1Password mini"
					perform action 2 of group 1 of UI element 1 of row 1 of table 1 of scroll area 1 of window 1
					delay 0.2
					repeat with nextRow in rows of table 1 of scroll area 1 of window 1
						kb's pressKey("down")
						if credKey is equal to the name of UI element 1 of nextRow then
							set found to true
							exit repeat
						end if
					end repeat
					
					kb's pressKey("right")
					delay 0.3
					kb's pressKey("down")
					kb's pressKey("down")
					kb's pressKey("return")
				end tell
			end script
			clip's extract(RetrievePassword)
		end getOtpViaMini
		
		
		(* Works for both mini and non-mini *)
		on isUnlocked()
			tell application "System Events" to tell process "1Password mini"
				if exists window 1 then return true
			end tell
			
			if running of application "1Password 6" is false then return false
			
			tell application "System Events" to tell process "1Password 6"
				exists (button "Lock" of group 2 of splitter group 1 of splitter group 1 of window "1Password")
			end tell
		end isUnlocked
		
		
		on waitToUnlock()
			script UnlockOrMasterOrTouch
				if running of application "1Password 6" is false then activate application "1Password 6"
				
				tell application "System Events" to tell process "1Password 6"
					if exists (button "Lock" of group 2 of splitter group 1 of splitter group 1 of window "1Password") then return "unlocked"
					
					if exists (button "Unlock" of window "1Password") then return "locked"
				end tell
				
				with timeout of 2 seconds
					tell application "System Events" to tell process "coreautha"
						if exists (button "Enter Master Password" of window 1) then return "touch"
					end tell
				end timeout
			end script
			
			set retry to retryLib's new()
			-- logger's debug("Waiting for unlock or master password for 60s...")
			set unlockState to exec of retry on UnlockOrMasterOrTouch by 0.5 for 120
			-- logger's debug("unlockState: " & unlockState)
			if unlockState is missing value then return false
			
			script Unlock
				tell application "System Events" to tell process "1Password 6"
					if exists (button "Lock" of group 2 of splitter group 1 of splitter group 1 of window "1Password") then
						do shell script "afplay ~/applescript/sounds/Beer\\ Opening.aiff > /dev/null 2>&1 &"
						return "unlocked"
					end if
				end tell
				
				tell application "System Events" to tell process "coreautha"
					if (count of windows) is not 0 then set frontmost to true
				end tell
			end script
			
			if unlockState is "locked" then
				-- logger's debug("Clicking touch ID...")
				_clickTouchId()
				delay 1
				do shell script "afplay /System/Library/Sounds/Purr.aiff"
				-- 		set my fingerPrintButtonClicked of Unlock		to true
				
				set unlockState to exec of retry on Unlock by 0.5 for 120
				return unlockState is "unlocked"
			end if
			
			if unlockState is "unlocked" then return true
			
			-- touch	
			tell application "System Events" to tell process "coreautha" to set frontmost to true
			logger's debug("Waiting for unlock...")
			do shell script "afplay /System/Library/Sounds/Purr.aiff"
			
			return (exec of retry on Unlock by 0.5 for 200) is "unlocked"
		end waitToUnlock
		
		
		on waitToUnlockMini()
			set retry to retryLib's new()
			tell application "System Events" to tell process "1Password mini"
				if exists (window 1) then return true
			end tell
			
			script Unlock
				tell application "System Events" to tell process "1Password mini"
					if exists (window 1) then
						-- do shell script "afplay ~/applescript/sounds/Beer\\ Opening.aiff > /dev/null 2>&1 &"
						return "unlocked"
					end if
				end tell
				
				tell application "System Events" to tell process "coreautha"
					if (count of windows) is not 0 then set frontmost to true
				end tell
			end script
			
			tell application "System Events" to tell process "coreautha" to set frontmost to true
			logger's debug("Waiting for unlock...")
			do shell script "afplay /System/Library/Sounds/Purr.aiff"
			
			return (exec of retry on Unlock by 0.5 for 200) is "unlocked"
		end waitToUnlockMini
		
		
		
		(* @returns true if the category is found. *)
		on selectCategory(catName as text)
			
			set found to false
			
			-- activate application "1Password 6"
			tell application "System Events" to tell process "1Password 6"
				repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of window "1Password"
					set descAndCount to get value of static text of first UI element of nextRow
					-- log descAndCount
					try
						if first item of descAndCount is catName then
							select nextRow
							-- logger's debug("Category " & catName & " found and selected")
							set found to true
							exit repeat
						end if
					end try
				end repeat
			end tell
			
			set initCategory to true
			return found
		end selectCategory
		
		on doGetUsernameAndPassword(credKey)
			set retry to retryLib's new()
			script SearchInitializer
				doClearSearch()
				doSearch("applescript")
				
				if doGetUsernamePrivate() is equal to "applescript" then return true
			end script
			
			exec of retry on SearchInitializer by 0.5 for 120
			
			script CredSearched
				doClearSearch()
				doSearch(credKey)
				
				if doGetUsernamePrivate() is not equal to "applescript" then return true
			end script
			
			exec of retry on CredSearched by 0.5 for 120
			
			set theUsername to doGetUsernamePrivate()
			set thePassword to doGetPasswordPrivate()
			
			return {theUsername, thePassword}
		end doGetUsernameAndPassword
		
		
		on doGetPasswordAndOtp(credKey)
			script SearchInitializer
				doClearSearch()
				doSearch("applescript")
				
				if doGetUsernamePrivate() is equal to "applescript" then return true
			end script
			exec of retry on SearchInitializer by 0.5 for 120
			
			script CredSearched
				doClearSearch()
				doSearch(credKey)
				
				if doGetUsernamePrivate() is not equal to "applescript" then return true
			end script
			exec of retry on CredSearched by 0.5 for 120
			
			set thePassword to doGetPasswordPrivate()
			set theOtp to doGetOTPPrivate()
			
			return {thePassword, theOtp}
		end doGetPasswordAndOtp
		
		
		on doGetUsername(credKey)
			repeat 5 times
				try
					doClearSearch()
					doSearch(credKey)
					
					--- logger's debug("Trying to get Username...")
					set theUsername to doGetUsernamePrivate()
					
					-- Check for success, exit
					if theUsername is not missing value and theUsername is not "" then
						exit repeat
					end if
				on error the error_message number the error_number
					logger's warn("Error: " & the error_number & ". " & the error_message)
					delay 1
				end try
			end repeat
			
			return theUsername
		end doGetUsername
		
		
		on doGetPassword(credKey)
			set dummyPassword to "zambian-CURIE-email"
			
			repeat 5 times
				try
					doClearSearch()
					doSearch(credKey)
					
					-- logger's debug("Trying to get Password...")
					set thePassword to doGetPasswordPrivate()
					
					-- Check for success, exit
					if thePassword is not missing value and thePassword is not "" and thePassword is not equal to dummyPassword then
						exit repeat
					end if
				on error the error_message number the error_number
					logger's warn("Error: " & the error_number & ". " & the error_message)
					delay 1
				end try
			end repeat
			
			return thePassword
		end doGetPassword
		
		
		on doGetOTP(credKey)
			repeat 5 times
				try
					doClearSearch()
					delay 0.1
					doSearch(credKey)
					delay 0.1
					
					-- logger's debug("Trying to get OTP...")
					set theOtp to doGetOTPPrivate()
					
					-- Check for success, exit
					if theOtp is not missing value and theOtp is not "" then
						exit repeat
					end if
				on error the error_message number the error_number
					-- logger's debug("Error: " & the error_number & ". " & the error_message)
					delay 1
				end try
			end repeat
			
			return theOtp
		end doGetOTP
		
		
		(* Fails sometimes, I'm not sure why, so lets just ignore it. *)
		on quitApp()
			try
				tell application "1Password 6" to quit
			end try
		end quitApp
		
		
		-- Private Codes below =======================================================
		
		(* Search for a credential. Make sure that your key results in only one match *)
		on doSearch(distinctiveSearchKey)
			tell application "System Events" to tell process "1Password 6"
				set searchField to text field 1 of group 1 of splitter group 1 of splitter group 1 of window "1Password"
				set value of searchField to distinctiveSearchKey
			end tell
		end doSearch
		
		
		(* Optionally clear if there's text present *)
		on doClearSearch()
			tell application "System Events" to tell process "1Password 6"
				set searchField to text field 1 of group 1 of splitter group 1 of splitter group 1 of window "1Password"
				if value of searchField is not "" then
					click button 2 of text field 1 of group 1 of splitter group 1 of splitter group 1 of window "1Password" -- Click the x button of the text field.
					set value of searchField to ""
				end if
			end tell
		end doClearSearch
		
		
		(* Get the password via the copy button, and pass it as a regular return value. Will attempt to restore original clipboard value.
  @throws an error, invoke the do Clear Search and do a retry if it does *)
		on doGetPasswordPrivate()
			set thePassword to missing value
			tell application "System Events" to tell process "1Password 6"
				repeat with nextRow in rows of table "Details" of scroll area 1 of group 2 of splitter group 1 of splitter group 1 of window "1Password"
					
					set fieldType to missing value
					try
						set fieldType to value of static text 1 of UI element 1 of nextRow
					end try
					if fieldType is "password" then
						set fieldValue to value of static text 2 of UI element 1 of nextRow
						try
							set originalClipboard to the clipboard
						on error
							set originalClipboard to ""
						end try
						
						set the clipboard to ""
						repeat until (the clipboard) is ""
							delay 0.1
						end repeat
						click button 1 of UI element 1 of nextRow
						set thePassword to ""
						repeat until thePassword is not ""
							delay 0.1
							set thePassword to the clipboard
						end repeat
						set the clipboard to originalClipboard
						return thePassword
					end if
				end repeat
			end tell
		end doGetPasswordPrivate
		
		
		(* Private handler, do not invoke directly in client code. Use doGetOTP with built-in retry mechanism instead. *)
		on doGetOTPPrivate()
			tell application "System Events" to tell process "1Password 6"
				repeat with nextRow in rows of table "Details" of scroll area 1 of group 2 of splitter group 1 of splitter group 1 of window "1Password"
					try
						set fieldType to value of static text 1 of UI element 1 of nextRow
					end try
					
					if fieldType is "one-time password" then
						set remainingTime to last item of (get value of static text of static text of UI element 1 of nextRow)
						
						logger's info("Remaining Time: " & remainingTime)
						set isAlmostExpired to remainingTime is less than or equal to my waitOtpThreshold
						if isAlmostExpired then
							logger's info("Running out of time, waiting for reset in: " & remainingTime)
							delay remainingTime
						end if
						
						set otpRaw to value of static text 2 of UI element 1 of nextRow
						return textUtil's substring(otpRaw, 1, 3) & textUtil's substringFrom(otpRaw, 5)
					end if
				end repeat
			end tell
		end doGetOTPPrivate
		
		
		(* Private handler, do not invoke directly in client code. Use doGetUsername with built-in retry mechanism instead. *)
		on doGetUsernamePrivate()
			tell application "System Events" to tell process "1Password 6"
				set detailsTable to table "Details" of scroll area 1 of group 2 of splitter group 1 of splitter group 1 of window "1Password"
				repeat with nextRow in rows of detailsTable
					set fieldType to missing value
					try
						set fieldType to value of static text 1 of UI element 1 of nextRow
					end try
					
					if fieldType is "username" then
						return value of static text 2 of UI element 1 of nextRow
					end if
				end repeat
			end tell
		end doGetUsernamePrivate
		
		
		(* Not accessible so we find the button beside it adjust the pointer from there. *)
		on _clickTouchId()
			tell application "System Events" to tell process "1Password 6"
				set theCoord to getCoord of cliclick at button "Unlock" of first window
				cliclick's lclickAtXy((item 1 of theCoord) - 50, item 2 of theCoord)
			end tell
		end _clickTouchId
	end script
end new
