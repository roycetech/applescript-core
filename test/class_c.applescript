use scripting additions

use class_b : script "class_b"

tell application "System Events"
	set scriptName to get name of (path to me)
end tell

log "class c"
log scriptName

hello()

on hello()
	log "calling b"
	class_b's hello()
	
	log "hello from c"
end hello

