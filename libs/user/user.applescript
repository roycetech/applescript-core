(*
	This script is very user-specific. For example, it is assumed that a user
	uses a particular set of versioned apps. Might be better to leave this out
	of this framework but let's give it a try

	@Usage:
		use userLib : script "core/user"

		property usr : userLib's new()

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh libs/user/user

	@Change Logs:
		Sun, Mar 09, 2025 at 09:00:59 AM - Added #getBrowserAppNames

	@Troubleshooting:
		Zoom is not yet tested at this time. June 25, 2023 5:22 PM. Test that library set before adding it to the config-lib-factory.

	Note: we use usr to avoid clash with the built-in AppleScript identifier.
*)

use scripting additions

use script "core/Text Utilities"

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

use ccLib : script "core/control-center"
use lovLib : script "core/lov"
use textUtil : script "core/string"

use decoratorLib : script "core/decorator"

property logger : missing value
property cc : missing value
property lov : missing value

property LOV_KEY : "[app-core] Deployment Type"
property PATH_DEPLOYMENT : "/Library/Script Libraries/core"
property PATH_SOUNDS : "/System/Library/Sounds"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Manual: Get Meeting window
		Manual: Cue for Touch ID
		Manual: Done Audible Cue
		Manual: Sound: Funk - Successful build
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if


	set sut to new()
	set decoratorLib to script "core/decorator"
	set decorator to decoratorLib's new(sut)
	decorator's printHierarchy()

	logger's infof("WiFi SID: {}", sut's getWifiSID())
	logger's infof("In Meeting: {}", sut's isInMeeting())
	logger's infof("Is Screen Sharing: {}", sut's isScreenSharing())
	logger's infof("Is Online?: {}", sut's isOnline())
	logger's infof("Major OS Version?: {}", sut's getOsMajorVersion())
	-- 	logger's infof("Integration: Sound output device: {}", sut's getAudioOutputDevice()) -- Decorated from another project, dec-user-sound-device.
	logger's infof("Deployment Type: {}", sut's getDeploymentType())
	logger's infof("Using default mic: {}", sut's isUsingDefaultSystemMicrophone())

	set browserAppNames to sut's getBrowserAppNames()
	repeat with nextBrowserAppName in browserAppNames
		logger's infof("Next browser: {}", nextBrowserAppName)
	end repeat

	if caseIndex is 1 then
		logger's logObj("Meeting Window", sut's getMeetingWindow())

	else if caseIndex is 2 then
		sut's cueForTouchId()

	else if caseIndex is 3 then
		sut's done()

	else if caseIndex is 4 then
		sut's afplay("funk.aiff")

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's injectBasic(me)
	set cc to ccLib's new()
	set lov to lovLib's new(LOV_KEY)

	script UserInstance
		(*
			Note: New browser app name must be manually added here in the future.
		*)
		on getBrowserAppNames()
			set browserList to do shell script "ls /Applications | grep -E '^(Google Chrome|Firefox|Safari|Microsoft Edge|Brave|Opera|Vivaldi)'"
			textUtil's replace(browserList, ".app", "")
			paragraphs of result
		end getBrowserAppNames


		on getWifiSID()
			if getOsMajorVersion() is greater than or equal to 15 then
				do shell script "ipconfig getsummary $(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}') | awk -F ' SSID : ' '/ SSID : / {print $2}'"
			else
				do shell script "networksetup -getairportnetwork en0 | awk -F\": \" '{ print $2 }'"
			end if
		end getWifiSID

		(*
			@returns "computer" or "user"
		*)
		on getDeploymentType()
			if lov's getSavedValue() is equal to "computer" then
				return "computer"
			end if

			"user"
		end getDeploymentType


		on getDeploymentPath()
			if isLocalDeployment() then return PATH_DEPLOYMENT

			getUserDeploymentPath()
		end getDeploymentPath


		on isUserDeployment()
			not isLocalDeployment()
		end isUserDeployment


		(*
			A bit confusing because "local" is normally associated to a smaller
			scope but in this case, local domain refers to the shared space in
			the computer.
		*)
		on isLocalDeployment()
			getDeploymentType() is equal to "computer"
		end isLocalDeployment


		on getUserDeploymentPath()
			"/Users/" & std's getUsername() & PATH_DEPLOYMENT
		end getUserDeploymentPath


		on cueForTouchId()
			afplay("Glass.aiff")
		end cueForTouchId

		on done()
			afplay("Submarine.aiff")
		end done


		on cueDone()
			afplay("Submarine.aiff")
		end cueDone


		(*
			Use funk.aiff for soft success like successful build.
			Use bottle.aiff for soft failure like build fail, unable to open file
		*)
		on afplay(filename)
			try
				do shell script "afplay " & PATH_SOUNDS & "/" & filename
			end try
		end afplay


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
				do shell script "ping -c 1 8.8.8.8"
				return true
			end try
			false
		end isOnline

		on getOsMajorVersion()
			set sysinfo to system info
			return (do shell script "echo '" & system version of sysinfo & "' | cut -d '.' -f 1") as integer
		end getOsMajorVersion
	end script

	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
