use scripting additions

use class_a : script "class_a"


tell application "System Events"
	set scriptName to get name of (path to me)
end tell

log "class b"
log scriptName

class_a's hello()


on hello()
	log "calling a"
	class_a's hello()
	
	log "hello from b"
end