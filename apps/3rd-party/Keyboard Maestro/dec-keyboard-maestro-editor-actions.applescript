(*
	@Purpose:
		This decorator contains actions-related handlers.  This was moved out of 
		the editor decorator to further reduce the scope.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Keyboard Maestro/dec-keyboard-maestro-editor-actions'

	@Created: Wednesday, August 14, 2024 at 5:53:03 PM
	@Last Modified: Wednesday, August 14, 2024 at 5:53:03 PM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"

property logger : missing value

property MENU_ALL : "All Actions"


if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitByLine("
		Main
		Manual: Toggle Edit
		Manual: Set macro name (un/focused)
		Manual: Show Actions Window
		Manual: Hide Actions Window

		Manual: Scroll Actions Pane
		Manual: Manual Insert Action
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	-- activate application ""
	set sutLib to script "core/keyboard-maestro"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Focused Type: {}", sut's getFocusedType())
	logger's infof("Editable: {}", sut's isEditable())
	logger's infof("Actions window present: {}", sut's isActionsWindowPresent())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's toggleEditable()
		
	else if caseIndex is 3 then
		sut's setMacroName("Spot Check Macro")
		
	else if caseIndex is 4 then
		sut's showActions()
		
	else if caseIndex is 5 then
		sut's hideActions()
		
	else if caseIndex is 6 then
		sut's scrollActionsPane(0) -- top
		-- sut's scrollActionsPane(1) -- bottom
		
	else if caseIndex is 7 then
		sut's insertAction("Keyboard Maestro", "Comment")
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script KeyboardMaestroEditorDecorator
		property parent : mainScript
		property show_action_retry_max : 3
		
		on isEditable()
			if running of application "Keyboard Maestro" is false then return false
			
			tell application "System Events" to tell process "Keyboard Maestro"
				value of checkbox "Edit" of my getEditorWindow() is 1
			end tell
		end isEditable
		
		
		on toggleEditable()
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				click checkbox "Edit" of my getEditorWindow()
			end tell
		end toggleEditable
		
		
		on setMacroName(newMacroName)
			if running of application "Keyboard Maestro" is false then
				logger's info("Cannot set macro name, Keyboard Maestro is not running")
				return
			end if
			if not isEditable() then
				logger's info("Cannot set macro name, Keyboard Maestro is not in Edit mode")
				return
			end if
			
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set macroNameTextField to text field 1 of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow()
				set value of macroNameTextField to newMacroName
			end tell
		end setMacroName
		
		
		(*  *)
		on focusActionCategory(categoryName)
			if running of application "Keyboard Maestro" is false then return
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					tell application "System Events" to tell process "Keyboard Maestro"
						click group categoryName of scroll area 1 of splitter group 1 of window "New Action"
					end tell
				end try
			end tell
		end focusActionCategory
		
		
		(* @Warning - Grabs app focus *)
		on showActions()
			if running of application "Keyboard Maestro" is false then return
			tell application "System Events" to tell process "Keyboard Maestro"
				if exists (window "New Action") then return
			end tell
			
			set retry to retryLib's new()
			script NewActionWindowWaiter
				tell application "System Events" to tell process "Keyboard Maestro"
					set frontmostOrigState to frontmost
					set frontmost to true -- REQUIRED!
					log frontmostOrigState
					try
						click menu item "Show Actions" of menu 1 of menu bar item "Actions" of menu bar 1
					end try
					if exists (window "New Action") then
						
						if frontmost is not equal to frontmostOrigState then
							set frontmost to frontmostOrigState -- DOES NOT WORK.
						end if
						return true
					end if
				end tell
			end script
			exec of retry on result for show_action_retry_max
		end showActions
		
		(* @Warning - Grabs app focus *)
		on hideActions()
			if running of application "Keyboard Maestro" is false then return
			tell application "System Events" to tell process "Keyboard Maestro"
				if not (exists (window "New Action")) then return
			end tell
			
			tell application "System Events" to tell process "Keyboard Maestro"
				set frontmostOrigState to frontmost
				set frontmost to true -- REQUIRED!
				
				try
					click menu item "Hide Actions" of menu 1 of menu bar item "Actions" of menu bar 1
				end try
				
				if frontmost is not equal to frontmostOrigState then set frontmost to frontmostOrigState -- DID NOT WORK.
			end tell
		end hideActions
		
		
		on isActionsWindowPresent()
			if running of application "Keyboard Maestro" is false then return false
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					return exists (window "New Action")
				end try
			end tell
			false
		end isActionsWindowPresent
		
		(*
			Insert a new action via the menu "Edit".
		
			@ middleMenu - missing value defaults to "All Actions" which is slow.
		*)
		on insertAction(middleMenu, menuItemKeyword)
			set actualMiddleMenu to middleMenu
			if actualMiddleMenu is missing value then set actualMiddleMenu to MENU_ALL
			
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					click (first menu item of menu 1 of menu item actualMiddleMenu of menu 1 of menu item "Insert Action" of menu 1 of menu bar item "Edit" of menu bar 1 whose title contains menuItemKeyword)
				end try
			end tell
		end insertAction
		
		
		on scrollActionsPane(zeroToOne)
			tell application "System Events" to tell process "Keyboard Maestro"
				try
					set value of value indicator 1 of scroll bar 1 of scroll area 3 of splitter group 1 of group 6 of my getEditorWindow() to zeroToOne
				end try -- Ignore if the scroll bar does not exist.
			end tell
			delay 0.1
		end scrollActionsPane
	end script
end decorate
