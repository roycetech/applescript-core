(*
	@Purpose:


	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh apps/3rd-party/Marked/2.6.46/dec-marked-settings-preview

	@Created: Wed, May 28, 2025 at 03:23:50 PM
	@Last Modified: Wed, May 28, 2025 at 03:23:50 PM
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
		Manual: Set Dark Mode: ON
		Manual: Set Dark Mode: OFF
		Manual: Scroll to first edit: ON
		Manual: Scroll to first edit: OFF
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
	set sutLib to script "core/marked"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Dark mode checked: {}", sut's isDarkMode())
	logger's infof("Scroll to first edit: {}", sut's isScrollToFirstEdit())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setDarkModeOn()
		
	else if caseIndex is 3 then
		sut's setDarkModeOff()
		
	else if caseIndex is 4 then
		sut's setScrollToFirstEditOn()

	else if caseIndex is 5 then
		sut's setScrollToFirstEditOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script MarkedSettingsPreviewDecorator
		property parent : mainScript
		
		on isDarkMode()
			_isSettingsCheckboxChecked("Preview", "Dark Mode")
		end isDarkMode
		
		on setDarkModeOn()
			if not isDarkMode() then _toggleSettingsCheckbox("Preview", "Dark Mode")
		end setDarkModeOn
		
		on setDarkModeOff()
			if isDarkMode() then _toggleSettingsCheckbox("Preview", "Dark Mode")
		end setDarkModeOff
		
		
		on isScrollToFirstEdit()
			_isSettingsCheckboxChecked("Preview", "Scroll to first edit")
		end isScrollToFirstEdit
		
		on setScrollToFirstEditOn()
			if not isScrollToFirstEdit() then _toggleSettingsCheckbox("Preview", "Scroll to first edit")
		end setScrollToFirstEditOn
		
		on setScrollToFirstEditOff()
			if isScrollToFirstEdit() then _toggleSettingsCheckbox("Preview", "Scroll to first edit")
		end setScrollToFirstEditOff
	end script
end decorate
