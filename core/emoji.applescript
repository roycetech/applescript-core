(*
	@Deployment:
		make compile-lib SOURCE=core/emoji
		
	@Known Issues:
		errOSAInternalTableOverflow - Just by adding new line, sometime it even crashes the app.
		
*)


use loggerFactory : script "logger-factory"
use configLib : script "config"

log 1
log 2

property config : configLib's new("emoji")
property logger : missing value

property WORK : missing value
property FAUCET : missing value
property TUBE : missing value
property WEB : missing value
property GUARD : missing value
property QA : missing value
property BOT : missing value
property CLOCK : missing value
property CHECK : missing value
property RED_Q : missing value
property NOTE_BLACK : missing value
property NOTE_YELLOW : missing value
property ANT : missing value
property PENCIL_FLAT : missing value
property PENCIL_DOWN : missing value
property HORN : missing value
property PERSON : missing value
property PHONE : missing value
property DOMAIN : missing value
property PLUG : missing value
property THUNDER : missing value
property WHITE_CHECK : missing value
property RED_CROSS : missing value
property TRASH_BIN : missing value
property HISTORY : missing value
property PIN : missing value
property CIRCLE_GREEN : "🟢"
property CIRCLE_RED : missing value
property CIRCLE_WHITE : missing value
property SQUARE_GREEN : missing value
property SQUARE_RED : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me, "emoji")
	
	new()
	
	set thisCaseId to "emoji-spotCheck"
	logger's start()
	
	logger's infof("Work: {}", my WORK)
	logger's infof("Faucet: {}", my FAUCET)
	logger's infof("Guard: {}", my GUARD)
	
	logger's finish()
end spotCheck


on new()
	log 2
	
	set WORK to config's getValue("EMOJI_WORK")
	set FAUCET to config's getValue("EMOJI_FAUCET")
	set TUBE to config's getValue("EMOJI_TUBE")
	set WEB to config's getValue("EMOJI_WEB")
	set GUARD to config's getValue("EMOJI_GUARD")
	set QA to config's getValue("EMOJI_QA")
	set BOT to config's getValue("EMOJI_BOT")
	set CLOCK to config's getValue("EMOJI_CLOCK")
	set CHECK to config's getValue("EMOJI_CHECK")
	set RED_QM to config's getValue("EMOJI_RED_QM")
	set NOTE_BLACK to config's getValue("EMOJI_NOTE_BLACK")
	set NOTE_YELLOW to config's getValue("EMOJI_NOTE_YELLOW")
	set ANT to config's getValue("EMOJI_ANT")
	set PENCIL_FLAT to config's getValue("EMOJI_PENCIL_FLAT")
	set PENCIL_DOWN to config's getValue("EMOJI_PENCIL_DOWN")
	set HORN to config's getValue("EMOJI_HORN")
	set PERSON to config's getValue("EMOJI_PERSON")
	set PHONE to config's getValue("EMOJI_PHONE")
	set DOMAIN to config's getValue("EMOJI_DOMAIN")
	set PLUG to config's getValue("EMOJI_PLUG")
	set THUNDER to config's getValue("EMOJI_THUNDER")
	set WHITE_CHECK to config's getValue("EMOJI_WHITE_CHECK")
	set RED_CROSS to config's getValue("EMOJI_RED_CROSS")
	set TRASH to config's getValue("EMOJI_TRASH")
	set HISTORY to config's getValue("EMOJI_HISTORY")
	set PIN to config's getValue("EMOJI_PIN")
	set CIRCLE_WHITE to config's getValue("EMOJI_CIRCLE_WHITE")
	set CIRCLE_GREEN to config's getValue("EMOJI_CIRCLE_GREEN")
	set CIRCLE_RED to config's getValue("EMOJI_CIRCLE_RED")
	set SQUARE_GREEN to config's getValue("EMOJI_SQUARE_GREEN")
	set SQUARE_RED to config's getValue("EMOJI_SQUARE_RED")
end new