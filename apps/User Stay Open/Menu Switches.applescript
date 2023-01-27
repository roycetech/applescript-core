global std, notif, configUser, textUtil, MapClass, emoji, switch, sessionPlist, listUtil
global SCRIPT_NAME, IDLE_SECONDS
global SWITCHES_LIST, SWITCHES_ID, SESSION_SWITCHES_LIST, SESSION_SWITCHES_ID

global IS_SPOT

(*
	TODO: 
		Change to green check mark if a script is active and thus our helper is not going to interrupt.

	Re-enable security grant after deploying:
		1. Delete from Security and Privacy > Accessibility. Close the window.
		2. Re-add to Security and Privacy > Accessibility. Close the window.

	Adding new flag:
		1. Add entry to config.plist, under applescript > Switches
		2. Add entry to config.plist, under applescript > All Switches...
		3. Sort both list.  (Can be done on Sublime Text by highlighting it and pressing F5)
		
	@Plist Files
		switches.plist - contains the state of each switch
		session.plist - 
			Menu Switches List - contains the list of session flags that we can quickly access.
		config-user.plist
			Switches - Contains the list managed by this app.
			Session Switches - app-managed switches.
*)

use framework "Foundation"
use framework "AppKit"

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

property StatusItem : missing value
property selectedMenu : ""
property defaults : class "NSUserDefaults"
property internalMenuItem : class "NSMenuItem"
property externalMenuItem : class "NSMenuItem"
property newMenu : class "NSMenu"
property switchesCount : 0
property sessionSwitchesCount : 0

set IS_SPOT to name of current application is "Script Editor"

init()
logger's start()

set IDLE_SECONDS to 60
set IDLE_SECONDS to 5 -- Let's see if this don't cause too much perf impact.

set SWITCHES_LIST to listUtil's simpleSort(configUser's getValue("Switches"))
set SESSION_SWITCHES_LIST to listUtil's simpleSort(configUser's getValue("Session Switches"))

if SWITCHES_LIST is not missing value then set switchesCount to count of SWITCHES_LIST
if SESSION_SWITCHES_LIST is not missing value then set sessionSwitchesCount to count of SESSION_SWITCHES_LIST

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
	
	-- set up the initial NSStatusBars title
	-- StatusItem's setTitle:("Switches")
	StatusItem's setTitle:(emoji's CHECKBOX)
	
	
	-- set up the initial NSMenu of the statusbar
	set newMenu to current application's NSMenu's alloc()'s initWithTitle:"Custom"
	newMenu's setDelegate:me
	(*
    		Required delegation for when the Status bar Menu is clicked  the menu will use the delegates method (menuNeedsUpdate:(menu)) to run dynamically update.
	*)
	StatusItem's setMenu:newMenu
end makeStatusBar

