(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Windows App/11.0.x/windows-app'

	@Created: Fri, Apr 18, 2025 at 12:27:44 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value
property retry : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Connect
		Manual: Switch Tab
		Manual: Close Devices Window
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
	logger's infof("Connection certificate prompt present: {}", sut's isConnectionCertificatePromptPresent())
	logger's infof("Sidebar present: {}", sut's isSidebarPresent())
	logger's infof("Current vtab name: {}", sut's getCurrentTabName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutConnectionName to "Unicorn"
		set sutConnectionName to "WFH-2025MAR02"
		
		logger's debugf("sutConnectionName: {}", sutConnectionName)
		
		sut's connect(sutConnectionName)
		
	else if caseIndex is 3 then
		set sutTabName to "Unicorn"
		set sutTabName to "Devices"
		
		logger's debugf("sutTabName: {}", sutTabName)
		
		sut's switchTab(sutTabName)
		
	else if caseIndex is 4 then
		sut's closeDevicesWindow()
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set retry to retryLib's new()
	
	script WindowsAppInstance
		on switchTab(tabName)
			if not isSidebarPresent() then return
			
			tell application "System Events" to tell process "Windows App"
				try
					
					first row of table 1 of scroll area 1 of splitter group 1 of front window whose description of button 1 of UI element 1 is tabName
					set selected of result to true
				end try
			end tell
		end switchTab
		
		on isSidebarPresent()
			if running of application "Windows App" is false then return false
			
			tell application "System Events" to tell process "Windows App"
				exists table 1 of scroll area 1 of splitter group 1 of front window
			end tell
		end isSidebarPresent
		
		on getCurrentTabName()
			if running of application "Windows App" is false then return missing value
			if not isSidebarPresent() then return missing value
			
			tell application "System Events" to tell process "Windows App"
				if (the count of windows) is 0 then return missing value
				
				first row of table 1 of scroll area 1 of splitter group 1 of front window whose selected is true
				description of button 1 of UI element 1 of result
			end tell
		end getCurrentTabName
		
		on isConnectionCertificatePromptPresent()
			if running of application "Windows App" is false then return false
			
			tell application "System Events" to tell process "Windows App"
				try
					return exists button "Continue" of group 2 of sheet 1 of front window
				end try
			end tell
			false
		end isConnectionCertificatePromptPresent
		
		on connect(connectionName)
			if running of application "Windows App" is false then return
			
			tell application "System Events" to tell process "Windows App"
				if (the count of windows) is 0 then
					tell application "System Events" to tell process "Dock"
						click UI element "Windows App" of list 1
					end tell
				end if
				
				set mainWindow to the first window whose description is not "Preferences"
				set connectionCard to missing value
				try
					set connectionCard to the first group of list 1 of list 1 of scroll area 1 of group 1 of splitter group 1 of mainWindow whose description of group 1 is connectionName
				end try
				if connectionCard is missing value then return
				
				perform action "AXPress" of group 1 of connectionCard
			end tell
			
			script PromptWaiter
				tell application "System Events" to tell process "Windows App"
					if exists button "Continue" of group 2 of sheet 1 of front window then return true
				end tell
			end script
			set waitResult to exec of retry on result for 20 by 0.1
			if waitResult is missing value then return
			
			tell application "System Events" to tell process "Windows App"
				click button "Continue" of group 2 of sheet 1 of front window
			end tell
		end connect
		
		
		on closeDevicesWindow()
			if running of application "Windows App" is false then return
			
			tell application "System Events" to tell process "Windows App"
				try
					click (first button of window "Devices" whose description is "close button")
				end try
			end tell
		end closeDevicesWindow
	end script
end new
