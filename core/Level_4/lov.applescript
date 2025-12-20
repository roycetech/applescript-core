(*
	Allows you to manage a list of values.

	@Installation Example:
		$ ./scripts/plist-array-append.sh "spot-lov" "option 1" ~/applescript-core/lov.plist

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/Level_4/lov

	@Last Modified: 2025-12-20 11:15:45
*)

use scripting additions

use listUtil : script "core/list" -- keep here.

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value

property plutil : missing value
property session : missing value

property PLIST_LOV : "lov"
property SESSION_KEY_SELECTED_SUFFIX : " - LOV Selected"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Binary
		Manual: Tertiary
		Manual: missing value returns the first item
	")

	set spotScript to script "core/spot-test"
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

	else if caseIndex is 3 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(lovName)
	loggerFactory's injectBasic(me)
	set plutil to plutilLib's new()
	set session to plutil's new("session")

	script LovInstance
		property _lovName : lovName
		property _lov : missing value
		property _plistName : missing value

		on getSavedValue()
			session's getValue(_lovName & SESSION_KEY_SELECTED_SUFFIX)
		end getSavedValue

		on setSavedValue(newValue)
			session's setValue(_lovName & SESSION_KEY_SELECTED_SUFFIX, newValue)
		end setSavedValue

		(*
			@Deprecated: Use #hasElement.
		*)
		on hasValue(targetElement)
			hasElement(targetElement)
		end hasValue

		on hasElement(targetElement)
			listUtil's listContains(_lov, targetElement)
		end hasElement


		on getElements()
			_lov
		end getElements

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


		on getFirstValue()
			if _lov is missing value or (count of _lov) is 0 then return missing value

			item 1 of _lov
		end getFirstValue


		on getLastValue()
			if _lov is missing value or (count of _lov) is 0 then return missing value

			last item of _lov
		end getLastValue


		on isBinary()
			if _lov is missing value then return missing value

			(count of my _lov) is 2
		end isBinary

		(* Used by unit test. *)
		on _setLovPlist(plistName, lovName)
			set _plistName to plistName
			set lovPlist to plutil's new(plistName)
			set _lov to lovPlist's getValue(lovName)
		end _setLovPlist
	end script
	result's _setLovPlist(PLIST_LOV, lovName)

	LovInstance
end new
