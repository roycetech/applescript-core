(* 
	This app is used to create an app using automator for the current document that is opened in the Script Editor app. Apps created via automator does not suffer from the problem of permission error as compared to apps exported via Script Editor, or compiled via osacompile.

	NOTE: This app requires exclusive focus without user interruption of app focus. 
	
	@Requires:
		automator.applescript
		script-editor.applescript
		
	@Deployment:
		1. Run this code, if the app is not yet installed, it will be created.
		2. Grant accessibility permission to the resulting app.
		Re-install this app by deleting the Create Automator App.app and redo deployment steps.
		
	@Session:
		Sets the new app name into "New Script Name", for easy fetching when you set the permission after creation.
	
	@Testing Notes
		Open the Run Script Editor.applescript and that will be used to test this script.	
		
	@Configurations
		Reads config-user.plist - AppleScript Projects Path
*)

use scripting additions

use std : script "std"
use fileUtil : script "file"
use textUtil : script "string"

use loggerLib : script "logger"
use syseveLib : script "system-events"
use retryLib : script "retry"
use plutilLib : script "plutil"
use seLib : script "script-editor"
use configLib : script "config"
use automatorLib : script "automator"

property logger : loggerLib's new("Create Automator App")
property syseve : syseveLib's new()
property retry : retryLib's new()
property plutil : plutilLib's new()
property se : seLib's new()
property configUser : configLib's new("user")
property automator : automatorLib's new()

property scriptName : missing value
property isSpot : false

property session : plutil's new("session")

tell application "System Events" to set scriptName to get name of (path to me)

if {"Script Editor", "Script Debugger"} contains the name of current application then set my isSpot to true

logger's start()

-- = Start of Code below =====================================================

try
	main()
on error the errorMessage number the errorNumber
	std's catch(scriptName, errorNumber, errorMessage)
end try

logger's finish()


-- HANDLERS ==================================================================


on main()
	if running of application "Script Editor" is false then
		logger's info("This app was designed to create an app for the currently opened document in Script Editor")
		return
	end if
	
	set thisAppName to text 1 thru ((offset of "." in scriptName) - 1) of scriptName
	logger's debugf("thisAppName: {}", thisAppName)
	
	if my isSpot and std's appExists(thisAppName) is true then
		set testScriptName to "Run Script Editor 2.applescript"
		set seTab to se's findTabWithName(testScriptName)
		if seTab is missing value then
			logger's infof("The test script {} was not found", testScriptName)
			return
		end if
		seTab's focus()
	else
		set seTab to se's getFrontTab()
	end if
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	logger's info("Base Script Name:  " & baseScriptName)
	session's setValue("New Script Name", baseScriptName & ".app")
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
	-- logger's debugf("scriptPosixPath: {}", scriptPosixPath)
	set computedProjectKey to missing value
	
	repeat with nextPath in projectPaths
		-- logger's debugf("nextPath: {}", nextPath)
		if scriptPosixPath starts with nextPath then
			set filePathTokens to textUtil's split(nextPath, "/")
			set computedProjectKey to the last item of filePathTokens
			exit repeat
		end if
	end repeat
	assertThat of std given condition:computedProjectKey is not missing value, messageOnFail:"Error: Make sure you have registered the project containing \"" & scriptPosixPath & "\". See its README.md for more details."
	
	
	(*		
	if selectedProjectKey is false then
		logger's info("User canceled")
		return
	end if
	set selectedProjectKey to first item of selectedProjectKey
	*)
	
	logger's debugf("computedProjectKey: {}", computedProjectKey)
	-- session's setValue(CURRENT_AS_PROJECT, selectedProjectKey)
	
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
