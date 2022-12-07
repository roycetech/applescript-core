global std
global SWITCHES

(*
	NOTE: The key do not need to exist in the flag.plist, it will be created 
	when its value is set.

	Usage:
		set yourFlag to new("Flag Name")
		yourFlag's turnOn()
*)

property initialized : false
property logger : missing value

if name of current application is "Script Editor" then  spotCheck() -- IMPORTANT: Comment out on deploy

to spotCheck()
	init()
	logger's start()
	
	unitTest()
	
	logger's finish()
end spotCheck


on active(featureName)
	try
		set theValue to SWITCHES's getValue(featureName)
	on error
		return false
	end try
	
	if theValue is "" or theValue is missing value then return false
	theValue
end active

on inactive(featureName)
	not active(featureName)
end inactive

on new(pFeatureName as text)
	script Instance
		property featureName : pFeatureName
		
		(*  *)
		on active()
			set theValue to SWITCHES's getValue(featureName)
			if theValue is "" or theValue is missing value then return false
			theValue
		end active
		
		(*  *)
		on inactive()
			not active()
		end inactive
		
		to turnOn()
			setValue(true)
		end turnOn
		
		to toggle()
			setValue(not active())
		end toggle
		
		to turnOff()
			setValue(false)
		end turnOff
		
		to setValue(boolValue)
			SWITCHES's setValue(featureName, boolValue)
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
to unitTest()
	set UT_KEY_MISSING to "$unit-test-missing"
	set UT_KEY_OFF to "$unit-test-off"
	set UT_KEY_ON to "$unit-test-on"
	
	script Hook
		on reinit()
			SWITCHES's deleteKey(UT_KEY_MISSING)
			SWITCHES's setValue(UT_KEY_OFF, false)
			SWITCHES's setValue(UT_KEY_ON, true)
		end reinit
	end script
	set Hook to result
	
	set utLib to std's import("unit-test")
	set ut to utLib's new()
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


(* Constructor. When you need to load another library, do it here. *)
on init()
	if initialized of me then return
	set initialized of me to true
	
	set std to script "std"
	set logger to std's import("logger")'s new("switch")
	set plutil to std's import("plutil")
	set SWITCHES to plutil's new("switches")
end init