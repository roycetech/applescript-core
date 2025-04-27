(*
	Checks the config-system.plist then adds this project key and path if it is not yet registered.

	@Plist:
		config-user.plist

	@Plist Keys
		User Country - Just an example.

	@Uninstall:
		plutil -remove 'User Country' ~/applescript-core/config-user.plist
*)

use scripting additions

use textUtil : script "core/string"
use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value
property plutil : missing value

loggerFactory's inject(me)
set infoKey to "User Country" -- e.g. Philippines
set plutil to plutilLib's new()
set configUser to plutil's new("config-user")

(*
if configUser's hasValue(infoKey) then
	logger's infof("The detail: {} is already present with the value: {}", {infoKey, configUser's getValue(infoKey)})
	return
end if
*)

set existingValue to ""
if configUser's hasValue(infoKey) then set existingValue to configUser's getValue(infoKey)

set userInput to display dialog "Enter a new value value for: " & infoKey default answer existingValue
set inputText to text returned of userInput
-- logger's debugf("inputText: {}", inputText)

configUser's setValue(infoKey, inputText)
logger's infof("The value: {} is now saved for {}", {inputText, infoKey})



