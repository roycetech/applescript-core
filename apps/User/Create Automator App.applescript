global std, fileUtil, textUtil, syseve, retry, sessionPlist
global seLib, automator
global IS_SPOT, SCRIPT_NAME

(* 
	This app is used to create an app using automator for the current document that is opened in the Script Editor app. Apps created via automator does not suffer from the problem of permission error as compared to apps exported via Script Editor, or compiled via osacompile.

	NOTE: This app requires exclusive focus without user interruption of app focus. 
	
	@Requires:
		automator.applescript
		script-editor.applescript
		
	@Deployment:
		1. Run this code, if the app is not yet installed, it will be created.
		2. Grant accessibility permission to the resulting app.
		
	@Session:
		Sets the new app name into "New Script Name", for easy fetching when you set the permission after creation.
	
	@Testing Notes
		Open the Run Script Editor.applescript and that will be used to test this script.	
*)

property logger : missing value

tell application "System Events" to set SCRIPT_NAME to get name of (path to me)
set IS_SPOT to false
if name of current application is "Script Editor" then set IS_SPOT to true

set std to script "std"
set logger to std's import("logger")'s new(SCRIPT_NAME)

logger's start()

-- = Start of Code below =====================================================
set syseve to std's import("syseve")'s new()
set fileUtil to std's import("file")
set textUtil to std's import("string")
set retry to std's import("retry")'s new()
set plutil to std's import("plutil")'s new()
set sessionPlist to plutil's new("session")
set seLib to std's import("script-editor")'s new()
set automator to std's import("automator")'s new()

try
	main()
on error the errorMessage number the errorNumber
	std's catch(SCRIPT_NAME, errorNumber, errorMessage)
end try

logger's finish()


-- HANDLERS ==================================================================


on main()
	if running of application "Script Editor" is false then
		logger's info("This app was designed to create an app for the currently opened document in Script Editor")
		return
	end if
	
	set thisAppName to text 1 thru ((offset of "." in SCRIPT_NAME) - 1) of SCRIPT_NAME
	if IS_SPOT and std's appExists(SCRIPT_NAME) is true then
		set seTab to seLib's findTabWithName("Run Script Editor.applescript")
		seTab's focus()
	else
		set seTab to seLib's getFrontTab()
	end if
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	logger's info("Base Script Name:  " & baseScriptName)
	sessionPlist's setValue("New Script Name", baseScriptName & ".app")
	-- logger's info("Target POSIX path:  " & targetPosixPath)
	
	(*
	set targetMonPath to fileUtil's convertPosixToMacOsNotation(targetPosixPath)
	logger's info("Target MON path:  " & targetMonPath)
*)
	
	logger's info("Conditionally quitting existing automator app...")
	automator's forceQuitApp()
	
	tell automator
		launchAndWaitReady()
		createNewDocument()
		selectApplicationType()
		addAppleScriptAction()
		writeRunScript(seTab's getResourcePath())
		compileScript()
		triggerSave()
		waitForSaveReady()
		enterScriptName(baseScriptName)
		triggerGoToFolder()
		waitForGoToFolderInputField()
		enterDefaultSavePath()
		set savePathFound to waitToFindSavePath()
		if savePathFound is missing value then
			error "The save path was not found: " & savePath & ". Check config-system['AppleScript Apps path']"
		end if
		
		acceptFoundSavePath()
		clickSave()
	end tell	
end main
