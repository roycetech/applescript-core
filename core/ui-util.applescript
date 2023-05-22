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
		Manual: Find By ID - not found
		Manual: Find By ID - found
		Manual: Find Containing ID - found
		Manual: Print Attributes
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
	set sut to new()
	
	if caseIndex is 1 then
		tell application "System Events" to tell process "Control Center"
			assertThat of std given condition:sut's findUiWithIdAttribute(menu bar item 2 of menu bar 1, "x") is missing value, messageOnFail:"Failed spot check"
		end tell
		
	else if caseIndex is 2 then
		tell application "System Events" to tell process "Control Center"
			assertThat of std given condition:sut's findUiWithIdAttribute(menu bar item 2 of menu bar 1, "com.apple.menuextra.controlcenter") is not missing value, messageOnFail:"Failed spot check"
		end tell
		
	else if caseIndex is 3 then
		-- Activate Control Center
		tell application "System Events" to tell process "ControlCenter"
			try
				click (first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" is "com.apple.menuextra.controlcenter")
			end try
		end tell
		
		tell application "System Events" to tell process "Control Center"
			log sut's findUiContainingIdAttribute(UI elements of group 1 of front window, "controlcenter-focus-modes") is not missing value
		end tell
		
	else if caseIndex is 4 then
		tell application "System Events" to tell process "Control Center"
			sut's printAttributeValues(menu bar item 2 of menu bar 1)
		end tell
	end if
	logger's info("Passed.")
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script UiUtilInstance
		(*
			Use this when the usual format fails. e.g. 'first static text of group 1 of splitter group 1 of front window whose value of attribute "AXIdentifier" is "notes-field"'
	
			@returns the UI with the matched attribute or missing value.
		*)
		on findUiWithIdAttribute(uiList, idAttribute)
			tell application "System Events"
				repeat with nextUIElement in uiList
					try
						set uiId to value of attribute "AXIdentifier" of nextUIElement
						if uiId is equal to the idAttribute then return nextUIElement
					end try
				end repeat
			end tell
			
			missing value
		end findUiWithIdAttribute
		
		(*
			Derived from findUiWithIdAttribute as a fix for Apple bug where the 
			AXIdentifier value is doubled (e.g. controlcenter-focus-modes-controlcenter-focus-modes), 
	
			@returns the UI with the matched attribute or missing value.
		*)
		on findUiContainingIdAttribute(uiList, idAttributeKeyword)
			tell application "System Events"
				repeat with nextUIElement in uiList
					try
						set uiId to value of attribute "AXIdentifier" of nextUIElement
						if uiId contains the idAttributeKeyword then return nextUIElement
					end try
				end repeat
			end tell
			
			missing value
		end findUiContainingIdAttribute
		
		
		on printAttributeValues(uiElement)
			tell application "System Events" to tell process ""
				
				set attrList to attributes of uiElement
				repeat with nextAttribute in attrList
					try
						log "Name: " & name of nextAttribute & ", Value: " & value of nextAttribute
					end try
				end repeat
			end tell
			
		end printAttributeValues
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
