(*
	@Project:
		applescript-core
		
	@Build:
		make build-intellij
		
	@Created: September 9, 2023 3:06 PM
	@Last Modified: July 24, 2023 10:56 AM
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

use spotScript : script "core/spot-test"

property logger : missing value
property kb : missing value
property config : missing value
property IDEA_CLI : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Noop
		Manual: Open Project
		Manual: Open File Path
		Manual: Toggle Scheme
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
	logger's debugf("sutProjectFilePath: {}", sutProjectFilePath)
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's openProject(sutProjectPath)
		
	else if caseIndex is 3 then
		sut's openFile(sutProjectFilePath)
		
	else if caseIndex is 4 then
		sut's toggleScheme()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set configSystem to configLib's new("system")
	set IDEA_CLI to configSystem's getValue("IntelliJ CLI")
	
	script IntelliJIDEAInstance
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
			if running of application "IntelliJ IDEA" is false then return missing value
			
			tell application "System Events" to tell process "idea"
				textUtil's split(name of front window, " " & unic's MAIL_SUBDASH & " ")
			end tell
			first item of result
		end getCurrentProjectName
		
		
		on getCurrentDocumentName()
			if running of application "IntelliJ IDEA" is false then return missing value
			
			tell application "System Events" to tell process "idea"
				textUtil's split(name of front window, " " & unic's MAIL_SUBDASH & " ")
			end tell
			last item of result
		end getCurrentDocumentName
		
		
		(* Change to the next scheme (called theme on most other editors) *)
		on toggleScheme()
			activate application "IntelliJ IDEA"
			delay 0.1
			kb's pressControlKey("`")
			kb's pressKey("enter") -- Choose the "Edit Color Scheme"
			kb's pressKey("enter") -- Choose the pre-selected next theme.
			delay 0.1 -- Fails without this
			tell application "System Events" to tell process "idea"
				click (first button of window "Change IntelliJ IDEA Theme" whose description is "Yes")
			end tell
		end toggleScheme
	end script
	
	set decorator to decoratorLib's new(result)
	decorator's decorate()
end new

