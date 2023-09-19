(*
	@Created: July 9, 2023 11:52 AM
	@Last Modified: 2023-09-18 22:33:08
*)

use loggerFactory : script "core/logger-factory"

use listUtil : script "core/list"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Found
		Manual: Not found
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then
		set sutTabName to "General"
		set sutTabName to "About"
		logger's debugf("sutTabName: {}", sutTabName)
		sut's switchPreferencesTab(sutTabName)
		-- logger's infof("Handler result: {}, ", )
		-- assertThat of std without condition given messageOnFail:"Failed spot check"
		-- logger's info("Passed")

	else if caseIndex is 2 then
		set sutTabName to "Unicorn"
		logger's debugf("sutTabName: {}", sutTabName)
		sut's switchPreferencesTab(sutTabName)

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck

(*  *)
on new()
	script MosaicInstance
		on switchPreferencesTab(newTabName)
			if running of application "Mosaic" is false then return

			tell application "System Events" to tell process "Mosaic"
				try
					click (first button of toolbar 1 of front window whose name is newTabName)
				end try
			end tell
		end switchPreferencesTab
	end script
end new

