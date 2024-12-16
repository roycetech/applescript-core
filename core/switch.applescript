(*
	NOTE: The key do not need to exist in the switches.plist, it will be created
	when its value is set.

	@Usage:
		use switchLib : script "core/switch"
		set yourSwitch to switchLib's new("Switch Name")
		yourSwitch's turnOn()

	@Project:
		applescript-core

	@Build:
		make build-lib SOURCE=core/switch

	@Last Modified: 2024-12-05 15:20:38
	@TODO: Migrate to ASUnit.
	@Change Log:
		September 4, 2023 11:42 AM - Removed reference to the built-in unit test.
		August 4, 2023 12:30 PM
*)

use loggerFactory : script "core/logger-factory"

use plutilLib : script "core/plutil"

property logger : missing value
property switchPlist : missing value
property switchesPlistName : "switches"

property ERROR_MISSING_SWITCH_NAME : 1000

(*
	@Legacy code. Wanted to remove this but let's just put the initialization in
	here. Duplicated initialization as a result. *)
on active(switchName)
	set plutil to plutilLib's new()
	set switchPlist to plutil's new(switchesPlistName)

	try
		set theValue to switchPlist's getValue(switchName)
	on error
		return false
	end try

	if theValue is "" or theValue is missing value then return false
	theValue
end active

on inactive(switchName)
	not active(switchName)
end inactive


on new(pSwitchName)
	if pSwitchName is missing value then error "Switch name must be present" number ERROR_MISSING_SWITCH_NAME

	set plutil to plutilLib's new()
	set switchPlist to plutil's new(switchesPlistName)

	script SwitchInstance
		property switchName : pSwitchName

		(*  *)
		on active()
			set theValue to switchPlist's getValue(switchName)
			if theValue is "" or theValue is missing value then return false
			theValue
		end active

		(*  *)
		on inactive()
			not active()
		end inactive

		on isActive()
			active()
		end isActive

		on isInactive()
			not active()
		end isActive


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
			switchPlist's setValue(switchName, boolValue)
		end setValue
	end script
end new
