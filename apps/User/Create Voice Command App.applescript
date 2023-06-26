global std, usr, fileUtil, textUtil, syseve, emoji, session, seLib, automator, configUser
global SCRIPT_NAME, IS_SPOT

(*
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
		Fails to trigger the keystroke detection on the Command Input as of February 5, 2023. Without this, the save keystroke fails because the value in the input field is not detected.
*)

use scripting additions

use std : script "std"
use textUtil : script "string"
use fileUtil : script "file"
use emoji : script "emoji"

use loggerLib : script "logger"
use usrLib : script "user"
use syseveLib : script "system-events"
use plutilLib : script "plutil"
use seLib : script "script-editor"
use automatorLib : script "automator"
use configLib : script "config"

property logger : loggerLib's new("Create Voice Command App")
property usr : usrLib's new()
property syseve : syseveLib's new()
property plutil : plutilLib's new()
property se : seLib's new()
property automator : automatorLib's new()
property configUser : configLib's new("user")

property session : plutil's new("session")

property SCRIPT_NAME : missing value
property isSpot : false

tell application "System Events" to set SCRIPT_NAME to get name of (path to me)


logger's start()

-- = Start of Code below =====================================================

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
		logger's info("This app was designed to create an app for the currently opened document in Script Editor")
		return
	end if
	
	set thisAppName to text 1 thru ((offset of "." in SCRIPT_NAME) - 1) of SCRIPT_NAME
	if IS_SPOT then
		logger's info("Switching to a test file for to create voice command for")
		set seTab to se's findTabWithName("hello.applescript")
		if seTab is missing value then
			error "You must open the hello.applescript in Script Editor"
		end if
		seTab's focus()
	else
		set seTab to se's getFrontTab()
	end if
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	logger's infof("Base Script Name:  {}", baseScriptName)
	session's setValue("New Script Name", baseScriptName & ".app")
	
	
	logger's info("Conditionally quitting existing automator app...")
	automator's forceQuitApp()
	
	set projectsPath to configUser's getValue("AppleScript Projects Path")
	if projectsPath is missing value then
		error "Projects Path was not found in config-user.plist"
		return
	end if
	
	set scriptPosixPath to seTab's getPosixPath()
	set computedProjectKey to missing value
	repeat with nextPath in projectsPath
		if scriptPosixPath starts with nextPath then
			set filePathTokens to textUtil's split(nextPath, "/")
			set computedProjectKey to the last item of filePathTokens
			exit repeat
		end if
	end repeat
	logger's debugf("computedProjectKey: {}", computedProjectKey)
	assertThat of std given condition:computedProjectKey is not missing value, messageOnFail:"Error: Make sure you have registered the project containing " & SCRIPT_NAME & ". See its README.md for more details."
	
	set projectPath to configUser's getValue("Project " & computedProjectKey)
	logger's debugf("projectPath: {}", projectPath)
	set resourcePath to textUtil's replace(scriptPosixPath, projectPath & "/", "")
	logger's debugf("resourcePath: {}", resourcePath)
	
	tell automator
		launchAndWaitReady()
		createNewDocument()
		selectDictationCommand()
		addAppleScriptAction()
		writeRunScript(computedProjectKey, resourcePath)
		clickCommandEnabled()
		setCommandPhrase(baseScriptName)
		compileScript()
		
		set the clipboard to baseScriptName & " " & emoji's HORN
		if name of automator is "AutomatorInstance" then -- vanilla implementation has problem with programmatically setting the dictation command getting recognized by the Automator app.
			display dialog "User needs to continue the steps manually
			1. Set the Dictation Command by re-typing it.
			2. Save the app by pressing Cmd + S
			3. Paste the generated filename"
		else
			triggerSave()
			
			waitForSaveReady()
			enterScriptName(baseScriptName & " " & emoji's HORN)
			
			clickSave()
		end if
		
	end tell
end main
