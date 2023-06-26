(*
	Prepares the user to update the accessibility settings.
	
	Note: Will close the existing System Preferences app to make this script more predictable.
*)

use std : script "std"

use loggerLib : script "logger"
use retryLib : script "retry"
use sysprefLib : script "system-preferences"

property logger : loggerLib's new("App Accessibility Settings")
property retry : retryLib's new()
property syspref : sysprefLib's new()

logger's start()

-- = Start of Code below =====================================================

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
