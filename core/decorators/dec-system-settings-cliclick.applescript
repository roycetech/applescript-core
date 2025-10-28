(*
	@Purpose:
		Fix retrieval of password because the regular click doesn't trigger the menu like before.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-system-settings-cliclick

	@Created: Saturday, September 21, 2024 at 10:36:44 AM
	@Last Modified: 2025-10-26 12:58:26
	@Change Logs:
*)
use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"
use clipLib : script "core/clipboard"
use cliclickLib : script "core/cliclick"

property logger : missing value

property clip : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
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
	set sutLib to script "core/system-settings"
	set sut to sutLib's new()
	set sut to decorate(sut)

	log (format {"Password: {}", sut's getPassword()})

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set clip to clipLib's new()
	set cliclick to cliclickLib's new()

	script SystemSettingsDecorator
		property parent : mainScript

		on getPassword()
			if running of application "System Settings" is false then return missing value

			script ExtractPassword
				tell application "System Events" to tell process "System Settings"
					set frontmost to true
					try
						set targetUI to static text 6 of group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
					on error -- Changed DOM.
						set targetUI to UI element 4 of group 1 of scroll area 1 of group 1 of sheet 1 of window "Passwords"
					end try

					-- perform action "AXShowMenu" of targetUI -- Stopped working.
					-- click targetUI
					lclick of cliclick at targetUI given relativex:100
					delay 0.1
					click menu item "Copy Password" of menu 1 of group 1 of sheet 1 of window "Passwords"
				end tell
			end script
			clip's extract(result)
		end getPassword
	end script
end decorate
