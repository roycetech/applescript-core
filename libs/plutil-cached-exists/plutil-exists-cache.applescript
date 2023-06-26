(* 
	Prerequisites:
		redis
*)

use redisLib : script "redis"

property redis : redisLib's new()
property PLIST_EXISTS_CACHE : redisLib's new(1 * minutes)

(* *)
on decorate(baseScript)
	
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