on makeMenus()
	newMenu's removeAllItems() -- remove existing menu items
	
	set appNameMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:"Menu Switches" action:("menuAction:") keyEquivalent:"")
	(newMenu's addItem:appNameMenuItem)
	(appNameMenuItem's setEnabled:false)
	
	if sessionPlist's getBool("Script Active") is true then
		set clearActiveMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:"Clear Active Script Flag" action:("clearActiveAction:") keyEquivalent:"")
		(newMenu's addItem:clearActiveMenuItem)
		(clearActiveMenuItem's setTarget:me)
	end if
	
	_addMenuSeparator()
	
	checkForUpdatedList()
	
	set SWITCHES_ID to "{"
	repeat with i from 1 to number of items in SWITCHES_LIST
		set this_item to item i of SWITCHES_LIST
		if SWITCHES_ID is not equal to "{" then set SWITCHES_ID to SWITCHES_ID & ", "
		
		set SWITCHES_ID to SWITCHES_ID & this_item & ": " & switch's active(this_item)
		if this_item as text is equal to "-" then
			set thisMenuItem to (current application's NSMenuItem's separatorItem())
		else
			if switch's active(this_item) then set this_item to this_item & " " & emoji's CHECK
			set thisMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:this_item action:("menuToggler:") keyEquivalent:"")
		end if
		
		(newMenu's addItem:thisMenuItem)
		(thisMenuItem's setTarget:me)
	end repeat
	set SWITCHES_ID to SWITCHES_ID & "}"
	-- logger's debugf("SWITCHES_ID: {}", SWITCHES_ID)
	_addMenuSeparator()
	
	
	set SESSION_SWITCHES_ID to "{"
	repeat with i from 1 to number of items in SESSION_SWITCHES_LIST
		set this_item to item i of SESSION_SWITCHES_LIST
		if SESSION_SWITCHES_ID is not equal to "{" then set SESSION_SWITCHES_ID to SESSION_SWITCHES_ID & ", "
		
		set SESSION_SWITCHES_ID to SESSION_SWITCHES_ID & this_item & ": " & sessionPlist's getBool(this_item)
		if this_item as text is equal to "-" then
			set thisMenuItem to (current application's NSMenuItem's separatorItem())
		else
			if sessionPlist's getBool(this_item) then set this_item to this_item & " " & emoji's CHECK
			set thisMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:this_item action:("menuSessionToggler:") keyEquivalent:"")
		end if
		-- (thisMenuItem's setEnabled:false)		
		(newMenu's addItem:thisMenuItem)
		(thisMenuItem's setTarget:me)
	end repeat
	set SESSION_SWITCHES_ID to SESSION_SWITCHES_ID & "}"
	_addMenuSeparator()
	
	
	-- Create the Quit menu item separately
	set thisMenuItem to (current application's NSMenuItem's alloc()'s initWithTitle:"Quit" action:("quitAction:") keyEquivalent:"")
	(newMenu's addItem:thisMenuItem)
	(thisMenuItem's setTarget:me) -- required for enabling the menu item
end makeMenus

on _addMenuSeparator()
	set sepMenuItem to (current application's NSMenuItem's separatorItem())
	(newMenu's addItem:sepMenuItem)
end _addMenuSeparator


on idle
	try
		if scriptStateHasChanged() then
			logger's debug("scriptStateHasChanged...")
			StatusItem's setTitle:(emoji's CHECKBOX)
		end if
		
		try -- intermittent error when reading the flags.plist.
			if listHasChanged() and IS_SPOT is false then makeMenus()
		on error the errorMessage number the errorNumber
			logger's fatal(errorMessage)
		end try
	on error the errorMessage number the errorNumber
		std's catch(me, errorMessage, errorNumber)
	end try
	
	IDLE_SECONDS
end idle


on scriptStateHasChanged()
	set currentActiveState to sessionPlist's getBool("Script Active")
	currentActiveState is not equal to SCRIPT_ACTIVE_FLAG
end scriptStateHasChanged


on listHasChanged()
	set switchesAsOfNow to configUser's getValue("Switches")
	set sortedKeys to listUtil's simpleSort(switchesAsOfNow)
	set currentSwitchesId to "{"
	repeat with nextKey in sortedKeys
		if currentSwitchesId is not equal to "{" then set currentSwitchesId to currentSwitchesId & ", "
		
		set currentSwitchesId to currentSwitchesId & nextKey & ": " & switch's active(nextKey)
	end repeat
	set currentSwitchesId to currentSwitchesId & "}"
	
	currentSwitchesId is not equal to SWITCHES_ID
end listHasChanged


on updateStatus(menuItem as text)
	init()
	
	set flagItem to switch's new(menuItem)
	flagItem's toggle()
	if IS_SPOT is false then makeMenus()
end updateStatus

on updateSessionStatus(menuItem as text)
	init()
	
	set currentState to sessionPlist's getBool(menuItem)
	sessionPlist's setValue(menuItem, not currentState)
	
	if IS_SPOT is false then makeMenus()
end updateSessionStatus


on quitAction:sender
	quit me
end quitAction:


-- Private Codes below =======================================================

on getPositionOfItemInList(theList, theItem)
	repeat with a from 1 to count of theList
		if item a of theList is theItem then return a
	end repeat
	return 0
end getPositionOfItemInList

(* Checks if Switches or Session Switches have been updated from the plist. *)
on checkForUpdatedList()
	set switchesAsOfNow to configUser's getValue("Switches")
	if (count of switchesAsOfNow) is not equal to switchesCount then
		set switchesCount to count of switchesAsOfNow
		set SWITCHES_LIST to listUtil's simpleSort(switchesAsOfNow)
	end if
	
	set sessionSwitchesAsOfNow to configUser's getValue("Session Switches")
	if (count of sessionSwitchesAsOfNow) is not equal to sessionSwitchesCount then
		set sessionSwitchesCount to count of sessionSwitchesAsOfNow
		set SESSION_SWITCHES_LIST to listUtil's simpleSort(sessionSwitchesAsOfNow)
	end if
end checkForUpdatedList


on clearActiveAction:sender
	sessionPlist's setValue("Script Active", false)
end clearActiveAction:

(* Handles menu click action for the regular (non-session) switches *)
on menuToggler:sender
	try
		set menuItem to sender's title as text
		if menuItem ends with " " & emoji's CHECK then set menuItem to text 1 thru ((length of menuItem) - 2) of menuItem
		
		updateStatus(menuItem)
	on error the errorMessage number the errorNumber
		std's catch(me, errorMessage, errorNumber)
	end try
end menuToggler:


(* Handles menu click action for the session switches *)
on menuSessionToggler:sender
	try
		set menuItem to sender's title as text
		if menuItem ends with " " & emoji's CHECK then set menuItem to text 1 thru ((length of menuItem) - 2) of menuItem
		
		updateSessionStatus(menuItem)
	on error the errorMessage number the errorNumber
		std's catch(me, errorMessage, errorNumber)
	end try
end menuSessionToggler:


(* Constructor *)
on init()
	tell application "System Events" to set SCRIPT_NAME to get name of (path to me)
	set SWITCHES_ID to missing value
	
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("Menu Switches")
	set switch to std's import("switch")
	set emoji to std's import("emoji")
	set configUser to std's import("config")'s new("user")
	set textUtil to std's import("string")
	set MapClass to std's import("map")
	set plutil to std's import("plutil")'s new()
	set sessionPlist to plutil's new("session")
	set listUtil to std's import("list")
end init