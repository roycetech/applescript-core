(*
	Enable Allow Javascript from Apple Events. Manual user authentication still required.

	@Created: Sat, Dec 13, 2025, at 10:04:54 AM
*)
use safariLib : script "core/safari"

set safari to safariLib's new()

activate application "Safari"
safari's showSettings()
safari's switchSettingsTab("Developer")

if safari's isAllowJavascriptFromAppleEvents() then
	log "Javascript is already allowed from Apple Events"

else
	safari's setAllowJavascriptFromAppleEventsOn()
	safari's respondAllow()
	log "Please authenticate to allow Javascript from Apple Events"
	delay 2
end if

safari's closeSettings()
""