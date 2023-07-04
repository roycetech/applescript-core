(*
	NOTE: The key do not need to exist in the flag.plist, it will be created 
	when its value is set.

	@Usage:
		use switchLib : script "switch"
		set yourFlag to switchLib's new("Flag Name")
		yourFlag's turnOn()
		
	@Build:
		make compile-lib SOURCE=core/switch
*)

use loggerFactory : script "logger-factory"
use utLib : script "unit-test"
use testLib : script "test"
use plutilLib : script "plutil"

property logger : missing value
property switchPlist : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me, "switch")
	set useBasicLogging of testLib to true
	
	logger's start()
	
	unitTest()
	
	logger's finish()
end spotCheck


(* 
	@Legacy code. Wanted to remove this but let's just put the initialization in 
	here. Duplicated initialization as a result. *)
on active(featureName)
	set plutil to plutilLib's new()
	set switchPlist to plutil's new("switches")

	try
		set theValue to switchPlist's getValue(featureName)
	on error
		return false
	end try
	
	if theValue is "" or theValue is missing value then return false
	theValue
end active

on inactive(featureName)
	not active(featureName)
end inactive

on new(pFeatureName)
	set plutil to plutilLib's new()
	set switchPlist to plutil's new("switches")
	
	script SwitchInstance
		property featureName : pFeatureName
		
		(*  *)
		on active()
			set theValue to switchPlist's getValue(featureName)
			if theValue is "" or theValue is missing value then return false
			theValue
		end active
		
		(*  *)
		on inactive()
			not active()
		end inactive
		
		on turnOn()
			setValue(true)
		end turnOn
		
		on toggle()
			setValue(not active())
		end toggle
		
		on turnOff()
			setValue(false)
		end turnOff
		
		on setValue(boolValue)
			switchPlist's setValue(featureName, boolValue)
		end setValue
	end script
end new





-- Private Codes below =======================================================
(*
	NOTE: Skip this for now, the implementation is fairly simple and dependencies are widely used.
	Handler grouped by hundredths.
	Put the case you are debugging at the top, and move to correct place once verified.
	
	(* TODO: To update the design guide in the notes. *)
*)
on unitTest()
	set UT_KEY_MISSING to "$unit-test-missing"
	set UT_KEY_OFF to "$unit-test-off"
	set UT_KEY_ON to "$unit-test-on"
	
	script Hook
		on reinit()
			switchPlist's deleteKey(UT_KEY_MISSING)
			switchPlist's setValue(UT_KEY_OFF, false)
			switchPlist's setValue(UT_KEY_ON, true)
		end reinit
	end script
	set Hook to result
	
	set test to testLib's new()
	set ut to test's new()
	
	tell ut
		newMethod("active")
		
		Hook's reinit()
		
		set sutMissing to my new(UT_KEY_MISSING)
		set sutOff to my new(UT_KEY_OFF)
		set sutOn to my new(UT_KEY_ON)
		
		newMethod("active")
		assertEqual(false, sutMissing's active(), "Non-existent flag name")
		assertEqual(false, sutOff's active(), "Unset flag")
		assertEqual(true, sutOn's active(), "Set flag")
		
		newMethod("inactive")
		assertEqual(true, sutMissing's inactive(), "Non-existent flag name")
		assertEqual(true, sutOff's inactive(), "Unset flag")
		assertEqual(false, sutOn's inactive(), "Set flag")
		
		newMethod("turnOn")
		sutMissing's turnOn()
		assertEqual(true, sutMissing's active(), "Non-existent turns on")
		sutOff's turnOn()
		assertEqual(true, sutOff's active(), "Off turns on")
		sutOn's turnOn()
		assertEqual(true, sutOn's active(), "On remains on")
		
		Hook's reinit()
		
		newMethod("turnOff")
		sutMissing's turnOff()
		assertEqual(false, sutMissing's active(), "Non-existent remains off")
		sutOff's turnOff()
		assertEqual(false, sutOff's active(), "Off remains off")
		sutOn's turnOff()
		assertEqual(false, sutOn's active(), "On turns off")
		
		Hook's reinit()
		
		newMethod("toggle")
		sutMissing's toggle()
		assertEqual(true, sutMissing's active(), "Non-existent turns on")
		sutOff's toggle()
		assertEqual(true, sutOff's active(), "Off turns on")
		sutOn's toggle()
		assertEqual(false, sutOn's active(), "On turns off")
		
		done()
	end tell
end unitTest