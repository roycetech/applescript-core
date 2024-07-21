(*
	This app picks up the current loaded file in Script Editor and creates a 
	stay open app, the updates the plist file so that the app doesn't show in 
	the dock while running.
	This app is created for menu-type stay open apps because doing it via 
	osacompile breaks the app.
	
	@Project:
		applescript-core

	@Prerequisites:
		make install-script-editor

	@Installation Instruction:
		echo 'Run "Create Automator App" while this script is loaded in Script Editor.'
		Grant Accessibility permission to the generated app.
	
	@Testing Notes
		Open the Menu Case.applescript and that will be used to test this script.
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use dateTimeLib : script "core/date-time"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use switchLib : script "core/switch"
use scriptEditorLib : script "core/script-editor"
use speechLib : script "core/speech"
use retryLib : script "core/retry"
use plutilLib : script "core/plutil"
use finderLib : script "core/finder"
use usrLib : script "core/user"
use diaLib : script "core/dialog"

property logger : missing value
property usr : missing value
property dia : missing value

property scriptEditor : missing value
property retry : missing value
property plutil : missing value
property finder : missing value
property dateTime : missing value
property session : missing value
property speech : missing value

property scriptName : missing value
property isSpot : false
property backUpSwitch : missing value

property SUBPATH_STAY_OPEN : "Stay Open"

tell application "System Events" to set scriptName to get name of (path to me)
if {"Script Editor", "Script Debugger"} contains the name of current application then set isSpot to true

loggerFactory's inject(me)
logger's start()

set plutil to plutilLib's new()
set session to plutil's new("session")
set speech to speechLib's new(missing value)
set scriptEditor to scriptEditorLib's new()
set retry to retryLib's new()
set plutil to plutilLib's new()
set finder to finderLib's new()
set dateTime to dateTimeLib's new()
set backUpSwitch to switchLib's new("Create Back Up Menu App")
set usr to usrLib's new()
set dia to diaLib's new()

try
	main()
on error the errorMessage number the errorNumber
	std's catch(me, errorNumber, errorMessage)
end try

logger's finish()


-- HANDLERS ==================================================================
on main()
	if running of application "Script Editor" is false then
		logger's info("This app was designed to deploy the currently opened document in Script Editor")
		return
	end if
	
	if isSpot then
		-- set spotCheckScript to "Menu Notes.applescript"
		set spotCheckScript to "Menu Case.applescript"
		set scriptEditorTab to scriptEditor's findTabWithName(spotCheckScript)
		if scriptEditorTab is missing value then
			error "You need to manually open the file: " & spotCheckScript
		end if
		
		scriptEditorTab's focus()
	else
		set scriptEditorTab to scriptEditor's getFrontTab()
	end if
	
	logger's infof("Current File Open: {}", scriptEditorTab's getScriptName())
	
	set baseScriptName to scriptEditorTab's getBaseScriptName()
	session's setValue("Last deployed script", baseScriptName)
	try
		logger's debugf("baseScriptName: {}", baseScriptName)
		do shell script "osascript -e 'tell application \"" & baseScriptName & "\" to quit'"
		logger's infof("App {} has been closed", baseScriptName)
	end try
	
	set currentDeploymentType to usr's getDeploymentType()
	set chosenDeployment to dia's showChoicesWithDefault("Deployment Type", "User-type has no dock icon but requires per user app deployment", {"user", "computer"}, currentDeploymentType)
	
	if chosenDeployment is "computer" then
		set appsFolder to finder's getApplicationsFolder()
	else
		set appsFolder to finder's getUserApplicationsFolder()
	end if
	
	
	tell application "Finder"
		set targetFolder to folder (my SUBPATH_STAY_OPEN) of folder "AppleScript" of appsFolder
	end tell
	logger's debugf("targetFolderMon: {}", targetFolder as text)
	
	-- set newScriptName to scriptEditorTab's getBaseScriptName() & ".app"
	set appFilename to scriptEditorTab's getBaseScriptName() & ".app"
	session's setValue("New Script Name", appFilename)
	
	if backUpSwitch's active() then backUpApp(appFilename, targetFolder)
	
	set savedScript to scriptEditorTab's saveAsStayOpenApp(targetFolder as text)
	logger's debugf("savedScript: {}", savedScript)
	
	if chosenDeployment is "user" then updateAppToDockless(appFilename, targetFolder)
	
	tell speech to speakSynchronously("Menu app deployed") -- causing problems.
	activate application baseScriptName
	scriptEditorTab's closeTab()
end main


on backUpApp(appFilename, targetFolder)
	tell application "Finder"
		set isReplacement to exists of (file appFilename of targetFolder)
	end tell
	
	if not isReplacement then return
	
	logger's info("Creating backup...")
	set backupAppName to appFilename & "-" & dateTime's formatYyyyMmDdHHmi(current date)
	tell application "Finder" to set sourceFile to file appFilename of targetFolder
	finder's createFile(sourceFile, targetFolder, backupAppName)
end backUpApp


(* Modify the app's Info.plist to prevent the app from appearing in the dock while running. *)
on updateAppToDockless(appFilename, targetFolder)
	tell application "Finder"
		URL of targetFolder
	end tell
	textUtil's stringAfter(result, "file://")
	set appPath to textUtil's decodeUrl(result)
	
	logger's info("Updating Info.plist to hide menu app from dock...")
	set defaultsScript to format {"defaults write '{}{}/Contents/Info.plist' LSUIElement -bool yes", {appPath, appFilename}}
	logger's debugf("defaultsScript: {}", defaultsScript)
	do shell script defaultsScript
end updateAppToDockless
