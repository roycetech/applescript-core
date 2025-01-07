(*
	This adds selection state handlers to finder-tab.applescript.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Finder/15.2/dec-finder-selection

	@Created: Tuesday, December 31, 2024 at 6:06:32 PM
	@Last Modified: 2025-01-03 08:53:15
	@Change Logs:
*)
use textUtil : script "core/string"
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
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

	-- activate application ""
	set sutLib to script "core/finder"
	set sut to sutLib's new()
	set sut to decorate(sut)

	(* Manual: Selection (None, One, Multi) *)
	logger's infof("Selected Objects: {}", sut's getSelection())
	logger's infof("First Selected File Path: {}", sut's getFirstSelectionPath())
	logger's infof("First Selected File URL: {}", sut's getFirstSelectionURL())
	logger's infof("First Selected Filename: {}", sut's getFirstSelectionName())
	logger's infof("First Selected Object Type: {}", sut's getFirstSelectionObjectType())

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else if caseIndex is 3 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script FinderSelectionDecorator
		property parent : mainScript

		(* @returns the selected objects. Empty list if none is selected. *)
		on getSelection()
			tell application "Finder"
				selection
			end tell
		end getSelection


		on getFirstSelectionPath()
			textUtil's replace(textUtil's stringAfter(getFirstSelectionURL(), "file://"), "%20", " ")
		end getFirstSelectionPath


		on getFirstSelectionURL()
			set userSelection to getSelection()
			if (the number of items in userSelection) is 0 then return missing value

			set firstSelection to first item of userSelection
			tell application "Finder"
				URL of firstSelection
			end tell
		end getFirstSelectionURL


		on getFirstSelectionName()
			set userSelection to getSelection()
			if (the number of items in userSelection) is 0 then return missing value

			set firstSelection to first item of userSelection
			name of firstSelection
		end getFirstSelectionName


		(*
			@returns
				folder - if folder is selected.
					.app - returns "app".
				file - the file extension
		*)
		on getFirstSelectionObjectType()
			set selectedFile to missing value
			try
				set selectedFile to first item of getSelection()
			end try
			if selectedFile is missing value then return missing value

			set filename to name of selectedFile
			if class of selectedFile as text is equal to "folder" then
				if filename ends with ".app" then return "app"
				return "folder"
			end if

			set filenameTokens to textUtil's split(filename, ".")

			last item of filenameTokens
		end getFirstSelectionObjectType
	end script
end decorate
