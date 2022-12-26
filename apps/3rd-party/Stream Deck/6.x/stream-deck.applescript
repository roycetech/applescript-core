global std

(* 
	This script wraps some of the Elgato Stream Deck app functionality.
	This script is slow when changing profile via menu so we just ignored the 
	application response to prevent this script from blocking.
	
	@Requires:
		Elgato Stream Deck App
		Keyboard Maestro with Custom Macros

	@Installation:
		Run `make install` from this file's sub directory.		
*)

property logger : missing value
property initialized : false

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "stream-deck-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	set textUtil to std's import("string")
	
	set cases to listUtil's splitByLine("
		Manual: Switch Profile: Found
		Manual: Switch Profile: Not Found
		Switch Profile: Atom		
	")
	
	set spotLib to std's import("spot-test")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	if caseDesc starts with "Switch Profile:" then
		set caseProfile to textUtil's stringAfter(caseDesc, "Switch Profile: ")
		logger's debugf("caseProfile: {}", caseProfile)
		sut's switchProfile(caseProfile)
		
	end if
	if caseIndex is 1 then
		logger's infof("Switch Profile: Found: {}", sut's switchProfile("Work - Default"))
		
	else if caseIndex is 2 then
		logger's infof("Switch Profile: Not Found: {}", sut's switchProfile("Unicorn"))
		
	end if
	
	spot's finish()
	
	logger's finish()
end spotCheck


(*  *)
on new()
	if std's appExists("Elgato Stream Deck") is false then error "Elgato Stream Deck app needs to be installed"
	
	script StreamDeckInstance
		
		(* 
			Very slow without the ignoring block.
			
			@returns true if the profile was found, else false. (Not implemented due to performance issue)
		*)
		on switchProfile(profileName)
			ignoring application responses
				tell application "System Events" to tell process "Stream Deck"
					try
						click menu bar item 1 of menu bar 2
					end try
				end tell
			end ignoring
			
			delay 0.1
			
			ignoring application responses
				tell application "System Events" to tell process "Stream Deck"
					try
						click menu item profileName of menu 1 of menu bar item 1 of menu bar 2
						return true
					end try
				end tell
			end ignoring
			false
		end switchProfile
	end script
end new


-- Private Codes below =======================================================

(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("stream-deck")
end init