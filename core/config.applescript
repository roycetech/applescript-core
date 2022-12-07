property filename : "~/applescript-core/config-default.plist"
property category : "default"
property plist : missing value

(*
    Usage:
        set config to std's import("config")'s new("<config suffix>")
        set DEPLOY_DIR to config's getCategoryValue("work", "DEPLOY_DIR")

    TODO: Optimize by creating new handlers with type like getValueString.
*)

if name of current application is "Script Editor" then spotCheck() -- IMPORTANT: Comment out on deploy

on spotCheck()
	log "start"
	set sut to new("system")
	
	(* Manual verifications. *)
	log "^Missing Data/Plist start"
	log sut's getValue("Non Existent!")
	try
		log sut's getCategoryValue("xlib-factory", "logger") -- Missing Config
		error "This should not be reached unless you actually have xlbi-factory.plist."
	end try
	log sut's getCategoryValue("lib-factory", "xlogger")
	log sut's getDefaultsValue("x$Spot Check")
	
	log "^Existing Data"
	log sut's getValue("AppleScript Core Project Path")
	log sut's getCategoryValue("lib-factory", "logger")
	log sut's getDefaultsValue("$Spot Check")
	
	(*
	log getCategoryValue("work", "VPN Websites")
	log getCategoryValue("web", "FIND_RETRY_MAX")
	log getCategoryValue("applescript", "TERM_SEP")
	log getCategoryValue("bss", "DB_NAME")
	*)
	-- log getDefaultsValue("TERM_SEP")
	log "end"
end spotCheck


(* @configName the plist name be default. *)
on new(pConfigName)
	
	if pConfigName is "" or pConfigName is missing value then
		set localConfigName to "default"
	else
		set localConfigName to pConfigName
	end if
	
	script ConfigInstance
		property configName : localConfigName
		
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
			
			
			set knownPlists to {"config-default", "session", "switches"} -- WET: 1/2
			set computedPlistName to "config-" & theCategory
			if knownPlists contains computedPlistName or plist's plistExists(computedPlistName) then
				set categoryPlist to plist's new(computedPlistName)
				return categoryPlist's getValue(configKey)
			end if
			
			if IS_SPOT then
				set startSeconds to do shell script "date +%s"
				-- log "measuring..." & theCategory & ":" & configKey
			end if
			
			set plistItems to {filename, theCategory, 1, configKey}
			try
				set startSeconds to do shell script "date +%s"
				-- log "measuring..."
				tell application "System Events"
					set theElement to property list file (filename as text) -- root element
				end tell
				set T2s to do shell script "date +%s"
				set elapsed to T2s - startSeconds
				
				-- log "elapsed: " & elapsed
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
			getCategoryValue(my configName, configKey)
		end getValue
	end script
end new
