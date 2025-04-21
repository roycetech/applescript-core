(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/iTerm2/3.5.x/iterm2

	@Created: Tuesday, February 11, 2025 at 6:30:28 AM
	@Last Modified: 2025-04-13 10:37:49
*)

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Run Command
		Manual: Type Command
		Manual: Switch Tab Index
		Manual: New Tab

		Manual: Close current tab
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
	logger's infof("Window title: {}", sut's getWindowTitle())
	logger's infof("Tab count: {}", sut's getTabCount())
	-- logger's infof("Recent output: {}", sut's getRecentOutput())  -- Too noisy
	if caseIndex is 1 then

	else if caseIndex is 2 then
		set sutCommand to "y"
		set sutCommand to "ls"

		sut's runCommandVoid(sutCommand)


	else if caseIndex is 3 then
		set sutCommand to "y"

		sut's typeCommand(sutCommand)

	else if caseIndex is 4 then
		set sutTargetIndex to -1
		set sutTargetIndex to 99
		set sutTargetIndex to 1
		set sutTargetIndex to 2

		logger's infof("sutTargetIndex: {}", sutTargetIndex)

		sut's switchTabIndex(sutTargetIndex)

	else if caseIndex is 5 then
		sut's newTab()

	else if caseIndex is 6 then
		sut's closeCurrentTab()
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()

	script ITerm2Instance
		property RECENT_OUTPUT_THRESHOLD : 1024


		on getWindowTitle()
			if running of application "iTerm" is false then return missing value

			tell application "System Events" to tell process "iTerm2"
				try
					return title of front window
				end try -- Failed Mon, Feb 24, 2025 at 08:57:35 AM
			end tell

			missing value
		end getWindowTitle


		on getRecentOutput()
			if running of application "iTerm" is false then return

			tell application "System Events" to tell process "iTerm2"
				try
					set terminalOutput to value of text area 1 of scroll area 1 of splitter group 1 of group 1 of window 1
					if length of terminalOutput is less than my RECENT_OUTPUT_THRESHOLD then return textUtil's rtrim(terminalOutput)

					set recentOutput to textUtil's substringFrom(terminalOutput, (length of terminalOutput) - (my RECENT_OUTPUT_THRESHOLD))
					return textUtil's trim(recentOutput)
				on error the errorMessage number the errorNumber
					return missing value
				end try
			end tell
		end getRecentOutput


		on runCommandVoid(command)
			if running of application "iTerm" is false then return

			tell application "iTerm"
				tell current session of current window
					write text command
				end tell
			end tell
		end runCommandVoid


		(* Type a command without pressing return in the end. *)
		on typeCommand(command)
			if running of application "iTerm" is false then return

			tell application "System Events" to tell process "iTerm2"
				set frontmost to true
			end tell
			kb's typeText(command)
		end typeCommand


		on getTabCount()
			if running of application "iTerm" is false then return 0

			tell application "iTerm" to tell current window
				count of tabs
			end tell
		end getTabCount


		on switchTabIndex(targetIndex)
			if running of application "iTerm" is false then return
			if getTabCount() is less than targetIndex or targetIndex is less than 1 then return

			tell application "iTerm"
				tell current window
					select tab targetIndex
				end tell
			end tell
		end switchTabIndex

		on newTab()
			if running of application "iTerm" is false then
				activate application "iTerm"
				return
			end if

			tell application "iTerm"
				tell current window
					create tab with default profile
				end tell
			end tell

			(*
				Example to create new tab and run a command. Perhaps create a handler runNewTabCommand()

				tell application "iTerm"
    tell current window
        set newTab to (create tab with default profile)
        tell current session of newTab
            write text "htop"
        end tell
    end tell
end tell
			*)
		end newTab

		on closeCurrentTab()
			if running of application "iTerm" is false then return
			if getTabCount() is 0 then return

			tell application "iTerm"
				tell current window
					close current tab
				end tell
			end tell
		end closeCurrentTab
	end script
end new
