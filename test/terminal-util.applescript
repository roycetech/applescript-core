(*
	Utility for testing Terminal app scripts.

	@Created: Friday, May 17, 2024 at 9:50:26 AM
	@Last Modified: 2024-05-26 10:15:12

	@Plists:
		config-user:
			Project applescript-core

	@Project:
		applescript-core

	@Build:
		/usr/bin/osacompile -o "$HOME/Library/Script Libraries/core/test/terminal-util.scpt" test/terminal-util.applescript
*)
use scripting additions

use textUtil : script "core/string"

(*
	NOTE: This logger doesn't show logs during test runs. Stick to vanilla log
	when debugging during tests.
*)
use loggerFactory : script "core/logger-factory"
use kbLib : script "core/keyboard"
use configLib : script "core/config"
use systemEventLib : script "core/system-events"
use dockLib : script "core/dock"

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value
property configUser : missing value
property systemEvent : missing value
property dock : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()


on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Launch Test Window
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()

	if caseIndex is 1 then
		set terminalTab to sut's getTestingTab()

	else if caseIndex is 2 then


	else if caseIndex is 3 then


	end if

	spot's finish()
	logger's finish()
end spotCheck



on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set delayAfterTypingSeconds of kb to 0.2 -- 0.1 results in intermittent failure.
	set configUser to configLib's new("user")
	set systemEvent to systemEventLib's new()
	set dock to dockLib's new()

	script TerminalUtilInstance
		property TEST_TAB_NAME : "unit-test-starter"
		property TEST_TAB_ENDING_WORD : "-starter"
		property TEST_TAB_MID_WORD : "-test-"

		(*
			Strange error when using OMZ where dash and dot doesn't get typed at all.
		*)
		property useCommandPasting : false

		on clearScreenAndCommands()
			if systemEvent's getFrontAppName() is not "Terminal" then return

			kb's pressControlKey("c")
			kb's pressCommandKey("k")
			repeat 2 times
				kb's pressControlKey("w")
			end repeat
			delay 1
		end clearScreenAndCommands

		on clearScreen()
			if systemEvent's getFrontAppName() is not "Terminal" then return

			kb's pressCommandKey("k")
			delay 1
		end clearScreenAndCommands

		on cdHome()
			if systemEvent's getFrontAppName() is not "Terminal" then return

			kb's typeText("cd" & return)
			delay 1
		end cdHome

		on cdScriptLibrary()
			if systemEvent's getFrontAppName() is not "Terminal" then return

			kb's typeText("cd ~/Library/Script\\ Libraries" & return)
			delay 1
		end cdScriptLibrary

		on cdNonUser()
			if systemEvent's getFrontAppName() is not "Terminal" then return

			kb's typeText("cd /usr/lib" & return)
			delay 1
		end cdNonUser

		on cdAppleScriptProject()
			if systemEvent's getFrontAppName() is not "Terminal" then return

			set projectPath to configUser's getValue("Project applescript-core")
			if useCommandPasting then
				kb's insertTextByPasting("cd " & projectPath)
				kb's typeText(return)
			else
				kb's typeText("cd " & projectPath & return)
			end if
			delay 1
		end cdAppleScriptProject

		on typeCommand(command)
			if systemEvent's getFrontAppName() is not "Terminal" then return

			set delayAfterTypingSeconds of kb to 0.15  -- Fix error typing the tail -f command.
			kb's typeText(command)
			delay 1 -- 0.1 seems not enough.  This additional delay allows terminal to register the command in its contents property.
		end typeCommand

		on pasteCommand(command)
			if systemEvent's getFrontAppName() is not "Terminal" then return

			kb's insertTextByPasting(command)
			delay 0.1 -- This additional delay allows terminal to register the command in its contents property.
		end typeCommand

		on quitTerminal()
			-- Using dock is a safe way to quit the Terminal app.
			-- Using quit command causes side effect, while pkill is a system level way to terminate a process.

			dock's triggerAppMenu("Terminal", "Quit")

			repeat until running of application "Terminal" is false
				delay 0.2

				tell application "System Events" to tell process "Terminal"
					if exists button "Terminate" of sheet 1 of front window then
						click button "Terminate" of sheet 1 of front window
						delay 1
						try
							dock's triggerAppMenu("Terminal", "Quit")
						end try
					end if
				end tell
			end repeat
		end quitTerminal

		on getTestingTab()
			set terminalLib to script "core/terminal"
			set terminal to terminalLib's new()

			-- log "looking for the test tab..."
			set terminalTab to terminal's findTabWithNameContaining(my TEST_TAB_NAME)
			if terminalTab is not missing value then
				-- log "--> Test tab was found, returning it"
				set autoDismissDialogue of terminalTab to true
				return terminalTab
			end if

			-- log "--> launching new test window"
			set terminalTab to terminal's newWindow("cd", my TEST_TAB_NAME)
			set autoDismissDialogue of terminalTab to true

			tell application "System Events" to tell process "Terminal"
				set windowCount to the count of windows
				if windowCount is greater than 1 then
					-- log "--> terminal-util: anomaly detected with windows count: " & windowCount
					-- attempt self-heal
					tell application "Terminal"
						close window 2
					end tell
					-- error "TODO: Clear existing windows"
				end if
			end tell

			-- log "--> newWindow launched...."
			tell application "Terminal"
				if contents of tab 1 of front window contains "Restored session:" then
					-- log "--> Re-launching because of restored session."
					terminalTab's closeTab()
					delay 1
					set terminalTab to terminal's newWindow("cd", my TEST_TAB_NAME)
					set autoDismissDialogue of terminalTab to true
				end if
			end tell

			terminalTab
		end getTestingTab

		on getFrontAppName()
			tell application "System Events"
				set frontApp to first application process whose frontmost is true
				name of frontApp
			end tell
		end getFrontAppName

		on getFrontWindowTitle()
			tell application "System Events"
				set frontApp to first application process whose frontmost is true
				set frontAppName to name of frontApp
				tell process frontAppName
					1st window whose value of attribute "AXMain" is true
				end tell
				title of result
			end tell
		end getFrontWindowTitle

		(*
			@returns true if expected count was met.
		*)
		on waitWindowCount(expectedCount)
			set limit to 200
			set counter to 0
			tell application "Terminal"
				repeat until (the number of windows) is expectedCount or counter is greater than limit
					set counter to counter + 1
					delay 0.2
				end repeat
			end tell
			counter is less than limit
		end waitWindowCount

		on getTrimmedContent()
			tell application "Terminal"
				set tabContents to contents of tab 1 of front window
				textUtil's rtrim(tabContents)
			end tell
		end getTrimmedContent

		on stretchScrollPane()
			set longline to ""
			repeat 22 times
				set longline to longline & (ASCII character 13)
			end repeat
			tell application "System Events" to tell process "Terminal"
				set frontmost to true
			end tell
			kb's typeText(longline)
		end stretchScrollPane

		on getDefaultProfile()
			tell application "System Events" to tell process "Terminal"
				try
					textUtil's stringAfter(title of menu item 1 of menu 1 of menu item 1 of menu 1 of menu bar item "Shell" of menu bar 1, "New Window with Profile - ")
				end try
			end tell
		end getDefaultTerminalProfile
	end script
end new
