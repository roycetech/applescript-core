(*
	@Prerequisites:
		zoom.applescript installed.
		zoom.us application installed.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/zoom.us/5.x/dec-user-zoom

	Install:
		make build-lib SOURCE=libs/user/dec-user-zoom
		plutil -replace 'UserInstance' -string 'dec-user-zoom' ~/applescript-core/config-lib-factory.plist

	Uninstall:
		make remove-lib SOURCE=libs/user/dec-user-zoom
		plutil -remove 'UserInstance' ~/applescript-core/config-lib-factory.plist

	@Last Modified: 2023-11-09 20:01:01
*)
use std : script "core/std"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"
use usrLib : script "core/user"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	-- All spot check cases are manual.
	set cases to listUtil's splitByLine("
		Manual: Info (In meeting [yes, no], Screen Sharing [yes, no])
	")

	set spotLib to spotScript's new()
	set spot to spotLib's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()

	set sut to usrLib's new()
	set sut to decorate(sut)
	logger's infof("In Meeting: {}", sut's isInMeeting())
	logger's infof("Is Screen Sharing: {}", sut's isScreenSharing())

	spot's finish()
	logger's finish()
end spotCheck


(* *)
on decorate(baseScript)
	loggerFactory's inject(me)

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
				script "core/zoom"
				return true
			end try
			false
		end _isZoomInstalled
	end script
end decorate
