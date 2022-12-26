global std

(* 
	Usage:
		set cp to std's import("clipboard")'s new()
		
	NOTE: Currently only supports text contents. May support other data types in the future.
*)

use scripting additions

property logger : missing value
property initialized : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "clipboard-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Manual: Extract From a Script
		Manual: Save the Clipboard value
		Manual E2E: Save and Restore the Clipboard value.
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
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
	end script
end new





-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("clipboard")
end init
