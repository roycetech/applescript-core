(*
	Core library, avoid adding any dependencies.

	Considering renaming this to decorator.

	@Plist:
		config-lib-factory.plist

	@Build:
		make build-lib SOURCE=core/decorator

	@Last Modified: 2023-09-25 14:57:57
	@Change Logs:
		August 10, 2023 7:49 AM - Allow multiple overrides on the same instance name.
*)

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	script SublimeTextInstance
	end script
	set sut to new(SublimeTextInstance)
	set wrapped to sut's decorate()
	sut's printHierarchy()
end spotCheck


(*  *)
on new(pScriptObject)
	script DecoratorInstance

		(*
			Set this to true to skip the override during testing.
		*)
		property skip : false
		property scriptObj : pScriptObject
		property PLIST : "~/applescript-core/config-lib-factory.plist"

		on printHierarchy()
			repeat with nextElement in _getHierarchy()
				log nextElement
			end repeat
		end printHierarchy


		on _getHierarchy()
			set hierarchy to {}
			repeat
				try
					set nextName to the name of scriptObj
					-- if class of nextName is not "text" then exit repeat
					nextName as text -- Strange error, crashes without this.

					if nextName is not "decorator" then
						set end of hierarchy to nextName
					end if

					set scriptObj to scriptObj's parent
				on error
					exit repeat
				end try
			end repeat
			reverse of hierarchy
		end _getHierarchy


		on decorate()
			if skip then return scriptObj

			set scriptName to the name of the scriptObj
			set factory to missing value
			try
				-- set factory to do shell script "plutil -extract '" & scriptName & "' raw " & PLIST
				set factoryType to do shell script "plutil -type '" & scriptName & "' " & PLIST
				-- log factoryType
				if factoryType is "array" then
					set command to "plutil -extract " & scriptName & " xml1 " & PLIST & " -o - \\
								| tail -n +5 \\
								| tail -r \\
								| tail -n +3 \\
								| tail -r \\
								| awk -F\">\" '{print $2}' \\
								| awk -F\"<\" '{print $1}' \\
								| paste -s -d, -"
					set csv to do shell script command
				else
					set csv to do shell script "plutil -extract '" & scriptName & "' raw " & PLIST
				end if

				set oldDelimiters to AppleScript's text item delimiters
				set AppleScript's text item delimiters to ","
				set array to every text item of csv
				set AppleScript's text item delimiters to oldDelimiters
				repeat with nextElement in the array
					-- log nextElement
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
		end decorate
	end script
end new
