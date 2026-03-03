(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Stream Deck/7.1.x/dec-stream-deck-dialog'

	@Created: Wed, Jan 28, 2026 at 04:42:47 PM
	@Last Modified: Wed, Jan 28, 2026 at 04:42:47 PM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Main
		Manual: Respond Cancel
		Manual: Respond Replace
		Manual: Set don't ask me again - ON
		Manual: Set don't ask me again - OFF
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
	
	logger's infof("Dialog replace present: {}", sut's isDialogReplacePresent())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's respondCancel()
		
	else if caseIndex is 3 then
		sut's respondReplace()
		
	else if caseIndex is 4 then
		sut's setDontAskMeAgainOn()
		
	else if caseIndex is 5 then
		sut's setDontAskMeAgainOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script StreamDeckDialogDecorator
		property parent : mainScript
		
		on setDontAskMeAgainOn()
			set replaceDialogWindow to getDialogWindow("Replace")
			if replaceDialogWindow is missing value then return
			
			tell application "System Events" to tell process "Stream Deck"
				try
					if value of checkbox 1 of replaceDialogWindow is 1 then return
					
					click checkbox 1 of replaceDialogWindow
				end try
			end tell
		end setDontAskMeAgainOn
		
		
		on setDontAskMeAgainOff()
			set replaceDialogWindow to getDialogWindow("Replace")
			if replaceDialogWindow is missing value then return
			
			tell application "System Events" to tell process "Stream Deck"
				try
					if value of checkbox 1 of replaceDialogWindow is 0 then return
					
					click checkbox 1 of replaceDialogWindow
				end try
			end tell
		end setDontAskMeAgainOff
		
		
		on respondCancel()
			set replaceDialogWindow to getDialogWindow("Replace")
			if replaceDialogWindow is missing value then return
			
			tell application "System Events" to tell process "Stream Deck"
				try
					click button "Cancel" of group 1 of replaceDialogWindow
				end try
			end tell
		end respondCancel
		
		
		on respondReplace()
			set replaceDialogWindow to getDialogWindow("Replace")
			if replaceDialogWindow is missing value then return
			
			tell application "System Events" to tell process "Stream Deck"
				try
					click button "Replace" of group 1 of replaceDialogWindow
				end try
			end tell
		end respondReplace
		
		
		on getDialogWindow(dialogOptionTitle)
			if running of application "Elgato Stream Deck" is false then return missing value
			
			tell application "System Events" to tell process "Stream Deck"
				try
					return first window whose description is "dialog" and title is "" and title of button 1 of group 1 is dialogOptionTitle
				end try
			end tell
			
			missing value
		end getDialogWindow
		
		
		on isDialogReplacePresent()
			set dialogWindow to getDialogWindow("Replace")
			dialogWindow is not missing value
		end isDialogReplacePresent
	end script
end decorate
