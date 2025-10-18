(*
	@Purpose:
		Provide handlers for the Script Editor editor window.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-window'

	@Created: Fri, Aug 29, 2025 at 07:13:29 AM
	@Last Modified: Fri, Aug 29, 2025 at 07:13:29 AM
	@Change Logs:
		Wed, Oct 08, 2025, at 06:48:27 AM - Added #toggleAccessoryView
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

property ACCESSORY_VIEW_TYPE_DESCRIPTION : "description" -- (i)
property ACCESSORY_VIEW_TYPE_RESULT : "result" --  (<-),
property ACCESSORY_VIEW_TYPE_LOG : "log" -- (=)

property ACCESSORY_VIEW_TYPE_DESCRIPTIONS : {ACCESSORY_VIEW_TYPE_DESCRIPTION, ACCESSORY_VIEW_TYPE_RESULT, ACCESSORY_VIEW_TYPE_LOG}

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Switch Accessory View > Tab (bottom left buttons)
		Manual: Switch Accessory View > Log > Tab
		Manual: Toggle Accessory View
		Manual: Show Accessory View		

		Manual: Hide Accessory View		
		Manual: Show Log History
		Manual: Hide Log History
		Dummy
		Dummy
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
	set sutLib to script "core/script-editor"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Accessory view type: {}", sut's getAccessoryViewTypeName())
	logger's infof("Accessory view visible: {}", sut's isAccessoryViewVisible())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutBottomTab to "unicorn"
		set sutBottomTab to "description"
		set sutBottomTab to "result"
		set sutBottomTab to "log"
		logger's debugf("sutBottomTab: {}", sutBottomTab)
		
		sut's switchAccessoryView(sutBottomTab)
		
	else if caseIndex is 3 then
		set sutLogTab to "unicorn"
		set sutLogTab to "Result"
		set sutLogTab to "Events"
		set sutLogTab to "Replies"
		logger's debugf("sutLogTab: {}", sutLogTab)
		
		sut's switchLogTab(sutLogTab)
		
	else if caseIndex is 4 then
		sut's toggleAccessoryView()
		
	else if caseIndex is 5 then
		sut's showAccessoryView()
		
		
	else if caseIndex is 6 then
		sut's hideAccessoryView()
		
	else if caseIndex is 7 then
		sut's showLogHistory()
		
	else if caseIndex is 8 then
		sut's closeLogHistory()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorWindowDecorator
		property parent : mainScript
		
		on closeLogHistory()
			tell application "System Events" to tell process "Script Editor"
				try
					click (first button of window "Log History" whose description is "close button")
				end try
			end tell
		end closeLogHistory
		
		
		on showLogHistory()
			tell application "System Events" to tell process "Script Editor"
				try
					click menu item "Log History" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end showLogHistory
		
		
		on hideAccessoryView()
			if not isAccessoryViewVisible() then return
			
			toggleAccessoryView()
		end hideAccessoryView
		
		
		on showAccessoryView()
			if isAccessoryViewVisible() then return
			
			toggleAccessoryView()
		end showAccessoryView
		
		on toggleAccessoryView()
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return
			
			tell application "System Events" to tell process "Script Editor"
				click checkbox 1 of group 1 of group 1 of toolbar 1 of front window
			end tell
		end toggleAccessoryView
		
		(*
			NOTE: The contents does not appear when the log accessory view isn't already active.
		*)
		on switchLogTab(targetLogTabName)
			if getAccessoryViewTypeName() is not ACCESSORY_VIEW_TYPE_LOG then
				switchAccessoryView(ACCESSORY_VIEW_TYPE_LOG)
			end if
			
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click checkbox targetLogTabName of group 1 of splitter group 1 of splitter group 1 of editorWindow
				end try
			end tell
		end switchLogTab
		
		
		(*
			Shows the bottom pane if it is not visible.
		*)
		on switchAccessoryView(accessoryViewType)
			if ACCESSORY_VIEW_TYPE_DESCRIPTIONS does not contain accessoryViewType then return
			
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click (first radio button of radio group 1 of editorWindow whose description is accessoryViewType)
				end try
			end tell
		end switchAccessoryView
		
		
		on isAccessoryViewVisible()
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return false
			
			tell application "System Events" to tell process "Script Editor"
				try
					return exists (first radio button of radio group 1 of editorWindow whose value is 1)
				end try
			end tell
			
			false
		end isAccessoryViewVisible
		
		
		(*
			@returns log, description, or result
		*)
		on getAccessoryViewTypeName()
			set editorWindow to getEditorWindow()
			if editorWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				try
					return description of (first radio button of radio group 1 of editorWindow whose value is 1)
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
			end tell
			
			missing value
		end getAccessoryViewTypeName
		
		
		on getEditorWindow()
			if running of application "Script Editor" is false then return missing value
			
			tell application "System Events" to tell process "Script Editor"
				try
					return first window whose title contains "."
				end try
				
				missing value
			end tell
			
		end getEditorWindow
	end script
end decorate
