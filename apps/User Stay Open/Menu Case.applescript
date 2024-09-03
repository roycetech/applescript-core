(*
	@Manual Deployment:
		Run "Create Menu App.app" while this script is loaded in Script Editor.

	@Optional:
		Create the app "Run Script Editor 2.app" to automatically trigger run after 
		selecting a test case.

	@Project:
		applescript-core 

	@Known Issues:
		Upon cases change, the menu items gets duplicated, but gets fixed after 
		a few seconds.
		Could not export as app as of June 27, 2023 2:50 PM.

	Refreshes menu automatically every 5.
	NOTE: On Option+click, must hold option longer for the handler to detect it.
*)

use framework "Foundation"
use framework "AppKit"
use framework "Cocoa"

use script "core/Text Utilities"
use scripting additions

property StatusItem : missing value
property selectedMenu : ""
property defaults : class "NSUserDefaults"
property internalMenuItem : class "NSMenuItem"
property externalMenuItem : class "NSMenuItem"
property newMenu : class "NSMenu"

use std : script "core/std"

use textUtil : script "core/string"
use listUtil : script "core/list"
use emoji : script "core/emoji"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"
use speechLib : script "core/speech"
use mapLib : script "core/map"
use switchLib : script "core/switch"
use plutilLib : script "core/plutil"

use spotScript : script "core/spot-test"

property logger : missing value
property speech : missing value
property plutil : missing value
property session : missing value

property isSpot : false

property idleSeconds : 5
property cases : {}
property caseId : missing value
property caseIndex : 1
property autoIncrement : false

loggerFactory's injectBasic(me)
logger's start()

set plutil to plutilLib's new()
set session to plutil's new("session")
set speech to speechLib's new()

set spotLib to spotScript's new()

set currentSessionCaseIndex to session's getValue("Current Case Index")
spotLib's setSessionCaseIndex(currentSessionCaseIndex)
set my caseId to session's getString("Case ID")
set my cases to session's getList("Case Labels")

set spotLib to missing value

set isSpot to {"Script Editor", "Script Debugger"} contains the name of current application


if isSpot then
	idle {}
else
	makeStatusBar()
	
	try
		makeMenus()
	end try
end if

logger's finish()


on makeStatusBar()
	set bar to current application's NSStatusBar's systemStatusBar
	set StatusItem to bar's statusItemWithLength:-1.0
	
	set currentCaseIndex to session's getInt("Current Case Index")
	StatusItem's setTitle:("C:" & currentCaseIndex)
	
	set newMenu to current application's NSMenu's alloc()'s initWithTitle:"Custom"
	newMenu's setDelegate:me
	StatusItem's setMenu:newMenu
end makeStatusBar


