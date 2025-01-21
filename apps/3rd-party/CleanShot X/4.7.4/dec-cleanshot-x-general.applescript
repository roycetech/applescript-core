(*
	Handlers for manipulating General settings.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-general'

	@Created: Tuesday, December 31, 2024 at 7:26:18 AM
	@Last Modified: Tuesday, December 31, 2024 at 7:26:18 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use finderMiniLib : script "core/finder-mini"

property logger : missing value
property retry : missing value
property finderMini : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Set Start at Login On
		Manual: Set Start at Login Off

		Manual: Set Export Location
		Manual: Set Hide Desktop icons On
		Manual: Set Hide Desktop icons Off
		Manual: Set Show Quick Access Overlay - Screenshot On
		Manual: Set Show Quick Access Overlay - Screenshot Off

		Manual: Set Show Quick Access Overlay - Recording On
		Manual: Set Show Quick Access Overlay - Recording Off
		Manual: Set Copy file to clipboard - Screenshot On
		Manual: Set Copy file to clipboard - Screenshot Off
		Manual: Set Copy file to clipboard - Recording On

		Manual: Set Copy file to clipboard - Recording Off
		Manual: Set Save - Screenshot On
		Manual: Set Save - Screenshot Off
		Manual: Set Save - Recording On
		Manual: Set Save - Recording Off
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
	
	logger's infof("Starts at Login: {}", sut's getStartsAtLoginOn())
	logger's infof("Export location: {}", sut's getExportLocation())
	logger's infof("Hide while capturing: {}", sut's getHideWhileCapturingOn())
	
	logger's infof("Show Quick Access Overlay-Screenshot: {}", sut's isShowQuickAccessOverlayScreenshot())
	logger's infof("Show Quick Access Overlay-Recording: {}", sut's isShowQuickAccessOverlayRecording())
	
	logger's infof("Copy file to clipboard-Screenshot: {}", sut's isCopyFileToClipboardScreenshot())
	logger's infof("Copy file to clipboard-Recording: {}", sut's isCopyFileToClipboardRecording())
	
	logger's infof("Save-Screenshot: {}", sut's isSaveScreenshot())
	logger's infof("Save-Recording: {}", sut's isSaveRecording())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setStartsAtLoginOn()
		
	else if caseIndex is 3 then
		sut's setStartsAtLoginOff()
		
	else if caseIndex is 4 then
		sut's setExportLocation("~/Desktop")
		
	else if caseIndex is 5 then
		sut's setHideWhileCapturingOn()
		
	else if caseIndex is 6 then
		sut's setHideWhileCapturingOff()
		
	else if caseIndex is 7 then
		sut's setShowQuickAccessOverlayScreenshotOn()
		
	else if caseIndex is 8 then
		sut's setShowQuickAccessOverlayScreenshotOff()
		
	else if caseIndex is 9 then
		sut's setShowQuickAccessOverlayRecordingOn()
		
	else if caseIndex is 10 then
		sut's setShowQuickAccessOverlayRecordingOff()
		
	else if caseIndex is 11 then
		sut's setCopyFileToClipboardScreenshotOn()
		
	else if caseIndex is 12 then
		sut's setCopyFileToClipboardScreenshotOff()
		
	else if caseIndex is 13 then
		sut's setCopyFileToClipboardRecordingOn()
		
	else if caseIndex is 14 then
		sut's setCopyFileToClipboardRecordingOff()
		
	else if caseIndex is 15 then
		sut's setSaveScreenshotOn()
		
	else if caseIndex is 16 then
		sut's setSaveScreenshotOff()
		
	else if caseIndex is 17 then
		sut's setSaveRecordingOn()
		
	else if caseIndex is 18 then
		sut's setSaveRecordingOff()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set retry to retryLib's new()
	set finderMini to finderMiniLib's new("CleanShot X")
	
	script CleanshotXGeneralDecorator
		property parent : mainScript
		
		on getStartsAtLoginOn()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				
				try
					return value of checkbox "Start at login" of front window is 1
				end try
			end tell
			
			false
		end getStartsAtLoginOn
		
		
		on toggleStartsAtLogin()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				
				click checkbox "Start at login" of front window
			end tell
		end toggleStartsAtLogin
		
		on setStartsAtLoginOn()
			if getStartsAtLoginOn() then return
			
			toggleStartsAtLogin()
		end setStartsAtLoginOn
		
		on setStartsAtLoginOff()
			if not getStartsAtLoginOn() then return
			
			toggleStartsAtLogin()
		end setStartsAtLoginOff
		
		
		on getHideWhileCapturingOn()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				
				try
					return value of checkbox "Hide while capturing" of front window is 1
				end try
			end tell
			
			false
		end getHideWhileCapturingOn
		
		
		on toggleHideWhileCapturing()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				
				try
					click checkbox "Hide while capturing" of front window
				end try
			end tell
		end toggleHideWhileCapturing
		
		
		on setHideWhileCapturingOn()
			if not getHideWhileCapturingOn() then toggleHideWhileCapturing()
		end setHideWhileCapturingOn
		
		
		on setHideWhileCapturingOff()
			if getHideWhileCapturingOn() then toggleHideWhileCapturing()
		end setHideWhileCapturingOff
		
		
		on getExportLocation()
			if running of application "CleanShot X" is false then return missing value
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return get value of pop up button 1 of front window
				end try
			end tell
			
			missing value
		end getExportLocation
		
		
		on setExportLocation(newPath)
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				
				set frontmost to true
				set newPosixPath to finderMini's untilde(newPath)
				if newPosixPath is equal to my getExportLocation() then 
					logger's info("New export location is the same, exiting")
				return
				end if
				
				try
					click pop up button 1 of front window
					delay 0.1
					click (first menu item of menu 1 of pop up button 1 of front window whose title starts with "Other")
				end try
			end tell
			
			script WindowOpenWaiter
				tell application "System Events" to tell process "CleanShot X"
					if exists (window "Open") then return true
				end tell
			end script
			set windowOpenExists to exec of retry on result for 3
			if windowOpenExists is missing value then
				logger's warn("Window Open was not found...")
				return
			end if
			
			finderMini's triggerGoToFolder()
			finderMini's enterPath("~/Delete Daily") -- Must of course exists, untested if not.
			finderMini's acceptFoundPath()
			
			tell application "System Events" to tell process "CleanShot X"
				click button "Choose" of window "Open"
			end tell
		end setExportLocation
		
		
		(* After capture handlers =Start =============================================================*)
		on isShowQuickAccessOverlayScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return (value of checkbox 1 of UI element 1 of row 1 of table 1 of scroll area 1 of front window) is 1
				end try
			end tell
			
			false
		end isShowQuickAccessOverlayScreenshot
		
		
		on toggleShowQuickAccessOverlayScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return
				
				click checkbox 1 of UI element 1 of row 1 of table 1 of scroll area 1 of front window
			end tell
		end toggleShowQuickAccessOverlayScreenshot
		
		
		on setShowQuickAccessOverlayScreenshotOn()
			if not isShowQuickAccessOverlayScreenshot() then toggleShowQuickAccessOverlayScreenshot()
		end setShowQuickAccessOverlayScreenshotOn
		
		
		on setShowQuickAccessOverlayScreenshotOff()
			if isShowQuickAccessOverlayScreenshot() then toggleShowQuickAccessOverlayScreenshot()
		end setShowQuickAccessOverlayScreenshotOff
		
		
		on isShowQuickAccessOverlayRecording()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return (value of checkbox 1 of UI element 2 of row 1 of table 1 of scroll area 1 of front window) is 1
				end try
			end tell
			
			false
		end isShowQuickAccessOverlayRecording
		
		
		on toggleShowQuickAccessOverlayRecording()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return
				
				click checkbox 1 of UI element 2 of row 1 of table 1 of scroll area 1 of front window
			end tell
		end toggleShowQuickAccessOverlayRecording
		
		
		on setShowQuickAccessOverlayRecordingOn()
			if not isShowQuickAccessOverlayRecording() then toggleShowQuickAccessOverlayRecording()
		end setShowQuickAccessOverlayRecordingOn
		
		
		on setShowQuickAccessOverlayRecordingOff()
			if isShowQuickAccessOverlayRecording() then toggleShowQuickAccessOverlayRecording()
		end setShowQuickAccessOverlayRecordingOff
		
		
		on isCopyFileToClipboardScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return (value of checkbox 1 of UI element 1 of row 2 of table 1 of scroll area 1 of front window) is 1
				end try
			end tell
			
			false
		end isCopyFileToClipboardScreenshot
		
		on toggleCopyFileToClipboardScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return
				
				click checkbox 1 of UI element 1 of row 2 of table 1 of scroll area 1 of front window
			end tell
		end toggleCopyFileToClipboardScreenshot
		
		on setCopyFileToClipboardScreenshotOn()
			if not isCopyFileToClipboardScreenshot() then toggleCopyFileToClipboardScreenshot()
		end setCopyFileToClipboardScreenshotOn
		
		on setCopyFileToClipboardScreenshotOff()
			if isCopyFileToClipboardScreenshot() then toggleCopyFileToClipboardScreenshot()
		end setCopyFileToClipboardScreenshotOff
		
		
		on isCopyFileToClipboardRecording()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return (value of checkbox 1 of UI element 2 of row 2 of table 1 of scroll area 1 of front window) is 1
				end try
			end tell
			
			false
		end isCopyFileToClipboardRecording
		
		on toggleCopyFileToClipboardRecording()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return
				
				click checkbox 1 of UI element 2 of row 2 of table 1 of scroll area 1 of front window
			end tell
		end toggleCopyFileToClipboardRecording
		
		on setCopyFileToClipboardRecordingOn()
			if not isCopyFileToClipboardRecording() then toggleCopyFileToClipboardRecording()
		end setCopyFileToClipboardRecordingOn
		
		on setCopyFileToClipboardRecordingOff()
			if isCopyFileToClipboardRecording() then toggleCopyFileToClipboardRecording()
		end setCopyFileToClipboardRecordingOff
		
		
		on isSaveScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return (value of checkbox 1 of UI element 1 of row 3 of table 1 of scroll area 1 of front window) is 1
				end try
			end tell
			
			false
		end isSaveScreenshot
		
		on toggleSaveScreenshot()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return
				
				click checkbox 1 of UI element 1 of row 3 of table 1 of scroll area 1 of front window
			end tell
		end toggleSaveScreenshot
		
		on setSaveScreenshotOn()
			if not isSaveScreenshot() then toggleSaveScreenshot()
		end setSaveScreenshotOn
		
		on setSaveScreenshotOff()
			if isSaveScreenshot() then toggleSaveScreenshot()
		end setSaveScreenshotOff
		
		
		on isSaveRecording()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return false
				try
					return (value of checkbox 1 of UI element 2 of row 3 of table 1 of scroll area 1 of front window) is 1
				end try
			end tell
			
			false
		end isSaveRecording
		
		on toggleSaveRecording()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if (count of windows) is 0 then return
				
				click checkbox 1 of UI element 2 of row 3 of table 1 of scroll area 1 of front window
			end tell
		end toggleSaveRecording
		
		on setSaveRecordingOn()
			if not isSaveRecording() then toggleSaveRecording()
		end setSaveRecordingOn
		
		on setSaveRecordingOff()
			if isSaveRecording() then toggleSaveRecording()
		end setSaveRecordingOff
		
		(* After capture handlers =End =============================================================*)
	end script
end decorate
