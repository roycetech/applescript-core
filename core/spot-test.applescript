(*
	This script is used for spot checking a library. It is used by almost all
	libraries. Only the most fundamental scripts are not using this.

	WARNING: The log needs to choose between console and logger object each time
	we need to log to avoid the circular dependency.

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/spot-test

	@Last Modified: 2023-09-25 14:57:57
*)

use script "core/Text Utilities"
use scripting additions

use loggerFactory : script "core/logger-factory"
use plutilLib : script "core/plutil"
use switchLib : script "core/switch"

use decoratorLib : script "core/decorator"

(*
	Let's optionally use a logger only when this script is being spot checked.

	@Use cases:
		Testing this class
		Testing another class
		Testing the logger class
*)
property session : missing value

property logger : missing value

tell application "System Events"
	set scriptName to get name of (path to me)
end tell

if {"Script Editor", "Script Debugger"} contains the name of current application then
	if scriptName is "spot-test.applescript" then spotCheck()
end if

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set spotClass to new()
	set sut to spotClass's new("spot-spotCheck", {"one", "two", "three", "four", "five"})
	set autoIncrement of sut to true
	set currentCase to sut's start()

	-- do some tests here
	if my logger is missing value then
		log "Current Case"
		log currentCase
	else
		my logger's logObj("Current Case", currentCase)
	end if

	sut's finish()

	if my logger is missing value then
		log "Spot check completed."
	else
		logger's finish()
	end if
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	set session to plutilLib's new()'s new("session")

	script SpotTestInstance
		on setSessionCaseIndex(newCaseIndex)
			session's setValue("Current Case Index", newCaseIndex)
		end setSessionCaseIndex

		(*
			@pCaseId test case identifier. It can be a string or the object itself.
			@pCases the list of test cases usually retrieved from the session.
		*)
		on new(pCaseId, pCases)
			set localCaseId to pCaseId
			if class of pCaseId is script then
				set localCaseId to (the name of pCaseId) & "-spot"
			end if

			script SpotTestCaseInstance
				property caseId : localCaseId
				property cases : pCases
				property autoIncrement : false

				property _currentCase : 0
				property _currentCaseCount : 0
				property _valid : true

				(* @returns {caseId, caseDescription} *)
				on start()
					set newCaseCount to count of cases
					set caseLabels to session's getList("Case Labels")
					if caseLabels is missing value then set caseLabels to {}
					set _currentCaseCount to length of caseLabels
					set caseIdChanged to session's getString("Case ID") is not equal to caseId
					set caseCountChanged to newCaseCount is not equal to _currentCaseCount
					set REINITIALIZE to caseIdChanged or caseCountChanged
					session's setValue("Case Labels", cases)

					if REINITIALIZE is true then
						if caseIdChanged then
							session's setValue("Case ID", caseId)
							session's setValue("Current Case Index", 1)
							set my _valid to false

							set noticeText to "Subject Changed, select desired case from menu and re-run"
							logger's info(noticeText)
							notifyChange({event_type: "spot:event:new-case", case_index: _currentCase as integer})
							return {0, "Re-run recommended"}

						else
							if newCaseCount is less than _currentCaseCount then
								session's setValue("Current Case Index", newCaseCount)
								if my logger is missing value then
									log "Number of cases reduced, running the last in the list"
								else
									logger's warn("Number of cases reduced, running the last in the list")
								end if
							else
								if my logger is missing value then
									log "Number of cases increased, running the next new case"
								else
									logger's warn("Number of cases increased, running the next new case")
								end if
								session's setValue("Current Case Index", _currentCaseCount + 1)
							end if
							set _currentCaseCount to newCaseCount
						end if
					end if

					set _currentCase to session's getInt("Current Case Index")
					if _currentCase is 0 or _currentCase is greater than the number of items in caseLabels then
						set _currentCase to 1
						session's setValue("Current Case Index", _currentCase)
					end if

					set autoText to "M"
					if autoIncrement is true then set autoText to "A"
					if my logger is missing value then
						log "Running case: " & _currentCase & "/" & _currentCaseCount & " (" & autoText & "): " & item _currentCase of cases
					else
						logger's infof("Running case: {}/{} ({}): {}", {_currentCase, _currentCaseCount, autoText, item _currentCase of cases})
					end if
					notifyChange({event_type: "spot:event:run-case", case_index: _currentCase as integer})
					{_currentCase as integer, item _currentCase of cases}
				end start

				(* event a record containing type and or case_index. *)
				on notifyChange(event)

				end notifyChange

				on setAutoIncrement(newValue)
					set incrementSwitch to switchLib's new("Auto Increment Case Index")
					incrementSwitch's setValue(newValue)
				end setAutoIncrement


				on finish()
					if my _valid is false then return

					if autoIncrement then
						session's setValue("Current Case Index", _currentCase + 1)
						if _currentCase is greater than or equal to _currentCaseCount then
							if my logger is missing value then
								log "End reached, restarting to 1"
							else
								logger's info("End reached, restarting to 1")
							end if
							session's setValue("Current Case Index", 1)
						end if
					end if

				end finish
			end script

			set incrementSwitch to switchLib's new("Auto Increment Case Index")
			set autoIncrement of SpotTestCaseInstance to incrementSwitch's active()

			set decoratorInner to decoratorLib's new(SpotTestCaseInstance)
			decoratorInner's decorate()
		end new
	end script

	set decoratorOuter to decoratorLib's new(result)
	decoratorOuter's decorate()
end new