on clearMenuItems()
	repeat while (newMenu's numberOfItems() > 0)
		newMenu's removeItemAtIndex:0
	end repeat
end clearMenuItems


on makeMenus()
	clearMenuItems()
	-- newMenu's removeAllItems() -- Causes brief duplication because it awaits UI refresh.
	
	set currentCaseIndex to session's getInt("Current Case Index")
	StatusItem's setTitle:(getMenuBarIcon() & currentCaseIndex)
	
	if session's getString("Case ID") is not missing value then
		set sessionCaseId to session's getString("Case ID")
		set titleMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:(sessionCaseId) action:("autoIncrementAction:") keyEquivalent:"")
		(newMenu's addItem:titleMenuItem)
		(titleMenuItem's setEnabled:false)
		
		set autoIncrementState to switchLib's active("Auto Increment Case Index")
		set autoIncMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:("Auto Increment") action:("autoIncrementAction:") keyEquivalent:"")
		autoIncMenuItem's setState:(autoIncrementState)
		(newMenu's addItem:autoIncMenuItem)
		(autoIncMenuItem's setTarget:me)
		
		set altLabel to "Auto Increment " & unic's ARROW_RIGHT & " OFF"
		if switchLib's inactive("Auto Increment Case Index") then set altLabel to "Auto Increment " & unic's ARROW_RIGHT & " ON"
		
		set autoIncAltMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:altLabel action:("autoIncrementAction:") keyEquivalent:"")
		set autoIncAltMenuItem's alternate to true
		autoIncAltMenuItem's setState:(autoIncrementState)
		
		(autoIncAltMenuItem's setKeyEquivalentModifierMask:(current application's NSEventModifierFlagOption))
		(newMenu's addItem:autoIncAltMenuItem)
		(autoIncAltMenuItem's setTarget:me)
		
		_addMenuSeparator()
	end if
	
	repeat with i from 1 to number of items in cases
		set this_item to item i of cases
		-- if i is equal to currentCaseIndex then
		-- 	set this_item to this_item & " " & emoji's CHECK
		-- end if
		
		set thisMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:this_item action:("menuAction:") keyEquivalent:"")
		(thisMenuItem's setState:(i is equal to currentCaseIndex))
		(newMenu's addItem:thisMenuItem)
		(thisMenuItem's setTarget:me)
		
		-- We place white space so we can detect alt, with the same menu item label.
		set altMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:(this_item & " ") action:("menuAction:") keyEquivalent:"")
		set altMenuItem's alternate to true
		(altMenuItem's setKeyEquivalentModifierMask:(current application's NSEventModifierFlagOption))
		(newMenu's addItem:altMenuItem)
		(altMenuItem's setTarget:me)
	end repeat
	
	_addMenuSeparator()
	
	-- Create the Quit menu item separately
	set quitMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:"Quit" action:("quitAction:") keyEquivalent:"")
	(newMenu's addItem:quitMenuItem)
	(quitMenuItem's setTarget:me) -- required for enabling the menu item
end makeMenus


on idle
	try
		set currentCases to cases
		set retrievedCases to session's getList("Case Labels")
		if retrievedCases is missing value then set retrievedCases to {}
		
		set casesCountChanged to (count of currentCases) is not equal to (count of retrievedCases)
		set caseIndexChanged to my caseIndex is not equal to session's getInt("Current Case Index")
		set caseIdChanged to my caseId is not equal to session's getString("Case ID")
		set autoIncrementChanged to my autoIncrement is not equal to switchLib's active("Auto Increment Case Index")
		
		set cases to retrievedCases
		
		if casesCountChanged or caseIndexChanged or caseIdChanged or autoIncrementChanged then
			if my isSpot is false then makeMenus()
			if casesCountChanged or caseIdChanged then tell speech to speak("Menu Cases Updated")
			set my caseId to session's getString("Case ID")
			set my caseIndex to session's getInt("Current Case Index")
			set my autoIncrement to switchLib's active("Auto Increment Case Index")
		else if not isSpot then
			StatusItem's setTitle:(getMenuBarIcon() & my caseIndex)
		end if
	on error the errorMessage number the errorNumber
		std's catch(me, errorMessage, errorNumber)
	end try
	
	my idleSeconds
end idle


on getMenuBarIcon()
	if switchLib's active("Auto Increment Case Index") then return emoji's PENCIL_DOWN
	
	emoji's PENCIL_FLAT
end getMenuBarIcon


on menuAction:sender
	set menuItem to sender's title as text
	set changeAutoIncrement to menuItem ends with " "
	set cleanMenuItem to textUtil's rtrim(menuItem)
	-- if cleanMenuItem ends with " " & emoji's CHECK then set cleanMenuItem to text 1 thru ((length of cleanMenuItem) - 2) of cleanMenuItem
	set isChecked to (sender's state() = 1)
	if isChecked then set cleanMenuItem to text 1 thru ((length of cleanMenuItem) - 2) of cleanMenuItem
	
	set newIndex to listUtil's indexOf(cases, cleanMenuItem)
	session's setValue("Current Case Index", newIndex)
	spotLib's setSessionCaseIndex(newIndex)
	set my caseIndex to newIndex
	if changeAutoIncrement then
		set autoIncSwitch to switchLib's new("Auto Increment Case Index")
		autoIncSwitch's toggle()
		set my autoIncrement to not my autoIncrement
	end if
	
	activate application "Script Editor"
	do shell script "open -ga 'Run Script Editor 2.app'"
	
	makeMenus()
end menuAction:


on autoIncrementAction:sender
	set autoIncSwitch to switchLib's new("Auto Increment Case Index")
	autoIncSwitch's toggle()
	
	makeMenus()
end autoIncrementAction:


on quitAction:sender
	quit me
end quitAction:


on _addMenuSeparator()
	set sepMenuItem to (current application's NSMenuItem's separatorItem())
	(newMenu's addItem:sepMenuItem)
end _addMenuSeparator


