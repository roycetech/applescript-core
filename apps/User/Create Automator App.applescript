(* 
	This app is used to create an app using automator for the current document 
	that is opened in the Script Editor app. Apps created via automator does not 
	suffer from the problem of permission error as compared to apps exported via 
	Script Editor, or compiled via osacompile.

	NOTE: This app requires exclusive focus without user interruption of app focus. 
	
	@Requires:
		automator.applescript (Install with make install-automator)
		script-editor.applescript (Install with make build-script-editor)
		 
	@Build:
		1. Run this code in Script Editor, if the app is not yet installed, it 
		will be created.
		2. Grant accessibility permission to the resulting app.
		This app may be re-installed by deleting the Create Automator App.app 
		and repeating the deployment steps.
		
	@Session:
		Sets the new app name into "New Script Name", for easy fetching when you 
		set the permission after creation.
	
	@Testing Notes
		Open the Run Script Editor.applescript and that will be used to test 
		this script.
		
	@Configurations
		Reads config-user.plist - AppleScript Projects Path
		
	@Known Issues:
		Sat, Oct 5, 2024 at 5:56:52 PM - Will not be able to create an app in the local namespace if it has a dependency
			in the user namespace.
			
		As of June 28, 2023 11:26 AM, while it is working on Script Editor, 
		there is a scary "errOSAInternalTableOverflow" dialog when I try to run 
		this on Script Debugger.
*)

use scripting additions

use std : script "core/std"
use fileUtil : script "core/file"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"
use plutilLib : script "core/plutil"
use scriptEditorLib : script "core/script-editor"
use automatorLib : script "core/automator"
use dockLib : script "core/dock"


property logger : missing value
property plutil : missing value
property scriptEditor : missing value
property automator : missing value
property dock : missing value
property session : missing value
property usr : missing value

property isSpot : false

if {"Script Editor", "Script Debugger"} contains the name of current application then set my isSpot to true

loggerFactory's inject(me)
logger's start()

set dock to dockLib's new()
set plutil to plutilLib's new()
set session to plutil's new("session")
set scriptEditor to scriptEditorLib's new()
set automator to automatorLib's new()
set usr to usrLib's new()

-- = Start of Code below =====================================================

try
	main()
on error the errorMessage number the errorNumber
	std's catch(me, errorNumber, errorMessage)
end try

logger's finish()


-- HANDLERS ==================================================================


on main()
	textUtil's trim("This fixes strange plutil core/string error")
	
	if running of application "Script Editor" is false then
		logger's info("This app was designed to create an app for the currently opened and focused document in Script Editor")
		return
	end if
	
	tell application "System Events" to set scriptName to get name of (path to me)
	set thisAppName to text 1 thru ((offset of "." in scriptName) - 1) of scriptName
	logger's debugf("thisAppName: {}", thisAppName)
	
	if my isSpot and std's appExists(thisAppName) is true then
		set testScriptName to "Run Script Editor 2.applescript"
		set scriptEditorTab to scriptEditor's findTabWithName(testScriptName)
		if scriptEditorTab is missing value then
			logger's infof("The test script {} was not found", testScriptName)
			return
		end if
		scriptEditorTab's focus()
	else
		set scriptEditorTab to scriptEditor's getFrontTab()
	end if
	logger's infof("Current File Open: {}", scriptEditorTab's getScriptName())
	
	set baseScriptName to scriptEditorTab's getBaseScriptName()
	logger's info("Base Script Name:  " & baseScriptName)
	
	textUtil's replace(baseScriptName, " ", "-")
	set dashedName to textUtil's lcase(result)
	logger's debugf("dashedName: {}", dashedName)
	
	session's setValue("New Script Name", baseScriptName & ".app")
	-- logger's info("Target POSIX path:  " & targetPosixPath)
	
	set filePath to scriptEditorTab's getPosixPath()
	
	if usr's getDeploymentType() is equal to "computer" then
		logger's info("Compiling this app script into the computer script library namespace")
		set deploymentPath to "/Library/Script Libraries/core/app/"
		set defaultScript to "sudo /usr/bin/osacompile -o \"" & deploymentPath & dashedName & ".scpt\" " & quoted form of filePath
		do shell script defaultScript with administrator privileges
		
	else
		set deploymentPath to "/Users/" & std's getUsername() & " /Library/Script Libraries/core/app/"
		do shell script defaultScript
	end if
	
	(* 
	set targetMonPath to fileUtil's convertPosixToMacOsNotation(targetPosixPath)
	logger's info("Target MON path:  " & targetMonPath)
	*)
	
	logger's info("Conditionally quitting existing automator app...")
	automator's forceQuitApp()
	
	tell automator
		launchAndWaitReady()
		dock's clickApp("Automator") -- Mitigate previous step fails to launch the app.
		
		createNewDocument()
		selectApplicationType()
		addAppleScriptAction()
		writeRunScript(dashedName)
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
