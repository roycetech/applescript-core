global std, fileUtil, textUtil, syseve, retry, sessionPlist, configUser
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
		
	@Configurations
		Reads config-user.plist - AppleScript Projects Path
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
set configUser to std's import("config")'s new("user")

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
	
	set projectPaths to configUser's getValue("AppleScript Projects Path")
	if projectPaths is missing value then
		error "'AppleScript Projects Path' was not found in config-user.plist"
		return
	end if
	(*	
	if currentAsProjectKey is missing value then
		set selectedProjectKey to choose from list projectKeys
	else
		set selectedProjectKey to choose from list projectKeys with title "Recent Project Key: " & currentAsProjectKey default items {currentAsProjectKey}
	end if
	*)
	
	set scriptPosixPath to seTab's getPosixPath()
	set computedProjectKey to missing value
	repeat with nextPath in projectPaths
		if scriptPosixPath starts with nextPath then
			set filePathTokens to textUtil's split(nextPath, "/")
			set computedProjectKey to the last item of filePathTokens
			exit repeat
		end if
	end repeat
	assertThat of std given condition: computedProjectKey is not missing value, messageOnFail:"Error: Make sure you have registered the project containing " & SCRIPT_NAME & ". See its README.md for more details."
	
	
	(*		
	if selectedProjectKey is false then
		logger's info("User canceled")
		return
	end if
	set selectedProjectKey to first item of selectedProjectKey
	*)
	
	logger's debugf("computedProjectKey: {}", computedProjectKey)
	-- sessionPlist's setValue(CURRENT_AS_PROJECT, selectedProjectKey)
	
	set projectPath to configUser's getValue("Project " & computedProjectKey)
	logger's debugf("projectPath: {}", projectPath)
	set resourcePath to textUtil's replace(scriptPosixPath, projectPath & "/", "")
	logger's debugf("resourcePath: {}", resourcePath)
	
	tell automator
		launchAndWaitReady()
		createNewDocument()
		selectApplicationType()
		addAppleScriptAction()
		writeRunScript(computedProjectKey, resourcePath)
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
		delay 0.2 -- fails with 0.1
		clickSave()
	end tell
end main
