(*
	This is a wrapper to a Terminal tab's instance.

	@Version:
		2.14.x for macOS Sonoma

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal-tab

	@Testing Note:
		WARNING: This script requires re-compilation each time there's a change on this file.

	@Created: Sunday, January 28, 2024 at 2:35:54 PM
	@Last Modified: 2025-05-17 08:06:32
*)
use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use textUtil : script "core/string"
use unic : script "core/unicodes"
use regex : script "core/regex"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use retryLib : script "core/retry"

use decoratorLib : script "core/decorator"

use extOutput : script "core/dec-terminal-output"
use extRun : script "core/dec-terminal-run"
use extPath : script "core/dec-terminal-path"
use extPrompt : script "core/dec-terminal-prompt"

property logger : missing value
property kb : missing value
property retry : missing value
property TopLevel : me

property SEPARATOR : unic's SEPARATOR

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: New Window
		Manual: New Tab
		Manual: Set Window Title
		Manual: Set Tab Title

		Manual: Clear Lingering Command
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set terminalLib to script "core/terminal"
	set terminal to terminalLib's new()
	set terminalTab to terminal's getFrontTab()
	if terminalTab is missing value then
		terminal's newWindow(missing value, "Initial Spot Terminal")
	end if

	tell application "Terminal" to set frontWinID to id of first window
	logger's debugf("Window ID: {}", frontWinID)

	set sut to new(frontWinID)
	logger's infof("Name: {}", name of sut)

	log 111
	log name of sut
	logger's infof("Lingering Command: {}", sut's getLingeringCommand())
	log 222

	logger's infof("Tab Name: {}", sut's getTabName())
	logger's infof("POSIX Path: {}", sut's getPosixPath())

	(* Manually test: zsh, bash, docker, sftp, redis-cli. *)
	logger's infof("Is Shell Prompt: {}", sut's isShellPrompt())
	logger's infof("Is Bash: {}", sut's isBash())
	logger's infof("Is Zsh: {}", sut's isZsh())
	logger's infof("Is SSH: {}", sut's isSSH())
	logger's infof("Prompt Text: {}", sut's getPromptText())

	logger's infof("Prompt: {}", sut's getPrompt())
	-- logger's infof("Last Output: {}", sut's getLastOutput()) -- BROKEN on @rt. Reproduce with command: "2"
	logger's infof("Window Title: {}", sut's getWindowTitle())
	logger's infof("Tab Title: {}", sut's getTabTitle())
	logger's infof("Has Dialogue: {}", sut's hasDialogue())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's newWindow("echo case 2", "spot window")

	else if caseIndex is 3 then
		set terminalTab to sut's newTab("Spot tab")

	else if caseIndex is 4 then
		sut's setWindowTitle("spot-win-title")

	else if caseIndex is 5 then
		sut's setTabTitle("spot-tab-title")

	else if caseIndex is 6 then
		sut's clearLingeringCommand()
	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new(pWindowId)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set retry to retryLib's new()

	tell application "Terminal"
		if not (exists window id pWindowId) then return missing value

		set localPromptEndChar to "$"
		tell application "Terminal"
			set termProcesses to processes of selected tab of window id pWindowId
			if (the number of items in termProcesses) is not 0 then
				if last item of termProcesses is "zsh" then set localPromptEndChar to ")"
				if termProcesses contains "-zsh" then set localPromptEndChar to "%"
			end if
		end tell
	end tell

	set initialTabIndex to TopLevel's getSelectedTabIndex()
	-- logger's debugf("initialTabIndex: {}", initialTabIndex)

	script TerminalTabInstance
		property appWindow : missing value -- will be set to app window (not system event window)
		property |instance name| : missing value

		(* Will only work for bash and zsh, not for ohmyzsh. *)
		property promptEndChar : localPromptEndChar -- designed for bash only.
		property commandRunMax : 100
		property commandRetrySleepSeconds : 3
		property lastCommand : missing value
		property maintainName : false
		property preferredName : ""
		property windowId : pWindowId
		property recentOutputChars : 300
		property tabIndex : initialTabIndex -- Will be affected when tab is closed.
		property storedTabTitle : ""
		property autoDismissDialogue : false

		(*
			User prompt has timestamp embedded. When refleshPromt is true, it
			will first send a blank command so the prompt is updated, then the
			actual command is sent next, so that execution time can be measured.
		*)
		property refreshPrompt : false


		(*
			Used to detect if the tab is in the state "Process Completed"
		*)
		on hasProcess()
			if running of application "Terminal" is false then return false

			tell application "Terminal"
				(the number of items in termProcesses) is not 0
			end tell
		end hasProcess


		on hasDuplicatedName()

		end hasDuplicatedName


		(* With test/s *)
		on scrollToTop()
			if running of application "Terminal" is false then return

			tell application "System Events" to tell process "Terminal"
				try
					set value of scroll bar 1 of scroll area 1 of splitter group 1 of window (name of my appWindow) to 0
				end try
			end tell
		end scrollToTop

		(* With test/s *)
		on scrollToBottom()
			scrollToEnd()
		end scrollToBottom

		(* With test/s *)
		on scrollToEnd()
			if running of application "Terminal" is false then return

			tell application "System Events" to tell process "Terminal"
				try
					set value of scroll bar 1 of scroll area 1 of splitter group 1 of window (name of my appWindow) to 1
				end try
			end tell
		end scrollToEnd

		(* With test/s *)
		on newWindow(bashCommand, windowName)
			set terminalLib to script "core/terminal"
			set terminal to terminalLib's new()
			terminal's newWindow(bashCommand, windowName)
		end newWindow

		(*
			Creates a new tab at the end of the window.

			Cases:
		*)
		(* With test/s *)
		on newTab(tabName)
			tell application "System Events" to tell process "Terminal"
				click menu item 1 of menu 1 of menu item "New Tab" of menu 1 of menu bar item "Shell" of menu bar 1
			end tell
			script FailRetrier
				(id of front window of application "Terminal") as integer
			end script
			set localWindowId to exec of retry on result for 20 by 0.2

			set theNewTab to new(localWindowId)
			set preferredName of theNewTab to tabName
			theNewTab's _setTabName(tabName)
			theNewTab
		end newTab

		(*
		on newTab(tabName)
			focus()
			tell application "System Events" to tell process "Terminal"
				click menu item "Basic" of menu 1 of menu item "New Tab" of menu 1 of menu bar item "Shell" of menu bar 1
			end tell

			set localWindowId to (id of front window of application "Terminal") as integer
			set theNewTab to new(localWindowId)
			set preferredName of theNewTab to tabName
			delay 1
			theNewTab's _setTabName(tabName)
			theNewTab
		end newTab
		*)

		on getDefaultProfile()
			tell application "System Events" to tell process "Terminal"
				try
					textUtil's stringAfter(title of menu item 1 of menu 1 of menu item 1 of menu 1 of menu bar item "Shell" of menu bar 1, "New Window with Profile - ")
				end try
			end tell
		end getDefaultProfile

		(* With test/s *)
		on getProfile()
			tell application "Terminal"
				name of current settings of selected tab of front window
			end tell
		end getProfile

		(* With test/s *)
		on setProfile(profileName)
			tell application "Terminal"
				script WaitBusy
					if busy of selected tab of appWindow is false then return true
				end script
				exec of retry on WaitBusy by 0.1
				activate

				set current settings of selected tab of appWindow to settings set profileName
			end tell
		end setProfile

		(* With test/s *)
		on focus()
			_focus(true)
		end focus

		on focusLast()
			_focus(false)
		end focusLast

		(* @ascending - why did we need this parameter again? *)
		on _focus(ascending)
			-- logger's debugf("ascending: {}", ascending)
			-- logger's debugf("window name: {}", name of my appWindow)
			tell application "System Events" to tell process "Terminal"
				try
					set windowMenu to first menu of menu bar item "Window" of first menu bar
				end try
				if ascending then
					click (first menu item of windowMenu whose title is equal to name of my appWindow)
				else
					click (last menu item of windowMenu whose title is equal to name of my appWindow)
				end if
			end tell
			activate application "Terminal"
		end _focus


		on dismissDialogue()
			focus()
			tell application "System Events" to tell process "Terminal"
				try
					click button "Terminate" of sheet 1 of window (name of my appWindow)
					logger's debug("Dismissed the dialogue")
				on error the error_message number the error_number
					logger's debug(error_message)
					logger's debug("I likely didn't find a dialog to dismiss ")
				end try
			end tell
		end dismissDialogue


		on hasDialogue()
			tell application "System Events" to tell process "Terminal"
				try
					return exists button "Terminate" of sheet 1 of window (name of my appWindow)
				end try
			end tell
			false
		end hasDialogue


		on isBash()
			if not hasProcess() then return false

			tell application "Terminal" to processes of selected tab of my appWindow contains "-bash"
		end isBash

		on isZsh()
			if not hasProcess() then return false

			tell application "Terminal"
				set termProcesses to processes of selected tab of my appWindow
			end tell

			set lastItem to last item of termProcesses

			termProcesses contains "-zsh" and {"com.docker.cli", "bash", "ssh"} does not contain the lastItem or lastItem contains "zsh"
			-- lastItem contains "zsh" -- fails when using awsume cli on MFA wait state
		end isZsh


		on hasLingeringCommand()
			if not hasProcess() then return false

			getLingeringCommand() is not missing value
		end hasLingeringCommand


		(*
			Checks most recent text in the buffer, and see if a command is waiting after the prompt to be executed.
			TODO:
			Edge case might be when not on shell prompt and the prompt character is present in the buffer.

			NOTE: Battle Scar. Nasty bug will freeze system if this don't work correctly because of the aggressive waitForShellPrompt.

			@returns missing value if there are no lingering commands.
		*)
		on getLingeringCommand()
			if not hasProcess() then return missing value

			set recentBuffer to getPromptText()
			if recentBuffer is missing value then return missing value

			if isBash() then
				if recentBuffer does not contain promptEndChar then return missing value
				if recentBuffer ends with my promptEndChar then return missing value
				return textUtil's substringFrom(recentBuffer, (textUtil's lastIndexOf(recentBuffer, my promptEndChar)) + 2)
			end if

			set dirName to getDirectoryName()
			-- logger's debugf("dirName: {}", dirName)

			if dirName is equal to std's getUsername() then set dirName to "~"
			-- logger's debugf("dirName: {}", dirName)

			ignoring case
				if recentBuffer ends with dirName then return missing value
			end ignoring

			regex's firstMatchInStringNoCase("(?<=" & dirName & "\\s%\\s)[\\w\\s-]+$", recentBuffer)
		end getLingeringCommand


		on clearLingeringCommand()
			if not hasProcess() then return

			set lingeringCommand to getLingeringCommand()
			if lingeringCommand is missing value then return

			set commandWords to count of words of lingeringCommand

			focus()
			set maxTry to 50 -- 5 / 0.1 = 5 seconds.
			repeat until getLingeringCommand() is missing value or maxTry is less than 0
				set maxTry to maxTry - 1
				kb's pressControlKey("w")
				delay 0.1
			end repeat
		end clearLingeringCommand


		on closeTab()
			tell application "Terminal" to close my appWindow
			if autoDismissDialogue and hasDialogue() then
				delay 0.2
				dismissDialogue()
			end if
		end closeTab


		(*
			@Deprecated: Move to #getTitle(). Confusing because the first tab
			title is also called window title which can mean the title of the
			Terminal window.

			@returns the value in the Window Title field (1st text field) when
			you view the inspector.
		*)
		(* With test/s *)
		on getWindowTitle()
			tell application "Terminal"
				custom title of selected tab of my appWindow
			end tell
		end getWindowTitle

		on getTitle()
			getWindowTitle()
		end getWindowTitle

		(* With test/s *)
		on setWindowTitle(newTitle)
			tell application "Terminal"
				set custom title of selected tab of my appWindow to newTitle
			end tell
		end setWindowTitle


		(*
			@returns the value in the Tab Title field (2nd text field) when you view the inspector.
		*)
		(* With test/s *)
		on getTabTitle()
			-- tell application "System Events" to tell process "Terminal"
			-- 	if exists (tab group "tab bar" of my appWindow) then
			-- 		title of radio button (my tabIndex) of tab group "tab bar" of my appWindow
			-- 	else
			-- 		my storedTabTitle
			-- 	end if
			-- end tell

			tell application "Terminal"
				set selectedTab to selected tab of my appWindow
			end tell
			tell application "System Events" to tell process "Terminal"
				title of selectedTab
			end tell
		end getTabTitle


		(* With test/s *)
		on setTabTitle(newTabTitle)
			tell application "System Events" to tell process "Terminal"
				set frontmost to true
				if not (exists window "Inspector") then
					try
						click menu item "Edit Title" of menu 1 of menu bar item "Shell" of menu bar 1
					end try
				end if
				set targetTextField to text field 2 of tab group 1 of window "Inspector"
				set the value of attribute "AXFocused" of targetTextField to true
				set the value of targetTextField to newTabTitle
				click (first button of window "Inspector" whose description is "close button")
			end tell
		end setTabTitle

		(*
			This is to improve flexibility when switching between zsh and bash,
			in zsh, window name contained the folder name as well.

			@Deprecated: Use getWindowTitle or getTabTitle instead.
		*)
		on getTabName()
			if isBash() then return name of appWindow

			set nameTokens to textUtil's split(name of appWindow, SEPARATOR)
			if (the number of items in nameTokens) is 0 then return missing value

			last item of nameTokens
		end getTabName


		on _setTabName(tabName as text)
			-- logger's debugf("Setting tab name to {}", tabName)
			script TabNameWaiter
				tell application "Terminal"
					if custom title of selected tab of appWindow is equal to tabName then return true
					set custom title of selected tab of appWindow to tabName
				end tell
			end script
			exec of retry on TabNameWaiter for 3
		end _setTabName

		on _refreshTabName()
			if not maintainName then return

			delay 1.5
			_setTabName(preferredName)
		end _refreshTabName
	end script

	tell application "Terminal"
		set appWindow of TerminalTabInstance to window id pWindowId
	end tell
	set |instance name| of TerminalTabInstance to the name of appWindow of TerminalTabInstance
	extOutput's decorate(TerminalTabInstance)
	extRun's decorate(result)
	extPath's decorate(result)
	extPrompt's decorate(result)
	decoratorLib's new(result)
	result's decorateByName("TerminalTabInstance")
end new


on getSelectedTabIndex()
	tell application "System Events" to tell process "Terminal"
		if not (exists (tab group "tab bar" of front window)) then return 1

		repeat with i from 1 to the count of radio buttons of tab group "tab bar" of front window
			if value of radio button i of tab group "tab bar" of front window is true then
				return i
			end if
		end repeat
	end tell
end getSelectedTabIndex

