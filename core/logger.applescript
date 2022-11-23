global std, sessionPlist, textUtil

(*
	Note: does not print properly when run in ST3.
	WARNING: Do not use the Core Text Utilities. It results to a not so
	visible crash for some scripts that are triggered via Voice Command.
*)

property filename : "applescript-core.log"
property logFilePath : missing value
property level : 1
property name : missing value
property logOverride : false
property startSeconds : 0
property logLite : missing value

property initialized : false

-- spotCheck() -- IMPORTANT: Comment out on deploy

on spotCheck()
	init()
	start("logger-spotCheck")
	
	info("Info Test")
	infof("Hello {}", "World")
	debugf("Hello {}", "World")
	debug("debug Test")
	
	-- return
	
	set theObj to {name:"This is an object", age:1}
	info(theObj)
	logObj("Example", theObj)
	
	finish()
end spotCheck


on new(pObjectName)
	script LoggerInstance
		property objectName : pObjectName
		
		on start()
			set theLabel to "Running: [" & my objectName & "]"
			set theBar to _repeatText("=", count of theLabel)
			
			info(theBar)
			info(theLabel)
			
			set my startSeconds to time of (current date)
		end start
		
		
		on finish()
			set T2s to time of (current date)
			set elapsed to T2s - startSeconds
			
			info("*** End: [" & my objectName & "] - " & elapsed & "s")
		end finish
		
		
		to logOnFile(thisInfo)
			set my logOverride to true
			info(thisInfo)
			set my logOverride to false
		end logOnFile
		
		
		(*
			Used only for debugging.
		*)
		to logObj(label, obj)
			debug(label & ": " & _toString(obj))
		end logObj
		
		
		on infof(thisInfo as text, tokens)
			info(textUtil's format(thisInfo, tokens))
		end infof
		
		
		on debugf(thisInfo as text, tokens)
			debug(textUtil's format(thisInfo, tokens))
		end debugf
		
		
		on info(objectToLog)
			set thisInfo to _toString(objectToLog)
			
			set currentDate to (current date)
			set {year:y, month:m, day:d, time:t} to currentDate
			set theTime to _secsToHMS(t as integer)
			set theDate to short date string of currentDate
			set customDateTime to theDate & " " & theTime
			
			-- What's "the"?
			set the info_log to logFilePath
			set CR to ASCII character 13
			
			set log_message to customDateTime & " " & my objectName & "> " & thisInfo
			log log_message
			
			-- do shell script "echo \"" & log_message & "\" > ~/AppleScript/logs/applescript.log" -- hard coded experimental
			-- return
			
			try
				open for access file logFilePath with write permission
				
				write (log_message & "
	") to file logFilePath starting at eof
				close access file logFilePath
			on error the errorMessage number the errorNumber
				log "Error encountered: " & errorMessage
				try
					close access file logFilePath
				end try
			end try
		end info
		
		
		on debug(thisInfo)
			if sessionPlist's debugOn() is false then return
			
			-- if config's debugOn() is true then
			if sessionPlist's debugOn() is true then
				info("D " & _toString(thisInfo))
			end if
		end debug
		
		
		on warn(thisMessage)
			info("W " & _toString(thisMessage))
		end warn
		
		on warnf(thisInfo as text, tokens)
			warn(textUtil's format(thisInfo, tokens))
		end warnf
		
		
		on fatal(thisMessage)
			info("F " & _toString(thisMessage))
		end fatal
		
		
		to _secsToHMS(secs)
			tell (1000000 + secs div hours * 10000 + secs mod hours div minutes * 100 + secs mod minutes) as string to return text 2 thru 3 & ":" & text 4 thru 5 & ":" & text 6 thru 7
		end _secsToHMS
		
		
		on _toString(target)
			if class of target is string then return target
			if class of target is not list then set target to {target}
			local lst, i, txt, errMsg, orgTids, oName, oId, prefix, txtCombined
			set lst to {}
			repeat with anyObj in target
				set txt to ""
				repeat with i from 1 to 2
					try
						if i is 1 then
							if class of anyObj is list then
								set {orgTids, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {", "}} # '
								set txt to ("{" & anyObj as string) & "}"
								set AppleScript's text item delimiters to orgTids # '
							else
								set txt to anyObj as string
							end if
						else
							set txt to properties of anyObj as string
						end if
					on error errMsg
						# Trick for records and record-*like* objects:
						# We exploit the fact that the error message contains the desired string representation of the record, so we extract it from there. This (still) works as of AS 2.3 (OS X 10.9).
						try
							set txt to do shell script "egrep -o '\\{.*\\}' <<< " & quoted form of errMsg
							set txt to text 2 thru -2 of txt
						end try
					end try
					if txt is not "" then exit repeat
				end repeat
				set prefix to ""
				if class of anyObj is not in {text, integer, real, boolean, date, list, record} and anyObj is not missing value then
					set prefix to "[" & class of anyObj
					set oName to ""
					set oId to ""
					try
						set oName to name of anyObj
						if oName is not missing value then set prefix to prefix & " name=\"" & oName & "\""
					end try
					try
						set oId to id of anyObj
						if oId is not missing value then set prefix to prefix & " id=" & oId
					end try
					set prefix to prefix & "] "
					set txt to prefix & txt
				end if
				set lst to lst & txt
			end repeat
			set {orgTids, AppleScript's text item delimiters} to {AppleScript's text item delimiters, {" "}} # '
			set txtCombined to lst as string
			set AppleScript's text item delimiters to orgTids # '
			return txtCombined
		end _toString
		
		
		to _repeatText(theText, ntimes)
			set theResult to ""
			repeat ntimes times
				set theResult to theResult & theText
			end repeat
		end _repeatText
	end script
	
	std's applyMappedOverride(result)
end new


to init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set config to std's import("config")'s new()
	set textUtil to std's import("string")
	
	set logSubDir to config's getDefaultsValue("LOG_SUBDIR")
	if logSubDir is missing value then set logSubDir to "applescript-core:logs:"
	set logFilePath to (path to home folder as text) & logSubDir & filename
end init
