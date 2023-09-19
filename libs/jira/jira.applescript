(*

*)

use script "core/Text Utilities"
use scripting additions

use listUtil : script "core/list"

use loggerFactory : script "core/logger-factory"

property logger : null

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()


	logger's finish()
end spotCheck


on new()
	loggerFactory's inject(me)

	script JiraInstance
		(*  *)
		on formatUrl(label, theUrl)
			format {"[{}|{}]", {label, theUrl}}
		end formatUrl

	end script
end new
