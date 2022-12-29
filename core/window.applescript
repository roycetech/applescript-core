global std

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "window-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Has Window (Check absence, presence, and on another desktop)
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
		logger's infof("Has Window: {}", sut's hasWindow("Safari"))
		
	else if caseIndex is 2 then
	end if
	
	spot's finish()
	logger's finish()
end spot

on new()
	script WindowInstance
		
		on hasWindow(appName)
			hasAllWindows({appName})
		end hasWindow
		
		
		(* @appNames list of app names *)
		on hasAllWindows(appNames)
			set calcAppNames to appNames
			if class of appNames is text then set calcAppNames to {appNames}
			
			repeat with nextAppName in calcAppNames
				if running of application nextAppName is false then return false
				
				tell application "System Events" to tell process nextAppName
					if (count of windows) is 0 then return false
				end tell
			end repeat
			
			true
		end hasAllWindows
		
	end script
end new

on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("window")
end init