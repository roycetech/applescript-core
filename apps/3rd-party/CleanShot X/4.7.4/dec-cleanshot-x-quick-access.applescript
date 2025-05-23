(*

	NOTE: The app has no label we could use for a better referencing of UI, that's why we stick to using hard-coded indeces.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/CleanShot X/4.7.4/dec-cleanshot-x-quick-access'

	@Created: Tuesday, December 31, 2024 at 7:57:59 AM
	@Last Modified: Tuesday, December 31, 2024 at 7:57:59 AM
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
		Manual: Auto-close - On
		Manual: Auto-close - Off
		Manual: Set Auto-close Action: Close
		Manual: Set Auto-close Action: Save and Close
		Manual: Set Auto-close Interval
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
	sut's switchTab("Quick Access")
	
	logger's infof("Auto-close: {}", sut's getAutoClose())
	logger's infof("Auto-close action: {}", sut's getAutoCloseAction())
	logger's infof("Auto-close interval: {}", sut's getAutoCloseInterval())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setAutoCloseOn()
		
	else if caseIndex is 3 then
		sut's setAutoCloseOff()
		
	else if caseIndex is 4 then
		sut's setAutoCloseAction("Close")
		
	else if caseIndex is 5 then
		sut's setAutoCloseAction("Save and Close")
		
	else if caseIndex is 6 then
		set sutInterval to "5 seconds"
		set sutInterval to "15 seconds"
		(*
		set sutInterval to "10 seconds"
		set sutInterval to "1 minute"
		set sutInterval to "10 minutes"
*)
		sut's setAutoCloseInterval(sutInterval)
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script CleanshotXQuickDecorator
		property parent : mainScript
		
		on getAutoClose()
			if running of application "CleanShot X" is false then return false
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Quick Access")) then return false
				
				try
					return value of checkbox "Enable" of window "Quick Access" is 1
				end try
			end tell
			
			false
		end getAutoClose
		
		
		on toggleAutoClose()
			if running of application "CleanShot X" is false then return
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Quick Access")) then return
				
				click checkbox "Enable" of window "Quick Access"
			end tell
			
			false
		end toggleAutoClose
		
		
		on setAutoCloseOn()
			if not getAutoClose() then toggleAutoClose()
		end setAutoCloseOn
		
		on setAutoCloseOff()
			if getAutoClose() then toggleAutoClose()
			
		end setAutoCloseOff
		
		
		(* @returns 'Close' or 'Save and Close' *)
		on getAutoCloseAction()
			if running of application "CleanShot X" is false then return missing value
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Quick Access")) then return missing value
				
				try
					return value of pop up button 3 of window "Quick Access"
				end try
			end tell
			
			missing value
		end getAutoCloseAction
		
		
		(* @ newValue 'Close' or 'Save and Close' *)
		on setAutoCloseAction(newValue)
			if running of application "CleanShot X" is false then return missing value
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Quick Access")) then return missing value
				
				click pop up button 3 of window "Quick Access"
				delay 0.1
				try
					click (first menu item of menu 1 of pop up button 3 of window "Quick Access" whose title is newValue)
				end try
			end tell
			
			missing value
		end setAutoCloseAction
		
		(*  *)
		on getAutoCloseInterval()
			if running of application "CleanShot X" is false then return missing value
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Quick Access")) then return missing value
				
				try
					return value of pop up button 1 of window "Quick Access"
				end try
			end tell
			
			missing value
		end getAutoCloseInterval
		
		(* @newInterval - 5, 10, 15..30 seconds; 1, 2, 5, 10 minutes *)
		on setAutoCloseInterval(newInterval)
			if running of application "CleanShot X" is false then return missing value
			
			tell application "System Events" to tell process "CleanShot X"
				if not (exists (window "Quick Access")) then return missing value
				
				click pop up button 1 of window "Quick Access"
				delay 0.1
				try
					click (first menu item of menu 1 of pop up button 1 of window "Quick Access" whose title is newInterval)
				end try
			end tell
			
			missing value
		end setAutoCloseInterval
	end script
end decorate
