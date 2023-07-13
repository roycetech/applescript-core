(*
 	Core library, avoid adding any dependencies.
 	
 	@Plist:
 		config-lib-factory.plist
 		
 	@Build:
 		make compile-lib SOURCE=core/overrider
*)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
end spotCheck


(*  *)
on new()
	script OverriderInstance
		(*
			Set this to true to skip the override during testing.
		*)
		property skip : false
		
		on applyMappedOverride(scriptObj)
			if skip then return scriptObj
			
			set scriptName to the name of the scriptObj
			set factory to missing value
			try
				set factory to do shell script "plutil -extract '" & scriptName & "' raw ~/applescript-core/config-lib-factory.plist"
				set oldDelimiters to AppleScript's text item delimiters
				set AppleScript's text item delimiters to ","
				set array to every text item of csv
				set AppleScript's text item delimiters to oldDelimiters
				repeat with nextElement in the array
					try
						set factoryScript to script nextElement
						set scriptObj to factoryScript's decorate(scriptObj)
					end try
					
				end repeat
				return scriptObj
			end try
			
			if factory is not missing value then
				set factoryScript to script factory
				return factoryScript's decorate(scriptObj)
			end if
			
			scriptObj
		end applyMappedOverride
	end script
end new
