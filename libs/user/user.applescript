global std, cc, zoomApp

(* 
	This script is very user-specific. For example, it is assumed that a user 
	uses a particular set of versioned apps. Might be better to leave this out 
	of this framework but let's give it a try 

	@Usage:
		set usr to std's import("user")
		
	@Deployment:
		make compile-lib SOURCE=libs/user/user

	Note: we use usr to avoid clash with the built-in AppleScript identifier.
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
		Manual: Is Screen Sharing
		Manual: Get Meeting window
		Manual: Cue for Touch ID
		Manual: Done Audible Cue
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
		logger's infof("In Meeting: {}", sut's isInMeeting())
		
	else if caseIndex is 2 then
		logger's infof("In Meeting: {}", sut's isScreenSharing())
		
	else if caseIndex is 3 then
		logger's logObj("Meeting Window", sut's getMeetingWindow())
		
	else if caseIndex is 4 then
		sut's cueForTouchId()
		
	else if caseIndex is 5 then
		sut's done()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	script UserInstance
		on cueForTouchId()
			do shell script "afplay /System/Library/Sounds/Glass.aiff"
		end cueForTouchId
		
		on done()
			try
				do shell script "afplay /System/Library/Sounds/Submarine.aiff"
			end try
		end done
		
		
		on isInMeeting()
			return cc's isMicInUse()
		end isInMeeting
		
		
		on isScreenSharing()
			false
		end isScreenSharing
		
		
		(* Currently supports only zoom.us at the moment. *)
		on getMeetingWindow()
			missing value
		end getMeetingWindow
	end script
	std's applyMappedOverride(result)
end new




-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("user")
	set cc to std's import("control-center")
end init
