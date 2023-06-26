global std

(* 
	@Prerequisites:
		Sublime Text app installed.

	@Install/Uninstall:
		make install-sublime-text
		Install/Uninstall this with the other Sublime Text related libraries by 
		running `make install` or make uninstall in this file's sub directory.
*)
use listUtil : script "list"

use spotScript : script "spot-test"

use loggerLib : script "logger"
use syseveLib : script "system-events"

property logger : loggerLib's new("dec-syseve-with-sublime-text")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set caseId to "dec-keyboard-dvorak-cmd-spotCheck"
	logger's start()
	
	-- All spot check cases are manual.
	set cases to listUtil's splitByLine("
		Basic Test
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to syseveLib's new()
	if name of sut is not "SyseveSublimeTextInstance" then set sut to decorate(sut)
	
	activate application "Sublime Text"
	delay 0.01
	
	if caseIndex is 1 then
		logger's infof("Process Name: {}", sut's getFrontAppName())
		
	end if
	activate
	
	spot's finish()
	logger's finish()
end spotCheck

(* *)

on decorate(baseScript)
	
	script SyseveSublimeTextInstance
		property parent : baseScript
		
		on getFrontAppName()
			set frontAppName to continue getFrontAppName()
			if frontAppName is "sublime_text" then return "Sublime Text"
			
			frontAppName
		end getFrontAppName
		
	end script
end decorate
