(*
	Decorator for view-related functionality. The main goal of this decorator 
	is to group together the view-related functions to keep the main component
	small.
*)
use listUtil : script "list"

use loggerLib : script "logger"
use usrLib : script "user"

use spotScript : script "spot-test"

property logger : loggerLib's new("dec-calendar-view")
property usr : usrLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "cal-ext-view-spotCheck"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Manual: Current Calendar View (Day, Week, Month, Year)
		Switch to Day View
		Switch to Week View
		Switch to Month View
		Switch to Year View
		
		Switch View - Day
		Switch View - Week
		Switch View - Month
		Switch View - Year
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application "Calendar"
	set sut to decorate(newSpotBase())
	
	if caseIndex is 1 then
		logger's infof("Current View: {}", sut's getViewType())
		
	else if caseIndex is 2 then
		sut's switchToDayView()
		
	else if caseIndex is 3 then
		sut's switchToWeekView()
		
	else if caseIndex is 4 then
		sut's switchToMonthView()
		
	else if caseIndex is 5 then
		sut's switchToYearView()
		
	else
		set viewTitle to last word of caseDesc
		sut's switchToViewByTitle(viewTitle)
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property yo : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	script CalendarWithViewInstance
		property parent : mainScript
		
		on getViewType()
			if running of application "Calendar" is false then return missing value
			
			tell application "System Events" to tell process "Calendar"
				set selectedRadio to get value of radio group 1 of group 2 of toolbar 1 of window "Calendar"
				if usr's getOsMajorVersion() is less than 13 then return title of selectedRadio
				
				return description of selectedRadio -- Ventura (13)
			end tell
		end getViewType
		
		
		on switchToViewByTitle(viewType)
			if running of application "Calendar" is false then return
			
			tell application "System Events" to tell process "Calendar"
				try
					click (first radio button of radio group 1 of group 2 of toolbar 1 of window "Calendar" whose description is viewType)
				on error -- Pre-Ventura
					click (first radio button of radio group 1 of group 2 of toolbar 1 of window "Calendar" whose title is viewType)
				end try
				
			end tell
		end switchToViewByTitle
		
		
		on switchToDayView()
			if running of application "Calendar" is false then return
			
			tell application "Calendar" to switch view to day view
		end switchToDayView
		
		
		on switchToWeekView()
			if running of application "Calendar" is false then return
			
			tell application "Calendar" to switch view to week view
		end switchToWeekView
		
		
		on switchToMonthView()
			if running of application "Calendar" is false then return
			
			tell application "Calendar" to switch view to month view
		end switchToMonthView
		
		on switchToYearView()
			switchToViewByTitle("Year") -- no native support for this.
		end switchToYearView
	end script
end decorate

