(*
	@Tab: AC
	@Build:
		make build-lib SOURCE=core/test
*)

use script "core/Text Utilities"
use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set ut to new()
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

on new()
	loggerFactory's injectBasic(me)

	script TestInstance
		property method : missing value
		property methodCounter : 0
		property caseCounter : 0

		on newMethod(pMethod)
			set caseCounter to 0
			set methodCounter to methodCounter + 100
			set method to pMethod
		end newMethod

		on newScenario(pScenario)
			newMethod(pScenario)
		end newScenario

		on newFeature(pFeature)
			newMethod(pFeature)
		end newFeature

		on assertEquals(expected, actual, caseDesc)
			assertEqual(expected, actual, caseDesc)
		end assertEquals

		on assertEqual(expected, actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			assert(expected, actual, caseDescIndexed)
		end assertEqual

		on assertTrue(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			assert(true, actual, caseDescIndexed)
		end assertTrue

		on assertFalse(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			assert(false, actual, caseDescIndexed)
		end assertFalse

		on assertNotMissingValue(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			logger's info(caseDescIndexed)

			if actual is missing value then error "Assertion failed for \"" & caseDesc & "\": Expected any value, but got missing value instead."
		end assertNotMissingValue

		on assertHasValue(actual, caseDesc)
			assertNotMissingValue(actual, caseDesc)
		end assertNotMissingValue

		on assertMissingValue(actual, caseDesc)
			set caseDescIndexed to formatCaseIndexed(caseDesc)
			logger's info(caseDescIndexed)

			if actual is not missing value then error "Assertion failed for \"" & caseDesc & "\": Expected missing value, but got \"" & actual & "\" value instead."
		end assertMissingValue

		on fail(caseDesc)
			logger's info(formatCaseIndexed(caseDesc))

			error "Assertion failed for \"" & caseDesc & "\": Expected not to reach this code"
		end fail

		on done()
			logger's info("All test cases passed.")
		end done

		on formatCaseIndexed(caseDesc)
			set caseCounter to caseCounter + 1
			set caseDescIndexed to format {"{} - Case {}: {}", {method, methodCounter + caseCounter, caseDesc}}
		end formatCaseIndexed
	end script
end new
