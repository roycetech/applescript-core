(*
	@Purpose:
		Commonly used unicodes in a macOS System.

	@Project:
		applescript-core

	@Build:
		./scripts/build-lib.sh core/unicodes

	@Known Issues:
		May fail to build using external shell tool because the file read may fail due to the presence of unicode characters.  Build manually or using the command line instead.

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
	logger's infof("Menu Checked", my MENU_CHECK)

	logger's finish()
end spotCheck

property WIFI : "Wi‑Fi"
property ELLIPSIS : "…"

(* Standard Mac OS Separator dash wrapped by space on both sides. *)
property SEPARATOR : " — "
property MAIL_SUBDASH : "–"
property ARROW_LEFT : "←"
property ARROW_RIGHT : "→"
property MENU_CHECK : "✓"

property APP_STORE_SPACE : ASCII character 202
