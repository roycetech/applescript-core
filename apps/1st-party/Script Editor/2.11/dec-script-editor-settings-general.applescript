(*
	@Purpose:
		Manipulate the Script Editor Settings > General tab.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh 'apps/1st-party/Script Editor/2.11/dec-script-editor-settings-general'

	@Created: Sat, May 24, 2025 at 07:35:00 AM
	@Last Modified: Sat, May 24, 2025 at 07:35:00 AM
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
		Manual: Set Show Script Menu On
		Manual: Set Show Script Menu Off
		Manual: Set Show Computer Scripts On
		Manual: Set Show Computer Scripts Off
		
		Manual: Set Show “tell” application menu ON
		Manual: Set Show “tell” application menu OFF
		Manual: Set Show inherited items ON
		Manual: Set Show inherited items OFF
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
	set sutLib to script "core/script-editor"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Script Menu On: {}", sut's isShowScriptMenu())
	logger's infof("Show Computer scripts On: {}", sut's isShowComputerScripts())
	logger's infof("Show tell application menu: {}", sut's isShowTellApplicationMenu())
	logger's infof("Show inherited items: {}", sut's isShowInheritedItems())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's setShowScriptMenuOn()
		
	else if caseIndex is 3 then
		sut's setShowScriptMenuOff()
		
	else if caseIndex is 4 then
		sut's setShowComputerScriptsOn()
		
	else if caseIndex is 5 then
		sut's setShowComputerScriptsOff()
		
	else if caseIndex is 6 then
		sut's setShowTellApplicationMenuOn()
		
	else if caseIndex is 7 then
		sut's setShowTellApplicationMenuOff()
		
	else if caseIndex is 8 then
		sut's setShowInheritedItemsOn()
		
	else if caseIndex is 9 then
		sut's setShowInheritedItemsOff()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ScriptEditorSettingsGeneralDecorator
		property parent : mainScript
		
		on isShowScriptMenu()
			_isSettingsCheckboxChecked("General", "Show Script menu in menu bar")
		end isShowScriptMenu
		
		on setShowScriptMenuOn()
			if isShowScriptMenu() then return
			
			_toggleSettingsCheckbox("General", "Show Script menu in menu bar")
		end setShowScriptMenuOn
		
		on setShowScriptMenuOff()
			if not isShowScriptMenu() then return
			
			_toggleSettingsCheckbox("General", "Show Script menu in menu bar")
		end setShowScriptMenuOff
		
		
		on isShowComputerScripts()
			_isSettingsCheckboxChecked("General", "Show Computer scripts")
		end isShowComputerScripts
		
		on setShowComputerScriptsOn()
			if isShowComputerScripts() then return
			
			_toggleSettingsCheckbox("General", "Show Computer scripts")
		end setShowComputerScriptsOn
		
		on setShowComputerScriptsOff()
			if not isShowComputerScripts() then return
			
			_toggleSettingsCheckbox("General", "Show Computer scripts")
		end setShowComputerScriptsOff
		
		
		on isShowTellApplicationMenu()
			_isSettingsCheckboxChecked("General", "Show “tell” application menu")
		end isShowTellApplicationMenu
		
		on setShowTellApplicationMenuOn()
			if isShowTellApplicationMenu() then return
			
			_toggleSettingsCheckbox("General", "Show “tell” application menu")
		end setShowTellApplicationMenuOn
		
		on setShowTellApplicationMenuOff()
			if not isShowTellApplicationMenu() then return
			
			_toggleSettingsCheckbox("General", "Show “tell” application menu")
		end setShowTellApplicationMenuOff
		
		
		on isShowInheritedItems()
			_isSettingsCheckboxChecked("General", "Show inherited items")
		end isShowInheritedItems
		
		on setShowInheritedItemsOn()
			if isShowInheritedItems() then return
			
			_toggleSettingsCheckbox("General", "Show inherited items")
		end setShowInheritedItemsOn
		
		on setShowInheritedItemsOff()
			if not isShowInheritedItems() then return
			
			_toggleSettingsCheckbox("General", "Show inherited items")
		end setShowInheritedItemsOff
		
	end script
end decorate
