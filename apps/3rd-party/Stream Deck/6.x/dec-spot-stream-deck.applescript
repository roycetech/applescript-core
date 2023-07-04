(*
	Allows spot library to be triggered using Elgato Stream Deck app.
	
	@Requires:
		Elgato Stream Deck App
		Keyboard Maestro with Custom Macros

	@Installation:
		Run `make install` from this file's sub directory.

	@Build:
		osacompile -o ~/Library/Script\ Libraries/dec-spot-stream-deck.scpt 'apps/3rd-party/Stream Deck/6.x/dec-spot-stream-deck..applescript'
*)

use std : script "std"

use loggerFactory : script "logger-factory"
use listUtil : script "list"
use kmLib : script "keyboard-maestro"
use textUtil : script "string"

property logger : missing value
property km : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me, "dec-spot-stream-deck")

	script BaseScript
		on setSessionCaseId(newCaseId)
			logger's debugf("New Case ID: {}", newCaseId)
		end setSessionCaseId
	end script
	set sut to decorate(BaseScript)
	sut's setSessionCaseId(98)
	-- Manually verify that the stream deck displays the number above.
end spotCheck

(* *)

on decorate(BaseScript)
	set km to kmLib's new()

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
