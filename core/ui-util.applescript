global std

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "ui-util-spotCheck"
	logger's start()
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Find By ID - not found
		Manual: Find By ID - found
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	tell application "System Events" to tell process "Safari"
		set uiButtons to buttons of group 1 of toolbar 1 of front window
	end tell
	set sut to new(uiButtons)
	
	if caseIndex is 1 then
		assertThat of std given condition:sut's findById("solid") is missing value, messageOnFail:"Failed spot check"
		
	else if caseIndex is 2 then
		assertThat of std given condition:sut's findById("SidebarButton") is not missing value, messageOnFail:"Failed spot check"
		
	end if
		logger's info("Passed.")
	
	spot's finish()
	logger's finish()
end spotCheck


on new(pUiElements)
	script ElementsInstance
		property uiElements : pUiElements
		
		(*  *)
		on findById(targetIdentifier)
			repeat with nextUI in uiElements
				tell application "System Events"
					set uiId to get value of attribute "AXIdentifier" of nextUI
				end tell
				if uiId is equal to targetIdentifier then return nextUI
			end repeat
			
			missing value
		end findById
	end script
end new


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("ui-util")
end init
