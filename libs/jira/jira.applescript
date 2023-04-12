global std

use script "Core Text Utilities"
use scripting additions

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	logger's start()
	
	unitTest()
	
	logger's finish()
end spotCheck


(*  *)
on formatUrl(label, theUrl)
	format {"[{}|{}]", {label, theUrl}}
end formatUrl

-- Private Codes below =======================================================
on unitTest()
	set utLib to std's import("unit-test")
	set ut to utLib's new()
	tell ut
		newMethod("formatUrl")
		assertEqual("[Google|http.google]", my formatUrl("Google", "http.google"), "Happy Case")
		
		done()
	end tell
end unitTest



(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("jira")
end init
