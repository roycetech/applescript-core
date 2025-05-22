(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-shortcuts'

	@Created: Tuesday, December 31, 2024 at 9:32:26 AM
	@Last Modified: Tuesday, December 31, 2024 at 9:32:26 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use cliclickLib : script "core/cliclick"

property logger : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Rebind OCR Hotkey
		Manual: Rebind Screenshot: Capture Window Hotkey
		Manual: Rebind Screenshot: Capture Area Hotkey
		Manual: Rebind Screen Recording: Toggle Hotkey
		
		Manual: Rebind Screenshot: Capture Fullscreen Hotkey
		Manual: Clear General: All-In-One
	")
	
	set spotScript to script "core/spot-test"
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
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's rebindOcrCaptureText()
		
	else if caseIndex is 3 then
		sut's rebindScreenshotsCaptureWindow()
		
	else if caseIndex is 4 then
		sut's rebindScreenshotsCaptureArea()
		
	else if caseIndex is 5 then
		sut's rebindScreenRecordingToggleRecording()
		
	else if caseIndex is 6 then
		sut's rebindScreenshotsCaptureFullscreen()
		
	else if caseIndex is 7 then
		sut's clearGeneralAllInOne()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	
	script CleanshotXDecorator
		property parent : mainScript
		
		
		on clearGeneralAllInOne()
			tell application "System Events" to tell process "CleanShot X"
				click button 1 of UI element 2 of row 2 of table 1 of scroll area 1 of front window
				set frontmost to true
				delay 0.1
				button "   Type shortcut…" of UI element 2 of row 2 of table 1 of scroll area 1 of window 1
				lclick of cliclick at result given relativex:90
			end tell
		end clearGeneralAllInOne 
		
		
		on rebindOcrCaptureText()
			tell application "System Events" to tell process "CleanShot X"
				click button 1 of UI element 2 of row 29 of table 1 of scroll area 1 of front window
				set frontmost to true
				delay 0.1
			end tell
		end rebindOcrCaptureText
		
		
		on rebindScreenshotsCaptureWindow()
			tell application "System Events" to tell process "CleanShot X"
				click button 1 of UI element 2 of row 10 of table 1 of scroll area 1 of front window
				set frontmost to true
				delay 0.1
			end tell
		end rebindScreenshotsCaptureWindow
		
		
		on rebindScreenshotsCaptureArea()
			tell application "System Events" to tell process "CleanShot X"
				click button 1 of UI element 2 of row 7 of table 1 of scroll area 1 of front window
				set frontmost to true
				delay 0.1
			end tell
		end rebindScreenshotsCaptureArea
		
		
		on rebindScreenshotsCaptureFullscreen()
			tell application "System Events" to tell process "CleanShot X"
				click button 1 of UI element 2 of row 9 of table 1 of scroll area 1 of front window
				set frontmost to true
				delay 0.1
			end tell
		end rebindScreenshotsCaptureFullscreen
		
		
		on rebindScreenRecordingToggleRecording()
			tell application "System Events" to tell process "CleanShot X"
				click button 1 of UI element 2 of row 18 of table 1 of scroll area 1 of front window
				set frontmost to true
				delay 0.1
			end tell
		end rebindScreenRecordingToggleRecording
	end script
end decorate
