(*
	@Purpose:
		Wrapper for the (Elgato) Camera Hub app.
		
	@Accessibility:
		Buttons does not have proper description that's why we need to trigger by index which is not great.
		There are three windows while the app is running.
			Dialog is for the text to read.
			Standard Window has the main controls.
	
	@Usage:
	
	@Notes:
		There are 2 windows, one dialog which is the one displayed in the prompter, and the non-dialog, is the main app window.	
				
	
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Camera Hub/2.2/camera-hub'

	@Created: Friday, August 2, 2024 at 1:35:44 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"

property logger : missing value

property cliclick : missing value

property INDEX_CHECKBOX_DISPLAY : 6
property INDEX_CHECKBOX_TEXT : 7
property INDEX_CHECKBOX_CHAT : 8

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
		Manual: Switch Content Type
		Manual: Preview - Collapse
		
		Manual: Preview - Show
		Manual: Preview - Toggle
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("Preview visible: {}", sut's isPreviewVisible())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's clickNext()
		
	else if caseIndex is 3 then
		sut's clickPrevious()
		
	else if caseIndex is 4 then
		set sutContentType to -1
		-- set sutContentType to INDEX_CHECKBOX_DISPLAY
		set sutContentType to INDEX_CHECKBOX_TEXT
		set sutContentType to INDEX_CHECKBOX_CHAT
		logger's debugf("sutContentType: {}", sutContentType)
		
		sut's switchContentType(sutContentType)
		
	else if caseIndex is 5 then
		sut's collapsePreview()
		
	else if caseIndex is 6 then
		sut's showPreview()
		
	else if caseIndex is 7 then
		sut's togglePreview()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	
	script CameraHubInstance
		
		on getMainWindow()
			if running of application "Elgato Camera Hub" is false then return missing value
			
			tell application "System Events" to tell process "Camera Hub"
				try
					return window "Camera Hub"
				end try
			end tell
			
			missing value
		end getMainWindow
		
		
		on collapsePreview()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return
			if not isPreviewVisible() then return
			
			tell application "System Events" to tell process "Camera Hub"
			try
				click (first button of group 1 of mainWindow whose description is "Collapse preview")
				end try
			end tell
		end collapsePreview
		
		
		on showPreview()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return
			if isPreviewVisible() then return
			
			tell application "System Events" to tell process "Camera Hub"
				try
				click (first button of group 1 of mainWindow whose description is "Show preview")
				end try
			end tell
		end showPreview
		
		
		on togglePreview()
			if isPreviewVisible() then
				collapsePreview()
			else
				showPreview()
			end if
			
		end togglePreview
		
		
		on isPreviewVisible()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return false
			
			tell application "System Events" to tell process "Camera Hub"
				try
					return exists (first button of group 1 of window 2 whose description is "Collapse Preview")
				end try
			end tell
			
			false
		end isPreviewVisible
		
		
		on switchContentTypeText()
			switchContentType(INDEX_CHECKBOX_TEXT)
		end switchContentTypeText
		
		
		on switchContentTypeDisplay()
			switchContentType(INDEX_CHECKBOX_DISPLAY)
		end switchContentTypeDisplay
		
		
		on switchContentType(contentTypeIndex)
			logger's debugf("contentTypeIndex: {}", contentTypeIndex)
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return
			
			if running of application "Elgato Camera Hub" is false then return
			
			tell application "System Events" to tell process "Camera Hub"
				set frontmost to true
				try
					-- click checkbox contentType of group 1 of (first window whose description is "standard window")  -- Didn't work.
					-- click checkbox 8 of group 1 of (first window whose description is "standard window")  -- Double selected.
					lclick of cliclick at checkbox contentTypeIndex of group 1 of mainWindow
				end try
			end tell
		end switchContentType
		
		
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
