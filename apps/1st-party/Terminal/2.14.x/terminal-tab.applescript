(*
	This is a wrapper to a Terminal tab's instance.

	@Version:
		2.14.x for macOS Sonoma

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Terminal/2.14.x/terminal-tab

	@Created: Sunday, January 28, 2024 at 2:35:54 PM
	@Last Modified: 2024-04-29 10:54:02
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

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value
property retry : missing value

property SEPARATOR : unic's SEPARATOR

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	if running of application "Terminal" is false then
		activate application "Terminal"
		delay 1
	end if
	tell application "Terminal" to set frontWinID to id of first window

	set sut to new(frontWinID)
	logger's infof("Name: {}", name of sut)
	logger's infof("Lingering Command: {}", sut's getLingeringCommand())
	-- logger's infof("Has Tab Bar: {}", sut's hasTabBar())
	logger's infof("Tab Name: {}", sut's getTabName())
	logger's infof("POSIX Path: {}", sut's getPosixPath())

	(* Manually test: zsh, bash, docker, sftp, redis-cli. *)
	logger's infof("Is Shell Prompt: {}", sut's isShellPrompt())
	logger's infof("Is Bash: {}", sut's isBash())
	logger's infof("Is Zsh: {}", sut's isZsh())
	logger's infof("Is SSH: {}", sut's isSSH())
	logger's infof("Prompt Text: {}", sut's getPromptText())

	logger's infof("Prompt: {}", sut's getPrompt())
	logger's infof("Last Output: {}", sut's getLastOutput()) -- BROKEN on @rt

	if caseIndex is 1 then

	else if caseIndex is 2 then

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

		on hasDuplicatedName()

		end hasDuplicatedName


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

		(* @ascending - why did we need this paramter again? *)
		on _focus(ascending)
			logger's debugf("ascending: {}", ascending)
			logger's debugf("window name: {}", name of my appWindow)
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
			set gitPromptPattern to format {"{}  [0-9a-zA-Z_\\s-\\.]+\\sgit:\\([a-zA-Z0-9/_\\.()-]+\\)(?: {})?\\s?", tokens}
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

			regex's firstMatchInStringNoCase("(?<=" & dirName & "\\s)[\\w\\s-]+$", recentBuffer)
		end getLingeringCommand


		on clearLingeringCommand()
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
			tell application "Terminal" to close appWindow
		end closeTab


		(*
			This is to improve flexibility when switching between zsh and bash,
			in zsh, window name contained the folder name as well.
		*)
		on getTabName()
			if isBash() then return name of appWindow

			set nameTokens to textUtil's split(name of appWindow, SEPARATOR)
			last item of nameTokens
		end getTabName


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
	set |instance name| of TerminalTabInstance to the name of appWindow of TerminalTabInstance
	extOutput's decorate(TerminalTabInstance)
	extRun's decorate(result)
	extPath's decorate(result)
	extPrompt's decorate(result)
	decoratorLib's new(result)
	result's decorate()
end new
