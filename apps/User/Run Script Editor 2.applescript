(*
	This script will trigger the run button of the front window of Script Editor. 
	Useful as a follow up process after selecting a new case using Menu Case.app.

	@Installation:
		Run Create Automator App.app while this script is opened and focused in Script Editor.
		Grant the resulting app an accessibility access so it can trigger the Script Editor's run button.
		The following fails with access permission error: make build-app SOURCE="apps/User/Run Script Editor"

*)

use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

on run argv
	set IS_MAIN_SCRIPT to (count of argv) is 0
	if IS_MAIN_SCRIPT then
		loggerFactory's inject(me)
		logger's start()
	end if
	
	try
		main()
	on error the errorMessage number the errorNumber
		std's catch(me, errorNumber, errorMessage)
	end try
	
	if IS_MAIN_SCRIPT then
		logger's finish()
	end if
end run


on main()
	tell application "System Events" to tell process "Script Editor"
		try
			click (first button of toolbar 1 of front window whose description is "Run")
		on error the errorMessage number the errorNumber
			logger's warn(errorMessage)
		end try
	end tell
end main