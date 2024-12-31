(*

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/decorators/dec-preview-markup

	@Created: Wednesday, December 4, 2024 at 7:39:09 AM
	@Last Modified: 2024-12-31 19:33:47
	@Change Logs:
*)

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value
property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		NOOP:
		Manual: Toggle markup toolbar
		Manual: Show markup toolbar
		Manual: Hide markup toolbar
		Manual: Trigger Shapes

		Manual: Shape Popover
		Manual: Insert Text
		Manual: Switch foreground color to red
		Manual: Switch foreground color to green
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	-- activate application ""
	set sutLib to script "core/preview"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Markup toolbar active: {}", sut's isMarkupToolbarChecked())

	if caseIndex is 2 then
		sut's toggleMarkupToolbar()

	else if caseIndex is 3 then
		sut's showMarkupToolbar()

	else if caseIndex is 4 then
		sut's hideMarkupToolbar()

	else if caseIndex is 5 then
		sut's triggerShapes()

	else if caseIndex is 6 then
		sut's triggerShapes()

		set sutShape to "unicorn"
		set sutShape to "Rounded Rectangle"

		sut's clickShapePopover(sutShape)

	else if caseIndex is 7 then
		sut's insertText()

	else if caseIndex is 8 then
		sut's switchToRedForeground()

	else if caseIndex is 9 then
		sut's switchToGreenForeground()

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	set kb to kbLib's new()

	script PreviewMarkupDecorator
		property parent : mainScript

		on showMarkupToolbar()
			if running of application "Preview" is false then return
			if isMarkupToolbarChecked() then return

			toggleMarkupToolbar()
		end showMarkupToolbar


		on hideMarkupToolbar()
			if running of application "Preview" is false then return
			if not isMarkupToolbarChecked() then return

			toggleMarkupToolbar()
		end hideMarkupToolbar


		on toggleMarkupToolbar()
			if running of application "Preview" is false then return false

			tell application "System Events" to tell process "Preview"
				try
					click (first checkbox of toolbar 1 of front window whose description is "Markup")
				end try
			end tell
		end toggleMarkupToolbar


		on isMarkupToolbarChecked()
			if running of application "Preview" is false then return false

			tell application "System Events" to tell process "Preview"
				try
					return value of (first checkbox of toolbar 1 of front window whose description is "Markup") is 1
				end try

				false
			end tell
		end isMarkupToolbarChecked


		on triggerShapes()
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				try
					set editToolbar to first toolbar of front window whose description is "edit toolbar"
					click (first button of editToolbar whose description is "Shapes")
				on error the errorMessage number the errorNumber
					log errorMessage

				end try
			end tell
		end triggerShapes


		on dismissShapes()
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				try
					set editToolbar to first toolbar of front window whose description is "edit toolbar"
					-- click pop over 1 of (first button of editToolbar whose description is "Shapes")
					-- click editToolbar
					-- blech!
					set frontmost to true
					delay 0.1
					kb's pressKey("esc")
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end dismissShapes

		(*
			@buttonDescription - Line, Line with Arrow, Rectangle, Rounded Rectangle,
				Oval, Speech Bubble, Star, Polygon, Mask, and Loupe
		*)
		on clickShapePopover(buttonDescription)
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				try
					set editToolbar to first toolbar of front window whose description is "edit toolbar"
					set targetButton to first button of editToolbar whose description is "Shapes"
					click targetButton
					delay 0.1
					set buttonContainer to first UI element of (UI element 1 of pop over 1 of targetButton) whose description of button 1 is buttonDescription
					click button 1 of buttonContainer
				on error the errorMessage number the errorNumber
					-- 					my triggerShapes() -- re-trigger to dismiss, DIDN'T WORK
					my dismissShapes()
					logger's warn(errorMessage)
				end try
			end tell
		end clickShapePopover


		on insertText()
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				try
					set editToolbar to first toolbar of front window whose description is "edit toolbar"
					click (first button of editToolbar whose description is "Text")
				end try
			end tell
		end insertText



		on triggerForegroundColorPopup()
			if running of application "Preview" is false then return

			tell application "System Events" to tell process "Preview"
				try
					set editToolbar to first toolbar of front window whose description is "edit toolbar"
					set targetWell to color well 1 of editToolbar
					click targetWell
					delay 0.1
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell

			targetWell
		end triggerForegroundColorPopup


		on switchToRedForeground()
			if running of application "Preview" is false then return

			set targetWell to triggerForegroundColorPopup()

			tell application "System Events" to tell process "Preview"
				set editToolbar to first toolbar of front window whose description is "edit toolbar"
				-- Stranger Things. UI Browser says UI Element 2 but it didn't work.
				click button 1 of UI element 3 of pop over 1 of color well 1 of editToolbar

			end tell
		end switchToRedForeground


		on switchToGreenForeground()
			if running of application "Preview" is false then return

			set targetWell to triggerForegroundColorPopup()

			tell application "System Events" to tell process "Preview"
				set editToolbar to first toolbar of front window whose description is "edit toolbar"
				-- Stranger Things. UI Browser says UI Element 2 but it didn't work.
				click button 4 of UI element 3 of pop over 1 of color well 1 of editToolbar
			end tell
		end switchToGreenForeground
	end script
end decorate
