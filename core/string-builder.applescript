global std

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "string-builder-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Happy
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	if caseIndex is 1 then
		set sut to new("the")
		sut's append(" big")'s append(" brown")'s append(" fox")
		log sut's toString()
		
	else if caseIndex is 2 then
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
to new(initialValue)
	script StringBuilderInstance
		property textValue : initialValue
		
		on append(textToAppend)
			set textValue to textValue & textToAppend
			me
		end append
		
		on toString()
			textValue
		end toString
	end script
end new

-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("string-builder")
end init

