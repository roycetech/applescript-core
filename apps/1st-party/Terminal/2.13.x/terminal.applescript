(*
    Script terminal.applescript.

	FOR REDESIGN:
		Currently configured for using a specific OMZ Theme.
	Dependent on your Terminal configuration for window/tab items.

	@Version:
		macOS Ventura

	@Usage:
		use terminalLib : script "core/terminal"
		property terminal : terminalLib's new()
		set foundTab to terminal's findTabWithName("project-dir-name", "tab_name")
		set shellResult to foundTab's runShell("echo yo", "temp key")

	@WARNING: This was originally designed for a very specific user profile.
		Terminal shells need to be configured specifically to be handled properly.
		Window name is used to locate the tabs thus we need to do the following to make locating tabs simple:

	@Plists:
		config-user
			Terminal Tab Decorators - Manually managed by user for the supported decorators.

	@Prerequisites:
		Under Profiles:
			Uncheck "Dimensions"
			Uncheck "Active process name"

		Under Tab:
			Uncheck all except "Show activity indicator"

	@Project:
		applescript-core

	@Build:
		make build-terminal

	@Known Issues:
		Breaks on macOS Ventura, when there is no existing Terminal window to launch from.

*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use listUtil : script "core/list"
use emoji : script "core/emoji"

use loggerFactory : script "core/logger-factory"

use terminalTabLib : script "core/terminal-tab"
use winUtilLib : script "core/window"
use syseveLib : script "core/system-events"
use retryLib : script "core/retry"

use spotScript : script "core/spot-test"

property logger : missing value
property winUtil : missing value
property syseve : missing value
property retry : missing value

(* Used so we can distinguish between script handlers vs instance handlers with the same name. *)
property main : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

(*
	Not for unit test codes because we are visually checking window behavior.
	Transient snippets, delete code once verified.
*)
on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Manual: Front Tab and Info
		Manual: New Tab, Find
		Focus
		Last Output - Broken
		Clear - Shell/Non-Shell

		Manual: Clear lingering command
		Wait for Prompt
		Find Tab - applescript logs
		New Window
		Find Tab - BSS Bug

		Find Tab with Title
		Manual: Set Tab Name
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	set frontTab to sut's getFrontTab()

	if caseIndex is 1 then
		logger's infof("Name: {}", name of frontTab)
		logger's infof("Has Tab Bar: {}", frontTab's hasTabBar())
		logger's infof("Tab Name: {}", frontTab's getTabName())
		logger's infof("Posix Path: {}", frontTab's getPosixPath())
		logger's infof("Lingering Command: {}", frontTab's getLingeringCommand())

		(* Manually test: zsh, bash, docker, sftp, redis-cli. *)
		logger's infof("Is Shell Prompt: {}", frontTab's isShellPrompt())
		logger's infof("Is Bash: {}", frontTab's isBash())
		logger's infof("Is Zsh: {}", frontTab's isZsh())
		logger's infof("Is SSH: {}", frontTab's isSSH())
		logger's infof("Prompt Text: {}", frontTab's getPromptText())
		logger's infof("Prompt: {}", frontTab's getPrompt())
		logger's infof("Last Output: {}", frontTab's getLastOutput()) -- BROKEN on @rt

	else if caseIndex is 2 then
		set spotTab to sut's newWindow("ls", "Main")
		spotTab's setProfile("Ocean")
		set spotTab2Name to "oc " & emoji's WORK
		set secondTab to spotTab's newTab(spotTab2Name)
		set foundTab to sut's findTabWithName(std's getUsername(), spotTab2Name)
		if foundTab is missing value then
			logger's info("Searched tab was not found")
		else
			spotTab's focus()
			-- foundTab's focus()
		end if

	else if caseIndex is 3 then



	else if caseIndex is 4 then

	else if caseIndex is 5 then
		frontTab's focus()

	else if caseIndex is 6 then

	else if caseIndex is 9 then

	else if caseIndex is 10 then

	else if caseIndex is 11 then

	else if caseIndex is 12 then
		frontTab's _setTabName("Spot Tab " & emoji's TUBE)

	else if caseIndex is 13 then
		frontTab's clearLingeringCommand()

	else if caseIndex is 14 then
		sut's waitForPrompt()

	else if caseIndex is 15 then
		log sut's findTabWithName("AppleScript", "applescript logs")
		log sut's findTabWithName("AppleScript", "AS " & emoji's WORK)

	else if caseIndex is 16 then
		set spotTabName to "AS " & emoji's WORK
		set spotTab to sut's newWindow("ls", "Main")

	else if caseIndex is 17 then
		(* Manually open a tab on the user home directory and name it as "spot <construction_sign_emoji>"*)
		set spotTabName to "spot " & emoji's WORK
		set foundTab to sut's findTabWithName(std's getUsername(), spotTabName)
		if foundTab is missing value then
			logger's info("Tab was not found")
		else
			logger's info("Tab was found")

		end if

	else if caseIndex is 18 then
		set foundTab to sut's findTabEndingWith("MBSS " & emoji's WORK)
		if foundTab is not missing value then
			foundTab's focus()
		end if
	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set winUtil to winUtilLib's new()
	set syseve to syseveLib's new()
	set retry to retryLib's new()

	script TerminalInstance
		on getFrontTab()
			getFrontMostInstance()
		end getFrontTab


		on confirmTerminateActiveTab()
			tell application "System Events" to tell process "Terminal"
				try
					click button "Terminate" of sheet 1 of front window
				end try
			end tell
		end confirmTerminateActiveTab


		on getFrontMostInstance()
			if running of application "Terminal" is false then return missing value

			tell application "Terminal" to set frontWinID to id of first window
			terminalTabLib's new(frontWinID)
		end getFrontMostInstance


		(* @return  missing value of tab is not found. TabInstance *)
		on findTabWithName(folderName, theName)
			if winUtil's hasWindow("Terminal") is false then return missing value

			-- logger's debugf("theName: {}", theName)
			-- logger's debugf("folderName: {}", folderName)
			-- log textUtil's join({folderName, separator, theName}, "")

			-- tell application "System Events" to tell process "Terminal" -- Check first if found in the same space.
			-- 	try
			-- 		set syseveWindow to first window whose name contains theName or name contains folderName
			-- 	on error the errorMessage number the errorNumber
			-- 		return missing value
			-- 	end try
			-- end tell

			set targetName to textUtil's join({folderName, SEPARATOR, theName}, "")
			logger's debugf("targetName: {}", targetName)
			tell application "Terminal"
				try
					-- if jada's isWorkMac() then
					-- 	set appWindow to first window whose name is equal to theName
					-- else
					set appWindow to first window whose name is equal to targetName
					-- end if
					return terminalTabLib's new(id of appWindow)
				end try
			end tell

			missing value
		end findTabWithName


		(*
			Useful for finding by tab title.
			@return  missing value of tab is not found. TabInstance
		*)
		on findTabEndingWith(titleEnding)
			if winUtil's hasWindow("Terminal") is false then return missing value

			tell application "Terminal"
				try
					set appWindow to first window whose name ends with titleEnding
					return terminalTabLib's new(id of appWindow)
				end try
			end tell

			missing value
		end findTabEndingWith


		(*
			You are expected to be running a bash command on the terminal, so it is required you provide the first command.
			@returns TerminalTabInstance
		*)
		on newWindow(bashCommand, tabName)
			if running of application "Terminal" then
				-- this tell script is required when you configure your System Preferences - General to always open in tabs.
				tell application "System Events" to tell process "Terminal"
					set currentWindowName to name of front window
					set origPosition to position of front window
					set origSize to size of front window

					click menu item "New Tab" of menu 1 of menu bar item "Shell" of menu bar 1
					delay 1.5 -- Does not work without the delay
					click menu item "Move Tab to New Window" of menu 1 of menu bar item "Window" of menu bar 1

					set newWindowName to name of front window
					set windowMenu to first menu of menu bar item "Window" of first menu bar
					click (first menu item of windowMenu whose title is equal to currentWindowName)
					set orginatingWindow to window currentWindowName
					set position of orginatingWindow to origPosition
					set size of orginatingWindow to origSize
					click (first menu item of windowMenu whose title is equal to newWindowName)
				end tell

				tell application "Terminal"
					if (contents of selected tab of front window as text) contains "Would you like to update?" then
						do script "Y" in front window

						repeat until (contents of selected tab of front window as text) contains "has been updated"
							delay 1
						end repeat
					end if

					do script bashCommand in front window
					set windowId to id of front window as integer
				end tell
			else
				tell application "Terminal"
					activate
					set windowId to id of front window as integer
					do script bashCommand in window id windowId
				end tell
			end if

			set theTab to terminalTab's (windowId)
			theTab's _setTabName(tabName)

			theTab
		end newWindow
	end script
end new

