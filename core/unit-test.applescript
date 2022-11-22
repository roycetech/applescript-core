global std, logger

use script "Core Text Utilities"
use scripting additions

property initialized : false

-- spotCheck() -- IMPORTANT: Comment out on deploy

to spotCheck()
	init()
	logger's start()
	
	set ut to newInstance()
	tell ut
		newMethod("isEven")
		assertEqual(true, isEven(0), "Happy Case for 0")
		assertEqual(false, isEven(1), "Happy Case for 1")
		
		newMethod("isOdd")
		assertEqual(false, isOdd(0), "Happy Case for 0")
		assertEqual(true, isOdd(1), "Happy Case for 1")
		assertEqual(false, isOdd(2), "Happy Case for 2")
		
		done()
	end tell
	
	set params to "
		true, 0, Happy Case
		false, 1, Happy Case
	"
	
	logger's finish()
end spotCheck


on isEven(theNumber)
	theNumber mod 2 is 0
end isEven

on isOdd(theNumber)
	theNumber mod 2 is 1
end isOdd


(* Used for unit testing *)
on assert(expected, actual, message)
	init()
	
	logger's info(message)
	
	if actual is not equal to expected then
		if expected contains (ASCII character 13) or expected contains return then
			error (("Assertion failed for \"" & message & "\": 
Expected: 
[" & expected as text) & "]
Actual: 
[" & actual as text) & "]
"
		end if
		
		error (("Assertion failed for \"" & message & "\": Expected: [" & expected as text) & "], but got: [" & actual as text) & "]"
	end if
end assert



-- Private Codes below =======================================================

on newInstance()
	script UnitTestInstance
		property method : missing value
		property methodCounter : 0
		property caseCounter : 0
		
		to newMethod(pMethod)
			set caseCounter to 0
			set methodCounter to methodCounter + 100
			set method to pMethod
		end newMethod
		
		to assertEqual(expected, actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			assert(expected, actual, caseDescIndexed)
		end assertEqual
		
		to assertTrue(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			std's assert(true, actual, caseDescIndexed)
		end assertTrue
		
		to assertFalse(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			std's assert(false, actual, caseDescIndexed)
		end assertFalse
		
		on assertNotMissingValue(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			if actual is missing value then error "Assertion failed for \"" & caseDesc & "\": Expected any value, but got missing value instead."
		end assertNotMissingValue
		
		on assertMissingValue(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			if actual is not missing value then error "Assertion failed for \"" & caseDesc & "\": Expected missing value, but got \"" & actual & "\" value instead."
		end assertMissingValue
		
		to done()
			logger's info("All unit test cases passed.")
		end done
		
		on formatCaseIndexed(caseDesc)
			set caseCounter to caseCounter + 1
			set caseDescIndexed to format {"{} - Case {}: {}", {method, methodCounter + caseCounter, caseDesc}}
		end formatCaseIndexed
	end script
end newInstance


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s newInstance("unit-test")
end init
