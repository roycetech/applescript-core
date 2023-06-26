use scripting additions

log "class a"

on hello()
	
	tell application "System Events"
		set scriptName to get name of (path to me)
	end tell
	
	log scriptName
end hello