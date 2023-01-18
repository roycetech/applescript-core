(*
	Sets up some useful user configurations that are specific to using the zoom app.
	
	@Plist:
		zoom.us/config.plist
		
	@Plist Keys
		User Meeting ID
		Username
		
	@Uninstall:
		plutil -remove 'User Meeting ID' ~/applescript-core/zoom.us/config.plist
		plutil -remove 'Username' ~/applescript-core/zoom.us/config.plist
*)
set infoKey to "User Meeting ID" -- e.g. 123456789

set std to script "std"
set logger to std's import("logger")'s new("enter-user-info")
set plutil to std's import("plutil")'s new()

set textUtil to std's import("string")
set listUtil to std's import("list")

set configUser to plutil's new("zoom.us/config")

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



