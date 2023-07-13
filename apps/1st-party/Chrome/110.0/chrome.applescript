use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"

use spotScript : script "spot-test"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	
	set cases to listUtil's splitByLine("
    Manual: New Window
    Manual: New Tab
    Manual: Open the Developer tools
  ")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	if caseIndex is 0 then
		return
	end if
	
	set sut to new()
	
	if caseIndex is 1 then
		sut's newWindow("https://www.example.com")
		
	else if caseIndex is 2 then
		sut's newTab("https://www.example.com")
		
	else if caseIndex is 3 then
		sut's openDeveloperTools()
	end if
	
end spotCheck

on new()
	script ChromeInstance
		on newWindow(targetUrl)
			tell application "Google Chrome"
				activate
				set newWindow to make new window
				set URL of active tab of newWindow to targetUrl
			end tell
		end newWindow
		
		on newTab(targetUrl)
			tell application "Google Chrome"
				activate
				tell front window
					set newTab to make new tab at end of tabs
					set URL of newTab to targetUrl
				end tell
			end tell
		end newTab
		
		on openDeveloperTools()
			tell application "Google Chrome"
				activate
				tell active tab of window 1 to activate
				tell application "System Events"
					keystroke "i" using {option down, command down}
				end tell
			end tell
		end openDeveloperTools
	end script
end new
