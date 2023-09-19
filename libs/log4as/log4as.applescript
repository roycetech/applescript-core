(*
	@Plists:
		log4as
			defaultLevel
			printToConsole
			categories

	WARNINGs:
		Do not use logger here, circular dependency to self is not good.
		Keys in the plist are case-sensitive!

	@Build:
		make compile-lib SOURCE=libs/log4as/log4as

	@Known Issues:
		July 3, 2023 2:07 PM - Default log prints multiple times for each
		library that uses this. The main benefit is that we can update the
		config and get the new values used. So we just hide the default level
		log print out for now.
*)

use std : script "core/std"

use listUtil : script "core/list"
use mapLib : script "core/map"
use plistBuddyLib : script "core/plist-buddy"

use spotScript : script "core/spot-test"

(* A bit confusing initially but the idea is, the higher the number, the more chances of getting logged. *)
property level : {debug:1, info:2, warn:3, ERR:4, OFF:5}
property defaultLevel : info of level

(* Default plist name *)
property plistName : "log4as"
(* List of classes from log4as.plist, categories.*)
property plistBuddyLog4as : missing value
property logClasses : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

(*
	Note: Bad idea to use logger here for spot checking.
*)
on spotCheck()
	-- logger's start()

	set cases to listUtil's splitByLine("
		Manual: Config Info
		Manual: Is Printable (un/registered, less, equal, greater, OFF)
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		return
	end if

	set sut to new()
	if caseIndex is 1 then
		log "Default Level: " & LOG4AS_CONFIG's getValue("defaultLevel")
		log "Print to console: " & LOG4AS_CONFIG's getValue("printToConsole")
		log "Write to file: " & LOG4AS_CONFIG's getValue("writeToFile")
		set categories to LOG4AS_CONFIG's getValue("categories")
		if categories is missing value then
			log "no categories"
		else
			log "categories:"
			log LOG4AS_CONFIG's getValue("categories")'s toString()
		end if

	else if caseIndex is 2 then
		(* Matched, Manually create appropriate entry in log4as.plist *)

		log "Is 'log4as' Printable on info? : " & sut's isPrintable("log4as", info of level)
		log "Is log4as.log4as Printable on debug: " & sut's isPrintable("log4as", debug of level)
		log "Is log4as.log4as Printable on warn: " & sut's isPrintable("log4as", warn of level)
		log "Is log4as.log4as Printable on ERR: " & sut's isPrintable("log4as", ERR of level)
		log "Is 'log4as' Printable on OFF? : " & sut's isPrintable("log4as", OFF of level)

		log "---"
		(* Unmatched, make sure there is no matching entry in log4as.plist *)
		set defaultLevel of sut to info of level
		set defaultLevel of sut to debug of level
		set defaultLevel of sut to warn of level
		set defaultLevel of sut to ERR of level
		set defaultLevel of sut to OFF of level

		log "Default level: " & sut's defaultLevel

		log "Will info() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", info of level)
		log "Will debug() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", debug of level)
		log "Will warn() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", warn of level)
		log "Will fatal() print on " & sut's defaultLevel & ": " & sut's isPrintable("$absent", ERR of level)
	end if

	spot's finish()
end spotCheck

(*  *)
on new()
	-- if my logClasses is missing value then loadPlist()
	loadPlist()

	script Log4asInstance

		(*
			@moduleName - the complete script name. e.g. "log4as" or "Menu Case" or "Edit Notes.app".
			@targetLogLevel - the method used to log, info(), debug(), etc.
		*)
		on isPrintable(moduleName, targetLogLevel)
			if targetLogLevel is equal to OFF of level then return false
			-- log "Module name: " & moduleName
			repeat with nextClassLevel in my logClasses
				-- log "nextClassLevel: " & nextClassLevel
				set nextClassKey to text 8 thru -1 of nextClassLevel
				-- log "nextClassKey: " & nextClassKey
				if moduleName starts with nextClassKey then
					set nextClassLevel to plistBuddyLog4as's getValue({"categories", "log4as." & nextClassKey})
					-- log "nextClassLevel: " & nextClassLevel
					set subjectLevelInt to _textToInt(nextClassLevel)
					-- log "matched moduleName: " & moduleName & ", nextClassLevel: " & nextClassLevel & ", subject's value: " & subjectLevelInt & ", Target Log Level: " & targetLogLevel
					if subjectLevelInt is equal to the OFF of level then return false

					return targetLogLevel is greater than or equal to subjectLevelInt
				end if
			end repeat

			-- log "un registered"

			-- when moduleName is not found in the plist.
			if my defaultLevel is equal to OFF of level then return false

			-- log "targetLogLevel: " & targetLogLevel & ", default level: " & my defaultLevel
			targetLogLevel is greater than or equal to my defaultLevel
		end isPrintable
	end script
end new


-- Private Codes below =======================================================


(* Can be called outside to reload the plist. *)
on loadPlist()
	set my plistBuddyLog4as to plistBuddyLib's new(plistName)
	set defaultLevelConfig to std's nvl(plistBuddyLog4as's getValue("defaultLevel"), "INFO")

	-- log "LOG4AS: defaultLevelConfig: " & defaultLevelConfig
	set my defaultLevel to _textToInt(defaultLevelConfig)

	set my logClasses to plistBuddyLog4as's getDictionaryKeys("categories")
end loadPlist


on initDefaultLevel()
	set defaultLevelConfig to LOG4AS_CONFIG's getValueWithDefault("defaultLevel", "INFO")
	set my defaultLevel to _textToInt(defaultLevelConfig)
end initDefaultLevel


on _textToInt(logLevel)
	if logLevel is "INFO" then return info of level
	if logLevel is "DEBUG" then return debug of level
	if logLevel is "WARN" then return warn of level
	if logLevel is "ERR" then return ERR of level

	OFF of level
end _textToInt
