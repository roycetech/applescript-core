(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to the keychain.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Safari/16.0/dec-safari-keychain

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2026-02-20 13:17:10
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Info only
		Manual: Select Keychain
		Manual: Show other passwords
		Manual: Select other password
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	activate application "Safari"
	set sutLib to script "core/safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Keychain form visible: {}", sut's isKeychainFormVisible())
	if caseIndex is 1 then

	else if caseIndex is 2 then
		logger's infof("Keychain clicked: {}", sut's selectKeychainItem("Unicorn"))

	else if caseIndex is 3 then
		sut's showOtherPasswords()

	else if caseIndex is 4 then
		sut's showOtherPasswords()
		logger's infof("Keychain clicked: {}", sut's selectOtherKeychainItem("ft-admin"))

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set delayAfterKeySeconds of kb to 0.05

	script SafariKeychainDecorator
		property parent : mainScript

		on showOtherPasswords()
			if running of application "Safari" is false then return

			tell application "System Events" to tell process "Safari"
				set frontmost to true
				delay 0.1
				set optionsCount to the (number of rows of table 1 of scroll area 1) - 1
				logger's debugf("optionsCount: {}", optionsCount)
				repeat optionsCount times
					kb's pressKey("down")
				end repeat
				kb's pressKey("enter")
			end tell
		end showOtherPasswords

		(*
			NOTE: Native AppleScript click command does not work. Tested on Ventura.

			@returns true if successfully clicked.
		*)
		on selectKeychainItem(itemName)
			if running of application "Safari" is false then return

			set itemIndex to 0
			tell application "System Events" to tell process "Safari"
				set frontmost to true
				try
					repeat with nextRow in rows of table 1 of scroll area 1
						set itemIndex to itemIndex + 1
						if value of static text 1 of UI element 1 of nextRow is equal to itemName then
							repeat itemIndex times
								kb's pressKey("down")
							end repeat
							kb's pressKey("enter")
							return true

						end if
					end repeat
				end try
			end tell
			false
		end selectKeychainItem


		(*
			Copied from selectKeychainItem
			@returns true if successfully clicked.
		*)
		on selectOtherKeychainItem(itemName)
			if running of application "Safari" is false then return

			set itemIndex to 0
			tell application "System Events" to tell process "Safari"
				set frontmost to true
				delay 0.1
				try
					repeat with nextRow in rows of table 1 of scroll area 1
						set itemIndex to itemIndex + 1
						set rowIsMatched to value of static text 1 of UI element 1 of nextRow is equal to itemName
						if rowIsMatched then
							-- Selection defaults at the 2nd item.
							if itemIndex is 1 then
								kb's pressKey("up")
							else if itemIndex is 2 then
								-- noop
							else
								repeat itemIndex - 2 times
									kb's pressKey("down")
								end repeat
							end if
							kb's pressKey("enter")
							return true
						end if
					end repeat
				end try
			end tell
			false
		end selectOtherKeychainItem


		on isKeychainFormVisible()
			tell application "System Events" to tell process "Safari"
				exists (table 1 of scroll area 1)
			end tell
		end isKeychainFormVisible
	end script
end decorate
