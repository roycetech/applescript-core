(*
	This app picks up the current loaded file in Script Editor and creates a 
	stay open app, the updates the plist file so that the app doesn't show in 
	the dock while running.
	This app is created for menu-type stay open apps because doing it via 
	osacompile breaks the app.
	
	@Deployment:
		Run "Create Automator App" while this script is loaded in Script Editor.
		Grant Accessibility permission to the generated app.
	
	@Testing Notes
		Open the Menu Case.applescript and that will be used to test this script.
*)

use script "Core Text Utilities"
use scripting additions

use std : script "std"

use switchLib : script "switch"
use loggerLib : script "logger"
use seLib : script "script-editor"
use speechLib : script "speech"
use retryLib : script "retry"
use plutilLib : script "plutil"
use finderLib : script "finder"

property logger : loggerLib's new("Create Menu App")
property se : seLib's new()
property retry : retryLib's new()
property plutil : plutilLib's new()
property finder : finderLib's new()

property session : plutil's new("session")

property speech : speechLib's new(missing value)

property scriptName : missing value
property isSpot : false

tell application "System Events" to set scriptName to get name of (path to me)
if {"Script Editor", "Script Debugger"} contains the name of current application then set isSpot to true

logger's start()

try
	main()
on error the errorMessage number the errorNumber
	std's catch(scriptName, errorNumber, errorMessage)
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
		set seTab to se's findTabWithName(spotCheckScript)
		if seTab is missing value then
			error "You need to manually open the file: " & spotCheckScript
		end if
		
		seTab's focus()
	else
		set seTab to se's getFrontTab()
	end if
	
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	session's setValue("Last deployed script", baseScriptName)
	try
		logger's debugf("baseScriptName: {}", baseScriptName)
		do shell script "osascript -e 'tell application \"" & baseScriptName & "\" to quit'"
		logger's infof("App {} has been closed", baseScriptName)
	end try
	
	tell application "Finder"
		set targetFolderMon to folder "Stay Open" of folder "AppleScript" of finder's getApplicationsFolder() as text
	end tell
	
	logger's debugf("targetFolderMon: {}", targetFolderMon)
	
	set newScriptName to seTab's getBaseScriptName() & ".app"
	session's setValue("New Script Name", newScriptName)
	
	set savedScript to seTab's saveAsStayOpenApp(targetFolderMon)
	
	logger's debugf("savedScript: {}", savedScript)
	
	-- Tab reference gets lost, so lets get the front tab.
	set frontTab to se's getFrontTab()
	set posixPath to frontTab's getPosixPath()
	logger's debugf("posixPath: {}", posixPath)
	logger's info("Updating Info.plist to hide menu app from dock...")
	do shell script (format {"defaults write '{}/Contents/Info.plist' LSUIElement -bool yes", posixPath})
	
	tell speech to speakSynchronously("Menu app deployed") -- casing problems.
	activate application baseScriptName
	seTab's closeTab()
end main
