global std, logger, config, flag, pots, sessionPlist

use script "RoyceTech String Utilities"
use scripting additions

property initialized : false

-- spotCheck() -- IMPORTANT: Comment out on deploy

to spotCheck()
	init()
	logger's start("spot-spotCheck")
	
	set sut to newInstance("spot-spotCheck", {"one", "two", "three", "four", "five"})
	set autoIncrement of sut to true
	set currentCase to sut's start()
	
	-- do some tests here
	log currentCase
	
	sut's finish()
	logger's finish()
end spotCheck


on newInstance(pCaseId as text, pCases as list)
	script CaseInstance
		property caseId : pCaseId
		property cases : pCases
		property autoIncrement : false
		
		property _currentCase : 0
		property _currentCaseCount : 0
		property _valid : true
		
		(* @returns {caseId, caseDescription} *)
		on start()
			set newCaseCount to count of cases
			set _currentCaseCount to length of sessionPlist's getList("Case Labels")
			set caseIdChanged to sessionPlist's getString("Case ID") is not equal to caseId
			set caseCountChanged to newCaseCount is not equal to _currentCaseCount
			set REINITIALIZE to caseIdChanged or caseCountChanged
			sessionPlist's setValue("Case Labels", cases)
			
			if REINITIALIZE is true then
				if caseIdChanged then
					sessionPlist's setValue("Case ID", caseId)
					sessionPlist's setValue("Current Case Index", 1)
					set my _valid to false
					
					tell pots to speak("Subject Changed, select desired case from menu and re-run")
					return {0, "Re-run recommended"}
					
				else
					if newCaseCount is less than _currentCaseCount then
						sessionPlist's setValue("Current Case Index", newCaseCount)
						logger's warn("Number of cases reduced, running the last in the list")
					else
						logger's warn("Number of cases increased, running the next new case")
						sessionPlist's setValue("Current Case Index", _currentCaseCount + 1)
					end if
				end if
			end if
			
			set _currentCase to sessionPlist's getInt("Current Case Index")
			logger's infof("Running case: {}/{}: {}", {_currentCase, _currentCaseCount, item _currentCase of cases})
			{_currentCase as integer, item _currentCase of cases}
		end start
		
		
		to setAutoIncrement(newValue)
			set incrementFlag to flag's newInstance("Auto Increment Case Index")
			incrementFlag's setValue(newValue)
		end setAutoIncrement
		
		
		on finish()
			if my _valid is false then return
			
			if autoIncrement then
				sessionPlist's setValue("Current Case Index", _currentCase + 1)
				if _currentCase is greater than or equal to _currentCaseCount then
					logger's info("End reached, restarting to 1")
					sessionPlist's setValue("Current Case Index", 1)
				end if
			end if
			
		end finish
	end script
	
	set incrementFlag to flag's newInstance("Auto Increment Case Index")
	set autoIncrement of CaseInstance to incrementFlag's active()
	CaseInstance
end newInstance


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")
	set plist to std's import("plist-flat")
	set sessionPlist to plist's newInstance("session")
	
	set flag to std's import("flag")
	set pots to std's import("pots")
end init
