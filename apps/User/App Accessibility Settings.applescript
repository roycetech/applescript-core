global std, syspref, retry

(*
	Prepares the user to update the accessibility settings.
	
	Note: Will close the existing System Preferences app to make this script more predictable.
*)

property logger : missing value

set std to script "std"
tell application "System Events" to set scriptName to get name of (path to me)
set logger to std's import("logger")'s new(scriptName)
logger's start()

-- = Start of Code below =====================================================
set syspref to std's import("system-preferences")'s new()
set retry to std's import("retry")'s new()

try
	main()
on error the errorMessage number the errorNumber
	std's catch(scriptName, errorNumber, errorMessage)
end try

logger's finish()


on main()
	tell syspref
		quitApp()
		revealSecurityAccessibilityPrivacy()
		unlockSecurityAccessibilityPrivacy()
	end tell
end main
