set std to script "std"
tell application "System Events" to set scriptName to get name of (path to me)
set logger to std's import("logger")'s new(scriptName)

logger's info("Hello AppleScript Core!")

try
	1 / 0
on error the errorMessage number the errorNumber
	std's catch(scriptName, errorNumber, errorMessage)
end try
