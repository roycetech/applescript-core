(*
	Copied from Chrome implementation while it wasn't fully tested yet.
	
	@Purpose: This was created because I wanted to have free access to ChatGPT 4 which is only available using Bing atm.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Microsoft Edge/120.0/microsoft-edge'
*)
use scripting additions

use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

use listUtil : script "core/list"

use winUtilLib : script "core/window"
use msedgeTabLib : script "core/microsoft-edge-tab"

use spotScript : script "core/spot-test"

property winUtil : missing value
property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
	    	Manual: New Window
    		Manual: New Tab
    		Manual: Open the Developer tools
    		Manual: JavaScript
  	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	if caseIndex is 0 then
		return
	end if
	
	set sut to new()
	
	logger's infof("ChatGPT is active: {}", sut's isChatActive())
	if caseIndex is 1 then
		sut's newWindow("https://www.example.com")
		
	else if caseIndex is 2 then
		sut's newTab("https://www.example.com")
		
	else if caseIndex is 3 then
		sut's openDeveloperTools()
		
	else if caseIndex is 4 then
		set msedgeTab to sut's getFrontTab()
		if msedgeTab is missing value then
			logger's info("MS Edge window was not found")
		else
			msedgeTab's runScript("alert('Hello MS Edge AppleScript')")
		end if
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck

on new()
	set winUtil to winUtilLib's new()
	
	script MicrosoftEdgeInstance
		on newWindow(targetUrl)
			tell application "Microsoft Edge"
				activate
				set newWindow to make new window
				set URL of active tab of newWindow to targetUrl
				
				tell front window
					msedgeTabLib's new(its id, active tab index)
				end tell
			end tell
		end newWindow
		
		on newTab(targetUrl)
			tell application "Microsoft Edge"
				activate
				tell front window
					set newTab to make new tab at end of tabs
					set URL of newTab to targetUrl
				end tell
			end tell
		end newTab
		
		on getFrontTab()
			if not winUtil's hasWindow("Microsoft Edge") then return missing value
			
			tell application "Microsoft Edge" to tell first window
				msedgeTabLib's new(its id, active tab index)
			end tell
		end getFrontTab
		
		
		on openDeveloperTools()
			tell application "Microsoft Edge"
				activate
				tell active tab of window 1 to activate
				tell application "System Events"
					keystroke "i" using {option down, command down}
				end tell
			end tell
		end openDeveloperTools
		
		on isChatActive()
			tell application "System Events" to tell process "Microsoft Edge"
				try
					return "Chat" is equal to the description of button 1 of group 1 of group 4 of group 1 of group 1 of group 1 of group 1 of front window
				end try
				
			end tell
			
			false
		end isChatActive
	end script
end new
