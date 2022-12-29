global std
global km, textUtil

(*
	Allows spot library to be triggered using Elgato Stream Deck app.
	
	@Requires:
		Elgato Stream Deck App
		Keyboard Maestro with Custom Macros

	@Installation:
		Run `make install` from this file's sub directory.
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	script BaseScript
		on setSessionCaseId(newCaseId)
			logger's debugf("New Case ID: {}", newCaseId)
		end setSessionCaseId
	end script
	set sut to decorate(BaseScript)
	sut's setSessionCaseId(99)
end spotCheck

(* *)

on decorate(BaseScript)
	init()
	
	script SpotTestStreamDeckInstance
		property parent : BaseScript
		
		on setSessionCaseId(newCaseId)
			continue setSessionCaseId(newCaseId)
			if std's appExists("Stream Deck") is false then return
			
			km's setVariable("km_spotName", textUtil's replace(newCaseId, "-spotCheck", "-$"))
			km's runScript("Script Editor: Update Stream Deck Case Desc")
		end setSessionCaseId

		on setSessionCaseIndex(newCaseIndex)
			continue setSessionCaseIndex(newCaseIndex)
			
			if std's appExists("Stream Deck") is false then return
			
			km's setVariable("km_caseIndex", newCaseIndex)
			km's runScript("Script Editor: Update Stream Deck Case Index")
		end setSessionCaseIndex		
	end script
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("doc-spot-stream-deck")
	
	if std's appExists("Stream Deck") then
		set km to std's import("keyboard-maestro")'s new()
		set textUtil to std's import("string")
	end if
end init