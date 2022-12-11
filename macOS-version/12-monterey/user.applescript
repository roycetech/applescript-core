global std, cc, zoomApp

(* 
	This script is very user-specific. For example, it is assumed that a user uses a particular set of versioned apps. 
	Might be better to leave this out of this framework but let's give it a try 
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
		Get Keyboard Layout
		Is DVORAK?
		
		Get Meeting window
	")
	
	set spotLib to std's import("spot")
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		log isInMeeting()
		
	else if caseIndex is 2 then
		log isInZoomMeeting()
		
	else if caseIndex is 3 then
		log isScreenSharing()
		
	else if caseIndex is 4 then
		log getKeyboardLayout()
		
	else if caseIndex is 5 then
		log isDvorak()
		
	else if caseIndex is 6 then
		log getMeetingWindow()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on isDvorak()
	getKeyboardLayout() contains "DVORAK"
end isDvorak

on getKeyboardLayout()
	do shell script "defaults read ~/Library/Preferences/com.apple.HIToolbox.plist \\
 AppleSelectedInputSources | \\
 egrep -w 'KeyboardLayout Name' | sed -E 's/^.+ = \"?([^\"]+)\"?;$/\\1/'"
end getKeyboardLayout

on isInMeeting()
	-- if running of application "Microsoft Teams" then return true
	
	-- assume, for now, that if mic is in use, that we are in a meeting.
	return cc's isMicInUse()
	
	isInZoomMeeting()
end isInMeeting


on isInZoomMeeting()
	if _isZoomInstalled() is false then return false
	if running of application "zoom.us" is false then return false
	
	tell application "System Events" to tell process "zoom.us"
		(exists window "Zoom Meeting") or (exists window "zoom share statusbar window") or (exists window "Zoom Webinar")
	end tell
end isInZoomMeeting


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


-- Private Codes below =======================================================

on _isZoomInstalled()
	if std's appExists("us.zoom.xos") is false then return false
	
	try
		set zoomApp to std's import("zoom")
		return true
	end try
	false
end _isZoomInstalled



(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("user")
	set cc to std's import("controlcenter")
end init
