(*
	@Project:
		applescript-core

	@Build:
		make compile-lib SOURCE="apps/3rd-party/Eclipse/v202306/eclipse"

	@Created: September 7, 2023 11:02 AM
	@Last Modified: 2023-09-17 11:49:34
*)

use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"

use spotScript : script "core/spot-test"

property logger : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitByLine("
		Manual: Show Preferences
		Manual: Appearance Preferences
		Manual: Switch to Light Mode
		Manual: Switch to Dark Mode
		Manual: Run As Java Application

		Manual: Run As JUnit Test
		Manual: Run As Maven Clean
		Manual: Debug As JUnit Test
		Manual: Coverage As JUnit Test
		Manual: Switch Perspective

		Manual: Switch Bottom Left Panel
		Manual: Show Default View
	")

	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sut to new()
	logger's infof("Current Document: {}", sut's getCurrentFilePath())
	logger's infof("Current Project Key: {}", sut's getCurrentProjectKey())

	if caseIndex is 1 then
		sut's openPreferences()

	else if caseIndex is 2 then
		sut's openPreferences()
		sut's gotoAppearancePreference()
		logger's infof("Theming enabled: {}", sut's isThemingEnabled())

	else if caseIndex is 3 then
		sut's switchTheme("Light")
		sut's clickAppyAndClose()
		sut's chooseRestart()
		sut's confirmPreferenceRecorder()

	else if caseIndex is 4 then
		sut's switchTheme("Dark")
		sut's clickAppyAndClose()
		sut's chooseRestart()
		sut's confirmPreferenceRecorder()

	else if caseIndex is 5 then
		sut's runAs("Java Application")

	else if caseIndex is 6 then
		sut's runAs("JUnit Test")

	else if caseIndex is 7 then
		sut's runAs("Maven clean")

	else if caseIndex is 8 then
		sut's debugAs("JUnit Test")

	else if caseIndex is 9 then
		sut's coverageAs("JUnit Test")

	else if caseIndex is 10 then
		set perspective to "Debug"
		set perspective to "Java"
		sut's switchPerspective(perspective)

	else if caseIndex is 11 then
		set panelName to "JUnit"
		set panelName to "Problems"
		set panelName to "Coverage"
		set panelName to "Project Explorer"
		set panelName to "Breakpoints"
		-- set panelName to "Error Log"
		-- set panelName to "Search"
		logger's infof("panelName: {}", panelName)
		sut's switchPanel(panelName)

	else if caseIndex is 12 then
		set viewName to "Progress"
		sut's showDefaultView(viewName)

	end if


	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()

	script EclipseInstance
		(*
			Clicks on any of the panels by title.
			@returns true if the panel was successfully clicked on.
		*)
		on switchPanel(panelName)
			tell application "System Events" to tell process "eclipse"
				set compositeUiElement to first UI element of front window whose role description is "SWTComposite"
				repeat with nextTabGroup in tab groups of compositeUiElement
					try
						set sut to radio button panelName of nextTabGroup
						lclick of cliclick at sut
						exit repeat
					on error the errorMessage number the errorNumber
						-- logger's warn(errorMessage)
					end try
				end repeat
			end tell
		end switchPanel


		(*
			Shows a view among the list when you trigger the Window > Show View menu.
			Grabs focus.
		*)
		on showDefaultView(viewName)
			activate application "Eclipse Java"

			tell application "System Events" to tell process "eclipse"
				try
					click menu item viewName of menu 1 of menu item "Show View" of menu 1 of menu bar item "Window" of menu bar 1
				end try
			end tell
		end showDefaultView


		(*
			Fails intermittently and returns a missing value.
			@returns the POSIX path of the currently opened file.
		*)
		on getCurrentFilePath()
			if running of application "Eclipse Java" is false then return missing value

			tell application "System Events" to tell process "eclipse"
				set mainWindow to the first window whose title is not ""
				textUtil's stringAfter(value of attribute "AXDocument" of mainWindow, "file://")
			end tell
		end getCurrentFilePath


		on getCurrentProjectKey()
			if running of application "Eclipse Java" is false then return missing value

			tell application "System Events" to tell process "eclipse"
				set mainWindow to the first window whose title is not ""
				set mainTokens to textUtil's split(title of mainWindow, " - ")
				if the number of items in mainTokens is less than 3 then return missing value
			end tell

			set resourcePath to the 2nd item of mainTokens
			set resourceTokens to textUtil's split(resourcePath, "/")
			the first item of resourceTokens
		end getCurrentProjectKey


		on openPreferences()
			if running of application "Eclipse Java" is false then return

			activate application "Eclipse Java"

			tell application "System Events" to tell process "eclipse"
				try
					click (first menu item of menu 1 of menu bar item "Eclipse" of menu bar 1 whose title starts with "Preferences")
					delay 0.1 -- Delay only if successful
				end try
			end tell
		end openPreferences


		(*
			Assumes the Preferences window is already active
		*)
		on gotoAppearancePreference()
			tell application "System Events" to tell process "eclipse"
				set generalDisclosure to UI element 1 of group 1 of row 1 of outline 1 of scroll area 2 of window "Preferences"

				if value of generalDisclosure is 0 then
					click generalDisclosure
				end if

				try
					select row 2 of outline 1 of scroll area 2 of window "Preferences" -- Select the Appearance
					delay 0.1 -- Delay only if successful
				end try
			end tell
		end gotoAppearancePreference


		(* Related to the appearance preference. See #gotoAppearancePreference() *)
		on isThemingEnabled()
			tell application "System Events" to tell process "eclipse"
				try
					return get value of checkbox "Enable theming" of scroll area 1 of window "Preferences" is 1
				end try
			end tell

			false
		end isThemingEnabled

		(* @mode - Dark or Light *)
		on switchTheme(mode)
			openPreferences()
			gotoAppearancePreference()
			if isThemingEnabled() is false then
				logger's warn("You need to enable and apply theming first. ")
				return
			end if

			tell application "System Events" to tell process "eclipse"
				try
					set themePopup to pop up button 2 of scroll area 1 of window "Preferences"
					click themePopup
					delay 0.1
					click menu item mode of menu 1 of themePopup
				end try
			end tell
		end switchTheme


		(* Used when the Preferences window is open. *)
		on clickAppyAndClose()
			tell application "System Events" to tell process "eclipse"
				try
					click button "Apply and Close" of window "Preferences"
					delay 1
				end try
			end tell
		end clickAppyAndClose


		(*
			After changing a preference and clicking on the Apply and Close button, you'll be prompted to restart.
			This handler will choose the restart option.
		*)
		on chooseRestart()
			tell application "System Events" to tell process "eclipse"
				try
					-- click button "Restart" of window "Theme Changed "
					click button "Restart" of front window
					delay 1
				end try
			end tell
		end chooseRestart


		on confirmPreferenceRecorder()
			tell application "System Events" to tell process "eclipse"
				try
					click button "OK" of window "Preference Recorder" -- Not present all the time
				end try
			end tell
		end confirmPreferenceRecorder

		(*
			@runType "Java Application" or "JUnit Test"
		*)
		on runAs(runType)
			if running of application "Eclipse Java" is false then return

			activate application "Eclipse Java"
			delay 0.1

			tell application "System Events" to tell process "eclipse"
				-- Let the error propagate. Sometimes the user needs to select a certain object in the package explorer.
				try
					click (first menu item of menu 1 of menu item "Run As" of menu 1 of menu bar item "Run" of menu bar 1 whose title contains runType)
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					error "Make sure you have the correct object type selected. "
				end try
			end tell

		end runAs


		(*
			@runType "Java Application" or "JUnit Test"
		*)
		on debugAs(runType)
			if running of application "Eclipse Java" is false then return

			activate application "Eclipse Java"
			delay 0.1

			tell application "System Events" to tell process "eclipse"
				-- Let the error propagate. Sometimes the user needs to select a certain object in the package explorer.
				try
					click (first menu item of menu 1 of menu item "Debug As" of menu 1 of menu bar item "Run" of menu bar 1 whose title contains runType)
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					error "Make sure you have the correct object type selected. "
				end try
			end tell
		end debugAs


		(*
			@runType "Java Application" or "JUnit Test"
		*)
		on coverageAs(runType)
			if running of application "Eclipse Java" is false then return

			activate application "Eclipse Java"
			delay 0.1

			tell application "System Events" to tell process "eclipse"
				-- Let the error propagate. Sometimes the user needs to select a certain object in the package explorer.
				try
					click (first menu item of menu 1 of menu item "Coverage As" of menu 1 of menu bar item "Run" of menu bar 1 whose title contains runType)
				on error the errorMessage number the errorNumber
					logger's warn(errorMessage)
					error "Make sure you have the correct object type selected. "
				end try
			end tell
		end coverageAs


		on switchPerspective(perspective)
			if running of application "Eclipse Java" is false then return

			activate application "Eclipse Java"
			delay 0.1

			tell application "System Events" to tell process "eclipse"
				click radio button perspective of toolbar 2 of front window
			end tell
		end switchPerspective
	end script
end new
