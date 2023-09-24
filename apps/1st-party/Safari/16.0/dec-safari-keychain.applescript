(*
	@Purpose:
		The original safari script is quite big and we want to improve its manageability by breaking it down into smaller pieces.
		This decorator will contain the handlers relating to the keychain.

	@Created: Wednesday, September 20, 2023 at 10:13:11 AM
	@Last Modified: 2023-09-24 10:53:08
	@Change Logs: .
*)
use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"
use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual:
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "safari"
	set sut to sutLib's new()
	set sut to decorate(sut)

	-- 	logger's infof("Is Loading: {}", sut's isLoading())

	if caseIndex is 1 then
		activate application "Safari"
		kb's pressCommandKey("r")
		delay 1
		logger's infof("Is Loading: {}", sut's isLoading())

	else if caseIndex is 2 then

	else if caseIndex is 3 then

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

	set kb to kbLib's new()

	script SafariKeychainDecorator
		property parent : mainScript

		(*
			@returns true if successfully clicked.
		*)
		on selectKeychainItem(itemName)
			if running of application "Safari" is false then return

			set itemIndex to 0
			tell application "System Events" to tell process "Safari"
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


		on isKeychainFormVisible()
			tell application "System Events" to tell process "Safari"
				exists (scroll area 1)
			end tell
		end isKeychainFormVisible
	end script
end decorate
