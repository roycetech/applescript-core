(*
	This script is used for spot checking a library. It is used by almost all
	libraries. Only the most fundamental scripts are not using this.

	WARNING: The log needs to choose between console and logger object each time
	we need to log to avoid the circular dependency.

	@Special Features:
		Run new case after adding a new case.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/spot-test

	@Last Modified: 2025-08-29 07:19:51

	@Change Logs:
		Wed, Jul 23, 2025 at 11:40:43 AM - Allow direct run.
		Mon, Jan 20, 2025 at 7:42:38 AM - Trigger Menu Case app refresh

*)

use scripting additions

use script "core/Text Utilities"

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"
use switchLib : script "core/switch"

property SESSION_KEY_RUN_SPOT_DIRECT : "app-core: Run Spot Direct"

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

property SWITCH_AUTO_INCREMENT_CASE : "Auto Increment Case Index"
property SESS_CURRENT_CASE_INDEX : "Current Case Index"
property SESS_CASE_ID : "Case ID"
property SESS_CASE_LABELS : "Case Labels"

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
			session's setValue(SESS_CURRENT_CASE_INDEX, newCaseIndex)
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
					set caseLabels to session's getList(SESS_CASE_LABELS)
					if caseLabels is missing value then set caseLabels to {}
					set _currentCaseCount to length of caseLabels
					set caseIdChanged to session's getString(SESS_CASE_ID) is not equal to caseId
					set caseCountChanged to newCaseCount is not equal to _currentCaseCount
					set runDirect to session's getBool(SESSION_KEY_RUN_SPOT_DIRECT)
					set REINITIALIZE to (caseIdChanged or caseCountChanged) and not runDirect and newCaseCount is greater than 1
					session's setValue(SESS_CASE_LABELS, cases)

					if REINITIALIZE is true then
						if caseIdChanged then
							session's setValue(SESS_CASE_ID, caseId)
							session's setValue(SESS_CURRENT_CASE_INDEX, 1)
							set my _valid to false

							set noticeText to "Subject Changed, select desired case from menu and re-run"
							logger's info(noticeText)
							notifyChange({event_type:"spot:event:new-case", case_index:_currentCase as integer})
							return {0, "Re-run recommended"}

						else
							if newCaseCount is less than _currentCaseCount then
								session's setValue(SESS_CURRENT_CASE_INDEX, newCaseCount)
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
									-- logger's debugf("_currentCaseCount: {}", _currentCaseCount)
									-- logger's debugf("newCaseCount: {}", newCaseCount)
								end if
								session's setValue(SESS_CURRENT_CASE_INDEX, _currentCaseCount + 1)
							end if
							set _currentCaseCount to newCaseCount
						end if
					end if

					set _currentCase to session's getInt(SESS_CURRENT_CASE_INDEX)
					-- DEBUG_LOGF("_currentCase", _currentCase)

					if _currentCase is 0 or _currentCase is greater than the number of items in cases then
						-- DEBUG_LOGF("Resetting case to 1 because of case label count", number of items in caseLabels)

						set _currentCase to 1
						session's setValue(SESS_CURRENT_CASE_INDEX, _currentCase)
					end if

					set autoText to "M"
					if autoIncrement is true then set autoText to "A"

					set calculatedCaseCount to _currentCaseCount
					if newCaseCount is 1 then set _currentCaseCount to newCaseCount

					if my logger is missing value then
						log "Running case: " & _currentCase & "/" & _currentCaseCount & " (" & autoText & "): " & item _currentCase of cases
					else
						logger's infof("Running case: {}/{} ({}): {}", {_currentCase, _currentCaseCount, autoText, item _currentCase of cases})
					end if

					notifyChange({event_type:"spot:event:run-case", case_index:_currentCase as integer})
					session's deleteKey(SESSION_KEY_RUN_SPOT_DIRECT)
					{_currentCase as integer, item _currentCase of cases}
				end start


				(* eventRecord - a record containing event_type and or case_index. *)
				on notifyChange(eventRecord)

				end notifyChange


				on setAutoIncrement(newValue)
					set incrementSwitch to switchLib's new(SWITCH_AUTO_INCREMENT_CASE)
					incrementSwitch's setValue(newValue)
				end setAutoIncrement


				on finish()
					if my _valid is false then return

					if autoIncrement then
						session's setValue(SESS_CURRENT_CASE_INDEX, _currentCase + 1)
						if _currentCase is greater than or equal to _currentCaseCount then
							if my logger is missing value then
								log "End reached, restarting to 1"
							else
								logger's info("End reached, restarting to 1")
							end if
							session's setValue(SESS_CURRENT_CASE_INDEX, 1)
						end if
					end if

				end finish


				on DEBUG_LOGF(message, value)
					if my logger is missing value then
						log "DEBUG " & message & ": " & value
					else
						logger's debugf("{}: {}", {message, value})
					end if
				end DEBUG_LOGF

				on DEBUG_LOG(message)
					if my logger is missing value then
						log "DEBUG " & message
					else
						logger's debug(message)
					end if
				end DEBUG_LOG

			end script

			set incrementSwitch to switchLib's new(SWITCH_AUTO_INCREMENT_CASE)
			set autoIncrement of SpotTestCaseInstance to incrementSwitch's active()

			set decoratorInner to decoratorLib's new(SpotTestCaseInstance)
			decoratorInner's decorate()
		end new
	end script

	set decoratorOuter to decoratorLib's new(result)
	decoratorOuter's decorate()
end new

