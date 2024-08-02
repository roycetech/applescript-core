(*
	@Purpose:
		Wrapper for the (Elgato) Camera Hub app.
		
	@Accessibility:
		Buttons does not have proper description that's why we need to trigger by index which is not great.
		There are three windows while the app is running.
			Dialog is for the text to read.
			Standard Window has the main controls.
	
	@Usage:
		
	
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Camera Hub/1.10.2/camera-hub'

	@Created: Friday, August 2, 2024 at 1:35:44 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Next
		Manual: Previous
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
		
	else if caseIndex is 2 then
		sut's clickNext()
		
	else if caseIndex is 3 then
		sut's clickPrevious()
		
	end if
	
	spot's finish()
	
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script CameraHubInstance
		
		on clickNext()
			if running of application "Elgato Camera Hub" is false then return
			
			tell application "System Events" to tell process "Camera Hub"
				-- of front window
				try
					click button 10 of group 1 of (first window whose description is "standard window")
				end try
			end tell
		end clickNext
		
		on clickPrevious()
			if running of application "Elgato Camera Hub" is false then return
			
			tell application "System Events" to tell process "Camera Hub"
				-- of front window
				try
					click button 8 of group 1 of (first window whose description is "standard window")
				end try
			end tell
		end clickPrevious
		
	end script
end new
