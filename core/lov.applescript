(*
	Allows you to manage a list of values.

	@Plists:
		lov.plist

	@Installation Example:
		$ ./scripts/plist-array-append.sh "spot-lov" "option 1" ~/applescript-core/lov.plist

	@Build:
		make compile-lib SOURCE=core/lov

	@Last Modified: 2023-09-05 12:05:52
*)

use listUtil : script "list"

use loggerLib : script "logger"
use plutilLib : script "plutil"

use spotScript : script "core/spot-test"

use loggerFactory : script "logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Binary
		Manual: Tertiary
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	if caseIndex is 1 then
		set sut to new("spot")
		set lov to sut's getLov()
		repeat with nextValue in lov
			logger's infof("nextValue: {}", nextValue)
		end repeat

		logger's infof("next of XXX: {}", sut's getNextValue("xxx"))
		logger's infof("next of Option 1: {}", sut's getNextValue("Option 1"))
		logger's infof("next of Option 2: {}", sut's getNextValue("Option 2"))
		logger's infof("Is Binary: {}", sut's isBinary())
		logger's infof("Has Value: {}", sut's hasValue("Option 2"))
		logger's infof("Has Value: {}", sut's hasValue("Option X"))

	else if caseIndex is 2 then
		set sut to new("spot3")
		set lov to sut's getLov()
		repeat with nextValue in lov
			logger's infof("nextValue: {}", nextValue)
		end repeat

		logger's infof("next of XXX: {}", sut's getNextValue("xxx"))
		logger's infof("next of Option 1: {}", sut's getNextValue("Option 1"))
		logger's infof("next of Option 2: {}", sut's getNextValue("Option 2"))
		logger's infof("Has Value: {}", sut's hasValue("Option 2"))
		logger's infof("Has Value: {}", sut's hasValue("Option X"))
		logger's infof("Is Binary: {}", sut's isBinary())
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(lovName)
	loggerFactory's injectBasic(me)
	set plutil to plutilLib's new()
	set localLovPlist to plutil's new("lov")

	script LovInstance
		property _lovName : lovName
		property _lov : localLovPlist's getValue(lovName)

		on hasValue(targetElement)
			listUtil's listContains(_lov, targetElement)
		end hasValue

		on getLov()
			_lov
		end getLov

		on getNextValue(currentValue)
			if _lov is missing value or (count of _lov) is 0 then return missing value

			set nextIndex to 1
			set currentIndex to listUtil's indexOf(_lov, currentValue)
			try
				return item (currentIndex + 1) of _lov
			end try

			item 1 of _lov
		end getNextValue

		on isBinary()
			(count of my _lov) is 2
		end isBinary
	end script
end new
