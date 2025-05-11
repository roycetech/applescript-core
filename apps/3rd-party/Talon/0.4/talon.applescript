(*
	Wrapper for the Talon Voice Recognition app.

	NOTE: The word "speech" means listen in talon's domain.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Talon/0.4/talon

	@Created: Sat, Apr 05, 2025 at 12:24:07 PM
	@Last Modified: 2025-05-02 07:42:40
*)
use std : script "core/std"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Enable Speech
		Manual: Disable Speech
		Manual: Show Logs
		Manual: Show Console
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Running: {}", sut's isRunning())
	logger's infof("Listening: {}", sut's isListening())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's enableSpeech()

	else if caseIndex is 3 then
		sut's disableSpeech()

	else if caseIndex is 4 then
		sut's showLogs()

	else if caseIndex is 5 then
		sut's showConsole()
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script TalonInstance

		property appName : "Talon"

		on isRunning()
			if not std's appExists(appName) then return false
			running of application appName
		end isRunning

		(*
			No straight forward way to implement this. Let's use a dedicated terminal tab for this
		*)
		on isListening()
			if not isRunning() then return false

			tell application "System Events" to tell process appName
				try
					-- Assuming the first menu item contains the state.
					set menuItemMarker to value of attribute "AXMenuItemMarkChar" of menu item 1 of menu "Speech Recognition" of menu item "Speech Recognition" of menu "Talon" of menu bar item 1 of menu bar 2
					return menuItemMarker is not missing value

				end try
			end tell

			false
		end isListening


		(*
		*)
		on toggleSpeech()
			if not isRunning() then return false

			tell application "System Events" to tell process appName
				try
					-- Assuming the first menu item contains the state.
					(* NOTE: To insert the correct menu, run entire contents of a known menu element. *)
					click menu item 1 of menu 1 of menu item "Speech Recognition" of menu "Talon" of menu bar item 1 of menu bar 2
				end try
			end tell

		end toggleSpeech

		(*		*)
		on enableSpeech()
			if not isRunning() then return
			if isListening() then return

			toggleSpeech()
		end enableSpeech


		(*		*)
		on disableSpeech()
			if not isRunning() then return

			if not isListening() then return

			toggleSpeech()
		end disableSpeech


		on showLogs()
			if not isRunning() then return

			tell application "System Events" to tell process appName
				try
					click menu item "View Log" of menu "Scripting" of menu item "Scripting" of menu "Talon" of menu bar item 1 of menu bar 2
				end try
			end tell
		end showLogs


		on showConsole()
			if running of application "Talon" is false then return

			tell application "System Events" to tell process appName
				try
					click menu item "Console (REPL)" of menu "Scripting" of menu item "Scripting" of menu "Talon" of menu bar item 1 of menu bar 2
				end try
			end tell
		end showConsole


	end script
end new
