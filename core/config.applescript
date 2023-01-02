property filename : "~/applescript-core/config-default.plist"
property plutil : missing value

(*
    Usage:
        set config to std's import("config")'s new("<config suffix>")
        set DEPLOY_DIR to config's getCategoryValue("work", "DEPLOY_DIR")

    TODO: Optimize by creating new handlers with type like getValueString.
*)

if name of current application is "Script Editor" then spotCheck()

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
		property categoryPlist : missing value
		property knownPlists : {"config-default", "session", "switches"} -- WET: 1/2
		
		on getBool(configKey)
			getBool(configKey)
		end getBool
		
		
		on getDefaultsValue(configKey)
			getCategoryValue("default", configKey)
		end getDefaultsValue
		
		
		on getCategoryValue(category, configKey)
			set IS_SPOT to (name of current application is "Script Editor")
			
			if plutil is missing value then
				set plutilLib to script "plutil"
				plutilLib's init()
				set plutil to plutilLib's new()
			end if
			
			if categoryPlist is missing value then
				set computedPlistName to "config-" & category
				if knownPlists contains computedPlistName then
					set categoryPlist to plutil's new(computedPlistName)

				else if plutil's plistExists(computedPlistName) then
					set categoryPlist to plutil's new(computedPlistName)
					set end of knownPlists to computedPlistName

				else 
					return missing value
				end if
			end if

			return categoryPlist's getValue(configKey)
			
			if IS_SPOT then
				set startSeconds to do shell script "date +%s"
				-- log "measuring..." & category & ":" & configKey
			end if
			
			set plistItems to {filename, category, 1, configKey}
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
