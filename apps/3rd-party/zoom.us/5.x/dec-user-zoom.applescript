(* 
	Prerequisites:
		zoom.applescript installed.
		zoom.us application installed.

	Install:
		make compile-lib SOURCE=libs/user/dec-user-zoom
		plutil -replace 'UserInstance' -string 'dec-user-zoom' ~/applescript-core/config-lib-factory.plist

	Uninstall:
		make remove-lib SOURCE=libs/user/dec-user-zoom
		plutil -remove 'UserInstance' ~/applescript-core/config-lib-factory.plist
*)
use std : script "std"
use listUtil : script "list"

use loggerLib : script "logger"
use usrLib : script "user"

use spotScript : script "spot-test"

property logger : loggerLib's new("dec-user-zoom")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()


on spotCheck()
	set caseId to "dec-user-zoom-spotCheck"
	logger's start()
	
	-- All spot check cases are manual.
	set cases to listUtil's splitByLine("
		Manual: Is in meeting (yes, no)
		Manual: Is screen sharing (yes, no)
	")
	
	set spotLib to spotScript's new()
	set spot to spotLib's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to usrLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		logger's infof("In Meeting: {}", sut's isInMeeting())
		
	else if caseIndex is 2 then
		logger's infof("Is Screen Sharing: {}", sut's isScreenSharing())
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(* *)
on decorate(baseScript)
	script UserZoomInstance
		property parent : baseScript
		
		on isInMeeting()
			if _isZoomInstalled() is false then
				continue isInMeeting()
				return
			end if
			
			if running of application "zoom.us" is false then return false
			
			tell application "System Events" to tell process "zoom.us"
				(exists window "Zoom Meeting") or (exists window "zoom share statusbar window") or (exists window "Zoom Webinar")
			end tell
		end isInMeeting
		
		on isScreenSharing()
			if running of application "zoom.us" is false then return continue isScreenSharing()
			
			try
				tell application "System Events" to tell process "zoom.us"
					return exists window "zoom share statusbar window"
				end tell
			end try
			
			false
		end isScreenSharing
		
		
		on _isZoomInstalled()
			if std's appExists("zoom.us") is false then return false
			
			try
				script "zoom"
				return true
			end try
			false
		end _isZoomInstalled
	end script
end decorate
