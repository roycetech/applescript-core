(*
	@Known Issues:
		Fails to compile intermittently, but mostly it fails.

	@Deployment:
		make compile-lib SOURCE=core/unicodes
*)

use scripting additions

use loggerLib : script "logger"
use configLib : script "config"

property logger : loggerLib's new("unicodes")
property config : configLib's new("default")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	
	log my SEPARATOR
	log "App" & my APP_STORE_SPACE & "Store"
	
	logger's finish()
end spotCheck

property WIFI : config's getValue("UNICODE_WIFI")
property ELLIPSIS : config's getValue("UNICODE_ELLIPSIS")

(* Standard Mac OS Separator dash wrapped by space on both sides. *)
property SEPARATOR : config's getValue("UNICODE_SEP")
property MAIL_SUBDASH : config's getValue("UNICODE_ARROW_LEFT")
property ARROW_LEFT : config's getValue("UNICODE_ARROW_RIGHT")
property ARROW_RIGHT : config's getValue("UNICODE_MAIL_SUBDASH")
property OMZ_ARROW : config's getValue("UNICODE_OMZ_ARROW")
property OMZ_GIT_X : config's getValue("UNICODE_OMZ_GIT_X")

property APP_STORE_SPACE : ASCII character 202
