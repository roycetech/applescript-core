(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/1st-party/Stickies/10.3/stickies

	@Created: Wed, Jul 16, 2025 at 08:54:28 AM
	@Last Modified: 2025-07-31 07:54:56
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: New Note
		Manual: Change Color
		Manual: Set Text
		Manual: Window: Collapse

		Manual: Window Expand
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set processLib to script "core/process"
	set sutProcess to processLib's new("Stickies")

	set sut to new()
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's newNote()

	else if caseIndex is 3 then
		set sutColor to "unicorn"
		set sutColor to "Blue"
		logger's debugf("sutColor: {}", sutColor)

		sut's setColorOfFrontmost(sutColor)

	else if caseIndex is 4 then
		sut's newNote()
		sut's setColorOfFrontmost("Blue")
		sut's setTextContent("Hello World")
		sut's resizeToOneLiner()
		sut's clearTextContent()
		sut's moveWindowPosition({322, 802})

	else if caseIndex is 5 then
		sut's menuWindowCollapse()

	else if caseIndex is 6 then
		sut's menuWindowExpand()
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script StickiesInstance
		on menuWindowCollapse()
			if running of application "Stickies" is false then return

			tell application "System Events" to tell process "Stickies"
				set frontmost to true
				try
					click menu item "Collapse" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end menuWindowCollapse

		on menuWindowExpand()
			if running of application "Stickies" is false then return

			tell application "System Events" to tell process "Stickies"
				set frontmost to true
				try
					click menu item "Expand" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end menuWindowCollapse

		on newNote()
			if running of application "Stickies" is false then
				activate application "Stickies"
			end if

			tell application "System Events" to tell process "Stickies"
				set frontmost to true
				try
					click menu item "New Note" of menu 1 of menu bar item "File" of menu bar 1
				end try
			end tell
			delay 1 -- Let's wait for the new note to be the frontmost.
		end newNote

		on setColorOfFrontmost(newColorKeyword)
			if running of application "Stickies" is false then return

			tell application "System Events" to tell process "Stickies"
				set frontmost to true
				try
					click (first menu item of menu 1 of menu bar item "Color" of menu bar 1 whose title contains newColorKeyword)
				end try
			end tell
		end setColorOfFrontmost

		on setTextContent(textContent)
			if running of application "Stickies" is false then return

			tell application "System Events" to tell process "Stickies"
				set value of text area 1 of scroll area 1 of last window to textContent
			end tell
		end setTextContent

		on clearTextContent()
			setTextContent("")
		end clearTextContent

		on resizeToOneLiner()
			if running of application "Stickies" is false then return

			tell application "System Events" to tell process "Stickies"
				set size of last window to {512, 30}
			end tell
		end resizeToOneLiner

		on moveWindowPosition(targetPosition)
			tell application "System Events" to tell process "Stickies"
				set position of last window to targetPosition
			end tell
		end moveWindowPosition
	end script
end new
