(*
	Allows spot library to be triggered using Elgato Stream Deck app.

	@TODO:
		Migrate this out because this is too user-centric.
	
	@Requires:
		Elgato Stream Deck App
		Keyboard Maestro with Custom Macros
			Script Editor: Stream Deck: Refresh Case Desc
			Script Editor: Stream Deck: Update Case Index

	@Installation:
		Run `make install` from this file's sub directory.

	@Build:
		osacompile -o ~/Library/Script\ Libraries/dec-spot-stream-deck.scpt 'apps/3rd-party/Stream Deck/6.x/dec-spot-stream-deck..applescript'

	@Last Modified: 
*)

use std : script "core/std"

use loggerFactory : script "core/logger-factory"
use listUtil : script "core/list"
use kmLib : script "core/keyboard-maestro"
use textUtil : script "core/string"

property logger : missing value
property km : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)

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

	script SpotStreamDeckDecorator
		property parent : BaseScript
		
		on setSessionCaseId(newCaseId)
			continue setSessionCaseId(newCaseId)
			
			if std's appExists("Stream Deck") is false then return
			
			km's runMacro("Script Editor: Stream Deck: Refresh Case Desc")
		end setSessionCaseId
		
		on setSessionCaseIndex(newCaseIndex)
			continue setSessionCaseIndex(newCaseIndex)
			
			if std's appExists("Stream Deck") is false then return
			
			km's runMacro("Script Editor: Stream Deck: Refresh Case Index")
		end setSessionCaseIndex
	end script
end decorate
