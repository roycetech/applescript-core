global std, plutil, mapLib
global LOG4AS_CONFIG

(*
	@Plists:
		log4as
			defaultLevel
			printToConsole
			Categories
*)

property initialized : false
property logger : missing value
property Level : {OFF:0, IGNORE:1, DEBUG:2, INFO:3, WARN:4, ERR:5}
property defaultLevel : INFO of Level

(* ASDictionary. Populated from log4as.plist, Categories.*)
property classesLevel : missing value

if name of current application is "Script Editor" then spotCheck()

on spotCheck()
	init()
	set thisCaseId to "log4as-spotCheck"
	logger's start()
	
	-- If you haven't got these imports already.
	set listUtil to std's import("list")
	
	set cases to listUtil's splitByLine("
		Manual: Config Info
		Manual: Is Printable (un/registered, less, equal, greater, OFF)
	")
	
	set spotLib to std's import("spot")'s new()
	set spot to spotLib's new(thisCaseId, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	sut's loadPlist() -- force reload each time during spot check.
	if caseIndex is 1 then
		logger's infof("Default Level: {}", LOG4AS_CONFIG's getValue("defaultLevel"))
		logger's infof("Print to console: {}", LOG4AS_CONFIG's getValue("printToConsole"))
		logger's infof("Write to file: {}", LOG4AS_CONFIG's getValue("writeToFile"))
		log LOG4AS_CONFIG's getValue("categories")'s toString()
		
	else if caseIndex is 2 then
		logger's infof("Is Printable INFO log4as.log4as: {}", sut's isPrintable("log4as", INFO of Level))
		logger's infof("Is Printable DEBUG log4as.log4as: {}", sut's isPrintable("log4as", DEBUG of Level))
		logger's infof("Is Printable DEBUG log4as.$spot: {}", sut's isPrintable("$spot", DEBUG of Level))
		logger's infof("Is Printable DEBUG log4as.$spot: {}", sut's isPrintable("$spot", INFO of Level))
		logger's infof("Is Printable DEBUG log4as.$spot: {}", sut's isPrintable("$spot", WARN of Level))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck

(*  *)
on new()
	script Log4asInstance
		on isPrintable(moduleName, logLevel)
			repeat with nextClassLevel in classesLevel's getKeys()
				set nextClassKey to text 8 thru -1 of nextClassLevel
				if moduleName starts with nextClassKey then
					set nextClassLevel to classesLevel's getValue(nextClassLevel)
					-- logger's debugf("nextClassLevel: {}", nextClassLevel)
					return logLevel is greater than or equal to the _textToInt(nextClassLevel) and _textToInt(nextClassLevel) is not equal to the OFF of Level
				end if
			end repeat
			
			logLevel is greater than or equal to my defaultLevel and defaultLevel is not equal to the OFF of Level
		end isPrintable
	end script
end new


-- Private Codes below =======================================================


(* Can be called outside to reload the plist. *)
on loadPlist()
	set LOG4AS_CONFIG to plutil's new("log4as")
	initDefaultLevel()
	
	set classLevel to mapLib's new()
	set classesLevel to LOG4AS_CONFIG's getValue("Categories")
	
	if classesLevel is not missing value then
		repeat with nextKey in classesLevel's getKeys()
			-- log nextKey
		end repeat
	end if
	
end loadPlist


on initDefaultLevel()
	set defaultLevelConfig to LOG4AS_CONFIG's getValueWithDefault("defaultLevel", "INFO")
	set defaultLevel to _textToInt(defaultLevelConfig)
end initDefaultLevel


on _textToInt(logLevel)
	if logLevel is "INFO" then return INFO of Level
	if logLevel is "OFF" then return OFF of Level
	if logLevel is "IGNORE" then return IGNORE of Level
	if logLevel is "DEBUG" then return DEBUG of Level
	if logLevel is "WARN" then return WARN of Level
	if logLevel is "ERR" then return ERR of Level
end _textToInt


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("log4as")
	set plutil to std's import("plutil")'s new()
	set mapLib to std's import("map")
	
	loadPlist()
end init
