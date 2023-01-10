tell application "System Events" to tell process "Safari"
	try
		click menu item "Allow JavaScript From Apple Events" of menu 1 of menu bar item "Develop" of menu bar 1
	end try
end tell
