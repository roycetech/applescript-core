(*
	Will trigger the "Allow JavaScript from Apple Events" in the menu for the AppleScripts to work with the app.

	DOES NOT WORK. Perform this manually instead.

	@Created: December 31, 2023 4:46 PM
*)
activate application "Microsoft Edge"

tell application "System Events" to tell process "Microsoft Edge"
	set frontmost to true
	try
		set allowJavaScriptMenu to menu item "Allow JavaScript from Apple Events" of menu 1 of menu item "Developer" of menu 1 of menu bar item "Tools" of menu bar 1
		if value of attribute "AXMenuItemMarkChar" of allowJavaScriptMenu is missing value then
			log "Clicking the menu"
			-- click allowJavaScriptMenu
			click menu item "Allow JavaScript from Apple Events" of menu 1 of menu item "Developer" of menu 1 of menu bar item "Tools" of menu bar 1
			-- click menu item "View Source" of menu 1 of menu item "Developer" of menu 1 of menu bar item "Tools" of menu bar 1

			-- click menu item "Refresh This Page" of menu 1 of menu bar item "View" of menu bar 1
		end if

	on error the errorMessage number the errorNumber
		log errorMessage
	end try
end tell
