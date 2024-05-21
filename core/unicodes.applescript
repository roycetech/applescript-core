(*
	@Known Issues:
		Fails to compile intermittently, but mostly it fails.

	@TODO:
		Migrate out domain-specific characters like the OMZ.

	@Build:
		make build-lib SOURCE=core/unicodes
*)

use scripting additions

use loggerLib : script "core/logger"
use configLib : script "core/config"

property logger : missing value
-- property config : configLib's new("default")

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set logger to loggerLib's new("unicodes")
	logger's start()

	logger's infof("Separator: {}", my SEPARATOR)
	logger's infof("App{}Store", my APP_STORE_SPACE)

	logger's finish()
end spotCheck

property WIFI : "Wi‑Fi"
property ELLIPSIS : "…"

(* Standard Mac OS Separator dash wrapped by space on both sides. *)
property SEPARATOR : " — "
property MAIL_SUBDASH : "–"
property ARROW_LEFT : "←"
property ARROW_RIGHT : "→"

property APP_STORE_SPACE : ASCII character 202
