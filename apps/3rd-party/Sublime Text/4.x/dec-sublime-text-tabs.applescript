(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Sublime Text/4.x/dec-sublime-text-tabs'

	@Created: Fri, Oct 10, 2025 at 07:06:22 AM
	@Last Modified: Fri, Oct 10, 2025 at 07:06:22 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
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
	
	-- activate application ""
	set sutLib to script "core/sublime-text"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Current tab count: {}", sut's getTabCount())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutTabIndex to 0
		set sutTabIndex to 1
		set sutTabIndex to 8
		logger's debugf("sutTabIndex: {}", sutTabIndex)
		
		sut's switchTabByIndex(sutTabIndex)
		
	else if caseIndex is 3 then
		tell application "System Events" to tell process "Sublime Text" to set frontmost to true
		sut's previousTab()
		
	else if caseIndex is 4 then
		tell application "System Events" to tell process "Sublime Text" to set frontmost to true
		sut's nextTab()
		
	else
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SublimeTextTabsDecorator
		property parent : mainScript
		
		(*
			@returns the tab count of the front window
		*)
		on getTabCount()
			if running of application "Sublime Text" is false then return 0
			
			tell application "System Events" to tell process "Sublime Text"
				count of radio buttons of tab group "tab bar" of front window
			end tell
		end getTabCount
		
		
		on switchTabByIndex(tabIndex)
			set currentTabCount to getTabCount()
			-- logger's debugf("currentTabCount: {}", currentTabCount)
			
			if tabIndex is less than 1 then return
			if tabIndex is greater than currentTabCount then return
			
			tell application "System Events" to tell process "Sublime Text"
				try
					click radio button tabIndex of tab group "tab bar" of front window
				end try
			end tell
		end switchTabByIndex
		
		
		(*
			Requires that Sublime Text app is in focus.
		*)
		on nextTab()
			if running of application "Script Editor" is false then return
			
			tell application "System Events" to tell process "Sublime Text"
				try
					click menu item "Show Next Tab" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end nextTab
		
		
		(*
			Requires that Sublime Text app is in focus.
		*)
		on previousTab()
			if running of application "Script Editor" is false then return
			
			tell application "System Events" to tell process "Sublime Text"
				set frontmost to true
				try
					click menu item "Show Previous Tab" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end previousTab
	end script
end decorate
