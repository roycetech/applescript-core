global std, seLib

(*
	This script will trigger the run button of the front window of Script Editor. 
	Useful as a follow up process after selecting a new case using Menu Case.app.

	@Installation:
		Run Create Automator App.app while this script is opened and focused in Script Editor.
		Grant the resulting app an accessibility access so it can trigger the Script Editor's run button.
		The following fails with access permission error: make compile-app SOURCE="apps/User/Run Script Editor"

*)

property logger : missing value

on run argv
	tell application "System Events" to set scriptName to get name of (path to me)
	
	set std to script "std"
	set logger to std's import("logger")'s new(scriptName)
	
	set IS_MAIN_SCRIPT to (count of argv) is 0
	if IS_MAIN_SCRIPT then
		logger's start()
	end if
	
	-- = Imports and Initialize constants below = -- 
	set seLib to std's import("script-editor")'s new()
	
	try
		main()
	on error the errorMessage number the errorNumber
		std's catch(scriptName, errorNumber, errorMessage)
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