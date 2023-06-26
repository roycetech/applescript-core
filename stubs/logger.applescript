global CR

(*
	This script is created to allow building library scripts that uses the 
	actual logger library to workaround the issue of circular dependency.

	This should be compiled first before the libraries required by the actual
	logger library.
*)

use scripting additions


property name : missing value
property logOverride : false
property startSeconds : 0
property logLite : missing value


if {"Script Debugger", "Script Editor"} contains the name of current application then spotCheck()

on new(pObjectName)	
	script LoggerStubInstance
		on start()
		end start
		
		
		on finish()
		end finish
		
		
		on logOnFile(thisInfo)
		end logOnFile
		
		
		on logObj(label, obj)
		end logObj
		
		
		on infof(thisInfo as text, tokens)
		end infof
		
		
		on debugf(thisInfo as text, tokens)
		end debugf
		
		
		on info(objectToLog)
		end info
		
		
		on debug(thisInfo)
		end debug
		
		on warn(thisMessage)
		end warn
		
		on warnf(thisInfo as text, tokens)
		end warnf
		
		
		on fatal(thisMessage)
		end fatal
		
		
	end script
end new
