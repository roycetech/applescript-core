global IS_SPOT

property filename : "~/applescript-core/config-default.plist"
property category : "default"
property plist : missing value

(*
    Usage:
        set config to std's import("config")'s newInstance()
        set DEPLOY_DIR to config's getCategoryValue("work", "DEPLOY_DIR")
*)

set IS_SPOT to (name of current application is "Script Editor")
-- spotCheck() -- IMPORTANT: Comment out on deploy

on spotCheck()
	log "start"
	log getCategoryValue("work", "VPN Websites")
	log getCategoryValue("web", "FIND_RETRY_MAX")
	log getCategoryValue("applescript", "TERM_SEP")
	log getCategoryValue("bss", "DB_NAME")
	-- log getDefaultsValue("TERM_SEP")
	log "end"
end spotCheck


on newInstance()
	script ConfigInstance
		on getBool(configKey)
			getBool(configKey)
		end getBool


		on getDefaultsValue(configKey)
			getCategoryValue("default", configKey)
		end getDefaultsValue


		on getCategoryValue(theCategory, configKey)
			set IS_SPOT to (name of current application is "Script Editor")
			
			if plist is missing value then
				set plist to script "plutil"
				plist's init()
			end if
			
			set computedPlistName to "config-" & theCategory
			if plist's plistExists(computedPlistName) then
				set categoryPlist to plist's newInstance(computedPlistName)
				return categoryPlist's getValue(configKey)
			end if
			
			if IS_SPOT then
				set startSeconds to do shell script "date +%s"
				log "measuring..." & theCategory & ":" & configKey
			end if
			
			set plistItems to {filename, theCategory, 1, configKey}
			try
				set startSeconds to do shell script "date +%s"
				log "measuring..."
				tell application "System Events"
					set theElement to property list file (filename as text) -- root element
				end tell
				set T2s to do shell script "date +%s"
				set elapsed to T2s - startSeconds
				
				log "elapsed: " & elapsed
				repeat with anItem in rest of plistItems -- add on the sub items 
					try
						set anItem to anItem as integer -- index number?
					end try
					tell application "System Events"
						set theElement to (get property list item anItem of theElement)
					end tell
				end repeat
				tell application "System Events" to return value of theElement
			on error errMess number errNum
				error "getValue error:  " & errMess & " (" & errNum & ")" -- pass it on
			end try
		end getCategoryValue


		on getValue(configKey)
			getCategoryValue(category, configKey)
		end getValue
	end script
end newInstance
