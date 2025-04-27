(*
	Sets up some useful user configurations that are specific to using the zoom app.

	@Plist:
		zoom.us/config.plist

	@Plist Keys
		User Meeting ID
		Username
		Display Name

	@Uninstall:
		plutil -remove 'User Meeting ID' ~/applescript-core/zoom.us/config.plist
		plutil -remove 'Username' ~/applescript-core/zoom.us/config.plist
		plutil -remove 'Display Name' ~/applescript-core/zoom.us/config.plist
*)

use scripting additions

use textUtil : script "core/string"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use loggerLib : script "core/logger-factory"
use plutilLib : script "core/plutil"

property logger : missing value
property plutil : missing value

property PLIST_PATH_ZOOM_CONFIG : "zoom.us/config"
property PLIST_KEY_USER_MEETING_ID : "User Meeting ID"
property PLIST_KEY_USERNAME : "Username" -- e.g. john@appleseed.com
property PLIST_KEY_DISPLAY_NAME : "Display Name"

loggerFactory's inject(me)

set plutil to plutilLib's new()
set configUser to plutil's new(PLIST_PATH_ZOOM_CONFIG)

-- set infoKey to  -- e.g. 123456789
set existingValue to ""
if configUser's hasValue(PLIST_KEY_USER_MEETING_ID) then set existingValue to configUser's getValue(PLIST_KEY_USER_MEETING_ID)

set userInput to display dialog "Enter a new value value for: " & PLIST_KEY_USER_MEETING_ID default answer existingValue
set inputText to text returned of userInput
logger's debugf("inputText: {}", inputText)

configUser's setValue(PLIST_KEY_USER_MEETING_ID, inputText)
logger's infof("The detail: {} is now saved for {}", {inputText, PLIST_KEY_USER_MEETING_ID})


-- set infoKey to "Username" -- e.g. john@appleseed.com
set existingValue to ""
if configUser's hasValue(PLIST_KEY_USERNAME) then set existingValue to configUser's getValue(PLIST_KEY_USERNAME)

set userInput to display dialog "Enter a new value value for: " & PLIST_KEY_USERNAME default answer existingValue
set inputText to text returned of userInput
logger's debugf("inputText: {}", inputText)

configUser's setValue(PLIST_KEY_USERNAME, inputText)
logger's infof("The detail: {} is now saved for {}", {inputText, PLIST_KEY_USERNAME})


-- set infoKey to "Display Name" -- e.g. Royce Remulla
set existingValue to ""
if configUser's hasValue(PLIST_KEY_DISPLAY_NAME) then set existingValue to configUser's getValue(PLIST_KEY_DISPLAY_NAME)

set userInput to display dialog "Enter a new value value for: " & PLIST_KEY_DISPLAY_NAME default answer existingValue
set inputText to text returned of userInput
logger's debugf("inputText: {}", inputText)

configUser's setValue(PLIST_KEY_DISPLAY_NAME, inputText)
logger's infof("The detail: {} is now saved for {}", {inputText, PLIST_KEY_DISPLAY_NAME})
