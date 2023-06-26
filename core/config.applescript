(*
	@Deployment:
		make compile-lib SOURCE=core/config		
*)

use plutilScript : script "plutil"
use loggerLib : script "logger"

property logger : loggerLib's new("config")
property plutilLib : plutilScript's new()
property filename : "~/applescript-core/config-default.plist"

(*
    Usage:
        use configLib :  script "config"
        
    property configUser : configLib's new("user")
    
    set DEPLOY_DIR to configUser's getValue("User Key")

    TODO: Optimize by creating new handlers with type like getValueString.
*)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	logger's start()
	set sut to new("system")
	
	log "^Existing Data start  =================="
	-- log sut's getValue("AppleScript Core Project Path")
	logger's infof("Raw value mapping: {}", sut's getValue("AppleScript Core Project Path"))
	logger's infof("Category value mapping: {}", sut's getCategoryValue("lib-factory", "UserInstance"))
	logger's infof("Defaults value mapping: {}", sut's getDefaultsValue("$Spot Check"))
	
	logger's finish()
	
	return
	
	(* Manual verifications. *)
	log "^Missing Data/Plist start =================="
	log sut's getValue("Non Existent!")
	try
		log sut's getCategoryValue("xlib-factory", "logger") -- Missing Config
		error "This should not be reached unless you actually have xlbi-factory.plist."
	end try
	log sut's getCategoryValue("lib-factory", "xlogger")
	log sut's getDefaultsValue("x$Spot Check")
	
	
	(*
	log getCategoryValue("work", "VPN Websites")
	log getCategoryValue("web", "FIND_RETRY_MAX")
	log getCategoryValue("applescript", "TERM_SEP")
	log getCategoryValue("bss", "DB_NAME")
	*)
	-- log getDefaultsValue("TERM_SEP")
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
			-- log "getCategoryValue category1: " & category & ", key: " & configKey
			set IS_SPOT to {"Script Editor", "Script Debugger"} contains the name of current application
			
			-- log "configName: " & configName
			if categoryPlist is missing value or category is not equal to the configName then
				set computedPlistName to "config-" & category
				if knownPlists contains computedPlistName then
					set categoryPlist to plutilLib's new(computedPlistName)
					
				else if plutilLib's plistExists(computedPlistName) then
					set categoryPlist to plutilLib's new(computedPlistName)
					set end of knownPlists to computedPlistName
					
				else
					return missing value
				end if
			end if
			
			return categoryPlist's getValue(configKey)
		end getCategoryValue
		
		
		on getValue(configKey)
			getCategoryValue(my configName, configKey)
		end getValue
	end script
end new
