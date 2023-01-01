global std, usr, fileUtil, textUtil, syseve, emoji, sessionPlist, seLib, automator
global SCRIPT_NAME, IS_SPOT

(*
	@Requires:
		automator.applescript
		script-editor.applescript
		
	@Testing:
		Open the Turn On Dictation.applescript for example.
*)

property logger : missing value

tell application "System Events" to set SCRIPT_NAME to get name of (path to me)

set std to script "std"
set logger to std's import("logger")'s new(SCRIPT_NAME)


logger's start()

-- = Start of Code below =====================================================
set usr to std's import("user")'s new()
set fileUtil to std's import("file")
set textUtil to std's import("string")
set syseve to std's import("syseve")'s new()
set emoji to std's import("emoji")
set plutil to std's import("plutil")'s new()
set sessionPlist to plutil's new("session")
set seLib to std's import("script-editor")'s new()
set automator to std's import("automator")'s new()


set IS_SPOT to name of current application is "Script Editor"

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
		set seTab to seLib's findTabWithName("Turn On Dictation.applescript")
		seTab's focus()
	else
		set seTab to seLib's getFrontTab()
	end if
	logger's infof("Current File Open: {}", seTab's getScriptName())
	
	set baseScriptName to seTab's getBaseScriptName()
	logger's infof("Base Script Name:  {}", baseScriptName)
	sessionPlist's setValue("New Script Name", baseScriptName & ".app")
	
	
	logger's info("Conditionally quitting existing automator app...")
	automator's forceQuitApp()
	
	tell automator
		launchAndWaitReady()
		createNewDocument()
		selectDictationCommand()
		addAppleScriptAction()
		writeRunScript(seTab's getPosixPath())
		clickCommandEnabled()
		setCommandPhrase(baseScriptName)
		compileScript()
		triggerSave()
		waitForSaveReady()
		enterScriptName(baseScriptName & " " & emoji's HORN)
		
		clickSave()
	end tell
end main
