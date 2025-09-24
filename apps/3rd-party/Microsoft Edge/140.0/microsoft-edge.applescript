(*
	@Purpose:

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Microsoft Edge/140.0/microsoft-edge'
		
	@Change Logs:
		Fri, Sep 19, 2025, at 07:17:56 AM - Fix newTab when there are no windows.
		Tue, Sep 09, 2025 at 10:21:03 AM - Updated
*)
use scripting additions

use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

use winUtilLib : script "core/window"
use microsoftEdgeTabLib : script "core/microsoft-edge-tab"

property logger : missing value

property winUtil : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: NOOP
		Manual: New Window
		Manual: New Tab
		Manual: Open the Developer tools
		Manual: JavaScript
		
		Placeholder - keep chat cases together
		Activate Chat
		Deactivate Chat
		Dummy
		Dummy
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	if caseIndex is 0 then
		return
	end if
	
	set sut to new()
	
	logger's infof("Integration: tab-finder: First Window Tab Count: {}", sut's getFirstWindowTabCount())
	logger's infof("Co-pilot is active: {}", sut's isChatActive())
	
	if caseIndex is 2 then
		sut's newWindow("https://www.example.com")
		
	else if caseIndex is 3 then
		set sutTab to sut's newTab("https://www.example.com")
		-- sutTab's waitForPageLoad() -- Integration with microsoft-edge-tab.applescript		
		
	else if caseIndex is 4 then
		sut's openDeveloperTools()
		
	else if caseIndex is 5 then
		set msedgeTab to sut's getFrontTab()
		if msedgeTab is missing value then
			logger's info("MS Edge window was not found")
		else
			msedgeTab's runScript("alert('Hello MS Edge AppleScript')")
		end if
		
	else if caseIndex is 6 then
		
	else if caseIndex is 7 then
		sut's activateChat()
		
	else if caseIndex is 8 then
		sut's deactivateChat()
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set winUtil to winUtilLib's new()
	
	script MicrosoftEdgeInstance
		on newWindow(targetUrl)
			tell application "Microsoft Edge"
				activate
				set newWindow to make new window
				set URL of active tab of newWindow to targetUrl
				
				tell front window
					microsoftEdgeTabLib's new(its id, active tab index)
				end tell
			end tell
		end newWindow
		
		
		on newTab(targetUrl)
			tell application "Microsoft Edge"
				activate
				
				if (count of windows) is 0 then					return my newWindow(targetUrl)
				
				tell front window
					set newTab to make new tab at end of tabs
					set URL of newTab to targetUrl
					-- return microsoftEdgeTabLib's new(newTab's id, active tab index)
					return microsoftEdgeTabLib's new(its id, active tab index)
				end tell
			end tell
		end newTab
		
		
		on getFrontTab()
			if not winUtil's hasWindow("Microsoft Edge") then return missing value
			
			tell application "Microsoft Edge" to tell first window
				microsoftEdgeTabLib's new(its id, active tab index)
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
					return exists (radio button 1 of group 1 of last group of group 1 of group 1 of group 1 of group 1 of front window whose description is "Chat")
					
				end try
			end tell
			
			false
		end isChatActive
		
		
		on activateChat()
			if isChatActive() then return
			
			tell application "System Events" to tell process "Microsoft Edge"
				click (first button of toolbar 1 of group 1 of group 1 of group 1 of group 1 of front window whose description starts with "Copilot")
			end tell
		end activateChat
		
		
		on deactivateChat()
			if not isChatActive() then return
			
			tell application "System Events" to tell process "Microsoft Edge"
				click (first button of toolbar 1 of group 1 of group 1 of group 1 of group 1 of front window whose description starts with "Copilot")
			end tell
		end deactivateChat
	end script
	
	set decMicrosoftEdgeTabFinder to script "core/dec-microsoft-edge-tab-finder"
	decMicrosoftEdgeTabFinder's decorate(MicrosoftEdgeInstance)
end new
