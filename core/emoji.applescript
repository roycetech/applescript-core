(*
	@Deployment:
		make compile-lib SOURCE=core/emoji
*)

use loggerFactory : script "logger-factory"
use configLib : script "config"

property config : configLib's new("emoji")

property logger : missing value

property WORK : config's getValue("EMOJI_WORK")
property FAUCET : config's getValue("EMOJI_FAUCET")

property TUBE : config's getValue("EMOJI_TUBE")
property WEB : config's getValue("EMOJI_WEB")
property GUARD : config's getValue("EMOJI_GUARD")
property QA : config's getValue("EMOJI_QA")
property BOT : config's getValue("EMOJI_BOT")
property CLOCK : config's getValue("EMOJI_CLOCK")
property CHECK : config's getValue("EMOJI_CHECK")
property DASH : config's getValue("DASH")
property ELLIPSIS : config's getValue("UNICODE_ELLIPSIS")
property RED_Q : config's getValue("EMOJI_RED_QM")
property NOTE_BLACK : config's getValue("EMOJI_NOTE_BLACK")
property NOTE_YELLOW : config's getValue("EMOJI_NOTE_YELLOW")
property ANT : config's getValue("EMOJI_ANT")
property PENCIL_FLAT : config's getValue("EMOJI_PENCIL_FLAT")
property PENCIL_DOWN : config's getValue("EMOJI_PENCIL_DOWN")

property HORN : config's getValue("EMOJI_HORN")
property PERSON : config's getValue("EMOJI_PERSON")
property PHONE : config's getValue("EMOJI_PHONE")
property DOMAIN : config's getValue("EMOJI_DOMAIN")
property PLUG : config's getValue("EMOJI_PLUG")
property THUNDER : config's getValue("EMOJI_THUNDER")
property WHITE_CHECK : config's getValue("EMOJI_WHITE_CHECK")
property RED_CROSS : config's getValue("EMOJI_RED_CROSS")
property TRASH_BIN : config's getValue("EMOJI_TRASH")
property HISTORY : config's getValue("EMOJI_HISTORY")
property PIN : config's getValue("EMOJI_PIN")
property CIRCLE_GREEN : config's getValue("EMOJI_CIRCLE_WHITE")
property CIRCLE_RED : config's getValue("EMOJI_CIRCLE_GREEN")
property CIRCLE_WHITE : config's getValue("EMOJI_CIRCLE_RED")
property SQUARE_GREEN : config's getValue("EMOJI_SQUARE_GREEN")
property SQUARE_RED : config's getValue("EMOJI_SQUARE_RED")

property useBasicLogging : false

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set useBasicLogging to true
	loggerFactory's inject(me, "emoji")
	
	set thisCaseId to "emoji-spotCheck"
	logger's start()
	
	logger's infof("Work: {}", my WORK)
	logger's infof("Faucet: {}", my FAUCET)
	
	logger's finish()
end spotCheck
