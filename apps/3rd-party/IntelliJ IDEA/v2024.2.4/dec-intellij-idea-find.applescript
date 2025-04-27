(*
	@Purpose:
	

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/IntelliJ IDEA/v2024.2.4/dec-intellij-idea-find'

	@Created: Wed, Apr 23, 2025 at 07:22:41 AM
	@Last Modified: Wed, Apr 23, 2025 at 07:22:41 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Menu Find in Files
		Manual: Set filter mask
		Manual: Clear filter mask
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/intellij-idea"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Find dialog probably present: {}", sut's isDialogWindowPresent())
	set isFiltered to sut's isFilteredByFileMask()
	logger's infof("Is filtered by file mask: {}", isFiltered)
	
	if isFiltered then logger's infof("Filter file mask: {}", sut's getFindInFilesFileMask())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerMenuFindInFiles()
		
	else if caseIndex is 3 then
		set sutFilterMask to "*.java"
		set sutFilterMask to "*.properties"
		logger's debugf("sutFilterMask: {}", sutFilterMask)
		
		sut's setFindInFilesFileMask(sutFilterMask)
		
	else if caseIndex is 4 then
		sut's clearFindInFilesFileMask()
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script IntellijIdeaFindDecorator
		property parent : mainScript
		
		on triggerMenuFindInFiles()
			if running of application (parent's intellijAppName) is false then return
			
			tell application "System Events" to tell process (my _getProcessName())
				try
					click (first menu item of menu 1 of menu item "Find" of menu 1 of menu bar item "Edit" of menu bar 1 whose title starts with "Find in Files")
				end try
			end tell
		end triggerMenuFindInFiles
		
		on isDialogWindowPresent()
			if running of application (parent's intellijAppName) is false then return false
			
			tell application "System Events" to tell process (my _getProcessName())
				exists (first window whose description is "window")
			end tell
		end isDialogWindowPresent
		
		
		on toggleFilterFindInFiles()
			if isDialogWindowPresent() is false then return
			
			tell application "System Events" to tell process (my _getProcessName())
				click checkbox 1 of window ""
			end tell
		end toggleFilterFindInFiles
		
		
		on unfilterFindInFiles()
			if not isFilteredByFileMask() then return
			toggleFilterFindInFiles()
		end unfilterFindInFiles
		
		
		on filterFindInFiles()
			if isFilteredByFileMask() then return
			toggleFilterFindInFiles()
		end filterFindInFiles
		
		
		on isFilteredByFileMask()
			if not isDialogWindowPresent() then return false
			
			tell application "System Events" to tell process (my _getProcessName())
				value of checkbox 1 of window "" is 1
			end tell
		end isFilteredByFileMask
		
		
		on getFindInFilesFileMask()
			if not isDialogWindowPresent() then return false
			
			tell application "System Events" to tell process (my _getProcessName())
				value of text field 1 of combo box 1 of window ""
			end tell
		end getFindInFilesFileMask
		
		
		on setFindInFilesFileMask(newMask)
			if not isDialogWindowPresent() then return false
			
			tell application "System Events" to tell process (my _getProcessName())
			try
				set focused of text field 1 of combo box 1 of window "" to true
				end try -- combo box is not always referece-able.
				set frontmost to true
				kb's typeText(newMask)
			end tell
		end setFindInFilesFileMask
		
		on clearFindInFilesFileMask()
			if not isDialogWindowPresent() then return false
			
			tell application "System Events" to tell process (my _getProcessName())
				set focused of text field 1 of combo box 1 of window "" to true
				set frontmost to true
				kb's pressCommandKey("a")
				kb's pressKey("delete")
			end tell
		end clearFindInFilesFileMask
	end script
end decorate
