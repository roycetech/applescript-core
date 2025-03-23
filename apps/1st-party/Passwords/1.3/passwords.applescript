(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Passwords/1.3/passwords

	@Created: Fri, Mar 07, 2025 at 08:42:28 AM
	@Last Modified: 2025-03-16 12:40:59
*)
use scripting additions

use loggerFactory : script "core/logger-factory"
use clipLib : script "core/clipboard"

property logger : missing value
property clip : missing value

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
	logger's infof("Current username: {}", sut's getCurrentUsername())
	logger's infof("Current password: {}", sut's getCurrentPassword())

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
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set clip to clipLib's new()

	script PasswordsInstance
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
				set searchField to text field 1 of group 3 of splitter group 1 of group 1 of front window
				set focused of searchField to true
				set value of searchField to searchKey

			end tell
		end search


		on selectFirstCredential()
			if running of application "Passwords" is false then return
			if isLocked() then return

			tell application "System Events" to tell process "Passwords"
				try
					set selected of row 2 of outline 1 of scroll area 1 of group 2 of splitter group 1 of group 1 of front window to true
				end try -- In case no credential is listed
			end tell
		end selectFirstCredential


		on getCurrentUsername()
			if running of application "Passwords" is false then return missing value
			if isLocked() then return missing value

			tell application "System Events" to tell process "Passwords"
				return get value of static text 1 of group 1 of scroll area 1 of group 4 of splitter group 1 of group 1 of front window
			end tell
			missing value
		end getCurrentUsername


		on getCurrentPassword()
			if running of application "Passwords" is false then return missing value
			if isLocked() then return missing value

			script ClipboardWaiter
				tell application "System Events" to tell process "Passwords"
					set frontmost to true
					click menu item "Copy Password" of menu 1 of menu bar item "Edit" of menu bar 1
				end tell
			end script
			clip's extract(result)
		end getCurrentPassword

		on clearSearch()
			if running of application "Passwords" is false then return missing value
			if isLocked() then return missing value

			tell application "System Events" to tell process "Passwords"
				try
					click (first button of text field 1 of group 3 of splitter group 1 of group 1 of front window whose description is "cancel")
				end try
			end tell
		end clearSearch
	end script
end new
