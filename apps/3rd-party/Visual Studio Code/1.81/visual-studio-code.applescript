(*
	Migrated from code.applescript.
	
	@Requirements:
	
	@Plists:
		config-user:
			User Projects Path
			
		repo-org-path - Need to have the project registered so we can determine the organization mapping.
			
		
	@Project:
		applescript-core
		
	@Build:
		./scripts/build-lib.sh 'apps/3rd-party/Visual Studio Code/1.81/visual-studio-code'
		
	Migrated On: Monday, April 29, 2024 at 12:44:46 PM
*)


use scripting additions

use script "core/Text Utilities"

use std : script "core/std"
use textUtil : script "core/string"
use listUtil : script "core/list"
use unic : script "core/unicodes"
use systemEventLib : script "core/system-events"

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"
use regexPatternLib : script "core/regex-pattern"
use configLib : script "core/config"
use kbLib : script "core/keyboard"

property logger : missing value

property systemEvent : missing value
property plutil : missing value
property configUser : missing value
property kb : missing value

(* TODO: Move away from using this extra configuration. *)
property REPO_PROJECT_PATH : missing value
property PROJECTS_PATH : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	-- If you haven't got these imports already.
	set cases to listUtil's splitByLine("
		NOOP
		Open File
		Open Resource via UI
		Run Script
		Manual: Switch Activity
		
		Manual: New Terminal
		Manual: Focus Terminal
		Manual: Next Tab
		Manual: Previous Tab
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("Has Terminal: {}", sut's hasTerminal())
	logger's infof("Current File Type: {}", sut's getFileType())
	logger's infof("Current Project Name: {}", sut's getProjectName())
	logger's infof("Resource Path: {}", sut's getResourcePath())
	logger's infof("Document Name: {}", sut's getDocumentName())
	logger's infof("Document Path: {}", sut's getDocumentPath())
	logger's infof("Projects Path: {}", sut's getProjectsPath())
	logger's infof("Project Path: {}", sut's getProjectPath())
	logger's infof("Open in Container: {}", sut's isOpenInContainer())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set filePath to format {"{}/{}", {my PROJECTS_PATH, "/@rt-playground/ts-fetchjson/index.ts"}}
		sut's openFile(filePath)
		
	else if caseIndex is 3 then
		set resourcePath to "index.ts"
		sut's openResourceViaUI(resourcePath)
		
	else if caseIndex is 4 then
		sut's runShell("ls")
		
	else if caseIndex is 5 then
		sut's switchActivity("Docker")
		
	else if caseIndex is 6 then
		sut's newTerminal()
		
	else if caseIndex is 7 then
		sut's focusTerminal()
		
	else if caseIndex is 8 then
		sut's nextTab()
		
	else if caseIndex is 9 then
		sut's previousTab()

	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)
	set systemEvent to systemEventLib's new()
	set plutil to plutilLib's new()
	set configUser to configLib's new("user")
	set kb to kbLib's new()
	
	set my REPO_PROJECT_PATH to plutil's new("repo-org-path")
	set my PROJECTS_PATH to configUser's getValue("User Projects Path")
	
	set configBusiness to configLib's new("business")
	
	script VisualStudioCodeInstance
		
		(* Go > Switch Editor > Next Editor *)
		on nextTab()
			if running of application "Visual Studio Code" is false then return
			
			tell application "System Events" to tell process "Electron"
				set frontmost to true
				try
					click menu item "Next Editor" of menu 1 of menu item "Switch Editor" of menu 1 of menu bar item "Go" of menu bar 1
				end try
			end tell
		end nextTab
		
		
		(* Go > Switch Editor > Previous Editor *)
		on previousTab()
			if running of application "Visual Studio Code" is false then return
			
			tell application "System Events" to tell process "Electron"
				set frontmost to true
				try
					click menu item "Previous Editor" of menu 1 of menu item "Switch Editor" of menu 1 of menu bar item "Go" of menu bar 1
				end try
			end tell
		end previousTab
		
		
		on focusTerminal()
			if running of application "Visual Studio Code" is false then return
			
			tell application "System Events" to tell process "Electron"
				set frontmost to true
				try
					click menu item "Terminal" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			
		end focusTerminal
		
		on newTerminal()
			if running of application "Visual Studio Code" is false then return
			
			tell application "System Events" to tell process "Electron"
				set frontmost to true
				try
					click menu item "New Terminal" of menu 1 of menu bar item "Terminal" of menu bar 1
				end try
			end tell
		end newTerminal
		
		
		on hasTerminal()
			if running of application "Visual Studio Code" is false then return false
			
			tell application "System Events" to tell process "Electron"
				try
					return enabled of menu item "Split Terminal" of menu 1 of menu bar item "Terminal" of menu bar 1
				end try
			end tell
			
			false
		end hasTerminal
		
		on switchActivity(activityName)
			if running of application "Visual Studio Code" is false then return
			
			tell application "System Events" to tell process "Electron"
				click radio button activityName of tab group 1 of group 1 of group 1 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 1 of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of front window
			end tell
		end switchActivity
		
		
		(* Problem when opening a file inside a container. *)
		on openFile(filePath)
			open location "vscode://file" & filePath & ":1:1"
		end openFile
		
		
		(* Problem when opening a file inside a container. *)
		on openResourceViaUI(resourcePath)
			if running of application "Visual Studio Code" is false then return false
			
			tell application "System Events"
				if (count of windows of process "Electron") is 0 then return false
			end tell
			
			activate application "Visual Studio Code"
			delay 0.1
			
			tell application "System Events"
				key code 35 using {command down} -- P
			end tell
			delay 0.2
			kb's insertTextByPasting(resourcePath)
			kb's pressKey("enter")
		end openResourceViaUI
		
		
		on runShell(shellCommand)
			if running of application "Visual Studio Code" is false then return
			
			tell application "System Events" to tell process "Electron"
				if (count of windows) is 0 then return
				
				set frontmost to true
			end tell
			
			kb's pressCommandKey("`")
			kb's insertTextByPasting(shellCommand)
			kb's pressKey("enter")
		end runShell
		
		
		on isOpenInContainer()
			if running of application "Visual Studio Code" is false then return false
			
			tell application "System Events" to tell process "Electron"
				if (count of windows) is 0 then return false
				
				set windowName to name of first window
			end tell
			
			windowName contains "[Dev Container: "
		end isOpenInContainer
		
		
		on getDocumentName()
			if running of application "Visual Studio Code" is false then return missing value
			
			tell application "System Events" to tell process "Electron"
				if (count of windows) is 0 then return missing value
				
				set windowName to name of first window
			end tell
			
			set tokens to listUtil's _split(windowName, unic's SEPARATOR)
			if (count of tokens) is less than 2 then return missing value
			
			set latterPart to last item of tokens
			set filePath to first item of tokens
			set filePathTokens to textUtil's split(filePath, "/")
			last item of filePathTokens
		end getDocumentName
		
		
		on getDocumentPath()
			(* Extract path from the window title. *)
			tell application "System Events" to tell process "Electron"
				title of front window
				textUtil's split(result, unic's SEPARATOR)
			end tell
			first item of result
			return textUtil's replace(result, "~", "/Users/" & std's getUsername())
			
			
			set resourcePath to getResourcePath()
			if resourcePath is missing value then return missing value
			
			if isOpenInContainer() then
				return "/opt/app/" & getResourcePath()
			end if
			
			set projectName to getProjectName()
			set repoSubfolder to REPO_PROJECT_PATH's getValue(projectName)
			my PROJECTS_PATH & "/" & getProjectsPath()
		end getDocumentPath
		
		
		(* Get the file path relative to the "Projects" folder *)
		on getProjectsPath()
			return textUtil's replace(getDocumentPath(), PROJECTS_PATH & "/", "")
			
			set resourcePath to getResourcePath()
			if resourcePath is missing value then return missing value
			
			set projectName to getProjectName()
			-- logger's debugf("projectName: {}", projectName)
			
			set repoSubfolder to REPO_PROJECT_PATH's getValue(projectName)
			repoSubfolder & "/" & projectName & "/" & resourcePath
		end getProjectsPath
		
		on getProjectPath()
			set projectName to getProjectName()
			if projectName is missing value then return missing value
			
			(* Extract path from the window title. *)
			tell application "System Events" to tell process "Electron"
				title of front window
				textUtil's split(result, unic's SEPARATOR)
			end tell
			first item of result
			textUtil's stringBefore(result, projectName) & projectName
			return textUtil's replace(result, "~", "/Users/" & std's getUsername())
			
			(* For when the project is registered. *)
			set projectName to getProjectName()
			-- 			logger's debugf("projectName: {}", projectName)
			set repoSubfolder to REPO_PROJECT_PATH's getValue(projectName)
			-- 			logger's debugf("PROJECTS_PATH: {}", PROJECTS_PATH)
			-- 			logger's debugf("repoSubfolder: {}", repoSubfolder)			
			textUtil's join({PROJECTS_PATH, repoSubfolder, projectName}, "/") & "/"
		end getProjectPath
		
		(*
			Cases:
				Root resource selected
				Non-root resource selected
		*)
		on getResourcePath()
			if running of application "Visual Studio Code" is false then return missing value
			
			tell application "System Events" to tell process "Electron"
				if (count of windows) is 0 then return missing value
				
				set windowName to name of first window
			end tell
			
			set tokens to listUtil's _split(windowName, unic's SEPARATOR)
			if (count of tokens) is less than 2 then return missing value
			
			set latterPart to last item of tokens
			textUtil's stringAfter(first item of tokens, getProjectName() & "/")
		end getResourcePath
		
		
		on getProjectName()
			if running of application "Visual Studio Code" is false then return missing value
			
			tell application "System Events" to tell process "Electron"
				if (count of windows) is 0 then return missing value
				
				set windowName to name of first window
			end tell
			
			set tokens to listUtil's _split(windowName, unic's SEPARATOR)
			set latterPart to last item of tokens
			set firstPart to first item of tokens
			
			set openedInContainer to windowName contains "Dev Container"
			if openedInContainer then
				set projectFolderName to regex's findFirst(latterPart, "(?<=\\[Dev Container:\\s)([a-zA-Z-_]+?)(?=])")
			else
				set workSpaceKeyOffset to offset of " (workspace)" in latterPart
				set projectFolderName to text 1 thru (workSpaceKeyOffset - 1) of latterPart
			end if
			projectFolderName
		end getProjectName
		
		
		on getFileType()
			if running of application "Visual Studio Code" is missing value then return
			
			tell application "System Events" to tell process "Electron"
				if (count of windows) is 0 then return missing value
				
				set winName to name of first window
			end tell
			
			set winNameTokens to textUtil's split(winName, unic's SEPARATOR)
			if (count of winNameTokens) is less than 2 then return missing value
			
			set resourcePath to first item of winNameTokens
			
			set jestProjects to configBusiness's getValue("Jest Projects")
			if jestProjects contains getProjectName() and resourcePath ends with "spec.ts" then return "jest"
			
			-- if regex's matchesInString("pipeline.*gocd\\.yml", resourcePath) then return "GoCD Pipeline Config"
			
			set filenameTokens to textUtil's split(resourcePath, ".")
			if {"untitled"} contains resourcePath then return "unknown"
			if resourcePath is "requirements.txt" then return "python-package-definition"
			if resourcePath is "Find Results" then return "find-results"
			
			last item of filenameTokens
		end getFileType
	end script
end new
