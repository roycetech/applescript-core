(*
	@Build:
		make build-lib SOURCE=core/string-builder
*)

use listUtil : script "core/list"
use loggerFactory : script "core/logger-factory"
use spotScript : script "core/spot-test"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()

	set cases to listUtil's splitByLine("
		Happy
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
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
on new(initialValue)
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
