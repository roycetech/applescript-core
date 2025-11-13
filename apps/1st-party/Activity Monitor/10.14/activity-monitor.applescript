(*
	@Purpose:
		Use activity monitor to force quit a non-responding or a rogue application process.
		
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Activity Monitor/10.14/activity-monitor'

	@Created: Wednesday, August 28, 2024 at 10:05:48 AM
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
		Manual: Filter Menu Case
		Manual: Quit Process
		Manual: Force Quit Process
		Manual: Switch Tab
		
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
	logger's infof("Selected tab: {}", sut's getSelectedTab())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		activate application "Activity Monitor"
		delay 1
		
		sut's filterApp("Menu Case")
		delay 2 -- Wait for the filter to take effect.
		
	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's quitFirstProcess())
		
	else if caseIndex is 4 then
		logger's infof("Handler result: {}", sut's forceQuitFirstProcess())
		
	else if caseIndex is 5 then
		set sutTabName to "unicorn"
		set sutTabName to "CPU"
		logger's debugf("sutTabName: {}", sutTabName)
		
		sut's switchTab(sutTabName)
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script ActivityMonitorInstance
		
		on switchTab(tabName)
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Activity Monitor"
				try
					click (first radio button of radio group 1 of group 1 of toolbar 1 of front window whose description is equal to the tabName)				
									end try
			end tell
		end switchTab
		
		
		on getSelectedTab()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then return missing value
			
			tell application "System Events" to tell process "Activity Monitor"
				first radio button of radio group 1 of group 1 of toolbar 1 of front window whose value is 1
				
				-- click radio button "CPU" of radio group 1 of group 1 of toolbar 1 of front window
				
				description of result
			end tell
		end getSelectedTab
		
		
		on getMainWindow()
			if running of application "Activity Monitor" is false then return missing value
			
			tell application "System Events" to tell process "Activity Monitor"
				try
					return first window whose description is "standard window"
				end try
			end tell
			
			missing value
		end getMainWindow
		
		on filterApp(appKeyword)
			if running of application "Activity Monitor" is false then return
			
			tell application "System Events" to tell process "Activity Monitor"
				set focused of text field 1 of group 2 of toolbar 1 of front window to true
				set value of text field 1 of group 2 of toolbar 1 of front window to appKeyword
			end tell
		end filterApp
		
		
		(* NOTE: It takes a few seconds for the task to disappear from the list. *)
		on quitFirstProcess()
			if running of application "Activity Monitor" is false then return false
			
			tell application "System Events" to tell process "Activity Monitor"
				if not (exists (first row of outline 1 of scroll area 1 of front window)) then
					logger's info("No process is listed")
					return false
				end if
				
				set selected of first row of outline 1 of scroll area 1 of front window to true
				click (first button of toolbar 1 of front window whose description is "Stop")
				delay 0.1
				click button "Quit" of sheet 1 of front window
			end tell
			true
		end quitFirstProcess
		
		
		on forceQuitFirstProcess()
			if running of application "Activity Monitor" is false then return false
			
			tell application "System Events" to tell process "Activity Monitor"
				if not (exists (first row of outline 1 of scroll area 1 of front window)) then
					logger's info("No process is listed")
					return false
				end if
				
				set selected of first row of outline 1 of scroll area 1 of front window to true
				click (first button of toolbar 1 of front window whose description is "Stop")
				delay 0.1
				click button "Force Quit" of sheet 1 of front window
			end tell
			true
		end forceQuitFirstProcess
	end script
end new
