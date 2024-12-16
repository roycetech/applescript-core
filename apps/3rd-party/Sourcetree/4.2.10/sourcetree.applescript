(*
	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Sourcetree/4.2.10/sourcetree

	@Created: Monday, November 25, 2024 at 3:32:55 PM
	@Last Modified: 2024-11-26 09:00:42
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

property LABEL_UNSTAGED_FILES : "Unstaged files"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		INFO
		Manual: Trigger Menu Show Only
		Manual: Trigger Menu Files View
		Manual: Trigger Files View Submenu (Single Column)
		Manual: Select first unstage file

		Manual: Select first file
		Manual: Select next file
		Manual: Select previous file
		Manual: Stage First Hunk
		Manual: Stage Selected File
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's triggerMenuShowOnly()

	else if caseIndex is 3 then
		sut's triggerMenuFilesView()

	else if caseIndex is 4 then
		sut's triggerMenuFilesView()
		delay 0.2

		set sutSubmenuKeyword to "single column"
		set sutSubmenuKeyword to "multiple columns"
		-- set sutSubmenuKeyword to "Tree view"
		logger's debugf("sutSubmenuKeyword: {}", sutSubmenuKeyword)

		sut's selectFilesViewSubMenu(sutSubmenuKeyword)

	else if caseIndex is 5 then
		sut's selectFirstUnstagedFile()

	else if caseIndex is 6 then
		sut's selectLastFile()

	else if caseIndex is 7 then
		sut's selectNextFile()

	else if caseIndex is 8 then
		sut's selectPreviousFile()

	else if caseIndex is 9 then
		sut's stageFirstHunk()

	else if caseIndex is 10 then
		sut's stageSelectedFile()

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)

	script SourcetreeInstance
		on triggerMenuShowOnly()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click menu button 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
				end try
			end tell
		end triggerMenuShowOnly

		on triggerMenuFilesView()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click menu button 2 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
				end try
			end tell
		end triggerMenuFilesView

		on selectFilesViewSubMenu(titleKeyword)
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					click (first menu item of menu 1 of menu button 2 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window whose title contains titleKeyword)
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end selectFilesViewSubMenu

		(* Requires flat view. See #selectFilesViewSubMenu *)
		on selectFirstUnstagedFile()
			if running of application "Sourcetree" is false then return

			set unstagedLabelFound to false
			tell application "System Events" to tell process "Sourcetree"
				-- set frontmost to true
				try
					set targetRows to rows of table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
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

		(* Requires flat view. See #selectFilesViewSubMenu *)
		on selectLastFile()
			if running of application "Sourcetree" is false then return

			set unstagedLabelFound to false
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
				end try

				set selected of last item of targetRows to true
			end tell
		end selectLastFile

		on selectNextFile()
			if running of application "Sourcetree" is false then return

			set selectedFound to false
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
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
					set targetRows to rows of table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
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
					click button "Stage hunk" of group 2 of group 1 of scroll area 2 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
				end try
			end tell
		end stageFirstHunk

		on stageSelectedFile()
			if running of application "Sourcetree" is false then return

			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
					set selectedRow to first item of targetRows whose selected is true
					click checkbox 1 of UI element 1 of selectedRow
				on error the errorMessage number the errorNumber
				end try
			end tell
		end stageSelectedFile
	end script
end new
