(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-advanced'

	@Created: Tuesday, December 31, 2024 at 11:55:42 AM
	@Last Modified: Tuesday, December 31, 2024 at 11:55:42 AM
	@Change Logs:
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
		Main
		Manual: Trigger Edit
		Manual: Set Filename
		Manual: Click button OK
		Manual: Set Ask for name after every capture On
		
		Manual: Set Ask for name after every capture Off
		Manual: Set Add 2x suffix to Retina screenshots On		
		Manual: Set Add 2x suffix to Retina screenshots Off
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/cleanshot-x"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	sut's showSettings()
	
	logger's infof("Ask for name for every capture: {}", sut's getAskForNameForEveryCapture())
	logger's infof("Add @2xSuffix to retina screenshots: {}", sut's get2xSuffixToRetinaScreenshots())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerEditFilename()
		
	else if caseIndex is 3 then
		set sutFilename to "%m,%d,-,%H,%M,-ScreenShot"
		sut's setFilename(sutFilename)
		
	else if caseIndex is 4 then
		sut's triggerEditFilenameButtonOk()
		
	else if caseIndex is 5 then
		sut's setAskForNameForEveryCaptureOn()
		
	else if caseIndex is 6 then
		sut's setAskForNameForEveryCaptureOff()
		
	else if caseIndex is 7 then
		sut's set2xSuffixToRetinaScreenshotsOn()
		
	else if caseIndex is 8 then
		sut's set2xSuffixToRetinaScreenshotsOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script CleanshotXAdvancedDecorator
		property parent : mainScript
		
		on triggerEditFilename()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return
				
				click button "Edit" of window "Advanced"
			end tell
		end triggerEditFilename
		
		
		on setFilename(newFilename)
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return
				
				set value of text field 1 of sheet 1 of window "Advanced" to newFilename
			end tell
		end setFilename
		
		
		on triggerEditFilenameButtonOk()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return
				
				-- set frontmost to true
				try
					click button "OK" of sheet 1 of window "Advanced"
				end try
			end tell
		end triggerEditFilenameButtonOk
		
		
		on getAskForNameForEveryCapture()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return false
				
				try
					return (value of checkbox "Ask for name after every capture" of window "Advanced") is 1
				end try
			end tell
			
			false
		end getAskForNameForEveryCapture
		
		on toggleAskForNameForEveryCapture()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return false
				
				try
					click checkbox "Ask for name after every capture" of window "Advanced"
				end try
			end tell
			
			false
		end toggleAskForNameForEveryCapture
		
		on setAskForNameForEveryCaptureOn()
			if not getAskForNameForEveryCapture() then toggleAskForNameForEveryCapture()
		end setAskForNameForEveryCaptureOn
		
		on setAskForNameForEveryCaptureOff()
			if getAskForNameForEveryCapture() then toggleAskForNameForEveryCapture()
		end setAskForNameForEveryCaptureOff
		
		
		on get2xSuffixToRetinaScreenshots()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return false
				
				try
					return (value of first checkbox of window "Advanced" whose name ends with "suffix to Retina screenshots") is 1
				end try
			end tell
			
			false
		end get2xSuffixToRetinaScreenshots
		
		
		on toggle2xSuffixToRetinaScreenshots()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Advanced")) then return false
				
				try
					click (first checkbox of window "Advanced" whose name ends with "suffix to Retina screenshots")
				end try
			end tell
			
			false
		end toggle2xSuffixToRetinaScreenshots
		
		on set2xSuffixToRetinaScreenshotsOn()
			if not get2xSuffixToRetinaScreenshots() then toggle2xSuffixToRetinaScreenshots()
		end set2xSuffixToRetinaScreenshotsOn
		
		on set2xSuffixToRetinaScreenshotsOff()
			if get2xSuffixToRetinaScreenshots() then toggle2xSuffixToRetinaScreenshots()
		end set2xSuffixToRetinaScreenshotsOff
		
	end script
end decorate
