global std, cc, zoomApp

(* 
	This script is very user-specific. For example, it is assumed that a user 
	uses a particular set of versioned apps. Might be better to leave this out 
	of this framework but let's give it a try 
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "user-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: In Meeting
		Manual: In zoom.us meeting
		Manual: Is Screen Sharing
		Manual: Get Meeting window
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		logger's infof("In Meeting: {}", isInMeeting())
		
	else if caseIndex is 2 then
		log isInZoomMeeting()
		
	else if caseIndex is 3 then
		log isScreenSharing()
				
	else if caseIndex is 4 then
		log getMeetingWindow()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script UserInstance
		on isInMeeting()
			-- if running of application "Microsoft Teams" then return true
			
			-- assume, for now, that if mic is in use, that we are in a meeting.
			return cc's isMicInUse()
			
			isInZoomMeeting()
		end isInMeeting


		on isScreenSharing()
			if _isZoomInstalled() is false then return false
			
			zoomApp's isSharing()
		end isScreenSharing


		(* Currently supports only zoom.us at the moment. *)
		on getMeetingWindow()
			if _isZoomInstalled() then
				tell application "System Events" to tell process "zoom.us"
					return window "Zoom Meeting"
				end tell
			end if
			
			missing value
		end getMeetingWindow
	end
	std's applyMappedOverride(result)
end




-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("user")
	set cc to std's import("control-center")
end init
