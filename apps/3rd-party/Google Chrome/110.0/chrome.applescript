(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Chrome/110.0/chrome
*)
use scripting additions

use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

use listUtil : script "core/list"

use winUtilLib : script "core/window"
use chromeTabLib : script "core/chrome-tab"

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
	if caseIndex is 1 then
		sut's newWindow("https://www.example.com")

	else if caseIndex is 2 then
		sut's newTab("https://www.example.com")

	else if caseIndex is 3 then
		sut's openDeveloperTools()

	else if caseIndex is 4 then
		set chromeTab to sut's getFrontTab()
		if chromeTab is missing value then
			logger's info("Chrome window was not found")
		else
			chromeTab's runScript("alert('Hello Chrome AppleScript')")
		end if

	end if

	spot's finish()
	logger's finish()
end spotCheck

on new()
	set winUtil to winUtilLib's new()

	script ChromeInstance
		on newWindow(targetUrl)
			tell application "Google Chrome"
				activate
				set newWindow to make new window
				set URL of active tab of newWindow to targetUrl

				tell front window
					chromeTabLib's new(its id, active tab index)
				end tell
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

		on getFrontTab()
			if not winUtil's hasWindow("Google Chrome") then return missing value

			tell application "Google Chrome" to tell first window
				chromeTabLib's new(its id, active tab index)
			end tell
		end getFrontTab


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
