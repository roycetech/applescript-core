(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Opera/110.0/opera

	@Created: Wednesday, June 5, 2024 at 1:16:18 PM
*)
use scripting additions

use script "core/Text Utilities"

use loggerFactory : script "core/logger-factory"

use winUtilLib : script "core/window"
use operaTabLib : script "core/opera-tab"
use decOperaTabFinder : script "core/dec-opera-tab-finder"
use dockLib : script "core/dock"

use retryLib : script "core/retry"

property winUtil : missing value
property logger : missing value
property retry : missing value
property dock : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
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
		set operaTab to sut's newTab("https://www.example.com")
		operaTab's waitForPageLoad()

	else if caseIndex is 3 then
		sut's openDeveloperTools()

	else if caseIndex is 4 then
		set operaTab to sut's getFrontTab()
		if operaTab is missing value then
			logger's info("opera window was not found")
		else
			operaTab's runScript("alert('Hello opera AppleScript')")
		end if

	end if

	spot's finish()
	logger's finish()
end spotCheck

on new()
	loggerFactory's inject(me)
	set dock to dockLib's new()

	set winUtil to winUtilLib's new()
	set retry to retryLib's new()

	script operaInstance
		on newWindow(targetUrl)

			-- TODO!
			if running of application "Opera" then
				dock's triggerAppMenu("Safari", {"New Window", "New " & windowProfileName & " Window"})

			else

			end if

			tell application "Opera"
				activate
			end tell

			tell application "System Events"
				tell process "Opera"
					keystroke "n" using command down
				end tell
				delay 1
			end tell

			tell application "Opera"
				set URL of active tab of front window to targetUrl

				tell front window
					operaTabLib's new(its id, active tab index)
				end tell
			end tell
		end newWindow

		on newTab(targetUrl)
			tell application "Opera"
				-- activate

				if (count of windows) is 0 then
					do shell script "open -a 'Opera'"
				end if
			end tell

			script WindowWaiter
				if exists (front window of application "Opera") then return true
			end script
			exec of retry on result for 10 by 0.5

			tell application "Opera" to tell front window
				if title of active tab is "New Tab" then
					logger's info("Re-using existing New Tab")
					set newTab to active tab
				else
					set newTab to make new tab at end of tabs
				end if
				set URL of newTab to targetUrl
				operaTabLib's new(its id, active tab index)
			end tell
		end newTab

		on getFrontTab()
			if not winUtil's hasWindow("Opera") then return missing value

			tell application "Opera" to tell first window
				operaTabLib's new(its id, active tab index)
			end tell
		end getFrontTab


		on openDeveloperTools()
			tell application "Opera"
				activate
				tell active tab of window 1 to activate
				tell application "System Events"
					keystroke "i" using {option down, command down}
				end tell
			end tell
		end openDeveloperTools
	end script

	decOperaTabFinder's decorate(result)
end new
