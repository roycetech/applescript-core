(*
	@Project:
		applescript-core

	@Created: September 4, 2023 3:58 PM
	@Last Modified: 2023-09-04 19:46:48
*)

use loggerFactory : script "logger-factory"

use textUtil : script "string"
use decoratorLib : script "decorator"

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

				set sut to pop up button 1 of group 2 of group 1 of group 1 of group 1 of group 4 of group 2 of group 1 of UI element 1 of front window
				textUtil's stringAfter(name of sut, "repository ")
			end tell
		end getCurrentRepositoryName
	end script
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
