global std, retry, regex, kb
global zoomParticipants, zoomWindow, zoomActions
global configZoom, configBusiness

(*
	@This script contains the most basic wrapper functions for the current zoom app. Mostly starting a meeting and login-related functions only for the sake of simplicity.

	@Related:
		zoom-actions.applescript - contains mic, video, hand raise, end meeting, sound source controls
		zoom-participants - participant-related functions.

	@Testing:
		@Plists
			config-user.plist
				Zoom User Meeting ID - Personal -> 
				Work Key (e.g. apple)
				Work Email
				
	@Known Issues:
		Sign in Dialog always appear with a meeting window regardless if already authonticated. So we try to sign in again because closing the window stops the meeting.
*)

use script "Core Text Utilities"
use scripting additions

(*
	Usage:
		-- join given id:"12345678"
		join given id:125678, domain:"apple" username:"john.appleseed.com" password:4321
	
	PREREQUISITES:
		[/] Automatically join audio by computer when joining a meeting.

	Must configure zoom to be muted on join, this button is used as indicator
		for some tasks that the meeting window is ready, one of which task is
		to arrange the windows. (NOT NEEDED)
		
	@Testing:
		@Plists:
			config-business
				Zoom User Meeting ID
*)

property initialized : false
property logger : missing value

if the name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "zoom-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Start Personal Meeting - End to End
		Decorated: End Meeting - Prefer to leave meeting vs end the meeting
		
		Login
		Is waiting for sign in		
		Show Participants
				
		Join Current Meeting
		Reset Windows
		Is Sharing
		Raise Hand
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
		set useSSO of sut to true
		set meetingID to configZoom's getValue("User Meeting ID")
		set username to configZoom's getValue("Username")
		logger's infof("meetingID: {}", meetingID)
		logger's infof("username: {}", username)
		join of sut given id:meetingID, username:username, domain:configBusiness's getValue("Domain Key")
		
	else if caseIndex is 2 then
		sut's endMeeting()
		
	else if caseIndex is 2 then
		sut's login()
		
	else if caseIndex is 3 then
		log isWaitingForSignIn()
		
	else if caseIndex is 4 then
		
	else if caseIndex is 5 then
		showParticipants()
		log isParticipantSidebarVisible()
		
	else if caseIndex is 6 then
		hideParticipants()
		log isParticipantSidebarVisible()
		
	else if caseIndex is 7 then
		log getParticipants()
		
	else if caseIndex is 12 then
		resetWindows()
		
	else if caseIndex is 13 then
		log isSharing()
		
		
		
	else if caseIndex is 15 then
		raiseHand()
		
	end if
	
	logger's finish()
	spot's finish()
end spotCheck


