(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/VLC/3.0.x/vlc

	@Created: Tuesday, August 27, 2024 at 7:43:41 PM
	@Last Modified: 2024-08-28 10:49:39
*)

use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Play
		Manual: Pause
		Manual: Toggle Play
		Manual: Disable Subtitle

		Manual: Enable Subtitle at index 1
		Manual: Toggle Subtitle
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Is playing: {}", sut's isPlaying())
	logger's infof("Is subtitle enabled: {}", sut's isSubtitleEnabled())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's play()

	else if caseIndex is 3 then
		sut's pause()

	else if caseIndex is 4 then
		sut's togglePlay()

	else if caseIndex is 5 then
		sut's disableSubtitle()

	else if caseIndex is 6 then
		sut's enableSubtitleIndex(1)

	else if caseIndex is 7 then
		sut's toggleSubtitle()
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script VLCInstance
		on toggleSubtitle()
			if isSubtitleEnabled() then
				disableSubtitle()
			else
				enableSubtitleIndex(1)
			end if
		end toggleSubtitle


		on isSubtitleEnabled()
			if running of application "VLC" is false then return false

			tell application "System Events" to tell process "VLC"
				unic's MENU_CHECK is not equal to the value of attribute "AXMenuItemMarkChar" of menu item 1 of menu 1 of menu item "Subtitle Track" of menu 1 of menu bar item "Subtitles" of menu bar 1

			end tell
		end isSubtitleEnabled


		on enableSubtitleIndex(idx)
			if running of application "VLC" is false then return

			tell application "System Events" to tell process "VLC"
				try
					click menu item (idx + 1) of menu 1 of menu item "Subtitle Track" of menu 1 of menu bar item "Subtitles" of menu bar 1
				end try
			end tell
		end enableSubtitleIndex


		on disableSubtitle()
			if running of application "VLC" is false then return

			tell application "System Events" to tell process "VLC"
				try
					click menu item "Disable" of menu 1 of menu item "Subtitle Track" of menu 1 of menu bar item "Subtitles" of menu bar 1
				end try
			end tell
		end disableSubtitle


		on togglePlay()
			if running of application "VLC" is false then return

			if isPlaying() then
				pause()
			else
				play()

			end if
		end togglePlay


		on play()
			if running of application "VLC" is false then return

			tell application "System Events" to tell process "VLC"
				try
					click menu item "Play" of menu 1 of menu bar item "Playback" of menu bar 1
				end try
			end tell
		end play

		on pause()
			if running of application "VLC" is false then return

			tell application "System Events" to tell process "VLC"
				try
					click menu item "Pause" of menu 1 of menu bar item "Playback" of menu bar 1
				end try
			end tell
		end pause

		on isPlaying()
			if running of application "VLC" is false then return false

			tell application "System Events" to tell process "VLC"
				try
					return exists menu item "Pause" of menu 1 of menu bar item "Playback" of menu bar 1
				end try
			end tell

			false
		end isPlaying
	end script
end new
