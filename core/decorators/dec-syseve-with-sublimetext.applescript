global std

(* 
	Prerequisites:
		Sublime Text app installed.

	Install:
		make compile-lib SOURCE=core/decorators/dec-syseve-with-sublimetext
		plutil -replace 'SysEveInstance' -string 'dec-syseve-with-sublimetext' ~/applescript-core/config-lib-factory.plist

	Uninstall:
		make remove-lib SOURCE=core/decorators/dec-syseve-with-sublimetext
		plutil -remove 'SysEveInstance' ~/applescript-core/config-lib-factory.plist
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set caseId to "dec-keyboard-dvorak-cmd-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	-- All spot check cases are manual.
	set cases to listUtil's splitByLine("
		Basic Test
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(caseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	
	set sut to std's import("syseve")'s new()
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
	init()
	
	script SyseveSublimeTextInstance
		property parent : baseScript
		
		on getFrontAppName()
			set frontAppName to continue getFrontAppName()
			if frontAppName is "sublime_text" then return "Sublime Text"
			
			frontAppName
		end getFrontAppName
		
	end script
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-syseve-with-sublimetext")
end init