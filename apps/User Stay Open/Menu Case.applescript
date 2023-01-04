global std, notif, textUtil, MapClass, emoji, listUtil, speech, switch, uni, sessionPlist, spotLib
global SCRIPT_NAME, IDLE_SECONDS, CASES, CASE_ID, CASE_INDEX, AUTO_INCREMENT
global IS_SPOT

(*
	@Deployment
		Run "Create Dockless App.app" while this script is loaded in Script Editor.

	@Optional:
		Create the app "Run Script Editor" to automatically trigger run after 
		selecting a test case.

	@Known Issues:
		Upon cases change, the menu items gets duplicated, but gets fixed after 
		a few seconds. 

	Refreshes menu automatically every 5.
	NOTE: On Option+click, must hold option longer for the handler to detect it.
*)

use framework "Foundation"
use framework "AppKit"
use framework "Cocoa"

use script "Core Text Utilities"
use scripting additions

property StatusItem : missing value
property selectedMenu : ""
property defaults : class "NSUserDefaults"
property internalMenuItem : class "NSMenuItem"
property externalMenuItem : class "NSMenuItem"
property newMenu : class "NSMenu"
property logger : missing value

init()

set IDLE_SECONDS to 5
set IS_SPOT to name of current application is "Script Editor"

tell application "System Events" to set SCRIPT_NAME to get name of (path to me)
logger's start()

if IS_SPOT then
	delay (idle {})
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
	
	set currentCaseIndex to sessionPlist's getInt("Current Case Index")
	StatusItem's setTitle:("C:" & currentCaseIndex)
	
	set newMenu to current application's NSMenu's alloc()'s initWithTitle:"Custom"
	newMenu's setDelegate:me
	StatusItem's setMenu:newMenu
end makeStatusBar


on makeMenus()
	newMenu's removeAllItems() -- remove existing menu items
	
	set currentCaseIndex to sessionPlist's getInt("Current Case Index")
	
	StatusItem's setTitle:(getMenuBarIcon() & currentCaseIndex)
	
	if sessionPlist's getString("Case ID") is not missing value then
		set sessionCaseId to sessionPlist's getString("Case ID")
		set titleMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:(sessionCaseId) action:("autoIncrementAction:") keyEquivalent:"")
		(newMenu's addItem:titleMenuItem)
		(titleMenuItem's setEnabled:false)
		
		set autoIncLabel to "Auto Increment"
		if switch's active("Auto Increment Case Index") then set autoIncLabel to autoIncLabel & " " & emoji's CHECK
		set autoIncMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:autoIncLabel action:("autoIncrementAction:") keyEquivalent:"")
		(newMenu's addItem:autoIncMenuItem)
		(autoIncMenuItem's setTarget:me)
		
		set altLabel to "Auto Increment " & uni's ARROW_RIGHT & " OFF"
		if switch's inactive("Auto Increment Case Index") then set altLabel to "Auto Increment " & uni's ARROW_RIGHT & " ON"
		
		set autoIncAltMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:altLabel action:("autoIncrementAction:") keyEquivalent:"")
		set autoIncAltMenuItem's alternate to true
		(autoIncAltMenuItem's setKeyEquivalentModifierMask:(current application's NSEventModifierFlagOption))
		(newMenu's addItem:autoIncAltMenuItem)
		(autoIncAltMenuItem's setTarget:me)
		
		_addMenuSeparator()
	end if
	
	repeat with i from 1 to number of items in CASES
		set this_item to item i of CASES
		if i is equal to currentCaseIndex then
			set this_item to this_item & " " & emoji's CHECK
		end if
		
		set thisMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:this_item action:("menuAction:") keyEquivalent:"")
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
	set thisMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:"Quit" action:("quitAction:") keyEquivalent:"")
	(newMenu's addItem:thisMenuItem)
	(thisMenuItem's setTarget:me) -- required for enabling the menu item
end makeMenus


on idle
	init()
	
	set currentCases to CASES
	set retrievedCases to sessionPlist's getList("Case Labels")
	if retrievedCases is missing value then set retrievedCases to {}
	
	set casesCountChanged to (count of currentCases) is not equal to (count of retrievedCases)
	set caseIndexChanged to CASE_INDEX is not equal to sessionPlist's getInt("Current Case Index")
	set caseIdChanged to CASE_ID is not equal to sessionPlist's getString("Case ID")
	set autoIncrementChanged to AUTO_INCREMENT is not equal to switch's active("Auto Increment Case Index")
	
	set CASES to retrievedCases
	
	if casesCountChanged or caseIndexChanged or caseIdChanged or autoIncrementChanged then
		if IS_SPOT is false then makeMenus()
		if casesCountChanged or caseIdChanged then tell speech to speak("Menu Cases Updated")
		set CASE_ID to sessionPlist's getString("Case ID")
		set CASE_INDEX to sessionPlist's getInt("Current Case Index")
		set AUTO_INCREMENT to switch's active("Auto Increment Case Index")
	else
		StatusItem's setTitle:(getMenuBarIcon() & CASE_INDEX)
	end if
	
	IDLE_SECONDS
end idle


on getMenuBarIcon()
	if switch's active("Auto Increment Case Index") then return emoji's PENCIL_DOWN
	
	emoji's PENCIL_FLAT
end getMenuBarIcon


on menuAction:sender
	set menuItem to sender's title as text
	set changeAutoIncrement to menuItem ends with " "
	set cleanMenuItem to textUtil's rtrim(menuItem)
	if cleanMenuItem ends with " " & emoji's CHECK then set cleanMenuItem to text 1 thru ((length of cleanMenuItem) - 2) of cleanMenuItem
	
	set newIndex to listUtil's indexOf(CASES, cleanMenuItem)
	sessionPlist's setValue("Current Case Index", newIndex)
	spotLib's setSessionCaseIndex(newIndex)
	set CASE_INDEX to newIndex
	if changeAutoIncrement then
		set autoIncSwitch to switch's new("Auto Increment Case Index")
		autoIncSwitch's toggle()
		set AUTO_INCREMENT to not AUTO_INCREMENT
	end if
	
	activate application "Script Editor"
	do shell script "open -ga 'Run Script Editor 2.app'"
	
	makeMenus()
end menuAction:


on autoIncrementAction:sender
	set autoIncSwitch to switch's new("Auto Increment Case Index")
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


property initialized : false

on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("Menu Case")
	set textUtil to std's import("string")
	set MapClass to std's import("Map")
	set emoji to std's import("emoji")
	set listUtil to std's import("list")
	set speech to std's import("speech")'s new()
	set switch to std's import("switch")
	set uni to std's import("unicodes")
	set plutil to std's import("plutil")'s new()
	set sessionPlist to plutil's new("session")
	set spotLib to std's import("spot-test")'s new()
	spotLib's setSessionCaseIndex(0)
	
	sessionPlist's setValue("Current Case Index", 0)
	sessionPlist's setValue("Case Labels", {})
	sessionPlist's deleteKey("Case ID")
	
	set CASES to {}
	set CASE_ID to missing value
	set CASE_INDEX to 1
	set AUTO_INCREMENT to false
end init