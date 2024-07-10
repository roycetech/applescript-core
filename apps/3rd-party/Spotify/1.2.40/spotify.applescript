(*
	Library wrapper for the Spotify app.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Spotify/1.2.40/spotify

	@Created: Tuesday, July 2, 2024 at 10:06:42 AM
	@Last Modified: 2024-07-08 11:32:08
*)

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set sut to new()
	logger's infof("Is playing: {} ", sut's isPlaying())
	logger's infof("Is paused: {} ", sut's isPaused())

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Play
		Manual: Pause
		Manual: Play Track
		Manual: Play Next

		Manual: Play Previous
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's play()

	else if caseIndex is 3 then
		sut's pause()

	else if caseIndex is 4 then
		sut's playTrack("spotify:track:14rZjW3RioG7WesZhYESso")

	else if caseIndex is 5 then
		sut's nextTrack()

	else if caseIndex is 6 then
		sut's previousTrack()

	end if

	spot's finish()

	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script SpotifyInstance
		on nextTrack()
			if running of application "Spotify" is false then return false

			tell application "Spotify"
				next track
			end tell
		end nextTrack


		on previousTrack()
			if running of application "Spotify" is false then return false

			tell application "Spotify"
				previous track
			end tell
		end previousTrack


		on play()
			if running of application "Spotify" is false then return false

			tell application "Spotify"
				play
			end tell
		end play


		on pause()
			tell application "Spotify"
				pause
			end tell
		end pause


		on playTrack(trackUrl)
			if running of application "Spotify" is false then
				activate application "Spotify"
				delay 1
			end if

			tell application "Spotify"
				play track trackUrl
			end tell

		end playTrack


		on isPlaying()
			if running of application "Spotify" is false then return false

			tell application "Spotify"
				player state is playing
			end tell
		end isPlaying

		on isPaused()
			if running of application "Spotify" is false then return false

			tell application "Spotify"
				player state is paused
			end tell
		end isPaused
	end script
end new
