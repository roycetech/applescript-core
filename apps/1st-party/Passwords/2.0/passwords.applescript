(*
	@Changes:
		1.4 -> 2.0
			splitter group 1 of group 1 -> toolbar 1

	@Usage:
		activate application "Passwords"
		passwords's waitUnlock()
		passwords's search('key')
		passwords's selectFirstCredential()
		passwords's getUsername()
		passwords's getPassword()


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Passwords/2.0/passwords

	@Created: Wed, Sep 24, 2025, at 07:39:47 AM
	@Last Modified: 2025-09-25 07:37:24
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

use clipLib : script "core/clipboard"
use retryLib : script "core/retry"
use usrLib : script "core/user"

property logger : missing value

property clip : missing value
property retry : missing value
property usr : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Search
		Manual: Select First Credential
		Manual: Clear Search Field
		Manual: Wait Unlock
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Is Locked: {}", sut's isLocked())
	logger's infof("Has search filter: {}", sut's hasSearchFilter())
	logger's infof("Has credential loaded: {}", sut's hasCredentialLoaded())
	logger's infof("Has credential selected: {}", sut's hasCredentialSelected())

	logger's infof("Current username: {}", sut's getLoadedUsername())
	logger's infof("Current password: {}", sut's getLoadedPassword())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		set sutSearchKey to "unicorn"
		set sutSearchKey to "AppleScript Testing"
		logger's infof("sutSearchKey: {}", sutSearchKey)
		sut's search(sutSearchKey)

	else if caseIndex is 3 then
		sut's selectFirstCredential()

	else if caseIndex is 4 then
		sut's clearSearch()


	else if caseIndex is 5 then
		activate application "Passwords"
		tell application "System Events" to tell process "Passwords"
			set frontmost to true
		end tell
		sut's waitUnlock()
		logger's infof("Unlock result: {}", result)
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set clip to clipLib's new()
	set retry to retryLib's new()
	set usr to usrLib's new()

	script PasswordsInstance
		on hasSearchFilter()
			if running of application "Passwords" is false then return false
			if isLocked() then return false

			tell application "System Events" to tell process "Passwords"
				try
					-- if value of text field 1 of group 3 of splitter group 1 of group 1 of front window is "" then return false
					if value of text field 1 of last group of splitter group 1 of group 1 of front window is "" then return false
				on error the errorMessage number the errorNumber
					-- Might have locked midway.
					return false
				end try
			end tell

			true
		end hasSearchFilter


		on waitUnlock()
			if not isLocked() then return true

			tell application "System Events" to tell process "Passwords"
				set frontmost to true
			end tell

			usr's cueForTouchId()
			script UnlockWaiter
				if not isLocked() then return true
			end script
			set retryResult to exec of retry on result for 15
			retryResult is not missing value
		end waitUnlock


		on isLocked()
			if running of application "Passwords" is false then return false -- Not locked but not running either.

			tell application "System Events" to tell process "Passwords"
				exists text field "Enter password" of group 1 of window "Passwords"
			end tell
		end isLocked

		on search(searchKey)
			if running of application "Passwords" is false then return
			if isLocked() then return

			tell application "System Events" to tell process "Passwords"
				-- set searchField to text field 1 of group 3 of splitter group 1 of group 1 of front window
				-- set searchField to text field 1 of group 3 of toolbar 1 of front window
				set searchField to text field 1 of last group of toolbar 1 of front window
				set focused of searchField to true
				set value of searchField to searchKey

			end tell
			delay 0.2
		end search


		on hasCredentialLoaded()
			if running of application "Passwords" is false then return false
			if isLocked() then return false

			tell application "System Events" to tell process "Passwords"
				not (exists static text "No Item Selected" of group 4 of splitter group 1 of group 1 of front window)
			end tell
		end hasCredentialLoaded


		on hasCredentialSelected()
			if running of application "Passwords" is false then return false
			if isLocked() then return false

			tell application "System Events" to tell process "Passwords"
				exists (first row of outline 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of front window whose selected is true)
			end tell
		end hasCredentialSelected


		on selectFirstCredential()
			if running of application "Passwords" is false then return
			if isLocked() then return

			tell application "System Events" to tell process "Passwords"
				try
					-- set selected of row 2 of outline 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of front window to true
					set selected of row 1 of outline 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of front window to true
				end try -- In case no credential is listed
			end tell
		end selectFirstCredential


		on getLoadedUsername()
			if running of application "Passwords" is false then return missing value
			if isLocked() then return missing value
			if not hasCredentialLoaded() then return missing value

			tell application "System Events" to tell process "Passwords"
				try
					-- return get value of static text 1 of group 1 of scroll area 1 of group 4 of splitter group 1 of group 1 of front window
					-- return get value of static text 4 of group 1 of scroll area 1 of group 4 of splitter group 1 of group 1 of front window
					return get value of static text 3 of group 1 of scroll area 1 of group 3 of splitter group 1 of group 1 of front window
				end try
			end tell
			missing value
		end getLoadedUsername


		on getLoadedPassword()
			if running of application "Passwords" is false then return missing value
			if isLocked() then return missing value
			if not hasCredentialLoaded() then return missing value

			script ClipboardWaiter
				tell application "System Events" to tell process "Passwords"
					set frontmost to true
					try
						click menu item "Copy Password" of menu 1 of menu bar item "Edit" of menu bar 1
					end try
				end tell
			end script
			clip's extract(result)
		end getLoadedPassword

		on clearSearch()
			if running of application "Passwords" is false then return missing value
			if isLocked() then return missing value

			tell application "System Events" to tell process "Passwords"
				try
					-- click (first button of text field 1 of group 3 of splitter group 1 of group 1 of front window whose description is "cancel")
					-- click (first button of text field 1 of group 3 of toolbar 1 of front window whose description is "cancel")
					click (first button of text field 1 of last group of toolbar 1 of front window whose description is "cancel")
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end clearSearch
	end script
end new
