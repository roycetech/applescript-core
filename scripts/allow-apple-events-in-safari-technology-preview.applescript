tell application "System Events" to tell process "Safari Technology Preview"
	try
		set allowJavaScriptMenu to menu item "Allow JavaScript from Apple Events" of menu 1 of menu bar item "Develop" of menu bar 1
		if value of attribute "AXMenuItemMarkChar" of allowJavaScriptMenu is missing value then
			click allowJavaScriptMenu
		end if
	end try
end tell
