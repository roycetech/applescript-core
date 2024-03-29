(*
	@Project:
		applescript-core

	@Build:
		make install-git-kraken

	@Version:
		9.8.2

	@Created: September 4, 2023 3:58 PM
	@Last Modified: 2023-10-06 10:27:36
	@Change Logs:
		September 25, 2023 10:08 PM - v9.8.2 Pop up address has changed.
*)

use loggerFactory : script "core/logger-factory"

use textUtil : script "core/string"
use decoratorLib : script "core/decorator"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set sut to new()


	set selectedResourcePath to sut's getSelectedResourcePath()
	logger's infof("Selected resource path: {}", selectedResourcePath)
	set currentRepoKey to sut's getCurrentRepositoryName()
	logger's infof("Current repository name: {}", currentRepoKey)

	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	script GitKrakenInstance
		on getSelectedResourcePath()
			if running of application "GitKraken" is false then return missing value

			tell application "System Events" to tell process "GitKraken"
				if (count of windows) is 0 then return missing value

				(* Could not determine the selected resource from the list, so use the alternative below. *)
				-- set sut to static texts of group 1 of group 1 of group 1 of table 1 of group 1 of group 1 of group 4 of group 1 of group 1 of group 1 of group 4 of group 5 of group 2 of group 1 of UI element 1 of front window

				set sut to static texts of group 1 of group 1 of group 3 of group 5 of group 2 of group 1 of UI element 1 of front window
				set pathBuilder to ""
				repeat with nextStaticText in sut
					set pathBuilder to pathBuilder & value of nextStaticText
				end repeat
				pathBuilder
			end tell
		end getSelectedResourcePath


		on getCurrentRepositoryName()
			if running of application "GitKraken" is false then return missing value

			tell application "System Events" to tell process "GitKraken"
				if (count of windows) is 0 then return missing value

				try
					set sut to pop up button 1 of group 1 of group 1 of group 1 of group 1 of group 4 of group 2 of group 1 of UI element 1 of front window
				on error -- Seems it likes to tango between group 1 and 2 without even a version update so let's try both.
					set sut to pop up button 1 of group 2 of group 1 of group 1 of group 1 of group 4 of group 2 of group 1 of UI element 1 of front window
				end try
				textUtil's stringAfter(name of sut, "repository ")
			end tell
		end getCurrentRepositoryName


		on clickStageFile()
			if running of application "GitKraken" is false then false

			tell application "System Events" to tell process "GitKraken"
				if (count of windows) is 0 then return false

				try
					button 1 of group 1 of group 3 of group 5 of group 2 of group 1 of UI element 1 of front window
					return true
				end try
			end tell

			false
		end clickStageFile
	end script
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
