(*
    Script terminal.applescript.

	FOR REDESIGN:
		Currently configured for using a specific OMZ Theme.
	Dependent on your Terminal configuration for window/tab items.

	@Usage:
		use terminalLib : script "terminal"
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

	@Build:
		make compile-terminal

	@Known Issues:
		Breaks on macOS Ventura, when there is no existing Terminal window to launch from.

*)

use scripting additions

use script "Core Text Utilities"
use std : script "std"

use textUtil : script "string"
use listUtil : script "list"
use unic : script "unicodes"
use regex : script "regex"
use emoji : script "emoji"

use loggerFactory : script "logger-factory"
use retryLib : script "retry"
use windowLib : script "window"
use syseveLib : script "system-events"

use extOutput : script "dec-terminal-output"
use extRun : script "dec-terminal-run"
use extPath : script "dec-terminal-path"
use extPrompt : script "dec-terminal-prompt"

use spotScript : script "spot-test"

use overriderLib : script "overrider"

property logger : missing value
property retry : missing value
property winUtil : missing value
property syseve : missing value

-- property SEPARATOR : unic's SEPARATOR

-- set main to me

(* Used so we can distinguish between script handlers vs instance handlers with the same name. *)
property main : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then
	spotCheck()
end if

(*
	Not for unit test codes because we are visually checking window behavior.
	Transient snippets, delete code once verified.
*)
on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set skip of overrider to true
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

	loggerFactory's share(me, spotScript)

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
	set retry to retryLib's new()
	set winUtil to windowLib's new()
	set syseve to syseveLib's new()

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
			new(frontWinID)
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

			set targetName to textUtil's join({folderName, unic's SEPARATOR, theName}, "")
			logger's debugf("targetName: {}", targetName)
			tell application "Terminal"
				try
					-- if jada's isWorkMac() then
					-- 	set appWindow to first window whose name is equal to theName
					-- else
					set appWindow to first window whose name is equal to targetName
					-- end if
					return my new(id of appWindow)
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
					return my new(id of appWindow)
				end try
			end tell

			missing value
		end findTabEndingWith


		(* You are expected to be running a bash command on the terminal, so it is required you provide the first command. *)
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

			set theTab to new(windowId)
			theTab's _setTabName(tabName)

			theTab
		end newWindow


		-- Private Codes below =======================================================

		on new(pWindowId)
			tell application "Terminal"
				if not (exists window id pWindowId) then return missing value

				set localPromptEndChar to "$"
				tell application "Terminal"
					set termProcesses to processes of selected tab of window id pWindowId
					if last item of termProcesses is "zsh" then set localPromptEndChar to ")"
					if termProcesses contains "-zsh" then set localPromptEndChar to "%"
				end tell
			end tell

			script TerminalTabInstance
				property appWindow : missing value -- will be set to app window (not sys eve window)
				property |instance name| : missing value

				(* Will only for for bash and zsh, not for ohmyzsh. *)
				property promptEndChar : localPromptEndChar -- designed for bash only.
				property commandRunMax : 100
				property commandRetrySleepSeconds : 3
				property lastCommand : missing value
				property maintainName : false
				property preferredName : ""
				property windowId : pWindowId
				property recentOutputChars : 300

				(*
			User prompt has timestamp embedded. When refleshPromt is true, it
			will first send a blank command so the prompt is updated, then the
			actual command is sent next, so that execution time can be measured.
		*)
				property refreshPrompt : false

				on scrollToTop()
					tell application "System Events" to tell process "Terminal"
						try
							set value of scroll bar 1 of scroll area 1 of splitter group 1 of window (name of my appWindow) to 0
						end try
					end tell
				end scrollToTop

				on scrollToEnd()
					tell application "System Events" to tell process "Terminal"
						try
							set value of scroll bar 1 of scroll area 1 of splitter group 1 of window (name of my appWindow) to 1
						end try
					end tell
				end scrollToEnd

				on newWindow(bashCommand, windowName)
					main's newWindow(bashCommand, windowName)
				end newWindow

				(* Creates a new tab at the end of the window. *)
				on newTab(tabName as text)
					focus()
					tell application "System Events" to tell process "Terminal"
						click menu item "New Tab" of menu 1 of menu bar item "Shell" of menu bar 1
					end tell

					set localWindowId to (id of front window of application "Terminal") as integer
					set theNewTab to new(localWindowId)
					set preferredName of theNewTab to tabName
					delay 1
					theNewTab's _setTabName(tabName)
					theNewTab
				end newTab

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

				on focus()
					_focus(true)
				end focus

				on focusLast()
					_focus(false)
				end focusLast

				on _focus(ascending)
					logger's debugf("ascending: {}", ascending)
					logger's debugf("window name: {}", name of my appWindow)
					tell application "System Events" to tell process "Terminal"
						try
							set windowMenu to first menu of menu bar item "Window" of first menu bar
							if ascending then
								click (first menu item of windowMenu whose title is equal to name of my appWindow)
							else
								click (last menu item of windowMenu whose title is equal to name of my appWindow)
							end if
						end try
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

				on isBash()
					tell application "Terminal" to processes of selected tab of my appWindow contains "-bash"
				end isBash

				on isZsh()
					tell application "Terminal"
						set termProcesses to processes of selected tab of my appWindow
					end tell
					set lastItem to last item of termProcesses

					termProcesses contains "-zsh" and {"com.docker.cli", "bash", "ssh"} does not contain the lastItem or lastItem contains "zsh"
					-- lastItem contains "zsh" -- fails when using awsume cli on MFA wait state
				end isZsh

				(*
					Checks most recent text in the buffer, and see if a command is waiting after the prompt to be executed.
					TODO:
						Edge case might be when not on shell prompt and the prompt character is present in the buffer.
						Move this to "prompt" decorator.


					NOTE: Battle Scar. Nasty bug will freeze system if this don't work correctly because of the aggressive waitForShellPrompt.

					Test Cases:
						- Git Directory
						- Non-Git Directory

					@returns missing value if there are no lingering commands.
				*)
				on getLingeringCommand()
					set recentBuffer to getPromptText()
					if recentBuffer is missing value then return missing value

					if isBash() then
						if recentBuffer does not contain promptEndChar then return missing value
						if recentBuffer ends with my promptEndChar then return missing value
						return textUtil's substringFrom(recentBuffer, (textUtil's lastIndexOf(recentBuffer, my promptEndChar)) + 2)
					end if

					-- zsh
					set tokens to {unic's OMZ_ARROW, unic's OMZ_GIT_X}
					set gitPromptPattern to format {"{}  [0-9a-zA-Z_\\s-]+\\sgit:\\([a-zA-Z0-9/_\\.()-]+\\)(?: {})?\\s?", tokens}
					set gitPattern to gitPromptPattern & ".+$" -- with a typed command

					set promptGit to regex's matchesInString(gitPattern, recentBuffer)

					(*
						logger's debugf("gitPromptPattern: {}", gitPromptPattern)
						logger's debugf("gitPattern: {}", gitPattern)
						logger's debugf("promptGit: {}", promptGit)
						logger's debugf("recentBuffer: {}", recentBuffer)
					*)

					if regex's matchesInString(gitPattern, recentBuffer) then
						set lingeringCommand to regex's stringByReplacingMatchesInString(gitPromptPattern, recentBuffer, "")
						if lingeringCommand is "" then set lingeringCommand to missing value
						return lingeringCommand
					end if

					set dirName to getDirectoryName()
					-- logger's debugf("dirName: {}", dirName)

					if dirName is equal to std's getUsername() then set dirName to "~"
					-- logger's debugf("dirName: {}", dirName)

					ignoring case
						if recentBuffer ends with dirName then return missing value
					end ignoring

					regex's firstMatchInStringNoCase("(?<=" & dirName & "\\s)[\\w\\s]+$", recentBuffer)
				end getLingeringCommand


				on clearLingeringCommand()
					set lingeringCommand to getLingeringCommand()
					if lingeringCommand is missing value then return

					set commandWords to count of words of lingeringCommand

					focus()
					repeat until getLingeringCommand() is missing value
						tell application "System Events" to key code 13 using {control down} -- w
						delay 0.1
					end repeat
				end clearLingeringCommand


				on closeTab()
					tell application "Terminal" to close appWindow
				end closeTab


				(* This is to improve flexibility when switching between zsh and bash, in zsh, window name contained the folder name as well. *)
				on getTabName()
					if isBash() then return name of appWindow

					set nameTokens to textUtil's split(name of appWindow, unic's SEPARATOR)
					last item of nameTokens
				end getTabName


				on hasTabBar()
					set windowName to name of appWindow

					tell application "System Events" to tell process "Terminal"
						try
							tab group 1 of window windowName
							return true
						end try
					end tell
					false
				end hasTabBar


				on _setTabName(tabName as text)
					logger's debugf("Setting tab name to {}", tabName)
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

			set overrider to overriderLib's new()

			set |instance name| of TerminalTabInstance to the name of appWindow of TerminalTabInstance
			extOutput's decorate(TerminalTabInstance)
			extRun's decorate(result)
			extPath's decorate(result)
			extPrompt's decorate(result)

			overrider's applyMappedOverride(result)
		end new
	end script
end new
