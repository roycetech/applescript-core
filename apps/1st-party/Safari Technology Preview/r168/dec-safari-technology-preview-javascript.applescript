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
use listUtil : script "core/list"

use safariTechPreviewLib : script "core/safari-technology-preview"

use loggerFactory : script "core/logger-factory"

use spotScript : script "core/spot-test"

property logger : missing value
property safariTechPreview : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set cases to listUtil's splitByLine("
		Basic
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set safariTechPreview to safariTechPreviewLib's new()
	logger's debug("decorating...")
	
	script ScriptSafariTechnologyPreviewJavaScript
		property parent : mainScript
		
		on runScriptPlain(scriptText)
			set theTab to _getTab()
			tell application "Safari Technology Preview" to do JavaScript scriptText in theTab
		end runScriptPlain
	end script
end decorate
