global std, usr

(*
	Provides handlers about the meeting window.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "zoom-window-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Close Home Window (Screen Sharing/Non Sharing)
		Manual: Toggle Always on Top
		Manual: Turn On Always on Top
		Manual: Turn Off Always on Top
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to std's import("zoom")'s new()
	try
		sut's bringWindowToFront
	on error
		set sut to decorate(sut)
	end try
	
	if caseIndex is 1 then
		sut's closeHomeWindow()
		
	else if caseIndex is 2 then
		sut's toggleAlwaysOnTop()
		
	else if caseIndex is 3 then
		sut's turnOnAlwaysOnTop()
		
	else if caseIndex is 4 then
		sut's turnOffAlwaysOnTop()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	script ZoomInstance
		property parent : mainScript
		
		
		(* POC, use the closeHomeWindow for now. *)
		on closeNonMeetingWindows()
			tell application "System Events" to tell process "zoom.us"
				-- click (first button of (windows whose subrole is "AXDialog") whose description is "Close") -- Don't do this, will result in closing the meeting window as well.
				
				
			end tell
			
			closeHomeWindow()
		end closeNonMeetingWindows
		
		(*
			NOTES:
				No need to activate the zoom app.
				Find the window with the home button, this is a tab bar.
				There will be 2 windows whose title is "Zoom", one contains "Home" button, and we want to close this window.
		*)
		on closeHomeWindow()
			if not running of application "zoom.us" then
				logger's debug("closeHomeWindow: zoom.us app is not running")
				return
			end if
			
			tell application "System Events" to tell process "zoom.us"
				set found to false
				repeat with nextWindow in (every window whose title is "Zoom")
					try
						set theSplitterGroup to first splitter group of nextWindow -- does not work
						if exists (first button of first splitter group of nextWindow whose value starts with "Home") then
							click (first button of first splitter group of nextWindow whose description is "close button")
							set found to true
							exit repeat
						end if
					end try
				end repeat
				
				if found then
					logger's debug("Zoom Home window was found and closed.")
					return
				end if
				
				logger's debug("The Zoom home window was not found")
			end tell
		end closeHomeWindow
		
		
		on turnOnAlwaysOnTop()
			if not running of application "zoom.us" then return
			
			if not running of application "zoom.us" then return
			
			tell application "System Events" to tell process "zoom.us"
				try
					if value of attribute "AXMenuItemMarkChar" of menu item "Keep on Top" of menu 1 of menu bar item "Meeting" of menu bar 1 is missing value then
						my toggleAlwaysOnTop()
					else
						logger's info("Keey on Top is already active")
					end if
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end turnOnAlwaysOnTop
		
		
		on turnOffAlwaysOnTop()
			if not running of application "zoom.us" then return
			
			tell application "System Events" to tell process "zoom.us"
				try
					if value of attribute "AXMenuItemMarkChar" of menu item "Keep on Top" of menu 1 of menu bar item "Meeting" of menu bar 1 is not missing value then
						my toggleAlwaysOnTop()
					else
						logger's info("Keey on Top is already inactive")
					end if
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end turnOffAlwaysOnTop
		
		
		on toggleAlwaysOnTop()
			if not running of application "zoom.us" then return false
			
			tell application "System Events" to tell process "zoom.us"
				try
					click menu item "Keep on Top" of menu 1 of menu bar item "Meeting" of menu bar 1
				end try
			end tell
		end toggleAlwaysOnTop
	end script
end decorate


-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set usr to std's import("user")'s new()
	set logger to std's import("logger")'s new("zoom-window")
end init
