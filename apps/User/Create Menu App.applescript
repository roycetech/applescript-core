(*
	This app picks up the current loaded file in Script Editor and creates a 
	stay open app, the updates the plist file so that the app doesn't show in 
	the dock while running.
	This app is created for menu-type stay open apps because doing it via 
	osacompile breaks the app.
	
	@Build:
		Run "Create Automator App" while this script is loaded in Script Editor.
		Grant Accessibility permission to the generated app.
	
	@Testing Notes
		Open the Menu Case.applescript and that will be used to test this script.
*)

use script "core/Text Utilities"
use scripting additions

use std : script "core/std"

use switchLib : script "core/switch"
use loggerFactory : script "core/logger-factory"
use seLib : script "core/script-editor"
use speechLib : script "core/speech"
use retryLib : script "core/retry"
use plutilLib : script "core/plutil"
use finderLib : script "core/finder"

property logger : missing value

property se : missing value
property retry : missing value
property plutil : missing value
property finder : missing value

property session : missing value
property speech : missing value

property scriptName : missing value
property isSpot : false

tell application "System Events" to set scriptName to get name of (path to me)
if {"Script Editor", "Script Debugger"} contains the name of current application then set isSpot to true

loggerFactory's inject(me)
logger's start()

set plutil to plutilLib's new()
set session to plutil's new("session")
set speech to speechLib's new(missing value)
set se to seLib's new()
set retry to retryLib's new()
set plutil to plutilLib's new()
set finder to finderLib's new()

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
		set targetFolderMon to folder "Stay Open" of folder "AppleScript" of finder's getUserApplicationsFolder() as text
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
