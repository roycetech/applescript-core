use scripting additions

use loggerLib : script "logger"

property logger : missing value

tell application "System Events" to set scriptName to get name of (path to me)

set my logger to loggerLib's new(scriptName)

logger's start()

logger's info("Hello AppleScript Core!")

logger's finish()
