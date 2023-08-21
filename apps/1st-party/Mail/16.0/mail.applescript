
use loggerFactory : script "logger-factory"

use spotScript : script "spot-test"

property logger : missing value


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "list"

	set cases to listUtil's splitByLine("
		Goto Favorite Folder
	")

	set spotLib to spotScript's new()
	set spot to spotLib's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then
		sut's gotoFolder("04 Updates")

	else if caseIndex is 2 then

	end if

	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)

	script MailInstance

		(*  *)
		on gotoFolder(folderName)
			tell application "System Events" to tell process "Mail"
				repeat with nextRow in rows of outline 1 of scroll area 1 of splitter group 1 of front window
					if get description of UI element 1 of nextRow contains folderName then
						set selected of nextRow to true
						exit repeat
					end if
				end repeat
			end tell
		end gotoFolder
	end script
end new