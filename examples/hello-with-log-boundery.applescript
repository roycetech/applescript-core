set std to script "std"
tell application "System Events" to set scriptName to get name of (path to me)
set logger to std's import("logger")'s new(scriptName)

logger's start()

logger's info("Hello AppleScript Core!")

logger's finish()
