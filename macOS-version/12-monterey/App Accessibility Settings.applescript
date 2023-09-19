(*
	Prepares the user to update the accessibility settings.
	
	Note: Will close the existing System Preferences app to make this script more predictable.
*)

use std : script "core/std"

use loggerFactory : script "core/logger-factory"
use retryLib : script "core/retry"
use sysprefLib : script "core/system-preferences"

property logger : missing value
property retry : missing value
property syspref : missing value

loggerFactory's inject(me)
logger's start()

-- = Start of Code below =====================================================

set retry to retryLib's new()
set syspref to sysprefLib's new()

try
	main()
on error the errorMessage number the errorNumber
	std's catch(me, errorNumber, errorMessage)
end try

logger's finish()


on main()
	tell syspref
		quitApp()
		revealSecurityAccessibilityPrivacy()
		unlockSecurityAccessibilityPrivacy()
	end tell
end main
