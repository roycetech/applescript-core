(*
	Usage:
		use clipboardLib : script "clipboard"

		property cp : clipboardLib's new()

	NOTE: Currently only supports text contents. May support other data types in the future.
*)

use scripting additions

use loggerFactory : script "logger-factory"
use listUtil : script "list"
use spotScript : script "spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)

	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Extract From a Script
		Manual: Save the Clipboard value
		Manual E2E: Save and Restore the Clipboard value
		Manual: Copy That (None, Selected)
		Manual Copy That Word (None, One Word, Multi)
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
		(*
			Manual Steps:
			1. Store something in the clipboard.
			2. Run this script
			3. Should log "Passed"
			4. Trigger paste command and should paste the value stored from step 1.
		*)
		script Manipulate
			set the clipboard to "Moohaha"
		end script
		set extractedValue to sut's extract(Manipulate)
		assertThat of std given condition:extractedValue is equal to "Moohaha", messageOnFail:"Failed spot check"
		logger's info("Passed")

	else if caseIndex is 2 then
		(*
			Manual Steps:
			1. Store something in the clipboard.
			2. Run this test case
			3. Should log "Passed"
			4. Trigger paste command and should paste the value stored from step 1.
		*)
		assertThat of std given condition:sut's getSavedValue() is missing value, messageOnFail:"Failed on pre-run state"
		sut's saveCurrent()
		assertThat of std given condition:sut's getSavedValue() is not missing value, messageOnFail:"Failed to save the current clipboard"

	else if caseIndex is 3 then
		assertThat of std given condition:sut's getSavedValue() is missing value, messageOnFail:"Failed on pre-run state"
		set the clipboard to "$spot"
		sut's saveCurrent()
		assertThat of std given condition:sut's getSavedValue() is not missing value, messageOnFail:"Failed to save the current clipboard"
		set the clipboard to "$spot-changed"
		delay 0.1
		assertThat of std given condition:(the clipboard) is not equal to "$spot", messageOnFail:"Failed to manipulate the clipboard value midway"
		sut's restore()
		assertThat of std given condition:(the clipboard) is equal to "$spot", messageOnFail:"Failed to restore the clipboard value"
		logger's info("Passed")

	else if caseIndex is 4 then
		(*
			Beeps when none is selected
		*)
		set copiedText to sut's copyThat()
		logger's infof("copied text: {}", copiedText)


	else if caseIndex is 5 then
		(*
			Beeps when none is selected
		*)
		set copiedText to sut's copyThatWord()
		logger's infof("copied text: {}", copiedText)
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	script ClipboardInstance
		property _clipValue : missing value

		(* Retrieve the value of the clipboard from the passed script without altering the actual value of the clipboard. *)
		on extract(scriptObj)
			saveCurrent()

			run of scriptObj

			set maxWait to 50 -- 5 seconds
			repeat until (the clipboard) is not ""
				delay 0.1
			end repeat

			set theResult to the clipboard
			restore()
			theResult
		end extract


		(*  *)
		on saveCurrent()
			set _clipValue to the clipboard
			repeat until _clipValue is equal to (the clipboard)
				delay 0.1
			end repeat
			set the clipboard to ""
			repeat until (the clipboard) is ""
				delay 0.1
			end repeat
		end saveCurrent

		on getSavedValue()
			_clipValue
		end getSavedValue

		on restore()
			set the clipboard to _clipValue
			repeat until _clipValue is equal to (the clipboard)
				delay 0.1
			end repeat
			_clipValue
		end restore


		(* Copies the selected text of the active app. *)
		on copyThat()
			try
				set originalClipboard to the clipboard
			on error
				set originalClipboard to ""
			end try

			set the clipboard to ""
			repeat until (the clipboard) is ""
				delay 0.1
			end repeat

			tell application "System Events"
				key code 8 using {command down} -- C
				delay 0.1
			end tell

			set theCopiedItem to ""
			set maxTry to 10
			set tryCount to 0
			repeat until theCopiedItem is not ""
				set tryCount to tryCount + 1
				if tryCount is greater than or equal to maxTry then exit repeat
				delay 0.1
				set theCopiedItem to the clipboard
			end repeat

			set the clipboard to originalClipboard
			delay 0.1

			theCopiedItem
		end copyThat


		(* Sends copy key stroke to the currently active app, and returns the selected word if present. Returns empty string if no text is selected, or when there are multiple words in the current line. *)
		on copyThatWord()
			set theCopiedItem to copyThat()

			try
				if (count of words in theCopiedItem) is 1 then return theCopiedItem
			end try

			missing value
		end copyThatWord
	end script
end new
