(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Stream Deck/6.9.1/dec-stream-deck-button'

	@Created: Wed, Oct 01, 2025 at 01:25:28 PM
	@Last Modified: Wed, Oct 01, 2025 at 01:25:28 PM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"
use kbLib : script "core/keyboard"

property logger : missing value

property cliclick : missing value
property kb : missing value

property ATTR_ID_TEXT_EDIT : "ESDStreamDeckApplication.MainWindow.centralWidget.leftFrame.mainStack.CanvasView.ESDCanvasSplitter.ESDPropertyInspector.PropertyInspectorBase.textEditButton"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Resize window for coordinates scripting
		Manual: Select Button
		Manual: Trigger Text
		Manual: Local Integration: Toggle Show Title

		Manual: Local Integration: Hide Title
		Manual: Local Integration: Show Title		
		Dummy
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
	
	-- activate application ""
	set sutLib to script "core/stream-deck"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Is button selected: {}", sut's isButtonSelected())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's resizeEditorWindowToMinimum()
		
	else if caseIndex is 3 then
		set sutColumn to 1
		set sutColumn to 4
		-- set sutColumn to 8
		logger's debugf("sutColumn: {}", sutColumn)
		
		set sutRow to 1
		set sutRow to 2
		-- set sutRow to 3
		-- set sutRow to 4
		logger's debugf("sutRow: {}", sutRow)
		sut's clickAtButton(sutColumn, sutRow)
		
	else if caseIndex is 4 then
		if not sut's isButtonSelected() then
			logger's warn("No button is currently selected. Please select one manually.")
		else
			sut's triggerText()
			
			-- logger's infof("Is show title: {}", sut's isShowTitle())
			-- sut's toggleShowTitle()
		end if
		-- kb's pressKey("esc")
		
		
	else if caseIndex is 5 then
		sut's triggerText()
		sut's toggleShowTitle()
		
	else if caseIndex is 6 then
		sut's hideTitle()
		
	else if caseIndex is 7 then
		sut's showTitle()
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	set kb to kbLib's new()
	
	script StreamDeckButtonDecorator
		property parent : mainScript
		
		property gridColumns : 8
		property gridRows : 4 
		
		(*
			WARNING:
				Acquires focus and resizes the window.
				
		*)
		on clickAtButton(column, row)
			if running of application "Elgato Stream Deck" is false then return
			if column is greater than gridColumns then return
			if row is greater than gridRows then return
			if column * row is less than 1 then return
			
			resizeEditorWindowToMinimum()
			if gridColumns is not 8 and gridRows is not 4 then error "Current grid layout is not yet implemented"
			
			if gridColumns is 8 then
				set columnMultiplier to 55
			end if
			if gridRows is 4 then
				set rowMultiplier to 55
			end if
			
			set computedFromLeft to 40 + columnMultiplier * column
			logger's debugf("computedFromLeft: {}", computedFromLeft)
			
			set computedFromTop to 130 + rowMultiplier * row
			logger's debugf("computedFromTop: {}", computedFromTop)
			
			tell application "System Events" to tell process "Stream Deck"
				set frontmost to true
				delay 0.1
				lclickRelative of cliclick at window "Stream Deck" given fromLeft:computedFromLeft, fromTop:computedFromTop
			end tell
			
		end clickAtButton
		
		
		(*
			Use the minimum for predictable scripting via UI coordinates.
		*)
		on resizeEditorWindowToMinimum()
			if running of application "Elgato Stream Deck" is false then return
			
			tell application "System Events" to tell process "Stream Deck"
				set size of window "Stream Deck" to {840, 768}
			end tell
		end resizeEditorWindowToMinimum
		
		(*
			Requires a key selected. TODO: Move to its own script.
		
			Use keyboard esc to cancel.
			WARNING: Acquires window focus.
		*)
		on triggerText()
			if running of application "Elgato Stream Deck" is false then return
			if not isButtonSelected() then return
			
			tell application "System Events" to tell process "Stream Deck"
				set frontmost to true
				delay 0.1
				try
					set textDropDown to first button of splitter group 1 of group 1 of front window whose value of attribute "AXIdentifier" is ATTR_ID_TEXT_EDIT
					click textDropDown
				end try
			end tell
			delay 0.5
		end triggerText
		
		
		(*
			Requires that the text modal is already visible, otherwise it returns missing value
		*)
		on isShowTitle()
			if not isTextDialogPresent() then return missing value
			
			tell application "System Events" to tell process "Stream Deck"
				-- set frontmost to true
				-- delay 0.1
				value of checkbox "Show Title" of window 1 is 1
			end tell
		end isShowTitle
		
		
		on isButtonSelected()
			if running of application "Elgato Stream Deck" is false then return false
			
			tell application "System Events" to tell process "Stream Deck"
				exists button 4 of splitter group 1 of group 1 of window "Stream Deck"
			end tell
		end isButtonSelected
		
		
		on hideTitle()
			if running of application "Elgato Stream Deck" is false then return
			if not isButtonSelected() then return
			
			if not isTextDialogPresent() then triggerText()
			if not isShowTitle() then
				kb's pressKey("esc")
				return
			end if
			
			toggleShowTitle()
			kb's pressKey("esc")
		end hideTitle
		
		
		on showTitle()
			if running of application "Elgato Stream Deck" is false then return
			if not isButtonSelected() then return
			
			if not isTextDialogPresent() then triggerText()
			if isShowTitle() then
				kb's pressKey("esc")
				return
			end if
			
			toggleShowTitle()
			kb's pressKey("esc")
		end showTitle
		
		
		on isTextDialogPresent()
			if running of application "Elgato Stream Deck" is false then return
			
			tell application "System Events" to tell process "Stream Deck"
				exists (checkbox "Show Title" of window 1)
			end tell
		end isTextDialogPresent
		
		
		(*
			Text options must already  be visible.
		*)
		on toggleShowTitle()
			if running of application "Elgato Stream Deck" is false then return
			
			set titleShown to isShowTitle()
			tell application "System Events" to tell process "Stream Deck"
				set frontmost to true
				delay 0.1
				
				(*
				click checkbox "Show Title" of window 1
				if titleShown then
					set newState to 0
				else
					set newState to 1
				end if
				set value of checkbox "Show Title" of window 1 to newState -- Click isn't enough for this noob app.
				*)
			end tell
			
			tell application "System Events" to tell process "Stream Deck"
				window 1
			end tell
			lclickRelative of cliclick at result given fromTop:50, fromLeft:25
			delay 0.1
		end toggleShowTitle
	end script
end decorate
