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

use loggerLib : script "core/logger"
use plutilLib : script "core/plutil"


property logger : loggerLib's new("enter-user-info")
property plutil : plutilLib's new()

set configUser to plutil's new("zoom.us/config")

set infoKey to "User Meeting ID" -- e.g. 123456789
set existingValue to ""
if configUser's hasValue(infoKey) then set existingValue to configUser's getValue(infoKey)

set userInput to display dialog "Enter a new value value for: " & infoKey default answer existingValue
set inputText to text returned of userInput
logger's debugf("inputText: {}", inputText)

configUser's setValue(infoKey, inputText)
logger's infof("The detail: {} is now saved for {}", {inputText, infoKey})


set infoKey to "Username" -- e.g. john@appleseed.com
set existingValue to ""
if configUser's hasValue(infoKey) then set existingValue to configUser's getValue(infoKey)

set userInput to display dialog "Enter a new value value for: " & infoKey default answer existingValue
set inputText to text returned of userInput
logger's debugf("inputText: {}", inputText)

configUser's setValue(infoKey, inputText)
logger's infof("The detail: {} is now saved for {}", {inputText, infoKey})


set infoKey to "Display Name" -- e.g. Royce Remulla
set existingValue to ""
if configUser's hasValue(infoKey) then set existingValue to configUser's getValue(infoKey)

set userInput to display dialog "Enter a new value value for: " & infoKey default answer existingValue
set inputText to text returned of userInput
logger's debugf("inputText: {}", inputText)

configUser's setValue(infoKey, inputText)
logger's infof("The detail: {} is now saved for {}", {inputText, infoKey})
