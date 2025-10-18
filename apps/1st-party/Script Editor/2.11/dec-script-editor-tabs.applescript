(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-tabs'

	@Created: Thu, Oct 09, 2025 at 02:12:10 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Switch Tab by Index
		Manual: Previous Tab
		Manual: Next Tab
		Dummy

		Dummy
		Dummy
		Dummy
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
	
	set sut to new()
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutTabIndex to 0
		set sutTabIndex to 1
		logger's debugf("sutTabIndex: {}", sutTabIndex)
		
		sut's switchTabByIndex(sutTabIndex)
		
	else if caseIndex is 3 then
		sut's previousTab()
		
	else if caseIndex is 4 then
		sut's nextTab()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorTabsDecorator
		property parent : mainScript

		on nextTab()
			if running of application "Script Editor" is false then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click menu item "Show Next Tab" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end nextTab
		
		
		on previousTab()
			if running of application "Script Editor" is false then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click menu item "Show Previous Tab" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end previousTab
		
		
		on getTabCount()
			if running of application "Script Editor" is false then return 0
			
			tell application "System Events" to tell process "Script Editor"
				count the radio buttons of tab group "tab bar" of front window
			end tell
		end getTabCount
		
		
		on switchTabByIndex(tabIndex)
			set currentTabCount to getTabCount()
			-- logger's debugf("currentTabCount: {}", currentTabCount)
			
			if tabIndex is less than 1 then return
			if tabIndex is greater than currentTabCount then return
			
			tell application "System Events" to tell process "Script Editor"
				try
					click radio button tabIndex of tab group "tab bar" of front window
				end try
			end tell
		end switchTabByIndex
	end script
end new
