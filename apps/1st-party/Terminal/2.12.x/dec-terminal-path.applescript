(*
	@Build:
		make build-lib SOURCE=apps/1st-party/Terminal/2.12.x/dec-terminal-path

	@Last Modified: 2023-09-25 14:57:56
*)

use scripting additions

use std : script "core/std"

use textUtil : script "core/string"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		NOOP
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set terminalLib to script "core/terminal"
	set terminal to terminalLib's new()
	set sut to terminal's getFrontTab()
	set sut to decorate(sut)

	-- Cases: Home, User subdir, Non-user; with/out command
	logger's infof("Posix Path: {}", sut's getPosixPath())

	-- Cases: Home, User subdir, Non-user; with/out command
	logger's infof("Is User Path: {}", sut's isUserPath())

	-- Cases: Home, User subdir, Non-user; with/out command
	logger's infof("Is Home Path: {}", sut's isAtHomePath())

	-- Cases: Home, User subdir, Non-user; with/out command
	logger's infof("Home Relative Path: {}", sut's getHomeRelativePath())

	-- Cases: Home, User subdir, Non-user; with/out command
	logger's infof("Directory Name: {}", sut's getDirectoryName())

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else if caseIndex is 4 then

	else if caseIndex is 5 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


on decorate(termTabScript)
	loggerFactory's inject(me)

	script TerminalTabInstance
		property parent : termTabScript
		property _posixPath : missing value

		on getPosixPath()
			if _posixPath is not missing value then return _posixPath

			tell application "Terminal"
				set termProcesses to processes of selected tab of my appWindow
			end tell

			set isZsh to termProcesses contains "-zsh"
			set shellType to "bash"
			if isZsh then set shellType to "zsh"

			tell application "Terminal"
				set frontTty to tty of selected tab of my appWindow
			end tell

			tell application "Terminal"
				set my _posixPath to do shell script "lsof -a -p `lsof -a -c zsh -u $USER -d 0 -n | tail -n +2 | awk '{if($NF==\"" & (tty of front tab of front window) & "\"){print $2}}'` -d cwd -n | tail -n +2 | awk '{$1=$2=$3=$4=$5=$6=$7=$8=\"\"; print $0}' | xargs"
			end tell

			if _posixPath is equal to "" then
				tell application "System Events" to tell process "Terminal"
					logger's debug("Alternative way of fetching the current Terminal tab directory")
					set _posixPath to textUtil's stringAfter(value of attribute "AXDocument" of front window, "file://")
					if _posixPath ends with "/" then set _posixPath to text 1 thru -2 of _posixPath
				end tell
			end if

			_posixPath
		end getPosixPath


		(*
			@returns true if current path is under the current user.
		*)
		on isUserPath()
			set posixPath to getPosixPath()
			posixPath starts with "/Users"
		end isUserPath


		on isAtHomePath()
			set posixPath to getPosixPath()
			posixPath is equal to "/Users/" & std's getUsername()
		end isAtHomePath


		(*
			@returns:
				- missing value when not under user directory.
				- empty string if on home directory
				- subpath relative to the user home directory.
		*)
		on getHomeRelativePath()
			if not isUserPath() then return missing value

			set posixPath to getPosixPath()
			if posixPath does not start with "/Users" then return missing value

			set homePath to "/Users/" & std's getUsername()
			if posixPath is equal to homePath then return ""

			set tempText to textUtil's replace(posixPath, homePath, "")
			set noStartingSlash to text 2 thru -1 of tempText
			noStartingSlash
		end getHomeRelativePath


		on getDirectoryName()
			set tokens to textUtil's split(getPosixPath(), "/")
			last item of tokens
		end getDirectoryName
	end script
end decorate
