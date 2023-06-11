global std

(*
	This library contains commonly used system event functions. 
	For additional functions related to the inspection of a process or a window, see inspector.applescript.
	For additional functions related to a process/app, see process.applescript.
	
	Usage:
		set syseve to std's import("system-events")
	Or type: sset syseve
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set caseId to "system-events-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set cases to listUtil's splitByLine("
		Manual: Get Front Window
		Manual: Get Front App Name
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to new()
	
	if caseIndex is 1 then
		logger's logObj("Front Window:", sut's getFrontWindow())
		
	else if caseIndex is 2 then
		logger's infof("Front App Name: {}", sut's getFrontAppName())
		
	end if
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script SysEveInstance
		on getFrontWindow()
			tell application "System Events"
				try
					set frontApp to first application process whose frontmost is true
					set frontAppName to name of frontApp
					
					tell process frontAppName
						return 1st window whose value of attribute "AXMain" is true
					end tell
				end try
			end tell
			
			missing value
		end getFrontWindow
		
		on getFrontAppName()
			set frontAppName to missing value
			tell application "System Events"
				try
					set frontApp to first application process whose frontmost is true
					set frontAppName to name of frontApp
				end try
			end tell
			
			frontAppName
		end getFrontAppName
	end script

	std's applyMappedOverride(result)	
end new


-- Private Codes below =======================================================

on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("system-events")
end init

-- EOS