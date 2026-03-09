(*
	@Project:
		applescript-core

	NOTES:
		Cursor prefers "Side Bar" over Sidebar.
		Cursor dialog should refer to window 1, instead of the usual window "Open" etc.

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Cursor/2.5/cursor

	@Created: Wed, Feb 25, 2026 at 12:27:36 PM
	@Last Modified: 2026-03-04 13:01:56
*)
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use retryLib : script "core/retry"

property logger : missing value
property retry : missing value

property kb : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP
		Manual: Show secondary side bar
		Manual: Hide secondary side bar
		Manual: Show minimap
		Manual: Hide minimap

		Manual: Single file layout
		Manual: Open file path via UI
		Manual: Switch Project Tab
		Manual: Open file via Command O
		Dummy
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
	logger's infof("Secondary side bar visible: {}", sut's isSecondarySideBarVisible())
	logger's infof("Project name: {}", sut's getCurrentProjectName())
	logger's infof("Is minimap visible: {}", sut's isMinimapVisible())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's showSecondarySideBar()

	else if caseIndex is 3 then
		sut's hideSecondarySideBar()

	else if caseIndex is 4 then
		sut's showMinimap()

	else if caseIndex is 5 then
		sut's hideMinimap()

	else if caseIndex is 6 then
		sut's singleFileLayout()

	else if caseIndex is 7 then
		set sutFilePath to "/etc/hosts"
		logger's debugf("sutFilePath: {}", sutFilePath)

		sut's openFilePathViaUI(sutFilePath)

	else if caseIndex is 8 then
		set sutProjectTab to "Unicorn"
		-- set sutProjectTab to "applescript-core"
		logger's debugf("sutProjectTab: {}", sutProjectTab)

		sut's switchProjectTab(sutProjectTab)

	else if caseIndex is 9 then
		set sutFilePath to "~/Projects/@roycetech/applescript-hub/src/apps/Sublime Text/Script Menu - Open in Cursor.applescript"
		logger's debugf("sutFilePath: {}", sutFilePath)

		sut's openFilePathViaCommandO(sutFilePath)
	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set decCursorLayout to script "core/dec-cursor-layout"
	set decCursorCurrentFile to script "core/dec-cursor-current-file"
	set kb to kbLib's new()

	set appWithFileDialogLib to script "core/abstract-app-with-file-dialog"
	set appWithFileDialog to appWithFileDialogLib's new("Cursor")
	set appWithFileDialog's doSetDialogTypeAsWindowReference to false

	script CursorInstance
		property parent : appWithFileDialog

		on switchProjectTab(projectTabKeyword)
			if running of application "Cursor" is false then return

			tell application "System Events" to tell process "Cursor"
				try
					click (first radio button of tab group 1 of window 1 whose title contains projectTabKeyword)
				end try
			end tell
		end switchProjectTab


		on getCurrentProjectName()
			if running of application "Cursor" is false then return missing value

			tell application "System Events" to tell process "Cursor"
				set windowTitle to title of window 1
			end tell

			if windowTitle does not contain unic's SEPARATOR then return windowTitle

			textUtil's split(result, unic's SEPARATOR)
			item 2 of result
		end getCurrentProjectName


		on _focusApp()
			tell application "System Events" to tell process "Cursor"
				if frontmost is false then set frontmost to true
			end tell
		end _focusApp

		(*
			NOTE: Not reliable on long paths.
		*)
		on openFilePathViaUI(filePath)
			if running of application "Cursor" is false then return

			_focusApp()
			kb's pressCommandKey("p")
			delay 0.5

			_focusApp()
			kb's typeText(filePath)
			-- delay 2
			delay 1

			_focusApp()
			kb's pressKey(return)
		end openFilePathViaUI


		on openFilePathViaCommandO(filePath)
			set fileUtil to script "core/file"
			if not fileUtil's posixFilePathExists(filePath) then return

			_focusApp()
			kb's pressCommandKey("o")
			delay 0.5

			fileDialogGoToFolder()
			fileDialogEnterPath(filePath)
			fileDialogAcceptFoundPath()
			fileDialogChooseSelectionWithAction("Open")
		end openFilePathViaCommandO

		(*
			@Overrides
		*)
		on fileDialogSheetUI()
			tell application "System Events" to tell process "Cursor"
				try
					return sheet 1 of window 1

				end try
			end tell
			missing value
		end fileDialogSheetUI


		on isMinimapVisible()
			if running of application "Cursor" is false then return false

			tell application "System Events" to tell process "Cursor"
				try
					menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
					return value of attribute "AXMenuItemMarkChar" of result is equal to unic's MENU_CHECK

				end try
			end tell

			false
		end isMinimapVisible


		(*  *)
		on showMinimap()
			if running of application "Cursor" is false then return
			if isMinimapVisible() then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showMinimap


		(*  *)
		on hideMinimap()
			if running of application "Cursor" is false then return
			if isMinimapVisible() is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideMinimap


		on showSecondarySideBar()
			if running of application "Cursor" is false then return
			if isSecondarySideBarVisible() then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus

				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showSecondarySideBar


		on hideSecondarySideBar()
			if running of application "Cursor" is false then return
			if isSecondarySideBarVisible() is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideSecondarySideBar


		on isSecondarySideBarVisible()
			if running of application "Cursor" is false then return false

			tell application "System Events" to tell process "Cursor"
				try
					menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
					return value of attribute "AXMenuItemMarkChar" of result is equal to unic's MENU_CHECK

				end try
			end tell

			false
		end isSecondarySideBarVisible
	end script
	decCursorLayout's decorate(result)
	decCursorCurrentFile's decorate(result)
end new
