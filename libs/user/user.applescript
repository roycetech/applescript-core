(*
	This script is very user-specific. For example, it is assumed that a user
	uses a particular set of versioned apps. Might be better to leave this out
	of this framework but let's give it a try

	@Usage:
		use userLib : script "user"

		property usr : userLib's new()

	@Build:
		make compile-lib SOURCE=libs/user/user

	@Troubleshooting:
		Zoom is not yet tested at this time. June 25, 2023 5:22 PM. Test that library set before adding it to the config-lib-factory.

	Note: we use usr to avoid clash with the built-in AppleScript identifier.
*)

use scripting additions

use std : script "std"
use listUtil : script "list"

use loggerFactory : script "logger-factory"
use ccLib : script "control-center"
use overriderLib : script "overrider"

use spotScript : script "spot-test"

property logger : missing value
property cc : missing value

property overrider : overriderLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Info
		Manual: Get Meeting window
		Manual: Cue for Touch ID
		Manual: Done Audible Cue
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if


	set sut to new()
	if caseIndex is 1 then
		logger's infof("In Meeting: {}", sut's isInMeeting())
		logger's infof("Is Screen Sharing: {}", sut's isScreenSharing())
		logger's infof("Is Online?: {}", sut's isOnline())
		logger's infof("Major OS Version?: {}", sut's getOsMajorVersion())

	else if caseIndex is 2 then

		logger's logObj("Meeting Window", sut's getMeetingWindow())

	else if caseIndex is 3 then
		sut's cueForTouchId()

	else if caseIndex is 4 then
		sdone()

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	set cc to ccLib's new()

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


		on isOnline()
			try
				set pingResult to do shell script "/usr/local/bin/gtimeout 1s bash -c 'ping -c 1 apple.com'"
				return pingResult contains "0.0% packet loss"
			end try
			false
		end isOnline

		on getOsMajorVersion()
			set sysinfo to system info
			return (do shell script "echo '" & system version of sysinfo & "' | cut -d '.' -f 1") as integer
		end getOsMajorVersion
	end script
	overrider's applyMappedOverride(result)
end new


