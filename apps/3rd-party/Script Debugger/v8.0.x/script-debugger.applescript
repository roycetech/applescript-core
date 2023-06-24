(*

*)

use loggerLib : script "logger"

property logger : loggerLib's new("script-debugger")

property DOC_EDITED_SUFFIX : " – Edited"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set thisCaseId to "script-debugger-spotCheck"
	logger's start()
	
	logger's finish()
end spotCheck


(*  *)
on new()
	script LibraryInstance
		on libHandler()
			
		end libHandler
	end script
end new


-- Private Codes below =======================================================
