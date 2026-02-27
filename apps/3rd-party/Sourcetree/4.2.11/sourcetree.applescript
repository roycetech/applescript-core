(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Sourcetree/4.2.11/sourcetree

	@Change Logs:
		Thu, Feb 26, 2026, at 05:35:40 PM - Added #getSelectedFilePath()
			Re-tested all spot cases (1-18)

	@Created: Monday, November 25, 2024 at 3:32:55 PM
	@Last Modified: 2026-02-27 13:14:11
*)
use loggerFactory : script "core/logger-factory"

use clipLib : script "core/clipboard"

property logger : missing value

property clip : missing value

property LABEL_UNSTAGED_FILES : "Unstaged files"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO:
		Manual: Trigger Menu Show Only
		Manual: Trigger Menu Files View
		Manual: Trigger Files View Sub menu (Single Column)
		Manual: Select first unstage file

		Manual: Select first file
		Manual: Select next file
		Manual: Select previous file
		Manual: Stage First Hunk
		Manual: Stage Selected File

		Manual: Toggle Push Changes Immediately
		Manual: Scroll down a page
		Manual: Scroll up a page
		Manual: Ignore White space
		Manual: Show White space

		Manual: Trigger Second Menu Button
		Manual: Select File - second
		Manual: Reveal selected file
		Dummy
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
	logger's infof("Commit message input focused: {}", sut's isCommitMessageFocused())
	logger's infof("Push changes immediately {}", sut's isPushChangesImmediately())

	activate application "Sourcetree"

	if caseIndex is 1 then
		logger's infof("Selected file path: {}", sut's getSelectedFilePath())

	else if caseIndex is 2 then
		sut's triggerMenuShowOnly()

	else if caseIndex is 3 then
		sut's triggerMenuFilesView()

	else if caseIndex is 4 then
		sut's triggerMenuFilesView()
		delay 0.2

		set sutSubmenuKeyword to "single column"
		-- set sutSubmenuKeyword to "multiple columns"
		-- set sutSubmenuKeyword to "Tree view"
		logger's debugf("sutSubmenuKeyword: {}", sutSubmenuKeyword)

		sut's selectFilesViewSubMenu(sutSubmenuKeyword)

	else if caseIndex is 5 then
		sut's selectFirstUnstagedFile()

	else if caseIndex is 6 then
		sut's selectFirstFile()

	else if caseIndex is 7 then
		sut's selectNextFile()

	else if caseIndex is 8 then
		sut's selectPreviousFile()

	else if caseIndex is 9 then
		sut's stageFirstHunk()

	else if caseIndex is 10 then
		sut's stageSelectedFile()

	else if caseIndex is 11 then
		sut's togglePushChangesImmediately()

	else if caseIndex is 12 then
		sut's scrollPageDown()

	else if caseIndex is 13 then
		sut's scrollPageUp()

	else if caseIndex is 14 then
		sut's setIgnoreWhiteSpace()

	else if caseIndex is 15 then
		sut's setShowWhiteSpace()

	else if caseIndex is 16 then
		set sutMenuItem to "Unicorn"
		set sutMenuItem to "Flat list (multiple columns)"
		logger's debugf("sutMenuItem: {}", sutMenuItem)

		-- sut's triggerSecondMenu(sutMenuItem)
		sut's triggerSecondMenu("Fluid staging")

	else if caseIndex is 17 then
		sut's selectFile(2)

	else if caseIndex is 18 then
		sut's revealSelectedFile()

	end if

	activate

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set clip to clipLib's new()

	script SourcetreeInstance
		(*
			WARNING: Triggers menu pop up.
		*)
		on getSelectedFilePath()
			tell application "System Events" to tell process "Sourcetree"
				set targetRow to missing value
				try
					set targetRow to first row of my _filesTable() whose selected is true
				end try
				if targetRow is missing value then
					logger's info("Target row could not be found")
					return missing value

				end if
			end tell

			(* Path inlined: this script runs in clip's context and cannot call _filesTable(). *)
			script CopyPathScript
				tell application "System Events" to tell process "Sourcetree"
					set menuUi to table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
					perform action 1 of menuUi
					delay 0.1
					click menu item "Copy Path To Clipboard" of menu 1 of menuUi
				end tell
			end script

			set filePath to clip's extract(CopyPathScript)
		end getSelectedFilePath


		(*
			@ menuItemTitle
				Flat list (single column)
				Flat list (multiple columns)
				Tree view
				No staging
				Fluid staging
				Split view staging
		*)
		on triggerSecondMenu(menuItemTitle)
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				set secondMenuButton to menu button 2 of my _toolbarGroup()
				click secondMenuButton
				click menu item menuItemTitle of menu 1 of secondMenuButton
			end tell

		end triggerSecondMenu


		on setIgnoreWhiteSpace()

			tell application "System Events" to tell process "Sourcetree"
				set whitespaceMenu to menu button 3 of my _toolbarGroup()
				click whitespaceMenu
				click menu item "Ignore whitespace" of menu 1 of whitespaceMenu
			end tell
		end setIgnoreWhiteSpace


		on setShowWhiteSpace()
			tell application "System Events" to tell process "Sourcetree"
				set whitespaceMenu to menu button 3 of my _toolbarGroup()
				click whitespaceMenu
				click menu item "Show whitespace" of menu 1 of whitespaceMenu
			end tell
		end setShowWhiteSpace

		on isCommitMessageFocused()
			if running of application "Sourcetree" is false then return false

			tell application "System Events" to tell process "Sourcetree"
				try
					return focused of text area 1 of my _commitScrollArea()
				end try
			end tell

			false
		end isCommitMessageFocused

		on scrollPageDown()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				click (first button of scroll bar 1 of my _diffScrollArea() whose description is "increment page button")
			end tell
		end scrollPageDown

		on scrollPageUp()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				click (first button of scroll bar 1 of my _diffScrollArea() whose description is "decrement page button")
			end tell
		end scrollPageUp

		on isPushChangesImmediately()
			if running of application "Sourcetree" is false then return false

			tell application "System Events" to tell process "Sourcetree"
				try
					return value of first checkbox of my _pushCheckboxSplitter() whose title starts with "Push changes immediately" is 1
				end try
			end tell

			false
		end isPushChangesImmediately


		(*
			The checkbox must already be visible for visual confirmation.
		*)
		on togglePushChangesImmediately()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click (first checkbox of my _pushCheckboxSplitter() whose title starts with "Push changes immediately")
				end try
			end tell
		end togglePushChangesImmediately


		on triggerMenuShowOnly()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click menu button 1 of my _toolbarGroup()
				end try
			end tell
		end triggerMenuShowOnly


		on triggerMenuFilesView()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click menu button 2 of my _toolbarGroup()
				end try
			end tell
		end triggerMenuFilesView


		on selectFilesViewSubMenu(titleKeyword)
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click (first menu item of menu 1 of menu button 2 of my _toolbarGroup() whose title contains titleKeyword)
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end selectFilesViewSubMenu


		on revealSelectedFile()
			set fileRows to _getFileRowsUI()
			if fileRows is missing value then return

			tell application "System Events" to tell process "Sourcetree"
				-- properties of button 1 of last UI Element of fileRows
				try
					first item of fileRows whose selected is true
					set ellipsisButton to the button 1 of last UI element of result
					click ellipsisButton
					delay 0.5
					click button "Show in Finder" of pop over 1 of ellipsisButton
				end try
				-- properties of result
			end tell
		end revealSelectedFile


		(* UI refs *)
		on _filesTable()
			tell application "System Events" to tell process "Sourcetree"
				return table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _filesTable

		on _toolbarGroup()
			tell application "System Events" to tell process "Sourcetree"
				return group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _toolbarGroup

		on _commitScrollArea()
			tell application "System Events" to tell process "Sourcetree"
				return scroll area 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _commitScrollArea

		on _diffScrollArea()
			tell application "System Events" to tell process "Sourcetree"
				return scroll area 2 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _diffScrollArea

		on _pushCheckboxSplitter()
			tell application "System Events" to tell process "Sourcetree"
				return splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _pushCheckboxSplitter

		on _getFileRowsUI()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					return rows of my _filesTable()
				end try
			end tell

			missing value
		end _getFileRowsUI


		(* Requires flat view. See #selectFilesViewSubMenu *)
		on selectFirstUnstagedFile()
			if running of application "Sourcetree" is false then return

			set unstagedLabelFound to false
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try

				repeat with nextRow in targetRows
					try
						if not unstagedLabelFound then
							if value of static text 1 of UI element 1 of nextRow is equal to my LABEL_UNSTAGED_FILES then
								set unstagedLabelFound to true
								-- log unstagedLabelFound
							end if

						else
							-- log "Selecting first row after the unstaged label..."
							set selected of nextRow to true
							exit repeat
						end if
					end try
				end repeat
			end tell
		end selectFirstUnstagedFile


		on selectFile(fileIndex)
			if running of application "Sourcetree" is false then return
			if fileIndex is less than 1 then return

			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try

				set selected of item (fileIndex + 1) of targetRows to true
			end tell
		end selectFile

		(*
		*)
		on selectFirstFile()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try

				set selected of second item of targetRows to true
			end tell
		end selectFirstFile


		(* Requires flat view. See #selectFilesViewSubMenu *)
		on selectLastFile()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try

				set selected of last item of targetRows to true
			end tell
		end selectLastFile


		on selectNextFile()
			if running of application "Sourcetree" is false then return

			set selectedFound to false
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try

				if selected of last item of targetRows is true then
					-- log "Selecting the first row"
					-- my selectFirstUnstagedFile()
					return
				end if

				repeat with nextRow in targetRows
					try
						if not selectedFound then
							if selected of nextRow then
								set selectedFound to true
								log selectedFound
							end if

						else
							log "Selecting first row after the selected row"
							set selected of nextRow to true
							exit repeat
						end if
					end try
				end repeat
			end tell
		end selectNextFile

		on selectPreviousFile()
			if running of application "Sourcetree" is false then return

			set selectedFound to false
			tell application "System Events" to tell process "Sourcetree"

				try
					set targetRows to rows of my _filesTable()
					set selectedRow to first item of targetRows whose selected is true
				on error the errorMessage number the errorNumber
					log errorMessage

					return
				end try
				log number of items in targetRows

				log selectedRow
				if selectedRow is not missing value then
					set selectedIndex to the value of attribute "AXIndex" of selectedRow
					log "seleced index: " & selectedIndex

				end if

				try
					set previousIsNotALabel to not (exists static text 1 of UI element 1 of item selectedIndex of targetRows)
					if previousIsNotALabel then
						log "selecting previous..."
						set selected of item selectedIndex of targetRows to true
					end if
				end try
			end tell
		end selectPreviousFile

		on stageFirstHunk()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click button "Stage hunk" of group 2 of group 1 of my _diffScrollArea()
				end try
			end tell
		end stageFirstHunk

		on stageSelectedFile()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
					set selectedRow to first item of targetRows whose selected is true
					click checkbox 1 of UI element 1 of selectedRow
				on error the errorMessage number the errorNumber
				end try
			end tell
		end stageSelectedFile
	end script
end new
