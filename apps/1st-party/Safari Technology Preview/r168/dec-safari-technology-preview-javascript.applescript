(*
	Update the following quite obvious if you read through the template code.:
	spotCheck()
		thisCaseId
		base library instantiation

		logger constructor parameter inside init handler

	decorate()
		instance name
		handler name
*)
use listUtil : script "list"

use loggerLib : script "logger"
use safariTechPreviewLib : script "safari-technology-preview"

use spotScript : script "spot-test"

property logger : loggerLib's new("dec-safari-technology-preview-javascript")
property safariTechPreview : safariTechPreviewLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "dec-safari-technology-preview-javascript"
	logger's start()
	
	set cases to listUtil's splitByLine("
		Basic
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	activate application "Safari Technology Preview"
	set frontTab to safariTechPreview's getFrontTab()
	if name of frontTab is not "ScriptSafariTechnologyPreviewJavaScript" then set frontTab to decorate(frontTab)
	
	if caseIndex is 1 then
		frontTab's runScriptPlain("alert('spot')")
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on newSpotBase()
	script SpotBaseInstance
		property template : missing value
	end script
end newSpotBase


(*  *)
on decorate(mainScript)
	logger's debug("decorating...")
	
	script ScriptSafariTechnologyPreviewJavaScript
		property parent : mainScript
		
		on runScriptPlain(scriptText)
			set theTab to _getTab()
			tell application "Safari Technology Preview" to do JavaScript scriptText in theTab
		end runScriptPlain
	end script
end decorate
