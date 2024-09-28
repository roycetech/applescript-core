(*
	@Purpose:
		Creates a voice command app in the user speech library. 
		
		NOTE: Installing in the local domain is not possible atm because it results in permission error. 
		Automator is not allowed to export into that directory.

	@Requires:
		automator.applescript
		script-editor.applescript
		
	@Session:
		Sets the new app name into "New Script Name", for easy fetching when you set the permission after creation.

	@Testing:
		Open the hello.applescript or your preferred script file for example.
		
	@Configurations
		Reads config-user.plist - AppleScript Projects Path		
		
	@Known Issues:
		August 21, 2023 1:24 PM - Re-add to accessibility when the System Preferences is launched automatically.
		Fails to trigger the keystroke detection on the Command Input as of February 5, 2023. Without this, the save keystroke fails because the value in the input field is not detected.
		
	@Last Modified: August 21, 2023 12:23 PM
*)

use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use fileUtil : script "core/file"
use emoji : script "core/emoji"

use loggerFactory : script "core/logger-factory"

use usrLib : script "core/user"
use systemEventsLib : script "core/system-events"
use plutilLib : script "core/plutil"
use scriptEditorLib : script "core/script-editor"
use automatorLib : script "core/automator"
use configLib : script "core/config"

property logger : missing value

property usr : missing value
property systemEvents : missing value
property plutil : missing value
property scriptEditor : missing value
property automator : missing value
property configUser : missing value
property session : missing value

property name : missing value
property isSpot : false

(* Sets the new app name for easy fetching when the permission is set after creation. *)
property SESSION_KEY_NEW_SCRIPT : "New Script Name"

tell application "System Events" to set my name to get name of (path to me)

loggerFactory's inject(me)
logger's start()

set usr to usrLib's new()
set systemEvents to systemEventsLib's new()
set plutil to plutilLib's new()
set scriptEditor to scriptEditorLib's new()
set automator to automatorLib's new()
set configUser to configLib's new("user")
set session to plutil's new("session")

if {"Script Editor", "Script Debugger"} contains the name of current application then set my isSpot to true

try
	main()
on error the errorMessage number the errorNumber
	std's catch(me, errorNumber, errorMessage)
end try

logger's finish()
usr's done()


-- HANDLERS ==================================================================
on main()
	if running of application "Script Editor" is false then
		logger's info("This app was designed to create a voice control app for the currently opened document in Script Editor")
		return
	end if
	
	if my isSpot then
		logger's info("Switching to a test file for to create voice command for")
		set scriptEditorTab to scriptEditor's findTabWithName("hello.applescript")
		if scriptEditorTab is missing value then
			error "You must open the hello.applescript in Script Editor"
		end if
		scriptEditorTab's focus()
	else
		set scriptEditorTab to scriptEditor's getFrontTab()
	end if
	logger's infof("Current File Open: {}", scriptEditorTab's getScriptName())
	
	set baseScriptName to scriptEditorTab's getBaseScriptName()
	logger's infof("Base Script Name:  {}", baseScriptName)
	session's setValue(SESSION_KEY_NEW_SCRIPT, baseScriptName & ".app")
	
	textUtil's replace(baseScriptName, " ", "-")
	set dashedName to textUtil's lcase(result)
	logger's debugf("dashedName: {}", dashedName)
	
	set filePath to scriptEditorTab's getPosixPath()
	
	compileAppScript(filePath, dashedName)
	
	logger's info("Conditionally quitting existing automator app...")
	automator's forceQuitApp()
	
	(*
	set projectsPath to configUser's getValue("AppleScript Projects Path")
	if projectsPath is missing value then
		error "Projects Path was not found in config-user.plist"
		return
	end if
*)
	
	(*
	set scriptPosixPath to scriptEditorTab's getPosixPath()
	set computedProjectKey to missing value
	repeat with nextPath in projectsPath
		if scriptPosixPath starts with nextPath then
			set filePathTokens to textUtil's split(nextPath, "/")
			set computedProjectKey to the last item of filePathTokens
			exit repeat
		end if
	end repeat
	logger's debugf("computedProjectKey: {}", computedProjectKey)
	assertThat of std given condition:computedProjectKey is not missing value, messageOnFail:"Error: Make sure you have registered the project containing " & my name & ". See its README.md for more details."
	
	set projectPath to configUser's getValue("Project " & computedProjectKey)
	logger's debugf("projectPath: {}", projectPath)
	
	set resourcePath to textUtil's replace(scriptPosixPath, projectPath & "/", "")
	logger's debugf("resourcePath: {}", resourcePath)
*)
	
	tell automator
		logger's debug("Launch and wait to be ready...")
		launchAndWaitReady()
		
		logger's debug("Create a new document...")
		createNewDocument()
		
		logger's debug("Select the dictation command...") 
		selectDictationCommand()
		
		logger's debug("Add AppleScript Action")
		addAppleScriptAction()
		
		logger's debug("Writing the run script...")
		set its domainKeyOverride to "user"
		-- writeRunScript(computedProjectKey, resourcePath)
		writeRunScript(dashedName)
		
		logger's debug("Clicking the command enabled...")
		clickCommandEnabled()
		
		setCommandPhrase(baseScriptName)
		
		logger's debug("Compiling the automator script...")
		compileScript()
		
		set the clipboard to baseScriptName & " " & emoji's HORN
		if name of automator is "AutomatorInstance" then -- vanilla implementation has problem with programmatically setting the dictation command getting recognized by the Automator app.
			display dialog "User needs to continue the steps manually
			1. Set the Dictation Command by re-typing it.
			2. Save the app by pressing Cmd + S
			3. Paste the generated filename"
		else
			logger's debug("Triggering save...")
			triggerSave()
			
			waitForSaveReady()
			enterScriptName(baseScriptName & " " & emoji's HORN)
			
			clickSave()
		end if
		
	end tell
end main


on compileAppScript(scriptPath, dashedName)
	-- set deploymentPath to usr's getDeploymentPath() & "/app/"
	set deploymentPath to usr's getUserDeploymentPath() & "/app/"
	set deployScript to "/usr/bin/osacompile -o \"" & deploymentPath & dashedName & ".scpt\" " & quoted form of scriptPath
	set deploymentType to usr's getDeploymentType()
	set deploymentType to "user" -- Force to user.
	
	logger's infof("Compiling this app script into the {} script library namespace", deploymentType)
	
	-- Force deploy into the user domain because installing into the shared local does not work.
	if deploymentType is equal to "computer" and false then
		set sudoDeployScript to "sudo " & deployScript
		logger's debugf("Deploy script: {}", sudoDeployScript)
		do shell script sudoDeployScript with administrator privileges
		
	else
		do shell script deployScript
	end if
end compileAppScript