on new()
	script ZoomInstance
		property useSSO : false
		
		(* Optional password. *)
		on join given id:meetingID, domain:domain, username:username, password:password : missing value, passcode:passcode : missing value
			
			set zoomUrlScheme to format {"zoommtg://{}.zoom.us/join?confno={}&zc=0&uname={}&stype=100", {domain, meetingID, username}}
			open location zoomUrlScheme
			
			set nextStep to waitForNextStepAfterJoining()
			logger's debugf("nextStep: {}", nextStep)
			
			if nextStep is "login" then
				logger's info("Logging in...")
				if useSSO then
					logger's info("Using SSO to login...")
					_loginViaSSO()
				else
					_loginViaPassword()
				end if
				
			else if nextStep is "passcode" then
				tell application "System Events" to tell process "zoom.us"
					set value of text field 1 of group 1 of window "" to passcode
					click (first button of window "" whose description is "Join")
				end tell
			end if
			
			doWaitForMeetingInProgress()
		end join
		
		
		on _loginViaSSO()
			set signInDialog to missing value
			tell application "System Events" to tell process "zoom.us"
				try
					set signInDialog to first window whose subrole is "AXDialog"
				end try
				if signInDialog is not missing value then
					click UI element "sign in" of text area 1 of scroll area 1 of signInDialog
				end if
			end tell
			
			script SSOWaiter
				tell application "System Events" to tell process "zoom.us"
					exists (first button of group 1 of window "Login" whose description is "Sign In with SSO")
				end tell
			end script
			set waitResult to exec of retry on result for 3
			logger's debugf("waitResult: {}", waitResult)
			if waitResult is missing value then
				logger's warn("Failed to detect the Sign In with SSO on time")
				return
			end if
			
			tell application "System Events" to tell process "zoom.us"
				try
					click (first button of group 1 of window "Login" whose description is "Sign In with SSO")
				end try
			end tell
		end _loginViaSSO
		
		
		on _loginViaPassword()
			error "Login via password is not implemented, it was but it needs redesign. Set useSSO flag to true"
		end _loginViaPassword
		
		
		on isWaitingForSignIn()
			tell application "System Events"
				try
					return exists (UI element "sign in" of text area 1 of scroll area 1 of front window of application process "zoom.us")
				end try
			end tell
			false
		end isWaitingForSignIn
		
		
		on doClickJoin()
			tell application "System Events" to tell process "zoom.us"
				tell window "Zoom" to click (first button whose description is "Join Meeting")
			end tell
			
			logger's debug("Waiting indefinitely for the 'Join' button...")
			script JoinWaiter
				tell application "System Events" to tell process "zoom.us"
					if exists (first button of window "" whose description is "Join") then return true
				end tell
			end script
			exec of retry on result
			logger's debug("... join button found")
		end doClickJoin
		
		
		on doTypeInId(meetingID)
			tell application "System Events" to tell process "zoom.us"
				set value of text field 1 of window "" to meetingID
				kb's pressKey("tab")
			end tell
		end doTypeInId
		
		
		(* Click 'Join' *)
		on doSubmitJoinMeeting()
			tell application "System Events" to tell process "zoom.us" to tell window ""
				click (first button whose description is "Join")
			end tell
		end doSubmitJoinMeeting
		
		
		(* Used to detect that meeting has loaded and is in progress*)
		on doWaitForMeetingInProgress()
			script UnmuteWaiter
				tell application "System Events" to tell process "zoom.us"
					if exists (first button of window "Zoom Meeting" whose description starts with "Unmute") then return true
					if exists (first button of window "Zoom Meeting" whose description starts with "Mute") then return true
					
				end tell
			end script
			exec of retry on UnmuteWaiter
		end doWaitForMeetingInProgress
		
		(*
			Determine if current window means any of the following:
				ready - if the Mute/Unmute button is present
				login - if sign in UI element is detected
				passcode - if the passcode UI element is detected

			@returns "login" or "passcode" or "ready"
		*)
		on waitForNextStepAfterJoining()
			script ReadyWaiter
				tell application "System Events" to tell process "zoom.us"
					try
						if exists (first button of window "Zoom Meeting" whose description starts with "Unmute") then return "ready"
						if exists (first button of window "Zoom Meeting" whose description starts with "Mute") then return "ready"
					end try
				end tell
				
				if isWaitingForSignIn() then return "login"
				
				tell application "System Events" to tell process "zoom.us"
					try
						if exists static text "Enter Meeting Passcode" of group 1 of window "" then return "passcode"
					end try
				end tell
			end script
			exec of retry on ReadyWaiter
		end waitForNextStepAfterJoining
		
		
		-- Private Codes below =======================================================
		
		
		(* @return the meeting window usually unless the user is sharing, than that window is returned. *)
		on _getMeetingWindow()
			set sharingWindowName to "zoom share toolbar window"
			tell application "System Events" to tell process "zoom.us"
				set isSharing to window sharingWindowName exists
				if isSharing then return window sharingWindowName
				
				window "Zoom Meeting"
			end tell
		end _getMeetingWindow
	end script
	
	zoomActions's decorate(result)
	zoomParticipants's decorate(result)
	zoomWindow's decorate(result)
	
	std's applyMappedOverride(result)
end new


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("zoom.us")
	set configBusiness to std's import("config")'s new("business")
	set plutil to std's import("plutil")'s new()
	set configZoom to plutil's new("zoom.us/config")
	
	set retry to std's import("retry")'s new()
	set regex to std's import("regex")
	set kb to std's import("keyboard")'s new()
	
	set zoomActions to std's import("zoom-actions")
	set zoomParticipants to std's import("zoom-participants")
	set zoomWindow to std's import("zoom-window")
end init