global std
global km

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

(* *)

on decorate(baseScript)
	init()
	
	script SpotStreamDeckInstance
		property parent : baseScript
		
		on setSessionCaseId(newCaseId)
			continue setSessionCaseId(newCaseId)
			if std's appExists("Stream Deck") is false then return
			
			km's setVariable("km_spotName", textUtil's replace(newCaseId, "-spotCheck", "-$"))
			km's runScript("Script Editor: Update Stream Deck Case Desc")
		end setSessionCaseId
	end script
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	if std's appExists("Stream Deck") then
		set km to std's import("keyboard-maestro")
		set textUtil to std's import("string")
	end if
end init