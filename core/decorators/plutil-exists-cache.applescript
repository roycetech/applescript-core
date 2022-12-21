global std, redis
global PLIST_EXISTS_CACHE

(* 
	@Deprecated:
		Optimizing config.applescript made this component unnecessary.

	Prerequisites:
		redis

	Compile:
		make compile-lib SOURCE=core/decorators/plutil-exists-cache
*)

property initialized : false

(* *)

on decorate(baseScript)
	init()

	script PlutilExistsCachedInstance
		property parent : baseScript
		
		on plistExists(plistName)
			set keyName to "plistExists-" & plistName
			if PLIST_EXISTS_CACHE's getBool(keyName) is false then
				set actualResult to continue plistExists(plistName)
				PLIST_EXISTS_CACHE's setValue(keyName, actualResult)
				return actualResult
			end if
			
			true
		end plistExists
	end script
end decorate


on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set redisLib to std's import("redis")
	set PLIST_EXISTS_CACHE to redisLib's new(1 * minutes)
end init