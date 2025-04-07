(*
	Wrapper script for IntelliJ IDEA application. Can handle the regular or the community edition.

	@Prerequisite:
		Run the script setup-intellij-cli.applescript to pick the correct CLI.

	@Project:
		applescript-core
		
	@Build:
		make build-intellij
		
	@Created: September 9, 2023 3:06 PM
	@Last Modified: 
	@Change Logs:
		September 28, 2023 5:31 PM - Added openProject and openFile
*)

use scripting additions

use std : script "core/std"
use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use configLib : script "core/config"
use decoratorLib : script "core/decorator"
use retryLib : script "core/retry"

property logger : missing value
property kb : missing value
property config : missing value
property IDEA_CLI : missing value
property retry : missing value

property CONFIG_SYSTEM : "system"
property CONFIG_KEY_IDEA_CLI : "IntelliJ CLI"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set spotScript to script "core/spot-test"
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		NOOP: Info
		Manual: Open Project
		Manual: Open File Path
		Manual: Toggle Scheme
		Manual: Trigger Menu
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	set sutProjectPath to "/Users/" & std's getUsername() & "/Projects/@rt-playground/spring-boot-3-tickets"
	set sutProjectFilePath to sutProjectPath & "/pom.xml"
	
	logger's infof("Current Project Name: {}", sut's getCurrentProjectName())
	logger's infof("Current Document Name: {}", sut's getCurrentDocumentName())
	logger's infof("Is Project Selected: {}", sut's isProjectSelected())
	
	logger's debugf("sutProjectFilePath: {}", sutProjectFilePath)
	logger's infof("Is code with me running: {}", sut's isCodingWithMe())
	logger's debugf("Integration: Current file path: {}", sut's getCurrentFilePath())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutProjectPath to "/Users/" & std's getUsername() & "/Projects/@Work_A2/obsr-core-v10" --  TEMP
		
		sut's openProject(sutProjectPath)
		
	else if caseIndex is 3 then
		sut's openFile(sutProjectFilePath)
		
	else if caseIndex is 4 then
		-- This is not working
		-- sut's toggleScheme()
		
	else if caseIndex is 5 then
		sut's triggerMenu("Run", "Run")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set configSystem to configLib's new(CONFIG_SYSTEM)
	set IDEA_CLI to configSystem's getValue(CONFIG_KEY_IDEA_CLI)
	set retry to retryLib's new()
	
	if std's appExists("IntelliJ IDEA") then
		set localAppName to "IntelliJ IDEA"
	else if std's appExists("IntelliJ IDEA CE") then
		set localAppName to "IntelliJ IDEA CE"
	else
		error "IntelliJ app was not found."
	end if
	logger's debugf("localAppName: {}", localAppName)
	
	script IntelliJIDEAInstance
		property intellijAppName : localAppName
		
		
		on triggerMenu(menuTitle, menuSubtitle)
			set ceAppName to "IntelliJ IDEA CE"
			set ultAppName to "IntelliJ IDEA Ultimate"
			
			set targetProcess to "idea"
			if codeWithMeIsRunning() then
				set targetProcess to "jetbrains_client"
			end if
			
			tell application "System Events" to tell process targetProcess
				try
					click (first menu item of menu 1 of menu bar item menuTitle of menu bar 1 whose title starts with menuSubtitle)
				end try
			end tell
		end triggerMenu
		
		
		(*
			Experimental!
		*)
		on isCodingWithMe()
			tell application "System Events" to tell process "Dock"
				set hasTwoIntelliJ to (count of (UI elements of list 1 whose title starts with "IntelliJ")) is 2
				if not hasTwoIntelliJ then return false
				
				set secondIdeaIsRunning to value of attribute "AXIsApplicationRunning" of (UI element 2 of list 1 whose title starts with "IntelliJ IDEA")
				
				hasTwoIntelliJ and secondIdeaIsRunning
			end tell
		end isCodingWithMe
		
		
		on openProject(projectPath)
			logger's debugf("projectPath: {}", projectPath)
			
			do shell script quoted form of IDEA_CLI & " " & projectPath & " > /dev/null 2>&1 &"
		end openProject
		
		
		on openFile(filePath)
			(* Does not work. Works fine on terminal.*)
			logger's debugf("IDEA_CLI: {}", IDEA_CLI)
			do shell script quoted form of IDEA_CLI & " " & filePath
		end openFile
		
		
		on getCurrentProjectName()
			-- log "Dummy code to prevent crash"
			(*
			-- First Version, broken after checking out a feature branch.
			set mainWindowName to _getMainWindowName()
			if mainWindowName is missing value then return missing value
			
			first item of textUtil's split(mainWindowName, " " & unic's MAIL_SUBDASH & " ")
			*)
			
			-- Second Version, fails when project uses another subfolder for the actual project
			(*
			tell application "System Events" to tell process "idea"
				set mainWindow to first window whose title is not ""
				try
					first group of group 1 of mainWindow whose description is "Status Bar"
					return description of first button of group 1 of scroll area 1 of result
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					return missing value
				end try
			end tell
*)
			
			(*
			tell application "System Events" to tell process "idea"
				title of first window whose title is not ""
				return textUtil's trim(first item of textUtil's split(result, unic's MAIL_SUBDASH))
			end tell
			*)
			
			(*
			tell application "System Events"
	if exists (first process whose name is "IntelliJ IDEA") then
	
	else if 	exists (first process whose name is "jetbrains_client")  then -- CWM
	
	end if
			*)
			
			tell application "System Events" to tell process intellijAppName
				set targetWindow to missing value
				try				
					set targetWindow to first window whose title is not ""
				end try
				if targetWindow is missing value then return missing value
				set windowTitle to title of targetWindow
			end tell
			if isCodingWithMe() then return textUtil's trim(second item of textUtil's split(windowTitle, unic's MAIL_SUBDASH))
			
			textUtil's trim(first item of textUtil's split(windowTitle, unic's MAIL_SUBDASH))
		end getCurrentProjectName
		
		
		on getCurrentDocumentName()
			
			set mainWindowName to _getMainWindowName()
			logger's debugf("mainWindowName: {}", mainWindowName)
			if mainWindowName is missing value then return missing value
			
			last item of textUtil's split(mainWindowName, " " & unic's MAIL_SUBDASH & " ")
			last item of textUtil's split(result, "/")
			first item of textUtil's split(result, " [")
		end getCurrentDocumentName
		
		(*
			@returns true of the project is selected from the Tree View, when the buttons at the status bar is single.
		*)
		on isProjectSelected()
			if running of application intellijAppName is false then return missing value
			
			set statusBarGroup to _getGroup("Status Bar")
			if statusBarGroup is missing value then return false
			
			-- tell application "System Events" to tell process "IntelliJ IDEA"
			-- 			tell application "System Events" to tell process "idea"
			tell application "System Events" to tell my _getProcessName()
				try
					return (count of buttons of group 1 of scroll area 1 of statusBarGroup) is 1
				end try -- Fails when only a file is open instead of a project.
			end tell
			false
		end isProjectSelected
		
		
		(* 
			NOT WORKING.
			
			Change to the next scheme (called theme on most other editors) 
		*)
		on toggleScheme()
			activate application intellijAppName
			delay 0.1
			kb's pressControlKey("`")
			kb's pressKey("enter") -- Choose the "Edit Color Scheme"
			kb's pressKey("enter") -- Choose the pre-selected next theme.
			delay 0.1 -- Fails without this
			tell application "System Events" to tell process "idea"
				click (first button of window "Change IntelliJ IDEA Theme" whose description is "Yes")
			end tell
		end toggleScheme
		
		
		on _getGroup(groupName)
			script Failable
				-- tell application "System Events" to tell process "idea"
				tell application "System Events" to tell process (my _getProcessName())
					set mainWindow to first window whose title is not ""
					
					first group of group 1 of mainWindow whose description is equal to the groupName
				end tell
			end script
			exec of retry on result for 5
		end _getGroup
		
		on _getMainWindowName()
			if running of application intellijAppName is false then return missing value
			
			-- 			tell application "System Events" to tell process "idea"
			tell application "System Events" to tell process (my intellijAppName)
				set mainWindow to missing value
				try
					return the name of first window whose name is not ""
				end try
			end tell
			
			missing value
		end _getMainWindowName
		
		
		on _getProcessName()
			tell application "System Events"
				if exists (first process whose name is "IntelliJ IDEA") then return "IntelliJ IDEA"
				if exists (first process whose name is "jetbrains_client") then return "jetbrains_client"
			end tell
			
			missing value
		end _getProcessName
	end script
	
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new
