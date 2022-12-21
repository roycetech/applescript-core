global std

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "emoji-spotCheck"
	logger's start()
	
	logger's infof("Work: {}", my WORK)
	logger's infof("Faucet: {}", my FAUCET)
	
	logger's finish()
end spotCheck

property work : missing value
property TUBE : missing value
property WEB : missing value
property GUARD : missing value
property QA : missing value
property BOT : missing value
property CLOCK : missing value
property CHECK : missing value
property DASH : missing value
property ELLIPSIS : missing value
property HORN : missing value
property RED_Q : missing value
property NOTE_BLACK : missing value
property NOTE_YELLOW : missing value
property CHECKBOX : missing value
property ANT : missing value
property INFO : missing value
property PENCIL_FLAT : missing value
property PENCIL_DOWN : missing value
property PERSON : missing value
property PHONE : missing value
property faucet : missing value
property DOMAIN : missing value
property PLUG : missing value
property THUNDER : missing value
property WHITE_CHECK : missing value
property RED_CROSS : missing value
property TRASH_BIN : missing value
property HISTORY : missing value
property PIN : missing value
property CIRCLE_GREEN : missing value
property CIRCLE_RED : missing value
property CIRCLE_WHITE : missing value
property SQUARE_GREEN : missing value
property SQUARE_RED : missing value

-- Private Codes below =======================================================
(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("emoji")
	set config to std's import("config")'s new("emoji")
	
	set work to config's getValue("EMOJI_WORK")
	set TUBE to config's getValue("EMOJI_TUBE")
	set WEB to config's getValue("EMOJI_WEB")
	set GUARD to config's getValue("EMOJI_GUARD")
	set QA to config's getValue("EMOJI_QA")
	set BOT to config's getValue("EMOJI_BOT")
	set CLOCK to config's getValue("EMOJI_CLOCK")
	set CHECK to config's getValue("EMOJI_CHECK")
	set DASH to config's getValue("DASH")
	set ELLIPSIS to config's getValue("UNICODE_ELLIPSIS")
	set HORN to config's getValue("EMOJI_HORN")
	set RED_Q to config's getValue("EMOJI_RED_QM")
	set NOTE_BLACK to config's getValue("EMOJI_NOTE_BLACK")
	set NOTE_YELLOW to config's getValue("EMOJI_NOTE_YELLOW")
	set INFO to config's getValue("EMOJI_INFO")
	set ANT to config's getValue("EMOJI_ANT")
	set CHECKBOX to config's getValue("EMOJI_CHECKBOX")
	set PENCIL_FLAT to config's getValue("EMOJI_PENCIL_FLAT")
	set PENCIL_DOWN to config's getValue("EMOJI_PENCIL_DOWN")
	set PERSON to config's getValue("EMOJI_PERSON")
	set PHONE to config's getValue("EMOJI_PHONE")
	set faucet to config's getValue("EMOJI_FAUCET")
	set DOMAIN to config's getValue("EMOJI_DOMAIN")
	set PLUG to config's getValue("EMOJI_PLUG")
	set THUNDER to config's getValue("EMOJI_THUNDER")
	set WHITE_CHECK to config's getValue("EMOJI_WHITE_CHECK")
	set RED_CROSS to config's getValue("EMOJI_RED_CROSS")
	set TRASH_BIN to config's getValue("EMOJI_TRASH")
	set HISTORY to config's getValue("EMOJI_HISTORY")
	set PIN to config's getValue("EMOJI_PIN")
	set CIRCLE_WHITE to config's getValue("EMOJI_CIRCLE_WHITE")
	set CIRCLE_GREEN to config's getValue("EMOJI_CIRCLE_GREEN")
	set CIRCLE_RED to config's getValue("EMOJI_CIRCLE_RED")
	set SQUARE_GREEN to config's getValue("EMOJI_SQUARE_GREEN")
	set SQUARE_RED to config's getValue("EMOJI_SQUARE_RED")
end init
