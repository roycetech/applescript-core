(*
	Non-file version of logging that can be used by libaries that need to avoid circular dependency with the standard logging library.
*)

use scripting additions

use textUtil : script "core/string"

property name : missing value
property logOverride : false
property startSeconds : 0

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	set sut to new("logger")

	tell sut
		start()

		info("Info Test")
		infof("Hello {}", "World")
		debugf("Hello {}", "World")
		debug("debug Test")

		-- return

		set theObj to {name:"This is an object", age:1}
		info(theObj)
		logObj("Example", theObj)

		finish()
	end tell
end spotCheck


on new(pObjectName)

	script LoggerInstance
		property objectName : pObjectName
		property level : 1

		on start()
			set theLabel to "Running: [" & objectName & "]"
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


		(*
			Used only for debugging. Could not print record contents.
		*)
		on logObj(label, obj)
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

			set log_message to customDateTime & " " & my objectName & "> " & thisInfo
			log log_message
		end info


		on debug(thisInfo)
			info("D " & _toString(thisInfo))
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


		on _secsToHMS(secs)
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


		on _repeatText(theText, ntimes)
			set theResult to ""
			repeat ntimes times
				set theResult to theResult & theText
			end repeat
		end _repeatText
	end script
end new
