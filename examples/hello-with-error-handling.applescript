use scripting additions

use std : script "std"

use loggerLib : script "logger"

property logger : missing value
property scriptName : missing value

tell application "System Events" to set my scriptName to get name of (path to me)

set my logger to loggerLib's new(my scriptName)

logger's info("Hello AppleScript Core!")

try
	1 / 0
on error the errorMessage number the errorNumber
	std's catch(my scriptName, errorNumber, errorMessage)
end try


