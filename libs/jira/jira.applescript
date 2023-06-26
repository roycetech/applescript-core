use script "Core Text Utilities"
use scripting additions

use listUtil : script "list"

use loggerLib : script "logger"

use testLib : script "test"

property logger : loggerLib's new("jira")
property test : testLib's new()

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	unitTest()
	
	logger's finish()
end spotCheck


(*  *)
on formatUrl(label, theUrl)
	log 3
	format {"[{}|{}]", {label, theUrl}}
end formatUrl


-- Private Codes below =======================================================
on unitTest()
	set ut to test's new()
	tell ut
		newMethod("formatUrl")
		assertEqual("[Google|http.google]", my formatUrl("Google", "http.google"), "Happy Case")
		
		done()
	end tell
end unitTest
