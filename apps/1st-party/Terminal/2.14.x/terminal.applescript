(*
    Script terminal.applescript.

	@Version:
		v 2.14.x for macOS Sonoma

	@Usage:
		use terminalLib : script "core/terminal"
		property terminal : terminalLib's new()
		set terminalTab to terminal's findTabWithName("project-dir-name", "tab_name")
		set shellResult to terminalTab's runShell("echo yo", "temp key")

	@WARNING: This was originally designed for a very specific user profile.
		Terminal shells need to be configured specifically to be handled properly.
		Window name is used to locate the tabs thus we need to do the following to make locating tabs simple:

	@Plists:
		config-user
			Terminal Tab Decorators - Manually managed by user for the supported decorators.

	@Prerequisites:
		Under Profiles:
			Uncheck "Dimensions"
			Uncheck "Active process name" - May need to work with process name.

		Under Tab:
			Uncheck all except "Show activity indicator"

	@TODO:
		Refactor using uniform handler names.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal

	@Known Issues:
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use emoji : script "core/emoji"
use unic : script "core/unicodes"
use dockLib : script "core/dock"

use loggerFactory : script "core/logger-factory"

use terminalTabLib : script "core/terminal-tab"
use winUtilLib : script "core/window"
use syseveLib : script "core/system-events"
use retryLib : script "core/retry"

property logger : missing value
property winUtil : missing value
property syseve : missing value
property retry : missing value
property dock : missing value

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
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Front Tab and Info
		Manual: New Tab, Find
		Focus
		Last Output - Broken
		Clear - Shell/Non-Shell

		Manual: Clear lingering command
		Wait for Prompt
		Manual: New Window (Not running, no window, has window)
		Manual: Set Tab Name
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
	set frontTab to sut's getFrontTab()
	
	logger's infof("Name: {}", name of frontTab)
	logger's infof("Has Tab Bar: {}", sut's hasTabBar())
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
	
	logger's infof("Settings dialog present: {}", sut's isSettingsWindowPresent())
	
	if caseIndex is 1 then
		
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
		frontTab's clearLingeringCommand()
		
	else if caseIndex is 7 then
		sut's waitForPrompt()
		
	else if caseIndex is 9 then
		sut's newWindow("echo case 9", "spot")
		
		
	else if caseIndex is 12 then
		frontTab's _setTabName("Spot Tab " & emoji's TUBE)
		
		
		
	else if caseIndex is 16 then
		set spotTabName to "AS " & emoji's WORK
		set spotTab to sut's newWindow("ls", "Main")
		
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set winUtil to winUtilLib's new()
	set syseve to syseveLib's new()
	set retry to retryLib's new()
	set dock to dockLib's new()
	
	set decSettings to script "core/dec-terminal-settings"
	set decSettingsGeneral to script "core/dec-terminal-settings-general"
	set decSettingsProfile to script "core/dec-terminal-settings-profile"
	set decSettingsProfileWindow to script "core/dec-terminal-settings-profile-window"
	set decSettingsProfileKeyboard to script "core/dec-terminal-settings-profile-keyboard"
	set decTerminalTabFinder to script "core/dec-terminal_tab-finder"
	
	script TerminalInstance
		on getWindowsCount()
			if running of application "Terminal" is false then return 0
			
			tell application "System Events" to tell process "Terminal"
				count of windows
			end tell
		end getWindowsCount
		
		
		on getFrontTab()
			if running of application "Terminal" is false then return missing value
			
			tell application "System Events" to tell process "Terminal"
				if (count of windows) is 0 then return missing value	
			end tell

			tell application "Terminal"
				set frontWinID to id of first window
			end tell
			terminalTabLib's new(frontWinID)
		end getFrontTab
		
		
		on confirmTerminateActiveTab()
			tell application "System Events" to tell process "Terminal"
				try
					click button "Terminate" of sheet 1 of front window
				end try
			end tell
		end confirmTerminateActiveTab
		
		
		(* @Deprecated use getFrontTab. *)
		on getFrontMostInstance()
			getFrontTab()
		end getFrontMostInstance
				
		
		on hasTabBar()
			if winUtil's hasWindow("Terminal") is false then return false
			
			tell application "System Events" to tell process "Terminal"
				try
					tab group 1 of front window
					return true
				end try
			end tell
			false
		end hasTabBar
		
		(*
			Launches a new terminal window and set as frontmost.
			@returns TerminalTabInstance
		*)
		on newWindow(bashCommand, tabName)
			if running of application "Terminal" then
				if (count of windows of application "Terminal") is 0 then
					_newWindow_noWindow(bashCommand)
				else
					_newWindow_hasWindow(bashCommand)
				end if
			else
				_newWindow_appNotRunning(bashCommand)
			end if
			
			set theTab to terminalTabLib's new(result)
			theTab's _setTabName(tabName)
			
			theTab
		end newWindow
		
		(*
			@returns windowId
		*)
		on _newWindow_appNotRunning(bashCommand)
			-- logger's debug("_newWindow_appNotRunning")
			tell application "Terminal"
				-- Do not use do script "" because it results in a double window.
				activate
				if (the count of windows) is 0 then dock's clickApp("Terminal")
				set windowId to id of front window as integer
				my _waitTerminalReady()
				if bashCommand is not missing value then do script bashCommand in window id windowId
			end tell
			windowId
		end _newWindow_appNotRunning
		
		
		(*
			NOTE: Starts running the command after the "Last Login" text is detected from the terminal.
		*)
		on _newWindow_noWindow(bashCommand)
			-- logger's debug("_newWindow_noWindow")
			tell application "Terminal" to do script ""
			_waitTerminalReady()
			tell application "Terminal"
				if bashCommand is not missing value then do script bashCommand in front window
				set windowId to id of front window as integer
			end tell
			tell application "System Events" to tell process "Terminal" to set frontmost to true
			windowId
		end _newWindow_noWindow
		
		
		(* Test Cases:
			System Settings:
				Prefer tabs when opening documents: FullScreen (default)
				Prefer tabs when opening documents: Always Open in Tabs
		*)
		on _newWindow_hasWindow(bashCommand)
			-- logger's debug("_newWindow_hasWindow")
			
			tell application "System Events" to tell process "Terminal"
				set initialWindowCount to count of windows
				click menu item 1 of menu 1 of menu item "New Window" of menu 1 of menu bar item "Shell" of menu bar 1
				set newWindowCount to count of windows
			end tell
			set alwaysTabbed to initialWindowCount is equal to newWindowCount
			-- logger's debugf("alwaysTabbed: {}", alwaysTabbed) -- System Settings: Prefer tabs when opening documents: Always
			
			_waitTerminalReady()
			if alwaysTabbed then
				tell application "System Events" to tell process "Terminal"
					click menu item "Move Tab to New Window" of menu 1 of menu bar item "Window" of menu bar 1
				end tell
			end if
			
			_autoUpdateFrontTab()
			tell application "Terminal"
				if bashCommand is not missing value then do script bashCommand in front window
				id of front window as integer
			end tell
		end _newWindow_hasWindow
		
		(*
			After launching a new terminal window, it waits so that you only issue the command once the prompt is present. No consequence but for vanity.
		*)
		on _waitTerminalReady()
			script WindowWaiter
				tell application "Terminal"
					if exists (front window) then
						set tabContents to the contents of tab 1 of front window
						set terminalReady to not busy of tab1 of front window and tabContents starts with "Last login" -- Processing the contents directly after retrieving it causes heartache
					end if
				end tell
				if terminalReady then
					-- logger's debug("Terminal is ready!")
					tell application "System Events" to tell process "Terminal"
						set frontmost to true
					end tell
					return true
				end if
			end script
			exec of retry on result for 20 by 0.2
			if result is missing value then return missing value
		end _waitTerminalReady
		
		on _autoUpdateFrontTab()
			tell application "Terminal"
				if (contents of selected tab of front window as text) contains "Would you like to update?" then
					do script "Y" in front window
					
					set maxWait to 30
					repeat until (contents of selected tab of front window as text) contains "has been updated" or maxWait is less than 0
						delay 1
						set maxWait to maxWait - 1
					end repeat
				end if
			end tell
			
		end _autoUpdateFrontTab
	end script
	
	decSettings's decorate(result)
	decSettingsGeneral's decorate(result)
	decSettingsProfile's decorate(result)
	decSettingsProfileWindow's decorate(result)
	decSettingsProfileKeyboard's decorate(result)
	decTerminalTabFinder's decorate(result)
end new

