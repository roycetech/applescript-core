global std, fileUtil, textUtil, syseve, retry, sessionPlist, configSystem
global seLib, automator
global IS_SPOT, SCRIPT_NAME, CURRENT_AS_PROJECT

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
		Sets the most recent project key (Current AppleScript Project) for easier subsequent deployment.
	
	@Testing Notes
		Open the Run Script Editor.applescript and that will be used to test this script.	
		
	@Configurations
		Reads config-system.plist - AppleScript Projects
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
set configSystem to std's import("config")'s new("system")

set CURRENT_AS_PROJECT to "Current AppleScript Project"
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
	logger's debugf("thisAppName: {}", thisAppName)
	
	if IS_SPOT and std's appExists(thisAppName) is true then
		set testScriptName to "Run Script Editor 2.applescript"
		set seTab to seLib's findTabWithName(testScriptName)
		if seTab is missing value then
			logger's infof("The test script {} was not found", testScriptName)
			return
		end if
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
	
	set projectKeys to configSystem's getValue("AppleScript Projects")
	if projectKeys is missing value then
		error "Project keys was not found in config-system.plist"
		return
	end if
	
	set currentAsProjectKey to sessionPlist's getString(CURRENT_AS_PROJECT)
	if currentAsProjectKey is missing value then
		set selectedProjectKey to choose from list projectKeys
	else
		set selectedProjectKey to choose from list projectKeys with title "Recent Project Key: " & currentAsProjectKey default items {currentAsProjectKey}
	end if
	
	if selectedProjectKey is false then
		logger's info("User canceled")
		return
	end if
	set selectedProjectKey to first item of selectedProjectKey
	
	logger's debugf("selectedProjectKey: {}", selectedProjectKey)
	sessionPlist's setValue(CURRENT_AS_PROJECT, selectedProjectKey)
	
	set projectPath to configSystem's getValue(selectedProjectKey)
	set resourcePath to textUtil's replace(seTab's getPosixPath(), projectPath & "/", "")
	
	tell automator
		launchAndWaitReady()
		createNewDocument()
		selectApplicationType()
		addAppleScriptAction()
		writeRunScript(selectedProjectKey, resourcePath)
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
