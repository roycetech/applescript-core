global std, usr, kb, process
global SHARING_WIN_NAME, SELECT_SHARE_WIN_NAME, SHARING_STATUSBAR_WIN_NAME

(*
	This decorator provides zoom action handlers.
	
	@Related:
		zoom.applescript

*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "zoom-actions-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Unmute
		Manual Mute
		Manual: Start Video
		Manual: Stop Video
		Manual: Raise Hand
		
		Manual: Lower Hand
		Manual: Start Screen Sharing
		Manual: Stop Screen Sharing
		Manual: End Meeting
		Manual: Cycle Camera
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
		sut's unmute
	on error
		set sut to decorate(sut)
	end try
	
	if caseIndex is 1 then
		sut's unmute()
		
	else if caseIndex is 2 then
		sut's mute()
		
	else if caseIndex is 3 then
		sut's cameraOn()
		
	else if caseIndex is 4 then
		sut's cameraOff()
		
	else if caseIndex is 5 then
		sut's raiseHand()
		
	else if caseIndex is 6 then
		sut's lowerHand()
		
	else if caseIndex is 7 then
		sut's startSharing()
		
	else if caseIndex is 8 then
		sut's stopSharing()
		
	else if caseIndex is 9 then
		sut's endMeeting()
		
	else if caseIndex is 10 then
		sut's cycleCamera()
		
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
	(* Use the same name as the parent because this decorator is only meant to organize the handlers. *)
	script ZoomInstance
		property parent : mainScript
		property currentCamera : missing value
		
		(**)
		on cycleCamera(listOfCamera)
			# TODO		
		end cycleCamera
		
		
		on mute()
			_clickMenuAction("Mute Audio")
		end mute
		
		
		on unmute()
			_clickMenuAction("Unmute Audio")
		end unmute
		
		
		on cameraOn()
			_clickMainButton("Start Video")
		end cameraOn
		
		
		on cameraOff()
			_clickMainButton("Stop Video")
		end cameraOff
		
		
		on setMicToSystem()
			_clickAudioSubMenu("MacBook Pro Microphone (MacBook Pro Microphone)")
		end setMicToSystem
		
		
		on setAudioToSystem()
			_clickAudioSubMenu("MacBook Pro Speakers (MacBook Pro Speakers)")
		end setAudioToSystem
		
		
		on raiseHand()
			if running of application "zoom.us" is false then return false
			
			activate application "zoom.us"
			delay 0.1
			tell application "System Events" to tell process "zoom.us"
				if name of front window is "Reactions" then
					logger's warn("Your virtual hand may already be raised")
					
				else if name of front window is "Zoom Meeting" then
					kb's pressOptionKey("y")
				else
					logger's warn("Couldn't find the Zoom Meeting window")
				end if
			end tell
		end raiseHand
		
		on lowerHand()
			if running of application "zoom.us" is false then return false
			
			activate application "zoom.us"
			delay 0.1
			tell application "System Events" to tell process "zoom.us"
				if name of front window is "Reactions" then
					kb's pressOptionKey("y")
				else
					logger's warn("Your virtual hand is not currently raised")
				end if
			end tell
		end lowerHand
		
		
		(* Too slow when in a big meeting. *)
		on startSharing given audio:theAudio as boolean
			if not running of application "zoom.us" then return
			
			set soundRequested to false
			try
				theAudio
				set soundRequested to theAudio
			end try
			
			tell application "System Events" to tell process "zoom.us"
				if exists (window SHARING_WIN_NAME) then
					logger's debug("Already sharing...")
					
					set sharingSound to (count of (images of window "zoom share statusbar window" whose help starts with "You are sharing sound")) is not 0
					set synched to sharingSound is equal to soundRequested
					logger's debug("Synched: " & synched)
					if synched then return
					
					my stopSharing()
				end if
				
				tell window "Zoom Meeting"
					click (first button whose description is "Share Screen")
				end tell
				
				logger's debug("Waiting for the share screen system dialogue window...")
				repeat until window SELECT_SHARE_WIN_NAME exists
					delay 0.5
				end repeat
				
				set doTurnOn to soundRequested and value of checkbox 1 of window SELECT_SHARE_WIN_NAME is 0
				set doTurnOff to soundRequested is false and value of checkbox 1 of window SELECT_SHARE_WIN_NAME is 1
				
				if doTurnOff or doTurnOn then
					click (first checkbox of window SELECT_SHARE_WIN_NAME whose description is "Share sound")
				end if
				
				tell window SELECT_SHARE_WIN_NAME to click (first button whose description starts with "Share ")
			end tell
		end startSharing
		
		
		on stopSharing()
			if not running of application "zoom.us" then return
			
			if usr's isScreenSharing() is false then
				logger's warn("Screen sharing appears to be off already.")
				return
			end if
			
			logger's debug("Stopping shared...")
			tell application "System Events" to tell process "zoom.us" to tell window "zoom share statusbar window"
				ignoring application responses
					click (first button whose description is "Stop Share")
				end ignoring
			end tell
		end stopSharing
		
		
		on endMeeting()
			if not running of application "zoom.us" then return false
			
			tell application "System Events" to tell process "zoom.us"
				set meetingWindowAbsent to not (exists (window "Zoom Meeting"))
			end tell
			
			if meetingWindowAbsent then
				set zoomProcess to process's new("zoom.us")
				zoomProcess's terminate()
				return
			end if
			
			tell application "System Events" to tell process "zoom.us"
				click (first button of window "Zoom Meeting" whose role description is "close button")
				delay 0.1
				
				try
					click (first button of window "" whose description is "Leave Meeting")
				on error
					click (first button of window "" whose description is "End Meeting for All")
				end try
			end tell
		end endMeeting
		
		
		on _clickAudioSubMenu(buttonDescription)
			if running of application "zoom.us" is false then return
			
			tell application "System Events" to tell process "zoom.us"
				if not (window "Zoom Meeting" exists) then return
				
				click (first button of window "Zoom Meeting" whose description is "Audio sub menu")
				delay 0.1
				try
					click (first button of window "" whose description is buttonDescription)
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end _clickAudioSubMenu
		
		
		on _clickMenuAction(menuItemName)
			tell application "System Events" to tell process "zoom.us"
				try
					click menu item menuItemName of menu 1 of menu bar item "Meeting" of menu bar 1
				end try
			end tell
		end _clickMenuAction
		
		
		(*
			Will fail when the controls are not visible. We'll use menus instead for better predictability.
		*)
		on _clickMainButton(buttonStartName)
			if running of application "zoom.us" is false then return
			
			tell application "System Events" to tell process "zoom.us" to tell my _getMeetingWindow()
				try
					click (first button whose description starts with buttonStartName)
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
				end try
			end tell
		end _clickMainButton
	end script
end decorate


-- Private Codes below =======================================================


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set usr to std's import("user")'s new()
	
	set logger to std's import("logger")'s new("zoom-actions")
	set kb to std's import("keyboard")'s new()
	set process to std's import("process")
	
	set SHARING_WIN_NAME to "zoom share toolbar window"
	set SELECT_SHARE_WIN_NAME to "Select a window or an application that you want to share"
	set SHARING_STATUSBAR_WIN_NAME to "zoom share statusbar window"
end init
