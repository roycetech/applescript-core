global std

(*
	Update the following quite obvious if you read through the template code.:
	spotCheck()
		thisCaseId
		base library instantiation

	init()
		logger constructor parameter inside init handler

	decorate()
		instance name
		handler name

*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "dec-safari-technology-preview-javascript"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Basic
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	activate application "Safari Technology Preview"
	set sut to std's import("safari-technology-preview")'s new()
	set frontTab to sut's getFrontTab()
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


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("dec-safari-technology-preview-javascript")
end init
